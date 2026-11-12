//! Remove unreferenced spill-reserve chunks after lowering. Existing spill
//! homes and object extents remain distinct; object/incoming offsets are rebased
//! by a multiple of 16. Opaque stack uses retain the original machine function.
const std = @import("std");
const ir = @import("../../../ir.zig");
const state = @import("composed_selector_state.zig");
const machine = @import("../machine.zig");
const FrameIndex = @import("../types.zig").FrameIndex;

pub const Error = error{ OpaqueStackUse, InvalidStackDepth, InvalidFrameSetup };
const Rebase = struct {
    object_base: u32,
    live: ?[]bool = null,
    prefix: ?[]const u32 = null,
    delta: u32 = 0,

    fn offset(r: *Rebase, value: anytype, depth: u32, extent: u32, indexed: bool) Error!void {
        const T = @typeInfo(@TypeOf(value)).pointer.child;
        const raw = std.math.cast(u32, value.*) orelse return error.OpaqueStackUse;
        if (raw < depth) return; // Temporary outgoing arguments, below the frame.
        const normalized = raw - depth;
        if (indexed and normalized < r.object_base) return error.OpaqueStackUse;
        if (normalized < r.object_base) {
            const end = std.math.add(u32, normalized, extent) catch return error.OpaqueStackUse;
            if (r.live) |live| {
                const first = @min(normalized / 16, live.len);
                const last = @min((@as(u64, end) + 15) / 16, live.len);
                @memset(live[first..@intCast(last)], true);
            }
            if (r.prefix) |prefix| {
                const chunk = normalized / 16;
                const mapped = if (chunk + 1 < prefix.len) prefix[chunk] + normalized % 16 else normalized - r.delta;
                // Every byte of a multi-chunk access must retain its displacement
                // from the first byte. This also closes any accidental mismatch
                // between the observation and rewrite scans.
                const last = @min(end, r.object_base) - 1;
                const last_chunk = last / 16;
                const mapped_last = if (last_chunk + 1 < prefix.len) prefix[last_chunk] + last % 16 else last - r.delta;
                if (mapped_last - mapped != last - normalized) return error.OpaqueStackUse;
                value.* = std.math.cast(T, depth + mapped) orelse return error.OpaqueStackUse;
            }
        } else if (r.delta != 0) value.* = std.math.cast(T, raw - r.delta) orelse return error.OpaqueStackUse;
    }

    fn frameFields(r: *Rebase, payload: anytype, depth: u32) Error!void {
        const T = @typeInfo(@TypeOf(payload)).pointer.child;
        if (T == FrameIndex) {
            var displacement = payload.byteOffset() catch return error.OpaqueStackUse;
            try r.offset(&displacement, depth, 16, false);
            payload.* = FrameIndex.fromSlot(displacement / 4) catch return error.OpaqueStackUse;
        } else if (@typeInfo(T) == .@"struct") {
            inline for (@typeInfo(T).@"struct".field_names) |field| {
                if (@FieldType(T, field) == FrameIndex) try r.frameFields(&@field(payload, field), depth);
            }
        }
    }
};

fn adjustment(inst: machine.Instruction) ?struct { subtract: bool, bytes: u32 } {
    return switch (inst) {
        .sub_rsp_8 => .{ .subtract = true, .bytes = 8 },
        .sub_rsp_24 => .{ .subtract = true, .bytes = 24 },
        .sub_rsp_40 => .{ .subtract = true, .bytes = 40 },
        .sub_rsp_56 => .{ .subtract = true, .bytes = 56 },
        .sub_rsp_imm8 => |n| .{ .subtract = true, .bytes = n },
        .sub_rsp_imm32 => |n| .{ .subtract = true, .bytes = n },
        .add_rsp_8 => .{ .subtract = false, .bytes = 8 },
        .add_rsp_24 => .{ .subtract = false, .bytes = 24 },
        .add_rsp_40 => .{ .subtract = false, .bytes = 40 },
        .add_rsp_56 => .{ .subtract = false, .bytes = 56 },
        .add_rsp_imm8 => |n| .{ .subtract = false, .bytes = n },
        .add_rsp_imm32 => |n| .{ .subtract = false, .bytes = n },
        else => null,
    };
}

pub fn walk(r: anytype, code: []machine.Instruction, old_frame: u32) Error!void {
    @setEvalBranchQuota(200000);
    var depth: u32 = 0;
    var index: usize = 0;
    while (index < code.len) : (index += 1) {
        const inst = &code[index];
        if (@hasDecl(@typeInfo(@TypeOf(r)).pointer.child, "beginInstruction")) try r.beginInstruction(inst.*, index, depth);
        if (adjustment(inst.*)) |change| {
            if (!change.subtract and depth == 0 and change.bytes == old_frame) {
                if (r.delta != 0) inst.* = .{ .add_rsp_imm32 = old_frame - r.delta };
            } else if (change.subtract) {
                depth = std.math.add(u32, depth, change.bytes) catch return error.InvalidStackDepth;
            } else depth = std.math.sub(u32, depth, change.bytes) catch return error.InvalidStackDepth;
            continue;
        }
        if (inst.* == .mov_rsp_arg64) {
            if (index + 1 == code.len or code[index + 1] != .add_arg64_imm32 or
                code[index + 1].add_arg64_imm32.reg != inst.mov_rsp_arg64) return error.OpaqueStackUse;
            const add = &code[index + 1].add_arg64_imm32;
            const raw = std.math.cast(u32, add.imm) orelse return error.OpaqueStackUse;
            // Address-taken private spill storage has no proven bounded extent.
            if (raw >= depth and raw - depth < r.object_base) return error.OpaqueStackUse;
            try r.offset(&add.imm, depth, 1, false);
            index += 1;
            continue;
        }
        switch (inst.*) {
            .label, .jmp, .je, .jne, .jo, .jc, .jp, .js, .jae, .jle, .direct_jump, .ret, .ud2 => if (depth != 0) return error.InvalidStackDepth,
            .stack_probe_rax_rcx_rsp,
            .and_rsp_neg16,
            .mov_rsp_rdi,
            .spill_rdi_rsi_rsp24,
            .reload_rdi_rsp24,
            .reload_rsi_rsp24,
            => return error.OpaqueStackUse,
            else => {},
        }
        switch (inst.*) {
            inline else => |payload, tag| {
                const name = @tagName(tag);
                var next = payload;
                try r.frameFields(&next, depth);
                if (comptime std.mem.startsWith(u8, name, "load_stack_") or
                    std.mem.startsWith(u8, name, "store_eax_stack_") or
                    std.mem.startsWith(u8, name, "store_al_stack_") or
                    std.mem.eql(u8, name, "push_stack_disp8") or std.mem.eql(u8, name, "push_stack_disp32"))
                {
                    const indexed = comptime std.mem.indexOf(u8, name, "rcx4") != null;
                    if (@typeInfo(@TypeOf(next)) == .int) {
                        try r.offset(&next, depth, 16, indexed);
                    } else if (@typeInfo(@TypeOf(next)) == .@"struct" and @hasField(@TypeOf(next), "disp")) {
                        try r.offset(&next.disp, depth, 16, indexed);
                    } else return error.OpaqueStackUse;
                } else if (comptime std.mem.eql(u8, name, "push_byval_tail_stack_ptr")) {
                    try r.offset(&next.stack_disp, depth, 8, false);
                } else if (comptime std.mem.indexOf(u8, name, "stack") != null and
                    !std.mem.eql(u8, name, "push_byval_tail_arg_ptr")) return error.OpaqueStackUse;
                if (r.delta != 0) inst.* = @unionInit(machine.Instruction, name, next);
            },
        }
        switch (inst.*) {
            .push_arg,
            .push_rax,
            .push_imm32,
            .push_xmm64,
            .push_stack_disp8,
            .push_stack_disp32,
            .push_byval_tail_arg_ptr,
            .push_byval_tail_stack_ptr,
            => depth = std.math.add(u32, depth, 8) catch return error.InvalidStackDepth,
            .pop_arg => depth = std.math.sub(u32, depth, 8) catch return error.InvalidStackDepth,
            else => {},
        }
    }
    if (depth != 0) return error.InvalidStackDepth;
}

fn appendAllocation(a: std.mem.Allocator, code: *std.ArrayList(machine.Instruction), bytes: u32) !void {
    if (bytes < 4096) return code.append(a, .{ .sub_rsp_imm32 = bytes });
    var remaining = bytes;
    while (remaining >= 4096) : (remaining -= 4096) {
        try code.append(a, .{ .sub_rsp_imm32 = 4088 });
        try code.append(a, .{ .push_imm32 = 0 });
    }
    if (remaining != 0) {
        if (remaining > 8) try code.append(a, .{ .sub_rsp_imm32 = remaining - 8 });
        try code.append(a, .{ .push_imm32 = 0 });
    }
}

pub fn compact(selector: *state.ComposedBlockSelector, function: ir.Function) !void {
    if (selector.stack_frame_bytes < 65536) return;
    const old_frame = selector.stack_frame_bytes;
    if (old_frame % 16 != 8) return;
    var object_base = old_frame - 8;
    for (function.blocks.items) |block| for (block.instructions.items) |instruction| {
        if (instruction.removed or instruction.kind != .alloca) continue;
        const location = state.valueLoc(selector, instruction.result orelse continue) orelse return;
        const base: u32 = switch (location) {
            .stack_scalar => |slot| slot.base_disp,
            .stack128 => |offset| offset,
            .stack_i32_array => |array| array.base_disp,
            .stack_f32_pair_ptr => |pair| pair.object_base_disp,
            else => return,
        };
        if (base > old_frame) return;
        object_base = @min(object_base, base);
    };
    const begin = selector.frame_setup_begin;
    const end = selector.frame_setup_end;
    if (end <= begin or end > selector.machine.instructions.items.len) return;
    var reserved: u32 = 0;
    for (selector.machine.instructions.items[begin..end]) |instruction| {
        if (adjustment(instruction)) |change| {
            if (!change.subtract) return;
            reserved = std.math.add(u32, reserved, change.bytes) catch return;
        } else if (instruction == .push_imm32 and instruction.push_imm32 == 0) {
            reserved = std.math.add(u32, reserved, 8) catch return;
        } else return;
    }
    if (reserved != old_frame) return;
    // The final machine stream owns the exact accesses. Planned but never
    // referenced homes need no physical storage. Keep complete 16-byte chunks
    // so the mapping preserves every admitted access and stack alignment.
    const live = try selector.allocator.alloc(bool, object_base / 16);
    defer selector.allocator.free(live);
    @memset(live, false);
    var analysis: Rebase = .{ .object_base = object_base, .live = live };
    walk(&analysis, selector.machine.instructions.items[end..], old_frame) catch return;
    const prefix = try selector.allocator.alloc(u32, live.len + 1);
    defer selector.allocator.free(prefix);
    prefix[0] = 0;
    for (live, 0..) |used, i| prefix[i + 1] = prefix[i] + @as(u32, if (used) 16 else 0);
    const delta = @as(u32, @intCast(live.len * 16)) - prefix[live.len];
    if (try compactHomes(selector, old_frame, object_base, begin, end, delta)) return;
    if (delta < 65536) return;
    var candidate: std.ArrayList(machine.Instruction) = .empty;
    errdefer candidate.deinit(selector.allocator);
    try candidate.appendSlice(selector.allocator, selector.machine.instructions.items[0..begin]);
    try appendAllocation(selector.allocator, &candidate, old_frame - delta);
    const body = candidate.items.len;
    try candidate.appendSlice(selector.allocator, selector.machine.instructions.items[end..]);
    var rebase: Rebase = .{ .object_base = object_base, .prefix = prefix, .delta = delta };
    walk(&rebase, candidate.items[body..], old_frame) catch {
        candidate.deinit(selector.allocator);
        return;
    };
    var checked = selector.machine.*;
    checked.instructions = candidate;
    @import("../verify.zig").verifyFunction(checked) catch {
        candidate.deinit(selector.allocator);
        return;
    };
    selector.machine.instructions.deinit(selector.allocator);
    selector.machine.instructions = candidate;
    selector.stack_frame_bytes = old_frame - delta;
}

fn compactHomes(selector: *state.ComposedBlockSelector, old_frame: u32, object_base: u32, begin: usize, end: usize, unused_delta: u32) !bool {
    const homes = @import("machine_stack_homes.zig");
    var arena = std.heap.ArenaAllocator.init(selector.allocator);
    defer arena.deinit();
    const mapping = (try homes.analyze(arena.allocator(), selector.machine.instructions.items[end..], old_frame, object_base)) orelse return false;
    if (mapping.delta < 65536) return false;
    // Keep the existing gap-only result whenever it is at least as compact.
    // Require a further page of savings before paying for a changed placement.
    if (mapping.delta <= unused_delta or mapping.delta - unused_delta < 4096) return false;
    var candidate: std.ArrayList(machine.Instruction) = .empty;
    errdefer candidate.deinit(selector.allocator);
    try candidate.appendSlice(selector.allocator, selector.machine.instructions.items[0..begin]);
    try appendAllocation(selector.allocator, &candidate, old_frame - mapping.delta);
    const body = candidate.items.len;
    try candidate.appendSlice(selector.allocator, selector.machine.instructions.items[end..]);
    homes.rewrite(candidate.items[body..], old_frame, mapping) catch {
        candidate.deinit(selector.allocator);
        return false;
    };
    var checked = selector.machine.*;
    checked.instructions = candidate;
    @import("../verify.zig").verifyFunction(checked) catch {
        candidate.deinit(selector.allocator);
        return false;
    };
    selector.machine.instructions.deinit(selector.allocator);
    selector.machine.instructions = candidate;
    selector.stack_frame_bytes = old_frame - mapping.delta;
    return true;
}
