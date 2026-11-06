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
    var serial: usize = 0;
    var changed = false;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            if (!inst.removed and inst.result != null and inst.kind == .gep) {
                const gep = inst.kind.gep;
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
