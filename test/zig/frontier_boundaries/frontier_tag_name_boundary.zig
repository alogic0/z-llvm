const TagNameBoundary = union(enum) {
    short: i32,
    longer: i32,
};

export fn frontier_union_tag_name_boundary(flag: bool, value: i32) usize {
    const tagged: TagNameBoundary = if (flag)
        .{ .longer = value }
    else
        .{ .short = value };
    return @tagName(tagged).len;
}
