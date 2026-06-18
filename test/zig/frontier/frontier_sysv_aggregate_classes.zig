const Mixed = extern struct {
    a: i64,
    b: f64,
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

export fn frontier_mixed_int(value: Mixed) i64 {
    return value.a;
}

export fn frontier_mixed_float(value: Mixed) f64 {
    return value.b;
}

export fn frontier_nested_pair_sum(value: NestedPair) i32 {
    return value.left.a + value.left.b + value.right.a + value.right.b;
}

export fn frontier_array_pair_sum(value: ArrayPair) i64 {
    return value.values[0] + value.values[1];
}
