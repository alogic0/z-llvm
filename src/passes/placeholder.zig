const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub fn make(
    comptime name: []const u8,
    comptime category: pass_manager.PassCategory,
    comptime upstream_owner: []const u8,
) pass_manager.ModulePass {
    return .{
        .name = name,
        .category = category,
        .target_status = "placeholder",
        .upstream_owner = upstream_owner,
        .run = run,
    };
}

fn run(_: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    return .unchanged;
}
