export fn scale_slice_sum(ptr: [*]const i32, len: usize) i32 {
    const values = ptr[0..len];
    var index: usize = 0;
    var sum: i32 = 0;
    while (index < values.len) : (index += 1) {
        sum += values[index];
    }
    return sum;
}

export fn scale_slice_threshold_sum(values: [*]const i32, len: usize, limit: i32) i32 {
    var index: usize = 0;
    var sum: i32 = 0;
    while (index < len) : (index += 1) {
        const value = values[index];
        if (value > limit) {
            sum += value;
        }
    }
    return sum;
}

export fn scale_branch_pointer_load(flag: i32, left: *const i32, right: *const i32) i32 {
    const chosen = if (flag != 0) left else right;
    return chosen.*;
}

export fn scale_branch_store(flag: i32, out: *i32, value: i32) i32 {
    if (flag != 0) {
        out.* = value + 5;
    } else {
        out.* = value - 5;
    }
    return out.*;
}
