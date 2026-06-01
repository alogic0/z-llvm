export fn main() c_int {
    sideEffectFree();
    if (add(40, 2) != 42) return 1;
    if (add(-7, 9) != 2) return 2;
    return 0;
}

fn add(a: i32, b: i32) i32 {
    return a + b;
}

fn sideEffectFree() void {}
