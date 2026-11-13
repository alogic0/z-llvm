//! Checked pointer promises on prefetch and SysV variadic intrinsics.
const std = @import("std");
const u = @import("validation/common.zig");
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    const contract = "independent-integer-byte-goldens=checked-pointer-facts=prefetch-memory=variadic-start-copy-end=independent-cursors=gp-overflow=call-clobbers=guard-pages=preserved";
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\ndeclare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)\ndeclare void @llvm.prefetch.p0(ptr,i32,i32,i32)\ndeclare void @llvm.va_start.p0(ptr)\ndeclare void @llvm.va_copy.p0(ptr,ptr)\ndeclare void @llvm.va_end.p0(ptr)\nattributes #7 = { nounwind }\n");
    try driver.writer.print("#define DRIVER_NAME \"intrinsic-pointer-facts\"\n#define DRIVER_SEEDS 64\n#define DRIVER_CONTRACT \"{s}\"\n", .{contract});
    try driver.writer.writeAll(try c.read("tools/templates/behavior_completion_core.h"));
    try driver.writer.writeAll(try c.read("tools/templates/intrinsic_pointer_facts_model.c"));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var count: usize = 0;
    const facts = [_][]const u8{ "nonnull", "noundef nonnull", "nonnull align 8 dereferenceable(8)", "noundef nonnull align 8 dereferenceable_or_null(8)" };
    for (facts) |attrs| for (0..2) |rw| for (0..4) |locality| {
        const probe = try c.fmt("intrinsic_pointer_probe_{d}", .{count});
        try u.add(&functions, u.s(probe));
        try text.writer.print("define i64 @{0s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n %before = load i64,ptr %source,align 1\n call void @llvm.prefetch.p0(ptr {1s} %source,i32 {2d},i32 {3d},i32 1) #7\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store i64 %before,ptr %out,align 1\n %p = getelementptr i8,ptr %out,i64 8\n store i64 %token,ptr %p,align 1\n ret i64 %token\n}}\n", .{ probe, attrs, rw, locality });
        try driver.writer.print("extern uint64_t {s}(void *,void *,const void *,uint64_t);\n", .{probe});
        try table.writer.print("{{{s},64,0,0}},\n", .{probe});
        count += 1;
    };
    for (facts) |attrs| for ([_]usize{ 1, 4, 5, 10 }) |lanes| for (0..2) |copy| {
        const body = try c.fmt("intrinsic_pointer_body_{d}", .{count});
        const probe = try c.fmt("intrinsic_pointer_probe_{d}", .{count});
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("define internal i64 @{s}(ptr %out,i64 %salt,i32 %count,...) noinline {{\nentry:\n %list = alloca [24 x i8],align 16\n %copy = alloca [24 x i8],align 16\n call void @llvm.va_start.p0(ptr {s} %list) #7\n", .{ body, attrs });
        if (copy != 0) try text.writer.print(" call void @llvm.va_copy.p0(ptr {0s} %copy,ptr {0s} %list) #7\n %first = va_arg ptr %list,i64\n", .{attrs});
        const active = if (copy != 0) "copy" else "list";
        var sum: []const u8 = if (copy != 0) "%first" else "0";
        for (0..lanes) |i| {
            try text.writer.print(" %v{0d} = va_arg ptr %{1s},i64\n %p{0d} = getelementptr i8,ptr %out,i64 {2d}\n store i64 %v{0d},ptr %p{0d},align 1\n %sum{0d} = add i64 {3s},%v{0d}\n", .{ i, active, i * 8, sum });
            sum = try c.fmt("%sum{d}", .{i});
        }
        if (copy != 0) try text.writer.print(" call void @llvm.va_end.p0(ptr {s} %copy) #7\n", .{attrs});
        try text.writer.print(" call void @llvm.va_end.p0(ptr {s} %list) #7\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n %answer = xor i64 {s},%token\n ret i64 %answer\n}}\ndefine i64 @{s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n", .{ attrs, sum, probe });
        for (0..lanes) |i| try text.writer.print(" %p{0d} = getelementptr i8,ptr %source,i64 {1d}\n %v{0d} = load i64,ptr %p{0d},align 1\n", .{ i, i * 8 });
        try text.writer.print(" %answer = call i64 (ptr,i64,i32,...) @{s}(ptr %out,i64 %salt,i32 {d}", .{ body, lanes });
        for (0..lanes) |i| try text.writer.print(",i64 %v{d}", .{i});
        try text.writer.writeAll(")\n ret i64 %answer\n}\n");
        try driver.writer.print("extern uint64_t {s}(void *,void *,const void *,uint64_t);\n", .{probe});
        try table.writer.print("{{{s},64,{d},0}},\n", .{ probe, lanes + copy * 16 });
        count += 1;
    };
    if (count != 64) return error.IntrinsicPointerCaseInventoryChanged;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ root, "intrinsic_pointer_facts.ll" }), text.written());
    try c.write(try c.join(&.{ root, "intrinsic_pointer_facts_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "intrinsic_pointer_facts", .fixture = "intrinsic_pointer_facts", .prefix = "intrinsic-pointer-facts", .functions = functions, .observations = count * 64 * 8, .stdout = try c.fmt("intrinsic-pointer-facts observations={d} {s}\n", .{ count * 64 * 8, contract }) });
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = &.{entry} }));
    if (args.get("verify-root")) |before| {
        for ([_][]const u8{ "intrinsic_pointer_facts.ll", "intrinsic_pointer_facts_driver.c" }) |file| if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureMismatch;
        const entries = try u.get(try c.load(try c.join(&.{ before, "native_canaries.json" })), "canaries");
        var found = false;
        for (try u.json.array(entries)) |row| if (u.json.is(try u.get(row, "population"), "intrinsic_pointer_facts")) {
            if (found or !u.json.eql(row, entry)) return error.RegistryContractMismatch;
            found = true;
        };
        if (!found) return error.RegistryPopulationMissing;
    }
    try c.print("intrinsic pointer facts:64 cases,96 definitions,32768 observations per route{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
