const ThreeTagValue = union(enum(u8)) {
    small: i32,
    middle: i32,
    large: i32,
};

export fn frontier_union_payload_boundary(flag: i32, value: i32) i32 {
    const tagged: ThreeTagValue = if (flag == 0)
        .{ .small = value + 4 }
    else
        .{ .large = value + 9 };

    return switch (tagged) {
        .small => |payload| payload + 1,
        .large => |payload| payload + 2,
        else => value,
    };
}
