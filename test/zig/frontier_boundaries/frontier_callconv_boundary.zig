extern fn frontier_win_call(value: i32) callconv(.winapi) i32;

export fn frontier_nondefault_callconv_boundary(value: i32) i32 {
    return frontier_win_call(value);
}
