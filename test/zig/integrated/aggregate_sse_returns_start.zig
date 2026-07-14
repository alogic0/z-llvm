const DoublePair = extern struct {
    first: f64,
    second: f64,
};

const FloatVectorPair = extern struct {
    value: @Vector(2, f32),
};

extern fn zllvm_return_f64_pair(f64, f64) callconv(.c) DoublePair;
extern fn zllvm_return_f32x2(f32, f32) callconv(.c) FloatVectorPair;

const f64_cases = [_][2]u64{
    .{ 0x0000000000000000, 0x8000000000000000 },
    .{ 0x0000000000000001, 0x8000000000000001 },
    .{ 0x3ff0000000000000, 0xc004000000000000 },
    .{ 0x7ff0000000000000, 0xfff0000000000000 },
    .{ 0x7ff8000000001234, 0xfff8000000005678 },
    .{ 0x7ff0000000001234, 0xfff0000000005678 },
};

const f32_cases = [_][2]u32{
    .{ 0x00000000, 0x80000000 },
    .{ 0x00000001, 0x80000001 },
    .{ 0x3f800000, 0xc0200000 },
    .{ 0x7f800000, 0xff800000 },
    .{ 0x7fc01234, 0xffc05678 },
    .{ 0x7f801234, 0xff805678 },
};

pub export fn _start() callconv(.c) noreturn {
    @setRuntimeSafety(false);
    var bad: usize = 0;
    for (f64_cases) |case| {
        const result = zllvm_return_f64_pair(@bitCast(case[0]), @bitCast(case[1]));
        bad += @intFromBool(@as(u64, @bitCast(result.first)) != case[0]);
        bad += @intFromBool(@as(u64, @bitCast(result.second)) != case[1]);
    }
    for (f32_cases) |case| {
        const result = zllvm_return_f32x2(@bitCast(case[0]), @bitCast(case[1])).value;
        bad += @intFromBool(@as(u32, @bitCast(result[0])) != case[0]);
        bad += @intFromBool(@as(u32, @bitCast(result[1])) != case[1]);
    }
    exit(bad);
}

fn exit(code: usize) noreturn {
    _ = syscall1(60, code);
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
