var slot: i32 = 0;

export fn main() c_int {
    return if (volatileRoundtrip(&slot, 42) == 42) 0 else 1;
}

fn volatileRoundtrip(p: *volatile i32, value: i32) i32 {
    p.* = value;
    return p.*;
}
