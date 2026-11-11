//! Verify clean narrow extension carriers and nullable pointer facts at the ABI.
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
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try d.writeAll("#include <stdint.h>\ntypedef uint64_t (*call_fn)(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);\n" ++
        "typedef uint32_t (*raw_return_fn)(uint32_t,uint64_t);\n");
    var names: std.ArrayList([]const u8) = .empty;
    var cases: std.Io.Writer.Allocating = .init(c.a);
    for ([_]u16{ 1, 7, 8, 16, 23, 31 }) |bits| {
        const own = try c.fmt("return_attr_own_{d}", .{bits});
        const caller = try c.fmt("return_attr_call_{d}", .{bits});
        try names.appendSlice(c.a, &.{ own, caller });
        try w.print(
            \\declare zeroext i{0d} @return_attr_helper_{0d}(i{0d} zeroext, i64, i64, i64, i64, i64, i64, i64)
            \\define zeroext i{0d} @{1s}(i{0d} zeroext %input, i64 %seed) {{
            \\entry:
            \\ %wide = zext i{0d} %input to i64
            \\ %mixed = xor i64 %wide, %seed
            \\ %small = trunc i64 %mixed to i{0d}
            \\ ret i{0d} %small
            \\}}
            \\define i64 @{2s}(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) {{
            \\entry:
            \\ %small = trunc i64 %a to i{0d}
            \\ %called = call zeroext i{0d} @return_attr_helper_{0d}(i{0d} zeroext %small, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
            \\ %wide = zext i{0d} %called to i64
            \\ %one = xor i64 %wide, %a
            \\ %two = add i64 %one, %b
            \\ %three = xor i64 %two, %c
            \\ %four = add i64 %three, %d
            \\ %five = xor i64 %four, %e
            \\ %six = sub i64 %five, %f
            \\ %seven = xor i64 %six, %g
            \\ %result = add i64 %seven, %h
            \\ ret i64 %result
            \\}}
            \\
        , .{ bits, own, caller });
        try d.print("extern uint64_t {s}(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);\n", .{caller});
        // Observe the ABI's legalized return container, retaining padding
        // inside AL/AX/EAX while excluding unspecified bits above it.
        const receive = if (bits <= 8) " movzbl %al,%eax\\n" else if (bits <= 16) " movzwl %ax,%eax\\n" else "";
        try d.print("extern uint32_t probe_return_attr_{0d}(uint32_t,uint64_t);\n" ++
            "__asm__(\".text\\n.globl probe_return_attr_{0d}\\n.type probe_return_attr_{0d},@function\\nprobe_return_attr_{0d}:\\n sub $8,%rsp\\n call {1s}\\n{2s} add $8,%rsp\\n ret\\n.size probe_return_attr_{0d},.-probe_return_attr_{0d}\\n\");\n", .{ bits, own, receive });
        try cases.writer.print(" {{{s},probe_return_attr_{d},{d}}},\n", .{ caller, bits, bits });
    }
    try d.writeAll("static const struct { call_fn run; raw_return_fn raw; unsigned bits; } narrow_cases[]={\n");
    try d.writeAll(cases.written());
    try d.writeAll("};\n");
    for ([_]u16{ 16, 140 }) |bytes| {
        const name = try c.fmt("return_attr_nullable_{d}", .{bytes});
        try names.append(c.a, name);
        try w.print(
            \\declare dereferenceable_or_null({0d}) ptr @return_attr_pointer_helper_{0d}(ptr dereferenceable_or_null({0d}), i64, i64, i64)
            \\define i64 @{1s}(ptr dereferenceable_or_null({0d}) %input, i64 %choose, i64 %seed, i64 %live) {{
            \\entry:
            \\ %called = call dereferenceable_or_null({0d}) ptr @return_attr_pointer_helper_{0d}(ptr dereferenceable_or_null({0d}) %input, i64 %choose, i64 %seed, i64 %live)
            \\ %empty = icmp eq ptr %called, null
            \\ br i1 %empty, label %null, label %read
            \\read:
            \\ %last = getelementptr i8, ptr %called, i64 {2d}
            \\ %first_byte = load i8, ptr %called, align 1
            \\ %last_byte = load i8, ptr %last, align 1
            \\ %first = zext i8 %first_byte to i64
            \\ %final = zext i8 %last_byte to i64
            \\ %bytes = xor i64 %first, %final
            \\ br label %done
            \\null:
            \\ br label %done
            \\done:
            \\ %value = phi i64 [ %bytes, %read ], [ 74565, %null ]
            \\ %mixed = xor i64 %value, %seed
            \\ %result = add i64 %mixed, %live
            \\ ret i64 %result
            \\}}
            \\
        , .{ bytes, name, bytes - 1 });
        try d.print("extern uint64_t {s}(unsigned char*,uint64_t,uint64_t,uint64_t);\n", .{name});
    }
    try names.append(c.a, "return_attr_nullable_forward");
    try w.writeAll("define dereferenceable_or_null(16) ptr @return_attr_nullable_forward(ptr dereferenceable_or_null(16) %input) {\nentry:\n ret ptr %input\n}\n");
    try d.writeAll("extern unsigned char *return_attr_nullable_forward(unsigned char*);\n");
    try d.writeAll(@embedFile("templates/call_return_attributes_driver.c"));
    try c.write(try c.join(&.{ output, "call_return_attributes.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "call_return_attributes_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "call_return_attributes",
        .prefix = "call-return-attributes",
        .fixture = "call_return_attributes",
        .functions = names.items,
        .observations = 520,
        .stdout = "call-return-attributes observations=520 zeroext=nullable=padding=live=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "call_return_attributes")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
