export fn main() c_int {
    sideEffectFree();
    if (add(1, 2) != 3) return 1;
    return 0;
}

fn add(a: i32, b: i32) i32 {
    return a + b;
}

fn sideEffectFree() void {}
