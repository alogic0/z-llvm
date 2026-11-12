//! Reuse only complete static objects whose explicit LLVM lifetimes cannot
//! overlap on any CFG path. Source IR, spill homes and ABI remain unchanged.
const std = @import("std");
const ir = @import("../../../ir.zig");
const cfg = @import("../../../analysis/cfg.zig");
const machine = @import("../machine.zig");
const storage = @import("storage_layout.zig");
const forms = @import("scalar_forms.zig");

const Object = struct {
    name: []const u8,
    bytes: u32 = 0,
    alignment: u32 = 0,
    starts: bool = false,
    ends: bool = false,
    color: ?usize = null,
    fn eligible(o: Object) bool {
        return o.bytes != 0 and o.starts and o.ends;
    }
};
const Event = struct { object: usize, start: bool };
const Group = struct { members: []u64, bytes: u32, alignment: u32, name: []const u8 = "" };

fn set(bits: []u64, index: usize) void {
    bits[index / 64] |= @as(u64, 1) << @intCast(index % 64);
}
fn unset(bits: []u64, index: usize) void {
    bits[index / 64] &= ~(@as(u64, 1) << @intCast(index % 64));
}
fn row(bits: []u64, index: usize, words: usize) []u64 {
    return bits[index * words ..][0..words];
}
fn conflict(a: []const u64, b: []const u64) bool {
    for (a, b) |x, y| if (x & y != 0) return true;
    return false;
}
fn connect(edges: []u64, live: []const u64, object: usize, words: usize) void {
    const target = row(edges, object, words);
    for (target, live) |*value, word| value.* |= word;
    for (live, 0..) |word, wi| {
        var pending = word;
        while (pending != 0) {
            const bit: usize = @intCast(@ctz(pending));
            set(row(edges, wi * 64 + bit, words), object);
            pending &= pending - 1;
        }
    }
}

pub fn legalize(a: std.mem.Allocator, source: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (source.blocks.items.len == 0 or source.blocks.items.len > 65536) return null;
    // Analysis bitset tables have a checked 64 MiB envelope, independent of generated
    // frame/object authority. A declined optimization retains the original IR.
    var scratch = std.heap.ArenaAllocator.init(a);
    defer scratch.deinit();
    const s = scratch.allocator();
    var names: cfg.BlockIndexes = .empty;
    var objects: std.ArrayList(Object) = .empty;
    for (source.blocks.items, 0..) |block, bi| for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        if (bi == 0 and inst.kind == .phi) return null;
        if (inst.kind != .alloca) continue;
        const name = inst.result orelse return null;
        if (objects.items.len == 8192) return null;
        const entry = try names.getOrPut(s, name);
        if (entry.found_existing) return null;
        entry.value_ptr.* = objects.items.len;
        var object: Object = .{ .name = name };
        const alloca = inst.kind.alloca;
        if (bi == 0 and alloca.isSingleObject() and alloca.allocated_ty_addrspace == null) {
            if (storage.query(context, alloca.allocated_ty)) |layout| {
                const attrs = std.mem.trim(u8, alloca.attrs orelse "", " \t");
                const alignment = if (attrs.len == 0) layout.alignment else if (std.mem.startsWith(u8, attrs, "align "))
                    std.fmt.parseUnsigned(u32, attrs[6..], 10) catch 0
                else
                    0;
                if (layout.bytes != 0 and layout.bytes <= 65536 and alignment != 0 and alignment <= 16 and std.math.isPowerOfTwo(alignment)) {
                    object.bytes = layout.bytes;
                    object.alignment = @max(alignment, layout.alignment);
                }
            }
        }
        try objects.append(s, object);
    };
    if (objects.items.len < 2) return null;
    const words = (objects.items.len + 63) / 64;
    const block_words = std.math.mul(usize, source.blocks.items.len, words) catch return null;
    const edge_words = std.math.mul(usize, objects.items.len, words) catch return null;
    const memory_words = std.math.add(usize, std.math.mul(usize, block_words, 3) catch return null, std.math.mul(usize, edge_words, 2) catch return null) catch return null;
    if (memory_words > (64 * 1024 * 1024) / 8) return null;
    const events = try s.alloc(std.ArrayList(Event), source.blocks.items.len);
    @memset(events, .empty);
    for (source.blocks.items, 0..) |block, bi| for (block.instructions.items) |inst| {
        if (inst.removed or inst.kind != .call) continue;
        const call = inst.kind.call;
        const start = ir.identifiers.eql(call.callee, "llvm.lifetime.start.p0");
        const end = ir.identifiers.eql(call.callee, "llvm.lifetime.end.p0");
        if (!start and !end) continue;
        if (inst.result != null or call.ret_ty != .void or call.args.items.len != 1 or call.args.items[0].ty != .ptr or
            call.inline_asm != null or call.callee_value != null or call.raw_args != null or call.operand_bundle != null or call.args.items[0].value != .named) return null;
        // An unclassified marker might restart an alias after a direct end.
        // Keep the whole function unchanged rather than ignoring that event.
        const oi = names.get(call.args.items[0].value.named) orelse return null;
        if (start) objects.items[oi].starts = true else objects.items[oi].ends = true;
        try events[bi].append(s, .{ .object = oi, .start = start });
    };
    var total: u64 = 0;
    var eligible: std.ArrayList(usize) = .empty;
    for (objects.items, 0..) |object, oi| if (object.eligible()) {
        total += std.mem.alignForward(u32, object.bytes, 16);
        try eligible.append(s, oi);
    };
    if (total < 65536 or eligible.items.len < 2) return null;
    var graph = cfg.Graph.build(s, source) catch |err| switch (err) {
        error.OutOfMemory => return err,
        else => return null,
    };
    defer graph.deinit();
    const generated = try s.alloc(u64, block_words);
    const killed = try s.alloc(u64, block_words);
    const outputs = try s.alloc(u64, block_words);
    @memset(generated, 0);
    @memset(killed, 0);
    @memset(outputs, 0);
    for (events, 0..) |block_events, bi| for (block_events.items) |event| {
        if (!objects.items[event.object].eligible()) continue;
        set(row(killed, bi, words), event.object);
        if (event.start) set(row(generated, bi, words), event.object) else unset(row(generated, bi, words), event.object);
    };
    const live = try s.alloc(u64, words);
    const queued = try s.alloc(bool, source.blocks.items.len);
    @memset(queued, true);
    var pending: std.ArrayList(usize) = .empty;
    for (source.blocks.items, 0..) |_, bi| try pending.append(s, source.blocks.items.len - 1 - bi);
    while (pending.pop()) |bi| {
        queued[bi] = false;
        @memset(live, 0);
        for (graph.predecessors(bi)) |pred| for (live, row(outputs, pred, words)) |*word, other| {
            word.* |= other;
        };
        const output = row(outputs, bi, words);
        var changed = false;
        for (live, row(killed, bi, words), row(generated, bi, words), output) |input, kill, gen, *old| {
            const next = (input & ~kill) | gen;
            changed = changed or old.* != next;
            old.* = next;
        }
        if (changed) for (graph.successors(bi)) |successor| {
            if (!queued[successor]) {
                queued[successor] = true;
                try pending.append(s, successor);
            }
        };
    }
    const edges = try s.alloc(u64, edge_words);
    @memset(edges, 0);
    for (events, 0..) |block_events, bi| {
        @memset(live, 0);
        for (graph.predecessors(bi)) |pred| for (live, row(outputs, pred, words)) |*word, other| {
            word.* |= other;
        };
        // All admitted objects are initially dead. Any real overlap must
        // therefore start at a lifetime.start while the other object may be
        // alive. Do not invent overlap merely by joining mutually exclusive
        // predecessor states; retain the conservative may-live union at starts.
        for (block_events.items) |event| {
            if (!objects.items[event.object].eligible()) continue;
            if (event.start) {
                set(live, event.object);
                connect(edges, live, event.object, words);
            } else unset(live, event.object);
        }
    }
    std.mem.sort(usize, eligible.items, objects.items, struct {
        fn less(all: []Object, x: usize, y: usize) bool {
            return if (all[x].bytes == all[y].bytes) x < y else all[x].bytes > all[y].bytes;
        }
    }.less);
    var groups: std.ArrayList(Group) = .empty;
    for (eligible.items) |oi| {
        const object = &objects.items[oi];
        const color = for (groups.items, 0..) |group, gi| {
            if (!conflict(row(edges, oi, words), group.members)) break gi;
        } else blk: {
            const members = try s.alloc(u64, words);
            @memset(members, 0);
            try groups.append(s, .{ .members = members, .bytes = object.bytes, .alignment = object.alignment });
            break :blk groups.items.len - 1;
        };
        object.color = color;
        set(groups.items[color].members, oi);
        groups.items[color].alignment = @max(groups.items[color].alignment, object.alignment);
    }
    var after: u64 = 0;
    for (groups.items) |group| after += std.mem.alignForward(u32, group.bytes, 16);
    if (after > total or total - after < 4096) return null;
    var result = source;
    result.blocks = .empty;
    var serial: forms.TemporaryNames = .{ .prefix = "__zllvm_lifetime_storage_" };
    defer serial.deinit(a);
    for (groups.items) |*group| group.name = try forms.temporary(a, source, &serial);
    for (source.blocks.items, 0..) |original, bi| {
        var block = original;
        block.instructions = .empty;
        if (bi == 0) for (groups.items) |group| {
            try block.instructions.append(a, .{ .result = group.name, .kind = .{ .alloca = .{
                .allocated_ty = .{ .aggregate = try std.fmt.allocPrint(a, "[{d} x i8]", .{group.bytes}) },
                .attrs = try std.fmt.allocPrint(a, "align {d}", .{group.alignment}),
            } } });
        };
        for (original.instructions.items) |inst| {
            if (!inst.removed and inst.kind == .call and
                (ir.identifiers.eql(inst.kind.call.callee, "llvm.lifetime.start.p0") or ir.identifiers.eql(inst.kind.call.callee, "llvm.lifetime.end.p0")))
            {
                const oi = names.get(inst.kind.call.args.items[0].value.named) orelse return null;
                if (objects.items[oi].color != null) continue;
            }
            if (!inst.removed and inst.kind == .alloca) if (names.get(inst.result orelse return null)) |oi| if (objects.items[oi].color) |color| {
                var indices: std.ArrayList(ir.GepIndex) = .empty;
                try indices.append(a, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
                try block.instructions.append(a, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .gep = .{
                    .source_ty = .{ .int = 8 },
                    .ptr = .{ .named = groups.items[color].name },
                    .indices = indices,
                } } });
                continue;
            };
            try block.instructions.append(a, inst);
        }
        try result.blocks.append(a, block);
    }
    return result;
}
