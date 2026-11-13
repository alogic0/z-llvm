//! Exact floating literal payloads through data, arguments, returns and bitcasts.
//! Usage: zig run tools/generate_floating_payload_canary.zig -- --output-root NEW [--verify-root DIR]
const std = @import("std");
const u = @import("validation/common.zig");
fn llvmFloat(bits: u32) u64 {
    if (bits & 0x7f800000 == 0x7f800000) return (@as(u64, bits & 0x80000000) << 32) | 0x7ff0000000000000 | (@as(u64, bits & 0x7fffff) << 29);
    return @bitCast(@as(f64, @as(f32, @bitCast(bits))));
}
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    const contract = "integer-bit-goldens=signaling-and-quiet-nans=payloads-and-signs=literal-stores=call-arguments=returns=bitcasts=call-clobbers=guard-pages=preserved";
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\ndeclare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)\n");
    try driver.writer.print("#define DRIVER_NAME \"floating-payload-literals\"\n#define DRIVER_SEEDS 64\n#define DRIVER_CONTRACT \"{s}\"\n", .{contract});
    try driver.writer.writeAll(try c.read("tools/templates/behavior_completion_core.h"));
    try driver.writer.writeAll(try c.read("tools/templates/floating_payload_model.c"));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var count: usize = 0;
    for ([_]u32{ 0, 0x80000000, 0x7f800000, 0xff800000, 0x7f800001, 0xff800001, 0x7fa00000, 0xffa00000, 0x7fbfffff, 0xffbfffff, 0x7fc00000, 0xffc00000, 0x7fffffff, 0xffffffff, 1, 0x80000001, 0x007fffff, 0x807fffff, 0x3f800000, 0xbf800000, 0x7f7fffff, 0xff7fffff }) |bits| for ([_][]const u8{ "", "fastcc " }, 0..) |cc, kind| {
        const returned = try c.fmt("floating_payload_return_{d}", .{count});
        const body = try c.fmt("floating_payload_body_{d}", .{count});
        const probe = try c.fmt("floating_payload_probe_{d}", .{count});
        const literal = try c.fmt("0x{X:0>16}", .{llvmFloat(bits)});
        for ([_][]const u8{ returned, body, probe }) |name| try u.add(&functions, u.s(name));
        try text.writer.print("define internal {0s}float @{1s}() noinline {{\nentry:\n ret float {2s}\n}}\ndefine internal {0s}i64 @{3s}(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {{\nentry:\n %local = alloca float,align 4\n %argument_bits = bitcast float %argument to i32\n store i32 %argument_bits,ptr %out,align 1\n store float {2s},ptr %local,align 4\n %loaded = load float,ptr %local,align 4\n %loaded_bits = bitcast float %loaded to i32\n %p1 = getelementptr i8,ptr %out,i64 4\n store i32 %loaded_bits,ptr %p1,align 1\n %literal_bits = bitcast float {2s} to i32\n %p2 = getelementptr i8,ptr %out,i64 8\n store i32 %literal_bits,ptr %p2,align 1\n %returned = call {0s}float @{1s}()\n %return_bits = bitcast float %returned to i32\n %p3 = getelementptr i8,ptr %out,i64 12\n store i32 %return_bits,ptr %p3,align 1\n %p4 = getelementptr i8,ptr %out,i64 16\n store i32 %dynamic,ptr %p4,align 1\n %p5 = getelementptr i8,ptr %out,i64 20\n store i64 %token,ptr %p5,align 1\n ret i64 %token\n}}\ndefine i64 @{4s}(ptr %out,ptr %input,ptr %unused,i64 %salt) {{\nentry:\n %dynamic = load i32,ptr %input,align 1\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n %r = call {0s}i64 @{3s}(ptr %out,float {2s},i32 %dynamic,i64 %token)\n ret i64 %r\n}}\n", .{ cc, returned, literal, body, probe });
        try driver.writer.print("extern uint64_t {s}(void *,void *,const void *,uint64_t);\n", .{probe});
        try table.writer.print("{{{s},{d},{d},0}},\n", .{ probe, bits, kind });
        count += 1;
    };
    if (count != 44) return error.PayloadCaseInventoryChanged;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ root, "floating_payload_literals.ll" }), text.written());
    try c.write(try c.join(&.{ root, "floating_payload_literals_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "floating_payload_literals", .fixture = "floating_payload_literals", .prefix = "floating-payload-literals", .functions = functions, .observations = count * 64 * 8, .stdout = try c.fmt("floating-payload-literals observations={d} {s}\n", .{ count * 64 * 8, contract }) });
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = &.{entry} }));
    if (args.get("verify-root")) |before| {
        for ([_][]const u8{ "floating_payload_literals.ll", "floating_payload_literals_driver.c" }) |file| if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureMismatch;
        const entries = try u.get(try c.load(try c.join(&.{ before, "native_canaries.json" })), "canaries");
        var found = false;
        for (try u.json.array(entries)) |row| if (u.json.is(try u.get(row, "population"), "floating_payload_literals")) {
            if (found or !u.json.eql(row, entry)) return error.RegistryContractMismatch;
            found = true;
        };
        if (!found) return error.RegistryPopulationMissing;
    }
    try c.print("floating payload literals:44 cases,132 definitions,22528 observations per route{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
