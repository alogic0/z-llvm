export fn expanded_error_optional(flag: i32, value: i32) i32 {
    const maybe_value: ?i32 = if (flag != 0) value else null;
    return maybe_value orelse -9;
}

export fn expanded_optional_pointer(ptr: ?*const i32) i32 {
    const value_ptr = ptr orelse return -1;
    return value_ptr.* + 8;
}
