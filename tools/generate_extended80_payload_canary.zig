//! Exact extended80 payloads with integer oracles and a protected source page.
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
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ntarget datalayout = \"e-i128:128-f80:128\"\ndeclare i64 @extended80_payload_clobber(i64)\n");
    try w.writeAll("declare x86_fp80 @extended80_call_provider(i64,x86_fp80,i64,i64,i64,i64,i64,i64,x86_fp80,x86_fp80,ptr)\n");
    try d.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef u128 (*payload_fn)(const uint8_t*,uint8_t*,u128,uint64_t,uint32_t,uint64_t,uint64_t);\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (0..8) |index| {
        const name = try c.fmt("extended80_payload_{d}", .{index});
        try names.append(c.a, name);
        try w.print("define i128 @{s}(ptr %input, ptr %output, i128 %raw, i64 %index, i32 %choice, i64 %live, i64 %extra) {{\nentry:\n", .{name});
        try w.writeAll(" %narrow = trunc i128 %raw to i80\n %from_bits = bitcast i80 %narrow to x86_fp80\n %cond = icmp ne i32 %choice, 0\n");
        if (index < 5) {
            if (index == 1) try w.writeAll(" %address = getelementptr x86_fp80, ptr %input, i64 %index\n");
            try w.print(" %loaded = load x86_fp80, ptr {s}, align 1\n", .{if (index == 1) "%address" else "%input"});
        }
        const operand = switch (index) {
            0, 1 => "%loaded",
            2 => blk: {
                try w.writeAll(" %slot = alloca x86_fp80, align 16\n store x86_fp80 %loaded, ptr %slot, align 16\n %owned = load x86_fp80, ptr %slot, align 16\n");
                break :blk "%owned";
            },
            3 => blk: {
                try w.writeAll(" %chosen = select i1 %cond, x86_fp80 %loaded, x86_fp80 %from_bits\n");
                break :blk "%chosen";
            },
            4 => blk: {
                try w.writeAll(" br i1 %cond, label %left, label %right\nleft:\n br label %join\nright:\n br label %join\njoin:\n %merged = phi x86_fp80 [ %loaded, %left ], [ %from_bits, %right ]\n");
                break :blk "%merged";
            },
            5 => "poison",
            6 => "undef",
            7 => "0xK7FFF8000000000000001",
            else => unreachable,
        };
        try w.print(" %stable = freeze x86_fp80 {s}\n", .{operand});
        try w.writeAll(" %probe = call i64 @extended80_payload_clobber(i64 %live)\n store x86_fp80 %stable, ptr %output, align 1\n %next = getelementptr i8, ptr %output, i64 10\n store x86_fp80 %stable, ptr %next, align 1\n %bits = bitcast x86_fp80 %stable to i80\n %wide = zext i80 %bits to i128\n %one = xor i64 %probe, %extra\n %two = add i64 %one, %index\n %choice64 = zext i32 %choice to i64\n %mixed = xor i64 %two, %choice64\n %mask = zext i64 %mixed to i128\n %with_raw = xor i128 %wide, %raw\n %answer = xor i128 %with_raw, %mask\n ret i128 %answer\n}\n");
        try d.print("extern u128 {s}(const uint8_t*,uint8_t*,u128,uint64_t,uint32_t,uint64_t,uint64_t);\n", .{name});
    }
    const incoming = "extended80_incoming";
    try names.append(c.a, incoming);
    try w.writeAll(
        \\define i128 @extended80_incoming(i64 %a, x86_fp80 %x, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, x86_fp80 %y, ptr %output) {
        \\entry:
        \\ %probe = call i64 @extended80_payload_clobber(i64 %a)
        \\ store x86_fp80 %x, ptr %output, align 1
        \\ %next = getelementptr i8, ptr %output, i64 10
        \\ store x86_fp80 %y, ptr %next, align 1
        \\ %xb = bitcast x86_fp80 %x to i80
        \\ %yb = bitcast x86_fp80 %y to i80
        \\ %xw = zext i80 %xb to i128
        \\ %yw = zext i80 %yb to i128
        \\ %one = xor i64 %probe, %b
        \\ %two = add i64 %one, %c
        \\ %three = xor i64 %two, %d
        \\ %four = add i64 %three, %e
        \\ %five = xor i64 %four, %f
        \\ %six = add i64 %five, %g
        \\ %mask = zext i64 %six to i128
        \\ %xy = xor i128 %xw, %yw
        \\ %answer = xor i128 %xy, %mask
        \\ ret i128 %answer
        \\}
        \\
    );
    try d.writeAll("extern u128 extended80_incoming(uint64_t,long double,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,long double,uint8_t*);\n");
    try names.appendSlice(c.a, &.{ "extended80_return_load", "extended80_return_phi", "extended80_return_constant" });
    try w.writeAll(
        \\define x86_fp80 @extended80_return_load(ptr %input, ptr %output, i64 %live) {
        \\entry:
        \\ %value = load x86_fp80, ptr %input, align 1
        \\ %probe = call i64 @extended80_payload_clobber(i64 %live)
        \\ store i64 %probe, ptr %output, align 1
        \\ ret x86_fp80 %value
        \\}
        \\define x86_fp80 @extended80_return_phi(i64 %live, x86_fp80 %x, x86_fp80 %y, i32 %choice, ptr %output) {
        \\entry:
        \\ %cond = icmp ne i32 %choice, 0
        \\ br i1 %cond, label %left, label %right
        \\left:
        \\ br label %join
        \\right:
        \\ br label %join
        \\join:
        \\ %value = phi x86_fp80 [ %x, %left ], [ %y, %right ]
        \\ %probe = call i64 @extended80_payload_clobber(i64 %live)
        \\ store i64 %probe, ptr %output, align 1
        \\ ret x86_fp80 %value
        \\}
        \\define x86_fp80 @extended80_return_constant(ptr %output, i64 %live) {
        \\entry:
        \\ %probe = call i64 @extended80_payload_clobber(i64 %live)
        \\ store i64 %probe, ptr %output, align 1
        \\ ret x86_fp80 0xK7FFF8000000000000001
        \\}
        \\
    );
    try d.writeAll("extern long double extended80_return_load(const uint8_t*,uint8_t*,uint64_t);\nextern long double extended80_return_phi(uint64_t,long double,long double,uint32_t,uint8_t*);\nextern long double extended80_return_constant(uint8_t*,uint64_t);\n");
    try names.append(c.a, "extended80_call");
    try w.writeAll(
        \\define i128 @extended80_call(ptr %input, ptr %output, i128 %raw, i64 %index, i32 %choice, i64 %live, i64 %extra) {
        \\entry:
        \\ %narrow = trunc i128 %raw to i80
        \\ %z = bitcast i80 %narrow to x86_fp80
        \\ %x = load x86_fp80, ptr %input, align 1
        \\ %next = getelementptr i8, ptr %input, i64 16
        \\ %y = load x86_fp80, ptr %next, align 1
        \\ %r = call x86_fp80 @extended80_call_provider(i64 %live,x86_fp80 %x,i64 %index,i64 %extra,i64 %live,i64 %index,i64 %extra,i64 %live,x86_fp80 %y,x86_fp80 %z,ptr %output)
        \\ %second = getelementptr i8, ptr %output, i64 10
        \\ %ignored = call x86_fp80 @extended80_call_provider(i64 %extra,x86_fp80 %z,i64 %index,i64 %live,i64 %extra,i64 %index,i64 %live,i64 %extra,x86_fp80 %x,x86_fp80 %y,ptr %second)
        \\ %probe = call i64 @extended80_payload_clobber(i64 %live)
        \\ %third = getelementptr i8, ptr %output, i64 20
        \\ store x86_fp80 %r, ptr %third, align 1
        \\ %bits = bitcast x86_fp80 %r to i80
        \\ %wide = zext i80 %bits to i128
        \\ %one = xor i64 %probe, %extra
        \\ %two = add i64 %one, %index
        \\ %choice64 = zext i32 %choice to i64
        \\ %mixed = xor i64 %two, %choice64
        \\ %mask = zext i64 %mixed to i128
        \\ %with_raw = xor i128 %wide, %raw
        \\ %answer = xor i128 %with_raw, %mask
        \\ ret i128 %answer
        \\}
        \\
    );
    try d.writeAll("extern u128 extended80_call(const uint8_t*,uint8_t*,u128,uint64_t,uint32_t,uint64_t,uint64_t);\n");
    try d.writeAll("static const payload_fn cases[]={\n");
    for (names.items[0..8]) |name| try d.print(" {s},\n", .{name});
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/extended80_payload_driver.c"));
    try c.write(try c.join(&.{ output, "extended80_payload.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "extended80_payload_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "extended80_payload",
        .prefix = "extended80-payload",
        .fixture = "extended80_payload",
        .functions = names.items,
        .observations = 53248,
        .stdout = "extended80-payload observations=53248 bits=storage=freeze=phi=live=stride=abi=page=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "extended80_payload")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
