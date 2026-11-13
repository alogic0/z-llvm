//! SysV va_list records keep independent GP/SSE cursors and overflow storage.
//! Private parameters snapshot the remaining incoming registers before use.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const abi = @import("../sysv_abi.zig");
const stack = @import("stack_arguments.zig");
const word: ir.Type = .{ .int = 64 };
const offset_ty: ir.Type = .{ .int = 32 };
const xmm: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .double } };

const TypedUse = struct {
    pub const Error = error{};
    name: []const u8,
    found: *bool,
    pub fn visit(state: TypedUse, value: *const ir.Value, _: ir.Type) Error!void {
        if (value.* == .named and ir.identifiers.eql(value.named, state.name)) state.found.* = true;
    }
};
fn hasTypedUse(function: ir.Function, name: []const u8) bool {
    var found = false;
    const visitor: TypedUse = .{ .name = name, .found = &found };
    for (function.blocks.items) |block| {
        for (block.instructions.items) |*inst| if (!inst.removed) {
            _ = ir.operands.instruction(@as(*const ir.Instruction, inst), visitor) catch unreachable;
        };
        if (block.terminator) |*term| _ = ir.operands.terminator(@as(*const ir.Terminator, term), visitor) catch unreachable;
    }
    return found;
}

const Builder = struct {
    a: std.mem.Allocator,
    source: ir.Function,
    names: *forms.TemporaryNames,
    block: *ir.BasicBlock,
    fn name(b: Builder) ![]const u8 {
        return forms.temporary(b.a, b.source, b.names);
    }
    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const next = try b.name();
        try b.block.instructions.append(b.a, .{ .result = next, .kind = kind });
        return .{ .named = next };
    }
    fn address(b: Builder, ptr: ir.Value, displacement: ir.Value) !ir.Value {
        var indices: std.ArrayList(ir.GepIndex) = .empty;
        try indices.append(b.a, .{ .ty = word, .value = displacement });
        return b.emit(.{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = ptr, .indices = indices } });
    }
    fn at(b: Builder, ptr: ir.Value, displacement: i128) !ir.Value {
        return b.address(ptr, .{ .int = displacement });
    }
    fn load(b: Builder, ty: ir.Type, ptr: ir.Value) !ir.Value {
        return b.emit(.{ .load = .{ .ty = ty, .ptr = ptr } });
    }
    fn store(b: Builder, ty: ir.Type, value: ir.Value, ptr: ir.Value) !void {
        try b.block.instructions.append(b.a, .{ .result = null, .kind = .{ .store = .{ .ty = ty, .value = value, .ptr = ptr } } });
    }
    fn add(b: Builder, ty: ir.Type, value: ir.Value, amount: i128) !ir.Value {
        return b.emit(.{ .binary = .{ .op = .add, .ty = ty, .lhs = value, .rhs = .{ .int = amount } } });
    }
};

fn intrinsic(call: ir.CallInst, name: []const u8, count: usize) bool {
    if (!ir.identifiers.eql(call.callee, name) or call.args.items.len != count or call.ret_ty != .void or
        call.callee_value != null or call.callee_function_ty != null or call.raw_args != null or call.inline_asm != null or
        call.calling_conv != null or call.ret_attrs != null or call.operand_bundle != null) return false;
    abi.rejectUnsupportedCallEnvelope(call) catch return false;
    for (call.args.items) |arg| if (!@import("intrinsic_attrs.zig").pointerArgumentAdvisory(arg)) return false;
    return true;
}

fn setup(a: std.mem.Allocator, source: ir.Function) !?ir.Function {
    var needed = false;
    var start = false;
    for (source.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.kind != .call) continue;
        const call = inst.kind.call;
        if (intrinsic(call, "llvm.va_start.p0", 1)) {
            needed = true;
            start = true;
        }
        if (intrinsic(call, "llvm.va_end.p0", 1) or intrinsic(call, "llvm.va_copy.p0", 2)) needed = true;
    };
    if (!needed or (start and !source.is_varargs) or source.blocks.items.len == 0) return null;
    if (source.calling_conv) |cc| if (!std.mem.eql(u8, cc, "ccc")) return null;
    const layout = stack.parameters(source) orelse return null;
    var gp: usize = 0;
    var fp: usize = 0;
    for (source.params.items, 0..) |param, index| {
        if (param.ty != .ptr and param.ty != .float and param.ty != .double and !(param.ty == .int and param.ty.int > 0 and param.ty.int <= 64)) return null;
        abi.rejectUnsupportedCallArgAttrs(.{ .ty = param.ty, .attrs = param.attrs, .value = .{ .named = param.name } }) catch return null;
        switch (layout.locations[index]) {
            .register => |reg| gp = @max(gp, reg + 1),
            .sse => |reg| fp = @max(fp, reg + 1),
            .stack => {},
            else => return null,
        }
    }
    var result = source;
    result.blocks = .empty;
    result.is_varargs = false;
    var names: forms.TemporaryNames = .{ .prefix = "__zllvm_va_setup_" };
    defer names.deinit(a);
    var entry = source.blocks.items[0];
    entry.instructions = .empty;
    var b: Builder = .{ .a = a, .source = source, .names = &names, .block = &entry };
    var save: ir.Value = undefined;
    var overflow: ir.Value = undefined;
    if (start) {
        result.params = try source.params.clone(a);
        save = try b.emit(.{ .alloca = .{ .allocated_ty = .{ .aggregate = "[176 x i8]" }, .attrs = "align 16" } });
        // Otherwise unused named registers still need stable entry homes when
        // va_arg creates framed control flow. Snapshot them in their real SysV
        // save cells; neither cursor nor the source signature changes. The use
        // scan only avoids redundant snapshots, not an absence-of-use proof.
        for (source.params.items, 0..) |param, index| {
            if (hasTypedUse(source, param.name)) continue;
            switch (layout.locations[index]) {
                .register => |reg| try b.store(param.ty, .{ .named = param.name }, try b.at(save, @intCast(reg * 8))),
                .sse => |reg| try b.store(param.ty, .{ .named = param.name }, try b.at(save, @intCast(48 + reg * 16))),
                else => {},
            }
        }
        for (gp..6) |index| {
            const name = try b.name();
            try result.params.append(a, .{ .ty = word, .name = name });
            try b.store(word, .{ .named = name }, try b.at(save, @intCast(index * 8)));
        }
        for (fp..8) |index| {
            const name = try b.name();
            try result.params.append(a, .{ .ty = xmm, .name = name });
            try b.store(xmm, .{ .named = name }, try b.at(save, @intCast(48 + index * 16)));
        }
        const incoming = try b.name();
        try result.params.append(a, .{ .ty = .ptr, .name = incoming, .abi_incoming_address = std.math.cast(u32, layout.stack_words * 8) orelse return null });
        if (result.params.items.len > stack.max_arguments) return null;
        overflow = .{ .named = incoming };
    }
    for (source.blocks.items, 0..) |original, block_index| {
        var block = if (block_index == 0) entry else original;
        if (block_index != 0) block.instructions = .empty;
        b.block = &block;
        for (original.instructions.items) |inst| {
            if (!inst.removed and inst.kind == .call) {
                const call = inst.kind.call;
                if (intrinsic(call, "llvm.va_start.p0", 1)) {
                    const record = call.args.items[0].value;
                    try b.store(offset_ty, .{ .int = @intCast(gp * 8) }, record);
                    try b.store(offset_ty, .{ .int = @intCast(48 + fp * 16) }, try b.at(record, 4));
                    try b.store(.ptr, overflow, try b.at(record, 8));
                    try b.store(.ptr, save, try b.at(record, 16));
                    continue;
                }
                if (intrinsic(call, "llvm.va_end.p0", 1)) continue;
                if (intrinsic(call, "llvm.va_copy.p0", 2)) {
                    var words: [3]ir.Value = undefined;
                    for (&words, 0..) |*value, index| value.* = try b.load(word, try b.at(call.args.items[1].value, @intCast(index * 8)));
                    for (words, 0..) |value, index| try b.store(word, value, try b.at(call.args.items[0].value, @intCast(index * 8)));
                    continue;
                }
            }
            try block.instructions.append(a, inst);
        }
        try result.blocks.append(a, block);
    }
    return result;
}

fn expandArgument(a: std.mem.Allocator, source: ir.Function) !?ir.Function {
    for (source.blocks.items, 0..) |original, block_index| for (original.instructions.items, 0..) |inst, instruction_index| {
        if (inst.removed or inst.kind != .call or !inst.kind.call.va_arg) continue;
        const call = inst.kind.call;
        if (call.args.items.len != 1) return null;
        const floating = call.ret_ty == .float or call.ret_ty == .double;
        if (!floating and call.ret_ty != .ptr and !(call.ret_ty == .int and call.ret_ty.int > 0 and call.ret_ty.int <= 64)) return null;
        const record = call.args.items[0].value;
        var names: forms.TemporaryNames = .{ .prefix = "__zllvm_va_arg_" };
        defer names.deinit(a);
        var prefix = original;
        prefix.instructions = .empty;
        try prefix.instructions.appendSlice(a, original.instructions.items[0..instruction_index]);
        var b: Builder = .{ .a = a, .source = source, .names = &names, .block = &prefix };
        const register_name = try b.name();
        const overflow_name = try b.name();
        const tail_name = try b.name();
        const cursor = if (floating) try b.at(record, 4) else record;
        const offset = try b.load(offset_ty, cursor);
        const available = try b.emit(.{ .icmp = .{ .predicate = .ule, .operand_ty = offset_ty, .lhs = offset, .rhs = .{ .int = if (floating) 160 else 40 } } });
        prefix.terminator = .{ .condbr = .{ .cond_ty = .{ .int = 1 }, .cond = available, .then_target = register_name, .else_target = overflow_name } };
        var registers = ir.BasicBlock.init(register_name);
        b.block = &registers;
        const saved = try b.load(.ptr, try b.at(record, 16));
        const wide_offset = try b.emit(.{ .cast = .{ .op = .zext, .from_ty = offset_ty, .value = offset, .to_ty = word } });
        const register_address = try b.address(saved, wide_offset);
        try b.store(offset_ty, try b.add(offset_ty, offset, if (floating) 16 else 8), cursor);
        registers.terminator = .{ .br = .{ .target = tail_name } };
        var overflow_block = ir.BasicBlock.init(overflow_name);
        b.block = &overflow_block;
        const overflow_cursor = try b.at(record, 8);
        const overflow_address = try b.load(.ptr, overflow_cursor);
        try b.store(.ptr, try b.at(overflow_address, 8), overflow_cursor);
        overflow_block.terminator = .{ .br = .{ .target = tail_name } };
        var tail = ir.BasicBlock.init(tail_name);
        b.block = &tail;
        var incoming: std.ArrayList(ir.PhiIncoming) = .empty;
        try incoming.appendSlice(a, &.{ .{ .value = register_address, .block = register_name }, .{ .value = overflow_address, .block = overflow_name } });
        const pointer = try b.emit(.{ .phi = .{ .ty = .ptr, .incoming = incoming } });
        try tail.instructions.append(a, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .load = .{ .ty = call.ret_ty, .ptr = pointer } } });
        try tail.instructions.appendSlice(a, original.instructions.items[instruction_index + 1 ..]);
        tail.terminator = original.terminator;
        var result = source;
        result.blocks = .empty;
        for (source.blocks.items, 0..) |source_block, index| {
            if (index == block_index) {
                try result.blocks.append(a, prefix);
            } else {
                var copy = source_block;
                copy.instructions = try source_block.instructions.clone(a);
                try result.blocks.append(a, copy);
            }
        }
        try result.blocks.appendSlice(a, &.{ registers, overflow_block, tail });
        for (result.blocks.items) |*block| for (block.instructions.items) |*instruction| {
            if (instruction.removed or instruction.kind != .phi) continue;
            var phi = &instruction.kind.phi;
            phi.incoming = try phi.incoming.clone(a);
            for (phi.incoming.items) |*edge| if (ir.identifiers.eql(edge.block, original.name)) {
                edge.block = tail_name;
            };
        };
        return result;
    };
    return null;
}

pub fn legalize(a: std.mem.Allocator, source: ir.Function) !?ir.Function {
    if (try setup(a, source)) |function| return function;
    return expandArgument(a, source);
}
