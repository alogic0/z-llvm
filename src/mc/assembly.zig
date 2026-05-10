const x86_64 = @import("../codegen/x86_64.zig");

pub fn printFunction(function: x86_64.MachineFunction, writer: anytype) !void {
    try writer.writeAll("\t.text\n");
    try writer.print("\t.globl {s}\n", .{function.name});
    try writer.print("{s}:\n", .{function.name});
    for (function.instructions.items) |instruction| {
        switch (instruction) {
            .mov_imm_eax => |value| try writer.print("\tmovl ${}, %eax\n", .{value}),
            .mov_param_eax => |reg| try writer.print("\tmovl {s}, %eax\n", .{reg.name()}),
            .add_param_eax => |reg| try writer.print("\taddl {s}, %eax\n", .{reg.name()}),
            .ret => try writer.writeAll("\tretq\n"),
        }
    }
}
