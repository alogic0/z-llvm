//! Materialize constant pointer operands through ordinary SSA values. Constants
//! on PHI edges are defined in their predecessor; the public IR stays unchanged.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const addresses = @import("../symbol_address.zig");
const tables = @import("../constant_table.zig");
const forms = @import("scalar_forms.zig");

const word: ir.Type = .{ .int = 64 };

fn constant(value: ir.Value) bool {
    return addresses.fromValue(value) != null or addresses.pointerBits(value) != null;
}

fn absoluteVolatile(ty: ir.Type, ty_addrspace: ?[]const u8, ptr: ir.Value, attrs: ir.MemoryAttrs) bool {
    if (!attrs.is_volatile or attrs.isAtomic() or attrs.syncscope != null or ty_addrspace != null or addresses.pointerBits(ptr) == null) return false;
    return ty == .ptr or (ty == .int and (ty.int == 8 or ty.int == 16 or ty.int == 32 or ty.int == 64));
}

fn symbolicVolatile(ty: ir.Type, ty_addrspace: ?[]const u8, ptr: ir.Value, attrs: ir.MemoryAttrs) bool {
    if (!attrs.is_volatile or attrs.isAtomic() or attrs.syncscope != null or ty_addrspace != null or addresses.fromValue(ptr) == null) return false;
    // Named pointer globals already have their own established load owner.
    if (ty == .ptr) return ptr == .constant_expr;
    return ty == .int and (ty.int == 8 or ty.int == 16 or ty.int == 32 or ty.int == 64);
}

fn appendSymbolAddress(allocator: std.mem.Allocator, block: *ir.BasicBlock, name: []const u8, address: addresses.Address) !void {
    var indices: std.ArrayList(ir.GepIndex) = .empty;
    try indices.append(allocator, .{ .ty = word, .value = .{ .int = address.addend } });
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .gep = .{
        .source_ty = .{ .int = 8 },
        .ptr = .{ .named = try std.fmt.allocPrint(allocator, "@{s}", .{address.symbol}) },
        .indices = indices,
    } } });
}

fn materialize(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, value: ir.Value) !ir.Value {
    if (!constant(value)) return value;
    const name = try forms.temporary(allocator, function, serial);
    if (addresses.fromValue(value)) |address| {
        try appendSymbolAddress(allocator, block, name, address);
    } else {
        const integer = try forms.temporary(allocator, function, serial);
        try block.instructions.append(allocator, .{ .result = integer, .kind = .{ .binary = .{
            .op = .add,
            .ty = word,
            .lhs = .{ .int = addresses.pointerBits(value).? },
            .rhs = .{ .int = 0 },
        } } });
        try block.instructions.append(allocator, .{ .result = name, .kind = .{ .cast = .{
            .op = .inttoptr,
            .from_ty = word,
            .value = .{ .named = integer },
            .to_ty = .ptr,
        } } });
    }
    return .{ .named = name };
}

fn materializeIntegerAddress(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, ty: ir.Type, value: ir.Value) !ir.Value {
    const address = addresses.fromIntegerValue(ty, value) orelse return value;
    const pointer = try forms.temporary(allocator, function, serial);
    try appendSymbolAddress(allocator, block, pointer, address);
    const integer = try forms.temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = integer, .kind = .{ .cast = .{
        .op = .ptrtoint,
        .from_ty = .ptr,
        .value = .{ .named = pointer },
        .to_ty = word,
    } } });
    return .{ .named = integer };
}

fn tableGep(allocator: std.mem.Allocator, context: ?*const machine.ReadOnlyModuleContext, gep: ir.GepInst) !bool {
    const address = addresses.fromValue(gep.ptr) orelse return false;
    if (address.addend != 0) return false;
    const ctx = context orelse return false;
    // The existing table owner retains supported floating/integer table shapes.
    if (try tables.decodeSymbol(allocator, ctx.*, address.symbol)) |value| {
        var decoded = value;
        decoded.deinit(allocator);
        return true;
    }
    return false;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!addresses.supportsLayout(if (context) |ctx| ctx.target_datalayout else null)) return null;
    var result = function;
    result.blocks = .empty;
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    var changed = false;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            var copy = inst;
            const before = block.instructions.items.len;
            if (!inst.removed) switch (inst.kind) {
                .binary => |binary| {
                    copy.kind.binary.lhs = try materializeIntegerAddress(allocator, function, &block, &serial, binary.ty, binary.lhs);
                    copy.kind.binary.rhs = try materializeIntegerAddress(allocator, function, &block, &serial, binary.ty, binary.rhs);
                },
                .cast => |cast| if (cast.op == .ptrtoint and cast.from_ty == .ptr and cast.to_ty.eql(word) and !cast.flags.any()) {
                    copy.kind.cast.value = try materialize(allocator, function, &block, &serial, cast.value);
                } else if (cast.from_ty.eql(word) and !cast.flags.any() and cast.value == .int and
                    ((cast.op == .inttoptr and cast.to_ty == .ptr) or (cast.op == .zext and cast.to_ty.eql(.{ .int = 128 }))))
                {
                    const name = try forms.temporary(allocator, function, &serial);
                    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .binary = .{
                        .op = .add,
                        .ty = word,
                        .lhs = cast.value,
                        .rhs = .{ .int = 0 },
                    } } });
                    copy.kind.cast.value = .{ .named = name };
                },
                .icmp => |cmp| if (cmp.operand_ty == .ptr) {
                    copy.kind.icmp.lhs = try materialize(allocator, function, &block, &serial, cmp.lhs);
                    copy.kind.icmp.rhs = try materialize(allocator, function, &block, &serial, cmp.rhs);
                },
                .gep => |gep| if (gep.ptr_addrspace == null and addresses.fromGep(gep) == null and constant(gep.ptr) and !try tableGep(allocator, context, gep)) {
                    copy.kind.gep.ptr = try materialize(allocator, function, &block, &serial, gep.ptr);
                },
                .load => |load| if (load.ptr_addrspace == null and (!load.attrs.isBarrier() or absoluteVolatile(load.ty, load.ty_addrspace, load.ptr, load.attrs) or symbolicVolatile(load.ty, load.ty_addrspace, load.ptr, load.attrs))) {
                    copy.kind.load.ptr = try materialize(allocator, function, &block, &serial, load.ptr);
                },
                .store => |store| if (store.ptr_addrspace == null and (!store.attrs.isBarrier() or absoluteVolatile(store.ty, store.ty_addrspace, store.ptr, store.attrs))) {
                    copy.kind.store.ptr = try materialize(allocator, function, &block, &serial, store.ptr);
                    if (store.ty == .ptr and store.ty_addrspace == null)
                        copy.kind.store.value = try materialize(allocator, function, &block, &serial, store.value);
                },
                .select => |select| if (select.ty == .ptr) {
                    copy.kind.select.true_value = try materialize(allocator, function, &block, &serial, select.true_value);
                    copy.kind.select.false_value = try materialize(allocator, function, &block, &serial, select.false_value);
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.cond == .int and select.cond.int >= -1 and select.cond.int <= 1) {
                        const selected = if (select.cond.int & 1 != 0) copy.kind.select.true_value else copy.kind.select.false_value;
                        var indices: std.ArrayList(ir.GepIndex) = .empty;
                        try indices.append(allocator, .{ .ty = word, .value = .{ .int = 0 } });
                        copy.kind = .{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = selected, .indices = indices } };
                        changed = true;
                    }
                },
                .call => |call| if (call.inline_asm == null and call.raw_args == null) {
                    var cloned = false;
                    for (call.args.items, 0..) |arg, i| if (arg.ty == .ptr and constant(arg.value)) {
                        if (!cloned) {
                            copy.kind.call.args = try call.args.clone(allocator);
                            cloned = true;
                        }
                        copy.kind.call.args.items[i].value = try materialize(allocator, function, &block, &serial, arg.value);
                    };
                },
                else => {},
            };
            changed = changed or before != block.instructions.items.len;
            try block.instructions.append(allocator, copy);
        }
        if (block.terminator) |*term| if (term.* == .ret and term.ret.ty == .ptr) if (term.ret.value) |value| {
            const normalized = try materialize(allocator, function, &block, &serial, value);
            changed = changed or !normalized.eql(value);
            term.ret.value = normalized;
        };
        try result.blocks.append(allocator, block);
    }
    // Appending to predecessor instruction arrays can reallocate them. Iterate
    // the original PHIs and update their scalar copies only after each append.
    for (function.blocks.items, 0..) |original, block_index| {
        for (original.instructions.items) |inst| {
            if (inst.removed or inst.kind != .phi or inst.kind.phi.ty != .ptr) continue;
            var phi = inst.kind.phi;
            var cloned = false;
            for (inst.kind.phi.incoming.items, 0..) |incoming, i| {
                if (!constant(incoming.value)) continue;
                const predecessor = function.blockIndex(incoming.block) orelse return null;
                if (!cloned) {
                    phi.incoming = try phi.incoming.clone(allocator);
                    cloned = true;
                }
                phi.incoming.items[i].value = try materialize(allocator, function, &result.blocks.items[predecessor], &serial, incoming.value);
            }
            if (cloned) {
                const name = inst.result orelse return null;
                var found = false;
                for (result.blocks.items[block_index].instructions.items) |*copy| if (copy.result != null and ir.identifiers.eql(copy.result.?, name)) {
                    copy.kind.phi = phi;
                    found = true;
                    break;
                };
                if (!found) return error.InvalidPointerPhiIdentity;
                changed = true;
            }
        }
    }
    return if (changed) result else null;
}
