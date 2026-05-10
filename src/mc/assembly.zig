const x86_64 = @import("../codegen/x86_64.zig");

pub fn printFunction(function: x86_64.MachineFunction, writer: anytype) !void {
    try writer.writeAll("\t.text\n");
    try writer.print("\t.globl {s}\n", .{function.name});
    try writer.print("{s}:\n", .{function.name});
    for (function.instructions.items) |instruction| {
        switch (instruction) {
            .label => |label| try writer.print(".L{s}_{s}:\n", .{ function.name, label }),
            .mov_imm_eax => |value| try writer.print("\tmovl ${}, %eax\n", .{value}),
            .mov_arg_eax => |reg| try writer.print("\tmovl {s}, %eax\n", .{reg.name32()}),
            .binary_arg_eax => |binary| try writer.print("\t{s} {s}, %eax\n", .{ binary.op.mnemonic(), binary.reg.name32() }),
            .test_arg8 => |reg| try writer.print("\ttestb {s}, {s}\n", .{ reg.name8(), reg.name8() }),
            .je => |label| try writer.print("\tje .L{s}_{s}\n", .{ function.name, label }),
            .ret => try writer.writeAll("\tretq\n"),
        }
    }
}
