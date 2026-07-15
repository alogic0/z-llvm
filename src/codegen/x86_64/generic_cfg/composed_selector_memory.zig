const std = @import("std");
const ir = @import("../../../ir.zig");
const constant_table = @import("../constant_table.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const selector_fp = @import("composed_selector_fp.zig");
const aggregate_object = @import("aggregate_object.zig");

pub const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const MachineBinaryOp = x86_64_types.MachineBinaryOp;
const PairSpillLoc = selector_types.PairSpillLoc;
const RegPair = selector_types.RegPair;
const StackArrayLoc = selector_types.StackArrayLoc;
const StackPtrLoc = selector_types.StackPtrLoc;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualReg = selector_types.VirtualReg;
const VirtualRegClass = selector_types.VirtualRegClass;
const VirtualRegMetadata = selector_types.VirtualRegMetadata;
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const selector_allocatable_pairs = selector_types.selector_allocatable_pairs;
const selector_allocatable_regs = selector_types.selector_allocatable_regs;
const argRegIndex = selector_types.argRegIndex;

pub const Diagnostic = inspection.Diagnostic;
pub const SelectionResult = inspection.SelectionResult;

const NameSet = stage2_planning.NameSet;
const PlannedValueAssignment = stage2_planning.PlannedValueAssignment;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const SelectorValueInterval = stage2_planning.SelectorValueInterval;
const SpillSlotAssignment = stage2_planning.SpillSlotAssignment;
const allocateSelectorIntervals = stage2_planning.allocateSelectorIntervals;
const analyzeStageTwoNoSpillEnvelope = stage2_planning.analyzeStageTwoNoSpillEnvelope;
const buildSelectorAllocationPlan = stage2_planning.buildSelectorAllocationPlan;
const namedValue = stage2_planning.namedValue;
const selectorValueMetadata = stage2_planning.selectorValueMetadata;
const stage2_max_blocks = stage2_planning.stage2_max_blocks;
const phi_regs = [_]ArgReg{ .r8, .r9, .rcx };

const blockHasPhiIncomingFrom = composed_helpers.blockHasPhiIncomingFrom;
const phiIncomingFrom = composed_helpers.phiIncomingFrom;
const canUseExpiredPlanRegisterReuse = composed_helpers.canUseExpiredPlanRegisterReuse;
const machineBinaryOp = composed_helpers.machineBinaryOp;
const isCommutative = composed_helpers.isCommutative;
const locIsAccumulator = composed_helpers.locIsAccumulator;
const valueLocEql = composed_helpers.valueLocEql;
const locContainsReg = composed_helpers.locContainsReg;
const valueIsInt = composed_helpers.valueIsInt;
const intBits = composed_helpers.intBits;
const callArgRegisterCount = composed_helpers.callArgRegisterCount;
const isDefaultOrFastcc = composed_helpers.isDefaultOrFastcc;
const parseI32ArrayType = composed_helpers.parseI32ArrayType;
const isComposedReturnType = composed_helpers.isComposedReturnType;
const shiftAmount5 = composed_helpers.shiftAmount5;
const shiftAmount6 = composed_helpers.shiftAmount6;
const shiftAmount7 = composed_helpers.shiftAmount7;
const i32Value = composed_helpers.i32Value;
const i32BitPattern = composed_helpers.i32BitPattern;
const i64Value = composed_helpers.i64Value;

pub const ComposedBlockSelector = selector_state.ComposedBlockSelector;

pub fn lowerAlloca(selector: *ComposedBlockSelector, result: ?[]const u8, alloca: ir.AllocaInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const loc = selector_state.valueLoc(selector, result_name) orelse return .{ .no_emitter = "composed-block-alloca-unplanned" };
    switch (loc) {
        .stack_scalar => |stack| {
            const integer_bits = if (alloca.allocated_ty == .ptr) @as(?u16, 64) else intBits(alloca.allocated_ty);
            const fp_bits = scalarFpStoreBits(alloca.allocated_ty);
            const bits = integer_bits orelse fp_bits orelse return .{ .no_emitter = "composed-block-alloca-plan-type" };
            const expected_kind: selector_types.StackScalarLoc.Kind = if (fp_bits != null) .fp else .integer;
            if (stack.bits != bits or stack.kind != expected_kind) return .{ .no_emitter = "composed-block-alloca-plan-type" };
        },
        .stack128 => if (!alloca.allocated_ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-alloca-plan-type" },
        .stack_i32_array => |stack_array| {
            const len = parseI32ArrayType(alloca.allocated_ty) orelse return .{ .no_emitter = "composed-block-alloca-plan-type" };
            if (stack_array.len != len) return .{ .no_emitter = "composed-block-alloca-plan-type" };
        },
        .stack_f32_pair_ptr => if (!aggregate_object.isF32PairType(selector.module_context, alloca.allocated_ty)) return .{ .no_emitter = "composed-block-alloca-plan-type" },
        .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .xmm, .stack128_value, .stack_i32_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-alloca-plan-loc" },
    }
    return null;
}

pub fn lowerLoad(selector: *ComposedBlockSelector, result: ?[]const u8, load: ir.LoadInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (load.attrs.isBarrier()) return .{ .no_emitter = "composed-block-load-barrier" };
    if (selector_state.resolveValue(selector, load.ptr)) |ptr| if (ptr == .readonly_table_ptr)
        return lowerReadOnlyTableLoad(selector, result_name, load, ptr.readonly_table_ptr);
    if (load.ptr == .named and selector.readonly_pointer_params.contains(load.ptr.named)) {
        if (intBits(load.ty)) |bits| {
            const exact_ei = if (selector.function) |function| stage2_planning.isExactEiScalarFamily(function.*) else false;
            if (exact_ei or bits == 64 or bits == 96 or bits == 128)
                return lowerReadOnlyPointerIntegerLoad(selector, result_name, load, bits);
        }
    }
    if (isF32x2(load.ty)) return lowerLoadF32Pair(selector, result_name, load);
    if (scalarFpBits(load.ty)) |bits| return lowerLoadFp(selector, result_name, load, bits);
    if (!load.ty.eql(.{ .int = 8 }) and !load.ty.eql(.{ .int = 16 }) and !load.ty.eql(.{ .int = 32 }) and !load.ty.eql(.{ .int = 64 }) and !load.ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-load-width" };
    const ptr = selector_state.resolveValue(selector, load.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-load-ptr" };
    switch (ptr) {
        .stack_scalar => |stack| {
            if (stack.bits == 64 and load.ty.eql(.{ .int = 64 })) {
                try loadStackU64IntoRax(selector, stack.base_disp);
                try selector_state.bindRax(selector, result_name);
            } else if (stack.bits == 8 and load.ty.eql(.{ .int = 8 })) {
                try selector_state.clobberAccumulator(selector);
                if (stack.base_disp <= std.math.maxInt(u8)) {
                    try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_u8_eax = @intCast(stack.base_disp) });
                } else {
                    try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_u8_eax = stack.base_disp });
                }
                try selector_state.bindEax(selector, result_name);
            } else return .{ .no_emitter = "composed-block-load-stack-width" };
        },
        .stack128 => |disp| {
            if (!load.ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-load-stack-width" };
            try selector_state.bindValueLoc(selector, result_name, .{ .stack128_value = disp });
        },
        .stack_i32_ptr => |stack_ptr| {
            if (!load.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-load-stack-array-width" };
            try appendLoadStackI32(selector, stack_ptr);
            try selector_state.bindEax(selector, result_name);
        },
        .stack_i32_array => |stack_array| {
            if (!load.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-load-stack-array-width" };
            try appendLoadStackI32(selector, .{ .disp = stack_array.base_disp });
            try selector_state.bindEax(selector, result_name);
        },
        .arg64, .scratch64 => |reg| {
            if (!load.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-load-ptr-width" };
            try selector_state.clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_eax = reg });
            try selector_state.bindEax(selector, result_name);
        },
        .spill64 => |frame_index| {
            if (!load.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-load-ptr-width" };
            try selector_state.clobberAccumulator(selector);
            try selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx });
            try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_eax = .rcx });
            try selector_state.bindEax(selector, result_name);
        },
        .arg32, .arg128, .xmm, .eax, .rax, .scratch32, .scratch128, .stack128_value, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-load-ptr" },
    }
    return null;
}

pub fn lowerStore(selector: *ComposedBlockSelector, store: ir.StoreInst) !?Diagnostic {
    if (store.attrs.isBarrier()) return .{ .no_emitter = "composed-block-store-barrier" };
    if (store.ptr == .named and selector.readonly_pointer_params.contains(store.ptr.named))
        return .{ .no_emitter = "composed-block-store-readonly-param" };
    if (scalarFpStoreBits(store.ty)) |bits| return lowerStoreFp(selector, store, bits);
    if (store.ty == .ptr) return lowerStoreStackPointer(selector, store);
    if (!store.ty.eql(.{ .int = 1 }) and !store.ty.eql(.{ .int = 32 }) and !store.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-store-width" };
    const ptr = selector_state.resolveValue(selector, store.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
    const value_loc = switch (store.value) {
        .named => selector_state.resolveValue(selector, store.value) orelse return .{ .unsupported_value = "composed-block-unknown-store-value" },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
    const value_detail = if (value_loc) |loc| switch (loc) {
        .arg32, .arg64 => "composed-block-store-value-arg",
        .scratch32, .scratch64 => "composed-block-store-value-scratch",
        .eax, .rax => "composed-block-store-value-accumulator",
        .spill64 => "composed-block-store-value-spill",
        .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => "composed-block-store-value-other",
    } else "composed-block-store-value-other";
    if (store.ty.eql(.{ .int = 64 })) return lowerStoreI64(selector, ptr, store.value, value_detail);
    selector_state.emitValueIntoEax(selector, store.value) catch return .{ .unsupported_value = value_detail };
    switch (ptr) {
        .stack_scalar => |stack| {
            if (stack.bits != 8 or !store.ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-store-stack-width" };
            if (stack.base_disp <= std.math.maxInt(u8)) {
                try selector.machine.instructions.append(selector.allocator, .{ .store_al_stack_disp8 = @intCast(stack.base_disp) });
            } else {
                try selector.machine.instructions.append(selector.allocator, .{ .store_al_stack_disp32 = stack.base_disp });
            }
        },
        .arg64, .scratch64 => |reg| {
            if (!store.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-store-ptr-width" };
            try selector.machine.instructions.append(selector.allocator, .{ .store_eax_arg_ptr = reg });
        },
        .stack_i32_ptr => |stack_ptr| {
            if (!store.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-store-ptr-width" };
            appendStoreStackI32(selector, stack_ptr) catch |err| switch (err) {
                error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-store-stack-index" },
                else => return err,
            };
        },
        .stack_i32_array => |stack_array| {
            if (!store.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-store-ptr-width" };
            appendStoreStackI32(selector, .{ .disp = stack_array.base_disp }) catch |err| switch (err) {
                error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-store-array-index" },
                else => return err,
            };
        },
        .spill64 => |frame_index| {
            if (!store.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-store-ptr-width" };
            selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx }) catch |err| switch (err) {
                error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-store-spill-ptr" },
                else => return err,
            };
            try selector.machine.instructions.append(selector.allocator, .{ .store_eax_arg_ptr = .rcx });
        },
        .readonly_table_ptr => return .{ .no_emitter = "composed-block-store-readonly-table" },
        .arg32, .scratch32, .arg128, .scratch128, .xmm, .eax, .rax, .stack128, .stack128_value, .stack_f32_pair_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-store-ptr" },
    }
    return null;
}

fn lowerReadOnlyPointerIntegerLoad(selector: *ComposedBlockSelector, result_name: []const u8, load: ir.LoadInst, bits: u16) !?Diagnostic {
    if (load.ty_addrspace != null or load.ptr_addrspace != null) return .{ .no_emitter = "composed-block-load-readonly-param-addrspace" };
    const ptr_name = switch (load.ptr) {
        .named => |name| name,
        else => return .{ .no_emitter = "composed-block-load-readonly-param-provenance" },
    };
    if (!selector.readonly_pointer_params.contains(ptr_name)) return .{ .no_emitter = "composed-block-load-ptr-width" };
    const ptr = selector_state.resolveValue(selector, load.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-load-ptr" };
    var ptr_reg: ArgReg = switch (ptr) {
        .arg64, .scratch64 => |reg| reg,
        .spill64 => |frame_index| blk: {
            selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rdi }) catch
                return .{ .unsupported_value = "composed-block-load-readonly-param-spill" };
            break :blk .rdi;
        },
        else => return .{ .no_emitter = "composed-block-load-readonly-param-provenance" },
    };
    try selector_state.clobberAccumulator(selector);
    if (bits == 8 or bits == 16 or bits == 32) {
        try selector.machine.instructions.append(selector.allocator, switch (bits) {
            8 => .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = ptr_reg, .offset = 0 } },
            16 => .{ .load_arg_ptr_disp8_u16_eax = .{ .reg = ptr_reg, .offset = 0 } },
            32 => .{ .load_arg_ptr_disp8_eax = .{ .reg = ptr_reg, .offset = 0 } },
            else => unreachable,
        });
        try selector_state.bindEax(selector, result_name);
        return null;
    }
    if (bits == 56) {
        const scratch: ArgReg = if (ptr_reg == .rcx) .r8 else .rcx;
        try selector_state.clobberArgReg(selector, scratch);
        try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_u16_eax = .{ .reg = ptr_reg, .offset = 4 } });
        try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = 32 });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = scratch });
        try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = ptr_reg, .offset = 6 } });
        try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = 48 });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = scratch } });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = scratch });
        try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_eax = .{ .reg = ptr_reg, .offset = 0 } });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = scratch } });
        try selector_state.bindRax(selector, result_name);
        return null;
    }
    if (bits == 64) {
        try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = ptr_reg, .offset = 0 } });
        try selector_state.bindRax(selector, result_name);
        return null;
    }

    if (bits != 96 and bits != 128) return .{ .no_emitter = "composed-block-load-width" };
    const pair = selector_state.choosePairScratchForClobber(selector, null) orelse
        return .{ .no_spill_envelope = "composed-block-load-readonly-param-pair" };
    if (pair.contains(ptr_reg)) {
        selector_state.materializeLocIntoLoc(selector, ptr, .{ .scratch64 = .rdi }) catch
            return .{ .unsupported_value = "composed-block-load-readonly-param-alias" };
        ptr_reg = .rdi;
    }
    try selector_state.clobberArgReg(selector, pair.lo);
    try selector_state.clobberArgReg(selector, pair.hi);
    try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = ptr_reg, .offset = 0 } });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = pair.lo });
    if (bits == 96) {
        try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_eax = .{ .reg = ptr_reg, .offset = 8 } });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = ptr_reg, .offset = 8 } });
    }
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = pair.hi });
    try selector_state.bindResultLoc(selector, result_name, .{ .scratch128 = pair });
    return null;
}

fn lowerStoreStackPointer(selector: *ComposedBlockSelector, store: ir.StoreInst) !?Diagnostic {
    if (store.ty_addrspace != null or store.ptr_addrspace != null) return .{ .no_emitter = "composed-block-store-stack-pointer-addrspace" };
    const ptr = selector_state.resolveValue(selector, store.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
    const destination = switch (ptr) {
        .stack_scalar => |stack| if (stack.bits == 64 and stack.kind == .integer) stack else return .{ .no_emitter = "composed-block-store-stack-pointer-width" },
        else => return .{ .no_emitter = "composed-block-store-stack-pointer-ptr" },
    };
    const value = selector_state.resolveValue(selector, store.value) orelse return .{ .unsupported_value = "composed-block-store-stack-pointer-value" };
    const source = switch (value) {
        .stack_scalar => |stack| stack,
        else => return .{ .no_emitter = "composed-block-store-stack-pointer-value" },
    };

    try selector_state.clobberArgReg(selector, .rcx);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = .rcx });
    if (source.base_disp != 0) {
        try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = @intCast(source.base_disp) } });
    }
    if (destination.base_disp % 4 != 0) return .{ .no_emitter = "composed-block-store-stack-pointer-align" };
    const frame_index = x86_64_types.FrameIndex.fromSlot(destination.base_disp / 4) catch return .{ .no_emitter = "composed-block-store-stack-pointer-frame" };
    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = .rcx } });
    return null;
}

fn scalarFpBits(ty: ir.Type) ?u16 {
    return if (ty == .float) 32 else if (ty == .double) 64 else null;
}

fn scalarFpStoreBits(ty: ir.Type) ?u16 {
    return if (ty == .half) 16 else scalarFpBits(ty);
}

fn lowerLoadFp(selector: *ComposedBlockSelector, result_name: []const u8, load: ir.LoadInst, bits: u16) !?Diagnostic {
    if (load.ty_addrspace != null or load.ptr_addrspace != null) return .{ .no_emitter = "composed-block-load-fp-addrspace" };
    const ptr = selector_state.resolveValue(selector, load.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-load-ptr" };
    const stack = switch (ptr) {
        .stack_scalar => |stack| stack,
        else => return .{ .no_emitter = "composed-block-load-fp-ptr" },
    };
    if (stack.kind != .fp or stack.bits != bits) return .{ .no_emitter = "composed-block-load-stack-width" };

    try selector_state.clobberXmmReg(selector, .xmm0);
    if (bits == 32) {
        if (stack.base_disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_xmm0_f32 = @intCast(stack.base_disp) });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_xmm0_f32 = stack.base_disp });
        }
    } else if (bits == 64) {
        if (stack.base_disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_xmm0 = @intCast(stack.base_disp) });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_xmm0 = stack.base_disp });
        }
    } else unreachable;
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = bits } });
    return null;
}

fn lowerLoadF32Pair(selector: *ComposedBlockSelector, result_name: []const u8, load: ir.LoadInst) !?Diagnostic {
    if (load.ty_addrspace != null or load.ptr_addrspace != null) return .{ .no_emitter = "composed-block-load-f32-pair-addrspace" };
    const view = aggregatePointerView(selector, load.ptr) orelse return .{ .no_emitter = "composed-block-load-f32-pair-ptr" };
    if (view.offset != 0 or !view.allows(aggregate_object.byte_size)) return .{ .no_emitter = "composed-block-load-f32-pair-bounds" };
    const ptr = selector_state.resolveValue(selector, load.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-load-ptr" };
    try selector_state.clobberXmmReg(selector, .xmm0);
    switch (ptr) {
        .stack_f32_pair_ptr => |stack| {
            if (stack.disp <= std.math.maxInt(u8)) {
                try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_xmm0 = @intCast(stack.disp) });
            } else {
                try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_xmm0 = stack.disp });
            }
        },
        .arg64, .scratch64 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_xmm = .{ .base = reg, .dst = .xmm0, .offset = 0 } }),
        .spill64 => |frame_index| {
            try selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx });
            try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_xmm = .{ .base = .rcx, .dst = .xmm0, .offset = 0 } });
        },
        else => return .{ .no_emitter = "composed-block-load-f32-pair-ptr" },
    }
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{
        .reg = .xmm0,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f32x2(0b11) },
    } });
    return null;
}

fn lowerStoreFp(selector: *ComposedBlockSelector, store: ir.StoreInst, bits: u16) !?Diagnostic {
    if (store.ty_addrspace != null or store.ptr_addrspace != null) return .{ .no_emitter = "composed-block-store-fp-addrspace" };
    const ptr = selector_state.resolveValue(selector, store.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
    if (aggregatePointerView(selector, store.ptr)) |view| {
        if (bits != 32 or !view.allows(4)) return .{ .no_emitter = "composed-block-store-f32-pair-bounds" };
        if (try selector_fp.materializeFpValue(selector, store.value, .xmm0, bits)) |diagnostic| return diagnostic;
        switch (ptr) {
            .stack_f32_pair_ptr => |stack| {
                if (stack.disp % 4 != 0) return .{ .no_emitter = "composed-block-store-f32-pair-align" };
                const frame_index = FrameIndex.fromSlot(stack.disp / 4) catch return .{ .no_spill_envelope = "composed-block-store-f32-pair-frame" };
                try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm32_rsp = .{ .frame_index = frame_index, .reg = .xmm0 } });
            },
            .arg64, .scratch64 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = reg, .offset = 0 } }),
            .spill64 => |frame_index| {
                try selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx });
                try selector.machine.instructions.append(selector.allocator, .{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = .rcx, .offset = 0 } });
            },
            else => return .{ .no_emitter = "composed-block-store-f32-pair-ptr" },
        }
        return null;
    }
    if (ptr == .stack_scalar) {
        const stack = ptr.stack_scalar;
        if (stack.kind != .fp or stack.bits != bits) return .{ .no_emitter = "composed-block-store-stack-width" };
        if (try selector_fp.materializeFpValue(selector, store.value, .xmm0, bits)) |diagnostic| return diagnostic;

        if (bits == 16) {
            try selector_state.clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, .{ .movd_xmm_eax = .xmm0 });
            try selector_state.clobberArgReg(selector, .rcx);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = .rcx });
            if (stack.base_disp != 0) {
                try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = @intCast(stack.base_disp) } });
            }
            try selector.machine.instructions.append(selector.allocator, .store_ax_rcx_ptr);
            return null;
        }

        if (stack.base_disp % 4 != 0) return .{ .no_emitter = "composed-block-store-fp-align" };
        const frame_index = FrameIndex.fromSlot(stack.base_disp / 4) catch return .{ .no_spill_envelope = "composed-block-store-fp-frame" };
        if (bits == 32) {
            try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm32_rsp = .{ .frame_index = frame_index, .reg = .xmm0 } });
        } else if (bits == 64) {
            try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm64_rsp = .{ .frame_index = frame_index, .reg = .xmm0 } });
        } else unreachable;
        return null;
    }

    const ptr_name = switch (store.ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-store-fp-ptr" },
    };
    if (!selector.abi_pointer_params.contains(ptr_name)) return .{ .no_emitter = "composed-block-store-fp-ptr" };
    if (try selector_fp.materializeFpValue(selector, store.value, .xmm0, bits)) |diagnostic| return diagnostic;
    const ptr_reg = switch (ptr) {
        .arg64, .scratch64 => |reg| reg,
        .spill64 => |frame_index| blk: {
            selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx }) catch return .{ .unsupported_value = "composed-block-store-fp-ptr" };
            break :blk .rcx;
        },
        else => return .{ .no_emitter = "composed-block-store-fp-ptr" },
    };
    if (bits == 16) {
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .movd_xmm_eax = .xmm0 });
        try selector.machine.instructions.append(selector.allocator, .{ .store_ax_arg_ptr_disp8 = .{ .reg = ptr_reg, .offset = 0 } });
    } else if (bits == 32) {
        try selector.machine.instructions.append(selector.allocator, .{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = ptr_reg, .offset = 0 } });
    } else if (bits == 64) {
        try selector.machine.instructions.append(selector.allocator, .{ .store_xmm0_arg_ptr_disp8 = .{ .reg = ptr_reg, .offset = 0 } });
    } else unreachable;
    return null;
}

fn lowerStoreI64(selector: *ComposedBlockSelector, ptr: ValueLoc, value: ir.Value, value_detail: []const u8) !?Diagnostic {
    switch (ptr) {
        .arg64, .scratch64 => |reg| try selector_state.materializeLocIntoLoc(selector, .{ .scratch64 = reg }, .{ .scratch64 = .rcx }),
        .spill64 => |frame_index| selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx }) catch |err| switch (err) {
            error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-store-spill-ptr" },
            else => return err,
        },
        .arg32, .arg128, .eax, .rax, .scratch32, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-store-ptr" },
    }
    selector_state.emitValueIntoRax(selector, value) catch return .{ .unsupported_value = value_detail };
    try selector.machine.instructions.append(selector.allocator, .store_rax_rcx_ptr);
    return null;
}

pub fn lowerGep(selector: *ComposedBlockSelector, result: ?[]const u8, gep: ir.GepInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (gep.ptr == .named and std.mem.startsWith(u8, gep.ptr.named, "@"))
        return try lowerReadOnlyTableGep(selector, result_name, gep);
    const exact_ei = if (selector.function) |function| stage2_planning.isExactEiScalarFamily(function.*) else false;
    const readonly_base = exact_ei and gep.ptr == .named and selector.readonly_pointer_params.contains(gep.ptr.named);
    if (isBytePointerSource(gep.source_ty)) {
        const diagnostic = try lowerBytePointerGep(selector, result_name, gep);
        if (diagnostic == null and readonly_base) try selector.readonly_pointer_params.put(result_name, {});
        return diagnostic;
    }
    if (isI32ElementPointerSource(gep.source_ty)) {
        const diagnostic = try lowerI32ElementPointerGep(selector, result_name, gep);
        if (diagnostic == null and readonly_base) try selector.readonly_pointer_params.put(result_name, {});
        return diagnostic;
    }
    const len = parseI32ArrayType(gep.source_ty) orelse return .{ .no_emitter = "composed-block-gep-source" };
    const base = selector_state.resolveValue(selector, gep.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-array-gep-ptr" };
    const stack_array = switch (base) {
        .stack_i32_array => |stack_array| stack_array,
        .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-gep-ptr" },
    };
    if (stack_array.len != len) return .{ .no_emitter = "composed-block-gep-len" };
    if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-addrspace" };
    if (gep.indices.items.len != 2) return .{ .no_emitter = "composed-block-gep-index-count" };
    const first_index = gep.indices.items[0];
    if (!first_index.ty.eql(.{ .int = 64 }) or !first_index.value.eql(.{ .int = 0 })) return .{ .no_emitter = "composed-block-gep-base-index" };
    const elem_index = gep.indices.items[1];
    if (!elem_index.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-gep-elem-index-ty" };
    const stack_ptr = switch (elem_index.value) {
        .int => |int| blk: {
            const index = std.math.cast(u32, int) orelse return .{ .no_emitter = "composed-block-gep-index-range" };
            if (index >= stack_array.len) return .{ .no_emitter = "composed-block-gep-index-range" };
            const byte_offset = std.math.mul(u32, index, 4) catch return .{ .no_spill_envelope = "composed-block-gep-offset" };
            break :blk StackPtrLoc{ .disp = stack_array.base_disp + byte_offset };
        },
        .named => |name| blk: {
            try selector_state.emitValueIntoScratch(selector, elem_index.value, .rcx, 64);
            break :blk StackPtrLoc{ .disp = stack_array.base_disp, .index = .{ .reg = .rcx, .name = name } };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-gep-dynamic-index" },
    };
    try selector_state.bindValueLoc(selector, result_name, .{ .stack_i32_ptr = stack_ptr });
    return null;
}

pub fn lowerI32ElementPointerGep(selector: *ComposedBlockSelector, result_name: []const u8, gep: ir.GepInst) !?Diagnostic {
    if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-addrspace" };
    if (gep.indices.items.len != 1) return .{ .no_emitter = "composed-block-gep-index-count" };
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-gep-elem-index-ty" };
    if (index.value != .named) return .{ .no_emitter = "composed-block-gep-index-form" };

    if (selector_state.resolveValue(selector, gep.ptr)) |base| switch (base) {
        .stack_i32_array => |stack_array| {
            selector_state.emitValueIntoScratch(selector, index.value, .rcx, 64) catch return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
            const index_name = switch (index.value) {
                .named => |name| name,
                else => unreachable,
            };
            try selector_state.bindValueLoc(selector, result_name, .{ .stack_i32_ptr = .{
                .disp = stack_array.base_disp,
                .index = .{ .reg = .rcx, .name = index_name },
            } });
            return null;
        },
        .stack_i32_ptr => |stack_ptr| {
            const stack_index = stack_ptr.index orelse return .{ .no_emitter = "composed-block-gep-ptr" };
            if (stack_index.reg != .rcx) return .{ .no_emitter = "composed-block-gep-ptr" };
            if (stack_index.addend_name != null) return .{ .no_emitter = "composed-block-gep-index-depth" };
            const addend_name = switch (index.value) {
                .named => |name| name,
                else => unreachable,
            };
            try selector_state.bindValueLoc(selector, result_name, .{ .stack_i32_ptr = .{
                .disp = stack_ptr.disp,
                .index = .{ .reg = .rcx, .name = stack_index.name, .addend_name = addend_name },
            } });
            return null;
        },
        else => {},
    };

    selector_state.emitValueIntoScratch(selector, gep.ptr, .rcx, 64) catch return .{ .unsupported_value = "composed-block-unknown-i32-element-gep-ptr" };
    selector_state.emitValueIntoScratch(selector, index.value, .r8, 64) catch return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
    try selector.machine.instructions.append(selector.allocator, .{ .shl_r8_imm6 = 2 });
    try selector.machine.instructions.append(selector.allocator, .add_r8_rcx);
    try selector_state.bindScratch(selector, result_name, .rcx, 64);
    return null;
}

pub fn lowerBytePointerGep(selector: *ComposedBlockSelector, result_name: []const u8, gep: ir.GepInst) !?Diagnostic {
    if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-addrspace" };
    if (gep.indices.items.len != 1) return .{ .no_emitter = "composed-block-gep-index-count" };
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-gep-elem-index-ty" };

    switch (index.value) {
        .int => |int| {
            const offset = std.math.cast(i32, int) orelse return .{ .no_emitter = "composed-block-gep-index-range" };
            if (selector_state.resolveValue(selector, gep.ptr)) |base| switch (base) {
                .stack_f32_pair_ptr => |ptr| {
                    const adjusted = std.math.add(i64, ptr.disp, offset) catch return .{ .no_emitter = "composed-block-gep-index-range" };
                    const disp = std.math.cast(u32, adjusted) orelse return .{ .no_emitter = "composed-block-gep-index-range" };
                    const object_end = std.math.add(u32, ptr.object_base_disp, aggregate_object.byte_size) catch return .{ .no_emitter = "composed-block-gep-index-range" };
                    if (disp < ptr.object_base_disp or disp > object_end) return .{ .no_emitter = "composed-block-gep-index-range" };
                    try selector_state.bindValueLoc(selector, result_name, .{ .stack_f32_pair_ptr = .{
                        .object_base_disp = ptr.object_base_disp,
                        .disp = disp,
                    } });
                    return null;
                },
                .readonly_table_ptr => |ptr| {
                    if (offset != 8 or ptr.offset != 0 or !ptr.shape.allowsOffset(8)) return .{ .no_emitter = "composed-block-gep-readonly-table-offset" };
                    var adjusted = ptr;
                    adjusted.offset = 8;
                    try selector_state.bindValueLoc(selector, result_name, .{ .readonly_table_ptr = adjusted });
                    return null;
                },
                .stack_i32_ptr => |stack_ptr| {
                    const adjusted = std.math.add(i64, stack_ptr.disp, offset) catch return .{ .no_emitter = "composed-block-gep-index-range" };
                    const disp = std.math.cast(u32, adjusted) orelse return .{ .no_emitter = "composed-block-gep-index-range" };
                    try selector_state.bindValueLoc(selector, result_name, .{ .stack_i32_ptr = .{ .disp = disp, .index = stack_ptr.index } });
                    return null;
                },
                else => {},
            };
            selector_state.emitValueIntoScratch(selector, gep.ptr, .rcx, 64) catch return .{ .unsupported_value = "composed-block-unknown-byte-gep-ptr" };
            if (offset != 0) try selector.machine.instructions.append(selector.allocator, .{ .add_rcx_imm32 = offset });
            try selector_state.bindScratch(selector, result_name, .rcx, 64);
        },
        .named => {
            selector_state.emitValueIntoScratch(selector, gep.ptr, .r8, 64) catch return .{ .unsupported_value = "composed-block-unknown-byte-gep-ptr" };
            selector_state.emitValueIntoScratch(selector, index.value, .rcx, 64) catch return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
            try selector.machine.instructions.append(selector.allocator, .add_r8_rcx);
            try selector_state.bindScratch(selector, result_name, .rcx, 64);
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-gep-dynamic-index" },
    }
    return null;
}

fn aggregatePointerView(selector: *const ComposedBlockSelector, value: ir.Value) ?aggregate_object.PointerView {
    const function = selector.function orelse return null;
    return aggregate_object.pointerView(function.*, selector.module_context, value);
}

fn isF32x2(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 2 and ty.vector.elem_ty == .float;
}

fn lowerReadOnlyTableGep(selector: *ComposedBlockSelector, result_name: []const u8, gep: ir.GepInst) !?Diagnostic {
    if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-readonly-table-addrspace" };
    if (gep.indices.items.len != 1) return .{ .no_emitter = "composed-block-gep-readonly-table-index-count" };
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or index.value != .named) return .{ .no_emitter = "composed-block-gep-readonly-table-index" };
    const context = selector.module_context orelse return .{ .no_emitter = "composed-block-gep-readonly-table-context" };
    var decoded = (constant_table.decodeSymbol(selector.allocator, context.*, gep.ptr.named) catch return .{ .no_emitter = "composed-block-gep-readonly-table-global" }) orelse
        return .{ .no_emitter = "composed-block-gep-readonly-table-global" };
    defer decoded.deinit(selector.allocator);
    if (!sourceStrideMatchesShape(gep.source_ty, decoded.shape)) return .{ .no_emitter = "composed-block-gep-readonly-table-source" };
    const shift = tableIndexShift(decoded.shape);
    if (!hasAdmittedIndexProof(selector, index.value.named, decoded.shape)) return .{ .no_emitter = "composed-block-gep-readonly-table-range" };

    selector_state.emitValueIntoScratch(selector, index.value, .r8, 64) catch return .{ .unsupported_value = "composed-block-gep-readonly-table-index" };
    try selector_state.clobberArgReg(selector, .rcx);
    try selector.machine.instructions.append(selector.allocator, .{ .lea_global_arg64 = .{ .reg = .rcx, .symbol = decoded.symbol } });
    try selector.machine.instructions.append(selector.allocator, .{ .shl_r8_imm6 = shift });
    try selector.machine.instructions.append(selector.allocator, .add_r8_rcx);
    try selector_state.bindValueLoc(selector, result_name, .{ .readonly_table_ptr = .{
        .storage = .{ .reg = .rcx },
        .symbol = decoded.symbol,
        .shape = decoded.shape,
    } });
    return null;
}

fn lowerReadOnlyTableLoad(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    load: ir.LoadInst,
    ptr: selector_types.ReadOnlyTablePtrLoc,
) !?Diagnostic {
    if (load.ty_addrspace != null or load.ptr_addrspace != null) return .{ .no_emitter = "composed-block-load-readonly-table-addrspace" };
    if (!ptr.shape.allowsOffset(ptr.offset)) return .{ .no_emitter = "composed-block-load-readonly-table-offset" };
    const base: ArgReg = switch (ptr.storage) {
        .reg => |reg| reg,
        .spill => |frame_index| blk: {
            selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx }) catch return .{ .unsupported_value = "composed-block-load-readonly-table-spill" };
            break :blk .rcx;
        },
    };
    if (ptr.shape == .i16_128) {
        if (!load.ty.eql(.{ .int = 16 }) or ptr.offset != 0) return .{ .no_emitter = "composed-block-load-readonly-table-type" };
        try selector_state.clobberArgReg(selector, .r8);
        try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_u16_arg = .{ .base = base, .dst = .r8, .offset = 0 } });
        try selector_state.bindResultLoc(selector, result_name, .{ .scratch32 = .r8 });
        return null;
    }
    if (load.ty != .double) return .{ .no_emitter = "composed-block-load-readonly-table-type" };
    try selector_state.clobberXmmReg(selector, .xmm0);
    try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_xmm = .{ .base = base, .dst = .xmm0, .offset = ptr.offset } });
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = 64 } });
    return null;
}

fn sourceStrideMatchesShape(source_ty: ir.Type, shape: constant_table.Shape) bool {
    const expected = switch (shape) {
        .i16_128 => "[2 x i8]",
        .f64_16, .f64_512_pairs => "[8 x i8]",
        .f64_pair_128 => "[16 x i8]",
    };
    return switch (source_ty) {
        .aggregate => |text| std.mem.eql(u8, std.mem.trim(u8, text, " \t"), expected),
        else => false,
    };
}

fn tableIndexShift(shape: constant_table.Shape) u6 {
    return switch (shape) {
        .i16_128 => 1,
        .f64_16, .f64_512_pairs => 3,
        .f64_pair_128 => 4,
    };
}

fn hasAdmittedIndexProof(selector: *const ComposedBlockSelector, name: []const u8, shape: constant_table.Shape) bool {
    const function = selector.function orelse return false;
    const source_name = stripZext(function.*, name) orelse name;
    const mask: i128 = switch (shape) {
        .i16_128, .f64_pair_128 => 127,
        .f64_16 => 15,
        .f64_512_pairs => 510,
    };
    const binary = findInstruction(function.*, source_name) orelse return false;
    const and_inst = switch (binary.kind) {
        .binary => |value| if (value.op == .@"and" and intOperand(value.lhs, value.rhs, mask)) value else return false,
        else => return false,
    };
    if (shape != .f64_512_pairs) return true;
    const shifted = namedNonIntOperand(and_inst.lhs, and_inst.rhs) orelse return false;
    const shift_inst = findInstruction(function.*, shifted) orelse return false;
    return switch (shift_inst.kind) {
        .binary => |value| value.op == .shl and intOperand(value.lhs, value.rhs, 1),
        else => false,
    };
}

fn stripZext(function: ir.Function, name: []const u8) ?[]const u8 {
    const instruction = findInstruction(function, name) orelse return null;
    return switch (instruction.kind) {
        .cast => |cast| if (cast.op == .zext and cast.value == .named) cast.value.named else null,
        else => null,
    };
}

fn findInstruction(function: ir.Function, name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| for (block.instructions.items) |instruction| {
        if (instruction.result) |result| if (std.mem.eql(u8, result, name)) return instruction;
    };
    return null;
}

fn intOperand(lhs: ir.Value, rhs: ir.Value, expected: i128) bool {
    return (lhs == .int and lhs.int == expected) or (rhs == .int and rhs.int == expected);
}

fn namedNonIntOperand(lhs: ir.Value, rhs: ir.Value) ?[]const u8 {
    if (lhs == .named and rhs == .int) return lhs.named;
    if (rhs == .named and lhs == .int) return rhs.named;
    return null;
}

pub fn isI32ElementPointerSource(ty: ir.Type) bool {
    return switch (ty) {
        .aggregate => |text| std.mem.eql(u8, std.mem.trim(u8, text, " "), "[4 x i8]"),
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

pub fn isBytePointerSource(ty: ir.Type) bool {
    if (ty.eql(.{ .int = 8 })) return true;
    return switch (ty) {
        .aggregate => |text| std.mem.eql(u8, std.mem.trim(u8, text, " "), "[1 x i8]"),
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

pub fn appendLoadStackI32(selector: *ComposedBlockSelector, stack_ptr: StackPtrLoc) !void {
    try materializeStackIndex(selector, stack_ptr);
    if (stack_ptr.index != null) {
        if (stack_ptr.disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_rcx4_disp8_eax = @intCast(stack_ptr.disp) });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_rcx4_disp32_eax = stack_ptr.disp });
        }
    } else if (stack_ptr.disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_eax = @intCast(stack_ptr.disp) });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_eax = stack_ptr.disp });
    }
}

pub fn loadStackU64IntoArg(selector: *ComposedBlockSelector, reg: ArgReg, disp: u32) !void {
    try selector_state.clobberArgReg(selector, reg);
    if (disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_arg64 = .{ .reg = reg, .disp = @intCast(disp) } });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_arg64 = .{ .reg = reg, .disp = disp } });
    }
}

pub fn loadStackU64IntoRax(selector: *ComposedBlockSelector, disp: u32) !void {
    try selector_state.clobberAccumulator(selector);
    if (disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_rax = @intCast(disp) });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_rax = disp });
    }
}

pub fn appendStoreStackI32(selector: *ComposedBlockSelector, stack_ptr: StackPtrLoc) !void {
    try materializeStackIndex(selector, stack_ptr);
    if (stack_ptr.index != null) {
        if (stack_ptr.disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .store_eax_stack_rcx4_disp8 = @intCast(stack_ptr.disp) });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .store_eax_stack_rcx4_disp32 = stack_ptr.disp });
        }
    } else if (stack_ptr.disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{ .store_eax_stack_disp8 = @intCast(stack_ptr.disp) });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .store_eax_stack_disp32 = stack_ptr.disp });
    }
}

pub fn materializeStackIndex(selector: *ComposedBlockSelector, stack_ptr: StackPtrLoc) !void {
    const index = stack_ptr.index orelse return;
    try selector_state.emitValueIntoScratch(selector, .{ .named = index.name }, .rcx, 64);
    if (index.addend_name) |addend_name| {
        try selector_state.emitValueIntoScratch(selector, .{ .named = addend_name }, .r8, 64);
        try selector.machine.instructions.append(selector.allocator, .add_r8_rcx);
    }
}
