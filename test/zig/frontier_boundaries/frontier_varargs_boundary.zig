extern fn frontier_varargs_sum(count: c_int, ...) callconv(.c) c_int;

const VarargsFn = *const fn (c_int, ...) callconv(.c) c_int;

export fn frontier_direct_varargs_boundary(value: c_int) c_int {
    return frontier_varargs_sum(1, value);
}

export fn frontier_indirect_varargs_boundary(func: VarargsFn, value: c_int) c_int {
    return func(1, value);
}
