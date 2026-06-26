const Big80 = extern struct {
    values: [80]i64,
};

extern fn frontier_big80_boundary_copy(value: Big80) callconv(.c) Big80;

export fn frontier_big80_stack_source_copy_boundary(a: i64, b: i64, c: i64, d: i64, e: i64, f: i64, value: Big80) Big80 {
    _ = a;
    _ = b;
    _ = c;
    _ = d;
    _ = e;
    _ = f;
    return frontier_big80_boundary_copy(value);
}
