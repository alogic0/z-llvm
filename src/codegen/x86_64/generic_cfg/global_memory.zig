//! Expose constant symbolic pointers as ordinary SSA addresses for the existing
//! transactional consumers. The input module and intrinsic contract stay intact.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const addresses = @import("../symbol_address.zig");
const constant_table = @import("../constant_table.zig");
const target = @import("../../../target.zig");

fn memcpy(call: ir.CallInst) bool {
    return (std.mem.eql(u8, call.callee, "llvm.memcpy.p0.p0.i64") or std.mem.eql(u8, call.callee, "llvm.memcpy.inline.p0.p0.i64")) and
        call.inline_asm == null and call.callee_value == null and call.args.items.len == 4 and
        call.args.items[0].ty == .ptr and call.args.items[1].ty == .ptr;
}

fn rewriteReturn(allocator: std.mem.Allocator, context: *const machine.ReadOnlyModuleContext, value: ir.Value) !bool {
    const address = addresses.fromValue(value) orelse return false;
    const global = context.findGlobal(address.symbol) orelse return false;
    // Existing floating constants/tables and zero-sized objects retain their
    // established emission path. This legalization owns ordinary native
    // integer/pointer objects and does not supersede those representations.
    switch (global.ty) {
        .int, .ptr, .aggregate => {},
        else => return false,
    }
    const layout = target.DataLayout.parse(context.target_datalayout orelse "") catch return false;
    if ((layout.typeStoreSizeBytes(global.ty) catch 1) == 0) return false;
    if (try constant_table.decodeGlobal(allocator, context.*, global)) |decoded_value| {
        var decoded = decoded_value;
        decoded.deinit(allocator);
        return false;
    }
    return true;
}

fn needsRewrite(allocator: std.mem.Allocator, function: ir.Function, context: *const machine.ReadOnlyModuleContext) !bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |inst| {
            if (inst.removed) continue;
            switch (inst.kind) {
                .gep => |gep| if (gep.ptr_addrspace == null and gep.ptr == .constant_expr and addresses.fromValue(gep.ptr) != null) return true,
                .call => |call| if (memcpy(call) and
                    (addresses.fromValue(call.args.items[0].value) != null or addresses.fromValue(call.args.items[1].value) != null)) return true,
                .store => |store| if (store.ptr_addrspace == null and (addresses.fromValue(store.ptr) != null or (store.ty == .ptr and store.ty_addrspace == null and addresses.fromValue(store.value) != null))) return true,
                .load => |load| if (load.attrs.isAtomic() and load.ptr_addrspace == null and addresses.fromValue(load.ptr) != null) return true,
                .atomicrmw => |rmw| if (addresses.fromValue(rmw.ptr) != null or (rmw.ty == .ptr and addresses.fromValue(rmw.value) != null)) return true,
                .cmpxchg => |cmp| if (addresses.fromValue(cmp.ptr) != null or (cmp.ty == .ptr and
                    (addresses.fromValue(cmp.expected) != null or addresses.fromValue(cmp.replacement) != null))) return true,
                else => {},
            }
        }
        if (block.terminator) |terminator| if (terminator == .ret and terminator.ret.ty == .ptr)
            if (terminator.ret.value) |value| if (try rewriteReturn(allocator, context, value)) return true;
    }
    return false;
}

fn temporary(allocator: std.mem.Allocator, function: ir.Function, serial: *usize) ![]const u8 {
    while (true) {
        const name = try std.fmt.allocPrint(allocator, "__zllvm_global_{d}", .{serial.*});
        serial.* += 1;
        var collision = false;
        for (function.params.items) |param| if (std.mem.eql(u8, name, param.name)) {
            collision = true;
        };
        for (function.blocks.items) |block| for (block.instructions.items) |inst| {
            if (inst.result) |result| if (std.mem.eql(u8, name, result)) {
                collision = true;
            };
        };
        if (!collision) return name;
    }
}

fn materialize(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *usize, value: ir.Value) !ir.Value {
    const address = addresses.fromValue(value) orelse return value;
    const name = try temporary(allocator, function, serial);
    var indices: std.ArrayList(ir.GepIndex) = .empty;
    try indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = address.addend } });
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .gep = .{
        .source_ty = .{ .int = 8 },
        .ptr = .{ .named = try std.fmt.allocPrint(allocator, "@{s}", .{address.symbol}) },
        .indices = indices,
    } } });
    return .{ .named = name };
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    const ctx = context orelse return null;
    if (!addresses.supportsLayout(ctx.target_datalayout) or !(try needsRewrite(allocator, function, ctx))) return null;
    var result = function;
    result.blocks = .empty;
    var serial: usize = 0;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (!inst.removed) switch (inst.kind) {
                .gep => |gep| if (gep.ptr_addrspace == null and gep.ptr == .constant_expr) {
                    copy.kind.gep.ptr = try materialize(allocator, function, &block, &serial, gep.ptr);
                },
                .call => |call| if (memcpy(call)) {
                    copy.kind.call.args = try call.args.clone(allocator);
                    for (copy.kind.call.args.items[0..2]) |*arg|
                        arg.value = try materialize(allocator, function, &block, &serial, arg.value);
                },
                .store => |store| if (store.ptr_addrspace == null) {
                    copy.kind.store.ptr = try materialize(allocator, function, &block, &serial, store.ptr);
                    if (store.ty == .ptr and store.ty_addrspace == null) copy.kind.store.value = try materialize(allocator, function, &block, &serial, store.value);
                },
                .load => |load| if (load.attrs.isAtomic() and load.ptr_addrspace == null) {
                    copy.kind.load.ptr = try materialize(allocator, function, &block, &serial, load.ptr);
                },
                .atomicrmw => |rmw| {
                    copy.kind.atomicrmw.ptr = try materialize(allocator, function, &block, &serial, rmw.ptr);
                    if (rmw.ty == .ptr) copy.kind.atomicrmw.value = try materialize(allocator, function, &block, &serial, rmw.value);
                },
                .cmpxchg => |cmp| {
                    copy.kind.cmpxchg.ptr = try materialize(allocator, function, &block, &serial, cmp.ptr);
                    if (cmp.ty == .ptr) {
                        copy.kind.cmpxchg.expected = try materialize(allocator, function, &block, &serial, cmp.expected);
                        copy.kind.cmpxchg.replacement = try materialize(allocator, function, &block, &serial, cmp.replacement);
                    }
                },
                else => {},
            };
            try block.instructions.append(allocator, copy);
        }
        if (block.terminator) |terminator| if (terminator == .ret and terminator.ret.ty == .ptr)
            if (terminator.ret.value) |value| {
                if (try rewriteReturn(allocator, ctx, value))
                    block.terminator.?.ret.value = try materialize(allocator, function, &block, &serial, value);
            };
        try result.blocks.append(allocator, block);
    }
    return result;
}
