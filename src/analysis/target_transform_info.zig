const std = @import("std");
const ir = @import("../ir.zig");
const target = @import("../target.zig");

pub const TargetKind = enum {
    generic,
    x86_64,
    aarch64,
};

pub const CostKind = enum {
    throughput,
    code_size,
};

pub const ArithmeticOpcode = enum {
    add,
    sub,
    mul,
    @"and",
    @"or",
    xor,
    fadd,
    fsub,
    fmul,
};

pub const ShuffleKind = enum {
    extract,
    insert,
    permute,
};

pub const Cost = struct {
    value: u32,

    pub fn free() Cost {
        return .{ .value = 0 };
    }

    pub fn of(value: u32) Cost {
        return .{ .value = value };
    }
};

pub const TargetTransformInfo = struct {
    target_kind: TargetKind,
    native_vector_bits: u16,

    pub fn generic() TargetTransformInfo {
        return .{ .target_kind = .generic, .native_vector_bits = 0 };
    }

    pub fn forTriple(triple_text: ?[]const u8) TargetTransformInfo {
        const text = triple_text orelse return generic();
        const parsed = target.Triple.parse(text) catch return generic();
        if (parsed.isX86_64()) return .{ .target_kind = .x86_64, .native_vector_bits = 128 };
        if (parsed.isAArch64()) return .{ .target_kind = .aarch64, .native_vector_bits = 128 };
        return generic();
    }

    pub fn arithmeticInstrCost(tti: TargetTransformInfo, opcode: ArithmeticOpcode, ty: ir.Type, cost_kind: CostKind) Cost {
        _ = opcode;
        _ = cost_kind;
        return tti.typeOperationCost(ty);
    }

    pub fn shuffleCost(tti: TargetTransformInfo, kind: ShuffleKind, ty: ir.Type, cost_kind: CostKind) Cost {
        _ = kind;
        _ = cost_kind;
        return tti.typeOperationCost(ty);
    }

    pub fn scalarizationOverhead(tti: TargetTransformInfo, ty: ir.Type) Cost {
        return switch (ty) {
            .vector => |vector| if (tti.hasNativeVectorSupport(vector))
                .free()
            else
                .of(vector.len),
            .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => .free(),
        };
    }

    fn typeOperationCost(tti: TargetTransformInfo, ty: ir.Type) Cost {
        return switch (ty) {
            .int => |bits| .of(if (bits <= 64) 1 else ceilDiv(bits, 64)),
            .float, .double, .ptr => .of(1),
            .vector => |vector| vectorOperationCost(tti, vector),
            .void, .metadata, .aggregate, .x86_fp80, .fp128 => .of(4),
        };
    }

    fn vectorOperationCost(tti: TargetTransformInfo, vector: ir.VectorType) Cost {
        if (tti.native_vector_bits == 0) return .of(vector.len);
        const total_bits = vectorTotalBits(vector) orelse return .of(vector.len);
        return .of(@max(@as(u32, 1), ceilDiv(total_bits, tti.native_vector_bits)));
    }

    fn hasNativeVectorSupport(tti: TargetTransformInfo, vector: ir.VectorType) bool {
        const total_bits = vectorTotalBits(vector) orelse return false;
        return tti.native_vector_bits != 0 and total_bits <= tti.native_vector_bits;
    }
};

fn vectorTotalBits(vector: ir.VectorType) ?u32 {
    const elem_bits = switch (vector.elem_ty) {
        .int => |bits| bits,
        .float => 32,
        .double, .ptr => 64,
    };
    return @as(u32, vector.len) * @as(u32, elem_bits);
}

fn ceilDiv(value: anytype, divisor: anytype) u32 {
    return @intCast((value + divisor - 1) / divisor);
}
