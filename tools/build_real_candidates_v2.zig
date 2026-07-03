const std = @import("std");
const common = @import("tool_common.zig");

const selector_version = "real-candidate-selector-v2";
const usage =
    \\usage: zig run tools/build_real_candidates_v2.zig -- --base=docs/evidence/real_candidates_releasefast_v1.tsv --out=docs/evidence/real_candidates_release_v2.tsv --releasefast-air=PATH --releasesafe-air=PATH --releasesmall-air=PATH [--migration-note=TEXT]
    \\
    \\Builds a mode-stable real-row candidate denominator by filtering the v1
    \\ReleaseFast candidate list to functions present in all three release AIR
    \\descriptors with leaf claims that hold in all modes, then re-ranks the
    \\surviving rows.
    \\
;

const Options = struct {
    base_path: []const u8,
    out_path: []const u8,
    releasefast_air_path: []const u8,
    releasesafe_air_path: []const u8,
    releasesmall_air_path: []const u8,
    migration_note: []const u8,
};

const Candidate = struct {
    source: []const u8,
    function: []const u8,
    instruction_count: []const u8,
    signature_class: []const u8,
    call_class: []const u8,
    global_refs: []const u8,
    runtime_refs: []const u8,
    determinism: []const u8,
    harnessable_reason: []const u8,
};

const FunctionInfo = struct {
    has_call: bool,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const options = try parseArgs(allocator, io, init);

    const base = try std.Io.Dir.cwd().readFileAlloc(io, options.base_path, allocator, .limited(64 * 1024 * 1024));
    defer allocator.free(base);

    var releasefast_functions = try readFunctionInfoMap(allocator, io, options.releasefast_air_path);
    defer deinitFunctionInfoMap(allocator, &releasefast_functions);
    var releasesafe_functions = try readFunctionInfoMap(allocator, io, options.releasesafe_air_path);
    defer deinitFunctionInfoMap(allocator, &releasesafe_functions);
    var releasesmall_functions = try readFunctionInfoMap(allocator, io, options.releasesmall_air_path);
    defer deinitFunctionInfoMap(allocator, &releasesmall_functions);

    var candidates: std.ArrayList(Candidate) = .empty;
    defer candidates.deinit(allocator);
    var old_rows: usize = 0;
    var removed_mode_unstable: usize = 0;
    var removed_leaf_unstable: usize = 0;
    var first_removed: ?Candidate = null;
    var first_removed_leaf: ?Candidate = null;

    var line_iter = std.mem.splitScalar(u8, base, '\n');
    const header = std.mem.trimEnd(u8, line_iter.next() orelse return error.EmptyCandidateFile, "\r");
    if (!std.mem.eql(u8, header, "rank\tsource\tfunction\tinstruction_count\tsignature_class\tcall_class\tglobal_refs\truntime_refs\tdeterminism\tharnessable_reason")) {
        return error.InvalidCandidateHeader;
    }
    while (line_iter.next()) |raw_line| {
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        if (line.len == 0) continue;
        old_rows += 1;
        const candidate = try parseCandidateLine(line);
        const releasefast_info = releasefast_functions.get(candidate.function) orelse {
            removed_mode_unstable += 1;
            if (first_removed == null) first_removed = candidate;
            continue;
        };
        const releasesafe_info = releasesafe_functions.get(candidate.function) orelse {
            removed_mode_unstable += 1;
            if (first_removed == null) first_removed = candidate;
            continue;
        };
        const releasesmall_info = releasesmall_functions.get(candidate.function) orelse {
            removed_mode_unstable += 1;
            if (first_removed == null) first_removed = candidate;
            continue;
        };
        if (std.mem.eql(u8, candidate.call_class, "leaf") and
            (releasefast_info.has_call or releasesafe_info.has_call or releasesmall_info.has_call))
        {
            removed_leaf_unstable += 1;
            if (first_removed_leaf == null) first_removed_leaf = candidate;
            continue;
        }
        try candidates.append(allocator, candidate);
    }

    var harnessable_rows: usize = 0;
    var not_yet_analyzed_rows: usize = 0;
    var proven_unharnessable_rows: usize = 0;
    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();
    const writer = &output.writer;
    try writer.writeAll("rank\tsource\tfunction\tinstruction_count\tsignature_class\tcall_class\tglobal_refs\truntime_refs\tdeterminism\tharnessable_reason\n");
    for (candidates.items, 1..) |candidate, rank| {
        if (std.mem.startsWith(u8, candidate.harnessable_reason, "harnessable:")) harnessable_rows += 1;
        if (std.mem.startsWith(u8, candidate.harnessable_reason, "not_yet_analyzed:")) not_yet_analyzed_rows += 1;
        if (std.mem.startsWith(u8, candidate.harnessable_reason, "proven_unharnessable:")) proven_unharnessable_rows += 1;
        try writer.print(
            "{}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\n",
            .{
                rank,
                candidate.source,
                candidate.function,
                candidate.instruction_count,
                candidate.signature_class,
                candidate.call_class,
                candidate.global_refs,
                candidate.runtime_refs,
                candidate.determinism,
                candidate.harnessable_reason,
            },
        );
    }

    var cwd = std.Io.Dir.cwd();
    if (std.fs.path.dirname(options.out_path)) |dirname| try cwd.createDirPath(io, dirname);
    try cwd.writeFile(io, .{ .sub_path = options.out_path, .data = output.written() });

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print(
        "summary distribution-real-candidates selector_version={s} base={s} path={s} old_rows={} rows={} harnessable_rows={} not_yet_analyzed_rows={} proven_unharnessable_rows={} removed_mode_unstable={} removed_leaf_unstable={} first_removed_mode_unstable={s}/{s} first_removed_leaf_unstable={s}/{s} migration_note=\"{s}\" local_fail=0\n",
        .{
            selector_version,
            options.base_path,
            options.out_path,
            old_rows,
            candidates.items.len,
            harnessable_rows,
            not_yet_analyzed_rows,
            proven_unharnessable_rows,
            removed_mode_unstable,
            removed_leaf_unstable,
            if (first_removed) |candidate| candidate.source else "-",
            if (first_removed) |candidate| candidate.function else "-",
            if (first_removed_leaf) |candidate| candidate.source else "-",
            if (first_removed_leaf) |candidate| candidate.function else "-",
            options.migration_note,
        },
    );
    try stdout_writer.interface.flush();
}

fn parseArgs(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Options {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var base_path: ?[]const u8 = null;
    var out_path: ?[]const u8 = null;
    var releasefast_air_path: ?[]const u8 = null;
    var releasesafe_air_path: ?[]const u8 = null;
    var releasesmall_air_path: ?[]const u8 = null;
    var migration_note: []const u8 = "n/a";

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [1024]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll(usage);
            try stdout_writer.interface.flush();
            std.process.exit(0);
        } else if (std.mem.startsWith(u8, arg, "--base=")) {
            base_path = arg["--base=".len..];
        } else if (std.mem.startsWith(u8, arg, "--out=")) {
            out_path = arg["--out=".len..];
        } else if (std.mem.startsWith(u8, arg, "--releasefast-air=")) {
            releasefast_air_path = arg["--releasefast-air=".len..];
        } else if (std.mem.startsWith(u8, arg, "--releasesafe-air=")) {
            releasesafe_air_path = arg["--releasesafe-air=".len..];
        } else if (std.mem.startsWith(u8, arg, "--releasesmall-air=")) {
            releasesmall_air_path = arg["--releasesmall-air=".len..];
        } else if (std.mem.startsWith(u8, arg, "--migration-note=")) {
            migration_note = arg["--migration-note=".len..];
        } else {
            try common.validationError(io, "unexpected argument: {s}\n{s}", .{ arg, usage });
        }
    }

    return .{
        .base_path = base_path orelse try common.validationError(io, "missing --base\n{s}", .{usage}),
        .out_path = out_path orelse try common.validationError(io, "missing --out\n{s}", .{usage}),
        .releasefast_air_path = releasefast_air_path orelse try common.validationError(io, "missing --releasefast-air\n{s}", .{usage}),
        .releasesafe_air_path = releasesafe_air_path orelse try common.validationError(io, "missing --releasesafe-air\n{s}", .{usage}),
        .releasesmall_air_path = releasesmall_air_path orelse try common.validationError(io, "missing --releasesmall-air\n{s}", .{usage}),
        .migration_note = migration_note,
    };
}

fn parseCandidateLine(line: []const u8) !Candidate {
    var fields = std.mem.splitScalar(u8, line, '\t');
    _ = fields.next() orelse return error.InvalidCandidateRow;
    const source = fields.next() orelse return error.InvalidCandidateRow;
    const function = fields.next() orelse return error.InvalidCandidateRow;
    const instruction_count = fields.next() orelse return error.InvalidCandidateRow;
    const signature_class = fields.next() orelse return error.InvalidCandidateRow;
    const call_class = fields.next() orelse return error.InvalidCandidateRow;
    const global_refs = fields.next() orelse return error.InvalidCandidateRow;
    const runtime_refs = fields.next() orelse return error.InvalidCandidateRow;
    const determinism = fields.next() orelse return error.InvalidCandidateRow;
    const harnessable_reason = fields.next() orelse return error.InvalidCandidateRow;
    if (fields.next() != null) return error.InvalidCandidateRow;
    return .{
        .source = source,
        .function = function,
        .instruction_count = instruction_count,
        .signature_class = signature_class,
        .call_class = call_class,
        .global_refs = global_refs,
        .runtime_refs = runtime_refs,
        .determinism = determinism,
        .harnessable_reason = harnessable_reason,
    };
}

fn readFunctionInfoMap(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
) !std.StringHashMap(FunctionInfo) {
    const descriptor = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(2 * 1024 * 1024 * 1024));
    defer allocator.free(descriptor);
    var functions = std.StringHashMap(FunctionInfo).init(allocator);
    errdefer deinitFunctionInfoMap(allocator, &functions);

    var search_start: usize = 0;
    while (std.mem.indexOfPos(u8, descriptor, search_start, "function_begin\n")) |frame_start| {
        const name_line_start = frame_start + "function_begin\n".len;
        const name_line_end = std.mem.indexOfScalarPos(u8, descriptor, name_line_start, '\n') orelse return error.InvalidAirFrame;
        const name_len = try parseValueLine(usize, descriptor[name_line_start..name_line_end], "name_bytes");
        const name_start = name_line_end + 1;
        const name_end = name_start + name_len;
        if (name_end >= descriptor.len) return error.InvalidAirFrame;
        const name = descriptor[name_start..name_end];
        const frame_marker_start = std.mem.indexOfPos(u8, descriptor, name_end, "\nfunction_end\n") orelse return error.InvalidAirFrame;
        const frame_end = frame_marker_start + "\nfunction_end\n".len;
        if (!functions.contains(name)) {
            const frame = descriptor[frame_start..frame_end];
            try functions.put(try allocator.dupe(u8, name), .{
                .has_call = std.mem.indexOf(u8, frame, "|call|") != null,
            });
        }
        search_start = frame_end;
    }
    return functions;
}

fn deinitFunctionInfoMap(allocator: std.mem.Allocator, functions: *std.StringHashMap(FunctionInfo)) void {
    var key_iter = functions.keyIterator();
    while (key_iter.next()) |key| allocator.free(key.*);
    functions.deinit();
}

fn parseValueLine(comptime T: type, line: []const u8, key: []const u8) !T {
    if (!std.mem.startsWith(u8, line, key) or line.len <= key.len or line[key.len] != '=') return error.InvalidValueLine;
    return std.fmt.parseUnsigned(T, line[key.len + 1 ..], 10);
}
