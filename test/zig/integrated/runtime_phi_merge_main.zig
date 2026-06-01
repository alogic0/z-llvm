comptime {
    if (branchMix(10, 3, true) != 13) @compileError("branch mix true check failed");
    if (branchMix(10, 3, false) != 7) @compileError("branch mix false check failed");
}

export fn main() c_int {
    return 0;
}

fn branchMix(a: i32, b: i32, flag: bool) i32 {
    var result = a;
    if (flag) {
        result += b;
    } else {
        result -= b;
    }
    return result;
}
