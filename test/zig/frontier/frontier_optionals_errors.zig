export fn frontier_optional_merge(flag: i32, value: i32) i32 {
    const maybe_value: ?i32 = if (flag != 0) value else null;
    return maybe_value orelse -17;
}

export fn frontier_optional_ptr_non_null(ptr: ?*const i32) i32 {
    if (ptr != null) {
        return ptr.?.*;
    }
    return -49;
}

export fn frontier_optional_payload_branch(flag: i32, value: i32, delta: i32) i32 {
    const maybe_value: ?i32 = if (flag != 0) value else null;
    if (maybe_value) |payload| {
        if (payload > 20) return payload + delta;
        return payload - delta;
    }
    return -63;
}

export fn frontier_error_payload(flag: i32, value: i32) i32 {
    _ = flag;
    return value + 2;
}

const FrontierError = error{
    BadTag,
    WorseTag,
};

export fn frontier_error_union_match(tag: i32) i32 {
    const result: FrontierError!i32 = if (tag == 0) 11 else FrontierError.BadTag;
    if (result) |value| {
        return value + 3;
    } else |_| {
        return -22;
    }
}

fn frontierMaybeTryPayload(tag: i32, value: i32) FrontierError!i32 {
    if (tag == 0) return value;
    return FrontierError.WorseTag;
}

fn frontierTryAdd(tag: i32, value: i32) FrontierError!i32 {
    const payload = try frontierMaybeTryPayload(tag, value);
    return payload + 7;
}

export fn frontier_try_match(tag: i32, value: i32) i32 {
    if (frontierTryAdd(tag, value)) |payload| {
        return payload;
    } else |_| {
        return -31;
    }
}

fn frontierNestedTryAdd(first_tag: i32, second_tag: i32, value: i32) FrontierError!i32 {
    const first = try frontierMaybeTryPayload(first_tag, value);
    const second = try frontierMaybeTryPayload(second_tag, first + 5);
    return second + 9;
}

export fn frontier_nested_try_match(first_tag: i32, second_tag: i32, value: i32) i32 {
    if (frontierNestedTryAdd(first_tag, second_tag, value)) |payload| {
        return payload;
    } else |_| {
        return -37;
    }
}

fn frontierTryBranch(tag: i32, value: i32, delta: i32) FrontierError!i32 {
    const payload = try frontierMaybeTryPayload(tag, value);
    if (payload > 20) return payload + delta;
    return payload - delta;
}

export fn frontier_try_branch_match(tag: i32, value: i32, delta: i32) i32 {
    if (frontierTryBranch(tag, value, delta)) |payload| {
        return payload;
    } else |_| {
        return -41;
    }
}

fn frontierTrySlotUpdate(tag: i32, value: i32, delta: i32) FrontierError!i32 {
    var total: i32 = value - delta;
    const payload = try frontierMaybeTryPayload(tag, value);
    total = payload + delta;
    return total;
}

export fn frontier_try_slot_update_match(tag: i32, value: i32, delta: i32) i32 {
    if (frontierTrySlotUpdate(tag, value, delta)) |payload| {
        return payload;
    } else |_| {
        return -69;
    }
}

fn frontierBranchThenTry(flag: i32, tag: i32, value: i32) FrontierError!i32 {
    if (flag != 0) {
        const payload = try frontierMaybeTryPayload(tag, value);
        return payload + 4;
    }
    return value - 4;
}

export fn frontier_branch_then_try_match(flag: i32, tag: i32, value: i32) i32 {
    if (frontierBranchThenTry(flag, tag, value)) |payload| {
        return payload;
    } else |_| {
        return -42;
    }
}

fn frontierSwitchThenTry(selector: i32, tag: i32, value: i32) FrontierError!i32 {
    return switch (selector & 1) {
        0 => value - 5,
        else => blk: {
            const payload = try frontierMaybeTryPayload(tag, value);
            break :blk payload + 5;
        },
    };
}

export fn frontier_switch_then_try_match(selector: i32, tag: i32, value: i32) i32 {
    if (frontierSwitchThenTry(selector, tag, value)) |payload| {
        return payload;
    } else |_| {
        return -73;
    }
}

fn frontierBranchBothTry(flag: i32, first_tag: i32, second_tag: i32, value: i32) FrontierError!i32 {
    if (flag != 0) {
        const payload = try frontierMaybeTryPayload(first_tag, value);
        return payload + 4;
    }
    const payload = try frontierMaybeTryPayload(second_tag, value);
    return payload + 6;
}

export fn frontier_branch_both_try_match(flag: i32, first_tag: i32, second_tag: i32, value: i32) i32 {
    if (frontierBranchBothTry(flag, first_tag, second_tag, value)) |payload| {
        return payload;
    } else |_| {
        return -75;
    }
}

fn frontierSwitchBothTry(selector: i32, first_tag: i32, second_tag: i32, value: i32) FrontierError!i32 {
    return switch (selector & 1) {
        0 => blk: {
            const payload = try frontierMaybeTryPayload(first_tag, value);
            break :blk payload + 4;
        },
        else => blk: {
            const payload = try frontierMaybeTryPayload(second_tag, value);
            break :blk payload + 6;
        },
    };
}

export fn frontier_switch_both_try_match(selector: i32, first_tag: i32, second_tag: i32, value: i32) i32 {
    if (frontierSwitchBothTry(selector, first_tag, second_tag, value)) |payload| {
        return payload;
    } else |_| {
        return -77;
    }
}

export fn frontier_loop_try_match(limit: i32, fail_at: i32) i32 {
    var total: i32 = 0;
    var index: i32 = 0;
    while (index < limit) : (index += 1) {
        const tag: i32 = if (index == fail_at) 1 else 0;
        const payload = frontierMaybeTryPayload(tag, index) catch return -79;
        total += payload;
    }
    return total;
}

export fn frontier_loop_try_post_branch(limit: i32, fail_at: i32, threshold: i32) i32 {
    var total: i32 = 0;
    var index: i32 = 0;
    while (index < limit) : (index += 1) {
        const tag: i32 = if (index == fail_at) 1 else 0;
        const payload = frontierMaybeTryPayload(tag, index) catch return -81;
        total += payload;
    }
    if (total > threshold) return total + 1;
    return total - 1;
}

export fn frontier_loop_try_post_switch(limit: i32, fail_at: i32) i32 {
    var total: i32 = 0;
    var index: i32 = 0;
    while (index < limit) : (index += 1) {
        const tag: i32 = if (index == fail_at) 1 else 0;
        const payload = frontierMaybeTryPayload(tag, index) catch return -83;
        total += payload;
    }
    return switch (total & 3) {
        0 => total + 3,
        1 => total + 5,
        else => total + 7,
    };
}

fn frontierTrySwitch(tag: i32, value: i32) FrontierError!i32 {
    const payload = try frontierMaybeTryPayload(tag, value);
    return switch (payload & 3) {
        0 => payload + 1,
        1 => payload + 2,
        else => payload + 3,
    };
}

export fn frontier_try_switch_match(tag: i32, value: i32) i32 {
    if (frontierTrySwitch(tag, value)) |payload| {
        return payload;
    } else |_| {
        return -43;
    }
}

fn frontierTryColdAdd(tag: i32, value: i32) FrontierError!i32 {
    @branchHint(.cold);
    const payload = try frontierMaybeTryPayload(tag, value);
    return payload + 11;
}

export fn frontier_try_cold_match(tag: i32, value: i32) i32 {
    if (frontierTryColdAdd(tag, value)) |payload| {
        return payload;
    } else |_| {
        return -51;
    }
}

fn frontierTryPtrAdd(tag: i32, value: i32) FrontierError!i32 {
    var result = frontierMaybeTryPayload(tag, value);
    const payload_ptr = &(try result);
    return payload_ptr.* + 13;
}

export fn frontier_try_ptr_match(tag: i32, value: i32) i32 {
    if (frontierTryPtrAdd(tag, value)) |payload| {
        return payload;
    } else |_| {
        return -53;
    }
}

fn frontierTryPtrColdAdd(tag: i32, value: i32) FrontierError!i32 {
    @branchHint(.cold);
    var result = frontierMaybeTryPayload(tag, value);
    const payload_ptr = &(try result);
    return payload_ptr.* + 15;
}

export fn frontier_try_ptr_cold_match(tag: i32, value: i32) i32 {
    if (frontierTryPtrColdAdd(tag, value)) |payload| {
        return payload;
    } else |_| {
        return -55;
    }
}

fn frontierTryPtrBranch(tag: i32, value: i32, delta: i32) FrontierError!i32 {
    var result = frontierMaybeTryPayload(tag, value);
    const payload_ptr = &(try result);
    if (payload_ptr.* > 20) return payload_ptr.* + delta;
    return payload_ptr.* - delta;
}

export fn frontier_try_ptr_branch_match(tag: i32, value: i32, delta: i32) i32 {
    if (frontierTryPtrBranch(tag, value, delta)) |payload| {
        return payload;
    } else |_| {
        return -57;
    }
}

fn frontierNestedTryPtrAdd(first_tag: i32, second_tag: i32, value: i32) FrontierError!i32 {
    var first_result = frontierMaybeTryPayload(first_tag, value);
    const first_ptr = &(try first_result);
    var second_result = frontierMaybeTryPayload(second_tag, first_ptr.* + 5);
    const second_ptr = &(try second_result);
    return second_ptr.* + 9;
}

export fn frontier_nested_try_ptr_match(first_tag: i32, second_tag: i32, value: i32) i32 {
    if (frontierNestedTryPtrAdd(first_tag, second_tag, value)) |payload| {
        return payload;
    } else |_| {
        return -59;
    }
}

fn frontierTryPtrSwitch(tag: i32, value: i32) FrontierError!i32 {
    var result = frontierMaybeTryPayload(tag, value);
    const payload_ptr = &(try result);
    return switch (payload_ptr.* & 3) {
        0 => payload_ptr.* + 1,
        1 => payload_ptr.* + 2,
        else => payload_ptr.* + 3,
    };
}

export fn frontier_try_ptr_switch_match(tag: i32, value: i32) i32 {
    if (frontierTryPtrSwitch(tag, value)) |payload| {
        return payload;
    } else |_| {
        return -61;
    }
}

export fn frontier_errunion_payload_ptr_branch(tag: i32, value: i32, delta: i32) i32 {
    var result = frontierMaybeTryPayload(tag, value);
    if (result) |*payload| {
        if (payload.* > 20) return payload.* + delta;
        return payload.* - delta;
    } else |_| {
        return -65;
    }
}

export fn frontier_errunion_payload_ptr_error_switch(tag: i32, value: i32) i32 {
    var result = frontierMaybeErrorTag(tag, value);
    if (result) |*payload| {
        return payload.* + 2;
    } else |err| {
        return switch (err) {
            FrontierError.BadTag => -67,
            FrontierError.WorseTag => -68,
        };
    }
}

fn frontierTryCatchMap(tag: i32, value: i32) FrontierError!i32 {
    const payload = frontierMaybeErrorTag(tag, value) catch |err| {
        return switch (err) {
            FrontierError.BadTag => FrontierError.WorseTag,
            FrontierError.WorseTag => FrontierError.BadTag,
        };
    };
    return payload + 6;
}

export fn frontier_try_catch_map_match(tag: i32, value: i32) i32 {
    if (frontierTryCatchMap(tag, value)) |payload| {
        return payload;
    } else |err| {
        return switch (err) {
            FrontierError.BadTag => -71,
            FrontierError.WorseTag => -72,
        };
    }
}

fn frontierMaybeErrorTag(tag: i32, value: i32) FrontierError!i32 {
    return switch (tag) {
        0 => value,
        1 => FrontierError.BadTag,
        else => FrontierError.WorseTag,
    };
}

export fn frontier_maybe_error_tag_match(tag: i32, value: i32) i32 {
    if (frontierMaybeErrorTag(tag, value)) |payload| {
        return payload;
    } else |_| {
        return -46;
    }
}

export fn frontier_error_tag_switch(tag: i32, value: i32) i32 {
    if (frontierMaybeErrorTag(tag, value)) |payload| {
        return payload + 1;
    } else |err| {
        return switch (err) {
            FrontierError.BadTag => -47,
            FrontierError.WorseTag => -48,
        };
    }
}
