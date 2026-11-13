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
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root", "population" }, &.{});
    const population = args.get("population");
    const tail = if (population) |name| std.mem.eql(u8, name, "vector_tail_calls") else false;
    const optional_assembly = if (population) |name| std.mem.eql(u8, name, "optional_assembly") else false;
    if (population != null and !tail and !optional_assembly) return error.UnsupportedPopulation;
    const root = try c.newOutput(try args.require("output-root"));
    var entries = u.array(c.a);
    if (optional_assembly) {
        try u.add(&entries, try optionalAssembly(&c, root));
    } else {
        try u.add(&entries, try vectorRanges(&c, root, tail));
        if (!tail) try u.add(&entries, try annotatedAssembly(&c, root));
    }
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
    try c.print("{s}{s}\n", .{ if (optional_assembly) "optional assembly:123 cases/123 definitions/62976 observations per route" else if (tail) "vector tail calls:80 cases/160 definitions/40960 observations per route" else "optimized facts:two populations/four generated fixtures", if (args.get("verify-root") != null) "; byte-exact verification passed" else "" });
}
fn vectorRanges(c: *u.Context, root: []const u8, tail: bool) !u.Value {
    const contract = if (tail) "independent-defined-lane-bytes=optional-tail-and-notail=typed-vector-ranges=cc-and-fastcc=closed-private-vectors=caller-values-after-calls=call-clobbers=guard-pages=preserved" else "independent-defined-lane-bytes=typed-vector-ranges=signed-and-wrapped=nonzero-wide-patterns=cc-and-fastcc=closed-private-vectors=call-clobbers=guard-pages=preserved";
    const prefix = if (tail) "vector-tail-calls" else "vector-range-facts";
    var out = try Output.init(c, prefix, if (tail) "vector_tail_calls_model.c" else "vector_range_facts_model.c", contract);
    const Shape = struct { bits: usize, lanes: usize };
    // Single-lane i128 has no admitted public vector ABI. Wider i128 shapes
    // use the existing proved, direct-only private fastcc memory view.
    const shapes = [_]Shape{ .{ .bits = 8, .lanes = 2 }, .{ .bits = 8, .lanes = 32 }, .{ .bits = 8, .lanes = 64 }, .{ .bits = 32, .lanes = 3 }, .{ .bits = 32, .lanes = 2 }, .{ .bits = 32, .lanes = 16 }, .{ .bits = 32, .lanes = 64 }, .{ .bits = 64, .lanes = 2 }, .{ .bits = 64, .lanes = 8 }, .{ .bits = 128, .lanes = 16 }, .{ .bits = 128, .lanes = 64 } };
    const hints: []const []const u8 = if (tail) &.{ "tail ", "notail " } else &.{""};
    for (shapes, 0..) |shape, shape_index| for (0..4) |kind| for ([_][]const u8{ "", "fastcc " }) |cc| for (hints) |hint| {
        if (tail and switch (shape_index) {
            0, 1, 3, 6, 8, 9 => false,
            else => true,
        }) continue;
        if (shape.bits * shape.lanes > 1024 and cc.len == 0) continue;
        const body = try c.fmt("{s}_body_{d}", .{ if (tail) "vector_tail" else "vector_range", out.count });
        const probe = try c.fmt("{s}_probe_{d}", .{ if (tail) "vector_tail" else "vector_range", out.count });
        try u.add(&out.functions, u.s(body));
        try out.probe(c, probe, shape.bits, kind * 128 + shape.lanes);
        const lo = ([_][]const u8{ "4", "-5", "-4", "1" })[kind];
        const hi = ([_][]const u8{ "21", "5", "4", "0" })[kind];
        try out.ir.writer.print("define internal {0s}i64 @{1s}(ptr %out,<{2d} x i{3d}> noundef range(i{3d} {4s}, {5s}) %input,i64 %salt) noinline {{\nentry:\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store <{2d} x i{3d}> %input,ptr %out,align 1\n %p = getelementptr i8,ptr %out,i64 {6d}\n store i64 %token,ptr %p,align 1\n ret i64 %token\n}}\ndefine i64 @{7s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n %input = load <{2d} x i{3d}>,ptr %source,align 1\n %r = {8s}call {0s}i64 @{1s}(ptr %out,<{2d} x i{3d}> noundef range(i{3d} {4s}, {5s}) %input,i64 %salt)\n{9s}\n}}\n", .{ cc, body, shape.lanes, shape.bits, lo, hi, shape.lanes * shape.bits / 8, probe, hint, if (tail) " %answer = xor i64 %r,%salt\n ret i64 %answer" else " ret i64 %r" });
    };
    if (out.count != @as(usize, if (tail) 80 else 76)) return error.RangeCaseInventoryChanged;
    return out.finish(c, root, if (tail) "vector_tail_calls" else "vector_range_facts", prefix, contract);
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

fn optionalAssembly(c: *u.Context, root: []const u8) !u.Value {
    const contract = "independent-integer-byte-goldens=optional-tail-and-notail=exact-register-assembly=plain-pointer-facts=global-and-caller-memory=live-results-after-calls=guard-pages=preserved";
    var out = try Output.init(c, "optional-assembly", "optional_assembly_model.c", contract);
    try out.ir.writer.writeAll("attributes #7 = { nounwind }\n");
    for ([_]usize{ 8, 16, 32, 64, 128 }) |bits| {
        var value: u128 = 0;
        for (0..bits / 8) |_| value = (value << 8) | 0xa5;
        // Preserve the established signed spelling of full-width i128 data.
        const literal: i128 = if (bits == 128) @bitCast(value) else @intCast(value);
        try out.ir.writer.print("@optional_assembly_global_{d} = internal constant i{d} {d},align 16\n", .{ bits, bits, literal });
    }
    for ([_]usize{ 8, 16, 32, 64, 128 }) |bits| for (0..2) |global| for (0..3) |facts| for ([_][]const u8{ "", "tail ", "notail " }) |hint| {
        const probe = try c.fmt("optional_assembly_probe_{d}", .{out.count});
        try out.probe(c, probe, bits, global);
        const pointer = if (global != 0) try c.fmt("@optional_assembly_global_{d}", .{bits}) else "%source";
        const attrs = switch (facts) {
            0 => "nonnull",
            1 => "noundef nonnull",
            else => try c.fmt("nonnull align {d} dereferenceable({d})", .{ bits / 8, bits / 8 }),
        };
        var mask: u128 = 0;
        for (0..bits / 8) |_| mask = (mask << 8) | 0x5a;
        try out.ir.writer.print("define i64 @{0s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n %before = load i{1d},ptr {2s},align 1\n {3s}call void asm sideeffect \"\",\"m,~{{dirflag}},~{{fpsr}},~{{flags}}\"(ptr {4s} {2s}) #7\n %next = xor i{1d} %before,{5d}\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store i{1d} %before,ptr %out,align 1\n %p = getelementptr i8,ptr %out,i64 {6d}\n store i{1d} %next,ptr %p,align 1\n ret i64 %token\n}}\n", .{ probe, bits, pointer, hint, attrs, mask, bits / 8 });
    };
    for ([_]usize{ 32, 64 }) |bits| for (0..5) |literal_kind| for ([_][]const u8{ "", "tail ", "notail " }) |hint| {
        const probe = try c.fmt("optional_assembly_probe_{d}", .{out.count});
        try out.probe(c, probe, bits, literal_kind + 2);
        const value: i128 = switch (literal_kind) {
            0 => -123,
            1 => 0,
            2 => 123,
            3 => -(@as(i128, 1) << @intCast(bits - 1)),
            else => (@as(i128, 1) << @intCast(bits)) - 1,
        };
        try out.ir.writer.print("define i64 @{0s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n %v = {1s}call i{2d} asm sideeffect \"mov $${3d}, ${{0}}\",\"=r,~{{dirflag}},~{{fpsr}},~{{flags}}\"() #7\n", .{ probe, hint, bits, value });
        if (bits == 32) try out.ir.writer.writeAll(" %wide = zext i32 %v to i64\n") else try out.ir.writer.writeAll(" %wide = or i64 %v,0\n");
        try out.ir.writer.writeAll(" %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store i64 %wide,ptr %out,align 1\n %p = getelementptr i8,ptr %out,i64 8\n store i64 %token,ptr %p,align 1\n %answer = xor i64 %wide,%token\n ret i64 %answer\n}\n");
    };
    for ([_][]const u8{ "", "tail ", "notail " }) |hint| {
        const probe = try c.fmt("optional_assembly_probe_{d}", .{out.count});
        try out.probe(c, probe, 32, 7);
        try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n %input = load i32,ptr %source,align 1\n %v = {s}call i32 asm \"addl ${{1}}, ${{0}}\",\"=r,r,0,~{{flags}},~{{dirflag}},~{{fpsr}},~{{flags}}\"(i32 13,i32 %input) #7\n %wide = zext i32 %v to i64\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store i64 %wide,ptr %out,align 1\n %p = getelementptr i8,ptr %out,i64 8\n store i64 %token,ptr %p,align 1\n %answer = xor i64 %wide,%token\n ret i64 %answer\n}}\n", .{ probe, hint });
    }
    if (out.count != 123) return error.OptionalAssemblyInventoryChanged;
    return out.finish(c, root, "optional_assembly", "optional-assembly", contract);
}
