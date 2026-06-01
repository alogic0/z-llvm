comptime {
    if (base64TableLookup(0) != 0) @compileError("base64 first entry check failed");
    if (base64TableLookup(1) != 4) @compileError("base64 second entry check failed");
    if (base64TableLookup(3) != 12) @compileError("base64 fourth entry check failed");
    if (base64TableLookup(7) != 12) @compileError("base64 masked entry check failed");
}

const table = [_]u8{ 0, 4, 8, 12 };

export fn main() c_int {
    return 0;
}

fn base64TableLookup(index: u8) i32 {
    return table[index & 3];
}
