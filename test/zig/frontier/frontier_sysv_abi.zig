const Pair64 = extern struct {
    a: i64,
    b: i64,
};

export fn frontier_pair64_make(a: i64, b: i64) Pair64 {
    return .{ .a = a, .b = b };
}

export fn frontier_pair64_first(pair: Pair64) i64 {
    return pair.a;
}

export fn frontier_pair64_second(pair: Pair64) i64 {
    return pair.b;
}

noinline fn frontier_id_i32(value: i32) i32 {
    return value;
}

export fn frontier_two_live_after_call(a: i32, b: i32, c: i32) i32 {
    return a + b + frontier_id_i32(c);
}

export fn frontier_three_live_after_call(a: i32, b: i32, c: i32, d: i32) i32 {
    return a + b + c + frontier_id_i32(d);
}

export fn frontier_four_live_after_call(a: i32, b: i32, c: i32, d: i32) i32 {
    const r = frontier_id_i32(d);
    return a + b + c + d + r;
}

export fn frontier_five_live_after_call(a: i32, b: i32, c: i32, d: i32, e: i32) i32 {
    const r = frontier_id_i32(e);
    return a + b + c + d + e + r;
}

export fn frontier_six_live_after_call(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32) i32 {
    const r = frontier_id_i32(f);
    return a + b + c + d + e + f + r;
}
