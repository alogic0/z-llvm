export fn main() c_int {
    return if (floatMul(3.0, 2.0) == 6.0) 0 else 1;
}

fn floatMul(a: f64, b: f64) f64 {
    return a * b;
}
