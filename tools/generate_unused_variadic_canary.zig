//! Unused named SysV inputs keep their positions before copied va_list cursors.
const std = @import("std");
const u = @import("validation/common.zig");
const Output = @import("generate_optimized_fact_canaries.zig").Output;
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    const contract = "independent-integer-goldens=unused-named-gpr-and-sse-inputs=exact-varargs-positions=copied-cursors=gp-overflow=pointer-arguments=call-clobbers=guard-pages=preserved";
    var out = try Output.init(&c, "unused-variadic-inputs", "unused_variadic_inputs_model.c", contract);
    try out.ir.writer.writeAll("%UnusedVaList = type { i32,i32,ptr,ptr }\ndeclare void @llvm.va_start.p0(ptr)\ndeclare void @llvm.va_end.p0(ptr)\ndeclare void @llvm.va_copy.p0(ptr,ptr)\ndeclare void @llvm.memcpy.p0.p0.i64(ptr,ptr,i64,i1)\n");
    for ([_][]const u8{ "i32", "i64", "ptr" }) |ty| for ([_]usize{ 1, 3, 6 }) |fixed| for (0..2) |fp| for (0..2) |copy| for (0..3) |kind| {
        const body = try c.fmt("unused_variadic_body_{d}", .{out.count});
        const probe = try c.fmt("unused_variadic_probe_{d}", .{out.count});
        const ctype = if (std.mem.eql(u8, ty, "i32")) "uint32_t" else if (std.mem.eql(u8, ty, "i64")) "uint64_t" else "const void *";
        try u.add(&out.functions, u.s(body));
        try out.ir.writer.print("define i32 @{s}(", .{body});
        try out.driver.writer.print("extern uint32_t {s}(", .{body});
        for (0..fixed) |index| {
            if (index != 0) {
                try out.ir.writer.writeAll(",");
                try out.driver.writer.writeAll(",");
            }
            try out.ir.writer.print("{s} %{d}", .{ ty, index });
            try out.driver.writer.writeAll(ctype);
        }
        if (fp != 0) {
            try out.ir.writer.writeAll(",double %fp_unused");
            try out.driver.writer.writeAll(",double");
        }
        try out.ir.writer.writeAll(",...) noinline {\nentry:\n %list = alloca %UnusedVaList,align 8\n %copy = alloca %UnusedVaList,align 8\n call void @llvm.va_start.p0(ptr nonnull %list)\n");
        try out.driver.writer.writeAll(",...);\n");
        if (copy != 0) try out.ir.writer.writeAll(" call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)\n") else try out.ir.writer.writeAll(" call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)\n");
        if (kind == 1) {
            try out.ir.writer.writeAll(" %a = va_arg ptr %copy,ptr\n %b = va_arg ptr %copy,ptr\n %first = load i32,ptr %a,align 1\n %second = load i32,ptr %b,align 1\n %answer = add i32 %first,%second\n");
        } else {
            try out.ir.writer.writeAll(" %first = va_arg ptr %copy,i32\n");
            if (kind == 0) try out.ir.writer.writeAll(" %second = va_arg ptr %copy,i32\n");
        }
        try out.ir.writer.print(" call void @llvm.va_end.p0(ptr nonnull %copy)\n ret i32 %{s}\n}}\n", .{if (kind == 0) "second" else if (kind == 1) "answer" else "first"});
        try out.driver.writer.print("static uint64_t {s}(void *out,void *source,const void *unused,uint64_t salt){{(void)unused;uint32_t inputs[2];memcpy(inputs,source,8);uint64_t value={s}(", .{ probe, body });
        for (0..fixed) |index| {
            if (index != 0) try out.driver.writer.writeAll(",");
            if (std.mem.eql(u8, ty, "ptr")) try out.driver.writer.writeAll("source") else try out.driver.writer.print("({s})(salt+{d})", .{ ctype, index });
        }
        if (fp != 0) try out.driver.writer.writeAll(",1.5");
        if (kind == 1) try out.driver.writer.writeAll(",source,(const unsigned char *)source+4") else {
            try out.driver.writer.writeAll(",inputs[0]");
            if (kind == 0) try out.driver.writer.writeAll(",inputs[1]");
        }
        try out.driver.writer.writeAll(");uint64_t token=complete_clobber(salt,2,3,4,5,6,7,8);memcpy(out,&value,8);memcpy((unsigned char *)out+8,&token,8);return value^token;}\n");
        try out.table.writer.print("{{{s},32,{d},0}},\n", .{ probe, kind });
        out.count += 1;
    };
    if (out.count != 108) return error.UnusedVariadicInventoryChanged;
    const entry = try out.finish(&c, root, "unused_variadic_inputs", "unused-variadic-inputs", contract);
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = &.{entry} }));
    if (args.get("verify-root")) |before| {
        for ([_][]const u8{ "unused_variadic_inputs.ll", "unused_variadic_inputs_driver.c" }) |file| if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureMismatch;
        const rows = try u.json.array(try u.get(try c.load(try c.join(&.{ before, "native_canaries.json" })), "canaries"));
        var found = false;
        for (rows) |row| if (u.json.is(try u.get(row, "population"), "unused_variadic_inputs")) {
            if (found or !u.json.eql(row, entry)) return error.RegistryContractMismatch;
            found = true;
        };
        if (!found) return error.PopulationMissing;
    }
    try c.print("unused variadic inputs:108 cases/108 definitions/55296 observations per route{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
