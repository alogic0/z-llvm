//! Private codegen legalization for two-word stack objects. Use the existing
//! 128-bit frame object and scalar address actions; do not change the source IR
//! or its ABI. LLVM's SelectionDAG splits aggregate memory operations similarly.
const std = @import("std");
const ir = @import("../../../ir.zig");
const target = @import("../../../target.zig");
const machine = @import("../machine.zig");
const uses = @import("stage2_planning.zig");
const addresses = @import("../symbol_address.zig");

const word: ir.Type = .{ .int = 64 };

fn pairTypes(context: ?*const machine.ReadOnlyModuleContext, ty: ir.Type, depth: u8) ?[2]ir.Type {
    if (depth >= 8 or ty != .aggregate) return null;
    const body = std.mem.trim(u8, ty.aggregate, " \t");
    if (std.mem.startsWith(u8, body, "%")) {
        const ctx = context orelse return null;
        var definition_body: ?[]const u8 = null;
        for (ctx.named_types) |named| {
            if (ir.identifiers.eql(named.name, body[1..])) {
                if (definition_body != null) return null;
                definition_body = named.body;
            }
        }
        return pairTypes(context, .{ .aggregate = definition_body orelse return null }, depth + 1);
    }
    // Match the complete field list. A field-count helper can stop at an
    // unresolved trailing named field, which must never shrink an allocation.
    if (spelling(body, "{ptr,i64}")) return .{ .ptr, word };
    if (spelling(body, "{i64,i64}")) return .{ word, word };
    if (body.len < 2 or body[0] != '{' or body[body.len - 1] != '}') return null;
    const inner = std.mem.trim(u8, body[1 .. body.len - 1], " \t");
    if (!std.mem.startsWith(u8, inner, "{") and !std.mem.startsWith(u8, inner, "%")) return null;
    return pairTypes(context, .{ .aggregate = inner }, depth + 1);
}

pub fn spelling(body: []const u8, expected: []const u8) bool {
    var index: usize = 0;
    for (body) |c| {
        if (std.ascii.isWhitespace(c)) continue;
        if (index >= expected.len or expected[index] != c) return false;
        index += 1;
    }
    return index == expected.len;
}

pub fn isIntegerPair(context: ?*const machine.ReadOnlyModuleContext, ty: ir.Type) bool {
    const fields = pairTypes(context, ty, 0) orelse return false;
    return fields[0].eql(word) and fields[1].eql(word);
}

pub fn supportsLayout(context: ?*const machine.ReadOnlyModuleContext) bool {
    const text = if (context) |ctx| ctx.target_datalayout else null;
    if (text) |explicit| if (explicit.len == 0 or explicit[0] != 'e') return false;
    if (!addresses.supportsLayout(text)) return false;
    const dl = target.DataLayout.parse(text orelse "") catch return false;
    if ((dl.integerAbiAlignmentBits(64) catch return false) != 64) return false;
    // Stronger aggregate ABI alignment can change the allocation size, including
    // transparent wrappers. It is outside this fixed native storage envelope.
    var parts = std.mem.splitScalar(u8, text orelse "", '-');
    while (parts.next()) |part| {
        if (!std.mem.startsWith(u8, part, "a:")) continue;
        var fields = std.mem.splitScalar(u8, part[2..], ':');
        const alignment = std.fmt.parseUnsigned(u16, fields.next() orelse return false, 10) catch return false;
        if (alignment > 64 or (alignment != 0 and !std.math.isPowerOfTwo(alignment))) return false;
        if (fields.next()) |preferred_text| {
            const preferred = std.fmt.parseUnsigned(u16, preferred_text, 10) catch return false;
            if (preferred < alignment or (preferred != 0 and !std.math.isPowerOfTwo(preferred))) return false;
        }
        if (fields.next() != null) return false;
    }
    return true;
}

test "pair storage rejects padding unresolved tails arrays packing and other address spaces" {
    try std.testing.expect(pairTypes(null, .{ .aggregate = "{ { ptr, i64 } }" }, 0) != null);
    try std.testing.expect(isIntegerPair(null, .{ .aggregate = "{ { i64, i64 } }" }));
    for ([_][]const u8{
        "{ ptr, i64, %Unknown }", "{ ptr, i64, i8 }",     "{ ptr, i32 }",
        "<{ ptr, i64 }>",         "[2 x i64]",            "{ ptr addrspace(1), i64 }",
        "{ float, float }",       "{ { ptr, i64 }, i8 }", "%Unresolved",
        "{ ptr, ptr }",           "{ i64, ptr }",         "{ i64, i64, %Unknown }",
    }) |text| try std.testing.expect(pairTypes(null, .{ .aggregate = text }, 0) == null);
}

fn definition(function: ir.Function, name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.result != null and ir.identifiers.eql(inst.result.?, name)) return inst;
    };
    return null;
}

fn fieldIndex(text: []const u8) ?usize {
    if (std.mem.eql(u8, text, "0")) return 0;
    if (std.mem.eql(u8, text, "1")) return 1;
    return null;
}

fn leaf(function: ir.Function, value: ir.Value, ty: ir.Type, index: usize, depth: u8) ?ir.Value {
    if (depth >= 64 or value != .named) return null;
    const inst = definition(function, value.named) orelse return null;
    if (inst.kind != .insertvalue or !inst.kind.insertvalue.aggregate_ty.eql(ty)) return null;
    const insert = inst.kind.insertvalue;
    const field = fieldIndex(insert.indices) orelse return null;
    if (field == index) return insert.value;
    return leaf(function, insert.aggregate, ty, index, depth + 1);
}

fn temporary(allocator: std.mem.Allocator, function: ir.Function, serial: *usize) ![]const u8 {
    while (true) {
        const name = try std.fmt.allocPrint(allocator, "__zllvm_word_pair_{d}", .{serial.*});
        serial.* += 1;
        if (definition(function, name) != null) continue;
        var collision = false;
        for (function.params.items) |param| if (ir.identifiers.eql(param.name, name)) {
            collision = true;
        };
        if (!collision) return name;
    }
}

fn address(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *usize, ptr: ir.Value, offset: usize, result: ?[]const u8) !ir.Value {
    const name = result orelse try temporary(allocator, function, serial);
    var indices: std.ArrayList(ir.GepIndex) = .empty;
    try indices.append(allocator, .{ .ty = word, .value = .{ .int = @intCast(offset) } });
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = ptr, .indices = indices } } });
    return .{ .named = name };
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!supportsLayout(context)) return null;
    var slots = std.StringHashMap(void).init(allocator);
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.kind != .alloca or inst.result == null) continue;
        const alloca = inst.kind.alloca;
        if (pairTypes(context, alloca.allocated_ty, 0) == null or !alloca.isSingleObject() or alloca.allocated_ty_addrspace != null) continue;
        if (alloca.attrs) |attrs| {
            var fields = std.mem.splitScalar(u8, attrs, ',');
            while (fields.next()) |raw| {
                const attr = std.mem.trim(u8, raw, " \t");
                if (!std.mem.startsWith(u8, attr, "align ")) return null;
                const alignment = std.fmt.parseUnsigned(u32, attr[6..], 10) catch return null;
                if (alignment == 0 or alignment > 16 or !std.math.isPowerOfTwo(alignment)) return null;
            }
        }
        try slots.put(inst.result.?, {});
    };
    if (slots.count() == 0) return null;

    // Only complete scalar constructors with consumers we can legalize. In
    // particular, keep volatile/atomic stores, aggregate calls/returns, PHIs,
    // loads, vectors, padding and unresolved definitions at their boundaries.
    var constructors = std.StringHashMap(void).init(allocator);
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.kind != .insertvalue or pairTypes(context, inst.kind.insertvalue.aggregate_ty, 0) == null) continue;
        const insert = inst.kind.insertvalue;
        const types = pairTypes(context, insert.aggregate_ty, 0).?;
        const index = fieldIndex(insert.indices) orelse return null;
        if (!insert.value_ty.eql(types[index])) return null;
        try constructors.put(inst.result orelse return null, {});
    };
    var iterator = constructors.keyIterator();
    while (iterator.next()) |name| {
        for (function.blocks.items) |block| {
            for (block.instructions.items) |inst| {
                if (inst.removed or !try uses.instructionUsesName(allocator, inst, name.*)) continue;
                switch (inst.kind) {
                    .insertvalue => |insert| if (insert.aggregate != .named or !std.mem.eql(u8, insert.aggregate.named, name.*) or !constructors.contains(inst.result orelse return null)) return null,
                    .extractvalue => |extract| {
                        const index = fieldIndex(extract.indices) orelse return null;
                        if (extract.aggregate != .named or !std.mem.eql(u8, extract.aggregate.named, name.*) or leaf(function, extract.aggregate, extract.aggregate_ty, index, 0) == null) return null;
                    },
                    .store => |store| {
                        if (store.value != .named or !std.mem.eql(u8, store.value.named, name.*) or store.ptr == .named and std.mem.eql(u8, store.ptr.named, name.*) or
                            store.attrs.isBarrier() or store.attrs.syncscope != null or store.ty_addrspace != null or store.ptr_addrspace != null or
                            leaf(function, store.value, store.ty, 0, 0) == null or leaf(function, store.value, store.ty, 1, 0) == null) return null;
                    },
                    else => return null,
                }
            }
            if (block.terminator) |term| if (try uses.terminatorUsesName(allocator, term, name.*)) return null;
        }
    }

    var result = function;
    result.blocks = .empty;
    var serial: usize = 0;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (!inst.removed and inst.result != null and constructors.contains(inst.result.?)) continue;
            if (!inst.removed and inst.kind == .alloca and inst.result != null and slots.contains(inst.result.?)) {
                copy.kind.alloca.allocated_ty = .{ .int = 128 };
            } else if (!inst.removed and inst.kind == .load and inst.kind.load.ptr == .named and
                slots.contains(inst.kind.load.ptr.named) and (inst.kind.load.ty == .ptr or inst.kind.load.ty.eql(word)))
            {
                copy.kind.load.ptr = try address(allocator, function, &block, &serial, inst.kind.load.ptr, 0, null);
            } else if (!inst.removed and inst.kind == .extractvalue and inst.kind.extractvalue.aggregate == .named and constructors.contains(inst.kind.extractvalue.aggregate.named)) {
                const extract = inst.kind.extractvalue;
                const index = fieldIndex(extract.indices).?;
                const value = leaf(function, extract.aggregate, extract.aggregate_ty, index, 0).?;
                const ty = pairTypes(context, extract.aggregate_ty, 0).?[index];
                if (ty == .ptr) {
                    _ = try address(allocator, function, &block, &serial, value, 0, inst.result);
                } else try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .binary = .{ .op = .add, .ty = word, .lhs = value, .rhs = .{ .int = 0 } } } });
                continue;
            } else if (!inst.removed and inst.kind == .store and inst.kind.store.value == .named and constructors.contains(inst.kind.store.value.named)) {
                const store = inst.kind.store;
                const types = pairTypes(context, store.ty, 0).?;
                for (types, 0..) |ty, index| {
                    const ptr = try address(allocator, function, &block, &serial, store.ptr, index * 8, null);
                    var scalar = store;
                    scalar.ty = ty;
                    scalar.ptr = ptr;
                    scalar.value = leaf(function, store.value, store.ty, index, 0).?;
                    if (scalar.attrs.@"align") |alignment| scalar.attrs.@"align" = @min(alignment, 8);
                    try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = scalar } });
                }
                continue;
            } else if (!inst.removed and inst.kind == .store and inst.kind.store.ptr == .named and
                slots.contains(inst.kind.store.ptr.named) and (inst.kind.store.ty == .ptr or inst.kind.store.ty.eql(word)))
            {
                copy.kind.store.ptr = try address(allocator, function, &block, &serial, inst.kind.store.ptr, 0, null);
            } else if (!inst.removed and inst.kind == .call and
                (std.mem.eql(u8, inst.kind.call.callee, "llvm.memcpy.p0.p0.i64") or
                    std.mem.eql(u8, inst.kind.call.callee, "llvm.memcpy.inline.p0.p0.i64")))
            {
                // The existing memcpy action takes pointer values. Materialize
                // frame-object addresses through the existing byte-address
                // action, cloning the nested argument list before rewriting it.
                var copied = false;
                for (inst.kind.call.args.items, 0..) |arg, index| {
                    if (index >= 2 or arg.value != .named or !slots.contains(arg.value.named)) continue;
                    if (!copied) {
                        copy = try inst.clone(allocator);
                        copied = true;
                    }
                    copy.kind.call.args.items[index].value = try address(allocator, function, &block, &serial, arg.value, 0, null);
                }
                if (copied and copy.kind.call.args.items.len == 4 and copy.kind.call.args.items[2].value == .int) {
                    const length = copy.kind.call.args.items[2].value;
                    if (length.int < 0 or length.int > 16) return null;
                    const name = try temporary(allocator, function, &serial);
                    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .cast = .{
                        .op = .zext,
                        .from_ty = .{ .int = 32 },
                        .value = length,
                        .to_ty = word,
                    } } });
                    copy.kind.call.args.items[2].value = .{ .named = name };
                }
            }
            try block.instructions.append(allocator, copy);
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
