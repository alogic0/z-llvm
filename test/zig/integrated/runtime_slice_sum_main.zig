const values = [_]i32{ 1, 2, 3, 4 };

comptime {
    if (sliceSum(&values, values.len) != 10) @compileError("slice sum selected check failed");
    if (sliceSum(&values, 0) != 0) @compileError("slice sum zero check failed");
}

export fn main() c_int {
    return if (sliceSum(&values, values.len) == 10) 0 else 1;
}

fn sliceSum(ptr: [*]const i32, len: usize) i32 {
    const slice = ptr[0..len];
    var index: usize = 0;
    var sum: i32 = 0;
    while (index < slice.len) : (index += 1) {
        sum += slice[index];
    }
    return sum;
}
