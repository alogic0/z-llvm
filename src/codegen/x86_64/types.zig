pub const ArgReg = enum {
    rdi,
    rsi,
    rdx,
    rcx,
    r8,
    r9,

    pub fn name32(reg: ArgReg) []const u8 {
        return switch (reg) {
            .rdi => "%edi",
            .rsi => "%esi",
            .rdx => "%edx",
            .rcx => "%ecx",
            .r8 => "%r8d",
            .r9 => "%r9d",
        };
    }

    pub fn name16(reg: ArgReg) []const u8 {
        return switch (reg) {
            .rdi => "%di",
            .rsi => "%si",
            .rdx => "%dx",
            .rcx => "%cx",
            .r8 => "%r8w",
            .r9 => "%r9w",
        };
    }

    pub fn name64(reg: ArgReg) []const u8 {
        return switch (reg) {
            .rdi => "%rdi",
            .rsi => "%rsi",
            .rdx => "%rdx",
            .rcx => "%rcx",
            .r8 => "%r8",
            .r9 => "%r9",
        };
    }

    pub fn name8(reg: ArgReg) []const u8 {
        return switch (reg) {
            .rdi => "%dil",
            .rsi => "%sil",
            .rdx => "%dl",
            .rcx => "%cl",
            .r8 => "%r8b",
            .r9 => "%r9b",
        };
    }

    pub fn lowCode(reg: ArgReg) u3 {
        return switch (reg) {
            .rdi => 7,
            .rsi => 6,
            .rdx => 2,
            .rcx => 1,
            .r8 => 0,
            .r9 => 1,
        };
    }

    pub fn fromIndex(index: usize) !ArgReg {
        return switch (index) {
            0 => .rdi,
            1 => .rsi,
            2 => .rdx,
            3 => .rcx,
            4 => .r8,
            5 => .r9,
            else => error.UnsupportedCodegenAbi,
        };
    }

    pub fn rexR(reg: ArgReg) bool {
        return reg == .r8 or reg == .r9;
    }

    pub fn rexB(reg: ArgReg) bool {
        return reg == .r8 or reg == .r9;
    }

    pub fn needsRex8(reg: ArgReg) bool {
        return reg == .rdi or reg == .rsi or reg == .r8 or reg == .r9;
    }
};

pub const XmmReg = enum(u3) {
    xmm0,
    xmm1,
    xmm2,
    xmm3,
    xmm4,
    xmm5,
    xmm6,
    xmm7,

    pub fn name(reg: XmmReg) []const u8 {
        return switch (reg) {
            .xmm0 => "%xmm0",
            .xmm1 => "%xmm1",
            .xmm2 => "%xmm2",
            .xmm3 => "%xmm3",
            .xmm4 => "%xmm4",
            .xmm5 => "%xmm5",
            .xmm6 => "%xmm6",
            .xmm7 => "%xmm7",
        };
    }

    pub fn lowCode(reg: XmmReg) u3 {
        return @intFromEnum(reg);
    }

    pub fn fromIndex(index: usize) !XmmReg {
        return switch (index) {
            0 => .xmm0,
            1 => .xmm1,
            2 => .xmm2,
            3 => .xmm3,
            4 => .xmm4,
            5 => .xmm5,
            6 => .xmm6,
            7 => .xmm7,
            else => error.UnsupportedCodegenAbi,
        };
    }
};

pub const MachineBinaryOp = enum {
    add,
    sub,
    @"and",
    @"or",
    xor,

    pub fn mnemonic(op: MachineBinaryOp) []const u8 {
        return switch (op) {
            .add => "addl",
            .sub => "subl",
            .@"and" => "andl",
            .@"or" => "orl",
            .xor => "xorl",
        };
    }

    pub fn mnemonic64(op: MachineBinaryOp) []const u8 {
        return switch (op) {
            .add => "addq",
            .sub => "subq",
            .@"and" => "andq",
            .@"or" => "orq",
            .xor => "xorq",
        };
    }
};

pub const FrameIndex = enum {
    slot0,
    slot1,
    slot2,
    slot3,
    slot4,
    slot5,
    slot6,
    slot7,
    slot8,
    slot9,
    slot10,
    slot11,
    slot12,
};

pub const CodegenPath = enum {
    structural_matcher,
    generic_cfg,
};

pub const CodegenOptions = struct {
    generic_cfg_selector: bool = false,
};
