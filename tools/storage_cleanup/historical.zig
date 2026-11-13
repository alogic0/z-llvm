//! Reconstruct historical compiler inputs from exact Git blobs or saved overrides.
const std = @import("std");
const core = @import("engine.zig");
const u = @import("../validation/common.zig");
const toolchain = @import("../validation/toolchain.zig");
const p = core.p;
pub const Library = struct { path: []const u8, sha256: []const u8, files: i64 };

fn gitSources(e: *core.Engine, revision: []const u8) !std.StringHashMap([]const u8) {
    if (e.git_sources.get(revision)) |cached| return cached;
    try e.sourceRevisions(try u.toValue(e.c.a, .{ .source_head = revision }));
    const result = try u.process.runReport(e.c.gpa, e.c.io, .{
        .spawn = .{ .argv = &.{ "git", "archive", "--format=tar", revision }, .cwd = .{ .path = e.c.root }, .environ_map = &e.c.env, .search_path = true },
        .timeout_ms = 120_000,
        .stdout_limit = 256 * 1024 * 1024,
        .stderr_limit = 1024 * 1024,
    });
    defer result.deinit(e.c.gpa);
    if (!result.success()) return error.SourceArchiveFailed;
    const bytes = result.stdout;
    var map = std.StringHashMap([]const u8).init(e.c.a);
    var offset: usize = 0;
    while (offset + 512 <= bytes.len) {
        const h = bytes[offset..][0..512];
        if (h[0] == 0) break;
        const size = try std.fmt.parseInt(usize, std.mem.trim(u8, h[124..136], " \x00"), 8);
        const start = offset + 512;
        if (size > bytes.len - start) return error.InvalidSourceArchive;
        if (h[156] == '0' or h[156] == 0) {
            const name = std.mem.sliceTo(h[0..100], 0);
            const prefix = std.mem.sliceTo(h[345..500], 0);
            const path = if (prefix.len == 0) try e.c.a.dupe(u8, name) else try e.c.fmt("{s}/{s}", .{ prefix, name });
            if (!p.relative(path) or map.contains(path)) return error.InvalidSourceArchive;
            try map.put(path, try u.digestBytes(e.c.a, bytes[start..][0..size]));
        }
        offset = start + ((size + 511) / 512) * 512;
    }
    try e.git_sources.put(try e.c.a.dupe(u8, revision), map);
    return map;
}

/// A ledger's "verified" flag is never trusted. Read every used blob/override
/// and match the SHA-256 requested by the original, authenticated build receipt.
fn source(e: *core.Engine, path: []const u8, sha: []const u8, original: std.StringHashMap([]const u8), ledgers: []const u.Value, retained: *std.ArrayList(core.Evidence)) !void {
    if (!p.relative(path) or !p.hash(sha)) return error.InvalidSourceEvidence;
    if (original.get(path)) |actual| if (std.mem.eql(u8, actual, sha)) return;
    for (ledgers) |ledger| {
        const sources = try core.get(ledger, "sources");
        if (sources != .array) return error.InvalidSourceReconstruction;
        for (sources.array.items) |binding| {
            if (!core.eq(binding, "sha256", sha)) continue;
            if (core.str(binding, "saved")) |saved| {
                if (!p.relative(saved)) return error.InvalidSourceEvidence;
                try e.keep(retained, saved, sha);
                return;
            } else |_| {}
            const revision = core.str(binding, "revision") catch continue;
            const blob = try core.str(binding, "path");
            if (!p.relative(blob)) return error.InvalidSourceEvidence;
            const hashes = try gitSources(e, revision);
            const actual = hashes.get(blob) orelse return error.ReconstructedSourceMissing;
            if (!std.mem.eql(u8, actual, sha)) return error.ReconstructedSourceMismatch;
            return;
        }
    }
    return error.SourceReconstructionMissing;
}

pub fn verifyLibraries(e: *core.Engine) !void {
    for (e.libraries.items) |library| {
        var arena = std.heap.ArenaAllocator.init(e.c.gpa);
        defer arena.deinit();
        var context = e.c.*;
        context.a = arena.allocator();
        const actual = try toolchain.libraryIdentity(&context, library.path);
        if (!core.eq(actual, "sha256", library.sha256) or try core.integer(actual, "files") != library.files) return error.ToolchainLibraryChanged;
    }
}

pub fn canonical(e: *core.Engine, report: []const u8, v: u.Value, retained: *std.ArrayList(core.Evidence), retiring: ?[]const u8, reconstructions: []const core.Evidence) !void {
    try e.keep(retained, report, null);
    const compiler = try e.relative(try core.str(v, "compiler"));
    const compiler_sha = try core.str(v, "compiler_sha256");
    try e.check(.{ .path = compiler, .sha256 = compiler_sha });
    if (retiring == null or !std.mem.eql(u8, retiring.?, compiler)) try e.keep(retained, compiler, compiler_sha);
    const command = try core.get(v, "command");
    if (!core.eq(command, "outcome", "completed") or try core.integer(command, "actual_returncode") != 0) return error.IncompleteBuildCommand;
    const argv = try core.get(command, "argv");
    if (argv != .array or argv.array.items.len < 4 or !u.json.eql(argv, try core.get(v, "argv"))) return error.MissingBuildCommand;
    const zig = try core.get(v, "zig");
    const zig_path = try core.str(zig, "path");
    if (argv.array.items[0] != .string or !std.mem.eql(u8, argv.array.items[0].string, zig_path) or argv.array.items[1] != .string or !std.mem.eql(u8, argv.array.items[1].string, "build")) return error.SourceCompilerCommandNotBound;
    var bound = false;
    for (argv.array.items, 0..) |arg, i| {
        if (arg != .string) return error.MissingBuildCommand;
        if (std.mem.eql(u8, arg.string, "--prefix")) {
            if (bound or i + 1 >= argv.array.items.len or argv.array.items[i + 1] != .string) return error.SourceCompilerCommandNotBound;
            const prefix = try e.relative(argv.array.items[i + 1].string);
            if (!std.mem.eql(u8, compiler, try e.c.fmt("{s}/bin/z_llvm", .{prefix}))) return error.SourceCompilerCommandNotBound;
            bound = true;
        }
    }
    if (!bound) return error.SourceCompilerCommandNotBound;
    try e.keep(retained, zig_path, try core.str(zig, "sha256"));
    for ([_][]const u8{ "stdout", "stderr" }) |key| try e.keep(retained, try core.str(command, key), null);
    const library = try core.get(zig, "library");
    const library_path = try core.str(library, "path");
    const library_sha = try core.str(library, "sha256");
    const library_files = try core.integer(library, "files");
    if (!p.hash(library_sha) or library_files <= 0) return error.InvalidToolchainLibrary;
    var seen = false;
    for (e.libraries.items) |old| if (std.mem.eql(u8, old.path, library_path)) {
        if (!std.mem.eql(u8, old.sha256, library_sha) or old.files != library_files) return error.ToolchainLibraryChanged;
        seen = true;
    };
    if (!seen) {
        try e.libraries.append(e.c.a, .{ .path = try e.c.a.dupe(u8, library_path), .sha256 = try e.c.a.dupe(u8, library_sha), .files = library_files });
        try verifyLibraries(e);
    }
    const original = try gitSources(e, try core.str(v, "source_head"));
    var ledger_arena = std.heap.ArenaAllocator.init(e.c.gpa);
    defer ledger_arena.deinit();
    const allocator = ledger_arena.allocator();
    var ledgers: std.ArrayList(u.Value) = .empty;
    for (reconstructions) |row| {
        if (!p.relative(row.path)) return error.InvalidEvidencePath;
        try e.keep(retained, row.path, row.sha256);
        const parsed = try e.load(allocator, row.path);
        try ledgers.append(allocator, parsed.value);
    }
    const hashes = try core.get(v, "source_sha256");
    if (hashes != .object or hashes.object.count() == 0) return error.MissingSourceEvidence;
    var it = hashes.object.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.* != .string) return error.InvalidSourceEvidence;
        try source(e, entry.key_ptr.*, entry.value_ptr.string, original, ledgers.items, retained);
    }
}
