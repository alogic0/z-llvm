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

const FloatArray = extern struct {
    values: [4]f32,
};
const FloatArraySumFn = *const fn (FloatArray) callconv(.c) f32;
const FloatArrayMakeFn = *const fn (f32, f32, f32, f32) callconv(.c) FloatArray;

const ReverseMixed = extern struct {
    a: f64,
    b: i64,
};
const ReverseMixedFloatFn = *const fn (ReverseMixed) callconv(.c) f64;
const ReverseMixedMakeFn = *const fn (f64, i64) callconv(.c) ReverseMixed;

const Pair32 = extern struct {
    a: i32,
    b: i32,
};

const NestedPair = extern struct {
    left: Pair32,
    right: Pair32,
};
const NestedPairSumFn = *const fn (NestedPair) callconv(.c) i32;

const ArrayPair = extern struct {
    values: [2]i64,
};
const ArrayPairSumFn = *const fn (ArrayPair) callconv(.c) i64;

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
const NestedMixedIntFn = *const fn (NestedMixed) callconv(.c) i32;
const NestedMixedMakeFn = *const fn (i32, i32, f64) callconv(.c) NestedMixed;
const NestedMixedForwardFn = *const fn (NestedMixed) callconv(.c) NestedMixed;

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

noinline fn helperMixedIntAfterPressure(a0: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64, f0: f64, f1: f64, f2: f64, f3: f64, f4: f64, f5: f64, f6: f64, f7: f64, value: Mixed) i64 {
    _ = a0;
    _ = a1;
    _ = a2;
    _ = a3;
    _ = a4;
    _ = a5;
    _ = f0;
    _ = f1;
    _ = f2;
    _ = f3;
    _ = f4;
    _ = f5;
    _ = f6;
    _ = f7;
    return value.a;
}

noinline fn helperMixedFloatAfterPressure(a0: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64, f0: f64, f1: f64, f2: f64, f3: f64, f4: f64, f5: f64, f6: f64, f7: f64, value: Mixed) f64 {
    _ = a0;
    _ = a1;
    _ = a2;
    _ = a3;
    _ = a4;
    _ = a5;
    _ = f0;
    _ = f1;
    _ = f2;
    _ = f3;
    _ = f4;
    _ = f5;
    _ = f6;
    _ = f7;
    return value.b;
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

export fn frontier_stack_mixed_call_int_after_pressure(a0: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64, f0: f64, f1: f64, f2: f64, f3: f64, f4: f64, f5: f64, f6: f64, f7: f64, value: Mixed) i64 {
    return helperMixedIntAfterPressure(a0, a1, a2, a3, a4, a5, f0, f1, f2, f3, f4, f5, f6, f7, value);
}

export fn frontier_stack_mixed_call_float_after_pressure(a0: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64, f0: f64, f1: f64, f2: f64, f3: f64, f4: f64, f5: f64, f6: f64, f7: f64, value: Mixed) f64 {
    return helperMixedFloatAfterPressure(a0, a1, a2, a3, a4, a5, f0, f1, f2, f3, f4, f5, f6, f7, value);
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

export fn frontier_float_array_first(value: FloatArray) f32 {
    return value.values[0];
}

export fn frontier_float_array_second(value: FloatArray) f32 {
    return value.values[1];
}

export fn frontier_float_array_third(value: FloatArray) f32 {
    return value.values[2];
}

export fn frontier_float_array_fourth(value: FloatArray) f32 {
    return value.values[3];
}

export fn frontier_float_array_make(a: f32, b: f32, c: f32, d: f32) FloatArray {
    return .{ .values = .{ a, b, c, d } };
}

noinline fn helperFloatArraySum(value: FloatArray) f32 {
    return value.values[0] + value.values[1] + value.values[2] + value.values[3];
}

noinline fn helperFloatArraySumAfterEight(a0: f64, a1: f64, a2: f64, a3: f64, a4: f64, a5: f64, a6: f64, a7: f64, value: FloatArray) f32 {
    _ = a0;
    _ = a1;
    _ = a2;
    _ = a3;
    _ = a4;
    _ = a5;
    _ = a6;
    _ = a7;
    return value.values[0] + value.values[1] + value.values[2] + value.values[3];
}

noinline fn helperFloatArrayMake(a: f32, b: f32, c: f32, d: f32) FloatArray {
    return .{ .values = .{ a, b, c, d } };
}

export fn frontier_float_array_call_sum(value: FloatArray) f32 {
    return helperFloatArraySum(value);
}

export fn frontier_indirect_float_array_sum(func: FloatArraySumFn, value: FloatArray) f32 {
    return func(value);
}

export fn frontier_stack_float_array_call_sum_after_eight(a0: f64, a1: f64, a2: f64, a3: f64, a4: f64, a5: f64, a6: f64, a7: f64, value: FloatArray) f32 {
    return helperFloatArraySumAfterEight(a0, a1, a2, a3, a4, a5, a6, a7, value);
}

export fn frontier_float_array_call_make(a: f32, b: f32, c: f32, d: f32) FloatArray {
    return helperFloatArrayMake(a, b, c, d);
}

export fn frontier_indirect_float_array_make(func: FloatArrayMakeFn, a: f32, b: f32, c: f32, d: f32) FloatArray {
    return func(a, b, c, d);
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

export fn frontier_indirect_reverse_mixed_call_float(func: ReverseMixedFloatFn, value: ReverseMixed) f64 {
    return func(value);
}

export fn frontier_indirect_reverse_mixed_make(func: ReverseMixedMakeFn, a: f64, b: i64) ReverseMixed {
    return func(a, b);
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

export fn frontier_indirect_nested_pair_sum(func: NestedPairSumFn, value: NestedPair) i32 {
    return func(value);
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

export fn frontier_indirect_array_pair_sum(func: ArrayPairSumFn, value: ArrayPair) i64 {
    return func(value);
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

export fn frontier_deep_stack_array_pair_call_sum_after_six(
    a0: i64,
    a1: i64,
    a2: i64,
    a3: i64,
    a4: i64,
    a5: i64,
    a6: i64,
    a7: i64,
    a8: i64,
    a9: i64,
    a10: i64,
    a11: i64,
    a12: i64,
    a13: i64,
    a14: i64,
    a15: i64,
    a16: i64,
    a17: i64,
    a18: i64,
    a19: i64,
    a20: i64,
    a21: i64,
    a22: i64,
    a23: i64,
    a24: i64,
    a25: i64,
    a26: i64,
    a27: i64,
    a28: i64,
    a29: i64,
    a30: i64,
    a31: i64,
    a32: i64,
    a33: i64,
    a34: i64,
    a35: i64,
    a36: i64,
    a37: i64,
    value: ArrayPair,
) i64 {
    _ = a6;
    _ = a7;
    _ = a8;
    _ = a9;
    _ = a10;
    _ = a11;
    _ = a12;
    _ = a13;
    _ = a14;
    _ = a15;
    _ = a16;
    _ = a17;
    _ = a18;
    _ = a19;
    _ = a20;
    _ = a21;
    _ = a22;
    _ = a23;
    _ = a24;
    _ = a25;
    _ = a26;
    _ = a27;
    _ = a28;
    _ = a29;
    _ = a30;
    _ = a31;
    _ = a32;
    _ = a33;
    _ = a34;
    _ = a35;
    _ = a36;
    _ = a37;
    return helperArrayPairSumAfterSix(a0, a1, a2, a3, a4, a5, value);
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

export fn frontier_shifted_array_double_second(prefix: f64, value: ArrayDouble) f64 {
    _ = prefix;
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

export fn frontier_shifted_array_double_call_sum(prefix: f64, value: ArrayDouble) f64 {
    _ = prefix;
    return helperArrayDoubleSum(value);
}

export fn frontier_register_array_double_call_sum_after_eight(value: ArrayDouble, a0: f64, a1: f64, a2: f64, a3: f64, a4: f64, a5: f64, a6: f64, a7: f64) f64 {
    return helperArrayDoubleSumAfterEight(a0, a1, a2, a3, a4, a5, a6, a7, value);
}

export fn frontier_deep_stack_array_double_call_sum(
    a0: f64,
    a1: f64,
    a2: f64,
    a3: f64,
    a4: f64,
    a5: f64,
    a6: f64,
    a7: f64,
    a8: f64,
    a9: f64,
    a10: f64,
    a11: f64,
    a12: f64,
    a13: f64,
    a14: f64,
    a15: f64,
    a16: f64,
    a17: f64,
    a18: f64,
    a19: f64,
    a20: f64,
    a21: f64,
    a22: f64,
    a23: f64,
    a24: f64,
    a25: f64,
    a26: f64,
    a27: f64,
    a28: f64,
    a29: f64,
    a30: f64,
    a31: f64,
    a32: f64,
    a33: f64,
    a34: f64,
    a35: f64,
    a36: f64,
    a37: f64,
    a38: f64,
    a39: f64,
    value: ArrayDouble,
) f64 {
    _ = a0;
    _ = a1;
    _ = a2;
    _ = a3;
    _ = a4;
    _ = a5;
    _ = a6;
    _ = a7;
    _ = a8;
    _ = a9;
    _ = a10;
    _ = a11;
    _ = a12;
    _ = a13;
    _ = a14;
    _ = a15;
    _ = a16;
    _ = a17;
    _ = a18;
    _ = a19;
    _ = a20;
    _ = a21;
    _ = a22;
    _ = a23;
    _ = a24;
    _ = a25;
    _ = a26;
    _ = a27;
    _ = a28;
    _ = a29;
    _ = a30;
    _ = a31;
    _ = a32;
    _ = a33;
    _ = a34;
    _ = a35;
    _ = a36;
    _ = a37;
    _ = a38;
    _ = a39;
    return helperArrayDoubleSum(value);
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

noinline fn helperNestedMixedIntSum(value: NestedMixed) i32 {
    return value.ints.a + value.ints.b;
}

noinline fn helperNestedMixedIntSumAfterPressure(a0: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64, f0: f64, f1: f64, f2: f64, f3: f64, f4: f64, f5: f64, f6: f64, f7: f64, value: NestedMixed) i32 {
    _ = a0;
    _ = a1;
    _ = a2;
    _ = a3;
    _ = a4;
    _ = a5;
    _ = f0;
    _ = f1;
    _ = f2;
    _ = f3;
    _ = f4;
    _ = f5;
    _ = f6;
    _ = f7;
    return value.ints.a + value.ints.b;
}

export fn frontier_nested_mixed_float(value: NestedMixed) f64 {
    return value.value;
}

export fn frontier_nested_mixed_make(a: i32, b: i32, c: f64) NestedMixed {
    return .{ .ints = .{ .a = a, .b = b }, .value = c };
}

noinline fn helperNestedMixedMake(a: i32, b: i32, c: f64) NestedMixed {
    return .{ .ints = .{ .a = a, .b = b }, .value = c };
}

noinline fn helperNestedMixedForward(value: NestedMixed) NestedMixed {
    return value;
}

export fn frontier_shifted_nested_mixed_call_int(prefix_int: i64, prefix_float: f64, value: NestedMixed) i32 {
    _ = prefix_int;
    _ = prefix_float;
    return helperNestedMixedIntSum(value);
}

export fn frontier_indirect_nested_mixed_call_int(func: NestedMixedIntFn, value: NestedMixed) i32 {
    return func(value);
}

export fn frontier_nested_mixed_call_make(a: i32, b: i32, c: f64) NestedMixed {
    return helperNestedMixedMake(a, b, c);
}

export fn frontier_indirect_nested_mixed_make(func: NestedMixedMakeFn, a: i32, b: i32, c: f64) NestedMixed {
    return func(a, b, c);
}

export fn frontier_nested_mixed_call_forward(value: NestedMixed) NestedMixed {
    return helperNestedMixedForward(value);
}

export fn frontier_indirect_nested_mixed_forward(func: NestedMixedForwardFn, value: NestedMixed) NestedMixed {
    return func(value);
}

export fn frontier_stack_nested_mixed_call_int_after_pressure(a0: i64, a1: i64, a2: i64, a3: i64, a4: i64, a5: i64, f0: f64, f1: f64, f2: f64, f3: f64, f4: f64, f5: f64, f6: f64, f7: f64, value: NestedMixed) i32 {
    return helperNestedMixedIntSumAfterPressure(a0, a1, a2, a3, a4, a5, f0, f1, f2, f3, f4, f5, f6, f7, value);
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
