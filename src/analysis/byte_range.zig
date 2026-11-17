//! Byte bounds describe an access, not object identity or alias provenance.
//! Unknown facts stay distinct from zero; owners supply any object extent.
const std = @import("std");

pub const ByteRange = struct {
    offset: ?i128,
    length: ?u64,

    pub fn end(range: ByteRange) ?i128 {
        return addOffset(range.offset, @as(i128, @intCast(range.length orelse return null)));
    }

    pub fn within(range: ByteRange, object_extent: ?u64) bool {
        const extent = object_extent orelse return false;
        const start = range.offset orelse return false;
        if (start < 0) return false;
        const limit = range.end() orelse return false;
        return limit <= @as(i128, @intCast(extent));
    }
};

pub fn addOffset(base: ?i128, delta: ?i128) ?i128 {
    return std.math.add(i128, base orelse return null, delta orelse return null) catch null;
}
