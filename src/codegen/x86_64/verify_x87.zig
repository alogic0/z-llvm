//! Path-sensitive x87 depth and ABI return verification.
const std = @import("std");
const machine = @import("machine.zig");

fn affected(function: machine.MachineFunction) bool {
    if (function.ret_ty == .x86_fp80) return true;
    for (function.instructions.items) |inst| switch (inst) {
        .fneg_x86_fp80_stack8_st0, .i80_rax_rdx_st0, .x87_st0_i80_rax_rdx, .x87_binary_pop, .x87_sqrt_st0 => return true,
        .direct_call => |call| if (call.ret_ty == .x86_fp80) return true,
        .indirect_call_rax => |ty| if (ty == .x86_fp80) return true,
        else => {},
    };
    return false;
}

const Flow = struct {
    allocator: std.mem.Allocator,
    states: []?u4,
    queue: std.ArrayList(usize) = .empty,
    labels: std.StringHashMap(usize),
    fn submit(flow: *Flow, index: usize, depth: u4) !void {
        if (index >= flow.states.len) return error.InvalidControlFlow;
        if (flow.states[index]) |previous| {
            if (previous != depth) return error.X87StackMergeMismatch;
        } else {
            flow.states[index] = depth;
            try flow.queue.append(flow.allocator, index);
        }
    }
    fn branch(flow: *Flow, name: []const u8, depth: u4) !void {
        try flow.submit(flow.labels.get(name) orelse return error.InvalidBranchTarget, depth);
    }
};

pub fn verify(function: machine.MachineFunction) !void {
    if (!affected(function) or function.instructions.items.len == 0) return;
    const allocator = std.heap.page_allocator;
    var flow: Flow = .{ .allocator = allocator, .states = try allocator.alloc(?u4, function.instructions.items.len), .labels = std.StringHashMap(usize).init(allocator) };
    defer allocator.free(flow.states);
    defer flow.queue.deinit(allocator);
    defer flow.labels.deinit();
    @memset(flow.states, null);
    for (function.instructions.items, 0..) |inst, index| if (inst == .label) {
        const entry = try flow.labels.getOrPut(inst.label);
        if (entry.found_existing) return error.InvalidBranchTarget;
        entry.value_ptr.* = index;
    };
    try flow.submit(0, 0);
    var cursor: usize = 0;
    while (cursor < flow.queue.items.len) : (cursor += 1) {
        const index = flow.queue.items[cursor];
        var depth = flow.states[index].?;
        switch (function.instructions.items[index]) {
            .fneg_x86_fp80_stack8_st0, .i80_rax_rdx_st0 => {
                if (depth == 8) return error.X87StackOverflow;
                depth += 1;
            },
            .x87_st0_i80_rax_rdx => {
                if (depth == 0) return error.X87StackUnderflow;
                depth -= 1;
            },
            .x87_binary_pop => {
                if (depth < 2) return error.X87StackUnderflow;
                depth -= 1;
            },
            .x87_sqrt_st0 => if (depth == 0) return error.X87StackUnderflow,
            .direct_call => |call| {
                if (depth != 0) return error.X87StackNotEmptyAtCall;
                depth = if (call.ret_ty == .x86_fp80) 1 else 0;
            },
            .indirect_call_rax => |ty| {
                if (depth != 0) return error.X87StackNotEmptyAtCall;
                depth = if (ty == .x86_fp80) 1 else 0;
            },
            .ret => {
                if (depth != (if (function.ret_ty == .x86_fp80) @as(u4, 1) else 0)) return error.ReturnRegisterUndefined;
                continue;
            },
            .ud2 => continue,
            .direct_jump => {
                if (depth != 0) return error.X87StackNotEmptyAtCall;
                continue;
            },
            .noreturn_direct_call => {
                if (depth != 0) return error.X87StackNotEmptyAtCall;
                continue;
            },
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
}
