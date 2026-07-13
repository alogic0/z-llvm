const std = @import("std");
const core = @import("core.zig");

pub const Lane = union(enum) {
    int: i128,
    fp: []const u8,
    undef,
    poison,
    null_value,
    zero_initializer,

    pub fn isDefined(lane: Lane) bool {
        return lane != .undef and lane != .poison;
    }

    pub fn value(lane: Lane) core.Value {
        return switch (lane) {
            .int => |int_value| .{ .int = int_value },
            .fp => |text| .{ .fp = text },
            .undef => .undef,
            .poison => .poison,
            .null_value => .null_value,
            .zero_initializer => .zero_initializer,
        };
    }
};

pub fn Fixed(comptime lane_count: usize) type {
    return struct {
        elem_ty: core.VectorElementType,
        lanes: [lane_count]Lane,
    };
}

pub fn parseFixed(comptime lane_count: usize, value: core.Value, vector_ty: core.VectorType) ?Fixed(lane_count) {
    if (vector_ty.len != lane_count) return null;
    var result: Fixed(lane_count) = .{
        .elem_ty = vector_ty.elem_ty,
        .lanes = undefined,
    };
    switch (value) {
        .zero_initializer => @memset(&result.lanes, .zero_initializer),
        .undef => @memset(&result.lanes, .undef),
        .poison => @memset(&result.lanes, .poison),
        .vector => |raw| {
            const text = std.mem.trim(u8, raw, " \t");
            if (std.mem.startsWith(u8, text, "splat (") and std.mem.endsWith(u8, text, ")")) {
                const lane = parseTypedLane(text["splat (".len .. text.len - 1], vector_ty.elem_ty) orelse return null;
                @memset(&result.lanes, lane);
            } else {
                if (text.len < 2 or text[0] != '<' or text[text.len - 1] != '>') return null;
                var rest = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
                for (&result.lanes, 0..) |*lane, index| {
                    if (rest.len == 0) return null;
                    const comma = findTopLevelComma(rest);
                    if (index + 1 == lane_count and comma != null) return null;
                    if (index + 1 != lane_count and comma == null) return null;
                    const lane_text = if (comma) |at| rest[0..at] else rest;
                    lane.* = parseTypedLane(lane_text, vector_ty.elem_ty) orelse return null;
                    rest = if (comma) |at| std.mem.trim(u8, rest[at + 1 ..], " \t") else "";
                }
                if (rest.len != 0) return null;
            }
        },
        else => return null,
    }
    return result;
}

pub fn isSplatMask(
    comptime lane_count: usize,
    shuffle: core.ShuffleVectorInst,
    source_lane: i128,
) bool {
    if (shuffle.lhs_ty != .vector or shuffle.rhs_ty != .vector or shuffle.mask_ty != .vector) return false;
    if (!shuffle.rhs_ty.eql(shuffle.lhs_ty) or shuffle.lhs_ty.vector.len != lane_count) return false;
    const mask_ty = shuffle.mask_ty.vector;
    if (mask_ty.len != lane_count or mask_ty.elem_ty != .int) return false;
    const parsed = parseFixed(lane_count, shuffle.mask, mask_ty) orelse return false;
    for (parsed.lanes) |lane| switch (lane) {
        .int => |value| if (value != source_lane) return false,
        .zero_initializer => if (source_lane != 0) return false,
        else => return false,
    };
    return true;
}

pub const Packed2ShuffleMask = enum {
    splat_lane0,
    lane1_to_lane0,
    f64_lane0_lane3,
};

pub fn classifyPacked2ShuffleMask(shuffle: core.ShuffleVectorInst) ?Packed2ShuffleMask {
    if (shuffle.lhs_ty != .vector or shuffle.rhs_ty != .vector or shuffle.mask_ty != .vector) return null;
    if (!shuffle.rhs_ty.eql(shuffle.lhs_ty) or shuffle.lhs_ty.vector.len != 2) return null;
    const mask_ty = shuffle.mask_ty.vector;
    if (mask_ty.len != 2 or mask_ty.elem_ty != .int or mask_ty.elem_ty.int != 32) return null;
    const parsed = parseFixed(2, shuffle.mask, mask_ty) orelse return null;
    if (maskLaneEquals(parsed.lanes[0], 0) and maskLaneEquals(parsed.lanes[1], 0)) return .splat_lane0;
    if (maskLaneEquals(parsed.lanes[0], 1) and parsed.lanes[1] == .poison) return .lane1_to_lane0;
    if (shuffle.lhs_ty.vector.elem_ty == .double and
        maskLaneEquals(parsed.lanes[0], 0) and maskLaneEquals(parsed.lanes[1], 3)) return .f64_lane0_lane3;
    return null;
}

fn maskLaneEquals(lane: Lane, expected: i128) bool {
    return switch (lane) {
        .int => |value| value == expected,
        .zero_initializer => expected == 0,
        else => false,
    };
}

fn parseTypedLane(raw: []const u8, elem_ty: core.VectorElementType) ?Lane {
    const lane = std.mem.trim(u8, raw, " \t");
    const separator = std.mem.indexOfAny(u8, lane, " \t") orelse return null;
    if (!elementTypeTextEql(lane[0..separator], elem_ty)) return null;
    const value = std.mem.trim(u8, lane[separator..], " \t");
    if (value.len == 0) return null;
    if (std.mem.eql(u8, value, "undef")) return .undef;
    if (std.mem.eql(u8, value, "poison")) return .poison;
    if (std.mem.eql(u8, value, "zeroinitializer")) return .zero_initializer;
    if (std.mem.eql(u8, value, "null")) return if (elem_ty == .ptr) .null_value else null;
    return switch (elem_ty) {
        .int => .{ .int = std.fmt.parseInt(i128, value, 10) catch return null },
        .half, .float, .double, .fp128 => .{ .fp = value },
        .ptr => null,
    };
}

fn elementTypeTextEql(text: []const u8, elem_ty: core.VectorElementType) bool {
    return switch (elem_ty) {
        .int => |bits| blk: {
            if (text.len < 2 or text[0] != 'i') break :blk false;
            break :blk (std.fmt.parseInt(u16, text[1..], 10) catch break :blk false) == bits;
        },
        .half => std.mem.eql(u8, text, "half"),
        .float => std.mem.eql(u8, text, "float"),
        .double => std.mem.eql(u8, text, "double"),
        .fp128 => std.mem.eql(u8, text, "fp128"),
        .ptr => std.mem.eql(u8, text, "ptr"),
    };
}

fn findTopLevelComma(text: []const u8) ?usize {
    var paren_depth: usize = 0;
    var brace_depth: usize = 0;
    var angle_depth: usize = 0;
    for (text, 0..) |char, index| switch (char) {
        '(' => paren_depth += 1,
        ')' => if (paren_depth > 0) {
            paren_depth -= 1;
        },
        '{' => brace_depth += 1,
        '}' => if (brace_depth > 0) {
            brace_depth -= 1;
        },
        '<' => angle_depth += 1,
        '>' => if (angle_depth > 0) {
            angle_depth -= 1;
        },
        ',' => if (paren_depth == 0 and brace_depth == 0 and angle_depth == 0) return index,
        else => {},
    };
    return null;
}

test "fixed vector constants and typed splat masks are structured once" {
    const f32x2: core.VectorType = .{ .len = 2, .elem_ty = .float };
    const parsed = parseFixed(2, .{ .vector = "<float 0x3FF0000000000000, float poison>" }, f32x2).?;
    try std.testing.expect(parsed.lanes[0] == .fp);
    try std.testing.expectEqualStrings("0x3FF0000000000000", parsed.lanes[0].fp);
    try std.testing.expect(!parsed.lanes[1].isDefined());

    const shuffle: core.ShuffleVectorInst = .{
        .lhs_ty = .{ .vector = f32x2 },
        .lhs = .poison,
        .rhs_ty = .{ .vector = f32x2 },
        .rhs = .poison,
        .mask_ty = .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 32 } } },
        .mask = .{ .vector = "<i32 0, i32 0>" },
    };
    try std.testing.expect(isSplatMask(2, shuffle, 0));
    try std.testing.expectEqual(Packed2ShuffleMask.splat_lane0, classifyPacked2ShuffleMask(shuffle).?);

    var lane_shift = shuffle;
    lane_shift.mask = .{ .vector = "<i32 1, i32 poison>" };
    try std.testing.expectEqual(Packed2ShuffleMask.lane1_to_lane0, classifyPacked2ShuffleMask(lane_shift).?);
    lane_shift.mask = .{ .vector = "<i32 1, i32 undef>" };
    try std.testing.expect(classifyPacked2ShuffleMask(lane_shift) == null);
    lane_shift.mask = .{ .vector = "<i32 0, i32 3>" };
    try std.testing.expect(classifyPacked2ShuffleMask(lane_shift) == null);
    lane_shift.lhs_ty.vector.elem_ty = .double;
    lane_shift.rhs_ty.vector.elem_ty = .double;
    try std.testing.expectEqual(Packed2ShuffleMask.f64_lane0_lane3, classifyPacked2ShuffleMask(lane_shift).?);
}
