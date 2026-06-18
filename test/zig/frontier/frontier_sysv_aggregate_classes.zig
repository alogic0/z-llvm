const Mixed = extern struct {
    a: i64,
    b: f64,
};

const DoublePair = extern struct {
    a: f64,
    b: f64,
};

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

const NestedMixed = extern struct {
    ints: Pair32,
    value: f64,
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

export fn frontier_mixed_call_make(a: i64, b: f64) Mixed {
    return helperMixedMake(a, b);
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

export fn frontier_reverse_mixed_float(value: ReverseMixed) f64 {
    return value.a;
}

export fn frontier_reverse_mixed_int(value: ReverseMixed) i64 {
    return value.b;
}

export fn frontier_reverse_mixed_make(a: f64, b: i64) ReverseMixed {
    return .{ .a = a, .b = b };
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

export fn frontier_array_pair_sum(value: ArrayPair) i64 {
    return value.values[0] + value.values[1];
}

export fn frontier_nested_mixed_int_sum(value: NestedMixed) i32 {
    return value.ints.a + value.ints.b;
}
