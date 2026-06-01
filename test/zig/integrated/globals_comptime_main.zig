comptime {
    if (comptimeConst(7) != 35) @compileError("comptime constant check failed");
}

const scale = blk: {
    break :blk 5;
};

export fn main() c_int {
    return 0;
}

fn comptimeConst(value: i32) i32 {
    return value * scale;
}
