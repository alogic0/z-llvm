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
            .mov_arg_arg => |mov| try writer.print("\tmovl {s}, {s}\n", .{ mov.src.name32(), mov.dst.name32() }),
            .binary_arg_eax => |binary| try writer.print("\t{s} {s}, %eax\n", .{ binary.op.mnemonic(), binary.reg.name32() }),
            .sub_rsp_8 => try writer.writeAll("\tsubq $8, %rsp\n"),
            .add_rsp_8 => try writer.writeAll("\taddq $8, %rsp\n"),
            .spill_arg_rsp => |reg| try writer.print("\tmovl {s}, (%rsp)\n", .{reg.name32()}),
            .reload_arg_rsp => |reg| try writer.print("\tmovl (%rsp), {s}\n", .{reg.name32()}),
            .reload_rsp_eax => try writer.writeAll("\tmovl (%rsp), %eax\n"),
            .direct_call => |call| try writer.print("\tcallq {s}\n", .{call.symbol}),
            .test_arg8 => |reg| try writer.print("\ttestb {s}, {s}\n", .{ reg.name8(), reg.name8() }),
            .je => |label| try writer.print("\tje .L{s}_{s}\n", .{ function.name, label }),
            .ret => try writer.writeAll("\tretq\n"),
        }
    }
}
