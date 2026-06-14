const Pair = extern struct {
    a: i32,
    b: i32,
};

fn addThree(value: i32) i32 {
    return value + 3;
}

export fn expanded_branch_pointer_load(flag: i32, left: *const i32, right: *const i32) i32 {
    const result = if (flag != 0) left.* else right.*;
    return result;
}

export fn expanded_branch_store(flag: i32, out: *i32, left: i32, right: i32) i32 {
    if (flag != 0) {
        out.* = left;
    } else {
        out.* = right;
    }
    return out.*;
}

fn expanded_slice_conditional_sum(values: [*]const i32, len: usize, limit: i32) i32 {
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

fn expanded_struct_branch_update(flag: i32, pair: *Pair) i32 {
    if (flag != 0) {
        pair.a += 5;
    } else {
        pair.a += 7;
    }
    return pair.a;
}

fn expanded_optional_pointer_branch(flag: i32, maybe_ptr: ?*const i32) i32 {
    const result = if (flag != 0) maybe_ptr.?.* else -12;
    return result + 1;
}

export fn expanded_branch_call(flag: i32, value: i32) i32 {
    const result = if (flag != 0) addThree(value) else value - 3;
    return result;
}
