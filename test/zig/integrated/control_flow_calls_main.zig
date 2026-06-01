comptime {
    if (loopSum(0) != 0) @compileError("loop zero check failed");
    if (loopSum(5) != 10) @compileError("loop small check failed");
    if (loopSum(13) != 78) @compileError("loop larger check failed");
    if (callChain(0) != 1) @compileError("call chain zero check failed");
    if (callChain(17) != 35) @compileError("call chain positive check failed");
}

export fn main() c_int {
    return 0;
}

fn callee(value: i32) i32 {
    return value * 2;
}

fn callChain(value: i32) i32 {
    return callee(value) + 1;
}

fn loopSum(limit: u32) i32 {
    var index: u32 = 0;
    var sum: i32 = 0;
    while (index < limit) : (index += 1) {
        sum += @as(i32, @intCast(index));
    }
    return sum;
}
