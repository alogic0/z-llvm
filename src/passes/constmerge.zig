const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const references = @import("../analysis/module_references.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "constmerge",
    .category = .ipo,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/IPO/ConstantMerge.cpp",
    .run = run,
};

const Replacement = struct {
    old_name: []const u8,
    new_name: []const u8,
    new_value: ir.Value,
};

fn run(module: *ir.Module, context: *pass_manager.Context) !pass_manager.PassResult {
    // The replacement walk cannot rewrite opaque expressions, metadata or
    // assembly. Incomplete reference coverage forbids deleting any candidate.
    if (references.hasUnknown(module)) return .unchanged;
    var replacements: std.ArrayList(Replacement) = .empty;
    defer replacements.deinit(context.allocator);

    for (module.globals.items, 0..) |global, index| {
        if (!isMergeableConstant(global)) continue;

        var canonical_index: ?usize = null;
        var candidate_index = index + 1;
        while (candidate_index < module.globals.items.len) : (candidate_index += 1) {
            const candidate = module.globals.items[candidate_index];
            if (!sameMergeKey(global, candidate)) continue;
            canonical_index = candidate_index;
        }

        const chosen_index = canonical_index orelse continue;
        const canonical = module.globals.items[chosen_index];
        const replacement_name = try module.ownString(try std.fmt.allocPrint(context.allocator, "@{s}", .{canonical.name}));
        try replacements.append(context.allocator, .{
            .old_name = global.name,
            .new_name = canonical.name,
            .new_value = .{ .named = replacement_name },
        });
    }

    if (replacements.items.len == 0) return .unchanged;

    for (replacements.items) |replacement| {
        replaceGlobalUses(module, replacement);
    }
    removeMergedGlobals(module, replacements.items);
    return .changed;
}

fn isMergeableConstant(global: ir.Global) bool {
    if (global.kind != .constant) return false;
    if (!isLocal(global.linkage)) return false;
    if (!hasUnnamedAddr(global)) return false;
    if (hasComdat(global.attrs) or isThreadLocal(global)) return false;
    return switch (global.initializer) {
        .scalar => |value| isScalarConstant(value),
        .none, .array, .c_string, .@"opaque" => false,
    };
}

fn sameMergeKey(a: ir.Global, b: ir.Global) bool {
    if (!isMergeableConstant(b)) return false;
    if (!a.ty.eql(b.ty)) return false;
    if (!sameOptionalText(a.attrs, b.attrs)) return false;
    return switch (a.initializer) {
        .scalar => |a_value| switch (b.initializer) {
            .scalar => |b_value| a_value.eql(b_value),
            .none, .array, .c_string, .@"opaque" => false,
        },
        .none, .array, .c_string, .@"opaque" => false,
    };
}

fn replaceGlobalUses(module: *ir.Module, replacement: Replacement) void {
    for (module.globals.items) |*global| {
        replaceInitializer(&global.initializer, replacement);
    }
    for (module.aliases.items) |*alias| {
        if (ir.identifiers.eql(alias.target, replacement.old_name)) alias.target = replacement.new_name;
    }
    for (module.functions.items) |*function| {
        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                if (instruction.removed) continue;
                _ = ir.operands.instruction(instruction, OperandReplacer{ .replacement = replacement }) catch unreachable;
            }
            if (block.terminator) |*terminator|
                _ = ir.operands.terminator(terminator, OperandReplacer{ .replacement = replacement }) catch unreachable;
        }
    }
}

fn replaceInitializer(initializer: *ir.GlobalInitializer, replacement: Replacement) void {
    switch (initializer.*) {
        .scalar => |*value| value.* = replaceValue(value.*, replacement),
        .array => |*array| for (array.values.items) |*value| {
            value.* = replaceValue(value.*, replacement);
        },
        .none, .c_string, .@"opaque" => {},
    }
}

fn removeMergedGlobals(module: *ir.Module, replacements: []const Replacement) void {
    var index: usize = 0;
    while (index < module.globals.items.len) {
        const global = module.globals.items[index];
        if (!isRemovedGlobal(global.name, replacements) or references.query(module, global.name).mayReference()) {
            index += 1;
            continue;
        }
        var removed = module.globals.orderedRemove(index);
        removed.deinit(module.allocator);
    }
}

fn isRemovedGlobal(name: []const u8, replacements: []const Replacement) bool {
    for (replacements) |replacement| {
        if (std.mem.eql(u8, name, replacement.old_name)) return true;
    }
    return false;
}

const OperandReplacer = struct {
    pub const Error = error{};
    replacement: Replacement,
    pub fn visit(replacer: OperandReplacer, value: *ir.Value, _: ir.Type) Error!void {
        value.* = replaceValue(value.*, replacer.replacement);
    }
};

fn replaceValue(value: ir.Value, replacement: Replacement) ir.Value {
    if (!references.isDirectValue(value, replacement.old_name)) return value;
    return replacement.new_value;
}

fn isScalarConstant(value: ir.Value) bool {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer => true,
        .named, .vector, .constant_expr => false,
    };
}

fn isLocal(linkage: ir.FunctionLinkage) bool {
    return linkage == .internal or linkage == .private;
}

fn hasUnnamedAddr(global: ir.Global) bool {
    return if (global.address_attrs) |text| std.mem.indexOf(u8, text, "unnamed_addr") != null else false;
}

fn hasComdat(attrs: ?[]const u8) bool {
    return if (attrs) |text| std.mem.indexOf(u8, text, "comdat") != null else false;
}

fn isThreadLocal(global: ir.Global) bool {
    return if (global.address_attrs) |text| std.mem.indexOf(u8, text, "thread_local") != null else false;
}

fn sameOptionalText(a: ?[]const u8, b: ?[]const u8) bool {
    if (a == null and b == null) return true;
    if (a == null or b == null) return false;
    return std.mem.eql(u8, a.?, b.?);
}
