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

export fn frontier_union_tag_reversed_arms(flag: i32, value: i32) i32 {
    const tagged: TaggedValue = if (flag == 0) .{ .small = value } else .{ .large = value + 3 };
    return switch (tagged) {
        .large => |payload| payload + 13,
        .small => |payload| payload + 9,
    };
}

export fn frontier_union_tag_small_payload_add(flag: i32, value: i32) i32 {
    const tagged: TaggedValue = if (flag == 0) .{ .small = value + 4 } else .{ .large = value };
    return switch (tagged) {
        .small => |payload| payload + 5,
        .large => |payload| payload + 16,
    };
}
