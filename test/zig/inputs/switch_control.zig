export fn dense_switch(value: u8) i32 {
    return switch (value) {
        0 => 11,
        1 => 13,
        2 => 17,
        3...5 => 19,
        else => 23,
    };
}

export fn branch_mix(a: i32, b: i32, flag: bool) i32 {
    var result = a;
    if (flag) {
        result += b;
    } else {
        result -= b;
    }
    return result;
}
