const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const sysv_abi = @import("../sysv_abi.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const selector_frame = @import("composed_selector_frame.zig");
const selector_fp = @import("composed_selector_fp.zig");
const selector_conversion = @import("composed_selector_conversion.zig");
const selector_vector = @import("composed_selector_vector.zig");
const selector_memory = @import("composed_selector_memory.zig");
const selector_atomic = @import("composed_selector_atomic.zig");
const selector_calls = @import("composed_selector_calls.zig");
const selector_cfg = @import("composed_selector_cfg.zig");
const selector_aggregate = @import("composed_selector_aggregate.zig");
const address_dependencies = @import("composed_selector_address_dependencies.zig");

pub const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const XmmReg = x86_64_types.XmmReg;
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
const AddressDependencyDomain = address_dependencies.AddressDependencyDomain;

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
const stack_arguments = @import("stack_arguments.zig");

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
const isComposedCfgReturnType = composed_helpers.isComposedCfgReturnType;
const shiftAmount5 = composed_helpers.shiftAmount5;
const shiftAmount6 = composed_helpers.shiftAmount6;
const shiftAmount7 = composed_helpers.shiftAmount7;
const i32Value = composed_helpers.i32Value;
const i32BitPattern = composed_helpers.i32BitPattern;
const i64Value = composed_helpers.i64Value;

pub fn tryLowerComposedCfg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    return tryLowerComposedCfgWithContext(allocator, machine, function, null);
}

pub fn tryLowerComposedCfgWithContext(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_types.ReadOnlyModuleContext,
) !SelectionResult {
    var dependency_domain: AddressDependencyDomain = .{};
    return tryLowerComposedCfgWithContextAndAddressDependencies(
        allocator,
        machine,
        function,
        module_context,
        &dependency_domain,
    );
}

pub fn tryLowerComposedCfgWithContextAndAddressDependencies(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_types.ReadOnlyModuleContext,
    dependency_domain: *AddressDependencyDomain,
) !SelectionResult {
    return tryLowerComposedCfgObserved(allocator, machine, function, module_context, dependency_domain, null);
}

pub fn tryLowerComposedCfgObserved(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_types.ReadOnlyModuleContext,
    dependency_domain: *AddressDependencyDomain,
    observer: ?*@import("rejection_observer.zig").Observer,
) !SelectionResult {
    if (!isComposedCfgReturnType(function.ret_ty)) return unsupported(.{ .no_emitter = "stage2-ret-type" });
    if (function.blocks.items.len == 0) return unsupported(.{ .unsupported_control_flow = "stage2-empty-function" });
    if (function.blocks.items.len > stage2_max_blocks) return unsupported(.{ .no_spill_envelope = "stage2-block-count" });

    var allocation_plan = try stage2_planning.buildSelectorAllocationPlanObserved(allocator, function, observer);
    defer allocation_plan.deinit();

    const start_len = machine.instructions.items.len;
    var composed = ComposedBlockSelector.init(allocator, machine);
    selector_state.beginPhysicalBindingFacts(&composed);
    composed.rejection_observer = observer;
    composed.module_context = module_context;
    composed.function = &function;
    composed.allocation_plan = &allocation_plan;
    composed.address_dependencies = dependency_domain.*;
    composed.next_spill_slot = allocation_plan.spill_slots;
    composed.enable_expired_plan_register_reuse = canUseExpiredPlanRegisterReuse(function);
    defer composed.deinit();
    defer dependency_domain.* = composed.address_dependencies;

    if (try bindPhysicalParams(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (try bindPhiResults(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (try prepareObservedStackFrame(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (try bindStackParams(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (try stabilizeFramedPhiDestinations(&composed)) |diagnostic| return unsupported(diagnostic);
    if (try stabilizeFramedParams(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (composed.stack_frame_bytes != 0) {
        composed.return_epilogue_label = try selector_cfg.ownedReturnEpilogueLabel(&composed);
    }

    for (function.blocks.items, 0..) |block, block_index| {
        if (block_index != 0) try machine.instructions.append(allocator, .{ .label = block.name });
        if (try enterBlock(&composed, block)) |diagnostic| {
            machine.instructions.items.len = start_len;
            return unsupported(diagnostic);
        }
        for (block.instructions.items) |instruction| {
            if (try lowerInstruction(&composed, instruction)) |diagnostic| {
                machine.instructions.items.len = start_len;
                return unsupported(diagnostic);
            }
        }
        const terminator = block.terminator orelse {
            machine.instructions.items.len = start_len;
            return unsupported(.{ .unsupported_control_flow = "stage2-missing-terminator" });
        };
        try selector_state.expireExpiredBindings(&composed);
        if (try selector_cfg.lowerCfgTerminator(&composed, function, block_index, terminator)) |diagnostic| {
            machine.instructions.items.len = start_len;
            return unsupported(diagnostic);
        }
        composed.current_position += 1;
    }
    if (composed.return_epilogue_label) |label| {
        try machine.instructions.append(allocator, .{ .label = label });
        if (sysv_abi.sseAggregateReturnKind(function.ret_ty) == .packed_f32x2) {
            try machine.instructions.appendSlice(allocator, &.{
                .{ .movq_xmm_rax = .xmm0 },
                .{ .movq_rax_xmm = .xmm0 },
            });
        }
        try selector_frame.appendAddRsp(&composed, composed.stack_frame_bytes);
        try machine.instructions.append(allocator, .ret);
    }
    try selector_state.validateEflagsInstructions(&composed, machine.instructions.items[start_len..], start_len);
    return .selected;
}

pub const ComposedBlockSelector = selector_state.ComposedBlockSelector;

fn bindPhysicalParams(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
    const layout = stack_arguments.parameters(function) orelse return bindParams(selector, function);
    if (layout.stack_words == 0) return bindParams(selector, function);
    var registers: [stack_arguments.max_arguments]ir.Param = undefined;
    var count: usize = 0;
    for (function.params.items, 0..) |param, index| {
        try sysv_abi.rejectUnsupportedCallArgAttrs(.{ .ty = param.ty, .attrs = param.attrs, .value = .{ .named = param.name } });
        switch (layout.locations[index]) {
            .register, .pair, .sse => {
                registers[count] = param;
                count += 1;
            },
            .stack => {},
            .split => if (!param.ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-param-width" },
        }
    }
    var register_view = function;
    register_view.params = .fromOwnedSlice(registers[0..count]);
    return bindParams(selector, register_view);
}

fn bindParams(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
    if (stack_arguments.hasParameters(function)) for (function.params.items) |param| {
        try sysv_abi.rejectUnsupportedCallArgAttrs(.{ .ty = param.ty, .attrs = param.attrs, .value = .{ .named = param.name } });
    };
    var gpr_index: usize = 0;
    var xmm_index: usize = 0;
    for (function.params.items) |param| {
        if (gpr_index >= 6 and stack_arguments.hasParameters(function)) {
            gpr_index += 1;
            continue;
        }
        const vector_shape = selector_vector.abiShape(param.ty);
        if (param.ty == .half or param.ty == .float or param.ty == .double or vector_shape != null) {
            const reg = XmmReg.fromIndex(xmm_index) catch return .{ .unsupported_value = "composed-block-param-xmm-reg" };
            const bits: u16 = if (vector_shape != null) 128 else if (param.ty == .half) 16 else if (param.ty == .float) 32 else 64;
            try selector_state.bindValueLoc(selector, param.name, .{ .xmm = .{ .reg = reg, .bits = bits, .shape = if (vector_shape) |shape| .{ .vector = shape } else .scalar } });
            selector.machine.entry_xmm_defined_bits[@backingInt(reg)] = bits;
            xmm_index += 1;
            continue;
        }
        const reg = ArgReg.fromIndex(gpr_index) catch return .{ .unsupported_value = "composed-block-param-reg" };
        if (param.ty == .ptr) {
            try selector.abi_pointer_params.put(param.name, {});
            if (param.attrs) |attrs| if (hasAttrToken(attrs, "readonly")) try selector.readonly_pointer_params.put(param.name, {});
            try selector_state.bindValueLoc(selector, param.name, .{ .arg64 = reg });
        } else {
            const bits = intBits(param.ty) orelse return .{ .no_emitter = "composed-block-param-not-scalar" };
            switch (bits) {
                // SysV zeroext guarantees a canonical low byte. Other narrow
                // ABI forms remain outside this composed entry envelope.
                1, 2, 3, 5, 7, 8 => {
                    if (param.attrs == null or !hasAttrToken(param.attrs.?, "zeroext")) {
                        if (selector.rejection_observer) |observer| try observer.reject(.{
                            .function = function,
                            .position = selector.current_position,
                            .tag = "no_emitter",
                            .detail = "composed-block-param-i8-extension",
                            .parameter = param,
                        });
                        return .{ .no_emitter = "composed-block-param-i8-extension" };
                    }
                    try selector_state.bindValueLoc(selector, param.name, .{ .arg32 = reg });
                },
                4, 6, 16, 23, 24 => try selector_state.bindValueLoc(selector, param.name, .{ .arg32 = reg }),
                32 => try selector_state.bindValueLoc(selector, param.name, .{ .arg32 = reg }),
                37, 64 => try selector_state.bindValueLoc(selector, param.name, .{ .arg64 = reg }),
                128 => {
                    const high = ArgReg.fromIndex(gpr_index + 1) catch return .{ .unsupported_value = "composed-block-param-reg" };
                    try selector_state.bindValueLoc(selector, param.name, .{ .arg128 = .{ .lo = reg, .hi = high } });
                    gpr_index += 1;
                },
                else => return .{ .no_emitter = "composed-block-param-width" },
            }
        }
        gpr_index += 1;
    }
    return null;
}

fn bindStackParams(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
    const layout = stack_arguments.parameters(function) orelse return null;
    if (layout.stack_words == 0) return null;
    for (function.params.items, 0..) |param, index| {
        const word_offset = switch (layout.locations[index]) {
            .stack => |word| word,
            .split => |split| split.stack,
            .register, .pair, .sse => continue,
        };
        // The incoming return address precedes 8-byte argument slots. Copy
        // only the declared scalar width into our own persistent spill home.
        const offset: u32 = std.math.cast(u32, @as(usize, selector.stack_frame_bytes) + 8 + word_offset * 8) orelse
            return .{ .no_spill_envelope = "composed-block-stack-param-offset" };
        const bits: u16 = if (param.ty == .ptr) 64 else param.ty.int;
        if (bits == 128) {
            const home = selector_state.allocatePairSpillSlots(selector, param.name) orelse
                return .{ .no_spill_envelope = "composed-block-stack-param-pair-home" };
            // Incoming register parameters may die at the first IR instruction.
            // Capture through RAX without clobbering those simultaneous inputs.
            // The reserved internal name cannot collide with an IR identifier.
            const word_name = "\x00incoming.integer.word";
            for ([_]x86_64_types.FrameIndex{ home.lo, home.hi }, 0..) |word_home, word| {
                const source: IncomingWord = if (layout.locations[index] == .split)
                    if (word == 0) .{ .register = ArgReg.fromIndex(layout.locations[index].split.register) catch unreachable } else .{ .stack = offset }
                else
                    .{ .stack = offset + @as(u32, @intCast(word * 8)) };
                if (try captureIncomingWord(selector, word_name, 64, source)) |diagnostic| return diagnostic;
                try selector_state.storeCapturedIncomingPairWord(selector, word_name, word_home);
            }
            try selector_state.defineIncomingPairHome(selector, param, home);
            continue;
        }
        if (bits != 32 and bits != 64) return .{ .no_emitter = "composed-block-stack-param-width" };
        if (try captureIncomingWord(selector, param.name, bits, .{ .stack = offset })) |diagnostic| return diagnostic;
        if (try selector_state.spillValue(selector, param.name)) |diagnostic| return diagnostic;
        if (param.ty == .ptr) {
            try selector.abi_pointer_params.put(param.name, {});
            if (param.attrs) |attrs| if (hasAttrToken(attrs, "readonly")) try selector.readonly_pointer_params.put(param.name, {});
        }
    }
    return null;
}

const IncomingWord = union(enum) { register: ArgReg, stack: u32 };

fn captureIncomingWord(selector: *ComposedBlockSelector, name: []const u8, bits: u16, source: IncomingWord) !?Diagnostic {
    var definition = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer definition.deinit();
    if (try definition.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, switch (source) {
        .register => |reg| .{ .mov_arg_rax = reg },
        .stack => |offset| if (bits == 32) .{ .load_stack_disp32_eax = offset } else .{ .load_stack_disp32_rax = offset },
    });
    try definition.define(name, if (bits == 32) .zeroExtending(32) else .fullRax());
    try definition.commit();
    return null;
}

fn hasAttrToken(attrs: []const u8, expected: []const u8) bool {
    var tokens = std.mem.tokenizeAny(u8, attrs, " \t");
    while (tokens.next()) |token| if (std.mem.eql(u8, token, expected)) return true;
    return false;
}

fn bindPhiResults(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
    for (function.blocks.items) |block| {
        var used_in_block: [phi_regs.len]bool = @splat(false);
        for (block.instructions.items) |instruction| {
            if (instruction.removed or instruction.kind != .phi) continue;
            const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
            const phi = instruction.kind.phi;
            const metadata = selectorValueMetadata(phi.ty) orelse return .{ .no_emitter = "stage2-phi-type" };
            if (metadata.class == .vector_xmm) {
                const shape = supportedPhiVectorShape(phi.ty) orelse continue;
                const assignment = selector.allocation_plan.?.assignment(result_name) orelse return .{ .unsupported_value = "stage2-phi-plan" };
                const destination: ValueLoc = switch (assignment) {
                    .vector_xmm => |reg| .{ .xmm = .{
                        .reg = reg,
                        .bits = 128,
                        .shape = .{ .vector = shape },
                    } },
                    .spill => |index| .{ .spill_vector = .{
                        .frames = selector_state.pairSpillFrameIndexMaybe(index) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" },
                        .shape = shape,
                    } },
                    else => return .{ .no_emitter = "stage2-phi-width" },
                };
                try selector.phi_results.put(result_name, {});
                try selector.phi_destinations.put(result_name, destination);
                try selector_state.bindValueLoc(selector, result_name, destination);
                continue;
            }
            if (metadata.class == .fp16 or metadata.class == .fp32 or metadata.class == .fp64) {
                const assignment = selector.allocation_plan.?.assignment(result_name) orelse return .{ .unsupported_value = "stage2-phi-plan" };
                const destination: ValueLoc = switch (assignment) {
                    .fp16 => |reg| if (metadata.bits == 16) .{ .xmm = .{ .reg = reg, .bits = 16 } } else return .{ .no_emitter = "stage2-phi-width" },
                    .fp32 => |reg| if (metadata.bits == 32) .{ .xmm = .{ .reg = reg, .bits = 32 } } else return .{ .no_emitter = "stage2-phi-width" },
                    .fp64 => |reg| if (metadata.bits == 64) .{ .xmm = .{ .reg = reg, .bits = 64 } } else return .{ .no_emitter = "stage2-phi-width" },
                    .spill => |index| .{ .spill_fp = .{
                        .frame_index = selector_state.spillFrameIndexMaybe(index) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" },
                        .bits = metadata.bits,
                    } },
                    else => return .{ .no_emitter = "stage2-phi-width" },
                };
                try selector.phi_results.put(result_name, {});
                try selector.phi_destinations.put(result_name, destination);
                try selector_state.bindValueLoc(selector, result_name, destination);
                continue;
            }
            const bits = switch (metadata.class) {
                .gpr32 => @as(u16, 32),
                .gpr64 => @as(u16, 64),
                .gpr128 => @as(u16, 128),
                .fp16, .fp32, .fp64, .vector_xmm, .aggregate_sse, .stack_object, .stack_pointer => return .{ .no_emitter = "stage2-phi-width" },
            };
            const planned_spill = if (bits != 128 and selector.allocation_plan != null) switch (selector.allocation_plan.?.assignment(result_name) orelse return .{ .unsupported_value = "stage2-phi-plan" }) {
                .spill => |index| selector_state.spillFrameIndexMaybe(index) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" },
                .gpr32, .gpr64, .gpr128, .fp16, .fp32, .fp64, .vector_xmm, .stack_object, .stack_pointer => null,
            } else null;
            const destination: ValueLoc = if (bits == 128)
                .{ .spill128 = selector_state.allocatePairSpillSlots(selector, result_name) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" } }
            else if (planned_spill) |frame_index|
                .{ .spill64 = frame_index }
            else if (nextPhiReg(&used_in_block)) |reg|
                if (bits == 64) .{ .scratch64 = reg } else .{ .scratch32 = reg }
            else
                .{ .spill64 = selector_state.allocateSpillSlot(selector, result_name) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" } };
            try selector.phi_results.put(result_name, {});
            try selector.phi_destinations.put(result_name, destination);
            try selector_state.bindValueLoc(selector, result_name, destination);
        }
    }
    return null;
}

fn stabilizeFramedParams(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
    if (selector.stack_frame_bytes == 0) return null;
    const stabilize_all = function.blocks.items.len > 1;
    const plan = selector.allocation_plan orelse return .{ .unsupported_value = "stage2-param-home-plan" };
    for (function.params.items) |param| {
        if (!stabilize_all and !plan.preservation_values.contains(param.name)) continue;
        const loc = selector_state.valueLoc(selector, param.name) orelse return .{ .unsupported_value = "stage2-param-home" };
        switch (loc) {
            .spill64, .spill128, .spill_fp, .spill_vector => {},
            .arg32, .arg64, .scratch32, .scratch64, .eax, .rax => {
                if (try selector_state.spillValue(selector, param.name)) |diagnostic| return diagnostic;
            },
            .arg128, .scratch128 => {
                if (try selector_state.spillPairValue(selector, param.name)) |diagnostic| return diagnostic;
            },
            .xmm => if (try selector_state.spillValue(selector, param.name)) |diagnostic| return diagnostic,
            .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .aggregate_sse => return .{ .unsupported_value = "stage2-param-home" },
        }
    }
    return null;
}

fn stabilizeFramedPhiDestinations(selector: *ComposedBlockSelector) !?Diagnostic {
    if (selector.stack_frame_bytes == 0) return null;
    var it = selector.phi_destinations.iterator();
    while (it.next()) |entry| {
        const destination: ValueLoc = switch (entry.value_ptr.*) {
            .scratch32, .scratch64 => .{ .spill64 = selector_state.allocateSpillSlot(selector, entry.key_ptr.*) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" } },
            .xmm => |fp| if (fp.vectorShape() == null and (fp.bits == 16 or fp.bits == 32 or fp.bits == 64))
                .{ .spill_fp = .{
                    .frame_index = selector_state.allocateSpillSlot(selector, entry.key_ptr.*) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" },
                    .bits = fp.bits,
                } }
            else if (fp.vectorShape()) |shape|
                if (supportedPhiVectorShapeFromLoc(fp))
                    .{ .spill_vector = .{
                        .frames = selector_state.allocatePairSpillSlots(selector, entry.key_ptr.*) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" },
                        .shape = shape,
                    } }
                else
                    continue
            else
                continue,
            else => continue,
        };
        entry.value_ptr.* = destination;
        try selector_state.bindValueLoc(selector, entry.key_ptr.*, destination);
    }
    return null;
}

fn supportedPhiVectorShape(ty: ir.Type) ?selector_types.VectorShape {
    if (ty != .vector or ty.vector.len != 2 or ty.vector.elem_ty != .double) return null;
    return .f64x2(0b11);
}

fn supportedPhiVectorShapeFromLoc(loc: selector_types.XmmValueLoc) bool {
    const shape = loc.vectorShape() orelse return false;
    return loc.bits == 128 and shape.eql(selector_types.VectorShape.f64x2(0b11));
}

fn nextPhiReg(used_in_block: *[phi_regs.len]bool) ?ArgReg {
    for (phi_regs, 0..) |reg, index| {
        if (used_in_block[index]) continue;
        used_in_block[index] = true;
        return reg;
    }
    return null;
}

fn enterBlock(selector: *ComposedBlockSelector, block: ir.BasicBlock) !?Diagnostic {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .phi => {},
            else => break,
        }
        const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
        const loc = selector.phi_destinations.get(result_name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
        try selector_state.bindValueLoc(selector, result_name, loc);
        switch (loc) {
            .scratch32, .scratch64, .xmm, .spill64, .spill128, .spill_fp, .spill_vector => {},
            .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .aggregate_sse => return .{ .no_emitter = "stage2-phi-dst-loc" },
        }
    }
    return null;
}

pub fn lowerInstruction(selector: *ComposedBlockSelector, instruction: ir.Instruction) !?Diagnostic {
    if (instruction.removed) return null;
    try selector_state.expireExpiredBindings(selector);
    defer selector.current_position += 1;
    return switch (instruction.kind) {
        .phi => null,
        .binary => lowerObservedBinary(selector, instruction),
        .alloca => |alloca| selector_memory.lowerAlloca(selector, instruction.result, alloca) catch |err| return instructionValueError(selector, err, "stage2-alloca-value"),
        .cast => lowerObservedCast(selector, instruction),
        .freeze => |freeze| lowerObservedFreeze(selector, instruction.result, freeze),
        .icmp => |icmp| lowerObservedIcmp(selector, instruction.result, icmp),
        .fcmp => |fcmp| if (fcmp.operand_ty == .vector)
            selector_vector.lowerFcmp(selector, instruction.result, fcmp) catch |err| return instructionValueError(selector, err, "stage2-vector-fcmp-value")
        else
            selector_fp.lowerFcmp(selector, instruction.result, fcmp) catch |err| return instructionValueError(selector, err, "stage2-fcmp-value"),
        .load => |load| selector_memory.lowerLoad(selector, instruction.result, load) catch |err| return instructionValueError(selector, err, "stage2-load-value"),
        .atomicrmw => |rmw| selector_atomic.lowerRmw(selector, instruction.result, rmw) catch |err| return instructionValueError(selector, err, "stage2-atomic-rmw-value"),
        .cmpxchg => |cmp| selector_atomic.lowerCmpxchg(selector, instruction.result, cmp) catch |err| return instructionValueError(selector, err, "stage2-atomic-cmpxchg-value"),
        .store => lowerObservedStore(selector, instruction),
        .gep => |gep| selector_memory.lowerGep(selector, instruction.result, gep) catch |err| return instructionValueError(selector, err, "stage2-gep-value"),
        .call => |call| lowerObservedCall(selector, instruction.result, call) catch |err| return instructionValueError(selector, err, "stage2-call-value"),
        .extractvalue => |extract| selector_calls.lowerExtractValue(selector, instruction.result, extract) catch |err| return instructionValueError(selector, err, "stage2-extractvalue-value"),
        .insertvalue => |insert| selector_aggregate.lowerInsertValue(selector, instruction.result, insert) catch |err| return instructionValueError(selector, err, "stage2-insertvalue-value"),
        .select => |select| if (select.ty == .vector)
            selector_vector.lowerSelect(selector, instruction.result, select) catch |err| return instructionValueError(selector, err, "stage2-vector-select-value")
        else
            selector_cfg.lowerSelect(selector, instruction.result, select) catch |err| return instructionValueError(selector, err, "stage2-select-value"),
        .extractelement => |extract| selector_vector.lowerExtractElement(selector, instruction.result, extract) catch |err| return instructionValueError(selector, err, "stage2-vector-extract-value"),
        .insertelement => |insert| selector_vector.lowerInsertElement(selector, instruction.result, insert) catch |err| return instructionValueError(selector, err, "stage2-vector-insert-value"),
        .shufflevector => |shuffle| selector_vector.lowerShuffleVector(selector, instruction.result, shuffle) catch |err| return instructionValueError(selector, err, "stage2-vector-shuffle-value"),
        else => .{ .no_emitter = "composed-block-instruction-not-owned" },
    };
}

fn lowerObservedCall(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const diagnostic = try selector_calls.lowerCall(selector, result, call);
    if (diagnostic) |failure| try selector_state.observeRejectedCall(selector, result, call, failure);
    return diagnostic;
}

fn lowerObservedStore(selector: *ComposedBlockSelector, instruction: ir.Instruction) !?Diagnostic {
    const diagnostic = try (selector_memory.lowerStore(selector, instruction.kind.store) catch |err|
        instructionValueError(selector, err, "stage2-store-value"));
    if (diagnostic) |failure| try selector_state.observeRejectedInstruction(selector, instruction, failure);
    return diagnostic;
}

fn lowerObservedBinary(selector: *ComposedBlockSelector, instruction: ir.Instruction) !?Diagnostic {
    const binary = instruction.kind.binary;
    const diagnostic = if (binary.ty == .vector)
        try (selector_vector.lowerBinary(selector, instruction.result, binary) catch |err| instructionValueError(selector, err, "stage2-vector-binary-value"))
    else if (binary.op == .fadd or binary.op == .fsub or binary.op == .fmul or binary.op == .fdiv)
        try (selector_fp.lowerFpBinary(selector, instruction.result, binary) catch |err| instructionValueError(selector, err, "stage2-fp-binary-value"))
    else
        try (selector_scalar.lowerBinary(selector, instruction.result, binary) catch |err| instructionValueError(selector, err, "stage2-binary-value"));
    if (diagnostic) |failure| try selector_state.observeRejectedInstruction(selector, instruction, failure);
    return diagnostic;
}

fn lowerObservedCast(selector: *ComposedBlockSelector, instruction: ir.Instruction) !?Diagnostic {
    const cast = instruction.kind.cast;
    const diagnostic = if (cast.from_ty == .vector or cast.to_ty == .vector)
        try (selector_vector.lowerCast(selector, instruction.result, cast) catch |err| instructionValueError(selector, err, "stage2-vector-cast-value"))
    else if (cast.op == .sitofp or cast.op == .uitofp)
        try (selector_conversion.lowerIntToFpCast(selector, instruction.result, cast) catch |err| instructionValueError(selector, err, "stage2-int-fp-cast-value"))
    else if (selector_conversion.isFpToSignedI32Cast(cast))
        try (selector_conversion.lowerFpToSignedIntCast(selector, instruction.result, cast) catch |err| instructionValueError(selector, err, "stage2-fp-int-cast-value"))
    else if (cast.op == .fpext or cast.op == .fptrunc or (cast.op == .bitcast and selector_fp.isFpIntBitcast(cast)))
        try (selector_fp.lowerFpCast(selector, instruction.result, cast) catch |err| instructionValueError(selector, err, "stage2-fp-cast-value"))
    else if (cast.op == .inttoptr)
        try (selector_scalar.lowerIntToPtr(selector, instruction.result, cast) catch |err| instructionValueError(selector, err, "stage2-int-pointer-cast-value"))
    else
        try (selector_scalar.lowerCast(selector, instruction.result, cast) catch |err| instructionValueError(selector, err, "stage2-cast-value"));
    if (diagnostic) |failure| try selector_state.observeRejectedInstruction(selector, instruction, failure);
    return diagnostic;
}

fn lowerObservedFreeze(selector: *ComposedBlockSelector, result: ?[]const u8, freeze: ir.FreezeInst) !?Diagnostic {
    const diagnostic = selector_scalar.lowerFreeze(selector, result, freeze) catch |err| try instructionValueError(selector, err, "stage2-freeze-value");
    if (diagnostic) |failure| try selector_state.observeRejectedFreeze(selector, result, freeze, failure);
    return diagnostic;
}

fn lowerObservedIcmp(selector: *ComposedBlockSelector, result: ?[]const u8, comparison: ir.IcmpInst) !?Diagnostic {
    const diagnostic = if (comparison.operand_ty == .vector)
        try (selector_vector.lowerIcmp(selector, result, comparison) catch |err| instructionValueError(selector, err, "stage2-vector-icmp-value"))
    else
        try (selector_scalar.lowerIcmp(selector, result, comparison) catch |err| instructionValueError(selector, err, "stage2-icmp-value"));
    if (diagnostic) |failure| try selector_state.observeRejectedIcmp(selector, result, comparison, failure);
    return diagnostic;
}

fn instructionValueError(selector: *ComposedBlockSelector, err: anyerror, detail: []const u8) anyerror!?Diagnostic {
    _ = selector;
    return switch (err) {
        error.UnsupportedCodegenValue => .{ .unsupported_value = detail },
        else => err,
    };
}

pub fn tryLowerComposedBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    return tryLowerComposedBlockWithContext(allocator, machine, function, null);
}

pub fn tryLowerComposedBlockWithContext(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_types.ReadOnlyModuleContext,
) !SelectionResult {
    var dependency_domain: AddressDependencyDomain = .{};
    return tryLowerComposedBlockWithContextAndAddressDependencies(
        allocator,
        machine,
        function,
        module_context,
        &dependency_domain,
    );
}

pub fn tryLowerComposedBlockWithContextAndAddressDependencies(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_types.ReadOnlyModuleContext,
    dependency_domain: *AddressDependencyDomain,
) !SelectionResult {
    return tryLowerComposedBlockObserved(allocator, machine, function, module_context, dependency_domain, null);
}

pub fn tryLowerComposedBlockObserved(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_types.ReadOnlyModuleContext,
    dependency_domain: *AddressDependencyDomain,
    observer: ?*@import("rejection_observer.zig").Observer,
) !SelectionResult {
    if (!isComposedReturnType(function.ret_ty)) return unsupported(.{ .no_emitter = "composed-block-ret-type" });
    if (function.blocks.items.len != 1) return unsupported(.{ .no_emitter = "composed-block-not-single-block" });

    var allocation_plan = try buildSelectorAllocationPlan(allocator, function);
    defer allocation_plan.deinit();

    const start_len = machine.instructions.items.len;
    var composed = ComposedBlockSelector.init(allocator, machine);
    selector_state.beginPhysicalBindingFacts(&composed);
    composed.rejection_observer = observer;
    composed.module_context = module_context;
    composed.function = &function;
    composed.allocation_plan = &allocation_plan;
    composed.address_dependencies = dependency_domain.*;
    composed.enable_expired_plan_register_reuse = canUseExpiredPlanRegisterReuse(function);
    defer composed.deinit();
    defer dependency_domain.* = composed.address_dependencies;

    if (try bindPhysicalParams(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (try prepareObservedStackFrame(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (try bindStackParams(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (try stabilizeFramedParams(&composed, function)) |diagnostic| return unsupported(diagnostic);

    const block = function.blocks.items[0];
    for (block.instructions.items) |instruction| {
        if (try lowerInstruction(&composed, instruction)) |diagnostic| return unsupported(diagnostic);
    }

    const terminator = block.terminator orelse return unsupported(.{ .unsupported_control_flow = "composed-block-missing-terminator" });
    try selector_state.expireExpiredBindings(&composed);
    switch (terminator) {
        .ret => |ret| {
            if (try selector_cfg.lowerReturn(&composed, ret)) |diagnostic| return unsupported(diagnostic);
        },
        .@"unreachable" => try selector_state.emitEflagsInstruction(&composed, .ud2, .preserve),
        .br, .condbr, .@"switch", .indirectbr => return unsupported(.{ .no_emitter = "composed-block-terminator-not-owned" }),
    }
    try selector_state.validateEflagsInstructions(&composed, machine.instructions.items[start_len..], start_len);
    return .selected;
}

fn unsupported(diagnostic: Diagnostic) SelectionResult {
    return .{ .unsupported = diagnostic };
}

fn prepareObservedStackFrame(composed: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
    const diagnostic = (try selector_frame.prepareStackFrame(composed, function)) orelse return null;
    if (composed.rejection_observer) |observer| try observer.reject(.{
        .function = function,
        .position = 0,
        .tag = diagnostic.tagName(),
        .detail = diagnostic.detail(),
        .pressure = try @import("stage2_planning.zig").analyzeStageTwoNoSpillEnvelope(composed.allocator, function),
    });
    return diagnostic;
}
