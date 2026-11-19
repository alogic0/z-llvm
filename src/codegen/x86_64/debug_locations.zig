const std = @import("std");
const ir = @import("../../ir.zig");
const calls = @import("../../ir/parser_calls.zig");

pub fn isLocation(inst: ir.Instruction) bool {
    if (inst.kind != .call or inst.result != null) return false;
    const call = inst.kind.call;
    const args = call.raw_args orelse return false;
    if (!call.isDebugVariableLocation() or call.ret_ty != .void or call.args.items.len != 0 or
        call.callee_value != null or call.inline_asm != null or call.operand_bundle != null or
        call.calling_conv != null or call.ret_attrs != null or call.tail_kind != null or
        call.attrs != null or call.native_query != null or call.va_arg or call.abi_x87_return) return false;
    calls.validateDebugIntrinsicArgs(call.callee, args) catch return false;
    return true;
}

/// The arena owns only the copied lists. Blocks without location records,
/// instruction operands and names continue to borrow from the original IR.
pub fn executableView(arena: std.mem.Allocator, source: ir.Function) !ir.Function {
    var function = source;
    for (source.blocks.items, 0..) |block, index| {
        const instructions = block.instructions.items;
        const first = for (instructions, 0..) |instruction, i| {
            if (isLocation(instruction)) break i;
        } else continue;
        if (function.blocks.items.ptr == source.blocks.items.ptr)
            function.blocks = try source.blocks.clone(arena);
        var executable = try std.ArrayList(ir.Instruction).initCapacity(arena, instructions.len - 1);
        executable.appendSliceAssumeCapacity(instructions[0..first]);
        for (instructions[first + 1 ..]) |instruction| {
            if (!isLocation(instruction)) executable.appendAssumeCapacity(instruction);
        }
        function.blocks.items[index].instructions = executable;
    }
    return function;
}
