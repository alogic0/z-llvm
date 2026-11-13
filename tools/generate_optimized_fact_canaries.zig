//! Generate two optimized-IR fact populations with independent C byte models.
//! Usage: zig run tools/generate_optimized_fact_canaries.zig -- --output-root NEW [--verify-root DIR]
const std = @import("std");
const u = @import("validation/common.zig");
const header = "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\ndeclare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)\n";
const Output = struct {
    ir: std.Io.Writer.Allocating,
    driver: std.Io.Writer.Allocating,
    table: std.Io.Writer.Allocating,
    functions: u.Value,
    count: usize = 0,
    fn init(c: *u.Context, prefix: []const u8, model: []const u8, contract: []const u8) !Output {
        var out: Output = .{ .ir = .init(c.a), .driver = .init(c.a), .table = .init(c.a), .functions = u.array(c.a) };
        try out.ir.writer.writeAll(header);
        try out.driver.writer.print("#define DRIVER_NAME \"{s}\"\n#define DRIVER_SEEDS 64\n#define DRIVER_CONTRACT \"{s}\"\n", .{ prefix, contract });
        try out.driver.writer.writeAll(try c.read("tools/templates/behavior_completion_core.h"));
        try out.driver.writer.writeAll(try c.read(try c.join(&.{ "tools/templates", model })));
        try out.table.writer.writeAll("static const struct test_case cases[]={\n");
        return out;
    }
    fn probe(out: *Output, c: *u.Context, name: []const u8, bits: usize, kind: usize) !void {
        try u.add(&out.functions, u.s(name));
        try out.driver.writer.print("extern uint64_t {s}(void *,void *,const void *,uint64_t);\n", .{name});
        try out.table.writer.print("{{{s},{d},{d},0}},\n", .{ name, bits, kind });
        out.count += 1;
        _ = c;
    }
    fn finish(out: *Output, c: *u.Context, root: []const u8, population: []const u8, prefix: []const u8, contract: []const u8) !u.Value {
        try out.table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
        try out.driver.writer.writeAll(out.table.written());
        try c.write(try c.join(&.{ root, try c.fmt("{s}.ll", .{population}) }), out.ir.written());
        try c.write(try c.join(&.{ root, try c.fmt("{s}_driver.c", .{population}) }), out.driver.written());
        return u.toValue(c.a, .{ .population = population, .fixture = population, .prefix = prefix, .functions = out.functions, .observations = out.count * 64 * 8, .stdout = try c.fmt("{s} observations={d} {s}\n", .{ prefix, out.count * 64 * 8, contract }) });
    }
};
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    var entries = u.array(c.a);
    try u.add(&entries, try vectorRanges(&c, root));
    try u.add(&entries, try annotatedAssembly(&c, root));
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = entries }));
    if (args.get("verify-root")) |before| {
        const old = try u.get(try c.load(try c.join(&.{ before, "native_canaries.json" })), "canaries");
        for (try u.json.array(entries)) |entry| {
            var found = false;
            for (try u.json.array(old)) |candidate| if (u.json.is(try u.get(candidate, "population"), try u.str(entry, "population"))) {
                if (found or !u.json.eql(entry, candidate)) return error.RegistryContractMismatch;
                found = true;
            };
            if (!found) return error.PopulationMissing;
            for ([_][]const u8{ ".ll", "_driver.c" }) |suffix| {
                const file = try c.fmt("{s}{s}", .{ try u.str(entry, "fixture"), suffix });
                if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureMismatch;
            }
        }
    }
    try c.print("optimized facts:two populations/four generated fixtures{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
fn vectorRanges(c: *u.Context, root: []const u8) !u.Value {
    const contract = "independent-defined-lane-bytes=typed-vector-ranges=signed-and-wrapped=nonzero-wide-patterns=cc-and-fastcc=closed-private-vectors=call-clobbers=guard-pages=preserved";
    var out = try Output.init(c, "vector-range-facts", "vector_range_facts_model.c", contract);
    const Shape = struct { bits: usize, lanes: usize };
    // Single-lane i128 has no admitted public vector ABI. Wider i128 shapes
    // use the existing proved, direct-only private fastcc memory view.
    const shapes = [_]Shape{ .{ .bits = 8, .lanes = 2 }, .{ .bits = 8, .lanes = 32 }, .{ .bits = 8, .lanes = 64 }, .{ .bits = 32, .lanes = 3 }, .{ .bits = 32, .lanes = 2 }, .{ .bits = 32, .lanes = 16 }, .{ .bits = 32, .lanes = 64 }, .{ .bits = 64, .lanes = 2 }, .{ .bits = 64, .lanes = 8 }, .{ .bits = 128, .lanes = 16 }, .{ .bits = 128, .lanes = 64 } };
    for (shapes) |shape| for (0..4) |kind| for ([_][]const u8{ "", "fastcc " }) |cc| {
        if (shape.bits * shape.lanes > 1024 and cc.len == 0) continue;
        const body = try c.fmt("vector_range_body_{d}", .{out.count});
        const probe = try c.fmt("vector_range_probe_{d}", .{out.count});
        try u.add(&out.functions, u.s(body));
        try out.probe(c, probe, shape.bits, kind * 128 + shape.lanes);
        const lo = ([_][]const u8{ "4", "-5", "-4", "1" })[kind];
        const hi = ([_][]const u8{ "21", "5", "4", "0" })[kind];
        try out.ir.writer.print("define internal {0s}i64 @{1s}(ptr %out,<{2d} x i{3d}> noundef range(i{3d} {4s}, {5s}) %input,i64 %salt) noinline {{\nentry:\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store <{2d} x i{3d}> %input,ptr %out,align 1\n %p = getelementptr i8,ptr %out,i64 {6d}\n store i64 %token,ptr %p,align 1\n ret i64 %token\n}}\ndefine i64 @{7s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n %input = load <{2d} x i{3d}>,ptr %source,align 1\n %r = call {0s}i64 @{1s}(ptr %out,<{2d} x i{3d}> noundef range(i{3d} {4s}, {5s}) %input,i64 %salt)\n ret i64 %r\n}}\n", .{ cc, body, shape.lanes, shape.bits, lo, hi, shape.lanes * shape.bits / 8, probe });
    };
    if (out.count != 76) return error.RangeCaseInventoryChanged;
    return out.finish(c, root, "vector_range_facts", "vector-range-facts", contract);
}
fn annotatedAssembly(c: *u.Context, root: []const u8) !u.Value {
    const contract = "independent-byte-oracle=elementtype-plus-pointer-facts=attribute-group=empty-assembly=defined-memory-after-outputs=live-load-snapshots=call-clobbers=guard-pages=preserved";
    var out = try Output.init(c, "annotated-assembly", "annotated_assembly_model.c", contract);
    try out.ir.writer.writeAll("attributes #7 = { nounwind }\n");
    for ([_]usize{ 8, 16, 32, 64, 128 }) |bits| for ([_][]const u8{ "=*r|m,r|m", "=*m|r", "=*r|m", "*m" }, 0..) |constraint, form| for (0..3) |attrs_kind| for ([_]usize{ bits / 8, 64 }) |alignment| {
        const probe = try c.fmt("annotated_assembly_probe_{d}", .{out.count});
        try out.probe(c, probe, bits, 0);
        const attrs = switch (attrs_kind) {
            0 => try c.fmt("nonnull elementtype(i{d})", .{bits}),
            1 => try c.fmt("noundef nonnull align {d} elementtype(i{d}) dereferenceable({d})", .{ alignment, bits, bits / 8 }),
            else => try c.fmt("elementtype(i{d}) align {d} nonnull noundef dereferenceable_or_null({d})", .{ bits, alignment, bits / 8 }),
        };
        var mask: u128 = 0;
        for (0..bits / 8) |_| mask = (mask << 8) | 0x5a;
        try out.ir.writer.print("define i64 @{0s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n %slot = alloca i{1d},align {2d}\n %input = load i{1d},ptr %source,align 1\n store i{1d} %input,ptr %slot,align {2d}\n %before = load i{1d},ptr %slot,align {2d}\n call void asm sideeffect \"\", \"{3s},~{{dirflag}},~{{fpsr}},~{{flags}}\"(ptr {4s} %slot{5s}) #7\n %next = xor i{1d} %before,{6d}\n store i{1d} %next,ptr %slot,align {2d}\n %after = load i{1d},ptr %slot,align {2d}\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store i{1d} %before,ptr %out,align 1\n %p = getelementptr i8,ptr %out,i64 {7d}\n store i{1d} %after,ptr %p,align 1\n ret i64 %token\n}}\n", .{ probe, bits, alignment, constraint, attrs, if (form == 0) ",i32 3" else "", mask, bits / 8 });
    };
    if (out.count != 120) return error.AssemblyCaseInventoryChanged;
    return out.finish(c, root, "annotated_assembly", "annotated-assembly", contract);
}
