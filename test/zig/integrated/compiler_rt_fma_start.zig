extern fn @"compiler_rt.fma.fma"(f64, f64, f64) callconv(.c) f64;
extern fn zllvm_fma_proof_ldexp(f64, i32) callconv(.c) f64;
extern fn zllvm_fma_proof_add_and_denorm(f64, f64, i32) callconv(.c) f64;

const FmaCase = struct {
    x: u64,
    y: u64,
    z: u64,
    expected: u64,
};

// Exact-bit expectations were captured from the frozen compiler_rt.fma.fma
// implementation. Together these rows cover ordinary finite arithmetic,
// fused cancellation and ties, normal/subnormal input populations, both
// product/z scaling branches, normal/subnormal boundaries, over/underflow,
// signed zero, infinities, and quiet/signaling NaN payload and sign behavior.
const fma_cases = [_]FmaCase{
    .{ .x = 0x3ff8000000000000, .y = 0x4000000000000000, .z = 0x3fd0000000000000, .expected = 0x400a000000000000 },
    .{ .x = 0x3ff0000020000000, .y = 0x3feffffffc000000, .z = 0xbff0000000000000, .expected = 0x3e7dfffffc000000 },
    .{ .x = 0x3ff0000000000000, .y = 0x3ff0000000000000, .z = 0x3ca0000000000000, .expected = 0x3ff0000000000000 },
    .{ .x = 0x3ff0000000000001, .y = 0x3ff0000000000000, .z = 0x3ca0000000000000, .expected = 0x3ff0000000000002 },
    .{ .x = 0x3ff0000000000001, .y = 0x3ff0000000000001, .z = 0xbff0000000000002, .expected = 0x3970000000000000 },
    .{ .x = 0x0000000000000001, .y = 0x3ff0000000000000, .z = 0x0010000000000000, .expected = 0x0010000000000001 },
    .{ .x = 0x3ff0000000000000, .y = 0x0000000000000001, .z = 0x0010000000000000, .expected = 0x0010000000000001 },
    .{ .x = 0x3ff0000000000000, .y = 0x3ff0000000000000, .z = 0x0000000000000001, .expected = 0x3ff0000000000000 },
    .{ .x = 0x5f30000000000000, .y = 0x5f30000000000000, .z = 0x3ff0000000000000, .expected = 0x7e70000000000000 },
    .{ .x = 0x7fefffffffffffff, .y = 0x4000000000000000, .z = 0xffefffffffffffff, .expected = 0x7fefffffffffffff },
    .{ .x = 0x7fefffffffffffff, .y = 0x4000000000000000, .z = 0x7fefffffffffffff, .expected = 0x7ff0000000000000 },
    .{ .x = 0x0010000000000000, .y = 0x3ca0000000000000, .z = 0x0000000000000000, .expected = 0x0000000000000000 },
    .{ .x = 0x0010000000000000, .y = 0x3cb0000000000000, .z = 0x0000000000000000, .expected = 0x0000000000000001 },
    .{ .x = 0x0010000000000000, .y = 0x3fe0000000000000, .z = 0x0000000000000001, .expected = 0x0008000000000001 },
    .{ .x = 0x000fffffffffffff, .y = 0x3ff0000000000000, .z = 0x0000000000000001, .expected = 0x0010000000000000 },
    .{ .x = 0x0010000000000000, .y = 0x3ff0000000000000, .z = 0x8000000000000001, .expected = 0x000fffffffffffff },
    .{ .x = 0x0000000000000000, .y = 0xbff0000000000000, .z = 0x8000000000000000, .expected = 0x8000000000000000 },
    .{ .x = 0x0000000000000000, .y = 0x3ff0000000000000, .z = 0x8000000000000000, .expected = 0x0000000000000000 },
    .{ .x = 0x7ff0000000000000, .y = 0x4000000000000000, .z = 0x3ff0000000000000, .expected = 0x7ff0000000000000 },
    .{ .x = 0x7ff0000000000000, .y = 0x0000000000000000, .z = 0x3ff0000000000000, .expected = 0xfff8000000000000 },
    .{ .x = 0x7ff0000000000000, .y = 0x4000000000000000, .z = 0xfff0000000000000, .expected = 0xfff8000000000000 },
    .{ .x = 0x7ff8000000001234, .y = 0x3ff0000000000000, .z = 0x3ff0000000000000, .expected = 0x7ff8000000001234 },
    .{ .x = 0x3ff0000000000000, .y = 0x3ff0000000000000, .z = 0xfff8000000005678, .expected = 0xfff8000000005678 },
    .{ .x = 0x7ff0000000001234, .y = 0x3ff0000000000000, .z = 0x3ff0000000000000, .expected = 0x7ff8000000001234 },
    .{ .x = 0x3ff0000000000000, .y = 0x3ff0000000000000, .z = 0xfff0000000005678, .expected = 0xfff0000000005678 },
};

pub export fn _start() callconv(.c) noreturn {
    @setRuntimeSafety(false);
    var bad: usize = 0;
    for (fma_cases) |case| {
        const actual = @"compiler_rt.fma.fma"(@bitCast(case.x), @bitCast(case.y), @bitCast(case.z));
        bad += @intFromBool(@as(u64, @bitCast(actual)) != case.expected);
    }

    // These calls make the proof execute both frozen internal helper bodies;
    // the fma matrix above also reaches their normal and denormal call sites.
    bad += @intFromBool(@as(u64, @bitCast(zllvm_fma_proof_ldexp(1.5, 4))) != 0x4038000000000000);
    bad += @intFromBool(@as(u64, @bitCast(zllvm_fma_proof_ldexp(@bitCast(@as(u64, 0x0010000000000000)), -1))) != 0x0008000000000000);
    bad += @intFromBool(@as(u64, @bitCast(zllvm_fma_proof_add_and_denorm(0.5, 0x1p-54, -1022))) != 0x0008000000000000);
    bad += @intFromBool(@as(u64, @bitCast(zllvm_fma_proof_add_and_denorm(-0.5, -0x1p-54, -1022))) != 0x8008000000000000);
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
