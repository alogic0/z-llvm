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
