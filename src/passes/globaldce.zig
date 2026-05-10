const std = @import("std");
const call_graph = @import("../analysis/call_graph.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "globaldce",
    .category = .ipo,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/IPO/GlobalDCE.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    const removed_functions = try removeDeadFunctions(module.allocator, module);
    const removed_globals = removeDeadGlobals(module);
    return if (removed_functions or removed_globals) .changed else .unchanged;
}

fn removeDeadFunctions(allocator: std.mem.Allocator, module: *ir.Module) !bool {
    var graph = try call_graph.CallGraph.build(allocator, module.*);
    defer graph.deinit();

    var live = std.StringHashMap(void).init(allocator);
    defer live.deinit();

    var worklist: std.ArrayList([]const u8) = .empty;
    defer worklist.deinit(allocator);

    for (module.functions.items) |function| {
        if (!isLocal(function.linkage)) try markLive(allocator, &live, &worklist, function.name);
    }

    while (worklist.pop()) |function_name| {
        const callees = graph.calleesOf(function_name) orelse continue;
        for (callees) |callee| {
            if (!hasDefinition(module.*, callee)) continue;
            try markLive(allocator, &live, &worklist, callee);
        }
    }

    var changed = false;
    var index: usize = 0;
    while (index < module.functions.items.len) {
        const function = module.functions.items[index];
        if (!isLocal(function.linkage) or live.contains(function.name)) {
            index += 1;
            continue;
        }

        var removed = module.functions.orderedRemove(index);
        removed.deinit(module.allocator);
        changed = true;
    }
    return changed;
}

fn removeDeadGlobals(module: *ir.Module) bool {
    var changed = false;
    var index: usize = 0;
    while (index < module.globals.items.len) {
        const global = module.globals.items[index];
        if (!isLocal(global.linkage)) {
            index += 1;
            continue;
        }
        _ = module.globals.orderedRemove(index);
        changed = true;
    }
    return changed;
}

fn markLive(
    allocator: std.mem.Allocator,
    live: *std.StringHashMap(void),
    worklist: *std.ArrayList([]const u8),
    name: []const u8,
) !void {
    if (live.contains(name)) return;
    try live.put(name, {});
    try worklist.append(allocator, name);
}

fn hasDefinition(module: ir.Module, name: []const u8) bool {
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, name)) return true;
    }
    return false;
}

fn isLocal(linkage: ir.FunctionLinkage) bool {
    return linkage == .internal or linkage == .private;
}
