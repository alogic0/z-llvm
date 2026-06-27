const std = @import("std");
const air_capabilities = @import("../../zig_air_capabilities.zig");
const ir = @import("../../ir.zig");
const target = @import("../../target.zig");
const types = @import("types.zig");

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

pub fn dataLayout() !target.DataLayout {
    return target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
}

pub fn classifyAggregateForTest(ty: ir.Type) !AggregateClassification {
    return try classifyAggregate(ty);
}

pub fn classifyAggregate(ty: ir.Type) !AggregateClassification {
    switch (ty) {
        .aggregate => |text| {
            const trimmed = std.mem.trim(u8, text, " \t");
            if (std.mem.startsWith(u8, trimmed, "<{")) return .{ .kind = .memory };
        },
        else => {},
    }
    const layout = try dataLayout();
    const size = try layout.typeStoreSizeBytes(ty);
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
            while (air_capabilities.aggregateFieldType(ty, field_index)) |field_ty| : (field_index += 1) {
                saw_field = true;
                const field_offset = air_capabilities.aggregateFieldByteOffset(layout, ty, field_index) orelse {
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
        .float, .double, .vector => {
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
        .float => 4,
        .double => 8,
        .vector => |vector| vector.len * (switch (vector.elem_ty) {
            .int => |bits| if (bits % 8 == 0) bits / 8 else return null,
            .float => 4,
            .double => 8,
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
    if (ty.eql(.{ .int = 1 }) or ty.eql(.{ .int = 8 }) or ty.eql(.{ .int = 16 }) or
        ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 }) or ty.eql(.ptr))
    {
        if (gpr_index.* < 6) gpr_index.* += 1 else stack_eightbytes.* += 1;
        return;
    }
    if (ty.eql(.float) or ty.eql(.double)) {
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
        if (arg.ty.eql(.float) or arg.ty.eql(.double)) {
            plan.has_non_i32_arg = true;
            if (fp_arg_index >= 8) {
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
            plan.has_non_i32_arg = true;
            const classification = try classifyAggregate(arg.ty);
            const pass = try planAggregatePassThrough(function, arg, classification, &int_arg_index, &fp_arg_index);
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
    try rejectUnsupportedAbiType(ret_ty);
    if (ret_ty == .void) return .{};
    if (ret_ty.eql(.{ .int = 1 }) or ret_ty.eql(.{ .int = 8 }) or ret_ty.eql(.{ .int = 16 }) or ret_ty.eql(.{ .int = 32 }) or ret_ty.eql(.{ .int = 64 }) or ret_ty == .ptr) {
        return .{ .gpr_returns = 1 };
    }
    if (ret_ty == .float or ret_ty == .double) {
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

pub fn rejectUnsupportedCallEnvelope(call: ir.CallInst) !void {
    if (call.tail_kind != null) return error.UnsupportedTailCallAbi;
    if (call.inline_asm != null) return error.UnsupportedCallAttributeAbi;
    if (call.ret_attrs) |attrs| {
        try rejectUnsupportedAbiAttrPayload(attrs);
        if (attrsContainAbiPayload(attrs, "sret") or attrsContainAbiPayload(attrs, "byval")) {
            return error.UnsupportedSretByvalAbi;
        }
        return error.UnsupportedCallAttributeAbi;
    }
    if (call.attrs) |attrs| {
        try rejectUnsupportedAbiAttrPayload(attrs);
        if (attrsContainAbiPayload(attrs, "sret") or attrsContainAbiPayload(attrs, "byval")) {
            return error.UnsupportedSretByvalAbi;
        }
        return error.UnsupportedCallAttributeAbi;
    }
    if (call.operand_bundle != null) return error.UnsupportedCallAttributeAbi;
}

pub fn rejectUnsupportedCallSignature(call: ir.CallInst) !void {
    if (call.calling_conv) |calling_conv| {
        if (!std.mem.eql(u8, calling_conv, "ccc") and !std.mem.eql(u8, calling_conv, "fastcc")) {
            return error.UnsupportedCallConvAbi;
        }
    }
    if (call.callee_function_ty) |function_ty| {
        if (std.mem.indexOf(u8, function_ty, "...") != null) return error.UnsupportedVarargsAbi;
    }
}

fn rejectUnsupportedAbiAttrPayload(attrs: []const u8) !void {
    inline for (.{ "sret", "byval" }) |name| {
        if (attrsContainPackedAbiPayload(attrs, name)) {
            return error.UnsupportedPackedAggregateAbi;
        }
        if (attrsContainVectorAbiPayload(attrs, name)) {
            return error.UnsupportedVectorAbi;
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
    return error.UnsupportedCallAttributeAbi;
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
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

fn isGprScalarType(ty: ir.Type) bool {
    return ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 }) or ty == .ptr;
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
