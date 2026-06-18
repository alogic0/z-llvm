const Inner = extern struct {
    a: i32,
    b: i32,
};

const Outer = extern struct {
    left: Inner,
    right: Inner,
};

export fn frontier_record_sum(a: i32, b: i32) i32 {
    return a + b;
}

export fn frontier_record_update(flag: i32, value: i32) i32 {
    return if (flag != 0) value + 1 else value + 2;
}

export fn frontier_nested_field_left_b(record: *const Outer) i32 {
    return record.left.b;
}

export fn frontier_nested_field_right_a(record: *const Outer) i32 {
    return record.right.a;
}
