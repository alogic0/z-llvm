const Pair = extern struct {
    a: i32,
    b: i32,
};

export fn make_pair(a: i32, b: i32) Pair {
    return .{ .a = a, .b = b };
}

export fn pair_first(pair: Pair) i32 {
    return pair.a;
}
