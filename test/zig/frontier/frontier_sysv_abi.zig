const Pair64 = extern struct {
    a: i64,
    b: i64,
};

const Sum6Fn = *const fn (i32, i32, i32, i32, i32, i32) callconv(.c) i32;
const Sum12Fn = *const fn (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) callconv(.c) i32;
const Sum14Fn = *const fn (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) callconv(.c) i32;
const Sum24Fn = *const fn (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) callconv(.c) i32;
const SubI32Fn = *const fn (i32, i32) callconv(.c) i32;
const SubI64Fn = *const fn (i64, i64) callconv(.c) i64;
const SubF32Fn = *const fn (f32, f32) callconv(.c) f32;
const SubF64Fn = *const fn (f64, f64) callconv(.c) f64;
const Sum8I64Fn = *const fn (i64, i64, i64, i64, i64, i64, i64, i64) callconv(.c) i64;
const Sum8PtrFn = *const fn (*const i32, *const i32, *const i32, *const i32, *const i32, *const i32, *const i32, *const i32) callconv(.c) i32;
const ChoosePtrFn = *const fn (*const i32, *const i32, i32) callconv(.c) *const i32;
const Sum5F32Fn = *const fn (f32, f32, f32, f32, f32) callconv(.c) f32;
const Sum5F64Fn = *const fn (f64, f64, f64, f64, f64) callconv(.c) f64;
const TouchF32Fn = *const fn (f32) callconv(.c) void;
const TouchF64Fn = *const fn (f64) callconv(.c) void;
const Touch2F32Fn = *const fn (f32, f32) callconv(.c) void;
const Touch2F64Fn = *const fn (f64, f64) callconv(.c) void;
const Touch3F32Fn = *const fn (f32, f32, f32) callconv(.c) void;
const Touch3F64Fn = *const fn (f64, f64, f64) callconv(.c) void;
const Touch5F32Fn = *const fn (f32, f32, f32, f32, f32) callconv(.c) void;
const Touch5F64Fn = *const fn (f64, f64, f64, f64, f64) callconv(.c) void;
const IdI32Fn = *const fn (i32) callconv(.c) i32;
const IdI64Fn = *const fn (i64) callconv(.c) i64;
const IdF32Fn = *const fn (f32) callconv(.c) f32;
const IdF64Fn = *const fn (f64) callconv(.c) f64;
const VoidFn = *const fn () callconv(.c) void;
const MakePair64Fn = *const fn (i64, i64) callconv(.c) Pair64;
const Pair64FirstFn = *const fn (Pair64) callconv(.c) i64;

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
extern fn frontier_touch2_f32(a: f32, b: f32) void;
extern fn frontier_touch2_f64(a: f64, b: f64) void;
extern fn frontier_touch3_f32(a: f32, b: f32, c: f32) void;
extern fn frontier_touch3_f64(a: f64, b: f64, c: f64) void;
extern fn frontier_touch5_f32(a: f32, b: f32, c: f32, d: f32, e: f32) void;
extern fn frontier_touch5_f64(a: f64, b: f64, c: f64, d: f64, e: f64) void;
extern fn frontier_touch_none() void;
extern fn frontier_touch_ordered() void;
extern fn frontier_touch_ordered_after_two() void;
extern fn frontier_ordered_i32(value: i32) i32;
extern fn frontier_ordered2_i32(value: i32) i32;
extern fn frontier_ordered_i64(value: i64) i64;
extern fn frontier_ordered2_i64(value: i64) i64;
extern fn frontier_ordered_f32(value: f32) f32;
extern fn frontier_ordered2_f32(value: f32) f32;
extern fn frontier_ordered_f64(value: f64) f64;
extern fn frontier_ordered2_f64(value: f64) f64;
extern fn frontier_sum5_f32(a: f32, b: f32, c: f32, d: f32, e: f32) f32;
extern fn frontier_sum5_f64(a: f64, b: f64, c: f64, d: f64, e: f64) f64;
extern fn frontier_sub_f32(a: f32, b: f32) f32;
extern fn frontier_sub_f64(a: f64, b: f64) f64;
extern fn frontier_sum6_i32(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32) i32;
extern fn frontier_sum12_i32(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32) i32;
extern fn frontier_sum14_i32(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32, m: i32, n: i32) i32;
extern fn frontier_sum18_i32(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32, m: i32, n: i32, o: i32, p: i32, q: i32, r: i32) i32;
extern fn frontier_sum24_i32(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32, m: i32, n: i32, o: i32, p: i32, q: i32, r: i32, s: i32, t: i32, u: i32, v: i32, w: i32, x: i32) i32;
extern fn frontier_sub_i32(a: i32, b: i32) i32;
extern fn frontier_weighted3_i32(a: i32, b: i32, c: i32) i32;
extern fn frontier_weighted6_i32(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32) i32;
extern fn frontier_sum6_i64(a: i64, b: i64, c: i64, d: i64, e: i64, f: i64) i64;
extern fn frontier_sum8_i64(a: i64, b: i64, c: i64, d: i64, e: i64, f: i64, g: i64, h: i64) i64;
extern fn frontier_sub_i64(a: i64, b: i64) i64;
extern fn frontier_weighted3_i64(a: i64, b: i64, c: i64) i64;
extern fn frontier_sum8_ptr(a: *const i32, b: *const i32, c: *const i32, d: *const i32, e: *const i32, f: *const i32, g: *const i32, h: *const i32) i32;
extern fn frontier_choose_ptr(a: *const i32, b: *const i32, tag: i32) *const i32;

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

export fn frontier_two_void_calls_six_live(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32) i32 {
    frontier_touch_none();
    frontier_touch_none();
    return a + b + c + d + e + f;
}

export fn frontier_two_indirect_void_calls_six_live(func: VoidFn, a: i32, b: i32, c: i32, d: i32, e: i32, f: i32) i32 {
    func();
    func();
    return a + b + c + d + e + f;
}

export fn frontier_call_result_live_across_second_call(a: i32) i32 {
    const first = frontier_ordered_i32(a);
    frontier_touch_ordered();
    return first + a;
}

export fn frontier_two_i32_results_across_calls(a: i32, b: i32) i32 {
    const first = frontier_ordered_i32(a);
    const second = frontier_ordered2_i32(b);
    return first + second + a;
}

export fn frontier_two_i32_results_across_indirect_call(func: IdI32Fn, a: i32, b: i32) i32 {
    const first = frontier_ordered_i32(a);
    const second = func(b);
    return first + second + a;
}

export fn frontier_indirect_first_two_i32_results_across_calls(func: IdI32Fn, a: i32, b: i32) i32 {
    const first = func(a);
    const second = frontier_ordered2_i32(b);
    return first + second + a;
}

export fn frontier_indirect_both_two_i32_results_across_calls(first_func: IdI32Fn, second_func: IdI32Fn, a: i32, b: i32) i32 {
    const first = first_func(a);
    const second = second_func(b);
    return first + second + a;
}

export fn frontier_two_i64_results_across_calls(a: i64, b: i64) i64 {
    const first = frontier_ordered_i64(a);
    const second = frontier_ordered2_i64(b);
    return first + second;
}

export fn frontier_indirect_first_i64_results_across_calls(func: IdI64Fn, a: i64, b: i64) i64 {
    const first = func(a);
    const second = frontier_ordered2_i64(b);
    return first + second;
}

export fn frontier_indirect_second_i64_results_across_calls(func: IdI64Fn, a: i64, b: i64) i64 {
    const first = frontier_ordered_i64(a);
    const second = func(b);
    return first + second;
}

export fn frontier_indirect_both_i64_results_across_calls(first_func: IdI64Fn, second_func: IdI64Fn, a: i64, b: i64) i64 {
    const first = first_func(a);
    const second = second_func(b);
    return first + second;
}

export fn frontier_two_i64_results_with_live_across_calls(a: i64, b: i64) i64 {
    const first = frontier_ordered_i64(a);
    const second = frontier_ordered2_i64(b);
    return first + second + a;
}

export fn frontier_indirect_first_i64_results_with_live_across_calls(func: IdI64Fn, a: i64, b: i64) i64 {
    const first = func(a);
    const second = frontier_ordered2_i64(b);
    return first + second + a;
}

export fn frontier_indirect_second_i64_results_with_live_across_calls(func: IdI64Fn, a: i64, b: i64) i64 {
    const first = frontier_ordered_i64(a);
    const second = func(b);
    return first + second + a;
}

export fn frontier_indirect_both_i64_results_with_live_across_calls(first_func: IdI64Fn, second_func: IdI64Fn, a: i64, b: i64) i64 {
    const first = first_func(a);
    const second = second_func(b);
    return first + second + a;
}

export fn frontier_i64_result_live_across_void_call(a: i64, b: i64) i64 {
    const first = frontier_ordered_i64(a);
    frontier_touch_ordered();
    return first + b;
}

export fn frontier_i64_result_live_across_indirect_void_call(func: VoidFn, a: i64, b: i64) i64 {
    const first = frontier_ordered_i64(a);
    func();
    return first + b;
}

export fn frontier_indirect_i64_result_live_across_void_call(func: IdI64Fn, a: i64, b: i64) i64 {
    const first = func(a);
    frontier_touch_ordered();
    return first + b;
}

export fn frontier_indirect_i64_result_live_across_indirect_void_call(func: IdI64Fn, later: VoidFn, a: i64, b: i64) i64 {
    const first = func(a);
    later();
    return first + b;
}

export fn frontier_two_i64_results_live_across_void_call(a: i64, b: i64) i64 {
    const first = frontier_ordered_i64(a);
    const second = frontier_ordered2_i64(b);
    frontier_touch_ordered_after_two();
    return first + second;
}

export fn frontier_two_i64_results_with_live_across_void_call(a: i64, b: i64) i64 {
    const first = frontier_ordered_i64(a);
    const second = frontier_ordered2_i64(b);
    frontier_touch_ordered_after_two();
    return first + second + a;
}

export fn frontier_two_i64_results_with_live_across_indirect_void_call(later: VoidFn, a: i64, b: i64) i64 {
    const first = frontier_ordered_i64(a);
    const second = frontier_ordered2_i64(b);
    later();
    return first + second + a;
}

export fn frontier_two_i64_results_live_across_indirect_void_call(func: VoidFn, a: i64, b: i64) i64 {
    const first = frontier_ordered_i64(a);
    const second = frontier_ordered2_i64(b);
    func();
    return first + second;
}

export fn frontier_indirect_first_two_i64_results_with_live_across_void_call(func: IdI64Fn, a: i64, b: i64) i64 {
    const first = func(a);
    const second = frontier_ordered2_i64(b);
    frontier_touch_ordered_after_two();
    return first + second + a;
}

export fn frontier_indirect_first_two_i64_results_live_across_void_call(func: IdI64Fn, a: i64, b: i64) i64 {
    const first = func(a);
    const second = frontier_ordered2_i64(b);
    frontier_touch_ordered_after_two();
    return first + second;
}

export fn frontier_indirect_second_two_i64_results_with_live_across_void_call(func: IdI64Fn, a: i64, b: i64) i64 {
    const first = frontier_ordered_i64(a);
    const second = func(b);
    frontier_touch_ordered_after_two();
    return first + second + a;
}

export fn frontier_indirect_second_two_i64_results_live_across_void_call(func: IdI64Fn, a: i64, b: i64) i64 {
    const first = frontier_ordered_i64(a);
    const second = func(b);
    frontier_touch_ordered_after_two();
    return first + second;
}

export fn frontier_indirect_both_two_i64_results_live_across_indirect_void_call(first_func: IdI64Fn, second_func: IdI64Fn, later: VoidFn, a: i64, b: i64) i64 {
    const first = first_func(a);
    const second = second_func(b);
    later();
    return first + second;
}

export fn frontier_indirect_both_two_i64_results_with_live_across_indirect_void_call(first_func: IdI64Fn, second_func: IdI64Fn, later: VoidFn, a: i64, b: i64) i64 {
    const first = first_func(a);
    const second = second_func(b);
    later();
    return first + second + a;
}

export fn frontier_two_i32_results_live_across_void_call(a: i32, b: i32) i32 {
    const first = frontier_ordered_i32(a);
    const second = frontier_ordered2_i32(b);
    frontier_touch_ordered_after_two();
    return first + second + a;
}

export fn frontier_two_i32_results_live_across_indirect_void_call(func: VoidFn, a: i32, b: i32) i32 {
    const first = frontier_ordered_i32(a);
    const second = frontier_ordered2_i32(b);
    func();
    return first + second + a;
}

export fn frontier_indirect_first_i32_result_live_across_void_call(func: IdI32Fn, a: i32, b: i32) i32 {
    const first = func(a);
    const second = frontier_ordered2_i32(b);
    frontier_touch_ordered_after_two();
    return first + second + a;
}

export fn frontier_indirect_second_i32_result_live_across_void_call(func: IdI32Fn, a: i32, b: i32) i32 {
    const first = frontier_ordered_i32(a);
    const second = func(b);
    frontier_touch_ordered_after_two();
    return first + second + a;
}

export fn frontier_indirect_both_i32_results_live_across_indirect_void_call(first_func: IdI32Fn, second_func: IdI32Fn, later: VoidFn, a: i32, b: i32) i32 {
    const first = first_func(a);
    const second = second_func(b);
    later();
    return first + second + a;
}

export fn frontier_f64_result_live_across_void_call(a: f64, b: f64) f64 {
    const first = frontier_ordered_f64(a);
    frontier_touch_ordered();
    return first + b;
}

export fn frontier_f32_result_live_across_void_call(a: f32, b: f32) f32 {
    const first = frontier_ordered_f32(a);
    frontier_touch_ordered();
    return first + b;
}

export fn frontier_f64_result_live_across_indirect_void_call(func: VoidFn, a: f64, b: f64) f64 {
    const first = frontier_ordered_f64(a);
    func();
    return first + b;
}

export fn frontier_f32_result_live_across_indirect_void_call(func: VoidFn, a: f32, b: f32) f32 {
    const first = frontier_ordered_f32(a);
    func();
    return first + b;
}

export fn frontier_indirect_f64_result_live_across_void_call(func: IdF64Fn, a: f64, b: f64) f64 {
    const first = func(a);
    frontier_touch_ordered();
    return first + b;
}

export fn frontier_indirect_f32_result_live_across_void_call(func: IdF32Fn, a: f32, b: f32) f32 {
    const first = func(a);
    frontier_touch_ordered();
    return first + b;
}

export fn frontier_indirect_f64_result_live_across_indirect_void_call(func: IdF64Fn, later: VoidFn, a: f64, b: f64) f64 {
    const first = func(a);
    later();
    return first + b;
}

export fn frontier_indirect_f32_result_live_across_indirect_void_call(func: IdF32Fn, later: VoidFn, a: f32, b: f32) f32 {
    const first = func(a);
    later();
    return first + b;
}

export fn frontier_two_f64_results_across_calls(a: f64, b: f64) f64 {
    const first = frontier_ordered_f64(a);
    const second = frontier_ordered2_f64(b);
    return first + second;
}

export fn frontier_two_f32_results_across_calls(a: f32, b: f32) f32 {
    const first = frontier_ordered_f32(a);
    const second = frontier_ordered2_f32(b);
    return first + second;
}

export fn frontier_indirect_first_f64_results_across_calls(func: IdF64Fn, a: f64, b: f64) f64 {
    const first = func(a);
    const second = frontier_ordered2_f64(b);
    return first + second;
}

export fn frontier_indirect_first_f32_results_across_calls(func: IdF32Fn, a: f32, b: f32) f32 {
    const first = func(a);
    const second = frontier_ordered2_f32(b);
    return first + second;
}

export fn frontier_indirect_second_f64_results_across_calls(func: IdF64Fn, a: f64, b: f64) f64 {
    const first = frontier_ordered_f64(a);
    const second = func(b);
    return first + second;
}

export fn frontier_indirect_second_f32_results_across_calls(func: IdF32Fn, a: f32, b: f32) f32 {
    const first = frontier_ordered_f32(a);
    const second = func(b);
    return first + second;
}

export fn frontier_mixed_f32_f64_results_across_calls(a: f32, b: f64) f64 {
    const first = frontier_ordered_f32(a);
    const second = frontier_ordered2_f64(b);
    return @as(f64, first) + second;
}

export fn frontier_mixed_indirect_first_f32_f64_results_across_calls(func: IdF32Fn, a: f32, b: f64) f64 {
    const first = func(a);
    const second = frontier_ordered2_f64(b);
    return @as(f64, first) + second;
}

export fn frontier_mixed_indirect_second_f32_f64_results_across_calls(func: IdF64Fn, a: f32, b: f64) f64 {
    const first = frontier_ordered_f32(a);
    const second = func(b);
    return @as(f64, first) + second;
}

export fn frontier_mixed_indirect_both_f32_f64_results_across_calls(first_func: IdF32Fn, second_func: IdF64Fn, a: f32, b: f64) f64 {
    const first = first_func(a);
    const second = second_func(b);
    return @as(f64, first) + second;
}

export fn frontier_mixed_f64_f32_results_across_calls(a: f64, b: f32) f64 {
    const first = frontier_ordered_f64(a);
    const second = frontier_ordered2_f32(b);
    return first + @as(f64, second);
}

export fn frontier_mixed_indirect_first_f64_f32_results_across_calls(func: IdF64Fn, a: f64, b: f32) f64 {
    const first = func(a);
    const second = frontier_ordered2_f32(b);
    return first + @as(f64, second);
}

export fn frontier_mixed_indirect_second_f64_f32_results_across_calls(func: IdF32Fn, a: f64, b: f32) f64 {
    const first = frontier_ordered_f64(a);
    const second = func(b);
    return first + @as(f64, second);
}

export fn frontier_mixed_indirect_both_f64_f32_results_across_calls(first_func: IdF64Fn, second_func: IdF32Fn, a: f64, b: f32) f64 {
    const first = first_func(a);
    const second = second_func(b);
    return first + @as(f64, second);
}

export fn frontier_six_stack_arg_call() i32 {
    return frontier_sum12_i32(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
}

export fn frontier_eight_stack_arg_call() i32 {
    return frontier_sum14_i32(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
}

export fn frontier_twelve_stack_arg_call() i32 {
    return frontier_sum18_i32(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18);
}

export fn frontier_eighteen_stack_arg_call() i32 {
    return frontier_sum24_i32(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24);
}

export fn frontier_stack_arg_forward(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32) i32 {
    return frontier_sum12_i32(a, b, c, d, e, f, g, h, i, j, k, l);
}

export fn frontier_stack_arg_to_registers(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32) i32 {
    _ = a;
    _ = b;
    _ = c;
    _ = d;
    _ = e;
    _ = f;
    return frontier_sum6_i32(g, h, i, j, k, l);
}

export fn frontier_indirect_stack_arg_to_registers(func: Sum6Fn, a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32) i32 {
    _ = a;
    _ = b;
    _ = c;
    _ = d;
    _ = e;
    _ = f;
    return func(g, h, i, j, k, l);
}

export fn frontier_indirect_stack_arg_forward(func: Sum12Fn, a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32) i32 {
    return func(a, b, c, d, e, f, g, h, i, j, k, l);
}

export fn frontier_indirect_eight_stack_arg_forward(func: Sum14Fn, a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32, m: i32, n: i32) i32 {
    return func(a, b, c, d, e, f, g, h, i, j, k, l, m, n);
}

export fn frontier_indirect_eighteen_stack_arg_forward(func: Sum24Fn, a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32, m: i32, n: i32, o: i32, p: i32, q: i32, r: i32, s: i32, t: i32, u: i32, v: i32, w: i32, x: i32) i32 {
    return func(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x);
}

export fn frontier_ptr_stack_arg_forward(a: *const i32, b: *const i32, c: *const i32, d: *const i32, e: *const i32, f: *const i32, g: *const i32, h: *const i32) i32 {
    return frontier_sum8_ptr(a, b, c, d, e, f, g, h);
}

export fn frontier_indirect_ptr_stack_arg_forward(func: Sum8PtrFn, a: *const i32, b: *const i32, c: *const i32, d: *const i32, e: *const i32, f: *const i32, g: *const i32, h: *const i32) i32 {
    return func(a, b, c, d, e, f, g, h);
}

export fn frontier_ptr_return_param(a: *const i32, b: *const i32) *const i32 {
    _ = a;
    return b;
}

export fn frontier_ptr_return_direct_call(a: *const i32, b: *const i32, tag: i32) *const i32 {
    return frontier_choose_ptr(a, b, tag);
}

export fn frontier_ptr_return_indirect_call(func: ChoosePtrFn, a: *const i32, b: *const i32, tag: i32) *const i32 {
    return func(a, b, tag);
}

export fn frontier_i32_swapped_direct_call(a: i32, b: i32) i32 {
    return frontier_sub_i32(b, a);
}

export fn frontier_i64_swapped_direct_call(a: i64, b: i64) i64 {
    return frontier_sub_i64(b, a);
}

export fn frontier_ptr_swapped_direct_call(a: *const i32, b: *const i32, tag: i32) *const i32 {
    return frontier_choose_ptr(b, a, tag);
}

export fn frontier_f32_swapped_direct_call(a: f32, b: f32) f32 {
    return frontier_sub_f32(b, a);
}

export fn frontier_f64_swapped_direct_call(a: f64, b: f64) f64 {
    return frontier_sub_f64(b, a);
}

export fn frontier_i32_three_cycle_direct_call(a: i32, b: i32, c: i32) i32 {
    return frontier_weighted3_i32(b, c, a);
}

export fn frontier_i64_three_cycle_direct_call(a: i64, b: i64, c: i64) i64 {
    return frontier_weighted3_i64(b, c, a);
}

export fn frontier_i32_six_cycle_direct_call(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32) i32 {
    return frontier_weighted6_i32(b, c, d, e, f, a);
}

export fn frontier_i32_swapped_indirect_call(a: i32, b: i32, func: SubI32Fn) i32 {
    return func(b, a);
}

export fn frontier_i64_swapped_indirect_call(a: i64, b: i64, func: SubI64Fn) i64 {
    return func(b, a);
}

export fn frontier_ptr_swapped_indirect_call(a: *const i32, b: *const i32, tag: i32, func: ChoosePtrFn) *const i32 {
    return func(b, a, tag);
}

export fn frontier_f32_swapped_indirect_call(a: f32, b: f32, func: SubF32Fn) f32 {
    return func(b, a);
}

export fn frontier_f64_swapped_indirect_call(a: f64, b: f64, func: SubF64Fn) f64 {
    return func(b, a);
}

export fn frontier_indirect_two_live_after_call(func: IdI32Fn, a: i32, b: i32, c: i32) i32 {
    const r = func(a);
    return b + c + r;
}

export fn frontier_computed_stack_arg_call(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32) i32 {
    const computed = g + 1;
    return frontier_sum12_i32(a, b, c, d, e, f, computed, 8, 9, 10, 11, 12);
}

export fn frontier_i64_stack_arg_to_registers(a: i64, b: i64, c: i64, d: i64, e: i64, f: i64, g: i64, h: i64, i: i64, j: i64, k: i64, l: i64) i64 {
    _ = a;
    _ = b;
    _ = c;
    _ = d;
    _ = e;
    _ = f;
    return frontier_sum6_i64(g, h, i, j, k, l);
}

export fn frontier_indirect_i64_stack_arg_forward(func: Sum8I64Fn, a: i64, b: i64, c: i64, d: i64, e: i64, f: i64, g: i64, h: i64) i64 {
    return func(a, b, c, d, e, f, g, h);
}

export fn frontier_indirect_pair64_make(func: MakePair64Fn, a: i64, b: i64) Pair64 {
    return func(a, b);
}

export fn frontier_indirect_pair64_first(func: Pair64FirstFn, value: Pair64) i64 {
    return func(value);
}

export fn frontier_computed_i64_stack_arg_call(a: i64, b: i64, c: i64, d: i64, e: i64, f: i64, g: i64) i64 {
    const computed = g + 1;
    return frontier_sum8_i64(a, b, c, d, e, f, computed, 8);
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

export fn frontier_ten_live_after_call(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32) i32 {
    const r = frontier_id_i32(f);
    return a + b + c + d + e + f + g + h + i + j + r;
}

export fn frontier_eleven_live_after_call(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32) i32 {
    const r = frontier_id_i32(f);
    return a + b + c + d + e + f + g + h + i + j + k + r;
}

export fn frontier_twelve_live_after_call(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32) i32 {
    const r = frontier_id_i32(f);
    return a + b + c + d + e + f + g + h + i + j + k + l + r;
}

export fn frontier_thirteen_live_after_call(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32, m: i32) i32 {
    const r = frontier_id_i32(f);
    return a + b + c + d + e + f + g + h + i + j + k + l + m + r;
}

export fn frontier_fourteen_live_after_call(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32, m: i32, n: i32) i32 {
    const r = frontier_id_i32(f);
    return a + b + c + d + e + f + g + h + i + j + k + l + m + n + r;
}

export fn frontier_eighteen_live_after_call(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32, m: i32, n: i32, o: i32, p: i32, q: i32, r_arg: i32) i32 {
    const r = frontier_id_i32(f);
    return a + b + c + d + e + f + g + h + i + j + k + l + m + n + o + p + q + r_arg + r;
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

export fn frontier_indirect_two_f32_live_sum_after_call(func: VoidFn, a: f32, b: f32) f32 {
    func();
    return a + b;
}

export fn frontier_indirect_two_f64_live_sum_after_call(func: VoidFn, a: f64, b: f64) f64 {
    func();
    return a + b;
}

export fn frontier_two_void_calls_two_f32_live_sum(a: f32, b: f32) f32 {
    frontier_touch_none();
    frontier_touch_none();
    return a + b;
}

export fn frontier_two_void_calls_two_f64_live_sum(a: f64, b: f64) f64 {
    frontier_touch_none();
    frontier_touch_none();
    return a + b;
}

export fn frontier_two_indirect_void_calls_two_f32_live_sum(func: VoidFn, a: f32, b: f32) f32 {
    func();
    func();
    return a + b;
}

export fn frontier_two_indirect_void_calls_two_f64_live_sum(func: VoidFn, a: f64, b: f64) f64 {
    func();
    func();
    return a + b;
}

export fn frontier_mixed_i32_f32_live_sum_after_call(a: i32, b: f32) f32 {
    frontier_touch_none();
    return @as(f32, @floatFromInt(a)) + b;
}

export fn frontier_mixed_i32_f64_live_sum_after_call(a: i32, b: f64) f64 {
    frontier_touch_none();
    return @as(f64, @floatFromInt(a)) + b;
}

export fn frontier_mixed_i64_f32_live_sum_after_call(a: i64, b: f32) f32 {
    frontier_touch_none();
    return @as(f32, @floatFromInt(a)) + b;
}

export fn frontier_mixed_i64_f64_live_sum_after_call(a: i64, b: f64) f64 {
    frontier_touch_none();
    return @as(f64, @floatFromInt(a)) + b;
}

export fn frontier_indirect_mixed_i32_f32_live_sum_after_call(func: VoidFn, a: i32, b: f32) f32 {
    func();
    return @as(f32, @floatFromInt(a)) + b;
}

export fn frontier_indirect_mixed_i32_f64_live_sum_after_call(func: VoidFn, a: i32, b: f64) f64 {
    func();
    return @as(f64, @floatFromInt(a)) + b;
}

export fn frontier_indirect_mixed_i64_f32_live_sum_after_call(func: VoidFn, a: i64, b: f32) f32 {
    func();
    return @as(f32, @floatFromInt(a)) + b;
}

export fn frontier_indirect_mixed_i64_f64_live_sum_after_call(func: VoidFn, a: i64, b: f64) f64 {
    func();
    return @as(f64, @floatFromInt(a)) + b;
}

export fn frontier_two_void_calls_mixed_i32_f32_live_sum(a: i32, b: f32) f32 {
    frontier_touch_none();
    frontier_touch_none();
    return @as(f32, @floatFromInt(a)) + b;
}

export fn frontier_two_void_calls_mixed_i32_f64_live_sum(a: i32, b: f64) f64 {
    frontier_touch_none();
    frontier_touch_none();
    return @as(f64, @floatFromInt(a)) + b;
}

export fn frontier_two_void_calls_mixed_i64_f32_live_sum(a: i64, b: f32) f32 {
    frontier_touch_none();
    frontier_touch_none();
    return @as(f32, @floatFromInt(a)) + b;
}

export fn frontier_two_void_calls_mixed_i64_f64_live_sum(a: i64, b: f64) f64 {
    frontier_touch_none();
    frontier_touch_none();
    return @as(f64, @floatFromInt(a)) + b;
}

export fn frontier_two_indirect_void_calls_mixed_i32_f32_live_sum(func: VoidFn, a: i32, b: f32) f32 {
    func();
    func();
    return @as(f32, @floatFromInt(a)) + b;
}

export fn frontier_two_indirect_void_calls_mixed_i32_f64_live_sum(func: VoidFn, a: i32, b: f64) f64 {
    func();
    func();
    return @as(f64, @floatFromInt(a)) + b;
}

export fn frontier_two_indirect_void_calls_mixed_i64_f32_live_sum(func: VoidFn, a: i64, b: f32) f32 {
    func();
    func();
    return @as(f32, @floatFromInt(a)) + b;
}

export fn frontier_two_indirect_void_calls_mixed_i64_f64_live_sum(func: VoidFn, a: i64, b: f64) f64 {
    func();
    func();
    return @as(f64, @floatFromInt(a)) + b;
}

export fn frontier_two_f32_live_sum_after_arg_call(a: f32, b: f32) f32 {
    frontier_touch_f32(b);
    return a + b;
}

export fn frontier_two_f64_live_sum_after_arg_call(a: f64, b: f64) f64 {
    frontier_touch_f64(b);
    return a + b;
}

export fn frontier_three_f32_live_sum_after_two_arg_call(a: f32, b: f32, c: f32) f32 {
    frontier_touch2_f32(b, c);
    return a + b + c;
}

export fn frontier_three_f64_live_sum_after_two_arg_call(a: f64, b: f64, c: f64) f64 {
    frontier_touch2_f64(b, c);
    return a + b + c;
}

export fn frontier_four_f32_live_sum_after_three_arg_call(a: f32, b: f32, c: f32, d: f32) f32 {
    frontier_touch3_f32(b, c, d);
    return a + b + c + d;
}

export fn frontier_four_f64_live_sum_after_three_arg_call(a: f64, b: f64, c: f64, d: f64) f64 {
    frontier_touch3_f64(b, c, d);
    return a + b + c + d;
}

export fn frontier_six_f32_live_sum_after_five_arg_call(a: f32, b: f32, c: f32, d: f32, e: f32, f: f32) f32 {
    frontier_touch5_f32(b, c, d, e, f);
    return a + b + c + d + e + f;
}

export fn frontier_six_f64_live_sum_after_five_arg_call(a: f64, b: f64, c: f64, d: f64, e: f64, f: f64) f64 {
    frontier_touch5_f64(b, c, d, e, f);
    return a + b + c + d + e + f;
}

export fn frontier_i32_live_across_f64_arg_call(a: i32, b: f64, c: i32) i32 {
    frontier_touch_f64(b);
    return a + c;
}

export fn frontier_indirect_two_f32_live_sum_after_arg_call(func: TouchF32Fn, a: f32, b: f32) f32 {
    func(b);
    return a + b;
}

export fn frontier_indirect_two_f64_live_sum_after_arg_call(func: TouchF64Fn, a: f64, b: f64) f64 {
    func(b);
    return a + b;
}

export fn frontier_i32_live_across_indirect_f64_arg_call(func: TouchF64Fn, a: i32, b: f64, c: i32) i32 {
    func(b);
    return a + c;
}

export fn frontier_indirect_three_f32_live_sum_after_two_arg_call(func: Touch2F32Fn, a: f32, b: f32, c: f32) f32 {
    func(b, c);
    return a + b + c;
}

export fn frontier_indirect_three_f64_live_sum_after_two_arg_call(func: Touch2F64Fn, a: f64, b: f64, c: f64) f64 {
    func(b, c);
    return a + b + c;
}

export fn frontier_indirect_four_f32_live_sum_after_three_arg_call(func: Touch3F32Fn, a: f32, b: f32, c: f32, d: f32) f32 {
    func(b, c, d);
    return a + b + c + d;
}

export fn frontier_indirect_four_f64_live_sum_after_three_arg_call(func: Touch3F64Fn, a: f64, b: f64, c: f64, d: f64) f64 {
    func(b, c, d);
    return a + b + c + d;
}

export fn frontier_indirect_six_f32_live_sum_after_five_arg_call(func: Touch5F32Fn, a: f32, b: f32, c: f32, d: f32, e: f32, f: f32) f32 {
    func(b, c, d, e, f);
    return a + b + c + d + e + f;
}

export fn frontier_indirect_six_f64_live_sum_after_five_arg_call(func: Touch5F64Fn, a: f64, b: f64, c: f64, d: f64, e: f64, f: f64) f64 {
    func(b, c, d, e, f);
    return a + b + c + d + e + f;
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

export fn frontier_indirect_five_f32_external_call(func: Sum5F32Fn, a: f32, b: f32, c: f32, d: f32, e: f32) f32 {
    return func(a, b, c, d, e);
}

export fn frontier_indirect_five_f64_external_call(func: Sum5F64Fn, a: f64, b: f64, c: f64, d: f64, e: f64) f64 {
    return func(a, b, c, d, e);
}
