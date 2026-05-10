const std = @import("std");
const ir = @import("ir.zig");

pub const PassResult = enum {
    unchanged,
    changed,

    pub fn merge(a: PassResult, b: PassResult) PassResult {
        return if (a == .changed or b == .changed) .changed else .unchanged;
    }
};

pub const Context = struct {
    allocator: std.mem.Allocator,
};

pub const ModulePass = struct {
    name: []const u8,
    run: *const fn (*ir.Module, *Context) anyerror!PassResult,
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
        var result: PassResult = .unchanged;
        for (pm.passes.items) |pass| {
            if (trace) {
                try writer.print("; before {s}\n", .{pass.name});
                try module.print(writer);
            }
            const pass_result = try pass.run(module, context);
            try module.verify();
            if (trace) {
                try writer.print("; after {s}: {s}\n", .{ pass.name, @tagName(pass_result) });
                try module.print(writer);
            }
            result = result.merge(pass_result);
        }
        return result;
    }
};
