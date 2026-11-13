//! Every LLVM binary128 class mask, with independent integer payload goldens.
const std = @import("std");
const u = @import("validation/common.zig");
const Output = @import("generate_optimized_fact_canaries.zig").Output;
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    const contract = "independent-c-integer-classification=all-1024-class-masks=ten-ieee-classes=both-signs=zeros-subnormals-normals-infinities-and-nans=signaling-and-quiet-payloads=optional-call-hints=literal-and-dynamic-inputs=call-clobbers=exact-payloads=guard-pages=preserved";
    var out = try Output.init(&c, "quad-classification", "quad_classification_model.c", contract);
    try out.ir.writer.writeAll("declare i1 @llvm.is.fpclass.f128(fp128,i32)\n");
    const literals = [_][]const u8{ "0xL00000000000000000000000000000000", "0xL00000000000000008000000000000000", "0xL00000000000000017FFF800000000000", "0xL00000000000000017FFF000000000000" };
    for (0..1040) |index| {
        const literal = if (index < 1024) null else (index - 1024) % 4;
        const mask = if (index < 1024) index else ([_]usize{ 32, 64, 3, 1023 })[(index - 1024) / 4];
        const name = try c.fmt("quad_classification_probe_{d}", .{index});
        const hint = ([_][]const u8{ "", "tail ", "notail " })[index % 3];
        const facts = if (index % 2 != 0) "noundef " else "";
        try out.probe(&c, name, 128, mask + if (literal) |which| (which + 1) * 1024 else @as(usize, 0));
        try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n %value = load fp128,ptr %source,align 1\n %r = {s}call {s}i1 @llvm.is.fpclass.f128(fp128 {s}{s},i32 {d})\n %flag = zext i1 %r to i64\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store i64 %flag,ptr %out,align 1\n %token_out = getelementptr i8,ptr %out,i64 8\n store i64 %token,ptr %token_out,align 1\n %payload_out = getelementptr i8,ptr %out,i64 16\n store fp128 %value,ptr %payload_out,align 1\n %answer = xor i64 %flag,%token\n ret i64 %answer\n}}\n", .{ name, hint, facts, facts, if (literal) |which| literals[which] else "%value", mask });
    }
    if (out.count != 1040) return error.QuadClassificationInventoryChanged;
    const entry = try out.finish(&c, root, "quad_classification", "quad-classification", contract);
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = &.{entry} }));
    if (args.get("verify-root")) |before| {
        if (!u.json.eql(try c.load(try c.join(&.{ before, "native_canaries.json" })), try c.load(try c.join(&.{ root, "native_canaries.json" })))) return error.RegistryContractMismatch;
        for ([_][]const u8{ "quad_classification.ll", "quad_classification_driver.c" }) |file| if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureMismatch;
    }
    try c.print("quad classification:1040 cases/532480 observations per route{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
