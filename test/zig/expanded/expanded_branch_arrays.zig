export fn expanded_optional_branch(flag: i32, value: i32) i32 {
    const maybe_value: ?i32 = if (flag != 0) value else null;
    return maybe_value orelse -5;
}
