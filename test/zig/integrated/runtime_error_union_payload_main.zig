const SmallError = error{Bad};

comptime {
    if (errorUnionPayload(0) != 7) @compileError("error union success check failed");
    if (errorUnionPayload(1) != -1) @compileError("error union catch check failed");
}

export fn main() c_int {
    return if (errorUnionPayload(0) == 7) 0 else 1;
}

fn maybeError(flag: i32) SmallError!i32 {
    if (flag != 0) return error.Bad;
    return 7;
}

fn errorUnionPayload(flag: i32) i32 {
    return maybeError(flag) catch -1;
}
