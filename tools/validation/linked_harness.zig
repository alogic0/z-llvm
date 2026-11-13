//! A fresh executable-mode compilation preserves std.start in the assembly.
//! Assemble it once, then use the same native linker and compiler-rt for every
//! subject. Nothing is reused across functions, modes, or validation runs.
const std = @import("std");
const u = @import("common.zig");
const toolchain = @import("toolchain.zig");
const Runner = @import("runner.zig").Runner;

pub fn emitterIdentity(c: *u.Context, emitter: []const u8) !u.Value {
    const path = try c.join(&.{emitter});
    const hash = try c.digest(path);
    const contract = try c.load(try c.join(&.{"test/real_programs/c_compiler.json"}));
    if (!std.mem.eql(u8, hash, try u.str(contract, "zig_emitter_sha256"))) return error.WrongHarnessEmitter;
    const environment = try toolchain.zigEnvironment(c, path);
    return u.toValue(c.a, .{
        .path = path,
        .resolved = try std.Io.Dir.cwd().realPathFileAlloc(c.io, path, c.a),
        .sha256 = hash,
        .version = environment.version,
        .target = environment.target,
        .cpu = "native",
        .library = try toolchain.libraryIdentity(c, environment.lib_dir),
    });
}

pub const Compiled = struct {
    source: []const u8,
    source_sha256: []const u8,
    object: []const u8,
    object_sha256: []const u8,
    mode: []const u8,
    emitter: u.Value,
    producer_commands: [2]usize,

    pub fn verify(h: Compiled, c: *u.Context) !void {
        if (!std.mem.eql(u8, h.source_sha256, try c.digest(h.source))) return error.HarnessSourceChanged;
        if (!std.mem.eql(u8, h.object_sha256, try c.digest(h.object))) return error.HarnessArtifactChanged;
    }

    pub fn linkCommand(h: Compiled, c: *u.Context, subject: []const u8, executable: []const u8) ![]const []const u8 {
        try h.verify(c);
        return c.a.dupe([]const u8, &.{ try u.str(h.emitter, "path"), "build-exe", "-fno-lld", "-fno-lto", "-fcompiler-rt", "-target", try u.str(h.emitter, "target"), "-mcpu=native", h.object, subject, try c.fmt("-O{s}", .{h.mode}), try c.fmt("-femit-bin={s}", .{executable}) });
    }

    pub fn identity(h: Compiled, c: *u.Context) !u.Value {
        return u.toValue(c.a, .{
            .source = h.source,
            .source_sha256 = h.source_sha256,
            .object = h.object,
            .object_sha256 = h.object_sha256,
            .harness_mode = h.mode,
            .emitter = h.emitter,
            .producer_commands = h.producer_commands,
            .startup = "executable-mode std.start; native linker; compiler-rt; no LTO",
        });
    }
};

pub fn compile(r: *Runner, directory: []const u8, source: []const u8, mode: []const u8, emitter: u.Value, env: *const std.process.Environ.Map) !Compiled {
    const c = r.context;
    if (!u.contains(&u.modes, mode)) return error.InvalidHarnessMode;
    const assembly = try c.temporaryPath(&.{ directory, "linked-harness.s" });
    const object = try c.temporaryPath(&.{ directory, "linked-harness.o" });
    const first = r.commands.array.items.len;
    const source_hash = try c.digest(source);
    try r.require(&.{ try u.str(emitter, "path"), "build-exe", "-fno-lld", "-fno-lto", "-target", try u.str(emitter, "target"), "-mcpu=native", source, try c.fmt("-O{s}", .{mode}), "-fno-emit-bin", try c.fmt("-femit-asm={s}", .{assembly}) }, try c.join(&.{ directory, "harness-compile" }), env);
    try r.require(&.{ try u.str(emitter, "path"), "cc", "-target", try u.str(emitter, "target"), "-x", "assembler", "-c", assembly, "-o", object }, try c.join(&.{ directory, "harness-assemble" }), env);
    const result: Compiled = .{ .source = source, .source_sha256 = source_hash, .object = object, .object_sha256 = try c.digest(object), .mode = mode, .emitter = emitter, .producer_commands = .{ first, first + 1 } };
    try result.verify(c);
    return result;
}
