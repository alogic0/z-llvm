const std = @import("std");
const aggregate_layout_boundaries = @import("zig_air_aggregate_layout_boundaries.zig");
const aggregate_layout_facts = @import("zig_air_aggregate_layout_facts.zig");
const exported_aggregate_layout_facts = @import("zig_air_exported_aggregate_layout_facts.zig");
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
    provider_kind: ?AggregateLayoutProviderKind = null,
    field_count: usize,
    evidence: AggregateLayoutEvidence = .{},
    leaves: [max_aggregate_layout_leaves]AggregateLeaf = undefined,
    leaf_count: usize = 0,

    pub fn leafSlice(summary: *const AggregateLayoutSummary) []const AggregateLeaf {
        return summary.leaves[0..summary.leaf_count];
    }
};

pub const AggregateLayoutProviderKind = enum {
    exported_aggregate_facts,
    generated_inference,
    static_source_facts,
    boundary_provider,
};

const AggregateLayoutProvider = struct {
    kind: AggregateLayoutProviderKind,

    fn lookup(provider: AggregateLayoutProvider, nominal: []const u8) ?AggregateLayoutSummary {
        return switch (provider.kind) {
            .exported_aggregate_facts => exportedFactAggregateLayoutSummary(nominal),
            .generated_inference => generatedAggregateLayoutSummary(nominal),
            .static_source_facts => sourceFactAggregateLayoutSummary(nominal),
            .boundary_provider => null,
        };
    }
};

const aggregate_layout_providers = [_]AggregateLayoutProvider{
    .{ .kind = .exported_aggregate_facts },
    .{ .kind = .generated_inference },
    .{ .kind = .static_source_facts },
};

pub const AggregateLayoutMismatch = struct {
    nominal_type_name: []const u8,
    inferred_field_count: usize,
    fallback_field_count: usize,
    inferred_leaf_count: usize,
    fallback_leaf_count: usize,
    evidence: AggregateLayoutEvidence,
};

pub fn summarizeInferredAggregateLayout(
    nominal: []const u8,
    ty: ir.Type,
    evidence: AggregateLayoutEvidence,
) AggregateLayoutSummary {
    return summarizeAggregateLayout(nominal, ty, .inference, evidence);
}

pub fn aggregateLayoutSummariesMatch(lhs: AggregateLayoutSummary, rhs: AggregateLayoutSummary) bool {
    return aggregateLayoutSummariesEquivalent(lhs, rhs);
}

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
    const inferred = ownedAggregateLayoutSummary(nominal) orelse return null;
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
    if (ownedAggregateLayoutSummary(nominal)) |summary| {
        if (fallbackNamedAggregateType(nominal)) |fallback_ty| {
            const fallback = summarizeAggregateLayout(nominal, fallback_ty, .fallback_table, .{});
            if (!aggregateLayoutSummariesEquivalent(summary, fallback)) return error.AggregateLayoutMismatch;
        }
        return summary;
    }
    if (boundaryNamedAggregateType(nominal)) |ty| {
        return boundaryAggregateLayoutSummary(nominal, ty);
    }
    if (fallbackNamedAggregateType(nominal)) |ty| {
        return summarizeAggregateLayout(nominal, ty, .fallback_table, .{});
    }
    return null;
}

fn ownedAggregateLayoutSummary(nominal: []const u8) ?AggregateLayoutSummary {
    for (aggregate_layout_providers) |provider| {
        if (provider.lookup(nominal)) |summary| return summary;
    }
    return null;
}

fn generatedAggregateLayoutSummary(nominal: []const u8) ?AggregateLayoutSummary {
    if (inferredBigScalarLayoutSummary(nominal)) |summary| return withProviderKind(summary, .generated_inference);
    if (inferredBigArrayLayoutSummary(nominal)) |summary| return withProviderKind(summary, .generated_inference);
    return null;
}

fn exportedFactAggregateLayoutSummary(nominal: []const u8) ?AggregateLayoutSummary {
    const fact = exported_aggregate_layout_facts.active_provider.lookup(nominal) orelse return null;
    return withProviderKind(summarizeAggregateLayout(nominal, aggregate(fact.aggregate_text), .facts, .{
        .construction = fact.evidence.construction,
        .store = fact.evidence.store,
        .load = fact.evidence.load,
    }), .exported_aggregate_facts);
}

fn sourceFactAggregateLayoutSummary(nominal: []const u8) ?AggregateLayoutSummary {
    const fact = aggregate_layout_facts.lookup(nominal) orelse return null;
    return withProviderKind(summarizeAggregateLayout(nominal, aggregate(fact.aggregate_text), .facts, .{
        .construction = fact.evidence.construction,
        .store = fact.evidence.store,
        .load = fact.evidence.load,
    }), .static_source_facts);
}

fn fallbackNamedAggregateType(nominal: []const u8) ?ir.Type {
    _ = nominal;
    return null;
}

fn boundaryNamedAggregateType(nominal: []const u8) ?ir.Type {
    const boundary = aggregate_layout_boundaries.lookup(nominal) orelse return null;
    return aggregate(boundary.aggregate_text);
}

fn boundaryAggregateLayoutSummary(nominal: []const u8, ty: ir.Type) AggregateLayoutSummary {
    return withProviderKind(summarizeAggregateLayout(nominal, ty, .boundary, .{}), .boundary_provider);
}

fn withProviderKind(summary: AggregateLayoutSummary, provider_kind: AggregateLayoutProviderKind) AggregateLayoutSummary {
    var result = summary;
    result.provider_kind = provider_kind;
    return result;
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

fn inferredBigScalarLayoutSummary(nominal: []const u8) ?AggregateLayoutSummary {
    const prefix = "frontier_sysv_sret_byval.Big";
    if (!std.mem.startsWith(u8, nominal, prefix)) return null;
    const field_count = std.fmt.parseInt(u16, nominal[prefix.len..], 10) catch return null;
    if (field_count < 3 or field_count > 20) return null;
    const aggregate_text = repeatedScalarAggregateText(field_count, "i64") orelse return null;
    return summarizeAggregateLayout(nominal, aggregate(aggregate_text), .inference, .{
        .construction = true,
        .store = true,
        .load = true,
    });
}

fn repeatedScalarAggregateText(field_count: usize, scalar_text: []const u8) ?[]const u8 {
    if (field_count == 0) return null;
    var aggregate_text: std.ArrayList(u8) = .empty;
    aggregate_text.appendSlice(std.heap.page_allocator, "{ ") catch return null;
    var index: usize = 0;
    while (index < field_count) : (index += 1) {
        if (index != 0) aggregate_text.appendSlice(std.heap.page_allocator, ", ") catch return null;
        aggregate_text.appendSlice(std.heap.page_allocator, scalar_text) catch return null;
    }
    aggregate_text.appendSlice(std.heap.page_allocator, " }") catch return null;
    return aggregate_text.toOwnedSlice(std.heap.page_allocator) catch return null;
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

pub fn normalizeAggregateTypeChecked(ty: ir.Type) error{AggregateLayoutMismatch}!ir.Type {
    return switch (ty) {
        .aggregate => |text| if (try aggregateLayoutSummaryChecked(text)) |summary| summary.ty else ty,
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

pub fn leafAtIndexPath(layout: target.DataLayout, aggregate_ty: ir.Type, path: []const usize) ?AggregateLeaf {
    if (path.len == 0) return null;
    var current_ty = normalizeAggregateType(aggregate_ty);
    var offset: u64 = 0;
    for (path, 0..) |field_index, position| {
        const field_ty = fieldType(current_ty, field_index) orelse return null;
        offset += fieldByteOffset(layout, current_ty, field_index) orelse return null;
        if (position == path.len - 1) {
            const normalized_field_ty = normalizeAggregateType(field_ty);
            if (isAggregateType(normalized_field_ty)) return null;
            return .{ .offset = offset, .ty = normalized_field_ty };
        }
        current_ty = normalizeAggregateType(field_ty);
        if (!isAggregateType(current_ty)) return null;
    }
    return null;
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
    const normalized_ty = try normalizeAggregateTypeChecked(aggregate_ty);
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
    return if (inferredBigScalarLayoutSummary(trimmed)) |summary| summary.ty else null;
}

fn aggregate(text: []const u8) ir.Type {
    return .{ .aggregate = text };
}

fn installTestExportedAggregateProvider() !exported_aggregate_layout_facts.Provider {
    const contents =
        exported_aggregate_layout_facts.section_name ++ "\n" ++
        "fact nominal=\"frontier_nested_records.Inner\" aggregate=\"{ i32, i32 }\" construction=1 store=1 load=1\n" ++
        "fact nominal=\"frontier_nested_records.Outer\" aggregate=\"{ { i32, i32 }, { i32, i32 } }\" construction=1 store=1 load=1\n" ++
        "fact nominal=\"frontier_sysv_aggregate_classes.Pair32\" aggregate=\"{ i32, i32 }\" construction=1 store=1 load=1\n";
    return exported_aggregate_layout_facts.parseSidecar(std.testing.allocator, contents);
}

test "type layout decodes nominal aggregate basenames without fixture module names" {
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i64, double }" }, parseNamedAggregateType("any_module.Mixed").?);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i64, double }" }, parseNamedAggregateType("%Mixed").?);
    try std.testing.expect(parseNamedAggregateType("*frontier_sysv_aggregate_classes.Mixed") == null);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ [2 x double] }" }, parseNamedAggregateType("frontier_sysv_aggregate_classes.ArrayDouble").?);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ { i32, i32 }, { i32, i32 } }" }, parseNamedAggregateType("other.NestedPair").?);
    try std.testing.expect(parseNamedAggregateType("%frontier_sysv_sret_byval.Big3").?.eql(.{ .aggregate = "{ i64, i64, i64 }" }));
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i32, i32 }" }, parseNamedAggregateType("aggregate_abi.Pair").?);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i32, i32 }" }, parseNamedAggregateType("%runtime_aggregate_pair_main.Pair").?);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i32, i32 }" }, normalizeAggregateType(.{ .aggregate = "%expanded_abi_frontier.Pair" }));
    try std.testing.expect(parseNamedAggregateType("other.Pair") == null);
}

test "type layout prefers exported facts and inference before fallback table" {
    const provider = try installTestExportedAggregateProvider();
    exported_aggregate_layout_facts.setActiveProvider(provider);
    defer provider.deinit(std.testing.allocator);
    defer exported_aggregate_layout_facts.setActiveProvider(exported_aggregate_layout_facts.empty_provider);

    const outer = aggregateLayoutSummary("frontier_nested_records.Outer").?;
    try std.testing.expectEqual(AggregateLayoutSource.facts, outer.source);
    try std.testing.expectEqual(AggregateLayoutProviderKind.exported_aggregate_facts, outer.provider_kind.?);
    try std.testing.expect(outer.ty.eql(.{ .aggregate = "{ { i32, i32 }, { i32, i32 } }" }));
    try std.testing.expectEqual(@as(usize, 2), outer.field_count);
    try std.testing.expectEqual(@as(usize, 4), outer.leaf_count);
    try std.testing.expect(outer.evidence.construction);
    try std.testing.expect(outer.evidence.store);
    try std.testing.expect(outer.evidence.load);

    try std.testing.expect(aggregateLayoutSummary("other.Outer") == null);

    const mixed = aggregateLayoutSummary("any_module.Mixed").?;
    try std.testing.expectEqual(AggregateLayoutSource.facts, mixed.source);
    try std.testing.expect(aggregateLayoutMismatch("any_module.Mixed") == null);
}

test "type layout prefers active exported facts before temporary static source facts" {
    const provider = try installTestExportedAggregateProvider();
    exported_aggregate_layout_facts.setActiveProvider(provider);
    defer provider.deinit(std.testing.allocator);
    defer exported_aggregate_layout_facts.setActiveProvider(exported_aggregate_layout_facts.empty_provider);

    const summary = aggregateLayoutSummary("frontier_nested_records.Inner").?;
    try std.testing.expectEqual(AggregateLayoutSource.facts, summary.source);
    try std.testing.expectEqual(AggregateLayoutProviderKind.exported_aggregate_facts, summary.provider_kind.?);
    try std.testing.expectEqual(@as(usize, 2), summary.field_count);
}

test "type layout infers representative frontier aggregate rows" {
    const provider = try installTestExportedAggregateProvider();
    exported_aggregate_layout_facts.setActiveProvider(provider);
    defer provider.deinit(std.testing.allocator);
    defer exported_aggregate_layout_facts.setActiveProvider(exported_aggregate_layout_facts.empty_provider);

    const inner = aggregateLayoutSummary("frontier_nested_records.Inner").?;
    try std.testing.expectEqual(AggregateLayoutSource.facts, inner.source);
    try std.testing.expectEqual(AggregateLayoutProviderKind.exported_aggregate_facts, inner.provider_kind.?);
    try std.testing.expectEqual(@as(usize, 2), inner.leaf_count);
    try std.testing.expect(inner.leafSlice()[0].ty.eql(.{ .int = 32 }));
    try std.testing.expect(inner.leafSlice()[1].ty.eql(.{ .int = 32 }));
    try std.testing.expect(aggregateLayoutSummary("other.Inner") == null);

    const pair32 = aggregateLayoutSummary("frontier_sysv_aggregate_classes.Pair32").?;
    try std.testing.expectEqual(AggregateLayoutSource.facts, pair32.source);
    try std.testing.expectEqual(AggregateLayoutProviderKind.exported_aggregate_facts, pair32.provider_kind.?);
    try std.testing.expect(pair32.ty.eql(.{ .aggregate = "{ i32, i32 }" }));

    const mixed = aggregateLayoutSummary("frontier_sysv_aggregate_classes.SmallMixed").?;
    try std.testing.expectEqual(AggregateLayoutSource.facts, mixed.source);
    try std.testing.expectEqual(@as(usize, 2), mixed.leaf_count);
    try std.testing.expect(mixed.leafSlice()[0].ty.eql(.{ .int = 32 }));
    try std.testing.expect(mixed.leafSlice()[1].ty.eql(.double));

    const big_array = aggregateLayoutSummary("frontier_sysv_sret_byval.BigArray").?;
    try std.testing.expectEqual(AggregateLayoutSource.facts, big_array.source);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ [5 x i64] }" }, big_array.ty);
    try std.testing.expectEqual(@as(usize, 5), big_array.leaf_count);

    const big3 = aggregateLayoutSummary("frontier_sysv_sret_byval.Big3").?;
    try std.testing.expectEqual(AggregateLayoutSource.inference, big3.source);
    try std.testing.expectEqual(AggregateLayoutProviderKind.generated_inference, big3.provider_kind.?);
    try std.testing.expect(big3.ty.eql(.{ .aggregate = "{ i64, i64, i64 }" }));
    try std.testing.expectEqual(@as(usize, 3), big3.leaf_count);

    const big20 = aggregateLayoutSummary("frontier_sysv_sret_byval.Big20").?;
    try std.testing.expectEqual(AggregateLayoutSource.inference, big20.source);
    try std.testing.expectEqual(@as(usize, 20), big20.leaf_count);
    try std.testing.expect(big20.leafSlice()[19].ty.eql(.{ .int = 64 }));

    const big256 = aggregateLayoutSummary("frontier_sysv_sret_byval.Big256").?;
    try std.testing.expectEqual(AggregateLayoutSource.inference, big256.source);
    try std.testing.expect(big256.ty.eql(.{ .aggregate = "{ [256 x i64] }" }));
    try std.testing.expectEqual(@as(usize, 256), big256.leaf_count);
}

test "type layout keeps packed aggregates compatibility boundary owned" {
    const packed_summary = aggregateLayoutSummary("frontier_sysv_aggregate_classes.PackedMixed").?;
    try std.testing.expectEqual(AggregateLayoutSource.boundary, packed_summary.source);
    try std.testing.expectEqual(AggregateLayoutProviderKind.boundary_provider, packed_summary.provider_kind.?);
    try std.testing.expectEqual(ir.Type{ .aggregate = "{ i32, i32, double }" }, packed_summary.ty);

    const big_mixed = aggregateLayoutSummary("frontier_sysv_sret_byval.BigMixed").?;
    try std.testing.expectEqual(AggregateLayoutSource.facts, big_mixed.source);
    try std.testing.expectEqual(@as(usize, 4), big_mixed.leaf_count);
}

test "type layout resolves leaf by aggregate index path" {
    const layout = try target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
    const nested = parseNamedAggregateType("frontier_sysv_sret_byval.BigNested").?;
    const leaf = leafAtIndexPath(layout, nested, &.{ 1, 2 }).?;
    try std.testing.expectEqual(@as(u64, 40), leaf.offset);
    try std.testing.expect(leaf.ty.eql(.{ .int = 64 }));

    const array = parseNamedAggregateType("frontier_sysv_sret_byval.BigArray").?;
    const array_leaf = leafAtIndexPath(layout, array, &.{ 0, 4 }).?;
    try std.testing.expectEqual(@as(u64, 32), array_leaf.offset);
    try std.testing.expect(array_leaf.ty.eql(.{ .int = 64 }));
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
