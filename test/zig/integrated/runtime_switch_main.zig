comptime {
    if (denseSwitch(0) != 11) @compileError("switch case 0 failed");
    if (denseSwitch(1) != 13) @compileError("switch case 1 failed");
    if (denseSwitch(2) != 17) @compileError("switch case 2 failed");
    if (denseSwitch(4) != 19) @compileError("switch range case failed");
    if (denseSwitch(9) != 23) @compileError("switch default case failed");
}

export fn main() c_int {
    return 0;
}

fn denseSwitch(value: u8) i32 {
    return switch (value) {
        0 => 11,
        1 => 13,
        2 => 17,
        3...5 => 19,
        else => 23,
    };
}
