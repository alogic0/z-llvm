//! Deterministically generate fifteen behavior-frontier native populations.
//! --output-root NEW; optional --verify-root DIR checks fixtures and registry.
const std = @import("std");
const u = @import("validation/common.zig");
const operations = [_][]const u8{ "trunc", "round", "ceil", "floor", "log10", "log2", "log", "exp2", "exp", "tan", "cos", "sin", "sqrt", "fma" };
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const target = try c.newOutput(try args.require("output-root"));
    var entries = u.array(c.a);
    try u.add(&entries, try wideSwitch(&c, target));
    try u.add(&entries, try floatingLanes(&c, target));
    try u.add(&entries, try smallFloatingAbi(&c, target));
    for ([_]u16{ 2, 4, 8, 16, 3 }) |layout| try u.add(&entries, try promotedIntegerAbi(&c, target, layout));
    try u.add(&entries, try scalarMinimum(&c, target));
    try u.add(&entries, try volatileAbsolute(&c, target));
    try u.add(&entries, try constantPairs(&c, target));
    try u.add(&entries, try pairSaturation(&c, target));
    try u.add(&entries, try floatingLiterals(&c, target));
    try u.add(&entries, try pairVectorSaturation(&c, target));
    try u.add(&entries, try pairLiteralExtrema(&c, target));
    if (entries.array.items.len != 15) return error.ExpectedFifteenPopulations;
    try c.writeJson(try c.join(&.{ target, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = entries }));
    var files = std.StringHashMap(void).init(c.a);
    for (entries.array.items) |entry| {
        for ([_][]const u8{ ".ll", "_driver.c" }) |suffix| try files.put(try c.fmt("{s}{s}", .{ try u.str(entry, "fixture"), suffix }), {});
        if (entry.object.get("reference_fixture")) |reference| try files.put(try c.fmt("{s}.ll", .{reference.string}), {});
        if (entry.object.get("reference_source")) |source| try files.put(source.string, {});
    }
    if (files.count() != 31) return error.ExpectedThirtyOneFixtureFiles;
    if (args.get("verify-root")) |root| {
        var names = files.keyIterator();
        while (names.next()) |name| if (!std.mem.eql(u8, try c.digest(try c.join(&.{ target, name.* })), try c.digest(try c.join(&.{ root, name.* })))) return c.fail("generated fixture differs: {s}", .{name.*});
        const registry = try u.json.array(try u.get(try c.load(try c.join(&.{ root, "native_canaries.json" })), "canaries"));
        for (entries.array.items) |entry| {
            var matches: usize = 0;
            for (registry) |candidate| if (u.json.eql(try u.get(candidate, "population"), try u.get(entry, "population"))) {
                if (!u.json.eql(entry, candidate)) return error.GeneratedPopulationDiffers;
                matches += 1;
            };
            if (matches != 1) return error.GeneratedPopulationMissingOrDuplicated;
        }
    }
    try c.print("behavior-expansion fixtures: 15 populations, 31 files{s}\n", .{if (args.get("verify-root") != null) ", byte-exact verification passed" else ""});
}
fn wideSwitch(c: *u.Context, target: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\n#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <sys/mman.h>\n#include <unistd.h>\ntypedef uint64_t (*kernel)(const void *,void *,uint64_t);\n");
    var functions = u.array(c.a);
    const widths = [_]u16{ 129, 140, 200, 257, 500, 512 };
    for (widths) |bits| {
        const minimum = @as(u512, 1) << @as(u9, @intCast(bits - 1));
        const maximum = minimum - 1;
        const name = try c.fmt("wide_switch_{d}", .{bits});
        const body = try c.fmt("wide_switch_body_{d}", .{bits});
        try u.add(&functions, u.s(name));
        try u.add(&functions, u.s(body));
        try text.writer.print("define fastcc i64 @{s}(i64 %seed,i{d} %x,i64 %salt) noinline {{\nentry:\n switch i{d} %x,label %other [ i{d} -125,label %negative\n i{d} 125,label %positive\n i{d} {d},label %minimum\n i{d} {d},label %maximum ]\nnegative:\n br label %join\npositive:\n br label %join\nminimum:\n br label %join\nmaximum:\n br label %join\nother:\n br label %join\njoin:\n %tag = phi i64 [1,%negative],[2,%positive],[3,%minimum],[4,%maximum],[5,%other]\n %added = add i64 %tag,%seed\n %r = xor i64 %added,%salt\n ret i64 %r\n}}\n", .{ body, bits, bits, bits, bits, bits, minimum, bits, maximum });
        try text.writer.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n %x = load i{d},ptr %input,align 1\n %seed = load i64,ptr %input,align 1\n %r = call fastcc i64 @{s}(i64 %seed,i{d} %x,i64 %salt)\n store i64 %r,ptr %out,align 1\n %out1 = getelementptr i8,ptr %out,i64 8\n store i64 %salt,ptr %out1,align 1\n %out2 = getelementptr i8,ptr %out,i64 16\n store i64 %seed,ptr %out2,align 1\n %live = add i64 %seed,%salt\n %answer = xor i64 %r,%live\n ret i64 %answer\n}}\n", .{ name, bits, body, bits });
        try driver.writer.print("extern uint64_t {s}(const void *,void *,uint64_t);\n", .{name});
    }
    try driver.writer.writeAll("static const struct {unsigned bits;kernel run;} cases[]={");
    for (widths) |bits| try driver.writer.print("{{{d},wide_switch_{d}}},", .{ bits, bits });
    try driver.writer.writeAll(
        \\};
        \\int main(int argc,char **argv){unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0;size_t page=(size_t)sysconf(_SC_PAGESIZE);unsigned char *map=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_READ|PROT_WRITE))return 2;
        \\#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"wide-switch bits=%u pattern=%u seed=%u observation=%zu fault=%u\n",bits,pattern,seed,observations,fault);return 1;}}while(0)
        \\for(unsigned which=0;which<sizeof cases/sizeof cases[0];which++){unsigned bits=cases[which].bits,n=(bits+7)/8;unsigned char mask=bits%8?(1u<<(bits%8))-1:255;unsigned char keys[4][64]={{0}};memset(keys[0],255,n);keys[0][0]=131;keys[1][0]=125;keys[2][(bits-1)/8]=1u<<((bits-1)%8);memset(keys[3],255,n);keys[3][(bits-1)/8]&=~(1u<<((bits-1)%8));for(unsigned key=0;key<4;key++)keys[key][n-1]&=mask;
        \\for(unsigned pattern=0;pattern<16;pattern++)for(unsigned seed=0;seed<64;seed++){unsigned char *input=map+2*page-n,saved[64],normal[64];if(pattern<4)memcpy(input,keys[pattern],n);else for(unsigned i=0;i<n;i++)input[i]=(unsigned char)((seed*73+i*131)^(pattern*19+255));if(pattern==4)memset(input,0,n);if(pattern==5)memset(input,255,n);input[n-1]=(input[n-1]&mask)|((seed*41)&~mask);memcpy(saved,input,n);memcpy(normal,input,n);normal[n-1]&=mask;uint64_t tag=5;for(unsigned key=0;key<4;key++)if(memcmp(normal,keys[key],n)==0)tag=key+1;uint64_t value;memcpy(&value,input,8);uint64_t salt=UINT64_C(0x8123456789abcdef)^(seed*113+pattern);struct {uint64_t pre,data[3],post;} out;memset(&out,0xa5,sizeof out);uint64_t returned=cases[which].run(input,out.data,salt);if(fault==1)out.data[0]^=1;if(fault==2)out.data[1]^=1;if(fault==3)out.post^=1;uint64_t expected=(tag+value)^salt;CHECK(returned==(expected^(value+salt)));CHECK(out.data[0]==expected);CHECK(out.data[1]==salt);CHECK(out.data[2]==value);CHECK(out.pre==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(out.post==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(memcmp(input,saved,n)==0);}}
        \\printf("wide-switch observations=%zu exact-limbs=cfg-phi-edges=stack-arguments=dirty-tail-bits=live-values=guard-pages=preserved\n",observations);return munmap(map,page*3)!=0;}
        \\
    );
    try c.write(try c.join(&.{ target, "wide_switch.ll" }), text.written());
    try c.write(try c.join(&.{ target, "wide_switch_driver.c" }), driver.written());
    return u.toValue(c.a, .{ .population = "wide_switch", .fixture = "wide_switch", .prefix = "wide-switch", .functions = functions, .observations = 43008, .stdout = "wide-switch observations=43008 exact-limbs=cfg-phi-edges=stack-arguments=dirty-tail-bits=live-values=guard-pages=preserved\n" });
}
fn floatingLanes(c: *u.Context, target: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    var functions = u.array(c.a);
    for ([_][]const u8{ "half", "float", "double", "x86_fp80", "fp128" }, [_]u16{ 16, 32, 64, 80, 128 }) |ty, bits| for ([_]u32{ 1, 2, 3, 4 }) |count| for (operations) |op| {
        const fma = std.mem.eql(u8, op, "fma");
        const name = try c.fmt("floating_lane_{d}_{d}_{s}", .{ bits, count, op });
        try u.add(&functions, u.s(name));
        try text.writer.print("declare <{0d} x {1s}> @llvm.{2s}.v{0d}f{3d}(<{0d} x {1s}>{5s})\ndefine i64 @{4s}(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {{\nentry:\n %a = load <{0d} x {1s}>,ptr %ap,align 1\n %b = load <{0d} x {1s}>,ptr %bp,align 1\n %c = load <{0d} x {1s}>,ptr %cp,align 1\n %r = call <{0d} x {1s}> @llvm.{2s}.v{0d}f{3d}(<{0d} x {1s}> %a{6s})\n store <{0d} x {1s}> %r,ptr %out,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{
            count,                                                                      ty,                                                                               op, bits, name,
            if (fma) try c.fmt(",<{0d} x {1s}>,<{0d} x {1s}>", .{ count, ty }) else "", if (fma) try c.fmt(",<{0d} x {1s}> %b,<{0d} x {1s}> %c", .{ count, ty }) else "",
        });
    };
    try c.write(try c.join(&.{ target, "floating_lanes.ll" }), text.written());
    try c.copy(try c.join(&.{"tools/templates/behavior_floatingLanes_core.c"}), try c.join(&.{ target, "floating_lanes_driver.c" }));
    return u.toValue(c.a, .{ .population = "floating_lanes", .fixture = "floating_lanes", .prefix = "floating-lanes", .functions = functions, .libraries = .{"m"}, .observations = 71680, .stdout = "floating-lanes observations=71680 all-five-formats=unary-math=fused-multiply-add=exact-tails=live-values=guard-pages=preserved\n" });
}
fn smallFloatingAbi(c: *u.Context, target: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_smallFloatingAbi_core.c"})));
    try table.writer.writeAll("static const struct abi_case cases[]={\n");
    var functions = u.array(c.a);
    for ([_][]const u8{ "half", "half", "half", "half", "float", "float", "double", "float" }, [_]u16{ 16, 16, 16, 16, 32, 32, 64, 32 }, [_]u16{ 1, 2, 4, 8, 1, 3, 1, 2 }) |ty, bits, n| for ([_]bool{ false, true }) |fast| {
        const cc = if (fast) "fastcc " else "";
        const label = if (fast) "fast" else "c";
        const body = try c.fmt("small_fp_body_{d}_{d}_{s}", .{ n, bits, label });
        const provider = try c.fmt("small_fp_provider_{d}_{d}_{s}", .{ n, bits, label });
        const probe = try c.fmt("small_fp_probe_{d}_{d}_{s}", .{ n, bits, label });
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("define {0s}<{1d} x {2s}> @{3s}(<{1d} x {2s}> %a,<{1d} x {2s}> %b) noinline {{\nentry:\n %r = shufflevector <{1d} x {2s}> %a,<{1d} x {2s}> %b,<{1d} x i32> <", .{ cc, n, ty, body });
        for (0..n) |i| {
            if (i != 0) try text.writer.writeAll(",");
            try text.writer.print("i32 {d}", .{(if (i % 2 == 0) @as(usize, n) else 0) + n - 1 - i});
        }
        try text.writer.print(">\n ret <{0d} x {1s}> %r\n}}\ndeclare {2s}<{0d} x {1s}> @{3s}(<{0d} x {1s}>,<{0d} x {1s}>)\ndefine i64 @{4s}(ptr %out,ptr %ap,ptr %bp,i64 %salt) {{\nentry:\n %a = load <{0d} x {1s}>,ptr %ap,align 1\n %b = load <{0d} x {1s}>,ptr %bp,align 1\n %local = call {2s}<{0d} x {1s}> @{5s}(<{0d} x {1s}> %a,<{0d} x {1s}> %b)\n %external = call {2s}<{0d} x {1s}> @{3s}(<{0d} x {1s}> %a,<{0d} x {1s}> %b)\n store <{0d} x {1s}> %local,ptr %out,align 1\n %out1 = getelementptr i8,ptr %out,i64 16\n store <{0d} x {1s}> %external,ptr %out1,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ n, ty, cc, provider, probe, body });
        try driver.writer.print("extern v128 {s}(v128,v128);\nextern uint64_t {s}(void *,const void *,const void *,uint64_t);\nv128 {s}(v128 x,v128 y){{return raw_model(x,y,{d},{d});}}\n", .{ body, probe, provider, n, bits });
        try table.writer.print("{{{d},{d},{s},{s}}},\n", .{ n, bits, probe, body });
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ target, "small_fp_vector_abi.ll" }), text.written());
    try c.write(try c.join(&.{ target, "small_fp_vector_abi_driver.c" }), driver.written());
    return u.toValue(c.a, .{ .population = "small_fp_vector_abi", .fixture = "small_fp_vector_abi", .prefix = "small-fp-vector-abi", .functions = functions, .observations = 10240, .stdout = "small-fp-vector-abi observations=10240 llvm-c-local-interop=ccc-fastcc=raw-payloads=exact-stores=guard-pages=preserved\n" });
}
fn promotedIntegerAbi(c: *u.Context, target: []const u8, selected: u16) !u.Value {
    if (selected != 2 and selected != 3 and selected != 4 and selected != 8 and selected != 16) return error.UnsupportedLayout;

    var shapes: std.ArrayList([2]u16) = .empty;
    for ([_]u16{ 2, 4, 8, 16 }) |n| for (1..128 / n) |bits| {
        if (n != selected) continue;
        if (bits == 8 or bits == 16 or bits == 32 or bits == 51 or bits == 52 or bits == 64) continue;
        try shapes.append(c.a, .{ n, @intCast(bits) });
    };
    if (selected == 3) try shapes.append(c.a, .{ 3, 32 });
    const expected: usize = switch (selected) {
        2 => 58,
        4 => 29,
        8 => 14,
        16 => 7,
        3 => 1,
        else => unreachable,
    };
    if (shapes.items.len != expected) return error.ExpectedBoundedShapes;
    const fixture = try c.fmt("promoted_vector_abi_{d}", .{selected});
    const prefix = try c.fmt("promoted-vector-abi-{d}", .{selected});
    const observations = shapes.items.len * 2 * 64 * 10;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    const oracle = try c.read(try c.join(&.{"tools/templates/behavior_promotedIntegerAbi_core.c"}));
    const bounded = try std.mem.replaceOwned(u8, c.a, oracle, "count!=218||observations!=139520", try c.fmt("count!={d}||observations!={d}", .{ expected * 2, observations }));
    try driver.writer.writeAll(bounded);
    try table.writer.writeAll("static const struct abi_case cases[]={\n");
    var functions = u.array(c.a);
    for (shapes.items) |shape| for ([_]bool{ false, true }) |fast| {
        const n = shape[0];
        const bits = shape[1];
        const convention = if (fast) "fastcc " else "";
        const label = if (fast) "fast" else "c";
        const body = try c.fmt("promoted_body_{d}_{d}_{s}", .{ n, bits, label });
        const probe = try c.fmt("promoted_probe_{d}_{d}_{s}", .{ n, bits, label });
        const provider = try c.fmt("promoted_provider_{d}_{d}_{s}", .{ n, bits, label });
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("define {2s}<{0d} x i{1d}> @{3s}(<{0d} x i{1d}> %a,<{0d} x i{1d}> %b) noinline {{\nentry:\n %r = add <{0d} x i{1d}> %a,%b\n ret <{0d} x i{1d}> %r\n}}\ndeclare {2s}<{0d} x i{1d}> @{4s}(<{0d} x i{1d}>,<{0d} x i{1d}>)\ndefine i64 @{5s}(ptr %out,ptr %ap,ptr %bp,i64 %salt) {{\nentry:\n %a = load <{0d} x i{1d}>,ptr %ap,align 1\n %b = load <{0d} x i{1d}>,ptr %bp,align 1\n %local = call {2s}<{0d} x i{1d}> @{3s}(<{0d} x i{1d}> %a,<{0d} x i{1d}> %b)\n %external = call {2s}<{0d} x i{1d}> @{4s}(<{0d} x i{1d}> %a,<{0d} x i{1d}> %b)\n store <{0d} x i{1d}> %local,ptr %out,align 1\n %out1 = getelementptr i8,ptr %out,i64 16\n store <{0d} x i{1d}> %external,ptr %out1,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ n, bits, convention, body, provider, probe });
        try driver.writer.print("extern v128 {s}(v128,v128);\nextern uint64_t {s}(void *,const void *,const void *,uint64_t);\nv128 {s}(v128 x,v128 y){{return raw_model(x,y,{d},{d});}}\n", .{ body, probe, provider, n, bits });
        try table.writer.print("{{{d},{d},{s},{s}}},\n", .{ n, bits, probe, body });
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ target, try c.fmt("{s}.ll", .{fixture}) }), text.written());
    try c.write(try c.join(&.{ target, try c.fmt("{s}_driver.c", .{fixture}) }), driver.written());
    return u.toValue(c.a, .{ .population = fixture, .fixture = fixture, .prefix = prefix, .functions = functions, .observations = observations, .stdout = try c.fmt("promoted-vector-abi observations={d} llvm-c-local-interop=ccc-fastcc=expanded-cells=dirty-bits=exact-stores=guard-pages=preserved\n", .{observations}) });
}
fn scalarMinimum(c: *u.Context, target: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    var functions = u.array(c.a);
    for ([_][]const u8{ "half", "float", "double", "x86_fp80", "fp128" }, [_]u16{ 16, 32, 64, 80, 128 }) |ty, bits| {
        try text.writer.print("declare {0s} @llvm.minnum.f{1d}({0s},{0s})\ndeclare {0s} @llvm.maxnum.f{1d}({0s},{0s})\n", .{ ty, bits });
        for ([_]u32{ 2, 3, 4 }) |count| {
            const minimum = try c.fmt("floating_minmax_{d}_{d}_min", .{ bits, count });
            const maximum = try c.fmt("floating_minmax_{d}_{d}_max", .{ bits, count });
            try u.add(&functions, u.s(minimum));
            try u.add(&functions, u.s(maximum));
            try text.writer.print("define i64 @{s}(ptr %out,ptr %in,i64 %salt) {{\nentry:\n", .{minimum});
            for (0..count) |i| try text.writer.print(" %p{0d} = getelementptr i8,ptr %in,i64 {1d}\n %v{0d} = load {2s},ptr %p{0d},align 1\n", .{ i, i * (bits / 8), ty });
            try text.writer.print(" %r1 = call {0s} @llvm.minnum.f{1d}({0s} %v0,{0s} %v1)\n", .{ ty, bits });
            for (2..count) |i| try text.writer.print(" %r{0d} = call {1s} @llvm.minnum.f{2d}({1s} %r{3d},{1s} %v{0d})\n", .{ i, ty, bits, i - 1 });
            try text.writer.print(" store {0s} %r{1d},ptr %out,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ ty, count - 1 });
            try text.writer.print("declare {0s} @llvm.vector.reduce.fmax.v{1d}f{2d}(<{1d} x {0s}>)\ndefine i64 @{3s}(ptr %out,ptr %in,i64 %salt) {{\nentry:\n %v = load <{1d} x {0s}>,ptr %in,align 1\n %r = call {0s} @llvm.vector.reduce.fmax.v{1d}f{2d}(<{1d} x {0s}> %v)\n store {0s} %r,ptr %out,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ ty, count, bits, maximum });
        }
    }
    try c.write(try c.join(&.{ target, "scalar_minimum.ll" }), text.written());
    try c.copy("test/real_programs/floating_minmax_mixed_zeros_driver.c", try c.join(&.{ target, "scalar_minimum_driver.c" }));
    try c.copy("test/real_programs/floating_minmax_zero_reference.ll", try c.join(&.{ target, "scalar_minimum_zero_reference.ll" }));
    return u.toValue(c.a, .{ .population = "scalar_minimum", .fixture = "scalar_minimum", .prefix = "scalar-minimum", .reference_fixture = "scalar_minimum_zero_reference", .reference_source = "scalar_minimum_driver.c", .functions = functions, .libraries = .{"m"}, .observations = 11520, .stdout = "floating-minmax observations=11520 all-five-formats=pinned-nan-contract=signed-zeros=exact-tails=guard-pages=preserved\n" });
}
fn volatileAbsolute(c: *u.Context, target: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_volatileAbsolute_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var functions = u.array(c.a);
    for ([_][]const u8{ "i8", "i16", "i32", "i64", "ptr" }, [_]u16{ 8, 16, 32, 64, 64 }, 0..) |ty, bits, shape| for ([_]bool{ false, true }) |literal| {
        const name = try c.fmt("volatile_absolute_{d}_{s}", .{ shape, if (literal) "literal" else "value" });
        const address: u64 = @as(u64, 0x520000002000) - bits / 8;
        try u.add(&functions, u.s(name));
        try text.writer.print("define i64 @{s}(i64 %value,i64 %salt) {{\nentry:\n", .{name});
        if (shape == 4) try text.writer.writeAll(" %input = inttoptr i64 %value to ptr\n") else if (bits < 64) try text.writer.print(" %input = trunc i64 %value to {s}\n", .{ty}) else try text.writer.writeAll(" %input = add i64 %value,0\n");
        const stored = if (literal) (if (shape == 4) "inttoptr (i64 88 to ptr)" else "88") else "%input";
        try text.writer.print(" %a = load volatile {0s},ptr inttoptr (i64 {1d} to ptr),align 1\n store volatile {0s} {2s},ptr inttoptr (i64 {1d} to ptr),align 1\n %b = load volatile {0s},ptr inttoptr (i64 {1d} to ptr),align 1\n", .{ ty, address, stored });
        for ([_][]const u8{ "a", "b" }) |v| {
            if (shape == 4) try text.writer.print(" %wide_{s} = ptrtoint ptr %{s} to i64\n", .{ v, v }) else if (bits < 64) try text.writer.print(" %wide_{s} = zext {s} %{s} to i64\n", .{ v, ty, v }) else try text.writer.print(" %wide_{s} = add i64 %{s},0\n", .{ v, v });
        }
        try text.writer.writeAll(" %pair = xor i64 %wide_a,%wide_b\n %r = xor i64 %pair,%salt\n ret i64 %r\n}\n");
        try driver.writer.print("extern uint64_t {s}(uint64_t,uint64_t);\n", .{name});
        try table.writer.print("{{{d},{d},{s}}},\n", .{ bits / 8, @intFromBool(literal), name });
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ target, "volatile_absolute.ll" }), text.written());
    try c.write(try c.join(&.{ target, "volatile_absolute_driver.c" }), driver.written());
    return u.toValue(c.a, .{ .population = "volatile_absolute", .fixture = "volatile_absolute", .prefix = "volatile-absolute", .functions = functions, .observations = 1920, .stdout = "volatile-absolute observations=1920 native-widths=constant-addresses=exact-events=guard-pages=preserved\n" });
}
fn constantPairs(c: *u.Context, target: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_constantPairs_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var functions = u.array(c.a);
    for ([_]u16{ 1, 3, 8, 17, 32, 64 }) |bits| for ([_][]const u8{ "add", "sub", "mul", "and", "or", "xor", "shl", "lshr", "ashr", "udiv", "urem" }, 0..) |op, kind| {
        const name = try c.fmt("constant_pairs_{d}_{s}", .{ bits, op });
        const mask: u64 = if (bits == 64) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
        try u.add(&functions, u.s(name));
        try text.writer.print("define i64 @{s}(ptr %out,i64 %salt) {{\nentry:\n", .{name});
        for (0..4) |sample| {
            const x = ([_]u64{ 0, 1, mask, @as(u64, 1) << @as(u6, @intCast(bits - 1)) })[sample];
            const y = if (kind >= 6 and kind <= 8) ([_]u64{ 0, if (bits > 1) 1 else 0, bits - 1, bits / 2 })[sample] else if (kind >= 9) ([_]u64{ 1, 1, mask, 1 })[sample] else ([_]u64{ mask, mask, 1, 1 })[sample];
            try text.writer.print(" %value{0d} = {1s} i{2d} {3d},{4d}\n", .{ sample, op, bits, x, y });
            if (bits == 64) try text.writer.print(" %wide{0d} = add i64 %value{0d},0\n", .{sample}) else try text.writer.print(" %wide{0d} = zext i{1d} %value{0d} to i64\n", .{ sample, bits });
            try text.writer.print(" %mix{0d} = xor i64 %wide{0d},%salt\n %ptr{0d} = getelementptr i8,ptr %out,i64 {1d}\n store i64 %mix{0d},ptr %ptr{0d},align 1\n", .{ sample, sample * 8 });
        }
        try text.writer.writeAll(" %live = xor i64 %salt,90\n ret i64 %live\n}\n");
        try driver.writer.print("extern uint64_t {s}(void *,uint64_t);\n", .{name});
        try table.writer.print("{{{d},{d},{s}}},\n", .{ bits, kind, name });
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ target, "integer_constant_pairs.ll" }), text.written());
    try c.write(try c.join(&.{ target, "integer_constant_pairs_driver.c" }), driver.written());
    return u.toValue(c.a, .{ .population = "integer_constant_pairs", .fixture = "integer_constant_pairs", .prefix = "integer-constant-pairs", .functions = functions, .observations = 29568, .stdout = "integer-constant-pairs observations=29568 defined-literal-operations=modular-widths=live-values=exact-stores=preserved\n" });
}
fn pairSaturation(c: *u.Context, target: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_pairSaturation_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var functions = u.array(c.a);
    for ([_][]const u8{ "uadd.sat", "usub.sat", "sadd.sat", "ssub.sat", "umin", "umax", "smin", "smax" }, 0..) |op, id| {
        const body = try c.fmt("pair_saturation_body_{d}", .{id});
        const provider = try c.fmt("pair_saturation_provider_{d}", .{id});
        const probe = try c.fmt("pair_saturation_probe_{d}", .{id});
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("declare i128 @llvm.{0s}.i128(i128,i128)\ndefine i128 @{1s}(i128 %a,i128 %b) noinline {{\nentry:\n %r = call i128 @llvm.{0s}.i128(i128 %a,i128 %b)\n ret i128 %r\n}}\ndeclare i128 @{2s}(i128,i128)\ndefine i64 @{3s}(ptr %out,ptr %ap,ptr %bp,i64 %salt) {{\nentry:\n %a = load i128,ptr %ap,align 1\n %b = load i128,ptr %bp,align 1\n %local = call i128 @{1s}(i128 %a,i128 %b)\n %external = call i128 @{2s}(i128 %a,i128 %b)\n store i128 %local,ptr %out,align 1\n %out1 = getelementptr i8,ptr %out,i64 16\n store i128 %external,ptr %out1,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ op, body, provider, probe });
        try driver.writer.print("extern u128 {s}(u128,u128);\nextern uint64_t {s}(void *,const void *,const void *,uint64_t);\nu128 {s}(u128 a,u128 b){{return model(a,b,{d});}}\n", .{ body, probe, provider, id });
        try table.writer.print("{{{d},{s},{s}}},\n", .{ id, body, probe });
    }
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ target, "pair_saturation.ll" }), text.written());
    try c.write(try c.join(&.{ target, "pair_saturation_driver.c" }), driver.written());
    return u.toValue(c.a, .{ .population = "pair_saturation", .fixture = "pair_saturation", .prefix = "pair-saturation", .functions = functions, .observations = 16384, .stdout = "pair-saturation observations=16384 signed-unsigned-clamps=extrema=llvm-c-local-interop=exact-stores=guard-pages=preserved\n" });
}
fn floatingLiterals(c: *u.Context, target: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_floatingLiterals_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var functions = u.array(c.a);
    for ([_][]const u8{ "half", "float", "double" }, [_][]const u8{ "_Float16", "float", "double" }, [_][]const u8{ "h", "f", "d" }, [_]u16{ 16, 32, 64 }) |ty, cty, field, bits| {
        const literals = if (bits == 16) [_][]const u8{ "0xH0000", "0xH8000", "0xH0001", "0xH7C00", "0xH7C01", "0xH7E23", "0xH3555" } else if (bits == 32) [_][]const u8{ "0.000000e+00", "-0.000000e+00", "0x36A0000000000000", "0x7FF0000000000000", "0x7FF0000020000000", "0x7FF8002460000000", "0x3FD5555560000000" } else [_][]const u8{ "0x0000000000000000", "0x8000000000000000", "0x0000000000000001", "0x7FF0000000000000", "0x7FF0000000000001", "0x7FF8000000000123", "0x3FD5555555555555" };
        for (literals, 0..) |literal, index| for ([_]bool{ false, true }) |fast| {
            const cc = if (fast) "fastcc " else "";
            const label = if (fast) "fast" else "c";
            const body = try c.fmt("fp_literal_body_{d}_{d}_{s}", .{ bits, index, label });
            const provider = try c.fmt("fp_literal_provider_{d}_{d}_{s}", .{ bits, index, label });
            const probe = try c.fmt("fp_literal_probe_{d}_{d}_{s}", .{ bits, index, label });
            try u.add(&functions, u.s(body));
            try u.add(&functions, u.s(probe));
            try text.writer.print("define {0s}{1s} @{2s}(i1 %choice,i64 %salt,ptr %effect) noinline {{\nentry:\n store volatile i64 %salt,ptr %effect,align 1\n br i1 %choice,label %yes,label %no\nyes:\n ret {1s} {3s}\nno:\n ret {1s} {4s}\n}}\ndeclare {1s} @{5s}(i1)\ndefine i64 @{6s}(ptr %out,ptr %effect,i64 %choice,i64 %salt) {{\nentry:\n %take = trunc i64 %choice to i1\n %local = call {0s}{1s} @{2s}(i1 %take,i64 %salt,ptr %effect)\n %external = call {1s} @{5s}(i1 %take)\n store {1s} %local,ptr %out,align 1\n %out1 = getelementptr i8,ptr %out,i64 16\n store {1s} %external,ptr %out1,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ cc, ty, body, literal, literals[1], provider, probe });
            try driver.writer.print("extern {0s} {1s}(uint32_t,uint64_t,void *);\nextern uint64_t {2s}(void *,void *,uint64_t,uint64_t);\n{0s} {3s}(uint32_t choice){{uint64_t bits=payload({4d},(choice&1)?{5d}:1);{0s} result;memcpy(&result,&bits,sizeof result);return result;}}\n", .{ cty, body, probe, provider, bits, index });
            try table.writer.print("{{{d},{d},{{.{s}={s}}},{s}}},\n", .{ bits, index, field, body, probe });
        };
    }
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ target, "native_fp_literals.ll" }), text.written());
    try c.write(try c.join(&.{ target, "native_fp_literals_driver.c" }), driver.written());
    return u.toValue(c.a, .{ .population = "native_fp_literals", .fixture = "native_fp_literals", .prefix = "native-fp-literals", .functions = functions, .observations = 26880, .stdout = "native-fp-literals observations=26880 exact-payloads=ccc-fastcc=llvm-c-local-interop=volatile-effects=guards=preserved\n" });
}
fn pairVectorSaturation(c: *u.Context, target: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_pairVectorSaturation_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var functions = u.array(c.a);
    for ([_]u32{ 2, 3, 4, 8, 16, 32 }) |n| for ([_][]const u8{ "uadd.sat", "usub.sat", "sadd.sat", "ssub.sat", "umin", "umax", "smin", "smax" }, 0..) |op, id| {
        const name = try c.fmt("pair_vector_saturation_{d}_{d}", .{ n, id });
        try u.add(&functions, u.s(name));
        try text.writer.print("declare <{0d} x i128> @llvm.{1s}.v{0d}i128(<{0d} x i128>,<{0d} x i128>)\ndefine i64 @{2s}(ptr %out,ptr %ap,ptr %bp,i64 %salt) {{\nentry:\n %slot = alloca <{0d} x i128>,align {3d}\n %a = load <{0d} x i128>,ptr %ap,align 1\n %b = load <{0d} x i128>,ptr %bp,align 1\n store <{0d} x i128> %a,ptr %slot,align 1\n %again = load <{0d} x i128>,ptr %slot,align 1\n %r = call <{0d} x i128> @llvm.{1s}.v{0d}i128(<{0d} x i128> %again,<{0d} x i128> %b)\n store <{0d} x i128> %r,ptr %out,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ n, op, name, try std.math.ceilPowerOfTwo(u32, n * 16) });
        try driver.writer.print("extern uint64_t {s}(void *,const void *,const void *,uint64_t);\n", .{name});
        try table.writer.print("{{{d},{d},{s}}},\n", .{ n, id, name });
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ target, "pair_vector_saturation.ll" }), text.written());
    try c.write(try c.join(&.{ target, "pair_vector_saturation_driver.c" }), driver.written());
    return u.toValue(c.a, .{ .population = "pair_vector_saturation", .fixture = "pair_vector_saturation", .prefix = "pair-vector-saturation", .functions = functions, .observations = 103424, .stdout = "pair-vector-saturation observations=103424 signed-unsigned-clamps=extrema=aligned-objects=exact-stores=guard-pages=preserved\n" });
}
fn pairLiteralExtrema(c: *u.Context, target: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try text.writer.writeAll("declare i128 @llvm.umin.i128(i128,i128)\ndeclare i128 @llvm.umax.i128(i128,i128)\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_pairLiteralExtrema_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var functions = u.array(c.a);
    for ([_]bool{ false, true }) |right| for ([_][]const u8{ "umin", "umax" }, 0..) |op, kind| {
        const id: usize = 8 + kind + @as(usize, if (right) 2 else 0);
        const body = try c.fmt("pair_literal_extrema_body_{d}", .{id});
        const provider = try c.fmt("pair_literal_extrema_provider_{d}", .{id});
        const probe = try c.fmt("pair_literal_extrema_probe_{d}", .{id});
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("define i128 @{1s}(i128 %a,i128 %b) noinline {{\nentry:\n %r = call i128 @llvm.{0s}.i128(i128 {4s},i128 {5s})\n ret i128 %r\n}}\ndeclare i128 @{2s}(i128,i128)\ndefine i64 @{3s}(ptr %out,ptr %ap,ptr %bp,i64 %salt) {{\nentry:\n %a = load i128,ptr %ap,align 1\n %b = load i128,ptr %bp,align 1\n %local = call i128 @{1s}(i128 %a,i128 %b)\n %external = call i128 @{2s}(i128 %a,i128 %b)\n store i128 %local,ptr %out,align 1\n %out1 = getelementptr i8,ptr %out,i64 16\n store i128 %external,ptr %out1,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ op, body, provider, probe, if (right) "%a" else "-2", if (right) "-2" else "%b" });
        try driver.writer.print("extern u128 {s}(u128,u128);\nextern uint64_t {s}(void *,const void *,const void *,uint64_t);\nu128 {s}(u128 a,u128 b){{return model(a,b,{d});}}\n", .{ body, probe, provider, id });
        try table.writer.print("{{{d},{s},{s}}},\n", .{ id, body, probe });
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ target, "pair_literal_extrema.ll" }), text.written());
    try c.write(try c.join(&.{ target, "pair_literal_extrema_driver.c" }), driver.written());
    return u.toValue(c.a, .{ .population = "pair_literal_extrema", .fixture = "pair_literal_extrema", .prefix = "pair-literal-extrema", .functions = functions, .observations = 8192, .stdout = "pair-literal-extrema observations=8192 unsigned-minmax=left-right-full-width-literals=llvm-c-local-interop=guards=preserved\n" });
}
