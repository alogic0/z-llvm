const shared = @import("core_shared.zig");

const std = shared.std;
const MachineFunction = shared.MachineFunction;

pub fn appendGenericCfgReturn(allocator: std.mem.Allocator, machine: *MachineFunction) !void {
    try machine.instructions.append(allocator, .ret);
}
