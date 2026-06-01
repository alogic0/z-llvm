export fn main() c_int {
    return if (i64Value() == 4) 0 else 1;
}

fn i64Value() i64 {
    return 2 + 2;
}
