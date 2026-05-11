export fn optional_ptr_value(p: ?*const i32) i32 {
    if (p) |ptr| return ptr.*;
    return -1;
}
