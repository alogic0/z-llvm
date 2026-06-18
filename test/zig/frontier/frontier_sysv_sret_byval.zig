const Big3 = extern struct {
    a: i64,
    b: i64,
    c: i64,
};

const Big4 = extern struct {
    a: i64,
    b: i64,
    c: i64,
    d: i64,
};

const Big5 = extern struct {
    a: i64,
    b: i64,
    c: i64,
    d: i64,
    e: i64,
};

const Big6 = extern struct {
    a: i64,
    b: i64,
    c: i64,
    d: i64,
    e: i64,
    f: i64,
};

const Big7 = extern struct {
    a: i64,
    b: i64,
    c: i64,
    d: i64,
    e: i64,
    f: i64,
    g: i64,
};

export fn frontier_big3_make(a: i64, b: i64, c: i64) Big3 {
    return .{ .a = a, .b = b, .c = c };
}

export fn frontier_big3_edges(value: Big3) i64 {
    return value.a + value.c;
}

export fn frontier_big3_copy(value: Big3) Big3 {
    return value;
}

export fn frontier_big4_make(a: i64, b: i64, c: i64, d: i64) Big4 {
    return .{ .a = a, .b = b, .c = c, .d = d };
}

export fn frontier_big4_edges(value: Big4) i64 {
    return value.a + value.d;
}

export fn frontier_big4_copy(value: Big4) Big4 {
    return value;
}

export fn frontier_big5_make(a: i64, b: i64, c: i64, d: i64, e: i64) Big5 {
    return .{ .a = a, .b = b, .c = c, .d = d, .e = e };
}

export fn frontier_big5_edges(value: Big5) i64 {
    return value.a + value.e;
}

export fn frontier_big5_inner(value: Big5) i64 {
    return value.b + value.d;
}

export fn frontier_big5_copy(value: Big5) Big5 {
    return value;
}

export fn frontier_big6_make(a: i64, b: i64, c: i64, d: i64, e: i64, f: i64) Big6 {
    return .{ .a = a, .b = b, .c = c, .d = d, .e = e, .f = f };
}

export fn frontier_big6_middle(value: Big6) i64 {
    return value.b + value.e;
}

export fn frontier_big6_copy(value: Big6) Big6 {
    return value;
}

export fn frontier_big7_make(a: i64, b: i64, c: i64, d: i64, e: i64, f: i64, g: i64) Big7 {
    return .{ .a = a, .b = b, .c = c, .d = d, .e = e, .f = f, .g = g };
}

export fn frontier_big7_inner(value: Big7) i64 {
    return value.c + value.f + value.g;
}

export fn frontier_big7_copy(value: Big7) Big7 {
    return value;
}
