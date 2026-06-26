const PackedPair = packed struct {
    a: u8,
    b: u32,
};

extern fn frontier_packed_sink(value: PackedPair) callconv(.c) u32;

export fn frontier_packed_return_boundary(value: PackedPair) PackedPair {
    return value;
}

export fn frontier_packed_arg_boundary(value: PackedPair) u32 {
    return frontier_packed_sink(value);
}
