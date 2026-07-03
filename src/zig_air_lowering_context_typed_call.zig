const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_types = @import("zig_air_types.zig");
const ir = @import("ir.zig");

const parseFunctionType = air_types.parseFunctionType;
const ownPrint = air_model.ownPrint;
const irCallingConvention = air_model.irCallingConvention;

pub fn lowerTypedCall(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len == 0) return error.UnsupportedAir;
    const call_details = air_model.callDetails(instruction) orelse return error.UnsupportedAir;
    const call_type = try parseFunctionType(self.allocator, call_details.signature_text);
    defer call_type.deinit(self.allocator);
    if (instruction.operands.len != call_type.params.len + 1) return error.UnsupportedAir;
    const callee = if (call_details.callee) |direct|
        if (direct.external)
            direct.name
        else
            try self.qualifiedCalleeName(direct.name)
    else
        "";
    const callee_value: ?ir.Value = if (call_details.callee == null) blk: {
        const callee_operand = try self.resolveTypedOperand(instruction, 0);
        if (callee_operand.ty.ir_type != .ptr) return error.UnsupportedAir;
        break :blk callee_operand.value;
    } else null;

    const is_default_panic = call_details.callee_name != null and std.mem.eql(u8, call_details.callee_name.?, "defaultPanic");
    const is_debug_assert = if (call_details.callee) |direct|
        !direct.external and call_details.callee_name != null and std.mem.eql(u8, call_details.callee_name.?, "assert") and
            call_type.return_type.ir_type == .void and call_type.params.len == 1 and call_type.params[0].ir_type.eql(.{ .int = 1 })
    else
        false;
    var call: ir.CallInst = .{
        .ret_ty = call_type.return_type.ir_type,
        .callee = if (is_default_panic) "debug.defaultPanic" else if (is_debug_assert) "debug.assert" else callee,
        .callee_value = callee_value,
        .calling_conv = irCallingConvention(call_type),
        .tail_kind = air_capabilities.callTailKindForOpcode(instruction.opcode),
        .args = .empty,
    };
    errdefer call.deinit(self.allocator);

    if (is_default_panic and (call_type.params.len == 1 or call_type.params.len == 2) and
        call_type.params[0].ir_type.eql(.{ .aggregate = "{ ptr, i64 }" }))
    {
        const slice_arg = try self.resolveTypedOperand(instruction, 1);
        if (!slice_arg.ty.ir_type.eql(.{ .aggregate = "{ ptr, i64 }" })) return error.UnsupportedAir;
        if (call_type.params.len == 2 and !call_type.params[1].ir_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
        const ptr_name = try ownPrint(self.module, "air{}_panic_ptr", .{instruction.index});
        const len_name = try ownPrint(self.module, "air{}_panic_len", .{instruction.index});
        try self.block.instructions.append(self.allocator, .{
            .result = ptr_name,
            .kind = .{ .extractvalue = .{
                .aggregate_ty = slice_arg.ty.ir_type,
                .aggregate = slice_arg.value,
                .indices = "0",
                .result_ty = .ptr,
            } },
        });
        try self.block.instructions.append(self.allocator, .{
            .result = len_name,
            .kind = .{ .extractvalue = .{
                .aggregate_ty = slice_arg.ty.ir_type,
                .aggregate = slice_arg.value,
                .indices = "1",
                .result_ty = .{ .int = 64 },
            } },
        });
        try call.args.append(self.allocator, .{ .ty = .ptr, .value = .{ .named = ptr_name } });
        try call.args.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = len_name } });
        try self.block.instructions.append(self.allocator, .{
            .result = null,
            .kind = .{ .call = call },
        });
        return;
    }

    for (call_type.params, 0..) |param_type, arg_index| {
        const arg = try self.resolveTypedOperand(instruction, arg_index + 1);
        if (!arg.ty.ir_type.eql(param_type.ir_type)) return error.UnsupportedAir;
        try call.args.append(self.allocator, .{
            .ty = arg.ty.ir_type,
            .value = arg.value,
        });
    }

    const result_name = if (call.ret_ty == .void) null else try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .call = call },
    });
    if (result_name) |name| {
        self.values[instruction.index] = .{
            .ty = call_type.return_type,
            .value = .{ .named = name },
        };
    }
}
