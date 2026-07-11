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
    };
    defer for (&functions) |*function| function.deinit(allocator);

    try appendPredicate(allocator, &functions[0], .sete_eax, false);
    try appendPredicate(allocator, &functions[1], .setne_eax, false);
    try appendPredicate(allocator, &functions[2], .setb_eax, true);
    try appendPredicate(allocator, &functions[3], .setb_eax, false);

    const object = try elf.buildObject(allocator, &functions);
    defer allocator.free(object);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = output_path, .data = object });
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
