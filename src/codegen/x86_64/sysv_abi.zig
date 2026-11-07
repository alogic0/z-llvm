const std = @import("std");
const air_capabilities = @import("../../zig_air_capabilities.zig");
const ir = @import("../../ir.zig");
const target = @import("../../target.zig");
const type_layout = @import("../../zig_air_type_layout.zig");
const types = @import("types.zig");
const syntax = @import("../../ir/parser_syntax.zig");

const ArgReg = types.ArgReg;
const XmmReg = types.XmmReg;

pub const AggregateEightbyteClass = enum {
    integer,
    sse,
};

pub const AggregateKind = enum {
    register,
    memory,
};

pub const AggregateClassification = struct {
    kind: AggregateKind,
    eightbytes: [2]?AggregateEightbyteClass = .{ null, null },
    eightbyte_count: u2 = 0,
    size_bytes: u64 = 0,

    pub fn isIntegerOnly(classification: AggregateClassification) bool {
        if (classification.kind != .register or classification.eightbyte_count == 0) return false;
        var index: usize = 0;
        while (index < classification.eightbyte_count) : (index += 1) {
            if (classification.eightbytes[index] != .integer) return false;
        }
        return true;
    }

    pub fn isSseOnly(classification: AggregateClassification) bool {
        if (classification.kind != .register or classification.eightbyte_count == 0) return false;
        var index: usize = 0;
        while (index < classification.eightbyte_count) : (index += 1) {
            if (classification.eightbytes[index] != .sse) return false;
        }
        return true;
    }
};

pub const SseAggregateReturnKind = enum {
    packed_f32x2,
    split_f64x2,
};

pub fn sseAggregateReturnKind(ty: ir.Type) ?SseAggregateReturnKind {
    if (ty != .aggregate) return null;
    if (compactTypeTextEql(ty.aggregate, "{<2xfloat>}")) return .packed_f32x2;
    const first = type_layout.fieldType(ty, 0) orelse return null;
    const second = type_layout.fieldType(ty, 1);
    if (second == null and type_layout.fieldType(ty, 2) == null and first == .vector) {
        const vector = first.vector;
        if (vector.len == 2 and vector.elem_ty == .float) return .packed_f32x2;
        return null;
    }
    if (first == .double and second != null and second.? == .double and type_layout.fieldType(ty, 2) == null) {
        return .split_f64x2;
    }
    return null;
}

fn compactTypeTextEql(text: []const u8, expected: []const u8) bool {
    var expected_index: usize = 0;
    for (text) |byte| {
        if (std.ascii.isWhitespace(byte)) continue;
        if (expected_index >= expected.len or byte != expected[expected_index]) return false;
        expected_index += 1;
    }
    return expected_index == expected.len;
}

pub fn dataLayout() !target.DataLayout {
    return target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
}

pub fn classifyAggregateForTest(ty: ir.Type) !AggregateClassification {
    return try classifyAggregate(ty);
}

pub fn classifyAggregate(ty: ir.Type) !AggregateClassification {
    const normalized_ty = type_layout.normalizeAggregateType(ty);
    switch (normalized_ty) {
        .aggregate => |text| {
            const trimmed = std.mem.trim(u8, text, " \t");
            if (std.mem.startsWith(u8, trimmed, "<{")) return .{ .kind = .memory };
        },
        else => {},
    }
    const layout = try dataLayout();
    const size = blk: {
        var max_leaf_end: u64 = 0;
        var f_idx: usize = 0;
        var has_nominal = false;
        while (type_layout.fieldType(normalized_ty, f_idx)) |f_ty| : (f_idx += 1) {
            if (type_layout.fieldByteOffset(layout, ty, f_idx)) |off| {
                const f_size = layout.typeStoreSizeBytes(f_ty) catch break;
                max_leaf_end = @max(max_leaf_end, off + f_size);
                has_nominal = true;
            }
        }
        if (has_nominal and max_leaf_end > 0) {
            break :blk @min(try layout.typeStoreSizeBytes(normalized_ty), std.mem.alignForward(u64, max_leaf_end, 8));
        }
        break :blk try layout.typeStoreSizeBytes(normalized_ty);
    };
    if (size == 0 or size > 16) return .{ .kind = .memory, .size_bytes = size };

    const classification = try classifyAggregateSized(layout, ty, size);
    return if (classification.kind == .register and classification.eightbyte_count == 0)
        .{ .kind = .memory, .size_bytes = size }
    else
        classification;
}

fn classifyAggregateSized(layout: target.DataLayout, ty: ir.Type, size: u64) !AggregateClassification {
    var classification = AggregateClassification{
        .kind = .register,
        .eightbyte_count = @intCast((size + 7) / 8),
        .size_bytes = size,
    };
    try classifyAggregateInto(layout, ty, 0, &classification);
    return classification;
}

fn classifyAggregateInto(
    layout: target.DataLayout,
    ty: ir.Type,
    base_offset: u64,
    classification: *AggregateClassification,
) !void {
    if (classification.kind == .memory) return;
    switch (ty) {
        .aggregate => |text| {
            const trimmed = std.mem.trim(u8, text, " \t");
            if (std.mem.startsWith(u8, trimmed, "<{")) {
                classification.kind = .memory;
                return;
            }
            var field_index: usize = 0;
            var saw_field = false;
            while (type_layout.fieldType(ty, field_index)) |field_ty| : (field_index += 1) {
                saw_field = true;
                const field_offset = type_layout.fieldByteOffset(layout, ty, field_index) orelse {
                    classification.kind = .memory;
                    return;
                };
                const field_size = try layout.typeStoreSizeBytes(field_ty);
                const field_align_bytes = bitsToBytes(try layout.typeAbiAlignmentBits(field_ty));
                if (field_align_bytes != 0 and field_offset % field_align_bytes != 0) {
                    classification.kind = .memory;
                    return;
                }
                try classifyAggregateInto(layout, field_ty, base_offset + field_offset, classification);
                if (base_offset + field_offset + field_size > 16) {
                    classification.kind = .memory;
                    return;
                }
            }
            if (!saw_field) classification.kind = .memory;
        },
        .int, .ptr => {
            const size = try layout.typeStoreSizeBytes(ty);
            try mergeAggregateClass(classification, base_offset, size, .integer);
        },
        .half, .float, .double, .vector => {
            const size = scalarOrVectorSizeBytes(ty) orelse {
                classification.kind = .memory;
                return;
            };
            if (size > 16) {
                classification.kind = .memory;
                return;
            }
            try mergeAggregateClass(classification, base_offset, size, .sse);
        },
        .x86_fp80, .fp128, .void, .metadata => classification.kind = .memory,
    }
}

fn mergeAggregateClass(
    classification: *AggregateClassification,
    offset: u64,
    size: u64,
    class: AggregateEightbyteClass,
) !void {
    if (size == 0) return;
    if (offset + size > 16) {
        classification.kind = .memory;
        return;
    }
    const first = offset / 8;
    const last = (offset + size - 1) / 8;
    var index = first;
    while (index <= last) : (index += 1) {
        if (index >= classification.eightbytes.len) {
            classification.kind = .memory;
            return;
        }
        const slot = &classification.eightbytes[@intCast(index)];
        slot.* = mergeEightbyte(slot.*, class);
    }
}

fn mergeEightbyte(existing: ?AggregateEightbyteClass, incoming: AggregateEightbyteClass) AggregateEightbyteClass {
    const current = existing orelse return incoming;
    if (current == .integer or incoming == .integer) return .integer;
    return .sse;
}

fn scalarOrVectorSizeBytes(ty: ir.Type) ?u64 {
    return switch (ty) {
        .half => 2,
        .float => 4,
        .double => 8,
        .vector => |vector| vector.len * (switch (vector.elem_ty) {
            .int => |bits| if (bits % 8 == 0) bits / 8 else return null,
            .half => 2,
            .float => 4,
            .double => 8,
            .fp128 => 16,
            .ptr => 8,
        }),
        .void, .int, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => null,
    };
}

fn bitsToBytes(bits: u16) u64 {
    return (@as(u64, bits) + 7) / 8;
}

pub const SmallIntegerAggregate = struct {
    eightbytes: u2,
    size_bytes: u8,
};

pub fn classifySmallIntegerAggregate(ty: ir.Type) ?SmallIntegerAggregate {
    const classification = classifyAggregate(ty) catch return null;
    if (!classification.isIntegerOnly()) return null;
    if (classification.size_bytes > std.math.maxInt(u8)) return null;
    return .{ .eightbytes = classification.eightbyte_count, .size_bytes = @intCast(classification.size_bytes) };
}

pub const RegisterNeeds = struct {
    gpr: usize = 0,
    sse: usize = 0,
};

pub fn aggregateRegisterNeeds(classification: AggregateClassification) RegisterNeeds {
    return aggregateRegisterNeedsBefore(classification, classification.eightbyte_count);
}

pub fn aggregateRegisterNeedsBefore(classification: AggregateClassification, limit: usize) RegisterNeeds {
    var needs: RegisterNeeds = .{};
    var index: usize = 0;
    while (index < limit and index < classification.eightbyte_count) : (index += 1) {
        switch (classification.eightbytes[index] orelse continue) {
            .integer => needs.gpr += 1,
            .sse => needs.sse += 1,
        }
    }
    return needs;
}

pub fn advanceParamCursors(
    ty: ir.Type,
    gpr_index: *usize,
    sse_index: *usize,
    stack_eightbytes: *usize,
) !void {
    if (isScalarGprAbiType(ty)) {
        if (gpr_index.* < 6) gpr_index.* += 1 else stack_eightbytes.* += 1;
        return;
    }
    if (isScalarSseAbiType(ty) or isVector128AbiType(ty)) {
        if (isVector128AbiType(ty) and sse_index.* >= 8) return error.UnsupportedCodegenValue;
        if (sse_index.* < 8) sse_index.* += 1 else stack_eightbytes.* += 1;
        return;
    }
    const classification = classifyAggregate(ty) catch return;
    if (classification.kind == .memory) {
        stack_eightbytes.* += @intCast((classification.size_bytes + 7) / 8);
        return;
    }
    const needs = aggregateRegisterNeeds(classification);
    if (gpr_index.* + needs.gpr <= 6 and sse_index.* + needs.sse <= 8) {
        gpr_index.* += needs.gpr;
        sse_index.* += needs.sse;
    } else {
        stack_eightbytes.* += @intCast((classification.size_bytes + 7) / 8);
    }
}

pub const CallPlanCounts = struct {
    gpr_args: usize = 0,
    sse_args: usize = 0,
    stack_args: usize = 0,
    register_aggregate_args: usize = 0,
    gpr_returns: usize = 0,
    sse_returns: usize = 0,
    memory_return: bool = false,
};

pub const CallArgAssignment = union(enum) {
    gpr: ArgReg,
    sse: XmmReg,
    stack_i32_const: i32,
    stack_i32_param: []const u8,
    stack_f32_const: []const u8,
    stack_f32_param: []const u8,
    stack_f64_const: []const u8,
    stack_f64_param: []const u8,
    byval_stack_copy: ByvalStackCopy,
    aggregate_register_passthrough: RegisterAggregatePassThrough,
    aggregate_stack_passthrough: RegisterAggregatePassThrough,
};

pub const ByvalStackCopy = struct {
    source_name: []const u8,
    aggregate_ty: ir.Type,
    classification: AggregateClassification,
};

pub const AggregatePassDestination = union(enum) {
    registers: struct {
        gpr: usize,
        sse: usize,
    },
    stack,
};

pub const RegisterAggregatePassThrough = struct {
    classification: AggregateClassification,
    source: ParamCursor,
    dest: AggregatePassDestination,
};

pub const CallPlan = struct {
    assignments: std.ArrayList(CallArgAssignment) = .empty,
    counts: CallPlanCounts = .{},
    has_non_i32_arg: bool = false,

    pub fn deinit(self: *CallPlan, allocator: std.mem.Allocator) void {
        self.assignments.deinit(allocator);
    }
};

pub fn isBoundaryError(err: anyerror) bool {
    return switch (err) {
        error.UnsupportedVarargsAbi,
        error.UnsupportedVectorAbi,
        error.UnsupportedLongDoubleAbi,
        error.UnsupportedPackedAggregateAbi,
        error.UnsupportedTailCallAbi,
        error.UnsupportedCallConvAbi,
        error.UnsupportedCallAttributeAbi,
        error.UnsupportedSretByvalAbi,
        => true,
        else => false,
    };
}

pub fn callPlanCountsForTest(allocator: std.mem.Allocator, function: ir.Function, call: ir.CallInst) !CallPlanCounts {
    var plan = try planCall(allocator, function, call);
    defer plan.deinit(allocator);
    return plan.counts;
}

pub fn callHasByvalArgAttrs(call: ir.CallInst) bool {
    for (call.args.items) |arg| {
        if (arg.attrs) |attrs| {
            if (std.mem.indexOf(u8, attrs, "byval") != null) return true;
        }
    }
    return false;
}

pub fn planCall(allocator: std.mem.Allocator, function: ir.Function, call: ir.CallInst) !CallPlan {
    return planCallWithFunction(allocator, function, call);
}

pub fn planScalarCall(allocator: std.mem.Allocator, call: ir.CallInst) !CallPlan {
    return planCallWithFunction(allocator, null, call);
}

fn planCallWithFunction(allocator: std.mem.Allocator, function: ?ir.Function, call: ir.CallInst) !CallPlan {
    try rejectUnsupportedCallEnvelope(call);
    try rejectUnsupportedCallSignature(call);
    try rejectUnsupportedAbiType(call.ret_ty);

    var plan: CallPlan = .{};
    errdefer plan.deinit(allocator);
    plan.counts = try planReturn(call.ret_ty);

    var int_arg_index: usize = 0;
    var fp_arg_index: usize = 0;
    for (call.args.items) |arg| {
        if (callArgByvalType(arg)) |byval_ty| {
            try rejectUnsupportedAbiType(byval_ty);
            if (arg.ty != .ptr) return error.UnsupportedSretByvalAbi;
            const source_name = switch (arg.value) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            const classification = try classifyAggregate(byval_ty);
            if (classification.size_bytes == 0) return error.UnsupportedSretByvalAbi;
            if (!supportsByvalStackCopySize(classification.size_bytes)) return error.UnsupportedSretByvalAbi;
            try plan.assignments.append(allocator, .{ .byval_stack_copy = .{
                .source_name = source_name,
                .aggregate_ty = byval_ty,
                .classification = classification,
            } });
            plan.has_non_i32_arg = true;
            plan.counts.stack_args += aggregateStackEightbytes(classification);
            continue;
        }
        try rejectUnsupportedCallArgAttrs(arg);
        try rejectUnsupportedAbiType(arg.ty);
        if (isGprScalarType(arg.ty)) {
            plan.has_non_i32_arg = plan.has_non_i32_arg or !arg.ty.eql(.{ .int = 32 });
            if (int_arg_index >= 6) {
                const assignment: CallArgAssignment = switch (arg.value) {
                    .int => |int| .{ .stack_i32_const = try i32Value(int) },
                    .named => |name| .{ .stack_i32_param = name },
                    .null_value => if (arg.ty == .ptr) .{ .stack_i32_const = 0 } else return error.UnsupportedCodegenValue,
                    .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                };
                try plan.assignments.append(allocator, assignment);
                int_arg_index += 1;
                plan.counts.stack_args += 1;
                continue;
            }
            try plan.assignments.append(allocator, .{ .gpr = try ArgReg.fromIndex(int_arg_index) });
            int_arg_index += 1;
            plan.counts.gpr_args += 1;
            continue;
        }
        if (isScalarSseAbiType(arg.ty) or isVector128AbiType(arg.ty)) {
            plan.has_non_i32_arg = true;
            if (fp_arg_index >= 8) {
                if (isVector128AbiType(arg.ty)) return error.UnsupportedVectorAbi;
                if (arg.ty == .half) return error.UnsupportedCodegenType;
                const assignment: CallArgAssignment = switch (arg.value) {
                    .fp => |text| if (arg.ty.eql(.float))
                        .{ .stack_f32_const = text }
                    else
                        .{ .stack_f64_const = text },
                    .named => |name| if (arg.ty.eql(.float))
                        .{ .stack_f32_param = name }
                    else
                        .{ .stack_f64_param = name },
                    .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                };
                try plan.assignments.append(allocator, assignment);
                fp_arg_index += 1;
                plan.counts.stack_args += 1;
                continue;
            }
            try plan.assignments.append(allocator, .{ .sse = try XmmReg.fromIndex(fp_arg_index) });
            fp_arg_index += 1;
            plan.counts.sse_args += 1;
            continue;
        }
        if (isAggregateType(arg.ty)) {
            const caller = function orelse return error.UnsupportedCodegenType;
            plan.has_non_i32_arg = true;
            const classification = try classifyAggregate(arg.ty);
            const pass = try planAggregatePassThrough(caller, arg, classification, &int_arg_index, &fp_arg_index);
            switch (pass.dest) {
                .registers => {
                    plan.counts.register_aggregate_args += 1;
                    try plan.assignments.append(allocator, .{ .aggregate_register_passthrough = pass });
                },
                .stack => {
                    plan.counts.stack_args += aggregateStackEightbytes(pass.classification);
                    try plan.assignments.append(allocator, .{ .aggregate_stack_passthrough = pass });
                },
            }
            continue;
        }
        return error.UnsupportedCodegenType;
    }
    return plan;
}

pub fn planReturn(ret_ty: ir.Type) !CallPlanCounts {
    if (sseAggregateReturnKind(ret_ty)) |kind| {
        return .{ .sse_returns = switch (kind) {
            .packed_f32x2 => 1,
            .split_f64x2 => 2,
        } };
    }
    try rejectUnsupportedAbiType(ret_ty);
    if (ret_ty == .void) return .{};
    if (isScalarGprAbiType(ret_ty)) {
        return .{ .gpr_returns = 1 };
    }
    if (isScalarSseAbiType(ret_ty) or isVector128AbiType(ret_ty)) {
        return .{ .sse_returns = 1 };
    }
    if (isAggregateType(ret_ty)) {
        const classification = try classifyAggregate(ret_ty);
        if (classification.kind == .memory) return .{ .memory_return = true };
        const needs = aggregateRegisterNeeds(classification);
        return .{ .gpr_returns = needs.gpr, .sse_returns = needs.sse };
    }
    return error.UnsupportedCodegenType;
}

pub fn isScalarSseAbiType(ty: ir.Type) bool {
    return ty == .half or ty == .float or ty == .double;
}

/// Native 128-bit SysV vector values occupy one complete XMM register.
/// Stack vectors and aggregates containing vectors remain separate boundaries.
pub fn isVector128AbiType(ty: ir.Type) bool {
    if (ty != .vector) return false;
    const v = ty.vector;
    return (v.len == 4 and (v.elem_ty == .float or (v.elem_ty == .int and v.elem_ty.int == 32))) or
        (v.len == 2 and (v.elem_ty == .double or (v.elem_ty == .int and v.elem_ty.int == 64)));
}

pub fn callHasScalarSseType(call: ir.CallInst) bool {
    if (isScalarSseAbiType(call.ret_ty) or isVector128AbiType(call.ret_ty)) return true;
    for (call.args.items) |arg| {
        if (isScalarSseAbiType(arg.ty) or isVector128AbiType(arg.ty)) return true;
    }
    return false;
}

pub fn entryXmmDefinedBits(function: ir.Function) [8]u16 {
    var result: [8]u16 = @splat(0);
    var xmm_index: usize = 0;
    for (function.params.items) |param| {
        if (isVector128AbiType(param.ty)) {
            if (xmm_index < result.len) result[xmm_index] = 128;
            xmm_index += 1;
            continue;
        }
        if (isScalarSseAbiType(param.ty)) {
            if (xmm_index < result.len) result[xmm_index] = if (param.ty == .half) 16 else if (param.ty == .float) 32 else 64;
            xmm_index += 1;
            continue;
        }
        if (param.ty != .aggregate) continue;
        const classification = classifyAggregate(param.ty) catch continue;
        if (classification.kind != .register) continue;
        var class_index: usize = 0;
        while (class_index < classification.eightbyte_count) : (class_index += 1) {
            if (classification.eightbytes[class_index] == .sse) {
                if (xmm_index < result.len) result[xmm_index] = 64;
                xmm_index += 1;
            }
        }
    }
    return result;
}

pub fn rejectUnsupportedCallEnvelope(call: ir.CallInst) !void {
    if (call.tail_kind) |tail_kind| {
        if (std.mem.eql(u8, tail_kind, "musttail")) return error.UnsupportedTailCallAbi;
        if (!std.mem.eql(u8, tail_kind, "tail") and !std.mem.eql(u8, tail_kind, "notail")) {
            return error.UnsupportedTailCallAbi;
        }
    }
    if (call.inline_asm != null) return error.UnsupportedCallAttributeAbi;
    if (call.ret_attrs) |attrs| {
        try rejectUnsupportedAbiAttrPayload(attrs);
        if (attrsContainAbiPayload(attrs, "sret") or attrsContainAbiPayload(attrs, "byval")) {
            return error.UnsupportedSretByvalAbi;
        }
        if (!callReturnAttrsSupported(call)) return error.UnsupportedCallAttributeAbi;
    }
    if (call.attrs) |attrs| {
        try rejectUnsupportedAbiAttrPayload(attrs);
        if (attrsContainAbiPayload(attrs, "sret") or attrsContainAbiPayload(attrs, "byval")) {
            return error.UnsupportedSretByvalAbi;
        }
        if (!isAttributeGroupReference(attrs)) return error.UnsupportedCallAttributeAbi;
    }
    if (call.operand_bundle != null) return error.UnsupportedCallAttributeAbi;
}

fn isAttributeGroupReference(attrs: []const u8) bool {
    const trimmed = std.mem.trim(u8, attrs, " \t");
    if (trimmed.len < 2 or trimmed[0] != '#') return false;
    for (trimmed[1..]) |c| {
        if (!std.ascii.isDigit(c)) return false;
    }
    return true;
}

pub fn callReturnAttrsSupported(call: ir.CallInst) bool {
    const attrs = call.ret_attrs orelse return true;
    // Return facts do not change the register representation. Parameter-only
    // promises (capture, memory effects, allocptr) are excluded here.
    ir.verifyParameterAttrs(call.ret_ty, attrs) catch return false;
    var rest = std.mem.trim(u8, attrs, " \t");
    while (rest.len != 0) {
        const end = syntax.findTopLevelTokenEnd(rest) orelse return false;
        if (end == 0) return false;
        const token = rest[0..end];
        rest = std.mem.trim(u8, rest[end..], " \t");
        if (std.mem.eql(u8, token, "noundef") and call.ret_ty != .void) continue;
        if (call.ret_ty == .int and std.mem.startsWith(u8, token, "range(")) continue;
        if (call.ret_ty == .ptr and (std.mem.eql(u8, token, "noalias") or std.mem.eql(u8, token, "nonnull") or
            std.mem.startsWith(u8, token, "dereferenceable("))) continue;
        if (call.ret_ty == .ptr and std.mem.eql(u8, token, "align")) {
            const alignment_end = syntax.findTopLevelTokenEnd(rest) orelse return false;
            if (alignment_end == 0) return false;
            rest = std.mem.trim(u8, rest[alignment_end..], " \t");
            continue;
        }
        return false;
    }
    return true;
}

pub fn isVariadicCall(call: ir.CallInst) bool {
    return if (call.callee_function_ty) |ty| std.mem.indexOf(u8, ty, "...") != null else false;
}

pub fn functionHasVariadicCall(function: ir.Function) bool {
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .call and isVariadicCall(inst.kind.call)) return true;
    };
    return false;
}

// Direct C variadic calls with ordinary pointer/i32/i64 arguments. The
// existing scalar call owner supplies register/stack placement and AL = 0.
// Floating, split-wide and indirect variadic calls remain separate boundaries.
pub fn isSupportedPointerVariadicCall(call: ir.CallInst) bool {
    if (!isVariadicCall(call) or call.callee_value != null or call.inline_asm != null or
        call.raw_args != null or call.operand_bundle != null or call.ret_attrs != null or
        call.args.items.len == 0 or call.args.items.len > 16 or
        !(call.ret_ty == .void or call.ret_ty == .ptr or call.ret_ty.eql(.{ .int = 32 }) or call.ret_ty.eql(.{ .int = 64 }))) return false;
    if (call.calling_conv) |cc| if (!std.mem.eql(u8, cc, "ccc")) return false;
    var ty = std.mem.trim(u8, call.callee_function_ty.?, " \t");
    if (ty.len >= 2 and ty[0] == '(' and ty[ty.len - 1] == ')') ty = ty[1 .. ty.len - 1];
    var fields = std.mem.splitScalar(u8, ty, ',');
    var fixed: usize = 0;
    var variadic = false;
    while (fields.next()) |field| {
        const text = std.mem.trim(u8, field, " \t");
        if (std.mem.eql(u8, text, "...")) {
            variadic = true;
            if (fields.next() != null) return false;
            break;
        }
        if (fixed >= call.args.items.len) return false;
        const expected: ir.Type = if (std.mem.eql(u8, text, "ptr")) .ptr else if (std.mem.eql(u8, text, "i32")) .{ .int = 32 } else if (std.mem.eql(u8, text, "i64")) .{ .int = 64 } else return false;
        if (!call.args.items[fixed].ty.eql(expected)) return false;
        fixed += 1;
    }
    if (!variadic or fixed == 0) return false;
    for (call.args.items) |arg| {
        if (!(arg.ty == .ptr or arg.ty.eql(.{ .int = 32 }) or arg.ty.eql(.{ .int = 64 }))) return false;
        rejectUnsupportedCallArgAttrs(arg) catch return false;
    }
    return true;
}

pub fn rejectUnsupportedCallSignature(call: ir.CallInst) !void {
    if (call.calling_conv) |calling_conv| {
        if (!std.mem.eql(u8, calling_conv, "ccc") and !std.mem.eql(u8, calling_conv, "fastcc")) {
            return error.UnsupportedCallConvAbi;
        }
    }
    if (isVariadicCall(call) and !isSupportedPointerVariadicCall(call)) return error.UnsupportedVarargsAbi;
}

fn rejectUnsupportedAbiAttrPayload(attrs: []const u8) !void {
    inline for (.{ "sret", "byval" }) |name| {
        if (attrsContainPackedAbiPayload(attrs, name)) {
            return error.UnsupportedPackedAggregateAbi;
        }
        if (attrsContainVectorAbiPayload(attrs, name)) {
            if (!std.mem.eql(u8, name, "sret") or !boundedVectorSret(attrs)) return error.UnsupportedVectorAbi;
        }
        if (attrsContainLongDoubleAbiPayload(attrs, name)) {
            return error.UnsupportedLongDoubleAbi;
        }
    }
}

pub fn rejectUnsupportedCallArgAttrs(arg: ir.CallArg) !void {
    const text = arg.attrs orelse return;
    try rejectUnsupportedAbiAttrPayload(text);
    if (attrsContainAbiPayload(text, "byval")) {
        return error.UnsupportedSretByvalAbi;
    }
    if (attrsContainAbiPayload(text, "sret")) {
        if (arg.ty != .ptr) return error.UnsupportedSretByvalAbi;
        return;
    }
    if (std.mem.eql(u8, std.mem.trim(u8, text, " \t"), "noundef")) return;
    if (arg.ty == .ptr and pointerCallAttrsAreAdvisory(text)) return;
    if (arg.ty == .int and callReturnAttrsSupported(.{ .callee = "", .ret_ty = arg.ty, .ret_attrs = text, .args = .empty })) return;
    return error.UnsupportedCallAttributeAbi;
}

/// Validated pointer facts that require no change to the machine call or
/// ordinary memory operation. ABI payloads and address spaces stay excluded.
pub fn pointerCallAttrsAreAdvisory(attrs: []const u8) bool {
    ir.verifyParameterAttrs(.ptr, attrs) catch return false;
    var rest = std.mem.trim(u8, attrs, " \t");
    var saw_attr = false;
    while (rest.len != 0) {
        const end = syntax.findTopLevelTokenEnd(rest) orelse return false;
        if (end == 0) return false;
        const token = rest[0..end];
        rest = std.mem.trim(u8, rest[end..], " \t");
        saw_attr = true;
        if (std.mem.eql(u8, token, "noundef")) continue;
        if (std.mem.eql(u8, token, "nonnull")) continue;
        if (std.mem.eql(u8, token, "readonly")) continue;
        if (std.mem.eql(u8, token, "writeonly")) continue;
        if (std.mem.eql(u8, token, "noalias")) continue;
        if (std.mem.eql(u8, token, "allocptr")) continue;
        if (std.mem.eql(u8, token, "dead_on_unwind")) continue;
        if (std.mem.eql(u8, token, "captures(none)")) continue;
        if (std.mem.startsWith(u8, token, "dereferenceable(")) continue;
        if (!std.mem.eql(u8, token, "align")) return false;
        const alignment_end = syntax.findTopLevelTokenEnd(rest) orelse return false;
        if (alignment_end == 0) return false;
        rest = std.mem.trim(u8, rest[alignment_end..], " \t");
    }
    return saw_attr;
}

test "pointer advisory attributes validate allocation and memory promises without admitting ABI changes" {
    for ([_][]const u8{
        "allocptr noundef align 1 captures(none)",
        "noundef nonnull align 16 dereferenceable(16)",
        "writeonly captures(none) align 1",
        "dead_on_unwind noalias writeonly align 4 captures(none)",
    }) |attrs| {
        try std.testing.expect(pointerCallAttrsAreAdvisory(attrs));
        try rejectUnsupportedCallArgAttrs(.{ .ty = .ptr, .value = .{ .named = "p" }, .attrs = attrs });
    }
    for ([_][]const u8{
        "allocptr allocptr", "align 3",           "align",      "dereferenceable(no)",
        "captures(unknown)", "allocptr, noundef", "byval(i32)", "sret(i32)",
        "addrspace(1)",
    }) |attrs| try std.testing.expect(!pointerCallAttrsAreAdvisory(attrs));
    try std.testing.expectError(error.UnsupportedCallAttributeAbi, rejectUnsupportedCallArgAttrs(.{ .ty = .{ .int = 64 }, .value = .{ .int = 0 }, .attrs = "allocptr" }));
}

test "call value facts validate typed wrapped ranges without extending the ABI" {
    var call: ir.CallInst = .{ .callee = "callee", .ret_ty = .{ .int = 8 }, .args = .empty };
    for ([_][]const u8{ "noundef", "range(i8 0, 128)", "noundef range(i8 -128, 0)", "range(i8 250, 5)", "range(i8 0, 0)" }) |attrs| {
        call.ret_attrs = attrs;
        try rejectUnsupportedCallEnvelope(call);
        try rejectUnsupportedCallArgAttrs(.{ .ty = call.ret_ty, .attrs = attrs, .value = .{ .named = "v" } });
    }
    for ([_][]const u8{
        "zeroext",                       "signext",                "noundef zeroext",   "range(i16 0, 128)", "range(i8 0 128)",
        "range(i8 0,,128)",              "range(i8 0, 256)",       "range(i8 -129, 0)", "range(i8 255, -1)", "range(i8 5, 5)",
        "range(i8 0, 5) range(i8 0, 5)", "range(i8 0, 5) unknown", "noundef noundef",
    }) |attrs| {
        call.ret_attrs = attrs;
        try std.testing.expectError(error.UnsupportedCallAttributeAbi, rejectUnsupportedCallEnvelope(call));
        try std.testing.expectError(error.UnsupportedCallAttributeAbi, rejectUnsupportedCallArgAttrs(.{ .ty = call.ret_ty, .attrs = attrs, .value = .{ .named = "v" } }));
    }
    call.ret_ty = .ptr;
    call.ret_attrs = "noundef noalias nonnull align 8 dereferenceable(8)";
    try rejectUnsupportedCallEnvelope(call);
    for ([_][]const u8{ "dead_on_unwind", "captures(none)", "allocptr", "writeonly", "sret(i64)", "byval(i64)" }) |attrs| {
        call.ret_attrs = attrs;
        try std.testing.expect(!callReturnAttrsSupported(call));
    }
}

pub fn callArgByvalType(arg: ir.CallArg) ?ir.Type {
    return aggregateAbiAttrType(arg.attrs, "byval");
}

fn aggregateAbiAttrType(attrs: ?[]const u8, name: []const u8) ?ir.Type {
    const text = attrs orelse return null;
    var start: usize = 0;
    while (std.mem.indexOfPos(u8, text, start, name)) |name_index| {
        const open_index = name_index + name.len;
        start = open_index;
        if (open_index >= text.len or text[open_index] != '(') continue;
        const close_index = findMatchingParen(text, open_index) orelse return null;
        const payload = std.mem.trim(u8, text[open_index + 1 .. close_index], " \t");
        if (payload.len >= 2 and ((payload[0] == '{' and payload[payload.len - 1] == '}') or
            (payload[0] == '[' and payload[payload.len - 1] == ']') or
            (payload[0] == '%' and payload.len > 1)))
        {
            return .{ .aggregate = payload };
        }
        start = close_index + 1;
    }
    return null;
}

fn findMatchingParen(text: []const u8, open_index: usize) ?usize {
    var depth: usize = 0;
    var index = open_index;
    while (index < text.len) : (index += 1) {
        switch (text[index]) {
            '(' => depth += 1,
            ')' => {
                if (depth == 0) return null;
                depth -= 1;
                if (depth == 0) return index;
            },
            else => {},
        }
    }
    return null;
}

fn attrsContainAbiPayload(attrs: []const u8, name: []const u8) bool {
    var index: usize = 0;
    while (std.mem.indexOfPos(u8, attrs, index, name)) |found| {
        const after = found + name.len;
        if (after < attrs.len and attrs[after] == '(') return true;
        index = after;
    }
    return false;
}

fn supportsByvalStackCopySize(size_bytes: u64) bool {
    return size_bytes != 0;
}

fn attrsContainPackedAbiPayload(attrs: []const u8, name: []const u8) bool {
    const payload = abiAttrPayload(attrs, name) orelse return false;
    return std.mem.startsWith(u8, payload, "<{");
}

fn attrsContainVectorAbiPayload(attrs: []const u8, name: []const u8) bool {
    const payload = abiAttrPayload(attrs, name) orelse return false;
    return std.mem.indexOfScalar(u8, payload, '<') != null;
}

fn boundedVectorSret(attrs: []const u8) bool {
    const payload = abiAttrPayload(attrs, "sret") orelse return false;
    const parsed = @import("../../ir/parser_helpers.zig").parseLeadingType(payload) catch return false;
    if (!std.mem.startsWith(u8, std.mem.trimStart(u8, parsed.after, " \t"), ")")) return false;
    return @import("generic_cfg/storage_layout.zig").query(null, parsed.ty) != null;
}

fn attrsContainLongDoubleAbiPayload(attrs: []const u8, name: []const u8) bool {
    const payload = abiAttrPayload(attrs, name) orelse return false;
    return std.mem.indexOf(u8, payload, "x86_fp80") != null or std.mem.indexOf(u8, payload, "fp128") != null;
}

fn abiAttrPayload(attrs: []const u8, name: []const u8) ?[]const u8 {
    var index: usize = 0;
    while (std.mem.indexOfPos(u8, attrs, index, name)) |found| {
        const after = found + name.len;
        if (after < attrs.len and attrs[after] == '(') {
            const payload = std.mem.trim(u8, attrs[after + 1 ..], " \t");
            return payload;
        }
        index = after;
    }
    return null;
}

pub fn rejectUnsupportedAbiType(ty: ir.Type) !void {
    if (isVector128AbiType(ty)) return;
    if (air_capabilities.boundaryForIrType(ty)) |boundary| {
        return switch (boundary) {
            .vector => error.UnsupportedVectorAbi,
            .x87 => error.UnsupportedLongDoubleAbi,
            .packed_aggregate => error.UnsupportedPackedAggregateAbi,
            .varargs => error.UnsupportedVarargsAbi,
        };
    }
}

pub fn aggregateReturnHasNoGpr(ret_ty: ir.Type) bool {
    const classification = classifyAggregate(ret_ty) catch return false;
    return classification.isSseOnly();
}

fn planAggregatePassThrough(
    function: ir.Function,
    arg: ir.CallArg,
    classification: AggregateClassification,
    int_arg_index: *usize,
    fp_arg_index: *usize,
) !RegisterAggregatePassThrough {
    const name = switch (arg.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const source = try paramCursorFor(function, name, arg.ty);
    if (classification.kind == .memory) {
        return .{
            .classification = classification,
            .source = source,
            .dest = .stack,
        };
    }
    const needs = aggregateRegisterNeeds(classification);
    const dest: AggregatePassDestination = if (int_arg_index.* + needs.gpr <= 6 and fp_arg_index.* + needs.sse <= 8) dest: {
        const dest_gpr = int_arg_index.*;
        const dest_sse = fp_arg_index.*;
        int_arg_index.* += needs.gpr;
        fp_arg_index.* += needs.sse;
        break :dest .{ .registers = .{ .gpr = dest_gpr, .sse = dest_sse } };
    } else .stack;
    return .{
        .classification = classification,
        .source = source,
        .dest = dest,
    };
}

pub fn aggregateStackEightbytes(classification: AggregateClassification) usize {
    return switch (classification.kind) {
        .register => classification.eightbyte_count,
        .memory => @intCast((classification.size_bytes + 7) / 8),
    };
}

pub const ParamCursor = struct {
    gpr: usize,
    sse: usize,
    stack_eightbytes: usize,
};

fn paramCursorFor(function: ir.Function, name: []const u8, ty: ir.Type) !ParamCursor {
    return try paramCursorForWithInitial(function, name, ty, .{ .gpr = 0, .sse = 0, .stack_eightbytes = 0 });
}

fn paramCursorForWithInitial(function: ir.Function, name: []const u8, ty: ir.Type, initial: ParamCursor) !ParamCursor {
    var cursor: ParamCursor = initial;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty)) return error.UnsupportedCodegenType;
            return cursor;
        }
        try advanceParamCursors(param.ty, &cursor.gpr, &cursor.sse, &cursor.stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

fn isAggregateType(ty: ir.Type) bool {
    return switch (ty) {
        .aggregate => true,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

fn isGprScalarType(ty: ir.Type) bool {
    return isScalarGprAbiType(ty);
}

fn isScalarGprAbiType(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits >= 1 and bits <= 64,
        .ptr => true,
        else => false,
    };
}

fn i32Value(value: i128) !i32 {
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

test "SysV call signature helper accepts default and fastcc" {
    const default_call: ir.CallInst = .{
        .ret_ty = .{ .int = 32 },
        .callee = "callee",
        .args = .empty,
    };
    try rejectUnsupportedCallSignature(default_call);

    const c_call: ir.CallInst = .{
        .ret_ty = .{ .int = 32 },
        .callee = "callee",
        .calling_conv = "ccc",
        .args = .empty,
    };
    try rejectUnsupportedCallSignature(c_call);

    const fast_call: ir.CallInst = .{
        .ret_ty = .{ .int = 32 },
        .callee = "callee",
        .calling_conv = "fastcc",
        .args = .empty,
    };
    try rejectUnsupportedCallSignature(fast_call);
}

test "SysV call signature helper rejects varargs and non-default callconv" {
    const varargs_call: ir.CallInst = .{
        .ret_ty = .{ .int = 32 },
        .callee = "printf",
        .callee_function_ty = "ptr, ...",
        .args = .empty,
    };
    try std.testing.expectError(error.UnsupportedVarargsAbi, rejectUnsupportedCallSignature(varargs_call));

    const callconv_call: ir.CallInst = .{
        .ret_ty = .{ .int = 32 },
        .callee = "callee",
        .calling_conv = "coldcc",
        .args = .empty,
    };
    try std.testing.expectError(error.UnsupportedCallConvAbi, rejectUnsupportedCallSignature(callconv_call));
}

test "call contracts variadic signatures retain exact fixed types and calling conventions" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare i32 @sink(ptr, ...)
        \\define i32 @caller(ptr %p) {
        \\entry:
        \\  %r = call i32 (ptr, ...) @sink(ptr %p)
        \\  ret i32 %r
        \\}
    );
    defer module.deinit();
    var call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try rejectUnsupportedCallSignature(call);
    try std.testing.expect(isSupportedPointerVariadicCall(call));
    try std.testing.expect(functionHasVariadicCall(module.functions.items[0]));
    call.calling_conv = "fastcc";
    try std.testing.expectError(error.UnsupportedVarargsAbi, rejectUnsupportedCallSignature(call));
    call.calling_conv = null;
    call.callee_function_ty = "(ptr, i32, ...)";
    try std.testing.expectError(error.UnsupportedVarargsAbi, rejectUnsupportedCallSignature(call));
    call.callee_function_ty = "(ptr, ...)";
    call.ret_ty = .double;
    try std.testing.expectError(error.UnsupportedVarargsAbi, rejectUnsupportedCallSignature(call));
}

test "call contracts C integer varargs validate fixed argument types and scalar unnamed values" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare i32 @sink(ptr, ptr, ...)
        \\define i32 @caller(ptr %p, ptr %q, i32 %value) {
        \\entry:
        \\  %r = call i32 (ptr, ptr, ...) @sink(ptr %p, ptr %q, i32 %value)
        \\  ret i32 %r
        \\}
    );
    defer module.deinit();
    var call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(isSupportedPointerVariadicCall(call));
    for ([_]ir.Type{ .float, .double, .{ .int = 8 }, .{ .int = 128 }, .{ .aggregate = "{ i64, i64 }" } }) |ty| {
        call.args.items[2].ty = ty;
        try std.testing.expect(!isSupportedPointerVariadicCall(call));
    }
    call.args.items[2].ty = .{ .int = 32 };
    call.callee_function_ty = "(ptr, i32, ...)";
    try std.testing.expect(!isSupportedPointerVariadicCall(call));
    call.callee_function_ty = "(ptr, ptr, ...)";
    call.callee_value = .{ .named = "%indirect" };
    try std.testing.expect(!isSupportedPointerVariadicCall(call));
    call.callee_value = null;
    call.calling_conv = "fastcc";
    try std.testing.expect(!isSupportedPointerVariadicCall(call));
}

test "call contracts advisory attributes preserve representation without admitting extension attributes" {
    var call: ir.CallInst = .{ .callee = "allocate", .ret_ty = .ptr, .ret_attrs = "noalias", .args = .empty };
    try rejectUnsupportedCallEnvelope(call);
    call.ret_ty = .{ .int = 32 };
    try std.testing.expectError(error.UnsupportedCallAttributeAbi, rejectUnsupportedCallEnvelope(call));
    call.ret_ty = .ptr;
    call.ret_attrs = "noalias signext";
    try std.testing.expectError(error.UnsupportedCallAttributeAbi, rejectUnsupportedCallEnvelope(call));
    try rejectUnsupportedCallArgAttrs(.{ .ty = .{ .int = 32 }, .attrs = "noundef", .value = .{ .int = 123 } });
    try rejectUnsupportedCallArgAttrs(.{ .ty = .ptr, .attrs = "noundef nonnull align 8", .value = .{ .named = "p" } });
    try rejectUnsupportedCallArgAttrs(.{ .ty = .ptr, .attrs = "noalias nonnull readonly align 8", .value = .{ .named = "p" } });
    try std.testing.expectError(error.UnsupportedCallAttributeAbi, rejectUnsupportedCallArgAttrs(.{ .ty = .ptr, .attrs = "noalias signext", .value = .{ .named = "p" } }));
    try std.testing.expectError(error.UnsupportedCallAttributeAbi, rejectUnsupportedCallArgAttrs(.{ .ty = .{ .int = 32 }, .attrs = "noundef zeroext", .value = .{ .int = 123 } }));
}

test "SysV call envelope accepts attribute group references without hiding bundles" {
    const grouped_call: ir.CallInst = .{
        .ret_ty = .float,
        .callee = "callee",
        .attrs = "#40",
        .args = .empty,
    };
    try rejectUnsupportedCallEnvelope(grouped_call);

    const bundled_call: ir.CallInst = .{
        .ret_ty = .float,
        .callee = "callee",
        .attrs = "#40",
        .operand_bundle = "[ \"deopt\"() ]",
        .args = .empty,
    };
    try std.testing.expectError(error.UnsupportedCallAttributeAbi, rejectUnsupportedCallEnvelope(bundled_call));
}

test "SysV call planner admits only advisory local-pointer argument attributes" {
    try rejectUnsupportedCallArgAttrs(.{
        .ty = .ptr,
        .attrs = "nonnull align 8",
        .value = .{ .named = "slot" },
    });
    try rejectUnsupportedCallArgAttrs(.{
        .ty = .ptr,
        .attrs = "nonnull dereferenceable(8)",
        .value = .{ .named = "slot" },
    });
    try std.testing.expectError(error.UnsupportedCallAttributeAbi, rejectUnsupportedCallArgAttrs(.{
        .ty = .{ .int = 64 },
        .attrs = "align 8",
        .value = .{ .named = "value" },
    }));
}
