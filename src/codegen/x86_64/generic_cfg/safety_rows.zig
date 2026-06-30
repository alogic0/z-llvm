const shared = @import("core_shared.zig");

const std = shared.std;
const ir = shared.ir;

const callIsFastcc = shared.callIsFastcc;
const globalSymbolNameFromValue = shared.globalSymbolNameFromValue;
const i64Value = shared.i64Value;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const validateDefaultCallConv = shared.validateDefaultCallConv;

fn validateAssumeColdCall(instruction: ir.Instruction) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, call.callee, "llvm.assume")) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !isInt(call.args.items[0].value, 1)) return error.UnsupportedCodegenValue;
}

pub fn genericCfgGuardPanicBlock(block: ir.BasicBlock) bool {
    if (block.instructions.items.len == 4) return genericCfgGuardSlicePanicBlock(block);
    if (block.instructions.items.len == 0 or block.instructions.items.len > 2) return false;
    var call_index: usize = 0;
    if (block.instructions.items.len == 2) {
        validateAssumeColdCall(block.instructions.items[0]) catch return false;
        call_index = 1;
    }
    const call = switch (block.instructions.items[call_index].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.args.items.len == 2) {
        if (call.args.items[0].ty != .ptr) return false;
        if (!call.args.items[1].ty.eql(.{ .int = 64 })) return false;
        switch (call.args.items[0].value) {
            .named => {},
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
        switch (call.args.items[1].value) {
            .int => |int| _ = i64Value(int) catch return false,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    } else if (call.args.items.len != 0) {
        return false;
    }
    return switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

fn genericCfgGuardSlicePanicBlock(block: ir.BasicBlock) bool {
    validateAssumeColdCall(block.instructions.items[0]) catch return false;
    const ptr_name = block.instructions.items[1].result orelse return false;
    const len_name = block.instructions.items[2].result orelse return false;
    const ptr_extract = switch (block.instructions.items[1].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    const len_extract = switch (block.instructions.items[2].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!ptr_extract.result_ty.eql(.ptr) or !std.mem.eql(u8, ptr_extract.indices, "0")) return false;
    if (!len_extract.result_ty.eql(.{ .int = 64 }) or !std.mem.eql(u8, len_extract.indices, "1")) return false;
    if (!ptr_extract.aggregate.eql(len_extract.aggregate)) return false;
    _ = globalSymbolNameFromValue(ptr_extract.aggregate) catch return false;

    const call = switch (block.instructions.items[3].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.args.items.len != 3) return false;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, ptr_name)) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !isNamed(call.args.items[1].value, len_name)) return false;
    if (call.args.items[2].ty != .ptr) return false;
    return switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}
