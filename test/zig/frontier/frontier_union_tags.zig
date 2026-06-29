const TaggedValue = union(enum(u8)) {
    small: i32,
    large: i32,
};

export fn frontier_union_tag_match(flag: i32, value: i32) i32 {
    const tagged: TaggedValue = if (flag == 0) .{ .small = value } else .{ .large = value + 5 };
    return switch (tagged) {
        .small => |payload| payload + 7,
        .large => |payload| payload + 11,
    };
}
