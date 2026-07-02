const V4f32 = @Vector(4, f32);

const VectorBox = extern struct {
    value: V4f32,
};

export fn frontier_vector_arg_return(value: V4f32) V4f32 {
    return value;
}

export fn frontier_vector_aggregate(value: VectorBox) VectorBox {
    return value;
}

export fn frontier_vector_unsupported_width(value: u8) u8 {
    const lanes: @Vector(16, u8) = @splat(value);
    return lanes[15];
}
