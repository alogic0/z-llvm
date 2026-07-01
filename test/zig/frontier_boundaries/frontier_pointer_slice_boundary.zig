export fn frontier_volatile_derived_pointer_boundary(values: [*]volatile i32, index: usize) i32 {
    const ptr = values + index;
    return ptr[0];
}

export fn frontier_atomic_derived_pointer_boundary(values: [*]const i32, index: usize) i32 {
    const ptr = values + index;
    return @atomicLoad(i32, &ptr[0], .acquire);
}
