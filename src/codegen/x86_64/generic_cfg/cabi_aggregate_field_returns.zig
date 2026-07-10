const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_types = @import("../types.zig");
const sysv_abi = @import("../sysv_abi.zig");
const x86_64_emit = @import("../emit.zig");
const x86_64_match = @import("../match.zig");
const x86_64_machine = @import("../machine.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");

const FrameIndex = x86_64_types.FrameIndex;
const XmmReg = x86_64_types.XmmReg;
const MachineFunction = x86_64_machine.MachineFunction;
const SysVAggregateClassification = sysv_abi.AggregateClassification;

const appendSysVScalarCallArgs = cabi_call_lowering.appendSysVScalarCallArgs;

const paramReg = cabi_abi_helpers.paramReg;

const appendDirectCallWithStackArgs = x86_64_emit.appendDirectCallWithStackArgs;
const appendIndirectCallRaxWithStackArgs = x86_64_emit.appendIndirectCallRaxWithStackArgs;
const appendStackFrame = x86_64_emit.appendStackFrame;
const appendStackFrameEnd = x86_64_emit.appendStackFrameEnd;

const callIsFastcc = x86_64_match.callIsFastcc;
const isNamed = x86_64_match.isNamed;
const validateDefaultCallConv = x86_64_match.validateDefaultCallConv;
const aggregate_classification = @import("cabi_aggregate_classification.zig");
const aggregate_fields = @import("cabi_aggregate_fields.zig");
const x86_64SysVDataLayout = aggregate_classification.x86_64SysVDataLayout;
const classifySysVAggregate = aggregate_classification.classifySysVAggregate;
const isI64LeafAggregate = aggregate_classification.isI64LeafAggregate;
const sysvAggregateRegisterNeedsBefore = aggregate_classification.sysvAggregateRegisterNeedsBefore;
const AggregateIntegerFieldLoad = aggregate_fields.AggregateIntegerFieldLoad;
const AggregateIntegerAddTerm = aggregate_fields.AggregateIntegerAddTerm;
const AggregateDoubleFieldLoad = aggregate_fields.AggregateDoubleFieldLoad;
const AggregateDoubleAddTerm = aggregate_fields.AggregateDoubleAddTerm;
const AggregateFloatFieldLoad = aggregate_fields.AggregateFloatFieldLoad;
const AggregateFloatAddTerm = aggregate_fields.AggregateFloatAddTerm;
const collectAggregateFloatAddTerms = aggregate_fields.collectAggregateFloatAddTerms;
const collectAggregateDoubleAddTerms = aggregate_fields.collectAggregateDoubleAddTerms;
const aggregateGepByteOffset = aggregate_fields.aggregateGepByteOffset;
const aggregateFieldIndexAtOffset = aggregate_fields.aggregateFieldIndexAtOffset;
const collectAggregateIntegerAddTerms = aggregate_fields.collectAggregateIntegerAddTerms;
const emitAggregateIntegerTerm = aggregate_fields.emitAggregateIntegerTerm;
const emitAggregateDoubleTerm = aggregate_fields.emitAggregateDoubleTerm;
const emitAggregateFloatTerm = aggregate_fields.emitAggregateFloatTerm;
const appendLoadStackDispRax = aggregate_fields.appendLoadStackDispRax;
const appendAddStackDispRax = aggregate_fields.appendAddStackDispRax;
const stackAggregateByteDisp = aggregate_fields.stackAggregateByteDisp;
const emitSysVAggregateFieldOffsetReturn = aggregate_fields.emitSysVAggregateFieldOffsetReturn;

pub fn lowerSysVAggregateFieldReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 }) and !ret.ty.eql(.float) and !ret.ty.eql(.double)) or
        (block.instructions.items.len != 3 and block.instructions.items.len != 4)) return false;
    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const maybe_gep_inst: ?ir.Instruction = if (block.instructions.items.len == 4) block.instructions.items[2] else null;
    const load_inst = block.instructions.items[block.instructions.items.len - 1];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed) return false;
    if (maybe_gep_inst) |gep_inst| if (gep_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const classification = classifySysVAggregate(alloca.allocated_ty) catch return false;
    if (classification.kind != .register or classification.eightbyte_count == 0) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(alloca.allocated_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(ret.ty) or load.attrs.isBarrier()) return false;

    const layout = try x86_64SysVDataLayout();
    const field_offset = if (maybe_gep_inst) |gep_inst| blk: {
        const gep_name = gep_inst.result orelse return false;
        if (!isNamed(load.ptr, gep_name)) return false;
        const gep = switch (gep_inst.kind) {
            .gep => |gep| gep,
            else => return false,
        };
        if (!isNamed(gep.ptr, alloca_name)) return false;
        break :blk aggregateGepByteOffset(layout, alloca.allocated_ty, gep) orelse return false;
    } else blk: {
        if (!isNamed(load.ptr, alloca_name)) return false;
        break :blk @as(u64, 0);
    };
    _ = aggregateFieldIndexAtOffset(alloca.allocated_ty, field_offset, load.ty) orelse return false;

    try emitSysVAggregateFieldOffsetReturn(allocator, machine, function, param_name, alloca.allocated_ty, field_offset, load.ty);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRegisterAggregateCallIntegerFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 })) or !function.ret_ty.eql(ret.ty)) return false;
    if (block.instructions.items.len < 6) return false;

    const call_inst = block.instructions.items[0];
    const alloca_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (call_inst.removed or alloca_inst.removed or store_inst.removed) return false;

    const call_result = call_inst.result orelse return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.inline_asm != null or call.tail_kind != null or call.callee_value != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    const aggregate_ty = call.ret_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(aggregate_ty)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.value, call_result) or !isNamed(store.ptr, alloca_name)) return false;

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateIntegerFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[3..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(ret.ty) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .add or !binary.ty.eql(ret.ty)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateIntegerAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateIntegerAddTerms(block, ret.value orelse return error.InvalidRet, ret.ty, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;
    sortAggregateIntegerTerms(terms[0..term_count]);

    const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
        error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
        else => if (sysv_abi.isBoundaryError(err)) return false else return err,
    };
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try emitAggregateIntegerReturnTerm(allocator, machine, classification, terms[0], ret.ty, true);
    for (terms[1..term_count]) |term| {
        try emitAggregateIntegerReturnTerm(allocator, machine, classification, term, ret.ty, false);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn sortAggregateIntegerTerms(terms: []AggregateIntegerAddTerm) void {
    var index: usize = 1;
    while (index < terms.len) : (index += 1) {
        var cursor = index;
        while (cursor > 0 and terms[cursor - 1].offset > terms[cursor].offset) : (cursor -= 1) {
            std.mem.swap(AggregateIntegerAddTerm, &terms[cursor - 1], &terms[cursor]);
        }
    }
}

fn emitAggregateIntegerReturnTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    classification: SysVAggregateClassification,
    term: AggregateIntegerAddTerm,
    ty: ir.Type,
    first: bool,
) !void {
    if (classification.kind != .register) return error.UnsupportedCodegenAbi;
    const field_eightbyte = term.offset / 8;
    if (field_eightbyte >= classification.eightbytes.len) return error.UnsupportedCodegenAbi;
    const field_class = classification.eightbytes[@intCast(field_eightbyte)] orelse return error.UnsupportedCodegenAbi;
    if (field_class != .integer) return error.UnsupportedCodegenAbi;
    const prior = sysvAggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
    const offset_in_eightbyte = term.offset % 8;

    if (ty.eql(.{ .int = 64 })) {
        if (offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
        switch (prior.gpr) {
            0 => if (!first) return error.UnsupportedCodegenAbi,
            1 => if (first)
                try machine.instructions.append(allocator, .{ .mov_arg_rax = .rdx })
            else
                try machine.instructions.append(allocator, .{ .add_arg64_rax = .rdx }),
            else => return error.UnsupportedCodegenAbi,
        }
        return;
    }

    if (!ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenAbi;
    switch (prior.gpr) {
        0 => switch (offset_in_eightbyte) {
            0 => if (!first) return error.UnsupportedCodegenAbi,
            4 => if (first) {
                try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
            } else {
                return error.UnsupportedCodegenAbi;
            },
            else => return error.UnsupportedCodegenAbi,
        },
        1 => switch (offset_in_eightbyte) {
            0 => if (first)
                try machine.instructions.append(allocator, .{ .mov_arg_rax = .rdx })
            else
                try machine.instructions.append(allocator, .{ .add_arg64_rax = .rdx }),
            4 => return error.UnsupportedCodegenAbi,
            else => return error.UnsupportedCodegenAbi,
        },
        else => return error.UnsupportedCodegenAbi,
    }
}

pub fn lowerRegisterAggregateIntegerFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 })) or !function.ret_ty.eql(ret.ty)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateIntegerFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(ret.ty) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .add or !binary.ty.eql(ret.ty)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateIntegerAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateIntegerAddTerms(block, ret.value orelse return error.InvalidRet, ret.ty, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;

    try emitAggregateIntegerTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], ret.ty, true);
    for (terms[1..term_count]) |term| {
        try emitAggregateIntegerTerm(allocator, machine, function, param_name, aggregate_ty, term, ret.ty, false);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRegisterAggregateFloatFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.float) or !function.ret_ty.eql(.float)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateFloatFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.float) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .fadd or !binary.ty.eql(.float)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateFloatAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateFloatAddTerms(block, ret.value orelse return error.InvalidRet, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;
    sortAggregateFloatTerms(terms[0..term_count]);

    if (term_count > 2 and try lowerSseF32AggregateStackedSum(allocator, machine, function, param_name, aggregate_ty, terms[0..term_count])) {
        return true;
    }

    try emitAggregateFloatTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], .xmm0);
    for (terms[1..term_count]) |term| {
        try emitAggregateFloatTerm(allocator, machine, function, param_name, aggregate_ty, term, .xmm1);
        try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSseF32AggregateStackedSum(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    terms: []const AggregateFloatAddTerm,
) !bool {
    if (function.params.items.len == 0 or !std.mem.eql(u8, function.params.items[0].name, param_name)) return false;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register or classification.eightbyte_count != 2 or
        classification.eightbytes[0] != .sse or classification.eightbytes[1] != .sse)
    {
        return false;
    }
    if (terms.len > 4) return error.UnsupportedCodegenAbi;

    try appendStackFrame(allocator, machine, 24);
    try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try reloadF32AggregateTerm(allocator, machine, terms[0], .xmm0);
    for (terms[1..]) |term| {
        try reloadF32AggregateTerm(allocator, machine, term, .xmm1);
        try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    }
    try appendStackFrameEnd(allocator, machine, 24);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn reloadF32AggregateTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    term: AggregateFloatAddTerm,
    reg: XmmReg,
) !void {
    if (term.offset % 4 != 0) return error.UnsupportedCodegenAbi;
    const frame_index = FrameIndex.fromSlot(term.offset / 4) catch return error.UnsupportedCodegenAbi;
    try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = reg, .frame_index = frame_index } });
}

fn sortAggregateFloatTerms(terms: []AggregateFloatAddTerm) void {
    var index: usize = 1;
    while (index < terms.len) : (index += 1) {
        var cursor = index;
        while (cursor > 0 and terms[cursor - 1].offset > terms[cursor].offset) : (cursor -= 1) {
            std.mem.swap(AggregateFloatAddTerm, &terms[cursor - 1], &terms[cursor]);
        }
    }
}

pub fn lowerRegisterAggregateDoubleFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.double) or !function.ret_ty.eql(.double)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateDoubleFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.double) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .fadd or !binary.ty.eql(.double)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [2]AggregateDoubleAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateDoubleAddTerms(block, ret.value orelse return error.InvalidRet, field_loads, &terms, &term_count)) return false;
    if (term_count != 2) return false;

    try emitAggregateDoubleTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], .xmm0);
    try emitAggregateDoubleTerm(allocator, machine, function, param_name, aggregate_ty, terms[1], .xmm1);
    try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerMemoryIntegerAggregateFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1) return false;
    const aggregate_ty = function.params.items[0].ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .memory or !isI64LeafAggregate(aggregate_ty)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(aggregate_ty)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name) or
        !isNamed(store.value, function.params.items[0].name)) return false;

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateIntegerFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                const total_offset = base_offset + offset;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, total_offset, .{ .int = 64 }) orelse return false;
                try pointer_offsets.put(result, total_offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .add or !binary.ty.eql(.{ .int = 64 })) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateIntegerAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateIntegerAddTerms(block, ret.value orelse return error.InvalidRet, .{ .int = 64 }, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;

    try appendLoadStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, terms[0].offset, .{ .int = 64 }));
    for (terms[1..term_count]) |term| {
        try appendAddStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, term.offset, .{ .int = 64 }));
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRegisterAggregateCallFieldReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty)) return false;
    if (!(ret.ty.eql(.{ .int = 64 }) or ret.ty.eql(.{ .int = 32 }) or ret.ty.eql(.float) or ret.ty.eql(.double))) return false;
    if (block.instructions.items.len != 4 and block.instructions.items.len != 5) return false;

    const call_inst = block.instructions.items[0];
    const alloca_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (call_inst.removed or alloca_inst.removed or store_inst.removed) return false;

    const call_result = call_inst.result orelse return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.inline_asm != null or call.tail_kind != null or call.callee_value != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    const aggregate_ty = call.ret_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(aggregate_ty)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.value, call_result) or !isNamed(store.ptr, alloca_name)) return false;

    const field_offset: u64 = if (block.instructions.items.len == 4) offset: {
        const load_inst = block.instructions.items[3];
        const load_name = validateAggregateFieldLoad(load_inst, ret.ty, alloca_name) orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;
        break :offset 0;
    } else offset: {
        const gep_inst = block.instructions.items[3];
        const load_inst = block.instructions.items[4];
        if (gep_inst.removed or load_inst.removed) return false;
        const gep_name = gep_inst.result orelse return false;
        const gep = switch (gep_inst.kind) {
            .gep => |gep| gep,
            else => return false,
        };
        if (!isNamed(gep.ptr, alloca_name)) return false;
        const computed_offset = aggregateGepByteOffset(try x86_64SysVDataLayout(), aggregate_ty, gep) orelse return false;
        const load_name = validateAggregateFieldLoad(load_inst, ret.ty, gep_name) orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;
        break :offset computed_offset;
    };
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, ret.ty) orelse return false;

    const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
        error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
        else => if (sysv_abi.isBoundaryError(err)) return false else return err,
    };
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try emitSysVAggregateReturnField(allocator, machine, classification, field_offset, ret.ty);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateAggregateFieldLoad(instruction: ir.Instruction, ty: ir.Type, ptr_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(ty) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return null;
    return name;
}

fn emitSysVAggregateReturnField(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    classification: SysVAggregateClassification,
    field_offset: u64,
    field_ty: ir.Type,
) !void {
    if (classification.kind != .register) return error.UnsupportedCodegenAbi;
    const field_eightbyte = field_offset / 8;
    if (field_eightbyte >= classification.eightbytes.len) return error.UnsupportedCodegenAbi;
    const field_class = classification.eightbytes[@intCast(field_eightbyte)] orelse return error.UnsupportedCodegenAbi;
    const prior = sysvAggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
    return switch (field_class) {
        .integer => emitSysVIntegerAggregateReturnField(allocator, machine, prior.gpr, field_offset % 8, field_ty),
        .sse => emitSysVSseAggregateReturnField(allocator, machine, prior.sse, field_offset % 8, field_ty),
    };
}

fn emitSysVIntegerAggregateReturnField(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    return_gpr_index: usize,
    offset_in_eightbyte: u64,
    field_ty: ir.Type,
) !void {
    if (field_ty.eql(.{ .int = 64 })) {
        if (offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
        switch (return_gpr_index) {
            0 => {},
            1 => try machine.instructions.append(allocator, .{ .mov_arg_rax = .rdx }),
            else => return error.UnsupportedCodegenAbi,
        }
        return;
    }
    if (field_ty.eql(.{ .int = 32 })) {
        switch (return_gpr_index) {
            0 => {
                if (offset_in_eightbyte == 4) {
                    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
                } else if (offset_in_eightbyte != 0) {
                    return error.UnsupportedCodegenAbi;
                }
            },
            1 => {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = .rdx });
                if (offset_in_eightbyte == 4) {
                    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
                } else if (offset_in_eightbyte != 0) {
                    return error.UnsupportedCodegenAbi;
                }
            },
            else => return error.UnsupportedCodegenAbi,
        }
        return;
    }
    return error.UnsupportedCodegenAbi;
}

fn emitSysVSseAggregateReturnField(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    return_sse_index: usize,
    offset_in_eightbyte: u64,
    field_ty: ir.Type,
) !void {
    const source = switch (return_sse_index) {
        0 => XmmReg.xmm0,
        1 => XmmReg.xmm1,
        else => return error.UnsupportedCodegenAbi,
    };
    if (field_ty.eql(.double)) {
        if (offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
        switch (source) {
            .xmm0 => {},
            .xmm1 => try machine.instructions.append(allocator, .movapd_xmm1_xmm0),
            .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = source } }),
        }
        return;
    }
    if (field_ty.eql(.float)) {
        switch (source) {
            .xmm0 => {},
            .xmm1, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = source } }),
        }
        if (offset_in_eightbyte == 4) {
            try machine.instructions.append(allocator, .{ .shufps_high_f32_to_low = .xmm0 });
        } else if (offset_in_eightbyte != 0) {
            return error.UnsupportedCodegenAbi;
        }
        return;
    }
    return error.UnsupportedCodegenAbi;
}

pub fn lowerRegisterAggregateDirectCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .register) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(function.ret_ty) or call.inline_asm != null) return false;
    if (call.tail_kind != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        const stack_arg_count = if (sysv_abi.callHasByvalArgAttrs(call)) count: {
            const count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
                error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
                else => if (sysv_abi.isBoundaryError(err)) return false else return err,
            };
            try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
            break :count count;
        } else count: {
            try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
            break :count appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
                error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
                else => if (sysv_abi.isBoundaryError(err)) return false else return err,
            };
        };
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
        error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
        else => if (sysv_abi.isBoundaryError(err)) return false else return err,
    };
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    return true;
}
