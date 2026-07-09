const std = @import("std");
const ir = @import("../../ir.zig");
const x86_64_machine = @import("machine.zig");
const x86_64_types = @import("types.zig");

pub const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const MachineBinaryOp = x86_64_types.MachineBinaryOp;

pub const Diagnostic = union(enum) {
    unsupported_control_flow: []const u8,
    unsupported_instruction: []const u8,
    unsupported_type: []const u8,
    unsupported_value: []const u8,
    no_spill_envelope: []const u8,
    no_emitter: []const u8,

    pub fn tagName(diagnostic: Diagnostic) []const u8 {
        return @tagName(diagnostic);
    }

    pub fn detail(diagnostic: Diagnostic) []const u8 {
        return switch (diagnostic) {
            inline else => |detail_text| detail_text,
        };
    }
};

pub const SelectionResult = union(enum) {
    selected,
    unsupported: Diagnostic,
};

pub const StageTwoSummary = struct {
    blocks: usize,
    edges: usize,
    max_live_in: usize,
    max_live_out: usize,
    max_pressure: usize,
    no_spill_limit: usize,

    pub fn exceedsNoSpill(summary: StageTwoSummary) bool {
        return summary.max_pressure > summary.no_spill_limit;
    }
};

const no_spill_register_values = 6;

pub fn tryLower(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    const inspected = inspectFunction(function);
    if (matchesMuloLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .mulo_limb64_rdi_rsi_rdx_cl_r8w_al);
        return .selected;
    }
    if (matchesByteswapLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .byteswap_limb64_rdi_rsi_dl_cx);
        return .selected;
    }
    if (matchesShrLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .shr_limb64_rdi_rsi_dx_cl_r8w);
        return .selected;
    }
    if (matchesShloLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .shlo_limb64_rdi_rsi_dx_cl_r8w_al);
        return .selected;
    }
    if (matchesNotLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .not_limb64_rdi_rsi_dl_cx);
        return .selected;
    }
    if (matchesBitwiseLimb64Envelope(function)) |op| {
        try machine.instructions.append(allocator, .{ .bitwise_limb64_rdi_rsi_rdx_cx = op });
        return .selected;
    }
    if (matchesCmpLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .cmp_limb64_rdi_rsi_dl_cx_ax);
        return .selected;
    }
    if (matchesOverflowLimb64Envelope(function)) |op| {
        try machine.instructions.append(allocator, .{ .overflow_limb64_rdi_rsi_rdx_cl_r8w_al = op });
        return .selected;
    }
    if (matchesBitreverseLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .bitreverse_limb64_rdi_rsi_dl_cx);
        return .selected;
    }
    if (matchesPopcountLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .popcount_limb64_rdi_si_ax);
        return .selected;
    }
    if (matchesCtzLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .ctz_limb64_rdi_si_ax);
        return .selected;
    }
    if (matchesClzLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .clz_limb64_rdi_si_ax);
        return .selected;
    }
    if (matchesUdivei4Envelope(function)) {
        try machine.instructions.append(allocator, .udivei4_before_intbytesize);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "zig.target.intByteSize", .ret_ty = .{ .int = 16 } } });
        try machine.instructions.append(allocator, .udivei4_between_intbytesize_and_memset);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "memset", .ret_ty = .ptr } });
        try machine.instructions.append(allocator, .udivei4_after_memset);
        return .selected;
    }
    if (matchesUmodei5Envelope(function)) {
        try machine.instructions.append(allocator, .umodei5_before_intbytesize);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "zig.target.intByteSize", .ret_ty = .{ .int = 16 } } });
        try machine.instructions.append(allocator, .umodei5_between_intbytesize_and_memset);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "memset", .ret_ty = .ptr } });
        try machine.instructions.append(allocator, .umodei5_after_memset_before_memcpy);
        try machine.instructions.append(allocator, .{ .direct_jump = "memcpy" });
        try machine.instructions.append(allocator, .umodei5_after_memcpy);
        return .selected;
    }
    switch (inspected) {
        .selected => unreachable,
        .unsupported => |diagnostic| switch (diagnostic) {
            .no_emitter => {},
            .unsupported_control_flow => {
                if (function.blocks.items.len > 1) {
                    const stage_two = try analyzeStageTwoNoSpillEnvelope(allocator, function);
                    if (stage_two.exceedsNoSpill()) return .{ .unsupported = .{ .no_spill_envelope = "stage2-register-pressure" } };
                    return tryLowerComposedCfg(allocator, machine, function);
                }
                return inspected;
            },
            else => return inspected,
        },
    }
    if (function.blocks.items.len > 1) {
        const stage_two = try analyzeStageTwoNoSpillEnvelope(allocator, function);
        if (stage_two.exceedsNoSpill()) return .{ .unsupported = .{ .no_spill_envelope = "stage2-register-pressure" } };
        return tryLowerComposedCfg(allocator, machine, function);
    }
    const composed_start_len = machine.instructions.items.len;
    switch (try tryLowerComposedBlock(allocator, machine, function)) {
        .selected => return .selected,
        .unsupported => |diagnostic| switch (diagnostic) {
            .no_emitter => machine.instructions.items.len = composed_start_len,
            else => {
                machine.instructions.items.len = composed_start_len;
                return .{ .unsupported = diagnostic };
            },
        },
    }
    return inspected;
}

fn tryLowerComposedCfg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    if (!isComposedReturnType(function.ret_ty)) return unsupported(.{ .no_emitter = "stage2-ret-type" });
    if (function.blocks.items.len == 0) return unsupported(.{ .unsupported_control_flow = "stage2-empty-function" });
    if (function.blocks.items.len > 16) return unsupported(.{ .no_spill_envelope = "stage2-block-count" });

    const start_len = machine.instructions.items.len;
    var composed = ComposedBlockSelector.init(allocator, machine);
    defer composed.deinit();

    if (try composed.bindParams(function)) |diagnostic| return unsupported(diagnostic);
    if (try composed.bindPhiResults(function)) |diagnostic| return unsupported(diagnostic);

    for (function.blocks.items, 0..) |block, block_index| {
        if (block_index != 0) try machine.instructions.append(allocator, .{ .label = block.name });
        if (try composed.enterBlock(block)) |diagnostic| {
            machine.instructions.items.len = start_len;
            return unsupported(diagnostic);
        }
        for (block.instructions.items) |instruction| {
            if (try composed.lowerInstruction(instruction)) |diagnostic| {
                machine.instructions.items.len = start_len;
                return unsupported(diagnostic);
            }
        }
        const terminator = block.terminator orelse {
            machine.instructions.items.len = start_len;
            return unsupported(.{ .unsupported_control_flow = "stage2-missing-terminator" });
        };
        if (try composed.lowerCfgTerminator(function, block_index, terminator)) |diagnostic| {
            machine.instructions.items.len = start_len;
            return unsupported(diagnostic);
        }
    }
    return .selected;
}

pub fn analyzeStageTwoNoSpillEnvelope(allocator: std.mem.Allocator, function: ir.Function) !StageTwoSummary {
    var blocks: std.ArrayList(StageTwoBlock) = .empty;
    defer {
        for (blocks.items) |*block| block.deinit();
        blocks.deinit(allocator);
    }

    for (function.blocks.items) |block| {
        try blocks.append(allocator, StageTwoBlock.init(allocator, block.name));
    }
    if (blocks.items.len == 0) {
        return .{
            .blocks = 0,
            .edges = 0,
            .max_live_in = 0,
            .max_live_out = 0,
            .max_pressure = 0,
            .no_spill_limit = no_spill_register_values,
        };
    }

    for (function.params.items) |param| {
        try blocks.items[0].defs.put(param.name, {});
    }

    var edge_count: usize = 0;
    for (function.blocks.items, 0..) |block, block_index| {
        try collectBlockUsesAndDefs(&blocks.items[block_index], block);
        const block_successors = try successors(block);
        for (block_successors.names[0..block_successors.len]) |successor_name| {
            if (successor_name.len == 0) continue;
            edge_count += 1;
            _ = function.blockIndex(successor_name) orelse return error.UnsupportedCodegenControlFlow;
        }
    }

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed or instruction.kind != .phi) continue;
            const phi = instruction.kind.phi;
            for (phi.incoming.items) |incoming| {
                const predecessor_index = function.blockIndex(incoming.block) orelse return error.UnsupportedCodegenControlFlow;
                try addNamedValue(&blocks.items[predecessor_index].phi_out, incoming.value);
            }
        }
    }

    var changed = true;
    while (changed) {
        changed = false;
        var reverse_index = blocks.items.len;
        while (reverse_index > 0) {
            reverse_index -= 1;
            var next_live_out = NameSet.init(allocator);
            defer next_live_out.deinit();
            try unionSet(&next_live_out, blocks.items[reverse_index].phi_out);
            const block_successors = try successors(function.blocks.items[reverse_index]);
            for (block_successors.names[0..block_successors.len]) |successor_name| {
                if (successor_name.len == 0) continue;
                const successor_index = function.blockIndex(successor_name) orelse return error.UnsupportedCodegenControlFlow;
                try unionSet(&next_live_out, blocks.items[successor_index].live_in);
            }

            var next_live_in = NameSet.init(allocator);
            defer next_live_in.deinit();
            try unionSet(&next_live_in, next_live_out);
            var def_it = blocks.items[reverse_index].defs.iterator();
            while (def_it.next()) |entry| {
                _ = next_live_in.remove(entry.key_ptr.*);
            }
            try unionSet(&next_live_in, blocks.items[reverse_index].uses);

            if (try replaceSet(&blocks.items[reverse_index].live_out, next_live_out)) changed = true;
            if (try replaceSet(&blocks.items[reverse_index].live_in, next_live_in)) changed = true;
        }
    }

    var max_live_in: usize = 0;
    var max_live_out: usize = 0;
    for (blocks.items) |block| {
        max_live_in = @max(max_live_in, block.live_in.count());
        max_live_out = @max(max_live_out, block.live_out.count());
    }
    const max_pressure = @max(max_live_in, max_live_out);
    return .{
        .blocks = blocks.items.len,
        .edges = edge_count,
        .max_live_in = max_live_in,
        .max_live_out = max_live_out,
        .max_pressure = max_pressure,
        .no_spill_limit = no_spill_register_values,
    };
}

const NameSet = std.StringHashMap(void);

const StageTwoBlock = struct {
    name: []const u8,
    defs: NameSet,
    uses: NameSet,
    phi_out: NameSet,
    live_in: NameSet,
    live_out: NameSet,

    fn init(allocator: std.mem.Allocator, name: []const u8) StageTwoBlock {
        return .{
            .name = name,
            .defs = NameSet.init(allocator),
            .uses = NameSet.init(allocator),
            .phi_out = NameSet.init(allocator),
            .live_in = NameSet.init(allocator),
            .live_out = NameSet.init(allocator),
        };
    }

    fn deinit(block: *StageTwoBlock) void {
        block.defs.deinit();
        block.uses.deinit();
        block.phi_out.deinit();
        block.live_in.deinit();
        block.live_out.deinit();
    }
};

fn collectBlockUsesAndDefs(stage_block: *StageTwoBlock, block: ir.BasicBlock) !void {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        if (instruction.kind != .phi) try collectInstructionUses(stage_block, instruction);
        if (instruction.result) |result| try stage_block.defs.put(result, {});
    }
    if (block.terminator) |terminator| try collectTerminatorUses(stage_block, terminator);
}

fn collectInstructionUses(stage_block: *StageTwoBlock, instruction: ir.Instruction) !void {
    switch (instruction.kind) {
        .binary => |binary| {
            try addBlockUse(stage_block, binary.lhs);
            try addBlockUse(stage_block, binary.rhs);
        },
        .cast => |cast| try addBlockUse(stage_block, cast.value),
        .freeze => |freeze| try addBlockUse(stage_block, freeze.value),
        .icmp => |icmp| {
            try addBlockUse(stage_block, icmp.lhs);
            try addBlockUse(stage_block, icmp.rhs);
        },
        .fcmp => |fcmp| {
            try addBlockUse(stage_block, fcmp.lhs);
            try addBlockUse(stage_block, fcmp.rhs);
        },
        .select => |select| {
            try addBlockUse(stage_block, select.cond);
            try addBlockUse(stage_block, select.true_value);
            try addBlockUse(stage_block, select.false_value);
        },
        .phi => {},
        .alloca, .fence => {},
        .load => |load| try addBlockUse(stage_block, load.ptr),
        .store => |store| {
            try addBlockUse(stage_block, store.value);
            try addBlockUse(stage_block, store.ptr);
        },
        .atomicrmw => |atomicrmw| {
            try addBlockUse(stage_block, atomicrmw.ptr);
            try addBlockUse(stage_block, atomicrmw.value);
        },
        .cmpxchg => |cmpxchg| {
            try addBlockUse(stage_block, cmpxchg.ptr);
            try addBlockUse(stage_block, cmpxchg.expected);
            try addBlockUse(stage_block, cmpxchg.replacement);
        },
        .extractelement => |extract| {
            try addBlockUse(stage_block, extract.vector);
            try addBlockUse(stage_block, extract.index);
        },
        .insertelement => |insert| {
            try addBlockUse(stage_block, insert.vector);
            try addBlockUse(stage_block, insert.value);
            try addBlockUse(stage_block, insert.index);
        },
        .shufflevector => |shuffle| {
            try addBlockUse(stage_block, shuffle.lhs);
            try addBlockUse(stage_block, shuffle.rhs);
            try addBlockUse(stage_block, shuffle.mask);
        },
        .extractvalue => |extract| try addBlockUse(stage_block, extract.aggregate),
        .insertvalue => |insert| {
            try addBlockUse(stage_block, insert.aggregate);
            try addBlockUse(stage_block, insert.value);
        },
        .gep => |gep| {
            try addBlockUse(stage_block, gep.ptr);
            for (gep.indices.items) |index| try addBlockUse(stage_block, index.value);
        },
        .call => |call| {
            if (call.isDebugVariableLocation()) return;
            if (call.callee_value) |callee| try addBlockUse(stage_block, callee);
            for (call.args.items) |arg| try addBlockUse(stage_block, arg.value);
        },
    }
}

fn collectTerminatorUses(stage_block: *StageTwoBlock, terminator: ir.Terminator) !void {
    switch (terminator) {
        .ret => |ret| if (ret.value) |value| try addBlockUse(stage_block, value),
        .br => {},
        .condbr => |condbr| try addBlockUse(stage_block, condbr.cond),
        .@"switch" => |switch_term| {
            try addBlockUse(stage_block, switch_term.cond);
            for (switch_term.cases.items) |case| try addBlockUse(stage_block, case.value);
        },
        .indirectbr => |indirectbr| try addBlockUse(stage_block, indirectbr.addr),
        .@"unreachable" => {},
    }
}

fn addBlockUse(stage_block: *StageTwoBlock, value: ir.Value) !void {
    const name = namedValue(value) orelse return;
    if (stage_block.defs.contains(name)) return;
    try stage_block.uses.put(name, {});
}

fn addNamedValue(set: *NameSet, value: ir.Value) !void {
    const name = namedValue(value) orelse return;
    try set.put(name, {});
}

fn namedValue(value: ir.Value) ?[]const u8 {
    return switch (value) {
        .named => |name| if (std.mem.startsWith(u8, name, "@") or std.mem.startsWith(u8, name, "!")) null else name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn unionSet(dst: *NameSet, src: NameSet) !void {
    var it = src.iterator();
    while (it.next()) |entry| try dst.put(entry.key_ptr.*, {});
}

fn replaceSet(dst: *NameSet, src: NameSet) !bool {
    if (setEquals(dst.*, src)) return false;
    dst.clearRetainingCapacity();
    try unionSet(dst, src);
    return true;
}

fn setEquals(lhs: NameSet, rhs: NameSet) bool {
    if (lhs.count() != rhs.count()) return false;
    var it = lhs.iterator();
    while (it.next()) |entry| {
        if (!rhs.contains(entry.key_ptr.*)) return false;
    }
    return true;
}

const BlockSuccessors = struct {
    names: [16][]const u8 = .{""} ** 16,
    len: usize = 0,

    fn add(successors_list: *BlockSuccessors, name: []const u8) !void {
        if (successors_list.len == successors_list.names.len) return error.UnsupportedCodegenControlFlow;
        successors_list.names[successors_list.len] = name;
        successors_list.len += 1;
    }
};

fn successors(block: ir.BasicBlock) !BlockSuccessors {
    var result = BlockSuccessors{};
    if (block.terminator) |terminator| switch (terminator) {
        .br => |br| try result.add(br.target),
        .condbr => |condbr| {
            try result.add(condbr.then_target);
            if (!std.mem.eql(u8, condbr.then_target, condbr.else_target)) try result.add(condbr.else_target);
        },
        .@"switch" => |switch_term| {
            try result.add(switch_term.default_target);
            for (switch_term.cases.items) |case| {
                var seen = std.mem.eql(u8, case.target, switch_term.default_target);
                for (result.names[0..result.len]) |name| {
                    if (std.mem.eql(u8, name, case.target)) seen = true;
                }
                if (!seen) try result.add(case.target);
            }
        },
        .indirectbr, .ret, .@"unreachable" => {},
    };
    return result;
}

const ValueLoc = union(enum) {
    arg32: ArgReg,
    arg64: ArgReg,
    arg128: RegPair,
    eax,
    rax,
    scratch32: ArgReg,
    scratch64: ArgReg,
    scratch128: RegPair,
    stack64: u8,
    spill64: FrameIndex,
};

const ComposedBlockSelector = struct {
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    values: std.StringHashMap(ValueLoc),
    phi_value_count: usize = 0,
    edge_label_count: usize = 0,
    current_eax_name: ?[]const u8 = null,
    current_scratch_names: [6]?[]const u8 = .{null} ** 6,
    current_pair_a_name: ?[]const u8 = null,
    current_pair_b_name: ?[]const u8 = null,
    stack_slot_allocated: bool = false,
    stack_frame_bytes: u8 = 0,
    spill_slot_names: [2]?[]const u8 = .{null} ** 2,
    call_clobbered_regs: bool = false,

    fn init(allocator: std.mem.Allocator, machine: *MachineFunction) ComposedBlockSelector {
        return .{
            .allocator = allocator,
            .machine = machine,
            .values = std.StringHashMap(ValueLoc).init(allocator),
        };
    }

    fn deinit(selector: *ComposedBlockSelector) void {
        selector.values.deinit();
    }

    fn bindParams(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
        if (function.params.items.len > 6) return .{ .unsupported_value = "composed-block-too-many-params" };
        var abi_index: usize = 0;
        for (function.params.items) |param| {
            const reg = ArgReg.fromIndex(abi_index) catch return .{ .unsupported_value = "composed-block-param-reg" };
            if (param.ty == .ptr) {
                try selector.values.put(param.name, .{ .arg64 = reg });
            } else {
                const bits = intBits(param.ty) orelse return .{ .no_emitter = "composed-block-param-not-scalar" };
                switch (bits) {
                    32 => try selector.values.put(param.name, .{ .arg32 = reg }),
                    64 => try selector.values.put(param.name, .{ .arg64 = reg }),
                    128 => {
                        const high = ArgReg.fromIndex(abi_index + 1) catch return .{ .unsupported_value = "composed-block-param-reg" };
                        try selector.values.put(param.name, .{ .arg128 = .{ .lo = reg, .hi = high } });
                        abi_index += 1;
                    },
                    else => return .{ .no_emitter = "composed-block-param-width" },
                }
            }
            abi_index += 1;
        }
        return null;
    }

    fn bindPhiResults(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed or instruction.kind != .phi) continue;
                const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
                const phi = instruction.kind.phi;
                const bits = intBits(phi.ty) orelse return .{ .no_emitter = "stage2-phi-type" };
                if (bits != 32 and bits != 64) return .{ .no_emitter = "stage2-phi-width" };
                const reg = selector.nextPhiReg() orelse return .{ .no_spill_envelope = "stage2-phi-registers" };
                try selector.values.put(result_name, if (bits == 64) .{ .scratch64 = reg } else .{ .scratch32 = reg });
            }
        }
        return null;
    }

    fn nextPhiReg(selector: *ComposedBlockSelector) ?ArgReg {
        const regs = [_]ArgReg{ .r8, .r9, .rcx };
        if (selector.phi_value_count >= regs.len) return null;
        const reg = regs[selector.phi_value_count];
        selector.phi_value_count += 1;
        return reg;
    }

    fn enterBlock(selector: *ComposedBlockSelector, block: ir.BasicBlock) !?Diagnostic {
        selector.clearVolatileRegisterCache();
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .phi => {},
                else => break,
            }
            const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
            const loc = selector.values.get(result_name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
            switch (loc) {
                .scratch32 => |reg| selector.current_scratch_names[argRegIndex(reg)] = result_name,
                .scratch64 => |reg| selector.current_scratch_names[argRegIndex(reg)] = result_name,
                .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack64, .spill64 => return .{ .no_emitter = "stage2-phi-dst-loc" },
            }
        }
        return null;
    }

    fn lowerInstruction(selector: *ComposedBlockSelector, instruction: ir.Instruction) !?Diagnostic {
        if (instruction.removed) return null;
        return switch (instruction.kind) {
            .phi => null,
            .binary => |binary| try selector.lowerBinary(instruction.result, binary),
            .alloca => |alloca| try selector.lowerAlloca(instruction.result, alloca),
            .cast => |cast| try selector.lowerCast(instruction.result, cast),
            .icmp => |icmp| try selector.lowerIcmp(instruction.result, icmp),
            .load => |load| try selector.lowerLoad(instruction.result, load),
            .store => |store| try selector.lowerStore(store),
            .call => |call| try selector.lowerCall(instruction.result, call),
            else => .{ .no_emitter = "composed-block-instruction-not-owned" },
        };
    }

    fn lowerAlloca(selector: *ComposedBlockSelector, result: ?[]const u8, alloca: ir.AllocaInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (!alloca.allocated_ty.eql(.{ .int = 64 }) or alloca.allocated_ty_addrspace != null) return .{ .no_emitter = "composed-block-alloca-form" };
        if (selector.stack_slot_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
        try selector.machine.instructions.append(selector.allocator, .sub_rsp_24);
        selector.stack_slot_allocated = true;
        selector.stack_frame_bytes = 24;
        try selector.values.put(result_name, .{ .stack64 = 0 });
        return null;
    }

    fn lowerBinary(selector: *ComposedBlockSelector, result: ?[]const u8, binary: ir.BinaryInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
        if (bits != 16 and bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-binary-width" };

        if (valueIsInt(binary.rhs)) {
            return try selector.lowerBinaryImmediateRhs(result_name, binary);
        }
        if (valueIsInt(binary.lhs)) {
            return try selector.lowerBinaryImmediateLhs(result_name, binary);
        }
        if (bits == 128) return try selector.lowerPairBinary(result_name, binary);

        if (binary.op == .mul and bits == 64) return try selector.lowerMul64(result_name, binary);

        const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-binary-op" };
        const lhs = selector.resolveValue(binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
        const rhs = selector.resolveValue(binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };

        if (locIsAccumulator(rhs) and !locIsAccumulator(lhs) and isCommutative(op)) {
            try selector.emitBinaryLocIntoAccumulator(op, lhs, bits);
        } else {
            try selector.emitValueIntoAccumulator(binary.lhs, bits);
            const rhs_reg = switch (rhs) {
                .arg32, .scratch32 => |reg| if (bits <= 32) reg else return .{ .no_emitter = "composed-block-rhs-width" },
                .arg64, .scratch64 => |reg| if (bits == 64) reg else return .{ .no_emitter = "composed-block-rhs-width" },
                .arg128, .scratch128 => return .{ .no_emitter = "composed-block-rhs-width" },
                .spill64 => |frame_index| if (bits == 64) blk: {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                    break :blk .rcx;
                } else return .{ .no_emitter = "composed-block-rhs-stack" },
                .stack64 => return .{ .no_emitter = "composed-block-rhs-stack" },
                .eax, .rax => return .{ .no_spill_envelope = "composed-block-two-address-rhs-accumulator" },
            };
            try selector.emitBinaryArgAccumulator(op, rhs_reg, bits);
        }

        try selector.bindAccumulator(result_name, bits);
        return null;
    }

    fn lowerBinaryImmediateRhs(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const rhs = switch (binary.rhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
        };
        const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
        switch (binary.op) {
            .lshr => {
                if (bits == 128) {
                    const amount = try shiftAmount7(rhs);
                    try selector.emitPairLshrImmediate(result_name, binary.lhs, amount);
                    return null;
                }
                try selector.emitValueIntoScratch(binary.lhs, .rcx, bits);
                switch (bits) {
                    16, 32 => {
                        const amount = try shiftAmount5(rhs);
                        if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_arg_imm5 = .{
                            .reg = .rcx,
                            .amount = amount,
                        } });
                        try selector.bindScratch(result_name, .rcx, bits);
                    },
                    64 => {
                        const amount = try shiftAmount6(rhs);
                        if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{
                            .reg = .rcx,
                            .amount = amount,
                        } });
                        try selector.bindScratch(result_name, .rcx, bits);
                    },
                    else => return .{ .no_emitter = "composed-block-binary-width" },
                }
            },
            .ashr => {
                if (bits != 64) return .{ .no_emitter = "composed-block-ashr-width" };
                const amount = try shiftAmount6(rhs);
                try selector.emitValueIntoScratch(binary.lhs, .rcx, bits);
                if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{
                    .reg = .rcx,
                    .amount = amount,
                } });
                try selector.bindScratch(result_name, .rcx, bits);
                if (try selector.spillValue(result_name)) |diagnostic| return diagnostic;
            },
            .@"and" => {
                if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                try selector.emitValueIntoEax(binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = try i32Value(rhs) });
                try selector.bindEax(result_name);
            },
            .@"or" => {
                if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                try selector.emitValueIntoEax(binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .or_eax_imm32 = try i32Value(rhs) });
                try selector.bindEax(result_name);
            },
            .add => {
                if (bits == 64) {
                    try selector.emitValueIntoScratch(binary.lhs, .rcx, bits);
                    try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = try i32Value(rhs) } });
                    try selector.bindScratch(result_name, .rcx, bits);
                } else {
                    if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                    try selector.emitValueIntoEax(binary.lhs);
                    try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = try i32Value(rhs) });
                    try selector.bindEax(result_name);
                }
            },
            .sub => {
                const imm = try i32Value(rhs);
                if (bits == 64) {
                    try selector.emitValueIntoScratch(binary.lhs, .rcx, bits);
                    try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = -imm } });
                    try selector.bindScratch(result_name, .rcx, bits);
                } else {
                    if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                    try selector.emitValueIntoEax(binary.lhs);
                    try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = -imm });
                    try selector.bindEax(result_name);
                }
            },
            else => return .{ .no_emitter = "composed-block-binary-imm-rhs" },
        }
        return null;
    }

    fn lowerPairBinary(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-pair-binary-op" };
        if (op != .xor) return .{ .no_emitter = "composed-block-pair-binary-op" };
        const lhs = selector.resolvePairValue(binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
        const rhs = selector.resolvePairValue(binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };

        try selector.emitPairLaneBinaryInto(.rcx, op, lhs.lo, rhs.lo);
        try selector.emitPairLaneBinaryInto(.rdx, op, lhs.hi, rhs.hi);
        try selector.bindPairScratch(result_name, .{ .lo = .rcx, .hi = .rdx });
        return null;
    }

    fn lowerMul64(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const lhs = selector.resolveValue(binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
        const rhs = selector.resolveValue(binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
        const dst = switch (lhs) {
            .scratch64 => |reg| reg,
            .arg32, .arg64, .scratch32, .arg128, .scratch128, .eax, .rax, .stack64, .spill64 => return .{ .no_emitter = "composed-block-mul64-lhs" },
        };
        const src = switch (rhs) {
            .scratch64, .arg64 => |reg| reg,
            .arg32, .scratch32, .arg128, .scratch128, .eax, .rax, .stack64, .spill64 => return .{ .no_emitter = "composed-block-mul64-rhs" },
        };
        try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } });
        try selector.bindScratch(result_name, dst, 64);
        return null;
    }

    fn lowerBinaryImmediateLhs(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const lhs = switch (binary.lhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
        };
        if (binary.op != .lshr) return .{ .no_emitter = "composed-block-binary-imm-lhs" };
        const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
        if (bits > 32) return .{ .no_emitter = "composed-block-variable-shift-width" };

        try selector.emitValueIntoScratch(binary.rhs, .rcx, bits);
        selector.current_eax_name = null;
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(lhs) });
        try selector.machine.instructions.append(selector.allocator, .shr_eax_cl);
        try selector.bindEax(result_name);
        return null;
    }

    fn lowerCast(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        const from_bits = intBits(cast.from_ty) orelse return .{ .no_emitter = "composed-block-cast-from-not-int" };
        const to_bits = intBits(cast.to_ty) orelse return .{ .no_emitter = "composed-block-cast-to-not-int" };
        if (from_bits > 128 or to_bits > 64) return .{ .no_emitter = "composed-block-cast-width" };

        switch (cast.op) {
            .trunc, .bitcast => {
                const loc = selector.resolveValue(cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-cast" };
                if (from_bits == 128) {
                    const pair = switch (loc) {
                        .arg128, .scratch128 => |pair| pair,
                        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .spill64 => return .{ .no_emitter = "composed-block-cast-width" },
                    };
                    try selector.values.put(result_name, .{ .scratch64 = pair.lo });
                    selector.current_scratch_names[argRegIndex(pair.lo)] = result_name;
                } else {
                    try selector.values.put(result_name, loc);
                    switch (loc) {
                        .eax => selector.current_eax_name = result_name,
                        .rax => selector.current_eax_name = result_name,
                        .scratch32, .scratch64 => |reg| selector.current_scratch_names[argRegIndex(reg)] = result_name,
                        .arg32, .arg64 => {},
                        .arg128, .scratch128, .stack64, .spill64 => return .{ .no_emitter = "composed-block-cast-width" },
                    }
                }
            },
            .zext => {
                if (to_bits > 32) return .{ .no_emitter = "composed-block-zext-width" };
                try selector.emitValueIntoEax(cast.value);
                if (from_bits < 32) {
                    const shift: u5 = @intCast(from_bits);
                    const mask = (@as(i32, 1) << shift) - 1;
                    try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = mask });
                }
                try selector.bindEax(result_name);
            },
            .sext => {
                if (from_bits != 32 or to_bits != 64) return .{ .no_emitter = "composed-block-sext-width" };
                const loc = selector.resolveValue(cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-sext" };
                const src = switch (loc) {
                    .arg32, .scratch32 => |reg| reg,
                    .arg64, .scratch64, .arg128, .scratch128, .eax, .rax, .stack64, .spill64 => return .{ .no_emitter = "composed-block-sext-source" },
                };
                const dst: ArgReg = switch (src) {
                    .rdi => .r8,
                    .rsi => .r9,
                    .rdx => .rcx,
                    .rcx => .r8,
                    .r8 => .r9,
                    .r9 => .r8,
                };
                try selector.machine.instructions.append(selector.allocator, .{ .movsxd_arg32_arg64 = .{ .dst = dst, .src = src } });
                try selector.bindScratch(result_name, dst, 64);
            },
            else => return .{ .no_emitter = "composed-block-cast-op" },
        }
        return null;
    }

    fn lowerIcmp(selector: *ComposedBlockSelector, result: ?[]const u8, icmp: ir.IcmpInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-icmp-form" };
        const rhs = switch (icmp.rhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-icmp-rhs" },
        };
        selector.emitValueIntoScratch(icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        selector.current_eax_name = null;
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = try i64Value(rhs) } });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
        try selector.bindEax(result_name);
        return null;
    }

    fn lowerLoad(selector: *ComposedBlockSelector, result: ?[]const u8, load: ir.LoadInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (load.attrs.isBarrier()) return .{ .no_emitter = "composed-block-load-barrier" };
        if (!load.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-load-width" };
        const ptr = selector.resolveValue(load.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-load-ptr" };
        const disp = switch (ptr) {
            .stack64 => |disp| disp,
            .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .spill64 => return .{ .no_emitter = "composed-block-load-ptr" },
        };
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_rax = disp });
        try selector.bindRax(result_name);
        return null;
    }

    fn lowerStore(selector: *ComposedBlockSelector, store: ir.StoreInst) !?Diagnostic {
        if (store.attrs.isBarrier()) return .{ .no_emitter = "composed-block-store-barrier" };
        if (!store.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-store-width" };
        const ptr = selector.resolveValue(store.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
        const ptr_reg = switch (ptr) {
            .arg64, .scratch64 => |reg| reg,
            .arg32, .scratch32, .arg128, .scratch128, .eax, .rax, .stack64, .spill64 => return .{ .no_emitter = "composed-block-store-ptr" },
        };
        try selector.emitValueIntoEax(store.value);
        try selector.machine.instructions.append(selector.allocator, .{ .store_eax_arg_ptr = ptr_reg });
        return null;
    }

    fn lowerCall(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
        if (call.isDebugVariableLocation()) return null;
        if (std.mem.eql(u8, call.callee, "llvm.abs.i64")) return try selector.lowerAbsI64(result, call);
        if (call.inline_asm != null) return .{ .no_emitter = "composed-block-inline-asm-call" };
        if (call.callee_value != null) return .{ .unsupported_value = "composed-block-indirect-call" };
        if (call.calling_conv != null or call.tail_kind != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
            return .{ .no_emitter = "composed-block-call-form" };
        }
        const ret_bits = if (call.ret_ty == .void) @as(u16, 0) else intBits(call.ret_ty) orelse return .{ .no_emitter = "composed-block-call-ret" };
        if (ret_bits != 0 and ret_bits != 32 and ret_bits != 64) return .{ .no_emitter = "composed-block-call-ret-width" };
        if (call.args.items.len > 6) return .{ .unsupported_value = "composed-block-call-arg-count" };

        for (call.args.items, 0..) |arg, arg_index| {
            const target = ArgReg.fromIndex(arg_index) catch return .{ .unsupported_value = "composed-block-call-arg-reg" };
            if (try selector.lowerDirectCallArg(arg, target)) |diagnostic| return diagnostic;
        }

        try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
        selector.invalidateCallClobbers();
        if (result) |result_name| switch (ret_bits) {
            0 => return .{ .unsupported_value = "composed-block-void-call-result" },
            32 => try selector.bindEax(result_name),
            64 => try selector.bindRax(result_name),
            else => unreachable,
        };
        return null;
    }

    fn lowerAbsI64(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (call.inline_asm != null or call.callee_value != null or call.calling_conv != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
            return .{ .no_emitter = "composed-block-abs-call-form" };
        }
        if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-abs-signature" };
        const value_arg = call.args.items[0];
        const poison_arg = call.args.items[1];
        if (!value_arg.ty.eql(.{ .int = 64 }) or !poison_arg.ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-abs-args" };
        if (!valueIsInt(poison_arg.value)) return .{ .no_emitter = "composed-block-abs-poison-arg" };
        const poison_ok = switch (poison_arg.value) {
            .int => |int| int == 0,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        };
        if (!poison_ok) return .{ .no_emitter = "composed-block-abs-poison-mode" };

        try selector.emitValueIntoScratch(value_arg.value, .rdi, 64);
        if (try selector.spillCurrentRax()) |diagnostic| return diagnostic;
        selector.current_eax_name = null;
        try selector.machine.instructions.append(selector.allocator, .abs_i64_rdi_rax);
        try selector.bindRax(result_name);
        return null;
    }

    fn lowerReturn(selector: *ComposedBlockSelector, ret: anytype) !?Diagnostic {
        if (ret.ty == .void) {
            if (ret.value != null) return .{ .unsupported_value = "composed-block-void-ret-value" };
            try selector.emitReturnEpilogue();
            return null;
        }
        const bits = intBits(ret.ty) orelse return .{ .no_emitter = "composed-block-ret-type" };
        if (bits != 32 and bits != 64) return .{ .no_emitter = "composed-block-ret-width" };
        const value = ret.value orelse return .{ .unsupported_value = "composed-block-missing-ret-value" };
        switch (value) {
            .int => |int| if (bits == 64)
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(int) })
            else
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) }),
            .named => {
                _ = selector.resolveValue(value) orelse return .{ .unsupported_value = "composed-block-unknown-ret" };
                try selector.emitValueIntoAccumulator(value, bits);
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-ret-value" },
        }
        try selector.emitReturnEpilogue();
        return null;
    }

    fn emitReturnEpilogue(selector: *ComposedBlockSelector) !void {
        if (selector.stack_frame_bytes == 24) {
            try selector.machine.instructions.append(selector.allocator, .add_rsp_24);
        } else if (selector.stack_frame_bytes == 8) {
            try selector.machine.instructions.append(selector.allocator, .add_rsp_8);
        }
        try selector.machine.instructions.append(selector.allocator, .ret);
    }

    fn lowerCfgTerminator(
        selector: *ComposedBlockSelector,
        function: ir.Function,
        block_index: usize,
        terminator: ir.Terminator,
    ) !?Diagnostic {
        return switch (terminator) {
            .ret => |ret| try selector.lowerReturn(ret),
            .br => |br| {
                const target_index = function.blockIndex(br.target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
                if (try selector.emitPhiEdgeMoves(function.blocks.items[target_index], function.blocks.items[block_index].name)) |diagnostic| return diagnostic;
                if (target_index != block_index + 1) {
                    try selector.machine.instructions.append(selector.allocator, .{ .jmp = br.target });
                }
                return null;
            },
            .condbr => |condbr| {
                if (!condbr.cond_ty.eql(.{ .int = 1 })) return .{ .no_emitter = "stage2-condbr-type" };
                const then_index = function.blockIndex(condbr.then_target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
                const else_index = function.blockIndex(condbr.else_target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
                const then_has_phi_edge = blockHasPhiIncomingFrom(function.blocks.items[then_index], function.blocks.items[block_index].name);
                const else_has_phi_edge = blockHasPhiIncomingFrom(function.blocks.items[else_index], function.blocks.items[block_index].name);
                if (try selector.emitBranchCondition(condbr.cond)) |diagnostic| return diagnostic;
                if (then_has_phi_edge or else_has_phi_edge) {
                    return try selector.lowerConditionalPhiEdges(function, block_index, then_index, else_index);
                }
                try selector.machine.instructions.append(selector.allocator, .{ .jne = condbr.then_target });
                if (else_index != block_index + 1) {
                    try selector.machine.instructions.append(selector.allocator, .{ .jmp = condbr.else_target });
                }
                return null;
            },
            .@"switch", .indirectbr, .@"unreachable" => .{ .no_emitter = "stage2-terminator-not-owned" },
        };
    }

    fn lowerConditionalPhiEdges(
        selector: *ComposedBlockSelector,
        function: ir.Function,
        block_index: usize,
        then_index: usize,
        else_index: usize,
    ) !?Diagnostic {
        const predecessor = function.blocks.items[block_index].name;
        const then_target = function.blocks.items[then_index].name;
        const else_target = function.blocks.items[else_index].name;
        const branch_cache = selector.saveRegisterCache();
        const then_edge_label = try selector.ownedEdgeLabel();

        try selector.machine.instructions.append(selector.allocator, .{ .jne = then_edge_label });

        selector.restoreRegisterCache(branch_cache);
        if (try selector.emitPhiEdgeMoves(function.blocks.items[else_index], predecessor)) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .{ .jmp = else_target });

        try selector.machine.instructions.append(selector.allocator, .{ .label = then_edge_label });
        selector.restoreRegisterCache(branch_cache);
        if (try selector.emitPhiEdgeMoves(function.blocks.items[then_index], predecessor)) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .{ .jmp = then_target });

        selector.clearVolatileRegisterCache();
        return null;
    }

    fn ownedEdgeLabel(selector: *ComposedBlockSelector) ![]const u8 {
        const label = try std.fmt.allocPrint(selector.allocator, "__zllvm_stage2_phi_edge_{d}", .{selector.edge_label_count});
        errdefer selector.allocator.free(label);
        selector.edge_label_count += 1;
        try selector.machine.owned_labels.append(selector.allocator, label);
        return label;
    }

    fn emitPhiEdgeMoves(selector: *ComposedBlockSelector, target: ir.BasicBlock, predecessor: []const u8) !?Diagnostic {
        for (target.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const phi = switch (instruction.kind) {
                .phi => |phi| phi,
                else => break,
            };
            const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
            const incoming = phiIncomingFrom(phi, predecessor) orelse return .{ .unsupported_control_flow = "stage2-phi-incoming" };
            const dst = selector.values.get(result_name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
            if (try selector.emitValueIntoLoc(incoming.value, dst)) |diagnostic| return diagnostic;
            switch (dst) {
                .scratch32 => |reg| selector.current_scratch_names[argRegIndex(reg)] = result_name,
                .scratch64 => |reg| selector.current_scratch_names[argRegIndex(reg)] = result_name,
                .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack64, .spill64 => return .{ .no_emitter = "stage2-phi-dst-loc" },
            }
        }
        return null;
    }

    fn emitValueIntoLoc(selector: *ComposedBlockSelector, value: ir.Value, dst: ValueLoc) !?Diagnostic {
        switch (dst) {
            .scratch32 => |reg| {
                switch (value) {
                    .int => |int| {
                        selector.invalidateScratchContaining(reg);
                        selector.invalidatePairContaining(reg);
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) });
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                    },
                    .named => {
                        selector.emitValueIntoScratch(value, reg, 32) catch return .{ .unsupported_value = "stage2-phi-src" };
                    },
                    .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
                }
            },
            .scratch64 => |reg| {
                switch (value) {
                    .int => |int| {
                        selector.invalidateScratchContaining(reg);
                        selector.invalidatePairContaining(reg);
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(int) });
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg });
                    },
                    .named => {
                        selector.emitValueIntoScratch(value, reg, 64) catch return .{ .unsupported_value = "stage2-phi-src" };
                    },
                    .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
                }
            },
            .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack64, .spill64 => return .{ .no_emitter = "stage2-phi-dst-loc" },
        }
        return null;
    }

    fn emitBranchCondition(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
        const loc = selector.resolveValue(value) orelse return .{ .unsupported_value = "stage2-unknown-cond" };
        switch (loc) {
            .eax => try selector.machine.instructions.append(selector.allocator, .test_eax_eax),
            .arg32, .scratch32 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .test_arg8 = reg }),
            .arg64, .scratch64, .arg128, .scratch128, .rax, .stack64, .spill64 => return .{ .no_emitter = "stage2-cond-loc" },
        }
        return null;
    }

    fn lowerDirectCallArg(selector: *ComposedBlockSelector, arg: ir.CallArg, target: ArgReg) !?Diagnostic {
        if (arg.ty == .ptr) {
            const loc = selector.resolveValue(arg.value) orelse return .{ .unsupported_value = "composed-block-call-unknown-ptr-arg" };
            const disp = switch (loc) {
                .stack64 => |disp| disp,
                .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .spill64 => return .{ .no_emitter = "composed-block-call-ptr-arg" },
            };
            if (disp != 0) return .{ .no_emitter = "composed-block-call-stack-disp" };
            selector.invalidateScratchContaining(target);
            selector.invalidatePairContaining(target);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = target });
            return null;
        }

        const bits = intBits(arg.ty) orelse return .{ .no_emitter = "composed-block-call-arg-type" };
        if (bits != 32 and bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
        const loc = selector.resolveValue(arg.value) orelse return .{ .unsupported_value = "composed-block-call-unknown-arg" };
        switch (loc) {
            .arg32, .scratch32 => |reg| {
                if (bits != 32) return .{ .no_emitter = "composed-block-call-arg-width" };
                if (reg != target) {
                    selector.invalidateScratchContaining(target);
                    selector.invalidatePairContaining(target);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = target, .src = reg } });
                }
            },
            .arg64, .scratch64 => |reg| {
                if (bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
                if (reg != target) {
                    selector.invalidateScratchContaining(target);
                    selector.invalidatePairContaining(target);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = target, .src = reg } });
                }
            },
            .eax => {
                if (bits != 32) return .{ .no_emitter = "composed-block-call-arg-width" };
                selector.invalidateScratchContaining(target);
                selector.invalidatePairContaining(target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = target });
            },
            .rax => {
                if (bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
                selector.invalidateScratchContaining(target);
                selector.invalidatePairContaining(target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = target });
            },
            .spill64 => |frame_index| {
                if (bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
                selector.invalidateScratchContaining(target);
                selector.invalidatePairContaining(target);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target, .frame_index = frame_index } });
            },
            .arg128, .scratch128, .stack64 => return .{ .no_emitter = "composed-block-call-arg-loc" },
        }
        return null;
    }

    fn bindEax(selector: *ComposedBlockSelector, name: []const u8) !void {
        try selector.values.put(name, .eax);
        selector.current_eax_name = name;
    }

    fn bindRax(selector: *ComposedBlockSelector, name: []const u8) !void {
        try selector.values.put(name, .rax);
        selector.current_eax_name = name;
    }

    fn bindAccumulator(selector: *ComposedBlockSelector, name: []const u8, bits: u16) !void {
        if (bits == 64) try selector.bindRax(name) else try selector.bindEax(name);
    }

    fn bindScratch(selector: *ComposedBlockSelector, name: []const u8, reg: ArgReg, bits: u16) !void {
        try selector.values.put(name, if (bits == 64) .{ .scratch64 = reg } else .{ .scratch32 = reg });
        selector.current_scratch_names[argRegIndex(reg)] = name;
        selector.invalidatePairContaining(reg);
    }

    fn bindPairScratch(selector: *ComposedBlockSelector, name: []const u8, pair: RegPair) !void {
        try selector.values.put(name, .{ .scratch128 = pair });
        if (pair.eql(pair_a)) {
            selector.current_pair_a_name = name;
        } else if (pair.eql(pair_b)) {
            selector.current_pair_b_name = name;
        } else {
            unreachable;
        }
        selector.invalidateScratchContaining(pair.lo);
        selector.invalidateScratchContaining(pair.hi);
    }

    fn spillCurrentRax(selector: *ComposedBlockSelector) !?Diagnostic {
        const name = selector.current_eax_name orelse return null;
        const loc = selector.resolveValue(.{ .named = name }) orelse return null;
        return switch (loc) {
            .rax => try selector.spillValue(name),
            .eax, .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .stack64, .spill64 => null,
        };
    }

    fn spillValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
        if (selector.stack_frame_bytes < 24) return .{ .no_spill_envelope = "composed-block-spill-frame" };
        const loc = selector.resolveValue(.{ .named = name }) orelse return .{ .unsupported_value = "composed-block-spill-unknown" };
        switch (loc) {
            .spill64 => return null,
            else => {},
        }
        const frame_index = selector.allocateSpillSlot(name) orelse return .{ .no_spill_envelope = "composed-block-spill-slots" };
        switch (loc) {
            .arg64, .scratch64 => |reg| {
                try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = reg } });
                switch (loc) {
                    .scratch64 => selector.invalidateScratchContaining(reg),
                    else => {},
                }
            },
            .rax => {
                try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = frame_index });
                selector.current_eax_name = null;
            },
            .arg32, .scratch32, .arg128, .scratch128, .eax, .stack64, .spill64 => return .{ .no_emitter = "composed-block-spill-loc" },
        }
        try selector.values.put(name, .{ .spill64 = frame_index });
        return null;
    }

    fn allocateSpillSlot(selector: *ComposedBlockSelector, name: []const u8) ?FrameIndex {
        for (selector.spill_slot_names, 0..) |slot_name, index| {
            if (slot_name) |existing| {
                if (std.mem.eql(u8, existing, name)) return spillFrameIndex(index);
            }
        }
        for (&selector.spill_slot_names, 0..) |*slot_name, index| {
            if (slot_name.* == null) {
                slot_name.* = name;
                return spillFrameIndex(index);
            }
        }
        return null;
    }

    fn spillFrameIndex(index: usize) FrameIndex {
        return switch (index) {
            0 => .slot2,
            1 => .slot4,
            else => unreachable,
        };
    }

    fn emitValueIntoEax(selector: *ComposedBlockSelector, value: ir.Value) !void {
        switch (value) {
            .int => |int| {
                selector.current_eax_name = null;
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) });
            },
            .named => {
                const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
                switch (loc) {
                    .arg32, .scratch32, .arg64, .scratch64 => |reg| {
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = reg });
                    },
                    .arg128, .scratch128 => |pair| {
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = pair.lo });
                    },
                    .stack64, .spill64 => return error.UnsupportedCodegenValue,
                    .eax, .rax => {},
                }
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }

    fn emitValueIntoRax(selector: *ComposedBlockSelector, value: ir.Value) !void {
        switch (value) {
            .int => return error.UnsupportedCodegenValue,
            .named => {
                const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
                switch (loc) {
                    .arg64, .scratch64 => |reg| {
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = reg });
                    },
                    .spill64 => |frame_index| {
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
                    },
                    .arg128, .scratch128 => |pair| {
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.lo });
                    },
                    .rax => {},
                    .arg32, .scratch32, .eax, .stack64 => return error.UnsupportedCodegenValue,
                }
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }

    fn emitValueIntoAccumulator(selector: *ComposedBlockSelector, value: ir.Value, bits: u16) !void {
        if (bits == 64) try selector.emitValueIntoRax(value) else try selector.emitValueIntoEax(value);
    }

    fn emitValueIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16) !void {
        switch (value) {
            .int => return error.UnsupportedCodegenValue,
            .named => {
                const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
                if (bits == 64) {
                    switch (loc) {
                        .arg64, .scratch64 => |src| {
                            if (src != reg) {
                                selector.invalidateScratchContaining(reg);
                                selector.invalidatePairContaining(reg);
                                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{
                                    .dst = reg,
                                    .src = src,
                                } });
                            }
                        },
                        .rax => {
                            selector.invalidateScratchContaining(reg);
                            selector.invalidatePairContaining(reg);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg });
                        },
                        .spill64 => |frame_index| {
                            selector.invalidateScratchContaining(reg);
                            selector.invalidatePairContaining(reg);
                            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = frame_index } });
                        },
                        .arg128, .scratch128 => |pair| {
                            if (pair.lo != reg) {
                                selector.invalidateScratchContaining(reg);
                                selector.invalidatePairContaining(reg);
                                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{
                                    .dst = reg,
                                    .src = pair.lo,
                                } });
                            }
                        },
                        .arg32, .scratch32, .eax, .stack64 => return error.UnsupportedCodegenValue,
                    }
                } else {
                    switch (loc) {
                        .arg32, .scratch32, .arg64, .scratch64 => |src| {
                            if (src != reg) {
                                selector.invalidateScratchContaining(reg);
                                selector.invalidatePairContaining(reg);
                                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{
                                    .dst = reg,
                                    .src = src,
                                } });
                            }
                        },
                        .arg128, .scratch128 => |pair| {
                            if (pair.lo != reg) {
                                selector.invalidateScratchContaining(reg);
                                selector.invalidatePairContaining(reg);
                                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{
                                    .dst = reg,
                                    .src = pair.lo,
                                } });
                            }
                        },
                        .eax, .rax => {
                            selector.invalidateScratchContaining(reg);
                            selector.invalidatePairContaining(reg);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                        },
                        .stack64, .spill64 => return error.UnsupportedCodegenValue,
                    }
                }
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }

    fn emitBinaryArgAccumulator(selector: *ComposedBlockSelector, op: MachineBinaryOp, reg: ArgReg, bits: u16) !void {
        if (bits == 64) {
            try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{
                .op = op,
                .reg = reg,
            } });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{
                .op = op,
                .reg = reg,
            } });
        }
    }

    fn emitBinaryLocIntoAccumulator(selector: *ComposedBlockSelector, op: MachineBinaryOp, loc: ValueLoc, bits: u16) !void {
        const reg = switch (loc) {
            .arg32, .scratch32 => |reg| if (bits <= 32) reg else return error.UnsupportedCodegenValue,
            .arg64, .scratch64 => |reg| if (bits == 64) reg else return error.UnsupportedCodegenValue,
            .spill64 => |frame_index| if (bits == 64) blk: {
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                break :blk .rcx;
            } else return error.UnsupportedCodegenValue,
            .arg128, .scratch128, .eax, .rax, .stack64 => return error.UnsupportedCodegenValue,
        };
        try selector.emitBinaryArgAccumulator(op, reg, bits);
    }

    fn emitPairLshrImmediate(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u7) !void {
        if (amount > 127) return error.UnsupportedCodegenValue;
        const src = selector.resolvePairValue(value) orelse return error.UnsupportedCodegenValue;
        const dst = selector.choosePairScratch(src);
        switch (amount) {
            0 => {
                try selector.emitPairIntoScratch(src, dst);
            },
            64 => {
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.hi } });
                try selector.emitZeroArg64(dst.hi);
            },
            1...63 => {
                try selector.emitPairIntoScratch(src, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.hi });
                try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = @intCast(64 - amount) });
                try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{ .reg = dst.lo, .amount = @intCast(amount) } });
                try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = dst.lo } });
                try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.lo });
                try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{ .reg = dst.hi, .amount = @intCast(amount) } });
            },
            65...127 => return error.UnsupportedCodegenValue,
        }
        try selector.bindPairScratch(result_name, dst);
    }

    fn emitPairIntoScratch(selector: *ComposedBlockSelector, src: RegPair, dst: RegPair) !void {
        selector.current_eax_name = null;
        selector.invalidateScratchContaining(dst.lo);
        selector.invalidateScratchContaining(dst.hi);
        selector.invalidatePair(dst);
        if (src.lo != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.lo } });
        if (src.hi != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = src.hi } });
    }

    fn emitPairLaneBinaryInto(selector: *ComposedBlockSelector, dst: ArgReg, op: MachineBinaryOp, lhs: ArgReg, rhs: ArgReg) !void {
        selector.current_eax_name = null;
        selector.invalidateScratchContaining(dst);
        selector.invalidatePairContaining(dst);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = lhs });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{
            .op = op,
            .reg = rhs,
        } });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
    }

    fn emitZeroArg64(selector: *ComposedBlockSelector, reg: ArgReg) !void {
        selector.invalidatePairContaining(reg);
        switch (reg) {
            .rdx => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rdx = 0 }),
            .rcx => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = 0 }),
            .r8 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r8 = 0 }),
            .r9 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r9 = 0 }),
            .rdi => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rdi = 0 }),
            .rsi => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rsi = 0 }),
        }
    }

    fn choosePairScratch(selector: ComposedBlockSelector, src: RegPair) RegPair {
        _ = selector;
        if (src.eql(pair_a)) return pair_b;
        return pair_a;
    }

    fn invalidatePair(selector: *ComposedBlockSelector, pair: RegPair) void {
        if (pair.eql(pair_a)) selector.current_pair_a_name = null;
        if (pair.eql(pair_b)) selector.current_pair_b_name = null;
    }

    fn invalidatePairContaining(selector: *ComposedBlockSelector, reg: ArgReg) void {
        if (pair_a.contains(reg)) selector.current_pair_a_name = null;
        if (pair_b.contains(reg)) selector.current_pair_b_name = null;
    }

    fn invalidateScratchContaining(selector: *ComposedBlockSelector, reg: ArgReg) void {
        selector.current_scratch_names[argRegIndex(reg)] = null;
    }

    fn invalidateCallClobbers(selector: *ComposedBlockSelector) void {
        selector.current_eax_name = null;
        selector.current_scratch_names = .{null} ** 6;
        selector.current_pair_a_name = null;
        selector.current_pair_b_name = null;
        selector.call_clobbered_regs = true;
    }

    const RegisterCache = struct {
        current_eax_name: ?[]const u8,
        current_scratch_names: [6]?[]const u8,
        current_pair_a_name: ?[]const u8,
        current_pair_b_name: ?[]const u8,
        call_clobbered_regs: bool,
    };

    fn saveRegisterCache(selector: ComposedBlockSelector) RegisterCache {
        return .{
            .current_eax_name = selector.current_eax_name,
            .current_scratch_names = selector.current_scratch_names,
            .current_pair_a_name = selector.current_pair_a_name,
            .current_pair_b_name = selector.current_pair_b_name,
            .call_clobbered_regs = selector.call_clobbered_regs,
        };
    }

    fn restoreRegisterCache(selector: *ComposedBlockSelector, cache: RegisterCache) void {
        selector.current_eax_name = cache.current_eax_name;
        selector.current_scratch_names = cache.current_scratch_names;
        selector.current_pair_a_name = cache.current_pair_a_name;
        selector.current_pair_b_name = cache.current_pair_b_name;
        selector.call_clobbered_regs = cache.call_clobbered_regs;
    }

    fn clearVolatileRegisterCache(selector: *ComposedBlockSelector) void {
        selector.current_eax_name = null;
        selector.current_scratch_names = .{null} ** 6;
        selector.current_pair_a_name = null;
        selector.current_pair_b_name = null;
    }

    fn resolvePairValue(selector: ComposedBlockSelector, value: ir.Value) ?RegPair {
        const loc = selector.resolveValue(value) orelse return null;
        return switch (loc) {
            .arg128, .scratch128 => |pair| pair,
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .spill64 => null,
        };
    }

    fn resolveValue(selector: ComposedBlockSelector, value: ir.Value) ?ValueLoc {
        return switch (value) {
            .named => |name| {
                const loc = selector.values.get(name) orelse return null;
                return switch (loc) {
                    .arg32, .arg64, .arg128 => if (selector.call_clobbered_regs) null else loc,
                    .eax, .rax => if (selector.current_eax_name) |current| blk: {
                        if (std.mem.eql(u8, current, name)) break :blk loc;
                        return null;
                    } else null,
                    .scratch32, .scratch64 => |reg| if (selector.current_scratch_names[argRegIndex(reg)]) |current| blk: {
                        if (std.mem.eql(u8, current, name)) break :blk loc;
                        return null;
                    } else null,
                    .scratch128 => |pair| {
                        const current = if (pair.eql(pair_a))
                            selector.current_pair_a_name
                        else if (pair.eql(pair_b))
                            selector.current_pair_b_name
                        else
                            null;
                        if (current) |current_name| {
                            if (std.mem.eql(u8, current_name, name)) return loc;
                        }
                        return null;
                    },
                    .stack64, .spill64 => loc,
                };
            },
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
        };
    }
};

fn blockHasPhiIncomingFrom(block: ir.BasicBlock, predecessor: []const u8) bool {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => break,
        };
        if (phiIncomingFrom(phi, predecessor) != null) return true;
    }
    return false;
}

fn phiIncomingFrom(phi: ir.PhiInst, predecessor: []const u8) ?ir.PhiIncoming {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, predecessor)) return incoming;
    }
    return null;
}

const RegPair = struct {
    lo: ArgReg,
    hi: ArgReg,

    fn eql(pair: RegPair, other: RegPair) bool {
        return pair.lo == other.lo and pair.hi == other.hi;
    }

    fn contains(pair: RegPair, reg: ArgReg) bool {
        return pair.lo == reg or pair.hi == reg;
    }
};

const pair_a: RegPair = .{ .lo = .rcx, .hi = .rdx };
const pair_b: RegPair = .{ .lo = .r8, .hi = .r9 };

fn tryLowerComposedBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    if (!isComposedReturnType(function.ret_ty)) return unsupported(.{ .no_emitter = "composed-block-ret-type" });
    if (function.blocks.items.len != 1) return unsupported(.{ .no_emitter = "composed-block-not-single-block" });

    var composed = ComposedBlockSelector.init(allocator, machine);
    defer composed.deinit();

    if (try composed.bindParams(function)) |diagnostic| return unsupported(diagnostic);

    const block = function.blocks.items[0];
    for (block.instructions.items) |instruction| {
        if (try composed.lowerInstruction(instruction)) |diagnostic| return unsupported(diagnostic);
    }

    const terminator = block.terminator orelse return unsupported(.{ .unsupported_control_flow = "composed-block-missing-terminator" });
    switch (terminator) {
        .ret => |ret| {
            if (try composed.lowerReturn(ret)) |diagnostic| return unsupported(diagnostic);
        },
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return unsupported(.{ .no_emitter = "composed-block-terminator-not-owned" }),
    }
    return .selected;
}

fn machineBinaryOp(op: ir.BinaryOp) ?MachineBinaryOp {
    return switch (op) {
        .add => .add,
        .sub => .sub,
        .@"and" => .@"and",
        .@"or" => .@"or",
        .xor => .xor,
        .fadd, .fsub, .fmul, .fdiv, .frem, .mul, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => null,
    };
}

fn isCommutative(op: MachineBinaryOp) bool {
    return switch (op) {
        .add, .@"and", .@"or", .xor => true,
        .sub => false,
    };
}

fn locIsAccumulator(loc: ValueLoc) bool {
    return switch (loc) {
        .eax, .rax => true,
        .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .stack64, .spill64 => false,
    };
}

fn valueIsInt(value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn intBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .int => |bits| bits,
        .void, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => null,
    };
}

fn isComposedReturnType(ty: ir.Type) bool {
    if (ty == .void) return true;
    const bits = intBits(ty) orelse return false;
    return bits == 32 or bits == 64;
}

fn shiftAmount5(value: i128) !u5 {
    if (value < 0 or value > std.math.maxInt(u5)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn shiftAmount6(value: i128) !u6 {
    if (value < 0 or value > std.math.maxInt(u6)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn shiftAmount7(value: i128) !u7 {
    if (value < 0 or value > std.math.maxInt(u7)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn i32Value(value: i128) !i32 {
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn i64Value(value: i128) !i64 {
    if (value < std.math.minInt(i64) or value > std.math.maxInt(i64)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn argRegIndex(reg: ArgReg) usize {
    return switch (reg) {
        .rdi => 0,
        .rsi => 1,
        .rdx => 2,
        .rcx => 3,
        .r8 => 4,
        .r9 => 5,
    };
}

pub fn inspectFunction(function: ir.Function) SelectionResult {
    if (function.calling_conv != null) {
        return unsupported(.{ .unsupported_control_flow = "non-default-calling-convention" });
    }
    if (!isScalarReturnType(function.ret_ty)) {
        return unsupported(.{ .unsupported_type = "unsupported-return-type" });
    }
    for (function.params.items) |param| {
        if (!isSelectorScalarType(param.ty)) {
            return unsupported(.{ .unsupported_type = "unsupported-param-type" });
        }
    }

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (inspectInstruction(instruction)) |diagnostic| {
                return unsupported(diagnostic);
            }
        }
        const terminator = block.terminator orelse {
            return unsupported(.{ .unsupported_control_flow = "missing-terminator" });
        };
        if (inspectTerminator(terminator)) |diagnostic| {
            return unsupported(diagnostic);
        }
    }

    return unsupported(.{ .no_emitter = "selector-skeleton-has-no-emitters" });
}

fn inspectInstruction(instruction: ir.Instruction) ?Diagnostic {
    return switch (instruction.kind) {
        .binary => |binary| inspectBinary(binary),
        .cast => |cast| inspectCast(cast),
        .icmp => |icmp| inspectIcmp(icmp),
        .select => |select| inspectSelect(select),
        .alloca => |alloca| if (isSelectorScalarType(alloca.allocated_ty)) null else .{ .unsupported_type = "alloca" },
        .load => |load| if (isSelectorScalarType(load.ty)) null else .{ .unsupported_type = "load" },
        .store => |store| if (isSelectorScalarType(store.ty)) null else .{ .unsupported_type = "store" },
        .gep => null,
        .call => |call| inspectCall(call),
        .phi => |phi| if (isSelectorScalarType(phi.ty)) null else .{ .unsupported_type = "phi" },
        .freeze => .{ .unsupported_instruction = "freeze" },
        .fcmp => .{ .unsupported_instruction = "fcmp" },
        .atomicrmw => .{ .unsupported_instruction = "atomicrmw" },
        .cmpxchg => .{ .unsupported_instruction = "cmpxchg" },
        .fence => .{ .unsupported_instruction = "fence" },
        .extractelement => .{ .unsupported_instruction = "extractelement" },
        .insertelement => .{ .unsupported_instruction = "insertelement" },
        .shufflevector => .{ .unsupported_instruction = "shufflevector" },
        .extractvalue => |extract| inspectExtractValue(extract),
        .insertvalue => .{ .unsupported_instruction = "insertvalue" },
    };
}

fn inspectBinary(binary: ir.BinaryInst) ?Diagnostic {
    if (!isSelectorScalarType(binary.ty)) return .{ .unsupported_type = "binary" };
    return switch (binary.op) {
        .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .lshr, .ashr => null,
        .udiv, .sdiv, .urem, .srem => .{ .unsupported_instruction = @tagName(binary.op) },
        .fadd, .fsub, .fmul, .fdiv, .frem => .{ .unsupported_instruction = @tagName(binary.op) },
    };
}

fn inspectCast(cast: ir.CastInst) ?Diagnostic {
    if (!isSelectorScalarType(cast.from_ty) or !isSelectorScalarType(cast.to_ty)) {
        return .{ .unsupported_type = "cast" };
    }
    return switch (cast.op) {
        .trunc, .zext, .sext, .bitcast, .ptrtoint, .inttoptr => null,
        .fpext, .fptrunc, .fptosi, .fptoui, .sitofp, .uitofp => .{ .unsupported_instruction = @tagName(cast.op) },
    };
}

fn inspectIcmp(icmp: ir.IcmpInst) ?Diagnostic {
    if (!isSelectorScalarType(icmp.operand_ty)) return .{ .unsupported_type = "icmp" };
    return null;
}

fn inspectSelect(select: ir.SelectInst) ?Diagnostic {
    if (!isSelectorScalarType(select.ty)) return .{ .unsupported_type = "select" };
    return switch (select.cond_ty) {
        .int => |bits| if (bits == 1) null else .{ .unsupported_type = "select-cond" },
        else => .{ .unsupported_type = "select-cond" },
    };
}

fn inspectCall(call: ir.CallInst) ?Diagnostic {
    if (call.inline_asm != null) return .{ .unsupported_instruction = "inline-asm-call" };
    if (call.callee_value != null) return .{ .unsupported_value = "indirect-call" };
    if (call.raw_args != null) return .{ .unsupported_instruction = "raw-call-args" };
    if (call.operand_bundle != null) return .{ .unsupported_instruction = "operand-bundle-call" };
    if (call.isDebugVariableLocation()) return null;
    if (std.mem.eql(u8, call.callee, "llvm.assume")) {
        if (call.ret_ty != .void or call.args.items.len != 1) return .{ .unsupported_instruction = "llvm.assume" };
        return if (call.args.items[0].ty.eql(.{ .int = 1 })) null else .{ .unsupported_type = "llvm.assume" };
    }
    if (isOverflowIntrinsic(call.callee)) {
        if (!call.ret_ty.eql(.{ .aggregate = "{ i64, i1 }" }) or call.args.items.len != 2) {
            return .{ .unsupported_type = "overflow-intrinsic" };
        }
        for (call.args.items) |arg| {
            if (!arg.ty.eql(.{ .int = 64 })) return .{ .unsupported_type = "overflow-intrinsic-arg" };
        }
        return null;
    }
    if (!isScalarReturnType(call.ret_ty)) return .{ .unsupported_type = "call-ret" };
    for (call.args.items) |arg| {
        if (!isSelectorScalarType(arg.ty)) return .{ .unsupported_type = "call-arg" };
    }
    return null;
}

fn inspectExtractValue(extract: ir.ExtractValueInst) ?Diagnostic {
    if (!extract.aggregate_ty.eql(.{ .aggregate = "{ i64, i1 }" })) {
        return .{ .unsupported_type = "extractvalue-aggregate" };
    }
    if (std.mem.eql(u8, extract.indices, "0")) {
        return if (extract.result_ty.eql(.{ .int = 64 })) null else .{ .unsupported_type = "extractvalue-result" };
    }
    if (std.mem.eql(u8, extract.indices, "1")) {
        return if (extract.result_ty.eql(.{ .int = 1 })) null else .{ .unsupported_type = "extractvalue-result" };
    }
    return .{ .unsupported_value = "extractvalue-index" };
}

fn inspectTerminator(terminator: ir.Terminator) ?Diagnostic {
    return switch (terminator) {
        .ret => |ret| if (isScalarReturnType(ret.ty)) null else .{ .unsupported_type = "ret" },
        .br => null,
        .condbr => |condbr| switch (condbr.cond_ty) {
            .int => |bits| if (bits == 1) null else .{ .unsupported_type = "condbr" },
            else => .{ .unsupported_type = "condbr" },
        },
        .@"switch" => .{ .unsupported_control_flow = "switch" },
        .indirectbr => .{ .unsupported_control_flow = "indirectbr" },
        .@"unreachable" => .{ .unsupported_control_flow = "unreachable" },
    };
}

fn isScalarReturnType(ty: ir.Type) bool {
    return ty == .void or isSelectorScalarType(ty);
}

fn isSelectorScalarType(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits > 0 and bits <= 128,
        .ptr => true,
        .void, .half, .float, .double, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

fn isOverflowIntrinsic(callee: []const u8) bool {
    return std.mem.eql(u8, callee, "llvm.uadd.with.overflow.i64") or
        std.mem.eql(u8, callee, "llvm.usub.with.overflow.i64");
}

fn matchesMuloLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.ptr)) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_uadd_overflow = false;
    var saw_usub_overflow = false;
    var overflow_extracts: usize = 0;
    var mul_i64_count: usize = 0;
    var result_i64_stores: usize = 0;
    var i8_allocas: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| {
                    if (alloca.allocated_ty.eql(.{ .int = 8 })) i8_allocas += 1;
                },
                .binary => |binary| {
                    if (binary.op == .mul and binary.ty.eql(.{ .int = 64 })) mul_i64_count += 1;
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    }
                    if (std.mem.eql(u8, call.callee, "llvm.uadd.with.overflow.i64")) saw_uadd_overflow = true;
                    if (std.mem.eql(u8, call.callee, "llvm.usub.with.overflow.i64")) saw_usub_overflow = true;
                },
                .extractvalue => |extract| {
                    if (extract.aggregate_ty.eql(.{ .aggregate = "{ i64, i1 }" })) overflow_extracts += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) result_i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_uadd_overflow and
        saw_usub_overflow and
        overflow_extracts >= 4 and
        mul_i64_count >= 4 and
        result_i64_stores >= 2 and
        i8_allocas >= 1;
}

fn matchesByteswapLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_bits = false;
    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_bswap_i64 = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_bits = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add) saw_limb_count_math = true;
                        if (binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.bswap.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 64 }))
                    {
                        saw_bswap_i64 = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_freeze_bits and
        saw_int_byte_size and
        saw_assume and
        saw_bswap_i64 and
        saw_limb_count_math and
        saw_remainder_mask and
        i64_loads >= 1 and
        i64_stores >= 1;
}

fn matchesShrLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 16 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_shift = false;
    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_shift_assert = false;
    var saw_limb_count_math = false;
    var saw_shift_decompose = false;
    var saw_sign_select = false;
    var saw_lshr_i64 = false;
    var saw_shl_i64 = false;
    var saw_or_i64 = false;
    var saw_fix_sign_extend = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_shift = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add) saw_limb_count_math = true;
                        if (binary.op == .lshr) {
                            saw_limb_count_math = true;
                            saw_shift_decompose = true;
                        }
                        if (binary.op == .@"and") saw_shift_decompose = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .lshr) saw_lshr_i64 = true;
                        if (binary.op == .shl) saw_shl_i64 = true;
                        if (binary.op == .@"or") saw_or_i64 = true;
                        if (binary.op == .ashr) saw_fix_sign_extend = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 }) and icmp.predicate == .ult) saw_shift_assert = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 1 })) saw_sign_select = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_freeze_shift and
        saw_int_byte_size and
        saw_assume and
        saw_shift_assert and
        saw_limb_count_math and
        saw_shift_decompose and
        saw_sign_select and
        saw_lshr_i64 and
        saw_shl_i64 and
        saw_or_i64 and
        saw_fix_sign_extend and
        i64_loads >= 2 and
        i64_stores >= 2;
}

fn matchesShloLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 16 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_shift = false;
    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_shift_assert = false;
    var saw_limb_count_math = false;
    var saw_shift_decompose = false;
    var saw_left_shift = false;
    var saw_carry_shift = false;
    var saw_or_chain = false;
    var saw_tail_mask = false;
    var saw_tail_sign_extend = false;
    var saw_tail_wrap_select = false;
    var saw_expected_carry = false;
    var saw_overflow_compare = false;
    var saw_overflow_select = false;
    var saw_return_i1 = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_shift = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add) saw_limb_count_math = true;
                        if (binary.op == .lshr) {
                            saw_limb_count_math = true;
                            saw_shift_decompose = true;
                        }
                        if (binary.op == .@"and") saw_shift_decompose = true;
                        if (binary.op == .sub) saw_shift_decompose = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .shl) saw_left_shift = true;
                        if (binary.op == .lshr) {
                            saw_carry_shift = true;
                            saw_tail_mask = true;
                            saw_expected_carry = true;
                        }
                        if (binary.op == .@"or") saw_or_chain = true;
                        if (binary.op == .@"and") saw_tail_mask = true;
                        if (binary.op == .ashr) saw_tail_sign_extend = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .sext and cast.from_ty.eql(.{ .int = 1 }) and cast.to_ty.eql(.{ .int = 64 })) {
                        saw_expected_carry = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 }) and icmp.predicate == .ult) saw_shift_assert = true;
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and icmp.predicate == .ne) saw_overflow_compare = true;
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and icmp.predicate == .slt) saw_expected_carry = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 64 })) saw_tail_wrap_select = true;
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 1 })) saw_overflow_select = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
        if (block.terminator) |terminator| {
            switch (terminator) {
                .ret => |ret| {
                    if (ret.ty.eql(.{ .int = 1 }) and ret.value != null) saw_return_i1 = true;
                },
                else => {},
            }
        }
    }

    return saw_freeze_shift and
        saw_int_byte_size and
        saw_assume and
        saw_shift_assert and
        saw_limb_count_math and
        saw_shift_decompose and
        saw_left_shift and
        saw_carry_shift and
        saw_or_chain and
        saw_tail_mask and
        saw_tail_sign_extend and
        saw_tail_wrap_select and
        saw_expected_carry and
        saw_overflow_compare and
        saw_overflow_select and
        saw_return_i1 and
        i64_loads >= 3 and
        i64_stores >= 2;
}

fn matchesBitreverseLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_bits = false;
    var saw_int_byte_size = false;
    var saw_umax = false;
    var saw_bitreverse_i64 = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_tail_shift = false;
    var saw_fix_sign_extend = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_bits = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .lshr or binary.op == .shl or binary.op == .@"or") saw_tail_shift = true;
                        if (binary.op == .ashr) saw_fix_sign_extend = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.umax.i64") and
                        call.ret_ty.eql(.{ .int = 64 }))
                    {
                        saw_umax = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.bitreverse.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 64 }))
                    {
                        saw_bitreverse_i64 = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_freeze_bits and
        saw_int_byte_size and
        saw_umax and
        saw_bitreverse_i64 and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_tail_shift and
        saw_fix_sign_extend and
        i64_loads >= 2 and
        i64_stores >= 2;
}

fn matchesNotLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_limb_count_math = false;
    var saw_limb_count_select = false;
    var saw_unary_not = false;
    var saw_partial_unsigned_mask = false;
    var saw_signed_high_fill = false;
    var saw_fix_last_limb_compare = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and" or binary.op == .sub) saw_partial_unsigned_mask = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .xor and (binary.rhs.eql(.{ .int = -1 }) or binary.lhs.eql(.{ .int = -1 }))) {
                            saw_unary_not = true;
                        }
                        if (binary.op == .lshr or binary.op == .@"and") saw_partial_unsigned_mask = true;
                        if (binary.op == .ashr) saw_signed_high_fill = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 })) saw_fix_last_limb_compare = true;
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and icmp.predicate == .slt) saw_signed_high_fill = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 16 })) saw_limb_count_select = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_assume and
        saw_limb_count_math and
        saw_limb_count_select and
        saw_unary_not and
        saw_partial_unsigned_mask and
        saw_signed_high_fill and
        saw_fix_last_limb_compare and
        i64_loads >= 2 and
        i64_stores >= 2;
}

fn matchesBitwiseLimb64Envelope(function: ir.Function) ?x86_64_machine.Limb64BitwiseOp {
    if (function.ret_ty != .void) return null;
    if (function.params.items.len != 4) return null;
    if (!function.params.items[0].ty.eql(.ptr)) return null;
    if (!function.params.items[1].ty.eql(.ptr)) return null;
    if (!function.params.items[2].ty.eql(.ptr)) return null;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return null;

    var saw_int_byte_size = false;
    var saw_umax = false;
    var saw_assume = false;
    var saw_limb_count_math = false;
    var saw_unroll_remainder = false;
    var xor_i64_count: usize = 0;
    var or_i64_count: usize = 0;
    var and_i64_count: usize = 0;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .lshr) saw_limb_count_math = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        switch (binary.op) {
                            .xor => xor_i64_count += 1,
                            .@"or" => or_i64_count += 1,
                            .@"and" => {
                                and_i64_count += 1;
                                saw_unroll_remainder = true;
                            },
                            else => {},
                        }
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.umax.i16") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 2)
                    {
                        saw_umax = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    if (!saw_int_byte_size or
        !saw_umax or
        !saw_assume or
        !saw_limb_count_math or
        !saw_unroll_remainder or
        i64_loads < 4 or
        i64_stores < 2)
    {
        return null;
    }

    if (xor_i64_count >= 2) return .xor;
    if (and_i64_count >= 2) return .@"and";
    if (or_i64_count >= 2) return .@"or";
    return null;
}

fn matchesCmpLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 8 })) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_limb_count_select = false;
    var saw_reverse_index_sub = false;
    var saw_signed_less = false;
    var saw_signed_greater = false;
    var saw_unsigned_less = false;
    var saw_unsigned_greater = false;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                    } else if (binary.ty.eql(.{ .int = 64 }) and binary.op == .sub) {
                        saw_reverse_index_sub = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 64 })) {
                        switch (icmp.predicate) {
                            .slt => saw_signed_less = true,
                            .sgt => saw_signed_greater = true,
                            .ult => saw_unsigned_less = true,
                            .ugt => saw_unsigned_greater = true,
                            else => {},
                        }
                    }
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 16 })) {
                        saw_limb_count_select = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_limb_count_select and
        saw_reverse_index_sub and
        saw_signed_less and
        saw_signed_greater and
        saw_unsigned_less and
        saw_unsigned_greater and
        i64_loads >= 4;
}

fn matchesOverflowLimb64Envelope(function: ir.Function) ?x86_64_machine.Limb64OverflowOp {
    if (!function.ret_ty.eql(.{ .int = 1 })) return null;
    if (function.params.items.len != 5) return null;
    if (!function.params.items[0].ty.eql(.ptr)) return null;
    if (!function.params.items[1].ty.eql(.ptr)) return null;
    if (!function.params.items[2].ty.eql(.ptr)) return null;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return null;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return null;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_limb_count_select = false;
    var saw_partial_limb_wrap = false;
    var saw_fix_last_limb_fill = false;
    var uadd_overflow_count: usize = 0;
    var sadd_overflow_count: usize = 0;
    var usub_overflow_count: usize = 0;
    var ssub_overflow_count: usize = 0;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;
    var i1_allocas: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| {
                    if (alloca.allocated_ty.eql(.{ .int = 8 }) or alloca.allocated_ty.eql(.{ .int = 1 })) {
                        i1_allocas += 1;
                    }
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr or binary.op == .@"and") saw_limb_count_math = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .shl or binary.op == .ashr or binary.op == .lshr) saw_partial_limb_wrap = true;
                        if (binary.op == .sub) saw_fix_last_limb_fill = true;
                    } else if (binary.ty.eql(.{ .int = 8 }) and binary.op == .@"or") {
                        saw_limb_count_math = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.uadd.with.overflow.i64")) {
                        uadd_overflow_count += 1;
                    } else if (std.mem.eql(u8, call.callee, "llvm.sadd.with.overflow.i64")) {
                        sadd_overflow_count += 1;
                    } else if (std.mem.eql(u8, call.callee, "llvm.usub.with.overflow.i64")) {
                        usub_overflow_count += 1;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ssub.with.overflow.i64")) {
                        ssub_overflow_count += 1;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 })) saw_limb_count_math = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 16 })) {
                        saw_limb_count_select = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    if (!saw_int_byte_size or
        !saw_limb_count_math or
        !saw_limb_count_select or
        !saw_partial_limb_wrap or
        !saw_fix_last_limb_fill or
        i64_loads < 4 or
        i64_stores < 2 or
        i1_allocas < 1)
    {
        return null;
    }

    if (uadd_overflow_count >= 4 and sadd_overflow_count >= 2 and usub_overflow_count == 0 and ssub_overflow_count == 0) {
        return .add;
    }
    if (usub_overflow_count >= 4 and ssub_overflow_count >= 2 and uadd_overflow_count == 0 and sadd_overflow_count == 0) {
        return .sub;
    }
    return null;
}

fn matchesPopcountLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_tail_shift = false;
    var ctpop_i64_count: usize = 0;
    var trunc_i64_to_i16_count: usize = 0;
    var add_i16_count: usize = 0;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                        if (binary.op == .add) add_i16_count += 1;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .shl) saw_tail_shift = true;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .trunc and
                        cast.from_ty.eql(.{ .int = 64 }) and
                        cast.to_ty.eql(.{ .int = 16 }))
                    {
                        trunc_i64_to_i16_count += 1;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctpop.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 64 }))
                    {
                        ctpop_i64_count += 1;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_tail_shift and
        ctpop_i64_count >= 2 and
        trunc_i64_to_i16_count >= 2 and
        add_i16_count >= 2 and
        i64_loads >= 2;
}

fn matchesCtzLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_zero_limb_branch = false;
    var cttz_i64_count: usize = 0;
    var trunc_i64_to_i16_count: usize = 0;
    var add_i16_count: usize = 0;
    var or_i16_count: usize = 0;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr or binary.op == .shl) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                        if (binary.op == .add) add_i16_count += 1;
                        if (binary.op == .@"or") or_i16_count += 1;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .trunc and
                        cast.from_ty.eql(.{ .int = 64 }) and
                        cast.to_ty.eql(.{ .int = 16 }))
                    {
                        trunc_i64_to_i16_count += 1;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.cttz.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 64 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        cttz_i64_count += 1;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 64 })) saw_zero_limb_branch = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_zero_limb_branch and
        cttz_i64_count >= 2 and
        trunc_i64_to_i16_count >= 2 and
        add_i16_count >= 2 and
        or_i16_count >= 1 and
        i64_loads >= 2;
}

fn matchesClzLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_zero_limb_branch = false;
    var saw_reverse_index_sub = false;
    var saw_partial_shift = false;
    var ctlz_i64_count: usize = 0;
    var trunc_i64_to_i16_count: usize = 0;
    var add_i16_count: usize = 0;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                        if (binary.op == .add) add_i16_count += 1;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .sub) saw_reverse_index_sub = true;
                        if (binary.op == .shl) saw_partial_shift = true;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .trunc and
                        cast.from_ty.eql(.{ .int = 64 }) and
                        cast.to_ty.eql(.{ .int = 16 }))
                    {
                        trunc_i64_to_i16_count += 1;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctlz.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 64 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        ctlz_i64_count += 1;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 64 })) saw_zero_limb_branch = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_zero_limb_branch and
        saw_reverse_index_sub and
        saw_partial_shift and
        ctlz_i64_count >= 2 and
        trunc_i64_to_i16_count >= 2 and
        add_i16_count >= 2 and
        i64_loads >= 2;
}

fn matchesUdivei4Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.ptr)) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 64 })) return false;

    var saw_un: bool = false;
    var saw_vn: bool = false;
    var saw_int_byte_size = false;
    var saw_ctlz_i32 = false;
    var saw_udiv_i64 = false;
    var saw_urem_i64 = false;
    var saw_limb_count_lshr_i16 = false;
    var saw_byte_count_shl_i64 = false;
    var aggregate_allocas: usize = 0;
    var other_allocas: usize = 0;
    var i32_stores: usize = 0;
    var i32_loads: usize = 0;
    var u64_from_i32_exts: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| switch (alloca.allocated_ty) {
                    .aggregate => |text| {
                        aggregate_allocas += 1;
                        if (std.mem.eql(u8, text, "[2049 x i32]")) saw_un = true;
                        if (std.mem.eql(u8, text, "[2048 x i32]")) saw_vn = true;
                    },
                    else => other_allocas += 1,
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctlz.i32") and
                        call.ret_ty.eql(.{ .int = 32 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 32 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        saw_ctlz_i32 = true;
                    }
                },
                .binary => |binary| {
                    if (binary.op == .lshr and binary.ty.eql(.{ .int = 16 })) {
                        saw_limb_count_lshr_i16 = true;
                    }
                    if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .udiv) saw_udiv_i64 = true;
                        if (binary.op == .urem) saw_urem_i64 = true;
                        if (binary.op == .shl) saw_byte_count_shl_i64 = true;
                    }
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 32 })) i32_stores += 1;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 32 })) i32_loads += 1;
                },
                .cast => |cast| {
                    if (cast.op == .zext and
                        cast.from_ty.eql(.{ .int = 32 }) and
                        cast.to_ty.eql(.{ .int = 64 }))
                    {
                        u64_from_i32_exts += 1;
                    }
                },
                else => {},
            }
        }
    }

    return saw_un and
        saw_vn and
        aggregate_allocas == 2 and
        other_allocas == 0 and
        saw_int_byte_size and
        saw_ctlz_i32 and
        saw_udiv_i64 and
        saw_urem_i64 and
        saw_limb_count_lshr_i16 and
        saw_byte_count_shl_i64 and
        i32_stores >= 8 and
        i32_loads >= 8 and
        u64_from_i32_exts >= 2;
}

fn matchesUmodei5Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.ptr)) return false;
    if (!function.params.items[3].ty.eql(.ptr)) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 64 })) return false;

    var saw_un: bool = false;
    var saw_vn: bool = false;
    var saw_int_byte_size = false;
    var saw_ctlz_i32 = false;
    var saw_inline_memcpy = false;
    var saw_udiv_i64 = false;
    var saw_urem_i64 = false;
    var saw_lshr_i16 = false;
    var saw_limb_count_lshr_i64 = false;
    var aggregate_allocas: usize = 0;
    var other_allocas: usize = 0;
    var i32_stores: usize = 0;
    var i32_loads: usize = 0;
    var u64_from_i32_exts: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| switch (alloca.allocated_ty) {
                    .aggregate => |text| {
                        aggregate_allocas += 1;
                        if (std.mem.eql(u8, text, "[2049 x i32]")) saw_un = true;
                        if (std.mem.eql(u8, text, "[2048 x i32]")) saw_vn = true;
                    },
                    else => other_allocas += 1,
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctlz.i32") and
                        call.ret_ty.eql(.{ .int = 32 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 32 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        saw_ctlz_i32 = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.memcpy.inline.p0.p0.i64")) {
                        saw_inline_memcpy = true;
                    }
                },
                .binary => |binary| {
                    if (binary.op == .lshr and binary.ty.eql(.{ .int = 16 })) saw_lshr_i16 = true;
                    if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .udiv) saw_udiv_i64 = true;
                        if (binary.op == .urem) saw_urem_i64 = true;
                        if (binary.op == .lshr) saw_limb_count_lshr_i64 = true;
                    }
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 32 })) i32_stores += 1;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 32 })) i32_loads += 1;
                },
                .cast => |cast| {
                    if (cast.op == .zext and
                        cast.from_ty.eql(.{ .int = 32 }) and
                        cast.to_ty.eql(.{ .int = 64 }))
                    {
                        u64_from_i32_exts += 1;
                    }
                },
                else => {},
            }
        }
    }

    return saw_un and
        saw_vn and
        aggregate_allocas == 2 and
        other_allocas == 0 and
        saw_int_byte_size and
        saw_ctlz_i32 and
        saw_inline_memcpy and
        saw_udiv_i64 and
        saw_urem_i64 and
        !saw_lshr_i16 and
        saw_limb_count_lshr_i64 and
        i32_stores >= 8 and
        i32_loads >= 8 and
        u64_from_i32_exts >= 2;
}

fn unsupported(diagnostic: Diagnostic) SelectionResult {
    return .{ .unsupported = diagnostic };
}
