const std = @import("std");
const common = @import("tool_common.zig");

const default_metadata = "test/opt/fixtures.tsv";

const usage =
    \\usage: zig run tools/compare_opt.zig -- [fixtures.tsv]
    \\
    \\Compare local optimizer output against checked fixtures and opt-22 where required.
    \\Set OPT_BIN to override opt-22.
    \\
;

const Row = struct {
    id: []const u8,
    z_pass: []const u8,
    llvm_pass: []const u8,
    input_path: []const u8,
    expected_path: []const u8,
    fixture_kind: []const u8,
    inventory_passes: []const u8,
    notes: []const u8,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const metadata_arg = try parseMetadataArg(allocator, io, init);
    defer if (metadata_arg.owned) allocator.free(metadata_arg.path);

    const opt_bin = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "OPT_BIN");
    defer if (opt_bin) |value| allocator.free(value);

    const temp = try common.TempDir.init(allocator, io, "compare_opt");
    defer temp.deinit(allocator, io);

    var cwd = std.Io.Dir.cwd();
    const contents = cwd.readFileAlloc(io, metadata_arg.path, allocator, .limited(64 * 1024 * 1024)) catch |err| {
        try common.validationError(io, "{s}: {s}\n", .{ metadata_arg.path, @errorName(err) });
    };
    defer allocator.free(contents);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        if (line.len == 0) continue;
        if (line[0] == '#') continue;

        const row = parseRow(line) orelse {
            try common.validationError(io, "{s}: invalid fixture row: {s}\n", .{ metadata_arg.path, line });
        };

        try runRow(allocator, io, temp, row, opt_bin orelse "opt-22");
        try stdout_writer.interface.print("ok {s} [{s}: {s}] ({s})\n", .{
            row.id,
            row.fixture_kind,
            row.inventory_passes,
            row.notes,
        });
        try stdout_writer.interface.flush();
    }
}

const PathArg = struct {
    path: []const u8,
    owned: bool = false,
};

fn parseMetadataArg(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !PathArg {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    const first = args.next() orelse return .{ .path = default_metadata };
    if (std.mem.eql(u8, first, "--help") or std.mem.eql(u8, first, "-h")) {
        var stdout_buffer: [512]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
        try stdout_writer.interface.writeAll(usage);
        try stdout_writer.interface.flush();
        std.process.exit(0);
    }
    if (args.next()) |extra| {
        try common.validationError(io, "unexpected argument: {s}\n{s}", .{ extra, usage });
    }
    return .{ .path = try allocator.dupe(u8, first), .owned = true };
}

fn parseRow(line: []const u8) ?Row {
    var fields: [8][]const u8 = undefined;
    var rest = line;
    var index: usize = 0;
    while (index + 1 < fields.len) : (index += 1) {
        const split = std.mem.indexOfScalar(u8, rest, '\t') orelse return null;
        fields[index] = rest[0..split];
        rest = rest[split + 1 ..];
    }
    fields[index] = rest;
    if (fields[0].len == 0) return null;
    return .{
        .id = fields[0],
        .z_pass = fields[1],
        .llvm_pass = fields[2],
        .input_path = fields[3],
        .expected_path = fields[4],
        .fixture_kind = fields[5],
        .inventory_passes = fields[6],
        .notes = fields[7],
    };
}

fn runRow(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    row: Row,
    opt_bin: []const u8,
) !void {
    const z_raw = try common.allocTempFile(allocator, temp, row.id, ".z.raw.ll");
    defer allocator.free(z_raw);
    const z_norm = try common.allocTempFile(allocator, temp, row.id, ".z.norm.ll");
    defer allocator.free(z_norm);
    const expected_norm = try common.allocTempFile(allocator, temp, row.id, ".expected.norm.ll");
    defer allocator.free(expected_norm);

    const z_pass_arg = try std.fmt.allocPrint(allocator, "--passes={s}", .{row.z_pass});
    defer allocator.free(z_pass_arg);
    const z_argv = [_][]const u8{ "zig", "build", "run", "--", z_pass_arg, row.input_path };
    try common.runToFile(allocator, io, &z_argv, "zig build run", z_raw);

    try common.normalizeToFile(allocator, io, z_raw, z_norm);
    try common.normalizeToFile(allocator, io, row.expected_path, expected_norm);
    try common.diffFiles(allocator, io, expected_norm, z_norm);

    if (std.mem.eql(u8, row.fixture_kind, "opt-equivalent")) {
        const llvm_raw = try common.allocTempFile(allocator, temp, row.id, ".llvm.raw.ll");
        defer allocator.free(llvm_raw);
        const llvm_norm = try common.allocTempFile(allocator, temp, row.id, ".llvm.norm.ll");
        defer allocator.free(llvm_norm);
        const llvm_pass_arg = try std.fmt.allocPrint(allocator, "-passes={s}", .{row.llvm_pass});
        defer allocator.free(llvm_pass_arg);
        const llvm_argv = [_][]const u8{ opt_bin, llvm_pass_arg, row.input_path, "-S", "-o", llvm_raw };
        const llvm_result = try common.runCapture(allocator, io, &llvm_argv, opt_bin);
        common.freeRunResult(allocator, llvm_result);
        try common.normalizeToFile(allocator, io, llvm_raw, llvm_norm);
        try common.diffFiles(allocator, io, llvm_norm, z_norm);
    } else if (std.mem.eql(u8, row.fixture_kind, "local-conservative") or
        std.mem.eql(u8, row.fixture_kind, "parse-preserve-only"))
    {
        return;
    } else {
        try common.validationError(io, "unknown fixture kind for {s}: {s}\n", .{ row.id, row.fixture_kind });
    }
}
