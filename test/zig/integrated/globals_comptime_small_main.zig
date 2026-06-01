const scale = blk: {
    break :blk 5;
};

export fn main() c_int {
    return @intFromBool(comptimeConst(-3) != -15);
}

fn comptimeConst(value: i32) i32 {
    return value * scale;
}
