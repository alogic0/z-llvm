//! Naked Linux ABI assembly must run at the original stack pointer.
const std = @import("std");
const ir = @import("../../ir.zig");
const machine = @import("machine.zig");
const Context = @import("constant_table.zig").ReadOnlyModuleContext;
const attributes = @import("../../ir/function_attributes.zig");

const clobbers = "~{dirflag},~{fpsr},~{flags}";
pub const tls_read = " movq %fs:0, ${0}";
pub const munmap_exit = " movl $$11, %eax # SYS_munmap\\0A syscall\\0A movl $$60, %eax # SYS_exit\\0A xor %rdi, %rdi\\0A syscall";
const restorer = " movl ${0}, %eax\\0A syscall";
const clone_start = " movl $$56,%eax // SYS_clone\\0A movq %rdi,%r11\\0A movq %rdx,%rdi\\0A movq %r8,%rdx\\0A movq %r9,%r8\\0A movq 8(%rsp),%r10\\0A movq %r11,%r9\\0A andq $$-16,%rsi\\0A subq $$8,%rsi\\0A movq %rcx,(%rsi)\\0A syscall\\0A testq %rax,%rax\\0A jz 1f\\0A retq\\0A\\0A1:";
const clone_child = " xorl %ebp,%ebp\\0A\\0A popq %rdi\\0A callq *%r9\\0A movl %eax,%edi\\0A movl $$60,%eax // SYS_exit\\0A syscall";

pub const clone_bytes = [_]u8{
    0xb8, 56, 0, 0, 0,                   // movl $56, %eax
    0x49, 0x89, 0xfb,                    // movq %rdi, %r11
    0x48, 0x89, 0xd7,                    // movq %rdx, %rdi
    0x4c, 0x89, 0xc2,                    // movq %r8, %rdx
    0x4d, 0x89, 0xc8,                    // movq %r9, %r8
    0x4c, 0x8b, 0x54, 0x24, 0x08,        // movq 8(%rsp), %r10
    0x4d, 0x89, 0xd9,                    // movq %r11, %r9
    0x48, 0x83, 0xe6, 0xf0,              // andq $-16, %rsi
    0x48, 0x83, 0xee, 0x08,              // subq $8, %rsi
    0x48, 0x89, 0x0e,                    // movq %rcx, (%rsi)
    0x0f, 0x05, 0x48, 0x85, 0xc0,        // syscall; testq %rax, %rax
    0x74, 0x01, 0xc3,                    // jz 1f; retq
    0x31, 0xed, 0x5f, 0x41, 0xff, 0xd1,  // 1: xorl %ebp, %ebp; popq %rdi; callq *%r9
    0x89, 0xc7, 0xb8, 60, 0, 0, 0,      // movl %eax, %edi; movl $60, %eax
    0x0f, 0x05,                          // syscall
};
pub const clone_text =
    \\  .cfi_startproc
    \\  movl $56,%eax
    \\  movq %rdi,%r11
    \\  movq %rdx,%rdi
    \\  movq %r8,%rdx
    \\  movq %r9,%r8
    \\  movq 8(%rsp),%r10
    \\  movq %r11,%r9
    \\  andq $-16,%rsi
    \\  subq $8,%rsi
    \\  movq %rcx,(%rsi)
    \\  syscall
    \\  testq %rax,%rax
    \\  jz 1f
    \\  retq
    \\1:
    \\  .cfi_undefined %rip
    \\  xorl %ebp,%ebp
    \\  popq %rdi
    \\  callq *%r9
    \\  movl %eax,%edi
    \\  movl $60,%eax
    \\  syscall
    \\  .cfi_endproc
    \\
;

pub fn plain(call: ir.CallInst) bool {
    return call.callee.len == 0 and call.callee_value == null and call.callee_function_ty == null and
        call.calling_conv == null and call.ret_attrs == null and call.tail_kind == null and
        call.attrs == null and call.raw_args == null and call.operand_bundle == null and
        call.native_query == null and !call.va_arg;
}

fn match(call: ir.CallInst, template: []const u8, constraints: []const u8, args: usize) bool {
    const assembly = call.inline_asm.?;
    return std.mem.eql(u8, assembly.template, template) and std.mem.eql(u8, assembly.constraints, constraints) and call.args.items.len == args;
}

pub fn lowerNaked(a: std.mem.Allocator, out: *machine.MachineFunction, f: ir.Function, ctx: ?*const Context) !bool {
    if (f.params.items.len != 0 or f.is_varargs or f.calling_conv != null or f.blocks.items.len != 1) return false;
    const block = f.blocks.items[0];
    if (block.terminator == null or block.terminator.? != .@"unreachable") return false;
    var calls: [3]ir.CallInst = undefined;
    var count: usize = 0;
    for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        if (inst.kind != .call) return false;
        const call = inst.kind.call;
        if (call.isDebugVariableLocation()) continue;
        if (count == calls.len or inst.result != null or call.ret_ty != .void or !plain(call) or
            call.inline_asm == null or !call.inline_asm.?.sideeffect) return false;
        calls[count] = call;
        count += 1;
    }
    if (!attributes.contains(f.attrs orelse return false, if (ctx) |c| c.attribute_groups else &.{}, "naked")) return false;
    if (count == 1 and f.ret_ty == .void and match(calls[0], restorer, "i," ++ clobbers, 1)) {
        const nr = calls[0].args.items[0];
        if (nr.attrs != null or !nr.ty.eql(.{ .int = 64 }) or nr.value != .int or nr.value.int != 15) return false;
        try out.instructions.appendSlice(a, &.{ .{ .mov_imm_eax = 15 }, .syscall, .ud2 });
    } else if (count == 3 and f.ret_ty.eql(.{ .int = 64 }) and match(calls[0], clone_start, clobbers, 0) and
        match(calls[1], " .cfi_undefined %rip", clobbers, 0) and match(calls[2], clone_child, clobbers, 0))
    {
        try out.instructions.appendSlice(a, &.{ .linux_clone_trampoline, .ud2 });
    } else return false;
    return true;
}
