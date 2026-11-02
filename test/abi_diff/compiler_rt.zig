//! INBOX-66 audited compiler-rt ABI cohort.
//!
//! These ten bodies are frozen source-identical extractions from the pinned
//! Zig compiler-rt implementation. Only export linkage is supplied here so a
//! reference object and a z_llvm-hook candidate object can expose the same
//! unchanged real bodies to the differential harness.

const std = @import("std");
const builtin = @import("builtin");
const native_endian = builtin.cpu.arch.endian();

// The pinned x86_64-linux cohort uses the upstream hard-float ABI adapters.
comptime {
    if (builtin.cpu.arch != .x86_64 or builtin.os.tag != .linux) @compileError("ABI cohort target is x86_64 Linux");
    if (std.zig.target.compilerRtFloatAbi(&builtin.target, 16) != .hard or
        std.zig.target.compilerRtFloatAbi(&builtin.target, 64) != .hard)
        @compileError("ABI cohort requires the audited hard-float signatures");
}
const compiler_rt = struct {
    pub const @"f16" = hardFloatAbi(f16);
    pub const @"f64" = hardFloatAbi(f64);
};
fn hardFloatAbi(comptime Float: type) type {
    return struct {
        pub const Abi = Float;
        pub inline fn toAbi(raw: Float) Abi {
            return raw;
        }
        pub inline fn fromAbi(abi: Abi) Float {
            return abi;
        }
    };
}

inline fn exportReal(comptime func: *const anyopaque, comptime name: []const u8) void {
    @export(func, .{ .name = name, .linkage = .weak, .visibility = .hidden });
}

comptime {
    exportReal(&__negsi2, "__negsi2");
    exportReal(&shift.__ashlsi3, "__ashlsi3");
    exportReal(&fabs.__fabsh, "__fabsh");
    exportReal(&__neghf2, "__neghf2");
    exportReal(&mulo.__mulosi4, "__mulosi4");
    exportReal(&mulo.__mulodi4, "__mulodi4");
    exportReal(&__negti2, "__negti2");
    exportReal(&shift.__ashlti3, "__ashlti3");
    exportReal(&fabs.fabs, "fabs");
    exportReal(&fmin.fmin, "fmin");
}

pub fn __negsi2(a: i32) callconv(.c) i32 {
    return negXi2(i32, a);
}

pub fn __negti2(a: i128) callconv(.c) i128 {
    return negXi2(i128, a);
}

inline fn negXi2(comptime T: type, a: T) T {
    return -a;
}

pub inline fn fneg(a: anytype) @TypeOf(a) {
    const F = @TypeOf(a);
    const bits = @typeInfo(F).float.bits;
    const U = @Int(.unsigned, bits);
    const sign_bit_mask = @as(U, 1) << (bits - 1);
    const negated = @as(U, @bitCast(a)) ^ sign_bit_mask;
    return @bitCast(negated);
}

fn __neghf2(a: compiler_rt.f16.Abi) callconv(.c) compiler_rt.f16.Abi {
    return compiler_rt.f16.toAbi(fneg(compiler_rt.f16.fromAbi(a)));
}

/// Allows to access underlying bits as two equally sized lower and higher
/// signed or unsigned integers.
pub fn HalveInt(comptime T: type, comptime signed_half: bool) type {
    return extern union {
        pub const bits = @divExact(@typeInfo(T).int.bits, 2);
        pub const HalfTU = @Int(.unsigned, bits);
        pub const HalfTS = @Int(.signed, bits);
        pub const HalfT = if (signed_half) HalfTS else HalfTU;

        all: T,
        s: if (native_endian == .little)
            extern struct { low: HalfT, high: HalfT }
        else
            extern struct { high: HalfT, low: HalfT },
    };
}

pub const shift = struct {
    // Arithmetic shift left: shift in 0 from right to left
    // Precondition: 0 <= b < bits_in_dword
    inline fn ashlXi3(comptime T: type, a: T, b: i32) T {
        const word_t = HalveInt(T, false);

        const input = word_t{ .all = a };
        var output: word_t = undefined;

        if (b >= word_t.bits) {
            output.s.low = 0;
            output.s.high = input.s.low << @intCast(b - word_t.bits);
        } else if (b == 0) {
            return a;
        } else {
            output.s.low = input.s.low << @intCast(b);
            output.s.high = input.s.high << @intCast(b);
            output.s.high |= input.s.low >> @intCast(word_t.bits - b);
        }

        return output.all;
    }

    pub fn __ashlsi3(a: i32, b: i32) callconv(.c) i32 {
        return ashlXi3(i32, a, b);
    }

    pub fn __ashlti3(a: i128, b: i32) callconv(.c) i128 {
        return ashlXi3(i128, a, b);
    }
};

pub const mulo = struct {
    const math = std.math;

    inline fn muloXi4_genericSmall(comptime ST: type, a: ST, b: ST, overflow: *c_int) ST {
        overflow.* = 0;
        const min = math.minInt(ST);
        const res: ST = a *% b;
        if ((a < 0 and b == min) or (a != 0 and @divTrunc(res, a) != b))
            overflow.* = 1;
        return res;
    }

    inline fn muloXi4_genericFast(comptime ST: type, a: ST, b: ST, overflow: *c_int) ST {
        overflow.* = 0;
        const EST = switch (ST) {
            i32 => i64,
            i64 => i128,
            i128 => i256,
            else => unreachable,
        };
        const min = math.minInt(ST);
        const max = math.maxInt(ST);
        const res: EST = @as(EST, a) * @as(EST, b);
        if (res < min or max < res)
            overflow.* = 1;
        return @as(ST, @truncate(res));
    }

    pub fn __mulosi4(a: i32, b: i32, overflow: *c_int) callconv(.c) i32 {
        if (2 * @bitSizeOf(i32) <= @bitSizeOf(usize)) {
            return muloXi4_genericFast(i32, a, b, overflow);
        } else {
            return muloXi4_genericSmall(i32, a, b, overflow);
        }
    }

    pub fn __mulodi4(a: i64, b: i64, overflow: *c_int) callconv(.c) i64 {
        if (2 * @bitSizeOf(i64) <= @bitSizeOf(usize)) {
            return muloXi4_genericFast(i64, a, b, overflow);
        } else {
            return muloXi4_genericSmall(i64, a, b, overflow);
        }
    }
};

pub const fabs = struct {
    pub fn __fabsh(a: compiler_rt.f16.Abi) callconv(.c) compiler_rt.f16.Abi {
        return compiler_rt.f16.toAbi(fabs_f16(compiler_rt.f16.fromAbi(a)));
    }

    pub fn fabs_f16(a: f16) f16 {
        return generic_fabs(a);
    }

    pub fn fabs(a: compiler_rt.f64.Abi) callconv(.c) compiler_rt.f64.Abi {
        return compiler_rt.f64.toAbi(fabs_f64(compiler_rt.f64.fromAbi(a)));
    }

    pub fn fabs_f64(a: f64) f64 {
        return generic_fabs(a);
    }

    inline fn generic_fabs(x: anytype) @TypeOf(x) {
        const T = @TypeOf(x);
        const TBits = @Int(.unsigned, @typeInfo(T).float.bits);
        const float_bits: TBits = @bitCast(x);
        const remove_sign = ~@as(TBits, 0) >> 1;
        return @bitCast(float_bits & remove_sign);
    }
};

pub const fmin = struct {
    const math = std.math;

    pub fn fmin(x: compiler_rt.f64.Abi, y: compiler_rt.f64.Abi) callconv(.c) compiler_rt.f64.Abi {
        return compiler_rt.f64.toAbi(fmin_f64(compiler_rt.f64.fromAbi(x), compiler_rt.f64.fromAbi(y)));
    }

    pub fn fmin_f64(x: f64, y: f64) f64 {
        return generic_fmin(f64, x, y);
    }

    inline fn generic_fmin(comptime T: type, x: T, y: T) T {
        if (math.isNan(x))
            return y;
        if (math.isNan(y))
            return x;
        if (math.signbit(x) != math.signbit(y))
            return if (math.signbit(x)) x else y;
        return if (x < y) x else y;
    }
};
