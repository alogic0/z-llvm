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

const Big32 = extern struct {
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
    u: i64,
    v: i64,
    w: i64,
    x: i64,
    y: i64,
    z: i64,
    aa: i64,
    ab: i64,
    ac: i64,
    ad: i64,
    ae: i64,
    af: i64,
};

const Big40 = extern struct {
    values: [40]i64,
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

const NarrowInner = extern struct {
    b: u16,
    c: i32,
};

const BigNarrow = extern struct {
    a: u8,
    inner: NarrowInner,
    d: i64,
};

const BigArray = extern struct {
    values: [5]i64,
};

const BigDouble = extern struct {
    a: f64,
    b: f64,
    c: f64,
};

const BigDoubleArray = extern struct {
    values: [3]f64,
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

const BigArrayMixed = extern struct {
    ints: [2]i32,
    doubles: [2]f64,
    ptr: *const i64,
};

const BigByteTail = extern struct {
    values: [17]u8,
};

const BigByteTail5 = extern struct {
    values: [21]u8,
};

const BigByteTail6 = extern struct {
    values: [22]u8,
};

const BigByteTail7 = extern struct {
    values: [23]u8,
};

const BigWordTail = extern struct {
    values: [9]u16,
};

const ScalarMixed = extern struct {
    a: u8,
    b: u16,
    c: i32,
    d: i64,
    ptr: *const i64,
    f: f32,
    g: f64,
};

const ScalarNestedInner = extern struct {
    a: u8,
    b: u16,
};

const ScalarNested = extern struct {
    inner: ScalarNestedInner,
    c: i32,
    d: f64,
    ptr: *const i64,
};

const ScalarArray = extern struct {
    ints: [3]i32,
    doubles: [2]f64,
    ptr: *const i64,
};

const Big3CopyFn = *const fn (Big3) callconv(.c) Big3;
const Big4CopyFn = *const fn (Big4) callconv(.c) Big4;
const Big5CopyFn = *const fn (Big5) callconv(.c) Big5;
const BigNestedCopyFn = *const fn (BigNested) callconv(.c) BigNested;
const BigMixedCopyFn = *const fn (BigMixed) callconv(.c) BigMixed;
const BigNarrowCopyFn = *const fn (BigNarrow) callconv(.c) BigNarrow;
const BigArrayCopyFn = *const fn (BigArray) callconv(.c) BigArray;
const BigDoubleCopyFn = *const fn (BigDouble) callconv(.c) BigDouble;
const BigDoubleArrayCopyFn = *const fn (BigDoubleArray) callconv(.c) BigDoubleArray;
const BigFloatCopyFn = *const fn (BigFloat) callconv(.c) BigFloat;
const BigPtrDoubleCopyFn = *const fn (BigPtrDouble) callconv(.c) BigPtrDouble;
const BigArrayMixedCopyFn = *const fn (BigArrayMixed) callconv(.c) BigArrayMixed;
const BigByteTailCopyFn = *const fn (BigByteTail) callconv(.c) BigByteTail;
const BigByteTail5CopyFn = *const fn (BigByteTail5) callconv(.c) BigByteTail5;
const BigByteTail6CopyFn = *const fn (BigByteTail6) callconv(.c) BigByteTail6;
const BigByteTail7CopyFn = *const fn (BigByteTail7) callconv(.c) BigByteTail7;
const BigWordTailCopyFn = *const fn (BigWordTail) callconv(.c) BigWordTail;
const Big32CopyFn = *const fn (Big32) callconv(.c) Big32;
const Big40CopyFn = *const fn (Big40) callconv(.c) Big40;

export fn frontier_big3_make(a: i64, b: i64, c: i64) Big3 {
    return .{ .a = a, .b = b, .c = c };
}

export fn frontier_big3_edges(value: Big3) i64 {
    return value.a + value.c;
}

export fn frontier_big3_copy(value: Big3) Big3 {
    return value;
}

export fn frontier_direct_big3_copy(value: Big3) Big3 {
    return frontier_big3_copy(value);
}

export fn frontier_indirect_big3_copy(func: Big3CopyFn, value: Big3) Big3 {
    return func(value);
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

export fn frontier_direct_big4_copy(value: Big4) Big4 {
    return frontier_big4_copy(value);
}

export fn frontier_indirect_big4_copy(func: Big4CopyFn, value: Big4) Big4 {
    return func(value);
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

export fn frontier_direct_big5_copy(value: Big5) Big5 {
    return frontier_big5_copy(value);
}

export fn frontier_indirect_big5_copy(func: Big5CopyFn, value: Big5) Big5 {
    return func(value);
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

export fn frontier_big32_copy(value: Big32) Big32 {
    return value;
}

export fn frontier_direct_big32_copy(value: Big32) Big32 {
    return frontier_big32_copy(value);
}

export fn frontier_indirect_big32_copy(func: Big32CopyFn, value: Big32) Big32 {
    return func(value);
}

export fn frontier_big40_copy(value: Big40) Big40 {
    return value;
}

export fn frontier_direct_big40_copy(value: Big40) Big40 {
    return frontier_big40_copy(value);
}

export fn frontier_indirect_big40_copy(func: Big40CopyFn, value: Big40) Big40 {
    return func(value);
}

export fn frontier_big_nested_copy(value: BigNested) BigNested {
    return value;
}

export fn frontier_direct_big_nested_copy(value: BigNested) BigNested {
    return frontier_big_nested_copy(value);
}

export fn frontier_indirect_big_nested_copy(func: BigNestedCopyFn, value: BigNested) BigNested {
    return func(value);
}

export fn frontier_big_nested_sum_inner(value: BigNested) i64 {
    return value.left.b + value.right.c;
}

export fn frontier_big_mixed_copy(value: BigMixed) BigMixed {
    return value;
}

export fn frontier_direct_big_mixed_copy(value: BigMixed) BigMixed {
    return frontier_big_mixed_copy(value);
}

export fn frontier_indirect_big_mixed_copy(func: BigMixedCopyFn, value: BigMixed) BigMixed {
    return func(value);
}

export fn frontier_big_narrow_copy(value: BigNarrow) BigNarrow {
    return value;
}

export fn frontier_direct_big_narrow_copy(value: BigNarrow) BigNarrow {
    return frontier_big_narrow_copy(value);
}

export fn frontier_indirect_big_narrow_copy(func: BigNarrowCopyFn, value: BigNarrow) BigNarrow {
    return func(value);
}

export fn frontier_big_array_copy(value: BigArray) BigArray {
    return value;
}

export fn frontier_direct_big_array_copy(value: BigArray) BigArray {
    return frontier_big_array_copy(value);
}

export fn frontier_indirect_big_array_copy(func: BigArrayCopyFn, value: BigArray) BigArray {
    return func(value);
}

export fn frontier_big_array_sum_edges(value: BigArray) i64 {
    return value.values[0] + value.values[4];
}

export fn frontier_big_double_copy(value: BigDouble) BigDouble {
    return value;
}

export fn frontier_direct_big_double_copy(value: BigDouble) BigDouble {
    return frontier_big_double_copy(value);
}

export fn frontier_indirect_big_double_copy(func: BigDoubleCopyFn, value: BigDouble) BigDouble {
    return func(value);
}

export fn frontier_big_double_array_copy(value: BigDoubleArray) BigDoubleArray {
    return value;
}

export fn frontier_direct_big_double_array_copy(value: BigDoubleArray) BigDoubleArray {
    return frontier_big_double_array_copy(value);
}

export fn frontier_indirect_big_double_array_copy(func: BigDoubleArrayCopyFn, value: BigDoubleArray) BigDoubleArray {
    return func(value);
}

export fn frontier_big_float_copy(value: BigFloat) BigFloat {
    return value;
}

export fn frontier_direct_big_float_copy(value: BigFloat) BigFloat {
    return frontier_big_float_copy(value);
}

export fn frontier_indirect_big_float_copy(func: BigFloatCopyFn, value: BigFloat) BigFloat {
    return func(value);
}

export fn frontier_big_ptr_double_copy(value: BigPtrDouble) BigPtrDouble {
    return value;
}

export fn frontier_direct_big_ptr_double_copy(value: BigPtrDouble) BigPtrDouble {
    return frontier_big_ptr_double_copy(value);
}

export fn frontier_indirect_big_ptr_double_copy(func: BigPtrDoubleCopyFn, value: BigPtrDouble) BigPtrDouble {
    return func(value);
}

export fn frontier_big_array_mixed_copy(value: BigArrayMixed) BigArrayMixed {
    return value;
}

export fn frontier_direct_big_array_mixed_copy(value: BigArrayMixed) BigArrayMixed {
    return frontier_big_array_mixed_copy(value);
}

export fn frontier_indirect_big_array_mixed_copy(func: BigArrayMixedCopyFn, value: BigArrayMixed) BigArrayMixed {
    return func(value);
}

export fn frontier_big_byte_tail_copy(value: BigByteTail) BigByteTail {
    return value;
}

export fn frontier_direct_big_byte_tail_copy(value: BigByteTail) BigByteTail {
    return frontier_big_byte_tail_copy(value);
}

export fn frontier_indirect_big_byte_tail_copy(func: BigByteTailCopyFn, value: BigByteTail) BigByteTail {
    return func(value);
}

export fn frontier_big_byte_tail5_copy(value: BigByteTail5) BigByteTail5 {
    return value;
}

export fn frontier_direct_big_byte_tail5_copy(value: BigByteTail5) BigByteTail5 {
    return frontier_big_byte_tail5_copy(value);
}

export fn frontier_indirect_big_byte_tail5_copy(func: BigByteTail5CopyFn, value: BigByteTail5) BigByteTail5 {
    return func(value);
}

export fn frontier_big_byte_tail6_copy(value: BigByteTail6) BigByteTail6 {
    return value;
}

export fn frontier_direct_big_byte_tail6_copy(value: BigByteTail6) BigByteTail6 {
    return frontier_big_byte_tail6_copy(value);
}

export fn frontier_indirect_big_byte_tail6_copy(func: BigByteTail6CopyFn, value: BigByteTail6) BigByteTail6 {
    return func(value);
}

export fn frontier_big_byte_tail7_copy(value: BigByteTail7) BigByteTail7 {
    return value;
}

export fn frontier_direct_big_byte_tail7_copy(value: BigByteTail7) BigByteTail7 {
    return frontier_big_byte_tail7_copy(value);
}

export fn frontier_indirect_big_byte_tail7_copy(func: BigByteTail7CopyFn, value: BigByteTail7) BigByteTail7 {
    return func(value);
}

export fn frontier_big_word_tail_copy(value: BigWordTail) BigWordTail {
    return value;
}

export fn frontier_direct_big_word_tail_copy(value: BigWordTail) BigWordTail {
    return frontier_big_word_tail_copy(value);
}

export fn frontier_indirect_big_word_tail_copy(func: BigWordTailCopyFn, value: BigWordTail) BigWordTail {
    return func(value);
}

export fn frontier_scalar_mixed_make(a: u8, b: u16, c: i32, d: i64, ptr: *const i64, f: f32, g: f64) ScalarMixed {
    return .{ .a = a, .b = b, .c = c, .d = d, .ptr = ptr, .f = f, .g = g };
}

export fn frontier_scalar_nested_make(a: u8, b: u16, c: i32, d: f64, ptr: *const i64) ScalarNested {
    return .{ .inner = .{ .a = a, .b = b }, .c = c, .d = d, .ptr = ptr };
}

export fn frontier_scalar_array_make(a: i32, b: i32, c: i32, d: f64, e: f64, ptr: *const i64) ScalarArray {
    return .{ .ints = .{ a, b, c }, .doubles = .{ d, e }, .ptr = ptr };
}
