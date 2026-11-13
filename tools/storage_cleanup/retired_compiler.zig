//! Original compiler identity authenticated by a completed guarded retirement.
const std = @import("std");
const core = @import("engine.zig");
const u = @import("../validation/common.zig");
const p = core.p;

pub const Proof = struct { compiler: p.Evidence, build: p.Evidence };

pub fn absent(e: *core.Engine, path: []const u8) !void {
    _ = e.metadata(path) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    return error.RetiredCompilerReappeared;
}

fn binding(v: u.Value, path: []const u8, sha: []const u8) bool {
    return core.eq(v, "path", path) and core.eq(v, "sha256", sha);
}

/// The record must describe this exact completed compiler deletion and retain
/// both its owner request and original build receipt by hash. No generic
/// "verified" flag or merely absent executable substitutes for that chain.
pub fn verify(e: *core.Engine, record: p.Evidence, retained: *std.ArrayList(core.Evidence)) !Proof {
    if (!p.relative(record.path) or !p.within("local-state/retirements/automatic-storage-cleanup", record.path) or
        !std.mem.startsWith(u8, std.fs.path.basename(record.path), "record-") or !std.mem.endsWith(u8, record.path, ".json")) return error.UnsupportedCompilerRetirement;
    try e.keep(retained, record.path, record.sha256);
    var parsed = try e.load(e.c.gpa, record.path);
    defer parsed.deinit();
    const v = parsed.value;
    const action = try core.get(v, "action");
    if (!core.eq(v, "status", "complete") or !core.eq(action, "status", "removed") or !core.eq(action, "kind", "build_output")) return error.IncompleteCompilerRetirement;
    const compiler = try core.str(action, "path");
    const sha = try core.str(action, "sha256");
    if (!p.artifactName(.{ .path = compiler, .sha256 = sha, .kind = .build_output })) return error.InvalidRetiredCompiler;
    const metadata = try core.get(action, "metadata");
    if (!core.eq(metadata, "kind", "file") or try core.integer(metadata, "links") != 1 or
        try core.integer(metadata, "uid") != std.os.linux.getuid()) return error.InvalidRetiredCompiler;
    const allocated = try core.integer(action, "allocated_bytes");
    if (allocated <= 0 or try core.integer(action, "reclaimed_file_bytes") != allocated or try core.integer(metadata, "allocated_bytes") != allocated) return error.IncompleteCompilerRetirement;
    try absent(e, compiler);

    const rows = try core.get(v, "retained");
    if (rows != .array or !u.json.eql(rows, try core.get(action, "retained"))) return error.UnboundCompilerRetirement;
    const request_path = try core.str(action, "producer");
    if (!p.relative(request_path)) return error.InvalidEvidencePath;
    var request_sha: ?[]const u8 = null;
    for (rows.array.items) |row| if (core.eq(row, "path", request_path)) {
        request_sha = try core.str(row, "sha256");
        break;
    };
    try e.keep(retained, request_path, request_sha orelse return error.UnboundCompilerRetirement);
    var request_json = try e.load(e.c.gpa, request_path);
    defer request_json.deinit();
    var request = try std.json.parseFromValue(p.Release, e.c.gpa, request_json.value, .{});
    defer request.deinit();
    const owner = request.value;
    if (!std.mem.eql(u8, owner.schema, "zllvm-storage-release-v1") or owner.state != .disposable or
        !p.candidate(owner.run_root) or !p.within(owner.run_root, compiler) or !p.within(owner.run_root, owner.producer.path)) return error.UnboundCompilerRetirement;
    var artifact_bound = false;
    for (owner.artifacts) |artifact| if (artifact.kind == .build_output and std.mem.eql(u8, artifact.path, compiler) and std.mem.eql(u8, artifact.sha256, sha)) {
        artifact_bound = true;
        break;
    };
    var build_bound = false;
    for (rows.array.items) |row| if (binding(row, owner.producer.path, owner.producer.sha256)) {
        build_bound = true;
        break;
    };
    if (!artifact_bound or !build_bound or !p.relative(owner.producer.path)) return error.UnboundCompilerRetirement;
    try e.keep(retained, owner.producer.path, owner.producer.sha256);
    var build = try e.load(e.c.gpa, owner.producer.path);
    defer build.deinit();
    if (!std.mem.eql(u8, compiler, try e.relative(try core.str(build.value, "compiler"))) or !core.eq(build.value, "compiler_sha256", sha)) return error.RetiredCompilerBuildMismatch;
    return .{
        .compiler = .{ .path = try e.c.a.dupe(u8, compiler), .sha256 = try e.c.a.dupe(u8, sha) },
        .build = .{ .path = try e.c.a.dupe(u8, owner.producer.path), .sha256 = try e.c.a.dupe(u8, owner.producer.sha256) },
    };
}

pub fn bind(e: *core.Engine, proof: Proof, report: []const u8, compiler: []const u8, sha: []const u8) !void {
    if (!std.mem.eql(u8, proof.build.path, report) or !std.mem.eql(u8, proof.compiler.path, compiler) or
        !std.mem.eql(u8, proof.compiler.sha256, sha)) return error.RetiredCompilerBuildMismatch;
    try e.check(proof.build);
    try absent(e, compiler);
}
