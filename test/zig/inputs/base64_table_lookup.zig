const table = [_]u8{ 0, 4, 8, 12 };

export fn base64_table_lookup(index: u8) i32 {
    return table[index & 3];
}
