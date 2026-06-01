comptime {
    if (optionalPayload(0, 42) != -1) @compileError("optional payload null check failed");
    if (optionalPayload(1, 42) != 42) @compileError("optional payload value check failed");
}

export fn main() c_int {
    return if (optionalPayload(1, 42) == 42) 0 else 1;
}

fn optionalPayload(flag: i32, value: i32) i32 {
    const maybe_value: ?i32 = if (flag != 0) value else null;
    return maybe_value orelse -1;
}
