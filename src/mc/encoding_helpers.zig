const std = @import("std");
const x86_64 = @import("../codegen/x86_64.zig");

pub fn binaryOpcode(op: x86_64.MachineBinaryOp) u8 {
    return switch (op) {
        .add => 0x01,
        .sub => 0x29,
        .@"and" => 0x21,
        .@"or" => 0x09,
        .xor => 0x31,
    };
}

pub fn base64Decode4FromTableRaxBytes() []const u8 {
    return &.{
        0x48, 0x83, 0xfe, 0x04, 0x0f, 0x85, 0xf7, 0x00,
        0x00, 0x00, 0x44, 0x0f, 0xb6, 0x07, 0x46, 0x0f,
        0xb6, 0x04, 0x00, 0x41, 0x80, 0xf8, 0xff, 0x0f,
        0x84, 0xe4, 0x00, 0x00, 0x00, 0x44, 0x0f, 0xb6,
        0x4f, 0x01, 0x46, 0x0f, 0xb6, 0x0c, 0x08, 0x41,
        0x80, 0xf9, 0xff, 0x0f, 0x84, 0xd0, 0x00, 0x00,
        0x00, 0x44, 0x0f, 0xb6, 0x57, 0x02, 0x41, 0x80,
        0xfa, 0x3d, 0x0f, 0x84, 0x9a, 0x00, 0x00, 0x00,
        0x46, 0x0f, 0xb6, 0x14, 0x10, 0x41, 0x80, 0xfa,
        0xff, 0x0f, 0x84, 0xb2, 0x00, 0x00, 0x00, 0x44,
        0x0f, 0xb6, 0x5f, 0x03, 0x41, 0x80, 0xfb, 0x3d,
        0x74, 0x4d, 0x46, 0x0f, 0xb6, 0x1c, 0x18, 0x41,
        0x80, 0xfb, 0xff, 0x0f, 0x84, 0x98, 0x00, 0x00,
        0x00, 0x48, 0x83, 0xf9, 0x03, 0x0f, 0x82, 0x8e,
        0x00, 0x00, 0x00, 0x41, 0xc1, 0xe0, 0x12, 0x41,
        0xc1, 0xe1, 0x0c, 0x45, 0x09, 0xc8, 0x41, 0xc1,
        0xe2, 0x06, 0x45, 0x09, 0xd0, 0x45, 0x09, 0xd8,
        0x45, 0x89, 0xc1, 0x41, 0xc1, 0xe9, 0x10, 0x44,
        0x88, 0x0a, 0x45, 0x89, 0xc1, 0x41, 0xc1, 0xe9,
        0x08, 0x44, 0x88, 0x4a, 0x01, 0x44, 0x88, 0x42,
        0x02, 0xb8, 0x03, 0x00, 0x00, 0x00, 0xc3, 0x48,
        0x83, 0xf9, 0x02, 0x72, 0x54, 0x41, 0xc1, 0xe0,
        0x12, 0x41, 0xc1, 0xe1, 0x0c, 0x45, 0x09, 0xc8,
        0x41, 0xc1, 0xe2, 0x06, 0x45, 0x09, 0xd0, 0x45,
        0x89, 0xc1, 0x41, 0xc1, 0xe9, 0x10, 0x44, 0x88,
        0x0a, 0x45, 0x89, 0xc1, 0x41, 0xc1, 0xe9, 0x08,
        0x44, 0x88, 0x4a, 0x01, 0xb8, 0x02, 0x00, 0x00,
        0x00, 0xc3, 0x80, 0x7f, 0x03, 0x3d, 0x75, 0x21,
        0x48, 0x83, 0xf9, 0x01, 0x72, 0x1b, 0x41, 0xc1,
        0xe0, 0x12, 0x41, 0xc1, 0xe1, 0x0c, 0x45, 0x09,
        0xc8, 0x45, 0x89, 0xc1, 0x41, 0xc1, 0xe9, 0x10,
        0x44, 0x88, 0x0a, 0xb8, 0x01, 0x00, 0x00, 0x00,
        0xc3, 0x48, 0xb8, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xc3,
    };
}

pub fn base64RawArgsToDecode4RegsBytes() []const u8 {
    return &.{
        0x48, 0x05, 0x00, 0x10, 0x00, 0x00, 0x49, 0x89,
        0xf8, 0x48, 0x89, 0xd7, 0x4c, 0x89, 0xc2, 0x49,
        0x89, 0xf0, 0x48, 0x89, 0xce, 0x4c, 0x89, 0xc1,
    };
}

pub fn encodeRegToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg) !void {
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, opcode);
    try bytes.append(allocator, 0xc0 | (@as(u8, reg.lowCode()) << 3));
}

pub fn encodeEaxToReg32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0xc0 | @as(u8, reg.lowCode()));
}

pub fn encodeRaxToReg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0xc0 | @as(u8, reg.lowCode()));
}

pub fn encodeShiftReg32Imm5(
    bytes: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    opcode_ext: u3,
    reg: x86_64.ArgReg,
    amount: u5,
) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0xc1);
    try bytes.append(allocator, 0xc0 | (@as(u8, opcode_ext) << 3) | @as(u8, reg.lowCode()));
    try bytes.append(allocator, amount);
}

pub fn encodeShiftReg64Imm6(
    bytes: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    opcode_ext: u3,
    reg: x86_64.ArgReg,
    amount: u6,
) !void {
    var rex: u8 = 0x48;
    if (reg.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0xc1);
    try bytes.append(allocator, 0xc0 | (@as(u8, opcode_ext) << 3) | @as(u8, reg.lowCode()));
    try bytes.append(allocator, amount);
}

pub fn encodeRegToRax64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, 0xc0 | @as(u8, reg.lowCode()));
}

pub fn encodeRegToRax64Binary(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (reg.rexR()) rex |= 0x04;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, opcode);
    try bytes.append(allocator, 0xc0 | (@as(u8, reg.lowCode()) << 3));
}

pub fn encodeDivReg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (reg.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0xf7);
    try bytes.append(allocator, 0xf0 | @as(u8, reg.lowCode()));
}

pub fn encodeDivReg32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0xf7);
    try bytes.append(allocator, 0xf0 | @as(u8, reg.lowCode()));
}

pub fn encodeFullMulReg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, signed: bool) !void {
    var rex: u8 = 0x48;
    if (reg.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0xf7);
    const extension: u8 = if (signed) 5 else 4;
    try bytes.append(allocator, 0xc0 | (extension << 3) | @as(u8, reg.lowCode()));
}

pub fn encodeAddHigh32ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    try encodeReg64ToReg64(bytes, allocator, .rcx, reg);
    try bytes.appendSlice(allocator, &.{ 0x48, 0xc1, 0xe9, 0x20, 0x01, 0xc8 });
}

pub fn encodeRegToReg(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, dst: x86_64.ArgReg, src: x86_64.ArgReg) !void {
    if (src.rexR() or dst.rexR()) {
        var rex: u8 = 0x40;
        if (src.rexR()) rex |= 0x04;
        if (dst.rexR()) rex |= 0x01;
        try bytes.append(allocator, rex);
    }
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0xc0 | (@as(u8, src.lowCode()) << 3) | @as(u8, dst.lowCode()));
}

pub fn encodeReg64ToReg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, dst: x86_64.ArgReg, src: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (src.rexR()) rex |= 0x04;
    if (dst.rexR()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0xc0 | (@as(u8, src.lowCode()) << 3) | @as(u8, dst.lowCode()));
}

pub fn encodeRspToReg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, dst: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (dst.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0xe0 | @as(u8, dst.lowCode()));
}

pub fn encodeMovsxdReg32ToReg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, dst: x86_64.ArgReg, src: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (dst.rexR()) rex |= 0x04;
    if (src.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x63);
    try bytes.append(allocator, 0xc0 | (@as(u8, dst.lowCode()) << 3) | @as(u8, src.lowCode()));
}

pub fn encodeImulReg64Reg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, dst: x86_64.ArgReg, src: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (dst.rexR()) rex |= 0x04;
    if (src.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xaf });
    try bytes.append(allocator, 0xc0 | (@as(u8, dst.lowCode()) << 3) | @as(u8, src.lowCode()));
}

pub fn encodeImulEaxReg32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, src: x86_64.ArgReg) !void {
    if (src.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xaf });
    try bytes.append(allocator, 0xc0 | @as(u8, src.lowCode()));
}

pub fn encodeImulReg64Rax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, dst: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (dst.rexR()) rex |= 0x04;
    try bytes.append(allocator, rex);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xaf });
    try bytes.append(allocator, 0xc0 | (@as(u8, dst.lowCode()) << 3));
}

pub fn encodeImulRaxReg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, src: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (src.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xaf });
    try bytes.append(allocator, 0xc0 | @as(u8, src.lowCode()));
}

pub fn encodeImulRaxFrameSlot(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, frame_index: x86_64.FrameIndex) !void {
    try bytes.appendSlice(allocator, &.{ 0x48, 0x0f, 0xaf });
    try encodeRspFrameOperand(bytes, allocator, 0, frame_index);
}

pub fn encodeAddReg64Imm32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, imm: i32) !void {
    var rex: u8 = 0x48;
    if (reg.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x81);
    try bytes.append(allocator, 0xc0 | @as(u8, reg.lowCode()));
    try appendI32(bytes, allocator, imm);
}

pub fn encodePushArg(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x50 + @as(u8, reg.lowCode()));
}

pub fn encodePopArg(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x58 + @as(u8, reg.lowCode()));
}

pub fn encodePushXmm64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.XmmReg) !void {
    try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xec, 0x08 });
    try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x11, 0x04 | (@as(u8, reg.lowCode()) << 3), 0x24 });
}

pub fn encodeRegToFrameSlot(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) !void {
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, opcode);
    try encodeRspFrameOperand(bytes, allocator, @as(u8, reg.lowCode()), frame_index);
}

pub fn encodeReg64ToFrameSlot(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) !void {
    try bytes.append(allocator, 0x48 | if (reg.rexR()) @as(u8, 0x04) else 0);
    try bytes.append(allocator, opcode);
    try encodeRspFrameOperand(bytes, allocator, @as(u8, reg.lowCode()), frame_index);
}

pub fn encodeFrameSlotToReg(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) !void {
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, opcode);
    try encodeRspFrameOperand(bytes, allocator, @as(u8, reg.lowCode()), frame_index);
}

pub fn encodeFrameSlotToReg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) !void {
    try bytes.append(allocator, 0x48 | if (reg.rexR()) @as(u8, 0x04) else 0);
    try bytes.append(allocator, opcode);
    try encodeRspFrameOperand(bytes, allocator, @as(u8, reg.lowCode()), frame_index);
}

pub fn encodeFrameSlotToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, frame_index: x86_64.FrameIndex) !void {
    try bytes.append(allocator, 0x8b);
    try encodeRspFrameOperand(bytes, allocator, 0, frame_index);
}

pub fn encodeEaxToFrameSlot(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, frame_index: x86_64.FrameIndex) !void {
    try bytes.append(allocator, 0x89);
    try encodeRspFrameOperand(bytes, allocator, 0, frame_index);
}

pub fn encodeRaxToFrameSlot(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, frame_index: x86_64.FrameIndex) !void {
    try bytes.appendSlice(allocator, &.{ 0x48, 0x89 });
    try encodeRspFrameOperand(bytes, allocator, 0, frame_index);
}

pub fn encodeFrameSlotToRax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, frame_index: x86_64.FrameIndex) !void {
    try bytes.appendSlice(allocator, &.{ 0x48, 0x8b });
    try encodeRspFrameOperand(bytes, allocator, 0, frame_index);
}

pub fn encodeStackDisp8ToArg32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, disp: u8) !void {
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, 0x44 | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    try bytes.append(allocator, disp);
}

pub fn encodeStackDisp32ToArg32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, disp: u32) !void {
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, 0x84 | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    try appendU32(bytes, allocator, disp);
}

pub fn encodeStackDisp8ToArg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, disp: u8) !void {
    var rex: u8 = 0x48;
    if (reg.rexR()) rex |= 0x04;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, 0x44 | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    try bytes.append(allocator, disp);
}

pub fn encodeStackDisp32ToArg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, disp: u32) !void {
    var rex: u8 = 0x48;
    if (reg.rexR()) rex |= 0x04;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, 0x84 | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    try appendU32(bytes, allocator, disp);
}

pub fn encodeStackDisp8U8ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, disp: u8) !void {
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6, 0x44, 0x24 });
    try bytes.append(allocator, disp);
}

pub fn encodeStackDisp32U8ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, disp: u32) !void {
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6, 0x84, 0x24 });
    try appendU32(bytes, allocator, disp);
}

pub fn encodeStackDisp8U16ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, disp: u8) !void {
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb7, 0x44, 0x24 });
    try bytes.append(allocator, disp);
}

pub fn encodeStackDisp32U16ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, disp: u32) !void {
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb7, 0x84, 0x24 });
    try appendU32(bytes, allocator, disp);
}

pub fn encodeXmmFrameSlot(
    bytes: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    prefix: u8,
    opcode: u8,
    reg: x86_64.XmmReg,
    frame_index: x86_64.FrameIndex,
) !void {
    try bytes.appendSlice(allocator, &.{ prefix, 0x0f, opcode });
    try encodeRspFrameOperand(bytes, allocator, @as(u8, reg.lowCode()), frame_index);
}

pub fn encodeRspFrameOperand(
    bytes: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    reg_low_code: u8,
    frame_index: x86_64.FrameIndex,
) !void {
    const disp = frameSlotDisp(frame_index);
    if (disp == 0) {
        try bytes.append(allocator, 0x04 | (reg_low_code << 3));
        try bytes.append(allocator, 0x24);
    } else if (disp <= 127) {
        try bytes.append(allocator, 0x44 | (reg_low_code << 3));
        try bytes.append(allocator, 0x24);
        try bytes.append(allocator, @intCast(disp));
    } else {
        try bytes.append(allocator, 0x84 | (reg_low_code << 3));
        try bytes.append(allocator, 0x24);
        try appendU32(bytes, allocator, disp);
    }
}

pub fn frameSlotDisp(frame_index: x86_64.FrameIndex) u32 {
    return frame_index.byteOffset() catch unreachable;
}

pub fn frameSlotInstructionSize(reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) u32 {
    return (if (reg.rexR()) @as(u32, 1) else 0) + 1 + frameSlotMemOperandSize(frame_index);
}

pub fn frameSlotInstructionSize64(reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) u32 {
    _ = reg;
    return 2 + frameSlotMemOperandSize(frame_index);
}

pub fn eaxFrameSlotInstructionSize(frame_index: x86_64.FrameIndex) u32 {
    return 1 + frameSlotMemOperandSize(frame_index);
}

pub fn raxFrameSlotInstructionSize(frame_index: x86_64.FrameIndex) u32 {
    return 2 + frameSlotMemOperandSize(frame_index);
}

pub fn imulRaxFrameSlotInstructionSize(frame_index: x86_64.FrameIndex) u32 {
    return 3 + frameSlotMemOperandSize(frame_index);
}

pub fn xmmFrameSlotInstructionSize(frame_index: x86_64.FrameIndex) u32 {
    return 3 + frameSlotMemOperandSize(frame_index);
}

pub fn frameSlotMemOperandSize(frame_index: x86_64.FrameIndex) u32 {
    const disp = frameSlotDisp(frame_index);
    return 2 + if (disp == 0) @as(u32, 0) else if (disp <= 127) @as(u32, 1) else 4;
}

pub fn encodeArgPtrToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, @as(u8, reg.lowCode()));
}

pub fn encodeEaxToArgPtr(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, @as(u8, reg.lowCode()));
}

pub fn encodeArgPtrDisp4ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x03);
    try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
    try bytes.append(allocator, 0x04);
}

pub fn encodeArgPtrDisp8ToRax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0x8b);
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
}

pub fn encodeArgPtrDisp32ToRax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

pub fn encodeArgPtrDisp8ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x8b);
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
}

pub fn encodeArgPtrDisp8U8ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6 });
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
}

pub fn encodeArgPtrDisp8U16ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb7 });
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
}

pub fn encodePushByvalTailArgPtr(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8, len: u8) !void {
    try validateByvalTail(offset, len);
    try encodeReserveZeroedStackEightbyte(bytes, allocator);
    var index: u8 = 0;
    while (index < len) : (index += 1) {
        try encodeArgPtrDisp8U8ToEax(bytes, allocator, reg, offset + index);
        try encodeStoreAlToRspDisp8(bytes, allocator, index);
    }
}

pub fn encodePushByvalTailStackPtr(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, stack_disp: u8, offset: u8, len: u8) !void {
    try validateByvalTail(offset, len);
    try encodeStackDisp8ToRdx(bytes, allocator, stack_disp);
    try encodeReserveZeroedStackEightbyte(bytes, allocator);
    var index: u8 = 0;
    while (index < len) : (index += 1) {
        try encodeRdxPtrDisp8U8ToEax(bytes, allocator, offset + index);
        try encodeStoreAlToRspDisp8(bytes, allocator, index);
    }
}

pub fn validateByvalTail(offset: u8, len: u8) !void {
    switch (len) {
        3, 5, 6, 7 => {},
        else => return error.UnsupportedSretByvalAbi,
    }
    if (@as(u16, offset) + @as(u16, len) > 256) return error.UnsupportedCodegenAbi;
}

pub fn encodeReserveZeroedStackEightbyte(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator) !void {
    try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xec, 0x08 });
    try bytes.appendSlice(allocator, &.{ 0x48, 0xc7, 0x04, 0x24, 0x00, 0x00, 0x00, 0x00 });
}

pub fn encodeStackDisp8ToRdx(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, stack_disp: u8) !void {
    try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x54, 0x24, stack_disp });
}

pub fn encodeRdxPtrDisp8U8ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, offset: u8) !void {
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6, 0x42, offset });
}

pub fn encodeStoreAlToRspDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, offset: u8) !void {
    try bytes.appendSlice(allocator, &.{ 0x88, 0x44, 0x24, offset });
}

pub fn pushByvalTailArgPtrSize(reg: x86_64.ArgReg, offset: u8, len: u8) u32 {
    var size: u32 = 12;
    var index: u8 = 0;
    while (index < len) : (index += 1) {
        const current = offset + index;
        size += (if (reg.rexB()) @as(u32, 1) else 0) + 3 + if (current == 0) @as(u32, 0) else 1;
        size += 4;
    }
    return size;
}

pub fn pushByvalTailStackPtrSize(len: u8) u32 {
    return 5 + 12 + @as(u32, len) * 8;
}

pub fn encodeStoreImm64ArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8, imm: i32) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0xc7);
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
    try appendI32(bytes, allocator, imm);
}

pub fn encodeStoreArg64ToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, ptr_reg: x86_64.ArgReg, src_reg: x86_64.ArgReg, offset: u8) !void {
    var rex: u8 = 0x48;
    if (src_reg.rexR()) rex |= 0x04;
    if (ptr_reg.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x89);
    if (offset == 0) {
        try bytes.append(allocator, (@as(u8, src_reg.lowCode()) << 3) | @as(u8, ptr_reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | (@as(u8, src_reg.lowCode()) << 3) | @as(u8, ptr_reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

pub fn encodeStoreArg64ToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, ptr_reg: x86_64.ArgReg, src_reg: x86_64.ArgReg, offset: u32) !void {
    var rex: u8 = 0x48;
    if (src_reg.rexR()) rex |= 0x04;
    if (ptr_reg.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0x80 | (@as(u8, src_reg.lowCode()) << 3) | @as(u8, ptr_reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

pub fn encodeStoreRaxToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0x89);
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

pub fn encodeStoreRaxToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

pub fn encodeStoreEaxToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x89);
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

pub fn encodeStoreEaxToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

pub fn encodeStoreAlToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x88);
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
}

pub fn encodeStoreAlToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x88);
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

pub fn encodeStoreAxToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    try bytes.append(allocator, 0x66);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x89);
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
}

pub fn encodeStoreAxToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    try bytes.append(allocator, 0x66);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

pub fn encodeStoreXmm0ToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    try bytes.append(allocator, 0xf2);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0x11 });
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

pub fn encodeStoreXmm0ToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    try bytes.append(allocator, 0xf2);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0x11 });
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

pub fn encodeStoreXmm0F32ToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    try bytes.append(allocator, 0xf3);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0x11 });
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

pub fn encodeStoreXmm0F32ToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    try bytes.append(allocator, 0xf3);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0x11 });
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

pub fn encodeStoreImm8ArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8, imm: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0xc6);
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
    try bytes.append(allocator, imm);
}

pub fn encodeArgPtrDisp8Tail(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

pub fn encodeRaxPtrDisp8Tail(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, offset: u8) !void {
    if (offset == 0) {
        try bytes.append(allocator, 0x00);
    } else {
        try bytes.append(allocator, 0x40);
        try bytes.append(allocator, offset);
    }
}

pub fn encodeF128ArgPtrToXmm0(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0x28 });
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

pub fn encodeF128Xmm0ToArgPtr(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0x29 });
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

pub fn f128ArgPtrInstructionSize(reg: x86_64.ArgReg, offset: u8) u32 {
    return (if (reg.rexB()) @as(u32, 1) else 0) + 3 + if (offset == 0) @as(u32, 0) else 1;
}

pub fn encodeCmp8Imm(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, imm: u8) !void {
    if (reg.needsRex8()) {
        var rex: u8 = 0x40;
        if (reg.rexB()) rex |= 0x01;
        try bytes.append(allocator, rex);
    }
    try bytes.append(allocator, 0x80);
    try bytes.append(allocator, 0xf8 | @as(u8, reg.lowCode()));
    try bytes.append(allocator, imm);
}

pub fn encodeCmp16Imm(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, imm: u16) !void {
    try bytes.append(allocator, 0x66);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x81);
    try bytes.append(allocator, 0xf8 | @as(u8, reg.lowCode()));
    try appendU16(bytes, allocator, imm);
}

pub fn encodeMovapdXmm(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, dst: x86_64.XmmReg, src: x86_64.XmmReg) !void {
    try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x28 });
    try bytes.append(allocator, 0xc0 | (@as(u8, dst.lowCode()) << 3) | @as(u8, src.lowCode()));
}

pub fn encodeCmpRcxToArg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (reg.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x39);
    try bytes.append(allocator, 0xc0 | (@as(u8, x86_64.ArgReg.rcx.lowCode()) << 3) | @as(u8, reg.lowCode()));
}

pub fn encodeCmpEcxToArg32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x39);
    try bytes.append(allocator, 0xc0 | (@as(u8, x86_64.ArgReg.rcx.lowCode()) << 3) | @as(u8, reg.lowCode()));
}

pub fn encodeCmpArg32ToR8d(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    var rex: u8 = 0x41;
    if (reg.rexR()) rex |= 0x04;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x39);
    try bytes.append(allocator, 0xc0 | (@as(u8, reg.lowCode()) << 3) | @as(u8, x86_64.ArgReg.r8.lowCode()));
}

pub fn encodeTest8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.needsRex8()) {
        var rex: u8 = 0x40;
        if (reg.rexR()) rex |= 0x05;
        try bytes.append(allocator, rex);
    }
    const code: u8 = @intCast(reg.lowCode());
    try bytes.append(allocator, 0x84);
    try bytes.append(allocator, 0xc0 | (code << 3) | code);
}

pub fn encodeTest32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexR()) {
        var rex: u8 = 0x40;
        rex |= 0x05;
        try bytes.append(allocator, rex);
    }
    const code: u8 = @intCast(reg.lowCode());
    try bytes.append(allocator, 0x85);
    try bytes.append(allocator, 0xc0 | (code << 3) | code);
}

pub fn encodeTest64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (reg.rexR()) rex |= 0x04;
    if (reg.rexB()) rex |= 0x01;
    const code: u8 = @intCast(reg.lowCode());
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x85);
    try bytes.append(allocator, 0xc0 | (code << 3) | code);
}

pub fn appendI32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, value: i32) !void {
    const raw: u32 = @bitCast(value);
    try appendU32(bytes, allocator, raw);
}

pub fn appendU16(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, value: u16) !void {
    try bytes.append(allocator, @intCast(value & 0xff));
    try bytes.append(allocator, @intCast((value >> 8) & 0xff));
}

pub fn appendU32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, value: u32) !void {
    try bytes.append(allocator, @intCast(value & 0xff));
    try bytes.append(allocator, @intCast((value >> 8) & 0xff));
    try bytes.append(allocator, @intCast((value >> 16) & 0xff));
    try bytes.append(allocator, @intCast((value >> 24) & 0xff));
}

pub fn appendU64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, value: u64) !void {
    try appendU32(bytes, allocator, @intCast(value & 0xffff_ffff));
    try appendU32(bytes, allocator, @intCast(value >> 32));
}
