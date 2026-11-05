//! Private scalar expansion of unsigned word overflow pairs. Only structured
//! extractvalue users are admitted; the borrowed source function stays intact.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const pairs = @import("word_pair_memory.zig");
const uses = @import("stage2_planning.zig");
const sysv = @import("../sysv_abi.zig");

const word: ir.Type = .{ .int = 64 };
const Entry = struct { op: ir.BinaryOp, ty: ir.Type, wrapped: []const u8, overflow: []const u8, wide_overflow: []const u8, literal: ?[]const u8 };

fn operation(call: ir.CallInst) ?ir.BinaryOp {
    const op: ir.BinaryOp = if (std.mem.eql(u8, call.callee, "llvm.uadd.with.overflow.i64")) .add else if (std.mem.eql(u8, call.callee, "llvm.usub.with.overflow.i64")) .sub else return null;
    if (call.ret_ty != .aggregate or !pairs.spelling(call.ret_ty.aggregate, "{i64,i1}") or call.callee_value != null or
        call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or call.callee_function_ty != null or
        call.calling_conv != null or call.ret_attrs != null or call.args.items.len != 2) return null;
    sysv.rejectUnsupportedCallEnvelope(call) catch return null;
    for (call.args.items) |arg| if (!arg.ty.eql(word) or arg.attrs != null or (arg.value != .named and arg.value != .int)) return null;
    if (call.args.items[0].value != .named) return null;
    return op;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var names = std.StringHashMap(Entry).init(allocator);
    var serial: usize = 0;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.result == null or inst.kind != .call) continue;
        const op = operation(inst.kind.call) orelse continue;
        try names.put(inst.result.?, .{
            .op = op,
            .ty = inst.kind.call.ret_ty,
            .wrapped = try forms.temporary(allocator, function, &serial),
            .overflow = try forms.temporary(allocator, function, &serial),
            .wide_overflow = try forms.temporary(allocator, function, &serial),
            .literal = if (inst.kind.call.args.items[1].value == .int) try forms.temporary(allocator, function, &serial) else null,
        });
    };
    if (names.count() == 0) return null;
    var iterator = names.iterator();
    while (iterator.next()) |item| {
        for (function.blocks.items) |block| {
            for (block.instructions.items) |inst| {
                if (inst.removed or !try uses.instructionUsesName(allocator, inst, item.key_ptr.*)) continue;
                if (inst.kind != .extractvalue or inst.result == null) return null;
                const extract = inst.kind.extractvalue;
                if (extract.aggregate != .named or !ir.identifiers.eql(extract.aggregate.named, item.key_ptr.*) or
                    !extract.aggregate_ty.eql(item.value_ptr.ty)) return null;
                if (std.mem.eql(u8, extract.indices, "0")) {
                    if (!extract.result_ty.eql(word)) return null;
                } else if (std.mem.eql(u8, extract.indices, "1")) {
                    if (!extract.result_ty.eql(.{ .int = 1 })) return null;
                } else return null;
            }
            if (block.terminator) |term| if (try uses.terminatorUsesName(allocator, term, item.key_ptr.*)) return null;
        }
    }
    var result = function;
    result.blocks = .empty;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            if (!inst.removed) {
                if (inst.kind == .call and inst.result != null) if (names.get(inst.result.?)) |entry| {
                    const lhs = inst.kind.call.args.items[0].value;
                    const original_rhs = inst.kind.call.args.items[1].value;
                    if (entry.literal) |literal| try block.instructions.append(allocator, .{ .result = literal, .kind = .{ .binary = .{
                        .op = .add,
                        .ty = word,
                        .lhs = original_rhs,
                        .rhs = .{ .int = 0 },
                    } } });
                    const rhs: ir.Value = if (entry.literal) |literal| .{ .named = literal } else original_rhs;
                    // Wrapping arithmetic is defined on both overflow paths.
                    try block.instructions.append(allocator, .{ .result = entry.wrapped, .metadata = inst.metadata, .kind = .{ .binary = .{
                        .op = entry.op,
                        .ty = word,
                        .lhs = lhs,
                        .rhs = rhs,
                    } } });
                    try block.instructions.append(allocator, .{ .result = entry.overflow, .kind = .{ .icmp = .{
                        .predicate = .ult,
                        .operand_ty = word,
                        .lhs = if (entry.op == .add) .{ .named = entry.wrapped } else lhs,
                        .rhs = if (entry.op == .add) lhs else rhs,
                    } } });
                    try block.instructions.append(allocator, .{ .result = entry.wide_overflow, .kind = .{ .cast = .{
                        .op = .zext,
                        .from_ty = .{ .int = 1 },
                        .value = .{ .named = entry.overflow },
                        .to_ty = .{ .int = 32 },
                    } } });
                    continue;
                };
                if (inst.kind == .extractvalue and inst.kind.extractvalue.aggregate == .named) if (names.get(inst.kind.extractvalue.aggregate.named)) |entry| {
                    var replacement = inst;
                    replacement.kind = if (std.mem.eql(u8, inst.kind.extractvalue.indices, "0")) .{ .binary = .{
                        .op = .add,
                        .ty = word,
                        .lhs = .{ .named = entry.wrapped },
                        .rhs = .{ .int = 0 },
                    } } else .{ .icmp = .{
                        .predicate = .ne,
                        .operand_ty = .{ .int = 32 },
                        .lhs = .{ .named = entry.wide_overflow },
                        .rhs = .{ .int = 0 },
                    } };
                    try block.instructions.append(allocator, replacement);
                    continue;
                };
            }
            try block.instructions.append(allocator, inst);
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
