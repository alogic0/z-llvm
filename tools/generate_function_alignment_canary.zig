//! Reproduce explicit function placement with independent hardware address checks.
//! Usage: zig run tools/generate_function_alignment_canary.zig -- --output-root NEW [--verify-root DIR]
const std = @import("std");
const u = @import("validation/common.zig");
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var cases: std.Io.Writer.Allocating = .init(c.a);
    var addresses: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    const contract = "hardware-address-checks=1-to-4096=aliases=global-function-pointers=direct-and-indirect-calls=guard-pages=preserved";
    try driver.writer.print("#define DRIVER_NAME \"function-alignment\"\n#define DRIVER_SEEDS 64\n#define DRIVER_CONTRACT \"{s}\"\n", .{contract});
    try driver.writer.writeAll(try c.read("tools/templates/behavior_completion_core.h"));
    try driver.writer.writeAll(try c.read("tools/templates/function_alignment_model.c"));
    try cases.writer.writeAll("static const struct test_case cases[]={\n");
    try addresses.writer.writeAll("static const struct address_case addresses[]={\n");
    var count: usize = 0;
    for ([_]usize{ 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096 }) |alignment| for ([_][]const u8{ "", "fastcc " }) |cc| {
        const target = try c.fmt("function_alignment_target_{d}", .{count});
        const probe = try c.fmt("function_alignment_probe_{d}", .{count});
        const getter = try c.fmt("function_alignment_get_{d}", .{count});
        for ([_][]const u8{ target, probe, getter }) |name| try u.add(&functions, u.s(name));
        const constant = @as(u64, 0x123456789abcdef0) ^ (@as(u64, @intCast(count)) * 17);
        try text.writer.print("@function_alignment_alias_{0d} = alias i64 (i64),ptr @{1s}\n@function_alignment_dispatch_{0d} = internal global ptr @{1s},align 8\ndefine internal {2s}i64 @{1s}(i64 %value) noinline align {3d} {{\nentry:\n %r = xor i64 %value,{4d}\n ret i64 %r\n}}\ndefine ptr @{5s}() {{\nentry:\n ret ptr @{1s}\n}}\ndefine i64 @{6s}(ptr %out,ptr %unused,ptr %other,i64 %salt) {{\nentry:\n %target = ptrtoint ptr @{1s} to i64\n %dispatch = load ptr,ptr @function_alignment_dispatch_{0d},align 8\n %loaded = ptrtoint ptr %dispatch to i64\n %low = and i64 %target,{7d}\n %same_dispatch = xor i64 %loaded,%target\n store i64 %low,ptr %out,align 1\n %p1 = getelementptr i8,ptr %out,i64 8\n store i64 %same_dispatch,ptr %p1,align 1\n %direct = call {2s}i64 @{1s}(i64 %salt)\n %second = xor i64 %salt,40926266145\n %indirect = call {2s}i64 %dispatch(i64 %second)\n %triple = mul i64 %indirect,3\n %r = add i64 %direct,%triple\n ret i64 %r\n}}\n", .{ count, target, cc, alignment, constant, getter, probe, alignment - 1 });
        try driver.writer.print("extern uint64_t {s}(void *,void *,const void *,uint64_t);\nextern void *{s}(void);\nextern uint64_t function_alignment_alias_{d}(uint64_t);\n", .{ probe, getter, count });
        try cases.writer.print("{{{s},{d},{d},0}},\n", .{ probe, alignment, count });
        try addresses.writer.print("{{{s},function_alignment_alias_{d},{d}}},\n", .{ getter, count, alignment });
        count += 1;
    };
    if (count != 26) return error.AlignmentInventoryChanged;
    try cases.writer.writeAll("};\n");
    try addresses.writer.writeAll("};\n");
    try driver.writer.writeAll(cases.written());
    try driver.writer.writeAll(addresses.written());
    try driver.writer.writeAll("int main(int argc,char **argv){if(!addresses_aligned(addresses,sizeof addresses/sizeof addresses[0]))return 1;return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try c.write(try c.join(&.{ root, "function_alignment.ll" }), text.written());
    try c.write(try c.join(&.{ root, "function_alignment_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "function_alignment", .fixture = "function_alignment", .prefix = "function-alignment", .codegen_args = try u.strings(c.a, &.{"--codegen-reachable"}), .functions = functions, .observations = count * 64 * 8, .stdout = try c.fmt("function-alignment observations={d} {s}\n", .{ count * 64 * 8, contract }) });
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = &.{entry} }));
    if (args.get("verify-root")) |before| {
        for ([_][]const u8{ "function_alignment.ll", "function_alignment_driver.c" }) |file| if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureMismatch;
        const registry = try u.get(try c.load(try c.join(&.{ before, "native_canaries.json" })), "canaries");
        var found = false;
        for (try u.json.array(registry)) |row| if (u.json.is(try u.get(row, "population"), "function_alignment")) {
            if (found or !u.json.eql(row, entry)) return error.RegistryContractMismatch;
            found = true;
        };
        if (!found) return error.RegistryPopulationMissing;
    }
    try c.print("function alignment:26 cases,78 definitions,13312 observations per route{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
