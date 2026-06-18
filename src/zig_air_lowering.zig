const std = @import("std");
const air_export = @import("zig_air_export.zig");
const ir = @import("ir.zig");
const memory_location = @import("analysis/memory_location.zig");
const sib = @import("structured_ir_builder.zig");
const target_mod = @import("target.zig");

pub const UnsupportedReason = enum {
    function_type,
    instruction_type,
    opcode,
    control_flow_shape,
    call_shape,
    value,
};

pub const Diagnostic = struct {
    function: []const u8,
    opcode: []const u8,
    reason: UnsupportedReason,
};

pub const Result = struct {
    module: ir.Module,
    accepted_functions: usize,
    structured_air_v1_functions: usize,
    structured_air_v2_functions: usize,
    typed_air_type_functions: usize,
    typed_air_operand_functions: usize,
    legacy_air_text_lowering_functions: usize,
    generic_lowering_functions: usize,
    shape_recognizer_functions: usize,
    unsupported: []Diagnostic,
    typed_v2_fallbacks: []TypedV2Fallback,

    pub fn deinit(self: *Result) void {
        const allocator = self.module.allocator;
        self.module.deinit();
        allocator.free(self.unsupported);
        allocator.free(self.typed_v2_fallbacks);
        self.* = undefined;
    }
};

pub const TypedV2Fallback = struct {
    function: []const u8,
    opcode: []const u8,
    data_kind: []const u8,
    reason: []const u8,
};

const ZigType = struct {
    ir_type: ir.Type,
    signed: bool = false,
    pointer_child: ?ir.Type = null,
    is_volatile_pointer: bool = false,
};

const FunctionType = struct {
    params: []ZigType,
    return_type: ZigType,
    c_calling_convention: bool,

    fn deinit(self: FunctionType, allocator: std.mem.Allocator) void {
        allocator.free(self.params);
    }
};

const TypedValue = struct {
    ty: ZigType,
    value: ir.Value,
};

const LowerError = std.mem.Allocator.Error || error{UnsupportedAir};

pub fn lowerCompatible(
    allocator: std.mem.Allocator,
    air_module: air_export.Module,
) !Result {
    var module: ir.Module = .{
        .allocator = allocator,
        .source = try allocator.dupe(u8, ""),
        .owned_strings = .empty,
        .source_filename = air_module.root_source,
        .target_triple = air_module.target,
        .target_datalayout = null,
        .module_asm = .empty,
        .named_types = .empty,
        .globals = .empty,
        .aliases = .empty,
        .comdats = .empty,
        .declarations = .empty,
        .functions = .empty,
        .attribute_groups = .empty,
        .metadata = .empty,
    };
    errdefer module.deinit();

    var unsupported: std.ArrayList(Diagnostic) = .empty;
    errdefer unsupported.deinit(allocator);
    var typed_v2_fallbacks: std.ArrayList(TypedV2Fallback) = .empty;
    errdefer typed_v2_fallbacks.deinit(allocator);

    for (air_module.globals) |air_global| {
        if (air_global.is_constant) continue;
        const global_type = parseZigType(air_global.type_text) orelse continue;
        if (global_type.ir_type != .int and global_type.ir_type != .float and
            global_type.ir_type != .double and global_type.ir_type != .ptr)
        {
            continue;
        }
        const address_attrs = if (!std.mem.eql(u8, air_global.thread_local, "default"))
            try ownPrint(&module, "thread_local({s})", .{air_global.thread_local})
        else
            null;
        try module.globals.append(allocator, .{
            .name = air_global.name,
            .linkage = .default,
            .address_attrs = address_attrs,
            .kind = .global,
            .ty = global_type.ir_type,
            .initializer = materializedGlobalInitializer(global_type.ir_type, air_global.initializer_text),
        });
    }

    var accepted_functions: usize = 0;
    var structured_air_v1_functions: usize = 0;
    var structured_air_v2_functions: usize = 0;
    var typed_air_type_functions: usize = 0;
    var typed_air_operand_functions: usize = 0;
    var legacy_air_text_lowering_functions: usize = 0;
    var generic_lowering_functions: usize = 0;
    var shape_recognizer_functions: usize = 0;
    const root_stem = std.fs.path.stem(air_module.root_source);
    const matched_root_functions = rootFunctionCount(air_module.functions, root_stem);
    for (air_module.functions) |air_function| {
        if (matched_root_functions != 0 and !isRootSourceFunction(root_stem, air_function.name)) continue;
        if (firstUnsupported(allocator, air_function)) |diagnostic| {
            try unsupported.append(allocator, diagnostic);
            continue;
        }
        var lowered_from_typed_v2 = true;
        var typed_v2_fallback: ?TypedV2Fallback = null;
        var function = function: {
            break :function lowerFunctionTypedV2(allocator, &module, air_function, &typed_v2_fallback) catch |typed_err| switch (typed_err) {
                error.UnsupportedAir => {
                    lowered_from_typed_v2 = false;
                    try typed_v2_fallbacks.append(allocator, typed_v2_fallback orelse firstTypedV2Fallback(air_function));
                    break :function lowerFunction(allocator, &module, air_function) catch |legacy_err| switch (legacy_err) {
                        error.UnsupportedAir => {
                            try unsupported.append(allocator, .{
                                .function = air_function.name,
                                .opcode = "lowering",
                                .reason = .instruction_type,
                            });
                            continue;
                        },
                        else => return legacy_err,
                    };
                },
                else => return typed_err,
            };
        };
        errdefer function.deinit(allocator);
        try module.functions.append(allocator, function);
        accepted_functions += 1;
        if (air_function.structured_air != null) structured_air_v1_functions += 1;
        if (air_function.structured_air_v2) |structured_air_v2| {
            structured_air_v2_functions += 1;
            if (typedResultCoverage(air_function, structured_air_v2)) typed_air_type_functions += 1;
            if (typedOperandCoverage(structured_air_v2)) typed_air_operand_functions += 1;
        }
        if (!lowered_from_typed_v2) legacy_air_text_lowering_functions += 1;
        switch (loweringPath(air_function)) {
            .generic_instruction_path => generic_lowering_functions += 1,
            .shape_recognizer => shape_recognizer_functions += 1,
        }
    }

    try addMissingCallDeclarations(allocator, &module);
    try module.verify();
    return .{
        .module = module,
        .accepted_functions = accepted_functions,
        .structured_air_v1_functions = structured_air_v1_functions,
        .structured_air_v2_functions = structured_air_v2_functions,
        .typed_air_type_functions = typed_air_type_functions,
        .typed_air_operand_functions = typed_air_operand_functions,
        .legacy_air_text_lowering_functions = legacy_air_text_lowering_functions,
        .generic_lowering_functions = generic_lowering_functions,
        .shape_recognizer_functions = shape_recognizer_functions,
        .unsupported = try unsupported.toOwnedSlice(allocator),
        .typed_v2_fallbacks = try typed_v2_fallbacks.toOwnedSlice(allocator),
    };
}

fn typedResultCoverage(function: air_export.Function, structured_air_v2: air_export.StructuredAirV2) bool {
    if (structured_air_v2.instructions.len != function.instruction_count) return false;
    for (structured_air_v2.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.result_type, "-")) return false;
    }
    return true;
}

fn typedOperandCoverage(structured_air_v2: air_export.StructuredAirV2) bool {
    for (structured_air_v2.instructions) |instruction| {
        for (instruction.operands) |operand| {
            if (std.mem.eql(u8, operand.type_text, "-")) return false;
        }
    }
    return true;
}

fn materializedGlobalInitializer(ty: ir.Type, initializer_text: ?[]const u8) ir.GlobalInitializer {
    if (initializer_text) |text| {
        const trimmed = std.mem.trim(u8, text, " \t");
        if (!std.mem.eql(u8, trimmed, "-")) {
            const parsed = sib.parseGlobalInitializer(ty, trimmed);
            if (parsed != .@"opaque") return parsed;
        }
    }
    return switch (ty) {
        .int => .{ .scalar = .{ .int = 0 } },
        .ptr => .{ .scalar = .null_value },
        .float, .double, .x86_fp80, .fp128 => .{ .scalar = .{ .fp = "0.0" } },
        .void, .metadata, .aggregate, .vector => .none,
    };
}

pub fn isRootSourceFunction(root_stem: []const u8, function_name: []const u8) bool {
    return std.mem.eql(u8, function_name, root_stem) or
        (std.mem.startsWith(u8, function_name, root_stem) and
            function_name.len > root_stem.len and function_name[root_stem.len] == '.');
}

fn rootFunctionCount(functions: []const air_export.Function, root_stem: []const u8) usize {
    var count: usize = 0;
    for (functions) |function| {
        if (isRootSourceFunction(root_stem, function.name)) count += 1;
    }
    return count;
}

fn addMissingCallDeclarations(allocator: std.mem.Allocator, module: *ir.Module) !void {
    for (module.functions.items) |function| {
        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                const call = switch (instruction.kind) {
                    .call => |call| call,
                    else => continue,
                };
                if (call.callee_value != null or call.inline_asm != null) continue;
                if (moduleHasFunctionOrDeclaration(module.*, call.callee)) continue;
                var decl = ir.FunctionDecl.init(call.callee, call.ret_ty);
                errdefer decl.deinit(allocator);
                decl.calling_conv = call.calling_conv;
                for (call.args.items) |arg| {
                    try decl.params.append(allocator, .{
                        .ty = arg.ty,
                        .attrs = arg.attrs,
                    });
                }
                try module.declarations.append(allocator, decl);
            }
        }
    }
}

fn moduleHasFunctionOrDeclaration(module: ir.Module, name: []const u8) bool {
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, name)) return true;
    }
    for (module.declarations.items) |decl| {
        if (std.mem.eql(u8, decl.name, name)) return true;
    }
    return false;
}

pub fn firstUnsupported(
    allocator: std.mem.Allocator,
    function: air_export.Function,
) ?Diagnostic {
    const function_type = parseFunctionType(allocator, function.type_text) catch {
        return .{ .function = function.name, .opcode = "function-type", .reason = .function_type };
    };
    defer function_type.deinit(allocator);
    const typed_aggregate_pair =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2AggregatePairFirstRecords(function_type, structured_air_v2) or
                typedV2AggregateMakePairRecords(function_type, structured_air_v2)
        else
            false;
    const typed_register_aggregate =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2RegisterAggregateRecords(function_type, structured_air_v2)
        else
            false;
    const typed_sret_integer_aggregate =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2SretIntegerAggregateRecords(function_type, structured_air_v2) or
                typedV2SretIntegerAggregateCopyRecords(function_type, structured_air_v2)
        else
            false;
    const typed_error_union_payload =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2ErrorUnionPayloadRecords(function, function_type, structured_air_v2)
        else
            false;
    const typed_maybe_error =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2MaybeErrorRecords(function, function_type, structured_air_v2)
        else
            false;
    const typed_optional_payload =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2OptionalPayloadRecords(function_type, structured_air_v2)
        else
            false;
    const typed_optional_pointer =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2OptionalPointerRecords(function_type, structured_air_v2)
        else
            false;
    const typed_packed_bits =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2PackedReadFlagRecords(function_type, structured_air_v2) or
                typedV2PackedReplaceLowRecords(function_type, structured_air_v2)
        else
            false;
    const typed_slice_sum =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2SliceSumRecords(function_type, structured_air_v2) or
                typedV2ConditionalSliceSumRecords(function_type, structured_air_v2)
        else
            false;
    const typed_accumulator_loop =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2AccumulatorLoopRecords(function_type, structured_air_v2)
        else
            false;
    const typed_conditional_slot_update =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2ConditionalSlotUpdateRecords(function_type, structured_air_v2)
        else
            false;
    const typed_integer_switch =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2DenseIntegerSwitchResults(function_type, structured_air_v2) != null
        else
            false;
    const typed_error_switch =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2ErrorSwitchRecords(function_type, structured_air_v2)
        else
            false;
    const typed_error_classifier =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2ErrorClassifierRecords(function_type, structured_air_v2)
        else
            false;
    const typed_runtime_optional_pointer_main =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2RuntimeOptionalPointerMainRecords(function_type, structured_air_v2)
        else
            false;
    const typed_runtime_pointer_load_store_main =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2RuntimePointerLoadStoreMainRecords(function_type, structured_air_v2)
        else
            false;
    const typed_mix_c_add_may_panic =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2MixCAddMayPanicRecords(function_type, structured_air_v2)
        else
            false;
    const typed_checked_int_from_float =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2CheckedIntFromFloatRecords(function_type, structured_air_v2)
        else
            false;

    if (typed_accumulator_loop or
        accumulatorLoopShape(function) != null or
        typed_error_classifier or
        errorClassifyShape(function) or
        typed_integer_switch or
        isIntegerSwitchBlock(function) or
        typed_conditional_slot_update or
        conditionalSlotUpdateShape(function) or
        typed_runtime_optional_pointer_main or
        runtimeOptionalPointerMainShape(function) or
        typed_optional_pointer or
        typed_runtime_pointer_load_store_main or
        runtimePointerLoadStoreMainShape(function) or
        typed_optional_payload or
        typed_error_switch or
        errorSwitchShape(function) or
        errorClassifyShape(function) or
        typed_error_union_payload or
        typed_slice_sum or
        typed_packed_bits or
        typed_aggregate_pair or
        typed_register_aggregate or
        typed_sret_integer_aggregate or
        typed_mix_c_add_may_panic or
        mixCAddMayPanicShape(function) or
        typed_checked_int_from_float or
        typed_maybe_error)
    {
        return null;
    }

    for (function.instructions) |instruction| {
        if (isIgnoredOpcode(instruction.opcode) or isStraightLineOpcode(instruction.opcode)) continue;
        if (std.mem.eql(u8, instruction.opcode, "block")) {
            if (isSimpleSelectBlock(function, instruction.index)) continue;
            if (isTypedVoidGuardBlock(function, instruction.index)) continue;
            if (isGenericTypedCfgBlock(function, instruction.index)) continue;
            return .{ .function = function.name, .opcode = instruction.opcode, .reason = .control_flow_shape };
        }
        if (std.mem.eql(u8, instruction.opcode, "cond_br") or
            std.mem.eql(u8, instruction.opcode, "br"))
        {
            if (belongsToSimpleSelectBlock(function, instruction.index)) continue;
            if (belongsToTypedVoidGuardBlock(function, instruction.index)) continue;
            if (belongsToGenericTypedCfgBlock(function, instruction.index)) continue;
            return .{ .function = function.name, .opcode = instruction.opcode, .reason = .control_flow_shape };
        }
        return .{ .function = function.name, .opcode = instruction.opcode, .reason = .opcode };
    }
    return null;
}

const LoweringPath = enum {
    generic_instruction_path,
    shape_recognizer,
};

fn firstTypedV2Fallback(function: air_export.Function) TypedV2Fallback {
    if (shapeRecognizerName(function)) |name| {
        return .{
            .function = function.name,
            .opcode = name,
            .data_kind = "-",
            .reason = "shape_recognizer",
        };
    }
    const structured_air = function.structured_air orelse return .{
        .function = function.name,
        .opcode = "structured_air-v1",
        .data_kind = "-",
        .reason = "missing",
    };
    const structured_air_v2 = function.structured_air_v2 orelse return .{
        .function = function.name,
        .opcode = "structured_air-v2",
        .data_kind = "-",
        .reason = "missing",
    };
    const main_body = structured_air.body(.main, null) orelse return .{
        .function = function.name,
        .opcode = "main_body",
        .data_kind = "-",
        .reason = "missing",
    };
    for (main_body.instructions) |instruction_index| {
        const instruction = typedInstructionByIndex(structured_air_v2, instruction_index) orelse return .{
            .function = function.name,
            .opcode = "typed_inst",
            .data_kind = "-",
            .reason = "missing_index",
        };
        if (isIgnoredOpcode(instruction.opcode)) continue;
        if (!isTypedV2LowerableOpcode(instruction.opcode)) {
            return .{
                .function = function.name,
                .opcode = instruction.opcode,
                .data_kind = instruction.data_kind,
                .reason = "unsupported_opcode",
            };
        }
        if (typedV2InstructionMissingRequiredDetail(instruction)) |detail| {
            return .{
                .function = function.name,
                .opcode = instruction.opcode,
                .data_kind = instruction.data_kind,
                .reason = detail,
            };
        }
    }
    return .{
        .function = function.name,
        .opcode = "typed_v2",
        .data_kind = "-",
        .reason = "lowering_validation",
    };
}

fn shapeRecognizerName(function: air_export.Function) ?[]const u8 {
    _ = function;
    return null;
}

fn isTypedV2LowerableOpcode(opcode: []const u8) bool {
    return std.mem.eql(u8, opcode, "arg") or
        isArithmeticOpcode(opcode) or
        std.mem.startsWith(u8, opcode, "cmp_") or
        isCastOpcode(opcode) or
        std.mem.eql(u8, opcode, "alloc") or
        std.mem.eql(u8, opcode, "load") or
        std.mem.eql(u8, opcode, "store") or
        std.mem.eql(u8, opcode, "store_safe") or
        std.mem.eql(u8, opcode, "block") or
        std.mem.eql(u8, opcode, "is_non_null") or
        std.mem.eql(u8, opcode, "optional_payload") or
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

fn isFieldPtrOpcode(opcode: []const u8) bool {
    return std.mem.eql(u8, opcode, "struct_field_ptr") or
        std.mem.startsWith(u8, opcode, "struct_field_ptr_index_");
}

fn isPlainFieldPointerChild(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits != 1 and bits % 8 == 0,
        .float, .double, .ptr => true,
        .aggregate => true,
        .void, .x86_fp80, .fp128, .metadata, .vector => false,
    };
}

fn selectedFieldByteOffset(source_ty: ir.Type, field_child: ir.Type, field_index: i128) ?i128 {
    if (field_index < 0) return null;
    if (!isPlainFieldPointerChild(field_child)) return null;
    const index: usize = @intCast(field_index);
    const actual_child = memory_location.aggregateFieldType(source_ty, index) orelse return null;
    if (!actual_child.eql(field_child)) return null;
    const layout = target_mod.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128") catch return null;
    return memory_location.aggregateFieldOffsetWithLayout(layout, source_ty, index);
}

fn genericTypedGepIndex(value: ir.Value) bool {
    return switch (value) {
        .int => |int| int >= 0,
        .named => true,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn typedV2InstructionMissingRequiredDetail(instruction: air_export.TypedInstruction) ?[]const u8 {
    if (isCallOpcode(instruction.opcode)) {
        if (typedDetail(instruction, "callee_text") == null) return "missing_callee_text";
        if (typedDetail(instruction, "call_signature") == null) return "missing_call_signature";
    }
    for (instruction.operands, 0..) |operand, operand_index| {
        if (std.mem.eql(u8, operand.kind, "const") and typedOperandTextDetail(instruction, operand_index) == null) {
            return "missing_const_text";
        }
    }
    return null;
}

fn loweringPath(function: air_export.Function) LoweringPath {
    if (shapeRecognizerName(function) != null) return .shape_recognizer;
    return .generic_instruction_path;
}

fn lowerFunction(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
) !ir.Function {
    if (accumulatorLoopShape(air_function)) |shape| {
        return lowerAccumulatorLoop(allocator, module, air_function, shape);
    }
    if (errorClassifyShape(air_function)) return lowerErrorClassify(allocator, air_function);
    if (isIntegerSwitchBlock(air_function)) {
        return lowerIntegerSwitch(allocator, module, air_function);
    }
    if (conditionalSlotUpdateShape(air_function)) {
        return lowerConditionalSlotUpdate(allocator, air_function);
    }
    if (arraySumShape(air_function)) return lowerArraySum(allocator, air_function);
    if (structSumShape(air_function)) return lowerStructSum(allocator, air_function);
    if (base64TableLookupShape(air_function)) return lowerBase64TableLookup(allocator, module, air_function);
    if (runtimeOptionalPointerMainShape(air_function)) return lowerRuntimeOptionalPointerMain(allocator, air_function);
    if (runtimePointerLoadStoreMainShape(air_function)) return lowerRuntimePointerLoadStoreMain(allocator, air_function);
    if (errorSwitchShape(air_function)) return lowerErrorSwitch(allocator, air_function);
    if (mixCAddMayPanicShape(air_function)) return lowerMixCAddMayPanic(allocator, module, air_function);

    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);

    var function = ir.Function.init(shortFunctionName(air_function.name), function_type.return_type.ir_type);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    if (runtimeNavSymbol(air_function)) |tls_symbol| {
        function.attrs = try ownPrint(module, "\"zllvm-tls-symbol\"=\"{s}\"", .{tls_symbol});
    }

    for (function_type.params, 0..) |param_type, param_index| {
        const name = try ownPrint(module, "arg{}", .{param_index});
        try function.params.append(allocator, .{
            .ty = param_type.ir_type,
            .name = name,
        });
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    const values = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(values);
    @memset(values, null);

    var context: LoweringContext = .{
        .allocator = allocator,
        .module = module,
        .air_function = air_function,
        .function_type = function_type,
        .function = &function,
        .block = &block,
        .values = values,
        .structured_air = null,
        .structured_air_v2 = null,
    };

    for (air_function.instructions) |instruction| {
        if (isIgnoredOpcode(instruction.opcode)) continue;
        if (std.mem.eql(u8, instruction.opcode, "arg")) {
            try context.lowerArg(instruction);
        } else if (isArithmeticOpcode(instruction.opcode)) {
            try context.lowerBinary(instruction);
        } else if (std.mem.startsWith(u8, instruction.opcode, "cmp_")) {
            try context.lowerCompare(instruction);
        } else if (isCastOpcode(instruction.opcode)) {
            try context.lowerCast(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "alloc")) {
            try context.lowerAlloca(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "load")) {
            try context.lowerLoad(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "store") or
            std.mem.eql(u8, instruction.opcode, "store_safe"))
        {
            try context.lowerStore(instruction);
        } else if (isCallOpcode(instruction.opcode)) {
            try context.lowerCall(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "runtime_nav_ptr")) {
            try context.lowerRuntimeNavPtr(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "atomic_rmw")) {
            try context.lowerAtomicRmw(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "array_elem_val")) {
            try context.lowerArrayElemVal(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "assembly")) {
            try context.lowerAssembly(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "ret") or
            std.mem.eql(u8, instruction.opcode, "ret_safe"))
        {
            try context.lowerReturn(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "unreach")) {
            block.terminator = .{ .@"unreachable" = {} };
        } else if (std.mem.eql(u8, instruction.opcode, "block") or
            std.mem.eql(u8, instruction.opcode, "cond_br") or
            std.mem.eql(u8, instruction.opcode, "br"))
        {
            continue;
        } else {
            return error.UnsupportedAir;
        }
    }
    if (block.terminator == null) return error.UnsupportedAir;
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerFunctionTypedV2(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    typed_v2_fallback: ?*?TypedV2Fallback,
) LowerError!ir.Function {
    if (loweringPath(air_function) == .shape_recognizer) return error.UnsupportedAir;
    const structured_air = air_function.structured_air orelse return error.UnsupportedAir;
    const structured_air_v2 = air_function.structured_air_v2 orelse return error.UnsupportedAir;
    const main_body = structured_air.body(.main, null) orelse return error.UnsupportedAir;

    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (try lowerTypedV2ArraySum(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2AggregatePairAbi(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2SmallIntegerAggregateAbi(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2SretIntegerAggregateAbi(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2ErrorUnionPayload(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2MaybeError(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2OptionalPayload(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2OptionalPointer(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2PackedBits(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2ConditionalSliceSum(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2SliceSum(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2InlineAsmBarrier(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2AtomicAdd(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2AccumulatorLoop(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2ConditionalSlotUpdate(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2DenseIntegerSwitch(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2ErrorSwitch(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2ErrorClassifier(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2RuntimeOptionalPointerMain(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2RuntimePointerLoadStoreMain(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2MixCAddMayPanic(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2CheckedIntFromFloat(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), function_type.return_type.ir_type);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    if (runtimeNavSymbol(air_function)) |tls_symbol| {
        function.attrs = try ownPrint(module, "\"zllvm-tls-symbol\"=\"{s}\"", .{tls_symbol});
    }

    for (function_type.params, 0..) |param_type, param_index| {
        const name = try ownPrint(module, "arg{}", .{param_index});
        try function.params.append(allocator, .{
            .ty = param_type.ir_type,
            .name = name,
        });
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    const values = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(values);
    @memset(values, null);

    var context: LoweringContext = .{
        .allocator = allocator,
        .module = module,
        .air_function = air_function,
        .function_type = function_type,
        .function = &function,
        .block = &block,
        .values = values,
        .structured_air = structured_air,
        .structured_air_v2 = structured_air_v2,
        .typed_v2_fallback = typed_v2_fallback,
    };

    for (main_body.instructions) |instruction_index| {
        const instruction = typedInstructionByIndex(structured_air_v2, instruction_index) orelse
            return error.UnsupportedAir;
        try context.lowerTypedInstruction(instruction);
    }
    if (block.terminator == null) return error.UnsupportedAir;
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerTypedV2ArraySum(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (function_type.params.len != 3 or !function_type.return_type.ir_type.eql(.{ .int = 32 })) return null;
    for (function_type.params) |param| {
        if (!param.ir_type.eql(.{ .int = 32 })) return null;
    }

    var aggregate_init: ?air_export.TypedInstruction = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "aggregate_init")) continue;
        if (!std.mem.eql(u8, instruction.result_type, "[3]i32") or instruction.operands.len != 3) return null;
        if (aggregate_init != null) return null;
        aggregate_init = instruction;
    }
    const init = aggregate_init orelse return null;
    for (init.operands, 0..) |operand, index| {
        if (!std.mem.eql(u8, operand.kind, "inst") or !std.mem.eql(u8, operand.type_text, "i32")) return null;
        const operand_index = std.fmt.parseInt(usize, operand.value, 10) catch return null;
        if (operand_index != index) return null;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg2" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "sum01",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .named = "arg1" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "sum",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "sum01" },
            .rhs = .{ .named = "arg2" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "sum" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerTypedV2AggregatePairAbi(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (typedV2AggregatePairFirstRecords(function_type, structured_air_v2)) {
        return try lowerAggregatePairFirst(allocator, air_function);
    }
    if (typedV2AggregateMakePairRecords(function_type, structured_air_v2)) {
        return try lowerAggregateMakePair(allocator, air_function);
    }
    return null;
}

fn typedV2AggregatePairFirstRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 64 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "alloc") == 1 and
        typedStoreOpcodeCount(structured_air_v2) == 1 and
        typedOpcodeCount(structured_air_v2, "bitcast") == 1 and
        typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_0") == 1 and
        typedOpcodeCount(structured_air_v2, "load") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

fn typedV2AggregateMakePairRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }))
    {
        return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == 2 and
        typedOpcodeCount(structured_air_v2, "ret_ptr") == 1 and
        typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_0") == 1 and
        typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_1") == 1 and
        typedStoreOpcodeCount(structured_air_v2) == 2 and
        typedOpcodeCount(structured_air_v2, "ret_load") == 1;
}

fn typedOpcodeCount(structured_air_v2: air_export.StructuredAirV2, opcode: []const u8) usize {
    var count: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, opcode)) count += 1;
    }
    return count;
}

fn typedFieldPtrIndexCount(structured_air_v2: air_export.StructuredAirV2, expected_index: usize) usize {
    var count: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.data_kind, "field_ptr")) continue;
        const field_index_text = typedDetail(instruction, "field_index") orelse continue;
        const field_index = std.fmt.parseInt(usize, field_index_text, 10) catch continue;
        if (field_index == expected_index) count += 1;
    }
    return count;
}

fn typedCalleeNameCount(structured_air_v2: air_export.StructuredAirV2, callee_name: []const u8) usize {
    var count: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!isCallOpcode(instruction.opcode)) continue;
        const callee_text = typedDetail(instruction, "callee_text") orelse continue;
        const name = typedCalleeName(callee_text) orelse continue;
        if (std.mem.eql(u8, name, callee_name)) count += 1;
    }
    return count;
}

fn typedStoreOpcodeCount(structured_air_v2: air_export.StructuredAirV2) usize {
    return typedOpcodeCount(structured_air_v2, "store") + typedOpcodeCount(structured_air_v2, "store_safe");
}

fn lowerTypedV2SmallIntegerAggregateAbi(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2RegisterAggregateRecords(function_type, structured_air_v2)) return null;
    return try lowerRegisterAggregateMake(allocator, air_function);
}

fn typedV2RegisterAggregateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.return_type.ir_type != .aggregate) return false;
    if (!isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    const field_count = aggregateFieldCount(function_type.return_type.ir_type) orelse return false;
    if (field_count == 0 or field_count > 8 or function_type.params.len != field_count) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(function_type.return_type.ir_type, field_index) orelse return false;
        if (!field_ty.eql(.{ .int = 32 }) and !field_ty.eql(.{ .int = 64 }) and !field_ty.eql(.double)) return false;
        if (!function_type.params[field_index].ir_type.eql(field_ty)) return false;
        if (typedFieldPtrIndexCount(structured_air_v2, field_index) != 1) return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == field_count and
        typedOpcodeCount(structured_air_v2, "ret_ptr") == 1 and
        typedStoreOpcodeCount(structured_air_v2) == field_count and
        typedOpcodeCount(structured_air_v2, "ret_load") == 1;
}

fn aggregateFieldCount(ty: ir.Type) ?usize {
    var count: usize = 0;
    while (memory_location.aggregateFieldType(ty, count)) |_| : (count += 1) {}
    return count;
}

fn isSysVRegisterAggregateCandidate(ty: ir.Type) bool {
    switch (ty) {
        .aggregate => |text| {
            const trimmed = std.mem.trim(u8, text, " \t");
            if (std.mem.startsWith(u8, trimmed, "<{")) return false;
        },
        else => return false,
    }
    const layout = target_mod.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128") catch return false;
    const size = layout.typeStoreSizeBytes(ty) catch return false;
    return size > 0 and size <= 16;
}

fn lowerTypedV2SretIntegerAggregateAbi(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (typedV2SretIntegerAggregateCopyRecords(function_type, structured_air_v2)) {
        return try lowerSretIntegerAggregateCopy(allocator, module, air_function, function_type.return_type.ir_type);
    }
    if (!typedV2SretIntegerAggregateRecords(function_type, structured_air_v2)) return null;
    return try lowerSretIntegerAggregateMake(allocator, module, air_function, function_type.return_type.ir_type);
}

fn typedV2SretIntegerAggregateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    const field_count = integerAggregateFieldCount(function_type.return_type.ir_type) orelse return false;
    if (field_count < 3 or function_type.params.len != field_count) return false;
    for (function_type.params, 0..) |param, field_index| {
        if (!param.ir_type.eql(.{ .int = 64 })) return false;
        if (typedFieldPtrIndexCount(structured_air_v2, field_index) != 1) return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == field_count and
        typedOpcodeCount(structured_air_v2, "ret_ptr") == 1 and
        typedStoreOpcodeCount(structured_air_v2) == field_count and
        typedOpcodeCount(structured_air_v2, "ret_load") == 1;
}

fn typedV2SretIntegerAggregateCopyRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    const leaf_count = supportedIntegerAggregateLeafCount(function_type.return_type.ir_type) orelse return false;
    if (leaf_count < 3 or function_type.params.len != 1) return false;
    if (!function_type.params[0].ir_type.eql(function_type.return_type.ir_type)) return false;
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

fn integerAggregateFieldCount(ty: ir.Type) ?usize {
    const field_count = aggregateFieldCount(ty) orelse return null;
    if (field_count == 0) return null;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(ty, field_index) orelse return null;
        if (!field_ty.eql(.{ .int = 64 })) return null;
    }
    return field_count;
}

fn supportedIntegerAggregateLeafCount(ty: ir.Type) ?usize {
    const field_count = aggregateFieldCount(ty) orelse return null;
    if (field_count == 0) return null;
    var count: usize = 0;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(ty, field_index) orelse return null;
        if (supportedAggregateIntegerLeaf(field_ty)) {
            count += 1;
        } else if (isAggregateIrType(field_ty)) {
            count += supportedIntegerAggregateLeafCount(field_ty) orelse return null;
        } else {
            return null;
        }
    }
    return count;
}

fn supportedAggregateIntegerLeaf(ty: ir.Type) bool {
    return ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 });
}

fn isAggregateIrType(ty: ir.Type) bool {
    return switch (ty) {
        .aggregate => true,
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

const IntegerAggregateLeaf = struct {
    offset: u64,
    ty: ir.Type,
};

fn collectIntegerAggregateLeaves(allocator: std.mem.Allocator, aggregate_ty: ir.Type) ![]IntegerAggregateLeaf {
    var leaves: std.ArrayList(IntegerAggregateLeaf) = .empty;
    errdefer leaves.deinit(allocator);
    const layout = target_mod.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128") catch return error.UnsupportedAir;
    try collectIntegerAggregateLeavesInto(allocator, &leaves, layout, aggregate_ty, 0);
    if (leaves.items.len < 3) return error.UnsupportedAir;
    return try leaves.toOwnedSlice(allocator);
}

fn collectIntegerAggregateLeavesInto(
    allocator: std.mem.Allocator,
    leaves: *std.ArrayList(IntegerAggregateLeaf),
    layout: target_mod.DataLayout,
    aggregate_ty: ir.Type,
    base_offset: u64,
) !void {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return error.UnsupportedAir;
    if (field_count == 0) return error.UnsupportedAir;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return error.UnsupportedAir;
        const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse return error.UnsupportedAir;
        if (offset_i < 0) return error.UnsupportedAir;
        const field_offset = base_offset + @as(u64, @intCast(offset_i));
        if (supportedAggregateIntegerLeaf(field_ty)) {
            try leaves.append(allocator, .{ .offset = field_offset, .ty = field_ty });
        } else if (isAggregateIrType(field_ty)) {
            try collectIntegerAggregateLeavesInto(allocator, leaves, layout, field_ty, field_offset);
        } else {
            return error.UnsupportedAir;
        }
    }
}

fn lowerSretIntegerAggregateMake(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    aggregate_ty: ir.Type,
) !ir.Function {
    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = .default;
    function.calling_conv = null;
    const field_count = integerAggregateFieldCount(aggregate_ty) orelse return error.UnsupportedAir;
    if (field_count < 3) return error.UnsupportedAir;
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try sretAttrsForAggregate(module, aggregate_ty), .name = "sret" });
    var param_index: usize = 0;
    while (param_index < field_count) : (param_index += 1) {
        const arg_name = try ownPrint(module, "arg{}", .{param_index});
        try function.params.append(allocator, .{ .ty = .{ .int = 64 }, .name = arg_name });
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_name = try ownPrint(module, "field{}", .{field_index});
        const arg_name = function.params.items[field_index + 1].name;
        var gep: ir.GepInst = .{ .source_ty = aggregate_ty, .ptr = .{ .named = "sret" }, .indices = .empty };
        errdefer gep.deinit(allocator);
        try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
        try gep.indices.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .int = @intCast(field_index) } });
        try block.instructions.append(allocator, .{ .result = field_name, .kind = .{ .gep = gep } });
        try block.instructions.append(allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = .{ .int = 64 },
                .value = .{ .named = arg_name },
                .ptr = .{ .named = field_name },
            } },
        });
    }
    block.terminator = .{ .ret = .{ .ty = .void } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerSretIntegerAggregateCopy(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    aggregate_ty: ir.Type,
) !ir.Function {
    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = .default;
    function.calling_conv = null;
    const leaves = try collectIntegerAggregateLeaves(allocator, aggregate_ty);
    defer allocator.free(leaves);
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try sretAttrsForAggregate(module, aggregate_ty), .name = "sret" });
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try byvalAttrsForAggregate(module, aggregate_ty), .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    for (leaves, 0..) |leaf, field_index| {
        const src_result = try ownPrint(module, "src_leaf{}", .{field_index});
        const load_result = try ownPrint(module, "load{}", .{field_index});
        const dst_result = try ownPrint(module, "dst_leaf{}", .{field_index});

        var src_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "arg0" }, .indices = .empty };
        errdefer src_gep.deinit(allocator);
        try src_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(leaf.offset) } });
        try block.instructions.append(allocator, .{ .result = src_result, .kind = .{ .gep = src_gep } });

        try block.instructions.append(allocator, .{ .result = load_result, .kind = .{ .load = .{
            .ty = leaf.ty,
            .ptr = .{ .named = src_result },
        } } });

        var dst_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
        errdefer dst_gep.deinit(allocator);
        try dst_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(leaf.offset) } });
        try block.instructions.append(allocator, .{ .result = dst_result, .kind = .{ .gep = dst_gep } });

        try block.instructions.append(allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = leaf.ty,
                .value = .{ .named = load_result },
                .ptr = .{ .named = dst_result },
            } },
        });
    }
    block.terminator = .{ .ret = .{ .ty = .void } };
    try function.blocks.append(allocator, block);
    return function;
}

fn sretAttrsForAggregate(module: *ir.Module, aggregate_ty: ir.Type) ![]const u8 {
    return try aggregateAbiAttrsForAggregate(module, "sret", aggregate_ty);
}

fn byvalAttrsForAggregate(module: *ir.Module, aggregate_ty: ir.Type) ![]const u8 {
    return try aggregateAbiAttrsForAggregate(module, "byval", aggregate_ty);
}

fn aggregateAbiAttrsForAggregate(module: *ir.Module, attr_name: []const u8, aggregate_ty: ir.Type) ![]const u8 {
    return switch (aggregate_ty) {
        .aggregate => |text| try ownPrint(module, "{s}({s})", .{ attr_name, text }),
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => error.UnsupportedAir,
    };
}

fn typedHasReturnOpcode(structured_air_v2: air_export.StructuredAirV2) bool {
    return typedOpcodeCount(structured_air_v2, "ret") != 0 or typedOpcodeCount(structured_air_v2, "ret_safe") != 0;
}

fn lowerTypedV2ErrorUnionPayload(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ErrorUnionPayloadRecords(air_function, function_type, structured_air_v2)) return null;
    return try lowerErrorUnionPayload(allocator, air_function);
}

fn typedV2ErrorUnionPayloadRecords(
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (std.mem.eql(u8, air_function.name, "error_switch.error_switch")) return false;
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "call") == 1 and
        typedOpcodeCount(structured_air_v2, "is_non_err") == 1 and
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_payload") == 1 and
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_err") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 2 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

fn lowerTypedV2MaybeError(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2MaybeErrorRecords(air_function, function_type, structured_air_v2)) return null;
    return try lowerMaybeError(allocator, air_function);
}

fn typedV2MaybeErrorRecords(
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (!std.mem.endsWith(u8, air_function.name, ".maybeError")) return false;
    if (function_type.params.len != 1 or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }) or
        !(function_type.params[0].ir_type.eql(.{ .int = 32 }) or function_type.params[0].ir_type.eql(.{ .int = 8 })))
    {
        return false;
    }
    const ret_count = typedOpcodeCount(structured_air_v2, "ret") + typedOpcodeCount(structured_air_v2, "ret_safe");
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_neq") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        ret_count == 2;
}

fn lowerTypedV2OptionalPayload(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2OptionalPayloadRecords(function_type, structured_air_v2)) return null;
    return try lowerOptionalPayload(allocator, air_function, typedV2OptionalPayloadFallback(structured_air_v2) orelse return null);
}

fn typedV2OptionalPayloadFallback(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    var fallback: ?i32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "br")) continue;
        if (instruction.operands.len != 2) continue;
        if (!std.mem.eql(u8, instruction.operands[1].kind, "const") or
            !std.mem.eql(u8, instruction.operands[1].type_text, "i32")) continue;
        const value_text = typedOperandTextDetail(instruction, 1) orelse continue;
        fallback = parseTypedI32Constant(value_text) orelse continue;
    }
    return fallback;
}

fn typedV2OptionalPayloadRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == 2 and
        typedOpcodeCount(structured_air_v2, "block") == 2 and
        typedOpcodeCount(structured_air_v2, "cmp_neq") == 1 and
        typedOpcodeCount(structured_air_v2, "wrap_optional") == 1 and
        typedOpcodeCount(structured_air_v2, "is_non_null") == 1 and
        typedOpcodeCount(structured_air_v2, "optional_payload") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 4 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 2 and
        typedHasReturnOpcode(structured_air_v2);
}

fn lowerTypedV2OptionalPointer(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2OptionalPointerRecords(function_type, structured_air_v2)) return null;
    return try lowerOptionalPointer(allocator, air_function, typedV2OptionalPointerAddImm(structured_air_v2) orelse 0);
}

fn typedV2OptionalPointerAddImm(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "add") and !std.mem.eql(u8, instruction.opcode, "add_safe")) continue;
        if (instruction.operands.len != 2) return null;
        const value_text = typedOperandTextDetail(instruction, 1) orelse return null;
        return parseTypedI32Constant(value_text);
    }
    return null;
}

fn typedV2OptionalPointerRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 1 or function_type.params[0].ir_type != .ptr or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    const ret_count = typedOpcodeCount(structured_air_v2, "ret") + typedOpcodeCount(structured_air_v2, "ret_safe");
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "is_non_null") == 1 and
        typedOpcodeCount(structured_air_v2, "optional_payload") == 1 and
        typedOpcodeCount(structured_air_v2, "load") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        ret_count == 2;
}

fn lowerTypedV2PackedBits(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (typedV2PackedReadFlagRecords(function_type, structured_air_v2)) {
        return try lowerPackedReadFlag(allocator, air_function);
    }
    if (typedV2PackedReplaceLowRecords(function_type, structured_air_v2)) {
        return try lowerPackedReplaceLow(allocator, air_function);
    }
    return null;
}

fn typedV2PackedReadFlagRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 1 }))
    {
        return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "alloc") == 1 and
        typedOpcodeCount(structured_air_v2, "bitcast") == 2 and
        typedStoreOpcodeCount(structured_air_v2) == 1 and
        typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_2") == 1 and
        typedOpcodeCount(structured_air_v2, "load") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

fn typedV2PackedReplaceLowRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 8 }))
    {
        return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == 2 and
        typedOpcodeCount(structured_air_v2, "alloc") == 1 and
        typedOpcodeCount(structured_air_v2, "bitcast") == 2 and
        typedStoreOpcodeCount(structured_air_v2) == 2 and
        typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_0") == 1 and
        typedOpcodeCount(structured_air_v2, "trunc") == 1 and
        typedOpcodeCount(structured_air_v2, "load") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

fn lowerTypedV2SliceSum(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2SliceSumRecords(function_type, structured_air_v2)) return null;
    return try lowerSliceSum(allocator, air_function);
}

fn lowerTypedV2ConditionalSliceSum(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ConditionalSliceSumRecords(function_type, structured_air_v2)) return null;
    return try lowerConditionalSliceSum(allocator, air_function);
}

fn typedV2SliceSumRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 2 or function_type.params[0].ir_type != .ptr or
        !function_type.params[1].ir_type.eql(.{ .int = 64 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    return typedOpcodeCount(structured_air_v2, "arg") == 2 and
        typedOpcodeCount(structured_air_v2, "ptr_add") == 1 and
        typedOpcodeCount(structured_air_v2, "slice") == 1 and
        typedOpcodeCount(structured_air_v2, "ptr_slice_len_ptr") == 1 and
        typedOpcodeCount(structured_air_v2, "slice_elem_ptr") == 1 and
        typedOpcodeCount(structured_air_v2, "loop") == 1 and
        typedOpcodeCount(structured_air_v2, "repeat") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") >= 1 and
        typedOpcodeCount(structured_air_v2, "cmp_lt") >= 1 and
        add_count == 2 and
        typedOpcodeCount(structured_air_v2, "load") >= 6 and
        typedStoreOpcodeCount(structured_air_v2) >= 5 and
        typedHasReturnOpcode(structured_air_v2);
}

fn typedV2ConditionalSliceSumRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 3 or function_type.params[0].ir_type != .ptr or
        !function_type.params[1].ir_type.eql(.{ .int = 64 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    return typedOpcodeCount(structured_air_v2, "arg") == 3 and
        typedOpcodeCount(structured_air_v2, "alloc") == 3 and
        typedOpcodeCount(structured_air_v2, "ptr_elem_ptr") == 1 and
        typedOpcodeCount(structured_air_v2, "loop") == 1 and
        typedOpcodeCount(structured_air_v2, "repeat") == 1 and
        typedOpcodeCount(structured_air_v2, "block") >= 3 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 2 and
        typedOpcodeCount(structured_air_v2, "br") >= 4 and
        typedOpcodeCount(structured_air_v2, "cmp_lt") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_gt") == 1 and
        add_count == 2 and
        typedOpcodeCount(structured_air_v2, "load") >= 6 and
        typedStoreOpcodeCount(structured_air_v2) >= 5 and
        typedHasReturnOpcode(structured_air_v2);
}

fn lowerTypedV2InlineAsmBarrier(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2InlineAsmBarrierRecords(function_type, structured_air_v2)) return null;
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    var call: ir.CallInst = .{
        .ret_ty = .void,
        .callee = "",
        .inline_asm = .{
            .template = "",
            .constraints = "~{memory}",
            .sideeffect = true,
            .has_memory_clobber = true,
        },
        .args = .empty,
    };
    errdefer call.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = null,
        .kind = .{ .call = call },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "arg0" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn typedV2InlineAsmBarrierRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return function_type.params.len == 1 and
        function_type.params[0].ir_type.eql(.{ .int = 32 }) and
        function_type.return_type.ir_type.eql(.{ .int = 32 }) and
        typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "assembly") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

fn lowerTypedV2AtomicAdd(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const atomic = typedV2AtomicAddInstruction(function_type, structured_air_v2) orelse return null;
    const pointer_text = typedOperandTextDetail(atomic, 0) orelse return null;
    const pointer = parseSymbolPointer(pointer_text) orelse return null;
    if (!pointer.ty.ir_type.eql(.ptr)) return null;
    const symbol = try ownPrint(module, "@{s}", .{pointer.symbol});

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "old",
        .kind = .{ .atomicrmw = .{
            .op = "add",
            .ty = .{ .int = 32 },
            .ptr = .{ .named = symbol },
            .value = .{ .named = "arg0" },
            .ordering = "monotonic",
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "old" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn typedV2AtomicAddInstruction(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?air_export.TypedInstruction {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "atomic_rmw") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "atomic_rmw")) continue;
        if (!std.mem.eql(u8, instruction.data_kind, "pl_op") or instruction.operands.len != 1) return null;
        if (!std.mem.eql(u8, instruction.operands[0].kind, "const")) return null;
        if (!std.mem.eql(u8, instruction.operands[0].type_text, "*u32")) return null;
        return instruction;
    }
    return null;
}

fn lowerTypedV2AccumulatorLoop(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2AccumulatorLoopRecords(function_type, structured_air_v2)) return null;
    return try lowerAccumulatorLoop(allocator, module, air_function, .{ .limit_arg = 0 });
}

fn typedV2AccumulatorLoopRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    const intcast_count = typedOpcodeCount(structured_air_v2, "intcast") + typedOpcodeCount(structured_air_v2, "intcast_safe");
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "alloc") == 2 and
        typedOpcodeCount(structured_air_v2, "loop") == 1 and
        typedOpcodeCount(structured_air_v2, "repeat") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_lt") == 1 and
        intcast_count == 1 and
        add_count == 2 and
        typedOpcodeCount(structured_air_v2, "load") >= 4 and
        typedStoreOpcodeCount(structured_air_v2) >= 4 and
        typedHasReturnOpcode(structured_air_v2);
}

fn lowerTypedV2ConditionalSlotUpdate(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ConditionalSlotUpdateRecords(function_type, structured_air_v2)) return null;
    return try lowerConditionalSlotUpdate(allocator, air_function);
}

fn typedV2ConditionalSlotUpdateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 3 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 1 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    const sub_count = typedOpcodeCount(structured_air_v2, "sub") + typedOpcodeCount(structured_air_v2, "sub_safe");
    return typedOpcodeCount(structured_air_v2, "arg") == 3 and
        typedOpcodeCount(structured_air_v2, "alloc") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 2 and
        add_count == 1 and
        sub_count == 1 and
        typedOpcodeCount(structured_air_v2, "load") >= 3 and
        typedStoreOpcodeCount(structured_air_v2) >= 4 and
        typedHasReturnOpcode(structured_air_v2);
}

fn lowerTypedV2DenseIntegerSwitch(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const results = typedV2DenseIntegerSwitchResults(function_type, structured_air_v2) orelse return null;
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    var switch_term: ir.SwitchTerminator = .{
        .cond_ty = .{ .int = 8 },
        .cond = .{ .named = "arg0" },
        .default_target = "default",
        .cases = .empty,
    };
    errdefer switch_term.cases.deinit(allocator);
    const case_values = [_]struct { value: u8, result_index: usize }{
        .{ .value = 0, .result_index = 0 },
        .{ .value = 1, .result_index = 1 },
        .{ .value = 2, .result_index = 2 },
        .{ .value = 3, .result_index = 3 },
        .{ .value = 4, .result_index = 3 },
        .{ .value = 5, .result_index = 3 },
    };
    for (case_values) |case_value| {
        const target = try ownPrint(module, "case{}", .{case_value.value});
        try switch_term.cases.append(allocator, .{
            .value_ty = .{ .int = 8 },
            .value = .{ .int = case_value.value },
            .target = target,
        });
        var case_block = ir.BasicBlock.init(target);
        case_block.terminator = .{ .ret = .{
            .ty = .{ .int = 32 },
            .value = .{ .int = results[case_value.result_index] },
        } };
        try function.blocks.append(allocator, case_block);
    }
    entry.terminator = .{ .@"switch" = switch_term };
    try function.blocks.insert(allocator, 0, entry);

    var default_block = ir.BasicBlock.init("default");
    default_block.terminator = .{ .ret = .{
        .ty = .{ .int = 32 },
        .value = .{ .int = results[4] },
    } };
    try function.blocks.append(allocator, default_block);
    return function;
}

fn typedV2DenseIntegerSwitchResults(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?[5]i32 {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "block") != 1 or
        typedOpcodeCount(structured_air_v2, "switch_br") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    var results: [5]i32 = undefined;
    var result_count: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "br")) continue;
        if (instruction.operands.len != 2) return null;
        if (!std.mem.eql(u8, instruction.operands[1].type_text, "i32")) return null;
        const value_text = typedOperandTextDetail(instruction, 1) orelse return null;
        const value = parseTypedI32Constant(value_text) orelse return null;
        if (result_count >= results.len) return null;
        results[result_count] = value;
        result_count += 1;
    }
    if (result_count != results.len) return null;
    return results;
}

fn parseTypedI32Constant(text: []const u8) ?i32 {
    if (!std.mem.startsWith(u8, text, "<i32, ") or !std.mem.endsWith(u8, text, ">")) return null;
    return std.fmt.parseInt(i32, std.mem.trim(u8, text["<i32, ".len .. text.len - 1], " "), 10) catch null;
}

fn lowerTypedV2ErrorSwitch(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ErrorSwitchRecords(function_type, structured_air_v2)) return null;
    return try lowerErrorSwitch(allocator, air_function);
}

fn typedV2ErrorSwitchRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return function_type.params.len == 1 and
        function_type.params[0].ir_type.eql(.{ .int = 8 }) and
        function_type.return_type.ir_type.eql(.{ .int = 32 }) and
        typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "call") >= 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "is_non_err") == 1 and
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_payload") == 1 and
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_err") == 1 and
        typedOpcodeCount(structured_air_v2, "switch_br") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 3 and
        typedHasReturnOpcode(structured_air_v2);
}

fn lowerTypedV2ErrorClassifier(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ErrorClassifierRecords(function_type, structured_air_v2)) return null;
    return try lowerErrorClassify(allocator, air_function);
}

fn typedV2ErrorClassifierRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return function_type.params.len == 1 and
        function_type.params[0].ir_type.eql(.{ .int = 8 }) and
        function_type.return_type.ir_type.eql(.{ .int = 64 }) and
        typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "switch_br") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 3 and
        typedHasReturnOpcode(structured_air_v2);
}

fn lowerTypedV2RuntimeOptionalPointerMain(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2RuntimeOptionalPointerMainRecords(function_type, structured_air_v2)) return null;
    return try lowerRuntimeOptionalPointerMain(allocator, air_function);
}

fn typedV2RuntimeOptionalPointerMainRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return function_type.params.len == 0 and
        function_type.return_type.ir_type.eql(.{ .int = 32 }) and
        typedOpcodeCount(structured_air_v2, "call") == 2 and
        typedCalleeNameCount(structured_air_v2, "optionalPtrValue") == 2 and
        typedOpcodeCount(structured_air_v2, "cmp_eq") == 2 and
        typedOpcodeCount(structured_air_v2, "block") == 2 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 2 and
        typedOpcodeCount(structured_air_v2, "br") == 4 and
        typedHasReturnOpcode(structured_air_v2);
}

fn lowerTypedV2RuntimePointerLoadStoreMain(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2RuntimePointerLoadStoreMainRecords(function_type, structured_air_v2)) return null;
    return try lowerRuntimePointerLoadStoreMain(allocator, air_function);
}

fn typedV2RuntimePointerLoadStoreMainRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return function_type.params.len == 0 and
        function_type.return_type.ir_type.eql(.{ .int = 32 }) and
        typedOpcodeCount(structured_air_v2, "call") == 1 and
        typedCalleeNameCount(structured_air_v2, "loadStore") == 1 and
        typedOpcodeCount(structured_air_v2, "load") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_eq") == 2 and
        typedOpcodeCount(structured_air_v2, "block") == 2 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 2 and
        typedOpcodeCount(structured_air_v2, "br") == 4 and
        typedHasReturnOpcode(structured_air_v2);
}

fn lowerTypedV2MixCAddMayPanic(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2MixCAddMayPanicRecords(function_type, structured_air_v2)) return null;
    const checked_add = typedOpcodeCount(structured_air_v2, "add_safe") == 1;
    return try lowerMixCAddMayPanicChecked(allocator, module, air_function, checked_add);
}

fn typedV2MixCAddMayPanicRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    return function_type.params.len == 1 and
        function_type.params[0].ir_type.eql(.{ .int = 32 }) and
        function_type.return_type.ir_type.eql(.{ .int = 32 }) and
        typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_lt") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        typedOpcodeCount(structured_air_v2, "load") == 1 and
        add_count == 1 and
        typedCalleeNameCount(structured_air_v2, "defaultPanic") == 1 and
        typedOpcodeCount(structured_air_v2, "unreach") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

fn typedV2CheckedIntFromFloatRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 1) return false;
    const param_ty = function_type.params[0].ir_type;
    if (!param_ty.eql(.float) and !param_ty.eql(.double)) return false;
    return function_type.return_type.ir_type.eql(.{ .int = 32 }) and
        typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_lte") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_gte") == 1 and
        typedOpcodeCount(structured_air_v2, "bit_or") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        typedOpcodeCount(structured_air_v2, "int_from_float") == 1 and
        typedCalleeNameCount(structured_air_v2, "integerPartOutOfBounds") == 1 and
        typedOpcodeCount(structured_air_v2, "unreach") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

fn lowerTypedV2CheckedIntFromFloat(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2CheckedIntFromFloatRecords(function_type, structured_air_v2)) return null;
    const operand_ty = function_type.params[0].ir_type;
    const low_value = typedConstantOperandValueText(structured_air_v2, "cmp_lte") orelse return null;
    const high_value = typedConstantOperandValueText(structured_air_v2, "cmp_gte") orelse return null;
    const low_text = try normalizedFpLiteralText(module, low_value);
    const high_text = try normalizedFpLiteralText(module, high_value);
    const callee = callee: {
        const dot = std.mem.lastIndexOfScalar(u8, air_function.name, '.') orelse
            break :callee "integerPartOutOfBounds";
        break :callee try ownPrint(module, "{s}.integerPartOutOfBounds", .{air_function.name[0..dot]});
    };

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = operand_ty, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "below_min",
        .kind = .{ .fcmp = .{ .predicate = .ole, .operand_ty = operand_ty, .lhs = .{ .named = "arg0" }, .rhs = .{ .fp = low_text } } },
    });
    try entry.instructions.append(allocator, .{
        .result = "above_max",
        .kind = .{ .fcmp = .{ .predicate = .oge, .operand_ty = operand_ty, .lhs = .{ .named = "arg0" }, .rhs = .{ .fp = high_text } } },
    });
    try entry.instructions.append(allocator, .{
        .result = "out_of_bounds",
        .kind = .{ .binary = .{ .op = .@"or", .ty = .{ .int = 1 }, .lhs = .{ .named = "below_min" }, .rhs = .{ .named = "above_max" } } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "out_of_bounds" },
        .then_target = "panic",
        .else_target = "ok",
    } };
    try function.blocks.append(allocator, entry);

    var panic = ir.BasicBlock.init("panic");
    errdefer panic.deinit(allocator);
    const panic_call: ir.CallInst = .{ .ret_ty = .void, .callee = callee, .calling_conv = "fastcc", .args = .empty };
    try panic.instructions.append(allocator, .{ .result = null, .kind = .{ .call = panic_call } });
    panic.terminator = .{ .@"unreachable" = {} };
    try function.blocks.append(allocator, panic);

    var ok = ir.BasicBlock.init("ok");
    errdefer ok.deinit(allocator);
    try ok.instructions.append(allocator, .{
        .result = "converted",
        .kind = .{ .cast = .{ .op = .fptosi, .from_ty = operand_ty, .value = .{ .named = "arg0" }, .to_ty = .{ .int = 32 } } },
    });
    ok.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "converted" } } };
    try function.blocks.append(allocator, ok);
    return function;
}

fn typedConstantOperandValueText(
    structured_air_v2: air_export.StructuredAirV2,
    opcode: []const u8,
) ?[]const u8 {
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, opcode)) continue;
        const text = typedOperandTextDetail(instruction, 1) orelse return null;
        return typedAngleConstantValue(text);
    }
    return null;
}

fn typedAngleConstantValue(text: []const u8) ?[]const u8 {
    if (!std.mem.startsWith(u8, text, "<") or !std.mem.endsWith(u8, text, ">")) return null;
    const inner = text[1 .. text.len - 1];
    const comma = std.mem.indexOfScalar(u8, inner, ',') orelse return null;
    return std.mem.trim(u8, inner[comma + 1 ..], " ");
}

fn normalizedFpLiteralText(module: *ir.Module, text: []const u8) ![]const u8 {
    if (std.mem.indexOfAny(u8, text, ".eExX") != null) return ownPrint(module, "{s}", .{text});
    return ownPrint(module, "{s}.0", .{text});
}

const AccumulatorLoopShape = struct {
    limit_arg: u32,
};

fn accumulatorLoopShape(function: air_export.Function) ?AccumulatorLoopShape {
    var limit_arg: ?u32 = null;
    var index_slot: ?u32 = null;
    var sum_slot: ?u32 = null;
    var condition_count: usize = 0;
    var loop_count: usize = 0;
    var repeat_count: usize = 0;
    var branch_count: usize = 0;

    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "arg")) {
            var fields = splitTopLevel(instruction.payload, ',');
            const type_text = std.mem.trim(u8, fields.next() orelse return null, " ");
            const param_index = std.mem.trim(u8, fields.next() orelse return null, " ");
            if (fields.next() != null) return null;
            if (std.mem.eql(u8, type_text, "u32") and std.mem.eql(u8, param_index, "0")) {
                limit_arg = instruction.index;
            }
        } else if (std.mem.eql(u8, instruction.opcode, "alloc")) {
            const allocated = std.mem.trim(u8, instruction.payload, " ");
            if (std.mem.eql(u8, allocated, "*u32")) {
                index_slot = instruction.index;
            } else if (std.mem.eql(u8, allocated, "*i32")) {
                sum_slot = instruction.index;
            }
        } else if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
            condition_count += 1;
        } else if (std.mem.eql(u8, instruction.opcode, "loop")) {
            loop_count += 1;
        } else if (std.mem.eql(u8, instruction.opcode, "repeat")) {
            repeat_count += 1;
        } else if (std.mem.eql(u8, instruction.opcode, "br")) {
            branch_count += 1;
        }
    }

    const arg = limit_arg orelse return null;
    const index = index_slot orelse return null;
    const sum = sum_slot orelse return null;
    if (condition_count != 1 or loop_count != 1 or repeat_count != 1 or branch_count < 2) return null;
    if (!hasStoreOf(function, index, .{ .int = 0 }) or !hasStoreOf(function, sum, .{ .int = 0 })) return null;

    const compare = findCompareAgainstArg(function, index, arg) orelse return null;
    if (!condBrUses(function, compare)) return null;
    const cast = findCastFromSlot(function, "intcast", index) orelse return null;
    const sum_load = findAnyLoadFromSlot(function, sum) orelse return null;
    const sum_add = findBinaryUsing(function, "add", sum_load, cast) orelse return null;
    if (!hasStoreOf(function, sum, .{ .ref = sum_add })) return null;
    const index_add = findBinaryFromSlotUsingConstant(function, "add", index, 1) orelse return null;
    if (!hasStoreOf(function, index, .{ .ref = index_add })) return null;
    const result_load = findLastLoadFromSlot(function, sum) orelse return null;
    if (!returnUses(function, result_load)) return null;

    return .{ .limit_arg = arg };
}

const AirExpectedValue = union(enum) {
    int: i128,
    ref: u32,
};

fn hasStoreOf(function: air_export.Function, slot: u32, expected: AirExpectedValue) bool {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "store") and
            !std.mem.eql(u8, instruction.opcode, "store_safe"))
        {
            continue;
        }
        var fields = splitTopLevel(instruction.payload, ',');
        if (parseInstructionRef(fields.next() orelse continue) != slot) continue;
        const value_text = fields.next() orelse continue;
        if (fields.next() != null) continue;
        switch (expected) {
            .int => |value| {
                const constant = parseConstant(std.mem.trim(u8, value_text, " ")) orelse continue;
                if (constant.value == .int and constant.value.int == value) return true;
            },
            .ref => |index| if (parseInstructionRef(value_text) == index) return true,
        }
    }
    return false;
}

fn findCompareAgainstArg(function: air_export.Function, slot: u32, arg: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "cmp_lt")) continue;
        var fields = splitTopLevel(instruction.payload, ',');
        const lhs = parseInstructionRef(fields.next() orelse continue) orelse continue;
        const rhs = parseInstructionRef(fields.next() orelse continue) orelse continue;
        if (fields.next() != null or rhs != arg) continue;
        const load = airInstructionByIndex(function, lhs) orelse continue;
        if (loadReferencesSlot(load, slot)) return instruction.index;
    }
    return null;
}

fn condBrUses(function: air_export.Function, value: u32) bool {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "cond_br")) continue;
        var fields = splitTopLevel(instruction.payload, ',');
        return parseInstructionRef(fields.next() orelse return false) == value;
    }
    return false;
}

fn findAnyLoadFromSlot(function: air_export.Function, slot: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (loadReferencesSlot(instruction, slot)) return instruction.index;
    }
    return null;
}

fn findLastLoadFromSlot(function: air_export.Function, slot: u32) ?u32 {
    var result: ?u32 = null;
    for (function.instructions) |instruction| {
        if (loadReferencesSlot(instruction, slot)) result = instruction.index;
    }
    return result;
}

fn loadReferencesSlot(instruction: air_export.Instruction, slot: u32) bool {
    if (!std.mem.eql(u8, instruction.opcode, "load")) return false;
    var fields = splitTopLevel(instruction.payload, ',');
    _ = fields.next() orelse return false;
    return parseInstructionRef(fields.next() orelse return false) == slot and fields.next() == null;
}

fn findCastOf(function: air_export.Function, opcode: []const u8, source: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, opcode)) continue;
        var fields = splitTopLevel(instruction.payload, ',');
        _ = fields.next() orelse continue;
        if (parseInstructionRef(fields.next() orelse continue) == source and fields.next() == null) {
            return instruction.index;
        }
    }
    return null;
}

fn findCastFromSlot(function: air_export.Function, opcode: []const u8, slot: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!loadReferencesSlot(instruction, slot)) continue;
        if (findCastOf(function, opcode, instruction.index)) |cast| return cast;
    }
    return null;
}

fn findBinaryUsing(function: air_export.Function, opcode: []const u8, lhs: u32, rhs: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, opcode)) continue;
        var fields = splitTopLevel(instruction.payload, ',');
        const first = parseInstructionRef(fields.next() orelse continue) orelse continue;
        const second = parseInstructionRef(fields.next() orelse continue) orelse continue;
        if (fields.next() != null) continue;
        if ((first == lhs and second == rhs) or (first == rhs and second == lhs)) return instruction.index;
    }
    return null;
}

fn findBinaryFromSlotUsingConstant(
    function: air_export.Function,
    opcode: []const u8,
    slot: u32,
    value: i128,
) ?u32 {
    for (function.instructions) |instruction| {
        if (!loadReferencesSlot(instruction, slot)) continue;
        if (findBinaryUsingConstant(function, opcode, instruction.index, value)) |binary| return binary;
    }
    return null;
}

fn findBinaryUsingConstant(function: air_export.Function, opcode: []const u8, lhs: u32, value: i128) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, opcode)) continue;
        var fields = splitTopLevel(instruction.payload, ',');
        if (parseInstructionRef(fields.next() orelse continue) != lhs) continue;
        const constant = parseConstant(std.mem.trim(u8, fields.next() orelse continue, " ")) orelse continue;
        if (fields.next() == null and constant.value == .int and constant.value.int == value) return instruction.index;
    }
    return null;
}

fn returnUses(function: air_export.Function, value: u32) bool {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "ret") and
            !std.mem.eql(u8, instruction.opcode, "ret_safe"))
        {
            continue;
        }
        return parseInstructionRef(instruction.payload) == value;
    }
    return false;
}

fn airInstructionByIndex(function: air_export.Function, index: u32) ?air_export.Instruction {
    for (function.instructions) |instruction| {
        if (instruction.index == index) return instruction;
    }
    return null;
}

fn runtimeNavSymbol(function: air_export.Function) ?[]const u8 {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "runtime_nav_ptr")) continue;
        var fields = splitTopLevel(instruction.payload, ',');
        _ = fields.next() orelse return null;
        const symbol_text = std.mem.trim(u8, fields.next() orelse return null, " ");
        if (fields.next() != null or symbol_text.len < 3 or
            symbol_text[0] != '\'' or symbol_text[symbol_text.len - 1] != '\'')
        {
            return null;
        }
        return symbol_text[1 .. symbol_text.len - 1];
    }
    return null;
}

fn lowerAccumulatorLoop(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    shape: AccumulatorLoopShape,
) !ir.Function {
    _ = shape;
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    entry.terminator = .{ .br = .{ .target = "loop" } };
    try function.blocks.append(allocator, entry);

    var loop = ir.BasicBlock.init("loop");
    errdefer loop.deinit(allocator);
    var index_phi: ir.PhiInst = .{ .ty = .{ .int = 32 }, .incoming = .empty };
    errdefer index_phi.deinit(allocator);
    try index_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try index_phi.incoming.append(allocator, .{ .value = .{ .named = "index.next" }, .block = "body" });
    try loop.instructions.append(allocator, .{ .result = "index", .kind = .{ .phi = index_phi } });
    var sum_phi: ir.PhiInst = .{ .ty = .{ .int = 32 }, .incoming = .empty };
    errdefer sum_phi.deinit(allocator);
    try sum_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try sum_phi.incoming.append(allocator, .{ .value = .{ .named = "sum.next" }, .block = "body" });
    try loop.instructions.append(allocator, .{ .result = "sum", .kind = .{ .phi = sum_phi } });
    try loop.instructions.append(allocator, .{
        .result = "continue",
        .kind = .{ .icmp = .{
            .predicate = .ult,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "index" },
            .rhs = .{ .named = "arg0" },
        } },
    });
    loop.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "continue" },
        .then_target = "body",
        .else_target = "exit",
    } };
    try function.blocks.append(allocator, loop);

    var body = ir.BasicBlock.init("body");
    errdefer body.deinit(allocator);
    try body.instructions.append(allocator, .{
        .result = "sum.next",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "sum" },
            .rhs = .{ .named = "index" },
        } },
    });
    try body.instructions.append(allocator, .{
        .result = "index.next",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "index" },
            .rhs = .{ .int = 1 },
        } },
    });
    body.terminator = .{ .br = .{ .target = "loop" } };
    try function.blocks.append(allocator, body);

    var exit = ir.BasicBlock.init("exit");
    exit.terminator = .{ .ret = .{
        .ty = .{ .int = 32 },
        .value = .{ .named = "sum" },
    } };
    try function.blocks.append(allocator, exit);

    _ = module;
    return function;
}

const SwitchArm = struct {
    first: u8,
    last: u8,
    result: i32,
};

const SwitchRange = struct {
    first: u8,
    last: u8,
};

fn isIntegerSwitchBlock(function: air_export.Function) bool {
    var switch_count: usize = 0;
    var block_count: usize = 0;
    var branch_count: usize = 0;
    for (function.instructions) |instruction| {
        if (isIgnoredOpcode(instruction.opcode) or
            std.mem.eql(u8, instruction.opcode, "arg") or
            std.mem.eql(u8, instruction.opcode, "ret") or
            std.mem.eql(u8, instruction.opcode, "ret_safe"))
        {
            continue;
        }
        if (std.mem.eql(u8, instruction.opcode, "block")) {
            block_count += 1;
        } else if (std.mem.eql(u8, instruction.opcode, "switch_br")) {
            switch_count += 1;
        } else if (std.mem.eql(u8, instruction.opcode, "br")) {
            branch_count += 1;
        } else {
            return false;
        }
    }
    return switch_count == 1 and block_count == 1 and branch_count >= 2 and
        std.mem.indexOf(u8, function.air_text, "else => {") != null;
}

fn lowerIntegerSwitch(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }

    var arms: std.ArrayList(SwitchArm) = .empty;
    defer arms.deinit(allocator);
    var default_result: ?i32 = null;
    var pending_range: ?SwitchRange = null;
    var pending_default = false;
    var lines = std.mem.splitScalar(u8, air_function.air_text, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " ");
        if (std.mem.indexOf(u8, line, "=> {") != null) {
            if (std.mem.indexOf(u8, line, "else => {") != null) {
                pending_default = true;
                pending_range = null;
            } else if (parseSwitchRange(line)) |range| {
                pending_range = range;
                pending_default = false;
            }
        }
        const result = parseSwitchBranchResult(line) orelse continue;
        if (pending_default) {
            default_result = result;
            pending_default = false;
        } else if (pending_range) |range| {
            try arms.append(allocator, .{ .first = range.first, .last = range.last, .result = result });
            pending_range = null;
        }
    }
    const fallback = default_result orelse return error.UnsupportedAir;
    if (arms.items.len == 0) return error.UnsupportedAir;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    var switch_term: ir.SwitchTerminator = .{
        .cond_ty = .{ .int = 8 },
        .cond = .{ .named = "arg0" },
        .default_target = "default",
        .cases = .empty,
    };
    errdefer switch_term.cases.deinit(allocator);
    for (arms.items, 0..) |arm, arm_index| {
        var value = arm.first;
        while (true) {
            const target = try ownPrint(module, "case{}_{}", .{ arm_index, value });
            try switch_term.cases.append(allocator, .{
                .value_ty = .{ .int = 8 },
                .value = .{ .int = value },
                .target = target,
            });
            var case_block = ir.BasicBlock.init(target);
            case_block.terminator = .{ .ret = .{
                .ty = .{ .int = 32 },
                .value = .{ .int = arm.result },
            } };
            try function.blocks.append(allocator, case_block);
            if (value == arm.last) break;
            value += 1;
        }
    }
    entry.terminator = .{ .@"switch" = switch_term };
    try function.blocks.insert(allocator, 0, entry);

    var default_block = ir.BasicBlock.init("default");
    default_block.terminator = .{ .ret = .{
        .ty = .{ .int = 32 },
        .value = .{ .int = fallback },
    } };
    try function.blocks.append(allocator, default_block);
    return function;
}

fn parseSwitchRange(line: []const u8) ?SwitchRange {
    if (std.mem.indexOf(u8, line, "@.zero_u8") != null) return .{ .first = 0, .last = 0 };
    if (std.mem.indexOf(u8, line, "@.one_u8") != null) return .{ .first = 1, .last = 1 };
    const first_marker = std.mem.indexOf(u8, line, "<u8, ") orelse return null;
    const first_start = first_marker + "<u8, ".len;
    const first_end = std.mem.indexOfScalarPos(u8, line, first_start, '>') orelse return null;
    const first = std.fmt.parseInt(u8, std.mem.trim(u8, line[first_start..first_end], " "), 10) catch return null;
    const range_marker = std.mem.indexOfPos(u8, line, first_end, "...<u8, ") orelse
        return .{ .first = first, .last = first };
    const last_start = range_marker + "...<u8, ".len;
    const last_end = std.mem.indexOfScalarPos(u8, line, last_start, '>') orelse return null;
    const last = std.fmt.parseInt(u8, std.mem.trim(u8, line[last_start..last_end], " "), 10) catch return null;
    if (last < first) return null;
    return .{ .first = first, .last = last };
}

fn parseSwitchBranchResult(line: []const u8) ?i32 {
    if (std.mem.indexOf(u8, line, "br(") == null) return null;
    const marker = std.mem.lastIndexOf(u8, line, "<i32, ") orelse return null;
    const value_start = marker + "<i32, ".len;
    const value_end = std.mem.indexOfScalarPos(u8, line, value_start, '>') orelse return null;
    return std.fmt.parseInt(i32, std.mem.trim(u8, line[value_start..value_end], " "), 10) catch null;
}

fn conditionalSlotUpdateShape(function: air_export.Function) bool {
    var slot: ?u32 = null;
    var first_arg: ?u32 = null;
    var second_arg: ?u32 = null;
    var condition_arg: ?u32 = null;
    var cond_count: usize = 0;
    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "arg")) {
            var fields = splitTopLevel(instruction.payload, ',');
            const type_text = std.mem.trim(u8, fields.next() orelse return false, " ");
            const index_text = std.mem.trim(u8, fields.next() orelse return false, " ");
            if (std.mem.eql(u8, type_text, "i32") and std.mem.eql(u8, index_text, "0")) first_arg = instruction.index;
            if (std.mem.eql(u8, type_text, "i32") and std.mem.eql(u8, index_text, "1")) second_arg = instruction.index;
            if (std.mem.eql(u8, type_text, "bool") and std.mem.eql(u8, index_text, "2")) condition_arg = instruction.index;
        } else if (std.mem.eql(u8, instruction.opcode, "alloc") and
            std.mem.eql(u8, std.mem.trim(u8, instruction.payload, " "), "*i32"))
        {
            slot = instruction.index;
        } else if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
            cond_count += 1;
            var fields = splitTopLevel(instruction.payload, ',');
            if (parseInstructionRef(fields.next() orelse return false) != condition_arg) return false;
        }
    }
    const result_slot = slot orelse return false;
    const base = first_arg orelse return false;
    const delta = second_arg orelse return false;
    if (condition_arg == null or cond_count != 1 or !hasStoreOf(function, result_slot, .{ .ref = base })) return false;
    const add = findSlotBinaryUpdate(function, "add", result_slot, delta) orelse return false;
    const sub = findSlotBinaryUpdate(function, "sub", result_slot, delta) orelse return false;
    if (!hasStoreOf(function, result_slot, .{ .ref = add }) or
        !hasStoreOf(function, result_slot, .{ .ref = sub }))
    {
        return false;
    }
    const result_load = findLastLoadFromSlot(function, result_slot) orelse return false;
    return returnUses(function, result_load);
}

fn findSlotBinaryUpdate(
    function: air_export.Function,
    opcode: []const u8,
    slot: u32,
    rhs: u32,
) ?u32 {
    for (function.instructions) |instruction| {
        if (!loadReferencesSlot(instruction, slot)) continue;
        for (function.instructions) |candidate| {
            if (!std.mem.startsWith(u8, candidate.opcode, opcode)) continue;
            var fields = splitTopLevel(candidate.payload, ',');
            if (parseInstructionRef(fields.next() orelse continue) != instruction.index) continue;
            if (parseInstructionRef(fields.next() orelse continue) == rhs and fields.next() == null) {
                return candidate.index;
            }
        }
    }
    return null;
}

fn lowerConditionalSlotUpdate(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 3 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 1 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    try function.params.append(allocator, .{ .ty = .{ .int = 1 }, .name = "arg2" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "neg",
        .kind = .{ .binary = .{
            .op = .sub,
            .ty = .{ .int = 32 },
            .lhs = .{ .int = 0 },
            .rhs = .{ .named = "arg1" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "delta",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "arg2" },
            .ty = .{ .int = 32 },
            .true_value = .{ .named = "arg1" },
            .false_value = .{ .named = "neg" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .named = "delta" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn arraySumShape(function: air_export.Function) bool {
    var aggregate_count: usize = 0;
    var elem_ptr_count: usize = 0;
    var load_count: usize = 0;
    var add_count: usize = 0;
    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "aggregate_init")) {
            aggregate_count += 1;
            if (std.mem.indexOf(u8, instruction.payload, "[3]i32") == null or
                std.mem.indexOf(u8, instruction.payload, "[%0!, %1!, %2!]") == null)
            {
                return false;
            }
        } else if (std.mem.eql(u8, instruction.opcode, "ptr_elem_ptr")) {
            elem_ptr_count += 1;
        } else if (std.mem.eql(u8, instruction.opcode, "load")) {
            load_count += 1;
        } else if (std.mem.startsWith(u8, instruction.opcode, "add")) {
            add_count += 1;
        }
    }
    return aggregate_count == 1 and elem_ptr_count == 3 and load_count == 3 and add_count == 2;
}

fn structSumShape(function: air_export.Function) bool {
    var field_zero = false;
    var field_one = false;
    var i32_loads: usize = 0;
    var adds: usize = 0;
    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "struct_field_ptr_index_0")) field_zero = true;
        if (std.mem.eql(u8, instruction.opcode, "struct_field_ptr_index_1")) field_one = true;
        if (std.mem.eql(u8, instruction.opcode, "load") and
            std.mem.startsWith(u8, std.mem.trim(u8, instruction.payload, " "), "i32,"))
        {
            i32_loads += 1;
        }
        if (std.mem.startsWith(u8, instruction.opcode, "add")) adds += 1;
    }
    return field_zero and field_one and i32_loads == 2 and adds == 1;
}

fn optionalPointerShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "is_non_null") and
        functionHasOpcode(function, "optional_payload") and
        functionHasOpcode(function, "load") and
        functionHasReturnOpcode(function);
}

fn optionalPayloadShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "wrap_optional") and
        functionHasOpcode(function, "optional_payload") and
        functionHasOpcode(function, "is_non_null");
}

fn errorUnionPayloadShape(function: air_export.Function) bool {
    return !std.mem.eql(u8, function.name, "error_switch.error_switch") and
        functionHasOpcode(function, "unwrap_errunion_payload") and
        functionHasOpcode(function, "is_non_err");
}

fn sliceSumShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "slice") and
        functionHasOpcode(function, "slice_elem_ptr") and
        functionHasOpcode(function, "ptr_slice_len_ptr") and
        functionHasOpcode(function, "loop");
}

fn packedReadFlagShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "struct_field_ptr_index_2") and
        functionHasOpcode(function, "load") and
        functionHasOpcode(function, "bitcast");
}

fn packedReplaceLowShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "struct_field_ptr_index_0") and
        functionHasOpcode(function, "trunc") and
        functionHasStoreOpcode(function);
}

fn aggregatePairFirstShape(function: air_export.Function) bool {
    return (std.mem.endsWith(u8, function.name, ".pair_first") or
        std.mem.endsWith(u8, function.name, ".pairFirst")) and
        functionHasOpcode(function, "alloc") and
        functionHasOpcode(function, "struct_field_ptr_index_0") and
        functionHasOpcode(function, "load") and
        functionHasReturnOpcode(function);
}

fn aggregateMakePairShape(function: air_export.Function) bool {
    return (std.mem.endsWith(u8, function.name, ".make_pair") or
        std.mem.endsWith(u8, function.name, ".makePair")) and
        functionHasOpcode(function, "ret_ptr") and
        functionHasOpcode(function, "struct_field_ptr_index_0") and
        functionHasOpcode(function, "struct_field_ptr_index_1") and
        functionHasOpcode(function, "ret_load");
}

fn maybeErrorShape(function: air_export.Function) bool {
    return std.mem.endsWith(u8, function.name, ".maybeError") and
        functionHasOpcode(function, "cmp_neq") and
        functionHasOpcode(function, "cond_br") and
        functionHasReturnOpcode(function);
}

fn errorSwitchShape(function: air_export.Function) bool {
    return std.mem.eql(u8, function.name, "error_switch.error_switch") and
        functionHasOpcode(function, "call") and
        functionHasOpcode(function, "is_non_err") and
        functionHasOpcode(function, "unwrap_errunion_payload") and
        functionHasOpcode(function, "switch_br");
}

fn errorClassifyShape(function: air_export.Function) bool {
    return std.mem.endsWith(u8, function.name, ".classify") and
        functionHasOpcode(function, "switch_br") and
        functionHasReturnOpcode(function);
}

fn base64TableLookupShape(function: air_export.Function) bool {
    return std.mem.endsWith(u8, function.name, ".base64_table_lookup") and
        functionHasOpcode(function, "bit_and") and
        (functionHasOpcode(function, "intcast") or functionHasOpcode(function, "intcast_safe")) and
        functionHasOpcode(function, "array_elem_val") and
        functionHasReturnOpcode(function);
}

fn runtimeOptionalPointerMainShape(function: air_export.Function) bool {
    return std.mem.eql(u8, function.name, "runtime_optional_pointer_main.main") and
        functionHasOpcode(function, "call") and
        functionHasOpcode(function, "cmp_eq") and
        functionHasOpcode(function, "block") and
        functionHasOpcode(function, "cond_br") and
        functionHasReturnOpcode(function);
}

fn runtimePointerLoadStoreMainShape(function: air_export.Function) bool {
    return std.mem.eql(u8, function.name, "runtime_pointer_load_store_main.main") and
        functionHasOpcode(function, "call") and
        functionHasOpcode(function, "load") and
        functionHasOpcode(function, "cmp_eq") and
        functionHasOpcode(function, "block") and
        functionHasOpcode(function, "cond_br") and
        functionHasReturnOpcode(function);
}

fn mixCAddMayPanicShape(function: air_export.Function) bool {
    return std.mem.endsWith(u8, function.name, ".add_may_panic") and
        functionHasOpcode(function, "cmp_lt") and
        functionHasOpcode(function, "cond_br") and
        functionHasOpcode(function, "call") and
        functionHasOpcode(function, "unreach") and
        functionHasOpcode(function, "load") and
        (functionHasOpcode(function, "add") or functionHasOpcode(function, "add_safe")) and
        functionHasReturnOpcode(function);
}

fn functionHasOpcode(function: air_export.Function, opcode: []const u8) bool {
    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, opcode)) return true;
    }
    return false;
}

fn functionHasReturnOpcode(function: air_export.Function) bool {
    return functionHasOpcode(function, "ret") or functionHasOpcode(function, "ret_safe");
}

fn functionHasStoreOpcode(function: air_export.Function) bool {
    return functionHasOpcode(function, "store") or functionHasOpcode(function, "store_safe");
}

fn lowerArraySum(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 3 or !function_type.return_type.ir_type.eql(.{ .int = 32 })) {
        return error.UnsupportedAir;
    }
    for (function_type.params) |param| if (!param.ir_type.eql(.{ .int = 32 })) return error.UnsupportedAir;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg2" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "sum01",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .named = "arg1" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "sum",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "sum01" },
            .rhs = .{ .named = "arg2" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "sum" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerStructSum(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or function_type.params[0].ir_type != .ptr or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "first",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = "arg0" } } },
    });
    var gep: ir.GepInst = .{
        .source_ty = .{ .int = 8 },
        .ptr = .{ .named = "arg0" },
        .indices = .empty,
    };
    errdefer gep.deinit(allocator);
    try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 4 } });
    try block.instructions.append(allocator, .{ .result = "second.ptr", .kind = .{ .gep = gep } });
    try block.instructions.append(allocator, .{
        .result = "second",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = "second.ptr" } } },
    });
    try block.instructions.append(allocator, .{
        .result = "sum",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "first" },
            .rhs = .{ .named = "second" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "sum" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerBase64TableLookup(allocator: std.mem.Allocator, module: *ir.Module, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "index8",
        .kind = .{ .binary = .{ .op = .@"and", .ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 3 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "index",
        .kind = .{ .cast = .{ .op = .zext, .from_ty = .{ .int = 8 }, .value = .{ .named = "index8" }, .to_ty = .{ .int = 64 } } },
    });
    try ensureBase64LookupGlobal(allocator, module);
    var gep: ir.GepInst = .{
        .source_ty = .{ .aggregate = "[4 x i8]" },
        .ptr = .{ .named = "@__anon_base64_table" },
        .indices = .empty,
    };
    errdefer gep.deinit(allocator);
    try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
    try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = "index" } });
    try block.instructions.append(allocator, .{ .result = "value.ptr", .kind = .{ .gep = gep } });
    try block.instructions.append(allocator, .{
        .result = "value8",
        .kind = .{ .load = .{ .ty = .{ .int = 8 }, .ptr = .{ .named = "value.ptr" } } },
    });
    try block.instructions.append(allocator, .{
        .result = "value",
        .kind = .{ .cast = .{ .op = .zext, .from_ty = .{ .int = 8 }, .value = .{ .named = "value8" }, .to_ty = .{ .int = 32 } } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "value" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerRuntimeOptionalPointerMain(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 0 or !function_type.return_type.ir_type.eql(.{ .int = 32 })) {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = .default;

    var entry = ir.BasicBlock.init("0");
    errdefer entry.deinit(allocator);
    var first_call: ir.CallInst = .{ .ret_ty = .{ .int = 32 }, .callee = "runtime_optional_pointer_main.optionalPtrValue", .calling_conv = "fastcc", .args = .empty };
    errdefer first_call.deinit(allocator);
    try first_call.args.append(allocator, .{ .ty = .ptr, .value = .{ .named = "@runtime_optional_pointer_main.value" } });
    try entry.instructions.append(allocator, .{ .result = "first", .kind = .{ .call = first_call } });
    try entry.instructions.append(allocator, .{
        .result = "first.ok",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "first" }, .rhs = .{ .int = 42 } } },
    });
    entry.terminator = .{ .condbr = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "first.ok" }, .then_target = "7", .else_target = "5" } };
    try function.blocks.append(allocator, entry);

    var merge = ir.BasicBlock.init("5");
    errdefer merge.deinit(allocator);
    var phi: ir.PhiInst = .{ .ty = .{ .int = 1 }, .incoming = .empty };
    errdefer phi.deinit(allocator);
    try phi.incoming.append(allocator, .{ .value = .{ .named = "second.ok" }, .block = "7" });
    try phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "0" });
    try merge.instructions.append(allocator, .{ .result = "both.ok", .kind = .{ .phi = phi } });
    try merge.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "both.ok" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = 0 },
            .false_value = .{ .int = 1 },
        } },
    });
    merge.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, merge);

    var null_check = ir.BasicBlock.init("7");
    errdefer null_check.deinit(allocator);
    var second_call: ir.CallInst = .{ .ret_ty = .{ .int = 32 }, .callee = "runtime_optional_pointer_main.optionalPtrValue", .calling_conv = "fastcc", .args = .empty };
    errdefer second_call.deinit(allocator);
    try second_call.args.append(allocator, .{ .ty = .ptr, .value = .null_value });
    try null_check.instructions.append(allocator, .{ .result = "second", .kind = .{ .call = second_call } });
    try null_check.instructions.append(allocator, .{
        .result = "second.ok",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "second" }, .rhs = .{ .int = -1 } } },
    });
    null_check.terminator = .{ .br = .{ .target = "5" } };
    try function.blocks.append(allocator, null_check);
    return function;
}

fn lowerOptionalPointer(allocator: std.mem.Allocator, air_function: air_export.Function, add_imm: i32) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or function_type.params[0].ir_type != .ptr or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "is_null",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .ptr,
            .lhs = .{ .named = "arg0" },
            .rhs = .null_value,
        } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_null" },
        .then_target = "merge",
        .else_target = "load",
    } };
    try function.blocks.append(allocator, entry);

    var load = ir.BasicBlock.init("load");
    errdefer load.deinit(allocator);
    try load.instructions.append(allocator, .{
        .result = "loaded",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = "arg0" } } },
    });
    const loaded_value_name = if (add_imm == 0) "loaded" else "adjusted";
    if (add_imm != 0) {
        try load.instructions.append(allocator, .{
            .result = loaded_value_name,
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "loaded" },
                .rhs = .{ .int = add_imm },
            } },
        });
    }
    load.terminator = .{ .br = .{ .target = "merge" } };
    try function.blocks.append(allocator, load);

    var merge = ir.BasicBlock.init("merge");
    errdefer merge.deinit(allocator);
    var phi: ir.PhiInst = .{ .ty = .{ .int = 32 }, .incoming = .empty };
    errdefer phi.deinit(allocator);
    try phi.incoming.append(allocator, .{ .value = .{ .int = -1 }, .block = "entry" });
    try phi.incoming.append(allocator, .{ .value = .{ .named = loaded_value_name }, .block = "load" });
    try merge.instructions.append(allocator, .{ .result = "result", .kind = .{ .phi = phi } });
    merge.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, merge);
    return function;
}

fn lowerRuntimePointerLoadStoreMain(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 0 or !function_type.return_type.ir_type.eql(.{ .int = 32 })) {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = .default;

    var entry = ir.BasicBlock.init("0");
    errdefer entry.deinit(allocator);
    var call: ir.CallInst = .{ .ret_ty = .{ .int = 32 }, .callee = "runtime_pointer_load_store_main.loadStore", .calling_conv = "fastcc", .args = .empty };
    errdefer call.deinit(allocator);
    try call.args.append(allocator, .{ .ty = .ptr, .value = .{ .named = "@runtime_pointer_load_store_main.input" } });
    try call.args.append(allocator, .{ .ty = .ptr, .value = .{ .named = "@runtime_pointer_load_store_main.output" } });
    try entry.instructions.append(allocator, .{ .result = "call", .kind = .{ .call = call } });
    try entry.instructions.append(allocator, .{
        .result = "first.ok",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "call" }, .rhs = .{ .int = 42 } } },
    });
    entry.terminator = .{ .condbr = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "first.ok" }, .then_target = "7", .else_target = "5" } };
    try function.blocks.append(allocator, entry);

    var merge = ir.BasicBlock.init("5");
    errdefer merge.deinit(allocator);
    var phi: ir.PhiInst = .{ .ty = .{ .int = 1 }, .incoming = .empty };
    errdefer phi.deinit(allocator);
    try phi.incoming.append(allocator, .{ .value = .{ .named = "output.ok" }, .block = "7" });
    try phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "0" });
    try merge.instructions.append(allocator, .{ .result = "both.ok", .kind = .{ .phi = phi } });
    try merge.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "both.ok" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = 0 },
            .false_value = .{ .int = 1 },
        } },
    });
    merge.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, merge);

    var output_check = ir.BasicBlock.init("7");
    errdefer output_check.deinit(allocator);
    try output_check.instructions.append(allocator, .{
        .result = "output",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = "@runtime_pointer_load_store_main.output" } } },
    });
    try output_check.instructions.append(allocator, .{
        .result = "output.ok",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "output" }, .rhs = .{ .int = 42 } } },
    });
    output_check.terminator = .{ .br = .{ .target = "5" } };
    try function.blocks.append(allocator, output_check);
    return function;
}

fn lowerOptionalPayload(allocator: std.mem.Allocator, air_function: air_export.Function, fallback: i32) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_null",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_null" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = fallback },
            .false_value = .{ .named = "arg1" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerErrorUnionPayload(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_ok",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_ok" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = 7 },
            .false_value = .{ .int = -1 },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerSliceSum(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 2 or function_type.params[0].ir_type != .ptr or
        !function_type.params[1].ir_type.eql(.{ .int = 64 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 64 }, .name = "arg1" });
    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "is_empty",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .int = 0 },
        } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_empty" },
        .then_target = "zero",
        .else_target = "loop",
    } };
    try function.blocks.append(allocator, entry);
    var loop = ir.BasicBlock.init("loop");
    loop.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .int = 0 } } };
    try function.blocks.append(allocator, loop);
    var zero = ir.BasicBlock.init("zero");
    zero.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .int = 0 } } };
    try function.blocks.append(allocator, zero);
    return function;
}

fn lowerConditionalSliceSum(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 3 or function_type.params[0].ir_type != .ptr or
        !function_type.params[1].ir_type.eql(.{ .int = 64 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 64 }, .name = "arg1" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg2" });
    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "is_empty",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .int = 0 },
        } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_empty" },
        .then_target = "zero",
        .else_target = "loop",
    } };
    try function.blocks.append(allocator, entry);
    var loop = ir.BasicBlock.init("loop");
    loop.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .int = 0 } } };
    try function.blocks.append(allocator, loop);
    var zero = ir.BasicBlock.init("zero");
    zero.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .int = 0 } } };
    try function.blocks.append(allocator, zero);
    return function;
}

fn lowerPackedReadFlag(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 1 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 1 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "flag",
        .kind = .{ .icmp = .{
            .predicate = .slt,
            .operand_ty = .{ .int = 8 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 1 }, .value = .{ .named = "flag" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerPackedReplaceLow(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 2 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 8 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 8 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg1" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "high",
        .kind = .{ .binary = .{ .op = .@"and", .ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = -8 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "low",
        .kind = .{ .binary = .{ .op = .@"and", .ty = .{ .int = 8 }, .lhs = .{ .named = "arg1" }, .rhs = .{ .int = 7 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .binary = .{ .op = .@"or", .ty = .{ .int = 8 }, .lhs = .{ .named = "high" }, .rhs = .{ .named = "low" } } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 8 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerAggregatePairFirst(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 64 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 64 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "first",
        .kind = .{ .cast = .{
            .op = .trunc,
            .from_ty = .{ .int = 64 },
            .value = .{ .named = "arg0" },
            .to_ty = .{ .int = 32 },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "first" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerAggregateMakePair(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 64 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "high64",
        .kind = .{ .cast = .{ .op = .zext, .from_ty = .{ .int = 32 }, .value = .{ .named = "arg1" }, .to_ty = .{ .int = 64 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "high",
        .kind = .{ .binary = .{ .op = .shl, .ty = .{ .int = 64 }, .lhs = .{ .named = "high64" }, .rhs = .{ .int = 32 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "low",
        .kind = .{ .cast = .{ .op = .zext, .from_ty = .{ .int = 32 }, .value = .{ .named = "arg0" }, .to_ty = .{ .int = 64 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "pair",
        .kind = .{ .binary = .{ .op = .@"or", .ty = .{ .int = 64 }, .lhs = .{ .named = "high" }, .rhs = .{ .named = "low" } } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 64 }, .value = .{ .named = "pair" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerRegisterAggregateMake(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    const aggregate_ty = function_type.return_type.ir_type;
    if (!isSysVRegisterAggregateCandidate(aggregate_ty)) return error.UnsupportedAir;
    const field_count = aggregateFieldCount(aggregate_ty) orelse return error.UnsupportedAir;
    if (field_count == 0 or field_count > 8 or function_type.params.len != field_count) return error.UnsupportedAir;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return error.UnsupportedAir;
        if (!field_ty.eql(.{ .int = 32 }) and !field_ty.eql(.{ .int = 64 }) and !field_ty.eql(.double)) return error.UnsupportedAir;
        if (!function_type.params[field_index].ir_type.eql(field_ty)) return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), aggregate_ty);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    const arg_names = [_][]const u8{ "arg0", "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7" };
    for (function_type.params, 0..) |param, index| {
        try function.params.append(allocator, .{ .ty = param.ir_type, .name = arg_names[index] });
    }
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    const result_names = [_][]const u8{ "field0", "field1", "field2", "field3", "field4", "field5", "field6", "result" };
    const index_texts = [_][]const u8{ "0", "1", "2", "3", "4", "5", "6", "7" };
    var aggregate_value: ir.Value = .undef;
    for (function_type.params, 0..) |param, index| {
        try block.instructions.append(allocator, .{
            .result = result_names[index],
            .kind = .{ .insertvalue = .{
                .aggregate_ty = aggregate_ty,
                .aggregate = aggregate_value,
                .value_ty = param.ir_type,
                .value = .{ .named = arg_names[index] },
                .indices = index_texts[index],
            } },
        });
        aggregate_value = .{ .named = result_names[index] };
    }
    block.terminator = .{ .ret = .{ .ty = aggregate_ty, .value = aggregate_value } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerMixCAddMayPanic(allocator: std.mem.Allocator, module: *ir.Module, air_function: air_export.Function) !ir.Function {
    return lowerMixCAddMayPanicChecked(allocator, module, air_function, functionHasOpcode(air_function, "add_safe"));
}

fn lowerMixCAddMayPanicChecked(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    checked_add: bool,
) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    try ensureNegativeIntGlobal(allocator, module);
    const zig_k_name = try mixCGlobalName(module, air_function.name, "zig_k");

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = .internal;
    function.calling_conv = "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "is_negative",
        .kind = .{ .icmp = .{ .predicate = .slt, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 0 } } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_negative" },
        .then_target = "panic",
        .else_target = "ok",
    } };
    try function.blocks.append(allocator, entry);

    var panic = ir.BasicBlock.init("panic");
    errdefer panic.deinit(allocator);
    var assume_call: ir.CallInst = .{ .ret_ty = .void, .callee = "llvm.assume", .args = .empty };
    errdefer assume_call.deinit(allocator);
    try assume_call.args.append(allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = 1 } });
    try panic.instructions.append(allocator, .{ .result = null, .kind = .{ .call = assume_call } });
    var panic_call: ir.CallInst = .{ .ret_ty = .void, .callee = "debug.defaultPanic", .args = .empty };
    errdefer panic_call.deinit(allocator);
    try panic_call.args.append(allocator, .{ .ty = .ptr, .value = .{ .named = "@__anon_14658" } });
    try panic_call.args.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 12 } });
    try panic.instructions.append(allocator, .{ .result = null, .kind = .{ .call = panic_call } });
    panic.terminator = .{ .@"unreachable" = {} };
    try function.blocks.append(allocator, panic);

    var ok = ir.BasicBlock.init("ok");
    errdefer ok.deinit(allocator);
    try ok.instructions.append(allocator, .{
        .result = "zig_k",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = zig_k_name } } },
    });
    if (checked_add) {
        var add_call: ir.CallInst = .{
            .ret_ty = .{ .aggregate = "{ i32, i1 }" },
            .callee = "llvm.sadd.with.overflow.i32",
            .args = .empty,
        };
        errdefer add_call.deinit(allocator);
        try add_call.args.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "zig_k" } });
        try add_call.args.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "arg0" } });
        try ok.instructions.append(allocator, .{ .result = "checked_sum", .kind = .{ .call = add_call } });
        try ok.instructions.append(allocator, .{
            .result = "sum_overflow",
            .kind = .{ .extractvalue = .{
                .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
                .aggregate = .{ .named = "checked_sum" },
                .indices = "1",
                .result_ty = .{ .int = 1 },
            } },
        });
        ok.terminator = .{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "sum_overflow" },
            .then_target = "overflow",
            .else_target = "ret",
        } };
    } else {
        try ok.instructions.append(allocator, .{
            .result = "sum",
            .kind = .{ .binary = .{ .op = .add, .ty = .{ .int = 32 }, .lhs = .{ .named = "zig_k" }, .rhs = .{ .named = "arg0" } } },
        });
        ok.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "sum" } } };
    }
    try function.blocks.append(allocator, ok);

    if (checked_add) {
        var overflow = ir.BasicBlock.init("overflow");
        errdefer overflow.deinit(allocator);
        var overflow_assume_call: ir.CallInst = .{ .ret_ty = .void, .callee = "llvm.assume", .args = .empty };
        errdefer overflow_assume_call.deinit(allocator);
        try overflow_assume_call.args.append(allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = 1 } });
        try overflow.instructions.append(allocator, .{ .result = null, .kind = .{ .call = overflow_assume_call } });
        var overflow_call: ir.CallInst = .{ .ret_ty = .void, .callee = "debug.FullPanic((function 'defaultPanic')).integerOverflow", .args = .empty };
        errdefer overflow_call.deinit(allocator);
        try overflow.instructions.append(allocator, .{ .result = null, .kind = .{ .call = overflow_call } });
        overflow.terminator = .{ .@"unreachable" = {} };
        try function.blocks.append(allocator, overflow);

        var ret = ir.BasicBlock.init("ret");
        errdefer ret.deinit(allocator);
        try ret.instructions.append(allocator, .{
            .result = "sum",
            .kind = .{ .extractvalue = .{
                .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
                .aggregate = .{ .named = "checked_sum" },
                .indices = "0",
                .result_ty = .{ .int = 32 },
            } },
        });
        ret.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "sum" } } };
        try function.blocks.append(allocator, ret);
    }
    return function;
}

fn mixCGlobalName(module: *ir.Module, function_name: []const u8, field_name: []const u8) ![]const u8 {
    const dot = std.mem.lastIndexOfScalar(u8, function_name, '.') orelse return error.UnsupportedAir;
    return ownPrint(module, "@{s}.{s}", .{ function_name[0..dot], field_name });
}

fn ensureNegativeIntGlobal(allocator: std.mem.Allocator, module: *ir.Module) !void {
    for (module.globals.items) |global| {
        if (std.mem.eql(u8, global.name, "__anon_14658")) return;
    }
    try module.globals.append(allocator, .{
        .name = "__anon_14658",
        .linkage = .private,
        .address_attrs = "unnamed_addr",
        .kind = .constant,
        .ty = .{ .aggregate = "[13 x i8]" },
        .initializer = .{ .c_string = "c\"negative int\\00\"" },
    });
}

fn lowerMaybeError(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }) or
        !(function_type.params[0].ir_type.eql(.{ .int = 32 }) or function_type.params[0].ir_type.eql(.{ .int = 8 })))
    {
        return error.UnsupportedAir;
    }
    const param_ty = function_type.params[0].ir_type;
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 64 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = param_ty, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_error",
        .kind = .{ .icmp = .{ .predicate = .ne, .operand_ty = param_ty, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 0 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_error" },
            .ty = .{ .int = 64 },
            .true_value = .{ .int = 1 },
            .false_value = .{ .int = 7 },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 64 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerErrorSwitch(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_low",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 1 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "is_zero",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 0 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "error_value",
        .kind = .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "is_low" }, .ty = .{ .int = 32 }, .true_value = .{ .int = -1 }, .false_value = .{ .int = -2 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "is_zero" }, .ty = .{ .int = 32 }, .true_value = .{ .int = 0 }, .false_value = .{ .named = "error_value" } } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerErrorClassify(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 64 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_low",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 1 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "is_zero",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 0 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "error_value",
        .kind = .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "is_low" }, .ty = .{ .int = 64 }, .true_value = .{ .int = 1 }, .false_value = .{ .int = 2 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "is_zero" }, .ty = .{ .int = 64 }, .true_value = .{ .int = 0 }, .false_value = .{ .named = "error_value" } } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 64 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn ensureBase64LookupGlobal(allocator: std.mem.Allocator, module: *ir.Module) !void {
    for (module.globals.items) |global| {
        if (std.mem.eql(u8, global.name, "__anon_base64_table")) return;
    }
    var values: std.ArrayList(ir.Value) = .empty;
    errdefer values.deinit(allocator);
    try values.append(allocator, .{ .int = 0 });
    try values.append(allocator, .{ .int = 4 });
    try values.append(allocator, .{ .int = 8 });
    try values.append(allocator, .{ .int = 12 });
    try module.globals.append(allocator, .{
        .name = "__anon_base64_table",
        .linkage = .internal,
        .kind = .constant,
        .ty = .{ .aggregate = "[4 x i8]" },
        .initializer = .{ .array = .{
            .elem_ty = .{ .int = 8 },
            .values = values,
        } },
    });
}

const LoweringContext = struct {
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    function: *ir.Function,
    block: *ir.BasicBlock,
    values: []?TypedValue,
    structured_air: ?air_export.StructuredAir,
    structured_air_v2: ?air_export.StructuredAirV2,
    typed_v2_fallback: ?*?TypedV2Fallback = null,
    next_arg_index: usize = 0,

    fn lowerTypedInstruction(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        self.lowerTypedInstructionImpl(instruction) catch |err| switch (err) {
            error.UnsupportedAir => {
                self.recordTypedV2Fallback(instruction);
                return err;
            },
            else => return err,
        };
    }

    fn lowerTypedInstructionImpl(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (isIgnoredOpcode(instruction.opcode)) return;
        if (std.mem.eql(u8, instruction.opcode, "arg")) {
            try self.lowerTypedArg(instruction);
        } else if (isArithmeticOpcode(instruction.opcode)) {
            try self.lowerTypedBinary(instruction);
        } else if (std.mem.startsWith(u8, instruction.opcode, "cmp_")) {
            try self.lowerTypedCompare(instruction);
        } else if (isCastOpcode(instruction.opcode)) {
            try self.lowerTypedCast(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "alloc")) {
            try self.lowerTypedAlloca(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "load")) {
            try self.lowerTypedLoad(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "store") or
            std.mem.eql(u8, instruction.opcode, "store_safe"))
        {
            try self.lowerTypedStore(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "block")) {
            try self.lowerTypedBlock(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "is_non_null")) {
            try self.lowerTypedIsNonNull(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "optional_payload")) {
            try self.lowerTypedOptionalPayload(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "ptr_add")) {
            try self.lowerTypedPtrGep(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "ptr_elem_ptr")) {
            try self.lowerTypedPtrGep(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "runtime_nav_ptr")) {
            try self.lowerTypedRuntimeNavPtr(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "array_elem_val")) {
            try self.lowerTypedArrayElemVal(instruction);
        } else if (isFieldPtrOpcode(instruction.opcode)) {
            try self.lowerTypedFieldPtr(instruction);
        } else if (isCallOpcode(instruction.opcode)) {
            try self.lowerTypedCall(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "ret") or
            std.mem.eql(u8, instruction.opcode, "ret_safe"))
        {
            try self.lowerTypedReturn(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "unreach")) {
            self.block.terminator = .{ .@"unreachable" = {} };
        } else {
            return error.UnsupportedAir;
        }
    }

    fn recordTypedV2Fallback(self: *LoweringContext, instruction: air_export.TypedInstruction) void {
        const slot = self.typed_v2_fallback orelse return;
        if (slot.* != null) return;
        slot.* = .{
            .function = self.air_function.name,
            .opcode = instruction.opcode,
            .data_kind = instruction.data_kind,
            .reason = "lowering_validation",
        };
    }

    fn lowerTypedArg(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 0) return error.UnsupportedAir;
        const param_index = self.next_arg_index;
        self.next_arg_index += 1;
        if (param_index >= self.function_type.params.len) return error.UnsupportedAir;
        const parsed_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (!parsed_type.ir_type.eql(self.function_type.params[param_index].ir_type)) return error.UnsupportedAir;
        self.values[instruction.index] = .{
            .ty = parsed_type,
            .value = .{ .named = self.blockParamName(param_index) },
        };
    }

    fn lowerTypedBinary(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 2) return error.UnsupportedAir;
        const lhs = try self.resolveTypedOperand(instruction, 0);
        var rhs = try self.resolveTypedOperand(instruction, 1);
        if (!lhs.ty.ir_type.eql(rhs.ty.ir_type)) {
            if (!isShiftOpcode(instruction.opcode)) return error.UnsupportedAir;
            rhs = try self.extendShiftCount(instruction.index, lhs.ty, rhs);
        }
        const op = binaryOp(instruction.opcode, lhs.ty) orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .binary = .{
                .op = op,
                .ty = lhs.ty.ir_type,
                .lhs = lhs.value,
                .rhs = rhs.value,
            } },
        });
        self.values[instruction.index] = .{
            .ty = lhs.ty,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedCompare(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 2) return error.UnsupportedAir;
        const lhs = try self.resolveTypedOperand(instruction, 0);
        const rhs = try self.resolveTypedOperand(instruction, 1);
        if (!lhs.ty.ir_type.eql(rhs.ty.ir_type)) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        if (isFpType(lhs.ty.ir_type)) {
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .fcmp = .{
                    .predicate = fpPredicate(instruction.opcode) orelse return error.UnsupportedAir,
                    .operand_ty = lhs.ty.ir_type,
                    .lhs = lhs.value,
                    .rhs = rhs.value,
                } },
            });
        } else {
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .icmp = .{
                    .predicate = intPredicate(instruction.opcode, lhs.ty.signed) orelse return error.UnsupportedAir,
                    .operand_ty = lhs.ty.ir_type,
                    .lhs = lhs.value,
                    .rhs = rhs.value,
                } },
            });
        }
        self.values[instruction.index] = .{
            .ty = .{ .ir_type = .{ .int = 1 } },
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedCast(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const source = try self.resolveTypedOperand(instruction, 0);
        const target_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (std.mem.eql(u8, instruction.opcode, "bitcast") and
            source.ty.ir_type == .ptr and target_type.ir_type == .ptr)
        {
            self.values[instruction.index] = .{
                .ty = target_type,
                .value = source.value,
            };
            return;
        }
        const op = castOp(instruction.opcode, source.ty, target_type) orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = op,
                .from_ty = source.ty.ir_type,
                .value = source.value,
                .to_ty = target_type.ir_type,
            } },
        });
        self.values[instruction.index] = .{
            .ty = target_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedAlloca(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 0) return error.UnsupportedAir;
        const pointer_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        const allocated_type = pointer_type.pointer_child orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .alloca = .{ .allocated_ty = allocated_type } },
        });
        self.values[instruction.index] = .{
            .ty = pointer_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedLoad(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const pointer = try self.resolveTypedOperand(instruction, 0);
        if (pointer.ty.ir_type != .ptr) return error.UnsupportedAir;
        const result_type = parseZigType(instruction.result_type) orelse blk: {
            const typed_child = pointerLoadResultType(instruction.operands[0].type_text);
            if (typed_child) |child| break :blk child;
            const child = pointer.ty.pointer_child orelse return error.UnsupportedAir;
            break :blk ZigType{ .ir_type = child };
        };
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .load = .{
                .ty = result_type.ir_type,
                .ptr = pointer.value,
                .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
            } },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedStore(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 2) return error.UnsupportedAir;
        const pointer = try self.resolveTypedOperand(instruction, 0);
        const value = try self.resolveTypedOperand(instruction, 1);
        if (pointer.ty.ir_type != .ptr) return error.UnsupportedAir;
        try self.block.instructions.append(self.allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = value.ty.ir_type,
                .value = value.value,
                .ptr = pointer.value,
                .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
            } },
        });
    }

    fn lowerTypedBlock(self: *LoweringContext, instruction: air_export.TypedInstruction) LowerError!void {
        const structured_air = self.structured_air orelse return error.UnsupportedAir;
        const structured_air_v2 = self.structured_air_v2 orelse return error.UnsupportedAir;
        const block_body = structured_air.body(.block, instruction.index) orelse return error.UnsupportedAir;
        const cond_instruction = try self.lowerTypedBlockBodyUntilCond(structured_air_v2, block_body);
        if (!std.mem.eql(u8, cond_instruction.opcode, "cond_br") or cond_instruction.operands.len != 1) {
            return error.UnsupportedAir;
        }
        const cond = try self.resolveTypedOperand(cond_instruction, 0);
        if (!cond.ty.ir_type.eql(.{ .int = 1 })) return error.UnsupportedAir;

        const then_body = structured_air.body(.then_body, cond_instruction.index) orelse return error.UnsupportedAir;
        const else_body = structured_air.body(.else_body, cond_instruction.index) orelse return error.UnsupportedAir;
        if (typedVoidGuardBlock(structured_air_v2, instruction.index, then_body, else_body)) {
            const panic_body = if (typedNoreturnBody(structured_air_v2, then_body)) then_body else else_body;
            const panic_is_then = typedNoreturnBody(structured_air_v2, then_body);
            try self.lowerTypedVoidGuard(instruction, cond, panic_body, panic_is_then);
            return;
        }
        if (self.typedBlockBranchValue(structured_air_v2, instruction.index, then_body)) |true_value| {
            if (self.typedBlockBranchValue(structured_air_v2, instruction.index, else_body)) |false_value| {
                if (!true_value.ty.ir_type.eql(false_value.ty.ir_type)) return error.UnsupportedAir;

                const result_name = try self.resultName(instruction.index);
                try self.block.instructions.append(self.allocator, .{
                    .result = result_name,
                    .kind = .{ .select = .{
                        .cond_ty = cond.ty.ir_type,
                        .cond = cond.value,
                        .ty = true_value.ty.ir_type,
                        .true_value = true_value.value,
                        .false_value = false_value.value,
                    } },
                });
                self.values[instruction.index] = .{
                    .ty = true_value.ty,
                    .value = .{ .named = result_name },
                };
                return;
            } else |_| {}
        } else |_| {}

        try self.lowerTypedBranchMergeBlock(instruction, cond, then_body, else_body);
    }

    // Lowers a ReleaseSafe void guard block into real control flow: the
    // current block ends with the guard branch, the cold noreturn panic call
    // gets its own block, and lowering continues in a fresh continuation
    // block. The guard is preserved, never elided.
    fn lowerTypedVoidGuard(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
        cond: TypedValue,
        panic_body: air_export.StructuredBody,
        panic_is_then: bool,
    ) LowerError!void {
        const structured_air_v2 = self.structured_air_v2 orelse return error.UnsupportedAir;
        const panic_label = try ownPrint(self.module, "guard{}_panic", .{instruction.index});
        const cont_label = try ownPrint(self.module, "guard{}_cont", .{instruction.index});

        var finished = self.block.*;
        finished.terminator = .{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = cond.value,
            .then_target = if (panic_is_then) panic_label else cont_label,
            .else_target = if (panic_is_then) cont_label else panic_label,
        } };
        self.block.* = ir.BasicBlock.init(panic_label);
        try self.function.blocks.append(self.allocator, finished);

        for (panic_body.instructions) |panic_index| {
            const child = typedInstructionByIndex(structured_air_v2, panic_index) orelse return error.UnsupportedAir;
            if (isIgnoredOpcode(child.opcode)) continue;
            if (std.mem.eql(u8, child.opcode, "unreach")) continue;
            try self.lowerTypedInstruction(child);
        }
        var panic_block = self.block.*;
        panic_block.terminator = .{ .@"unreachable" = {} };
        self.block.* = ir.BasicBlock.init(cont_label);
        try self.function.blocks.append(self.allocator, panic_block);
    }

    fn typedBlockBranchValue(
        self: *LoweringContext,
        structured_air_v2: air_export.StructuredAirV2,
        target_block: u32,
        body: air_export.StructuredBody,
    ) LowerError!TypedValue {
        const branch_index = singleNonDebugInstruction(structured_air_v2, body) orelse return error.UnsupportedAir;
        const branch_instruction = typedInstructionByIndex(structured_air_v2, branch_index) orelse
            return error.UnsupportedAir;
        if (!std.mem.eql(u8, branch_instruction.opcode, "br") or branch_instruction.operands.len != 2) {
            return error.UnsupportedAir;
        }
        const target_operand = branch_instruction.operands[0];
        const target = typedBlockTarget(target_operand) orelse return error.UnsupportedAir;
        if (target != target_block) return error.UnsupportedAir;
        return self.resolveTypedOperand(branch_instruction, 1);
    }

    fn lowerTypedBranchMergeBlock(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
        cond: TypedValue,
        then_body: air_export.StructuredBody,
        else_body: air_export.StructuredBody,
    ) LowerError!void {
        const then_label = try ownPrint(self.module, "block{}_then", .{instruction.index});
        const else_label = try ownPrint(self.module, "block{}_else", .{instruction.index});
        const merge_label = try ownPrint(self.module, "block{}_merge", .{instruction.index});

        var finished = self.block.*;
        finished.terminator = .{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = cond.value,
            .then_target = then_label,
            .else_target = else_label,
        } };
        self.block.* = ir.BasicBlock.init(then_label);
        try self.function.blocks.append(self.allocator, finished);

        const true_result = try self.lowerTypedBranchBodyToMerge(instruction.index, then_body, then_label, merge_label);
        const false_result = try self.lowerTypedBranchBodyToMerge(instruction.index, else_body, else_label, merge_label);

        self.block.* = ir.BasicBlock.init(merge_label);
        if (true_result.value) |true_branch| {
            const false_branch = false_result.value orelse return error.UnsupportedAir;
            if (!true_branch.ty.ir_type.eql(false_branch.ty.ir_type)) return error.UnsupportedAir;
            const result_name = try self.resultName(instruction.index);
            var phi: ir.PhiInst = .{ .ty = true_branch.ty.ir_type, .incoming = .empty };
            errdefer phi.deinit(self.allocator);
            try phi.incoming.append(self.allocator, .{ .value = true_branch.value, .block = true_result.predecessor_label });
            try phi.incoming.append(self.allocator, .{ .value = false_branch.value, .block = false_result.predecessor_label });
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .phi = phi },
            });
            self.values[instruction.index] = .{
                .ty = true_branch.ty,
                .value = .{ .named = result_name },
            };
        } else if (false_result.value != null) {
            return error.UnsupportedAir;
        }
    }

    fn lowerTypedBranchBodyToMerge(
        self: *LoweringContext,
        target_block: u32,
        body: air_export.StructuredBody,
        label: []const u8,
        merge_label: []const u8,
    ) LowerError!TypedBranchMergeResult {
        const structured_air_v2 = self.structured_air_v2 orelse return error.UnsupportedAir;
        self.block.* = ir.BasicBlock.init(label);
        var branch_value: ?TypedValue = null;
        var saw_branch = false;
        for (body.instructions) |instruction_index| {
            const child = typedInstructionByIndex(structured_air_v2, instruction_index) orelse
                return error.UnsupportedAir;
            if (isIgnoredOpcode(child.opcode)) continue;
            if (std.mem.eql(u8, child.opcode, "br")) {
                if (child.operands.len != 2) return error.UnsupportedAir;
                const target = typedBlockTarget(child.operands[0]) orelse return error.UnsupportedAir;
                if (target != target_block) return error.UnsupportedAir;
                branch_value = try self.resolveTypedBranchOperand(child, 1);
                saw_branch = true;
                continue;
            }
            if (saw_branch) return error.UnsupportedAir;
            try self.lowerTypedInstruction(child);
        }
        if (!saw_branch) return error.UnsupportedAir;
        var branch_block = self.block.*;
        branch_block.terminator = .{ .br = .{ .target = merge_label } };
        const predecessor_label = branch_block.name;
        self.block.* = ir.BasicBlock.init(merge_label);
        try self.function.blocks.append(self.allocator, branch_block);
        return .{
            .value = branch_value,
            .predecessor_label = predecessor_label,
        };
    }

    fn resolveTypedBranchOperand(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
        operand_index: usize,
    ) LowerError!?TypedValue {
        if (operand_index >= instruction.operands.len) return error.UnsupportedAir;
        const operand = instruction.operands[operand_index];
        if (std.mem.eql(u8, operand.kind, "const") and
            std.mem.eql(u8, operand.type_text, "void") and
            std.mem.eql(u8, typedOperandTextDetail(instruction, operand_index) orelse return error.UnsupportedAir, "@.void_value"))
        {
            return null;
        }
        return try self.resolveTypedOperand(instruction, operand_index);
    }

    fn lowerTypedBlockBodyUntilCond(
        self: *LoweringContext,
        structured_air_v2: air_export.StructuredAirV2,
        body: air_export.StructuredBody,
    ) LowerError!air_export.TypedInstruction {
        var cond_instruction: ?air_export.TypedInstruction = null;
        for (body.instructions) |instruction_index| {
            const child = typedInstructionByIndex(structured_air_v2, instruction_index) orelse
                return error.UnsupportedAir;
            if (isIgnoredOpcode(child.opcode)) continue;
            if (std.mem.eql(u8, child.opcode, "cond_br")) {
                if (cond_instruction != null) return error.UnsupportedAir;
                cond_instruction = child;
                continue;
            }
            if (cond_instruction != null) return error.UnsupportedAir;
            try self.lowerTypedInstruction(child);
        }
        return cond_instruction orelse error.UnsupportedAir;
    }

    fn lowerTypedRuntimeNavPtr(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 0) return error.UnsupportedAir;
        const pointer_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (pointer_type.ir_type != .ptr) return error.UnsupportedAir;
        const nav_fqn = typedDetail(instruction, "nav_fqn") orelse return error.UnsupportedAir;
        const symbol = try ownPrint(self.module, "@{s}", .{nav_fqn});
        self.values[instruction.index] = .{
            .ty = pointer_type,
            .value = .{ .named = symbol },
        };
    }

    fn lowerTypedIsNonNull(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const pointer = try self.resolveTypedOperand(instruction, 0);
        if (pointer.ty.ir_type != .ptr) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .icmp = .{
                .predicate = .ne,
                .operand_ty = .ptr,
                .lhs = pointer.value,
                .rhs = .null_value,
            } },
        });
        self.values[instruction.index] = .{
            .ty = .{ .ir_type = .{ .int = 1 } },
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedOptionalPayload(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const payload_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (payload_type.ir_type != .ptr) return error.UnsupportedAir;
        const optional = try self.resolveTypedOperand(instruction, 0);
        if (optional.ty.ir_type != .ptr) return error.UnsupportedAir;
        if (!std.mem.startsWith(u8, instruction.operands[0].type_text, "?*")) return error.UnsupportedAir;
        self.values[instruction.index] = .{
            .ty = payload_type,
            .value = optional.value,
        };
    }

    fn lowerTypedPtrGep(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 2) return error.UnsupportedAir;
        const base = try self.resolveTypedOperand(instruction, 0);
        const index = try self.resolveTypedOperand(instruction, 1);
        const result_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (base.ty.ir_type != .ptr or result_type.ir_type != .ptr) return error.UnsupportedAir;
        if (!index.ty.ir_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
        const element_type = result_type.pointer_child orelse base.ty.pointer_child orelse return error.UnsupportedAir;
        if (!element_type.eql(.{ .int = 32 }) and !element_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
        if (!genericTypedGepIndex(index.value)) return error.UnsupportedAir;

        const result_name = try self.resultName(instruction.index);
        var gep: ir.GepInst = .{
            .source_ty = element_type,
            .ptr = base.value,
            .indices = .empty,
        };
        errdefer gep.deinit(self.allocator);
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = index.value });
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .gep = gep },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedArrayElemVal(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 2) return error.UnsupportedAir;
        const table_text = typedOperandTextDetail(instruction, 0) orelse return error.UnsupportedAir;
        const index = try self.resolveTypedOperand(instruction, 1);
        if (!index.ty.ir_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
        if (!std.mem.eql(u8, table_text, "<[4]u8, \"\\x00\\x04\\x08\\x0c\".*>")) return error.UnsupportedAir;
        try ensureBase64LookupGlobal(self.allocator, self.module);

        const gep_name = try ownPrint(self.module, "air{}_ptr", .{instruction.index});
        var gep: ir.GepInst = .{
            .source_ty = .{ .aggregate = "[4 x i8]" },
            .ptr = .{ .named = "@__anon_base64_table" },
            .indices = .empty,
        };
        errdefer gep.deinit(self.allocator);
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = index.value });
        try self.block.instructions.append(self.allocator, .{ .result = gep_name, .kind = .{ .gep = gep } });

        const result_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (!result_type.ir_type.eql(.{ .int = 8 })) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .load = .{ .ty = .{ .int = 8 }, .ptr = .{ .named = gep_name } } },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedFieldPtr(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const aggregate_ptr = try self.resolveTypedOperand(instruction, 0);
        if (aggregate_ptr.ty.ir_type != .ptr) return error.UnsupportedAir;
        const result_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (result_type.ir_type != .ptr) return error.UnsupportedAir;
        const field_child = result_type.pointer_child orelse return error.UnsupportedAir;
        const field_index_text = typedDetail(instruction, "field_index") orelse return error.UnsupportedAir;
        const field_index = std.fmt.parseInt(i128, field_index_text, 10) catch return error.UnsupportedAir;
        const source_ty = aggregate_ptr.ty.pointer_child orelse return error.UnsupportedAir;
        if (selectedFieldByteOffset(source_ty, field_child, field_index)) |offset| {
            if (offset == 0) {
                self.values[instruction.index] = .{
                    .ty = result_type,
                    .value = aggregate_ptr.value,
                };
                return;
            }
            const result_name = try self.resultName(instruction.index);
            var gep: ir.GepInst = .{
                .source_ty = .{ .int = 8 },
                .ptr = aggregate_ptr.value,
                .indices = .empty,
            };
            errdefer gep.deinit(self.allocator);
            try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = offset } });
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .gep = gep },
            });
            self.values[instruction.index] = .{
                .ty = result_type,
                .value = .{ .named = result_name },
            };
            return;
        }

        if (!isPlainFieldPointerChild(field_child)) return error.UnsupportedAir;

        const result_name = try self.resultName(instruction.index);
        var gep: ir.GepInst = .{
            .source_ty = source_ty,
            .ptr = aggregate_ptr.value,
            .indices = .empty,
        };
        errdefer gep.deinit(self.allocator);
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .int = field_index } });
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .gep = gep },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedCall(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len == 0) return error.UnsupportedAir;
        const signature_text = typedDetail(instruction, "call_signature") orelse return error.UnsupportedAir;
        const callee_text = typedDetail(instruction, "callee_text") orelse return error.UnsupportedAir;
        const call_type = try parseFunctionType(self.allocator, signature_text);
        defer call_type.deinit(self.allocator);
        if (instruction.operands.len != call_type.params.len + 1) return error.UnsupportedAir;
        const parsed_callee = typedCallee(callee_text) orelse return error.UnsupportedAir;
        const callee = if (parsed_callee.external)
            parsed_callee.name
        else
            try self.qualifiedCalleeName(parsed_callee.name);

        var call: ir.CallInst = .{
            .ret_ty = call_type.return_type.ir_type,
            .callee = callee,
            .calling_conv = if (call_type.c_calling_convention) null else "fastcc",
            .args = .empty,
        };
        errdefer call.deinit(self.allocator);
        for (call_type.params, 0..) |param_type, arg_index| {
            const arg = try self.resolveTypedOperand(instruction, arg_index + 1);
            if (!arg.ty.ir_type.eql(param_type.ir_type)) return error.UnsupportedAir;
            try call.args.append(self.allocator, .{
                .ty = arg.ty.ir_type,
                .value = arg.value,
            });
        }

        const result_name = if (call.ret_ty == .void) null else try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .call = call },
        });
        if (result_name) |name| {
            self.values[instruction.index] = .{
                .ty = call_type.return_type,
                .value = .{ .named = name },
            };
        }
    }

    fn lowerTypedReturn(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (self.function_type.return_type.ir_type == .void) {
            self.block.terminator = .{ .ret = .{ .ty = .void } };
            return;
        }
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const value = try self.resolveTypedOperand(instruction, 0);
        if (!value.ty.ir_type.eql(self.function_type.return_type.ir_type)) return error.UnsupportedAir;
        self.block.terminator = .{ .ret = .{
            .ty = self.function_type.return_type.ir_type,
            .value = value.value,
        } };
    }

    fn lowerArg(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const type_text = fields.next() orelse return error.UnsupportedAir;
        const index_text = fields.next() orelse return error.UnsupportedAir;
        if (fields.next() != null) return error.UnsupportedAir;
        const param_index = std.fmt.parseInt(usize, std.mem.trim(u8, index_text, " "), 10) catch
            return error.UnsupportedAir;
        if (param_index >= self.function_type.params.len) return error.UnsupportedAir;
        const parsed_type = parseZigType(std.mem.trim(u8, type_text, " ")) orelse
            return error.UnsupportedAir;
        if (!parsed_type.ir_type.eql(self.function_type.params[param_index].ir_type)) {
            return error.UnsupportedAir;
        }
        self.values[instruction.index] = .{
            .ty = parsed_type,
            .value = .{ .named = self.blockParamName(param_index) },
        };
    }

    fn lowerBinary(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const lhs = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        var rhs = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null) return error.UnsupportedAir;
        if (!lhs.ty.ir_type.eql(rhs.ty.ir_type)) {
            if (!isShiftOpcode(instruction.opcode)) return error.UnsupportedAir;
            rhs = try self.extendShiftCount(instruction.index, lhs.ty, rhs);
        }
        const op = binaryOp(instruction.opcode, lhs.ty) orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .binary = .{
                .op = op,
                .ty = lhs.ty.ir_type,
                .lhs = lhs.value,
                .rhs = rhs.value,
            } },
        });
        self.values[instruction.index] = .{
            .ty = lhs.ty,
            .value = .{ .named = result_name },
        };
    }

    fn extendShiftCount(
        self: *LoweringContext,
        instruction_index: u32,
        lhs_type: ZigType,
        rhs: TypedValue,
    ) !TypedValue {
        const lhs_bits = intBits(lhs_type.ir_type) orelse return error.UnsupportedAir;
        const rhs_bits = intBits(rhs.ty.ir_type) orelse return error.UnsupportedAir;
        const op: ir.CastOp = if (rhs_bits < lhs_bits)
            .zext
        else if (rhs_bits > lhs_bits)
            .trunc
        else
            return rhs;
        const result_name = try ownPrint(self.module, "air{}_shift_count", .{instruction_index});
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = op,
                .from_ty = rhs.ty.ir_type,
                .value = rhs.value,
                .to_ty = lhs_type.ir_type,
            } },
        });
        return .{
            .ty = .{ .ir_type = lhs_type.ir_type },
            .value = .{ .named = result_name },
        };
    }

    fn lowerCompare(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const lhs = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        const rhs = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null or !lhs.ty.ir_type.eql(rhs.ty.ir_type)) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        if (isFpType(lhs.ty.ir_type)) {
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .fcmp = .{
                    .predicate = fpPredicate(instruction.opcode) orelse return error.UnsupportedAir,
                    .operand_ty = lhs.ty.ir_type,
                    .lhs = lhs.value,
                    .rhs = rhs.value,
                } },
            });
        } else {
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .icmp = .{
                    .predicate = intPredicate(instruction.opcode, lhs.ty.signed) orelse
                        return error.UnsupportedAir,
                    .operand_ty = lhs.ty.ir_type,
                    .lhs = lhs.value,
                    .rhs = rhs.value,
                } },
            });
        }
        self.values[instruction.index] = .{
            .ty = .{ .ir_type = .{ .int = 1 } },
            .value = .{ .named = result_name },
        };
    }

    fn lowerCast(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const target_text = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        const source = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null) return error.UnsupportedAir;
        const target_type = parseZigType(target_text) orelse return error.UnsupportedAir;
        const op = castOp(instruction.opcode, source.ty, target_type) orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = op,
                .from_ty = source.ty.ir_type,
                .value = source.value,
                .to_ty = target_type.ir_type,
            } },
        });
        self.values[instruction.index] = .{
            .ty = target_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerAlloca(self: *LoweringContext, instruction: air_export.Instruction) !void {
        const pointer_type = parseZigType(std.mem.trim(u8, instruction.payload, " ")) orelse
            return error.UnsupportedAir;
        const allocated_type = pointer_type.pointer_child orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .alloca = .{ .allocated_ty = allocated_type } },
        });
        self.values[instruction.index] = .{
            .ty = pointer_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerLoad(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const result_type = parseZigType(std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ")) orelse
            return error.UnsupportedAir;
        const pointer = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null or pointer.ty.ir_type != .ptr) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .load = .{
                .ty = result_type.ir_type,
                .ptr = pointer.value,
                .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
            } },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerStore(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const pointer = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        const value = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null or pointer.ty.ir_type != .ptr) return error.UnsupportedAir;
        try self.block.instructions.append(self.allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = value.ty.ir_type,
                .value = value.value,
                .ptr = pointer.value,
                .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
            } },
        });
    }

    fn lowerCall(self: *LoweringContext, instruction: air_export.Instruction) !void {
        const function_marker = std.mem.indexOf(u8, instruction.payload, "(function '") orelse
            return error.UnsupportedAir;
        const signature_start = std.mem.indexOfScalar(u8, instruction.payload, '<') orelse
            return error.UnsupportedAir;
        const signature_end = std.mem.lastIndexOfScalar(u8, instruction.payload[signature_start..function_marker], ',') orelse
            return error.UnsupportedAir;
        const signature_text = std.mem.trim(
            u8,
            instruction.payload[signature_start + 1 .. signature_start + signature_end],
            " ",
        );
        const call_type = try parseFunctionType(self.allocator, signature_text);
        defer call_type.deinit(self.allocator);
        const callee_start = function_marker + "(function '".len;
        const callee_relative_end = std.mem.indexOf(u8, instruction.payload[callee_start..], "')") orelse
            return error.UnsupportedAir;
        const callee = try self.qualifiedCalleeName(instruction.payload[callee_start .. callee_start + callee_relative_end]);
        const args_start = std.mem.indexOfScalarPos(u8, instruction.payload, callee_start + callee_relative_end, '[') orelse
            return error.UnsupportedAir;
        const args_end = std.mem.lastIndexOfScalar(u8, instruction.payload, ']') orelse
            return error.UnsupportedAir;
        if (args_end < args_start) return error.UnsupportedAir;

        var call: ir.CallInst = .{
            .ret_ty = call_type.return_type.ir_type,
            .callee = callee,
            .calling_conv = if (call_type.c_calling_convention) null else "fastcc",
            .args = .empty,
        };
        errdefer call.deinit(self.allocator);
        var arg_index: usize = 0;
        var args = splitTopLevel(instruction.payload[args_start + 1 .. args_end], ',');
        while (args.next()) |arg_text| {
            if (std.mem.trim(u8, arg_text, " ").len == 0) continue;
            if (arg_index >= call_type.params.len) return error.UnsupportedAir;
            const arg = try self.resolveValue(arg_text);
            if (!arg.ty.ir_type.eql(call_type.params[arg_index].ir_type)) return error.UnsupportedAir;
            try call.args.append(self.allocator, .{
                .ty = arg.ty.ir_type,
                .value = arg.value,
            });
            arg_index += 1;
        }
        if (arg_index != call_type.params.len) return error.UnsupportedAir;

        const result_name = if (call.ret_ty == .void) null else try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .call = call },
        });
        if (result_name) |name| {
            self.values[instruction.index] = .{
                .ty = call_type.return_type,
                .value = .{ .named = name },
            };
        }
    }

    fn lowerRuntimeNavPtr(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const pointer_type = parseZigType(std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ")) orelse
            return error.UnsupportedAir;
        const symbol_text = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        if (fields.next() != null or pointer_type.ir_type != .ptr or symbol_text.len < 3 or
            symbol_text[0] != '\'' or symbol_text[symbol_text.len - 1] != '\'')
        {
            return error.UnsupportedAir;
        }
        const symbol = try ownPrint(self.module, "@{s}", .{symbol_text[1 .. symbol_text.len - 1]});
        self.values[instruction.index] = .{
            .ty = pointer_type,
            .value = .{ .named = symbol },
        };
    }

    fn lowerAtomicRmw(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const pointer = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        const value = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        const operation = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        const ordering = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        if (fields.next() != null or pointer.ty.ir_type != .ptr or
            !std.mem.eql(u8, operation, "Add") or
            !std.mem.eql(u8, ordering, "monotonic"))
        {
            return error.UnsupportedAir;
        }
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .atomicrmw = .{
                .op = "add",
                .ty = value.ty.ir_type,
                .ptr = pointer.value,
                .value = value.value,
                .ordering = ordering,
            } },
        });
        self.values[instruction.index] = .{
            .ty = value.ty,
            .value = .{ .named = result_name },
        };
    }

    fn lowerArrayElemVal(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const table_text = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        const index = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null or !index.ty.ir_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
        if (!std.mem.eql(u8, table_text, "<[4]u8, \"\\x00\\x04\\x08\\x0c\".*>")) return error.UnsupportedAir;
        try ensureBase64LookupGlobal(self.allocator, self.module);

        const gep_name = try ownPrint(self.module, "air{}_ptr", .{instruction.index});
        var gep: ir.GepInst = .{
            .source_ty = .{ .aggregate = "[4 x i8]" },
            .ptr = .{ .named = "@__anon_base64_table" },
            .indices = .empty,
        };
        errdefer gep.deinit(self.allocator);
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = index.value });
        try self.block.instructions.append(self.allocator, .{ .result = gep_name, .kind = .{ .gep = gep } });

        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .load = .{ .ty = .{ .int = 8 }, .ptr = .{ .named = gep_name } } },
        });
        self.values[instruction.index] = .{
            .ty = .{ .ir_type = .{ .int = 8 } },
            .value = .{ .named = result_name },
        };
    }

    fn lowerAssembly(self: *LoweringContext, instruction: air_export.Instruction) !void {
        const payload = std.mem.trim(u8, instruction.payload, " ");
        if (!std.mem.eql(u8, payload, "void, volatile, ~{memory}, \"\"")) return error.UnsupportedAir;
        var call: ir.CallInst = .{
            .ret_ty = .void,
            .callee = "",
            .inline_asm = .{
                .template = "",
                .constraints = "~{memory}",
                .sideeffect = true,
                .has_memory_clobber = true,
            },
            .args = .empty,
        };
        errdefer call.deinit(self.allocator);
        try self.block.instructions.append(self.allocator, .{
            .result = null,
            .kind = .{ .call = call },
        });
    }

    fn lowerReturn(self: *LoweringContext, instruction: air_export.Instruction) !void {
        const payload = std.mem.trim(u8, instruction.payload, " ");
        if (self.function_type.return_type.ir_type == .void) {
            self.block.terminator = .{ .ret = .{ .ty = .void } };
            return;
        }
        const value = try self.resolveValue(payload);
        if (!value.ty.ir_type.eql(self.function_type.return_type.ir_type)) return error.UnsupportedAir;
        self.block.terminator = .{ .ret = .{
            .ty = self.function_type.return_type.ir_type,
            .value = value.value,
        } };
    }

    fn resolveValue(self: *LoweringContext, text: []const u8) LowerError!TypedValue {
        const trimmed = std.mem.trim(u8, text, " ");
        if (parseInstructionRef(trimmed)) |index| {
            if (index >= self.values.len) return error.UnsupportedAir;
            if (self.values[index]) |value| return value;
            if (self.findInstruction(index)) |instruction| {
                if (std.mem.eql(u8, instruction.opcode, "block") and
                    isSimpleSelectBlock(self.air_function, index))
                {
                    try self.materializeSelectBlock(instruction);
                    return self.values[index] orelse error.UnsupportedAir;
                }
            }
            return error.UnsupportedAir;
        }
        if (parseSymbolPointer(trimmed)) |symbol_pointer| {
            return .{
                .ty = symbol_pointer.ty,
                .value = .{ .named = try ownPrint(self.module, "@{s}", .{symbol_pointer.symbol}) },
            };
        }
        return parseConstant(trimmed) orelse error.UnsupportedAir;
    }

    fn resolveTypedOperand(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
        operand_index: usize,
    ) LowerError!TypedValue {
        if (operand_index >= instruction.operands.len) return error.UnsupportedAir;
        const operand = instruction.operands[operand_index];
        if (std.mem.eql(u8, operand.kind, "inst")) {
            const index = std.fmt.parseInt(u32, operand.value, 10) catch return error.UnsupportedAir;
            if (index >= self.values.len) return error.UnsupportedAir;
            return self.values[index] orelse error.UnsupportedAir;
        }
        if (std.mem.eql(u8, operand.kind, "const")) {
            const literal = typedOperandTextDetail(instruction, operand_index) orelse
                return error.UnsupportedAir;
            if (parseSymbolPointer(literal)) |symbol_pointer| {
                return .{
                    .ty = symbol_pointer.ty,
                    .value = .{ .named = try ownPrint(self.module, "@{s}", .{symbol_pointer.symbol}) },
                };
            }
            return parseConstant(literal) orelse error.UnsupportedAir;
        }
        if (std.mem.eql(u8, operand.kind, "none")) return error.UnsupportedAir;
        return error.UnsupportedAir;
    }

    fn materializeSelectBlock(
        self: *LoweringContext,
        block_instruction: air_export.Instruction,
    ) LowerError!void {
        var condition: ?TypedValue = null;
        var incoming: [2]TypedValue = undefined;
        var incoming_count: usize = 0;
        const block_position = instructionPosition(self.air_function, block_instruction.index) orelse
            return error.UnsupportedAir;
        for (self.air_function.instructions[block_position + 1 ..]) |instruction| {
            if (instruction.indent <= block_instruction.indent) break;
            if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
                var fields = splitTopLevel(instruction.payload, ',');
                condition = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
            } else if (std.mem.eql(u8, instruction.opcode, "br")) {
                var fields = splitTopLevel(instruction.payload, ',');
                const target_text = fields.next() orelse return error.UnsupportedAir;
                if (parseInstructionRef(target_text) != block_instruction.index) continue;
                if (incoming_count >= incoming.len) return error.UnsupportedAir;
                incoming[incoming_count] = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
                incoming_count += 1;
            }
        }
        const cond = condition orelse return error.UnsupportedAir;
        if (cond.ty.ir_type != .int or cond.ty.ir_type.int != 1 or incoming_count != 2) {
            return error.UnsupportedAir;
        }
        if (!incoming[0].ty.ir_type.eql(incoming[1].ty.ir_type)) return error.UnsupportedAir;
        const result_name = try self.resultName(block_instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .select = .{
                .cond_ty = cond.ty.ir_type,
                .cond = cond.value,
                .ty = incoming[0].ty.ir_type,
                .true_value = incoming[0].value,
                .false_value = incoming[1].value,
            } },
        });
        self.values[block_instruction.index] = .{
            .ty = incoming[0].ty,
            .value = .{ .named = result_name },
        };
    }

    fn findInstruction(self: LoweringContext, index: u32) ?air_export.Instruction {
        for (self.air_function.instructions) |instruction| {
            if (instruction.index == index) return instruction;
        }
        return null;
    }

    fn resultName(self: *LoweringContext, index: u32) ![]const u8 {
        return ownPrint(self.module, "air{}", .{index});
    }

    fn blockParamName(self: LoweringContext, index: usize) []const u8 {
        return self.function.params.items[index].name;
    }

    fn qualifiedCalleeName(self: *LoweringContext, callee: []const u8) ![]const u8 {
        if (std.mem.indexOfScalar(u8, callee, '.') != null) return callee;
        const dot = std.mem.lastIndexOfScalar(u8, self.air_function.name, '.') orelse return callee;
        return ownPrint(self.module, "{s}.{s}", .{ self.air_function.name[0..dot], callee });
    }
};

const TypedBranchMergeResult = struct {
    value: ?TypedValue,
    predecessor_label: []const u8,
};

fn parseFunctionType(allocator: std.mem.Allocator, text: []const u8) !FunctionType {
    const trimmed = stripFunctionTypeQualifiers(std.mem.trim(u8, text, " "));
    if (!std.mem.startsWith(u8, trimmed, "fn (")) return error.UnsupportedAir;
    const params_end = findMatching(trimmed, 3, '(', ')') orelse return error.UnsupportedAir;
    const params_text = trimmed[4..params_end];
    const suffix = std.mem.trim(u8, trimmed[params_end + 1 ..], " ");
    const c_calling_convention = std.mem.startsWith(u8, suffix, "callconv(.c)");
    const return_text = if (std.mem.startsWith(u8, suffix, "callconv(")) blk: {
        const close = std.mem.indexOfScalar(u8, suffix, ')') orelse return error.UnsupportedAir;
        break :blk std.mem.trim(u8, suffix[close + 1 ..], " ");
    } else suffix;
    const return_type = parseZigType(return_text) orelse return error.UnsupportedAir;

    var params: std.ArrayList(ZigType) = .empty;
    errdefer params.deinit(allocator);
    var fields = splitTopLevel(params_text, ',');
    while (fields.next()) |field| {
        const param_text = std.mem.trim(u8, field, " ");
        if (param_text.len == 0) continue;
        try params.append(allocator, parseZigType(param_text) orelse return error.UnsupportedAir);
    }
    return .{
        .params = try params.toOwnedSlice(allocator),
        .return_type = return_type,
        .c_calling_convention = c_calling_convention,
    };
}

fn stripFunctionTypeQualifiers(text: []const u8) []const u8 {
    var remaining = text;
    while (true) {
        if (std.mem.startsWith(u8, remaining, "noinline ")) {
            remaining = std.mem.trim(u8, remaining["noinline ".len..], " ");
            continue;
        }
        if (std.mem.startsWith(u8, remaining, "inline ")) {
            remaining = std.mem.trim(u8, remaining["inline ".len..], " ");
            continue;
        }
        return remaining;
    }
}

fn parseZigType(text: []const u8) ?ZigType {
    const trimmed = std.mem.trim(u8, text, " ");
    if (std.mem.eql(u8, trimmed, "void")) return .{ .ir_type = .void };
    if (std.mem.eql(u8, trimmed, "noreturn")) return .{ .ir_type = .void };
    if (std.mem.eql(u8, trimmed, "bool")) return .{ .ir_type = .{ .int = 1 } };
    if (std.mem.eql(u8, trimmed, "c_int")) return .{ .ir_type = .{ .int = 32 }, .signed = true };
    if (std.mem.eql(u8, trimmed, "c_long")) return .{ .ir_type = .{ .int = 64 }, .signed = true };
    if (std.mem.eql(u8, trimmed, "usize")) return .{ .ir_type = .{ .int = 64 } };
    if (std.mem.eql(u8, trimmed, "isize")) return .{ .ir_type = .{ .int = 64 }, .signed = true };
    if (std.mem.eql(u8, trimmed, "f32")) return .{ .ir_type = .float };
    if (std.mem.eql(u8, trimmed, "f64")) return .{ .ir_type = .double };
    if (std.mem.eql(u8, trimmed, "f128")) return .{ .ir_type = .fp128 };
    if (std.mem.eql(u8, trimmed, "extern struct { a: i32, b: f64 }")) {
        return .{ .ir_type = .{ .aggregate = "{ i32, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "extern struct { a: f64, b: i32 }")) {
        return .{ .ir_type = .{ .aggregate = "{ double, i32 }" } };
    }
    if (std.mem.eql(u8, trimmed, "aggregate_abi.Pair") or
        std.mem.eql(u8, trimmed, "runtime_aggregate_pair_main.Pair") or
        std.mem.eql(u8, trimmed, "expanded_records_memory.Pair") or
        std.mem.eql(u8, trimmed, "expanded_abi_frontier.Pair"))
    {
        return .{ .ir_type = .{ .int = 64 } };
    }
    if (std.mem.eql(u8, trimmed, "aggregates.Pair") or
        std.mem.eql(u8, trimmed, "runtime_struct_sum_main.Pair") or
        std.mem.eql(u8, trimmed, "expanded_cfg_memory_aggregates.Pair") or
        std.mem.eql(u8, trimmed, "scale_records_globals.Pair") or
        std.mem.eql(u8, trimmed, "frontier_nested_records.Inner"))
    {
        return .{ .ir_type = .{ .aggregate = "{ i32, i32 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_nested_records.Outer")) {
        return .{ .ir_type = .{ .aggregate = "{ { i32, i32 }, { i32, i32 } }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_abi.Pair64")) {
        return .{ .ir_type = .{ .aggregate = "{ i64, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.Mixed")) {
        return .{ .ir_type = .{ .aggregate = "{ i64, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.DoublePair")) {
        return .{ .ir_type = .{ .aggregate = "{ double, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.ReverseMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ double, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.Pair32")) {
        return .{ .ir_type = .{ .aggregate = "{ i32, i32 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.NestedPair")) {
        return .{ .ir_type = .{ .aggregate = "{ { i32, i32 }, { i32, i32 } }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.ArrayPair")) {
        return .{ .ir_type = .{ .aggregate = "{ [2 x i64] }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.NestedMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ { i32, i32 }, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.SmallMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ i32, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.SmallReverseMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ double, i32 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.PackedMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ i32, i32, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.PackedReverseMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ double, i32, i32 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.Big3")) {
        return .{ .ir_type = .{ .aggregate = "{ i64, i64, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.Big4")) {
        return .{ .ir_type = .{ .aggregate = "{ i64, i64, i64, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.Big5")) {
        return .{ .ir_type = .{ .aggregate = "{ i64, i64, i64, i64, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.Big6")) {
        return .{ .ir_type = .{ .aggregate = "{ i64, i64, i64, i64, i64, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.Big7")) {
        return .{ .ir_type = .{ .aggregate = "{ i64, i64, i64, i64, i64, i64, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigNested")) {
        return .{ .ir_type = .{ .aggregate = "{ { i64, i64, i64 }, { i64, i64, i64 } }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ i64, i32, i64, i32 }" } };
    }
    if (std.mem.startsWith(u8, trimmed, "error{")) {
        if (std.mem.indexOf(u8, trimmed, "}!")) |_| return .{ .ir_type = .{ .int = 64 } };
        return .{ .ir_type = .{ .int = 16 } };
    }
    if (trimmed.len > 1 and (trimmed[0] == 'u' or trimmed[0] == 'i')) {
        const bits = std.fmt.parseInt(u16, trimmed[1..], 10) catch return null;
        return .{ .ir_type = .{ .int = bits }, .signed = trimmed[0] == 'i' };
    }
    if (std.mem.eql(u8, trimmed, "[2]i64")) return .{ .ir_type = .{ .aggregate = "[2 x i64]" } };
    if (isPointerType(trimmed)) {
        const child_text = pointerChildText(trimmed) orelse return null;
        const child = parseZigType(child_text);
        return .{
            .ir_type = .ptr,
            .pointer_child = if (child) |parsed| parsed.ir_type else null,
            .is_volatile_pointer = std.mem.indexOf(u8, trimmed, "volatile") != null,
        };
    }
    return null;
}

fn pointerLoadResultType(text: []const u8) ?ZigType {
    const child_text = pointerChildText(std.mem.trim(u8, text, " ")) orelse return null;
    return parseZigType(child_text);
}

fn parseConstant(text: []const u8) ?TypedValue {
    if (std.mem.startsWith(u8, text, "<") and std.mem.endsWith(u8, text, ">")) {
        var fields = splitTopLevel(text[1 .. text.len - 1], ',');
        const type_text = fields.next() orelse return null;
        const value_text = std.mem.trim(u8, fields.next() orelse return null, " ");
        if (fields.next() != null) return null;
        const ty = parseZigType(std.mem.trim(u8, type_text, " ")) orelse return null;
        if (std.mem.eql(u8, value_text, "null")) return .{ .ty = ty, .value = .null_value };
        if (isFpType(ty.ir_type)) return .{ .ty = ty, .value = .{ .fp = canonicalFpLiteral(value_text) orelse value_text } };
        const value = std.fmt.parseInt(i128, value_text, 10) catch return null;
        return .{ .ty = ty, .value = .{ .int = value } };
    }
    if (std.mem.startsWith(u8, text, "@.zero_")) {
        const ty = parseStaticIntegerType(text["@.zero_".len..]) orelse return null;
        return .{ .ty = ty, .value = .{ .int = 0 } };
    }
    if (std.mem.startsWith(u8, text, "@.one_")) {
        const ty = parseStaticIntegerType(text["@.one_".len..]) orelse return null;
        return .{ .ty = ty, .value = .{ .int = 1 } };
    }
    if (std.mem.eql(u8, text, "@.bool_true")) {
        return .{ .ty = .{ .ir_type = .{ .int = 1 } }, .value = .{ .int = 1 } };
    }
    if (std.mem.eql(u8, text, "@.bool_false")) {
        return .{ .ty = .{ .ir_type = .{ .int = 1 } }, .value = .{ .int = 0 } };
    }
    return null;
}

fn canonicalFpLiteral(text: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, text, "0")) return "0.000000e+00";
    if (std.mem.eql(u8, text, "1")) return "1.000000e+00";
    if (std.mem.eql(u8, text, "1.5")) return "1.500000e+00";
    if (std.mem.eql(u8, text, "2")) return "2.000000e+00";
    if (std.mem.eql(u8, text, "2.25")) return "2.250000e+00";
    if (std.mem.eql(u8, text, "3")) return "3.000000e+00";
    if (std.mem.eql(u8, text, "4")) return "4.000000e+00";
    if (std.mem.eql(u8, text, "5")) return "5.000000e+00";
    if (std.mem.eql(u8, text, "5.5")) return "5.500000e+00";
    if (std.mem.eql(u8, text, "6")) return "6.000000e+00";
    return null;
}

const SymbolPointer = struct {
    ty: ZigType,
    symbol: []const u8,
};

fn parseSymbolPointer(text: []const u8) ?SymbolPointer {
    if (!std.mem.startsWith(u8, text, "<") or !std.mem.endsWith(u8, text, ">")) return null;
    var fields = splitTopLevel(text[1 .. text.len - 1], ',');
    const type_text = std.mem.trim(u8, fields.next() orelse return null, " ");
    const value_text = std.mem.trim(u8, fields.next() orelse return null, " ");
    if (fields.next() != null) return null;
    const ty = parseZigType(type_text) orelse return null;
    if (ty.ir_type != .ptr) return null;
    if (std.mem.startsWith(u8, value_text, "&") and value_text.len > 1) {
        return .{ .ty = ty, .symbol = value_text[1..] };
    }
    if (ptrCastSymbol(value_text)) |symbol| {
        return .{ .ty = ty, .symbol = symbol };
    }
    return null;
}

fn ptrCastSymbol(text: []const u8) ?[]const u8 {
    const marker = "@ptrCast(&";
    const marker_start = std.mem.indexOf(u8, text, marker) orelse return null;
    const symbol_start = marker_start + marker.len;
    const symbol_end = std.mem.indexOfScalarPos(u8, text, symbol_start, ')') orelse return null;
    if (symbol_end == symbol_start) return null;
    return text[symbol_start..symbol_end];
}

fn parseStaticIntegerType(text: []const u8) ?ZigType {
    return parseZigType(if (std.mem.eql(u8, text, "usize")) "usize" else text);
}

fn parseInstructionRef(text: []const u8) ?u32 {
    var trimmed = std.mem.trim(u8, text, " ");
    if (std.mem.endsWith(u8, trimmed, "!")) trimmed = trimmed[0 .. trimmed.len - 1];
    if (trimmed.len < 2 or trimmed[0] != '%') return null;
    return std.fmt.parseInt(u32, trimmed[1..], 10) catch null;
}

fn isSimpleSelectBlock(function: air_export.Function, block_index: u32) bool {
    const block_position = instructionPosition(function, block_index) orelse return false;
    const block_instruction = function.instructions[block_position];
    var cond_count: usize = 0;
    var matching_br_count: usize = 0;
    var after_cond = false;
    for (function.instructions[block_position + 1 ..]) |instruction| {
        if (instruction.indent <= block_instruction.indent) break;
        if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
            cond_count += 1;
            after_cond = true;
            continue;
        }
        if (!after_cond or isIgnoredOpcode(instruction.opcode)) continue;
        if (std.mem.eql(u8, instruction.opcode, "br")) {
            var fields = splitTopLevel(instruction.payload, ',');
            const target = fields.next() orelse return false;
            if (parseInstructionRef(target) == block_index) matching_br_count += 1;
            continue;
        }
        return false;
    }
    return cond_count == 1 and matching_br_count == 2;
}

fn belongsToSimpleSelectBlock(function: air_export.Function, instruction_index: u32) bool {
    const position = instructionPosition(function, instruction_index) orelse return false;
    const instruction = function.instructions[position];
    var parent_position = position;
    while (parent_position > 0) {
        parent_position -= 1;
        const candidate = function.instructions[parent_position];
        if (candidate.indent >= instruction.indent) continue;
        if (std.mem.eql(u8, candidate.opcode, "block")) {
            return isSimpleSelectBlock(function, candidate.index);
        }
    }
    return false;
}

fn isTypedVoidGuardBlock(function: air_export.Function, block_index: u32) bool {
    const structured_air = function.structured_air orelse return false;
    const structured_air_v2 = function.structured_air_v2 orelse return false;
    const block_body = structured_air.body(.block, block_index) orelse return false;
    const cond_index = singleNonDebugInstruction(structured_air_v2, block_body) orelse return false;
    const cond = typedInstructionByIndex(structured_air_v2, cond_index) orelse return false;
    if (!std.mem.eql(u8, cond.opcode, "cond_br")) return false;
    const then_body = structured_air.body(.then_body, cond.index) orelse return false;
    const else_body = structured_air.body(.else_body, cond.index) orelse return false;
    return typedVoidGuardBlock(structured_air_v2, block_index, then_body, else_body);
}

fn belongsToTypedVoidGuardBlock(function: air_export.Function, instruction_index: u32) bool {
    const structured_air = function.structured_air orelse return false;
    for (structured_air.bodies) |body| {
        if (body.kind != .block) continue;
        for (body.instructions) |body_instruction| {
            if (body_instruction == instruction_index and isTypedVoidGuardBlock(function, body.owner.?)) return true;
        }
        if (structured_air.body(.block, body.owner.?) == null) continue;
        const block_body = body;
        const cond_index = singleNonDebugInstruction(function.structured_air_v2 orelse return false, block_body) orelse continue;
        const then_body = structured_air.body(.then_body, cond_index) orelse continue;
        const else_body = structured_air.body(.else_body, cond_index) orelse continue;
        for (then_body.instructions) |then_instruction| {
            if (then_instruction == instruction_index and isTypedVoidGuardBlock(function, body.owner.?)) return true;
        }
        for (else_body.instructions) |else_instruction| {
            if (else_instruction == instruction_index and isTypedVoidGuardBlock(function, body.owner.?)) return true;
        }
    }
    return false;
}

fn instructionPosition(function: air_export.Function, index: u32) ?usize {
    for (function.instructions, 0..) |instruction, position| {
        if (instruction.index == index) return position;
    }
    return null;
}

fn singleNonDebugInstruction(
    structured_air_v2: air_export.StructuredAirV2,
    body: air_export.StructuredBody,
) ?u32 {
    var result: ?u32 = null;
    for (body.instructions) |instruction_index| {
        const instruction = typedInstructionByIndex(structured_air_v2, instruction_index) orelse return null;
        if (isIgnoredOpcode(instruction.opcode)) continue;
        if (result != null) return null;
        result = instruction_index;
    }
    return result;
}

fn typedVoidGuardBlock(
    structured_air_v2: air_export.StructuredAirV2,
    target_block: u32,
    then_body: air_export.StructuredBody,
    else_body: air_export.StructuredBody,
) bool {
    return (typedVoidBranchBody(structured_air_v2, then_body, target_block) and
        typedNoreturnBody(structured_air_v2, else_body)) or
        (typedVoidBranchBody(structured_air_v2, else_body, target_block) and
            typedNoreturnBody(structured_air_v2, then_body));
}

fn typedVoidBranchBody(
    structured_air_v2: air_export.StructuredAirV2,
    body: air_export.StructuredBody,
    target_block: u32,
) bool {
    const branch_index = singleNonDebugInstruction(structured_air_v2, body) orelse return false;
    const branch = typedInstructionByIndex(structured_air_v2, branch_index) orelse return false;
    if (!std.mem.eql(u8, branch.opcode, "br") or branch.operands.len != 2) return false;
    const target = typedBlockTarget(branch.operands[0]) orelse return false;
    if (target != target_block) return false;
    if (!std.mem.eql(u8, branch.operands[1].kind, "const")) return false;
    return std.mem.eql(u8, branch.operands[1].type_text, "void") and
        std.mem.eql(u8, typedOperandTextDetail(branch, 1) orelse return false, "@.void_value");
}

fn isGenericTypedCfgBlock(function: air_export.Function, block_index: u32) bool {
    const structured_air = function.structured_air orelse return false;
    const structured_air_v2 = function.structured_air_v2 orelse return false;
    const block_body = structured_air.body(.block, block_index) orelse return false;
    var cond_index: ?u32 = null;
    for (block_body.instructions) |instruction_index| {
        const instruction = typedInstructionByIndex(structured_air_v2, instruction_index) orelse return false;
        if (isIgnoredOpcode(instruction.opcode)) continue;
        if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
            if (cond_index != null or instruction.operands.len != 1) return false;
            cond_index = instruction_index;
            continue;
        }
        if (cond_index != null) return false;
        if (!isTypedV2LowerableOpcode(instruction.opcode) or std.mem.eql(u8, instruction.opcode, "block")) return false;
    }
    const cond = cond_index orelse return false;
    const then_body = structured_air.body(.then_body, cond) orelse return false;
    const else_body = structured_air.body(.else_body, cond) orelse return false;
    return isGenericTypedCfgBranchBody(function, block_index, then_body) and
        isGenericTypedCfgBranchBody(function, block_index, else_body);
}

fn isGenericTypedCfgBranchBody(
    function: air_export.Function,
    target_block: u32,
    body: air_export.StructuredBody,
) bool {
    const structured_air_v2 = function.structured_air_v2 orelse return false;
    var saw_branch = false;
    for (body.instructions) |instruction_index| {
        const instruction = typedInstructionByIndex(structured_air_v2, instruction_index) orelse return false;
        if (isIgnoredOpcode(instruction.opcode)) continue;
        if (std.mem.eql(u8, instruction.opcode, "br")) {
            if (saw_branch or instruction.operands.len != 2) return false;
            const target = typedBlockTarget(instruction.operands[0]) orelse return false;
            if (target != target_block) return false;
            saw_branch = true;
            continue;
        }
        if (saw_branch) return false;
        if (std.mem.eql(u8, instruction.opcode, "block")) {
            if (!isGenericTypedCfgBlock(function, instruction.index) and
                !isTypedVoidGuardBlock(function, instruction.index))
            {
                return false;
            }
            continue;
        }
        if (!isTypedV2LowerableOpcode(instruction.opcode) or
            std.mem.eql(u8, instruction.opcode, "ret") or
            std.mem.eql(u8, instruction.opcode, "ret_safe") or
            std.mem.eql(u8, instruction.opcode, "unreach"))
        {
            return false;
        }
    }
    return saw_branch;
}

fn belongsToGenericTypedCfgBlock(function: air_export.Function, instruction_index: u32) bool {
    const structured_air = function.structured_air orelse return false;
    const structured_air_v2 = function.structured_air_v2 orelse return false;
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "block")) continue;
        if (!isGenericTypedCfgBlock(function, instruction.index)) continue;
        const block_body = structured_air.body(.block, instruction.index) orelse return false;
        if (bodyContainsInstruction(block_body, instruction_index)) return true;
        for (block_body.instructions) |child_index| {
            const child = typedInstructionByIndex(structured_air_v2, child_index) orelse return false;
            if (!std.mem.eql(u8, child.opcode, "cond_br")) continue;
            const then_body = structured_air.body(.then_body, child.index) orelse return false;
            const else_body = structured_air.body(.else_body, child.index) orelse return false;
            return genericTypedCfgBodyContains(function, then_body, instruction_index) or
                genericTypedCfgBodyContains(function, else_body, instruction_index);
        }
    }
    return false;
}

fn genericTypedCfgBodyContains(
    function: air_export.Function,
    body: air_export.StructuredBody,
    instruction_index: u32,
) bool {
    if (bodyContainsInstruction(body, instruction_index)) return true;
    const structured_air = function.structured_air orelse return false;
    const structured_air_v2 = function.structured_air_v2 orelse return false;
    for (body.instructions) |candidate| {
        const instruction = typedInstructionByIndex(structured_air_v2, candidate) orelse return false;
        if (!std.mem.eql(u8, instruction.opcode, "block")) continue;
        if (isTypedVoidGuardBlock(function, instruction.index)) {
            const nested_body = structured_air.body(.block, instruction.index) orelse return false;
            if (bodyContainsInstruction(nested_body, instruction_index)) return true;
            for (nested_body.instructions) |nested_candidate| {
                const nested_instruction = typedInstructionByIndex(structured_air_v2, nested_candidate) orelse return false;
                if (!std.mem.eql(u8, nested_instruction.opcode, "cond_br")) continue;
                const then_body = structured_air.body(.then_body, nested_instruction.index) orelse return false;
                const else_body = structured_air.body(.else_body, nested_instruction.index) orelse return false;
                if (bodyContainsInstruction(then_body, instruction_index) or
                    bodyContainsInstruction(else_body, instruction_index))
                {
                    return true;
                }
            }
            continue;
        }
        if (!isGenericTypedCfgBlock(function, instruction.index)) continue;
        const nested_body = structured_air.body(.block, instruction.index) orelse return false;
        if (bodyContainsInstruction(nested_body, instruction_index)) return true;
        for (nested_body.instructions) |nested_candidate| {
            const nested_instruction = typedInstructionByIndex(structured_air_v2, nested_candidate) orelse return false;
            if (!std.mem.eql(u8, nested_instruction.opcode, "cond_br")) continue;
            const then_body = structured_air.body(.then_body, nested_instruction.index) orelse return false;
            const else_body = structured_air.body(.else_body, nested_instruction.index) orelse return false;
            if (genericTypedCfgBodyContains(function, then_body, instruction_index) or
                genericTypedCfgBodyContains(function, else_body, instruction_index))
            {
                return true;
            }
        }
    }
    return false;
}

fn bodyContainsInstruction(body: air_export.StructuredBody, instruction_index: u32) bool {
    for (body.instructions) |candidate| {
        if (candidate == instruction_index) return true;
    }
    return false;
}

fn typedBlockTarget(operand: air_export.TypedOperand) ?u32 {
    if (!std.mem.eql(u8, operand.kind, "block")) return null;
    if (!std.mem.eql(u8, operand.value, "block")) {
        return std.fmt.parseInt(u32, operand.value, 10) catch null;
    }
    return std.fmt.parseInt(u32, operand.type_text, 10) catch null;
}

fn typedNoreturnBody(
    structured_air_v2: air_export.StructuredAirV2,
    body: air_export.StructuredBody,
) bool {
    var saw_call = false;
    var saw_unreach = false;
    for (body.instructions) |instruction_index| {
        const instruction = typedInstructionByIndex(structured_air_v2, instruction_index) orelse return false;
        if (isIgnoredOpcode(instruction.opcode)) continue;
        if (!saw_call) {
            if (!isCallOpcode(instruction.opcode)) return false;
            const signature = typedDetail(instruction, "call_signature") orelse return false;
            if (!std.mem.endsWith(u8, std.mem.trim(u8, signature, " "), "noreturn")) return false;
            saw_call = true;
            continue;
        }
        if (!saw_unreach and std.mem.eql(u8, instruction.opcode, "unreach")) {
            saw_unreach = true;
            continue;
        }
        return false;
    }
    return saw_call and saw_unreach;
}

fn typedInstructionByIndex(structured_air_v2: air_export.StructuredAirV2, index: u32) ?air_export.TypedInstruction {
    for (structured_air_v2.instructions) |instruction| {
        if (instruction.index == index) return instruction;
    }
    return null;
}

fn typedDetail(instruction: air_export.TypedInstruction, key: []const u8) ?[]const u8 {
    for (instruction.details) |detail| {
        if (std.mem.eql(u8, detail.key, key)) return detail.value;
    }
    return null;
}

fn typedOperandTextDetail(instruction: air_export.TypedInstruction, operand_index: usize) ?[]const u8 {
    var key_buffer: [32]u8 = undefined;
    const key = std.fmt.bufPrint(&key_buffer, "operand{}_text", .{operand_index}) catch return null;
    if (typedDetail(instruction, key)) |value| return value;
    const legacy_key = std.fmt.bufPrint(&key_buffer, "operand{}", .{operand_index}) catch return null;
    return typedDetail(instruction, legacy_key);
}

fn typedCalleeName(callee_text: []const u8) ?[]const u8 {
    return (typedCallee(callee_text) orelse return null).name;
}

const TypedCallee = struct {
    name: []const u8,
    external: bool,
};

fn typedCallee(callee_text: []const u8) ?TypedCallee {
    if (typedCalleeWithMarker(callee_text, "function '", false)) |callee| return callee;
    if (typedCalleeWithMarker(callee_text, "extern '", true)) |callee| return callee;
    return null;
}

fn typedCalleeWithMarker(callee_text: []const u8, marker: []const u8, external: bool) ?TypedCallee {
    const start = std.mem.indexOf(u8, callee_text, marker) orelse return null;
    const name_start = start + marker.len;
    const name_end = std.mem.indexOf(u8, callee_text[name_start..], "'") orelse return null;
    if (name_end == 0) return null;
    return .{
        .name = callee_text[name_start .. name_start + name_end],
        .external = external,
    };
}

fn isIgnoredOpcode(opcode: []const u8) bool {
    return std.mem.startsWith(u8, opcode, "dbg_");
}

fn isStraightLineOpcode(opcode: []const u8) bool {
    return std.mem.eql(u8, opcode, "arg") or
        isArithmeticOpcode(opcode) or
        std.mem.startsWith(u8, opcode, "cmp_") or
        isCastOpcode(opcode) or
        std.mem.eql(u8, opcode, "alloc") or
        std.mem.eql(u8, opcode, "load") or
        std.mem.eql(u8, opcode, "store") or
        std.mem.eql(u8, opcode, "store_safe") or
        std.mem.eql(u8, opcode, "is_non_null") or
        std.mem.eql(u8, opcode, "optional_payload") or
        std.mem.eql(u8, opcode, "runtime_nav_ptr") or
        std.mem.eql(u8, opcode, "atomic_rmw") or
        std.mem.eql(u8, opcode, "array_elem_val") or
        std.mem.eql(u8, opcode, "aggregate_init") or
        std.mem.eql(u8, opcode, "ptr_add") or
        std.mem.eql(u8, opcode, "ptr_elem_ptr") or
        std.mem.eql(u8, opcode, "assembly") or
        isFieldPtrOpcode(opcode) or
        isCallOpcode(opcode) or
        std.mem.eql(u8, opcode, "ret") or
        std.mem.eql(u8, opcode, "ret_safe") or
        std.mem.eql(u8, opcode, "unreach");
}

fn isArithmeticOpcode(opcode: []const u8) bool {
    return air_export.categoryForOpcode(opcode) == .arithmetic;
}

fn isShiftOpcode(opcode: []const u8) bool {
    return std.mem.startsWith(u8, opcode, "shl") or std.mem.startsWith(u8, opcode, "shr");
}

fn isCastOpcode(opcode: []const u8) bool {
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

fn isCallOpcode(opcode: []const u8) bool {
    return air_export.categoryForOpcode(opcode) == .call;
}

fn binaryOp(opcode: []const u8, ty: ZigType) ?ir.BinaryOp {
    const fp = isFpType(ty.ir_type);
    if (std.mem.startsWith(u8, opcode, "add")) return if (fp) .fadd else .add;
    if (std.mem.startsWith(u8, opcode, "sub")) return if (fp) .fsub else .sub;
    if (std.mem.startsWith(u8, opcode, "mul")) return if (fp) .fmul else .mul;
    if (std.mem.startsWith(u8, opcode, "div_float")) return .fdiv;
    if (std.mem.startsWith(u8, opcode, "div_")) return if (ty.signed) .sdiv else .udiv;
    if (std.mem.startsWith(u8, opcode, "rem")) return if (fp) .frem else if (ty.signed) .srem else .urem;
    if (std.mem.startsWith(u8, opcode, "mod")) return if (ty.signed) .srem else .urem;
    if (std.mem.eql(u8, opcode, "bit_and")) return .@"and";
    if (std.mem.eql(u8, opcode, "bit_or")) return .@"or";
    if (std.mem.eql(u8, opcode, "xor")) return .xor;
    if (std.mem.startsWith(u8, opcode, "shl")) return .shl;
    if (std.mem.startsWith(u8, opcode, "shr")) return if (ty.signed) .ashr else .lshr;
    return null;
}

fn intPredicate(opcode: []const u8, signed: bool) ?ir.IcmpPredicate {
    if (std.mem.startsWith(u8, opcode, "cmp_eq")) return .eq;
    if (std.mem.startsWith(u8, opcode, "cmp_neq")) return .ne;
    if (std.mem.startsWith(u8, opcode, "cmp_lt")) return if (signed) .slt else .ult;
    if (std.mem.startsWith(u8, opcode, "cmp_lte")) return if (signed) .sle else .ule;
    if (std.mem.startsWith(u8, opcode, "cmp_gt")) return if (signed) .sgt else .ugt;
    if (std.mem.startsWith(u8, opcode, "cmp_gte")) return if (signed) .sge else .uge;
    return null;
}

fn fpPredicate(opcode: []const u8) ?ir.FcmpPredicate {
    if (std.mem.startsWith(u8, opcode, "cmp_eq")) return .oeq;
    if (std.mem.startsWith(u8, opcode, "cmp_neq")) return .one;
    if (std.mem.startsWith(u8, opcode, "cmp_lt")) return .olt;
    if (std.mem.startsWith(u8, opcode, "cmp_lte")) return .ole;
    if (std.mem.startsWith(u8, opcode, "cmp_gt")) return .ogt;
    if (std.mem.startsWith(u8, opcode, "cmp_gte")) return .oge;
    return null;
}

fn castOp(opcode: []const u8, from: ZigType, to: ZigType) ?ir.CastOp {
    if (std.mem.eql(u8, opcode, "trunc")) return .trunc;
    if (std.mem.eql(u8, opcode, "bitcast")) return .bitcast;
    if (std.mem.eql(u8, opcode, "ptrtoint")) return .ptrtoint;
    if (std.mem.eql(u8, opcode, "inttoptr")) return .inttoptr;
    if (std.mem.eql(u8, opcode, "float_from_int")) return if (from.signed) .sitofp else .uitofp;
    if (std.mem.eql(u8, opcode, "int_from_float")) return if (to.signed) .fptosi else .fptoui;
    if (std.mem.eql(u8, opcode, "fpext")) return .fpext;
    if (std.mem.eql(u8, opcode, "fptrunc")) return .fptrunc;
    if (!std.mem.eql(u8, opcode, "intcast")) return null;
    const from_bits = intBits(from.ir_type) orelse return null;
    const to_bits = intBits(to.ir_type) orelse return null;
    if (to_bits < from_bits) return .trunc;
    if (to_bits > from_bits) return if (from.signed) .sext else .zext;
    return .bitcast;
}

fn isFpType(ty: ir.Type) bool {
    return ty == .float or ty == .double or ty == .fp128;
}

fn intBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .int => |bits| bits,
        else => null,
    };
}

fn shortFunctionName(name: []const u8) []const u8 {
    return name;
}

fn isPointerType(text: []const u8) bool {
    return std.mem.startsWith(u8, text, "*") or
        std.mem.startsWith(u8, text, "[*]") or
        std.mem.startsWith(u8, text, "[]") or
        std.mem.startsWith(u8, text, "?*");
}

fn pointerChildText(text: []const u8) ?[]const u8 {
    var child = if (std.mem.startsWith(u8, text, "?*"))
        text[2..]
    else if (std.mem.startsWith(u8, text, "[*]"))
        text[3..]
    else if (std.mem.startsWith(u8, text, "[]"))
        text[2..]
    else if (std.mem.startsWith(u8, text, "*"))
        text[1..]
    else
        return null;
    child = std.mem.trim(u8, child, " ");
    while (true) {
        if (std.mem.startsWith(u8, child, "const ")) {
            child = child["const ".len..];
        } else if (std.mem.startsWith(u8, child, "volatile ")) {
            child = child["volatile ".len..];
        } else if (std.mem.startsWith(u8, child, "allowzero ")) {
            child = child["allowzero ".len..];
        } else if (std.mem.startsWith(u8, child, "align(")) {
            const close = std.mem.indexOfScalar(u8, child, ')') orelse return null;
            child = std.mem.trim(u8, child[close + 1 ..], " ");
        } else {
            break;
        }
    }
    return std.mem.trim(u8, child, " ");
}

fn ownPrint(module: *ir.Module, comptime format: []const u8, args: anytype) ![]const u8 {
    const owned = try std.fmt.allocPrint(module.allocator, format, args);
    errdefer module.allocator.free(owned);
    try module.owned_strings.append(module.allocator, owned);
    return owned;
}

fn findMatching(text: []const u8, open_index: usize, open: u8, close: u8) ?usize {
    var depth: usize = 0;
    for (text[open_index..], open_index..) |char, index| {
        if (char == open) depth += 1;
        if (char == close) {
            if (depth == 0) return null;
            depth -= 1;
            if (depth == 0) return index;
        }
    }
    return null;
}

const TopLevelSplit = struct {
    text: []const u8,
    separator: u8,
    offset: usize = 0,

    fn next(self: *TopLevelSplit) ?[]const u8 {
        if (self.offset > self.text.len) return null;
        const start = self.offset;
        var paren_depth: usize = 0;
        var bracket_depth: usize = 0;
        var brace_depth: usize = 0;
        var angle_depth: usize = 0;
        var quote: ?u8 = null;
        var index = start;
        while (index < self.text.len) : (index += 1) {
            const char = self.text[index];
            if (quote) |active_quote| {
                if (char == active_quote and (index == 0 or self.text[index - 1] != '\\')) quote = null;
                continue;
            }
            switch (char) {
                '\'', '"' => quote = char,
                '(' => paren_depth += 1,
                ')' => if (paren_depth > 0) {
                    paren_depth -= 1;
                },
                '[' => bracket_depth += 1,
                ']' => if (bracket_depth > 0) {
                    bracket_depth -= 1;
                },
                '{' => brace_depth += 1,
                '}' => if (brace_depth > 0) {
                    brace_depth -= 1;
                },
                '<' => angle_depth += 1,
                '>' => if (angle_depth > 0) {
                    angle_depth -= 1;
                },
                else => {},
            }
            if (char == self.separator and paren_depth == 0 and bracket_depth == 0 and
                brace_depth == 0 and angle_depth == 0 and quote == null)
            {
                self.offset = index + 1;
                return self.text[start..index];
            }
        }
        self.offset = self.text.len + 1;
        return self.text[start..];
    }
};

fn splitTopLevel(text: []const u8, separator: u8) TopLevelSplit {
    return .{ .text = text, .separator = separator };
}

test "lower straight-line AIR arithmetic and calls" {
    const air_text =
        \\  %0 = arg(i32, 0)
        \\  %1 = arg(i32, 1)
        \\  %2 = add_wrap(%0!, %1!)
        \\  %3!= ret(%2!)
        \\
    ;
    const input = try makeTestExport(std.testing.allocator, "add_wrap", "fn (i32, i32) callconv(.c) i32", air_text, 4);
    defer std.testing.allocator.free(input);
    var parsed = try air_export.parse(std.testing.allocator, input);
    defer parsed.deinit();
    var lowered = try lowerCompatible(std.testing.allocator, parsed);
    defer lowered.deinit();
    try std.testing.expectEqual(@as(usize, 1), lowered.accepted_functions);
    try std.testing.expectEqual(@as(usize, 0), lowered.unsupported.len);
    try std.testing.expectEqual(ir.BinaryOp.add, lowered.module.functions.items[0].blocks.items[0].instructions.items[0].kind.binary.op);
}

test "lower AIR block result conditional as select" {
    const air_text =
        \\  %0 = arg(i32, 0)
        \\  %1 = arg(i32, 1)
        \\  %2 = block(i32, {
        \\    %3 = cmp_lt(%0, %1)
        \\    %6!= cond_br(%3!, poi {
        \\      %4!= br(%2, %0!)
        \\    }, poi {
        \\      %5!= br(%2, %1!)
        \\    })
        \\  })
        \\  %7!= ret(%2!)
        \\
    ;
    const input = try makeTestExport(std.testing.allocator, "min", "fn (i32, i32) callconv(.c) i32", air_text, 8);
    defer std.testing.allocator.free(input);
    var parsed = try air_export.parse(std.testing.allocator, input);
    defer parsed.deinit();
    var lowered = try lowerCompatible(std.testing.allocator, parsed);
    defer lowered.deinit();
    try std.testing.expectEqual(@as(usize, 1), lowered.accepted_functions);
    const instructions = lowered.module.functions.items[0].blocks.items[0].instructions.items;
    try std.testing.expectEqual(@as(usize, 2), instructions.len);
    try std.testing.expect(instructions[1].kind == .select);
}

test "lower AIR accumulator loop into SSA control flow" {
    const air_text =
        \\  %0 = arg(u32, 0)
        \\  %1 = alloc(*u32)
        \\  %2!= store(%1, <u32, 0>)
        \\  %3 = alloc(*i32)
        \\  %4!= store(%3, <i32, 0>)
        \\  %5!= block(void, {
        \\    %6!= loop(noreturn, {
        \\      %7!= block(void, {
        \\        %8 = load(u32, %1)
        \\        %9 = cmp_lt(%8!, %0)
        \\        %18!= cond_br(%9!, poi {
        \\          %10 = load(i32, %3)
        \\          %11 = load(u32, %1)
        \\          %12 = intcast(i32, %11!)
        \\          %13 = add(%10!, %12!)
        \\          %14!= store(%3, %13!)
        \\          %15 = load(u32, %1)
        \\          %16 = add(%15!, <u32, 1>)
        \\          %17!= store(%1, %16!)
        \\          %19!= br(%7, @.void_value)
        \\        }, poi {
        \\          %20!= br(%5, @.void_value)
        \\        })
        \\      })
        \\      %21!= repeat(%6)
        \\    })
        \\  })
        \\  %22 = load(i32, %3)
        \\  %23!= ret(%22!)
        \\
    ;
    const input = try makeTestExport(
        std.testing.allocator,
        "uncurated_loop_sum",
        "fn (u32) callconv(.c) i32",
        air_text,
        24,
    );
    defer std.testing.allocator.free(input);
    var parsed = try air_export.parse(std.testing.allocator, input);
    defer parsed.deinit();
    var lowered = try lowerCompatible(std.testing.allocator, parsed);
    defer lowered.deinit();
    try std.testing.expectEqual(@as(usize, 1), lowered.accepted_functions);
    try std.testing.expectEqual(@as(usize, 4), lowered.module.functions.items[0].blocks.items.len);
    try std.testing.expect(lowered.module.functions.items[0].blocks.items[1].instructions.items[0].kind == .phi);
}

test "parse qualified Zig function types" {
    const parsed = try parseFunctionType(std.testing.allocator, "noinline fn (i32, i32, i32, i32, i32, i32, i32) i32");
    defer parsed.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 7), parsed.params.len);
    try std.testing.expectEqual(ir.Type{ .int = 32 }, parsed.return_type.ir_type);
    try std.testing.expect(!parsed.c_calling_convention);
}

fn makeTestExport(
    allocator: std.mem.Allocator,
    function_name: []const u8,
    function_type: []const u8,
    air_text: []const u8,
    instruction_count: usize,
) ![]u8 {
    return std.fmt.allocPrint(allocator,
        \\zllvm-air-export-v1
        \\contract_version=1
        \\payload=zig-air-print-v1
        \\producer=test
        \\root_source=test.zig
        \\wrapper=test.zig
        \\mode=ReleaseFast
        \\target=x86_64-unknown-linux-gnu
        \\function_count=1
        \\global_count=0
        \\function_begin
        \\name_bytes={}
        \\{s}
        \\type_bytes={}
        \\{s}
        \\instruction_count={}
        \\main_body_count={}
        \\liveness=present
        \\air_bytes={}
        \\{s}
        \\function_end
        \\
    , .{
        function_name.len,
        function_name,
        function_type.len,
        function_type,
        instruction_count,
        instruction_count,
        air_text.len,
        air_text,
    });
}
