const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const selector_frame = @import("composed_selector_frame.zig");

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
const stage2SpillReservedBytes = stage2_planning.stage2SpillReservedBytes;
const stage2_max_blocks = stage2_planning.stage2_max_blocks;
const stage2_spill_slots = stage2_planning.stage2_spill_slots;
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
const alignedCallFrameBytes = composed_helpers.alignedCallFrameBytes;
const stack128FrameBytes = composed_helpers.stack128FrameBytes;
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
    if (selector_state.valueLoc(selector, result_name)) |loc| switch (loc) {
        .stack_scalar, .stack128, .stack_i32_array => return null,
        .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .xmm, .stack128_value, .stack_i32_ptr, .spill64, .spill128, .spill_fp, .spill_vector => {},
    };
    if (alloca.allocated_ty_addrspace != null) return .{ .no_emitter = "composed-block-alloca-addrspace" };
    if (alloca.allocated_ty.eql(.{ .int = 64 })) {
        if (selector.stack_slot_allocated or selector.stack_array_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
        try selector_frame.appendSubRsp(selector, 24);
        selector.stack_slot_allocated = true;
        selector.stack_frame_bytes = 24;
        try selector_state.bindValueLoc(selector, result_name, .{ .stack_scalar = .{ .base_disp = 0, .bits = 64 } });
        return null;
    }
    if (alloca.allocated_ty.eql(.{ .int = 128 })) {
        if (selector.stack_slot_allocated or selector.stack_array_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
        const frame_bytes = stack128FrameBytes();
        try selector_frame.appendSubRsp(selector, frame_bytes);
        selector.stack_slot_allocated = true;
        selector.stack_frame_bytes = frame_bytes;
        try selector_state.bindValueLoc(selector, result_name, .{ .stack128 = 0 });
        return null;
    }
    if (parseI32ArrayType(alloca.allocated_ty)) |len| {
        if (selector.stack_slot_allocated or selector.stack_array_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
        const payload_bytes = std.math.mul(u32, len, 4) catch return .{ .no_spill_envelope = "composed-block-stack-array-size" };
        const frame_bytes = alignedCallFrameBytes(payload_bytes) orelse return .{ .no_spill_envelope = "composed-block-stack-array-size" };
        try selector_frame.appendSubRsp(selector, frame_bytes);
        selector.stack_array_allocated = true;
        selector.stack_frame_bytes = frame_bytes;
        try selector_state.bindValueLoc(selector, result_name, .{ .stack_i32_array = .{ .base_disp = 0, .len = len } });
        return null;
    }
    return .{ .no_emitter = "composed-block-alloca-form" };
}

pub fn lowerLoad(selector: *ComposedBlockSelector, result: ?[]const u8, load: ir.LoadInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (load.attrs.isBarrier()) return .{ .no_emitter = "composed-block-load-barrier" };
    if (!load.ty.eql(.{ .int = 8 }) and !load.ty.eql(.{ .int = 32 }) and !load.ty.eql(.{ .int = 64 }) and !load.ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-load-width" };
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
        .arg32, .arg128, .xmm, .eax, .rax, .scratch32, .scratch128, .stack128_value, .spill128, .spill_fp, .spill_vector => return .{ .no_emitter = "composed-block-load-ptr" },
    }
    return null;
}

pub fn lowerStore(selector: *ComposedBlockSelector, store: ir.StoreInst) !?Diagnostic {
    if (store.attrs.isBarrier()) return .{ .no_emitter = "composed-block-store-barrier" };
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
        .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128, .spill_fp, .spill_vector => "composed-block-store-value-other",
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
        .arg32, .scratch32, .arg128, .scratch128, .xmm, .eax, .rax, .stack128, .stack128_value, .spill128, .spill_fp, .spill_vector => return .{ .no_emitter = "composed-block-store-ptr" },
    }
    return null;
}

fn lowerStoreI64(selector: *ComposedBlockSelector, ptr: ValueLoc, value: ir.Value, value_detail: []const u8) !?Diagnostic {
    switch (ptr) {
        .arg64, .scratch64 => |reg| try selector_state.materializeLocIntoLoc(selector, .{ .scratch64 = reg }, .{ .scratch64 = .rcx }),
        .spill64 => |frame_index| selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx }) catch |err| switch (err) {
            error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-store-spill-ptr" },
            else => return err,
        },
        .arg32, .arg128, .eax, .rax, .scratch32, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128, .spill_fp, .spill_vector => return .{ .no_emitter = "composed-block-store-ptr" },
    }
    selector_state.emitValueIntoRax(selector, value) catch return .{ .unsupported_value = value_detail };
    try selector.machine.instructions.append(selector.allocator, .store_rax_rcx_ptr);
    return null;
}

pub fn lowerGep(selector: *ComposedBlockSelector, result: ?[]const u8, gep: ir.GepInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (isBytePointerSource(gep.source_ty)) return try lowerBytePointerGep(selector, result_name, gep);
    if (isI32ElementPointerSource(gep.source_ty)) return try lowerI32ElementPointerGep(selector, result_name, gep);
    const len = parseI32ArrayType(gep.source_ty) orelse return .{ .no_emitter = "composed-block-gep-source" };
    const base = selector_state.resolveValue(selector, gep.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-array-gep-ptr" };
    const stack_array = switch (base) {
        .stack_i32_array => |stack_array| stack_array,
        .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_ptr, .spill64, .spill128, .spill_fp, .spill_vector => return .{ .no_emitter = "composed-block-gep-ptr" },
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
