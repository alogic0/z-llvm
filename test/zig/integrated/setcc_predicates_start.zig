extern fn zllvm_sete_u64(u64, u64) callconv(.c) u32;
extern fn zllvm_setne_u64(u64, u64) callconv(.c) u32;
extern fn zllvm_setb_u64(u64, u64) callconv(.c) u32;
extern fn zllvm_ugt_u64(u64, u64) callconv(.c) u32;
extern fn zllvm_ult_u32(u32, u32) callconv(.c) u32;

var low: u64 = 3;
var high: u64 = 7;
var high_bit: u32 = 0x80000000;

pub export fn _start() callconv(.c) noreturn {
    @setRuntimeSafety(false);

    const lhs = loadU64(&low);
    const rhs = loadU64(&high);
    var bad: usize = 0;
    bad += @intFromBool(zllvm_sete_u64(lhs, lhs) != 1);
    bad += @intFromBool(zllvm_sete_u64(lhs, rhs) != 0);
    bad += @intFromBool(zllvm_setne_u64(lhs, rhs) != 1);
    bad += @intFromBool(zllvm_setne_u64(lhs, lhs) != 0);
    bad += @intFromBool(zllvm_setb_u64(lhs, rhs) != 1);
    bad += @intFromBool(zllvm_setb_u64(rhs, lhs) != 0);
    bad += @intFromBool(zllvm_ugt_u64(rhs, lhs) != 1);
    bad += @intFromBool(zllvm_ugt_u64(lhs, rhs) != 0);
    bad += @intFromBool(zllvm_ult_u32(@intCast(lhs), @intCast(rhs)) != 1);
    bad += @intFromBool(zllvm_ult_u32(@intCast(rhs), @intCast(lhs)) != 0);
    const unsigned_high = loadU32(&high_bit);
    bad += @intFromBool(zllvm_ult_u32(@intCast(rhs), unsigned_high) != 1);
    bad += @intFromBool(zllvm_ult_u32(unsigned_high, @intCast(rhs)) != 0);
    exit(bad);
}

fn loadU64(ptr: *u64) u64 {
    return @as(*volatile u64, @ptrCast(ptr)).*;
}

fn loadU32(ptr: *u32) u32 {
    return @as(*volatile u32, @ptrCast(ptr)).*;
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
