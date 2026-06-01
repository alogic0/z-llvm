export fn main() c_int {
    return if (floatAdd(1.0, 2.0) == 3.0) 0 else 1;
}

fn floatAdd(a: f32, b: f32) f32 {
    return a + b;
}
