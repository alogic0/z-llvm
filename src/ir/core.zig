const std = @import("std");

pub const Type = union(enum) {
    int: u16,
    ptr,

    pub fn eql(a: Type, b: Type) bool {
        return switch (a) {
            .int => |bits| switch (b) {
                .int => |other_bits| bits == other_bits,
                .ptr => false,
            },
            .ptr => b == .ptr,
        };
    }

    pub fn format(ty: Type, writer: anytype) !void {
        switch (ty) {
            .int => |bits| try writer.print("i{}", .{bits}),
            .ptr => try writer.writeAll("ptr"),
        }
    }
};

pub const Value = union(enum) {
    named: []const u8,
    int: i128,
    undef,

    pub fn eql(a: Value, b: Value) bool {
        return switch (a) {
            .named => |name| switch (b) {
                .named => |other_name| std.mem.eql(u8, name, other_name),
                .int, .undef => false,
            },
            .int => |value| switch (b) {
                .named, .undef => false,
                .int => |other_value| value == other_value,
            },
            .undef => b == .undef,
        };
    }

    pub fn format(value: Value, writer: anytype) !void {
        switch (value) {
            .named => |name| try writer.print("%{s}", .{name}),
            .int => |int| try writer.print("{}", .{int}),
            .undef => try writer.writeAll("undef"),
        }
    }
};

pub const BinaryOp = enum {
    add,
    sub,
    mul,
    @"and",
    @"or",
    xor,
    shl,
    lshr,
    ashr,

    pub fn parse(text: []const u8) ?BinaryOp {
        if (std.mem.eql(u8, text, "add")) return .add;
        if (std.mem.eql(u8, text, "sub")) return .sub;
        if (std.mem.eql(u8, text, "mul")) return .mul;
        if (std.mem.eql(u8, text, "and")) return .@"and";
        if (std.mem.eql(u8, text, "or")) return .@"or";
        if (std.mem.eql(u8, text, "xor")) return .xor;
        if (std.mem.eql(u8, text, "shl")) return .shl;
        if (std.mem.eql(u8, text, "lshr")) return .lshr;
        if (std.mem.eql(u8, text, "ashr")) return .ashr;
        return null;
    }

    pub fn name(op: BinaryOp) []const u8 {
        return @tagName(op);
    }
};

pub const IcmpPredicate = enum {
    eq,
    ne,

    pub fn parse(text: []const u8) ?IcmpPredicate {
        if (std.mem.eql(u8, text, "eq")) return .eq;
        if (std.mem.eql(u8, text, "ne")) return .ne;
        return null;
    }

    pub fn name(predicate: IcmpPredicate) []const u8 {
        return @tagName(predicate);
    }
};

pub const Param = struct {
    ty: Type,
    name: []const u8,
};

pub const BinaryInst = struct {
    op: BinaryOp,
    ty: Type,
    lhs: Value,
    rhs: Value,
};

pub const IcmpInst = struct {
    predicate: IcmpPredicate,
    operand_ty: Type,
    lhs: Value,
    rhs: Value,
};

pub const SelectInst = struct {
    cond_ty: Type,
    cond: Value,
    ty: Type,
    true_value: Value,
    false_value: Value,
};

pub const PhiIncoming = struct {
    value: Value,
    block: []const u8,
};

pub const PhiInst = struct {
    ty: Type,
    incoming: std.ArrayList(PhiIncoming),

    pub fn deinit(phi: *PhiInst, allocator: std.mem.Allocator) void {
        phi.incoming.deinit(allocator);
    }
};

pub const AllocaInst = struct {
    allocated_ty: Type,
};

pub const LoadInst = struct {
    ty: Type,
    ptr: Value,
};

pub const StoreInst = struct {
    ty: Type,
    value: Value,
    ptr: Value,
};

pub const GepIndex = struct {
    ty: Type,
    value: Value,
};

pub const GepInst = struct {
    source_ty: Type,
    ptr: Value,
    indices: std.ArrayList(GepIndex),

    pub fn deinit(gep: *GepInst, allocator: std.mem.Allocator) void {
        gep.indices.deinit(allocator);
    }
};

pub const Instruction = struct {
    result: ?[]const u8,
    kind: union(enum) {
        binary: BinaryInst,
        icmp: IcmpInst,
        select: SelectInst,
        phi: PhiInst,
        alloca: AllocaInst,
        load: LoadInst,
        store: StoreInst,
        gep: GepInst,
    },
    removed: bool = false,
    replacement: ?Value = null,

    pub fn hasSideEffects(instruction: Instruction) bool {
        return instruction.mayWriteMemory();
    }

    pub fn mayReadMemory(instruction: Instruction) bool {
        return instruction.kind == .load;
    }

    pub fn mayWriteMemory(instruction: Instruction) bool {
        return instruction.kind == .store;
    }

    pub fn resultType(instruction: Instruction) ?Type {
        return switch (instruction.kind) {
            .binary => |binary| binary.ty,
            .icmp => .{ .int = 1 },
            .select => |select| select.ty,
            .phi => |phi| phi.ty,
            .alloca => .ptr,
            .load => |load| load.ty,
            .gep => .ptr,
            .store => null,
        };
    }

    pub fn mapOperands(instruction: *Instruction, aliases: std.StringHashMap(Value)) void {
        switch (instruction.kind) {
            .binary => |*binary| {
                binary.lhs = resolveValue(aliases, binary.lhs);
                binary.rhs = resolveValue(aliases, binary.rhs);
            },
            .icmp => |*icmp| {
                icmp.lhs = resolveValue(aliases, icmp.lhs);
                icmp.rhs = resolveValue(aliases, icmp.rhs);
            },
            .select => |*select| {
                select.cond = resolveValue(aliases, select.cond);
                select.true_value = resolveValue(aliases, select.true_value);
                select.false_value = resolveValue(aliases, select.false_value);
            },
            .phi => |*phi| for (phi.incoming.items) |*incoming| {
                incoming.value = resolveValue(aliases, incoming.value);
            },
            .alloca => {},
            .load => |*load| load.ptr = resolveValue(aliases, load.ptr),
            .store => |*store| {
                store.value = resolveValue(aliases, store.value);
                store.ptr = resolveValue(aliases, store.ptr);
            },
            .gep => |*gep| {
                gep.ptr = resolveValue(aliases, gep.ptr);
                for (gep.indices.items) |*index| {
                    index.value = resolveValue(aliases, index.value);
                }
            },
        }
    }

    pub fn deinit(instruction: *Instruction, allocator: std.mem.Allocator) void {
        switch (instruction.kind) {
            .binary, .icmp, .select, .alloca, .load, .store => {},
            .phi => |*phi| phi.deinit(allocator),
            .gep => |*gep| gep.deinit(allocator),
        }
    }
};

fn resolveValue(aliases: std.StringHashMap(Value), value: Value) Value {
    return switch (value) {
        .int, .undef => value,
        .named => |name| aliases.get(name) orelse value,
    };
}

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
    @"unreachable",
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
        for (block.instructions.items) |*instruction| instruction.deinit(allocator);
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
    owned_strings: std.ArrayList([]u8),
    functions: std.ArrayList(Function),

    pub fn parse(allocator: std.mem.Allocator, text: []const u8) !Module {
        var module: Module = .{
            .allocator = allocator,
            .source = try allocator.dupe(u8, text),
            .owned_strings = .empty,
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

            if (std.mem.eql(u8, line, "unreachable")) {
                if (block.terminator != null) return error.MultipleTerminators;
                block.terminator = .{ .@"unreachable" = {} };
                continue;
            }

            try block.instructions.append(allocator, try parseInstruction(allocator, line));
        }

        if (current_function != null) return error.UnclosedFunction;
        if (module.functions.items.len == 0) return error.EmptyModule;
        return module;
    }

    pub fn deinit(module: *Module) void {
        for (module.functions.items) |*function| function.deinit(module.allocator);
        module.functions.deinit(module.allocator);
        for (module.owned_strings.items) |owned| module.allocator.free(owned);
        module.owned_strings.deinit(module.allocator);
        module.allocator.free(module.source);
    }

    pub fn ownString(module: *Module, value: []u8) ![]const u8 {
        errdefer module.allocator.free(value);
        try module.owned_strings.append(module.allocator, value);
        return value;
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
                    if (instruction.result) |result| {
                        try writer.print("  %{s} = ", .{result});
                    } else {
                        try writer.writeAll("  ");
                    }
                    switch (instruction.kind) {
                        .binary => |binary| {
                            try writer.print("{s} ", .{binary.op.name()});
                            try binary.ty.format(writer);
                            try writer.writeByte(' ');
                            try binary.lhs.format(writer);
                            try writer.writeAll(", ");
                            try binary.rhs.format(writer);
                            try writer.writeByte('\n');
                        },
                        .icmp => |icmp| {
                            try writer.print("icmp {s} ", .{icmp.predicate.name()});
                            try icmp.operand_ty.format(writer);
                            try writer.writeByte(' ');
                            try icmp.lhs.format(writer);
                            try writer.writeAll(", ");
                            try icmp.rhs.format(writer);
                            try writer.writeByte('\n');
                        },
                        .select => |select| {
                            try writer.writeAll("select ");
                            try select.cond_ty.format(writer);
                            try writer.writeByte(' ');
                            try select.cond.format(writer);
                            try writer.writeAll(", ");
                            try select.ty.format(writer);
                            try writer.writeByte(' ');
                            try select.true_value.format(writer);
                            try writer.writeAll(", ");
                            try select.ty.format(writer);
                            try writer.writeByte(' ');
                            try select.false_value.format(writer);
                            try writer.writeByte('\n');
                        },
                        .phi => |phi| {
                            try writer.writeAll("phi ");
                            try phi.ty.format(writer);
                            try writer.writeByte(' ');
                            for (phi.incoming.items, 0..) |incoming, index| {
                                if (index != 0) try writer.writeAll(", ");
                                try writer.writeAll("[ ");
                                try incoming.value.format(writer);
                                try writer.print(", %{s} ]", .{incoming.block});
                            }
                            try writer.writeByte('\n');
                        },
                        .alloca => |alloca| {
                            try writer.writeAll("alloca ");
                            try alloca.allocated_ty.format(writer);
                            try writer.writeByte('\n');
                        },
                        .load => |load| {
                            try writer.writeAll("load ");
                            try load.ty.format(writer);
                            try writer.writeAll(", ptr ");
                            try load.ptr.format(writer);
                            try writer.writeByte('\n');
                        },
                        .store => |store| {
                            try writer.writeAll("store ");
                            try store.ty.format(writer);
                            try writer.writeByte(' ');
                            try store.value.format(writer);
                            try writer.writeAll(", ptr ");
                            try store.ptr.format(writer);
                            try writer.writeByte('\n');
                        },
                        .gep => |gep| {
                            try writer.writeAll("getelementptr ");
                            try gep.source_ty.format(writer);
                            try writer.writeAll(", ptr ");
                            try gep.ptr.format(writer);
                            for (gep.indices.items) |index| {
                                try writer.writeAll(", ");
                                try index.ty.format(writer);
                                try writer.writeByte(' ');
                                try index.value.format(writer);
                            }
                            try writer.writeByte('\n');
                        },
                    }
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
                    .@"unreachable" => try writer.writeAll("  unreachable\n"),
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
                    const result = instruction.result orelse continue;
                    if (defs.contains(result)) return error.DuplicateDefinition;
                    const result_ty = instruction.resultType() orelse return error.InstructionWithoutResultType;
                    try defs.put(result, result_ty);
                }
            }

            for (function.blocks.items) |block| {
                for (block.instructions.items) |instruction| {
                    switch (instruction.kind) {
                        .binary => |binary| {
                            if (instruction.result == null) return error.InstructionNeedsResult;
                            try verifyValue(defs, binary.ty, binary.lhs);
                            try verifyValue(defs, binary.ty, binary.rhs);
                        },
                        .icmp => |icmp| {
                            if (instruction.result == null) return error.InstructionNeedsResult;
                            try verifyValue(defs, icmp.operand_ty, icmp.lhs);
                            try verifyValue(defs, icmp.operand_ty, icmp.rhs);
                        },
                        .select => |select| {
                            if (instruction.result == null) return error.InstructionNeedsResult;
                            if (!select.cond_ty.eql(.{ .int = 1 })) return error.SelectConditionTypeMismatch;
                            try verifyValue(defs, select.cond_ty, select.cond);
                            try verifyValue(defs, select.ty, select.true_value);
                            try verifyValue(defs, select.ty, select.false_value);
                        },
                        .phi => |phi| {
                            if (instruction.result == null) return error.InstructionNeedsResult;
                            if (phi.incoming.items.len == 0) return error.EmptyPhi;
                            for (phi.incoming.items) |incoming| {
                                try verifyValue(defs, phi.ty, incoming.value);
                                try verifyBlockTarget(function, incoming.block);
                            }
                        },
                        .alloca => {
                            if (instruction.result == null) return error.InstructionNeedsResult;
                        },
                        .load => |load| {
                            if (instruction.result == null) return error.InstructionNeedsResult;
                            try verifyValue(defs, .ptr, load.ptr);
                        },
                        .store => |store| {
                            if (instruction.result != null) return error.StoreHasResult;
                            try verifyValue(defs, store.ty, store.value);
                            try verifyValue(defs, .ptr, store.ptr);
                        },
                        .gep => |gep| {
                            if (instruction.result == null) return error.InstructionNeedsResult;
                            try verifyValue(defs, .ptr, gep.ptr);
                            if (gep.indices.items.len == 0) return error.InvalidGetElementPtr;
                            for (gep.indices.items) |index| {
                                try verifyValue(defs, index.ty, index.value);
                            }
                        },
                    }
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
                    .@"unreachable" => {},
                }
            }
        }
    }
};

fn verifyValue(defs: std.StringHashMap(Type), ty: Type, value: Value) !void {
    switch (value) {
        .int, .undef => {},
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

fn parseInstruction(allocator: std.mem.Allocator, line: []const u8) !Instruction {
    if (std.mem.startsWith(u8, line, "store ")) return parseStore(line);

    const eq_index = std.mem.indexOfScalar(u8, line, '=') orelse return error.InvalidInstruction;
    const result_text = std.mem.trim(u8, line[0..eq_index], " \t");
    if (!std.mem.startsWith(u8, result_text, "%")) return error.InvalidValueName;

    const rhs_text = std.mem.trim(u8, line[eq_index + 1 ..], " \t");
    if (std.mem.startsWith(u8, rhs_text, "phi ")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .phi = try parsePhi(allocator, rhs_text) },
        };
    }

    var parts = std.mem.tokenizeAny(u8, rhs_text, " \t,");
    const op_text = parts.next() orelse return error.InvalidInstruction;

    if (std.mem.eql(u8, op_text, "icmp")) {
        const predicate = IcmpPredicate.parse(parts.next() orelse return error.InvalidInstruction) orelse return error.UnsupportedPredicate;
        const operand_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        const lhs = try parseValue(parts.next() orelse return error.InvalidInstruction);
        const rhs = try parseValue(parts.next() orelse return error.InvalidInstruction);
        if (parts.next() != null) return error.InvalidInstruction;
        return .{
            .result = result_text[1..],
            .kind = .{ .icmp = .{
                .predicate = predicate,
                .operand_ty = operand_ty,
                .lhs = lhs,
                .rhs = rhs,
            } },
        };
    }

    if (std.mem.eql(u8, op_text, "select")) {
        const cond_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        const cond = try parseValue(parts.next() orelse return error.InvalidInstruction);
        const ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        const true_value = try parseValue(parts.next() orelse return error.InvalidInstruction);
        const false_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        if (!ty.eql(false_ty)) return error.TypeMismatch;
        const false_value = try parseValue(parts.next() orelse return error.InvalidInstruction);
        if (parts.next() != null) return error.InvalidInstruction;
        return .{
            .result = result_text[1..],
            .kind = .{ .select = .{
                .cond_ty = cond_ty,
                .cond = cond,
                .ty = ty,
                .true_value = true_value,
                .false_value = false_value,
            } },
        };
    }

    if (std.mem.eql(u8, op_text, "alloca")) {
        const allocated_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        if (parts.next() != null) return error.InvalidInstruction;
        return .{
            .result = result_text[1..],
            .kind = .{ .alloca = .{ .allocated_ty = allocated_ty } },
        };
    }

    if (std.mem.eql(u8, op_text, "load")) {
        const ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        const ptr_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        if (ptr_ty != .ptr) return error.ExpectedPointerType;
        const ptr = try parseValue(parts.next() orelse return error.InvalidInstruction);
        if (parts.next() != null) return error.InvalidInstruction;
        return .{
            .result = result_text[1..],
            .kind = .{ .load = .{
                .ty = ty,
                .ptr = ptr,
            } },
        };
    }

    if (std.mem.eql(u8, op_text, "getelementptr")) {
        var gep: GepInst = .{
            .source_ty = try parseType(parts.next() orelse return error.InvalidInstruction),
            .ptr = undefined,
            .indices = .empty,
        };
        errdefer gep.deinit(allocator);

        const ptr_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        if (ptr_ty != .ptr) return error.ExpectedPointerType;
        gep.ptr = try parseValue(parts.next() orelse return error.InvalidInstruction);

        while (parts.next()) |index_ty_text| {
            const index_ty = try parseType(index_ty_text);
            const index_value = try parseValue(parts.next() orelse return error.InvalidInstruction);
            try gep.indices.append(allocator, .{
                .ty = index_ty,
                .value = index_value,
            });
        }
        if (gep.indices.items.len == 0) return error.InvalidGetElementPtr;

        return .{
            .result = result_text[1..],
            .kind = .{ .gep = gep },
        };
    }

    const op = BinaryOp.parse(op_text) orelse return error.UnsupportedInstruction;
    const ty = try parseType(parts.next() orelse return error.InvalidInstruction);
    const lhs = try parseValue(parts.next() orelse return error.InvalidInstruction);
    const rhs = try parseValue(parts.next() orelse return error.InvalidInstruction);
    if (parts.next() != null) return error.InvalidInstruction;

    return .{
        .result = result_text[1..],
        .kind = .{ .binary = .{
            .op = op,
            .ty = ty,
            .lhs = lhs,
            .rhs = rhs,
        } },
    };
}

fn parseStore(line: []const u8) !Instruction {
    var parts = std.mem.tokenizeAny(u8, line, " \t,");
    if (!std.mem.eql(u8, parts.next() orelse return error.InvalidInstruction, "store")) return error.InvalidInstruction;
    const ty = try parseType(parts.next() orelse return error.InvalidInstruction);
    const value = try parseValue(parts.next() orelse return error.InvalidInstruction);
    const ptr_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
    if (ptr_ty != .ptr) return error.ExpectedPointerType;
    const ptr = try parseValue(parts.next() orelse return error.InvalidInstruction);
    if (parts.next() != null) return error.InvalidInstruction;

    return .{
        .result = null,
        .kind = .{ .store = .{
            .ty = ty,
            .value = value,
            .ptr = ptr,
        } },
    };
}

fn parsePhi(allocator: std.mem.Allocator, text: []const u8) !PhiInst {
    var rest = std.mem.trim(u8, text["phi ".len..], " \t");
    const ty_end = std.mem.indexOfAny(u8, rest, " \t") orelse return error.InvalidPhi;
    const ty = try parseType(rest[0..ty_end]);
    rest = std.mem.trim(u8, rest[ty_end..], " \t");

    var phi: PhiInst = .{
        .ty = ty,
        .incoming = .empty,
    };
    errdefer phi.deinit(allocator);

    while (rest.len > 0) {
        if (rest[0] != '[') return error.InvalidPhi;
        const close = std.mem.indexOfScalar(u8, rest, ']') orelse return error.InvalidPhi;
        const incoming_text = std.mem.trim(u8, rest[1..close], " \t");
        const comma = std.mem.indexOfScalar(u8, incoming_text, ',') orelse return error.InvalidPhi;
        const value_text = std.mem.trim(u8, incoming_text[0..comma], " \t");
        const block_text = std.mem.trim(u8, incoming_text[comma + 1 ..], " \t");

        try phi.incoming.append(allocator, .{
            .value = try parseValue(value_text),
            .block = try parseLabel(block_text),
        });

        rest = std.mem.trim(u8, rest[close + 1 ..], " \t");
        if (rest.len == 0) break;
        if (rest[0] != ',') return error.InvalidPhi;
        rest = std.mem.trim(u8, rest[1..], " \t");
    }

    if (phi.incoming.items.len == 0) return error.EmptyPhi;
    return phi;
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
    if (std.mem.eql(u8, text, "ptr")) return .ptr;
    if (text.len < 2 or text[0] != 'i') return error.UnsupportedType;
    const bits = try std.fmt.parseInt(u16, text[1..], 10);
    if (bits == 0) return error.UnsupportedType;
    return .{ .int = bits };
}

fn parseValue(text: []const u8) !Value {
    if (text.len == 0) return error.InvalidValue;
    if (std.mem.eql(u8, text, "undef")) return .undef;
    if (text[0] == '%') {
        if (text.len == 1) return error.InvalidValueName;
        return .{ .named = text[1..] };
    }
    return .{ .int = try std.fmt.parseInt(i128, text, 10) };
}
