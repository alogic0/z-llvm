export fn main() c_int {
    return if (floatRem(5.5, 2.0) == 1.5) 0 else 1;
}

fn floatRem(a: f32, b: f32) f32 {
    return @rem(a, b);
}
