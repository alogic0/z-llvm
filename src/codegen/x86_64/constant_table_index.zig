//! Prove a constant-table index without changing IR or trusting a load's type
//! as a value range. A private scalar slot is followed to its last store on
//! every predecessor path. Escapes, nonzero aliases and unknown paths close.
const std = @import("std");
const ir = @import("../../ir.zig");
const cfg = @import("../../analysis/cfg.zig");
const opaque_names = @import("../../ir/opaque_names.zig");
const machine = @import("machine.zig");
const storage_layout = @import("generic_cfg/storage_layout.zig");

pub fn proves(allocator: std.mem.Allocator, context: ?*const machine.ReadOnlyModuleContext, function: ir.Function, name: []const u8, allowed: u64) !bool {
    var proof: Proof = .{ .context = context, .function = function, .graph = try cfg.Graph.build(allocator, function) };
    defer proof.graph.deinit();
    return proof.value(.{ .named = name }, allowed, 0);
}

const Position = struct { block: usize, index: usize, instruction: *const ir.Instruction };
const Proof = struct {
    context: ?*const machine.ReadOnlyModuleContext,
    function: ir.Function,
    graph: cfg.Graph,
    remaining: usize = 4096,

    fn enter(p: *Proof, depth: u8) bool {
        if (depth >= 32 or p.remaining == 0) return false;
        p.remaining -= 1;
        return true;
    }
    fn find(p: *const Proof, name: []const u8) ?Position {
        for (p.function.blocks.items, 0..) |block, bi| for (block.instructions.items, 0..) |*inst, ii| {
            if (!inst.removed and inst.result != null and ir.identifiers.eql(inst.result.?, name))
                return .{ .block = bi, .index = ii, .instruction = inst };
        };
        return null;
    }
    fn value(p: *Proof, input: ir.Value, allowed: u128, depth: u8) bool {
        if (!p.enter(depth)) return false;
        if (input == .int) return input.int >= 0 and @as(u128, @intCast(input.int)) & ~allowed == 0;
        if (input != .named) return false;
        const at = p.find(input.named) orelse return false;
        return switch (at.instruction.kind) {
            .cast => |cast| integer(cast.from_ty) and integer(cast.to_ty) and
                (cast.op == .trunc or cast.op == .zext or
                    (cast.op == .bitcast and cast.from_ty.eql(cast.to_ty))) and
                p.value(cast.value, allowed, depth + 1),
            .binary => |binary| if (integer(binary.ty)) switch (binary.op) {
                .@"and" => p.value(binary.rhs, allowed, depth + 1) or p.value(binary.lhs, allowed, depth + 1),
                .@"or" => p.value(binary.lhs, allowed, depth + 1) and p.value(binary.rhs, allowed, depth + 1),
                .add => p.disjointAdd(binary.lhs, binary.rhs, binary.ty.int, allowed, depth + 1) or
                    p.disjointAdd(binary.rhs, binary.lhs, binary.ty.int, allowed, depth + 1),
                .lshr => if (amount(binary.rhs, binary.ty.int)) |shift|
                    (lowMask(binary.ty.int) >> shift) & ~allowed == 0
                else
                    false,
                .urem => if (divisor(binary.rhs, binary.ty.int)) |n|
                    maskThrough(n - 1) & ~allowed == 0
                else
                    false,
                .shl => if (amount(binary.rhs, binary.ty.int)) |shift| p.value(binary.lhs, allowed >> shift, depth + 1) else false,
                .mul => if (power(binary.rhs, binary.ty.int)) |shift|
                    p.value(binary.lhs, allowed >> shift, depth + 1)
                else if (power(binary.lhs, binary.ty.int)) |shift|
                    p.value(binary.rhs, allowed >> shift, depth + 1)
                else
                    false,
                else => false,
            } else false,
            .select => |select| integer(select.ty) and select.cond_ty.eql(.{ .int = 1 }) and
                p.value(select.true_value, allowed, depth + 1) and p.value(select.false_value, allowed, depth + 1),
            .phi => |phi| blk: {
                if (!integer(phi.ty) or phi.incoming.items.len == 0) break :blk false;
                for (phi.incoming.items) |incoming| if (!p.value(incoming.value, allowed, depth + 1)) break :blk false;
                break :blk true;
            },
            .load => |load| blk: {
                if (!integer(load.ty) or load.ptr != .named or load.attrs.isBarrier() or load.attrs.syncscope != null or
                    load.ty_addrspace != null or load.ptr_addrspace != null) break :blk false;
                const slot = p.slotRoot(load.ptr.named) orelse break :blk false;
                if (!p.privateSlot(slot, load.ty)) break :blk false;
                break :blk p.before(at.block, at.index, slot, allowed, depth + 1);
            },
            else => false,
        };
    }
    fn disjointAdd(p: *Proof, input: ir.Value, constant: ir.Value, bits: u16, allowed: u128, depth: u8) bool {
        if (constant != .int or constant.int < 0) return false;
        const payload: u128 = @intCast(constant.int);
        if (payload > lowMask(bits) or payload & ~allowed != 0) return false;
        // Proving the other operand disjoint makes addition an exact bitwise
        // union. No carry or wrap can create a bit outside the table envelope.
        return p.value(input, allowed & ~payload, depth);
    }
    fn before(p: *Proof, bi: usize, end: usize, slot: []const u8, allowed: u128, depth: u8) bool {
        if (!p.enter(depth)) return false;
        var ii = end;
        while (ii != 0) {
            ii -= 1;
            const inst = p.function.blocks.items[bi].instructions.items[ii];
            if (inst.removed or inst.kind != .store or !p.isSlotPointer(inst.kind.store.ptr, slot)) continue;
            return p.value(inst.kind.store.value, allowed, depth + 1);
        }
        if (bi == 0) return false;
        const predecessors = p.graph.predecessors(bi);
        if (predecessors.len == 0) return false;
        for (predecessors) |pred| if (!p.before(pred, p.function.blocks.items[pred].instructions.items.len, slot, allowed, depth + 1)) return false;
        return true;
    }
    fn slotRoot(p: *const Proof, name: []const u8) ?[]const u8 {
        var cursor = name;
        for (0..32) |_| {
            const at = p.find(cursor) orelse return null;
            if (at.instruction.kind == .alloca) return at.instruction.result;
            if (at.instruction.kind != .gep or !zeroByteGep(at.instruction.kind.gep)) return null;
            cursor = at.instruction.kind.gep.ptr.named;
        }
        return null;
    }
    fn isSlotPointer(p: *const Proof, value_: ir.Value, slot: []const u8) bool {
        if (value_ != .named) return false;
        const root = p.slotRoot(value_.named) orelse return false;
        return ir.identifiers.eql(root, slot);
    }
    fn privateSlot(p: *const Proof, slot: []const u8, ty: ir.Type) bool {
        const definition = p.find(slot) orelse return false;
        if (definition.block != 0 or definition.instruction.kind != .alloca) return false;
        const alloca = definition.instruction.kind.alloca;
        if (!alloca.isSingleObject() or alloca.allocated_ty_addrspace != null) return false;
        // Frame normalization may pad the allocation. Every admitted access
        // still covers the same typed prefix. Only proven zero-byte aliases
        // introduced by normalization can share that private object.
        const allocation = storage_layout.query(p.context, alloca.allocated_ty) orelse return false;
        const access = storage_layout.query(p.context, ty) orelse return false;
        if (access.bytes > allocation.bytes) return false;
        var aliases: [128][]const u8 = undefined;
        aliases[0] = slot;
        var count: usize = 1;
        for (p.function.blocks.items) |block| for (block.instructions.items) |inst| {
            if (inst.removed or inst.kind != .gep or inst.result == null) continue;
            if (!p.isSlotPointer(.{ .named = inst.result.? }, slot)) continue;
            if (count == aliases.len) return false;
            aliases[count] = inst.result.?;
            count += 1;
        };
        for (p.function.blocks.items) |block| {
            for (block.instructions.items) |inst| {
                if (inst.removed) continue;
                if (inst.kind == .call and inst.kind.call.inline_asm != null) return false;
                const used = for (aliases[0..count]) |alias| {
                    if (mentions(inst, alias) catch return false) break true;
                } else false;
                if (!used) continue;
                switch (inst.kind) {
                    .gep => |gep| if (inst.result == null or !zeroByteGep(gep) or !p.isSlotPointer(gep.ptr, slot)) return false,
                    .load => |load| if (!p.isSlotPointer(load.ptr, slot) or !load.ty.eql(ty) or
                        load.attrs.isBarrier() or load.attrs.syncscope != null or load.ty_addrspace != null or load.ptr_addrspace != null) return false,
                    .store => |store| if (!p.isSlotPointer(store.ptr, slot) or !store.ty.eql(ty) or p.isSlotPointer(store.value, slot) or
                        store.attrs.isBarrier() or store.attrs.syncscope != null or store.ty_addrspace != null or store.ptr_addrspace != null) return false,
                    .call => |call| if (!call.isDebugVariableLocation()) return false,
                    else => return false,
                }
            }
            if (block.terminator) |term| {
                for (aliases[0..count]) |alias| {
                    var seen = Names{ .name = alias };
                    _ = ir.operands.terminator(&term, seen.visitor()) catch return false;
                    switch (term) {
                        .br => |b| seen.text(b.metadata) catch return false,
                        .condbr => |b| seen.text(b.metadata) catch return false,
                        .@"switch" => |b| seen.text(b.metadata) catch return false,
                        .indirectbr => |b| seen.text(b.metadata) catch return false,
                        else => {},
                    }
                    if (seen.found) return false;
                }
            }
        }
        return true;
    }
};

fn integer(ty: ir.Type) bool {
    return ty == .int and ty.int > 0 and ty.int <= 128;
}
fn zeroByteGep(gep: ir.GepInst) bool {
    return gep.ptr_addrspace == null and gep.ptr == .named and gep.source_ty.eql(.{ .int = 8 }) and
        gep.indices.items.len == 1 and gep.indices.items[0].ty.eql(.{ .int = 64 }) and
        gep.indices.items[0].value.eql(.{ .int = 0 });
}
fn lowMask(bits: u16) u128 {
    return @as(u128, std.math.maxInt(u128)) >> @as(u7, @intCast(128 - bits));
}
fn amount(value: ir.Value, bits: u16) ?u7 {
    return if (value == .int and value.int >= 0 and value.int < bits) @intCast(value.int) else null;
}
fn divisor(value: ir.Value, bits: u16) ?u128 {
    if (value != .int or value.int <= 0) return null;
    const n: u128 = @intCast(value.int);
    return if (n <= lowMask(bits)) n else null;
}
fn maskThrough(upper: u128) u128 {
    return if (upper == 0) 0 else @as(u128, std.math.maxInt(u128)) >> @as(u7, @intCast(@clz(upper)));
}
fn power(value: ir.Value, bits: u16) ?u7 {
    if (value != .int or value.int <= 0) return null;
    const raw: u128 = @intCast(value.int);
    if (!std.math.isPowerOfTwo(raw)) return null;
    const shift = @ctz(raw);
    return if (shift < bits) @intCast(shift) else null;
}

// The structured visitor reports opaque slots too. Scan all of those slots for
// local tokens, as the IR local-name machinery does; unknown syntax declines.
const Names = struct {
    name: []const u8,
    found: bool = false,
    const Visitor = struct {
        pub const Error = opaque_names.Error;
        names: *Names,
        pub fn visit(v: Visitor, operand: *const ir.Value, _: ir.Type) Error!void {
            switch (operand.*) {
                .named => |name| if (ir.identifiers.eql(name, v.names.name)) {
                    v.names.found = true;
                },
                .vector, .constant_expr => |payload| try v.names.text(payload),
                else => {},
            }
        }
    };
    fn visitor(n: *Names) Visitor {
        return .{ .names = n };
    }
    fn text(n: *Names, raw: ?[]const u8) opaque_names.Error!void {
        var it: opaque_names.Iterator = .{ .raw = raw orelse return };
        while (try it.next()) |token| {
            const name = switch (token) {
                .local => |name| name,
                .block_address => |address| address.block,
            };
            if (ir.identifiers.eql(name, n.name)) n.found = true;
        }
    }
};
fn mentions(inst: ir.Instruction, slot: []const u8) opaque_names.Error!bool {
    var names = Names{ .name = slot };
    _ = try ir.operands.instruction(&inst, names.visitor());
    try names.text(inst.metadata);
    switch (inst.kind) {
        .alloca => |alloca| try names.text(alloca.attrs),
        .call => |call| {
            try names.text(call.raw_args);
            try names.text(call.operand_bundle);
            try names.text(call.attrs);
            try names.text(call.ret_attrs);
            for (call.args.items) |arg| try names.text(arg.attrs);
        },
        else => {},
    }
    return names.found;
}

test "readonly table index proofs retain typed bitcasts wide masks and scaled bounds" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i64 @index(i128 %input) {
        \\entry:
        \\ %masked = and i128 %input,127
        \\ %low = trunc i128 %masked to i64
        \\ %identity = bitcast i64 %low to i64
        \\ %scaled = mul i64 %identity,2
        \\ %outside = or i64 %identity,128
        \\ %remainder = urem i128 %input,128
        \\ %remainder3 = urem i128 %input,3
        \\ %zero = urem i128 %input,0
        \\ %lower = and i128 %input,63
        \\ %offset = add i128 %lower,64
        \\ %carry = add i128 %lower,65
        \\ ret i64 %scaled
        \\}
    );
    defer module.deinit();
    try module.verify();
    try std.testing.expect(try proves(std.testing.allocator, null, module.functions.items[0], "identity", 127));
    try std.testing.expect(try proves(std.testing.allocator, null, module.functions.items[0], "scaled", 510));
    try std.testing.expect(!try proves(std.testing.allocator, null, module.functions.items[0], "scaled", 127));
    try std.testing.expect(!try proves(std.testing.allocator, null, module.functions.items[0], "outside", 127));
    try std.testing.expect(try proves(std.testing.allocator, null, module.functions.items[0], "remainder", 127));
    try std.testing.expect(try proves(std.testing.allocator, null, module.functions.items[0], "remainder3", 3));
    try std.testing.expect(!try proves(std.testing.allocator, null, module.functions.items[0], "remainder3", 2));
    try std.testing.expect(!try proves(std.testing.allocator, null, module.functions.items[0], "zero", 127));
    try std.testing.expect(try proves(std.testing.allocator, null, module.functions.items[0], "offset", 127));
    try std.testing.expect(!try proves(std.testing.allocator, null, module.functions.items[0], "carry", 127));
}

test "readonly table index proofs require bounded reaching stores and a private scalar slot" {
    for ([_]struct { before: []const u8 = "", right: []const u8, access: []const u8 = "load", pointer: []const u8 = "slot", accepted: bool }{
        .{ .right = "store i64 %masked,ptr %slot", .accepted = true },
        .{ .right = "store i64 %input,ptr %slot", .accepted = false },
        .{ .right = "", .accepted = false },
        .{ .before = "call void @escape(ptr %slot)", .right = "store i64 %masked,ptr %slot", .accepted = false },
        .{ .before = "%alias = getelementptr i8,ptr %slot,i64 0", .right = "store i64 %masked,ptr %alias", .pointer = "alias", .accepted = true },
        .{ .before = "%alias = getelementptr i8,ptr %slot,i64 0\n call void @escape(ptr %alias)", .right = "store i64 %masked,ptr %slot", .accepted = false },
        .{ .before = "%alias = getelementptr i8,ptr %slot,i64 1", .right = "store i64 %masked,ptr %slot", .accepted = false },
        .{ .before = "store i32 0,ptr %slot", .right = "store i64 %masked,ptr %slot", .accepted = false },
        .{ .right = "store i64 %masked,ptr %slot", .access = "load volatile", .accepted = false },
    }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare void @escape(ptr)\ndefine i64 @index(i64 %input,i1 %choose) {{\nentry:\n %slot = alloca i64,align 8\n %masked = and i64 %input,127\n {s}\n br i1 %choose,label %left,label %right\nleft:\n store i64 %masked,ptr %slot\n br label %merge\nright:\n {s}\n br label %merge\nmerge:\n %index = {s} i64,ptr %{s}\n ret i64 %index\n}}\n", .{ case.before, case.right, case.access, case.pointer });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        try std.testing.expectEqual(case.accepted, try proves(std.testing.allocator, null, module.functions.items[0], "index", 127));
    }
}

test "readonly table index proof admits only a complete uniform prefix in padded private storage" {
    for ([_]struct { allocation: []const u8, accepted: bool }{
        .{ .allocation = "i64", .accepted = true },
        .{ .allocation = "[2 x i32]", .accepted = true },
        .{ .allocation = "[8 x i8]", .accepted = true },
        .{ .allocation = "i32", .accepted = false },
        .{ .allocation = "[7 x i8]", .accepted = false },
    }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @index(i64 %input) {{\nentry:\n %slot = alloca {s},align 8\n %masked = and i64 %input,127\n store i64 %masked,ptr %slot\n %index = load i64,ptr %slot\n ret i64 %index\n}}\n", .{case.allocation});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        try std.testing.expectEqual(case.accepted, try proves(std.testing.allocator, null, module.functions.items[0], "index", 127));
    }
}
