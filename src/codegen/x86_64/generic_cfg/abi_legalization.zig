const std = @import("std");
const ir = @import("../../../ir.zig");
const layout = @import("../../../zig_air_type_layout.zig");
const uses = @import("stage2_planning.zig");

const wide: ir.Type = .{ .int = 128 };
const limb: ir.Type = .{ .int = 64 };

fn definition(function: ir.Function, name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| for (block.instructions.items) |instruction| {
        if (!instruction.removed and instruction.result != null and std.mem.eql(u8, instruction.result.?, name)) return instruction;
    };
    return null;
}

fn field(insert: ir.InsertValueInst) ?u1 {
    if (!insert.value_ty.eql(limb)) return null;
    if (std.mem.eql(u8, insert.indices, "0")) return 0;
    if (std.mem.eql(u8, insert.indices, "1")) return 1;
    return null;
}

fn constructor(function: ir.Function, instruction: ir.Instruction) bool {
    if (instruction.kind != .insertvalue) return false;
    const insert = instruction.kind.insertvalue;
    if (!insert.aggregate_ty.eql(function.ret_ty)) return false;
    const index = field(insert) orelse return false;
    if (insert.aggregate == .undef or insert.aggregate == .poison) return true;
    if (insert.aggregate != .named) return false;
    const previous = definition(function, insert.aggregate.named) orelse return false;
    if (previous.kind != .insertvalue) return false;
    const other = previous.kind.insertvalue;
    return other.aggregate_ty.eql(function.ret_ty) and field(other) != null and field(other).? != index and
        (other.aggregate == .undef or other.aggregate == .poison);
}

fn temporary(allocator: std.mem.Allocator, function: ir.Function, serial: *usize) ![]const u8 {
    while (true) {
        const name = try std.fmt.allocPrint(allocator, "__zllvm_return_limb_{d}", .{serial.*});
        serial.* += 1;
        if (definition(function, name) != null) continue;
        var collision = false;
        for (function.params.items) |param| if (std.mem.eql(u8, param.name, name)) {
            collision = true;
        };
        if (!collision) return name;
    }
}

// The caller owns an arena. Nested operand lists borrow the original immutable
// function; only block/instruction records and synthetic names are allocated.
// SysV returns {i64,i64} and i128 in the same RAX/RDX pair on x86_64 Linux.
// Legalize only constructors used by returns or by the next constructor.
pub fn integerPair(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    if (function.ret_ty != .aggregate or layout.fieldCount(function.ret_ty) != 2 or
        !(layout.fieldType(function.ret_ty, 0) orelse return null).eql(limb) or
        !(layout.fieldType(function.ret_ty, 1) orelse return null).eql(limb)) return null;
    var needs_composition = function.blocks.items.len > 1;
    for (function.params.items) |param| if (param.ty == .aggregate) return null;
    var constructors: usize = 0;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.resultType()) |ty| {
                if (ty.eql(wide)) needs_composition = true;
                if (!ty.eql(function.ret_ty)) continue;
                if (!constructor(function, instruction)) return null;
                const name = instruction.result orelse return null;
                constructors += 1;
                for (function.blocks.items) |user_block| {
                    for (user_block.instructions.items) |user| {
                        if (user.removed or !try uses.instructionUsesName(allocator, user, name)) continue;
                        if (user.kind != .insertvalue or !user.kind.insertvalue.aggregate_ty.eql(function.ret_ty) or
                            user.kind.insertvalue.aggregate != .named or !std.mem.eql(u8, user.kind.insertvalue.aggregate.named, name)) return null;
                    }
                    if (user_block.terminator) |term| {
                        if (!try uses.terminatorUsesName(allocator, term, name)) continue;
                        if (term != .ret or !term.ret.ty.eql(function.ret_ty)) return null;
                    }
                }
            }
        }
        if (block.terminator) |term| if (term == .ret) {
            if (!term.ret.ty.eql(function.ret_ty) or term.ret.value == null or term.ret.value.? != .named) return null;
            if (!constructor(function, definition(function, term.ret.value.?.named) orelse return null)) return null;
        };
    }
    if (!needs_composition or constructors == 0) return null;
    var result = function;
    result.ret_ty = wide;
    result.blocks = .empty;
    var serial: usize = 0;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |instruction| {
            if (instruction.removed or instruction.kind != .insertvalue or !instruction.kind.insertvalue.aggregate_ty.eql(function.ret_ty)) {
                try block.instructions.append(allocator, instruction);
                continue;
            }
            const insert = instruction.kind.insertvalue;
            const index = field(insert).?;
            const first = insert.aggregate == .undef or insert.aggregate == .poison;
            const extension = if (first and index == 0) instruction.result.? else try temporary(allocator, function, &serial);
            try block.instructions.append(allocator, .{ .result = extension, .kind = .{ .cast = .{
                .op = .zext,
                .from_ty = limb,
                .value = insert.value,
                .to_ty = wide,
            } } });
            var value: ir.Value = .{ .named = extension };
            if (index == 1) {
                const shifted = if (first) instruction.result.? else try temporary(allocator, function, &serial);
                try block.instructions.append(allocator, .{ .result = shifted, .kind = .{ .binary = .{
                    .op = .shl,
                    .ty = wide,
                    .lhs = value,
                    .rhs = .{ .int = 64 },
                } } });
                value = .{ .named = shifted };
            }
            if (!first) try block.instructions.append(allocator, .{ .result = instruction.result, .kind = .{ .binary = .{
                .op = .@"or",
                .ty = wide,
                .lhs = insert.aggregate,
                .rhs = value,
            } } });
        }
        if (block.terminator) |*term| if (term.* == .ret) {
            term.ret.ty = wide;
        };
        try result.blocks.append(allocator, block);
    }
    return result;
}

// Zig's baseline C ABI can carry an f16 payload in a double-width XMM value.
// Its direct, aligned temporary contains 16 defined payload bits and unspecified
// upper padding. Choose zero padding and make the carrier slot explicitly wide.
// This is a private codegen view; escaping or barrier accesses are declined.
pub fn paddedHalf(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var slots = std.StringHashMap(void).init(allocator);
    for (function.blocks.items) |block| for (block.instructions.items) |instruction| {
        if (instruction.removed or instruction.kind != .alloca or instruction.kind.alloca.allocated_ty != .half) continue;
        const alloca = instruction.kind.alloca;
        if (!alloca.isSingleObject() or alloca.allocated_ty_addrspace != null) continue;
        const attrs = alloca.attrs orelse continue;
        const start = std.mem.indexOf(u8, attrs, "align ") orelse continue;
        var end = start + "align ".len;
        while (end < attrs.len and std.ascii.isDigit(attrs[end])) : (end += 1) {}
        const alignment = std.fmt.parseUnsigned(u32, attrs[start + "align ".len .. end], 10) catch continue;
        if (alignment < 8) continue;
        const name = instruction.result orelse continue;
        var carrier_read = false;
        var valid = true;
        for (function.blocks.items) |user_block| {
            for (user_block.instructions.items) |user| {
                if (user.removed or !try uses.instructionUsesName(allocator, user, name)) continue;
                switch (user.kind) {
                    .load => |load| {
                        if (load.ty != .double or load.attrs.isBarrier() or load.ty_addrspace != null or load.ptr_addrspace != null or
                            load.ptr != .named or !std.mem.eql(u8, load.ptr.named, name)) valid = false;
                        carrier_read = true;
                    },
                    .store => |store| {
                        if ((!store.ty.eql(.{ .int = 16 }) and store.ty != .half) or store.attrs.isBarrier() or store.ty_addrspace != null or store.ptr_addrspace != null or
                            store.ptr != .named or !std.mem.eql(u8, store.ptr.named, name)) valid = false;
                    },
                    else => valid = false,
                }
            }
            if (user_block.terminator) |term| if (try uses.terminatorUsesName(allocator, term, name)) {
                valid = false;
            };
        }
        if (valid and carrier_read) try slots.put(name, {});
    };
    if (slots.count() == 0) return null;
    var result = function;
    result.blocks = .empty;
    var serial: usize = 0;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |instruction| {
            var copy = instruction;
            if (!copy.removed and copy.kind == .alloca and copy.result != null and slots.contains(copy.result.?)) {
                copy.kind.alloca.allocated_ty = .double;
            } else if (!copy.removed and copy.kind == .store and copy.kind.store.ptr == .named and slots.contains(copy.kind.store.ptr.named)) {
                const store = copy.kind.store;
                var bits = store.value;
                if (store.ty == .half) {
                    const name = try temporary(allocator, function, &serial);
                    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .cast = .{
                        .op = .bitcast,
                        .from_ty = .half,
                        .value = bits,
                        .to_ty = .{ .int = 16 },
                    } } });
                    bits = .{ .named = name };
                }
                const extended = try temporary(allocator, function, &serial);
                try block.instructions.append(allocator, .{ .result = extended, .kind = .{ .cast = .{
                    .op = .zext,
                    .from_ty = .{ .int = 16 },
                    .value = bits,
                    .to_ty = limb,
                } } });
                const carrier = try temporary(allocator, function, &serial);
                try block.instructions.append(allocator, .{ .result = carrier, .kind = .{ .cast = .{
                    .op = .bitcast,
                    .from_ty = limb,
                    .value = .{ .named = extended },
                    .to_ty = .double,
                } } });
                copy.kind.store.ty = .double;
                copy.kind.store.value = .{ .named = carrier };
            }
            try block.instructions.append(allocator, copy);
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
