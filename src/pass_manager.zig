const std = @import("std");
const ir = @import("ir.zig");

pub const PassResult = enum {
    unchanged,
    changed,

    pub fn merge(a: PassResult, b: PassResult) PassResult {
        return if (a == .changed or b == .changed) .changed else .unchanged;
    }
};

pub const PassCategory = enum {
    mandatory,
    canonicalization,
    scalar,
    memory,
    loop,
    ipo,
    vector,
    instrumentation,
    lto,
    analysis,
    pipeline_guard,
    codegen_prep,
};

pub const Context = struct {
    allocator: std.mem.Allocator,
    io: ?std.Io = null,
    diagnostic_count: usize = 0,
    last_diagnostic: ?PassDiagnostic = null,
    debug_variable_location_scan_count: usize = 0,
    skipped_transform_passes: usize = 0,

    pub fn emitDiagnostic(
        context: *Context,
        pass_name: []const u8,
        function_name: []const u8,
        value_name: ?[]const u8,
        message: []const u8,
    ) void {
        context.diagnostic_count += 1;
        context.last_diagnostic = .{
            .pass_name = pass_name,
            .function_name = function_name,
            .value_name = value_name,
            .message = message,
        };
    }
};

pub const PassDiagnostic = struct {
    pass_name: []const u8,
    function_name: []const u8,
    value_name: ?[]const u8 = null,
    message: []const u8,
};

pub const ModulePass = struct {
    name: []const u8,
    category: PassCategory = .scalar,
    target_status: []const u8 = "LLVM-shaped algorithm subset",
    upstream_owner: []const u8 = "",
    run: *const fn (*ir.Module, *Context) anyerror!PassResult,
};

pub const RunOptions = struct {
    trace: bool = false,
    timing: bool = false,
    pass_limit: ?usize = null,
    verify_each_pass: bool = true,
};

pub const ModulePassManager = struct {
    allocator: std.mem.Allocator,
    passes: std.ArrayList(ModulePass) = .empty,

    pub fn init(allocator: std.mem.Allocator) ModulePassManager {
        return .{ .allocator = allocator };
    }

    pub fn deinit(pm: *ModulePassManager) void {
        pm.passes.deinit(pm.allocator);
    }

    pub fn add(pm: *ModulePassManager, pass: ModulePass) !void {
        try pm.passes.append(pm.allocator, pass);
    }

    pub fn run(pm: ModulePassManager, module: *ir.Module, context: *Context, writer: anytype, trace: bool) !PassResult {
        return pm.runWithOptions(module, context, writer, .{ .trace = trace });
    }

    pub fn runWithOptions(pm: ModulePassManager, module: *ir.Module, context: *Context, writer: anytype, options: RunOptions) !PassResult {
        var result: PassResult = .unchanged;
        var executed: usize = 0;
        const has_debug_variable_locations = module.hasDebugVariableLocationIntrinsics();
        context.debug_variable_location_scan_count += 1;
        var skipped_transform_passes: usize = 0;
        for (pm.passes.items) |pass| {
            if (options.pass_limit) |limit| {
                if (executed >= limit) {
                    if (options.trace) try writer.print("; pass limit reached after {} pass(es)\n", .{executed});
                    break;
                }
            }
            if (options.trace) {
                try writer.print("; before {s}\n", .{pass.name});
                try module.print(writer);
            }
            if (has_debug_variable_locations and isTransformPass(pass.category)) {
                if (options.verify_each_pass) try module.verify();
                if (options.trace) try writer.print("; skipped {s}: debug variable-location salvage is not modeled\n", .{pass.name});
                skipped_transform_passes += 1;
                context.skipped_transform_passes += 1;
                executed += 1;
                continue;
            }
            const start = timestamp(context);
            const diagnostic_count_before = context.diagnostic_count;
            const pass_result = try pass.run(module, context);
            const elapsed_ns = elapsedNanoseconds(start, timestamp(context));
            if (options.verify_each_pass) try module.verify();
            if (options.timing) try writer.print("; time {s}: {} ns\n", .{ pass.name, elapsed_ns });
            if (options.trace and context.diagnostic_count != diagnostic_count_before) {
                if (context.last_diagnostic) |diagnostic| {
                    try writer.print("; diagnostic {s}: @{s}", .{ diagnostic.pass_name, diagnostic.function_name });
                    if (diagnostic.value_name) |value_name| try writer.print(" %{s}", .{value_name});
                    try writer.print(": {s}\n", .{diagnostic.message});
                }
            }
            if (options.trace) {
                try writer.print("; after {s}: {s}\n", .{ pass.name, @tagName(pass_result) });
                try module.print(writer);
            }
            result = result.merge(pass_result);
            executed += 1;
        }
        if (skipped_transform_passes != 0) {
            try writer.print("; skipped_transform_passes={} reason=debug-variable-location-salvage-unmodeled\n", .{skipped_transform_passes});
        }
        return result;
    }
};

fn isTransformPass(category: PassCategory) bool {
    return switch (category) {
        .mandatory, .analysis, .pipeline_guard => false,
        .canonicalization, .scalar, .memory, .loop, .ipo, .vector, .instrumentation, .lto, .codegen_prep => true,
    };
}

fn timestamp(context: *Context) std.Io.Timestamp {
    const io = context.io orelse return .zero;
    return std.Io.Timestamp.now(io, .awake);
}

fn elapsedNanoseconds(start: std.Io.Timestamp, end: std.Io.Timestamp) i96 {
    return start.durationTo(end).nanoseconds;
}
