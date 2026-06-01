comptime {
    if (add(1, 2) != 3) @compileError("ReleaseSafe tiny scalar check failed");
}

export fn main() c_int {
    return 0;
}

fn add(a: i32, b: i32) i32 {
    return a + b;
}
