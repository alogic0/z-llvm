const std = @import("std");
const ir = @import("ir.zig");
const target = @import("target.zig");
const memory_location = @import("analysis/memory_location.zig");
const air_export = @import("zig_air_export.zig");

pub const OpcodeCapability = struct {
    category: air_export.InstructionCategory,
    status: OpcodeStatus,
    owner: CapabilityOwner,
    lowerer: LowererKind,
    inventory_known: bool,
    ignored_metadata: bool,
    straight_line_lowerable: bool,
    typed_v2_lowerable: bool,
    boundary_reason: ?[]const u8 = null,
};

pub const DataKindCapability = struct {
    category: UnknownOpcodeCategory,
    status: OpcodeStatus,
    owner: CapabilityOwner,
    lowerer: LowererKind,
    inventory_known: bool,
};

pub const OpcodeStatus = enum {
    unknown,
    inventory_only,
    boundary,
    ignored_metadata,
    lowerable,

    pub fn name(self: OpcodeStatus) []const u8 {
        return switch (self) {
            .unknown => "unknown",
            .inventory_only => "inventory-only",
            .boundary => "boundary",
            .ignored_metadata => "ignored-metadata",
            .lowerable => "lowerable",
        };
    }
};

pub const CapabilityOwner = enum {
    unknown,
    inventory,
    debug_metadata,
    air_parser,
    semantic_lowering,
    cfg_lowering,
    abi_planner,
    backend,
    runtime_boundary,

    pub fn name(self: CapabilityOwner) []const u8 {
        return switch (self) {
            .unknown => "unknown",
            .inventory => "inventory",
            .debug_metadata => "debug-metadata",
            .air_parser => "air-parser",
            .semantic_lowering => "semantic-lowering",
            .cfg_lowering => "cfg-lowering",
            .abi_planner => "abi-planner",
            .backend => "backend",
            .runtime_boundary => "runtime-boundary",
        };
    }
};

pub const LowererKind = enum {
    none,
    ignore,
    typed_v2_semantic,
    typed_v2_cfg,
    call_abi,
    backend_runtime,
    boundary,

    pub fn name(self: LowererKind) []const u8 {
        return switch (self) {
            .none => "none",
            .ignore => "ignore",
            .typed_v2_semantic => "typed-v2-semantic",
            .typed_v2_cfg => "typed-v2-cfg",
            .call_abi => "call-abi",
            .backend_runtime => "backend-runtime",
            .boundary => "boundary",
        };
    }
};

pub const SemanticDomain = enum {
    none,
    scalar,
    memory,
    optional,
    error_union,
    pointer_aggregate,

    pub fn name(self: SemanticDomain) []const u8 {
        return switch (self) {
            .none => "none",
            .scalar => "scalar",
            .memory => "memory",
            .optional => "optional",
            .error_union => "error-union",
            .pointer_aggregate => "pointer-aggregate",
        };
    }
};

pub const ScalarSemanticOp = enum {
    none,
    arg,
    add_with_overflow,
    binary,
    compare,
    cast,
};

pub const MemorySemanticOp = enum {
    none,
    alloc,
    load,
    store,
};

pub const OptionalSemanticOp = enum {
    none,
    is_non_null,
    wrap_optional,
    optional_payload,
};

pub const ErrorUnionSemanticOp = enum {
    none,
    is_non_err,
    wrap_payload,
    wrap_err,
    unwrap_payload,
    unwrap_err,
    try_op,
};

pub const PointerAggregateSemanticOp = enum {
    none,
    slice,
    ptr_gep,
    runtime_nav_ptr,
    array_elem_val,
    field_ptr,
};

pub const CfgLoweringOp = enum {
    none,
    block,
    cond_br,
    ret,
    unreach,
};

pub const UnknownOpcodeCategory = enum(u8) {
    debug_metadata,
    error_union_try,
    pointer_address,
    switch_dispatch,
    safety_runtime,
    aggregate_shape,
    call_shape,
    memory_shape,
    other,

    pub fn name(self: UnknownOpcodeCategory) []const u8 {
        return switch (self) {
            .debug_metadata => "debug-metadata",
            .error_union_try => "error-union-try",
            .pointer_address => "pointer-address",
            .switch_dispatch => "switch-dispatch",
            .safety_runtime => "safety-runtime",
            .aggregate_shape => "aggregate-shape",
            .call_shape => "call-shape",
            .memory_shape => "memory-shape",
            .other => "other",
        };
    }
};

pub const TypeBoundary = enum {
    varargs,
    vector,
    x87,
    packed_aggregate,
};

pub const TypeSurfaceCapability = struct {
    varargs: bool = false,
    vector: bool = false,
    x87: bool = false,
    packed_or_unaligned_aggregate: bool = false,
    aggregate_abi: bool = false,
    pointer: bool = false,
    slice: bool = false,
    optional: bool = false,
    error_union: bool = false,

    pub fn firstBoundary(self: TypeSurfaceCapability) ?TypeBoundary {
        if (self.varargs) return .varargs;
        if (self.vector) return .vector;
        if (self.x87) return .x87;
        if (self.packed_or_unaligned_aggregate) return .packed_aggregate;
        return null;
    }
};

pub fn opcodeCapability(opcode: []const u8) OpcodeCapability {
    const category = air_export.categoryForOpcode(opcode);
    const ignored_metadata = isIgnoredMetadataOpcode(opcode);
    const straight_line_lowerable = isStraightLineLowerableOpcode(opcode);
    const typed_v2_lowerable = isTypedV2LowerableOpcode(opcode);
    const boundary_reason = boundaryReasonForOpcode(opcode);
    const inventory_known = category != .other or isInventoryKnownOtherOpcode(opcode);
    const status = opcodeStatus(ignored_metadata, typed_v2_lowerable, inventory_known, boundary_reason);
    return .{
        .category = category,
        .status = status,
        .owner = capabilityOwnerForOpcode(opcode, category, status),
        .lowerer = lowererForOpcode(opcode, category, status),
        .inventory_known = inventory_known,
        .ignored_metadata = ignored_metadata,
        .straight_line_lowerable = straight_line_lowerable,
        .typed_v2_lowerable = typed_v2_lowerable,
        .boundary_reason = boundary_reason,
    };
}

pub fn isInventoryKnownOpcode(opcode: []const u8) bool {
    return opcodeCapability(opcode).inventory_known;
}

pub fn isIgnoredOpcode(opcode: []const u8) bool {
    return opcodeCapability(opcode).ignored_metadata;
}

pub fn isStraightLineOpcode(opcode: []const u8) bool {
    return opcodeCapability(opcode).straight_line_lowerable;
}

pub fn isTypedV2LowerableOpcode(opcode: []const u8) bool {
    return isCommonLowerableOpcode(opcode) or
        std.mem.eql(u8, opcode, "block") or
        std.mem.eql(u8, opcode, "cond_br");
}

pub fn typedV2CanLower(capability: OpcodeCapability) bool {
    return capability.status == .lowerable and capability.typed_v2_lowerable;
}

pub fn typedV2FallbackReason(capability: OpcodeCapability) []const u8 {
    if (typedV2CanLower(capability)) return "lowerable";
    if (capability.boundary_reason) |reason| return reason;
    return switch (capability.status) {
        .unknown => "unknown-opcode",
        .inventory_only => "inventory-only",
        .boundary => "boundary",
        .ignored_metadata => "ignored-metadata",
        .lowerable => "unsupported-lowerer",
    };
}

pub fn semanticDomainForOpcode(opcode: []const u8) SemanticDomain {
    const capability = opcodeCapability(opcode);
    if (capability.lowerer != .typed_v2_semantic) return .none;
    if (std.mem.eql(u8, opcode, "arg") or
        isArithmeticOpcode(opcode) or
        std.mem.eql(u8, opcode, "add_with_overflow") or
        std.mem.startsWith(u8, opcode, "cmp_") or
        isCastOpcode(opcode))
    {
        return .scalar;
    }
    if (std.mem.eql(u8, opcode, "alloc") or
        std.mem.eql(u8, opcode, "load") or
        std.mem.eql(u8, opcode, "store") or
        std.mem.eql(u8, opcode, "store_safe"))
    {
        return .memory;
    }
    if (std.mem.eql(u8, opcode, "is_non_null") or
        std.mem.eql(u8, opcode, "wrap_optional") or
        std.mem.eql(u8, opcode, "optional_payload"))
    {
        return .optional;
    }
    if (std.mem.eql(u8, opcode, "is_non_err") or
        std.mem.startsWith(u8, opcode, "wrap_errunion") or
        std.mem.startsWith(u8, opcode, "unwrap_errunion") or
        std.mem.eql(u8, opcode, "try"))
    {
        return .error_union;
    }
    if (std.mem.eql(u8, opcode, "slice") or
        std.mem.eql(u8, opcode, "ptr_add") or
        std.mem.eql(u8, opcode, "ptr_elem_ptr") or
        std.mem.eql(u8, opcode, "runtime_nav_ptr") or
        std.mem.eql(u8, opcode, "array_elem_val") or
        isFieldPtrOpcode(opcode))
    {
        return .pointer_aggregate;
    }
    return .none;
}

pub fn scalarSemanticOpForOpcode(opcode: []const u8) ScalarSemanticOp {
    if (std.mem.eql(u8, opcode, "arg")) return .arg;
    if (std.mem.eql(u8, opcode, "add_with_overflow")) return .add_with_overflow;
    if (isArithmeticOpcode(opcode)) return .binary;
    if (std.mem.startsWith(u8, opcode, "cmp_")) return .compare;
    if (isCastOpcode(opcode)) return .cast;
    return .none;
}

pub fn memorySemanticOpForOpcode(opcode: []const u8) MemorySemanticOp {
    if (std.mem.eql(u8, opcode, "alloc")) return .alloc;
    if (std.mem.eql(u8, opcode, "load")) return .load;
    if (std.mem.eql(u8, opcode, "store") or std.mem.eql(u8, opcode, "store_safe")) return .store;
    return .none;
}

pub fn optionalSemanticOpForOpcode(opcode: []const u8) OptionalSemanticOp {
    if (std.mem.eql(u8, opcode, "is_non_null")) return .is_non_null;
    if (std.mem.eql(u8, opcode, "wrap_optional")) return .wrap_optional;
    if (std.mem.eql(u8, opcode, "optional_payload")) return .optional_payload;
    return .none;
}

pub fn errorUnionSemanticOpForOpcode(opcode: []const u8) ErrorUnionSemanticOp {
    if (std.mem.eql(u8, opcode, "is_non_err")) return .is_non_err;
    if (std.mem.eql(u8, opcode, "wrap_errunion_payload")) return .wrap_payload;
    if (std.mem.eql(u8, opcode, "wrap_errunion_err")) return .wrap_err;
    if (std.mem.eql(u8, opcode, "unwrap_errunion_payload")) return .unwrap_payload;
    if (std.mem.eql(u8, opcode, "unwrap_errunion_err")) return .unwrap_err;
    if (std.mem.eql(u8, opcode, "try")) return .try_op;
    return .none;
}

pub fn pointerAggregateSemanticOpForOpcode(opcode: []const u8) PointerAggregateSemanticOp {
    if (std.mem.eql(u8, opcode, "slice")) return .slice;
    if (std.mem.eql(u8, opcode, "ptr_add") or std.mem.eql(u8, opcode, "ptr_elem_ptr")) return .ptr_gep;
    if (std.mem.eql(u8, opcode, "runtime_nav_ptr")) return .runtime_nav_ptr;
    if (std.mem.eql(u8, opcode, "array_elem_val")) return .array_elem_val;
    if (isFieldPtrOpcode(opcode)) return .field_ptr;
    return .none;
}

pub fn cfgLoweringOpForOpcode(opcode: []const u8) CfgLoweringOp {
    if (std.mem.eql(u8, opcode, "block")) return .block;
    if (std.mem.eql(u8, opcode, "cond_br")) return .cond_br;
    if (std.mem.eql(u8, opcode, "ret") or std.mem.eql(u8, opcode, "ret_safe")) return .ret;
    if (std.mem.eql(u8, opcode, "unreach")) return .unreach;
    return .none;
}

fn opcodeStatus(
    ignored_metadata: bool,
    typed_v2_lowerable: bool,
    inventory_known: bool,
    boundary_reason: ?[]const u8,
) OpcodeStatus {
    if (ignored_metadata) return .ignored_metadata;
    if (typed_v2_lowerable) return .lowerable;
    if (boundary_reason != null) return .boundary;
    if (inventory_known) return .inventory_only;
    return .unknown;
}

fn capabilityOwnerForOpcode(
    opcode: []const u8,
    category: air_export.InstructionCategory,
    status: OpcodeStatus,
) CapabilityOwner {
    return switch (status) {
        .ignored_metadata => .debug_metadata,
        .boundary => .runtime_boundary,
        .unknown => .unknown,
        .inventory_only => .inventory,
        .lowerable => lowerableOwnerForOpcode(opcode, category),
    };
}

fn lowerableOwnerForOpcode(opcode: []const u8, category: air_export.InstructionCategory) CapabilityOwner {
    if (std.mem.eql(u8, opcode, "block") or
        std.mem.eql(u8, opcode, "br") or
        std.mem.eql(u8, opcode, "cond_br") or
        std.mem.eql(u8, opcode, "loop") or
        std.mem.eql(u8, opcode, "repeat") or
        std.mem.eql(u8, opcode, "switch_br") or
        category == .control_flow or
        category == .return_op)
    {
        return .cfg_lowering;
    }
    if (category == .call) return .abi_planner;
    if (std.mem.eql(u8, opcode, "atomic_rmw") or std.mem.eql(u8, opcode, "assembly")) return .backend;
    if (std.mem.eql(u8, opcode, "add_with_overflow") or
        std.mem.eql(u8, opcode, "is_non_null") or
        std.mem.eql(u8, opcode, "is_non_err") or
        std.mem.eql(u8, opcode, "wrap_optional") or
        std.mem.eql(u8, opcode, "optional_payload") or
        std.mem.startsWith(u8, opcode, "wrap_errunion") or
        std.mem.startsWith(u8, opcode, "unwrap_errunion") or
        std.mem.eql(u8, opcode, "try") or
        std.mem.eql(u8, opcode, "slice") or
        std.mem.eql(u8, opcode, "ptr_add") or
        std.mem.eql(u8, opcode, "ptr_elem_ptr") or
        std.mem.eql(u8, opcode, "array_elem_val") or
        isFieldPtrOpcode(opcode))
    {
        return .semantic_lowering;
    }
    return .air_parser;
}

fn lowererForOpcode(
    opcode: []const u8,
    category: air_export.InstructionCategory,
    status: OpcodeStatus,
) LowererKind {
    return switch (status) {
        .ignored_metadata => .ignore,
        .boundary => .boundary,
        .unknown, .inventory_only => .none,
        .lowerable => lowererForLowerableOpcode(opcode, category),
    };
}

fn lowererForLowerableOpcode(opcode: []const u8, category: air_export.InstructionCategory) LowererKind {
    if (category == .call) return .call_abi;
    if (category == .control_flow or category == .return_op or std.mem.eql(u8, opcode, "block")) return .typed_v2_cfg;
    if (std.mem.eql(u8, opcode, "atomic_rmw") or std.mem.eql(u8, opcode, "assembly")) return .backend_runtime;
    return .typed_v2_semantic;
}

pub fn unknownOpcodeCategory(opcode: []const u8, data_kind: []const u8) UnknownOpcodeCategory {
    return opcodeDataKindCapability(opcode, data_kind).category;
}

pub fn opcodeDataKindCapability(opcode: []const u8, data_kind: []const u8) DataKindCapability {
    const opcode_category = dataKindCategoryFromText(opcode);
    const data_kind_category = dataKindCategoryFromText(data_kind);
    const category = if (opcode_category != .other) opcode_category else data_kind_category;
    const inventory_known = category != .other;
    return .{
        .category = category,
        .status = if (inventory_known) .inventory_only else .unknown,
        .owner = ownerForDataKindCategory(category),
        .lowerer = .none,
        .inventory_known = inventory_known,
    };
}

pub fn dataKindCapability(data_kind: []const u8) DataKindCapability {
    const category = dataKindCategoryFromText(data_kind);
    const inventory_known = category != .other;
    return .{
        .category = category,
        .status = if (inventory_known) .inventory_only else .unknown,
        .owner = ownerForDataKindCategory(category),
        .lowerer = .none,
        .inventory_known = inventory_known,
    };
}

fn dataKindCategoryFromText(text: []const u8) UnknownOpcodeCategory {
    if (containsAny(text, &.{ "dbg", "debug" })) return .debug_metadata;
    if (containsAny(text, &.{ "try", "err", "error", "unwrap_err", "errunion" })) return .error_union_try;
    if (containsAny(text, &.{ "ptr", "addr", "gep", "nav", "field_ptr" })) return .pointer_address;
    if (containsAny(text, &.{ "switch", "dispatch" })) return .switch_dispatch;
    if (containsAny(text, &.{ "safe", "panic", "overflow", "bounds", "trap", "sentinel" })) return .safety_runtime;
    if (containsAny(text, &.{ "aggregate", "struct", "field", "elem", "array", "slice" })) return .aggregate_shape;
    if (containsAny(text, &.{ "call", "invoke" })) return .call_shape;
    if (containsAny(text, &.{ "load", "store", "alloc", "memcpy", "memset", "memmove", "atomic", "cmpxchg", "fence" })) return .memory_shape;
    return .other;
}

fn ownerForDataKindCategory(category: UnknownOpcodeCategory) CapabilityOwner {
    return switch (category) {
        .debug_metadata => .debug_metadata,
        .error_union_try, .pointer_address, .aggregate_shape => .semantic_lowering,
        .switch_dispatch, .safety_runtime => .cfg_lowering,
        .call_shape => .abi_planner,
        .memory_shape => .backend,
        .other => .unknown,
    };
}

pub fn isArithmeticOpcode(opcode: []const u8) bool {
    return air_export.categoryForOpcode(opcode) == .arithmetic;
}

pub fn isCastOpcode(opcode: []const u8) bool {
    return std.mem.eql(u8, opcode, "trunc") or
        std.mem.eql(u8, opcode, "intcast") or
        std.mem.eql(u8, opcode, "bitcast") or
        std.mem.eql(u8, opcode, "ptrtoint") or
        std.mem.eql(u8, opcode, "inttoptr") or
        std.mem.eql(u8, opcode, "float_from_int") or
        std.mem.eql(u8, opcode, "int_from_float") or
        std.mem.eql(u8, opcode, "fpext") or
        std.mem.eql(u8, opcode, "fptrunc");
}

pub fn isCallOpcode(opcode: []const u8) bool {
    return air_export.categoryForOpcode(opcode) == .call;
}

pub fn isReturnOpcode(opcode: []const u8) bool {
    return air_export.categoryForOpcode(opcode) == .return_op;
}

pub fn callTailKindForOpcode(opcode: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, opcode, "call_always_tail")) return "tail";
    if (std.mem.eql(u8, opcode, "call_never_tail")) return "notail";
    if (std.mem.eql(u8, opcode, "call_never_inline")) return "neverinline";
    return null;
}

pub fn isFieldPtrOpcode(opcode: []const u8) bool {
    return std.mem.eql(u8, opcode, "struct_field_ptr") or
        std.mem.startsWith(u8, opcode, "struct_field_ptr_index_");
}

pub fn isShiftOpcode(opcode: []const u8) bool {
    return std.mem.startsWith(u8, opcode, "shl") or std.mem.startsWith(u8, opcode, "shr");
}

pub fn typeSurfaceCapability(text: []const u8) TypeSurfaceCapability {
    if (text.len == 0) return .{};
    return .{
        .varargs = isVarargsText(text),
        .vector = isVectorText(text),
        .x87 = isX87Text(text),
        .packed_or_unaligned_aggregate = isPackedOrUnalignedAggregateText(text),
        .aggregate_abi = isAggregateAbiText(text),
        .pointer = isPointerText(text),
        .slice = isSliceText(text),
        .optional = isOptionalText(text),
        .error_union = isErrorUnionText(text),
    };
}

pub fn boundaryForIrType(ty: ir.Type) ?TypeBoundary {
    return switch (ty) {
        .vector => .vector,
        .x86_fp80, .fp128 => .x87,
        .aggregate => |text| {
            const trimmed = std.mem.trim(u8, text, " \t");
            if (std.mem.startsWith(u8, trimmed, "<{")) return .packed_aggregate;
            if (std.mem.indexOfScalar(u8, trimmed, '<') != null) return .vector;
            var field_index: usize = 0;
            while (memory_location.aggregateFieldType(ty, field_index)) |field_ty| : (field_index += 1) {
                if (boundaryForIrType(field_ty)) |boundary| return boundary;
            }
            return null;
        },
        .void, .int, .float, .double, .metadata, .ptr => null,
    };
}

pub fn aggregateFieldType(aggregate_ty: ir.Type, field_index: usize) ?ir.Type {
    return memory_location.aggregateFieldType(aggregate_ty, field_index);
}

pub fn aggregateFieldCount(aggregate_ty: ir.Type) usize {
    var count: usize = 0;
    while (aggregateFieldType(aggregate_ty, count)) |_| : (count += 1) {}
    return count;
}

pub fn aggregateFieldByteOffset(layout: target.DataLayout, aggregate_ty: ir.Type, field_index: usize) ?u64 {
    const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse return null;
    if (offset_i < 0) return null;
    return @intCast(offset_i);
}

pub fn aggregateFieldIndexAtOffset(
    layout: target.DataLayout,
    aggregate_ty: ir.Type,
    expected_offset: u64,
    expected_ty: ir.Type,
) ?usize {
    var field_index: usize = 0;
    while (aggregateFieldType(aggregate_ty, field_index)) |field_ty| : (field_index += 1) {
        const field_offset = aggregateFieldByteOffset(layout, aggregate_ty, field_index) orelse return null;
        if (field_ty.eql(expected_ty) and field_offset == expected_offset) return field_index;
        if (isAggregateType(field_ty) and expected_offset >= field_offset) {
            if (aggregateFieldIndexAtOffset(layout, field_ty, expected_offset - field_offset, expected_ty) != null) {
                return field_index;
            }
        }
    }
    return null;
}

pub fn aggregateLeafTypeAtOffset(layout: target.DataLayout, aggregate_ty: ir.Type, expected_offset: u64) ?ir.Type {
    var field_index: usize = 0;
    while (aggregateFieldType(aggregate_ty, field_index)) |field_ty| : (field_index += 1) {
        const field_offset = aggregateFieldByteOffset(layout, aggregate_ty, field_index) orelse return null;
        if (isAggregateType(field_ty)) {
            if (expected_offset >= field_offset) {
                if (aggregateLeafTypeAtOffset(layout, field_ty, expected_offset - field_offset)) |nested_ty| return nested_ty;
            }
        } else if (field_offset == expected_offset) {
            return field_ty;
        }
    }
    return null;
}

pub const AggregateLeaf = struct {
    offset: u64,
    ty: ir.Type,
};

pub fn isSupportedScalarAggregateLeaf(ty: ir.Type) bool {
    return ty.eql(.{ .int = 8 }) or ty.eql(.{ .int = 16 }) or ty.eql(.{ .int = 32 }) or
        ty.eql(.{ .int = 64 }) or ty.eql(.ptr) or ty.eql(.float) or ty.eql(.double);
}

pub fn isSupportedScalarLeafAggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty);
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = aggregateFieldType(aggregate_ty, field_index) orelse return false;
        if (isSupportedScalarAggregateLeaf(field_ty)) continue;
        if (isAggregateType(field_ty) and isSupportedScalarLeafAggregate(field_ty)) continue;
        return false;
    }
    return true;
}

pub fn collectSupportedScalarAggregateLeaves(
    layout: target.DataLayout,
    aggregate_ty: ir.Type,
    base_offset: u64,
    leaves: []AggregateLeaf,
    leaf_count: *usize,
) !void {
    const field_count = aggregateFieldCount(aggregate_ty);
    if (field_count == 0) return error.UnsupportedCodegenAbi;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = aggregateFieldType(aggregate_ty, field_index) orelse return error.UnsupportedCodegenAbi;
        const field_offset = base_offset + (aggregateFieldByteOffset(layout, aggregate_ty, field_index) orelse
            return error.UnsupportedCodegenAbi);
        if (isSupportedScalarAggregateLeaf(field_ty)) {
            if (leaf_count.* >= leaves.len) return error.UnsupportedCodegenAbi;
            leaves[leaf_count.*] = .{ .offset = field_offset, .ty = field_ty };
            leaf_count.* += 1;
        } else if (isAggregateType(field_ty)) {
            try collectSupportedScalarAggregateLeaves(layout, field_ty, field_offset, leaves, leaf_count);
        } else {
            return error.UnsupportedCodegenAbi;
        }
    }
}

pub fn isAggregateType(ty: ir.Type) bool {
    return switch (ty) {
        .aggregate => true,
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

fn isIgnoredMetadataOpcode(opcode: []const u8) bool {
    return std.mem.startsWith(u8, opcode, "dbg_");
}

fn isStraightLineLowerableOpcode(opcode: []const u8) bool {
    return isCommonLowerableOpcode(opcode) or
        std.mem.eql(u8, opcode, "runtime_nav_ptr") or
        std.mem.eql(u8, opcode, "atomic_rmw") or
        std.mem.eql(u8, opcode, "aggregate_init") or
        std.mem.eql(u8, opcode, "assembly");
}

fn isCommonLowerableOpcode(opcode: []const u8) bool {
    return std.mem.eql(u8, opcode, "arg") or
        isArithmeticOpcode(opcode) or
        std.mem.eql(u8, opcode, "add_with_overflow") or
        std.mem.startsWith(u8, opcode, "cmp_") or
        isCastOpcode(opcode) or
        std.mem.eql(u8, opcode, "alloc") or
        std.mem.eql(u8, opcode, "load") or
        std.mem.eql(u8, opcode, "store") or
        std.mem.eql(u8, opcode, "store_safe") or
        std.mem.eql(u8, opcode, "is_non_null") or
        std.mem.eql(u8, opcode, "is_non_err") or
        std.mem.eql(u8, opcode, "wrap_optional") or
        std.mem.eql(u8, opcode, "optional_payload") or
        std.mem.eql(u8, opcode, "wrap_errunion_payload") or
        std.mem.eql(u8, opcode, "wrap_errunion_err") or
        std.mem.eql(u8, opcode, "unwrap_errunion_payload") or
        std.mem.eql(u8, opcode, "unwrap_errunion_err") or
        std.mem.eql(u8, opcode, "try") or
        std.mem.eql(u8, opcode, "slice") or
        std.mem.eql(u8, opcode, "ptr_add") or
        std.mem.eql(u8, opcode, "ptr_elem_ptr") or
        std.mem.eql(u8, opcode, "array_elem_val") or
        std.mem.eql(u8, opcode, "runtime_nav_ptr") or
        isFieldPtrOpcode(opcode) or
        isCallOpcode(opcode) or
        std.mem.eql(u8, opcode, "ret") or
        std.mem.eql(u8, opcode, "ret_safe") or
        std.mem.eql(u8, opcode, "unreach");
}

fn isInventoryKnownOtherOpcode(opcode: []const u8) bool {
    return containsAny(opcode, &.{
        "alloc",
        "arg",
        "assembly",
        "atomic",
        "bitcast",
        "block",
        "br",
        "call",
        "cmpxchg",
        "cond_br",
        "dbg",
        "fence",
        "inferred_alloc",
        "load",
        "loop",
        "not",
        "repeat",
        "ret",
        "store",
        "switch",
        "trap",
        "unreach",
    });
}

fn boundaryReasonForOpcode(opcode: []const u8) ?[]const u8 {
    if (isIgnoredMetadataOpcode(opcode)) return "debug-metadata";
    if (std.mem.indexOf(u8, opcode, "asm") != null or std.mem.indexOf(u8, opcode, "assembly") != null) return "inline-asm";
    return null;
}

fn isVarargsText(text: []const u8) bool {
    return containsAny(text, &.{ "...", "varargs", "var_args", "is_var_args=true" });
}

fn isVectorText(text: []const u8) bool {
    return containsAny(text, &.{ "@Vector", "vector", "Vector", "<2 x", "<4 x", "<8 x", "<16 x" });
}

fn isX87Text(text: []const u8) bool {
    return containsAny(text, &.{ "f80", "f128", "x86_fp80", "fp128", "long double" });
}

fn isPackedOrUnalignedAggregateText(text: []const u8) bool {
    return containsAny(text, &.{ "packed", "unaligned", "align(1)", "abi_align=1" });
}

fn isAggregateAbiText(text: []const u8) bool {
    return containsAny(text, &.{ "struct", "extern struct", "{ ", "{", "[", "byval", "sret" });
}

fn isPointerText(text: []const u8) bool {
    return containsAny(text, &.{ "*", "ptr", "pointer" });
}

fn isSliceText(text: []const u8) bool {
    return containsAny(text, &.{ "[]", "slice", "{ ptr, i64 }", "{ptr,i64}" });
}

fn isOptionalText(text: []const u8) bool {
    return containsAny(text, &.{ "?", "optional", "is_null", "is_non_null" });
}

fn isErrorUnionText(text: []const u8) bool {
    return containsAny(text, &.{ "error", "errunion", "is_err", "is_non_err" });
}

fn containsAny(text: []const u8, needles: []const []const u8) bool {
    for (needles) |needle| {
        if (std.mem.indexOf(u8, text, needle) != null) return true;
    }
    return false;
}

test "opcode capability registry covers inventory and lowering policies" {
    try std.testing.expect(isIgnoredOpcode("dbg_stmt"));
    try std.testing.expect(isInventoryKnownOpcode("dbg_stmt"));
    try std.testing.expect(isTypedV2LowerableOpcode("block"));
    try std.testing.expect(isReturnOpcode("ret_safe"));
    try std.testing.expect(!isReturnOpcode("call"));
    try std.testing.expect(isStraightLineOpcode("assembly"));
    try std.testing.expect(isInventoryKnownOpcode("assembly"));
    try std.testing.expect(!isTypedV2LowerableOpcode("assembly"));
    try std.testing.expect(!isInventoryKnownOpcode("definitely_unknown_opcode"));
    try std.testing.expectEqual(UnknownOpcodeCategory.pointer_address, unknownOpcodeCategory("slice_ptr", "none"));
    try std.testing.expectEqual(UnknownOpcodeCategory.error_union_try, unknownOpcodeCategory("try_ptr", "error_union"));
    try std.testing.expectEqual(UnknownOpcodeCategory.safety_runtime, unknownOpcodeCategory("panic_cold", "none"));
    try std.testing.expectEqual(UnknownOpcodeCategory.error_union_try, opcodeDataKindCapability("try", "pl_op").category);
    try std.testing.expectEqual(CapabilityOwner.semantic_lowering, opcodeDataKindCapability("try", "pl_op").owner);
    try std.testing.expectEqual(UnknownOpcodeCategory.pointer_address, dataKindCapability("ptr_slice_len_ptr:ty_op").category);
    try std.testing.expectEqual(CapabilityOwner.semantic_lowering, dataKindCapability("ptr_slice_len_ptr:ty_op").owner);

    const try_capability = opcodeCapability("try");
    try std.testing.expectEqual(OpcodeStatus.lowerable, try_capability.status);
    try std.testing.expectEqual(CapabilityOwner.semantic_lowering, try_capability.owner);
    try std.testing.expectEqual(LowererKind.typed_v2_semantic, try_capability.lowerer);
    try std.testing.expect(typedV2CanLower(try_capability));

    const block_capability = opcodeCapability("block");
    try std.testing.expectEqual(CapabilityOwner.cfg_lowering, block_capability.owner);
    try std.testing.expectEqual(LowererKind.typed_v2_cfg, block_capability.lowerer);
    try std.testing.expect(typedV2CanLower(opcodeCapability("cond_br")));
    try std.testing.expectEqual(CapabilityOwner.cfg_lowering, opcodeCapability("cond_br").owner);

    const call_capability = opcodeCapability("call");
    try std.testing.expectEqual(CapabilityOwner.abi_planner, call_capability.owner);
    try std.testing.expectEqual(LowererKind.call_abi, call_capability.lowerer);
    try std.testing.expectEqualStrings("tail", callTailKindForOpcode("call_always_tail").?);
    try std.testing.expectEqualStrings("notail", callTailKindForOpcode("call_never_tail").?);
    try std.testing.expectEqualStrings("neverinline", callTailKindForOpcode("call_never_inline").?);
    try std.testing.expect(callTailKindForOpcode("call") == null);
    try std.testing.expectEqual(SemanticDomain.scalar, semanticDomainForOpcode("add"));
    try std.testing.expectEqual(ScalarSemanticOp.arg, scalarSemanticOpForOpcode("arg"));
    try std.testing.expectEqual(ScalarSemanticOp.add_with_overflow, scalarSemanticOpForOpcode("add_with_overflow"));
    try std.testing.expectEqual(ScalarSemanticOp.binary, scalarSemanticOpForOpcode("add"));
    try std.testing.expectEqual(ScalarSemanticOp.compare, scalarSemanticOpForOpcode("cmp_eq"));
    try std.testing.expectEqual(ScalarSemanticOp.cast, scalarSemanticOpForOpcode("intcast"));
    try std.testing.expectEqual(SemanticDomain.memory, semanticDomainForOpcode("load"));
    try std.testing.expectEqual(MemorySemanticOp.alloc, memorySemanticOpForOpcode("alloc"));
    try std.testing.expectEqual(MemorySemanticOp.load, memorySemanticOpForOpcode("load"));
    try std.testing.expectEqual(MemorySemanticOp.store, memorySemanticOpForOpcode("store"));
    try std.testing.expectEqual(MemorySemanticOp.store, memorySemanticOpForOpcode("store_safe"));
    try std.testing.expectEqual(SemanticDomain.optional, semanticDomainForOpcode("optional_payload"));
    try std.testing.expectEqual(OptionalSemanticOp.is_non_null, optionalSemanticOpForOpcode("is_non_null"));
    try std.testing.expectEqual(OptionalSemanticOp.wrap_optional, optionalSemanticOpForOpcode("wrap_optional"));
    try std.testing.expectEqual(OptionalSemanticOp.optional_payload, optionalSemanticOpForOpcode("optional_payload"));
    try std.testing.expectEqual(SemanticDomain.error_union, semanticDomainForOpcode("try"));
    try std.testing.expectEqual(ErrorUnionSemanticOp.is_non_err, errorUnionSemanticOpForOpcode("is_non_err"));
    try std.testing.expectEqual(ErrorUnionSemanticOp.wrap_payload, errorUnionSemanticOpForOpcode("wrap_errunion_payload"));
    try std.testing.expectEqual(ErrorUnionSemanticOp.wrap_err, errorUnionSemanticOpForOpcode("wrap_errunion_err"));
    try std.testing.expectEqual(ErrorUnionSemanticOp.unwrap_payload, errorUnionSemanticOpForOpcode("unwrap_errunion_payload"));
    try std.testing.expectEqual(ErrorUnionSemanticOp.unwrap_err, errorUnionSemanticOpForOpcode("unwrap_errunion_err"));
    try std.testing.expectEqual(ErrorUnionSemanticOp.try_op, errorUnionSemanticOpForOpcode("try"));
    try std.testing.expectEqual(SemanticDomain.pointer_aggregate, semanticDomainForOpcode("ptr_add"));
    try std.testing.expectEqual(PointerAggregateSemanticOp.slice, pointerAggregateSemanticOpForOpcode("slice"));
    try std.testing.expectEqual(PointerAggregateSemanticOp.ptr_gep, pointerAggregateSemanticOpForOpcode("ptr_add"));
    try std.testing.expectEqual(PointerAggregateSemanticOp.ptr_gep, pointerAggregateSemanticOpForOpcode("ptr_elem_ptr"));
    try std.testing.expectEqual(PointerAggregateSemanticOp.runtime_nav_ptr, pointerAggregateSemanticOpForOpcode("runtime_nav_ptr"));
    try std.testing.expectEqual(PointerAggregateSemanticOp.array_elem_val, pointerAggregateSemanticOpForOpcode("array_elem_val"));
    try std.testing.expectEqual(PointerAggregateSemanticOp.field_ptr, pointerAggregateSemanticOpForOpcode("struct_field_ptr"));
    try std.testing.expectEqual(SemanticDomain.none, semanticDomainForOpcode("call"));
    try std.testing.expectEqual(SemanticDomain.none, semanticDomainForOpcode("block"));
    try std.testing.expectEqual(CfgLoweringOp.block, cfgLoweringOpForOpcode("block"));
    try std.testing.expectEqual(CfgLoweringOp.cond_br, cfgLoweringOpForOpcode("cond_br"));
    try std.testing.expectEqual(CfgLoweringOp.ret, cfgLoweringOpForOpcode("ret"));
    try std.testing.expectEqual(CfgLoweringOp.ret, cfgLoweringOpForOpcode("ret_safe"));
    try std.testing.expectEqual(CfgLoweringOp.unreach, cfgLoweringOpForOpcode("unreach"));
    try std.testing.expectEqual(CfgLoweringOp.none, cfgLoweringOpForOpcode("add"));

    const asm_capability = opcodeCapability("assembly");
    try std.testing.expectEqual(OpcodeStatus.boundary, asm_capability.status);
    try std.testing.expectEqual(LowererKind.boundary, asm_capability.lowerer);
    try std.testing.expect(!typedV2CanLower(asm_capability));
    try std.testing.expectEqualStrings("inline-asm", typedV2FallbackReason(asm_capability));
    try std.testing.expectEqualStrings("inventory-only", typedV2FallbackReason(opcodeCapability("memcpy")));
    try std.testing.expectEqualStrings("unknown-opcode", typedV2FallbackReason(opcodeCapability("definitely_unknown_opcode")));
}

test "type surface capability classifies inventory and ABI boundary surfaces" {
    const mixed = typeSurfaceCapability("fn (*i32, []const u8, ?i32) error{}!void");
    try std.testing.expect(mixed.pointer);
    try std.testing.expect(mixed.slice);
    try std.testing.expect(mixed.optional);
    try std.testing.expect(mixed.error_union);

    try std.testing.expectEqual(TypeBoundary.vector, typeSurfaceCapability("@Vector(4, f32)").firstBoundary().?);
    try std.testing.expectEqual(TypeBoundary.x87, boundaryForIrType(.fp128).?);
    try std.testing.expectEqual(TypeBoundary.vector, boundaryForIrType(.{ .vector = .{ .len = 4, .elem_ty = .float } }).?);
    try std.testing.expectEqual(TypeBoundary.packed_aggregate, boundaryForIrType(.{ .aggregate = "<{ i32, i32 }" }).?);
}

test "aggregate layout capability resolves nested fields by offset" {
    const layout = try target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
    const aggregate_ty: ir.Type = .{ .aggregate = "{ i32, { i64, float } }" };

    try std.testing.expectEqual(@as(usize, 2), aggregateFieldCount(aggregate_ty));
    try std.testing.expectEqual(@as(u64, 0), aggregateFieldByteOffset(layout, aggregate_ty, 0).?);
    try std.testing.expectEqual(@as(u64, 8), aggregateFieldByteOffset(layout, aggregate_ty, 1).?);
    try std.testing.expectEqual(@as(usize, 1), aggregateFieldIndexAtOffset(layout, aggregate_ty, 16, .float).?);
    try std.testing.expect((aggregateLeafTypeAtOffset(layout, aggregate_ty, 16) orelse return error.TestUnexpectedResult).eql(.float));

    var leaves: [4]AggregateLeaf = undefined;
    var leaf_count: usize = 0;
    try collectSupportedScalarAggregateLeaves(layout, aggregate_ty, 0, &leaves, &leaf_count);
    try std.testing.expectEqual(@as(usize, 3), leaf_count);
    try std.testing.expectEqual(@as(u64, 0), leaves[0].offset);
    try std.testing.expectEqual(@as(u64, 8), leaves[1].offset);
    try std.testing.expectEqual(@as(u64, 16), leaves[2].offset);
}
