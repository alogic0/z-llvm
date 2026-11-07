//! Scalar atomics use the existing locked machine operations. Their stronger
//! ordering also covers singlethread scope; no atomic RMW becomes a plain load
//! followed by a store.
const std = @import("std");
const ir = @import("../../../ir.zig");
const core_ir = @import("../../../ir/core.zig");
const machine = @import("../machine.zig");
const types = @import("../types.zig");
const selector_state = @import("composed_selector_state.zig");
const calls = @import("composed_selector_calls.zig");
const forms = @import("scalar_forms.zig");
const ValueUseTransaction = @import("composed_selector_value_use_transaction.zig").ValueUseTransaction;
const Selector = selector_state.ComposedBlockSelector;
const Diagnostic = selector_state.Diagnostic;

pub fn width(ty: ir.Type) ?u16 {
    if (ty == .ptr) return 64;
    if (ty != .int) return null;
    return switch (ty.int) {
        8, 16, 32, 64 => ty.int,
        else => null,
    };
}

pub fn supportedScope(scope: ?[]const u8) bool {
    return if (scope) |text| std.mem.eql(u8, text, "syncscope(\"singlethread\")") else true;
}

fn ordering(text: []const u8) bool {
    for ([_][]const u8{ "monotonic", "acquire", "release", "acq_rel", "seq_cst" }) |accepted|
        if (std.mem.eql(u8, text, accepted)) return true;
    return false;
}

fn aligned(ty: ir.Type, alignment: ?u64) bool {
    const bits = width(ty) orelse return false;
    return if (alignment) |value| std.math.isPowerOfTwo(value) and value >= bits / 8 else true;
}

pub fn inspectRmw(rmw: core_ir.AtomicRmwInst) ?Diagnostic {
    if (!aligned(rmw.ty, rmw.@"align") or !ordering(rmw.ordering) or !supportedScope(rmw.syncscope))
        return .{ .no_emitter = "scalar-atomic-rmw-form" };
    if (rmw.ty == .ptr and !std.mem.eql(u8, rmw.op, "xchg")) return .{ .no_emitter = "scalar-atomic-pointer-operation" };
    for ([_][]const u8{ "xchg", "add", "sub", "and", "or", "xor", "nand", "umin", "umax" }) |op|
        if (std.mem.eql(u8, rmw.op, op)) return null;
    return .{ .no_emitter = "scalar-atomic-rmw-operation" };
}

pub fn inspectCmpxchg(cmp: core_ir.CmpxchgInst) ?Diagnostic {
    if (!aligned(cmp.ty, cmp.@"align") or !ordering(cmp.success_ordering) or !supportedScope(cmp.syncscope))
        return .{ .no_emitter = "scalar-atomic-cmpxchg-form" };
    if (!std.mem.eql(u8, cmp.failure_ordering, "monotonic") and
        !std.mem.eql(u8, cmp.failure_ordering, "acquire") and !std.mem.eql(u8, cmp.failure_ordering, "seq_cst"))
        return .{ .no_emitter = "scalar-atomic-cmpxchg-failure-order" };
    return null;
}

pub fn supportedMemoryAccess(ty: ir.Type, attrs: core_ir.MemoryAttrs) bool {
    if (!attrs.isAtomic()) return !attrs.is_volatile and attrs.syncscope == null;
    return aligned(ty, attrs.@"align") and supportedScope(attrs.syncscope);
}

pub fn lowerSequentialStore(selector: *Selector, store: ir.StoreInst) !?Diagnostic {
    const temporary = try slot(selector);
    return lowerRmw(selector, temporary.name, .{
        .op = "xchg",
        .ty = store.ty,
        .ptr = store.ptr,
        .value = store.value,
        .ordering = "seq_cst",
        .syncscope = store.attrs.syncscope,
        .is_volatile = store.attrs.is_volatile,
        .@"align" = store.attrs.@"align",
    });
}

fn specialOperand(ty: ir.Type, value: ir.Value) bool {
    return (ty == .int and value == .int) or
        (ty == .ptr and (value == .null_value or (value == .named and std.mem.startsWith(u8, value.named, "@"))));
}

fn registerOperand(transaction: *ValueUseTransaction, ty: ir.Type, value: ir.Value, target: types.ArgReg) !void {
    if (specialOperand(ty, value)) return;
    const bits = width(ty) orelse return error.UnsupportedCodegenValue;
    _ = try transaction.register(.{
        .source = value,
        .expected = .{ .ty = ty, .register_class = if (bits <= 32) .gpr32 else .gpr64, .pointer_address_space = if (ty == .ptr) @as(?u32, 0) else null },
        .form = if (ty == .ptr) .pointer else if (bits <= 32) .gpr32 else .gpr64,
        .destination = if (bits <= 32) .{ .gpr32 = target } else .{ .gpr64 = target },
    });
}

fn materializeSpecial(selector: *Selector, ty: ir.Type, value: ir.Value, target: types.ArgReg) !?Diagnostic {
    if (!specialOperand(ty, value)) return null;
    if (ty == .int and value == .int) {
        const bits = width(ty) orelse return error.UnsupportedCodegenValue;
        if (value.int < -(@as(i128, 1) << @as(u7, @intCast(bits - 1))) or
            value.int >= (@as(i128, 1) << @as(u7, @intCast(bits))))
            return .{ .unsupported_value = "scalar-atomic-literal-range" };
        const masked: ir.Value = .{ .int = value.int & ((@as(i128, 1) << @as(u7, @intCast(bits))) - 1) };
        return calls.lowerDirectCallArg(selector, .{ .ty = .{ .int = if (bits <= 32) 32 else 64 }, .value = masked }, target);
    }
    return calls.lowerDirectCallArg(selector, .{ .ty = ty, .value = value }, target);
}

fn rmwInstruction(op: []const u8, bits: u16) machine.Instruction {
    inline for (.{ "add", "sub", "and", "or", "xor", "nand", "umin", "umax" }) |name| {
        if (std.mem.eql(u8, op, name)) return switch (bits) {
            8 => @unionInit(machine.Instruction, "atomic_fetch_" ++ name ++ "_i8_rdi_sil_eax", {}),
            16 => @unionInit(machine.Instruction, "atomic_fetch_" ++ name ++ "_i16_rdi_si_eax", {}),
            32 => @unionInit(machine.Instruction, "atomic_fetch_" ++ name ++ "_i32_rdi_esi_eax", {}),
            64 => @unionInit(machine.Instruction, "atomic_fetch_" ++ name ++ "_i64_rdi_rsi_rax", {}),
            else => unreachable,
        };
    }
    return switch (bits) {
        8 => .xchg_ptr_value_i8_eax,
        16 => .xchg_ptr_value_i16_eax,
        32 => .xchg_ptr_value_i32_eax,
        64 => .xchg_ptr_value_i64_rax,
        else => unreachable,
    };
}

pub fn lowerRmw(selector: *Selector, result: ?[]const u8, rmw: core_ir.AtomicRmwInst) !?Diagnostic {
    if (inspectRmw(rmw)) |diagnostic| return diagnostic;
    const name = result orelse return .{ .unsupported_value = "scalar-atomic-rmw-result" };
    const bits = width(rmw.ty).?;
    // An integer undef operand can take any bit pattern. Choose zero while
    // retaining the atomic operation and its defined old-memory result.
    const value: ir.Value = if (rmw.ty == .int and rmw.value == .undef) .{ .int = 0 } else rmw.value;
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    try registerOperand(&transaction, .ptr, rmw.ptr, .rdi);
    try registerOperand(&transaction, rmw.ty, value, .rsi);
    try transaction.seal();
    const accumulator = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    if (try materializeSpecial(selector, .ptr, rmw.ptr, .rdi)) |diagnostic| return diagnostic;
    if (try materializeSpecial(selector, rmw.ty, value, .rsi)) |diagnostic| return diagnostic;
    try selector_state.clobberArgReg(selector, .rcx);
    if (try transaction.prepareAccumulator(accumulator, .clobber, .spill_live)) |diagnostic| return diagnostic;
    try selector_state.emitEflagsInstruction(selector, rmwInstruction(rmw.op, bits), .clobber);
    try transaction.defineAccumulatorResult(accumulator, name, if (bits == 64) .fullRax() else .zeroExtending(bits));
    try transaction.finalizeAccumulatorResult(accumulator);
    try transaction.commit();
    return null;
}

const Slot = struct { name: []const u8, frame: types.FrameIndex };
fn slot(selector: *Selector) !Slot {
    const function = selector.function orelse return error.UnsupportedCodegenValue;
    var serial: usize = 0;
    while (true) {
        const name = try forms.temporary(selector.allocator, function.*, &serial);
        // temporary excludes every SSA name in the legalized function. Every
        // additional name created here immediately owns a spill slot.
        if (selector.spill_slots.contains(name)) {
            selector.allocator.free(name);
            continue;
        }
        errdefer selector.allocator.free(name);
        const frame = selector_state.allocateSpillSlot(selector, name) orelse return error.UnsupportedCodegenValue;
        try selector.machine.owned_labels.append(selector.allocator, name);
        return .{ .name = name, .frame = frame };
    }
}

pub fn lowerCmpxchg(selector: *Selector, result: ?[]const u8, cmp: core_ir.CmpxchgInst) !?Diagnostic {
    if (inspectCmpxchg(cmp)) |diagnostic| return diagnostic;
    const name = result orelse return .{ .unsupported_value = "scalar-atomic-cmpxchg-result" };
    const bits = width(cmp.ty).?;
    const old = try slot(selector);
    const success = try slot(selector);
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    try registerOperand(&transaction, .ptr, cmp.ptr, .rdi);
    try registerOperand(&transaction, cmp.ty, cmp.expected, .rsi);
    try registerOperand(&transaction, cmp.ty, cmp.replacement, .rdx);
    try transaction.seal();
    const accumulator = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    if (try materializeSpecial(selector, .ptr, cmp.ptr, .rdi)) |diagnostic| return diagnostic;
    if (try materializeSpecial(selector, cmp.ty, cmp.expected, .rsi)) |diagnostic| return diagnostic;
    if (try materializeSpecial(selector, cmp.ty, cmp.replacement, .rdx)) |diagnostic| return diagnostic;
    if (try transaction.prepareAccumulator(accumulator, .clobber, .spill_live)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, if (bits == 64)
        .{ .spill_arg64_rsp = .{ .reg = .rsi, .frame_index = old.frame } }
    else
        .{ .spill_arg_rsp = .{ .reg = .rsi, .frame_index = old.frame } });
    // The existing instruction has a C expected-pointer interface. Keep its
    // expected slot private; after success or failure it contains LLVM's old value.
    try selector_state.clobberArgReg(selector, .rsi);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = .rsi });
    const offset = try old.frame.byteOffset();
    if (offset != 0) try selector_state.emitEflagsInstruction(selector, .{ .add_arg64_imm32 = .{ .reg = .rsi, .imm = @intCast(offset) } }, .write);
    try selector_state.emitEflagsInstruction(selector, switch (bits) {
        8 => .cmpxchg_ptr_expected_desired_i8_eax,
        16 => .cmpxchg_ptr_expected_desired_i16_eax,
        32 => .cmpxchg_ptr_expected_desired_i32_eax,
        64 => .cmpxchg_ptr_expected_desired_i64_eax,
        else => unreachable,
    }, .clobber);
    try transaction.defineAccumulatorResult(accumulator, success.name, .zeroExtending(1));
    try transaction.finalizeAccumulatorResult(accumulator);
    try transaction.commit();
    try selector_state.spillValueOrError(selector, success.name);

    var normalization = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer normalization.deinit();
    if (try normalization.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, switch (bits) {
        8 => .{ .load_stack_disp32_u8_eax = offset },
        16 => .{ .load_stack_disp32_u16_eax = offset },
        32 => .{ .reload_rsp_eax = old.frame },
        64 => .{ .reload_rsp_rax = old.frame },
        else => unreachable,
    });
    try normalization.define(old.name, if (bits == 64) .fullRax() else .zeroExtending(bits));
    try normalization.commit();
    try selector_state.spillValueOrError(selector, old.name);
    try selector.overflow_results.put(name, .{ .value = .{ .spill64 = old.frame }, .overflow = .{ .spill64 = success.frame }, .require_value_first = false });
    return null;
}
