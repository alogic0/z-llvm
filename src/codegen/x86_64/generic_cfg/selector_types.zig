const std = @import("std");
const constant_table = @import("../constant_table.zig");
const x86_64_types = @import("../types.zig");

pub const ArgReg = x86_64_types.ArgReg;
pub const FrameIndex = x86_64_types.FrameIndex;
pub const XmmReg = x86_64_types.XmmReg;

pub const RegPair = struct {
    lo: ArgReg,
    hi: ArgReg,

    pub fn eql(pair: RegPair, other: RegPair) bool {
        return pair.lo == other.lo and pair.hi == other.hi;
    }

    pub fn contains(pair: RegPair, reg: ArgReg) bool {
        return pair.lo == reg or pair.hi == reg;
    }
};

pub const ValueLoc = union(enum) {
    arg32: ArgReg,
    arg64: ArgReg,
    arg128: RegPair,
    eax,
    rax,
    scratch32: ArgReg,
    scratch64: ArgReg,
    scratch128: RegPair,
    xmm: XmmValueLoc,
    stack_scalar: StackScalarLoc,
    stack128: u32,
    stack128_value: u32,
    stack_i32_array: StackArrayLoc,
    stack_i32_ptr: StackPtrLoc,
    stack_f32_pair_ptr: StackF32PairPtrLoc,
    readonly_table_ptr: ReadOnlyTablePtrLoc,
    spill64: FrameIndex,
    spill128: PairSpillLoc,
    spill_fp: FpSpillLoc,
    spill_vector: VectorSpillLoc,
    aggregate_sse: SseAggregateLoc,
};

pub const SseAggregateLoc = union(enum) {
    packed_f32x2: ?SseAggregateLeaf,
    split_f64x2: [2]?SseAggregateLeaf,
};

pub const SseAggregateLeaf = struct {
    name: []const u8,
    kind: Kind,

    pub const Kind = enum {
        f32x2,
        f64,
    };
};

pub const ReadOnlyTablePtrLoc = struct {
    storage: Storage,
    symbol: []const u8,
    shape: constant_table.Shape,
    offset: u8 = 0,

    pub const Storage = union(enum) {
        reg: ArgReg,
        spill: FrameIndex,
    };
};

pub const VirtualRegClass = enum {
    gpr32,
    gpr64,
    gpr128,
    fp16,
    fp32,
    fp64,
    vector_xmm,
    aggregate_sse,
    stack_object,
    stack_pointer,
};

pub const VirtualReg = struct {
    index: usize,
    class: VirtualRegClass,
    bits: u16,
};

pub const ValueBinding = struct {
    vreg: VirtualReg,
    loc: ValueLoc,
};

/// EAX and RAX are one physical accumulator alias.  This domain is the single
/// selector-state representation of the value occupying that alias and of the
/// bits defined by its most recent committed definition.
pub const AccumulatorDomain = struct {
    occupant: ?Occupant = null,
    defined_bits: u16 = 0,

    pub const Alias = enum {
        eax,
        rax,
    };

    pub const Occupant = struct {
        binding: ValueBinding,
        logical_bits: u16,
    };

    pub fn occupantFor(domain: AccumulatorDomain, alias: Alias) ?Occupant {
        _ = alias;
        return domain.occupant;
    }

    pub fn invalidate(domain: *AccumulatorDomain) void {
        domain.* = .{};
    }
};

pub const VirtualRegMetadata = struct {
    class: VirtualRegClass,
    bits: u16,
};

pub const PairSpillLoc = struct {
    lo: FrameIndex,
    hi: FrameIndex,
};

pub const XmmValueLoc = struct {
    reg: XmmReg,
    bits: u16,
    shape: XmmValueShape = .scalar,

    pub fn vectorShape(loc: XmmValueLoc) ?VectorShape {
        return switch (loc.shape) {
            .scalar => null,
            .vector => |shape| shape,
        };
    }

    pub fn shapeEql(loc: XmmValueLoc, other: XmmValueLoc) bool {
        if (loc.bits != other.bits or std.meta.activeTag(loc.shape) != std.meta.activeTag(other.shape)) return false;
        return switch (loc.shape) {
            .scalar => true,
            .vector => |shape| shape.eql(other.shape.vector),
        };
    }
};

pub const XmmValueShape = union(enum) {
    scalar,
    vector: VectorShape,
};

pub const VectorShape = struct {
    kind: Kind = .data,
    lane_type: LaneType,
    lane_count: u8,
    lane_bits: u16,
    defined_lanes: u4,

    pub const LaneType = enum {
        float,
        double,
        integer,
    };

    pub const Kind = enum {
        data,
        canonical_mask,
    };

    pub fn f32x2(defined_lanes: u4) VectorShape {
        return .{
            .lane_type = .float,
            .lane_count = 2,
            .lane_bits = 32,
            .defined_lanes = defined_lanes,
        };
    }

    pub fn f64x2(defined_lanes: u4) VectorShape {
        return .{
            .lane_type = .double,
            .lane_count = 2,
            .lane_bits = 64,
            .defined_lanes = defined_lanes,
        };
    }

    pub fn i32x2(defined_lanes: u4) VectorShape {
        return .{
            .lane_type = .integer,
            .lane_count = 2,
            .lane_bits = 32,
            .defined_lanes = defined_lanes,
        };
    }

    pub fn i64x2(defined_lanes: u4) VectorShape {
        return .{
            .lane_type = .integer,
            .lane_count = 2,
            .lane_bits = 64,
            .defined_lanes = defined_lanes,
        };
    }

    pub fn mask32x2(defined_lanes: u4) VectorShape {
        var shape = i32x2(defined_lanes);
        shape.kind = .canonical_mask;
        return shape;
    }

    pub fn mask64x2(defined_lanes: u4) VectorShape {
        var shape = i64x2(defined_lanes);
        shape.kind = .canonical_mask;
        return shape;
    }

    pub fn f32x4(defined_lanes: u4) VectorShape {
        return .{
            .lane_type = .float,
            .lane_count = 4,
            .lane_bits = 32,
            .defined_lanes = defined_lanes,
        };
    }

    pub fn i32x4(defined_lanes: u4) VectorShape {
        return .{
            .lane_type = .integer,
            .lane_count = 4,
            .lane_bits = 32,
            .defined_lanes = defined_lanes,
        };
    }

    pub fn mask32x4(defined_lanes: u4) VectorShape {
        var shape = i32x4(defined_lanes);
        shape.kind = .canonical_mask;
        return shape;
    }

    pub fn eql(shape: VectorShape, other: VectorShape) bool {
        return shape.kind == other.kind and
            shape.lane_type == other.lane_type and
            shape.lane_count == other.lane_count and
            shape.lane_bits == other.lane_bits and
            shape.defined_lanes == other.defined_lanes;
    }
};

pub const FpSpillLoc = struct {
    frame_index: FrameIndex,
    bits: u16,
};

pub const VectorSpillLoc = struct {
    frames: PairSpillLoc,
    shape: VectorShape,
};

pub const StackArrayLoc = struct {
    base_disp: u32,
    len: u32,
};

pub const StackScalarLoc = struct {
    base_disp: u32,
    bits: u16,
    kind: Kind = .integer,

    pub const Kind = enum {
        integer,
        fp,
    };
};

pub const StackPtrLoc = struct {
    disp: u32,
    index: ?StackIndexLoc = null,
};

pub const StackF32PairPtrLoc = struct {
    object_base_disp: u32,
    disp: u32,
};

pub const StackIndexLoc = struct {
    reg: ArgReg,
    name: []const u8,
    addend_name: ?[]const u8 = null,
};

pub const pair_a: RegPair = .{ .lo = .rcx, .hi = .rdx };
pub const pair_b: RegPair = .{ .lo = .r8, .hi = .r9 };
pub const selector_allocatable_regs = [_]ArgReg{ .rdi, .rsi, .rdx, .rcx, .r8, .r9 };
pub const selector_allocatable_pairs = [_]RegPair{ pair_a, pair_b };
pub const selector_allocatable_xmm_regs = [_]XmmReg{ .xmm0, .xmm1, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 };

pub fn argRegIndex(reg: ArgReg) usize {
    return switch (reg) {
        .rdi => 0,
        .rsi => 1,
        .rdx => 2,
        .rcx => 3,
        .r8 => 4,
        .r9 => 5,
    };
}

pub fn xmmRegIndex(reg: XmmReg) usize {
    return @intFromEnum(reg);
}
