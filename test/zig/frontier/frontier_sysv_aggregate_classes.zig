const Mixed = extern struct {
    a: i64,
    b: f64,
};

const DoublePair = extern struct {
    a: f64,
    b: f64,
};

const FloatPair = extern struct {
    a: f32,
    b: f32,
};
const FloatPairSumFn = *const fn (FloatPair) callconv(.c) f32;

const ReverseMixed = extern struct {
    a: f64,
    b: i64,
};

const Pair32 = extern struct {
    a: i32,
    b: i32,
};

const NestedPair = extern struct {
    left: Pair32,
    right: Pair32,
};

const ArrayPair = extern struct {
    values: [2]i64,
};

const ArrayDouble = extern struct {
    values: [2]f64,
};
const ArrayDoubleMakeFn = *const fn (f64, f64) callconv(.c) ArrayDouble;
const ArrayDoubleSumFn = *const fn (ArrayDouble) callconv(.c) f64;

const DoubleBox = extern struct {
    value: f64,
};

const NestedDouble = extern struct {
    left: DoubleBox,
    right: DoubleBox,
};

const NestedMixed = extern struct {
    ints: Pair32,
    value: f64,
};

const SmallMixed = extern struct {
    a: i32,
    b: f64,
};

const SmallReverseMixed = extern struct {
    a: f64,
    b: i32,
};

const PackedMixed = extern struct {
    a: i32,
    b: i32,
    c: f64,
};

const PackedReverseMixed = extern struct {
    a: f64,
    b: i32,
    c: i32,
};

export fn frontier_mixed_int(value: Mixed) i64 {
    return value.a;
}

export fn frontier_mixed_float(value: Mixed) f64 {
    return value.b;
}

export fn frontier_mixed_make(a: i64, b: f64) Mixed {
    return .{ .a = a, .b = b };
}

noinline fn helperMixedMake(a: i64, b: f64) Mixed {
    return .{ .a = a, .b = b };
}

noinline fn helperMixedInt(value: Mixed) i64 {
    return value.a;
}

export fn frontier_mixed_call_make(a: i64, b: f64) Mixed {
    return helperMixedMake(a, b);
}

export fn frontier_stack_mixed_call_int(a0: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64, value: Mixed) i64 {
    _ = a0;
    _ = a1;
    _ = a2;
    _ = a3;
    _ = a4;
    _ = a5;
    return helperMixedInt(value);
}

export fn frontier_shifted_mixed_call_int(prefix: i64, value: Mixed) i64 {
    _ = prefix;
    return helperMixedInt(value);
}

export fn frontier_double_pair_first(value: DoublePair) f64 {
    return value.a;
}

export fn frontier_double_pair_second(value: DoublePair) f64 {
    return value.b;
}

export fn frontier_double_pair_make(a: f64, b: f64) DoublePair {
    return .{ .a = a, .b = b };
}

export fn frontier_float_pair_first(value: FloatPair) f32 {
    return value.a;
}

export fn frontier_float_pair_second(value: FloatPair) f32 {
    return value.b;
}

export fn frontier_float_pair_make(a: f32, b: f32) FloatPair {
    return .{ .a = a, .b = b };
}

noinline fn helperFloatPairSum(value: FloatPair) f32 {
    return value.a + value.b;
}

export fn frontier_float_pair_call_sum(value: FloatPair) f32 {
    return helperFloatPairSum(value);
}

export fn frontier_shifted_float_pair_call_sum(prefix: f64, value: FloatPair) f32 {
    _ = prefix;
    return helperFloatPairSum(value);
}

export fn frontier_indirect_float_pair_sum(func: FloatPairSumFn, value: FloatPair) f32 {
    return func(value);
}

export fn frontier_reverse_mixed_float(value: ReverseMixed) f64 {
    return value.a;
}

export fn frontier_reverse_mixed_int(value: ReverseMixed) i64 {
    return value.b;
}

export fn frontier_reverse_mixed_make(a: f64, b: i64) ReverseMixed {
    return .{ .a = a, .b = b };
}

noinline fn helperReverseMixedFloat(value: ReverseMixed) f64 {
    return value.a;
}

export fn frontier_shifted_reverse_mixed_call_float(prefix: f64, value: ReverseMixed) f64 {
    _ = prefix;
    return helperReverseMixedFloat(value);
}

export fn frontier_nested_pair_sum(value: NestedPair) i32 {
    return value.left.a + value.left.b + value.right.a + value.right.b;
}

noinline fn helperNestedPairSum(value: NestedPair) i32 {
    return value.left.a + value.left.b + value.right.a + value.right.b;
}

export fn frontier_nested_pair_call_sum(value: NestedPair) i32 {
    return helperNestedPairSum(value);
}

noinline fn helperArrayPairSum(value: ArrayPair) i64 {
    return value.values[0] + value.values[1];
}

noinline fn helperArrayPairSumAfterSix(a0: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64, value: ArrayPair) i64 {
    _ = a0;
    _ = a1;
    _ = a2;
    _ = a3;
    _ = a4;
    _ = a5;
    return value.values[0] + value.values[1];
}

export fn frontier_nested_pair_make(a: i32, b: i32, c: i32, d: i32) NestedPair {
    return .{ .left = .{ .a = a, .b = b }, .right = .{ .a = c, .b = d } };
}

export fn frontier_array_pair_sum(value: ArrayPair) i64 {
    return value.values[0] + value.values[1];
}

export fn frontier_array_pair_make(a: i64, b: i64) ArrayPair {
    return .{ .values = .{ a, b } };
}

export fn frontier_stack_array_pair_first(a0: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64, value: ArrayPair) i64 {
    _ = a0;
    _ = a1;
    _ = a2;
    _ = a3;
    _ = a4;
    _ = a5;
    return value.values[0];
}

export fn frontier_stack_array_pair_second(a0: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64, value: ArrayPair) i64 {
    _ = a0;
    _ = a1;
    _ = a2;
    _ = a3;
    _ = a4;
    _ = a5;
    return value.values[1];
}

export fn frontier_stack_array_pair_call_sum(a0: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64, value: ArrayPair) i64 {
    _ = a0;
    _ = a1;
    _ = a2;
    _ = a3;
    _ = a4;
    _ = a5;
    return helperArrayPairSum(value);
}

export fn frontier_stack_array_pair_call_sum_after_six(a0: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64, value: ArrayPair) i64 {
    return helperArrayPairSumAfterSix(a0, a1, a2, a3, a4, a5, value);
}

export fn frontier_register_array_pair_call_sum_after_six(value: ArrayPair) i64 {
    return helperArrayPairSumAfterSix(1, 2, 3, 4, 5, 6, value);
}

noinline fn helperArrayDoubleSum(value: ArrayDouble) f64 {
    return value.values[0] + value.values[1];
}

noinline fn helperArrayDoubleSumAfterEight(a0: f64, a1: f64, a2: f64, a3: f64, a4: f64, a5: f64, a6: f64, a7: f64, value: ArrayDouble) f64 {
    _ = a0;
    _ = a1;
    _ = a2;
    _ = a3;
    _ = a4;
    _ = a5;
    _ = a6;
    _ = a7;
    return value.values[0] + value.values[1];
}

export fn frontier_array_double_first(value: ArrayDouble) f64 {
    return value.values[0];
}

export fn frontier_array_double_second(value: ArrayDouble) f64 {
    return value.values[1];
}

export fn frontier_array_double_make(a: f64, b: f64) ArrayDouble {
    return .{ .values = .{ a, b } };
}

export fn frontier_stack_array_double_call_sum(a0: f64, a1: f64, a2: f64, a3: f64, a4: f64, a5: f64, a6: f64, a7: f64, value: ArrayDouble) f64 {
    _ = a0;
    _ = a1;
    _ = a2;
    _ = a3;
    _ = a4;
    _ = a5;
    _ = a6;
    _ = a7;
    return helperArrayDoubleSum(value);
}

export fn frontier_register_array_double_call_sum_after_eight(value: ArrayDouble, a0: f64, a1: f64, a2: f64, a3: f64, a4: f64, a5: f64, a6: f64, a7: f64) f64 {
    return helperArrayDoubleSumAfterEight(a0, a1, a2, a3, a4, a5, a6, a7, value);
}

export fn frontier_indirect_array_double_make(func: ArrayDoubleMakeFn, a: f64, b: f64) ArrayDouble {
    return func(a, b);
}

export fn frontier_indirect_array_double_sum(func: ArrayDoubleSumFn, value: ArrayDouble) f64 {
    return func(value);
}

export fn frontier_nested_double_left(value: NestedDouble) f64 {
    return value.left.value;
}

export fn frontier_nested_double_right(value: NestedDouble) f64 {
    return value.right.value;
}

export fn frontier_nested_double_make(a: f64, b: f64) NestedDouble {
    return .{ .left = .{ .value = a }, .right = .{ .value = b } };
}

export fn frontier_nested_mixed_int_sum(value: NestedMixed) i32 {
    return value.ints.a + value.ints.b;
}

export fn frontier_nested_mixed_float(value: NestedMixed) f64 {
    return value.value;
}

export fn frontier_nested_mixed_make(a: i32, b: i32, c: f64) NestedMixed {
    return .{ .ints = .{ .a = a, .b = b }, .value = c };
}

export fn frontier_small_mixed_int(value: SmallMixed) i32 {
    return value.a;
}

export fn frontier_small_mixed_float(value: SmallMixed) f64 {
    return value.b;
}

export fn frontier_small_reverse_mixed_float(value: SmallReverseMixed) f64 {
    return value.a;
}

export fn frontier_small_reverse_mixed_int(value: SmallReverseMixed) i32 {
    return value.b;
}

export fn frontier_packed_mixed_low_int(value: PackedMixed) i32 {
    return value.a;
}

export fn frontier_packed_mixed_high_int(value: PackedMixed) i32 {
    return value.b;
}

export fn frontier_packed_mixed_float(value: PackedMixed) f64 {
    return value.c;
}

export fn frontier_packed_mixed_make(a: i32, b: i32, c: f64) PackedMixed {
    return .{ .a = a, .b = b, .c = c };
}

export fn frontier_packed_reverse_mixed_float(value: PackedReverseMixed) f64 {
    return value.a;
}

export fn frontier_packed_reverse_mixed_low_int(value: PackedReverseMixed) i32 {
    return value.b;
}

export fn frontier_packed_reverse_mixed_high_int(value: PackedReverseMixed) i32 {
    return value.c;
}

export fn frontier_packed_reverse_mixed_make(a: f64, b: i32, c: i32) PackedReverseMixed {
    return .{ .a = a, .b = b, .c = c };
}
