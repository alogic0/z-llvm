comptime {
    if (debugLocation(0) != 1) @compileError("debug location zero check failed");
    if (debugLocation(41) != 42) @compileError("debug location positive check failed");
    if (debugLocation(-2) != -1) @compileError("debug location negative check failed");
}

export fn main() c_int {
    return 0;
}

fn debugLocation(value: i32) i32 {
    const local = value + 1;
    return local;
}
