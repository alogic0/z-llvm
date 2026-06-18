export fn frontier_branch_store_reload(flag: i32, out: *i32, left: i32, right: i32) i32 {
    if (flag != 0) {
        out.* = left + 9;
    } else {
        out.* = right - 9;
    }
    return out.*;
}

export fn frontier_branch_local_mix(flag: i32, out: *i32, value: i32) i32 {
    if (flag != 0) {
        out.* = value + 6;
    } else {
        out.* = value - 6;
    }
    return out.*;
}
