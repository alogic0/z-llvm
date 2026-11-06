const std = @import("std");
const constant_table = @import("constant_table.zig");

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

pub const FrameIndex = struct {
    slot: u32,

    pub fn fromSlot(slot: usize) !FrameIndex {
        const narrowed = std.math.cast(u32, slot) orelse return error.UnsupportedCodegenAbi;
        return .{ .slot = narrowed };
    }

    pub fn byteOffset(index: FrameIndex) !u32 {
        return std.math.mul(u32, index.slot, 4) catch error.UnsupportedCodegenAbi;
    }

    pub fn eql(index: FrameIndex, other: FrameIndex) bool {
        return index.slot == other.slot;
    }

    pub const slot0: FrameIndex = .{ .slot = 0 };
    pub const slot1: FrameIndex = .{ .slot = 1 };
    pub const slot2: FrameIndex = .{ .slot = 2 };
    pub const slot3: FrameIndex = .{ .slot = 3 };
    pub const slot4: FrameIndex = .{ .slot = 4 };
    pub const slot5: FrameIndex = .{ .slot = 5 };
    pub const slot6: FrameIndex = .{ .slot = 6 };
    pub const slot7: FrameIndex = .{ .slot = 7 };
    pub const slot8: FrameIndex = .{ .slot = 8 };
    pub const slot9: FrameIndex = .{ .slot = 9 };
    pub const slot10: FrameIndex = .{ .slot = 10 };
    pub const slot11: FrameIndex = .{ .slot = 11 };
    pub const slot12: FrameIndex = .{ .slot = 12 };
    pub const slot13: FrameIndex = .{ .slot = 13 };
    pub const slot14: FrameIndex = .{ .slot = 14 };
    pub const slot15: FrameIndex = .{ .slot = 15 };
    pub const slot16: FrameIndex = .{ .slot = 16 };
    pub const slot17: FrameIndex = .{ .slot = 17 };
    pub const slot18: FrameIndex = .{ .slot = 18 };
    pub const slot19: FrameIndex = .{ .slot = 19 };
    pub const slot20: FrameIndex = .{ .slot = 20 };
    pub const slot21: FrameIndex = .{ .slot = 21 };
    pub const slot22: FrameIndex = .{ .slot = 22 };
    pub const slot23: FrameIndex = .{ .slot = 23 };
    pub const slot24: FrameIndex = .{ .slot = 24 };
    pub const slot25: FrameIndex = .{ .slot = 25 };
    pub const slot26: FrameIndex = .{ .slot = 26 };
    pub const slot27: FrameIndex = .{ .slot = 27 };
    pub const slot28: FrameIndex = .{ .slot = 28 };
    pub const slot29: FrameIndex = .{ .slot = 29 };
    pub const slot30: FrameIndex = .{ .slot = 30 };
    pub const slot31: FrameIndex = .{ .slot = 31 };
    pub const slot32: FrameIndex = .{ .slot = 32 };
    pub const slot33: FrameIndex = .{ .slot = 33 };
    pub const slot34: FrameIndex = .{ .slot = 34 };
    pub const slot35: FrameIndex = .{ .slot = 35 };
    pub const slot36: FrameIndex = .{ .slot = 36 };
    pub const slot37: FrameIndex = .{ .slot = 37 };
    pub const slot38: FrameIndex = .{ .slot = 38 };
    pub const slot39: FrameIndex = .{ .slot = 39 };
    pub const slot40: FrameIndex = .{ .slot = 40 };
    pub const slot41: FrameIndex = .{ .slot = 41 };
    pub const slot42: FrameIndex = .{ .slot = 42 };
    pub const slot43: FrameIndex = .{ .slot = 43 };
    pub const slot44: FrameIndex = .{ .slot = 44 };
    pub const slot45: FrameIndex = .{ .slot = 45 };
    pub const slot46: FrameIndex = .{ .slot = 46 };
    pub const slot47: FrameIndex = .{ .slot = 47 };
    pub const slot48: FrameIndex = .{ .slot = 48 };
    pub const slot49: FrameIndex = .{ .slot = 49 };
    pub const slot50: FrameIndex = .{ .slot = 50 };
    pub const slot51: FrameIndex = .{ .slot = 51 };
    pub const slot52: FrameIndex = .{ .slot = 52 };
    pub const slot53: FrameIndex = .{ .slot = 53 };
    pub const slot54: FrameIndex = .{ .slot = 54 };
    pub const slot55: FrameIndex = .{ .slot = 55 };
    pub const slot56: FrameIndex = .{ .slot = 56 };
    pub const slot57: FrameIndex = .{ .slot = 57 };
    pub const slot58: FrameIndex = .{ .slot = 58 };
    pub const slot59: FrameIndex = .{ .slot = 59 };
    pub const slot60: FrameIndex = .{ .slot = 60 };
    pub const slot61: FrameIndex = .{ .slot = 61 };
    pub const slot62: FrameIndex = .{ .slot = 62 };
};

pub const CodegenPath = enum {
    structural_matcher,
    generic_cfg,
};

pub const SelectionOwner = enum {
    unassigned,
    composed_block,
    composed_cfg,
    legacy_envelope,
    structural_fallback,
};

pub const CodegenOptions = struct {
    profile: ?*@import("../../compilation_profile.zig").Profile = null,
    generic_cfg_selector: bool = false,
    generic_cfg_selector_diagnostic_tag: ?*?[]const u8 = null,
    generic_cfg_selector_diagnostic_detail: ?*?[]const u8 = null,
    module_context: ?*const constant_table.ReadOnlyModuleContext = null,
};

pub const ReadOnlyModuleContext = constant_table.ReadOnlyModuleContext;
