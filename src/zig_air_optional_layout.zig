const std = @import("std");
const ir = @import("ir.zig");
const types = @import("zig_air_types.zig");
const model = @import("zig_air_model.zig");
const layout = @import("zig_air_type_layout.zig");
const facts = @import("zig_air_aggregate_layout_facts.zig");
const aggregates = @import("zig_air_aggregate_values.zig");
const target = @import("target.zig");

pub const Representation = struct {
    payload: model.ZigType,
    tag_offset: ?u64,
};

pub fn representation(text: []const u8) ?Representation {
    if (text.len < 2 or text[0] != '?') return null;
    const child = std.mem.trim(u8, text[1..], " ");
    const payload = types.parseZigType(child) orelse return null;
    if (types.optionalUsesPointerSentinel(text)) return .{ .payload = payload, .tag_offset = null };
    // Error sets and slices can reserve a payload value for null. Their ABI
    // needs an explicit representation contract before generic admission.
    if (std.mem.startsWith(u8, child, "error") or std.mem.eql(u8, child, "anyerror") or
        std.mem.startsWith(u8, child, "[]") or std.mem.startsWith(u8, child, "[:")) return null;
    if (payload.ir_type == .ptr and !std.mem.startsWith(u8, child, "*")) return null;
    const dl = target.DataLayout.parse("e-m:e-p:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128") catch return null;
    const normalized = layout.normalizeAggregateTypeChecked(payload.ir_type) catch return null;
    const size = dl.typeStoreSizeBytes(normalized) catch return null;
    const alignment_bits = dl.typeAbiAlignmentBits(normalized) catch return null;
    const alignment = @max(@as(u64, 1), (@as(u64, alignment_bits) + 7) / 8);
    const computed = std.mem.alignForward(u64, size, alignment);
    const exported = layout.aggregateLayoutSummaryChecked(child) catch return null;
    const tag_offset = if (exported != null) computed else facts.nominalTypeByteSize(child) orelse computed;
    return .{ .payload = payload, .tag_offset = tag_offset };
}

pub fn loadTag(self: anytype, index: u32, ptr: ir.Value, offset: u64, is_volatile: bool) !ir.Value {
    var address = ptr;
    if (offset != 0) {
        const name = try model.ownPrint(self.module, "air{}_optional_tag_ptr", .{index});
        var gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = ptr, .indices = .empty };
        errdefer gep.deinit(self.allocator);
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = offset } });
        try self.block.instructions.append(self.allocator, .{ .result = name, .kind = .{ .gep = gep } });
        address = .{ .named = name };
    }
    const name = try model.ownPrint(self.module, "air{}_optional_tag", .{index});
    try self.block.instructions.append(self.allocator, .{ .result = name, .kind = .{ .load = .{
        .ty = .{ .int = 8 },
        .ptr = address,
        .attrs = .{ .is_volatile = is_volatile },
    } } });
    return .{ .named = name };
}

pub fn captureLoad(self: anytype, index: u32, optional_text: []const u8, ptr: ir.Value, is_volatile: bool) !bool {
    const repr = representation(optional_text) orelse return error.UnsupportedAir;
    const tag_offset = repr.tag_offset orelse return false;
    if (is_volatile) return error.UnsupportedAir;
    const tag = try loadTag(self, index, ptr, tag_offset, false);
    const payload: ir.Value = if (repr.payload.ir_type == .aggregate)
        try aggregates.load(self, index, repr.payload.ir_type, ptr)
    else if (repr.payload.ir_type == .void or repr.payload.ir_type.eql(.{ .int = 0 }))
        .zero_initializer
    else blk: {
        const name = try model.ownPrint(self.module, "air{}_optional_payload", .{index});
        try self.block.instructions.append(self.allocator, .{ .result = name, .kind = .{ .load = .{ .ty = repr.payload.ir_type, .ptr = ptr } } });
        break :blk ir.Value{ .named = name };
    };
    if (index >= self.synthetic_optional_ptrs.len) return error.UnsupportedAir;
    self.synthetic_optional_ptrs[index] = .{
        .base_ptr = ptr,
        .optional_type_text = optional_text,
        .tag_value = tag,
        .payload_value = .{ .ty = repr.payload, .value = payload },
    };
    self.values[index] = .{ .ty = types.parseZigType(optional_text) orelse return error.UnsupportedAir, .value = payload };
    return true;
}
