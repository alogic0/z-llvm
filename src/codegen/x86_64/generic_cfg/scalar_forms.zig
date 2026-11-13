//! Private scalar expansions reuse the selector's ordinary compare/select and
//! memory paths. The caller owns an arena; the original IR is never changed.
const std = @import("std");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const ir = @import("../../../ir.zig");
const sysv = @import("../sysv_abi.zig");

const temporary_prefix = "__zllvm_scalar_form_";

/// One state per immutable source function, prefix and rewrite attempt. Build the
/// collision index only on the first requested temporary; unsuccessful scans
/// still allocate nothing. Monotonic serials also exclude generated names.
pub const TemporaryNames = struct {
    prefix: []const u8 = temporary_prefix,
    next: usize = 0,
    initialized: bool = false,
    names_visited: usize = 0,
    occupied: std.AutoHashMapUnmanaged(usize, void) = .empty,

    pub fn deinit(self: *TemporaryNames, allocator: std.mem.Allocator) void {
        self.occupied.deinit(allocator);
    }

    fn visit(self: *TemporaryNames, allocator: std.mem.Allocator, name: []const u8) !void {
        self.names_visited += 1;
        // Most source names cannot collide. Avoid decoding ordinary names
        // unless their spelling starts with our prefix.
        if (name.len == 0 or (name[0] != '"' and !std.mem.startsWith(u8, name, self.prefix))) return;
        if (ir.identifiers.indexedSuffix(name, self.prefix)) |suffix| try self.occupied.put(allocator, suffix, {});
    }

    fn index(self: *TemporaryNames, allocator: std.mem.Allocator, function: ir.Function) !void {
        if (self.initialized) return;
        for (function.params.items) |param| try self.visit(allocator, param.name);
        for (function.blocks.items) |block| {
            try self.visit(allocator, block.name);
            for (block.instructions.items) |inst| if (inst.result) |result| try self.visit(allocator, result);
        }
        self.initialized = true;
    }
};

pub fn temporary(allocator: std.mem.Allocator, function: ir.Function, serial: *TemporaryNames) ![]const u8 {
    try serial.index(allocator, function);
    while (serial.occupied.contains(serial.next)) serial.next = try std.math.add(usize, serial.next, 1);
    const name = try std.fmt.allocPrint(allocator, "{s}{d}", .{ serial.prefix, serial.next });
    errdefer allocator.free(name);
    serial.next = try std.math.add(usize, serial.next, 1);
    return name;
}

fn unsignedMin(call: ir.CallInst) bool {
    const bits: u16 = if (std.mem.eql(u8, call.callee, "llvm.umin.i64")) 64 else if (std.mem.eql(u8, call.callee, "llvm.umin.i32")) 32 else return false;
    if (call.callee_value != null or call.inline_asm != null or call.raw_args != null or
        call.operand_bundle != null or call.callee_function_ty != null or call.calling_conv != null or
        call.ret_attrs != null or call.args.items.len != 2 or !call.ret_ty.eql(.{ .int = bits })) return false;
    sysv.rejectUnsupportedCallEnvelope(call) catch return false;
    for (call.args.items) |arg| if (!arg.ty.eql(call.ret_ty) or arg.attrs != null or
        (arg.value != .named and arg.value != .int)) return false;
    return call.args.items[0].value == .named or call.args.items[1].value == .named;
}

fn relativeLoad(call: ir.CallInst) bool {
    if (!std.mem.eql(u8, call.callee, "llvm.load.relative.i64") or call.ret_ty != .ptr or
        call.args.items.len != 2 or call.args.items[0].ty != .ptr or !call.args.items[1].ty.eql(.{ .int = 64 }) or
        call.callee_value != null or call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or
        call.callee_function_ty != null or call.calling_conv != null) return false;
    sysv.rejectUnsupportedCallEnvelope(call) catch return false;
    for (call.args.items) |arg| {
        sysv.rejectUnsupportedCallArgAttrs(arg) catch return false;
        if (arg.value != .named and arg.value != .int) return false;
    }
    return call.args.items[0].value == .named;
}

fn signedLe(icmp: ir.IcmpInst) bool {
    return !icmp.samesign and icmp.predicate == .sle and
        (icmp.operand_ty.eql(.{ .int = 32 }) or icmp.operand_ty.eql(.{ .int = 64 })) and
        icmp.lhs == .named and (icmp.rhs == .named or icmp.rhs == .int);
}

fn unsignedSaturatingSub(call: ir.CallInst) bool {
    const bits: u16 = if (std.mem.eql(u8, call.callee, "llvm.usub.sat.i64")) 64 else if (std.mem.eql(u8, call.callee, "llvm.usub.sat.i32")) 32 else return false;
    if (call.callee_value != null or call.inline_asm != null or call.raw_args != null or
        call.operand_bundle != null or call.callee_function_ty != null or call.calling_conv != null or
        call.ret_attrs != null or call.args.items.len != 2 or !call.ret_ty.eql(.{ .int = bits })) return false;
    sysv.rejectUnsupportedCallEnvelope(call) catch return false;
    for (call.args.items) |arg| if (!arg.ty.eql(call.ret_ty) or arg.attrs != null or arg.value != .named) return false;
    return true;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var serial: TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null) switch (inst.kind) {
                .freeze => |freeze| if (freeze.ty == .int and freeze.ty.int > 32 and freeze.ty.int < 64 and
                    freeze.value == .named and !std.mem.startsWith(u8, freeze.value.named, "@"))
                {
                    try candidate.begin(&block, block_index, instruction_index);
                    const input = try temporary(allocator, function, &serial);
                    const stable = try temporary(allocator, function, &serial);
                    // Freeze a native carrier, then retain precisely the source
                    // bits. The original wider alias remains a separate value.
                    try block.instructions.append(allocator, .{ .result = input, .kind = .{ .cast = .{
                        .op = .zext,
                        .from_ty = freeze.ty,
                        .value = freeze.value,
                        .to_ty = .{ .int = 64 },
                    } } });
                    try block.instructions.append(allocator, .{ .result = stable, .metadata = inst.metadata, .kind = .{ .freeze = .{
                        .ty = .{ .int = 64 },
                        .value = .{ .named = input },
                    } } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .cast = .{
                        .op = .trunc,
                        .from_ty = .{ .int = 64 },
                        .value = .{ .named = stable },
                        .to_ty = freeze.ty,
                    } } });
                    continue;
                },
                .call => |call| if (unsignedMin(call)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    const condition = try temporary(allocator, function, &serial);
                    const swapped = call.args.items[0].value == .int;
                    const lhs = call.args.items[@intFromBool(swapped)].value;
                    const rhs = call.args.items[@intFromBool(!swapped)].value;
                    try block.instructions.append(allocator, .{ .result = condition, .kind = .{ .icmp = .{
                        .predicate = .ult,
                        .operand_ty = call.ret_ty,
                        .lhs = lhs,
                        .rhs = rhs,
                    } } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .select = .{
                        .cond_ty = .{ .int = 1 },
                        .cond = .{ .named = condition },
                        .ty = call.ret_ty,
                        .true_value = lhs,
                        .false_value = rhs,
                    } } });
                    continue;
                } else if (relativeLoad(call)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    const address = try temporary(allocator, function, &serial);
                    const offset = try temporary(allocator, function, &serial);
                    const wide = try temporary(allocator, function, &serial);
                    var entry: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = call.args.items[0].value, .indices = .empty };
                    try entry.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = call.args.items[1].value });
                    try block.instructions.append(allocator, .{ .result = address, .kind = .{ .gep = entry } });
                    try block.instructions.append(allocator, .{ .result = offset, .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = address }, .attrs = .{ .@"align" = 1 } } } });
                    try block.instructions.append(allocator, .{ .result = wide, .kind = .{ .cast = .{ .op = .sext, .from_ty = .{ .int = 32 }, .to_ty = .{ .int = 64 }, .value = .{ .named = offset } } } });
                    // The signed displacement is relative to the original base,
                    // not to the table entry from which it was loaded.
                    var result: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = call.args.items[0].value, .indices = .empty };
                    try result.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = wide } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .gep = result } });
                    continue;
                } else if (unsignedSaturatingSub(call)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    const condition = try temporary(allocator, function, &serial);
                    const difference = try temporary(allocator, function, &serial);
                    const lhs = call.args.items[0].value;
                    const rhs = call.args.items[1].value;
                    try block.instructions.append(allocator, .{ .result = condition, .kind = .{ .icmp = .{
                        .predicate = .ult,
                        .operand_ty = call.ret_ty,
                        .lhs = lhs,
                        .rhs = rhs,
                    } } });
                    // Wrapping subtraction is defined even on the discarded
                    // underflow arm; attaching nuw here would create poison.
                    try block.instructions.append(allocator, .{ .result = difference, .kind = .{ .binary = .{
                        .op = .sub,
                        .ty = call.ret_ty,
                        .lhs = lhs,
                        .rhs = rhs,
                    } } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .select = .{
                        .cond_ty = .{ .int = 1 },
                        .cond = .{ .named = condition },
                        .ty = call.ret_ty,
                        .true_value = .{ .int = 0 },
                        .false_value = .{ .named = difference },
                    } } });
                    continue;
                },
                .icmp => |icmp| if (!icmp.samesign and
                    (icmp.predicate == .eq or icmp.predicate == .ne) and
                    (((icmp.operand_ty.eql(.{ .int = 32 }) or icmp.operand_ty.eql(.{ .int = 64 })) and icmp.lhs == .int) or
                        (icmp.operand_ty == .ptr and icmp.lhs == .null_value)) and icmp.rhs == .named)
                {
                    try candidate.begin(&block, block_index, instruction_index);
                    var comparison = inst;
                    comparison.kind.icmp.lhs = icmp.rhs;
                    comparison.kind.icmp.rhs = icmp.lhs;
                    try block.instructions.append(allocator, comparison);
                    continue;
                } else if (signedLe(icmp)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    var comparison = inst;
                    comparison.result = try temporary(allocator, function, &serial);
                    comparison.kind.icmp.predicate = .sgt;
                    try block.instructions.append(allocator, comparison);
                    try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .binary = .{
                        .op = .xor,
                        .ty = .{ .int = 1 },
                        .lhs = .{ .named = comparison.result.? },
                        .rhs = .{ .int = 1 },
                    } } });
                    continue;
                },
                else => {},
            };
            try candidate.keep(&block, inst);
        }
        if (original.terminator) |terminator| {
            if (terminator == .condbr and terminator.condbr.cond_ty.eql(.{ .int = 1 }) and terminator.condbr.cond == .int) {
                const literal = terminator.condbr.cond.int;
                if (literal >= -1 and literal <= 1) {
                    try candidate.begin(&block, block_index, original.instructions.items.len);
                    const input = try temporary(allocator, function, &serial);
                    const condition = try temporary(allocator, function, &serial);
                    // Keep the exact CFG and PHI predecessor sets. The existing
                    // scalar compare/branch owner receives a named i1 condition.
                    try block.instructions.append(allocator, .{ .result = input, .kind = .{ .binary = .{
                        .op = .add,
                        .ty = .{ .int = 32 },
                        .lhs = .{ .int = literal & 1 },
                        .rhs = .{ .int = 0 },
                    } } });
                    try block.instructions.append(allocator, .{ .result = condition, .kind = .{ .icmp = .{
                        .predicate = .ne,
                        .operand_ty = .{ .int = 32 },
                        .lhs = .{ .named = input },
                        .rhs = .{ .int = 0 },
                    } } });
                    block.terminator.?.condbr.cond = .{ .named = condition };
                }
            }
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
