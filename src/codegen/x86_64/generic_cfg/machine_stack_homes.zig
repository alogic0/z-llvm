//! Final machine-memory liveness, independent of SSA homes and alias guesses.
//! Overlapping accesses form indivisible four-byte-cell groups. Partial writes
//! never kill a group; every access, including dead stores, spans its interval.
const std = @import("std");
const machine = @import("../machine.zig");
const FrameIndex = @import("../types.zig").FrameIndex;
const walker = @import("frame_compaction.zig");
const Error = walker.Error;
const absent = std.math.maxInt(u32);
const Access = struct { position: u32, offset: u32, bytes: u32, write: bool, group: u32 = absent };
const Effect = struct { bytes: u32, write: bool };
fn effect(instruction: machine.Instruction) ?Effect {
    return switch (instruction) {
        .spill_eax_rsp, .spill_arg_rsp, .spill_xmm32_rsp => .{ .bytes = 4, .write = true },
        .spill_rax_rsp, .spill_arg64_rsp, .spill_xmm64_rsp => .{ .bytes = 8, .write = true },
        .spill_xmm128_rsp, .spill_xmm128ps_rsp => .{ .bytes = 16, .write = true },
        .reload_rsp_eax, .reload_arg_rsp, .reload_xmm32_rsp => .{ .bytes = 4, .write = false },
        .reload_rsp_rax, .reload_arg64_rsp, .reload_xmm64_rsp, .imul_rax_rsp => .{ .bytes = 8, .write = false },
        .reload_xmm128_rsp, .reload_xmm128ps_rsp => .{ .bytes = 16, .write = false },
        .load_stack_disp8_eax, .load_stack_disp32_eax, .load_stack_disp8_xmm0_f32, .load_stack_disp32_xmm0_f32, .load_stack_disp8_xmm_f32, .load_stack_disp32_xmm_f32, .load_stack_disp8_arg32, .load_stack_disp32_arg32 => .{ .bytes = 4, .write = false },
        .load_stack_disp8_rax, .load_stack_disp32_rax, .load_stack_disp8_xmm0, .load_stack_disp32_xmm0, .load_stack_disp8_xmm, .load_stack_disp32_xmm, .load_stack_disp8_arg64, .load_stack_disp32_arg64, .push_stack_disp8, .push_stack_disp32, .push_byval_tail_stack_ptr => .{ .bytes = 8, .write = false },
        .load_stack_disp8_u8_eax, .load_stack_disp32_u8_eax => .{ .bytes = 1, .write = false },
        .load_stack_disp8_u16_eax, .load_stack_disp32_u16_eax => .{ .bytes = 2, .write = false },
        .store_eax_stack_disp8, .store_eax_stack_disp32 => .{ .bytes = 4, .write = true },
        .store_al_stack_disp8, .store_al_stack_disp32 => .{ .bytes = 1, .write = true },
        else => null,
    };
}
const Walk = struct {
    object_base: u32,
    delta: u32 = 0,
    accesses: ?*std.ArrayList(Access) = null,
    mapping: ?[]const u32 = null,
    position: u32 = 0,
    current: ?Effect = null,
    pub fn beginInstruction(w: *Walk, inst: machine.Instruction, index: usize, depth: u32) Error!void {
        if (inst == .indirect_jump and depth != 0) return error.InvalidStackDepth;
        w.position = @intCast(index);
        w.current = effect(inst);
    }
    pub fn offset(w: *Walk, value: anytype, depth: u32, _: u32, indexed: bool) Error!void {
        const T = @typeInfo(@TypeOf(value)).pointer.child;
        const raw = std.math.cast(u32, value.*) orelse return error.OpaqueStackUse;
        if (raw < depth) return;
        const offset_bytes = raw - depth;
        if (offset_bytes >= w.object_base) {
            if (w.delta != 0) value.* = std.math.cast(T, raw - w.delta) orelse return error.OpaqueStackUse;
            return;
        }
        if (indexed) return error.OpaqueStackUse;
        const e = w.current orelse return error.OpaqueStackUse;
        const end = std.math.add(u32, offset_bytes, e.bytes) catch return error.OpaqueStackUse;
        if (end > w.object_base) return error.OpaqueStackUse;
        if (w.accesses) |accesses| {
            if (accesses.items.len != 0 and accesses.items[accesses.items.len - 1].position == w.position) return error.OpaqueStackUse;
            accesses.appendAssumeCapacity(.{ .position = w.position, .offset = offset_bytes, .bytes = e.bytes, .write = e.write });
        }
        if (w.mapping) |mapping| {
            const mapped = mapping[offset_bytes / 4] + offset_bytes % 4;
            const last = end - 1;
            const mapped_last = mapping[last / 4] + last % 4;
            if (mapped_last < mapped or mapped_last - mapped != e.bytes - 1) return error.OpaqueStackUse;
            value.* = std.math.cast(T, depth + mapped) orelse return error.OpaqueStackUse;
        }
    }
    pub fn frameFields(w: *Walk, payload: anytype, depth: u32) Error!void {
        const T = @typeInfo(@TypeOf(payload)).pointer.child;
        if (T == FrameIndex) {
            var displacement = payload.byteOffset() catch return error.OpaqueStackUse;
            try w.offset(&displacement, depth, 0, false);
            payload.* = FrameIndex.fromSlot(displacement / 4) catch return error.OpaqueStackUse;
        } else if (@typeInfo(T) == .@"struct") {
            inline for (@typeInfo(T).@"struct".field_names) |field| if (@FieldType(T, field) == FrameIndex) try w.frameFields(&@field(payload, field), depth);
        }
    }
};
const Group = struct { begin: u32, end: u32, first: u32 = absent, last: u32 = 0, mapped: u32 = absent };
const Block = struct {
    begin: u32,
    end: u32,
    access_begin: u32 = 0,
    access_end: u32 = 0,
    successors: std.ArrayList(u32) = .empty,
    predecessors: std.ArrayList(u32) = .empty,
};
fn target(inst: machine.Instruction) ?[]const u8 {
    return switch (inst) {
        .je, .jne, .jo, .jc, .jp, .js, .jae, .jle, .jmp => |name| name,
        else => null,
    };
}
fn endsBlock(inst: machine.Instruction) bool {
    return target(inst) != null or inst == .indirect_jump or inst == .direct_jump or inst == .ret or inst == .ud2;
}
fn root(parent: []u32, id: u32) u32 {
    var r = id;
    while (parent[r] != r) r = parent[r];
    var n = id;
    while (parent[n] != n) {
        const next = parent[n];
        parent[n] = r;
        n = next;
    }
    return r;
}
fn bitSet(row: []u64, id: u32, value: bool) void {
    const flag = @as(u64, 1) << @as(u6, @intCast(id % 64));
    if (value) row[id / 64] |= flag else row[id / 64] &= ~flag;
}
pub const Result = struct {
    object_base: u32,
    delta: u32,
    mapping: []u32,
    groups: usize,
    blocks: usize,
    liveness_bytes: usize,
    old_spill_bytes: u32,
    new_spill_bytes: u32,
};
pub fn analyze(a: std.mem.Allocator, code: []machine.Instruction, old_frame: u32, raw_object_base: u32) !?Result {
    return analyzeClosed(a, code, old_frame, raw_object_base) catch |err| switch (err) {
        error.OpaqueStackUse, error.InvalidStackDepth, error.InvalidFrameSetup => null,
        else => return err,
    };
}
fn analyzeClosed(a: std.mem.Allocator, code: []machine.Instruction, old_frame: u32, raw_object_base: u32) !?Result {
    if (raw_object_base > old_frame or old_frame > 8 * 1024 * 1024 or old_frame % 16 != 8) return null;
    if (code.len == 0 or code.len > 1_000_000 or raw_object_base > 8 * 1024 * 1024) return null;
    const object_base = std.mem.alignBackward(u32, raw_object_base, 16);
    if (object_base < 65536) return null;
    var accesses = try std.ArrayList(Access).initCapacity(a, code.len);
    var observe: Walk = .{ .object_base = object_base, .accesses = &accesses };
    try walker.walk(&observe, code, old_frame);
    if (accesses.items.len == 0) return null;
    const cells = object_base / 4;
    const parent = try a.alloc(u32, cells);
    @memset(parent, absent);
    for (accesses.items) |access| {
        const first = access.offset / 4;
        const end = (access.offset + access.bytes + 3) / 4;
        for (first..end) |i| if (parent[i] == absent) {
            parent[i] = @intCast(i);
        };
        for (first + 1..end) |i| {
            const x = root(parent, first);
            const y = root(parent, @intCast(i));
            parent[@max(x, y)] = @min(x, y);
        }
    }
    var groups: std.ArrayList(Group) = .empty;
    const cell_group = try a.alloc(u32, cells);
    @memset(cell_group, absent);
    var ids = std.AutoHashMap(u32, u32).init(a);
    for (parent, 0..) |p, i| {
        if (p == absent) continue;
        const r = root(parent, @intCast(i));
        const e = try ids.getOrPut(r);
        if (!e.found_existing) {
            e.value_ptr.* = @intCast(groups.items.len);
            try groups.append(a, .{ .begin = @intCast(i * 4), .end = @intCast(i * 4 + 4) });
        }
        cell_group[i] = e.value_ptr.*;
        groups.items[e.value_ptr.*].end = @intCast(i * 4 + 4);
    }
    for (accesses.items) |*access| {
        access.group = cell_group[access.offset / 4];
        const g = &groups.items[access.group];
        if (g.end - g.begin > 65536) return null;
        g.first = @min(g.first, access.position);
        g.last = @max(g.last, access.position);
    }
    const leaders = try a.alloc(bool, code.len + 1);
    @memset(leaders, false);
    leaders[0] = true;
    for (code, 0..) |inst, i| {
        if (inst == .label) leaders[i] = true;
        if (endsBlock(inst) and i + 1 < code.len) leaders[i + 1] = true;
    }
    var blocks: std.ArrayList(Block) = .empty;
    for (leaders[0..code.len], 0..) |leader, i| if (leader) {
        if (blocks.items.len != 0) blocks.items[blocks.items.len - 1].end = @intCast(i);
        try blocks.append(a, .{ .begin = @intCast(i), .end = @intCast(code.len) });
    };
    if (blocks.items.len > 65536) return null;
    var labels = std.StringHashMap(u32).init(a);
    var access_index: usize = 0;
    for (blocks.items, 0..) |*block, i| {
        if (code[block.begin] == .label) {
            const e = try labels.getOrPut(code[block.begin].label);
            if (e.found_existing) return error.OpaqueStackUse;
            e.value_ptr.* = @intCast(i);
        }
        block.access_begin = @intCast(access_index);
        while (access_index < accesses.items.len and accesses.items[access_index].position < block.end) access_index += 1;
        block.access_end = @intCast(access_index);
    }
    for (blocks.items, 0..) |*block, i| {
        const last = code[block.end - 1];
        if (target(last)) |name| try block.successors.append(a, labels.get(name) orelse return error.OpaqueStackUse);
        if (last == .indirect_jump) {
            for (last.indirect_jump.targets) |name| try block.successors.append(a, labels.get(name) orelse return error.OpaqueStackUse);
        } else if (last != .jmp and last != .direct_jump and last != .ret and last != .ud2 and i + 1 < blocks.items.len)
            try block.successors.append(a, @intCast(i + 1));
    }
    for (blocks.items, 0..) |block, i| for (block.successors.items) |s| try blocks.items[s].predecessors.append(a, @intCast(i));
    const memory = (try extendIntervals(a, groups.items, blocks.items, accesses.items)) orelse return null;
    return assign(a, object_base, groups.items, cell_group, blocks.items.len, memory);
}

// Each memory group has independent gen/kill equations. Solve fixed batches;
// no inter-group approximation or changed interference relation is introduced.
fn extendIntervals(a: std.mem.Allocator, groups: []Group, blocks: []const Block, accesses: []const Access) !?usize {
    const batch_groups = 4096;
    const max_words = (@min(groups.len, batch_groups) + 63) / 64;
    const table_words = std.math.mul(usize, max_words, blocks.len) catch return null;
    const table_bytes = std.math.mul(usize, table_words, 8) catch return null;
    if (table_bytes > 64 * 1024 * 1024) return null;
    const live = try a.alloc(u64, table_words);
    const temp = try a.alloc(u64, max_words);
    const pending = try a.alloc(bool, blocks.len);
    var work: std.ArrayList(u32) = .empty;
    var group_begin: usize = 0;
    while (group_begin < groups.len) : (group_begin += batch_groups) {
        const group_end = @min(groups.len, group_begin + batch_groups);
        const words = (group_end - group_begin + 63) / 64;
        @memset(live, 0);
        @memset(pending, true);
        work.clearRetainingCapacity();
        for (blocks, 0..) |_, i| try work.append(a, @intCast(i));
        var steps: usize = 0;
        while (work.pop()) |index| {
            steps += 1;
            if (steps > @max(4096, blocks.len * 128)) return null;
            pending[index] = false;
            const block = blocks[index];
            @memset(temp[0..words], 0);
            for (block.successors.items) |s| for (temp[0..words], live[s * words ..][0..words]) |*v, next| {
                v.* |= next;
            };
            var at: usize = block.access_end;
            while (at > block.access_begin) {
                at -= 1;
                const access = accesses[at];
                if (access.group < group_begin or access.group >= group_end) continue;
                const local: u32 = @intCast(access.group - group_begin);
                const g = groups[access.group];
                if (!access.write) bitSet(temp[0..words], local, true) else if (access.offset == g.begin and access.bytes == g.end - g.begin) bitSet(temp[0..words], local, false);
            }
            const row = live[index * words ..][0..words];
            if (!std.mem.eql(u64, row, temp[0..words])) {
                @memcpy(row, temp[0..words]);
                for (block.predecessors.items) |p| if (!pending[p]) {
                    pending[p] = true;
                    try work.append(a, p);
                };
            }
        }
        for (blocks, 0..) |block, i| {
            @memset(temp[0..words], 0);
            for (block.successors.items) |s| for (temp[0..words], live[s * words ..][0..words]) |*v, next| {
                v.* |= next;
            };
            for (live[i * words ..][0..words], temp[0..words], 0..) |incoming, outgoing, wi| {
                var bits = incoming | outgoing;
                while (bits != 0) {
                    const bit: u6 = @intCast(@ctz(bits));
                    const g = &groups[group_begin + wi * 64 + bit];
                    if (incoming & (@as(u64, 1) << bit) != 0) g.first = @min(g.first, block.begin);
                    if (outgoing & (@as(u64, 1) << bit) != 0) g.last = @max(g.last, block.end - 1);
                    bits &= bits - 1;
                }
            }
        }
    }
    return table_bytes;
}

fn key(g: Group) u64 {
    return @as(u64, g.end - g.begin) * 16 + g.begin % 16;
}
fn before(groups: []const Group, x: u32, y: u32) bool {
    return groups[x].last < groups[y].last;
}
fn popActive(active: *std.ArrayList(u32), groups: []const Group) u32 {
    const result = active.items[0];
    const last = active.pop().?;
    if (active.items.len == 0) return result;
    active.items[0] = last;
    var at: usize = 0;
    while (at * 2 + 1 < active.items.len) {
        var child = at * 2 + 1;
        if (child + 1 < active.items.len and before(groups, active.items[child + 1], active.items[child])) child += 1;
        if (!before(groups, active.items[child], active.items[at])) break;
        std.mem.swap(u32, &active.items[child], &active.items[at]);
        at = child;
    }
    return result;
}
fn assign(a: std.mem.Allocator, object_base: u32, groups: []Group, cell_group: []const u32, blocks: usize, table_bytes: usize) !?Result {
    const order = try a.alloc(u32, groups.len);
    var reserved: u32 = 256;
    for (groups, 0..) |*g, i| {
        order[i] = @intCast(i);
        if (g.begin < 256) {
            g.mapped = g.begin;
            reserved = @max(reserved, g.end);
        }
    }
    var cursor = std.mem.alignForward(u32, reserved, 16);
    std.mem.sort(u32, order, groups, struct {
        fn less(gs: []Group, x: u32, y: u32) bool {
            return if (gs[x].first == gs[y].first) gs[x].begin < gs[y].begin else gs[x].first < gs[y].first;
        }
    }.less);
    var free = std.AutoHashMap(u64, std.ArrayList(u32)).init(a);
    var active: std.ArrayList(u32) = .empty;
    for (order) |index| {
        const g = &groups[index];
        if (g.mapped != absent) continue;
        while (active.items.len != 0 and groups[active.items[0]].last < g.first) {
            const old = groups[popActive(&active, groups)];
            const e = try free.getOrPut(key(old));
            if (!e.found_existing) e.value_ptr.* = .empty;
            try e.value_ptr.append(a, old.mapped);
        }
        const e = try free.getOrPut(key(g.*));
        if (!e.found_existing) e.value_ptr.* = .empty;
        if (e.value_ptr.pop()) |location| g.mapped = location else {
            cursor += (g.begin % 16 + 16 - cursor % 16) % 16;
            g.mapped = cursor;
            cursor += g.end - g.begin;
            if (cursor >= object_base) return null;
        }
        try active.append(a, index);
        var at = active.items.len - 1;
        while (at != 0) {
            const parent = (at - 1) / 2;
            if (!before(groups, active.items[at], active.items[parent])) break;
            std.mem.swap(u32, &active.items[at], &active.items[parent]);
            at = parent;
        }
    }
    cursor = std.mem.alignForward(u32, cursor, 16);
    if (cursor >= object_base) return null;
    // Independently check the proposed placement at four-byte resolution.
    // Closed live intervals sharing any cell would overwrite a live value.
    const occupied_until = try a.alloc(u32, cursor / 4);
    @memset(occupied_until, absent);
    for (order) |index| {
        const g = groups[index];
        if (g.mapped % 16 != g.begin % 16 or g.mapped + g.end - g.begin > cursor) return error.OpaqueStackUse;
        for (g.mapped / 4..(g.mapped + g.end - g.begin) / 4) |cell| {
            if (occupied_until[cell] != absent and occupied_until[cell] >= g.first) return error.OpaqueStackUse;
            occupied_until[cell] = g.last;
        }
    }
    const mapping = try a.alloc(u32, cell_group.len);
    for (cell_group, 0..) |id, cell| mapping[cell] = if (id == absent) absent else groups[id].mapped + @as(u32, @intCast(cell * 4)) - groups[id].begin;
    return .{ .object_base = object_base, .delta = object_base - cursor, .mapping = mapping, .groups = groups.len, .blocks = blocks, .liveness_bytes = table_bytes, .old_spill_bytes = object_base, .new_spill_bytes = cursor };
}
pub fn rewrite(code: []machine.Instruction, old_frame: u32, result: Result) !void {
    var r: Walk = .{ .object_base = result.object_base, .delta = result.delta, .mapping = result.mapping };
    try walker.walk(&r, code, old_frame);
}
