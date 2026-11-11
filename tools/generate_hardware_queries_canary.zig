//! Exact host CPU queries with independent hardware and ABI checks.
const std = @import("std");
const u = @import("validation/common.zig");
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const out = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    const names = [_][]const u8{ "hardware_queries_named", "hardware_queries_leaf0", "hardware_queries_leaf7", "hardware_queries_xcr0", "hardware_queries_delayed" };
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try d.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef u128 (*query_fn)(uint32_t,uint32_t,uint8_t*,u128);\nstruct query_case { query_fn function; unsigned kind; };\n");
    for (names, 0..) |name, index| {
        try d.print("extern u128 {s}(uint32_t,uint32_t,uint8_t*,u128);\n", .{name});
        try w.print("define i128 @{s}(i32 %leaf,i32 %subleaf,ptr %out,i128 %live) {{\nentry:\n", .{name});
        const leaf = if (index == 0 or index == 4) "%leaf" else if (index == 2) "7" else if (index == 3) "1" else "0";
        const subleaf = if (index == 0 or index == 4) "%subleaf" else "0";
        try w.print(" %r = call {{ i32, i32, i32, i32 }} asm sideeffect \"cpuid\", \"={{eax}},={{ebx}},={{ecx}},={{edx}},{{eax}},{{ecx}},~{{dirflag}},~{{fpsr}},~{{flags}}\"(i32 {s},i32 {s})\n", .{ leaf, subleaf });
        if (index == 3) {
            try w.writeAll(" %features = extractvalue { i32, i32, i32, i32 } %r,2\n %osxsave = and i32 %features,134217728\n %enabled = icmp ne i32 %osxsave,0\n br i1 %enabled,label %query,label %exit\nquery:\n %xcr = call i32 asm sideeffect \" xor %ecx, %ecx\\0A xgetbv\", \"={eax},~{ecx},~{edx},~{dirflag},~{fpsr},~{flags}\"()\n %wide = zext i32 %xcr to i128\n br label %exit\nexit:\n %packed = phi i128 [ 0,%entry ],[ %wide,%query ]\n");
        } else {
            for ([_][]const u8{ "a", "b", "c", "d" }, 0..) |field, i| {
                try w.print(" %{s} = extractvalue {{ i32, i32, i32, i32 }} %r,{d}\n %{s}w = zext i32 %{s} to i128\n", .{ field, i, field, field });
                if (i != 0) try w.print(" %{s}s = shl i128 %{s}w,{d}\n", .{ field, field, i * 32 });
            }
            try w.writeAll(" %lo = or i128 %aw,%bs\n %hi = or i128 %cs,%ds\n %packed = or i128 %lo,%hi\n");
        }
        if (index == 4) try w.writeAll(" %unused = call { i32, i32, i32, i32 } asm sideeffect \"cpuid\", \"={eax},={ebx},={ecx},={edx},{eax},{ecx},~{dirflag},~{fpsr},~{flags}\"(i32 0,i32 0)\n %zero = icmp eq i32 %a,0\n %flag = zext i1 %zero to i128\n %marker = shl i128 %flag,127\n %payload = xor i128 %packed,%marker\n");
        const payload = if (index == 4) "%payload" else "%packed";
        try w.print(" store i128 {s},ptr %out,align 1\n %answer = xor i128 {s},%live\n ret i128 %answer\n}}\n", .{ payload, payload });
    }
    try d.writeAll("static const struct query_case cases[]={\n");
    for (names, 0..) |name, i| try d.print("{{{s},{d}}},\n", .{ name, i });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/hardware_queries_driver.c"));
    try c.write(try c.join(&.{ out, "hardware_queries.ll" }), llvm.written());
    try c.write(try c.join(&.{ out, "hardware_queries_driver.c" }), driver.written());
    const pop = try u.toValue(c.a, .{ .population = "hardware_queries", .prefix = "hardware-queries", .fixture = "hardware_queries", .functions = names, .observations = 40960, .stdout = "hardware-queries observations=40960 cpuid=xcr0=live=rbx=stack=guards=preserved\n" });
    try c.writeJson(try c.join(&.{ out, "population.json" }), pop);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "hardware_queries")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, pop, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ out, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
