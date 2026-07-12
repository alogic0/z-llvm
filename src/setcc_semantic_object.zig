const std = @import("std");
const x86_64 = @import("codegen/x86_64.zig");
const elf = @import("mc/elf.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    const output_path = args.next() orelse return error.MissingOutputPath;
    if (args.next() != null) return error.UnexpectedArgument;

    var functions = [_]x86_64.MachineFunction{
        x86_64.MachineFunction.init("zllvm_sete_u64", .{ .int = 32 }),
        x86_64.MachineFunction.init("zllvm_setne_u64", .{ .int = 32 }),
        x86_64.MachineFunction.init("zllvm_setb_u64", .{ .int = 32 }),
        x86_64.MachineFunction.init("zllvm_ugt_u64", .{ .int = 32 }),
        x86_64.MachineFunction.init("zllvm_ult_u32", .{ .int = 32 }),
        x86_64.MachineFunction.init("zllvm_udiv_u32", .{ .int = 32 }),
        x86_64.MachineFunction.init("zllvm_urem_u32", .{ .int = 32 }),
        x86_64.MachineFunction.init("zllvm_ugt_u32", .{ .int = 32 }),
        x86_64.MachineFunction.init("zllvm_usub_value_u32", .{ .int = 32 }),
        x86_64.MachineFunction.init("zllvm_usub_borrow_u32", .{ .int = 32 }),
    };
    defer for (&functions) |*function| function.deinit(allocator);

    try appendPredicate(allocator, &functions[0], .sete_eax, false);
    try appendPredicate(allocator, &functions[1], .setne_eax, false);
    try appendPredicate(allocator, &functions[2], .setb_eax, true);
    try appendPredicate(allocator, &functions[3], .setb_eax, false);
    try appendUltU32(allocator, &functions[4]);
    try appendUnsignedDivU32(allocator, &functions[5], false);
    try appendUnsignedDivU32(allocator, &functions[6], true);
    try appendUgtU32(allocator, &functions[7]);
    try appendUsubOverflowU32(allocator, &functions[8], false);
    try appendUsubOverflowU32(allocator, &functions[9], true);

    const object = try elf.buildObject(allocator, &functions);
    defer allocator.free(object);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = output_path, .data = object });
}

fn appendUsubOverflowU32(allocator: std.mem.Allocator, function: *x86_64.MachineFunction, borrow: bool) !void {
    try function.instructions.appendSlice(allocator, &.{
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
        .{ .mov_arg_eax = .rdi },
        .{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } },
        .{ .mov_eax_to_arg = .rdx },
        .setb_eax,
    });
    if (!borrow) try function.instructions.append(allocator, .{ .mov_arg_eax = .rdx });
    try function.instructions.append(allocator, .ret);
}

fn appendUgtU32(allocator: std.mem.Allocator, function: *x86_64.MachineFunction) !void {
    try function.instructions.appendSlice(allocator, &.{
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
        .{ .mov_arg_arg = .{ .dst = .r8, .src = .rsi } },
        .{ .cmp_ecx_arg32 = .r8 },
        .setb_eax,
        .ret,
    });
}

fn appendUnsignedDivU32(allocator: std.mem.Allocator, function: *x86_64.MachineFunction, remainder: bool) !void {
    try function.instructions.appendSlice(allocator, &.{
        .{ .mov_arg_eax = .rdi },
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
        .xor_edx_edx,
        .{ .div_arg32 = .rcx },
    });
    if (remainder) try function.instructions.append(allocator, .{ .mov_arg_eax = .rdx });
    try function.instructions.append(allocator, .ret);
}

fn appendUltU32(allocator: std.mem.Allocator, function: *x86_64.MachineFunction) !void {
    try function.instructions.appendSlice(allocator, &.{
        .{ .mov_arg_arg = .{ .dst = .r8, .src = .rdi } },
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
        .{ .cmp_ecx_arg32 = .r8 },
        .setb_eax,
        .ret,
    });
}

fn appendPredicate(
    allocator: std.mem.Allocator,
    function: *x86_64.MachineFunction,
    setcc: x86_64.Instruction,
    swap_operands: bool,
) !void {
    const rcx_source: x86_64.ArgReg = if (swap_operands) .rsi else .rdi;
    const r8_source: x86_64.ArgReg = if (swap_operands) .rdi else .rsi;
    try function.instructions.appendSlice(allocator, &.{
        .{ .mov_arg64_arg = .{ .dst = .rcx, .src = rcx_source } },
        .{ .mov_arg64_arg = .{ .dst = .r8, .src = r8_source } },
        .{ .cmp_rcx_arg64 = .r8 },
        setcc,
        .ret,
    });
}
