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

const Big8 = extern struct {
    a: i64,
    b: i64,
    c: i64,
    d: i64,
    e: i64,
    f: i64,
    g: i64,
    h: i64,
};

const Big12 = extern struct {
    a: i64,
    b: i64,
    c: i64,
    d: i64,
    e: i64,
    f: i64,
    g: i64,
    h: i64,
    i: i64,
    j: i64,
    k: i64,
    l: i64,
};

const Big16 = extern struct {
    a: i64,
    b: i64,
    c: i64,
    d: i64,
    e: i64,
    f: i64,
    g: i64,
    h: i64,
    i: i64,
    j: i64,
    k: i64,
    l: i64,
    m: i64,
    n: i64,
    o: i64,
    p: i64,
};

const Big20 = extern struct {
    a: i64,
    b: i64,
    c: i64,
    d: i64,
    e: i64,
    f: i64,
    g: i64,
    h: i64,
    i: i64,
    j: i64,
    k: i64,
    l: i64,
    m: i64,
    n: i64,
    o: i64,
    p: i64,
    q: i64,
    r: i64,
    s: i64,
    t: i64,
};

const BigNested = extern struct {
    left: Big3,
    right: Big3,
};

const BigMixed = extern struct {
    a: i64,
    b: i32,
    c: i64,
    d: i32,
};

const BigArray = extern struct {
    values: [5]i64,
};

const BigDouble = extern struct {
    a: f64,
    b: f64,
    c: f64,
};

const BigFloat = extern struct {
    a: f32,
    b: f32,
    c: f32,
    d: f32,
    e: f32,
};

const BigPtrDouble = extern struct {
    ptr: *const i64,
    value: f64,
    tag: i64,
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

export fn frontier_big8_make(a: i64, b: i64, c: i64, d: i64, e: i64, f: i64, g: i64, h: i64) Big8 {
    return .{ .a = a, .b = b, .c = c, .d = d, .e = e, .f = f, .g = g, .h = h };
}

export fn frontier_big8_inner(value: Big8) i64 {
    return value.b + value.e + value.h;
}

export fn frontier_big8_copy(value: Big8) Big8 {
    return value;
}

export fn frontier_big12_make(a: i64, b: i64, c: i64, d: i64, e: i64, f: i64, g: i64, h: i64, i: i64, j: i64, k: i64, l: i64) Big12 {
    return .{ .a = a, .b = b, .c = c, .d = d, .e = e, .f = f, .g = g, .h = h, .i = i, .j = j, .k = k, .l = l };
}

export fn frontier_big12_inner(value: Big12) i64 {
    return value.c + value.h + value.l;
}

export fn frontier_big12_copy(value: Big12) Big12 {
    return value;
}

export fn frontier_big16_make(a: i64, b: i64, c: i64, d: i64, e: i64, f: i64, g: i64, h: i64, i: i64, j: i64, k: i64, l: i64, m: i64, n: i64, o: i64, p: i64) Big16 {
    return .{ .a = a, .b = b, .c = c, .d = d, .e = e, .f = f, .g = g, .h = h, .i = i, .j = j, .k = k, .l = l, .m = m, .n = n, .o = o, .p = p };
}

export fn frontier_big16_inner(value: Big16) i64 {
    return value.d + value.k + value.p;
}

export fn frontier_big16_copy(value: Big16) Big16 {
    return value;
}

export fn frontier_big20_make(a: i64, b: i64, c: i64, d: i64, e: i64, f: i64, g: i64, h: i64, i: i64, j: i64, k: i64, l: i64, m: i64, n: i64, o: i64, p: i64, q: i64, r: i64, s: i64, t: i64) Big20 {
    return .{ .a = a, .b = b, .c = c, .d = d, .e = e, .f = f, .g = g, .h = h, .i = i, .j = j, .k = k, .l = l, .m = m, .n = n, .o = o, .p = p, .q = q, .r = r, .s = s, .t = t };
}

export fn frontier_big20_inner(value: Big20) i64 {
    return value.d + value.k + value.q + value.t;
}

export fn frontier_big20_copy(value: Big20) Big20 {
    return value;
}

export fn frontier_big_nested_copy(value: BigNested) BigNested {
    return value;
}

export fn frontier_big_nested_sum_inner(value: BigNested) i64 {
    return value.left.b + value.right.c;
}

export fn frontier_big_mixed_copy(value: BigMixed) BigMixed {
    return value;
}

export fn frontier_big_array_copy(value: BigArray) BigArray {
    return value;
}

export fn frontier_big_array_sum_edges(value: BigArray) i64 {
    return value.values[0] + value.values[4];
}

export fn frontier_big_double_copy(value: BigDouble) BigDouble {
    return value;
}

export fn frontier_big_float_copy(value: BigFloat) BigFloat {
    return value;
}

export fn frontier_big_ptr_double_copy(value: BigPtrDouble) BigPtrDouble {
    return value;
}
