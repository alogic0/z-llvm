comptime {
    if (arraySum(10, 20, 12) != 42) @compileError("array sum selected check failed");
    if (arraySum(-5, 4, 1) != 0) @compileError("array sum signed check failed");
}

export fn main() c_int {
    return if (arraySum(10, 20, 12) == 42) 0 else 1;
}

fn arraySum(a: i32, b: i32, c: i32) i32 {
    const values = [3]i32{ a, b, c };
    return values[0] + values[1] + values[2];
}
