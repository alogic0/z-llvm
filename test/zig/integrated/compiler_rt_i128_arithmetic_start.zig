extern fn __multi3(i128, i128) callconv(.c) i128;
extern fn __modti3(i128, i128) callconv(.c) i128;
extern fn zllvm_ne_zero_i16(u32) callconv(.c) u32;

var multi_lhs: i128 = 4294967299;
var multi_rhs: i128 = -8589934597;
var mod_lhs: i128 = 123456789;
var mod_rhs: i128 = 4294967299;
var predicate_zero: u32 = 65536;
var predicate_nonzero: u32 = 65537;

const expected_product: i128 = -36893488194663743503;
const expected_remainder: i128 = 123456789;

pub export fn _start() callconv(.c) noreturn {
    @setRuntimeSafety(false);

    const product = __multi3(loadI128(&multi_lhs), loadI128(&multi_rhs));
    const remainder = __modti3(loadI128(&mod_lhs), loadI128(&mod_rhs));

    const product_bad: usize = @intFromBool(product != expected_product);
    const remainder_bad: usize = @intFromBool(remainder != expected_remainder);
    const ne_zero_bad: usize = @intFromBool(zllvm_ne_zero_i16(loadU32(&predicate_zero)) != 0);
    const ne_nonzero_bad: usize = @intFromBool(zllvm_ne_zero_i16(loadU32(&predicate_nonzero)) != 1);
    exit(product_bad * 11 + remainder_bad * 12 + ne_zero_bad * 13 + ne_nonzero_bad * 14);
}

fn loadI128(ptr: *i128) i128 {
    return @as(*volatile i128, @ptrCast(ptr)).*;
}

fn loadU32(ptr: *u32) u32 {
    return @as(*volatile u32, @ptrCast(ptr)).*;
}

fn exit(code: usize) noreturn {
    _ = syscall1(60, code);
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
