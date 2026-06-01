comptime {
    if (i64Value() != 4) @compileError("i64 value check failed");
}

export fn main() c_int {
    return 0;
}

fn i64Value() i64 {
    return 2 + 2;
}
