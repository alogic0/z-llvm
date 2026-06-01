export fn main() c_int {
    return if (floatSub(5.0, 2.0) == 3.0) 0 else 1;
}

fn floatSub(a: f32, b: f32) f32 {
    return a - b;
}
