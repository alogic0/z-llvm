//! Private register carriers for unannotated narrow integer ABI values.
//! The low bits retain their source width; only the selector's view is widened.
const std = @import("std");
const ir = @import("../../../ir.zig");
const sysv = @import("../sysv_abi.zig");
const helpers = @import("composed_helpers.zig");

const carrier: ir.Type = .{ .int = 32 };

fn narrow(ty: ir.Type) bool {
    return ty == .int and ty.int > 0 and ty.int <= 16;
}

fn advisory(attrs: ?[]const u8) bool {
    return attrs == null or std.mem.eql(u8, std.mem.trim(u8, attrs.?, " \t"), "noundef");
}

fn parameter(param: ir.Param) bool {
    return narrow(param.ty) and advisory(param.attrs);
}

fn callForm(call: ir.CallInst) bool {
    if (std.mem.startsWith(u8, call.callee, "llvm.") or
        std.mem.eql(u8, call.callee, "zig.target.intByteSize") or
        call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or
        call.callee_function_ty != null or !helpers.isDefaultOrFastcc(call.calling_conv)) return false;
    if (call.callee_value) |callee| if (callee != .named or callee.named.len == 0 or callee.named[0] == '@') return false;
    sysv.rejectUnsupportedCallEnvelope(call) catch return false;
    for (call.args.items) |arg| sysv.rejectUnsupportedCallArgAttrs(arg) catch return false;
    return true;
}

fn stackObject(function: ir.Function, value: ir.Value) bool {
    if (value != .named) return false;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .alloca and inst.result != null and ir.identifiers.eql(inst.result.?, value.named)) return true;
    };
    return false;
}

fn callReturn(function: ir.Function, call: ir.CallInst) bool {
    if (!narrow(call.ret_ty) or call.ret_attrs != null) return false;
    if (call.ret_ty.int != 1 or call.callee_value != null) return true;
    // The established typed boolean action owns up to six named scalar or
    // stack-object arguments. Other ordinary calls use the general ABI path,
    // then mask AL before publishing the original boolean SSA value.
    if (call.args.items.len > 6) return true;
    for (call.args.items) |arg| {
        if (arg.value != .named or std.mem.startsWith(u8, arg.value.named, "@")) return true;
        if (arg.ty == .ptr and !stackObject(function, arg.value)) return true;
    }
    return false;
}

fn needsCall(function: ir.Function, call: ir.CallInst) bool {
    if (!callForm(call)) return false;
    if (callReturn(function, call)) return true;
    for (call.args.items) |arg| if (narrow(arg.ty)) return true;
    return false;
}

fn booleanXor(inst: ir.Instruction) bool {
    return inst.kind == .binary and inst.kind.binary.op == .xor and
        inst.kind.binary.ty.eql(.{ .int = 1 }) and !inst.kind.binary.flags.any();
}

fn temporary(allocator: std.mem.Allocator, function: ir.Function, serial: *usize) ![]const u8 {
    while (true) {
        const name = try std.fmt.allocPrint(allocator, "__zllvm_narrow_{d}", .{serial.*});
        serial.* += 1;
        var collision = false;
        for (function.params.items) |param| if (ir.identifiers.eql(name, param.name)) {
            collision = true;
        };
        for (function.blocks.items) |block| {
            if (ir.identifiers.eql(name, block.name)) collision = true;
            for (block.instructions.items) |inst| if (inst.result) |result| {
                if (ir.identifiers.eql(name, result)) collision = true;
            };
        }
        if (!collision) return name;
    }
}

fn widen(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *usize, ty: ir.Type, value: ir.Value) !ir.Value {
    if (value == .int) return .{ .int = value.int & ((@as(i128, 1) << @intCast(ty.int)) - 1) };
    const name = try temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .cast = .{
        .op = .zext,
        .from_ty = ty,
        .value = value,
        .to_ty = carrier,
    } } });
    return .{ .named = name };
}

fn receive(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *usize, ty: ir.Type, value: ir.Value, name: []const u8) !void {
    const masked = try temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = masked, .kind = .{ .binary = .{
        .op = .@"and",
        .ty = carrier,
        .lhs = value,
        .rhs = .{ .int = (@as(i128, 1) << @intCast(ty.int)) - 1 },
    } } });
    // A trunc alone is a location alias in the selector. Mask before binding the
    // original narrow name, including booleans consumed directly by a branch.
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .cast = .{
        .op = .trunc,
        .from_ty = carrier,
        .value = .{ .named = masked },
        .to_ty = ty,
    } } });
}

// The caller owns an arena. Clone every list that changes and borrow immutable
// nested operands. C/fastcc integer register carriers occupy the same ABI homes.
pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    if (!helpers.isDefaultOrFastcc(function.calling_conv) or function.blocks.items.len == 0) return null;
    if (narrow(function.ret_ty) and function.ret_attrs != null) return null;
    const return_value = narrow(function.ret_ty) and function.ret_attrs == null;
    var needed = return_value;
    for (function.params.items) |param| if (parameter(param)) {
        needed = true;
    };
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        if (booleanXor(inst) or (inst.kind == .call and needsCall(function, inst.kind.call))) needed = true;
    };
    if (!needed) return null;
    var result = function;
    result.params = try function.params.clone(allocator);
    result.blocks = .empty;
    if (return_value) result.ret_ty = carrier;
    var serial: usize = 0;
    for (result.params.items) |*param| if (parameter(param.*)) {
        param.name = try temporary(allocator, function, &serial);
        param.ty = carrier;
    };
    for (function.blocks.items, 0..) |original, index| {
        var block = original;
        block.instructions = .empty;
        if (index == 0) for (function.params.items, result.params.items) |param, incoming| {
            if (parameter(param)) try receive(allocator, function, &block, &serial, param.ty, .{ .named = incoming.name }, param.name);
        };
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (!inst.removed and booleanXor(inst)) {
                const binary = inst.kind.binary;
                copy.kind.binary.lhs = try widen(allocator, function, &block, &serial, binary.ty, binary.lhs);
                copy.kind.binary.rhs = try widen(allocator, function, &block, &serial, binary.ty, binary.rhs);
                copy.kind.binary.ty = carrier;
                copy.result = try temporary(allocator, function, &serial);
                try block.instructions.append(allocator, copy);
                try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .cast = .{
                    .op = .trunc,
                    .from_ty = carrier,
                    .value = .{ .named = copy.result.? },
                    .to_ty = binary.ty,
                } } });
                continue;
            }
            if (!inst.removed and inst.kind == .call and needsCall(function, inst.kind.call)) {
                const call = inst.kind.call;
                copy.kind.call.args = try call.args.clone(allocator);
                for (copy.kind.call.args.items) |*arg| if (narrow(arg.ty)) {
                    arg.value = try widen(allocator, function, &block, &serial, arg.ty, arg.value);
                    arg.ty = carrier;
                };
                if (callReturn(function, call)) {
                    copy.kind.call.ret_ty = carrier;
                    if (inst.result != null) copy.result = try temporary(allocator, function, &serial);
                }
                try block.instructions.append(allocator, copy);
                if (callReturn(function, call) and inst.result != null)
                    try receive(allocator, function, &block, &serial, call.ret_ty, .{ .named = copy.result.? }, inst.result.?);
                continue;
            }
            try block.instructions.append(allocator, copy);
        }
        if (return_value) if (block.terminator) |*term| if (term.* == .ret) {
            if (term.ret.value) |value| term.ret.value = try widen(allocator, function, &block, &serial, function.ret_ty, value);
            term.ret.ty = carrier;
        };
        try result.blocks.append(allocator, block);
    }
    return result;
}
