comptime {
    sideEffectFree();
}

export fn main() c_int {
    sideEffectFree();
    return 0;
}

fn sideEffectFree() void {}
