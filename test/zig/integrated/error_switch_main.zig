const SmallError = error{ Low, High };

export fn main() c_int {
    if (errorSwitch(0) != 0) return 1;
    if (errorSwitch(1) != -1) return 2;
    if (errorSwitch(2) != -2) return 3;
    if (errorSwitch(255) != -2) return 4;
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
