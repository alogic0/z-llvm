//! Generate native proofs for typed frame addresses, copies, GEPs and PHIs.
const std = @import("std");
const u = @import("validation/common.zig");

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    try w.writeAll(
        \\target triple = "x86_64-unknown-linux-gnu"
        \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
        \\declare void @llvm.memmove.p0.p0.i64(ptr, ptr, i64, i1)
        \\declare i64 @stack_object_touch(ptr, i64)
        \\declare i1 @stack_object_predicate(ptr, i64)
        \\
    );
    try driver.writer.writeAll("#include <stdint.h>\n#include <stdbool.h>\n");
    var names: std.ArrayList([]const u8) = .empty;
    const Storage = struct { suffix: []const u8, ty: []const u8, bytes: u32 };
    const storage = [_]Storage{
        .{ .suffix = "i8", .ty = "i8", .bytes = 1 },
        .{ .suffix = "i16", .ty = "i16", .bytes = 2 },
        .{ .suffix = "i32", .ty = "i32", .bytes = 4 },
        .{ .suffix = "i64", .ty = "i64", .bytes = 8 },
        .{ .suffix = "f32", .ty = "float", .bytes = 4 },
        .{ .suffix = "f64", .ty = "double", .bytes = 8 },
        .{ .suffix = "i128", .ty = "i128", .bytes = 16 },
        .{ .suffix = "array3", .ty = "[3 x i32]", .bytes = 12 },
        .{ .suffix = "array16", .ty = "[16 x i32]", .bytes = 64 },
    };
    for (storage) |s| {
        const name = try c.fmt("stack_copy_{s}", .{s.suffix});
        try names.append(c.a, name);
        try w.print(
            \\define i64 @{0s}(ptr %out, ptr %input, ptr %alternate, ptr %source_out, i64 %length, i64 %seed) {{
            \\entry:
            \\ %src = alloca {1s}, align 16
            \\ %dst = alloca {1s}, align 16
            \\ call void @llvm.memcpy.p0.p0.i64(ptr %src, ptr %input, i64 {2d}, i1 false)
            \\ call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %alternate, i64 {2d}, i1 false)
            \\ call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %length, i1 false)
            \\ call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %dst, i64 {2d}, i1 false)
            \\ call void @llvm.memcpy.p0.p0.i64(ptr %source_out, ptr %src, i64 {2d}, i1 false)
            \\ %r = xor i64 %seed, {2d}
            \\ ret i64 %r
            \\}}
            \\
        , .{ name, s.ty, s.bytes });
        try driver.writer.print("extern uint64_t {s}(unsigned char*,const unsigned char*,const unsigned char*,unsigned char*,uint64_t,uint64_t);\n", .{name});
    }
    try driver.writer.writeAll("typedef uint64_t (*copy_fn)(unsigned char*,const unsigned char*,const unsigned char*,unsigned char*,uint64_t,uint64_t);\nstatic const struct { copy_fn run; unsigned bytes; } copies[]={\n");
    for (storage) |s| try driver.writer.print(" {{stack_copy_{s},{d}}},\n", .{ s.suffix, s.bytes });
    try driver.writer.writeAll("};\n");
    for ([_]Storage{ storage[3], storage[6], storage[7], storage[8] }) |s| {
        const name = try c.fmt("stack_phi_{s}", .{s.suffix});
        try names.append(c.a, name);
        try w.print(
            \\define i64 @{0s}(ptr %external, i64 %value, i1 %take_local, i64 %seed) {{
            \\entry:
            \\ %slot = alloca {1s}, align 16
            \\ %address = getelementptr i8, ptr %slot, i64 0
            \\ store i64 %value, ptr %address, align 8
            \\ br i1 %take_local, label %local, label %outside
            \\local:
            \\ br label %join
            \\outside:
            \\ br label %join
            \\join:
            \\ %p = phi ptr [ %slot, %local ], [ %external, %outside ]
            \\ %read = load i64, ptr %p, align 8
            \\ %r = xor i64 %read, %seed
            \\ ret i64 %r
            \\}}
            \\
        , .{ name, s.ty });
        try driver.writer.print("extern uint64_t {s}(const uint64_t*,uint64_t,bool,uint64_t);\n", .{name});
    }
    try driver.writer.writeAll("static uint64_t (*const choices[])(const uint64_t*,uint64_t,bool,uint64_t)={stack_phi_i64,stack_phi_i128,stack_phi_array3,stack_phi_array16};\n");
    for ([_]u32{ 2, 16 }) |words| {
        const name = try c.fmt("stack_phi_swap_{d}", .{words});
        try names.append(c.a, name);
        try w.print(
            \\define i64 @{0s}(i64 %a, i64 %b, i32 %count, i64 %seed) {{
            \\entry:
            \\ %first = alloca [{1d} x i32], align 8
            \\ %second = alloca [{1d} x i32], align 8
            \\ %fa = getelementptr i8, ptr %first, i64 0
            \\ %sa = getelementptr i8, ptr %second, i64 0
            \\ store i64 %a, ptr %fa, align 8
            \\ store i64 %b, ptr %sa, align 8
            \\ br label %loop
            \\loop:
            \\ %p = phi ptr [ %first, %entry ], [ %q, %loop ]
            \\ %q = phi ptr [ %second, %entry ], [ %p, %loop ]
            \\ %n = phi i32 [ 0, %entry ], [ %next, %loop ]
            \\ %next = add i32 %n, 1
            \\ %more = icmp ult i32 %n, %count
            \\ br i1 %more, label %loop, label %exit
            \\exit:
            \\ %x = load i64, ptr %p, align 8
            \\ %y = load i64, ptr %q, align 8
            \\ %difference = sub i64 %x, %y
            \\ %r = xor i64 %difference, %seed
            \\ ret i64 %r
            \\}}
            \\
        , .{ name, words });
        try driver.writer.print("extern uint64_t {s}(uint64_t,uint64_t,uint32_t,uint64_t);\n", .{name});
    }
    try driver.writer.writeAll("static uint64_t (*const swaps[])(uint64_t,uint64_t,uint32_t,uint64_t)={stack_phi_swap_2,stack_phi_swap_16};\n");
    try w.writeAll(@embedFile("templates/stack_object_addresses_base.ll"));
    for ([_][]const u8{ "stack_window", "stack_move", "stack_call_array", "stack_call_bool" }) |name| try names.append(c.a, name);
    try driver.writer.writeAll(@embedFile("templates/stack_object_addresses_driver.c"));
    try c.write(try c.join(&.{ output, "stack_object_addresses.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "stack_object_addresses_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "stack_object_addresses",
        .prefix = "stack-object-addresses",
        .fixture = "stack_object_addresses",
        .functions = names.items,
        .observations = 9480,
        .stdout = "stack-object-addresses observations=9480 copies=offsets=phis=loops=overlap=calls=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "stack_object_addresses")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
