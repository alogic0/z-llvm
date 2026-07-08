const std = @import("std");
const ir = @import("../../ir.zig");
const x86_64_machine = @import("machine.zig");
const x86_64_types = @import("types.zig");

pub const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
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
            else => return inspected,
        },
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

const ValueLoc = union(enum) {
    arg32: ArgReg,
    eax,
    scratch32: ArgReg,
};

const ComposedBlockSelector = struct {
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    values: std.StringHashMap(ValueLoc),
    current_eax_name: ?[]const u8 = null,
    current_scratch_name: ?[]const u8 = null,

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
        for (function.params.items, 0..) |param, index| {
            if (!param.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-param-not-i32" };
            const reg = ArgReg.fromIndex(index) catch return .{ .unsupported_value = "composed-block-param-reg" };
            try selector.values.put(param.name, .{ .arg32 = reg });
        }
        return null;
    }

    fn lowerInstruction(selector: *ComposedBlockSelector, instruction: ir.Instruction) !?Diagnostic {
        if (instruction.removed) return null;
        return switch (instruction.kind) {
            .binary => |binary| try selector.lowerBinary(instruction.result, binary),
            .cast => |cast| try selector.lowerCast(instruction.result, cast),
            .call => |call| if (call.isDebugVariableLocation()) null else .{ .no_emitter = "composed-block-call-not-owned" },
            else => .{ .no_emitter = "composed-block-instruction-not-owned" },
        };
    }

    fn lowerBinary(selector: *ComposedBlockSelector, result: ?[]const u8, binary: ir.BinaryInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
        if (bits != 16 and bits != 32) return .{ .no_emitter = "composed-block-binary-width" };

        if (valueIsInt(binary.rhs)) {
            return try selector.lowerBinaryImmediateRhs(result_name, binary);
        }
        if (valueIsInt(binary.lhs)) {
            return try selector.lowerBinaryImmediateLhs(result_name, binary);
        }

        const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-binary-op" };
        const lhs = selector.resolveValue(binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
        const rhs = selector.resolveValue(binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };

        if (locIsEax(rhs) and !locIsEax(lhs) and isCommutative(op)) {
            try selector.emitBinaryLocIntoEax(op, lhs);
        } else {
            try selector.emitValueIntoEax(binary.lhs);
            const rhs_reg = switch (rhs) {
                .arg32, .scratch32 => |reg| reg,
                .eax => return .{ .no_spill_envelope = "composed-block-two-address-rhs-eax" },
            };
            try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{
                .op = op,
                .reg = rhs_reg,
            } });
        }

        try selector.bindEax(result_name);
        return null;
    }

    fn lowerBinaryImmediateRhs(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const rhs = switch (binary.rhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
        };
        switch (binary.op) {
            .lshr => {
                const amount = try shiftAmount5(rhs);
                try selector.emitValueIntoScratch(binary.lhs, .rcx);
                if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_arg_imm5 = .{
                    .reg = .rcx,
                    .amount = amount,
                } });
                try selector.bindScratch(result_name, .rcx);
            },
            .@"and" => {
                try selector.emitValueIntoEax(binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = try i32Value(rhs) });
                try selector.bindEax(result_name);
            },
            .@"or" => {
                try selector.emitValueIntoEax(binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .or_eax_imm32 = try i32Value(rhs) });
                try selector.bindEax(result_name);
            },
            .add => {
                try selector.emitValueIntoEax(binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = try i32Value(rhs) });
                try selector.bindEax(result_name);
            },
            .sub => {
                try selector.emitValueIntoEax(binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = -try i32Value(rhs) });
                try selector.bindEax(result_name);
            },
            else => return .{ .no_emitter = "composed-block-binary-imm-rhs" },
        }
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

        try selector.emitValueIntoScratch(binary.rhs, .rcx);
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
        if (from_bits > 32 or to_bits > 32) return .{ .no_emitter = "composed-block-cast-width" };

        switch (cast.op) {
            .trunc, .bitcast => {
                const loc = selector.resolveValue(cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-cast" };
                try selector.values.put(result_name, loc);
                switch (loc) {
                    .eax => selector.current_eax_name = result_name,
                    .scratch32 => selector.current_scratch_name = result_name,
                    .arg32 => {},
                }
            },
            .zext => {
                try selector.emitValueIntoEax(cast.value);
                if (from_bits < 32) {
                    const shift: u5 = @intCast(from_bits);
                    const mask = (@as(i32, 1) << shift) - 1;
                    try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = mask });
                }
                try selector.bindEax(result_name);
            },
            else => return .{ .no_emitter = "composed-block-cast-op" },
        }
        return null;
    }

    fn lowerReturn(selector: *ComposedBlockSelector, ret: anytype) !?Diagnostic {
        if (!ret.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-ret-not-i32" };
        const value = ret.value orelse return .{ .unsupported_value = "composed-block-missing-ret-value" };
        switch (value) {
            .int => |int| try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) }),
            .named => {
                _ = selector.resolveValue(value) orelse return .{ .unsupported_value = "composed-block-unknown-ret" };
                try selector.emitValueIntoEax(value);
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-ret-value" },
        }
        try selector.machine.instructions.append(selector.allocator, .ret);
        return null;
    }

    fn bindEax(selector: *ComposedBlockSelector, name: []const u8) !void {
        try selector.values.put(name, .eax);
        selector.current_eax_name = name;
    }

    fn bindScratch(selector: *ComposedBlockSelector, name: []const u8, reg: ArgReg) !void {
        try selector.values.put(name, .{ .scratch32 = reg });
        selector.current_scratch_name = name;
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
                    .arg32, .scratch32 => |reg| {
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = reg });
                    },
                    .eax => {},
                }
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }

    fn emitValueIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg) !void {
        selector.current_scratch_name = null;
        switch (value) {
            .int => return error.UnsupportedCodegenValue,
            .named => {
                const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
                switch (loc) {
                    .arg32 => |src| {
                        if (src != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{
                            .dst = reg,
                            .src = src,
                        } });
                    },
                    .scratch32 => |src| {
                        if (src != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{
                            .dst = reg,
                            .src = src,
                        } });
                    },
                    .eax => try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg }),
                }
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }

    fn emitBinaryLocIntoEax(selector: *ComposedBlockSelector, op: MachineBinaryOp, loc: ValueLoc) !void {
        const reg = switch (loc) {
            .arg32, .scratch32 => |reg| reg,
            .eax => return error.UnsupportedCodegenValue,
        };
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{
            .op = op,
            .reg = reg,
        } });
    }

    fn resolveValue(selector: ComposedBlockSelector, value: ir.Value) ?ValueLoc {
        return switch (value) {
            .named => |name| {
                const loc = selector.values.get(name) orelse return null;
                return switch (loc) {
                    .arg32 => loc,
                    .eax => if (selector.current_eax_name) |current| blk: {
                        if (std.mem.eql(u8, current, name)) break :blk loc;
                        return null;
                    } else null,
                    .scratch32 => if (selector.current_scratch_name) |current| blk: {
                        if (std.mem.eql(u8, current, name)) break :blk loc;
                        return null;
                    } else null,
                };
            },
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
        };
    }
};

fn tryLowerComposedBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    if (!function.ret_ty.eql(.{ .int = 32 })) return unsupported(.{ .no_emitter = "composed-block-ret-not-i32" });
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

fn locIsEax(loc: ValueLoc) bool {
    return switch (loc) {
        .eax => true,
        .arg32, .scratch32 => false,
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

fn shiftAmount5(value: i128) !u5 {
    if (value < 0 or value > std.math.maxInt(u5)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn i32Value(value: i128) !i32 {
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
    return @intCast(value);
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
