//! Prepare only the requested compiler mode, using Zig's dependency-aware cache.
//! Receipts describe builds; they do not authorize reuse of validation results.
const std = @import("std");
const u = @import("validation/common.zig");
const provenance = @import("validation/provenance.zig");
const Runner = @import("validation/runner.zig").Runner;
const toolchain = @import("validation/toolchain.zig");

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    if (u.contains(argv[1..], "--help")) return c.print("usage: zig run tools/build_validation_compiler.zig -- --output-root DIR --mode Debug|ReleaseSafe|ReleaseFast [--zig EXE] [--target TARGET] [--cpu CPU]\n", .{});
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "mode", "zig", "target", "cpu" }, &.{});
    const mode = try args.require("mode");
    if (!u.contains(&.{ "Debug", "ReleaseSafe", "ReleaseFast" }, mode)) return error.InvalidCompilerBuildMode;
    const prefix = try c.ownedPath(try c.join(&.{ try args.require("output-root"), mode }));
    try c.mkdir(prefix);
    var directory = try @import("zllvm_artifact_store/store.zig").openDirectory(c.io, prefix, false);
    defer directory.close(c.io);
    const build_lock = try directory.createFile(c.io, "compiler-build.lock", .{ .truncate = false });
    defer build_lock.close(c.io);
    if (!try build_lock.tryLock(c.io, .exclusive)) return error.CompilerBuildBusy;
    defer build_lock.unlock(c.io);
    const alias = try c.join(&.{ prefix, "bin/z_llvm" });
    const receipt_path = try c.fmt("{s}.build.json", .{alias});
    const layout_path = try c.join(&.{ prefix, "compiler.storage-layout.json" });
    const result_path = try c.join(&.{ prefix, "report.json" });
    // Existing mixed installations remain compatible. Fresh installations keep
    // only the stable alias and receipt here; the actual compiler is temporary.
    const workspace = if (u.exists(c.io, alias) and !u.exists(c.io, layout_path)) null else try @import("validation/storage_workspace.zig").compiler(&c, prefix);
    defer if (workspace) |w| w.close(&c);
    errdefer if (workspace) |w| {
        c.writeJson(result_path, .{ .schema = "compiler-pipeline-v1", .status = "failed", .diagnostic = c.diagnostic orelse "Compiler preparation failed; inspect build.stderr and commands.json" }) catch {};
        w.finishReport(&c) catch {};
    };
    const install = if (c.workspace_paths) |mapping| mapping.temporary else prefix;
    const compiler = try c.temporaryPath(&.{ prefix, "bin/z_llvm" });
    if (workspace == null) for ([_][]const u8{ compiler, receipt_path }) |path| {
        if (!std.mem.eql(u8, path, try c.ownedPath(path))) return error.SharedCompilerInstallPath;
    };
    // A damaged installed file must not be blessed with a new receipt merely
    // because its size/mtime happen to satisfy an installation cache check.
    if (u.exists(c.io, compiler)) {
        const previous = toolchain.compilerBuild(&c, alias) catch null;
        if (previous == null or !u.json.is(try u.get(previous.?, "status"), "recorded")) try std.Io.Dir.cwd().deleteFile(c.io, compiler);
    }
    var runner = Runner.init(&c, prefix);
    var env = try c.env.clone(c.a);
    if (workspace != null) {
        if (env.get("ZIG_LOCAL_CACHE_DIR") == null) try env.put("ZIG_LOCAL_CACHE_DIR", try c.temporaryPath(&.{ prefix, "local-cache" }));
        if (env.get("ZIG_GLOBAL_CACHE_DIR") == null) try env.put("ZIG_GLOBAL_CACHE_DIR", try c.temporaryPath(&.{ prefix, "global-cache" }));
    }
    const zig = try std.Io.Dir.cwd().realPathFileAlloc(c.io, args.get("zig") orelse u.trim(try c.capture(&.{ "which", "zig" })), c.a);
    const zig_env = try toolchain.zigEnvironment(&c, zig);
    if (!std.mem.eql(u8, zig_env.version, u.trim(try c.read(try c.join(&.{".zigversion"}))))) return error.WrongProjectZigVersion;
    const compiler_sources = try provenance.files(&c, &.{ "src", "build.zig", "build.zig.zon", ".zigversion" });
    const zig_hash = try c.digest(zig);
    const library = try toolchain.libraryIdentity(&c, zig_env.lib_dir);
    const target = args.get("target") orelse "x86_64-linux-gnu";
    const cpu = args.get("cpu") orelse "baseline";
    const command = &.{ zig, "build", try c.fmt("-Doptimize={s}", .{mode}), try c.fmt("-Dtarget={s}", .{target}), try c.fmt("-Dcpu={s}", .{cpu}), "-Dstrip=false", "-Domit-frame-pointer=false", "--prefix", install };
    const result = try runner.run(command, try c.join(&.{ prefix, "build" }), &env, .{ .timeout_ms = 900_000 });
    if (!result.completed or result.code != 0) return c.fail("compiler build failed; see {s}/build.stderr and commands.json", .{prefix});
    if (!u.json.eql(compiler_sources, try provenance.files(&c, &.{ "src", "build.zig", "build.zig.zon", ".zigversion" })) or
        !std.mem.eql(u8, zig_hash, try c.digest(zig)) or !u.json.eql(library, try toolchain.libraryIdentity(&c, zig_env.lib_dir))) return error.CompilerBuildInputsChanged;
    var environment = u.object(c.a);
    for ([_][]const u8{ "ZIG_LIB_DIR", "ZIG_LIBC", "ZIG_LOCAL_CACHE_DIR", "ZIG_GLOBAL_CACHE_DIR", "CC", "C_INCLUDE_PATH", "CPLUS_INCLUDE_PATH", "LIBRARY_PATH", "NIX_CFLAGS_COMPILE", "NIX_CFLAGS_LINK", "NIX_LDFLAGS" }) |key| {
        if (env.get(key)) |value| try u.put(c.a, &environment, key, u.s(value));
    }
    const receipt = try u.toValue(c.a, .{
        .schema = "zllvm-compiler-build-v1",
        .compiler_sha256 = try c.digest(compiler),
        .compiler = alias,
        .build_mode = mode,
        .target = target,
        .cpu = cpu,
        .strip = false,
        .omit_frame_pointer = false,
        .argv = command,
        .source_head = u.trim(try c.capture(&.{ "git", "rev-parse", "HEAD" })),
        .source_sha256 = compiler_sources,
        .zig = .{ .path = zig, .sha256 = zig_hash, .version = zig_env.version, .host_target = zig_env.target, .library = library },
        .environment = environment,
        .cache_policy = "Zig validates build dependencies and artifacts; no validation result reuse is implied",
        .command = runner.commands.array.items[0],
    });
    var unchanged = false;
    if (u.exists(c.io, receipt_path)) {
        const previous = c.load(receipt_path) catch .null;
        if (previous == .object) {
            unchanged = true;
            for ([_][]const u8{ "schema", "compiler_sha256", "compiler", "build_mode", "target", "cpu", "strip", "omit_frame_pointer", "argv", "source_sha256", "zig", "environment" }) |key| {
                if (!u.json.eql(previous.object.get(key) orelse .null, try u.get(receipt, key))) unchanged = false;
            }
        }
    }
    // Preserve the original producer identity across an unchanged cached build.
    // The latest build command remains separately recorded in commands.json.
    if (workspace != null) {
        var bin = try @import("zllvm_artifact_store/store.zig").openDirectory(c.io, std.fs.path.dirname(alias).?, true);
        defer bin.close(c.io);
        // Do not replace an unrelated install or a link changed by a reader.
        bin.symLink(c.io, compiler, "z_llvm", .{}) catch |err| switch (err) {
            error.PathAlreadyExists => {
                if (!std.mem.eql(u8, compiler, try std.Io.Dir.cwd().realPathFileAlloc(c.io, alias, c.a))) return error.SharedCompilerInstallPath;
            },
            else => return err,
        };
    }
    if (!unchanged) try c.writeJson(receipt_path, receipt);
    if (workspace) |w| {
        try c.writeJson(try c.join(&.{ prefix, "report.json" }), .{ .schema = "compiler-pipeline-v1", .status = "passed", .compiler = alias, .receipt = receipt_path, .compiler_sha256 = try c.digest(compiler) });
        try w.finish(&c, try c.join(&.{ prefix, "report.json" }), &.{ receipt_path, try c.join(&.{ prefix, "commands.json" }) });
    }
    try c.print("compiler mode={s} target={s} cpu={s} path={s} sha256={s}\n", .{ mode, target, cpu, alias, try c.digest(compiler) });
}
