//! Bounded GNU function alias directives become ordinary owned ELF aliases.
//! No assembly instructions or unknown directives are discarded or delegated.
const std = @import("std");
const ir = @import("../../ir.zig");
const Entry = struct { global: bool = false, function: bool = false, target: ?[]const u8 = null };
const Entries = std.array_hash_map.String(Entry);
const max_aliases = 1024;

pub const Parsed = struct {
    aliases: std.ArrayList(ir.GlobalAlias) = .empty,
    types: std.ArrayList([]const u8) = .empty,
    pub fn deinit(p: *Parsed, a: std.mem.Allocator) void {
        p.aliases.deinit(a);
        for (p.types.items) |text| a.free(text);
        p.types.deinit(a);
    }
};

fn symbol(text: []const u8) ![]const u8 {
    const name = std.mem.trim(u8, text, " \t");
    if (name.len == 0 or std.ascii.isDigit(name[0])) return error.UnsupportedModuleAssembly;
    for (name) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '_' and byte != '.' and byte != '$') return error.UnsupportedModuleAssembly;
    return name;
}

fn entry(a: std.mem.Allocator, entries: *Entries, name: []const u8) !*Entry {
    if (entries.count() >= max_aliases and !entries.contains(name)) return error.ModuleAssemblyAliasLimit;
    const found = try entries.getOrPut(a, name);
    if (!found.found_existing) found.value_ptr.* = .{};
    return found.value_ptr;
}

fn targetFunction(module: ir.Module, entries: *const Entries, name: []const u8, depth: usize) !ir.Function {
    if (depth > entries.count() + module.aliases.items.len) return error.UnsupportedModuleAssembly;
    if (entries.get(name)) |alias| return targetFunction(module, entries, alias.target orelse return error.UnsupportedModuleAssembly, depth + 1);
    for (module.aliases.items) |alias| if (ir.identifiers.eql(alias.name, name))
        return targetFunction(module, entries, alias.target, depth + 1);
    for (module.functions.items) |function| if (ir.identifiers.eql(function.name, name)) {
        switch (function.linkage) {
            .default, .external, .internal, .private => return function,
            else => return error.UnsupportedModuleAssembly,
        }
    };
    return error.UnsupportedModuleAssembly;
}

fn functionType(a: std.mem.Allocator, function: ir.Function) ![]const u8 {
    var output: std.Io.Writer.Allocating = .init(a);
    errdefer output.deinit();
    try function.ret_ty.format(&output.writer);
    try output.writer.writeAll(" (");
    for (function.params.items, 0..) |param, index| {
        if (index != 0) try output.writer.writeAll(", ");
        try param.ty.format(&output.writer);
    }
    if (function.is_varargs) {
        if (function.params.items.len != 0) try output.writer.writeAll(", ");
        try output.writer.writeAll("...");
    }
    try output.writer.writeByte(')');
    return output.toOwnedSlice();
}

pub fn parse(a: std.mem.Allocator, module: ir.Module) !?Parsed {
    if (module.module_asm.items.len == 0) return null;
    var entries: Entries = .empty;
    defer entries.deinit(a);
    for (module.module_asm.items) |raw| {
        const prefix = "module asm \"";
        if (!std.mem.startsWith(u8, raw, prefix) or !std.mem.endsWith(u8, raw, "\"")) return error.UnsupportedModuleAssembly;
        const body = raw[prefix.len .. raw.len - 1];
        if (std.mem.indexOfAny(u8, body, "\\\r\n\"") != null) return error.UnsupportedModuleAssembly;
        var commands = std.mem.splitScalar(u8, body, ';');
        while (commands.next()) |command_text| {
            const command = std.mem.trim(u8, command_text, " \t");
            if (command.len == 0) continue;
            const space = std.mem.indexOfAny(u8, command, " \t") orelse return error.UnsupportedModuleAssembly;
            const directive = command[0..space];
            const operands = std.mem.trim(u8, command[space..], " \t");
            if (std.mem.eql(u8, directive, ".globl") or std.mem.eql(u8, directive, ".global")) {
                const found = try entry(a, &entries, try symbol(operands));
                if (found.global) return error.UnsupportedModuleAssembly;
                found.global = true;
            } else if (std.mem.eql(u8, directive, ".type") or std.mem.eql(u8, directive, ".set")) {
                const comma = std.mem.indexOfScalar(u8, operands, ',') orelse return error.UnsupportedModuleAssembly;
                const name = try symbol(operands[0..comma]);
                const rest = std.mem.trim(u8, operands[comma + 1 ..], " \t");
                const found = try entry(a, &entries, name);
                if (std.mem.eql(u8, directive, ".type")) {
                    if (found.function or !std.mem.eql(u8, rest, "@function")) return error.UnsupportedModuleAssembly;
                    found.function = true;
                } else {
                    if (found.target != null) return error.UnsupportedModuleAssembly;
                    found.target = try symbol(rest);
                }
            } else return error.UnsupportedModuleAssembly;
        }
    }
    if (entries.count() == 0) return error.UnsupportedModuleAssembly;
    var result: Parsed = .{};
    errdefer result.deinit(a);
    result.aliases = try module.aliases.clone(a);
    for (entries.keys(), entries.values()) |name, alias| {
        if (!alias.global or !alias.function or alias.target == null) return error.UnsupportedModuleAssembly;
        for (module.functions.items) |function| if (ir.identifiers.eql(function.name, name)) return error.UnsupportedModuleAssembly;
        for (module.globals.items) |global| if (ir.identifiers.eql(global.name, name)) return error.UnsupportedModuleAssembly;
        for (module.aliases.items) |old| if (ir.identifiers.eql(old.name, name)) return error.UnsupportedModuleAssembly;
        const function = try targetFunction(module, &entries, name, 0);
        const ty = try functionType(a, function);
        result.types.append(a, ty) catch |err| { a.free(ty); return err; };
        try result.aliases.append(a, .{ .name = name, .aliased_ty = ty, .target_ty = .ptr, .target = alias.target.? });
    }
    return result;
}
