const Error = error{Bad};

fn maybeError(flag: i32, value: i32) ?Error!i32 {
    if (flag == 0) return null;
    if (flag < 0) return Error.Bad;
    return value + 3;
}

export fn frontier_optional_error_mix_boundary(flag: i32, value: i32) i32 {
    const maybe_result = maybeError(flag, value);
    const result = maybe_result orelse return -2;
    return result catch -1;
}
