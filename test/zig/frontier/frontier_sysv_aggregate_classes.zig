const Mixed = extern struct {
    a: i64,
    b: f64,
};

export fn frontier_mixed_int(value: Mixed) i64 {
    return value.a;
}

export fn frontier_mixed_float(value: Mixed) f64 {
    return value.b;
}
