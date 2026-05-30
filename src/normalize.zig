const std = @import("std");
const ir = @import("ir.zig");

pub fn llvmCompatibleIr(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    const filtered = try stripComparisonNoise(allocator, text);
    defer allocator.free(filtered);

    if (std.mem.trim(u8, filtered, " \t\r\n").len == 0) return try allocator.dupe(u8, "");

    var module = try ir.Module.parse(allocator, filtered);
    defer module.deinit();
    try module.verify();
    try canonicalizeNumericLocalNames(&module);

    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();

    try module.print(&output.writer);
    return try allocator.dupe(u8, output.writer.buffered());
}

pub fn stripComparisonNoise(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();

    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw_line| {
        const line = trimRight(raw_line, " \t\r");
        const trimmed = std.mem.trim(u8, line, " \t");
        if (trimmed.len == 0) {
            try output.writer.writeByte('\n');
            continue;
        }
        if (std.mem.startsWith(u8, trimmed, ";")) continue;
        if (std.mem.startsWith(u8, trimmed, "source_filename = ")) continue;
        if (std.mem.startsWith(u8, trimmed, "target datalayout = ")) continue;
        if (std.mem.startsWith(u8, trimmed, "target triple = ")) continue;

        try writeWithoutSimpleAlign(&output.writer, line);
        try output.writer.writeByte('\n');
    }

    return try allocator.dupe(u8, output.writer.buffered());
}

fn writeWithoutSimpleAlign(writer: anytype, line: []const u8) !void {
    const align_index = std.mem.indexOf(u8, line, ", align ") orelse {
        try writer.writeAll(line);
        return;
    };
    const suffix = line[align_index + ", align ".len ..];
    if (!isDecimal(suffix)) {
        try writer.writeAll(line);
        return;
    }
    try writer.writeAll(line[0..align_index]);
}

fn trimRight(text: []const u8, cutset: []const u8) []const u8 {
    var end = text.len;
    while (end > 0 and std.mem.indexOfScalar(u8, cutset, text[end - 1]) != null) {
        end -= 1;
    }
    return text[0..end];
}

fn isDecimal(text: []const u8) bool {
    if (text.len == 0) return false;
    for (text) |byte| {
        if (byte < '0' or byte > '9') return false;
    }
    return true;
}

fn canonicalizeNumericLocalNames(module: *ir.Module) !void {
    for (module.functions.items) |*function| {
        var aliases = std.StringHashMap(ir.Value).init(module.allocator);
        defer aliases.deinit();

        var next_index: usize = 0;
        for (function.params.items) |*param| {
            if (!isDecimal(param.name)) continue;
            const old_name = param.name;
            const new_name = try canonicalLocalName(module, next_index);
            next_index += 1;
            param.name = new_name;
            try aliases.put(old_name, .{ .named = new_name });
        }

        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                if (instruction.result) |old_name| {
                    if (!isDecimal(old_name)) continue;
                    const new_name = try canonicalLocalName(module, next_index);
                    next_index += 1;
                    instruction.result = new_name;
                    try aliases.put(old_name, .{ .named = new_name });
                }
            }
        }

        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                instruction.mapOperands(aliases);
            }
            if (block.terminator) |*terminator| mapTerminatorValues(terminator, aliases);
        }
    }
}

fn canonicalLocalName(module: *ir.Module, index: usize) ![]const u8 {
    return try module.ownString(try std.fmt.allocPrint(module.allocator, "{}", .{index}));
}

fn mapTerminatorValues(terminator: *ir.Terminator, aliases: std.StringHashMap(ir.Value)) void {
    switch (terminator.*) {
        .ret => |*ret| {
            if (ret.value) |value| ret.value = resolveValue(aliases, value);
        },
        .condbr => |*condbr| condbr.cond = resolveValue(aliases, condbr.cond),
        .@"switch" => |*switch_term| {
            switch_term.cond = resolveValue(aliases, switch_term.cond);
            for (switch_term.cases.items) |*case| {
                case.value = resolveValue(aliases, case.value);
            }
        },
        .indirectbr => |*indirectbr| indirectbr.addr = resolveValue(aliases, indirectbr.addr),
        .br, .@"unreachable" => {},
    }
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => value,
        .named => |name| aliases.get(name) orelse value,
    };
}
