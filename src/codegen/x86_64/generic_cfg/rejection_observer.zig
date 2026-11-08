//! Optional, borrowed observations at the failing composed selection operation.
//! Consumers copy what they retain; an attempt reset invalidates earlier retries.
const ir = @import("../../../ir.zig");

pub const Operand = struct {
    argument: ir.CallArg,
    location: ?[]const u8,
};

pub const GlobalAddress = struct {
    symbol: []const u8,
    addend: i32,
    global: ir.Global,
    property_failure: ?[]const u8,
};

pub const Rejection = struct {
    function: ir.Function,
    position: usize,
    tag: []const u8,
    detail: []const u8,
    call: ?ir.CallInst = null,
    result: ?[]const u8 = null,
    parameter: ?ir.Param = null,
    global_address: ?GlobalAddress = null,
    pressure: ?@import("stage2_planning.zig").StageTwoSummary = null,
    operands: []const Operand = &.{},
};

pub const Observer = struct {
    context: *anyopaque,
    reset_fn: *const fn (*anyopaque) void,
    reject_fn: *const fn (*anyopaque, Rejection) anyerror!void,

    pub fn reset(observer: ?*Observer) void {
        if (observer) |value| value.reset_fn(value.context);
    }

    pub fn reject(observer: *Observer, value: Rejection) !void {
        try observer.reject_fn(observer.context, value);
    }
};
