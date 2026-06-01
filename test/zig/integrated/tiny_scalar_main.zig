comptime {
    if (add(40, 2) != 42) @compileError("add positive check failed");
    if (add(-7, 9) != 2) @compileError("add mixed-sign check failed");
}

export fn main() c_int {
    return 0;
}

fn add(a: i32, b: i32) i32 {
    return a + b;
}
