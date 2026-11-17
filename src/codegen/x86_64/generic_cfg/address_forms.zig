//! Canonical byte offsets for exact, bounded pointee allocation sizes. The
//! original module remains untouched; ordinary pointer actions own emission.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const storage = @import("storage_layout.zig");
const addresses = @import("../symbol_address.zig");
const forms = @import("scalar_forms.zig");

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!addresses.supportsLayout(if (context) |ctx| ctx.target_datalayout else null)) return null;
    var result = function;
    result.blocks = .empty;
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    var changed = false;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            if (!inst.removed and inst.result != null and inst.kind == .gep) {
                const gep = inst.kind.gep;
                // A recognized table owns element scaling and its range proof.
                if (try tableOwnsStride(allocator, context, gep)) {
                    try block.instructions.append(allocator, inst);
                    continue;
                }
                if (gep.ptr_addrspace == null and gep.indices.items.len >= 2 and
                    gep.indices.items[0].ty == .int and gep.indices.items[0].ty.int <= 64 and
                    (gep.indices.items[0].value.eql(.{ .int = 0 }) or
                        (gep.indices.items[0].ty.int == 64 and
                            (gep.indices.items[0].value == .int or gep.indices.items[0].value == .named))))
                {
                    if (structureOffset(context, gep)) |offset| {
                        var base = gep.ptr;
                        if (!gep.indices.items[0].value.eql(.{ .int = 0 })) {
                            // Keep allocation stride and member placement as
                            // separate proven GEPs. The normal byte-offset
                            // path below owns scaling on the next iteration.
                            const name = try forms.temporary(allocator, function, &serial);
                            var step = inst;
                            step.result = name;
                            step.kind.gep.indices = .empty;
                            try step.kind.gep.indices.append(allocator, gep.indices.items[0]);
                            try block.instructions.append(allocator, step);
                            base = .{ .named = name };
                        }
                        var copy = inst;
                        copy.kind.gep.ptr = base;
                        copy.kind.gep.source_ty = .{ .int = 8 };
                        copy.kind.gep.indices = .empty;
                        try copy.kind.gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = offset } });
                        try block.instructions.append(allocator, copy);
                        changed = true;
                        continue;
                    }
                }
                // A leading zero steps within the same array; the second
                // index selects a byte. Keep the layout proof explicit and
                // reuse ordinary byte addressing for globals and parameters.
                if (gep.ptr_addrspace == null and gep.indices.items.len == 2 and
                    gep.indices.items[0].ty.eql(.{ .int = 64 }) and gep.indices.items[0].value.eql(.{ .int = 0 }) and
                    gep.indices.items[1].ty.eql(.{ .int = 64 }) and isByteArray(context, gep.source_ty))
                {
                    var copy = inst;
                    copy.kind.gep.source_ty = .{ .int = 8 };
                    copy.kind.gep.indices = .empty;
                    try copy.kind.gep.indices.append(allocator, gep.indices.items[1]);
                    try block.instructions.append(allocator, copy);
                    changed = true;
                    continue;
                }
                // A bounded array uses its element allocation stride, including
                // vector tail padding. The next iteration owns byte scaling.
                if (gep.ptr_addrspace == null and gep.indices.items.len == 2 and
                    gep.indices.items[0].ty.eql(.{ .int = 64 }) and gep.indices.items[0].value.eql(.{ .int = 0 }) and
                    gep.indices.items[1].ty.eql(.{ .int = 64 }) and
                    (gep.indices.items[1].value == .int or gep.indices.items[1].value == .named))
                {
                    if (arrayElement(context, gep.source_ty)) |element| {
                        var copy = inst;
                        copy.kind.gep.source_ty = element;
                        copy.kind.gep.indices = .empty;
                        try copy.kind.gep.indices.append(allocator, gep.indices.items[1]);
                        try block.instructions.append(allocator, copy);
                        changed = true;
                        continue;
                    }
                }
                if (gep.ptr_addrspace == null and gep.indices.items.len == 1 and
                    !gep.source_ty.eql(.{ .int = 8 }) and gep.indices.items[0].ty.eql(.{ .int = 64 }) and
                    (gep.indices.items[0].value == .int or gep.indices.items[0].value == .named))
                {
                    if (storage.query(context, gep.source_ty)) |layout| {
                        const index = gep.indices.items[0].value;
                        var offset: ir.Value = undefined;
                        if (index == .int) {
                            // GEP index arithmetic wraps at the pointer index width.
                            const bits: u64 = @truncate(@as(u128, @bitCast(index.int)));
                            offset = .{ .int = @as(i64, @bitCast(bits *% @as(u64, layout.bytes))) };
                        } else if (layout.bytes == 0) {
                            offset = .{ .int = 0 };
                        } else if (layout.bytes == 1) {
                            offset = index;
                        } else {
                            const name = try forms.temporary(allocator, function, &serial);
                            try block.instructions.append(allocator, .{ .result = name, .kind = .{ .binary = .{
                                .op = .mul,
                                .ty = .{ .int = 64 },
                                .lhs = index,
                                .rhs = .{ .int = layout.bytes },
                            } } });
                            offset = .{ .named = name };
                        }
                        var copy = inst;
                        copy.kind.gep.source_ty = .{ .int = 8 };
                        copy.kind.gep.indices = .empty;
                        try copy.kind.gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = offset });
                        try block.instructions.append(allocator, copy);
                        changed = true;
                        continue;
                    }
                }
            }
            try block.instructions.append(allocator, inst);
        }
        try result.blocks.append(allocator, block);
    }
    return if (changed) result else null;
}

fn tableOwnsStride(allocator: std.mem.Allocator, context: ?*const machine.ReadOnlyModuleContext, gep: ir.GepInst) !bool {
    const ctx = context orelse return false;
    if (gep.ptr_addrspace != null or gep.ptr != .named or !std.mem.startsWith(u8, gep.ptr.named, "@") or gep.indices.items.len != 1) return false;
    const tables = @import("../constant_table.zig");
    var decoded = (tables.decodeSymbol(allocator, ctx.*, gep.ptr.named) catch |err| {
        if (err == error.OutOfMemory) return err;
        return false;
    }) orelse return false;
    defer decoded.deinit(allocator);
    return tables.sourceStrideMatches(ctx.target_datalayout, gep.source_ty, decoded.shape);
}

fn structureOffset(context: ?*const machine.ReadOnlyModuleContext, gep: ir.GepInst) ?u32 {
    if (gep.indices.items.len > 32) return null;
    var ty = gep.source_ty;
    var offset: u32 = 0;
    for (gep.indices.items[1..]) |index| {
        if (!index.ty.eql(.{ .int = 32 }) or index.value != .int) return null;
        const member = storage.fieldInfo(context, ty, std.math.cast(usize, index.value.int) orelse return null) orelse return null;
        offset = std.math.add(u32, offset, member.offset) catch return null;
        ty = member.ty;
    }
    return offset;
}

fn isByteArray(context: ?*const machine.ReadOnlyModuleContext, ty: ir.Type) bool {
    if (ty != .aggregate) return false;
    const text = std.mem.trim(u8, ty.aggregate, " \t\r\n");
    if (text.len < 2 or text[0] != '[' or text[text.len - 1] != ']') return false;
    var tokens = std.mem.tokenizeAny(u8, text[1 .. text.len - 1], " \t\r\n");
    _ = std.fmt.parseUnsigned(u32, tokens.next() orelse return false, 10) catch return false;
    if (!std.mem.eql(u8, tokens.next() orelse return false, "x") or
        !std.mem.eql(u8, tokens.next() orelse return false, "i8") or tokens.next() != null) return false;
    _ = storage.query(context, ty) orelse return false;
    const element = storage.query(context, .{ .int = 8 }) orelse return false;
    return element.bytes == 1;
}

fn arrayElement(context: ?*const machine.ReadOnlyModuleContext, original: ir.Type) ?ir.Type {
    _ = storage.query(context, original) orelse return null;
    var ty = original;
    for (0..32) |_| {
        if (ty != .aggregate) return null;
        const text = std.mem.trim(u8, ty.aggregate, " \t\r\n");
        if (text.len == 0) return null;
        if (text[0] == '%') {
            const ctx = context orelse return null;
            var body: ?[]const u8 = null;
            for (ctx.named_types) |named| if (ir.identifiers.eql(named.name, text[1..])) {
                if (body != null) return null;
                body = named.body;
            };
            ty = @import("../../../ir/parser_types_values.zig").parseType(body orelse return null) catch return null;
            continue;
        }
        if (text.len < 2 or text[0] != '[' or text[text.len - 1] != ']') return null;
        var tokens = std.mem.tokenizeAny(u8, text[1 .. text.len - 1], " \t\r\n");
        _ = std.fmt.parseUnsigned(u32, tokens.next() orelse return null, 10) catch return null;
        if (!std.mem.eql(u8, tokens.next() orelse return null, "x")) return null;
        const element = @import("../../../ir/parser_types_values.zig").parseType(tokens.rest()) catch return null;
        // The existing byte-array path separately proves the byte stride.
        // In particular i8:16 layouts cannot use ordinary one-byte GEPs.
        if (element.eql(.{ .int = 8 })) return null;
        _ = storage.query(context, element) orelse return null;
        return element;
    }
    return null;
}
