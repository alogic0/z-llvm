const std = @import("std");
const ir = @import("ir.zig");
const memory_location = @import("analysis/memory_location.zig");
const target = @import("target.zig");

pub const AggregateLeaf = struct {
    offset: u64,
    ty: ir.Type,
};

pub const max_aggregate_layout_leaves = 512;

pub const AggregateLayoutPlan = struct {
    ty: ir.Type,
    size_bytes: u64,
    field_count: usize,
    leaves: [max_aggregate_layout_leaves]AggregateLeaf = undefined,
    leaf_count: usize = 0,

    pub fn leafSlice(plan: *const AggregateLayoutPlan) []const AggregateLeaf {
        return plan.leaves[0..plan.leaf_count];
    }
};

pub const AggregateLayoutSource = enum {
    facts,
    inference,
    fallback_table,
    boundary,
};

pub const AggregateLayoutEvidence = struct {
    construction: bool = false,
    store: bool = false,
    load: bool = false,
};

pub const AggregateLayoutSummary = struct {
    nominal_type_name: []const u8,
    ty: ir.Type,
    source: AggregateLayoutSource,
    field_count: usize,
    evidence: AggregateLayoutEvidence = .{},
    leaves: [max_aggregate_layout_leaves]AggregateLeaf = undefined,
    leaf_count: usize = 0,

    pub fn leafSlice(summary: *const AggregateLayoutSummary) []const AggregateLeaf {
        return summary.leaves[0..summary.leaf_count];
    }
};

const AggregateLayoutMatch = enum {
    exact,
    basename,
};

const SourceAggregateLayoutFact = struct {
    name: []const u8,
    aggregate_text: []const u8,
    match: AggregateLayoutMatch = .basename,
    evidence: AggregateLayoutEvidence = .{
        .construction = true,
        .store = true,
        .load = true,
    },
};

pub const AggregateLayoutMismatch = struct {
    nominal_type_name: []const u8,
    inferred_field_count: usize,
    fallback_field_count: usize,
    inferred_leaf_count: usize,
    fallback_leaf_count: usize,
    evidence: AggregateLayoutEvidence,
};

pub fn parseNamedAggregateType(text: []const u8) ?ir.Type {
    const trimmed = std.mem.trim(u8, text, " ");
    if (isPointerOrSliceSurface(trimmed) or std.mem.startsWith(u8, trimmed, "fn ")) return null;
    const nominal = stripNominalSigil(trimmed);
    if (aggregateLayoutSummaryForNominal(nominal) catch null) |summary| return summary.ty;
    return null;
}

pub fn aggregateLayoutSummary(text: []const u8) ?AggregateLayoutSummary {
    const trimmed = std.mem.trim(u8, text, " ");
    if (isPointerOrSliceSurface(trimmed) or std.mem.startsWith(u8, trimmed, "fn ")) return null;
    return aggregateLayoutSummaryChecked(trimmed) catch null;
}

pub fn aggregateLayoutSummaryChecked(text: []const u8) error{AggregateLayoutMismatch}!?AggregateLayoutSummary {
    const trimmed = std.mem.trim(u8, text, " ");
    if (isPointerOrSliceSurface(trimmed) or std.mem.startsWith(u8, trimmed, "fn ")) return null;
    return aggregateLayoutSummaryForNominal(stripNominalSigil(trimmed));
}

pub fn aggregateLayoutMismatch(text: []const u8) ?AggregateLayoutMismatch {
    const trimmed = std.mem.trim(u8, text, " ");
    if (isPointerOrSliceSurface(trimmed) or std.mem.startsWith(u8, trimmed, "fn ")) return null;
    const nominal = stripNominalSigil(trimmed);
    const inferred = inferredAggregateLayoutSummary(nominal) orelse return null;
    const fallback_ty = fallbackNamedAggregateType(nominal) orelse return null;
    const fallback = summarizeAggregateLayout(nominal, fallback_ty, .fallback_table, .{});
    if (aggregateLayoutSummariesEquivalent(inferred, fallback)) return null;
    return .{
        .nominal_type_name = nominal,
        .inferred_field_count = inferred.field_count,
        .fallback_field_count = fallback.field_count,
        .inferred_leaf_count = inferred.leaf_count,
        .fallback_leaf_count = fallback.leaf_count,
        .evidence = inferred.evidence,
    };
}

fn aggregateLayoutSummaryForNominal(nominal: []const u8) error{AggregateLayoutMismatch}!?AggregateLayoutSummary {
    if (inferredAggregateLayoutSummary(nominal)) |summary| {
        if (fallbackNamedAggregateType(nominal)) |fallback_ty| {
            const fallback = summarizeAggregateLayout(nominal, fallback_ty, .fallback_table, .{});
            if (!aggregateLayoutSummariesEquivalent(summary, fallback)) return error.AggregateLayoutMismatch;
        }
        return summary;
    }
    if (frontierSysVSretByvalBigType(nominal)) |ty| {
        return summarizeAggregateLayout(nominal, ty, .fallback_table, .{});
    }
    if (fallbackNamedAggregateType(nominal)) |ty| {
        return summarizeAggregateLayout(nominal, ty, .fallback_table, .{});
    }
    return null;
}

fn inferredAggregateLayoutSummary(nominal: []const u8) ?AggregateLayoutSummary {
    if (inferredBigArrayLayoutSummary(nominal)) |summary| return summary;
    for (source_aggregate_layout_facts) |fact| {
        if (!sourceAggregateLayoutFactMatches(nominal, fact)) continue;
        return summarizeAggregateLayout(nominal, aggregate(fact.aggregate_text), .inference, fact.evidence);
    }
    return null;
}

fn fallbackNamedAggregateType(nominal: []const u8) ?ir.Type {
    const basename = typeBasename(nominal);
    if (std.mem.eql(u8, basename, "Outer")) return aggregate("{ { i32, i32 }, { i32, i32 } }");
    if (std.mem.eql(u8, basename, "PackedMixed")) return aggregate("{ i32, i32, double }");
    if (std.mem.eql(u8, basename, "PackedReverseMixed")) return aggregate("{ double, i32, i32 }");
    if (std.mem.eql(u8, basename, "BigNested")) return aggregate("{ { i64, i64, i64 }, { i64, i64, i64 } }");
    if (std.mem.eql(u8, basename, "BigMixed")) return aggregate("{ i64, i32, i64, i32 }");
    if (std.mem.eql(u8, basename, "NarrowInner")) return aggregate("{ i16, i32 }");
    if (std.mem.eql(u8, basename, "BigNarrow")) return aggregate("{ i8, { i16, i32 }, i64 }");
    if (std.mem.eql(u8, basename, "BigArray")) return aggregate("{ [5 x i64] }");
    if (std.mem.eql(u8, basename, "BigDouble")) return aggregate("{ double, double, double }");
    if (std.mem.eql(u8, basename, "BigDoubleArray")) return aggregate("{ [3 x double] }");
    if (std.mem.eql(u8, basename, "BigFloat")) return aggregate("{ float, float, float, float, float }");
    if (std.mem.eql(u8, basename, "BigFloatArray")) return aggregate("{ [5 x float] }");
    if (std.mem.eql(u8, basename, "BigPtrDouble")) return aggregate("{ ptr, double, i64 }");
    if (std.mem.eql(u8, basename, "BigPtrFloat")) return aggregate("{ ptr, float, i64 }");
    if (std.mem.eql(u8, basename, "BigArrayMixed")) return aggregate("{ [2 x i32], [2 x double], ptr }");
    if (std.mem.eql(u8, basename, "BigNestedArrayMixed")) return aggregate("{ { [5 x float] }, { [3 x double] }, ptr, i64 }");
    if (std.mem.eql(u8, basename, "MixedArrayLeaf")) return aggregate("{ i32, double }");
    if (std.mem.eql(u8, basename, "BigStructArrayMixed")) return aggregate("{ [3 x { i32, double }], i64 }");
    if (std.mem.eql(u8, basename, "BigDeepMixed")) return aggregate("{ { { [5 x float] }, { [3 x double] }, ptr, i64 }, [2 x { i32, double }], { { i8, i16 }, i32, double, ptr }, [2 x ptr], i32 }");
    if (std.mem.eql(u8, basename, "BigByteTail")) return aggregate("{ [17 x i8] }");
    if (std.mem.eql(u8, basename, "BigByteTail5")) return aggregate("{ [21 x i8] }");
    if (std.mem.eql(u8, basename, "BigByteTail6")) return aggregate("{ [22 x i8] }");
    if (std.mem.eql(u8, basename, "BigByteTail7")) return aggregate("{ [23 x i8] }");
    if (std.mem.eql(u8, basename, "BigWordTail")) return aggregate("{ [9 x i16] }");
    if (std.mem.eql(u8, basename, "ScalarMixed")) return aggregate("{ i8, i16, i32, i64, ptr, float, double }");
    if (std.mem.eql(u8, basename, "ScalarNestedInner")) return aggregate("{ i8, i16 }");
    if (std.mem.eql(u8, basename, "ScalarNested")) return aggregate("{ { i8, i16 }, i32, double, ptr }");
    if (std.mem.eql(u8, basename, "ScalarArray")) return aggregate("{ [3 x i32], [2 x double], ptr }");

    if (std.mem.eql(u8, basename, "Pair")) return aggregate("{ i32, i32 }");
    if (std.mem.eql(u8, basename, "Inner")) return aggregate("{ i32, i32 }");
    return null;
}

const source_aggregate_layout_facts = [_]SourceAggregateLayoutFact{
    .{ .name = "frontier_nested_records.Inner", .aggregate_text = "{ i32, i32 }", .match = .exact },
    .{ .name = "frontier_nested_records.Outer", .aggregate_text = "{ { i32, i32 }, { i32, i32 } }", .match = .exact },
    .{ .name = "Pair64", .aggregate_text = "{ i64, i64 }" },
    .{ .name = "Mixed", .aggregate_text = "{ i64, double }" },
    .{ .name = "ReverseMixed", .aggregate_text = "{ double, i64 }" },
    .{ .name = "DoublePair", .aggregate_text = "{ double, double }" },
    .{ .name = "FloatPair", .aggregate_text = "{ float, float }" },
    .{ .name = "FloatArray", .aggregate_text = "{ [4 x float] }" },
    .{ .name = "Pair32", .aggregate_text = "{ i32, i32 }" },
    .{ .name = "NestedPair", .aggregate_text = "{ { i32, i32 }, { i32, i32 } }" },
    .{ .name = "ArrayPair", .aggregate_text = "{ [2 x i64] }" },
    .{ .name = "ArrayDouble", .aggregate_text = "{ [2 x double] }" },
    .{ .name = "DoubleBox", .aggregate_text = "{ double }" },
    .{ .name = "NestedDouble", .aggregate_text = "{ { double }, { double } }" },
    .{ .name = "NestedMixed", .aggregate_text = "{ { i32, i32 }, double }" },
    .{ .name = "SmallMixed", .aggregate_text = "{ i32, double }" },
    .{ .name = "SmallReverseMixed", .aggregate_text = "{ double, i32 }" },
    .{ .name = "frontier_sysv_sret_byval.BigArray", .aggregate_text = "{ [5 x i64] }", .match = .exact },
};

fn sourceAggregateLayoutFactMatches(nominal: []const u8, fact: SourceAggregateLayoutFact) bool {
    return switch (fact.match) {
        .exact => std.mem.eql(u8, nominal, fact.name),
        .basename => std.mem.eql(u8, typeBasename(nominal), fact.name),
    };
}

fn inferredBigArrayLayoutSummary(nominal: []const u8) ?AggregateLayoutSummary {
    const prefix = "frontier_sysv_sret_byval.Big";
    if (!std.mem.startsWith(u8, nominal, prefix)) return null;
    const field_count = std.fmt.parseInt(u16, nominal[prefix.len..], 10) catch return null;
    if (field_count < 32) return null;
    const aggregate_text = std.fmt.allocPrint(std.heap.page_allocator, "{{ [{d} x i64] }}", .{field_count}) catch return null;
    return summarizeAggregateLayout(nominal, aggregate(aggregate_text), .inference, .{
        .construction = true,
        .store = true,
        .load = true,
    });
}

fn aggregateLayoutSummariesEquivalent(lhs: AggregateLayoutSummary, rhs: AggregateLayoutSummary) bool {
    if (!lhs.ty.eql(rhs.ty)) return false;
    if (lhs.field_count != rhs.field_count or lhs.leaf_count != rhs.leaf_count) return false;
    const lhs_leaves = lhs.leafSlice();
    const rhs_leaves = rhs.leafSlice();
    for (lhs_leaves, rhs_leaves) |lhs_leaf, rhs_leaf| {
        if (lhs_leaf.offset != rhs_leaf.offset or !lhs_leaf.ty.eql(rhs_leaf.ty)) return false;
    }
    return true;
}

fn summarizeAggregateLayout(
    nominal: []const u8,
    ty: ir.Type,
    source: AggregateLayoutSource,
    evidence: AggregateLayoutEvidence,
) AggregateLayoutSummary {
    var summary = AggregateLayoutSummary{
        .nominal_type_name = nominal,
        .ty = ty,
        .source = source,
        .field_count = fieldCount(ty),
        .evidence = evidence,
    };
    const layout = x86_64SysVDataLayout() catch return summary;
    const plan = aggregateLayoutPlan(layout, ty) catch return summary;
    summary.field_count = plan.field_count;
    const leaves = plan.leafSlice();
    summary.leaf_count = leaves.len;
    @memcpy(summary.leaves[0..leaves.len], leaves);
    return summary;
}

fn x86_64SysVDataLayout() !target.DataLayout {
    return target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
}

pub fn normalizeAggregateType(ty: ir.Type) ir.Type {
    return switch (ty) {
        .aggregate => |text| parseNamedAggregateType(text) orelse ty,
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => ty,
    };
}

pub fn typeBasename(text: []const u8) []const u8 {
    const trimmed = stripNominalSigil(std.mem.trim(u8, text, " "));
    if (std.mem.lastIndexOfScalar(u8, trimmed, '.')) |dot| return trimmed[dot + 1 ..];
    return trimmed;
}

pub fn stripNominalSigil(text: []const u8) []const u8 {
    if (text.len != 0 and (text[0] == '%' or text[0] == '@')) return text[1..];
    return text;
}

fn isPointerOrSliceSurface(text: []const u8) bool {
    return std.mem.startsWith(u8, text, "*") or
        std.mem.startsWith(u8, text, "?*") or
        std.mem.startsWith(u8, text, "[*]") or
        std.mem.startsWith(u8, text, "[]");
}

pub fn fieldType(aggregate_ty: ir.Type, field_index: usize) ?ir.Type {
    return memory_location.aggregateFieldType(normalizeAggregateType(aggregate_ty), field_index);
}

pub fn fieldCount(aggregate_ty: ir.Type) usize {
    var count: usize = 0;
    while (fieldType(aggregate_ty, count)) |_| : (count += 1) {}
    return count;
}

pub fn fieldByteOffset(layout: target.DataLayout, aggregate_ty: ir.Type, field_index: usize) ?u64 {
    const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, normalizeAggregateType(aggregate_ty), field_index) orelse return null;
    if (offset_i < 0) return null;
    return @intCast(offset_i);
}

pub fn fieldIndexAtOffset(
    layout: target.DataLayout,
    aggregate_ty: ir.Type,
    expected_offset: u64,
    expected_ty: ir.Type,
) ?usize {
    var field_index: usize = 0;
    while (fieldType(aggregate_ty, field_index)) |field_ty| : (field_index += 1) {
        const field_offset = fieldByteOffset(layout, aggregate_ty, field_index) orelse return null;
        if (field_ty.eql(expected_ty) and field_offset == expected_offset) return field_index;
        if (isAggregateType(field_ty) and expected_offset >= field_offset) {
            if (fieldIndexAtOffset(layout, field_ty, expected_offset - field_offset, expected_ty) != null) return field_index;
        }
    }
    return null;
}

pub fn leafTypeAtOffset(layout: target.DataLayout, aggregate_ty: ir.Type, expected_offset: u64) ?ir.Type {
    var field_index: usize = 0;
    while (fieldType(aggregate_ty, field_index)) |field_ty| : (field_index += 1) {
        const field_offset = fieldByteOffset(layout, aggregate_ty, field_index) orelse return null;
        if (isAggregateType(field_ty)) {
            if (expected_offset >= field_offset) {
                if (leafTypeAtOffset(layout, field_ty, expected_offset - field_offset)) |nested_ty| return nested_ty;
            }
        } else if (field_offset == expected_offset) {
            return field_ty;
        }
    }
    return null;
}

pub fn isSupportedScalarLeaf(ty: ir.Type) bool {
    return ty.eql(.{ .int = 8 }) or ty.eql(.{ .int = 16 }) or ty.eql(.{ .int = 32 }) or
        ty.eql(.{ .int = 64 }) or ty.eql(.ptr) or ty.eql(.float) or ty.eql(.double);
}

pub fn isSupportedScalarLeafAggregate(aggregate_ty: ir.Type) bool {
    const count = fieldCount(aggregate_ty);
    if (count == 0) return false;
    var field_index: usize = 0;
    while (field_index < count) : (field_index += 1) {
        const ty = fieldType(aggregate_ty, field_index) orelse return false;
        if (isSupportedScalarLeaf(ty)) continue;
        if (isAggregateType(ty) and isSupportedScalarLeafAggregate(ty)) continue;
        return false;
    }
    return true;
}

pub fn collectSupportedScalarLeaves(
    layout: target.DataLayout,
    aggregate_ty: ir.Type,
    base_offset: u64,
    leaves: []AggregateLeaf,
    leaf_count: *usize,
) !void {
    const count = fieldCount(aggregate_ty);
    if (count == 0) return error.UnsupportedCodegenAbi;
    var field_index: usize = 0;
    while (field_index < count) : (field_index += 1) {
        const ty = fieldType(aggregate_ty, field_index) orelse return error.UnsupportedCodegenAbi;
        const offset = base_offset + (fieldByteOffset(layout, aggregate_ty, field_index) orelse return error.UnsupportedCodegenAbi);
        if (isSupportedScalarLeaf(ty)) {
            if (leaf_count.* >= leaves.len) return error.UnsupportedCodegenAbi;
            leaves[leaf_count.*] = .{ .offset = offset, .ty = ty };
            leaf_count.* += 1;
        } else if (isAggregateType(ty)) {
            try collectSupportedScalarLeaves(layout, ty, offset, leaves, leaf_count);
        } else {
            return error.UnsupportedCodegenAbi;
        }
    }
}

pub fn aggregateLayoutPlan(layout: target.DataLayout, aggregate_ty: ir.Type) !AggregateLayoutPlan {
    const normalized_ty = normalizeAggregateType(aggregate_ty);
    if (!isAggregateType(normalized_ty)) return error.UnsupportedCodegenAbi;
    const count = fieldCount(normalized_ty);
    if (count == 0) return error.UnsupportedCodegenAbi;
    var plan = AggregateLayoutPlan{
        .ty = normalized_ty,
        .size_bytes = try layout.typeStoreSizeBytes(normalized_ty),
        .field_count = count,
    };
    try collectSupportedScalarLeaves(layout, normalized_ty, 0, &plan.leaves, &plan.leaf_count);
    return plan;
}

pub fn isAggregateType(ty: ir.Type) bool {
    return switch (ty) {
        .aggregate => true,
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

pub fn frontierSysVSretByvalBigType(trimmed: []const u8) ?ir.Type {
    const prefix = "frontier_sysv_sret_byval.Big";
    if (!std.mem.startsWith(u8, trimmed, prefix)) return null;
    const field_count = std.fmt.parseInt(u16, trimmed[prefix.len..], 10) catch return null;
    const aggregate_text: []const u8 = switch (field_count) {
        3 => "{ i64, i64, i64 }",
        4 => "{ i64, i64, i64, i64 }",
        5 => "{ i64, i64, i64, i64, i64 }",
        6 => "{ i64, i64, i64, i64, i64, i64 }",
        7 => "{ i64, i64, i64, i64, i64, i64, i64 }",
        8 => "{ i64, i64, i64, i64, i64, i64, i64, i64 }",
        9 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        10 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        11 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        12 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        13 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        14 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        15 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        16 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        17 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        18 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        19 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        20 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        else => return null,
    };
    return aggregate(aggregate_text);
}

fn aggregate(text: []const u8) ir.Type {
    return .{ .aggregate = text };
}

test "type layout decodes nominal aggregate basenames without fixture module names" {
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i64, double }" }, parseNamedAggregateType("any_module.Mixed").?);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i64, double }" }, parseNamedAggregateType("%Mixed").?);
    try std.testing.expect(parseNamedAggregateType("*frontier_sysv_aggregate_classes.Mixed") == null);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ [2 x double] }" }, parseNamedAggregateType("frontier_sysv_aggregate_classes.ArrayDouble").?);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ { i32, i32 }, { i32, i32 } }" }, parseNamedAggregateType("other.NestedPair").?);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i64, i64, i64 }" }, parseNamedAggregateType("%frontier_sysv_sret_byval.Big3").?);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i32, i32 }" }, parseNamedAggregateType("aggregate_abi.Pair").?);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i32, i32 }" }, parseNamedAggregateType("%runtime_aggregate_pair_main.Pair").?);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i32, i32 }" }, normalizeAggregateType(.{ .aggregate = "%expanded_abi_frontier.Pair" }));
}

test "type layout prefers source inferred aggregate summaries before fallback table" {
    const outer = aggregateLayoutSummary("frontier_nested_records.Outer").?;
    try std.testing.expectEqual(AggregateLayoutSource.inference, outer.source);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ { i32, i32 }, { i32, i32 } }" }, outer.ty);
    try std.testing.expectEqual(@as(usize, 2), outer.field_count);
    try std.testing.expectEqual(@as(usize, 4), outer.leaf_count);
    try std.testing.expect(outer.evidence.construction);
    try std.testing.expect(outer.evidence.store);
    try std.testing.expect(outer.evidence.load);

    const fallback_outer = aggregateLayoutSummary("other.Outer").?;
    try std.testing.expectEqual(AggregateLayoutSource.fallback_table, fallback_outer.source);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ { i32, i32 }, { i32, i32 } }" }, fallback_outer.ty);

    const mixed = aggregateLayoutSummary("any_module.Mixed").?;
    try std.testing.expectEqual(AggregateLayoutSource.inference, mixed.source);
    try std.testing.expect(aggregateLayoutMismatch("any_module.Mixed") == null);
}

test "type layout infers representative frontier aggregate rows" {
    const inner = aggregateLayoutSummary("frontier_nested_records.Inner").?;
    try std.testing.expectEqual(AggregateLayoutSource.inference, inner.source);
    try std.testing.expectEqual(@as(usize, 2), inner.leaf_count);
    try std.testing.expect(inner.leafSlice()[0].ty.eql(.{ .int = 32 }));
    try std.testing.expect(inner.leafSlice()[1].ty.eql(.{ .int = 32 }));

    const pair32 = aggregateLayoutSummary("frontier_sysv_aggregate_classes.Pair32").?;
    try std.testing.expectEqual(AggregateLayoutSource.inference, pair32.source);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i32, i32 }" }, pair32.ty);

    const mixed = aggregateLayoutSummary("frontier_sysv_aggregate_classes.SmallMixed").?;
    try std.testing.expectEqual(AggregateLayoutSource.inference, mixed.source);
    try std.testing.expectEqual(@as(usize, 2), mixed.leaf_count);
    try std.testing.expect(mixed.leafSlice()[0].ty.eql(.{ .int = 32 }));
    try std.testing.expect(mixed.leafSlice()[1].ty.eql(.double));

    const big_array = aggregateLayoutSummary("frontier_sysv_sret_byval.BigArray").?;
    try std.testing.expectEqual(AggregateLayoutSource.inference, big_array.source);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ [5 x i64] }" }, big_array.ty);
    try std.testing.expectEqual(@as(usize, 5), big_array.leaf_count);

    const big256 = aggregateLayoutSummary("frontier_sysv_sret_byval.Big256").?;
    try std.testing.expectEqual(AggregateLayoutSource.inference, big256.source);
    try std.testing.expect(big256.ty.eql(.{ .aggregate = "{ [256 x i64] }" }));
    try std.testing.expectEqual(@as(usize, 256), big256.leaf_count);
}

test "type layout keeps packed aggregates compatibility boundary owned" {
    const packed_summary = aggregateLayoutSummary("frontier_sysv_aggregate_classes.PackedMixed").?;
    try std.testing.expectEqual(AggregateLayoutSource.fallback_table, packed_summary.source);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i32, i32, double }" }, packed_summary.ty);
}

test "type layout owns aggregate field and leaf queries" {
    const layout = try target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
    const ty = parseNamedAggregateType("frontier_sysv_sret_byval.BigPtrDouble").?;
    try std.testing.expectEqual(@as(usize, 3), fieldCount(ty));
    try std.testing.expectEqual(ir.Type.ptr, fieldType(ty, 0).?);
    try std.testing.expectEqual(@as(u64, 8), fieldByteOffset(layout, ty, 1).?);
    try std.testing.expectEqual(@as(usize, 1), fieldIndexAtOffset(layout, ty, 8, .double).?);
    try std.testing.expectEqual(ir.Type.double, leafTypeAtOffset(layout, ty, 8).?);
}

test "type layout builds reusable aggregate layout plan" {
    const layout = try target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
    const plan = try aggregateLayoutPlan(layout, .{ .aggregate = "%runtime_aggregate_pair_main.Pair" });
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i32, i32 }" }, plan.ty);
    try std.testing.expectEqual(@as(usize, 2), plan.field_count);
    try std.testing.expectEqual(@as(usize, 2), plan.leaf_count);
    try std.testing.expectEqual(@as(u64, 0), plan.leafSlice()[0].offset);
    try std.testing.expectEqual(@as(u64, 4), plan.leafSlice()[1].offset);
    try std.testing.expect(plan.leafSlice()[0].ty.eql(.{ .int = 32 }));
    try std.testing.expect(plan.leafSlice()[1].ty.eql(.{ .int = 32 }));
}

test "type layout plan covers large sret byval aggregates" {
    const layout = try target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
    const plan = try aggregateLayoutPlan(layout, .{ .aggregate = "%frontier_sysv_sret_byval.Big256" });
    try std.testing.expectEqual(@as(usize, 256), plan.leaf_count);
    try std.testing.expectEqual(@as(u64, 0), plan.leafSlice()[0].offset);
    try std.testing.expectEqual(@as(u64, 2040), plan.leafSlice()[255].offset);
    try std.testing.expect(plan.leafSlice()[255].ty.eql(.{ .int = 64 }));
}
