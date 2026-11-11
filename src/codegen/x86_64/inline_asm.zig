//! Closed descriptions of supported nonempty assembly. The template, constraints
//! and typed operands must all agree; no general assembly parsing is implied.
const std = @import("std");
const ir = @import("../../ir.zig");
const sysv = @import("sysv_abi.zig");

pub const Operation = union(enum) {
    linux_syscall: u3,
    register_snapshot,
    unsigned_divide,
};

pub fn unsignedDivide(call: ir.CallInst) bool {
    const assembly = call.inline_asm orelse return false;
    if (assembly.sideeffect or !std.mem.eql(u8, assembly.template, "divq ${2}") or
        !std.mem.eql(u8, assembly.constraints, "={rax},={rdx},r,{rax},{rdx},~{dirflag},~{fpsr},~{flags}") or
        call.args.items.len != 3 or call.callee_value != null or call.callee_function_ty != null or call.calling_conv != null or call.raw_args != null or call.operand_bundle != null or call.ret_attrs != null) return false;
    const layout = @import("../../zig_air_type_layout.zig");
    if (!call.ret_ty.eql(.{ .int = 128 }) and !(call.ret_ty == .aggregate and layout.fieldCount(call.ret_ty) == 2 and
        (layout.fieldType(call.ret_ty, 0) orelse return false).eql(.{ .int = 64 }) and (layout.fieldType(call.ret_ty, 1) orelse return false).eql(.{ .int = 64 }))) return false;
    if (call.tail_kind) |tail| if (std.mem.eql(u8, tail, "musttail")) return false;
    for (call.args.items) |arg| if (!arg.ty.eql(.{ .int = 64 }) or arg.attrs != null) return false;
    return true;
}

pub const snapshot_template = " movq %rax, 0x00(%rdi)\\0A movq %rdx, 0x08(%rdi)\\0A movq %rcx, 0x10(%rdi)\\0A movq %rbx, 0x18(%rdi)\\0A movq %rsi, 0x20(%rdi)\\0A movq %rdi, 0x28(%rdi)\\0A movq %rbp, 0x30(%rdi)\\0A movq %rsp, 0x38(%rdi)\\0A movq %r8,  0x40(%rdi)\\0A movq %r9,  0x48(%rdi)\\0A movq %r10, 0x50(%rdi)\\0A movq %r11, 0x58(%rdi)\\0A movq %r12, 0x60(%rdi)\\0A movq %r13, 0x68(%rdi)\\0A movq %r14, 0x70(%rdi)\\0A movq %r15, 0x78(%rdi)\\0A leaq (%rip), %rax\\0A movq %rax, 0x80(%rdi)";
pub const snapshot_constraints = "{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}";
pub const syscall_inputs = [_][]const u8{ "{rax}", "{rdi}", "{rsi}", "{rdx}", "{r10}", "{r8}", "{r9}" };
pub const syscall_clobbers = "~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}";

pub fn classify(call: ir.CallInst) ?Operation {
    if (unsignedDivide(call)) return .unsigned_divide;
    const asm_value = call.inline_asm orelse return null;
    if (!asm_value.sideeffect or call.callee_value != null or call.callee_function_ty != null or
        call.calling_conv != null or
        call.raw_args != null or call.operand_bundle != null) return null;
    if (std.mem.eql(u8, asm_value.template, snapshot_template) and
        std.mem.eql(u8, asm_value.constraints, snapshot_constraints) and
        call.ret_attrs == null and call.tail_kind == null and
        call.ret_ty == .void and call.args.items.len == 1 and call.args.items[0].ty == .ptr and
        call.args.items[0].attrs == null)
        return .register_snapshot;
    if (!std.mem.eql(u8, asm_value.template, "syscall") or !call.ret_ty.eql(.{ .int = 64 }) or
        call.args.items.len == 0 or call.args.items.len > syscall_inputs.len) return null;
    // This exact instruction contract supplies the assembly effects. Reuse the
    // ordinary call validators for typed facts and optional tail hints without
    // changing the source IR or admitting a mandatory tail-call guarantee.
    var envelope = call;
    envelope.inline_asm = null;
    sysv.rejectUnsupportedCallEnvelope(envelope) catch return null;
    var constraints = std.mem.splitScalar(u8, asm_value.constraints, ',');
    if (!std.mem.eql(u8, constraints.next() orelse return null, "={rax}")) return null;
    for (call.args.items, 0..) |arg, index| {
        if (!arg.ty.eql(.{ .int = 64 }) or !std.mem.eql(u8, constraints.next() orelse return null, syscall_inputs[index])) return null;
        sysv.rejectUnsupportedCallArgAttrs(arg) catch return null;
    }
    if (!std.mem.eql(u8, constraints.rest(), syscall_clobbers)) return null;
    return .{ .linux_syscall = @intCast(call.args.items.len - 1) };
}
