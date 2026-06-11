export fn expanded_slice_sum(ptr: [*]const i32, len: usize) i32 {
    const values = ptr[0..len];
    var index: usize = 0;
    var sum: i32 = 0;
    while (index < values.len) : (index += 1) {
        sum += values[index];
    }
    return sum;
}

export fn expanded_load_store(src: *i32, dst: *i32) i32 {
    const value = src.*;
    dst.* = value + 3;
    return dst.*;
}
