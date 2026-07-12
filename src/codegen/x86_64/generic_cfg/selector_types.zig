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
    xmm: FpRegLoc,
    stack_scalar: StackScalarLoc,
    stack128: u32,
    stack128_value: u32,
    stack_i32_array: StackArrayLoc,
    stack_i32_ptr: StackPtrLoc,
    spill64: FrameIndex,
    spill128: PairSpillLoc,
    spill_fp: FpSpillLoc,
};

pub const VirtualRegClass = enum {
    gpr32,
    gpr64,
    gpr128,
    fp16,
    fp32,
    fp64,
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

pub const VirtualRegMetadata = struct {
    class: VirtualRegClass,
    bits: u16,
};

pub const PairSpillLoc = struct {
    lo: FrameIndex,
    hi: FrameIndex,
};

pub const FpRegLoc = struct {
    reg: XmmReg,
    bits: u16,
};

pub const FpSpillLoc = struct {
    frame_index: FrameIndex,
    bits: u16,
};

pub const StackArrayLoc = struct {
    base_disp: u32,
    len: u32,
};

pub const StackScalarLoc = struct {
    base_disp: u32,
    bits: u16,
};

pub const StackPtrLoc = struct {
    disp: u32,
    index: ?StackIndexLoc = null,
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
