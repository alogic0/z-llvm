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
