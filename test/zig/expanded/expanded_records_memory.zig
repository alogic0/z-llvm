const Pair = extern struct {
    a: i32,
    b: i32,
};

var global_accumulator: i32 = 11;
threadlocal var tls_accumulator: i32 = 2;

export fn expanded_make_pair(a: i32, b: i32) Pair {
    return .{ .a = a, .b = b };
}

export fn expanded_pair_first(pair: Pair) i32 {
    return pair.a;
}

export fn expanded_global_update(delta: i32) i32 {
    global_accumulator += delta;
    return global_accumulator;
}

export fn expanded_tls_bump(delta: i32) i32 {
    tls_accumulator += delta;
    return tls_accumulator;
}
