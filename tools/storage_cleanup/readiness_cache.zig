//! One fixed legacy readiness-launcher template, never a shell interpreter.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
pub const Launcher = struct {
    script: p.Evidence,
    source_snapshot: p.Evidence,
    compiler: []const u8,
    zig_source_directory: []const u8,
    zig_emitter: []const u8,
};
fn literal(path: []const u8) bool {
    if (path.len == 0) return false;
    for (path) |ch| if (!std.ascii.isAlphanumeric(ch) and std.mem.indexOfScalar(u8, "_./-", ch) == null) return false;
    return if (path[0] == '/') p.relative(path[1..]) else p.relative(path);
}
pub fn script(e: *core.Engine, cache: []const u8, binding: Launcher) ![]const u8 {
    const prefix = "readiness-zig-local-";
    const root = std.fs.path.dirname(cache) orelse return error.InvalidReadinessCache;
    const name = std.fs.path.basename(cache);
    if (!p.candidate(cache) or !std.mem.startsWith(u8, name, prefix) or name.len == prefix.len) return error.InvalidReadinessCache;
    for ([_][]const u8{ cache, binding.script.path, binding.source_snapshot.path, binding.compiler, binding.zig_source_directory, binding.zig_emitter }) |path| if (!literal(path)) return error.InvalidReadinessCache;
    if (!std.mem.eql(u8, std.fs.path.dirname(binding.script.path) orelse "", root) or
        !std.mem.eql(u8, std.fs.path.dirname(binding.source_snapshot.path) orelse "", root) or
        !p.within(root, binding.compiler) or !std.mem.eql(u8, std.fs.path.basename(binding.compiler), "z_llvm") or
        !std.fs.path.isAbsolute(binding.zig_source_directory) or !std.fs.path.isAbsolute(binding.zig_emitter)) return error.InvalidReadinessCache;
    const tag = name[prefix.len..];
    return e.c.fmt(
        "#!/usr/bin/env bash\nset -euo pipefail\nproof_root={s}\n" ++
            "zig run tools/validation_snapshot.zig -- --verify \"$proof_root/{s}\"\n" ++
            "export ZLLVM_PROJECT_ROOT=\"$PWD\"\n" ++
            "export ZLLVM_EXE=\"$PWD/$proof_root/{s}\"\n" ++
            "export ZIG_SOURCE_DIR={s}\nexport ZIG_EMITTER={s}\n" ++
            "export ZIG_LOCAL_CACHE_DIR=\"$PWD/$proof_root/readiness-zig-local-{s}\"\n" ++
            "export ZIG_GLOBAL_CACHE_DIR=\"$PWD/$proof_root/readiness-zig-global-{s}\"\n" ++
            "for proof_tool in compare_opt run_optimizer_correctness lint_zig_ir_manifest run_zig_corpus run_handoff_validation run_generated_scalar_diff; do\n" ++
            " zig run tools/run_checked.zig -- --output-root \"$proof_root/readiness-{s}\" \"$proof_tool\" -- zig run \"tools/$proof_tool.zig\"\n" ++
            "done\n" ++
            "zig run tools/run_checked.zig -- --output-root \"$proof_root/readiness-{s}\" release-pipeline-policy -- zig build release-pipeline-policy\n" ++
            "zig run tools/run_checked.zig -- --output-root \"$proof_root/readiness-{s}\" abi-differential -- bash tools/run_abi_differential.sh \"$proof_root/readiness-abi-{s}\"\n" ++
            "zig run tools/validation_snapshot.zig -- --verify \"$proof_root/{s}\"\n",
        .{ root, std.fs.path.basename(binding.source_snapshot.path), binding.compiler[root.len + 1 ..], binding.zig_source_directory, binding.zig_emitter, tag, tag, tag, tag, tag, tag, std.fs.path.basename(binding.source_snapshot.path) },
    );
}
pub fn verify(e: *core.Engine, cache: []const u8, receipt: p.Evidence, binding: Launcher, kept: *std.ArrayList(p.Evidence)) !void {
    const expected = try script(e, cache, binding);
    try e.check(binding.script);
    const actual = try e.read(e.c.gpa, binding.script.path, 64 * 1024);
    defer e.c.gpa.free(actual);
    if (!std.mem.eql(u8, expected, actual)) return error.UnsupportedReadinessLauncher;
    try e.check(receipt);
    var parsed = try e.load(e.c.gpa, receipt.path);
    defer parsed.deinit();
    const v = parsed.value;
    if (!std.mem.eql(u8, std.fs.path.dirname(receipt.path) orelse "", std.fs.path.dirname(cache).?) or
        !core.eq(v, "status", "finished") or !core.eq(v, "outcome", "completed") or
        try core.integer(v, "actual_returncode") != 0 or try core.integer(v, "returncode") != 0 or
        try core.integer(v, "finished_ns") <= try core.integer(v, "started_ns")) return error.ReadinessNotClosed;
    if (core.has(v, "cwd", .string) and !core.eq(v, "cwd", e.c.root)) return error.ReadinessWorkingDirectoryMismatch;
    const argv = try core.get(v, "argv");
    if (argv != .array or argv.array.items.len != 2 or argv.array.items[0] != .string or argv.array.items[1] != .string or
        !std.mem.eql(u8, argv.array.items[0].string, "bash") or
        !std.mem.eql(u8, try e.relative(argv.array.items[1].string), binding.script.path)) return error.UnboundReadinessLauncher;
    for ([_]p.Evidence{ receipt, binding.script, binding.source_snapshot }) |row| {
        try e.keep(kept, row.path, row.sha256);
        try e.addControl(row.path);
    }
}
