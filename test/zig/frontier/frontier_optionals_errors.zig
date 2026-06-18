export fn frontier_optional_merge(flag: i32, value: i32) i32 {
    const maybe_value: ?i32 = if (flag != 0) value else null;
    return maybe_value orelse -17;
}

export fn frontier_error_payload(flag: i32, value: i32) i32 {
    _ = flag;
    return value + 2;
}
