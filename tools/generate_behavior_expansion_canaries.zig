//! Deterministically generate forty-one behavior-frontier native populations.
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
    try u.add(&entries, try oddSaturation(&c, target));
    try u.add(&entries, try signExtensionLive(&c, target));
    try u.add(&entries, try pairAbsolute(&c, target));
    try u.add(&entries, try pairExtendedSaturation(&c, target));
    try u.add(&entries, try vectorInputFragments(&c, target));
    try u.add(&entries, try mixedStackArguments(&c, target));
    for (0..3) |kind| try u.add(&entries, try scalarFollowupPopulation(&c, target, kind));
    try u.add(&entries, try checkedVectorArithmetic(&c, target));
    try u.add(&entries, try floatingInputPieces(&c, target));
    try u.add(&entries, try nativeMasks(&c, target));
    try u.add(&entries, try vectorExtrema(&c, target));
    try u.add(&entries, try integerVectorProducts(&c, target));
    try u.add(&entries, try booleanWideArguments(&c, target));
    try u.add(&entries, try boundedInlineAssembly(&c, target));
    try u.add(&entries, try narrowIntegerHalf(&c, target));
    try u.add(&entries, try unsignedByteSaturation(&c, target));
    try u.add(&entries, try definedConstantFlags(&c, target));
    try u.add(&entries, try pointerConstants(&c, target));
    try u.add(&entries, try mask3Input(&c, target));
    try u.add(&entries, try packedFloatExtract(&c, target));
    try u.add(&entries, try oddPairBitreverse(&c, target));
    try u.add(&entries,try integerUndef(&c,target));
    try u.add(&entries,try nativeLiteralTruncation(&c,target));
    try u.add(&entries,try memoryLimbs(&c,target));
    if (entries.array.items.len != 41) return error.ExpectedFortyOnePopulations;
    try c.writeJson(try c.join(&.{ target, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = entries }));
    var files = std.StringHashMap(void).init(c.a);
    for (entries.array.items) |entry| {
        for ([_][]const u8{ ".ll", "_driver.c" }) |suffix| try files.put(try c.fmt("{s}{s}", .{ try u.str(entry, "fixture"), suffix }), {});
        if (entry.object.get("reference_fixture")) |reference| try files.put(try c.fmt("{s}.ll", .{reference.string}), {});
        if (entry.object.get("reference_source")) |source| try files.put(source.string, {});
    }
    if (files.count() != 84) return error.ExpectedEightyFourFixtureFiles;
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
    try c.print("behavior-expansion fixtures: 41 populations, 84 files{s}\n", .{if (args.get("verify-root") != null) ", byte-exact verification passed" else ""});
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

fn replaceFixtureText(c: *u.Context, data: []const u8, old: []const u8, new: []const u8) ![]const u8 {
    const at = std.mem.indexOf(u8, data, old) orelse return error.ExpectedFixtureTemplateAnchor;
    return c.fmt("{s}{s}{s}", .{ data[0..at], new, data[at + old.len ..] });
}

fn oddSaturation(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var ir: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try ir.writer.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_oddSaturation_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    for (1..65) |bits| {
        if (bits == 51 or bits == 52) continue;
        for ([_][]const u8{ "sadd.sat", "ssub.sat" }, 0..) |op, kind| {
            const name = try c.fmt("odd_saturation_{d}_{d}", .{ bits, kind });
            try u.add(&functions, u.s(name));
            try ir.writer.print("declare i{0d} @llvm.{1s}.i{0d}(i{0d},i{0d})\ndefine i64 @{2s}(ptr %out,i64 %a,i64 %b,i64 %salt) {{\nentry:\n", .{ bits, op, name });
            if (bits == 64) try ir.writer.writeAll(" %x = add i64 %a,0\n %y = add i64 %b,0\n") else try ir.writer.print(" %x = trunc i64 %a to i{0d}\n %y = trunc i64 %b to i{0d}\n", .{bits});
            for (0..4) |mode| {
                try ir.writer.print(" %v{2d} = call i{0d} @llvm.{1s}.i{0d}(i{0d} {3s},i{0d} {4s})\n", .{ bits, op, mode, if (mode == 1 or mode == 3) "-1" else "%x", if (mode == 2 or mode == 3) "1" else "%y" });
                if (bits == 64) try ir.writer.print(" %wide{0d} = add i64 %v{0d},0\n", .{mode}) else try ir.writer.print(" %wide{1d} = zext i{0d} %v{1d} to i64\n", .{ bits, mode });
                try ir.writer.print(" %r{0d} = xor i64 %wide{0d},%salt\n %p{0d} = getelementptr i8,ptr %out,i64 {1d}\n store i64 %r{0d},ptr %p{0d},align 1\n", .{ mode, mode * 8 });
            }
            try ir.writer.writeAll(" %live = xor i64 %salt,90\n ret i64 %live\n}\n");
            try driver.writer.print("extern uint64_t {s}(void *,uint64_t,uint64_t,uint64_t);\n", .{name});
            try table.writer.print("{{{d},{d},{s}}},\n", .{ bits, kind, name });
        }
    }
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "odd_saturation.ll" }), ir.written());
    try c.write(try c.join(&.{ fixtures, "odd_saturation_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{
        .population = "odd_saturation",
        .fixture = "odd_saturation",
        .prefix = "odd-saturation",
        .functions = functions,
        .observations = 55552,
        .stdout = "odd-saturation observations=55552 all-proved-widths=logical-signs=literal-modes=live-values=exact-stores=guard-page=preserved\n",
    });
    return entry;
}

fn signExtensionLive(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_signExtensionLive_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    for ([_]bool{ false, true }) |branch| for (0..6) |index| {
        const id = @as(usize, if (branch) 6 else 0) + index;
        const body = try c.fmt("sign_extension_body_{d}", .{id});
        const provider = try c.fmt("sign_extension_provider_{d}", .{id});
        const probe = try c.fmt("sign_extension_probe_{d}", .{id});
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("define i64 @{s}(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {{\nentry:\n %narrow = trunc i64 %a{d} to i32\n %wide = sext i32 %narrow to i64\n", .{ body, index });
        if (branch) try text.writer.writeAll(" %condition = icmp eq i64 %a0,0\n br i1 %condition,label %left,label %right\nleft:\n br label %join\nright:\n br label %join\njoin:\n %carried = phi i64 [%wide,%left],[%wide,%right]\n");
        for (0..6) |i| {
            const previous = if (i == 0) (if (branch) "%carried" else "%wide") else try c.fmt("%r{d}", .{i - 1});
            try text.writer.print(" %mix{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %mix{0d},%a{0d}\n", .{ i, previous });
        }
        try text.writer.print(" ret i64 %r5\n}}\ndeclare i64 @{s}(i64,i64,i64,i64,i64,i64)\ndefine i64 @{s}(ptr %out,ptr %input,i64 %salt) {{\nentry:\n", .{ provider, probe });
        for (0..6) |i| try text.writer.print(" %p{0d} = getelementptr i8,ptr %input,i64 {1d}\n %a{0d} = load i64,ptr %p{0d},align 1\n", .{ i, i * 8 });
        try text.writer.print(" %local = call i64 @{s}(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)\n %external = call i64 @{s}(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)\n store i64 %local,ptr %out,align 1\n %next = getelementptr i8,ptr %out,i64 8\n store i64 %external,ptr %next,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ body, provider });
        try driver.writer.print("extern uint64_t {s}(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);\nextern uint64_t {s}(void *,const void *,uint64_t);\nuint64_t {s}(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5){{uint64_t args[]={{a0,a1,a2,a3,a4,a5}};return model(args,{d});}}\n", .{ body, probe, provider, index });
        try table.writer.print("{{{d},{s},{s}}},\n", .{ index, body, probe });
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "sign_extension_live.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "sign_extension_live_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "sign_extension_live", .fixture = "sign_extension_live", .prefix = "sign-extension-live", .functions = functions, .observations = 21504, .stdout = "sign-extension-live observations=21504 six-gp-sources=full-width-aliases=phi-edges=llvm-c-local-interop=exact-stores=guard-pages=preserved\n" });
    return entry;
}

fn pairAbsolute(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var driver: []const u8 = try c.read(try c.join(&.{"tools/templates/behavior_pairLiteralExtrema_core.c"}));
    const begin = std.mem.indexOf(u8, driver, "static __attribute__((noinline)) u128 model(") orelse return error.ModelMissing;
    const end = std.mem.indexOf(u8, driver, "static u128 sample(") orelse return error.SampleMissing;
    driver = try c.fmt("{s}static __attribute__((noinline)) u128 model(u128 a,u128 b,unsigned op){{(void)op;u128 absolute=(a>>127)?(u128)0-a:a;return absolute^b;}}\n{s}", .{ driver[0..begin], driver[end..] });
    driver = try replaceFixtureText(c, driver, "  memcpy(ap,&a,16);", "  if((cases[slot].op&1)&&a==((u128)1<<127))a++;\n  memcpy(ap,&a,16);");
    driver = try replaceFixtureText(c, driver, "pair-saturation slot=", "pair-absolute slot=");
    driver = try replaceFixtureText(c, driver, "pair-literal-extrema observations=%zu unsigned-minmax=left-right-full-width-literals=llvm-c-local-interop=guards=preserved", "pair-absolute observations=%zu minimum-false-flag=defined-true-flag=full-width-values=live-words=llvm-c-local-interop=guards=preserved");
    var text: std.Io.Writer.Allocating = .init(c.a);
    var declarations: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ndeclare i128 @llvm.abs.i128(i128,i1)\n");
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    for ([_]bool{ false, true }) |fast| for ([_]bool{ false, true }) |flag| {
        const id: usize = @as(usize, if (fast) 2 else 0) + @as(usize, if (flag) 1 else 0);
        const body = try c.fmt("pair_absolute_body_{d}", .{id});
        const provider = try c.fmt("pair_absolute_provider_{d}", .{id});
        const probe = try c.fmt("pair_absolute_probe_{d}", .{id});
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("define {0s}i128 @{1s}(i128 %a,i128 %b) noinline {{\nentry:\n %v = call i128 @llvm.abs.i128(i128 %a,i1 {2s})\n %r = xor i128 %v,%b\n ret i128 %r\n}}\ndeclare i128 @{3s}(i128,i128)\ndefine i64 @{4s}(ptr %out,ptr %ap,ptr %bp,i64 %salt) {{\nentry:\n %a = load i128,ptr %ap,align 1\n %b = load i128,ptr %bp,align 1\n %local = call {0s}i128 @{1s}(i128 %a,i128 %b)\n %external = call i128 @{3s}(i128 %a,i128 %b)\n store i128 %local,ptr %out,align 1\n %next = getelementptr i8,ptr %out,i64 16\n store i128 %external,ptr %next,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ if (fast) "fastcc " else "", body, if (flag) "true" else "false", provider, probe });
        try declarations.writer.print("extern u128 {s}(u128,u128);\nextern uint64_t {s}(void *,const void *,const void *,uint64_t);\nu128 {s}(u128 a,u128 b){{return model(a,b,{d});}}\n", .{ body, probe, provider, id });
        try table.writer.print("{{{d},{s},{s}}},\n", .{ id, body, probe });
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try c.write(try c.join(&.{ fixtures, "pair_absolute.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "pair_absolute_driver.c" }), try c.fmt("{s}{s}{s}", .{ driver, declarations.written(), table.written() }));
    const entry = try u.toValue(c.a, .{ .population = "pair_absolute", .fixture = "pair_absolute", .prefix = "pair-absolute", .functions = functions, .observations = 8192, .stdout = "pair-absolute observations=8192 minimum-false-flag=defined-true-flag=full-width-values=live-words=llvm-c-local-interop=guards=preserved\n" });
    return entry;
}

fn pairExtendedSaturation(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var driver: []const u8 = try c.read(try c.join(&.{"tools/templates/behavior_pairLiteralExtrema_core.c"}));
    const begin = std.mem.indexOf(u8, driver, "static __attribute__((noinline)) u128 model(") orelse return error.ModelMissing;
    const end = std.mem.indexOf(u8, driver, "static u128 sample(") orelse return error.SampleMissing;
    driver = try c.fmt("{s}{s}\n{s}", .{ driver[0..begin], try c.read(try c.join(&.{"tools/templates/behavior_pairExtendedSaturation_core.c"})), driver[end..] });
    driver = try replaceFixtureText(c, driver, "pair-saturation slot=", "pair-extended slot=");
    driver = try replaceFixtureText(c, driver, "count!=4||observations!=8192", "count!=8||observations!=16384");
    driver = try replaceFixtureText(c, driver, "pair-literal-extrema observations=%zu unsigned-minmax=left-right-full-width-literals=llvm-c-local-interop=guards=preserved", "pair-extended observations=%zu signed-unsigned-shifts=full-products=scale-zero=live-words=llvm-c-local-interop=guards=preserved");
    var text: std.Io.Writer.Allocating = .init(c.a);
    var declarations: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    const pair_operations = [_][]const u8{ "ushl.sat", "sshl.sat", "umul.fix.sat", "smul.fix.sat" };
    for (pair_operations, 0..) |op, id| try text.writer.print("declare i128 @llvm.{s}.i128(i128,i128{s})\n", .{ op, if (id >= 2) ",i32 immarg" else "" });
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    for ([_]bool{ false, true }) |fast| for (pair_operations, 0..) |op, kind| {
        const id: usize = @as(usize, if (fast) 4 else 0) + kind;
        const body = try c.fmt("pair_extended_body_{d}", .{id});
        const provider = try c.fmt("pair_extended_provider_{d}", .{id});
        const probe = try c.fmt("pair_extended_probe_{d}", .{id});
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("define {0s}i128 @{1s}(i128 %a,i128 %b) noinline {{\nentry:\n %n = and i128 %b,127\n %v = call i128 @llvm.{2s}.i128(i128 %a,i128 {3s}{4s})\n %r = xor i128 %v,%b\n ret i128 %r\n}}\ndeclare i128 @{5s}(i128,i128)\ndefine i64 @{6s}(ptr %out,ptr %ap,ptr %bp,i64 %salt) {{\nentry:\n %a = load i128,ptr %ap,align 1\n %b = load i128,ptr %bp,align 1\n %local = call {0s}i128 @{1s}(i128 %a,i128 %b)\n %external = call i128 @{5s}(i128 %a,i128 %b)\n store i128 %local,ptr %out,align 1\n %next = getelementptr i8,ptr %out,i64 16\n store i128 %external,ptr %next,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ if (fast) "fastcc " else "", body, op, if (kind >= 2) "%b" else "%n", if (kind >= 2) ",i32 0" else "", provider, probe });
        try declarations.writer.print("extern u128 {s}(u128,u128);\nextern uint64_t {s}(void *,const void *,const void *,uint64_t);\nu128 {s}(u128 a,u128 b){{return model(a,b,{d});}}\n", .{ body, probe, provider, id });
        try table.writer.print("{{{d},{s},{s}}},\n", .{ id, body, probe });
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try c.write(try c.join(&.{ fixtures, "pair_extended_saturation.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "pair_extended_saturation_driver.c" }), try c.fmt("{s}{s}{s}", .{ driver, declarations.written(), table.written() }));
    const entry = try u.toValue(c.a, .{ .population = "pair_extended_saturation", .fixture = "pair_extended_saturation", .prefix = "pair-extended", .functions = functions, .observations = 16384, .stdout = "pair-extended observations=16384 signed-unsigned-shifts=full-products=scale-zero=live-words=llvm-c-local-interop=guards=preserved\n" });
    return entry;
}

fn vectorInputFragments(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    const prefixes = [_]u64{ 0x123456789abcdef0, 0xfedcba9876543210, 0x1122334455667788, 0xabcd0123456789ef, 0x87654321fedcba98, 0x1020304050607080 };
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_vectorInputFragments_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    const shapes = [_][3]u16{ .{ 32, 8, 0 }, .{ 64, 8, 0 }, .{ 16, 16, 0 }, .{ 32, 16, 0 }, .{ 64, 16, 0 }, .{ 8, 32, 0 }, .{ 16, 32, 0 }, .{ 32, 32, 0 }, .{ 4, 64, 0 }, .{ 8, 64, 0 }, .{ 16, 64, 0 }, .{ 3, 8, 0 }, .{ 3, 16, 0 }, .{ 3, 64, 0 }, .{ 5, 32, 0 }, .{ 3, 64, 1 } };
    for (shapes, 0..) |shape, index| for ([_]bool{ false, true }) |fast| {
        const n = shape[0];
        const bits = shape[1];
        const pointer = shape[2] != 0;
        const scalar = if (pointer) "ptr" else try c.fmt("i{d}", .{bits});
        const scalarized = n == 3 or n == 5;
        const parts: usize = if (scalarized) n else n * bits / 128;
        const id = index * 2 + @as(usize, if (fast) 1 else 0);
        const cc = if (fast) "fastcc " else "";
        const body = try c.fmt("vector_input_body_{d}", .{id});
        const provider = try c.fmt("vector_input_provider_{d}", .{id});
        const probe = try c.fmt("vector_input_probe_{d}", .{id});
        const direct = try c.fmt("vector_input_direct_{d}", .{id});
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("define {0s}i64 @{1s}(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<{2d} x {3s}> %v,i64 %salt) noinline {{\nentry:\n %s0 = xor i64 %salt,%p0\n", .{ cc, body, n, scalar });
        for (1..6) |i| try text.writer.print(" %s{d} = xor i64 %s{d},%p{d}\n", .{ i, i - 1, i });
        for (0..n) |i| {
            try text.writer.print(" %lane{0d} = extractelement <{1d} x {2s}> %v,i64 {0d}\n", .{ i, n, scalar });
            if (pointer) try text.writer.print(" %word{0d} = ptrtoint ptr %lane{0d} to i64\n", .{i}) else if (bits == 64) try text.writer.print(" %word{0d} = add i64 %lane{0d},0\n", .{i}) else try text.writer.print(" %word{0d} = zext i{1d} %lane{0d} to i64\n", .{ i, bits });
            const previous = if (i == 0) "%s5" else try c.fmt("%r{d}", .{i - 1});
            try text.writer.print(" %mix{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %mix{0d},%word{0d}\n", .{ i, previous });
        }
        try text.writer.print(" ret i64 %r{d}\n}}\ndeclare i64 @{s}(i64,i64,i64,i64,i64,i64,<{d} x {s}>,i64)\ndefine i64 @{s}(ptr %out,ptr %input,i64 %salt) {{\nentry:\n %v = load <{d} x {s}>,ptr %input,align 1\n %local = call {s}i64 @{s}(", .{ n - 1, provider, n, scalar, probe, n, scalar, cc, body });
        for (prefixes) |value| try text.writer.print("i64 {d},", .{value});
        try text.writer.print("<{d} x {s}> %v,i64 %salt)\n %external = call i64 @{s}(", .{ n, scalar, provider });
        for (prefixes) |value| try text.writer.print("i64 {d},", .{value});
        try text.writer.print("<{d} x {s}> %v,i64 %salt)\n store i64 %local,ptr %out,align 1\n %next = getelementptr i8,ptr %out,i64 8\n store i64 %external,ptr %next,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ n, scalar });
        var declaration: std.Io.Writer.Allocating = .init(c.a);
        var invocation: std.Io.Writer.Allocating = .init(c.a);
        try declaration.writer.writeAll("uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,");
        try invocation.writer.writeAll("prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],");
        for (0..parts) |i| {
            try declaration.writer.print("{s} v{d},", .{ if (scalarized) "uint64_t" else "Carrier", i });
            try invocation.writer.print("v[{d}],", .{i});
        }
        try declaration.writer.writeAll("uint64_t salt");
        try invocation.writer.writeAll("salt");
        try driver.writer.print("extern uint64_t {s}({s});\nextern uint64_t {s}(void *,const void *,uint64_t);\nuint64_t {s}({s}){{uint64_t pre[]={{p0,p1,p2,p3,p4,p5}};unsigned char raw[128];", .{ body, declaration.written(), probe, provider, declaration.written() });
        for (0..parts) |i| try driver.writer.print("memcpy(raw+{d},&v{d},{d});", .{ if (scalarized) i * (bits / 8) else i * 16, i, if (scalarized) bits / 8 else 16 });
        try driver.writer.print("return digest(raw,{d},{d},pre,salt);}}\nstatic uint64_t {s}(const unsigned char *input,uint64_t salt){{{s} v[{d}];", .{ n, bits, direct, if (scalarized) "uint64_t" else "Carrier", parts });
        for (0..parts) |i| if (scalarized) {
            const mask = if (bits == 64) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
            try driver.writer.print("v[{d}]=word(input+{d},{d})|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C({d}));", .{ i, i * (bits / 8), bits / 8, mask });
        } else {
            try driver.writer.print("memcpy(&v[{d}],input+{d},16);", .{ i, i * 16 });
        };
        try driver.writer.print("return {s}({s});}}\n", .{ body, invocation.written() });
        try table.writer.print("{{{d},{d},{d},{s},{s}}},\n", .{ n, bits, @as(u8, if (pointer) 1 else 0), direct, probe });
    };
    try text.writer.writeAll("declare void @vector_input_void_provider(<8 x i32>)\ndefine void @vector_input_void_probe(ptr %p) {\nentry:\n %v = load <8 x i32>,ptr %p,align 1\n call void @vector_input_void_provider(<8 x i32> %v)\n ret void\n}\n");
    try u.add(&functions, u.s("vector_input_void_probe"));
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "vector_input_fragments.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "vector_input_fragments_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "vector_input_fragments", .fixture = "vector_input_fragments", .prefix = "vector-input-fragments", .functions = functions, .observations = 14464, .stdout = "vector-input-fragments observations=14464 ccc-fastcc=split-xmm=scalar-gp=live-prefixes=stack-words=llvm-c-local-interop=void-call=guard-pages=preserved\n" });
    return entry;
}

fn mixedStackArguments(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    const prefix = [_]u64{ 0x123456789abcdef0, 0xfedcba9876543210, 0x1122334455667788, 0xabcd0123456789ef, 0x87654321fedcba98, 0x1020304050607080, 0xf1379bdf2468ace0 };
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_mixedStackArguments_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    for ([_]bool{ false, true }) |fast| for ([_][]const u8{ "float", "double", "<2 x double>" }, 0..) |ty, kind| {
        const id = @as(usize, if (fast) 3 else 0) + kind;
        const cc = if (fast) "fastcc " else "";
        const cty = if (kind == 0) "float" else if (kind == 1) "double" else "Carrier";
        const provider = try c.fmt("mixed_stack_provider_{d}", .{id});
        const probe = try c.fmt("mixed_stack_probe_{d}", .{id});
        try u.add(&functions, u.s(probe));
        try text.writer.print("declare {s}i64 @{s}(i64,i64,i64,i64,i64,i64,i64,{s},i128,i64)\ndefine i64 @{s}(ptr %input,i64 %fpbits,i64 %salt) {{\nentry:\n %pair = load i128,ptr %input,align 1\n", .{ cc, provider, ty, probe });
        if (kind == 0) try text.writer.writeAll(" %low = trunc i64 %fpbits to i32\n %fp = bitcast i32 %low to float\n") else if (kind == 1) try text.writer.writeAll(" %fp = bitcast i64 %fpbits to double\n") else try text.writer.writeAll(" %fp = load <2 x double>,ptr %input,align 1\n");
        try text.writer.print(" %result = call {s}i64 @{s}(", .{ cc, provider });
        for (prefix) |word| try text.writer.print("i64 {d},", .{word});
        try text.writer.print("{s} %fp,i128 %pair,i64 %salt)\n ret i64 %result\n}}\n", .{ty});
        try driver.writer.print("extern uint64_t {s}(const void *,uint64_t,uint64_t);\nuint64_t {s}(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t p6,{s} fp,u128 pair,uint64_t salt){{uint64_t pre[]={{p0,p1,p2,p3,p4,p5,p6}},raw[2]={{0,0}};memcpy(raw,&fp,sizeof fp);calls++;return model(pre,pair,raw[0],raw[1],salt);}}\n", .{ probe, provider, cty });
        try table.writer.print("{{{d},{s}}},\n", .{ kind, probe });
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "mixed_stack_arguments.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "mixed_stack_arguments_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "mixed_stack_arguments", .fixture = "mixed_stack_arguments", .prefix = "mixed-stack-arguments", .functions = functions, .observations = 6144, .stdout = "mixed-stack-arguments observations=6144 ccc-fastcc=scalar-fp-vector128=stack-gp128=alignment-holes=live-suffixes=llvm-c-interop=guard-pages=preserved\n" });
    return entry;
}

const scalarFollowupNames = [_][]const u8{ "bitreverse_native_width", "literal_branches", "literal_fp_bitcasts" };
const scalarFollowupPrefixes = [_][]const u8{ "bitreverse-native-width", "literal-branches", "literal-fp-bitcasts" };
fn scalarFollowupPopulation(c: *u.Context, target: []const u8, kind: usize) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    if (kind == 0) try text.writer.writeAll("declare i32 @llvm.bitreverse.i32(i32)\n");
    try driver.writer.writeAll(try std.mem.replaceOwned(u8, c.a, try c.read(try c.join(&.{"tools/templates/behavior_scalarFollowup_core.c"})), "@PREFIX@", scalarFollowupPrefixes[kind]));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    const cases: usize = if (kind == 0) 24 else if (kind == 1) 12 else 60;
    for (0..cases) |id| {
        const cc = if (id % 2 == 0) "" else "fastcc ";
        const body = try c.fmt("{s}_body_{d}", .{ scalarFollowupNames[kind], id });
        const probe = try c.fmt("{s}_probe_{d}", .{ scalarFollowupNames[kind], id });
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        const position = (id / 2) % 6;
        const declared = kind == 0 and id / 12 == 1;
        const truth = kind == 1 and (id / 2) % 3 != 0;
        const loop = kind == 1 and id / 6 == 1;
        const bits: u16 = if (kind != 2 or id / 20 == 0) 16 else if (id / 20 == 1) 32 else 64;
        const ty = if (bits == 16) "half" else if (bits == 32) "float" else "double";
        const patterns = [_]u64{ 0, 1, 0xffffffffffffffff, 0x8000000000008000, 0x7c007f807f800000, 0x7fc123457ff81234, 0x7ff0000000000001, 0x7ff8000000001234, 0x8000000000000000, 0x123456789abcdef0 };
        const mask: u64 = if (bits == 64) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
        const raw = patterns[(id / 2) % 10] & mask;
        if (kind == 1) {
            const literal = ([_][]const u8{ "false", "true", "-1" })[(id / 2) % 3];
            try text.writer.print("define {s}i64 @{s}(i64 %a,i64 %b,i64 %live) noinline {{\nentry:\n", .{ cc, body });
            if (loop) {
                try text.writer.writeAll(" br label %loop\nloop:\n %i = phi i32 [0,%entry],[%next,%join]\n %sum = phi i64 [0,%entry],[%added,%join]\n");
                try text.writer.print(" br i1 {s},label %yes,label %no\nyes:\n br label %join\nno:\n br label %join\njoin:\n %increment = phi i64 [%a,%yes],[%b,%no]\n %added = add i64 %sum,%increment\n %next = add i32 %i,1\n %more = icmp ult i32 %next,32\n br i1 %more,label %loop,label %end\nend:\n %r = xor i64 %added,%live\n ret i64 %r\n}}\n", .{literal});
            } else try text.writer.print(" br i1 {s},label %yes,label %no\nyes:\n %x = xor i64 %a,%live\n br label %join\nno:\n %y = add i64 %b,%live\n br label %join\njoin:\n %r = phi i64 [%x,%yes],[%y,%no]\n ret i64 %r\n}}\n", .{literal});
        } else {
            try text.writer.print("define {s}{s} @{s}(", .{ cc, if (kind == 2) ty else "i64", body });
            for (0..6) |i| try text.writer.print("{s}i{d} %a{d}", .{ if (i == 0) "" else ",", if (declared and i == position) @as(u16, 32) else 64, i });
            if (kind == 2) try text.writer.writeAll(",ptr %out");
            try text.writer.writeAll(") noinline {\nentry:\n");
            if (kind == 0) {
                if (!declared) try text.writer.print(" %input = trunc i64 %a{d} to i32\n", .{position});
                try text.writer.print(" %v = call i32 @llvm.bitreverse.i32(i32 {s})\n %wide = zext i32 %v to i64\n", .{if (declared) try c.fmt("%a{d}", .{position}) else "%input"});
                if (declared) try text.writer.print(" %logical = zext i32 %a{d} to i64\n", .{position});
            } else {
                try text.writer.print(" %v = bitcast i{d} {d} to {s}\n store {s} %v,ptr %out,align 1\n", .{ bits, raw, ty, ty });
            }
            for (0..6) |i| {
                const value = if (declared and i == position) "%logical" else try c.fmt("%a{d}", .{i});
                const previous = if (i == 0) (if (kind == 2) "0" else "%wide") else try c.fmt("%r{d}", .{i - 1});
                try text.writer.print(" %m{d} = mul i64 {s},1099511628211\n %r{d} = xor i64 %m{d},{s}\n", .{ i, previous, i, i, value });
            }
            if (kind == 2) try text.writer.print(" %next = getelementptr i8,ptr %out,i64 8\n store i64 %r5,ptr %next,align 1\n ret {s} %v\n}}\n", .{ty}) else try text.writer.writeAll(" ret i64 %r5\n}\n");
        }
        try text.writer.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n", .{probe});
        for (0..6) |i| try text.writer.print(" %p{d} = getelementptr i8,ptr %input,i64 {d}\n %a{d} = load i64,ptr %p{d},align 1\n", .{ i, i * 8, i, i });
        if (declared) try text.writer.print(" %logical = trunc i64 %a{d} to i32\n", .{position});
        try text.writer.print(" %v = call {s}{s} @{s}(", .{ cc, if (kind == 2) ty else "i64", body });
        if (kind == 1) try text.writer.writeAll("i64 %a0,i64 %a1,i64 %a2") else for (0..6) |i| try text.writer.print("{s}i{d} {s}", .{ if (i == 0) "" else ",", if (declared and i == position) @as(u16, 32) else 64, if (declared and i == position) "%logical" else try c.fmt("%a{d}", .{i}) });
        if (kind == 2) try text.writer.writeAll(",ptr %out");
        try text.writer.writeAll(")\n");
        if (kind == 2) {
            try text.writer.print(" %raw = bitcast {s} %v to i{d}\n", .{ ty, bits });
            if (bits == 64) try text.writer.writeAll(" %wide = add i64 %raw,0\n") else try text.writer.print(" %wide = zext i{d} %raw to i64\n", .{bits});
            try text.writer.writeAll(" %liveptr = getelementptr i8,ptr %out,i64 8\n %live = load i64,ptr %liveptr,align 1\n %tail = getelementptr i8,ptr %out,i64 16\n store i64 %wide,ptr %tail,align 1\n %mix = xor i64 %live,%wide\n %r = xor i64 %mix,%salt\n ret i64 %r\n}\n");
        } else try text.writer.writeAll(" store i64 %v,ptr %out,align 1\n %next = getelementptr i8,ptr %out,i64 8\n store i64 %salt,ptr %next,align 1\n %tail = getelementptr i8,ptr %out,i64 16\n store i64 %a0,ptr %tail,align 1\n %r = xor i64 %v,%salt\n ret i64 %r\n}\n");
        try driver.writer.print("extern uint64_t {s}(const void *,void *,uint64_t);\n", .{probe});
        try table.writer.print("{{{s},{d},{d},{d},{d},UINT64_C({d})}},\n", .{ probe, if (kind == 0) @as(usize, 0) else if (kind == 1) (if (loop) @as(usize, 2) else 1) else 3, position, @intFromBool(if (kind == 1) truth else declared), bits, raw });
    }
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ target, try c.fmt("{s}.ll", .{scalarFollowupNames[kind]}) }), text.written());
    try c.write(try c.join(&.{ target, try c.fmt("{s}_driver.c", .{scalarFollowupNames[kind]}) }), driver.written());
    return u.toValue(c.a, .{ .population = scalarFollowupNames[kind], .fixture = scalarFollowupNames[kind], .prefix = scalarFollowupPrefixes[kind], .functions = functions, .observations = cases * 64 * 7, .stdout = try c.fmt("{s} observations={d} exact-payloads=live-aliases=cfg-phis=stack-calls=guard-pages=preserved\n", .{ scalarFollowupPrefixes[kind], cases * 64 * 7 }) });
}

fn checkedVectorArithmetic(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    var count: usize = 0;
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_checkedVectorArithmetic_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    const shapes = [_][2]u16{ .{ 2, 32 }, .{ 3, 32 }, .{ 4, 8 }, .{ 2, 8 }, .{ 4, 16 }, .{ 8, 8 }, .{ 4, 32 }, .{ 8, 32 }, .{ 1, 8 }, .{ 64, 32 } };
    var seen_lengths = std.AutoHashMap(u16, void).init(c.a);
    for (shapes, 0..) |s, shape_index| {
        const n = s[0];
        const bits = s[1];
        if (!seen_lengths.contains(n)) {
            try text.writer.print("declare i1 @llvm.vector.reduce.or.v{d}i1(<{d} x i1>)\n", .{ n, n });
            try seen_lengths.put(n, {});
        }
        for ([_][]const u8{ "uadd", "usub", "umul", "sadd", "ssub", "smul" }, 0..) |op, kind| {
            try text.writer.print("declare {{<{0d} x i{1d}>,<{0d} x i1>}} @llvm.{2s}.with.overflow.v{0d}i{1d}(<{0d} x i{1d}>,<{0d} x i{1d}>)\n", .{ n, bits, op });
            for ([_]bool{ false, true }) |zero| {
                if (zero and shape_index != 0 and shape_index != 2) continue;
                for ([_][]const u8{ "", "fastcc " }) |cc| {
                    const body = try c.fmt("checked_vector_body_{d}", .{count});
                    const probe = try c.fmt("checked_vector_probe_{d}", .{count});
                    count += 1;
                    try u.add(&functions, u.s(body));
                    try u.add(&functions, u.s(probe));
                    try text.writer.print("define {0s}i64 @{1s}(ptr %out,ptr %a,ptr %b,i64 %live) noinline {{\nentry:\n %x = load <{2d} x i{3d}>,ptr %a,align 1\n %y = load <{2d} x i{3d}>,ptr %b,align 1\n %pair = call {{<{2d} x i{3d}>,<{2d} x i1>}} @llvm.{4s}.with.overflow.v{2d}i{3d}(<{2d} x i{3d}> {5s},<{2d} x i{3d}> %y)\n %v = extractvalue {{<{2d} x i{3d}>,<{2d} x i1>}} %pair,0\n %flags = extractvalue {{<{2d} x i{3d}>,<{2d} x i1>}} %pair,1\n store <{2d} x i{3d}> %v,ptr %out,align 1\n %fptr = getelementptr i8,ptr %out,i64 {6d}\n store <{2d} x i1> %flags,ptr %fptr,align 1\n %any = call i1 @llvm.vector.reduce.or.v{2d}i1(<{2d} x i1> %flags)\n %wide = zext i1 %any to i64\n %r = xor i64 %wide,%live\n ret i64 %r\n}}\ndefine i64 @{7s}(ptr %out,ptr %a,ptr %b,i64 %live) {{\nentry:\n %r = call {0s}i64 @{1s}(ptr %out,ptr %a,ptr %b,i64 %live)\n ret i64 %r\n}}\n", .{ cc, body, n, bits, op, if (zero) "zeroinitializer" else "%x", n * (bits / 8), probe });
                    try driver.writer.print("extern uint64_t {s}(void *,const void *,const void *,uint64_t);\n", .{probe});
                    try table.writer.print("{{{s},{d},{d},{d},{d}}},\n", .{ probe, n, bits, kind, @intFromBool(zero) });
                }
            }
        }
    }
    if (count != 144) return error.CaseInventoryDiffers;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "checked_vector_arithmetic.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "checked_vector_arithmetic_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "checked_vector_arithmetic", .fixture = "checked_vector_arithmetic", .prefix = "checked-vector-arithmetic", .functions = functions, .observations = count * 64 * 7, .stdout = try c.fmt("checked-vector-arithmetic observations={d} wrapped-lanes=packed-overflow-flags=live-values=exact-stores=guard-pages=preserved\n", .{count * 64 * 7}) });
    return entry;
}

fn fpPieceCSignature(w: *std.Io.Writer, name: []const u8, ty: []const u8, parts: usize) !void {
    try w.print("uint64_t {s}(", .{name});
    for (0..6) |i| try w.print("{s}uint64_t p{d}", .{ if (i == 0) "" else ",", i });
    for (0..parts) |i| try w.print(",{s} v{d}", .{ ty, i });
    try w.writeAll(",uint64_t last,void *out)");
}
fn fpPieceIrArgs(w: *std.Io.Writer, ty: []const u8) !void {
    for (0..6) |i| try w.print("{s}i64 {s}{d}", .{ if (i == 0) "" else ",", "%p", i });
    try w.print(",<4 x {0s}> %a,<4 x {0s}> %b,i64 %tail,ptr %out", .{ty});
}

fn floatingInputPieces(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_floatingInputPieces_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    for ([_][]const u8{ "double", "fp128", "x86_fp80" }, [_][]const u8{ "fp_pair", "__float128", "long double" }, [_]u16{ 8, 16, 10 }, 0..) |ty, c_ty, bytes, format| for ([_][]const u8{ "", "fastcc " }, 0..) |cc, mode| {
        const id = format * 2 + mode;
        const parts: usize = if (bytes == 8) 4 else 8;
        const part_bytes: usize = if (bytes == 10) 10 else 16;
        const body = try c.fmt("fp_piece_body_{d}", .{id});
        const probe = try c.fmt("fp_piece_probe_{d}", .{id});
        const provider = try c.fmt("fp_piece_provider_{d}", .{id});
        const direct = try c.fmt("fp_piece_direct_{d}", .{id});
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("define {s}i64 @{s}(", .{ cc, body });
        try fpPieceIrArgs(&text.writer, ty);
        try text.writer.print(") noinline {{\nentry:\n store <4 x {0s}> %a,ptr %out,align 1\n %next = getelementptr i8,ptr %out,i64 {1d}\n store <4 x {0s}> %b,ptr %next,align 1\n", .{ ty, 4 * bytes });
        for (0..6) |i| try text.writer.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n", .{ i, if (i == 0) "%tail" else try c.fmt("%r{d}", .{i - 1}) });
        try text.writer.print(" %checksum = getelementptr i8,ptr %out,i64 {d}\n store i64 %r5,ptr %checksum,align 1\n ret i64 %r5\n}}\ndeclare i64 @{s}(i64,i64,i64,i64,i64,i64,<4 x {s}>,<4 x {s}>,i64,ptr)\n", .{ 8 * bytes, provider, ty, ty });
        try text.writer.print("define i64 @{s}(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) {{\nentry:\n %a = load <4 x {s}>,ptr %a_ptr,align 1\n %b = load <4 x {s}>,ptr %b_ptr,align 1\n", .{ probe, ty, ty });
        for (0..6) |i| try text.writer.print(" %p{d} = xor i64 %salt,{d}\n", .{ i, @as(u64, i + 1) *% 0x123456789abcdef1 });
        try text.writer.print(" %tail = xor i64 %salt,{d}\n %local = call {s}i64 @{s}(", .{ @as(u64, 0x8123456789abcdef), cc, body });
        try fpPieceIrArgs(&text.writer, ty);
        try text.writer.print(")\n %other = getelementptr i8,ptr %out,i64 {d}\n %external = call i64 @{s}(", .{ 8 * bytes + 8, provider });
        for (0..6) |i| try text.writer.print("{s}i64 %p{d}", .{ if (i == 0) "" else ",", i });
        try text.writer.print(",<4 x {0s}> %a,<4 x {0s}> %b,i64 %tail,ptr %other)\n %mixed = xor i64 %local,%external\n %r = xor i64 %mixed,%salt\n ret i64 %r\n}}\n", .{ty});
        try driver.writer.writeAll("extern ");
        try fpPieceCSignature(&driver.writer, body, c_ty, parts);
        try driver.writer.writeAll(";\n");
        try driver.writer.print("extern uint64_t {s}(void *,const void *,const void *,uint64_t);\n", .{probe});
        try fpPieceCSignature(&driver.writer, provider, c_ty, parts);
        try driver.writer.writeAll("{uint64_t args[]={p0,p1,p2,p3,p4,p5};unsigned char *bytes=out;");
        for (0..parts) |i| try driver.writer.print("memcpy(bytes+{d},&v{d},{d});", .{ i * part_bytes, i, part_bytes });
        try driver.writer.print("uint64_t value=checksum(args,last);memcpy(bytes+{d},&value,8);return value;}}\n", .{8 * bytes});
        try driver.writer.print("static uint64_t {s}(void *out,const void *a,const void *b,uint64_t salt){{{s} values[{d}];memset(values,0,sizeof values);", .{ direct, c_ty, parts });
        for (0..parts) |i| try driver.writer.print("memcpy(&values[{d}],(const unsigned char *){s}+{d},{d});", .{ i, if (i < parts / 2) "a" else "b", (i % (parts / 2)) * part_bytes, part_bytes });
        try driver.writer.print("return {s}(", .{body});
        for (0..6) |i| try driver.writer.print("{s}prefix({d},salt)", .{ if (i == 0) "" else ",", i });
        for (0..parts) |i| try driver.writer.print(",values[{d}]", .{i});
        try driver.writer.writeAll(",tail(salt),out);}\n");
        try table.writer.print("{{{s},{s},{d}}},\n", .{ probe, direct, bytes });
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "fp_input_pieces.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "fp_input_pieces_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "fp_input_pieces", .fixture = "fp_input_pieces", .prefix = "fp-input-pieces", .functions = functions, .observations = 5376, .stdout = "fp-input-pieces observations=5376 physical-c-llvm-local-interop=double-quad-x87=live-gp-prefixes=stack-slots=exact-payloads=guard-pages=preserved\n" });
    return entry;
}

const fpMasksExtremaLayout = "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n";
fn nativeMasks(c: *u.Context, fixtures: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll(fpMasksExtremaLayout);
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_nativeMasks_core.c"})));
    try driver.writer.writeAll("typedef float mask_f32x4 __attribute__((vector_size(16)));\ntypedef double mask_f64x2 __attribute__((vector_size(16)));\n");
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var functions = u.array(c.a);
    const predicates = [_][]const u8{ "false", "oeq", "ogt", "oge", "olt", "ole", "one", "ord", "ueq", "ugt", "uge", "ult", "ule", "une", "uno", "true" };
    for ([_][]const u8{ "float", "double" }, [_]usize{ 32, 64 }, [_]usize{ 4, 2 }, [_][]const u8{ "mask_f32x4", "mask_f64x2" }) |ty, bits, count, c_ty| for (predicates, 0..) |predicate, p| for ([_][]const u8{ "", "fastcc " }, 0..) |cc, mode| {
        const name = try c.fmt("native_fp_mask_{d}_{d}_{d}", .{ bits, p, mode });
        const wrapper = try c.fmt("{s}_call", .{name});
        try u.add(&functions, u.s(name));
        try text.writer.print("define {0s}<{1d} x {2s}> @{3s}(<{1d} x {2s}> %a,<{1d} x {2s}> %b) noinline {{\nentry:\n %home = alloca <{1d} x {2s}>,align 16\n store <{1d} x {2s}> %a,ptr %home,align 16\n %copy = load <{1d} x {2s}>,ptr %home,align 16\n %condition = fcmp {4s} <{1d} x {2s}> %copy,%b\n %result = select <{1d} x i1> %condition,<{1d} x {2s}> %copy,<{1d} x {2s}> %b\n ret <{1d} x {2s}> %result\n}}\n", .{ cc, count, ty, name, predicate });
        try driver.writer.print("extern {0s} {1s}({0s},{0s});\nstatic uint64_t {2s}(void *out,const void *a,const void *b,uint64_t salt){{{0s} left,right,result;memcpy(&left,a,16);memcpy(&right,b,16);result={1s}(left,right);memcpy(out,&result,16);return salt^90;}}\n", .{ c_ty, name, wrapper });
        try table.writer.print("{{{s},{d},{d}}},\n", .{ wrapper, bits, p });
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "native_fp_masks.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "native_fp_masks_driver.c" }), driver.written());
    return u.toValue(c.a, .{ .population = "native_fp_masks", .fixture = "native_fp_masks", .prefix = "native-fp-masks", .functions = functions, .observations = 32768, .stdout = "native-fp-masks observations=32768 all-sixteen-predicates=physical-xmm-returns=raw-payloads=stack-storage=guard-pages=preserved\n" });
}
fn vectorExtrema(c: *u.Context, fixtures: []const u8) !u.Value {
    var text: std.Io.Writer.Allocating = .init(c.a);
    var reference: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    try text.writer.writeAll(fpMasksExtremaLayout);
    try reference.writer.writeAll(fpMasksExtremaLayout);
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_vectorExtrema_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var functions = u.array(c.a);
    for ([_][]const u8{ "half", "float", "double", "x86_fp80", "fp128" }, [_]usize{ 16, 32, 64, 80, 128 }) |ty, bits| for ([_]usize{ 2, 3, 4 }) |count| for ([_][]const u8{ "minnum", "maxnum" }, 0..) |operation, maximum| {
        const decl = try c.fmt("declare <{0d} x {1s}> @llvm.{2s}.v{0d}f{3d}(<{0d} x {1s}>,<{0d} x {1s}>)\n", .{ count, ty, operation, bits });
        try text.writer.writeAll(decl);
        try reference.writer.writeAll(decl);
        for ([_][]const u8{ "", "fastcc " }, 0..) |cc, mode| {
            const body = try c.fmt("vector_fp_extrema_{d}_{d}_{d}_{d}", .{ bits, count, maximum, mode });
            try u.add(&functions, u.s(body));
            const head = try c.fmt("define {0s}i64 @{1s}(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {{\nentry:\n %a = load <{2d} x {3s}>,ptr %a_ptr,align 1\n %b = load <{2d} x {3s}>,ptr %b_ptr,align 1\n %result = call <{2d} x {3s}> @llvm.{4s}.v{2d}f{5d}(<{2d} x {3s}> %a,<{2d} x {3s}> %b)\n", .{ cc, body, count, ty, operation, bits });
            try text.writer.writeAll(head);
            try reference.writer.writeAll(head);
            try text.writer.print(" store <{d} x {s}> %result,ptr %out,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ count, ty });
            try reference.writer.print(" %az = fcmp oeq <{0d} x {1s}> %a,zeroinitializer\n %bz = fcmp oeq <{0d} x {1s}> %b,zeroinitializer\n %tie = and <{0d} x i1> %az,%bz\n %ia = bitcast <{0d} x {1s}> %a to <{0d} x i{2d}>\n %ib = bitcast <{0d} x {1s}> %b to <{0d} x i{2d}>\n %joined = {3s} <{0d} x i{2d}> %ia,%ib\n %safe = select <{0d} x i1> %tie,<{0d} x i{2d}> %joined,<{0d} x i{2d}> zeroinitializer\n %zero = bitcast <{0d} x i{2d}> %safe to <{0d} x {1s}>\n %canonical = select <{0d} x i1> %tie,<{0d} x {1s}> %zero,<{0d} x {1s}> %result\n store <{0d} x {1s}> %canonical,ptr %out,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ count, ty, bits, if (maximum == 0) "or" else "and" });
            try driver.writer.print("extern uint64_t {s}(void *,const void *,const void *,uint64_t);\n", .{body});
            try table.writer.print("{{{s},{d},{d},{d}}},\n", .{ body, bits, count, maximum });
        }
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "vector_fp_extrema.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "vector_fp_extrema_zero_reference.ll" }), reference.written());
    try c.write(try c.join(&.{ fixtures, "vector_fp_extrema_driver.c" }), driver.written());
    return u.toValue(c.a, .{ .population = "vector_fp_extrema", .fixture = "vector_fp_extrema", .prefix = "vector-fp-extrema", .reference_fixture = "vector_fp_extrema_zero_reference", .reference_source = "vector_fp_extrema_driver.c", .functions = functions, .libraries = .{"m"}, .observations = 30720, .stdout = "vector-fp-extrema observations=30720 five-formats=independent-c-model=canonical-zero-ties=quiet-nan-classification=exact-stores=guard-pages=preserved\n" });
}

fn integerVectorProducts(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_vectorProducts_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    for ([_]usize{ 8, 16, 24, 32, 48, 64, 128 }) |bits| for ([_]usize{ 1, 2, 3, 4, 8, 16, 64 }) |count| {
        try text.writer.print("declare i{0d} @llvm.vector.reduce.mul.v{1d}i{0d}(<{1d} x i{0d}>)\n", .{ bits, count });
        for ([_][]const u8{ "", "fastcc " }, 0..) |cc, mode| {
            const name = try c.fmt("integer_vector_product_{d}_{d}_{d}", .{ bits, count, mode });
            try u.add(&functions, u.s(name));
            try text.writer.print("define {0s}i64 @{1s}(ptr %out,ptr %input,i64 %salt) noinline {{\nentry:\n %v = load <{2d} x i{3d}>,ptr %input,align 1\n %r = call i{3d} @llvm.vector.reduce.mul.v{2d}i{3d}(<{2d} x i{3d}> %v)\n store i{3d} %r,ptr %out,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ cc, name, count, bits });
            try driver.writer.print("extern uint64_t {s}(void *,const void *,uint64_t);\n", .{name});
            try table.writer.print("{{{s},{d},{d}}},\n", .{ name, bits, count });
        }
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "integer_vector_products.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "integer_vector_products_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "integer_vector_products", .fixture = "integer_vector_products", .prefix = "integer-vector-products", .functions = functions, .observations = 31360, .stdout = "integer-vector-products observations=31360 seven-widths=modular-c-model=one-to-sixty-four-lanes=exact-stores=guard-pages=preserved\n" });
    return entry;
}

fn booleanWideArguments(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_booleanWideArguments_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    for ([_]usize{ 65, 96, 127, 128 }) |bits| for ([_]usize{ 0, 1 }) |dirty| {
        if (dirty == 1 and bits != 128) continue;
        for ([_][]const u8{ "", "fastcc " }, 0..) |cc, mode| {
            const name = try c.fmt("boolean_wide_{d}_{d}_{d}", .{ bits, dirty, mode });
            const provider = try c.fmt("{s}_provider", .{name});
            try u.add(&functions, u.s(name));
            try text.writer.print("declare {0s}i1 @{1s}(i{2d},i64)\ndefine {0s}i64 @{3s}(ptr %out,ptr %input,i64 %salt) noinline {{\nentry:\n %v = load i{2d},ptr %input,align 1\n %r = call {0s}i1 @{1s}(i{2d} %v,i64 %salt)\n store i1 %r,ptr %out,align 1\n %saved = getelementptr i8,ptr %out,i64 8\n store i64 %salt,ptr %saved,align 1\n %z = zext i1 %r to i64\n %answer = xor i64 %z,%salt\n ret i64 %answer\n}}\n", .{ cc, provider, bits, name });
            try driver.writer.print("extern uint64_t {s}(void *,const void *,uint64_t);\n", .{name});
            if (dirty == 0) try driver.writer.print("_Bool {s}(uint64_t lo,uint64_t hi,uint64_t salt){{return model(lo,hi,salt,{d},0);}}\n", .{ provider, bits }) else try driver.writer.print("__asm__(\".text\\n.globl {0s}\\n.type {0s},@function\\n{0s}:\\nmovabs $0xa5a5a5a5a5a5a500,%rax\\nmovb %dil,%al\\nxorb %sil,%al\\nxorb %dl,%al\\nandb $1,%al\\nret\\n.size {0s},.-{0s}\\n\");\n", .{provider});
            try table.writer.print("{{{s},{d},{d}}},\n", .{ name, bits, dirty });
        }
    };
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "boolean_wide_arguments.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "boolean_wide_arguments_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "boolean_wide_arguments", .fixture = "boolean_wide_arguments", .prefix = "boolean-wide-arguments", .functions = functions, .observations = 10240, .stdout = "boolean-wide-arguments observations=10240 multiword-c-abi=defined-al-only=live-pointers=live-salt=exact-stores=guard-pages=preserved\n" });
    return entry;
}

fn boundedAsmCase(c: *u.Context, text: *std.Io.Writer, driver: *std.Io.Writer, table: *std.Io.Writer, functions: *u.Value, id: usize, cc: []const u8, kind: usize, position: usize, literal_operand: bool, bits: usize, literal: i128, form: usize) !void {
    const body = try c.fmt("bounded_asm_body_{d}", .{id});
    const probe = try c.fmt("bounded_asm_probe_{d}", .{id});
    try u.add(functions, u.s(body));
    try u.add(functions, u.s(probe));
    try text.print("define {s}i64 @{s}(", .{ cc, body });
    for (0..6) |i| try text.print("{s}i64 %p{d}", .{ if (i == 0) "" else ",", i });
    try text.writeAll(",ptr %out) noinline {\nentry:\n");
    if (kind == 0) {
        try text.print(" %value = call i{d} asm sideeffect \"mov $${d}, ${{0}}\", \"=r,~{{dirflag}},~{{fpsr}},~{{flags}}\"()\n", .{ bits, literal });
        if (bits == 32) try text.writeAll(" %result = zext i32 %value to i64\n") else try text.writeAll(" %result = add i64 %value,0\n");
    } else if (kind == 1) {
        try text.print(" %x = trunc i64 %p{d} to i32\n", .{position});
        if (!literal_operand) try text.print(" %y = trunc i64 %p{d} to i32\n", .{(position + 1) % 6});
        try text.print(" %value = call i32 asm \"addl ${{1}}, ${{0}}\", \"=r,r,0,~{{flags}},~{{dirflag}},~{{fpsr}},~{{flags}}\"(i32 {s},i32 %x)\n %result = zext i32 %value to i64\n", .{if (literal_operand) "13" else "%y"});
    } else if (kind == 3) {
        try text.writeAll(" call void asm sideeffect \"\", \"m,~{dirflag},~{fpsr},~{flags}\"(ptr @bounded_asm_global)\n %result = load i64,ptr @bounded_asm_global,align 1\n");
    } else {
        try text.print(" store i64 %p{d},ptr %out,align 1\n", .{position});
        const constraints = [_][]const u8{ "m", "=*m|r", "=*r|m", "=*r|m,r|m" };
        if (form == 3) try text.writeAll(" %extra = trunc i64 %p1 to i32\n");
        try text.print(" call void asm sideeffect \"\", \"{s},~{{dirflag}},~{{fpsr}},~{{flags}}\"(ptr {s}%out{s})\n", .{ constraints[form], if (form == 0) "" else "elementtype(i64) ", if (form == 3) ",i32 %extra" else "" });
        // Indirect register outputs are unconstrained. Observe a subsequent defined
        // store, retaining their pointer escape and ordering without choosing bits.
        try text.print(" store i64 %p{d},ptr %out,align 1\n %result = load i64,ptr %out,align 1\n", .{position});
    }
    for (0..6) |i| try text.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n", .{ i, if (i == 0) "%result" else try c.fmt("%r{d}", .{i - 1}) });
    try text.writeAll(" ret i64 %r5\n}\n");
    try text.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n", .{probe});
    for (0..6) |i| try text.print(" %a{0d} = getelementptr i8,ptr %input,i64 {1d}\n %v{0d} = load i64,ptr %a{0d},align 1\n", .{ i, i * 8 });
    try text.print(" %answer = call {s}i64 @{s}(", .{ cc, body });
    for (0..6) |i| try text.print("{s}i64 %v{d}", .{ if (i == 0) "" else ",", i });
    try text.writeAll(",ptr %out)\n store i64 %answer,ptr %out,align 1\n %o1 = getelementptr i8,ptr %out,i64 8\n store i64 %salt,ptr %o1,align 1\n %o2 = getelementptr i8,ptr %out,i64 16\n store i64 %v0,ptr %o2,align 1\n %r = xor i64 %answer,%salt\n ret i64 %r\n}\n");
    try driver.print("extern uint64_t {s}(const void *,void *,uint64_t);\n", .{probe});
    const raw: u64 = if (bits == 32) @as(u32, @truncate(@as(u128, @bitCast(literal)))) else @truncate(@as(u128, @bitCast(literal)));
    try table.print("{{{s},{d},{d},{d},{d},UINT64_C({d})}},\n", .{ probe, kind, position, @intFromBool(literal_operand), bits, raw });
}

fn boundedInlineAssembly(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    var id: usize = 0;
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n@bounded_asm_global = internal global i64 1311768467463790321,align 8\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_boundedInlineAssembly_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    for ([_][]const u8{ "", "fastcc " }) |cc| {
        for ([_]usize{ 32, 64 }) |bits| for ([_]i128{ 0, 1, -1, 123, -(@as(i128, 1) << @as(u7, @intCast(bits - 1))), (@as(i128, 1) << @as(u7, @intCast(bits))) - 1 }) |value| {
            try boundedAsmCase(c, &text.writer, &driver.writer, &table.writer, &functions, id, cc, 0, 0, false, bits, value, 0);
            id += 1;
        };
        for (0..6) |position| for ([_]bool{ false, true }) |literal_operand| {
            try boundedAsmCase(c, &text.writer, &driver.writer, &table.writer, &functions, id, cc, 1, position, literal_operand, 32, 0, 0);
            id += 1;
        };
        for (0..5) |form| {
            try boundedAsmCase(c, &text.writer, &driver.writer, &table.writer, &functions, id, cc, if (form == 4) 3 else 2, 0, false, 64, if (form == 4) 0x123456789abcdef1 else 0, form);
            id += 1;
        }
    }
    if (id != 58) return error.ExpectedCases;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "bounded_inline_assembly.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "bounded_inline_assembly_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "bounded_inline_assembly", .fixture = "bounded_inline_assembly", .prefix = "bounded-inline-assembly", .functions = functions, .observations = 25984, .stdout = "bounded-inline-assembly observations=25984 exact-asm-effects=live-aliases=opaque-memory-ordering=stack-calls=guard-pages=preserved\n" });
    return entry;
}

fn narrowIntegerHalf(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_narrowIntegerHalf_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var id: usize = 0;
    for ([_]usize{ 1, 2, 3, 7, 8, 11, 12, 15, 16, 17, 24, 31 }) |bits| for ([_][]const u8{ "uitofp", "sitofp" }, 0..) |operation, signed| for (0..6) |position| for ([_][]const u8{ "", "fastcc " }) |cc| {
        const body = try c.fmt("narrow_half_body_{d}", .{id});
        const probe = try c.fmt("narrow_half_probe_{d}", .{id});
        id += 1;
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("define {s}i64 @{s}(", .{ cc, body });
        for (0..6) |i| try text.writer.print("{s}i64 %p{d}", .{ if (i == 0) "" else ",", i });
        try text.writer.writeAll(",ptr %out) noinline {\nentry:\n");
        try text.writer.print(" %input = trunc i64 %p{0d} to i{1d}\n %value = {2s} i{1d} %input to half\n %raw = bitcast half %value to i16\n %wide = zext i16 %raw to i64\n", .{ position, bits, operation });
        for (0..6) |i| try text.writer.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n", .{ i, if (i == 0) "%wide" else try c.fmt("%r{d}", .{i - 1}) });
        try text.writer.writeAll(" ret i64 %r5\n}\n");
        try text.writer.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n", .{probe});
        for (0..6) |i| try text.writer.print(" %a{0d} = getelementptr i8,ptr %input,i64 {1d}\n %v{0d} = load i64,ptr %a{0d},align 1\n", .{ i, i * 8 });
        try text.writer.print(" %answer = call {s}i64 @{s}(", .{ cc, body });
        for (0..6) |i| try text.writer.print("{s}i64 %v{d}", .{ if (i == 0) "" else ",", i });
        try text.writer.writeAll(",ptr %out)\n store i64 %answer,ptr %out,align 1\n %o1 = getelementptr i8,ptr %out,i64 8\n store i64 %salt,ptr %o1,align 1\n %o2 = getelementptr i8,ptr %out,i64 16\n store i64 %v0,ptr %o2,align 1\n %r = xor i64 %answer,%salt\n ret i64 %r\n}\n");
        try driver.writer.print("extern uint64_t {s}(const void *,void *,uint64_t);\n", .{probe});
        try table.writer.print("{{{s},0,{d},{d},{d},UINT64_C(0)}},\n", .{ probe, position, signed, bits });
    };
    if (id != 288) return error.CaseInventoryChanged;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "narrow_integer_half.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "narrow_integer_half_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "narrow_integer_half", .fixture = "narrow_integer_half", .prefix = "narrow-integer-half", .functions = functions, .observations = 129024, .stdout = "narrow-integer-half observations=129024 integer-rounding-model=exact-half-payloads=live-aliases=stack-calls=guard-pages=preserved\n" });
    return entry;
}

fn unsignedByteSaturation(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_unsignedByteSaturation_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var id: usize = 0;
    for ([_]usize{ 40, 48, 56 }) |bits| for ([_]usize{ 1, 2, 4 }) |lanes| for ([_][]const u8{ "uadd", "usub" }, 0..) |operation, subtract| {
        const ty = if (lanes == 1) try c.fmt("i{d}", .{bits}) else try c.fmt("<{d} x i{d}>", .{ lanes, bits });
        const suffix = if (lanes == 1) try c.fmt("i{d}", .{bits}) else try c.fmt("v{d}i{d}", .{ lanes, bits });
        try text.writer.print("declare {0s} @llvm.{1s}.sat.{2s}({0s},{0s})\n", .{ ty, operation, suffix });
        var literal: std.Io.Writer.Allocating = .init(c.a);
        if (lanes == 1) try literal.writer.writeAll("-1") else {
            try literal.writer.writeAll("<");
            for (0..lanes) |i| try literal.writer.print("{s}i{d} -1", .{ if (i == 0) "" else ",", bits });
            try literal.writer.writeAll(">");
        }
        for (0..3) |mode| for ([_][]const u8{ "", "fastcc " }) |cc| {
            const body = try c.fmt("unsigned_odd_body_{d}", .{id});
            const probe = try c.fmt("unsigned_odd_probe_{d}", .{id});
            id += 1;
            try u.add(&functions, u.s(body));
            try u.add(&functions, u.s(probe));
            try text.writer.print("define {s}i64 @{s}(", .{ cc, body });
            for (0..6) |i| try text.writer.print("{s}i64 %p{d}", .{ if (i == 0) "" else ",", i });
            try text.writer.print(",ptr %ap,ptr %bp,ptr %out) noinline {{\nentry:\n %a = load {0s},ptr %ap,align 1\n %b = load {0s},ptr %bp,align 1\n %value = call {0s} @llvm.{1s}.sat.{2s}({0s} {3s},{0s} {4s})\n store {0s} %value,ptr %out,align 1\n", .{ ty, operation, suffix, if (mode == 1) literal.written() else "%a", if (mode == 2) literal.written() else "%b" });
            for (0..6) |i| try text.writer.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n", .{ i, if (i == 0) "0" else try c.fmt("%r{d}", .{i - 1}) });
            try text.writer.writeAll(" ret i64 %r5\n}\n");
            const extent = (bits * lanes + 7) / 8;
            try text.writer.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n", .{probe});
            for (0..6) |i| try text.writer.print(" %a{0d} = getelementptr i8,ptr %input,i64 {1d}\n %v{0d} = load i64,ptr %a{0d},align 1\n", .{ i, i * 8 });
            try text.writer.print(" %ap = getelementptr i8,ptr %input,i64 48\n %bp = getelementptr i8,ptr %input,i64 {d}\n %answer = call {s}i64 @{s}(", .{ 48 + extent, cc, body });
            for (0..6) |i| try text.writer.print("{s}i64 %v{d}", .{ if (i == 0) "" else ",", i });
            try text.writer.writeAll(",ptr %ap,ptr %bp,ptr %out)\n");
            for ([_][]const u8{ "%answer", "%salt", "%v0" }, 0..) |value, i| try text.writer.print(" %o{0d} = getelementptr i8,ptr %out,i64 {1d}\n store i64 {2s},ptr %o{0d},align 1\n", .{ i, extent + i * 8, value });
            try text.writer.writeAll(" %result = xor i64 %answer,%salt\n ret i64 %result\n}\n");
            try driver.writer.print("extern uint64_t {s}(const void *,void *,uint64_t);\n", .{probe});
            try table.writer.print("{{{s},{d},{d},{d},{d}}},\n", .{ probe, bits, lanes, subtract, mode });
        };
    };
    if (id != 108) return error.CaseInventoryChanged;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "unsigned_odd_saturation.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "unsigned_odd_saturation_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "unsigned_odd_saturation", .fixture = "unsigned_odd_saturation", .prefix = "unsigned-odd-saturation", .functions = functions, .observations = id * 64 * 8, .stdout = try c.fmt("unsigned-odd-saturation observations={d} integer-clamp-model=packed-vectors=literal-modes=live-aliases=stack-calls=guard-pages=preserved\n", .{id * 64 * 8}) });
    return entry;
}

fn definedConstantFlags(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_definedConstantFlags_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var id: usize = 0;
    for ([_]usize{ 1, 3, 8, 17, 32, 48, 64 }) |bits| for (0..3) |operation| for ([_]usize{ 1, 2, 3 }) |flags| for (0..5) |pair| {
        const limit = @as(u128, 1) << @as(u7, @intCast(bits));
        const mask = limit - 1;
        const sign = limit >> 1;
        const x: u128 = switch (pair) {
            0 => 0,
            1 => mask,
            2 => sign - 1,
            3 => mask / 4,
            else => 10 & mask,
        };
        const y: u128 = switch (pair) {
            0, 1 => 0,
            2 => 1,
            3 => 2 & mask,
            else => (limit - 4 % limit) & mask,
        };
        const result = switch (operation) {
            0 => x + y,
            1 => x -% y,
            else => x * y,
        };
        const sx = if (x >= sign) @as(i128, @intCast(x)) - @as(i128, @intCast(limit)) else @as(i128, @intCast(x));
        const sy = if (y >= sign) @as(i128, @intCast(y)) - @as(i128, @intCast(limit)) else @as(i128, @intCast(y));
        const signed_result = switch (operation) {
            0 => sx + sy,
            1 => sx - sy,
            else => sx * sy,
        };
        if (flags & 1 != 0 and (if (operation == 1) x < y else result > mask)) continue;
        if (flags & 2 != 0 and (signed_result < -@as(i128, @intCast(sign)) or signed_result > @as(i128, @intCast(sign)) - 1)) continue;
        for ([_][]const u8{ "", "fastcc " }) |cc| {
            const body = try c.fmt("constant_flags_body_{d}", .{id});
            const probe = try c.fmt("constant_flags_probe_{d}", .{id});
            id += 1;
            try u.add(&functions, u.s(body));
            try u.add(&functions, u.s(probe));
            try text.writer.print("define {s}i64 @{s}(", .{ cc, body });
            for (0..6) |i| try text.writer.print("{s}i64 %p{d}", .{ if (i == 0) "" else ",", i });
            try text.writer.writeAll(",ptr %out) noinline {\nentry:\n");
            const op = ([_][]const u8{ "add", "sub", "mul" })[operation];
            const fact = ([_][]const u8{ "", "nuw ", "nsw ", "nuw nsw " })[flags];
            const rhs = if (pair == 4 and sy < 0) try c.fmt("{d}", .{sy}) else try c.fmt("{d}", .{y});
            try text.writer.print(" %value = {s} {s}i{d} {d},{s}\n %wide = {s}\n", .{ op, fact, bits, x, rhs, if (bits == 64) "add i64 %value,0" else try c.fmt("zext i{d} %value to i64", .{bits}) });
            for (0..6) |i| try text.writer.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n", .{ i, if (i == 0) "%wide" else try c.fmt("%r{d}", .{i - 1}) });
            try text.writer.writeAll(" ret i64 %r5\n}\n");
            try text.writer.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n", .{probe});
            for (0..6) |i| try text.writer.print(" %a{0d} = getelementptr i8,ptr %input,i64 {1d}\n %v{0d} = load i64,ptr %a{0d},align 1\n", .{ i, i * 8 });
            try text.writer.print(" %answer = call {s}i64 @{s}(", .{ cc, body });
            for (0..6) |i| try text.writer.print("{s}i64 %v{d}", .{ if (i == 0) "" else ",", i });
            try text.writer.writeAll(",ptr %out)\n store i64 %answer,ptr %out,align 1\n %o1 = getelementptr i8,ptr %out,i64 8\n store i64 %salt,ptr %o1,align 1\n %o2 = getelementptr i8,ptr %out,i64 16\n store i64 %v0,ptr %o2,align 1\n %r = xor i64 %answer,%salt\n ret i64 %r\n}\n");
            try driver.writer.print("extern uint64_t {s}(const void *,void *,uint64_t);\n", .{probe});
            try table.writer.print("{{{s},{d},0,{d},{d},UINT64_C({d}),UINT64_C({d})}},\n", .{ probe, operation, flags, bits, x, y });
        }
    };
    if (id == 0) return error.EmptyCaseInventory;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "constant_flags.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "constant_flags_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "constant_flags", .fixture = "constant_flags", .prefix = "constant-flags", .functions = functions, .observations = id * 64 * 7, .stdout = try c.fmt("constant-flags observations={d} defined-overflow-facts=integer-model=literal-spellings=live-aliases=stack-calls=guard-pages=preserved\n", .{id * 64 * 7}) });
    return entry;
}

fn pointerConstants(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_pointerConstants_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var id: usize = 0;
    const values = [_]i128{ 0, 1, -1, 9223372036854775808, 4294967295, 1311768467463790320 };
    for ([_]usize{ 1, 2, 3, 4, 8, 16, 32, 64 }) |n| for ([_][]const u8{ "", "fastcc " }) |cc| {
        const body = try c.fmt("pointer_constants_body_{d}", .{id});
        const probe = try c.fmt("pointer_constants_probe_{d}", .{id});
        id += 1;
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("define {s}i64 @{s}(", .{ cc, body });
        for (0..6) |i| try text.writer.print("{s}i64 %p{d}", .{ if (i == 0) "" else ",", i });
        try text.writer.print(",ptr %input,ptr %out) noinline {{\nentry:\n %a = load <{0d} x i64>,ptr %input,align 1\n %p = inttoptr <{0d} x i64> %a to <{0d} x ptr>\n %bits = ptrtoint <{0d} x ptr> %p to <{0d} x i64>\n store <{0d} x i64> %bits,ptr %out,align 1\n %out1 = getelementptr i8,ptr %out,i64 {1d}\n store <{0d} x ptr> <", .{ n, n * 8 });
        for (0..n) |i| try text.writer.print("{s}ptr {s}", .{ if (i == 0) "" else ",", if (values[i % 6] == 0) "null" else try c.fmt("inttoptr (i64 {d} to ptr)", .{values[i % 6]}) });
        try text.writer.writeAll(">,ptr %out1,align 1\n");
        for (0..n) |i| {
            const lane = n - 1 - i;
            try text.writer.print(" %insert{0d} = insertelement <{1d} x ptr> {2s},ptr {3s},i32 {4d}\n", .{ i, n, if (i == 0) "poison" else try c.fmt("%insert{d}", .{i - 1}), if (values[lane % 6] == 0) "null" else try c.fmt("inttoptr (i64 {d} to ptr)", .{values[lane % 6]}), lane });
        }
        try text.writer.print(" %out2 = getelementptr i8,ptr %out,i64 {d}\n store <{d} x ptr> %insert{d},ptr %out2,align 1\n", .{ n * 16, n, n - 1 });
        for (0..6) |i| try text.writer.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n", .{ i, if (i == 0) "0" else try c.fmt("%r{d}", .{i - 1}) });
        try text.writer.writeAll(" ret i64 %r5\n}\n");
        try text.writer.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n", .{probe});
        for (0..6) |i| try text.writer.print(" %a{0d} = getelementptr i8,ptr %input,i64 {1d}\n %v{0d} = load i64,ptr %a{0d},align 1\n", .{ i, i * 8 });
        try text.writer.print(" %data = getelementptr i8,ptr %input,i64 48\n %answer = call {s}i64 @{s}(", .{ cc, body });
        for (0..6) |i| try text.writer.print("{s}i64 %v{d}", .{ if (i == 0) "" else ",", i });
        try text.writer.writeAll(",ptr %data,ptr %out)\n");
        for ([_][]const u8{ "%answer", "%salt", "%v0" }, 0..) |value, i| try text.writer.print(" %o{0d} = getelementptr i8,ptr %out,i64 {1d}\n store i64 {2s},ptr %o{0d},align 1\n", .{ i, n * 24 + i * 8, value });
        try text.writer.writeAll(" %result = xor i64 %answer,%salt\n ret i64 %result\n}\n");
        try driver.writer.print("extern uint64_t {s}(const void *,void *,uint64_t);\n", .{probe});
        try table.writer.print("{{{s},{d}}},\n", .{ probe, n });
    };
    if (id != 16) return error.CaseInventoryChanged;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "pointer_constants.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "pointer_constants_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "pointer_constants", .fixture = "pointer_constants", .prefix = "pointer-constants", .functions = functions, .observations = 10240, .stdout = "pointer-constants observations=10240 exact-pointer-bits=literal-vectors=inserted-lanes=live-aliases=stack-calls=guard-pages=preserved\n" });
    return entry;
}
fn mask3InputArguments(c: *u.Context, w: *std.Io.Writer, first: bool, values: bool) !void {
    var count: usize = 0;
    for (0..2) |part| {
        const masks = (part == 0) == first;
        if (masks) {
            for (0..2) |i| {
                try w.print("{s}<3 x i1>{s}", .{ if (count == 0) "" else ",", if (values) (if (i == 0) " %a" else " %b") else "" });
                count += 1;
            }
        } else for (0..6) |i| {
            try w.print("{s}i64{s}", .{ if (count == 0) "" else ",", if (values) try c.fmt(" %p{d}", .{i}) else "" });
            count += 1;
        }
    }
    try w.print(",ptr{s}", .{if (values) " %out" else ""});
}

fn mask3Input(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_mask3Input_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var id: usize = 0;
    for ([_]bool{ false, true }) |first| for ([_][]const u8{ "", "fastcc " }) |cc| {
        const body = try c.fmt("mask3_input_body_{d}", .{id});
        const probe = try c.fmt("mask3_input_probe_{d}", .{id});
        const external = try c.fmt("mask3_input_provider_{d}", .{id});
        id += 1;
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("declare {s}i64 @{s}(", .{ cc, external });
        try mask3InputArguments(c, &text.writer, first, false);
        try text.writer.writeAll(")\n");
        try text.writer.print("define {s}i64 @{s}(", .{ cc, body });
        try mask3InputArguments(c, &text.writer, first, true);
        try text.writer.writeAll(") noinline {\nentry:\n");
        for (0..6) |i| try text.writer.print(" %lane{0d} = extractelement <3 x i1> %{1s},i32 {2d}\n %v{0d} = zext i1 %lane{0d} to i64\n %shift{0d} = shl i64 %v{0d},{0d}\n %bits{0d} = or i64 {3s},%shift{0d}\n", .{ i, if (i < 3) "a" else "b", i % 3, if (i == 0) "0" else try c.fmt("%bits{d}", .{i - 1}) });
        try text.writer.writeAll(" %oa = getelementptr i8,ptr %out,i64 24\n %ob = getelementptr i8,ptr %out,i64 25\n store <3 x i1> %a,ptr %oa,align 1\n store <3 x i1> %b,ptr %ob,align 1\n");
        for (0..6) |i| try text.writer.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n", .{ i, if (i == 0) "%bits5" else try c.fmt("%r{d}", .{i - 1}) });
        try text.writer.writeAll(" ret i64 %r5\n}\n");
        try text.writer.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n", .{probe});
        for (0..6) |i| try text.writer.print(" %ap{0d} = getelementptr i8,ptr %input,i64 {1d}\n %p{0d} = load i64,ptr %ap{0d},align 1\n", .{ i, i * 8 });
        try text.writer.writeAll(" %av = getelementptr i8,ptr %input,i64 48\n %bv = getelementptr i8,ptr %input,i64 49\n %a = load <3 x i1>,ptr %av,align 1\n %b = load <3 x i1>,ptr %bv,align 1\n");
        for ([_][]const u8{ body, external }, 0..) |callee, i| {
            try text.writer.print(" %answer{d} = call {s}i64 @{s}(", .{ i, cc, callee });
            try mask3InputArguments(c, &text.writer, first, true);
            try text.writer.writeAll(")\n");
        }
        for ([_][]const u8{ "%answer0", "%answer1", "%p0" }, 0..) |value, i| try text.writer.print(" %o{0d} = getelementptr i8,ptr %out,i64 {1d}\n store i64 {2s},ptr %o{0d},align 1\n", .{ i, i * 8, value });
        try text.writer.writeAll(" %result = xor i64 %answer0,%salt\n ret i64 %result\n}\n");
        try driver.writer.print("extern uint64_t {s}(const void *,void *,uint64_t);\nextern uint64_t {s}(", .{ probe, body });
        for (0..12) |i| try driver.writer.print("{s}uint64_t", .{if (i == 0) "" else ","});
        try driver.writer.print(",void *);\nuint64_t {s}(", .{external});
        for (0..12) |i| try driver.writer.print("{s}uint64_t {s}{d}", .{ if (i == 0) "" else ",", if ((i < 6) == first) "b" else "w", i % 6 });
        try driver.writer.writeAll(",void *out){uint64_t w[]={w0,w1,w2,w3,w4,w5},b[]={b0,b1,b2,b3,b4,b5};return provider(w,b,out);}\n");
        try table.writer.print("{{{s},{s},{d}}},\n", .{ probe, body, @intFromBool(first) });
    };
    if (id != 4) return error.CaseInventoryChanged;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "mask3_input.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "mask3_input_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "mask3_input", .fixture = "mask3_input", .prefix = "mask3-input", .functions = functions, .observations = 4352, .stdout = "mask3-input observations=4352 c-direct-entry=external-provider=dirty-carriers=packed-bits=live-aliases=stack-calls=guard-pages=preserved\n" });
    return entry;
}

fn packedFloatExtract(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_packedFloatExtract_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var id: usize = 0;
    for ([_]bool{ false, true }) |literal| for ([_][]const u8{ "", "fastcc " }) |cc| {
        const body = try c.fmt("packed_float_extract_body_{d}", .{id});
        const probe = try c.fmt("packed_float_extract_probe_{d}", .{id});
        const global = try c.fmt("packed_float_extract_global_{d}", .{id});
        id += 1;
        try u.add(&functions, u.s(body));
        try u.add(&functions, u.s(probe));
        try text.writer.print("@{s} = global <2 x float> zeroinitializer,align 8\ndefine {s}i64 @{s}(", .{ global, cc, body });
        for (0..6) |i| try text.writer.print("{s}i64 %p{d}", .{ if (i == 0) "" else ",", i });
        try text.writer.writeAll(",ptr %input,ptr %out) noinline {\nentry:\n %input_value = load <2 x float>,ptr %input,align 1\n");
        try text.writer.print(" store <2 x float> {s},ptr @{s},align 8\n %again = load <2 x float>,ptr @{s},align 8\n %lo = extractelement <2 x float> %again,i32 0\n %hi = extractelement <2 x float> %again,i32 1\n %out_lo_bits = bitcast float %lo to i32\n %out_hi_bits = bitcast float %hi to i32\n store i32 %out_lo_bits,ptr %out,align 1\n %out_hi = getelementptr i8,ptr %out,i64 4\n store i32 %out_hi_bits,ptr %out_hi,align 1\n %swap0 = insertelement <2 x float> poison,float %hi,i32 0\n %swap1 = insertelement <2 x float> %swap0,float %lo,i32 1\n store <2 x float> %swap1,ptr @{s},align 8\n %lobits = bitcast float %lo to i32\n %hibits = bitcast float %hi to i32\n %lowide = zext i32 %lobits to i64\n %hiwide = zext i32 %hibits to i64\n %shifted = shl i64 %hiwide,32\n %raw = or i64 %lowide,%shifted\n", .{ if (literal) "<float 0.000000e+00,float 1.000000e+00>" else "%input_value", global, global, global });
        for (0..6) |i| try text.writer.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n", .{ i, if (i == 0) "%raw" else try c.fmt("%r{d}", .{i - 1}) });
        try text.writer.writeAll(" ret i64 %r5\n}\n");
        try text.writer.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n", .{probe});
        for (0..6) |i| try text.writer.print(" %a{0d} = getelementptr i8,ptr %input,i64 {1d}\n %v{0d} = load i64,ptr %a{0d},align 1\n", .{ i, i * 8 });
        try text.writer.print(" %data = getelementptr i8,ptr %input,i64 48\n %answer = call {s}i64 @{s}(", .{ cc, body });
        for (0..6) |i| try text.writer.print("{s}i64 %v{d}", .{ if (i == 0) "" else ",", i });
        try text.writer.writeAll(",ptr %data,ptr %out)\n");
        for ([_][]const u8{ "%answer", "%salt", "%v0" }, 0..) |value, i| try text.writer.print(" %o{0d} = getelementptr i8,ptr %out,i64 {1d}\n store i64 {2s},ptr %o{0d},align 1\n", .{ i, 8 + i * 8, value });
        try text.writer.writeAll(" %result = xor i64 %answer,%salt\n ret i64 %result\n}\n");
        try driver.writer.print("extern uint64_t {s}(const void *,void *,uint64_t);\nextern uint32_t {s}[2];\n", .{ probe, global });
        try table.writer.print("{{{s},{s},{d}}},\n", .{ probe, global, @intFromBool(literal) });
    };
    if (id != 4) return error.CaseInventoryChanged;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "packed_float_extract.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "packed_float_extract_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "packed_float_extract", .fixture = "packed_float_extract", .prefix = "packed-float-extract", .functions = functions, .observations = 2560, .stdout = "packed-float-extract observations=2560 exact-eight-byte-storage=literal-lanes=all-payload-moves=global-roundtrip=live-aliases=guard-pages=preserved\n" });
    return entry;
}

fn oddPairBitreverse(c: *u.Context, target: []const u8) !u.Value {
    const fixtures = target;
    var text: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var table: std.Io.Writer.Allocating = .init(c.a);
    var functions = u.array(c.a);
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");
    try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_oddPairBitreverse_core.c"})));
    try table.writer.writeAll("static const struct test_case cases[]={\n");
    var id: usize = 0;
    for ([_]usize{ 65, 66, 79, 80, 94, 95, 96, 97, 111, 112, 126, 127 }) |bits| {
        try text.writer.print("declare i{0d} @llvm.bitreverse.i{0d}(i{0d})\n", .{bits});
        for ([_][]const u8{ "", "fastcc " }) |cc| {
            const body = try c.fmt("odd_pair_reverse_body_{d}", .{id});
            const probe = try c.fmt("odd_pair_reverse_probe_{d}", .{id});
            id += 1;
            try u.add(&functions, u.s(body));
            try u.add(&functions, u.s(probe));
            try text.writer.print("define {s}i64 @{s}(", .{ cc, body });
            for (0..6) |i| try text.writer.print("{s}i64 %p{d}", .{ if (i == 0) "" else ",", i });
            try text.writer.print(",i{0d} %a,ptr %out) noinline {{\nentry:\n %reverse = call i{0d} @llvm.bitreverse.i{0d}(i{0d} %a)\n store i{0d} %reverse,ptr %out,align 1\n %wide = zext i{0d} %reverse to i128\n %lo = trunc i128 %wide to i64\n %shifted = lshr i128 %wide,64\n %hi = trunc i128 %shifted to i64\n %raw = xor i64 %lo,%hi\n", .{bits});
            for (0..6) |i| try text.writer.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n", .{ i, if (i == 0) "%raw" else try c.fmt("%r{d}", .{i - 1}) });
            try text.writer.writeAll(" ret i64 %r5\n}\n");
            try text.writer.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n", .{probe});
            for (0..6) |i| try text.writer.print(" %ap{0d} = getelementptr i8,ptr %input,i64 {1d}\n %p{0d} = load i64,ptr %ap{0d},align 1\n", .{ i, i * 8 });
            try text.writer.print(" %data = getelementptr i8,ptr %input,i64 48\n %a = load i{d},ptr %data,align 1\n %answer = call {s}i64 @{s}(", .{ bits, cc, body });
            for (0..6) |i| try text.writer.print("{s}i64 %p{d}", .{ if (i == 0) "" else ",", i });
            try text.writer.print(",i{d} %a,ptr %out)\n", .{bits});
            for ([_][]const u8{ "%answer", "%salt", "%p0" }, 0..) |value, i| try text.writer.print(" %o{0d} = getelementptr i8,ptr %out,i64 {1d}\n store i64 {2s},ptr %o{0d},align 1\n", .{ i, (bits + 7) / 8 + i * 8, value });
            try text.writer.writeAll(" %result = xor i64 %answer,%salt\n ret i64 %result\n}\n");
            try driver.writer.print("extern uint64_t {s}(const void *,void *,uint64_t);\nextern uint64_t {s}(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,u128,void *);\n", .{ probe, body });
            try table.writer.print("{{{s},{s},{d}}},\n", .{ probe, body, bits });
        }
    }
    if (id != 24) return error.CaseInventoryChanged;
    try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");
    try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{ fixtures, "odd_pair_bitreverse.ll" }), text.written());
    try c.write(try c.join(&.{ fixtures, "odd_pair_bitreverse_driver.c" }), driver.written());
    const entry = try u.toValue(c.a, .{ .population = "odd_pair_bitreverse", .fixture = "odd_pair_bitreverse", .prefix = "odd-pair-bitreverse", .functions = functions, .observations = 147456, .stdout = "odd-pair-bitreverse observations=147456 independent-bit-loop=all-basis-bits=dirty-upper-bits=exact-tails=c-direct-entry=live-aliases=stack-calls=guard-pages=preserved\n" });
    return entry;
}

const integer_undef_client_template=" rolq  $$3,  %rdi ; rolq $$13, %rdi\\0A rolq  $$61, %rdi ; rolq $$51, %rdi\\0A xchgq %rbx, %rbx";
const integer_undef_client_constraints="={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}";
fn integerUndefCase(c:*u.Context,text:*std.Io.Writer,driver:*std.Io.Writer,table:*std.Io.Writer,functions:*u.Value,id:usize,kind:usize,bits:usize,to:usize,cc:[]const u8) !void{
 const body=try c.fmt("integer_undef_body_{d}",.{id});const probe=try c.fmt("integer_undef_probe_{d}",.{id});try u.add(functions,u.s(body));try u.add(functions,u.s(probe));const extent=((if(kind==2)bits else to)+7)/8;
 try text.print("define {s}i64 @{s}(",.{cc,body});for(0..6) |i|try text.print("{s}i64 %p{d}",.{if(i==0)"" else ",",i});try text.writeAll(",ptr %out) noinline {\nentry:\n %header = alloca [6 x i64],align 8\n");for(0..6) |i|try text.print(" %h{0d} = getelementptr i8,ptr %header,i64 {1d}\n store i64 %p{0d},ptr %h{0d},align 8\n",.{i,i*8});
 if(kind==2)try text.print(" store i{d} undef,ptr %out,align 1\n",.{bits}) else if(kind==3)try text.print(" %narrow = trunc i64 undef to i{0d}\n %value = zext i{0d} %narrow to i64\n store i64 %value,ptr %out,align 1\n",.{bits}) else try text.print(" %value = {s} i{d} undef to i{d}\n store i{d} %value,ptr %out,align 1\n",.{if(kind==0)"zext" else "sext",bits,to,to});
 try text.print(" %request = ptrtoint ptr %header to i64\n %client = call i64 asm sideeffect \"{s}\", \"{s}\"(i64 %request,i64 %p4)\n",.{integer_undef_client_template,integer_undef_client_constraints});if(kind==2)try text.print(" store i64 %p0,ptr %out,align 1\n %last = getelementptr i8,ptr %out,i64 {d}\n store i64 %p1,ptr %last,align 1\n",.{extent-8});try text.print(" %marker = getelementptr i8,ptr %out,i64 {d}\n store i64 %client,ptr %marker,align 1\n",.{extent});for(0..6) |i|try text.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n",.{i,if(i==0)"%client" else try c.fmt("%r{d}",.{i-1})});try text.writeAll(" ret i64 %r5\n}\n");
 try text.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n",.{probe});for(0..6) |i|try text.print(" %a{0d} = getelementptr i8,ptr %input,i64 {1d}\n %v{0d} = load i64,ptr %a{0d},align 1\n",.{i,i*8});try text.print(" %answer = call {s}i64 @{s}(",.{cc,body});for(0..6) |i|try text.print("{s}i64 %v{d}",.{if(i==0)"" else ",",i});try text.writeAll(",ptr %out)\n");for([_][]const u8{"%answer","%salt","%v0"},0..) |value,i|try text.print(" %o{0d} = getelementptr i8,ptr %out,i64 {1d}\n store i64 {2s},ptr %o{0d},align 1\n",.{i,extent+8+i*8,value});try text.writeAll(" %result = xor i64 %answer,%salt\n ret i64 %result\n}\n");try driver.print("extern uint64_t {s}(const void *,void *,uint64_t);\n",.{probe});try table.print("{{{s},{d},{d},{d}}},\n",.{probe,kind,bits,to});
}

fn integerUndef(c:*u.Context,destination:[]const u8) !u.Value {
 const fixtures=destination;
var text:std.Io.Writer.Allocating=.init(c.a);var driver:std.Io.Writer.Allocating=.init(c.a);var table:std.Io.Writer.Allocating=.init(c.a);var functions=u.array(c.a);var id:usize=0;
 try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_integerUndef_core.c"})));try table.writer.writeAll("static const struct test_case cases[]={\n");
 for([_]usize{1,4,7,15,31}) |bits| for([_]usize{8,16,32,64}) |to|{if(bits>=to)continue;for(0..2) |kind| for([_][]const u8{"","fastcc "}) |cc|{try integerUndefCase(c,&text.writer,&driver.writer,&table.writer,&functions,id,kind,bits,to,cc);id+=1;};};
 for([_]usize{8,63}) |bits| for([_][]const u8{"","fastcc "}) |cc|{try integerUndefCase(c,&text.writer,&driver.writer,&table.writer,&functions,id,3,bits,64,cc);id+=1;};
 for([_]usize{129,512,800,1024,64000}) |bits| for([_][]const u8{"","fastcc "}) |cc|{try integerUndefCase(c,&text.writer,&driver.writer,&table.writer,&functions,id,2,bits,0,cc);id+=1;};
 if(id!=82)return error.CaseInventoryChanged;try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");try driver.writer.writeAll(table.written());try c.write(try c.join(&.{fixtures,"integer_undef.ll"}),text.written());try c.write(try c.join(&.{fixtures,"integer_undef_driver.c"}),driver.written());const entry=try u.toValue(c.a,.{.population="integer_undef",.fixture="integer_undef",.prefix="integer-undef",.functions=functions,.observations=47872,.stdout="integer-undef observations=47872 refinement-domains=defined-endpoints=guard-pages=live-aliases=client-request-marker=preserved\n"});
 return entry;
}

fn nativeLiteralTruncation(c:*u.Context,destination:[]const u8) !u.Value {
 const fixtures=destination;
var text:std.Io.Writer.Allocating=.init(c.a);var driver:std.Io.Writer.Allocating=.init(c.a);var table:std.Io.Writer.Allocating=.init(c.a);var functions=u.array(c.a);
 try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_nativeLiteralTruncation_core.c"})));try table.writer.writeAll("static const struct test_case cases[]={\n");var id:usize=0;
 for([_][2]usize{.{16,8},.{32,8},.{32,16},.{64,8},.{64,16},.{64,32}}) |widths| {
  const source=widths[0];const target=widths[1];const limit=@as(u128,1)<<@as(u7,@intCast(source));const mask=limit-1;const sign=limit>>1;
  for([_]u128{0,1,mask,sign,sign-1,mask-1},0..) |raw,sample| for([_][]const u8{"","fastcc "}) |cc| {
   const body=try c.fmt("literal_truncation_body_{d}",.{id});const probe=try c.fmt("literal_truncation_probe_{d}",.{id});id+=1;try u.add(&functions,u.s(body));try u.add(&functions,u.s(probe));
   try text.writer.print("define {s}i64 @{s}(",.{cc,body});for(0..6) |i|try text.writer.print("{s}i64 %p{d}",.{if(i==0)"" else ",",i});try text.writer.writeAll(",ptr %out) noinline {\nentry:\n");
   const literal: i128=if(sample==2 or sample==3)@as(i128,@intCast(raw))-@as(i128,@intCast(limit)) else @intCast(raw);
   try text.writer.print(" %value = trunc i{d} {d} to i{d}\n %wide = zext i{d} %value to i64\n",.{source,literal,target,target});
   for(0..6) |i|try text.writer.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n",.{i,if(i==0)"%wide" else try c.fmt("%r{d}",.{i-1})});try text.writer.writeAll(" ret i64 %r5\n}\n");
   try text.writer.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n",.{probe});for(0..6) |i|try text.writer.print(" %a{0d} = getelementptr i8,ptr %input,i64 {1d}\n %v{0d} = load i64,ptr %a{0d},align 1\n",.{i,i*8});
   try text.writer.print(" %answer = call {s}i64 @{s}(",.{cc,body});for(0..6) |i|try text.writer.print("{s}i64 %v{d}",.{if(i==0)"" else ",",i});try text.writer.writeAll(",ptr %out)\n store i64 %answer,ptr %out,align 1\n %o1 = getelementptr i8,ptr %out,i64 8\n store i64 %salt,ptr %o1,align 1\n %o2 = getelementptr i8,ptr %out,i64 16\n store i64 %v0,ptr %o2,align 1\n %r = xor i64 %answer,%salt\n ret i64 %r\n}\n");
   try driver.writer.print("extern uint64_t {s}(const void *,void *,uint64_t);\n",.{probe});try table.writer.print("{{{s},0,0,{d},{d},UINT64_C({d}),UINT64_C(0)}},\n",.{probe,source,target,raw});
  };
 }
 if(id!=72)return error.CaseInventoryChanged;try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");try driver.writer.writeAll(table.written());
 try c.write(try c.join(&.{fixtures,"native_literal_truncation.ll"}),text.written());try c.write(try c.join(&.{fixtures,"native_literal_truncation_driver.c"}),driver.written());
 const observations=id*64*7; const expected_stdout=try c.fmt("native-literal-truncation observations={d} integer-mask-model=native-widths=literal-spellings=live-aliases=stack-calls=guard-pages=preserved\n",.{observations});
 const entry=try u.toValue(c.a,.{.population="native_literal_truncation",.fixture="native_literal_truncation",.prefix="native-literal-truncation",.functions=functions,.observations=observations,.stdout=expected_stdout});
 return entry;
}

fn memoryLimbLiteral(c:*u.Context,bits:usize,pattern:usize) ![]const u8 {
    if(pattern==0)return "0";if(pattern==1)return "-1";
    var words:[16]u64=@splat(0);const at=(bits-1)/64;const bit:@TypeOf(@as(u6,0))=@intCast((bits-1)%64);
    if(pattern==2)words[at]=@as(u64,1)<<bit else {for(words[0..at]) |*word|word.*=std.math.maxInt(u64);words[at]=(@as(u64,1)<<bit)-1;}
    var digits:std.ArrayList(u8)=.empty;
    while(true){var carry:u128=0;var nonzero=false;var i:usize=words.len;while(i>0){i-=1;const value=(carry<<64)|words[i];words[i]=@intCast(value/10);carry=value%10;nonzero=nonzero or words[i]!=0;}try digits.append(c.a,'0'+@as(u8,@intCast(carry)));if(!nonzero)break;}
    std.mem.reverse(u8,digits.items);return if(pattern==2)try c.fmt("-{s}",.{digits.items}) else digits.items;
}
fn memoryLimbCase(c:*u.Context,text:*std.Io.Writer,driver:*std.Io.Writer,table:*std.Io.Writer,functions:*u.Value,id:usize,kind:usize,from:usize,to:usize,predicate:usize,pattern:usize,cc:[]const u8) !void {
    const body=try c.fmt("memory_limbs_body_{d}",.{id});const probe=try c.fmt("memory_limbs_probe_{d}",.{id});try u.add(functions,u.s(body));try u.add(functions,u.s(probe));
    try text.print("define {s}i64 @{s}(",.{cc,body});for(0..6) |i|try text.print("{s}i64 %p{d}",.{if(i==0)"" else ",",i});try text.writeAll(",ptr %input,ptr %out,i64 %salt) noinline {\nentry:\n");
    if(kind!=5)try text.print(" %x = load i{d},ptr %input,align 1\n",.{from});
    var initial:[]const u8="%low";var payload=(to+7)/8;
    if(kind==1){
        const names=[_][]const u8{"eq","ne","ult","ule","ugt","uge","slt","sle","sgt","sge"};
        try text.print(" %yp = getelementptr i{0d},ptr %input,i64 1\n %y = load i{0d},ptr %yp,align 1\n %condition = icmp {1s} i{0d} %x,%y\n %selected = select i1 %condition,i{0d} %x,i{0d} %y\n %slot = alloca i{0d},align 16\n store i{0d} %selected,ptr %slot,align 16\n %slot0 = getelementptr i{0d},ptr %slot,i64 0\n %roundtrip = load i{0d},ptr %slot0,align 16\n store i{0d} %roundtrip,ptr %out,align 1\n br i1 %condition,label %left,label %right\nleft:\n br label %join\nright:\n br label %join\njoin:\n %chosen = phi i{0d} [%y,%left],[%x,%right]\n %defined = freeze i{0d} %chosen\n %other = getelementptr i8,ptr %out,i64 {2d}\n store i{0d} %defined,ptr %other,align 1\n %first = trunc i{0d} %roundtrip to i64\n %second = trunc i{0d} %defined to i64\n %mix = xor i64 %first,%second\n %flag = zext i1 %condition to i64\n %initial = xor i64 %mix,%flag\n",.{from,names[predicate],payload});
        initial="%initial";payload*=2;
    } else {
        if(kind==0)try text.print(" %value = freeze i{0d} %x\n",.{from}) else if(kind==5) {
            try text.print(" store i{0d} {1s},ptr %out,align 1\n %value = load i{0d},ptr %out,align 1\n",.{to,try memoryLimbLiteral(c,to,pattern)});
        } else try text.print(" %value = {s} i{d} %x to i{d}\n",.{switch(kind){2=>"trunc",3=>"zext",4=>"sext",else=>unreachable},from,to});
        try text.print(" store i{d} %value,ptr %out,align 1\n",.{to});
        if(to==64)initial="%value" else try text.print(" %low = {s} i{d} %value to i64\n",.{if(to>64)"trunc" else "zext",to});
    }
    for(0..6) |i|try text.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n",.{i,if(i==0)initial else try c.fmt("%r{d}",.{i-1})});
    for([_][]const u8{"%r5","%salt","%p0"},0..) |value,i|try text.print(" %record{0d} = getelementptr i8,ptr %out,i64 {1d}\n store i64 {2s},ptr %record{0d},align 1\n",.{i,payload+i*8,value});try text.writeAll(" %result = xor i64 %r5,%salt\n ret i64 %result\n}\n");
    try text.print("define i64 @{s}(ptr %input,ptr %out,i64 %salt) {{\nentry:\n",.{probe});for(0..6) |i|try text.print(" %a{0d} = getelementptr i8,ptr %input,i64 {1d}\n %v{0d} = load i64,ptr %a{0d},align 1\n",.{i,i*8});
    const stride=((from+127)/128)*16;try text.print(" %xp = getelementptr i8,ptr %input,i64 {d}\n %answer = call {s}i64 @{s}(",.{if(kind==1)48 else 48+stride,cc,body});for(0..6) |i|try text.print("{s}i64 %v{d}",.{if(i==0)"" else ",",i});try text.writeAll(",ptr %xp,ptr %out,i64 %salt)\n ret i64 %answer\n}\n");
    try driver.print("extern uint64_t {s}(const void *,void *,uint64_t);\n",.{probe});try table.print("{{{s},{d},{d},{d},{d},{d}}},\n",.{probe,kind,from,to,predicate,pattern});
}

fn memoryLimbs(c:*u.Context,destination:[]const u8) !u.Value {
 const fixtures=destination;
var text:std.Io.Writer.Allocating=.init(c.a);var driver:std.Io.Writer.Allocating=.init(c.a);var table:std.Io.Writer.Allocating=.init(c.a);var functions=u.array(c.a);var id:usize=0;
    try text.writer.writeAll("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ntarget triple = \"x86_64-unknown-linux-gnu\"\n");try driver.writer.writeAll(try c.read(try c.join(&.{"tools/templates/behavior_memoryLimbs_core.c"})));try table.writer.writeAll("static const struct test_case cases[]={\n");
    for([_]usize{800,896,1024}) |bits| {
        for([_][]const u8{"","fastcc "}) |cc| {
            try memoryLimbCase(c,&text.writer,&driver.writer,&table.writer,&functions,id,0,bits,bits,0,0,cc);id+=1;
            for(0..10) |predicate|{try memoryLimbCase(c,&text.writer,&driver.writer,&table.writer,&functions,id,1,bits,bits,predicate,0,cc);id+=1;}
            for(0..4) |pattern|{try memoryLimbCase(c,&text.writer,&driver.writer,&table.writer,&functions,id,5,bits,bits,0,pattern,cc);id+=1;}
            for([_]usize{8,16,32,64,128}) |small| {
                try memoryLimbCase(c,&text.writer,&driver.writer,&table.writer,&functions,id,2,bits,small,0,0,cc);id+=1;
                for([_]usize{3,4}) |kind|{try memoryLimbCase(c,&text.writer,&driver.writer,&table.writer,&functions,id,kind,small,bits,0,0,cc);id+=1;}
            }
        }
    }
    for([_][2]usize{.{800,896},.{800,1024},.{896,1024}}) |pair|for([_][]const u8{"","fastcc "}) |cc| {
        for([_]usize{3,4}) |kind|{try memoryLimbCase(c,&text.writer,&driver.writer,&table.writer,&functions,id,kind,pair[0],pair[1],0,0,cc);id+=1;}
        try memoryLimbCase(c,&text.writer,&driver.writer,&table.writer,&functions,id,2,pair[1],pair[0],0,0,cc);id+=1;
    };
    if(id!=198)return error.CaseInventoryChanged;try table.writer.writeAll("};\nint main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}\n");try driver.writer.writeAll(table.written());
    try c.write(try c.join(&.{fixtures,"memory_limbs.ll"}),text.written());try c.write(try c.join(&.{fixtures,"memory_limbs_driver.c"}),driver.written());const observations=id*64*9;
    const entry=try u.toValue(c.a,.{.population="memory_limbs",.fixture="memory_limbs",.prefix="memory-limbs",.functions=functions,.observations=observations,.stdout=try c.fmt("memory-limbs observations={d} byte-model=integer-predicates=cast-domains=exact-tails=guard-pages=live-aliases=stack-calls=preserved\n",.{observations})});
 return entry;
}
