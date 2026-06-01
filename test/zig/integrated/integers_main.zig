export fn main() c_int {
    if (addWrap(2147483647, 1) != -2147483648) return 1;
    if (cmpSelect(7, 3) != 3) return 2;
    if (cmpSelect(-4, 2) != -4) return 3;
    if (shiftMix(0x12345678, 4) != expectedShiftMix(0x12345678, 4)) return 4;
    if (shiftMix(@bitCast(@as(i32, -7)), 35) != expectedShiftMix(@bitCast(@as(i32, -7)), 35)) return 5;
    return 0;
}

fn addWrap(a: i32, b: i32) i32 {
    return a +% b;
}

fn shiftMix(a: u32, b: u32) u32 {
    const sh: u5 = @truncate(b);
    return (a << sh) ^ (a >> sh);
}

fn cmpSelect(a: i32, b: i32) i32 {
    return if (a < b) a else b;
}

fn expectedShiftMix(value: u32, amount: u32) u32 {
    const shift: u5 = @truncate(amount);
    return (value << shift) ^ (value >> shift);
}
