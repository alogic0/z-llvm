var value: i32 = 42;

export fn main() c_int {
    return if (optionalPtrValue(&value) == 42 and optionalPtrValue(null) == -1) 0 else 1;
}

fn optionalPtrValue(p: ?*const i32) i32 {
    if (p) |ptr| return ptr.*;
    return -1;
}
