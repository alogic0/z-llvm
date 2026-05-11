const Pair = extern struct {
    a: i32,
    b: i32,
};

const SmallError = error{Bad};

export fn array_sum(a: i32, b: i32, c: i32) i32 {
    const values = [3]i32{ a, b, c };
    return values[0] + values[1] + values[2];
}

export fn struct_sum(pair: *const Pair) i32 {
    return pair.a + pair.b;
}

export fn slice_sum(ptr: [*]const i32, len: usize) i32 {
    const values = ptr[0..len];
    var index: usize = 0;
    var sum: i32 = 0;
    while (index < values.len) : (index += 1) {
        sum += values[index];
    }
    return sum;
}

export fn optional_payload(flag: i32, value: i32) i32 {
    const maybe_value: ?i32 = if (flag != 0) value else null;
    return maybe_value orelse -1;
}

fn maybeError(flag: i32) SmallError!i32 {
    if (flag != 0) return error.Bad;
    return 7;
}

export fn error_union_payload(flag: i32) i32 {
    return maybeError(flag) catch -1;
}
