fn callee(value: i32) i32 {
    return value * 2;
}

export fn call_chain(value: i32) i32 {
    return callee(value) + 1;
}

export fn loop_sum(limit: u32) i32 {
    var index: u32 = 0;
    var sum: i32 = 0;
    while (index < limit) : (index += 1) {
        sum += @as(i32, @intCast(index));
    }
    return sum;
}
