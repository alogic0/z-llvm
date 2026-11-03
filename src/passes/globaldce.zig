const std = @import("std");
const dependencies = @import("../analysis/global_dependencies.zig");
const NodeRef = dependencies.NodeRef;
const containsRef = dependencies.containsRef;
const isLocal = dependencies.isLocal;
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "globaldce",
    .category = .ipo,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/IPO/GlobalDCE.cpp",
    .run = run,
};

fn run(module: *ir.Module, context: *pass_manager.Context) !pass_manager.PassResult {
    var graph = try dependencies.Graph.build(context.allocator, module.*);
    defer graph.deinit();
    var reachable = try graph.reachable();
    defer reachable.deinit();
    if (reachable.has_unknown) return .unchanged;
    const live = reachable.live;

    const removed_functions = removeDeadFunctions(module, live.items);
    const removed_globals = removeDeadGlobals(module, live.items);
    const removed_aliases = removeDeadAliases(module, live.items);
    const removed_comdats = removeDeadComdats(module);
    return if (removed_functions or removed_globals or removed_aliases or removed_comdats) .changed else .unchanged;
}

fn removeDeadFunctions(module: *ir.Module, live: []const NodeRef) bool {
    var changed = false;
    var index: usize = 0;
    while (index < module.functions.items.len) {
        const function = module.functions.items[index];
        if (!isLocal(function.linkage) or containsRef(live, .{ .kind = .function, .name = function.name })) {
            index += 1;
            continue;
        }

        var removed = module.functions.orderedRemove(index);
        removed.deinit(module.allocator);
        changed = true;
    }
    return changed;
}

fn removeDeadGlobals(module: *ir.Module, live: []const NodeRef) bool {
    var changed = false;
    var index: usize = 0;
    while (index < module.globals.items.len) {
        const global = module.globals.items[index];
        if (!isLocal(global.linkage) or containsRef(live, .{ .kind = .global, .name = global.name })) {
            index += 1;
            continue;
        }
        var removed = module.globals.orderedRemove(index);
        removed.deinit(module.allocator);
        changed = true;
    }
    return changed;
}

fn removeDeadAliases(module: *ir.Module, live: []const NodeRef) bool {
    var changed = false;
    var index: usize = 0;
    while (index < module.aliases.items.len) {
        const alias = module.aliases.items[index];
        if (!isLocal(alias.linkage) or containsRef(live, .{ .kind = .alias, .name = alias.name })) {
            index += 1;
            continue;
        }
        _ = module.aliases.orderedRemove(index);
        changed = true;
    }
    return changed;
}

fn removeDeadComdats(module: *ir.Module) bool {
    var changed = false;
    var index: usize = 0;
    while (index < module.comdats.items.len) {
        const name = comdatRecordName(module.comdats.items[index]) orelse {
            index += 1;
            continue;
        };
        if (comdatReferenced(module.*, name)) {
            index += 1;
            continue;
        }
        _ = module.comdats.orderedRemove(index);
        changed = true;
    }
    return changed;
}

fn comdatReferenced(module: ir.Module, name: []const u8) bool {
    for (module.globals.items) |global| {
        if (attrsReferenceComdat(global.attrs, name)) return true;
    }
    for (module.functions.items) |function| {
        if (attrsReferenceComdat(function.attrs, name)) return true;
    }
    return false;
}

fn attrsReferenceComdat(attrs: ?[]const u8, name: []const u8) bool {
    const text = attrs orelse return false;
    var rest = text;
    while (std.mem.indexOf(u8, rest, "comdat(")) |relative_start| {
        const start = relative_start + "comdat(".len;
        const after_start = rest[start..];
        const close = std.mem.indexOfScalar(u8, after_start, ')') orelse return false;
        if (std.mem.eql(u8, after_start[0..close], name)) return true;
        rest = after_start[close + 1 ..];
    }
    return false;
}

fn comdatRecordName(record: []const u8) ?[]const u8 {
    const eq_index = std.mem.indexOfScalar(u8, record, '=') orelse return null;
    return std.mem.trim(u8, record[0..eq_index], " \t");
}
