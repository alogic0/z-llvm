//! Native private SSA identities beyond the unchanged typed-action limit.
const std = @import("std");
const u = @import("validation/common.zig");
const Output = @import("generate_optimized_fact_canaries.zig").Output;
fn localName(c: *u.Context, length: usize, spelling: usize, index: usize) ![]const u8 {
    const body = try c.a.alloc(u8, length);
    @memset(body, 'x');
    const prefix = try c.fmt("value_{d}_", .{index});
    @memcpy(body[0..prefix.len], prefix);
    return switch (spelling) {
        0 => body,
        1 => try c.fmt("\"{s}\"", .{body}),
        else => try c.fmt("\"\\76{s}\"", .{body[1..]}),
    };
}
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    const contract = "independent-c-memory-oracle=private-local-identities=513-652-1024-byte-names=plain-and-quoted-and-escaped-spellings=unchanged-512-byte-action-limit=collision-safe-retry=phi-and-switch-and-select=call-arguments-and-gep-indices=live-values-after-clobbers=source-and-neighbor-bytes=guard-pages=preserved";
    var out = try Output.init(&c, "bounded-local-identities", "bounded_local_identities_model.c", contract);
    try out.ir.writer.writeAll("declare i64 @identity_echo(ptr,i64)\n");
    for ([_]usize{ 513, 652, 1024 }) |length| for (0..3) |spelling| for (0..3) |flow| {
        const probe = try c.fmt("bounded_local_identity_probe_{d}", .{out.count});
        try out.probe(&c, probe, length, flow);
        var names: [12][]const u8 = undefined;
        for (&names, 0..) |*name, i| name.* = try localName(&c, length, spelling, i);
        const w = &out.ir.writer;
        try w.print("define i64 @{s}(ptr %out,ptr %input,ptr %unused,i64 %__zllvm_short_local_0) {{\nentry:\n %salt = or i64 %__zllvm_short_local_0,0\n", .{probe});
        try w.print(" %{0s} = and i64 %salt,7\n %{1s} = getelementptr i8,ptr %input,i64 %{0s}\n %{2s} = load i64,ptr %{1s},align 1\n %{3s} = add i64 %salt,7\n", .{ names[0], names[1], names[2], names[3] });
        switch (flow) {
            0 => try w.print(" %{0s} = icmp ult i64 %{1s},%{2s}\n br i1 %{0s},label %yes,label %no\nyes:\n %{3s} = add i64 %{1s},%{2s}\n br label %join\nno:\n %{4s} = xor i64 %{1s},%{2s}\n br label %join\njoin:\n %{5s} = phi i64 [%{3s},%yes],[%{4s},%no]\n", .{ names[4], names[2], names[3], names[5], names[6], names[8] }),
            1 => try w.print(" %{0s} = icmp ult i64 %{1s},%{2s}\n %{3s} = select i1 %{0s},i64 %{1s},i64 %{2s}\n %{4s} = call i64 @identity_echo(ptr %{5s},i64 %{3s})\n", .{ names[4], names[2], names[3], names[5], names[8], names[1] }),
            2 => try w.print(" %{0s} = and i64 %{1s},3\n switch i64 %{0s},label %other [ i64 0,label %zero\n i64 1,label %one ]\nzero:\n %{2s} = add i64 %{1s},%{3s}\n br label %join\none:\n %{4s} = xor i64 %{1s},%{3s}\n br label %join\nother:\n %{5s} = sub i64 %{1s},%{3s}\n br label %join\njoin:\n %{6s} = phi i64 [%{2s},%zero],[%{4s},%one],[%{5s},%other]\n", .{ names[4], names[2], names[5], names[3], names[6], names[7], names[8] }),
            else => unreachable,
        }
        try w.print(" %seed = xor i64 %salt,%{0s}\n %token = call i64 @complete_clobber(i64 %seed,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store i64 %{0s},ptr %out,align 1\n %{1s} = getelementptr i8,ptr %out,i64 8\n store i64 %token,ptr %{1s},align 1\n %vp = getelementptr i8,ptr %out,i64 16\n store i64 %{2s},ptr %vp,align 1\n %{3s} = add i64 %{0s},%token\n %{4s} = add i64 %{3s},%{2s}\n ret i64 %{4s}\n}}\n", .{ names[8], names[9], names[2], names[10], names[11] });
    };
    if (out.count != 27) return error.LocalIdentityCaseCountChanged;
    const entry = try out.finish(&c, root, "bounded_local_identities", "bounded-local-identities", contract);
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = &.{entry} }));
    if (args.get("verify-root")) |before| {
        if (!u.json.eql(try c.load(try c.join(&.{ before, "native_canaries.json" })), try c.load(try c.join(&.{ root, "native_canaries.json" })))) return error.RegistryChanged;
        for ([_][]const u8{ "bounded_local_identities.ll", "bounded_local_identities_driver.c" }) |file| if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureChanged;
    }
    try c.print("bounded local identities:27 cases/13824 observations per route{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
