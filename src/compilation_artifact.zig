//! Structured adapter artifacts describe how to build a module; their textual
//! body is not the module. Preserve that ownership while carrying preparation
//! requests to materialization. No pass is claimed to have run during transport.
const std = @import("std");
const ir = @import("ir.zig");
const compilation = @import("compilation.zig");

pub const prefix = "; zllvm_deferred_preparation_v1 = ";

const Stage = struct {
    optimization: []const u8,
    trace: bool = false,
    timing: bool = false,
    pass_limit: ?usize = null,

    fn options(stage: Stage) compilation.Options {
        return .{
            .optimization = stage.optimization,
            .passes = .{ .trace = stage.trace, .timing = stage.timing, .pass_limit = stage.pass_limit },
        };
    }
};

fn read(allocator: std.mem.Allocator, input: []const u8) !?std.json.Parsed([]const Stage) {
    var payload: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, prefix)) continue;
        if (payload != null) return error.DuplicateDeferredPreparation;
        payload = line[prefix.len..];
    }
    const parsed = try std.json.parseFromSlice([]const Stage, allocator, payload orelse return null, .{});
    errdefer parsed.deinit();
    for (parsed.value) |stage| try compilation.validate(allocator, stage.options());
    return parsed;
}

/// Append one explicit request; retain the original descriptor and body bytes.
/// Multiple optimizer invocations retain their order and individual pass limits.
pub fn write(allocator: std.mem.Allocator, writer: *std.Io.Writer, input: []const u8, options: compilation.Options) !void {
    const parsed = try read(allocator, input);
    defer if (parsed) |plan| plan.deinit();
    const sequence = options.optimization orelse {
        if (options.passes.trace or options.passes.timing or options.passes.pass_limit != null)
            return error.ArtifactPassOptionsRequireExplicitOptimization;
        return writer.writeAll(input);
    };
    try compilation.validate(allocator, options);
    const previous: []const Stage = if (parsed) |plan| plan.value else &.{};
    const stages = try allocator.alloc(Stage, previous.len + 1);
    defer allocator.free(stages);
    @memcpy(stages[0..previous.len], previous);
    stages[previous.len] = .{
        .optimization = sequence,
        .trace = options.passes.trace,
        .timing = options.passes.timing,
        .pass_limit = options.passes.pass_limit,
    };
    try writer.writeAll(prefix);
    try std.json.Stringify.value(stages, .{}, writer);
    try writer.writeByte('\n');
    var start: usize = 0;
    while (start < input.len) {
        const end = if (std.mem.indexOfScalarPos(u8, input, start, '\n')) |index| index + 1 else input.len;
        if (!std.mem.startsWith(u8, input[start..end], prefix)) try writer.writeAll(input[start..end]);
        start = end;
    }
}

/// Run the recorded requests against the adapter's actual typed module.
pub fn prepare(allocator: std.mem.Allocator, io: ?std.Io, module: *ir.Module, diagnostics: *std.Io.Writer, input: []const u8) !void {
    const parsed = try read(allocator, input) orelse return;
    defer parsed.deinit();
    for (parsed.value) |stage| try compilation.prepare(allocator, io, module, diagnostics, stage.options());
}
