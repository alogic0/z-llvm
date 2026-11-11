//! Fixed large objects and exact scalar loads through table/merged pointers.
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
    var names: std.ArrayList([]const u8) = .empty;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ndeclare i64 @storage_boundaries_clobber(i64)\n@storage_table32 = external global [16 x i32]\n@storage_table64 = external global [16 x i64]\n");
    try d.writeAll("#include <stdint.h>\ntypedef uint64_t (*storage_fn)(uint64_t,uint8_t*,uint8_t*,uint64_t);\nstruct storage_case {storage_fn function;unsigned bits,merged,bytes;};\n");
    for ([_]u16{ 32, 64 }) |bits| {
        const scalar = if (bits == 32) "float" else "double";
        for (0..2) |merged| {
            const name = try c.fmt("storage_boundaries_fp{d}_{d}", .{ bits, merged });
            try names.append(c.a, name);
            try d.print("extern uint64_t {s}(uint64_t,uint8_t*,uint8_t*,uint64_t);\n", .{name});
            try w.print("define i64 @{s}(i64 %raw,ptr %input,ptr %output,i64 %live) {{\nentry:\n %index = and i64 %raw,15\n %table = getelementptr [{d} x i8],ptr @storage_table{d},i64 %index\n", .{ name, bits / 8, bits });
            if (merged != 0) {
                try w.writeAll(" %choice = trunc i64 %live to i1\n br i1 %choice,label %left,label %right\nleft:\n br label %join\nright:\n br label %join\njoin:\n %pointer = phi ptr [ %table,%left ],[ %input,%right ]\n");
            }
            try w.print(" %loaded = load {s},ptr %{s},align 1\n %saved = call i64 @storage_boundaries_clobber(i64 %live)\n", .{ scalar, if (merged != 0) "pointer" else "table" });
            if (bits == 32) try w.writeAll(" %narrow = trunc i64 %raw to i32\n");
            try w.print(" store i{d} %{s},ptr %input,align 1\n %bits = bitcast {s} %loaded to i{d}\n store i{d} %bits,ptr %output,align 1\n", .{ bits, if (bits == 32) "narrow" else "raw", scalar, bits, bits });
            if (bits == 32) try w.writeAll(" %wide = zext i32 %bits to i64\n");
            try w.print(" %answer = xor i64 %{s},%saved\n ret i64 %answer\n}}\n", .{if (bits == 32) "wide" else "bits"});
        }
    }
    for ([_]u32{ 131072, 2300000, 4194304 }) |bytes| {
        const name = try c.fmt("storage_boundaries_object{d}", .{bytes});
        try names.append(c.a, name);
        try d.print("extern uint64_t {s}(uint64_t,uint8_t*,uint8_t*,uint64_t);\n", .{name});
        try w.print(
            \\define i64 @{s}(i64 %raw,ptr %input,ptr %output,i64 %live) {{
            \\entry:
            \\ %slot = alloca [{d} x i8],align 16
            \\ %guard = alloca i64,align 8
            \\ %tail = getelementptr i8,ptr %slot,i64 {d}
            \\ %middle = getelementptr i8,ptr %slot,i64 4096
            \\ %head = trunc i64 %raw to i8
            \\ %last = trunc i64 %live to i8
            \\ %mix = xor i8 %head,%last
            \\ store i64 %raw,ptr %guard,align 8
            \\ store i8 %head,ptr %slot,align 1
            \\ store i8 %last,ptr %tail,align 1
            \\ store i8 %mix,ptr %middle,align 1
            \\ %saved = call i64 @storage_boundaries_clobber(i64 %live)
            \\ %h = load i8,ptr %slot,align 1
            \\ %t = load i8,ptr %tail,align 1
            \\ %m = load i8,ptr %middle,align 1
            \\ %g = load i64,ptr %guard,align 8
            \\ %hw = zext i8 %h to i64
            \\ %tw = zext i8 %t to i64
            \\ %mw = zext i8 %m to i64
            \\ %ts = shl i64 %tw,8
            \\ %ms = shl i64 %mw,16
            \\ %one = or i64 %hw,%ts
            \\ %two = or i64 %one,%ms
            \\ %value = xor i64 %two,%g
            \\ store i64 %value,ptr %output,align 1
            \\ %answer = xor i64 %value,%saved
            \\ ret i64 %answer
            \\}}
            \\
        , .{ name, bytes, bytes - 1 });
    }
    try d.writeAll("static const struct storage_case cases[]={\n");
    for ([_]u16{ 32, 64 }) |bits| for (0..2) |merged| {
        try d.print("{{storage_boundaries_fp{d}_{d},{d},{d},0}},\n", .{ bits, merged, bits, merged });
    };
    for ([_]u32{ 131072, 2300000, 4194304 }) |bytes| try d.print("{{storage_boundaries_object{d},64,0,{d}}},\n", .{ bytes, bytes });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/storage_boundaries_driver.c"));
    try c.write(try c.join(&.{ out, "storage_boundaries.ll" }), llvm.written());
    try c.write(try c.join(&.{ out, "storage_boundaries_driver.c" }), driver.written());
    const pop = try u.toValue(c.a, .{ .population = "storage_boundaries", .prefix = "storage-boundaries", .fixture = "storage_boundaries", .functions = names.items, .observations = 57344, .stdout = "storage-boundaries observations=57344 tables=merged=payloads=objects=pages=guards=live=preserved\n" });
    try c.writeJson(try c.join(&.{ out, "population.json" }), pop);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "storage_boundaries")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, pop, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ out, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
