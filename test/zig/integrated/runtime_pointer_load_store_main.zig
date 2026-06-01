var input: i32 = 41;
var output: i32 = 0;

export fn main() c_int {
    return if (loadStore(&input, &output) == 42 and output == 42) 0 else 1;
}

fn loadStore(p: *i32, q: *i32) i32 {
    const value = p.*;
    q.* = value + 1;
    return q.*;
}
