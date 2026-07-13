fn helper(a: i128, b: i128, out: *i128) callconv(.c) i128 {
    _ = b;
    out.* = a;
    return 0;
}

fn helper64(a: u64, b: u64, out: *u64) callconv(.c) u64 {
    out.* = a % b;
    return a / b;
}

comptime {
    @export(&helper, .{ .name = "compiler_rt.udivmod.udivmod__anon_15304" });
    @export(&helper64, .{ .name = "compiler_rt.int.__udivmoddi4" });
}
