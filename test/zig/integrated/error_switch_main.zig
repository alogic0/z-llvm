comptime {
    if (errorSwitch(0) != 0) @compileError("error switch success check failed");
    if (errorSwitch(1) != -1) @compileError("error switch low check failed");
    if (errorSwitch(2) != -2) @compileError("error switch high check failed");
    if (errorSwitch(255) != -2) @compileError("error switch fallback check failed");
}

const SmallError = error{ Low, High };

export fn main() c_int {
    return 0;
}

fn classify(value: u8) SmallError!i32 {
    return switch (value) {
        0 => 0,
        1 => error.Low,
        else => error.High,
    };
}

fn errorSwitch(value: u8) i32 {
    return classify(value) catch |err| switch (err) {
        error.Low => -1,
        error.High => -2,
    };
}
