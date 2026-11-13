//! Exact path-sensitive stack balance at nonlocal tail transfers.
const std = @import("std");
const machine = @import("machine.zig");
const Flow = struct {
    a: std.mem.Allocator,
    states: []?u32,
    queue: std.ArrayList(usize) = .empty,
    labels: std.StringHashMap(usize),
    fn submit(f: *Flow, index: usize, depth: u32) !void {
        if (index >= f.states.len) return error.InvalidTailControlFlow;
        if (f.states[index]) |old| {
            if (old != depth) return error.TailStackMergeMismatch;
        } else {
            f.states[index] = depth;
            try f.queue.append(f.a, index);
        }
    }
    fn branch(f: *Flow, name: []const u8, depth: u32) !void {
        try f.submit(f.labels.get(name) orelse return error.InvalidBranchTarget, depth);
    }
};
fn change(inst: machine.Instruction) ?i64 {
    return switch (inst) {
        .sub_rsp_8, .push_imm32, .push_stack_disp8, .push_stack_disp32, .push_arg, .push_rax, .push_xmm64, .push_byval_tail_arg_ptr, .push_byval_tail_stack_ptr => 8,
        .add_rsp_8, .pop_arg => -8,
        .sub_rsp_24 => 24,
        .add_rsp_24 => -24,
        .sub_rsp_40 => 40,
        .add_rsp_40 => -40,
        .sub_rsp_56 => 56,
        .add_rsp_56 => -56,
        .sub_rsp_imm8 => |n| n,
        .sub_rsp_imm32 => |n| n,
        .add_rsp_imm8 => |n| -@as(i64, n),
        .add_rsp_imm32 => |n| -@as(i64, n),
        else => null,
    };
}
pub fn prove(function: machine.MachineFunction) !?[]?u32 {
    // This exact legacy envelope contains opaque conditional frame restores.
    // Its existing typed verifier owns those bytes and their external jump.
    if (legacyOpaqueFrame(function)) return null;
    const affected = for (function.instructions.items) |inst| {
        if (inst == .direct_jump or inst == .tail_jump_rax) break true;
    } else false;
    if (!affected) return null;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const depths = try std.heap.page_allocator.alloc(?u32, function.instructions.items.len);
    errdefer std.heap.page_allocator.free(depths);
    var flow: Flow = .{ .a = a, .states = depths, .labels = std.StringHashMap(usize).init(a) };
    @memset(flow.states, null);
    for (function.instructions.items, 0..) |inst, index| if (inst == .label) try flow.labels.put(inst.label, index);
    try flow.submit(0, 0);
    var cursor: usize = 0;
    while (cursor < flow.queue.items.len) : (cursor += 1) {
        const index = flow.queue.items[cursor];
        const inst = function.instructions.items[index];
        var depth = flow.states[index].?;
        if (change(inst)) |delta| {
            const next = @as(i64, depth) + delta;
            if (next < 0 or next > 8 * 1024 * 1024) return error.UnbalancedStackFrame;
            depth = @intCast(next);
        }
        switch (inst) {
            .direct_jump, .tail_jump_rax, .ret => {
                if (depth != 0) return error.UnbalancedStackFrame;
                continue;
            },
            .ud2, .noreturn_direct_call => continue,
            .and_rsp_neg16 => return error.OpaqueTailStackAdjustment,
            .jmp => |target| {
                try flow.branch(target, depth);
                continue;
            },
            .je, .jne, .jo, .jc, .jp, .js, .jae, .jle => |target| try flow.branch(target, depth),
            .indirect_jump => |jump| {
                for (jump.targets) |target| try flow.branch(target, depth);
                continue;
            },
            else => {},
        }
        try flow.submit(index + 1, depth);
    }
    return depths;
}

fn legacyOpaqueFrame(function: machine.MachineFunction) bool {
    if (function.selection_owner != .legacy_envelope) return false;
    const instructions = function.instructions.items;
    if (instructions.len != 7 or instructions[0] != .umodei5_before_intbytesize or
        instructions[1] != .direct_call or instructions[2] != .umodei5_between_intbytesize_and_memset or
        instructions[3] != .direct_call or instructions[4] != .umodei5_after_memset_before_memcpy or
        instructions[5] != .direct_jump or instructions[6] != .umodei5_after_memcpy) return false;
    return std.mem.eql(u8, instructions[1].direct_call.symbol, "zig.target.intByteSize") and
        instructions[1].direct_call.ret_ty.eql(.{ .int = 16 }) and
        std.mem.eql(u8, instructions[3].direct_call.symbol, "memset") and instructions[3].direct_call.ret_ty == .ptr and
        std.mem.eql(u8, instructions[5].direct_jump, "memcpy");
}

pub fn ownsLegacyDirectJump(function: machine.MachineFunction, index: usize) bool {
    return index == 5 and legacyOpaqueFrame(function);
}

test "scalar tail proof preserves the exact legacy opaque-frame verifier" {
    const a = std.testing.allocator;
    var function = machine.MachineFunction.init("legacy_remainder_frame", .void);
    defer function.deinit(a);
    function.selection_owner = .legacy_envelope;
    try function.instructions.appendSlice(a, &.{
        .umodei5_before_intbytesize,             .{ .direct_call = .{ .symbol = "zig.target.intByteSize", .ret_ty = .{ .int = 16 } } },
        .umodei5_between_intbytesize_and_memset, .{ .direct_call = .{ .symbol = "memset", .ret_ty = .ptr } },
        .umodei5_after_memset_before_memcpy,     .{ .direct_jump = "memcpy" },
        .umodei5_after_memcpy,
    });
    try std.testing.expect((try prove(function)) == null);
    try @import("verify.zig").verifyFunction(function);
    function.ret_ty = .{ .int = 32 };
    try std.testing.expectError(error.ReturnTypeMismatch, @import("verify.zig").verifyFunction(function));
    function.ret_ty = .void;
    function.instructions.items[5] = .{ .direct_jump = "other" };
    try std.testing.expect(!ownsLegacyDirectJump(function, 5));
    try std.testing.expectError(error.MisalignedStackBeforeCall, @import("verify.zig").verifyFunction(function));
}

test "scalar tail proof keeps composed and indirect full-depth guards" {
    const a = std.testing.allocator;
    var function = machine.MachineFunction.init("invalid_composed_tail", .void);
    defer function.deinit(a);
    function.selection_owner = .composed_cfg;
    try function.instructions.appendSlice(a, &.{ .{ .sub_rsp_imm8 = 16 }, .{ .direct_jump = "next" } });
    try std.testing.expectError(error.UnbalancedStackFrame, prove(function));
    function.selection_owner = .legacy_envelope;
    try std.testing.expectError(error.UnbalancedStackFrame, prove(function));
    function.instructions.items[1] = .tail_jump_rax;
    try std.testing.expectError(error.UnbalancedStackFrame, prove(function));
}
