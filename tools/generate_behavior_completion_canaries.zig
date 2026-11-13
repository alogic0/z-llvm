//! Generate six behavior-completion populations and independent C oracles.
//! Usage: zig run tools/generate_behavior_completion_canaries.zig -- --output-root NEW [--verify-root DIR]
const std = @import("std");
const u = @import("validation/common.zig");
const batch = "tools/templates";
const odd = @import("validation/behavior_odd_oracles.zig");
const header = "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\ndeclare void @llvm.memcpy.p0.p0.i64(ptr,ptr,i64,i1)\ndeclare void @llvm.memset.p0.i64(ptr,i8,i64,i1)\n";
const Output = struct {
    text: std.Io.Writer.Allocating,
    driver: std.Io.Writer.Allocating,
    table: std.Io.Writer.Allocating,
    functions: u.Value,
    count: usize = 0,
    fn init(c: *u.Context, name: []const u8, model: []const u8, seeds: usize, contract: []const u8, mask: ?[]const u8) !Output {
        var result: Output = .{ .text = .init(c.a), .driver = .init(c.a), .table = .init(c.a), .functions = u.array(c.a) };
        try result.text.writer.writeAll(header);
        try result.driver.writer.print("#define DRIVER_NAME \"{s}\"\n#define DRIVER_SEEDS {d}\n#define DRIVER_CONTRACT \"{s}\"\n", .{ name, seeds, contract });
        if (mask) |expression| try result.driver.writer.print("#define DRIVER_BYTE_MASK(j) {s}\n", .{expression});
        try result.driver.writer.writeAll(try c.read(batch ++ "/behavior_completion_core.h"));
        try result.driver.writer.writeAll(try c.read(try c.fmt("{s}/{s}", .{ batch, model })));
        try result.table.writer.writeAll("static const struct test_case cases[]={\n");
        return result;
    }
    fn function(out: *Output, c: *u.Context, name: []const u8) !void {
        try u.add(&out.functions, u.s(name));
        _ = c;
    }
    fn probe(out: *Output, c: *u.Context, name: []const u8, bits: usize, kind: usize, mutate: bool) !void {
        try out.function(c, name);
        try out.driver.writer.print("extern uint64_t {s}(void *,void *,const void *,uint64_t);\n", .{name});
        try out.table.writer.print("{{{s},{d},{d},{d}}},\n", .{ name, bits, kind, @intFromBool(mutate) });
        out.count += 1;
    }
    fn finish(out: *Output, c: *u.Context, fixtures: []const u8, name: []const u8, prefix: []const u8, seeds: usize, contract: []const u8, readonly: bool) !u.Value {
        try out.table.writer.writeAll("};\nint main(int argc,char **argv){");
        if (readonly) try out.table.writer.writeAll("if(!readonly_global_is_protected())return 1;");
        try out.table.writer.writeAll("return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
        try out.driver.writer.writeAll(out.table.written());
        try c.write(try c.join(&.{ fixtures, try c.fmt("{s}.ll", .{name}) }), out.text.written());
        try c.write(try c.join(&.{ fixtures, try c.fmt("{s}_driver.c", .{name}) }), out.driver.written());
        return u.toValue(c.a, .{ .population = name, .fixture = name, .prefix = prefix, .functions = out.functions, .observations = out.count * seeds * 8, .stdout = try c.fmt("{s} observations={d} {s}\n", .{ prefix, out.count * seeds * 8, contract }) });
    }
};
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const fixtures = try c.newOutput(try args.require("output-root"));
    var entries = u.array(c.a);
    try u.add(&entries, try odd.booleanChecked(&c, fixtures));
    try u.add(&entries, try odd.oddShift(&c, fixtures));
    try u.add(&entries, try closedVectors(&c, fixtures));
    try u.add(&entries, try memoryBitcasts(&c, fixtures));
    try u.add(&entries, try largeMemory(&c, fixtures));
    try u.add(&entries, try globals(&c, fixtures));
    try c.writeJson(try c.join(&.{ fixtures, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = entries }));
    if (args.get("verify-root")) |root| {
        const expected = try u.get(try c.load(try c.join(&.{ root, "native_canaries.json" })), "canaries");
        for (try u.json.array(entries)) |entry| {
            var found = false;
            for (try u.json.array(expected)) |candidate| if (u.json.is(try u.get(candidate, "population"), try u.str(entry, "population"))) {
                if (found or !u.json.eql(entry, candidate)) return error.RegistryContractMismatch;
                found = true;
            };
            if (!found) return error.RegistryPopulationMissing;
            for ([_][]const u8{ ".ll", "_driver.c" }) |suffix| {
                const name = try c.fmt("{s}{s}", .{ try u.str(entry, "fixture"), suffix });
                if (!std.mem.eql(u8, try c.digest(try c.join(&.{ fixtures, name })), try c.digest(try c.join(&.{ root, name })))) return error.GeneratedFixtureMismatch;
            }
        }
    }
    try c.print("behavior completion: six populations, twelve generated fixtures{s}\n", .{if (args.get("verify-root") != null) "; byte and registry verification passed" else ""});
}

fn closedVectors(c: *u.Context, fixtures: []const u8) !u.Value {
    const contract = "independent-byte-bit-counts=closed-fastcc-calls=packed-i4-i5=by-value-aliases=1024-alignment=call-clobbers=guard-pages=preserved";
    var out = try Output.init(c, "closed-vectors", "behavior_closed_vectors_model.c", 260, contract, null);
    try out.text.writer.writeAll("declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)\ndeclare i1 @llvm.vector.reduce.or.v64i1(<64 x i1>)\n");
    for ([_]usize{ 8, 16, 128 }, [_]usize{ 4, 5, 8 }) |bits, count_bits| {
        const compare = try c.fmt("closed.vector.compare.{d}", .{bits});
        try out.function(c, compare);
        try out.text.writer.print("define internal fastcc i64 @{0s}(ptr %out,<64 x i{1d}> %counts,<64 x i32> %expected) noinline {{\nentry:\n %wide = zext <64 x i{1d}> %counts to <64 x i32>\n store <64 x i32> %wide,ptr %out,align 1\n %different = icmp ne <64 x i32> %wide,%expected\n %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %different)\n %r = zext i1 %any to i64\n ret i64 %r\n}}\n", .{ compare, count_bits });
        for ([_][]const u8{ "cttz", "ctlz" }, 0..) |operation, kind| {
            try out.text.writer.print("declare <64 x i{0d}> @llvm.{1s}.v64i{0d}(<64 x i{0d}>,i1)\n", .{ bits, operation });
            for ([_]bool{ false, true }) |mutate| {
                const body = try c.fmt("closed.vector.body.{d}", .{out.count});
                const probe = try c.fmt("closed_vectors_probe_{d}", .{out.count});
                try out.function(c, body);
                try out.probe(c, probe, bits, kind, mutate);
                try out.text.writer.print("define internal fastcc i64 @{0s}(ptr %out,<64 x i{1d}> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {{\nentry:\n %local = alloca <64 x i{1d}>,align {2d}\n store <64 x i{1d}> %input,ptr %local,align {2d}\n", .{ body, bits, 64 * bits / 8 });
                if (mutate) try out.text.writer.print(" store <64 x i{0d}> zeroinitializer,ptr %source,align 1\n", .{bits});
                try out.text.writer.print(" %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n %round = load <64 x i{0d}>,ptr %local,align {1d}\n %counts = call <64 x i{0d}> @llvm.{2s}.v64i{0d}(<64 x i{0d}> %round,i1 0)\n %small = trunc <64 x i{0d}> %counts to <64 x i{3d}>\n %check = call fastcc i64 @{4s}(ptr %out,<64 x i{3d}> %small,<64 x i32> %expected)\n %payload = getelementptr i8,ptr %out,i64 256\n store <64 x i{0d}> %round,ptr %payload,align 1\n %bits = ptrtoint ptr %local to i64\n %low = and i64 %bits,{5d}\n %ap = getelementptr i8,ptr %out,i64 {6d}\n store i64 %low,ptr %ap,align 1\n %r = xor i64 %token,%check\n ret i64 %r\n}}\n", .{ bits, 64 * bits / 8, operation, count_bits, compare, 64 * bits / 8 - 1, 256 + 64 * bits / 8 });
                try out.text.writer.print("define i64 @{0s}(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {{\nentry:\n %input = load <64 x i{1d}>,ptr %source,align 1\n %expected = load <64 x i32>,ptr %expected_ptr,align 1\n %r = call fastcc i64 @{2s}(ptr %out,<64 x i{1d}> %input,<64 x i32> %expected,ptr %source,i64 %salt)\n ret i64 %r\n}}\n", .{ probe, bits, body });
            }
        }
    }
    if (out.count != 12) return error.ClosedVectorCasesChanged;
    return out.finish(c, fixtures, "closed_vectors", "closed-vectors", 260, contract, false);
}
fn memoryBitcasts(c: *u.Context, fixtures: []const u8) !u.Value {
    const contract = "dynamic-half-bitcasts=wide-ssa-snapshots=array-of-vectors=by-value-aliases=exact-stores=guard-pages=preserved";
    var out = try Output.init(c, "memory-bitcasts", "behavior_memory_bitcasts_model.c", 128, contract, null);
    for ([_]usize{ 256, 512 }) |bits| for ([_][]const u8{ "", "fastcc " }) |cc| for ([_]bool{ false, true }) |mutate| {
        const body = try c.fmt("memory.bitcast.body.{d}", .{out.count});
        const probe = try c.fmt("memory_bitcasts_probe_{d}", .{out.count});
        try out.function(c, body);
        try out.probe(c, probe, bits, 0, mutate);
        try out.text.writer.print("define internal {0s}i64 @{1s}(ptr %out,<{2d} x i8> %input,ptr %source,i64 %salt) noinline {{\nentry:\n %local = alloca [2 x <{3d} x i8>],align {3d}\n", .{ cc, body, bits / 8, bits / 16 });
        if (mutate) try out.text.writer.print(" store <{0d} x i8> zeroinitializer,ptr %source,align 1\n", .{bits / 8});
        try out.text.writer.print(" %wide = bitcast <{0d} x i8> %input to i{1d}\n %q = and i64 %salt,1\n %amount = mul i64 %q,{2d}\n %count = zext i64 %amount to i{1d}\n %shifted = lshr i{1d} %wide,%count\n %half = trunc i{1d} %shifted to i{2d}\n %vector = bitcast i{2d} %half to <{3d} x i8>\n %where = getelementptr [{3d} x i8],ptr %local,i64 %q\n store <{3d} x i8> %vector,ptr %where,align {3d}\n call void @llvm.memcpy.p0.p0.i64(ptr %out,ptr %where,i64 {3d},i1 0)\n %address = ptrtoint ptr %local to i64\n %low = and i64 %address,{4d}\n %ap = getelementptr i8,ptr %out,i64 {3d}\n store i64 %low,ptr %ap,align 1\n ret i64 %salt\n}}\ndefine i64 @{5s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n %input = load <{0d} x i8>,ptr %source,align 1\n %r = call {6s}i64 @{7s}(ptr %out,<{0d} x i8> %input,ptr %source,i64 %salt)\n ret i64 %r\n}}\n", .{ bits / 8, bits, bits / 2, bits / 16, bits / 16 - 1, probe, cc, body });
    };
    if (out.count != 8) return error.MemoryBitcastCasesChanged;
    return out.finish(c, fixtures, "memory_bitcasts", "memory-bitcasts", 128, contract, false);
}
fn largeMemory(c: *u.Context, fixtures: []const u8) !u.Value {
    const contract = "independent-byte-oracle=1025-to-65536-bits=canonical-tail-bits=load-snapshots=vector-one=8192-alignment=guard-pages=preserved";
    var out = try Output.init(c, "large-memory-bytes", "behavior_large_memory_model.c", 64, contract, null);
    for ([_]usize{ 1025, 2047, 4095, 65528, 65529, 65535, 65536 }) |bits| for ([_]bool{ false, true }) |mutate| {
        const probe = try c.fmt("large_memory_probe_{d}", .{out.count});
        try out.probe(c, probe, bits, 0, mutate);
        try out.text.writer.print("define i64 @{0s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n", .{probe});
        if (bits == 65536) try out.text.writer.writeAll(" %local = alloca i65536,align 8192\n") else try out.text.writer.print(" %local = alloca <1 x i{d}>,align 8192\n", .{bits});
        try out.text.writer.print(" %old = load i{d},ptr %source,align 1\n", .{bits});
        if (mutate) try out.text.writer.print(" store i{d} 0,ptr %source,align 1\n", .{bits});
        if (bits == 65536) try out.text.writer.writeAll(" store i65536 %old,ptr %local,align 1\n %round = load i65536,ptr %local,align 1\n %same = icmp eq i65536 %round,%old\n") else {
            try out.text.writer.print(" %vector = insertelement <1 x i{0d}> poison,i{0d} %old,i32 0\n store <1 x i{0d}> %vector,ptr %local,align 1\n %loaded = load <1 x i{0d}>,ptr %local,align 1\n %round = extractelement <1 x i{0d}> %loaded,i32 0\n %extended = zext i{0d} %old to i65536\n %back = trunc nuw i65536 %extended to i{0d}\n %same = icmp eq i{0d} %round,%back\n", .{bits});
        }
        try out.text.writer.print(" store i{0d} %round,ptr %out,align 1\n %ones = icmp eq i{0d} %old,-1\n %mismatch = xor i1 %same,true\n %bad = zext i1 %mismatch to i64\n %bad2 = shl i64 %bad,1\n %isones = zext i1 %ones to i64\n %flags = or i64 %bad2,%isones\n %r = xor i64 %salt,%flags\n %address = ptrtoint ptr %local to i64\n %low = and i64 %address,8191\n %ap = getelementptr i8,ptr %out,i64 {1d}\n store i64 %low,ptr %ap,align 1\n ret i64 %r\n}}\n", .{ bits, (bits + 7) / 8 });
    };
    if (out.count != 14) return error.LargeMemoryCasesChanged;
    return out.finish(c, fixtures, "large_memory_bytes", "large-memory-bytes", 64, contract, false);
}
fn globals(c: *u.Context, fixtures: []const u8) !u.Value {
    const contract = "independent-defined-bytes=packed-integer-vectors=nested-layout=quoted-braces=owned-sections=readonly-write-fault=guard-pages=preserved";
    const mask = "(((j)>=9&&(j)<24)||((j)>=36&&(j)<40)||((j)>=52&&(j)<56)||((j)>=57&&(j)<72)||(j)==76?0:(j)==72?15:(j)==75?15:255)";
    var out = try Output.init(c, "integer-global-data", "behavior_integer_globals_model.c", 64, contract, mask);
    try out.text.writer.writeAll("@pair = internal constant <2 x i32> <i32 287454020,i32 -1>\n@nested = internal constant {i8,[2 x <3 x i32>],i8} {i8 7,[2 x <3 x i32>] [<3 x i32> <i32 1,i32 2,i32 3>,<3 x i32> <i32 4,i32 5,i32 6>],i8 9},section \".rodata\",align 16\n@mask = internal constant <4 x i1> <i1 true,i1 false,i1 true,i1 true>\n@packed = internal constant <4 x i5> <i5 1,i5 2,i5 3,i5 4>\n@left = internal constant {[3 x i8],i8} {[3 x i8] c\"{,X\",i8 7}\n@right = internal constant {[3 x i8],i8} {[3 x i8] c\"},Y\",i8 9}\n@writable = internal global i32 123,section \".data\",align 4\n@readonly = internal constant i32 456,section \".rodata\",align 4\n@ro_pointer = internal constant ptr @pair,section \".rodata\",align 8\n@counter = internal global i64 0,section \".data\",align 8\n");
    const probe = "integer_globals_probe";
    try out.probe(c, probe, 0, 0, false);
    try out.function(c, "integer_globals_readonly");
    try out.text.writer.writeAll("define ptr @integer_globals_readonly() {\nentry:\n ret ptr @nested\n}\ndefine i64 @integer_globals_probe(ptr %out,ptr %unused,ptr %other,i64 %salt) {\nentry:\n %first = load ptr,ptr @ro_pointer,align 8\n");
    var offset: usize = 0;
    for ([_][]const u8{ "pair", "nested", "mask", "packed", "left", "right", "writable", "readonly" }, [_]usize{ 8, 64, 1, 4, 4, 4, 4, 4 }, 0..) |name, size, index| {
        try out.text.writer.print(" %p{0d} = getelementptr i8,ptr %out,i64 {1d}\n call void @llvm.memcpy.p0.p0.i64(ptr %p{0d},ptr {2s}{3s},i64 {4d},i1 0)\n", .{ index, offset, if (index == 0) "%" else "@", if (index == 0) "first" else name, size });
        offset += size;
    }
    if (offset != 93) return error.GlobalByteExtentChanged;
    try out.text.writer.writeAll(" %old = load i64,ptr @counter,align 8\n store i64 %salt,ptr @counter,align 8\n %r = xor i64 %old,%salt\n ret i64 %r\n}\n");
    return out.finish(c, fixtures, "integer_global_data", "integer-global-data", 64, contract, true);
}
