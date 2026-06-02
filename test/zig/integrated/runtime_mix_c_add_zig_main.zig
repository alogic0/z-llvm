threadlocal var C_k: i32 = 2;
var zig_k: i32 = 1;

export fn main() c_int {
    return add_zig(4);
}

fn add_zig(value: i32) i32 {
    return zig_k + value + C_k;
}
