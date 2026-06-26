extern fn frontier_tail_target(value: i32) callconv(.c) i32;

export fn frontier_always_tail_boundary(value: i32) i32 {
    return @call(.always_tail, frontier_tail_target, .{value});
}
