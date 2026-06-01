export fn main() c_int {
    return if (floatSelect(4.0, 5.0, true) == 4.0) 0 else 1;
}

fn floatSelect(a: f64, b: f64, flag: bool) f64 {
    return if (flag) a else b;
}
