const SmallError = error{ Low, High };

fn classify(value: u8) SmallError!i32 {
    return switch (value) {
        0 => 0,
        1 => error.Low,
        else => error.High,
    };
}

export fn error_switch(value: u8) i32 {
    return classify(value) catch |err| switch (err) {
        error.Low => -1,
        error.High => -2,
    };
}
