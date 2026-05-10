const std = @import("std");

pub const Type = union(enum) {
    int: u16,

    pub fn eql(a: Type, b: Type) bool {
        return switch (a) {
            .int => |bits| switch (b) {
                .int => |other_bits| bits == other_bits,
            },
        };
    }

    pub fn format(ty: Type, writer: anytype) !void {
        switch (ty) {
            .int => |bits| try writer.print("i{}", .{bits}),
        }
    }
};

pub const Value = union(enum) {
    named: []const u8,
    int: i128,

    pub fn eql(a: Value, b: Value) bool {
        return switch (a) {
            .named => |name| switch (b) {
                .named => |other_name| std.mem.eql(u8, name, other_name),
                .int => false,
            },
            .int => |value| switch (b) {
                .named => false,
                .int => |other_value| value == other_value,
            },
        };
    }

    pub fn format(value: Value, writer: anytype) !void {
        switch (value) {
            .named => |name| try writer.print("%{s}", .{name}),
            .int => |int| try writer.print("{}", .{int}),
        }
    }
};

pub const BinaryOp = enum {
    add,
    sub,
    mul,

    pub fn parse(text: []const u8) ?BinaryOp {
        if (std.mem.eql(u8, text, "add")) return .add;
        if (std.mem.eql(u8, text, "sub")) return .sub;
        if (std.mem.eql(u8, text, "mul")) return .mul;
        return null;
    }

    pub fn name(op: BinaryOp) []const u8 {
        return @tagName(op);
    }
};

pub const Param = struct {
    ty: Type,
    name: []const u8,
};

pub const Instruction = struct {
    result: []const u8,
    op: BinaryOp,
    ty: Type,
    lhs: Value,
    rhs: Value,
    removed: bool = false,
    replacement: ?Value = null,

    pub fn hasSideEffects(_: Instruction) bool {
        return false;
    }
};

pub const Terminator = union(enum) {
    ret: struct {
        ty: Type,
        value: Value,
    },
    br: struct {
        target: []const u8,
    },
    condbr: struct {
        cond_ty: Type,
        cond: Value,
        then_target: []const u8,
        else_target: []const u8,
    },
};

pub const BasicBlock = struct {
    name: []const u8,
    instructions: std.ArrayList(Instruction),
    terminator: ?Terminator = null,

    pub fn init(name: []const u8) BasicBlock {
        return .{
            .name = name,
            .instructions = .empty,
        };
    }

    pub fn deinit(block: *BasicBlock, allocator: std.mem.Allocator) void {
        block.instructions.deinit(allocator);
    }
};

pub const Function = struct {
    name: []const u8,
    ret_ty: Type,
    params: std.ArrayList(Param),
    blocks: std.ArrayList(BasicBlock),

    pub fn init(name: []const u8, ret_ty: Type) Function {
        return .{
            .name = name,
            .ret_ty = ret_ty,
            .params = .empty,
            .blocks = .empty,
        };
    }

    pub fn deinit(function: *Function, allocator: std.mem.Allocator) void {
        function.params.deinit(allocator);
        for (function.blocks.items) |*block| block.deinit(allocator);
        function.blocks.deinit(allocator);
    }

    pub fn blockIndex(function: Function, name: []const u8) ?usize {
        for (function.blocks.items, 0..) |block, index| {
            if (std.mem.eql(u8, block.name, name)) return index;
        }
        return null;
    }
};

pub const Module = struct {
    allocator: std.mem.Allocator,
    source: []u8,
    functions: std.ArrayList(Function),

    pub fn parse(allocator: std.mem.Allocator, text: []const u8) !Module {
        var module: Module = .{
            .allocator = allocator,
            .source = try allocator.dupe(u8, text),
            .functions = .empty,
        };
        errdefer module.deinit();

        var current_function: ?usize = null;
        var current_block: ?usize = null;

        var lines = std.mem.splitScalar(u8, module.source, '\n');
        while (lines.next()) |raw_line| {
            const line_without_comment = if (std.mem.indexOfScalar(u8, raw_line, ';')) |index|
                raw_line[0..index]
            else
                raw_line;
            const line = std.mem.trim(u8, line_without_comment, " \t\r");
            if (line.len == 0) continue;

            if (std.mem.startsWith(u8, line, "define ")) {
                if (current_function != null) return error.NestedFunction;
                const function = try parseFunctionHeader(allocator, line);
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
                try function.blocks.append(allocator, BasicBlock.init(name));
                current_block = function.blocks.items.len - 1;
                continue;
            }

            if (current_block == null) {
                try function.blocks.append(allocator, BasicBlock.init("entry"));
                current_block = function.blocks.items.len - 1;
            }
            const block = &function.blocks.items[current_block.?];

            if (std.mem.startsWith(u8, line, "ret ")) {
                if (block.terminator != null) return error.MultipleTerminators;
                block.terminator = try parseRet(line);
                continue;
            }

            if (std.mem.startsWith(u8, line, "br ")) {
                if (block.terminator != null) return error.MultipleTerminators;
                block.terminator = try parseBr(line);
                continue;
            }

            try block.instructions.append(allocator, try parseInstruction(line));
        }

        if (current_function != null) return error.UnclosedFunction;
        if (module.functions.items.len == 0) return error.EmptyModule;
        return module;
    }

    pub fn deinit(module: *Module) void {
        for (module.functions.items) |*function| function.deinit(module.allocator);
        module.functions.deinit(module.allocator);
        module.allocator.free(module.source);
    }

    pub fn print(module: Module, writer: anytype) !void {
        for (module.functions.items, 0..) |function, function_index| {
            if (function_index != 0) try writer.writeByte('\n');
            try writer.writeAll("define ");
            try function.ret_ty.format(writer);
            try writer.print(" @{s}(", .{function.name});
            for (function.params.items, 0..) |param, index| {
                if (index != 0) try writer.writeAll(", ");
                try param.ty.format(writer);
                try writer.print(" %{s}", .{param.name});
            }
            try writer.writeAll(") {\n");

            for (function.blocks.items) |block| {
                try writer.print("{s}:\n", .{block.name});
                for (block.instructions.items) |instruction| {
                    if (instruction.removed) continue;
                    try writer.print("  %{s} = {s} ", .{ instruction.result, instruction.op.name() });
                    try instruction.ty.format(writer);
                    try writer.writeByte(' ');
                    try instruction.lhs.format(writer);
                    try writer.writeAll(", ");
                    try instruction.rhs.format(writer);
                    try writer.writeByte('\n');
                }
                if (block.terminator) |terminator| switch (terminator) {
                    .ret => |ret| {
                        try writer.writeAll("  ret ");
                        try ret.ty.format(writer);
                        try writer.writeByte(' ');
                        try ret.value.format(writer);
                        try writer.writeByte('\n');
                    },
                    .br => |br| try writer.print("  br label %{s}\n", .{br.target}),
                    .condbr => |condbr| {
                        try writer.writeAll("  br ");
                        try condbr.cond_ty.format(writer);
                        try writer.writeByte(' ');
                        try condbr.cond.format(writer);
                        try writer.print(", label %{s}, label %{s}\n", .{ condbr.then_target, condbr.else_target });
                    },
                };
            }

            try writer.writeAll("}\n");
        }
    }

    pub fn verify(module: Module) !void {
        for (module.functions.items) |function| {
            var defs = std.StringHashMap(Type).init(module.allocator);
            defer defs.deinit();

            for (function.params.items) |param| try defs.put(param.name, param.ty);

            for (function.blocks.items) |block| {
                for (block.instructions.items) |instruction| {
                    try verifyValue(defs, instruction.ty, instruction.lhs);
                    try verifyValue(defs, instruction.ty, instruction.rhs);
                    if (defs.contains(instruction.result)) return error.DuplicateDefinition;
                    try defs.put(instruction.result, instruction.ty);
                }

                const terminator = block.terminator orelse return error.BlockWithoutTerminator;
                switch (terminator) {
                    .ret => |ret| {
                        if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;
                        try verifyValue(defs, ret.ty, ret.value);
                    },
                    .br => |br| try verifyBlockTarget(function, br.target),
                    .condbr => |condbr| {
                        if (!condbr.cond_ty.eql(.{ .int = 1 })) return error.BranchConditionTypeMismatch;
                        try verifyValue(defs, condbr.cond_ty, condbr.cond);
                        try verifyBlockTarget(function, condbr.then_target);
                        try verifyBlockTarget(function, condbr.else_target);
                    },
                }
            }
        }
    }
};

fn verifyValue(defs: std.StringHashMap(Type), ty: Type, value: Value) !void {
    switch (value) {
        .int => {},
        .named => |name| {
            const def_ty = defs.get(name) orelse return error.UnknownValue;
            if (!def_ty.eql(ty)) return error.TypeMismatch;
        },
    }
}

fn verifyBlockTarget(function: Function, target: []const u8) !void {
    if (function.blockIndex(target) == null) return error.UnknownBlock;
}

fn parseFunctionHeader(allocator: std.mem.Allocator, line: []const u8) !Function {
    if (!std.mem.endsWith(u8, line, "{")) return error.InvalidFunctionHeader;
    const body = std.mem.trim(u8, line["define ".len .. line.len - 1], " \t");
    const open_paren = std.mem.indexOfScalar(u8, body, '(') orelse return error.InvalidFunctionHeader;
    const close_paren = std.mem.lastIndexOfScalar(u8, body, ')') orelse return error.InvalidFunctionHeader;
    if (close_paren < open_paren) return error.InvalidFunctionHeader;

    const head = std.mem.trim(u8, body[0..open_paren], " \t");
    var head_parts = std.mem.tokenizeAny(u8, head, " \t");
    const ret_ty = try parseType(head_parts.next() orelse return error.InvalidFunctionHeader);
    const name_text = head_parts.next() orelse return error.InvalidFunctionHeader;
    if (head_parts.next() != null) return error.InvalidFunctionHeader;
    if (!std.mem.startsWith(u8, name_text, "@")) return error.InvalidFunctionName;

    var function = Function.init(name_text[1..], ret_ty);
    errdefer function.deinit(allocator);

    const params_text = std.mem.trim(u8, body[open_paren + 1 .. close_paren], " \t");
    if (params_text.len != 0) {
        var params = std.mem.splitScalar(u8, params_text, ',');
        while (params.next()) |raw_param| {
            const param_text = std.mem.trim(u8, raw_param, " \t");
            var parts = std.mem.tokenizeAny(u8, param_text, " \t");
            const param_ty = try parseType(parts.next() orelse return error.InvalidParameter);
            const param_name = parts.next() orelse return error.InvalidParameter;
            if (parts.next() != null) return error.InvalidParameter;
            if (!std.mem.startsWith(u8, param_name, "%")) return error.InvalidValueName;
            try function.params.append(allocator, .{ .ty = param_ty, .name = param_name[1..] });
        }
    }

    return function;
}

fn parseInstruction(line: []const u8) !Instruction {
    const eq_index = std.mem.indexOfScalar(u8, line, '=') orelse return error.InvalidInstruction;
    const result_text = std.mem.trim(u8, line[0..eq_index], " \t");
    if (!std.mem.startsWith(u8, result_text, "%")) return error.InvalidValueName;

    const rhs_text = std.mem.trim(u8, line[eq_index + 1 ..], " \t");
    var parts = std.mem.tokenizeAny(u8, rhs_text, " \t,");
    const op = BinaryOp.parse(parts.next() orelse return error.InvalidInstruction) orelse return error.UnsupportedInstruction;
    const ty = try parseType(parts.next() orelse return error.InvalidInstruction);
    const lhs = try parseValue(parts.next() orelse return error.InvalidInstruction);
    const rhs = try parseValue(parts.next() orelse return error.InvalidInstruction);
    if (parts.next() != null) return error.InvalidInstruction;

    return .{
        .result = result_text[1..],
        .op = op,
        .ty = ty,
        .lhs = lhs,
        .rhs = rhs,
    };
}

fn parseRet(line: []const u8) !Terminator {
    var parts = std.mem.tokenizeAny(u8, line, " \t");
    if (!std.mem.eql(u8, parts.next() orelse return error.InvalidRet, "ret")) return error.InvalidRet;
    const ty = try parseType(parts.next() orelse return error.InvalidRet);
    const value = try parseValue(parts.next() orelse return error.InvalidRet);
    if (parts.next() != null) return error.InvalidRet;
    return .{ .ret = .{ .ty = ty, .value = value } };
}

fn parseBr(line: []const u8) !Terminator {
    var parts = std.mem.tokenizeAny(u8, line, " \t,");
    if (!std.mem.eql(u8, parts.next() orelse return error.InvalidBr, "br")) return error.InvalidBr;
    const first_ty = try parseTypeOrLabel(parts.next() orelse return error.InvalidBr);
    switch (first_ty) {
        .label => {
            const target = try parseLabel(parts.next() orelse return error.InvalidBr);
            if (parts.next() != null) return error.InvalidBr;
            return .{ .br = .{ .target = target } };
        },
        .ty => |cond_ty| {
            const cond = try parseValue(parts.next() orelse return error.InvalidBr);
            const then_label = parts.next() orelse return error.InvalidBr;
            if (!std.mem.eql(u8, then_label, "label")) return error.InvalidBr;
            const then_target = try parseLabel(parts.next() orelse return error.InvalidBr);
            const else_label = parts.next() orelse return error.InvalidBr;
            if (!std.mem.eql(u8, else_label, "label")) return error.InvalidBr;
            const else_target = try parseLabel(parts.next() orelse return error.InvalidBr);
            if (parts.next() != null) return error.InvalidBr;
            return .{ .condbr = .{
                .cond_ty = cond_ty,
                .cond = cond,
                .then_target = then_target,
                .else_target = else_target,
            } };
        },
    }
}

const TypeOrLabel = union(enum) {
    ty: Type,
    label,
};

fn parseTypeOrLabel(text: []const u8) !TypeOrLabel {
    if (std.mem.eql(u8, text, "label")) return .label;
    return .{ .ty = try parseType(text) };
}

fn parseLabel(text: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, text, "%") or text.len == 1) return error.InvalidLabel;
    return text[1..];
}

fn parseType(text: []const u8) !Type {
    if (text.len < 2 or text[0] != 'i') return error.UnsupportedType;
    const bits = try std.fmt.parseInt(u16, text[1..], 10);
    if (bits == 0) return error.UnsupportedType;
    return .{ .int = bits };
}

fn parseValue(text: []const u8) !Value {
    if (text.len == 0) return error.InvalidValue;
    if (text[0] == '%') {
        if (text.len == 1) return error.InvalidValueName;
        return .{ .named = text[1..] };
    }
    return .{ .int = try std.fmt.parseInt(i128, text, 10) };
}
