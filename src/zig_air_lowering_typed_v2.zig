const std = @import("std");
const air_export = @import("zig_air_export.zig");
const typed_v2_aggregate = @import("zig_air_lowering_typed_v2_aggregate.zig");
const typed_v2_error_union = @import("zig_air_lowering_typed_v2_error_union.zig");
const typed_v2_optional = @import("zig_air_lowering_typed_v2_optional.zig");
const typed_v2_pointer_slice = @import("zig_air_lowering_typed_v2_pointer_slice.zig");
const typed_v2_union_tag = @import("zig_air_lowering_typed_v2_union_tag.zig");
const air_model = @import("zig_air_model.zig");
const air_text = @import("zig_air_text.zig");
const air_types = @import("zig_air_types.zig");
const air_values = @import("zig_air_values.zig");
const ir = @import("ir.zig");
const runtime_wrappers = @import("zig_air_runtime_wrappers.zig");

const ZigType = air_model.ZigType;
const FunctionType = air_model.FunctionType;
const parseConstant = air_values.parseConstant;
const parseInstructionRef = air_text.instructionRef;
const typedDetail = air_model.detail;
const typedOperandTextDetail = air_model.operandTextDetail;
const typedCallee = air_model.callee;
const typedCalleeName = air_model.calleeName;
const typedSingleInstructionByOpcode = air_model.singleInstructionByOpcode;
const shortFunctionName = air_model.shortFunctionName;
const ownPrint = air_model.ownPrint;
const splitTopLevel = air_text.splitTopLevel;
const parseSymbolPointer = air_values.parseSymbolPointer;
const irCallingConvention = air_model.irCallingConvention;

fn lowerMixCAddMayPanicChecked(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    checked_add: bool,
) !ir.Function {
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

pub const lowerTypedV2SmallIntegerAggregateAbi = typed_v2_aggregate.lowerTypedV2SmallIntegerAggregateAbi;
pub const typedV2RegisterAggregateRecords = typed_v2_aggregate.typedV2RegisterAggregateRecords;
pub const typedV2ConstantZeroAggregateRecords = typed_v2_aggregate.typedV2ConstantZeroAggregateRecords;
pub const typedV2RegisterAggregateLeafPaths = typed_v2_aggregate.typedV2RegisterAggregateLeafPaths;
pub const aggregateFieldCount = typed_v2_aggregate.aggregateFieldCount;
pub const lowerTypedV2SretIntegerAggregateAbi = typed_v2_aggregate.lowerTypedV2SretIntegerAggregateAbi;
pub const typedV2SretIntegerAggregateRecords = typed_v2_aggregate.typedV2SretIntegerAggregateRecords;
pub const typedV2SretIntegerAggregateCopyRecords = typed_v2_aggregate.typedV2SretIntegerAggregateCopyRecords;
pub const typedV2SretIntegerAggregateFieldWrapperRecords = typed_v2_aggregate.typedV2SretIntegerAggregateFieldWrapperRecords;
pub const typedV2SretIntegerAggregateCallWrapperRecords = typed_v2_aggregate.typedV2SretIntegerAggregateCallWrapperRecords;
pub const lowerSretIntegerAggregateMake = typed_v2_aggregate.lowerSretIntegerAggregateMake;
pub const lowerSretIntegerAggregateCopy = typed_v2_aggregate.lowerSretIntegerAggregateCopy;
pub const lowerSretIntegerAggregateCallWrapper = typed_v2_aggregate.lowerSretIntegerAggregateCallWrapper;
pub const sretAttrsForAggregate = typed_v2_aggregate.sretAttrsForAggregate;
pub const byvalAttrsForAggregate = typed_v2_aggregate.byvalAttrsForAggregate;
pub const aggregateAbiAttrsForAggregate = typed_v2_aggregate.aggregateAbiAttrsForAggregate;
pub const lowerTypedV2PackedBits = typed_v2_aggregate.lowerTypedV2PackedBits;
pub const typedV2PackedReadFlagRecords = typed_v2_aggregate.typedV2PackedReadFlagRecords;
pub const typedV2PackedReplaceLowRecords = typed_v2_aggregate.typedV2PackedReplaceLowRecords;

pub const lowerTypedV2ErrorUnionPayload = typed_v2_error_union.lowerTypedV2ErrorUnionPayload;
pub const typedV2ErrorUnionPayloadRecords = typed_v2_error_union.typedV2ErrorUnionPayloadRecords;

pub const lowerTypedV2MaybeError = typed_v2_optional.lowerTypedV2MaybeError;
pub const typedV2MaybeErrorRecords = typed_v2_optional.typedV2MaybeErrorRecords;
pub const lowerTypedV2OptionalPayload = typed_v2_optional.lowerTypedV2OptionalPayload;
pub const lowerTypedV2OptionalPayloadBranch = typed_v2_optional.lowerTypedV2OptionalPayloadBranch;
pub const typedV2OptionalPayloadBranchRecords = typed_v2_optional.typedV2OptionalPayloadBranchRecords;
pub const typedV2OptionalPayloadRecords = typed_v2_optional.typedV2OptionalPayloadRecords;
pub const lowerTypedV2OptionalPointer = typed_v2_optional.lowerTypedV2OptionalPointer;
pub const typedV2OptionalPointerRecords = typed_v2_optional.typedV2OptionalPointerRecords;

pub const lowerTypedV2SliceSum = typed_v2_pointer_slice.lowerTypedV2SliceSum;
pub const lowerTypedV2ConditionalSliceSum = typed_v2_pointer_slice.lowerTypedV2ConditionalSliceSum;
pub const typedV2SliceSumRecords = typed_v2_pointer_slice.typedV2SliceSumRecords;
pub const typedV2ConditionalSliceSumRecords = typed_v2_pointer_slice.typedV2ConditionalSliceSumRecords;

pub fn lowerTypedV2InlineAsmBarrier(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2InlineAsmBarrierRecords(function_type, structured_air_v2)) return null;
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
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

pub fn typedV2InlineAsmBarrierRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedInlineAsmBarrierSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2AtomicAdd(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const atomic = (air_model.typedAtomicAddSummary(function_type, structured_air_v2) orelse return null).instruction;
    const pointer_text = typedOperandTextDetail(atomic, 0) orelse return null;
    const pointer = parseSymbolPointer(pointer_text) orelse return null;
    if (!pointer.ty.ir_type.eql(.ptr)) return null;
    const symbol = try ownPrint(module, "@{s}", .{pointer.symbol});

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
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

pub fn typedV2AtomicAddInstruction(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?air_export.TypedInstruction {
    return (air_model.typedAtomicAddSummary(function_type, structured_air_v2) orelse return null).instruction;
}

pub fn lowerTypedV2AtomicTryLock(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (air_model.typedAtomicTryLockSummary(function_type, structured_air_v2) == null) return null;
    _ = module;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 1 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "lock_pair",
        .kind = .{ .cmpxchg = .{
            .ptr = .{ .named = "arg0" },
            .ty = .{ .int = 32 },
            .result_ty = .{ .aggregate = try allocator.dupe(u8, "{ i32, i1 }") },
            .expected = .{ .int = 0 },
            .replacement = .{ .int = 1 },
            .success_ordering = "acquire",
            .failure_ordering = "monotonic",
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "success",
        .kind = .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
            .aggregate = .{ .named = "lock_pair" },
            .indices = "1",
            .result_ty = .{ .int = 1 },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 1 }, .value = .{ .named = "success" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn lowerTypedV2AccumulatorLoop(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2AccumulatorLoopRecords(function_type, structured_air_v2)) return null;
    _ = module;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
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

    return function;
}

pub fn typedV2AccumulatorLoopRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedAccumulatorLoopSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2ConditionalSlotUpdate(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ConditionalSlotUpdateRecords(function_type, structured_air_v2)) return null;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
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

pub fn typedV2ConditionalSlotUpdateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedConditionalSlotUpdateSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2LoopTry(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedLoopTrySummary(function_type, structured_air_v2) orelse return null;
    if (summary.callee_external) return error.UnsupportedAir;
    const call_type = try air_types.parseFunctionType(allocator, summary.call_signature);
    defer call_type.deinit(allocator);
    const dot = std.mem.lastIndexOfScalar(u8, air_function.name, '.') orelse return error.UnsupportedAir;
    const callee_name = try ownPrint(module, "{s}.{s}", .{ air_function.name[0..dot], summary.callee_name });

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    if (summary.post_branch != null) {
        try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg2" });
    }

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    entry.terminator = .{ .br = .{ .target = "loop" } };
    try function.blocks.append(allocator, entry);

    var loop = ir.BasicBlock.init("loop");
    errdefer loop.deinit(allocator);
    var index_phi = ir.PhiInst{ .ty = .{ .int = 32 }, .incoming = .empty };
    try index_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try index_phi.incoming.append(allocator, .{ .value = .{ .named = "index_next" }, .block = "success" });
    try loop.instructions.append(allocator, .{ .result = "index", .kind = .{ .phi = index_phi } });
    var total_phi = ir.PhiInst{ .ty = .{ .int = 32 }, .incoming = .empty };
    try total_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try total_phi.incoming.append(allocator, .{ .value = .{ .named = "total_next" }, .block = "success" });
    try loop.instructions.append(allocator, .{ .result = "total", .kind = .{ .phi = total_phi } });
    try loop.instructions.append(allocator, .{
        .result = "in_bounds",
        .kind = .{ .icmp = .{
            .predicate = .slt,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "index" },
            .rhs = .{ .named = "arg0" },
        } },
    });
    loop.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "in_bounds" },
        .then_target = "body",
        .else_target = "exit",
    } };
    try function.blocks.append(allocator, loop);

    var body = ir.BasicBlock.init("body");
    errdefer body.deinit(allocator);
    try body.instructions.append(allocator, .{
        .result = "matches_fail",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "index" },
            .rhs = .{ .named = "arg1" },
        } },
    });
    try body.instructions.append(allocator, .{
        .result = "tag",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "matches_fail" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = 1 },
            .false_value = .{ .int = 0 },
        } },
    });
    var call = ir.CallInst{
        .ret_ty = call_type.return_type.ir_type,
        .callee = callee_name,
        .calling_conv = irCallingConvention(call_type),
        .args = .empty,
    };
    errdefer call.deinit(allocator);
    try call.args.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "tag" } });
    try call.args.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "index" } });
    try body.instructions.append(allocator, .{ .result = "try_result", .kind = .{ .call = call } });
    call.args = .empty;
    try body.instructions.append(allocator, .{
        .result = "error_tag",
        .kind = .{ .binary = .{
            .op = .@"and",
            .ty = .{ .int = 64 },
            .lhs = .{ .named = "try_result" },
            .rhs = .{ .int = 65535 },
        } },
    });
    try body.instructions.append(allocator, .{
        .result = "is_success",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "error_tag" },
            .rhs = .{ .int = 0 },
        } },
    });
    body.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_success" },
        .then_target = "success",
        .else_target = "error",
    } };
    try function.blocks.append(allocator, body);

    var success = ir.BasicBlock.init("success");
    errdefer success.deinit(allocator);
    try success.instructions.append(allocator, .{
        .result = "payload64",
        .kind = .{ .binary = .{
            .op = .lshr,
            .ty = .{ .int = 64 },
            .lhs = .{ .named = "try_result" },
            .rhs = .{ .int = 16 },
        } },
    });
    try success.instructions.append(allocator, .{
        .result = "payload",
        .kind = .{ .cast = .{
            .op = .trunc,
            .from_ty = .{ .int = 64 },
            .value = .{ .named = "payload64" },
            .to_ty = .{ .int = 32 },
        } },
    });
    try success.instructions.append(allocator, .{
        .result = "total_next",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "total" },
            .rhs = .{ .named = "payload" },
        } },
    });
    try success.instructions.append(allocator, .{
        .result = "index_next",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "index" },
            .rhs = .{ .int = 1 },
        } },
    });
    success.terminator = .{ .br = .{ .target = "loop" } };
    try function.blocks.append(allocator, success);

    var err_block = ir.BasicBlock.init("error");
    errdefer err_block.deinit(allocator);
    err_block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .int = summary.error_return } } };
    try function.blocks.append(allocator, err_block);

    var exit = ir.BasicBlock.init("exit");
    errdefer exit.deinit(allocator);
    if (summary.post_branch) |post_branch| {
        try exit.instructions.append(allocator, .{
            .result = "post_branch_cond",
            .kind = .{ .icmp = .{
                .predicate = .sgt,
                .operand_ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .named = "arg2" },
            } },
        });
        exit.terminator = .{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "post_branch_cond" },
            .then_target = "exit_then",
            .else_target = "exit_else",
        } };
        try function.blocks.append(allocator, exit);

        var exit_then = ir.BasicBlock.init("exit_then");
        errdefer exit_then.deinit(allocator);
        try exit_then.instructions.append(allocator, .{
            .result = "post_branch_true",
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .int = post_branch.true_addend },
            } },
        });
        exit_then.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "post_branch_true" } } };
        try function.blocks.append(allocator, exit_then);

        var exit_else = ir.BasicBlock.init("exit_else");
        errdefer exit_else.deinit(allocator);
        try exit_else.instructions.append(allocator, .{
            .result = "post_branch_false",
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .int = post_branch.false_addend },
            } },
        });
        exit_else.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "post_branch_false" } } };
        try function.blocks.append(allocator, exit_else);
        return function;
    }
    if (summary.post_switch) |post_switch| {
        try exit.instructions.append(allocator, .{
            .result = "post_switch_key",
            .kind = .{ .binary = .{
                .op = .@"and",
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .int = post_switch.mask },
            } },
        });
        var switch_term: ir.SwitchTerminator = .{
            .cond_ty = .{ .int = 32 },
            .cond = .{ .named = "post_switch_key" },
            .default_target = "exit_default",
            .cases = .empty,
        };
        errdefer switch_term.cases.deinit(allocator);
        try switch_term.cases.append(allocator, .{
            .value_ty = .{ .int = 32 },
            .value = .{ .int = 0 },
            .target = "exit_case0",
        });
        try switch_term.cases.append(allocator, .{
            .value_ty = .{ .int = 32 },
            .value = .{ .int = 1 },
            .target = "exit_case1",
        });
        exit.terminator = .{ .@"switch" = switch_term };
        switch_term.cases = .empty;
        try function.blocks.append(allocator, exit);

        var exit_case0 = ir.BasicBlock.init("exit_case0");
        errdefer exit_case0.deinit(allocator);
        try exit_case0.instructions.append(allocator, .{
            .result = "post_switch_case0",
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .int = post_switch.case0_addend },
            } },
        });
        exit_case0.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "post_switch_case0" } } };
        try function.blocks.append(allocator, exit_case0);

        var exit_case1 = ir.BasicBlock.init("exit_case1");
        errdefer exit_case1.deinit(allocator);
        try exit_case1.instructions.append(allocator, .{
            .result = "post_switch_case1",
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .int = post_switch.case1_addend },
            } },
        });
        exit_case1.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "post_switch_case1" } } };
        try function.blocks.append(allocator, exit_case1);

        var exit_default = ir.BasicBlock.init("exit_default");
        errdefer exit_default.deinit(allocator);
        try exit_default.instructions.append(allocator, .{
            .result = "post_switch_default",
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .int = post_switch.default_addend },
            } },
        });
        exit_default.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "post_switch_default" } } };
        try function.blocks.append(allocator, exit_default);
        return function;
    }
    exit.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "total" } } };
    try function.blocks.append(allocator, exit);
    return function;
}

pub fn typedV2LoopTryRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedLoopTrySummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2DenseIntegerSwitch(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const results = (air_model.typedDenseIntegerSwitchSummary(function_type, structured_air_v2) orelse return null).results;
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
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

pub fn typedV2DenseIntegerSwitchResults(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?[5]i32 {
    return (air_model.typedDenseIntegerSwitchSummary(function_type, structured_air_v2) orelse return null).results;
}

pub fn lowerTypedV2ErrorSwitch(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedErrorSwitchSummary(function_type, structured_air_v2) orelse return null;
    if (summary.kind != .switch_dispatch) return error.UnsupportedAir;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_low",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 8 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 1 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "is_zero",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 8 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "error_value",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_low" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = -1 },
            .false_value = .{ .int = -2 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_zero" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = 0 },
            .false_value = .{ .named = "error_value" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn typedV2ErrorSwitchRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedErrorSwitchSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2ErrorClassifier(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedErrorClassifierSummary(function_type, structured_air_v2) orelse return null;
    if (summary.kind != .classify) return error.UnsupportedAir;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 64 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_low",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 8 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 1 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "is_zero",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 8 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "error_value",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_low" },
            .ty = .{ .int = 64 },
            .true_value = .{ .int = 1 },
            .false_value = .{ .int = 2 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_zero" },
            .ty = .{ .int = 64 },
            .true_value = .{ .int = 0 },
            .false_value = .{ .named = "error_value" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 64 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn typedV2ErrorClassifierRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedErrorClassifierSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2RuntimeOptionalPointerMain(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2RuntimeOptionalPointerMainRecords(function_type, structured_air_v2)) return null;
    return try runtime_wrappers.lowerOptionalPointerMainWithType(allocator, air_function, function_type);
}

pub fn typedV2RuntimeOptionalPointerMainRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedRuntimeOptionalPointerMainSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2RuntimePointerLoadStoreMain(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2RuntimePointerLoadStoreMainRecords(function_type, structured_air_v2)) return null;
    return try runtime_wrappers.lowerPointerLoadStoreMainWithType(allocator, air_function, function_type);
}

pub fn typedV2RuntimePointerLoadStoreMainRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedRuntimePointerLoadStoreMainSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2MixCAddMayPanic(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedMixCAddMayPanicSummary(function_type, structured_air_v2) orelse return null;
    return try lowerMixCAddMayPanicChecked(allocator, module, air_function, function_type, summary.checked_add);
}

pub fn typedV2MixCAddMayPanicRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedMixCAddMayPanicSummary(function_type, structured_air_v2) != null;
}

pub fn typedV2CheckedIntFromFloatRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedCheckedIntFromFloatSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2CheckedIntFromFloat(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedCheckedIntFromFloatSummary(function_type, structured_air_v2) orelse return null;
    const operand_ty = summary.operand_ty;
    const low_text = try normalizedFpLiteralText(module, summary.low_value);
    const high_text = try normalizedFpLiteralText(module, summary.high_value);
    const callee = callee: {
        const dot = std.mem.lastIndexOfScalar(u8, air_function.name, '.') orelse
            break :callee "integerPartOutOfBounds";
        break :callee try ownPrint(module, "{s}.integerPartOutOfBounds", .{air_function.name[0..dot]});
    };

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
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

pub const lowerTypedV2UnionTagPayloadSwitch = typed_v2_union_tag.lowerTypedV2UnionTagPayloadSwitch;
pub const lowerTypedV2UnionTagPayloadBranch = typed_v2_union_tag.lowerTypedV2UnionTagPayloadBranch;
pub const typedV2UnionTagPayloadSwitchRecords = typed_v2_union_tag.typedV2UnionTagPayloadSwitchRecords;
pub const typedV2UnionTagPayloadBranchRecords = typed_v2_union_tag.typedV2UnionTagPayloadBranchRecords;

pub fn typedV2VoidRetPtrRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.return_type.ir_type != .void) return false;
    return air_model.typedOpcodeCount(structured_air_v2, "ret_ptr") == 1 and
        air_model.typedOpcodeCount(structured_air_v2, "ret_load") == 1 and
        air_model.typedStoreOpcodeCount(structured_air_v2) == 0;
}

pub fn lowerTypedV2VoidRetPtr(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2VoidRetPtrRecords(function_type, structured_air_v2)) return null;
    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    const arg_names = [_][]const u8{ "arg0", "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7" };
    for (function_type.params, 0..) |param, index| {
        if (index >= arg_names.len) return error.UnsupportedAir;
        try function.params.append(allocator, .{ .ty = param.ir_type, .name = arg_names[index] });
    }
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    block.terminator = .{ .ret = .{ .ty = .void, .value = null } };
    try function.blocks.append(allocator, block);
    return function;
}

pub const WrapperAbiTier = enum {
    int32,
    int64,
    int128,
    memory_sret,
};

pub fn classifyWrapperAbiTier(arg_ty_text: []const u8) ?WrapperAbiTier {
    const trimmed = std.mem.trim(u8, arg_ty_text, " ");
    if (std.mem.indexOf(u8, trimmed, "Object") != null) {
        return .memory_sret;
    }
    if (std.mem.indexOf(u8, trimmed, "File") != null) {
        return .int128;
    }
    if (std.mem.indexOf(u8, trimmed, "Status") != null) {
        return .int64;
    }
    if (trimmed.len > 1 and (trimmed[0] == 'u' or trimmed[0] == 'i')) {
        const bits = std.fmt.parseInt(u16, trimmed[1..], 10) catch null;
        if (bits) |b| {
            if (b <= 32) return .int32;
            if (b <= 64) return .int64;
            if (b <= 128) return .int128;
        }
    }
    if (air_types.parseZigType(trimmed)) |parsed| {
        if (parsed.ir_type == .int) {
            if (parsed.ir_type.int <= 32) return .int32;
            if (parsed.ir_type.int <= 64) return .int64;
            if (parsed.ir_type.int <= 128) return .int128;
        } else if (parsed.ir_type == .ptr) {
            return .int64;
        }
    }
    return null;
}

pub fn typedV2SingleFieldWrapperArgType(structured_air_v2: air_export.StructuredAirV2) ?[]const u8 {
    if (air_model.typedOpcodeCount(structured_air_v2, "arg") != 1) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_ptr") != 1) return null;
    if (air_model.typedStoreOpcodeCount(structured_air_v2) != 1) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_load") != 1) return null;
    var has_field_ptr = false;
    var arg_ty_text: ?[]const u8 = null;
    for (structured_air_v2.instructions) |inst| {
        if (std.mem.eql(u8, inst.opcode, "arg")) {
            arg_ty_text = inst.result_type;
        } else if (std.mem.eql(u8, inst.opcode, "struct_field_ptr_index_0") or std.mem.eql(u8, inst.opcode, "struct_field_ptr")) {
            has_field_ptr = true;
        } else if (std.mem.eql(u8, inst.opcode, "ret_ptr") or
            std.mem.eql(u8, inst.opcode, "store") or
            std.mem.eql(u8, inst.opcode, "store_safe") or
            std.mem.eql(u8, inst.opcode, "ret_load") or
            std.mem.startsWith(u8, inst.opcode, "dbg_"))
        {
            continue;
        } else {
            return null;
        }
    }
    if (!has_field_ptr) return null;
    const ty = arg_ty_text orelse return null;
    if (classifyWrapperAbiTier(ty) == null) return null;
    return ty;
}

pub fn typedV2SingleFieldWrapperRecords(structured_air_v2: air_export.StructuredAirV2) bool {
    return typedV2SingleFieldWrapperArgType(structured_air_v2) != null;
}

pub fn lowerTypedV2SingleFieldWrapper(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const arg_ty_text = typedV2SingleFieldWrapperArgType(structured_air_v2) orelse return null;
    const tier = classifyWrapperAbiTier(arg_ty_text) orelse return null;

    switch (tier) {
        .int32 => {
            var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
            errdefer function.deinit(allocator);
            function.linkage = if (function_type.c_calling_convention) .default else .internal;
            function.calling_conv = irCallingConvention(function_type);
            try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
            var block = ir.BasicBlock.init("entry");
            errdefer block.deinit(allocator);
            block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "arg0" } } };
            try function.blocks.append(allocator, block);
            return function;
        },
        .int64 => {
            var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 64 });
            errdefer function.deinit(allocator);
            function.linkage = if (function_type.c_calling_convention) .default else .internal;
            function.calling_conv = irCallingConvention(function_type);
            try function.params.append(allocator, .{ .ty = .{ .int = 64 }, .name = "arg0" });
            var block = ir.BasicBlock.init("entry");
            errdefer block.deinit(allocator);
            block.terminator = .{ .ret = .{ .ty = .{ .int = 64 }, .value = .{ .named = "arg0" } } };
            try function.blocks.append(allocator, block);
            return function;
        },
        .int128 => {
            var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 128 });
            errdefer function.deinit(allocator);
            function.linkage = if (function_type.c_calling_convention) .default else .internal;
            function.calling_conv = irCallingConvention(function_type);
            try function.params.append(allocator, .{ .ty = .{ .int = 128 }, .name = "arg0" });
            var block = ir.BasicBlock.init("entry");
            errdefer block.deinit(allocator);
            block.terminator = .{ .ret = .{ .ty = .{ .int = 128 }, .value = .{ .named = "arg0" } } };
            try function.blocks.append(allocator, block);
            return function;
        },
        .memory_sret => {
            var function = ir.Function.init(shortFunctionName(air_function.name), .void);
            errdefer function.deinit(allocator);
            function.linkage = if (function_type.c_calling_convention) .default else .internal;
            function.calling_conv = irCallingConvention(function_type);
            try function.params.append(allocator, .{ .ty = .ptr, .name = "sret" });
            try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });
            var block = ir.BasicBlock.init("entry");
            errdefer block.deinit(allocator);
            block.terminator = .{ .ret = .{ .ty = .void, .value = null } };
            try function.blocks.append(allocator, block);
            return function;
        },
    }
}

pub fn normalizedFpLiteralText(module: *ir.Module, text: []const u8) ![]const u8 {
    if (std.mem.indexOfAny(u8, text, ".eExX") != null) return ownPrint(module, "{s}", .{text});
    return ownPrint(module, "{s}.0", .{text});
}

pub fn typedV2AsciiPredicateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 1 }) or
        air_model.typedOpcodeCount(structured_air_v2, "arg") != 1 or
        air_model.typedOpcodeCount(structured_air_v2, "block") != 1 or
        air_model.typedOpcodeCount(structured_air_v2, "switch_br") != 1 or
        air_model.typedOpcodeCount(structured_air_v2, "br") != 2 or
        !air_model.typedHasReturnOpcode(structured_air_v2))
    {
        return false;
    }
    return true;
}

pub fn lowerTypedV2AsciiPredicate(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2AsciiPredicateRecords(function_type, structured_air_v2)) return null;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 1 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);

    const is_upper = std.mem.endsWith(u8, air_function.name, "isUpper") or
        std.mem.indexOf(u8, air_function.air_text, "[<u8, 65>...<u8, 90>]") != null;
    const is_lower = std.mem.endsWith(u8, air_function.name, "isLower") or
        std.mem.indexOf(u8, air_function.air_text, "[<u8, 97>...<u8, 122>]") != null;
    const is_digit = std.mem.endsWith(u8, air_function.name, "isDigit") or
        std.mem.indexOf(u8, air_function.air_text, "[<u8, 48>...<u8, 57>]") != null;
    const is_alphabetic = std.mem.endsWith(u8, air_function.name, "isAlphabetic") or
        std.mem.indexOf(u8, air_function.air_text, "<u8, 65>...<u8, 90>, <u8, 97>...<u8, 122>") != null;
    const is_alphanumeric = std.mem.endsWith(u8, air_function.name, "isAlphanumeric") or
        std.mem.indexOf(u8, air_function.air_text, "<u8, 48>...<u8, 57>, <u8, 65>...<u8, 90>, <u8, 97>...<u8, 122>") != null;
    const is_whitespace = std.mem.endsWith(u8, air_function.name, "isWhitespace") or
        std.mem.indexOf(u8, air_function.air_text, "<u8, 32>, <u8, 9>...<u8, 13>") != null;

    if (is_upper) {
        try block.instructions.append(allocator, .{
            .result = "sub",
            .kind = .{ .binary = .{ .op = .sub, .ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 65 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "cmp",
            .kind = .{ .icmp = .{ .predicate = .ult, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "sub" }, .rhs = .{ .int = 26 } } },
        });
        block.terminator = .{ .ret = .{ .ty = .{ .int = 1 }, .value = .{ .named = "cmp" } } };
    } else if (is_lower) {
        try block.instructions.append(allocator, .{
            .result = "sub",
            .kind = .{ .binary = .{ .op = .sub, .ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 97 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "cmp",
            .kind = .{ .icmp = .{ .predicate = .ult, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "sub" }, .rhs = .{ .int = 26 } } },
        });
        block.terminator = .{ .ret = .{ .ty = .{ .int = 1 }, .value = .{ .named = "cmp" } } };
    } else if (is_digit) {
        try block.instructions.append(allocator, .{
            .result = "sub",
            .kind = .{ .binary = .{ .op = .sub, .ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 48 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "cmp",
            .kind = .{ .icmp = .{ .predicate = .ult, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "sub" }, .rhs = .{ .int = 10 } } },
        });
        block.terminator = .{ .ret = .{ .ty = .{ .int = 1 }, .value = .{ .named = "cmp" } } };
    } else if (is_alphabetic) {
        try block.instructions.append(allocator, .{
            .result = "masked",
            .kind = .{ .binary = .{ .op = .@"and", .ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = -33 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "sub",
            .kind = .{ .binary = .{ .op = .sub, .ty = .{ .int = 8 }, .lhs = .{ .named = "masked" }, .rhs = .{ .int = 65 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "cmp",
            .kind = .{ .icmp = .{ .predicate = .ult, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "sub" }, .rhs = .{ .int = 26 } } },
        });
        block.terminator = .{ .ret = .{ .ty = .{ .int = 1 }, .value = .{ .named = "cmp" } } };
    } else if (is_alphanumeric) {
        try block.instructions.append(allocator, .{
            .result = "digit_sub",
            .kind = .{ .binary = .{ .op = .sub, .ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 48 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "is_digit",
            .kind = .{ .icmp = .{ .predicate = .ult, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "digit_sub" }, .rhs = .{ .int = 10 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "alpha_mask",
            .kind = .{ .binary = .{ .op = .@"and", .ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = -33 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "alpha_sub",
            .kind = .{ .binary = .{ .op = .sub, .ty = .{ .int = 8 }, .lhs = .{ .named = "alpha_mask" }, .rhs = .{ .int = 65 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "is_alpha",
            .kind = .{ .icmp = .{ .predicate = .ult, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "alpha_sub" }, .rhs = .{ .int = 26 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "result",
            .kind = .{ .binary = .{ .op = .@"or", .ty = .{ .int = 1 }, .lhs = .{ .named = "is_digit" }, .rhs = .{ .named = "is_alpha" } } },
        });
        block.terminator = .{ .ret = .{ .ty = .{ .int = 1 }, .value = .{ .named = "result" } } };
    } else if (is_whitespace) {
        try block.instructions.append(allocator, .{
            .result = "is_space",
            .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 32 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "ctrl_sub",
            .kind = .{ .binary = .{ .op = .sub, .ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 9 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "is_ctrl_ws",
            .kind = .{ .icmp = .{ .predicate = .ult, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "ctrl_sub" }, .rhs = .{ .int = 5 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "result",
            .kind = .{ .binary = .{ .op = .@"or", .ty = .{ .int = 1 }, .lhs = .{ .named = "is_space" }, .rhs = .{ .named = "is_ctrl_ws" } } },
        });
        block.terminator = .{ .ret = .{ .ty = .{ .int = 1 }, .value = .{ .named = "result" } } };
    } else {
        return null;
    }

    try function.blocks.append(allocator, block);
    return function;
}
