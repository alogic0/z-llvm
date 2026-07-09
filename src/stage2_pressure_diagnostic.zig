const std = @import("std");
const ir = @import("ir.zig");
const selector = @import("codegen/x86_64/generic_cfg_selector.zig");

const usage =
    \\usage: zig run src/stage2_pressure_diagnostic.zig -- --input=PATH --function=TEXT [--out=docs/evidence/NAME.tsv]
    \\
    \\Writes one TSV row with the generic-CFG selector stage-two pressure numbers
    \\for the selected function. TEXT must match exactly one function name or
    \\function-name substring.
    \\
;

const Options = struct {
    input_path: []const u8,
    function: []const u8,
    out_path: ?[]const u8,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const options = try parseArgs(allocator, io, init);

    const input = try std.Io.Dir.cwd().readFileAlloc(io, options.input_path, allocator, .limited(2 * 1024 * 1024 * 1024));
    defer allocator.free(input);

    var module = try ir.Module.parse(allocator, input);
    defer module.deinit();

    const function = try findOneFunction(io, module, options.function);
    const summary = try selector.analyzeStageTwoNoSpillEnvelope(allocator, function);

    var output: std.ArrayList(u8) = .empty;
    defer output.deinit(allocator);
    try appendTsv(
        allocator,
        &output,
        "record\tfunction\tblocks\tedges\tno_spill_limit\tspill_slot_count\tspill_envelope_limit\tmax_live_values\tmax_block\tmax_boundary\tmax_spill_slots_needed\tmax_spill_slots_over_envelope\tfirst_exceed_block\tfirst_exceed_boundary\tfirst_exceed_live_values\tfirst_exceed_spill_slots_needed\tfirst_exceed_spill_slots_over_envelope\n",
        .{},
    );
    try appendTsv(
        allocator,
        &output,
        "stage2-pressure\t{s}\t{}\t{}\t{}\t{}\t{}\t{}\t{s}\t{s}\t{}\t{}\t{s}\t{s}\t{}\t{}\t{}\n",
        .{
            function.name,
            summary.blocks,
            summary.edges,
            summary.no_spill_limit,
            summary.spill_slot_count,
            summary.spill_envelope_limit,
            summary.max_pressure,
            summary.max_pressure_block,
            summary.max_pressure_boundary,
            summary.max_pressure_spill_slots_needed,
            summary.max_pressure_spill_slots_over_envelope,
            summary.first_exceeding_block,
            summary.first_exceeding_boundary,
            summary.first_exceeding_live_values,
            summary.first_exceeding_spill_slots_needed,
            summary.first_exceeding_spill_slots_over_envelope,
        },
    );

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.writeAll(output.items);
    try stdout_writer.interface.print(
        "summary stage2-pressure-diagnostic function={s} blocks={} edges={} no_spill_limit={} spill_slot_count={} spill_envelope_limit={} max_live_values={} max_block={s} max_boundary={s} max_spill_slots_needed={} max_spill_slots_over_envelope={} first_exceed_block={s} first_exceed_boundary={s} first_exceed_live_values={} first_exceed_spill_slots_needed={} first_exceed_spill_slots_over_envelope={} local_fail=0\n",
        .{
            function.name,
            summary.blocks,
            summary.edges,
            summary.no_spill_limit,
            summary.spill_slot_count,
            summary.spill_envelope_limit,
            summary.max_pressure,
            summary.max_pressure_block,
            summary.max_pressure_boundary,
            summary.max_pressure_spill_slots_needed,
            summary.max_pressure_spill_slots_over_envelope,
            summary.first_exceeding_block,
            summary.first_exceeding_boundary,
            summary.first_exceeding_live_values,
            summary.first_exceeding_spill_slots_needed,
            summary.first_exceeding_spill_slots_over_envelope,
        },
    );
    try stdout_writer.interface.flush();

    if (options.out_path) |out_path| {
        if (!std.mem.startsWith(u8, out_path, "docs/evidence/") or !std.mem.endsWith(u8, out_path, ".tsv")) {
            return validationError(io, "--out must be a docs/evidence/*.tsv path: {s}\n", .{out_path});
        }
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = out_path, .data = output.items });
    }
}

fn parseArgs(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Options {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var input_path: ?[]const u8 = null;
    var function: ?[]const u8 = null;
    var out_path: ?[]const u8 = null;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [4096]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll(usage);
            try stdout_writer.interface.flush();
            std.process.exit(0);
        } else if (std.mem.startsWith(u8, arg, "--input=")) {
            input_path = arg["--input=".len..];
        } else if (std.mem.startsWith(u8, arg, "--function=")) {
            function = arg["--function=".len..];
        } else if (std.mem.startsWith(u8, arg, "--out=")) {
            out_path = arg["--out=".len..];
        } else {
            return validationError(io, "unknown argument: {s}\n{s}", .{ arg, usage });
        }
    }

    return .{
        .input_path = input_path orelse return validationError(io, "missing --input\n{s}", .{usage}),
        .function = function orelse return validationError(io, "missing --function\n{s}", .{usage}),
        .out_path = out_path,
    };
}

fn findOneFunction(io: std.Io, module: ir.Module, needle: []const u8) !ir.Function {
    var found: ?ir.Function = null;
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, needle) or std.mem.indexOf(u8, function.name, needle) != null) {
            if (found != null) return validationError(io, "--function matched more than one function: {s}\n", .{needle});
            found = function;
        }
    }
    return found orelse validationError(io, "--function matched no functions: {s}\n", .{needle});
}

fn appendTsv(allocator: std.mem.Allocator, output: *std.ArrayList(u8), comptime fmt: []const u8, args: anytype) !void {
    const text = try std.fmt.allocPrint(allocator, fmt, args);
    defer allocator.free(text);
    try output.appendSlice(allocator, text);
}

fn validationError(io: std.Io, comptime fmt: []const u8, args: anytype) error{ValidationError} {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    stderr_writer.interface.print(fmt, args) catch {};
    stderr_writer.interface.flush() catch {};
    return error.ValidationError;
}
