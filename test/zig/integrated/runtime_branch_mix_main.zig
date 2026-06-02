comptime {
    if (branchMix(40, 2, true) != 42) @compileError("branch mix add check failed");
    if (branchMix(44, 2, false) != 42) @compileError("branch mix sub check failed");
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
