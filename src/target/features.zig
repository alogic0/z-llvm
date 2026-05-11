const std = @import("std");

pub const FeatureAttrs = struct {
    cpu: ?[]const u8 = null,
    features: ?[]const u8 = null,

    pub fn hasFeature(attrs: FeatureAttrs, feature: []const u8) bool {
        const text = attrs.features orelse return false;
        var parts = std.mem.splitScalar(u8, text, ',');
        while (parts.next()) |raw| {
            const item = std.mem.trim(u8, raw, " \t");
            if (item.len == 0) continue;
            if (std.mem.eql(u8, item, feature)) return true;
        }
        return false;
    }
};

pub fn parseAttributeText(text: []const u8) FeatureAttrs {
    return .{
        .cpu = quotedValue(text, "target-cpu"),
        .features = quotedValue(text, "target-features"),
    };
}

fn quotedValue(text: []const u8, key: []const u8) ?[]const u8 {
    var needle_buffer: [64]u8 = undefined;
    if (key.len + 3 > needle_buffer.len) return null;
    needle_buffer[0] = '"';
    @memcpy(needle_buffer[1 .. 1 + key.len], key);
    needle_buffer[1 + key.len] = '"';
    needle_buffer[2 + key.len] = '=';
    const needle = needle_buffer[0 .. key.len + 3];

    const start = std.mem.indexOf(u8, text, needle) orelse return null;
    var rest = text[start + needle.len ..];
    rest = std.mem.trim(u8, rest, " \t");
    if (rest.len == 0 or rest[0] != '"') return null;
    rest = rest[1..];
    const end = std.mem.indexOfScalar(u8, rest, '"') orelse return null;
    return rest[0..end];
}
