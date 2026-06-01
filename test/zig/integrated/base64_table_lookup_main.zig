const table = [_]u8{ 0, 4, 8, 12 };

export fn main() c_int {
    if (base64TableLookup(0) != 0) return 1;
    if (base64TableLookup(1) != 4) return 2;
    if (base64TableLookup(3) != 12) return 3;
    if (base64TableLookup(7) != 12) return 4;
    return 0;
}

fn base64TableLookup(index: u8) i32 {
    return table[index & 3];
}
