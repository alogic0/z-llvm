fn inc(value: i32) i32 {
    return value + 1;
}

fn double(value: i32) i32 {
    return value * 2;
}

export fn frontier_helper_chain(left: i32, right: i32) i32 {
    _ = right;
    return inc(left);
}

export fn frontier_helper_branch(flag: i32, value: i32) i32 {
    const selected = if (flag != 0) inc(value) else double(value);
    return selected + 3;
}
