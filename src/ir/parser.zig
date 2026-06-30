const std = @import("std");
const core = @import("core.zig");
const parser_helpers = @import("parser_helpers.zig");

pub fn parse(allocator: std.mem.Allocator, text: []const u8) !core.Module {
    var module: core.Module = .{
        .allocator = allocator,
        .source = try allocator.dupe(u8, text),
        .owned_strings = .empty,
        .module_asm = .empty,
        .named_types = .empty,
        .globals = .empty,
        .aliases = .empty,
        .comdats = .empty,
        .declarations = .empty,
        .functions = .empty,
        .attribute_groups = .empty,
        .metadata = .empty,
    };
    errdefer module.deinit();

    var current_function: ?usize = null;
    var current_block: ?usize = null;

    var lines = std.mem.splitScalar(u8, module.source, '\n');
    while (lines.next()) |raw_line| {
        const raw_top_level_line = std.mem.trim(u8, raw_line, " \t\r");
        if (current_function == null and std.mem.startsWith(u8, raw_top_level_line, "module asm ")) {
            try parser_helpers.parseModuleAsm(raw_top_level_line);
            try module.module_asm.append(allocator, raw_top_level_line);
            continue;
        }

        const line_without_comment = if (parser_helpers.findLineCommentStart(raw_line)) |index|
            raw_line[0..index]
        else
            raw_line;
        const line = std.mem.trim(u8, line_without_comment, " \t\r");
        if (line.len == 0) continue;

        if (current_function == null and std.mem.startsWith(u8, line, "source_filename")) {
            module.source_filename = try parser_helpers.parseModuleStringRecord(line, "source_filename");
            continue;
        }

        if (current_function == null and std.mem.startsWith(u8, line, "target triple")) {
            module.target_triple = try parser_helpers.parseModuleStringRecord(line, "target triple");
            _ = try @import("../target.zig").Triple.parse(module.target_triple.?);
            continue;
        }

        if (current_function == null and std.mem.startsWith(u8, line, "target datalayout")) {
            module.target_datalayout = try parser_helpers.parseModuleStringRecord(line, "target datalayout");
            _ = try @import("../target.zig").DataLayout.parse(module.target_datalayout.?);
            continue;
        }

        if (current_function == null and std.mem.startsWith(u8, line, "%")) {
            const named_type = try parser_helpers.parseNamedTypeDefinition(line);
            try module.named_types.append(allocator, named_type);
            continue;
        }

        if (current_function == null and std.mem.startsWith(u8, line, "@")) {
            if (parser_helpers.parseGlobalAlias(line)) |alias| {
                try module.aliases.append(allocator, alias);
                continue;
            } else |err| switch (err) {
                error.NotGlobalAlias => {},
                else => return err,
            }
            const global = try parser_helpers.parseGlobal(&module, line);
            try module.globals.append(allocator, global);
            continue;
        }
        if (current_function == null and std.mem.startsWith(u8, line, "$")) {
            try parser_helpers.parseComdat(line);
            try module.comdats.append(allocator, line);
            continue;
        }
        if (current_function == null and std.mem.startsWith(u8, line, "declare ")) {
            const decl = try parser_helpers.parseFunctionDecl(allocator, line);
            try module.declarations.append(allocator, decl);
            continue;
        }
        if (current_function == null and std.mem.startsWith(u8, line, "attributes ")) {
            try parser_helpers.parseAttributeGroup(line);
            try module.attribute_groups.append(allocator, line);
            continue;
        }
        if (current_function == null and std.mem.startsWith(u8, line, "!")) {
            try module.metadata.append(allocator, line);
            continue;
        }

        if (std.mem.startsWith(u8, line, "define ")) {
            if (current_function != null) return error.NestedFunction;
            const function = try parser_helpers.parseFunctionHeader(allocator, line);
            try module.functions.append(allocator, function);
            current_function = module.functions.items.len - 1;
            current_block = null;
            continue;
        }

        if (std.mem.eql(u8, line, "}")) {
            const function_index = current_function orelse return error.UnexpectedFunctionEnd;
            const function = &module.functions.items[function_index];
            if (function.blocks.items.len == 0) return error.FunctionWithoutBlocks;
            for (function.blocks.items) |block| {
                if (block.terminator == null) return error.BlockWithoutTerminator;
            }
            current_function = null;
            current_block = null;
            continue;
        }

        const function_index = current_function orelse return error.LineOutsideFunction;
        const function = &module.functions.items[function_index];

        if (std.mem.endsWith(u8, line, ":")) {
            const name = std.mem.trim(u8, line[0 .. line.len - 1], " \t");
            if (name.len == 0) return error.EmptyBlockName;
            if (function.blockIndex(name) != null) return error.DuplicateBlock;
            try function.blocks.append(allocator, core.BasicBlock.init(name));
            current_block = function.blocks.items.len - 1;
            continue;
        }

        if (current_block == null) {
            try function.blocks.append(allocator, core.BasicBlock.init(try parser_helpers.implicitEntryBlockName(&module, function.*, line)));
            current_block = function.blocks.items.len - 1;
        }
        const block = &function.blocks.items[current_block.?];

        if (std.mem.startsWith(u8, line, "ret ")) {
            if (block.terminator != null) return error.MultipleTerminators;
            block.terminator = try parser_helpers.parseRet(line);
            continue;
        }

        if (std.mem.startsWith(u8, line, "br ")) {
            if (block.terminator != null) return error.MultipleTerminators;
            block.terminator = try parser_helpers.parseBr(line);
            continue;
        }

        if (std.mem.startsWith(u8, line, "indirectbr ")) {
            if (block.terminator != null) return error.MultipleTerminators;
            block.terminator = try parser_helpers.parseIndirectBr(allocator, line);
            continue;
        }

        if (std.mem.startsWith(u8, line, "switch ")) {
            if (block.terminator != null) return error.MultipleTerminators;
            block.terminator = try parser_helpers.parseSwitch(allocator, line, &lines);
            continue;
        }

        if (std.mem.startsWith(u8, line, "fence ")) {
            try block.instructions.append(allocator, try parser_helpers.parseFence(line));
            continue;
        }
        if (parser_helpers.isUnsupportedEhTerminator(line)) return error.UnsupportedExceptionHandling;

        if (parser_helpers.isDebugRecord(line)) continue;

        if (std.mem.startsWith(u8, line, "unreachable")) {
            const trailing = std.mem.trim(u8, line["unreachable".len..], " \t");
            if (trailing.len != 0) {
                if (!std.mem.startsWith(u8, trailing, ",")) return error.InvalidTerminator;
                const metadata = std.mem.trim(u8, trailing[1..], " \t");
                if (metadata.len == 0) return error.InvalidTerminator;
                try parser_helpers.validateInstructionMetadata(metadata);
            }
            if (block.terminator != null) return error.MultipleTerminators;
            block.terminator = .{ .@"unreachable" = {} };
            continue;
        }

        try block.instructions.append(allocator, try parser_helpers.parseInstruction(allocator, line));
    }

    if (current_function != null) return error.UnclosedFunction;
    if (module.functions.items.len == 0 and module.module_asm.items.len == 0 and module.named_types.items.len == 0 and module.globals.items.len == 0 and module.aliases.items.len == 0 and module.comdats.items.len == 0 and module.declarations.items.len == 0 and module.metadata.items.len == 0 and module.attribute_groups.items.len == 0) return error.EmptyModule;
    return module;
}
