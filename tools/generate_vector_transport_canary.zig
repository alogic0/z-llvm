//! Exact wide lanes, vector GEPs, packed PHIs, and bounded literal staging.
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
    var cases: std.ArrayList([]const u8) = .empty;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ndeclare i64 @vector_transport_clobber(i64)\ndeclare fp128 @vector_transport_probe(fp128,fp128)\n");
    try d.writeAll("#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef u128 (*transport_fn)(u128,uint8_t*,uint8_t*,uint64_t);\nstruct transport_case {transport_fn function;unsigned kind,width,variant;};\n");
    for ([_]u16{ 80, 113, 127 }) |bits| {
        const body = try c.fmt("vector_transport_wide{d}_body", .{bits});
        const name = try c.fmt("vector_transport_wide{d}", .{bits});
        try names.appendSlice(c.a, &.{ body, name });
        try w.print("define i{d} @{s}(i{d} %raw,ptr %out) {{\nentry:\n store i{d} %raw,ptr %out,align 1\n %one = insertelement <8 x i{d}> poison,i{d} %raw,i64 0\n %all = shufflevector <8 x i{d}> %one,<8 x i{d}> poison,<8 x i32> zeroinitializer\n %parts = lshr <8 x i{d}> %all,<", .{ bits, body, bits, bits, bits, bits, bits, bits, bits });
        for (0..8) |i| try w.print("{s}i{d} {d}", .{ if (i == 0) "" else ",", bits, i * 8 });
        try w.print(">\n %small = trunc <8 x i{d}> %parts to <8 x i8>\n store <8 x i8> %small,ptr %out,align 1\n ret i{d} %raw\n}}\n", .{ bits, bits });
        try w.print("define i128 @{s}(i128 %raw,ptr %input,ptr %out,i64 %live) {{\nentry:\n %narrow = trunc i128 %raw to i{d}\n %value = call i{d} @{s}(i{d} %narrow,ptr %out)\n %saved = call i64 @vector_transport_clobber(i64 %live)\n %wide = zext i{d} %value to i128\n %extended = zext i64 %saved to i128\n %result = xor i128 %wide,%extended\n ret i128 %result\n}}\n", .{ name, bits, bits, body, bits, bits });
        try cases.append(c.a, try c.fmt("{{{s},0,{d},0}},\n", .{ name, bits }));
        try d.print("extern u128 {s}(u128,uint8_t*,uint8_t*,uint64_t);\n", .{name});
    }
    for (0..2) |variant| {
        const name = try c.fmt("vector_transport_gep{d}", .{variant});
        try names.append(c.a, name);
        try w.print("define i128 @{s}(i128 %raw,ptr %input,ptr %out,i64 %live) {{\nentry:\n %base = getelementptr i8,ptr %input,i64 8\n", .{name});
        if (variant == 0) try w.writeAll(" %pointers = getelementptr i8,ptr %base,<4 x i64> <i64 -8,i64 0,i64 8,i64 16>\n") else try w.writeAll(" %offsets = add <4 x i64> zeroinitializer,<i64 -8,i64 0,i64 8,i64 16>\n %pointers = getelementptr i8,ptr %base,<4 x i64> %offsets\n");
        try w.writeAll(" %index = and i64 %live,3\n %picked = extractelement <4 x ptr> %pointers,i64 %index\n %value = load i64,ptr %picked,align 1\n %saved = call i64 @vector_transport_clobber(i64 %live)\n store i64 %value,ptr %out,align 1\n %wide = zext i64 %value to i128\n %extended = zext i64 %saved to i128\n %result = xor i128 %wide,%extended\n ret i128 %result\n}\n");
        try cases.append(c.a, try c.fmt("{{{s},1,64,{d}}},\n", .{ name, variant }));
        try d.print("extern u128 {s}(u128,uint8_t*,uint8_t*,uint64_t);\n", .{name});
    }
    for (0..2) |variant| {
        const name = try c.fmt("vector_transport_phi{d}", .{variant});
        try names.append(c.a, name);
        if (variant == 0) try w.print("@{s}_table = internal constant [2 x ptr] [ptr blockaddress(@{s},%exit),ptr blockaddress(@{s},%loop)]\n", .{ name, name, name });
        try w.print("define i128 @{s}(i128 %raw,ptr %input,ptr %out,i64 %live) {{\nentry:\n %a = bitcast i128 %raw to fp128\n %b = load fp128,ptr %input,align 1\n %low = trunc i128 %raw to i64\n %masked = and i64 %low,3\n %limit = add i64 %masked,1\n %narrow_limit = trunc i64 %limit to i56\n %choice = trunc i64 %live to i1\n", .{name});
        if (variant == 0) try w.print(" %branch_index = and i64 %live,1\n %branch_slot = getelementptr ptr,ptr @{s}_table,i64 %branch_index\n %address = load ptr,ptr %branch_slot,align 8\n indirectbr ptr %address,[label %loop,label %exit]\n", .{name}) else try w.writeAll(" br i1 %choice,label %loop,label %exit\n");
        const alternate = if (variant == 0) "%b" else "0xL0123456789ABCDEF7FFF800000000123";
        try w.print("loop:\n %x = phi fp128 [ %a,%entry ],[ %y,%loop ]\n %y = phi fp128 [ {s},%entry ],[ %x,%loop ]\n %flag = phi i32 [ 4294967295,%entry ],[ %flag_next,%loop ]\n %n = phi i56 [ 0,%entry ],[ %next,%loop ]\n %flag_next = or i32 %flag,0\n %next = add i56 %n,1\n %again = icmp ult i56 %next,%narrow_limit\n br i1 %again,label %loop,label %exit\nexit:\n %picked = phi fp128 [ {s},%entry ],[ %x,%loop ]\n %return_flag = phi i32 [ 4294967295,%entry ],[ %flag,%loop ]\n %saved_raw = call i64 @vector_transport_clobber(i64 %live)\n %flag_bits = zext i32 %return_flag to i64\n %saved = xor i64 %saved_raw,%flag_bits\n store fp128 %picked,ptr %out,align 1\n %bits = bitcast fp128 %picked to i128\n %extended = zext i64 %saved to i128\n %result = xor i128 %bits,%extended\n ret i128 %result\n}}\n", .{ alternate, if (variant == 0) "%a" else alternate });
        try cases.append(c.a, try c.fmt("{{{s},2,128,{d}}},\n", .{ name, variant }));
        try d.print("extern u128 {s}(u128,uint8_t*,uint8_t*,uint64_t);\n", .{name});
    }
    const chain = "vector_transport_literal_chain";
    try names.append(c.a, chain);
    try w.print("define i128 @{s}(i128 %raw,ptr %input,ptr %out,i64 %live) {{\nentry:\n %a = bitcast i128 %raw to fp128\n", .{chain});
    for (0..97) |index| {
        const previous = if (index == 0) "%a" else try c.fmt("%r{d}", .{index - 1});
        try w.print(" %r{d} = call fp128 @vector_transport_probe(fp128 {s},fp128 0xL00000000000000004000400000000000)\n", .{ index, previous });
    }
    try w.writeAll(" %saved = call i64 @vector_transport_clobber(i64 %live)\n store fp128 %r96,ptr %out,align 1\n %bits = bitcast fp128 %r96 to i128\n %extended = zext i64 %saved to i128\n %result = xor i128 %bits,%extended\n ret i128 %result\n}\n");
    const sentinel = "vector_transport_stack_sentinel";
    try names.append(c.a, sentinel);
    try w.print("define i128 @{s}(i128 %raw,ptr %input,ptr %out,i64 %live) {{\nentry:\n %slot = alloca [8 x i8],align 8\n %low = trunc i128 %raw to i64\n store i64 %low,ptr %slot,align 8\n %before = getelementptr i8,ptr %slot,i64 -1\n %pointer = getelementptr i8,ptr %before,i64 1\n %value = load i64,ptr %pointer,align 1\n %saved = call i64 @vector_transport_clobber(i64 %live)\n store i64 %value,ptr %out,align 1\n %wide = zext i64 %value to i128\n %extended = zext i64 %saved to i128\n %result = xor i128 %wide,%extended\n ret i128 %result\n}}\n", .{sentinel});
    try d.print("extern u128 {s}(u128,uint8_t*,uint8_t*,uint64_t);\n", .{sentinel});
    try cases.append(c.a, try c.fmt("{{{s},4,64,0}},\n", .{sentinel}));
    try d.print("extern u128 {s}(u128,uint8_t*,uint8_t*,uint64_t);\nstatic const struct transport_case cases[]={{\n", .{chain});
    for (cases.items) |entry| try d.writeAll(entry);
    try d.print("{{{s},3,128,0}}\n}};\n", .{chain});
    try d.writeAll(@embedFile("templates/vector_transport_driver.c"));
    try c.write(try c.join(&.{ out, "vector_transport.ll" }), llvm.written());
    try c.write(try c.join(&.{ out, "vector_transport_driver.c" }), driver.written());
    const pop = try u.toValue(c.a, .{ .population = "vector_transport", .prefix = "vector-transport", .fixture = "vector_transport", .functions = names.items, .observations = 73728, .stdout = "vector-transport observations=73728 wide=gep=phi=payloads=staging=guards=live=preserved\n" });
    try c.writeJson(try c.join(&.{ out, "population.json" }), pop);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "vector_transport")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, pop, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ out, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
