//! Private SSA transport for literal integer/pointer and flag pairs. Producers retain their
//! original type and effects; only PHIs, selects, freezes and constructors are
//! split. In particular, each cmpxchg still executes exactly once.
const std = @import("std");
const ir = @import("../../../ir.zig");
const fields = @import("../../../ir/structure.zig");
const parser = @import("../../../ir/parser_types_values.zig");
const opaque_names = @import("../../../ir/opaque_names.zig");
const forms = @import("scalar_forms.zig");

const Entry = struct { ty: ir.Type, parts: [2][]const u8, transport: bool };
const Names = std.HashMap([]const u8, Entry, ir.identifiers.Context, std.hash_map.default_max_load_percentage);

fn types(ty: ir.Type) ?[2]ir.Type {
    if (ty != .aggregate) return null;
    var members = fields.Fields.init(ty.aggregate) orelse return null;
    const first = parser.parseType(members.next() orelse return null) catch return null;
    const second = parser.parseType(members.next() orelse return null) catch return null;
    if (members.next() != null or (first != .ptr and (first != .int or first.int == 0 or first.int > 128)) or !second.eql(.{ .int = 1 })) return null;
    return .{ first, second };
}

fn index(raw: []const u8) ?usize {
    const text = std.mem.trim(u8, raw, " \t");
    if (std.mem.eql(u8, text, "0")) return 0;
    if (std.mem.eql(u8, text, "1")) return 1;
    return null;
}

fn isTransport(inst: ir.Instruction) bool {
    return switch (inst.kind) {
        .phi, .select, .freeze, .insertvalue => true,
        else => false,
    };
}

fn leaf(names: Names, value: ir.Value, ty: ir.Type, part: usize) ?ir.Value {
    switch (value) {
        .undef, .poison => return value,
        .zero_initializer => return if (types(ty).?[part] == .ptr) .null_value else .{ .int = 0 },
        .named => |name| {
            const entry = names.get(name) orelse return null;
            if (!entry.ty.eql(ty)) return null;
            return .{ .named = entry.parts[part] };
        },
        .constant_expr => |raw| {
            var members = fields.Fields.init(raw) orelse return null;
            var result: [2]ir.Value = undefined;
            for (types(ty).?, 0..) |expected, i| {
                const field = parser.parseTypedValue(members.next() orelse return null) catch return null;
                if (!field.ty.eql(expected)) return null;
                result[i] = field.value;
            }
            if (members.next() != null) return null;
            return result[part];
        },
        else => return null,
    }
}

const UseCheck = struct {
    pub const Error = error{};
    names: Names,
    allowed: bool,
    valid: *bool,

    fn text(check: UseCheck, raw: ?[]const u8) void {
        var tokens: opaque_names.Iterator = .{ .raw = raw orelse return };
        while (tokens.next() catch {
            check.valid.* = false;
            return;
        }) |token| {
            if (token == .local) if (check.names.get(token.local)) |entry| {
                if (entry.transport) check.valid.* = false;
            };
        }
    }

    pub fn visit(check: UseCheck, value: *const ir.Value, ty: ir.Type) Error!void {
        switch (value.*) {
            .named => |name| if (check.names.get(name)) |entry| {
                if (entry.transport and (!check.allowed or !ty.eql(entry.ty))) check.valid.* = false;
            },
            .constant_expr => |raw| check.text(raw),
            .vector => |raw| check.text(raw),
            else => {},
        }
    }
};

fn alias(allocator: std.mem.Allocator, function: ir.Function, serial: *forms.TemporaryNames, block: *ir.BasicBlock, name: ?[]const u8, ty: ir.Type, value: ir.Value, metadata: ?[]const u8) !void {
    // A later insert may overwrite an undefined constructor field. Choose a
    // concrete refinement instead of demanding an undefined scalar carrier.
    const concrete: ir.Value = if (value == .undef or value == .poison) (if (ty == .ptr) .null_value else .{ .int = 0 }) else value;
    if (ty == .ptr) {
        if (concrete == .null_value) {
            const zero = try forms.temporary(allocator, function, serial);
            try block.instructions.append(allocator, .{ .result = zero, .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 64 },
                .lhs = .{ .int = 0 },
                .rhs = .{ .int = 0 },
            } } });
            try block.instructions.append(allocator, .{ .result = name, .metadata = metadata, .kind = .{ .cast = .{
                .op = .inttoptr,
                .from_ty = .{ .int = 64 },
                .value = .{ .named = zero },
                .to_ty = .ptr,
            } } });
        } else {
            var indices: std.ArrayList(ir.GepIndex) = .empty;
            try indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
            try block.instructions.append(allocator, .{ .result = name, .metadata = metadata, .kind = .{ .gep = .{
                .source_ty = .{ .int = 8 },
                .ptr = concrete,
                .indices = indices,
            } } });
        }
        return;
    }
    if (ty.eql(.{ .int = 1 })) {
        const literal = if (concrete == .int) try forms.temporary(allocator, function, serial) else null;
        if (literal) |temporary| try block.instructions.append(allocator, .{ .result = temporary, .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .int = concrete.int & 1 },
            .rhs = .{ .int = 0 },
        } } });
        try block.instructions.append(allocator, .{ .result = name, .metadata = metadata, .kind = if (concrete == .int) .{ .icmp = .{
            .predicate = .ne,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = literal.? },
            .rhs = .{ .int = 0 },
        } } else .{ .cast = .{
            .op = .bitcast,
            .from_ty = ty,
            .value = concrete,
            .to_ty = ty,
        } } });
        return;
    }
    try block.instructions.append(allocator, .{ .result = name, .metadata = metadata, .kind = .{ .binary = .{
        .op = .add,
        .ty = ty,
        .lhs = concrete,
        .rhs = .{ .int = 0 },
    } } });
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    // Ordinary scalar functions and extract-only producers allocate nothing.
    var needed = false;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and isTransport(inst) and types(inst.resultType() orelse continue) != null) needed = true;
    };
    if (!needed) return null;

    var names = Names.init(allocator);
    defer names.deinit();
    var serial: forms.TemporaryNames = .{ .prefix = "__zllvm_flag_pair_" };
    defer serial.deinit(allocator);
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        const name = inst.result orelse continue;
        const ty = inst.resultType() orelse continue;
        if (types(ty) == null) continue;
        if (!isTransport(inst) and inst.kind != .call and inst.kind != .cmpxchg) continue;
        try names.put(name, .{ .ty = ty, .parts = .{
            try forms.temporary(allocator, function, &serial),
            try forms.temporary(allocator, function, &serial),
        }, .transport = isTransport(inst) });
    };

    // A removed aggregate must have only structured, typed field/transport uses.
    // Public returns, memory, calls and opaque references remain fail-closed.
    var valid = true;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |inst| {
            if (inst.removed) continue;
            const allowed = if (inst.kind == .extractvalue) types(inst.kind.extractvalue.aggregate_ty) != null else isTransport(inst) and names.contains(inst.result orelse "");
            const check: UseCheck = .{ .names = names, .allowed = allowed, .valid = &valid };
            _ = try ir.operands.instruction(&inst, check);
            check.text(inst.metadata);
            if (inst.kind == .call) {
                check.text(inst.kind.call.raw_args);
                check.text(inst.kind.call.operand_bundle);
                check.text(inst.kind.call.attrs);
                check.text(inst.kind.call.ret_attrs);
            }
        }
        if (block.terminator) |term| _ = try ir.operands.terminator(&term, UseCheck{ .names = names, .allowed = false, .valid = &valid });
    }
    if (!valid) return null;

    var result = function;
    result.blocks = .empty;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            if (!inst.removed) {
                if (inst.kind == .extractvalue) {
                    const extract = inst.kind.extractvalue;
                    if (types(extract.aggregate_ty)) |members| {
                        const part = index(extract.indices) orelse return null;
                        if (!extract.result_ty.eql(members[part])) return null;
                        const value = leaf(names, extract.aggregate, extract.aggregate_ty, part) orelse return null;
                        try alias(allocator, function, &serial, &block, inst.result, members[part], value, inst.metadata);
                        continue;
                    }
                }
                if (inst.result) |name| if (names.get(name)) |entry| {
                    const members = types(entry.ty).?;
                    if (!entry.transport) {
                        try block.instructions.append(allocator, inst);
                        for (members, 0..) |ty, part| try block.instructions.append(allocator, .{ .result = entry.parts[part], .kind = .{ .extractvalue = .{
                            .aggregate_ty = entry.ty,
                            .aggregate = .{ .named = name },
                            .indices = if (part == 0) "0" else "1",
                            .result_ty = ty,
                        } } });
                    } else for (members, 0..) |ty, part| {
                        var copy = inst;
                        copy.result = entry.parts[part];
                        switch (copy.kind) {
                            .phi => |*phi| {
                                phi.ty = ty;
                                phi.incoming = try inst.kind.phi.incoming.clone(allocator);
                                for (phi.incoming.items) |*incoming| incoming.value = leaf(names, incoming.value, entry.ty, part) orelse return null;
                            },
                            .select => |*select| {
                                select.ty = ty;
                                select.true_value = leaf(names, select.true_value, entry.ty, part) orelse return null;
                                select.false_value = leaf(names, select.false_value, entry.ty, part) orelse return null;
                            },
                            .freeze => |*freeze| {
                                freeze.ty = ty;
                                freeze.value = leaf(names, freeze.value, entry.ty, part) orelse return null;
                                if (freeze.value != .named) {
                                    const scalar = try forms.temporary(allocator, function, &serial);
                                    try alias(allocator, function, &serial, &block, scalar, ty, freeze.value, null);
                                    freeze.value = .{ .named = scalar };
                                }
                            },
                            .insertvalue => |insert| {
                                const which = index(insert.indices) orelse return null;
                                if (!insert.value_ty.eql(members[which])) return null;
                                const value = if (part == which) insert.value else leaf(names, insert.aggregate, entry.ty, part) orelse return null;
                                try alias(allocator, function, &serial, &block, copy.result, ty, value, inst.metadata);
                                continue;
                            },
                            else => unreachable,
                        }
                        try block.instructions.append(allocator, copy);
                    }
                    continue;
                };
            }
            try block.instructions.append(allocator, inst);
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
