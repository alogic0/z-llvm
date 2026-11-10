const std = @import("std");
const constant_table = @import("../constant_table.zig");
const x86_64_types = @import("../types.zig");

pub const ArgReg = x86_64_types.ArgReg;
pub const FrameIndex = x86_64_types.FrameIndex;
pub const XmmReg = x86_64_types.XmmReg;
/// Maximum byte-addressed stack object admitted by the storage view/authority.
pub const max_stack_object_bytes: u32 = 64 * 1024;
/// Total private frame capacity, including spills, objects and call storage.
pub const max_stack_frame_bytes: u32 = 8 * 1024 * 1024;

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

pub const ValueSnapshotEntry = struct { name: []const u8, binding: ValueBinding };

/// Reuse storage only. Every capture overwrites its entire borrowed slice, and
/// simultaneous snapshots always hold distinct buffers. Inactive contents are
/// never read; names remain borrowed exactly as in ordinary snapshot arrays.
pub const ValueSnapshotBuffers = struct {
    buffers: std.ArrayList(Buffer) = .empty,
    const Buffer = struct { entries: []ValueSnapshotEntry, in_use: bool };

    pub fn acquire(pool: *ValueSnapshotBuffers, allocator: std.mem.Allocator, count: usize) ![]ValueSnapshotEntry {
        if (count == 0) return &.{};
        var reusable: ?usize = null;
        for (pool.buffers.items, 0..) |*buffer, i| {
            if (buffer.in_use) continue;
            if (buffer.entries.len >= count) {
                buffer.in_use = true;
                return buffer.entries[0..count];
            }
            if (reusable == null) reusable = i;
        }
        if (reusable) |i| {
            const capacity = @max(count, std.math.mul(usize, pool.buffers.items[i].entries.len, 2) catch count);
            const entries = try allocator.alloc(ValueSnapshotEntry, capacity);
            allocator.free(pool.buffers.items[i].entries);
            pool.buffers.items[i] = .{ .entries = entries, .in_use = true };
            return entries[0..count];
        }
        try pool.buffers.ensureUnusedCapacity(allocator, 1);
        const entries = try allocator.alloc(ValueSnapshotEntry, count);
        pool.buffers.appendAssumeCapacity(.{ .entries = entries, .in_use = true });
        return entries;
    }
    pub fn release(pool: *ValueSnapshotBuffers, entries: []ValueSnapshotEntry) void {
        if (entries.len == 0) return;
        for (pool.buffers.items) |*buffer| {
            if (buffer.entries.ptr != entries.ptr) continue;
            std.debug.assert(buffer.in_use and entries.len <= buffer.entries.len);
            buffer.in_use = false;
            return;
        }
        unreachable;
    }
    pub fn deinit(pool: *ValueSnapshotBuffers, allocator: std.mem.Allocator) void {
        for (pool.buffers.items) |buffer| {
            std.debug.assert(!buffer.in_use);
            allocator.free(buffer.entries);
        }
        pool.buffers.deinit(allocator);
    }
};

/// Counts mirror canonical binding writes; they never choose a binding or home.
/// Only production selectors enable tracking, before their first binding.
/// Manually assembled selector states retain ordinary complete scans.
pub const PhysicalBindingFacts = struct {
    active: bool = false,
    accumulator: usize = 0,
    scalar: [6]usize = @splat(0),
    pair: [6]usize = @splat(0),
    xmm: [8]usize = @splat(0),

    pub fn accumulatorEmpty(facts: PhysicalBindingFacts) bool {
        return facts.active and facts.accumulator == 0;
    }
    pub fn scalarEmpty(facts: PhysicalBindingFacts, reg: ArgReg) bool {
        return facts.active and facts.scalar[@backingInt(reg)] == 0;
    }
    pub fn pairEmpty(facts: PhysicalBindingFacts, reg: ArgReg) bool {
        return facts.active and facts.pair[@backingInt(reg)] == 0;
    }
    pub fn xmmEmpty(facts: PhysicalBindingFacts, reg: XmmReg) bool {
        return facts.active and facts.xmm[@backingInt(reg)] == 0;
    }
    pub fn change(facts: *PhysicalBindingFacts, before: ?ValueLoc, after: ?ValueLoc) void {
        if (!facts.active) return;
        if (before) |loc| facts.account(loc, false);
        if (after) |loc| facts.account(loc, true);
    }
    fn adjust(count: *usize, add: bool) void {
        if (add) count.* += 1 else {
            std.debug.assert(count.* != 0);
            count.* -= 1;
        }
    }
    fn account(facts: *PhysicalBindingFacts, loc: ValueLoc, add: bool) void {
        switch (loc) {
            .eax, .rax => adjust(&facts.accumulator, add),
            .arg32, .arg64, .scratch32, .scratch64 => |reg| adjust(&facts.scalar[@backingInt(reg)], add),
            .arg128, .scratch128 => |pair| {
                adjust(&facts.pair[@backingInt(pair.lo)], add);
                adjust(&facts.pair[@backingInt(pair.hi)], add);
            },
            .xmm => |fp| adjust(&facts.xmm[@backingInt(fp.reg)], add),
            .readonly_table_ptr => |ptr| switch (ptr.storage) {
                .reg => |reg| adjust(&facts.scalar[@backingInt(reg)], add),
                .spill => {},
            },
            .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
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
    defined_lanes: u16,

    pub const LaneType = enum {
        float,
        double,
        integer,
    };

    pub const Kind = enum {
        data,
        canonical_mask,
    };

    pub fn f32x2(defined_lanes: u16) VectorShape {
        return .{
            .lane_type = .float,
            .lane_count = 2,
            .lane_bits = 32,
            .defined_lanes = defined_lanes,
        };
    }

    pub fn f64x2(defined_lanes: u16) VectorShape {
        return .{
            .lane_type = .double,
            .lane_count = 2,
            .lane_bits = 64,
            .defined_lanes = defined_lanes,
        };
    }

    pub fn i32x2(defined_lanes: u16) VectorShape {
        return .{
            .lane_type = .integer,
            .lane_count = 2,
            .lane_bits = 32,
            .defined_lanes = defined_lanes,
        };
    }

    pub fn i64x2(defined_lanes: u16) VectorShape {
        return .{
            .lane_type = .integer,
            .lane_count = 2,
            .lane_bits = 64,
            .defined_lanes = defined_lanes,
        };
    }

    pub fn mask32x2(defined_lanes: u16) VectorShape {
        var shape = i32x2(defined_lanes);
        shape.kind = .canonical_mask;
        return shape;
    }

    pub fn mask64x2(defined_lanes: u16) VectorShape {
        var shape = i64x2(defined_lanes);
        shape.kind = .canonical_mask;
        return shape;
    }

    pub fn f32x4(defined_lanes: u16) VectorShape {
        return .{
            .lane_type = .float,
            .lane_count = 4,
            .lane_bits = 32,
            .defined_lanes = defined_lanes,
        };
    }

    pub fn i32x4(defined_lanes: u16) VectorShape {
        return .{
            .lane_type = .integer,
            .lane_count = 4,
            .lane_bits = 32,
            .defined_lanes = defined_lanes,
        };
    }

    pub fn mask32x4(defined_lanes: u16) VectorShape {
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
    return @backingInt(reg);
}
