export fn frontier_optional_merge(flag: i32, value: i32) i32 {
    const maybe_value: ?i32 = if (flag != 0) value else null;
    return maybe_value orelse -17;
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
