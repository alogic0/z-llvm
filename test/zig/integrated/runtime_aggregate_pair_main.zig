const Pair = extern struct {
    a: i32,
    b: i32,
};

export fn main() c_int {
    const pair = makePair(1, 2);
    return pairFirst(pair);
}

fn makePair(a: i32, b: i32) Pair {
    return .{ .a = a, .b = b };
}

fn pairFirst(pair: Pair) i32 {
    return pair.a;
}
