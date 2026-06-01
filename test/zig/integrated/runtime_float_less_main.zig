export fn main() c_int {
    return if (floatLess(1.0, 2.0)) 0 else 1;
}

fn floatLess(a: f32, b: f32) bool {
    return a < b;
}
