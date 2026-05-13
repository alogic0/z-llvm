const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "canonicalize-aliases",
    .category = .lto,
    .target_status = "LLVM-shaped alias-chain flattening subset",
    .upstream_owner = "llvm/lib/Transforms/Utils/CanonicalizeAliases.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.aliases.items) |*alias| {
        const target = canonicalAliasTarget(module.*, alias.target) orelse continue;
        if (std.mem.eql(u8, target, alias.target)) continue;
        alias.target = target;
        changed = true;
    }
    return if (changed) .changed else .unchanged;
}

fn canonicalAliasTarget(module: ir.Module, target: []const u8) ?[]const u8 {
    var current = target;
    var depth: usize = 0;
    while (depth < module.aliases.items.len) : (depth += 1) {
        const next = aliasTarget(module, current) orelse return current;
        current = next;
    }
    return null;
}

fn aliasTarget(module: ir.Module, name: []const u8) ?[]const u8 {
    for (module.aliases.items) |alias| {
        if (std.mem.eql(u8, alias.name, name)) return alias.target;
    }
    return null;
}
