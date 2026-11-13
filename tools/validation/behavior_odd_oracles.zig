const std = @import("std");
const u = @import("common.zig");
const batch = "tools/templates";
const header = "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n";
pub fn booleanChecked(c: *u.Context, fixtures: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    var count: usize = 0;
    try text.writer.writeAll(header);
    try driver.writer.writeAll(try c.read(batch ++ "/behavior_boolean_checked_model.c"));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    for ([_]usize{ 1, 2, 3, 4, 8, 16, 32, 64 }) |n| {
        try text.writer.print("declare i1 @llvm.vector.reduce.or.v{0d}i1(<{0d} x i1>)\n", .{n});
        for ([_][]const u8{ "uadd", "usub", "umul", "sadd", "ssub", "smul" }, 0..) |op, kind| {
            try text.writer.print("declare {{<{0d} x i1>,<{0d} x i1>}} @llvm.{1s}.with.overflow.v{0d}i1(<{0d} x i1>,<{0d} x i1>)\n", .{ n, op });
            for ([_][]const u8{ "", "fastcc " }) |cc| {
                const body = try c.fmt("boolean_checked_body_{d}", .{count});
                const probe = try c.fmt("boolean_checked_probe_{d}", .{count});
                count += 1;
                try u.add(&functions, u.s(body));
                try u.add(&functions, u.s(probe));
                try text.writer.print("define {0s}i64 @{1s}(ptr %out,ptr %a,ptr %b,i64 %live) noinline {{\nentry:\n %xb = load <{2d} x i8>,ptr %a,align 1\n %yb = load <{2d} x i8>,ptr %b,align 1\n %x = trunc <{2d} x i8> %xb to <{2d} x i1>\n %y = trunc <{2d} x i8> %yb to <{2d} x i1>\n %pair = call {{<{2d} x i1>,<{2d} x i1>}} @llvm.{3s}.with.overflow.v{2d}i1(<{2d} x i1> %x,<{2d} x i1> %y)\n %v = extractvalue {{<{2d} x i1>,<{2d} x i1>}} %pair,0\n %flags = extractvalue {{<{2d} x i1>,<{2d} x i1>}} %pair,1\n %bytes = zext <{2d} x i1> %v to <{2d} x i8>\n store <{2d} x i8> %bytes,ptr %out,align 1\n %fp = getelementptr i8,ptr %out,i64 {2d}\n store <{2d} x i1> %flags,ptr %fp,align 1\n %wp = getelementptr i8,ptr %out,i64 {4d}\n store <{2d} x i1> %v,ptr %wp,align 1\n %any = call i1 @llvm.vector.reduce.or.v{2d}i1(<{2d} x i1> %flags)\n %wide = zext i1 %any to i64\n %r = xor i64 %wide,%live\n ret i64 %r\n}}\ndefine i64 @{5s}(ptr %out,ptr %a,ptr %b,i64 %live) {{\nentry:\n %r = call {0s}i64 @{1s}(ptr %out,ptr %a,ptr %b,i64 %live)\n ret i64 %r\n}}\n", .{ cc, body, n, op, n + (n + 7) / 8, probe });
                try driver.writer.print("extern uint64_t {s}(void *,const void *,const void *,uint64_t);\n", .{probe});
                try table.writer.print("{{{s},{d},{d}}},\n", .{ probe, n, kind });
            }
        }
    }
    if (count != 96) return error.BooleanCaseInventoryDiffers;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "boolean_checked.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "boolean_checked_driver.c" }), driver.written());
    return u.toValue(c.a, .{ .population = "boolean_checked", .fixture = "boolean_checked", .prefix = "boolean-checked", .functions = functions, .observations = count * 64 * 8, .stdout = try c.fmt("boolean-checked observations={d} exhaustive-one-bit-pairs=signed-unsigned=packed-flags=canonical-lanes=readonly-inputs=guard-pages=preserved\n", .{count * 64 * 8}) });
}
pub fn oddShift(c: *u.Context, fixtures: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    var count: usize = 0;
    try text.writer.writeAll(header);
    try text.writer.writeAll("declare i64 @odd_shift_clobber(i64,i64,i64,i64,i64,i64,i64,i64)\n");
    try driver.writer.writeAll(try c.read(batch ++ "/behavior_odd_shift_model.c"));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    for ([_]usize{ 1, 2, 4, 8, 16, 32, 64 }) |n| for ([_][]const u8{ "shl", "lshr", "ashr" }, 0..) |op, kind| for ([_][]const u8{ "", "fastcc " }) |cc| {
        const body = try c.fmt("odd_shift_body_{d}", .{count});
        const probe = try c.fmt("odd_shift_probe_{d}", .{count});
        count += 1;
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("define {0s}i64 @{1s}(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {{\nentry:\n %x = load <{2d} x i24>,ptr %a,align 1\n %y = load <{2d} x i24>,ptr %b,align 1\n %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n %v = {3s} <{2d} x i24> %x,%y\n store <{2d} x i24> %v,ptr %out,align 1\n %r = xor i64 %token,%salt\n ret i64 %r\n}}\ndefine i64 @{4s}(ptr %out,ptr %a,ptr %b,i64 %salt) {{\nentry:\n %r = call {0s}i64 @{1s}(ptr %out,ptr %a,ptr %b,i64 %salt)\n ret i64 %r\n}}\n", .{ cc, body, n, op, probe });
        try driver.writer.print("extern uint64_t {s}(void *,const void *,const void *,uint64_t);\n", .{probe});
        try table.writer.print("{{{s},{d},{d}}},\n", .{ probe, n, kind });
    };
    if (count != 42) return error.ShiftCaseInventoryDiffers;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "odd_shift.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "odd_shift_driver.c" }), driver.written());
    return u.toValue(c.a, .{ .population = "odd_shift", .fixture = "odd_shift", .prefix = "odd-shift", .functions = functions, .observations = count * 128 * 6, .stdout = try c.fmt("odd-shift observations={d} i24-all-valid-counts=three-operators=call-clobbers=spilled-inputs=readonly-inputs=guard-pages=preserved\n", .{count * 128 * 6}) });
}
