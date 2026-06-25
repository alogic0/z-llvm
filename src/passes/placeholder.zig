const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub fn make(
    comptime name: []const u8,
    comptime category: pass_manager.PassCategory,
    comptime upstream_owner: []const u8,
) pass_manager.ModulePass {
    return makeWithStatus(name, category, upstream_owner, "placeholder");
}

pub fn makeBoundaryNoop(
    comptime name: []const u8,
    comptime category: pass_manager.PassCategory,
    comptime upstream_owner: []const u8,
) pass_manager.ModulePass {
    return makeWithStatus(name, category, upstream_owner, "boundary-noop");
}

pub fn makeOutOfScope(
    comptime name: []const u8,
    comptime category: pass_manager.PassCategory,
    comptime upstream_owner: []const u8,
) pass_manager.ModulePass {
    return makeWithStatus(name, category, upstream_owner, "out-of-scope");
}

fn makeWithStatus(
    comptime name: []const u8,
    comptime category: pass_manager.PassCategory,
    comptime upstream_owner: []const u8,
    comptime target_status: []const u8,
) pass_manager.ModulePass {
    return .{
        .name = name,
        .category = category,
        .target_status = target_status,
        .upstream_owner = upstream_owner,
        .run = run,
    };
}

fn run(_: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    return .unchanged;
}
