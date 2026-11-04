//! Numeric LLVM locals share one ordered namespace across parameters, blocks
//! and instruction results. CFG edits may change that order. This print-only
//! plan never mutates IR or its analyses, and completes before output starts.
const std = @import("std");
const ir = @import("core.zig");
const operands = @import("operands.zig");
const opaque_names = @import("opaque_names.zig");

pub const Mode = enum { repair, canonical };

pub const Names = struct {
    aliases: std.StringHashMapUnmanaged([]const u8) = .empty,
    texts: std.StringHashMapUnmanaged([]const u8) = .empty,

    pub fn name(names: Names, original: []const u8) []const u8 {
        return names.aliases.get(original) orelse original;
    }

    pub fn value(names: Names, original: ir.Value) ir.Value {
        return switch (original) {
            .named => |raw| .{ .named = names.text(names.name(raw)) },
            .vector => |raw| .{ .vector = names.text(raw) },
            .constant_expr => |raw| .{ .constant_expr = names.text(raw) },
            else => original,
        };
    }

    pub fn text(names: Names, original: []const u8) []const u8 {
        return names.texts.get(original) orelse original;
    }

    pub fn optionalText(names: Names, original: ?[]const u8) ?[]const u8 {
        return if (original) |raw| names.text(raw) else null;
    }

    fn changes(names: Names, original: []const u8) bool {
        return !std.mem.eql(u8, original, names.name(original));
    }
};

pub const Plan = struct {
    arena: std.heap.ArenaAllocator,
    functions: []Names = &.{},
    ir_functions: []const ir.Function = &.{},
    function_indexes: std.StringHashMapUnmanaged(usize) = .empty,
    texts: std.StringHashMapUnmanaged([]const u8) = .empty,

    pub fn init(module: ir.Module, mode: Mode) !Plan {
        var plan: Plan = .{ .arena = .init(module.allocator) };
        errdefer plan.deinit();
        var needed = false;
        for (module.functions.items) |function| {
            if (try needsNames(function, mode)) {
                needed = true;
                break;
            }
        }
        if (!needed) return plan;

        const allocator = plan.arena.allocator();
        plan.ir_functions = module.functions.items;
        for (module.functions.items, 0..) |function, index| try plan.function_indexes.put(allocator, function.name, index);
        plan.functions = try allocator.alloc(Names, module.functions.items.len);
        @memset(plan.functions, .{});
        var changed_blocks: std.StringHashMapUnmanaged(void) = .empty;
        var changed_locals: std.StringHashMapUnmanaged(void) = .empty;
        for (module.functions.items, plan.functions) |function, *names| {
            if (!try needsNames(function, mode)) continue;
            var index: usize = 0;
            for (function.params.items) |param| try addName(allocator, names, param.name, &index);
            for (function.blocks.items) |block| {
                try addName(allocator, names, block.name, &index);
                if (names.changes(block.name)) try changed_blocks.put(allocator, block.name, {});
                for (block.instructions.items) |instruction| {
                    if (instruction.removed) continue;
                    if (instruction.result) |result| {
                        try addName(allocator, names, result, &index);
                    } else if (instruction.resultType() != null) {
                        // The verifier already rejects unnamed non-void calls.
                        // Their implicit definitions are not represented in IR.
                        return error.InstructionNeedsResult;
                    }
                }
            }
            var entries = names.aliases.iterator();
            while (entries.next()) |entry| {
                if (names.changes(entry.key_ptr.*)) try changed_locals.put(allocator, entry.key_ptr.*, {});
            }
        }

        // Parse blockaddress's complete function/block pair before renaming.
        // Other opaque numeric references remain conservative; numeric types
        // are never blindly substituted as though they were SSA operands.
        const module_check: OpaqueCheck = .{ .plan = &plan, .other_names = changed_locals };
        for (module.globals.items) |global| {
            switch (global.initializer) {
                .none, .c_string => {},
                .scalar => |value| try module_check.visit(&value, global.ty),
                .array => |array| for (array.values.items) |*value| try module_check.visit(value, global.ty),
                .@"opaque" => |raw| try module_check.text(raw),
            }
            try module_check.text(global.attrs);
            try module_check.text(global.address_attrs);
        }
        for (module.metadata.items) |raw| try module_check.text(raw);
        for (module.attribute_groups.items) |raw| try module_check.text(raw);
        for (module.declarations.items) |decl| {
            try module_check.text(decl.attrs);
            try module_check.text(decl.ret_attrs);
            for (decl.params.items) |param| try module_check.text(param.attrs);
        }
        for (module.functions.items, plan.functions) |function, names| {
            const check: OpaqueCheck = .{ .plan = &plan, .names = names, .other_names = changed_blocks };
            try check.text(function.attrs);
            try check.text(function.ret_attrs);
            for (function.params.items) |param| try check.text(param.attrs);
            for (function.blocks.items) |block| {
                for (block.instructions.items) |*instruction| {
                    if (instruction.removed) continue;
                    _ = try operands.instruction(@as(*const ir.Instruction, instruction), check);
                    try check.text(instruction.metadata);
                    switch (instruction.kind) {
                        .call => |call| {
                            try check.text(call.raw_args);
                            try check.text(call.operand_bundle);
                            try check.text(call.attrs);
                            try check.text(call.ret_attrs);
                            for (call.args.items) |arg| try check.text(arg.attrs);
                            // Assembly templates refer to bound arguments, not
                            // LLVM local names; quoted template bytes stay intact.
                        },
                        .alloca => |alloca| try check.text(alloca.attrs),
                        .binary,
                        .cast,
                        .freeze,
                        .icmp,
                        .fcmp,
                        .select,
                        .phi,
                        .load,
                        .store,
                        .atomicrmw,
                        .cmpxchg,
                        .fence,
                        .extractelement,
                        .insertelement,
                        .shufflevector,
                        .extractvalue,
                        .insertvalue,
                        .gep,
                        => {},
                    }
                }
                if (block.terminator) |term| {
                    _ = try operands.terminator(&term, check);
                    switch (term) {
                        .br => |x| try check.text(x.metadata),
                        .condbr => |x| try check.text(x.metadata),
                        .@"switch" => |x| try check.text(x.metadata),
                        .indirectbr => |x| try check.text(x.metadata),
                        .ret, .@"unreachable" => {},
                    }
                }
            }
        }
        return plan;
    }

    pub fn deinit(plan: *Plan) void {
        plan.arena.deinit();
    }

    pub fn forFunction(plan: Plan, index: usize) Names {
        var names: Names = if (plan.functions.len == 0) .{} else plan.functions[index];
        names.texts = plan.texts;
        return names;
    }

    pub fn moduleNames(plan: Plan) Names {
        return .{ .texts = plan.texts };
    }

    fn blockName(plan: *const Plan, function_name: []const u8, block_name: []const u8) ![]const u8 {
        const index = plan.function_indexes.get(function_name) orelse return error.UnsupportedNumericLocalReference;
        for (plan.ir_functions[index].blocks.items) |block| {
            if (std.mem.eql(u8, block.name, block_name)) return plan.functions[index].name(block_name);
        }
        return error.UnsupportedNumericLocalReference;
    }
};

fn numeric(name: []const u8) bool {
    if (name.len == 0) return false;
    for (name) |byte| if (!std.ascii.isDigit(byte)) return false;
    return true;
}

fn orderedName(name: []const u8, next: *usize, mode: Mode) !bool {
    if (!numeric(name)) return true;
    const id = std.fmt.parseInt(usize, name, 10) catch return error.NumericLocalNameOutOfRange;
    const ordered = if (mode == .canonical) id == next.* else id >= next.*;
    next.* = std.math.add(usize, id, 1) catch return error.NumericLocalNameOutOfRange;
    return ordered;
}

fn needsNames(function: ir.Function, mode: Mode) !bool {
    var next: usize = 0;
    for (function.params.items) |param| if (!try orderedName(param.name, &next, mode)) return true;
    for (function.blocks.items) |block| {
        if (!try orderedName(block.name, &next, mode)) return true;
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| {
                if (!try orderedName(result, &next, mode)) return true;
            } else if (instruction.resultType() != null) {
                next = std.math.add(usize, next, 1) catch return error.NumericLocalNameOutOfRange;
            }
        }
    }
    return false;
}

fn addName(allocator: std.mem.Allocator, names: *Names, original: []const u8, next: *usize) !void {
    if (!numeric(original)) return;
    if (names.aliases.contains(original)) return error.DuplicateNumericLocalName;
    const replacement = try std.fmt.allocPrint(allocator, "{}", .{next.*});
    try names.aliases.put(allocator, original, replacement);
    next.* += 1;
}

const OpaqueCheck = struct {
    pub const Error = std.mem.Allocator.Error || error{UnsupportedNumericLocalReference};
    plan: *Plan,
    names: Names = .{},
    other_names: std.StringHashMapUnmanaged(void) = .empty,

    pub fn visit(check: OpaqueCheck, value: *const ir.Value, _: ir.Type) Error!void {
        switch (value.*) {
            .vector => |raw| try check.text(raw),
            .constant_expr => |raw| try check.text(raw),
            .named => |raw| if (std.mem.startsWith(u8, raw, "!")) try check.text(raw),
            .int, .fp, .undef, .poison, .null_value, .zero_initializer => {},
        }
    }

    // Recognize complete identifier tokens outside LLVM quoted strings. This
    // proves only absence of names that this plan changes, not general reference
    // coverage. Only a parsed blockaddress pair can be rewritten. Other
    // matching tokens reject before output, and quoted bytes remain intact.
    fn text(check: OpaqueCheck, optional: ?[]const u8) Error!void {
        if (check.names.aliases.count() == 0 and check.other_names.count() == 0) return;
        const raw = optional orelse return;
        var tokens: opaque_names.Iterator = .{ .raw = raw };
        var copied: usize = 0;
        var rewritten: std.ArrayList(u8) = .empty;
        const allocator = check.plan.arena.allocator();
        while (tokens.next() catch return error.UnsupportedNumericLocalReference) |token| {
            switch (token) {
                .local => |name| if (check.names.changes(name) or check.other_names.contains(name)) {
                    return error.UnsupportedNumericLocalReference;
                },
                .block_address => |address| {
                    const replacement = try check.plan.blockName(address.function, address.block);
                    if (!std.mem.eql(u8, replacement, address.block)) {
                        try rewritten.appendSlice(allocator, raw[copied..address.block_start]);
                        try rewritten.appendSlice(allocator, replacement);
                        copied = address.block_end;
                    }
                },
            }
        }
        if (copied != 0 and !check.plan.texts.contains(raw)) {
            try rewritten.appendSlice(allocator, raw[copied..]);
            try check.plan.texts.put(allocator, raw, try rewritten.toOwnedSlice(allocator));
        }
    }
};
