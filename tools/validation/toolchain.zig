//! Explicit selections for nested validation commands and retained identities.
const std = @import("std");
const u = @import("common.zig");

pub const ZigEnvironment = struct { version: []const u8, lib_dir: []const u8, target: []const u8 };

pub fn zigEnvironment(c: *u.Context, zig: []const u8) !ZigEnvironment {
    var diagnostics: std.zon.parse.Diagnostics = undefined;
    return std.zon.parse.fromSlice(ZigEnvironment, .{
        .gpa = c.gpa,
        .arena = c.a,
        .source = try c.a.dupeSentinel(u8, try c.capture(&.{ zig, "env" }), 0),
        .diagnostics = &diagnostics,
        .ignore_unknown_fields = true,
    });
}

pub fn libraryIdentity(c: *u.Context, root: []const u8) !u.Value {
    var directory = try std.Io.Dir.cwd().openDir(c.io, root, .{ .iterate = true });
    defer directory.close(c.io);
    var walker = try directory.walk(c.a);
    defer walker.deinit();
    var paths: std.ArrayList([]const u8) = .empty;
    while (try walker.next(c.io)) |entry| switch (entry.kind) {
        .directory => {},
        .file => try paths.append(c.a, try c.a.dupe(u8, entry.path)),
        else => return error.UnsupportedZigLibraryFileType,
    };
    if (paths.items.len == 0) return error.EmptyZigLibrary;
    std.mem.sort([]const u8, paths.items, {}, struct {
        fn less(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.less);
    var hash = std.crypto.hash.sha2.Sha256.init(.{});
    for (paths.items) |path| {
        hash.update(path);
        hash.update("\x00");
        hash.update(try c.digest(try c.join(&.{ root, path })));
        hash.update("\x00");
    }
    return u.toValue(c.a, .{ .path = root, .files = paths.items.len, .sha256 = std.fmt.bytesToHex(hash.finalResult(), .lower) });
}

pub const Consumer = enum { program, upstream_c, input_program };
pub const Selection = struct {
    zllvm: []const u8,
    emitter: []const u8,
    source: []const u8,

    pub fn command(s: Selection, a: std.mem.Allocator, consumer: Consumer, output: []const u8, extra: []const []const u8) ![][]const u8 {
        const script = switch (consumer) {
            .program => "tools/run_real_program.zig",
            .upstream_c => "tools/run_upstream_c_program.zig",
            .input_program => "tools/run_input_program.zig",
        };
        return std.mem.concat(a, []const u8, &.{
            &.{ "zig", "run", script, "--", "--output-root", output, "--zllvm", s.zllvm, "--zig-emitter", s.emitter },
            if (consumer == .input_program) &.{} else &.{ "--zig-source", s.source },
            extra,
        });
    }
};

/// A receipt describes the binary that was built, never the current checkout by
/// inference. Ordinary caller-supplied binaries remain usable without a receipt.
pub fn compilerBuild(c: *u.Context, compiler: []const u8) !u.Value {
    var receipt_path = try c.fmt("{s}.build.json", .{compiler});
    if (!u.exists(c.io, receipt_path)) {
        const resolved = try std.Io.Dir.cwd().realPathFileAlloc(c.io, compiler, c.a);
        receipt_path = try c.fmt("{s}.build.json", .{resolved});
        if (!u.exists(c.io, receipt_path)) return u.toValue(c.a, .{ .status = "unrecorded", .receipt = @as(?[]const u8, null) });
    }
    const receipt = try c.load(receipt_path);
    if (!u.json.is(try u.get(receipt, "schema"), "zllvm-compiler-build-v1") or
        !std.mem.eql(u8, try u.str(receipt, "compiler_sha256"), try c.digest(compiler))) return error.CompilerBuildReceiptMismatch;
    return u.toValue(c.a, .{ .status = "recorded", .receipt = receipt_path, .receipt_sha256 = try c.digest(receipt_path), .identity = receipt });
}

pub fn record(c: *u.Context, compiler: []const u8, emitter: []const u8, source: []const u8) !u.Value {
    return u.toValue(c.a, .{
        .zllvm = try c.join(&.{compiler}),
        .zllvm_resolved = try std.Io.Dir.cwd().realPathFileAlloc(c.io, compiler, c.a),
        .zllvm_sha256 = try c.digest(compiler),
        .compiler_build = try compilerBuild(c, compiler),
        .zig_emitter = try c.join(&.{emitter}),
        .zig_emitter_resolved = try std.Io.Dir.cwd().realPathFileAlloc(c.io, emitter, c.a),
        .zig_emitter_sha256 = try c.digest(emitter),
        .zig_source = try c.join(&.{source}),
        .zig_source_resolved = try std.Io.Dir.cwd().realPathFileAlloc(c.io, source, c.a),
        .zig_revision = u.trim(try c.capture(&.{ "git", "-C", source, "rev-parse", "HEAD" })),
        .zig_pin = u.trim(try c.read(try c.join(&.{"docs/evidence/ziglang_pin.txt"}))),
    });
}

pub fn verify(c: *u.Context, before: u.Value) !void {
    if (!u.json.eql(before, try record(c, try u.str(before, "zllvm"), try u.str(before, "zig_emitter"), try u.str(before, "zig_source")))) return error.SelectedToolchainChanged;
}
