//! Materialize bounded frame addresses used as scalar SSA values. The private
//! allocation retains storage ownership; the original name becomes a pointer.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const storage = @import("storage_layout.zig");
const helpers = @import("composed_helpers.zig");
const forms = @import("scalar_forms.zig");
const selector_types = @import("selector_types.zig");

// Native i32 array carriers already have exact frame ownership. Permit their
// scalar address views up to the total frame bound, without broadening the
// general aggregate layout contract. Non-native i32 layouts remain closed.
fn slotLayout(context: ?*const machine.ReadOnlyModuleContext, ty: ir.Type) ?storage.Layout {
    if (storage.query(context, ty)) |layout| return layout;
    const count = helpers.parseI32ArrayType(ty) orelse return null;
    const word = storage.query(context, .{ .int = 32 }) orelse return null;
    if (word.bytes != 4 or word.alignment != 4) return null;
    const bytes = std.math.mul(u32, count, 4) catch return null;
    if (bytes > selector_types.max_stack_frame_bytes) return null;
    return .{ .bytes = bytes, .alignment = 4 };
}

const Use = struct { bytes: u32, scalar: bool = false, bounded: bool = true };
const Uses = std.HashMap([]const u8, Use, ir.identifiers.Context, std.hash_map.default_max_load_percentage);

fn use(uses: *Uses, value: ir.Value) ?*Use {
    return if (value == .named) uses.getPtr(value.named) else null;
}

fn scalar(uses: *Uses, value: ir.Value, width: u32) void {
    if (use(uses, value)) |entry| {
        if (width <= entry.bytes) entry.scalar = true;
    }
}

// Observe every use once for all candidate allocations. Preserve the exact
// scalar-use and bounded-memory contracts, including escaped identifier aliases.
fn collectUses(uses: *Uses, function: ir.Function) void {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |inst| {
            if (inst.removed) continue;
            switch (inst.kind) {
                .phi => |phi| if (phi.ty == .ptr) {
                    for (phi.incoming.items) |incoming| scalar(uses, incoming.value, 0);
                },
                .select => |select| if (select.ty == .ptr) {
                    scalar(uses, select.true_value, 0);
                    scalar(uses, select.false_value, 0);
                },
                .store => |store| {
                    if (store.ty == .ptr) scalar(uses, store.value, 0);
                    const width: u32 = if (store.ty == .ptr) 64 else if (store.ty == .int) store.ty.int else 0;
                    if (width > 0 and width <= 64) scalar(uses, store.ptr, (width + 7) / 8);
                },
                .load => |load| {
                    const width: u32 = if (load.ty == .ptr) 64 else if (load.ty == .int) load.ty.int else 0;
                    if (width > 0 and width <= 64) scalar(uses, load.ptr, (width + 7) / 8);
                },
                .call => |call| {
                    const memory = std.mem.startsWith(u8, call.callee, "llvm.memcpy.") or
                        std.mem.startsWith(u8, call.callee, "llvm.memmove.") or
                        std.mem.startsWith(u8, call.callee, "llvm.memset.");
                    for (call.args.items, 0..) |arg, index| {
                        if (arg.ty != .ptr) continue;
                        const entry = use(uses, arg.value) orelse continue;
                        var bounded = true;
                        if (memory) {
                            bounded = call.args.items.len == 4;
                            if (bounded) {
                                const length = call.args.items[2].value;
                                bounded = length == .int and length.int >= 0 and length.int <= entry.bytes;
                            }
                            if (!bounded) entry.bounded = false;
                        }
                        if (call.inline_asm == null and call.raw_args == null and
                            (!memory or (index <= 1 and bounded))) entry.scalar = true;
                    }
                },
                .cast => |cast| if (cast.from_ty == .ptr) scalar(uses, cast.value, 0),
                .icmp => |icmp| if (icmp.operand_ty == .ptr) {
                    scalar(uses, icmp.lhs, 0);
                    scalar(uses, icmp.rhs, 0);
                },
                .gep => |gep| {
                    for (gep.indices.items) |index| if (index.value == .named) {
                        scalar(uses, gep.ptr, 0);
                        break;
                    };
                },
                else => {},
            }
        }
        if (block.terminator) |term| if (term == .ret and term.ret.ty == .ptr and term.ret.value != null) scalar(uses, term.ret.value.?, 0);
    }
}

test "stack use index preserves quoted aliases width bounds and invalid memory uses" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    for ([_]struct { width: u8, length: []const u8, scalar_use: bool, bounded: bool }{
        .{ .width = 32, .length = "4", .scalar_use = true, .bounded = true },
        .{ .width = 32, .length = "5", .scalar_use = true, .bounded = false },
        .{ .width = 32, .length = "%n", .scalar_use = true, .bounded = false },
        .{ .width = 64, .length = "5", .scalar_use = false, .bounded = false },
    }) |case| {
        const source = try std.fmt.allocPrint(a,
            \\declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
            \\define void @uses(i64 %n) {{
            \\entry:
            \\ %"\73lot" = alloca i32
            \\ %v = load i{d}, ptr %"\73lot", align 1
            \\ call void @llvm.memset.p0.i64(ptr %"\73lot", i8 0, i64 {s}, i1 false)
            \\ ret void
            \\}}
        , .{ case.width, case.length });
        var module = try ir.Module.parse(a, source);
        defer module.deinit();
        try module.verify();
        var uses = Uses.init(a);
        defer uses.deinit();
        try uses.put("slot", .{ .bytes = 4 });
        collectUses(&uses, module.functions.items[0]);
        const actual = uses.get("\"\\73lot\"").?;
        try std.testing.expectEqual(case.scalar_use, actual.scalar);
        try std.testing.expectEqual(case.bounded, actual.bounded);
    }
}

const Slot = struct { backing: []const u8, bytes: u32, alignment: u32 };

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    var uses = Uses.init(allocator);
    defer uses.deinit();
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.result == null or inst.kind != .alloca) continue;
        const ty = inst.kind.alloca.allocated_ty;
        if (ty == .aggregate and helpers.parseI32ArrayType(ty) == null) continue;
        const layout = slotLayout(context, ty) orelse continue;
        try uses.put(inst.result.?, .{ .bytes = layout.bytes });
    };
    if (uses.count() == 0) return null;
    collectUses(&uses, function);
    var slots = std.StringHashMap(Slot).init(allocator);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.result == null or inst.kind != .alloca) continue;
        const alloca = inst.kind.alloca;
        // Aggregate allocation admission belongs to padded_frame. Only its
        // concrete array carrier and native scalar objects enter this view.
        if (alloca.allocated_ty == .aggregate and helpers.parseI32ArrayType(alloca.allocated_ty) == null) continue;
        const layout = slotLayout(context, alloca.allocated_ty) orelse continue;
        const usage = uses.get(inst.result.?) orelse continue;
        if (!usage.scalar) continue;
        // Leave this object's allocation and uses intact; independent eligible
        // allocations can still receive their ordinary pointer-valued views.
        if (!usage.bounded) continue;
        if (!alloca.isSingleObject() or alloca.allocated_ty_addrspace != null) return null;
        var alignment = layout.alignment;
        if (alloca.attrs) |attrs| {
            const text = std.mem.trim(u8, attrs, " \t\r\n");
            if (!std.mem.startsWith(u8, text, "align ")) return null;
            const explicit = std.fmt.parseUnsigned(u32, std.mem.trim(u8, text[6..], " \t"), 10) catch return null;
            if (explicit == 0 or explicit > 16 or !std.math.isPowerOfTwo(explicit)) return null;
            alignment = @max(alignment, explicit);
        }
        try slots.put(inst.result.?, .{ .backing = try forms.temporary(allocator, function, &serial), .bytes = layout.bytes, .alignment = @max(4, alignment) });
    };
    if (slots.count() == 0) return null;
    var result = function;
    result.blocks = .empty;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            if (!inst.removed and inst.kind == .alloca and inst.result != null) if (slots.get(inst.result.?)) |slot| {
                var copy = inst;
                copy.result = slot.backing;
                copy.kind.alloca.allocated_ty = .{ .aggregate = try std.fmt.allocPrint(allocator, "[{d} x i32]", .{std.mem.alignForward(u32, @max(1, slot.bytes), 4) / 4}) };
                copy.kind.alloca.attrs = try std.fmt.allocPrint(allocator, "align {d}", .{slot.alignment});
                try block.instructions.append(allocator, copy);
                var indices: std.ArrayList(ir.GepIndex) = .empty;
                try indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
                try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .gep = .{
                    .source_ty = .{ .int = 8 },
                    .ptr = .{ .named = slot.backing },
                    .indices = indices,
                } } });
                continue;
            };
            try block.instructions.append(allocator, inst);
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
