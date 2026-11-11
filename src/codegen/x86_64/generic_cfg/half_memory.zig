//! Exact two-byte binary16 storage through ordinary integer memory operations.
const std = @import("std");
const ir = @import("../../../ir.zig");
const target = @import("../../../target.zig");
const machine = @import("../machine.zig");
const fp = @import("../../../analysis/fp_semantics.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");
const bits: ir.Type = .{ .int = 16 };

fn ordinary(attrs: ir.MemoryAttrs, ty_space: ?[]const u8, ptr_space: ?[]const u8) bool {
    return !attrs.isBarrier() and attrs.syncscope == null and ty_space == null and ptr_space == null;
}

fn eligible(function: ir.Function, context: ?*const machine.ReadOnlyModuleContext, include_stores: bool) bool {
    const layout = target.DataLayout.parse(if (context) |ctx| ctx.target_datalayout orelse "" else "") catch return false;
    if ((layout.typeStoreSizeBytes(.half) catch return false) != 2 or
        (layout.typeStoreSizeBytes(bits) catch return false) != 2 or
        (layout.typeAllocSizeBytes(.half) catch return false) != (layout.typeAllocSizeBytes(bits) catch return false) or
        (layout.typeAbiAlignmentBits(.half) catch return false) != (layout.typeAbiAlignmentBits(bits) catch return false)) return false;
    var found = false;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        if (inst.kind == .load and inst.kind.load.ty == .half) {
            const load = inst.kind.load;
            if (!ordinary(load.attrs, load.ty_addrspace, load.ptr_addrspace)) return false;
            found = true;
        }
        if (inst.kind == .store and inst.kind.store.ty == .half) {
            const store = inst.kind.store;
            if (!ordinary(store.attrs, store.ty_addrspace, store.ptr_addrspace)) return false;
            switch (store.value) {
                .named, .undef, .poison, .zero_initializer => {},
                .fp => |text| _ = fp.halfLiteralBits(text) catch return false,
                else => return false,
            }
            found = found or include_stores;
        }
    };
    return found;
}

fn emit(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, names: *forms.TemporaryNames, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
    const name = try forms.temporary(allocator, function, names);
    try block.instructions.append(allocator, .{ .result = name, .kind = kind });
    return .{ .named = name };
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    return expand(allocator, function, context, false);
}

/// The final optional stage tries the existing composed form first, retaining
/// successful owners and object bytes before opening store-only memory graphs.
pub fn legalizeOrdinaryStores(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    return expand(allocator, function, context, true);
}

fn expand(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext, include_stores: bool) !?ir.Function {
    if (!eligible(function, context, include_stores)) return null;
    var candidate = Candidate.init(allocator, function);
    var names: forms.TemporaryNames = .{};
    defer names.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed) switch (inst.kind) {
                .alloca => |value| if (value.allocated_ty == .half) {
                    try candidate.begin(&block, block_index, instruction_index);
                    var copy = inst;
                    copy.kind.alloca.allocated_ty = bits;
                    try block.instructions.append(allocator, copy);
                    continue;
                },
                .gep => |value| if (value.source_ty == .half) {
                    try candidate.begin(&block, block_index, instruction_index);
                    var copy = inst;
                    copy.kind.gep.source_ty = bits;
                    try block.instructions.append(allocator, copy);
                    continue;
                },
                .load => |value| if (value.ty == .half) {
                    try candidate.begin(&block, block_index, instruction_index);
                    var load = value;
                    load.ty = bits;
                    const raw = try emit(allocator, function, &block, &names, .{ .load = load });
                    var copy = inst;
                    copy.kind = .{ .cast = .{ .op = .bitcast, .from_ty = bits, .value = raw, .to_ty = .half } };
                    copy.metadata = null;
                    try block.instructions.append(allocator, copy);
                    continue;
                },
                .store => |value| if (value.ty == .half) {
                    try candidate.begin(&block, block_index, instruction_index);
                    const raw = switch (value.value) {
                        .fp => |text| ir.Value{ .int = try fp.halfLiteralBits(text) },
                        .zero_initializer => ir.Value{ .int = 0 },
                        .undef, .poison => value.value,
                        .named => try emit(allocator, function, &block, &names, .{ .cast = .{ .op = .bitcast, .from_ty = .half, .value = value.value, .to_ty = bits } }),
                        else => unreachable,
                    };
                    var copy = inst;
                    copy.kind.store.ty = bits;
                    copy.kind.store.value = raw;
                    copy.metadata = null;
                    try block.instructions.append(allocator, copy);
                    continue;
                },
                else => {},
            };
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
