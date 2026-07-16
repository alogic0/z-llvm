extern fn __multi3(i128, i128) callconv(.c) i128;

const Inputs = struct {
    lhs: i128,
    rhs: i128,
};

const high_a: i128 = @as(i128, 3) << 64;
const high_b: i128 = @as(i128, 5) << 64;
const high_low: i128 = @as(i128, 7) << 64;
const cross_lhs: i128 = 0x0000_0001_ffff_ffff;
const cross_rhs: i128 = 0x0000_0002_0000_0003;

const input_values = [_]Inputs{
    .{ .lhs = 0, .rhs = 0x1234_5678_9abc_def0 },
    .{ .lhs = 1, .rhs = 0x1234_5678_9abc_def0_fedc_ba98_7654_3210 },
    .{ .lhs = high_a, .rhs = high_b },
    .{ .lhs = high_low, .rhs = 9 },
    .{ .lhs = -1, .rhs = -1 },
    .{ .lhs = cross_lhs, .rhs = cross_rhs },
};

var inputs = input_values;

const expected = [_]i128{
    input_values[0].lhs *% input_values[0].rhs,
    input_values[1].lhs *% input_values[1].rhs,
    input_values[2].lhs *% input_values[2].rhs,
    input_values[3].lhs *% input_values[3].rhs,
    input_values[4].lhs *% input_values[4].rhs,
    input_values[5].lhs *% input_values[5].rhs,
};

pub export fn _start() callconv(.c) noreturn {
    @setRuntimeSafety(false);
    var failures: usize = 0;
    inline for (0..inputs.len) |index| {
        const actual = __multi3(loadI128(&inputs[index].lhs), loadI128(&inputs[index].rhs));
        failures += @intFromBool(actual != expected[index]);
    }
    exit(failures);
}

fn loadI128(ptr: *i128) i128 {
    return @as(*volatile i128, @ptrCast(ptr)).*;
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
