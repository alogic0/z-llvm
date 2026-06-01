export fn main() c_int {
    if (loopSum(0) != 0) return 1;
    if (loopSum(5) != 10) return 2;
    if (loopSum(13) != 78) return 3;
    if (callChain(0) != 1) return 4;
    if (callChain(17) != 35) return 5;
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
