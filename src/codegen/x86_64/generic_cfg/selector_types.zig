const x86_64_types = @import("../types.zig");

pub const ArgReg = x86_64_types.ArgReg;
pub const FrameIndex = x86_64_types.FrameIndex;

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
    stack64: u32,
    stack128: u32,
    stack128_value: u32,
    stack_i32_array: StackArrayLoc,
    stack_i32_ptr: StackPtrLoc,
    spill64: FrameIndex,
    spill128: PairSpillLoc,
};

pub const VirtualRegClass = enum {
    gpr32,
    gpr64,
    gpr128,
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

pub const StackArrayLoc = struct {
    base_disp: u32,
    len: u32,
};

pub const StackPtrLoc = struct {
    disp: u32,
    index: ?StackIndexLoc = null,
};

pub const StackIndexLoc = struct {
    reg: ArgReg,
    name: []const u8,
};

pub const pair_a: RegPair = .{ .lo = .rcx, .hi = .rdx };
pub const pair_b: RegPair = .{ .lo = .r8, .hi = .r9 };
pub const selector_allocatable_regs = [_]ArgReg{ .rdi, .rsi, .rdx, .rcx, .r8, .r9 };
pub const selector_allocatable_pairs = [_]RegPair{ pair_a, pair_b };

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
