//! Private storage view for bounded scalar and aggregate objects. The existing i32
//! array frame allocator owns the bytes; typed byte-address actions own access.
//! This does not legalize aggregate values or alter the source module/ABI.
const std = @import("std");
const ir = @import("../../../ir.zig");
const syntax = @import("../../../ir/parser_syntax.zig");
const target = @import("../../../target.zig");
const machine = @import("../machine.zig");
const pairs = @import("word_pair_memory.zig");
const storage = @import("storage_layout.zig");
const helpers = @import("composed_helpers.zig");
const forms = @import("scalar_forms.zig");

fn trim(text: []const u8) []const u8 {
    return std.mem.trim(u8, text, " \t\r\n");
}

pub fn size(context: ?*const machine.ReadOnlyModuleContext, ty: ir.Type, depth: u8) ?u32 {
    if (depth >= 8 or ty != .aggregate) return null;
    const body = trim(ty.aggregate);
    if (std.mem.startsWith(u8, body, "%")) {
        const ctx = context orelse return null;
        var found: ?[]const u8 = null;
        for (ctx.named_types) |named| if (ir.identifiers.eql(named.name, body[1..])) {
            if (found != null) return null;
            found = named.body;
        };
        return size(context, .{ .aggregate = found orelse return null }, depth + 1);
    }
    if (body.len < 2 or body[0] != '{' or body[body.len - 1] != '}' or
        (syntax.findTopLevelTokenEnd(body) orelse return null) != body.len) return null;
    var fields: [3][]const u8 = undefined;
    var count: usize = 0;
    var rest = trim(body[1 .. body.len - 1]);
    while (rest.len != 0) {
        if (count == fields.len) return null;
        const comma = syntax.findTopLevelComma(rest);
        fields[count] = trim(if (comma) |index| rest[0..index] else rest);
        if (fields[count].len == 0) return null;
        count += 1;
        rest = if (comma) |index| trim(rest[index + 1 ..]) else "";
        if (comma != null and rest.len == 0) return null;
    }
    if (count == 1) return size(context, .{ .aggregate = fields[0] }, depth + 1);
    if (count != 3 or !std.mem.eql(u8, fields[1], "i16") or !pairs.spelling(fields[2], "[6xi8]")) return null;
    if (std.mem.eql(u8, fields[0], "i64")) return 16;
    return if (pairs.isIntegerPair(context, .{ .aggregate = fields[0] })) 24 else null;
}

fn alignment(alloca: ir.AllocaInst) ?u32 {
    if (!alloca.isSingleObject() or alloca.allocated_ty_addrspace != null) return null;
    const text = trim(alloca.attrs orelse return 8);
    if (!std.mem.startsWith(u8, text, "align ")) return null;
    const value = std.fmt.parseUnsigned(u32, trim(text[6..]), 10) catch return null;
    if (value == 0 or value > 16 or !std.math.isPowerOfTwo(value)) return null;
    return @max(value, 8);
}

fn address(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, value: ir.Value) !ir.Value {
    const name = try forms.temporary(allocator, function, serial);
    var indices: std.ArrayList(ir.GepIndex) = .empty;
    try indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .gep = .{
        .source_ty = .{ .int = 8 },
        .ptr = value,
        .indices = indices,
    } } });
    return .{ .named = name };
}

fn slotSize(slots: std.StringHashMap(u32), value: ir.Value) ?u32 {
    return if (value == .named) slots.get(value.named) else null;
}

fn copyLength(function: ir.Function, value: ir.Value) ?i128 {
    if (value == .int) return value.int;
    if (value != .named) return null;
    // Word-pair lowering presents a literal length through this scalar cast.
    // Resolve only that exact constant form, retaining the original range check.
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.result == null or !ir.identifiers.eql(inst.result.?, value.named)) continue;
        if (inst.kind != .cast) return null;
        const cast = inst.kind.cast;
        if (cast.op != .zext or !cast.from_ty.eql(.{ .int = 32 }) or !cast.to_ty.eql(.{ .int = 64 }) or
            cast.value != .int or cast.value.int < 0 or cast.value.int > std.math.maxInt(u32)) return null;
        return cast.value.int;
    };
    return null;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    return legalizeImpl(allocator, function, context, false);
}

pub fn legalizeStorage(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    return legalizeImpl(allocator, function, context, true);
}

fn legalizeImpl(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext, comptime general: bool) !?ir.Function {
    if (!pairs.supportsLayout(context)) return null;
    const dl = target.DataLayout.parse(if (context) |ctx| ctx.target_datalayout orelse "" else "") catch return null;
    inline for (.{ 8, 16, 32 }) |bits| if ((dl.integerAbiAlignmentBits(bits) catch return null) != bits) return null;
    var slots = std.StringHashMap(u32).init(allocator);
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.kind != .alloca or inst.result == null) continue;
        const ty = inst.kind.alloca.allocated_ty;
        const scalar = general and ty == .int and ty.int > 8 and ty.int < 64;
        if ((!scalar and ty != .aggregate) or helpers.parseI32ArrayType(ty) != null) continue;
        const bytes = if (general) (storage.query(context, ty) orelse continue).bytes else size(context, ty, 0) orelse continue;
        // General storage may have private trailing padding. Keep the original
        // extent in slots so memcpy admission never treats that padding as data.
        if (!general and (bytes == 0 or bytes % 4 != 0)) continue;
        _ = alignment(inst.kind.alloca) orelse return null;
        try slots.put(inst.result.?, bytes);
    };
    if (slots.count() == 0) return null;

    var result = function;
    result.blocks = .empty;
    var serial: forms.TemporaryNames = .{ .prefix = "__zllvm_padded_frame_" };
    defer serial.deinit(allocator);
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (!inst.removed) switch (inst.kind) {
                .alloca => |alloca| if (inst.result) |name| {
                    if (slots.get(name)) |bytes| {
                        const carrier_bytes = std.mem.alignForward(u32, @max(bytes, 1), 4);
                        copy.kind.alloca.allocated_ty = .{ .aggregate = try std.fmt.allocPrint(allocator, "[{d} x i32]", .{carrier_bytes / 4}) };
                        const natural = if (general) storage.query(context, alloca.allocated_ty).?.alignment else 8;
                        copy.kind.alloca.attrs = try std.fmt.allocPrint(allocator, "align {d}", .{@max(alignment(alloca).?, natural)});
                    }
                },
                .load => |load| if (slotSize(slots, load.ptr) != null) {
                    if (load.attrs.isBarrier() or load.attrs.syncscope != null or load.ty_addrspace != null or load.ptr_addrspace != null) return null;
                    copy.kind.load.ptr = try address(allocator, function, &block, &serial, load.ptr);
                },
                .store => |store| if (slotSize(slots, store.ptr) != null) {
                    if (store.attrs.isBarrier() or store.attrs.syncscope != null or store.ty_addrspace != null or store.ptr_addrspace != null) return null;
                    copy.kind.store.ptr = try address(allocator, function, &block, &serial, store.ptr);
                },
                .call => |call| {
                    const memcpy = std.mem.eql(u8, call.callee, "llvm.memcpy.p0.p0.i64") or std.mem.eql(u8, call.callee, "llvm.memcpy.inline.p0.p0.i64");
                    var copied = false;
                    for (call.args.items, 0..) |arg, index| if (slotSize(slots, arg.value)) |bytes| {
                        if (arg.ty != .ptr) return null;
                        if (memcpy and index < 2) {
                            if (call.args.items.len != 4) return null;
                            if (copyLength(function, call.args.items[2].value)) |length| {
                                if (length < 0 or length > bytes) return null;
                            } else if (!general or std.mem.eql(u8, call.callee, "llvm.memcpy.inline.p0.p0.i64")) {
                                return null;
                            }
                            // A general byte view retains the runtime length.
                            // Defined source executions stay within the original
                            // extent; private carrier padding grants no extra bytes.
                        }
                        if (!copied) {
                            copy.kind.call.args = try call.args.clone(allocator);
                            copied = true;
                        }
                        copy.kind.call.args.items[index].value = try address(allocator, function, &block, &serial, arg.value);
                    };
                },
                else => {},
            };
            try block.instructions.append(allocator, copy);
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
