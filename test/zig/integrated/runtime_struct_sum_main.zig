const Pair = extern struct {
    a: i32,
    b: i32,
};

var pair = Pair{ .a = 20, .b = 22 };

export fn main() c_int {
    return if (structSum(&pair) == 42) 0 else 1;
}

fn structSum(value: *const Pair) i32 {
    return value.a + value.b;
}
