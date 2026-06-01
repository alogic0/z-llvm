comptime {
    if (loopSum(0) != 0) @compileError("loop zero check failed");
    if (loopSum(5) != 10) @compileError("loop small check failed");
}

export fn main() c_int {
    return 0;
}

fn loopSum(limit: u32) i32 {
    var index: u32 = 0;
    var sum: i32 = 0;
    while (index < limit) : (index += 1) {
        sum += @as(i32, @intCast(index));
    }
    return sum;
}
