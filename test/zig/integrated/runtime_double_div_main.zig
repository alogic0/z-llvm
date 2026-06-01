export fn main() c_int {
    return if (doubleDiv(6.0, 2.0) == 3.0) 0 else 1;
}

fn doubleDiv(a: f64, b: f64) f64 {
    return a / b;
}
