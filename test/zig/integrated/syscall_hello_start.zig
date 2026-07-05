const message = "hello\n";

pub export fn _start() callconv(.c) noreturn {
    _ = syscall3(1, 1, @intFromPtr(message.ptr), message.len);
    _ = syscall1(60, 0);
    @setRuntimeSafety(false);
    unreachable;
}

fn syscall1(number: usize, arg1: usize) usize {
    return asm volatile (
        \\syscall
        : [ret] "={rax}" (-> usize),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
        : .{ .rcx = true, .r11 = true, .memory = true });
}

fn syscall3(number: usize, arg1: usize, arg2: usize, arg3: usize) usize {
    return asm volatile (
        \\syscall
        : [ret] "={rax}" (-> usize),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
          [arg3] "{rdx}" (arg3),
        : .{ .rcx = true, .r11 = true, .memory = true });
}
