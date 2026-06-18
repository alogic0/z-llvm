const Big3 = extern struct {
    a: i64,
    b: i64,
    c: i64,
};

export fn frontier_big3_make(a: i64, b: i64, c: i64) Big3 {
    return .{ .a = a, .b = b, .c = c };
}

export fn frontier_big3_edges(value: Big3) i64 {
    return value.a + value.c;
}
