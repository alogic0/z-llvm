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

extern fn frontier_touch_f32(value: f32) void;
extern fn frontier_touch_f64(value: f64) void;
extern fn frontier_touch_none() void;
extern fn frontier_sum5_f32(a: f32, b: f32, c: f32, d: f32, e: f32) f32;
extern fn frontier_sum5_f64(a: f64, b: f64, c: f64, d: f64, e: f64) f64;

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

export fn frontier_seven_live_after_call(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32) i32 {
    const r = frontier_id_i32(f);
    return a + b + c + d + e + f + g + r;
}

export fn frontier_eight_live_after_call(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32) i32 {
    const r = frontier_id_i32(f);
    return a + b + c + d + e + f + g + h + r;
}

export fn frontier_nine_live_after_call(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32) i32 {
    const r = frontier_id_i32(f);
    return a + b + c + d + e + f + g + h + i + r;
}

export fn frontier_f32_live_after_call(a: f32, b: f32) f32 {
    frontier_touch_f32(b);
    return a;
}

export fn frontier_f64_live_after_call(a: f64, b: f64) f64 {
    frontier_touch_f64(b);
    return a;
}

export fn frontier_two_f32_live_sum_after_call(a: f32, b: f32) f32 {
    frontier_touch_none();
    return a + b;
}

export fn frontier_two_f64_live_sum_after_call(a: f64, b: f64) f64 {
    frontier_touch_none();
    return a + b;
}

export fn frontier_three_f32_live_sum_after_call(a: f32, b: f32, c: f32) f32 {
    frontier_touch_none();
    return a + b + c;
}

export fn frontier_four_f32_live_sum_after_call(a: f32, b: f32, c: f32, d: f32) f32 {
    frontier_touch_none();
    return a + b + c + d;
}

export fn frontier_five_f32_live_sum_after_call(a: f32, b: f32, c: f32, d: f32, e: f32) f32 {
    frontier_touch_none();
    return a + b + c + d + e;
}

export fn frontier_six_f32_live_sum_after_call(a: f32, b: f32, c: f32, d: f32, e: f32, f: f32) f32 {
    frontier_touch_none();
    return a + b + c + d + e + f;
}

export fn frontier_three_f64_live_sum_after_call(a: f64, b: f64, c: f64) f64 {
    frontier_touch_none();
    return a + b + c;
}

export fn frontier_four_f64_live_sum_after_call(a: f64, b: f64, c: f64, d: f64) f64 {
    frontier_touch_none();
    return a + b + c + d;
}

export fn frontier_five_f64_live_sum_after_call(a: f64, b: f64, c: f64, d: f64, e: f64) f64 {
    frontier_touch_none();
    return a + b + c + d + e;
}

export fn frontier_six_f64_live_sum_after_call(a: f64, b: f64, c: f64, d: f64, e: f64, f: f64) f64 {
    frontier_touch_none();
    return a + b + c + d + e + f;
}

export fn frontier_five_f32_external_call(a: f32, b: f32, c: f32, d: f32, e: f32) f32 {
    return frontier_sum5_f32(a, b, c, d, e);
}

export fn frontier_five_f64_external_call(a: f64, b: f64, c: f64, d: f64, e: f64) f64 {
    return frontier_sum5_f64(a, b, c, d, e);
}
