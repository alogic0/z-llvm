//! Large memory-only integer values use private, canonical byte snapshots.
//! No large integer arithmetic, PHI, return or argument authority is added.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const raw = @import("../../../ir/wide_integers.zig");
const forms = @import("scalar_forms.zig");
const Snapshot = struct { bits: u32, pointer: ir.Value };
const Values = std.HashMap([]const u8, Snapshot, ir.identifiers.Context, 80);
fn width(ty: ir.Type) ?u32 {
    const bits = if (ty == .vector and ty.vector.len == 1 and ty.vector.elem_ty == .int) ty.vector.elem_ty.int else raw.width(ty) orelse return null;
    return if (bits > 1024 and bits <= raw.max_bits) bits else null;
}
fn bytes(bits: u32) u32 {
    return (bits + 7) / 8;
}
fn resultWidth(inst: ir.Instruction) ?u32 {
    return width(inst.resultType() orelse return null);
}
const Touched = struct {
    pub const Error = error{};
    found: *bool,
    pub fn visit(state: Touched, _: *const ir.Value, ty: ir.Type) Error!void {
        state.found.* = state.found.* or width(ty) != null;
    }
};
fn touches(inst: ir.Instruction) bool {
    var found = resultWidth(inst) != null;
    _ = ir.operands.instruction(&inst, Touched{ .found = &found }) catch unreachable;
    if (inst.kind == .alloca) found = found or width(inst.kind.alloca.allocated_ty) != null;
    if (inst.kind == .gep) found = found or width(inst.kind.gep.source_ty) != null;
    return found;
}
fn intrinsic(context: *const machine.ReadOnlyModuleContext, name: []const u8, types: []const ir.Type) bool {
    for (context.functions) |function| if (ir.identifiers.eql(function.name, name)) return false;
    for (context.aliases) |alias| if (ir.identifiers.eql(alias.name, name)) return false;
    if (context.findGlobal(name) != null) return false;
    var found = false;
    for (context.declarations) |declaration| if (ir.identifiers.eql(declaration.name, name)) {
        if (found or declaration.ret_ty != .void or declaration.ret_attrs != null or declaration.calling_conv != null or declaration.is_varargs or declaration.params.items.len != types.len) return false;
        if (declaration.linkage != .default and declaration.linkage != .external) return false;
        for (declaration.params.items, types) |param, ty| {
            if (!param.ty.eql(ty)) return false;
            var tokens = std.mem.tokenizeAny(u8, param.attrs orelse "", " \t\r\n");
            while (tokens.next()) |token| {
                if (!std.mem.eql(u8, token, "noalias") and !std.mem.eql(u8, token, "nocapture") and !std.mem.eql(u8, token, "readonly") and !std.mem.eql(u8, token, "writeonly") and !std.mem.eql(u8, token, "noundef") and !std.mem.eql(u8, token, "immarg") and !std.mem.eql(u8, token, "captures(none)")) return false;
            }
        }
        found = true;
    };
    return found;
}
const Builder = struct {
    a: std.mem.Allocator,
    function: ir.Function,
    names: *forms.TemporaryNames,
    prefixes: *std.ArrayList(ir.Instruction),
    block: *ir.BasicBlock,
    values: *Values,
    allocations: *usize,
    blocks: *std.ArrayList(ir.BasicBlock),
    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.a, b.function, b.names);
        try b.block.instructions.append(b.a, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn binary(b: Builder, op: ir.BinaryOp, lhs: ir.Value, rhs: ir.Value) !ir.Value {
        return b.emit(.{ .binary = .{ .op = op, .ty = .{ .int = 64 }, .lhs = lhs, .rhs = rhs } });
    }
    fn cast(b: Builder, op: ir.CastOp, from: ir.Type, value: ir.Value, to: ir.Type) !ir.Value {
        return b.emit(.{ .cast = .{ .op = op, .from_ty = from, .value = value, .to_ty = to } });
    }
    fn address(b: Builder, pointer: ir.Value, offset: u32) !ir.Value {
        return b.addressValue(pointer, .{ .int = offset });
    }
    fn addressValue(b: Builder, pointer: ir.Value, offset: ir.Value) !ir.Value {
        var indices: std.ArrayList(ir.GepIndex) = .empty;
        try indices.append(b.a, .{ .ty = .{ .int = 64 }, .value = offset });
        return b.emit(.{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = pointer, .indices = indices } });
    }
    fn allocate(b: Builder, bits: u32) !Snapshot {
        if (b.allocations.* == 64) return error.UnsupportedMemoryBytes;
        b.allocations.* += 1;
        const name = try forms.temporary(b.a, b.function, b.names);
        try b.prefixes.append(b.a, .{ .result = name, .kind = .{ .alloca = .{ .allocated_ty = .{ .aggregate = try std.fmt.allocPrint(b.a, "[{d} x i32]", .{((bytes(bits) + 7) / 8) * 2}) }, .attrs = "align 16" } } });
        return .{ .bits = bits, .pointer = .{ .named = name } };
    }
    fn copy(b: Builder, destination_pointer: ir.Value, source: ir.Value, length: u32) !void {
        var call: ir.CallInst = .{ .ret_ty = .void, .callee = "llvm.memcpy.p0.p0.i64", .args = .empty };
        try call.args.appendSlice(b.a, &.{ .{ .ty = .ptr, .value = destination_pointer }, .{ .ty = .ptr, .value = source }, .{ .ty = .{ .int = 64 }, .value = .{ .int = length } }, .{ .ty = .{ .int = 1 }, .value = .{ .int = 0 } } });
        try b.block.instructions.append(b.a, .{ .result = null, .kind = .{ .call = call } });
    }
    fn fill(b: Builder, destination_pointer: ir.Value, byte: i128, length: u32) !void {
        var call: ir.CallInst = .{ .ret_ty = .void, .callee = "llvm.memset.p0.i64", .args = .empty };
        try call.args.appendSlice(b.a, &.{ .{ .ty = .ptr, .value = destination_pointer }, .{ .ty = .{ .int = 8 }, .value = .{ .int = byte } }, .{ .ty = .{ .int = 64 }, .value = .{ .int = length } }, .{ .ty = .{ .int = 1 }, .value = .{ .int = 0 } } });
        try b.block.instructions.append(b.a, .{ .result = null, .kind = .{ .call = call } });
    }
    fn mask(b: Builder, snapshot: Snapshot) !void {
        if (snapshot.bits % 8 == 0) return;
        const pointer = try b.address(snapshot.pointer, bytes(snapshot.bits) - 1);
        const last = try b.emit(.{ .load = .{ .ty = .{ .int = 8 }, .ptr = pointer, .attrs = .{ .@"align" = 1 } } });
        const value = try b.binary(.@"and", try b.cast(.zext, .{ .int = 8 }, last, .{ .int = 64 }), .{ .int = (@as(i128, 1) << @as(u7, @intCast(snapshot.bits % 8))) - 1 });
        try b.block.instructions.append(b.a, .{ .result = null, .kind = .{ .store = .{ .ty = .{ .int = 8 }, .value = try b.cast(.trunc, .{ .int = 64 }, value, .{ .int = 8 }), .ptr = pointer, .attrs = .{ .@"align" = 1 } } } });
    }
    fn get(b: Builder, value: ir.Value, ty: ir.Type) !Snapshot {
        const bits = width(ty) orelse return error.UnsupportedMemoryBytes;
        if (value == .named) {
            const found = b.values.get(value.named) orelse return error.UnsupportedMemoryBytes;
            if (found.bits != bits) return error.UnsupportedMemoryBytes;
            return found;
        }
        const words = raw.decode(b.a, bits, value) catch |err| switch (err) {
            error.OutOfMemory => return err,
            else => return error.UnsupportedMemoryBytes,
        };
        defer b.a.free(words);
        const snapshot = try b.allocate(bits);
        var ones = true;
        for (words[0 .. words.len - 1]) |word| if (word != std.math.maxInt(u64)) {
            ones = false;
            break;
        };
        const background: u64 = if (ones) std.math.maxInt(u64) else 0;
        try b.fill(snapshot.pointer, if (ones) -1 else 0, @intCast(words.len * 8));
        for (words, 0..) |word, index| if (word != background) {
            try b.block.instructions.append(b.a, .{ .result = null, .kind = .{ .store = .{ .ty = .{ .int = 64 }, .value = .{ .int = word }, .ptr = try b.address(snapshot.pointer, @intCast(index * 8)), .attrs = .{ .@"align" = 1 } } } });
        };
        return snapshot;
    }
    fn destination(b: Builder, inst: ir.Instruction) !Snapshot {
        return b.values.get(inst.result orelse return error.UnsupportedMemoryBytes) orelse error.UnsupportedMemoryBytes;
    }
    fn object(b: Builder, inst: ir.Instruction, bits: u32) !void {
        const allocation = inst.kind.alloca;
        if (!allocation.isSingleObject() or allocation.allocated_ty_addrspace != null) return error.UnsupportedMemoryBytes;
        var alignment = try std.math.ceilPowerOfTwo(u32, bytes(bits));
        if (allocation.attrs) |attrs| {
            const text = std.mem.trim(u8, attrs, " \t\r\n");
            if (!std.mem.startsWith(u8, text, "align ")) return error.UnsupportedMemoryBytes;
            const explicit = std.fmt.parseUnsigned(u32, text[6..], 10) catch return error.UnsupportedMemoryBytes;
            if (explicit == 0 or explicit > 8192 or !std.math.isPowerOfTwo(explicit)) return error.UnsupportedMemoryBytes;
            alignment = @max(alignment, explicit);
        }
        const reserved = std.math.add(u32, bytes(bits), alignment - 1) catch return error.UnsupportedMemoryBytes;
        if (reserved > 65536) return error.UnsupportedMemoryBytes;
        const backing = try forms.temporary(b.a, b.function, b.names);
        try b.block.instructions.append(b.a, .{ .result = backing, .kind = .{ .alloca = .{ .allocated_ty = .{ .aggregate = try std.fmt.allocPrint(b.a, "[{d} x i32]", .{(reserved + 3) / 4}) }, .attrs = "align 16" } } });
        const base = try b.cast(.ptrtoint, .ptr, try b.address(.{ .named = backing }, 0), .{ .int = 64 });
        const aligned = try b.binary(.@"and", try b.binary(.add, base, .{ .int = alignment - 1 }), .{ .int = -@as(i128, alignment) });
        var view = inst;
        view.kind = .{ .cast = .{ .op = .inttoptr, .from_ty = .{ .int = 64 }, .value = aligned, .to_ty = .ptr } };
        try b.block.instructions.append(b.a, view);
    }
    fn compare(b: Builder, inst: ir.Instruction) !void {
        const comparison = inst.kind.icmp;
        if (comparison.predicate != .eq and comparison.predicate != .ne) return error.UnsupportedMemoryBytes;
        const lhs = try b.get(comparison.lhs, comparison.operand_ty);
        const rhs = try b.get(comparison.rhs, comparison.operand_ty);
        const loop_name = try forms.temporary(b.a, b.function, b.names);
        const exit_name = try forms.temporary(b.a, b.function, b.names);
        const index_name = try forms.temporary(b.a, b.function, b.names);
        const next_name = try forms.temporary(b.a, b.function, b.names);
        const accumulator_name = try forms.temporary(b.a, b.function, b.names);
        const updated_name = try forms.temporary(b.a, b.function, b.names);
        const original_exit = b.block.terminator;
        const previous_name = b.block.name;
        b.block.terminator = .{ .br = .{ .target = loop_name } };
        try b.blocks.append(b.a, b.block.*);
        b.block.* = .{ .name = loop_name, .instructions = .empty, .terminator = null };
        var index_incoming: std.ArrayList(ir.PhiIncoming) = .empty;
        try index_incoming.appendSlice(b.a, &.{ .{ .value = .{ .int = 0 }, .block = previous_name }, .{ .value = .{ .named = next_name }, .block = loop_name } });
        var sum_incoming: std.ArrayList(ir.PhiIncoming) = .empty;
        try sum_incoming.appendSlice(b.a, &.{ .{ .value = .{ .int = 0 }, .block = previous_name }, .{ .value = .{ .named = updated_name }, .block = loop_name } });
        try b.block.instructions.appendSlice(b.a, &.{ .{ .result = index_name, .kind = .{ .phi = .{ .ty = .{ .int = 64 }, .incoming = index_incoming } } }, .{ .result = accumulator_name, .kind = .{ .phi = .{ .ty = .{ .int = 64 }, .incoming = sum_incoming } } } });
        const x_word = try b.emit(.{ .load = .{ .ty = .{ .int = 64 }, .ptr = try b.addressValue(lhs.pointer, .{ .named = index_name }), .attrs = .{ .@"align" = 1 } } });
        const y_word = try b.emit(.{ .load = .{ .ty = .{ .int = 64 }, .ptr = try b.addressValue(rhs.pointer, .{ .named = index_name }), .attrs = .{ .@"align" = 1 } } });
        const difference = try b.binary(.xor, x_word, y_word);
        try b.block.instructions.append(b.a, .{ .result = updated_name, .kind = .{ .binary = .{ .op = .@"or", .ty = .{ .int = 64 }, .lhs = .{ .named = accumulator_name }, .rhs = difference } } });
        try b.block.instructions.append(b.a, .{ .result = next_name, .kind = .{ .binary = .{ .op = .add, .ty = .{ .int = 64 }, .lhs = .{ .named = index_name }, .rhs = .{ .int = 8 } } } });
        const repeated = try b.emit(.{ .icmp = .{ .predicate = .ult, .operand_ty = .{ .int = 64 }, .lhs = .{ .named = next_name }, .rhs = .{ .int = bytes(lhs.bits) / 8 * 8 } } });
        b.block.terminator = .{ .condbr = .{ .cond_ty = .{ .int = 1 }, .cond = repeated, .then_target = loop_name, .else_target = exit_name } };
        try b.blocks.append(b.a, b.block.*);
        b.block.* = .{ .name = exit_name, .instructions = .empty, .terminator = original_exit };
        var accumulator: ir.Value = .{ .named = updated_name };
        var offset: u32 = bytes(lhs.bits) / 8 * 8;
        while (offset < bytes(lhs.bits)) {
            const step: u32 = if (bytes(lhs.bits) - offset >= 8) 8 else 1;
            const ty: ir.Type = .{ .int = if (step == 8) 64 else 8 };
            const x = try b.emit(.{ .load = .{ .ty = ty, .ptr = try b.address(lhs.pointer, offset), .attrs = .{ .@"align" = 1 } } });
            const y = try b.emit(.{ .load = .{ .ty = ty, .ptr = try b.address(rhs.pointer, offset), .attrs = .{ .@"align" = 1 } } });
            const left = if (step == 8) x else try b.cast(.zext, ty, x, .{ .int = 64 });
            const right = if (step == 8) y else try b.cast(.zext, ty, y, .{ .int = 64 });
            accumulator = try b.binary(.@"or", accumulator, try b.binary(.xor, left, right));
            offset += step;
        }
        var comparison_instruction = inst;
        comparison_instruction.kind.icmp.operand_ty = .{ .int = 64 };
        comparison_instruction.kind.icmp.lhs = accumulator;
        comparison_instruction.kind.icmp.rhs = .{ .int = 0 };
        try b.block.instructions.append(b.a, comparison_instruction);
    }
};
pub fn legalize(a: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    return lower(a, function, context) catch |err| switch (err) {
        error.UnsupportedMemoryBytes => null,
        else => return err,
    };
}
fn lower(a: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (function.blocks.items.len == 0 or width(function.ret_ty) != null or function.is_varargs or !@import("composed_helpers.zig").isDefaultOrFastcc(function.calling_conv)) return null;
    for (function.params.items) |param| if (width(param.ty) != null) return null;
    if (!@import("../symbol_address.zig").supportsLayout(if (context) |ctx| ctx.target_datalayout else null)) return null;
    var needed = false;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| if (!inst.removed) {
        needed = needed or resultWidth(inst) != null or (inst.kind == .alloca and width(inst.kind.alloca.allocated_ty) != null) or (inst.kind == .store and width(inst.kind.store.ty) != null) or (inst.kind == .icmp and width(inst.kind.icmp.operand_ty) != null);
    };
    if (!needed) return null;
    const ctx = context orelse return null;
    if (!intrinsic(ctx, "llvm.memcpy.p0.p0.i64", &.{ .ptr, .ptr, .{ .int = 64 }, .{ .int = 1 } }) or
        !intrinsic(ctx, "llvm.memset.p0.i64", &.{ .ptr, .{ .int = 8 }, .{ .int = 64 }, .{ .int = 1 } })) return null;
    var names: forms.TemporaryNames = .{ .prefix = "__zllvm_byte_snapshot_" };
    defer names.deinit(a);
    var prefixes: std.ArrayList(ir.Instruction) = .empty;
    defer prefixes.deinit(a);
    var values = Values.init(a);
    defer values.deinit();
    var count: usize = 0;
    var dummy: ir.BasicBlock = .{ .name = "", .instructions = .empty, .terminator = null };
    var dummy_blocks: std.ArrayList(ir.BasicBlock) = .empty;
    const allocator_builder: Builder = .{ .a = a, .function = function, .names = &names, .prefixes = &prefixes, .block = &dummy, .values = &values, .allocations = &count, .blocks = &dummy_blocks };
    for (function.blocks.items) |block| for (block.instructions.items) |inst| if (!inst.removed) if (resultWidth(inst)) |bits| {
        if (inst.result) |name| try values.put(name, try allocator_builder.allocate(bits)) else return error.UnsupportedMemoryBytes;
    };
    var result = function;
    result.blocks = .empty;
    var exits = std.HashMap([]const u8, []const u8, ir.identifiers.Context, 80).init(a);
    defer exits.deinit();
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .a = a, .function = function, .names = &names, .prefixes = &prefixes, .block = &block, .values = &values, .allocations = &count, .blocks = &result.blocks };
        for (original.instructions.items) |inst| {
            if (inst.removed) {
                try block.instructions.append(a, inst);
                continue;
            }
            switch (inst.kind) {
                .alloca => |allocation| if (width(allocation.allocated_ty)) |bits| {
                    try b.object(inst, bits);
                    continue;
                },
                .load => |load| if (width(load.ty) != null) {
                    if (load.attrs.isBarrier() or load.attrs.syncscope != null or load.ty_addrspace != null or load.ptr_addrspace != null) return error.UnsupportedMemoryBytes;
                    const destination = try b.destination(inst);
                    try b.copy(destination.pointer, load.ptr, bytes(destination.bits));
                    try b.mask(destination);
                    continue;
                },
                .store => |store| if (width(store.ty) != null) {
                    if (store.attrs.isBarrier() or store.attrs.syncscope != null or store.ty_addrspace != null or store.ptr_addrspace != null) return error.UnsupportedMemoryBytes;
                    const source = try b.get(store.value, store.ty);
                    try b.copy(store.ptr, source.pointer, bytes(source.bits));
                    continue;
                },
                .cast => |cast| if (width(cast.from_ty) != null or width(cast.to_ty) != null) {
                    const from = width(cast.from_ty) orelse return error.UnsupportedMemoryBytes;
                    const to = width(cast.to_ty) orelse return error.UnsupportedMemoryBytes;
                    if ((cast.op != .trunc or from <= to) and (cast.op != .zext or from >= to) and (cast.op != .bitcast or from != to)) return error.UnsupportedMemoryBytes;
                    const source = try b.get(cast.value, cast.from_ty);
                    const destination = try b.destination(inst);
                    if (to > from) try b.fill(destination.pointer, 0, bytes(to));
                    try b.copy(destination.pointer, source.pointer, @min(bytes(from), bytes(to)));
                    try b.mask(destination);
                    continue;
                },
                .insertelement => |insert| if (width(insert.vector_ty) != null) {
                    if (insert.index != .int or insert.index.int != 0 or width(insert.value_ty) != width(insert.vector_ty)) return error.UnsupportedMemoryBytes;
                    const source = try b.get(insert.value, insert.value_ty);
                    const destination = try b.destination(inst);
                    try b.copy(destination.pointer, source.pointer, bytes(source.bits));
                    continue;
                },
                .extractelement => |extract| if (width(extract.vector_ty) != null) {
                    if (extract.index != .int or extract.index.int != 0) return error.UnsupportedMemoryBytes;
                    const source = try b.get(extract.vector, extract.vector_ty);
                    const destination = try b.destination(inst);
                    try b.copy(destination.pointer, source.pointer, bytes(source.bits));
                    continue;
                },
                .icmp => |comparison| if (width(comparison.operand_ty) != null) {
                    try b.compare(inst);
                    continue;
                },
                else => {},
            }
            if (touches(inst)) return error.UnsupportedMemoryBytes;
            try block.instructions.append(a, inst);
        }
        if (original.terminator) |term| {
            var touched = false;
            _ = ir.operands.terminator(&term, Touched{ .found = &touched }) catch unreachable;
            if (touched) return error.UnsupportedMemoryBytes;
        }
        try exits.put(original.name, block.name);
        try result.blocks.append(a, block);
    }
    // Splitting a predecessor moves its outgoing edge to the continuation.
    // Rewrite only original PHIs; the new loop PHIs use their own exact edges.
    for (result.blocks.items) |*block| if (exits.contains(block.name)) for (block.instructions.items) |*inst| if (inst.kind == .phi) {
        inst.kind.phi.incoming = try inst.kind.phi.incoming.clone(a);
        for (inst.kind.phi.incoming.items) |*incoming| if (exits.get(incoming.block)) |exit_name| {
            incoming.block = exit_name;
        };
    };
    var entry = result.blocks.items[0];
    var instructions: std.ArrayList(ir.Instruction) = .empty;
    var leading: usize = 0;
    while (leading < entry.instructions.items.len and entry.instructions.items[leading].kind == .phi) : (leading += 1) {}
    try instructions.appendSlice(a, entry.instructions.items[0..leading]);
    try instructions.appendSlice(a, prefixes.items);
    try instructions.appendSlice(a, entry.instructions.items[leading..]);
    entry.instructions = instructions;
    result.blocks.items[0] = entry;
    return result;
}
