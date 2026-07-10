fn helper(a: i128, b: i128, out: *i128) callconv(.c) i128 {
    _ = b;
    out.* = a;
    return 0;
}

comptime {
    @export(&helper, .{ .name = "compiler_rt.udivmod.udivmod__anon_15304" });
}
