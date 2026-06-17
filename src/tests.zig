const std = @import("std");
const air_bridge = @import("air_bridge.zig");
const alias = @import("analysis/alias.zig");
const call_graph = @import("analysis/call_graph.zig");
const cfg = @import("analysis/cfg.zig");
const codegen = @import("codegen.zig");
const dominator = @import("analysis/dominator.zig");
const function_attrs = @import("analysis/function_attrs.zig");
const fp_semantics = @import("analysis/fp_semantics.zig");
const loop_info = @import("analysis/loop_info.zig");
const memory_effect = @import("analysis/memory_effect.zig");
const memory_location = @import("analysis/memory_location.zig");
const memory_ssa = @import("analysis/memory_ssa.zig");
const ir = @import("ir.zig");
const normalize = @import("normalize.zig");
const mc = @import("mc.zig");
const pass_manager = @import("pass_manager.zig");
const pipelines = @import("pipelines.zig");
const postdominator = @import("analysis/postdominator.zig");
const semantic_descriptor_v2 = @import("semantic_descriptor_v2.zig");
const target = @import("target.zig");
const target_library_info = @import("analysis/target_library_info.zig");
const target_transform_info = @import("analysis/target_transform_info.zig");
const instcombine = @import("passes/instcombine.zig");
const zig_air_export = @import("zig_air_export.zig");
const zig_air_lowering = @import("zig_air_lowering.zig");
const dce = @import("passes/dce.zig");
const dse = @import("passes/dse.zig");
const early_cse = @import("passes/early_cse.zig");
const gvn = @import("passes/gvn.zig");
const licm = @import("passes/licm.zig");
const mem2reg = @import("passes/mem2reg.zig");
const sccp = @import("passes/sccp.zig");
const simplifycfg = @import("passes/simplifycfg.zig");
const slp_vectorizer = @import("passes/slp_vectorizer.zig");
const sroa = @import("passes/sroa.zig");

test {
    _ = zig_air_export;
    _ = zig_air_lowering;
}

test "named pipelines expand to stable pass sequences" {
    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();

    try pipelines.addPasses(&pm, "scalar-foundation");

    const expected = [_][]const u8{
        "simplifycfg",
        "jump-threading",
        "correlated-propagation",
        "instcombine",
        "simplifycfg",
        "jump-threading",
        "correlated-propagation",
        "instcombine",
        "aggressive-instcombine",
        "lower-constant-intrinsics",
        "early-cse",
        "sccp",
        "gvn",
        "dce",
        "adce",
    };
    try std.testing.expectEqual(expected.len, pm.passes.items.len);
    for (expected, pm.passes.items) |expected_name, pass| {
        try std.testing.expectEqualStrings(expected_name, pass.name);
    }
}

test "zig scalar foundation pipeline aliases scalar foundation passes" {
    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();

    try pipelines.addPasses(&pm, "zig-scalar-foundation");

    const expected = [_][]const u8{
        "simplifycfg",
        "jump-threading",
        "correlated-propagation",
        "instcombine",
        "simplifycfg",
        "jump-threading",
        "correlated-propagation",
        "instcombine",
        "aggressive-instcombine",
        "lower-constant-intrinsics",
        "early-cse",
        "sccp",
        "gvn",
        "dce",
        "adce",
    };
    try std.testing.expectEqual(expected.len, pm.passes.items.len);
    for (expected, pm.passes.items) |expected_name, pass| {
        try std.testing.expectEqualStrings(expected_name, pass.name);
    }
}

test "Zig mode pipelines expand to stable pass and placeholder sequences" {
    var debug_pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer debug_pm.deinit();
    try pipelines.addPasses(&debug_pm, "debug-o0");

    const debug_expected = [_]struct {
        name: []const u8,
        category: pass_manager.PassCategory,
        status: []const u8,
    }{
        .{ .name = "verify", .category = .mandatory, .status = "LLVM-shaped algorithm subset" },
        .{ .name = "ee-instrument", .category = .instrumentation, .status = "placeholder" },
        .{ .name = "always-inline", .category = .ipo, .status = "LLVM-shaped subset for direct internal single-block calls" },
        .{ .name = "alloc-token", .category = .instrumentation, .status = "placeholder" },
        .{ .name = "annotation-remarks", .category = .instrumentation, .status = "placeholder" },
        .{ .name = "verify", .category = .mandatory, .status = "LLVM-shaped algorithm subset" },
    };
    try std.testing.expectEqual(debug_expected.len, debug_pm.passes.items.len);
    for (debug_expected, debug_pm.passes.items) |expected, pass| {
        try std.testing.expectEqualStrings(expected.name, pass.name);
        try std.testing.expectEqual(expected.category, pass.category);
        try std.testing.expectEqualStrings(expected.status, pass.target_status);
    }

    var release_pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer release_pm.deinit();
    try pipelines.addPasses(&release_pm, "release-o3");

    const release_expected = [_][]const u8{
        "verify",
        "add-discriminators",
        "forceattrs",
        "inferattrs",
        "sroa",
        "mem2reg",
        "simplifycfg",
        "jump-threading",
        "correlated-propagation",
        "instcombine",
        "simplifycfg",
        "jump-threading",
        "correlated-propagation",
        "instcombine",
        "aggressive-instcombine",
        "lower-constant-intrinsics",
        "early-cse",
        "sccp",
        "gvn",
        "dse",
        "adce",
        "loop-instsimplify",
        "licm",
        "loop-simplifycfg",
        "globalopt",
        "globaldce",
        "mergefunc",
        "annotation-remarks",
        "verify",
    };
    try std.testing.expectEqual(release_expected.len, release_pm.passes.items.len);
    for (release_expected, release_pm.passes.items) |expected_name, pass| {
        try std.testing.expectEqualStrings(expected_name, pass.name);
    }

    var corpus_pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer corpus_pm.deinit();
    try pipelines.addPasses(&corpus_pm, "zig-release-fast-accepted");

    const corpus_expected = [_][]const u8{
        "verify",
        "simplifycfg",
        "instcombine",
        "dce",
        "verify",
    };
    try std.testing.expectEqual(corpus_expected.len, corpus_pm.passes.items.len);
    for (corpus_expected, corpus_pm.passes.items) |expected_name, pass| {
        try std.testing.expectEqualStrings(expected_name, pass.name);
    }
}

test "inventory placeholders run as documented no-op passes" {
    const input =
        \\define i32 @placeholder(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, "verify,always-inline,aggressive-instcombine,drop-unnecessary-assumes,jump-threading,tailcallelim,lower-expect,div-rem-pairs,float2int,libcalls-shrinkwrap,inject-tli-mappings,rel-lookup-table-converter,dse,loop-rotate,loop-deletion,indvars,simple-loop-unswitch,loop-idiom,loop-sink,loop-unroll,loop-unroll-full,loop-distribute,loop-load-elim,extra-simple-loop-unswitch-passes,inline,argpromotion,called-value-propagation,callsite-splitting,deadargelim,constmerge,elim-avail-extern,recompute-globalsaa,globals-aa,require<branch-probability>,require<block-frequency>,annotation2metadata,sancov,module-tsan,tsan,memprof-remove-attributes,cg-profile,chr,transform-warning,loop-vectorize,slp-vectorizer,vector-combine,coro-early,coro-split,coro-elide,coro-cleanup,coro-annotation-elide,openmp-opt,openmp-opt-cgscc,canonicalize-aliases");

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    const result = try pm.run(&module, &context, &output.writer, false);
    try std.testing.expectEqual(pass_manager.PassResult.unchanged, result);

    var printed: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer printed.deinit();
    try module.print(&printed.writer);
    try std.testing.expectEqualStrings(input, printed.writer.buffered());
}

test "nested pipeline placeholders flatten accepted inner passes" {
    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();

    try pipelines.addPasses(&pm, "module(verify,function(instcombine,dce)),loop(licm),cgscc(always-inline)");

    const expected = [_][]const u8{
        "verify",
        "instcombine",
        "dce",
        "licm",
        "always-inline",
    };
    try std.testing.expectEqual(expected.len, pm.passes.items.len);
    for (expected, pm.passes.items) |expected_name, pass| {
        try std.testing.expectEqualStrings(expected_name, pass.name);
    }
}

test "nested pipeline placeholders reject unbalanced groups" {
    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();

    try std.testing.expectError(error.InvalidPassPipeline, pipelines.addPasses(&pm, "function(instcombine,dce"));
}

test "accepted Zig corpus pipelines exclude vector placeholders" {
    const aliases = [_][]const u8{
        "zig-debug-accepted",
        "zig-release-safe-accepted",
        "zig-release-fast-accepted",
        "zig-release-small-accepted",
    };
    const vector_passes = [_][]const u8{
        "loop-vectorize",
        "slp-vectorizer",
        "vector-combine",
    };

    for (aliases) |alias_name| {
        var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
        defer pm.deinit();
        try pipelines.addPasses(&pm, alias_name);
        for (vector_passes) |pass_name| {
            try std.testing.expect(!pipelineContainsPass(pm, pass_name));
        }
    }
}

test "accepted release pipeline notes keep target cost out of scope" {
    const release_fast = pipelines.find("zig-release-fast-accepted").?;
    try std.testing.expect(std.mem.indexOf(u8, release_fast.notes, "target-cost-sensitive") != null);
    try std.testing.expect(std.mem.indexOf(u8, release_fast.notes, "TTI") != null);

    const release_small = pipelines.find("zig-release-small-accepted").?;
    try std.testing.expect(std.mem.indexOf(u8, release_small.notes, "size-specific cost") != null);
    try std.testing.expect(std.mem.indexOf(u8, release_small.notes, "TTI") != null);
}

test "AArch64 accepted pipeline keeps target-sensitive passes out of scope" {
    const descriptor = pipelines.find("aarch64-target-independent").?;
    try std.testing.expect(std.mem.indexOf(u8, descriptor.notes, "TTI") != null);
    try std.testing.expect(std.mem.indexOf(u8, descriptor.notes, "DataLayout-sensitive memory") != null);

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, "aarch64-target-independent");

    const expected = [_][]const u8{
        "verify",
        "instcombine",
        "dce",
        "verify",
    };
    try std.testing.expectEqual(expected.len, pm.passes.items.len);
    for (expected, pm.passes.items) |expected_name, pass| {
        try std.testing.expectEqualStrings(expected_name, pass.name);
    }

    const blocked = [_][]const u8{
        "simplifycfg",
        "sroa",
        "mem2reg",
        "early-cse",
        "gvn",
        "dse",
        "licm",
        "loop-vectorize",
        "slp-vectorizer",
        "vector-combine",
        "div-rem-pairs",
        "libcalls-shrinkwrap",
    };
    for (blocked) |pass_name| {
        try std.testing.expect(!pipelineContainsPass(pm, pass_name));
    }
}

test "TargetTransformInfo skeleton exposes target vector costs" {
    const x86_tti = target_transform_info.TargetTransformInfo.forTriple("x86_64-unknown-linux-gnu");
    const aarch64_tti = target_transform_info.TargetTransformInfo.forTriple("aarch64-unknown-linux-gnu");
    const generic_tti = target_transform_info.TargetTransformInfo.forTriple("wasm32-wasi");

    const v4i32: ir.Type = .{ .vector = .{ .len = 4, .elem_ty = .{ .int = 32 } } };
    const v8i32: ir.Type = .{ .vector = .{ .len = 8, .elem_ty = .{ .int = 32 } } };

    try std.testing.expectEqual(@as(u32, 1), x86_tti.arithmeticInstrCost(.add, v4i32, .throughput).value);
    try std.testing.expectEqual(@as(u32, 1), aarch64_tti.shuffleCost(.permute, v4i32, .throughput).value);
    try std.testing.expectEqual(@as(u32, 2), x86_tti.arithmeticInstrCost(.add, v8i32, .throughput).value);
    try std.testing.expectEqual(@as(u32, 4), generic_tti.arithmeticInstrCost(.add, v4i32, .throughput).value);
    try std.testing.expectEqual(@as(u32, 0), x86_tti.scalarizationOverhead(v4i32).value);
    try std.testing.expectEqual(@as(u32, 8), x86_tti.scalarizationOverhead(v8i32).value);
}

test "lto prelink pipelines expose prelink placeholders without bitcode semantics" {
    const aliases = [_][]const u8{
        "lto-prelink-o3",
        "lto-prelink-oz",
    };

    for (aliases) |alias_name| {
        const descriptor = pipelines.find(alias_name).?;
        try std.testing.expect(std.mem.indexOf(u8, descriptor.llvm_analogue, "buildLTOPreLinkDefaultPipeline") != null);
        try std.testing.expect(std.mem.indexOf(u8, descriptor.notes, "no bitcode writer") != null);
        try std.testing.expect(std.mem.indexOf(u8, descriptor.notes, "ThinLTO summary") != null);

        var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
        defer pm.deinit();
        try pipelines.addPasses(&pm, alias_name);

        try std.testing.expect(pipelineContainsPass(pm, "verify"));
        try std.testing.expect(pipelineContainsPass(pm, "canonicalize-aliases"));
        try std.testing.expect(pipelineContainsPass(pm, "name-anon-globals"));
        try std.testing.expect(!pipelineContainsPass(pm, "loop-vectorize"));
        try std.testing.expect(!pipelineContainsPass(pm, "slp-vectorizer"));
    }
}

fn pipelineContainsPass(pm: pass_manager.ModulePassManager, pass_name: []const u8) bool {
    for (pm.passes.items) |pass| {
        if (std.mem.eql(u8, pass.name, pass_name)) return true;
    }
    return false;
}

test "debug and release mode pipelines expose mode-sensitive scalar behavior" {
    const input =
        \\define i32 @mode(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 0
        \\  ret i32 %x
        \\}
        \\
    ;

    var debug_module = try ir.Module.parse(std.testing.allocator, input);
    defer debug_module.deinit();
    var debug_pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer debug_pm.deinit();
    try pipelines.addPasses(&debug_pm, "debug-o0");
    var debug_context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var debug_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer debug_output.deinit();
    _ = try debug_pm.run(&debug_module, &debug_context, &debug_output.writer, false);
    try debug_module.print(&debug_output.writer);
    try std.testing.expectEqualStrings(input, debug_output.writer.buffered());

    var release_module = try ir.Module.parse(std.testing.allocator, input);
    defer release_module.deinit();
    var release_pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer release_pm.deinit();
    try pipelines.addPasses(&release_pm, "release-o3");
    var release_context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var release_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer release_output.deinit();
    _ = try release_pm.run(&release_module, &release_context, &release_output.writer, false);
    try release_module.print(&release_output.writer);

    const expected_release =
        \\define i32 @mode(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected_release, release_output.writer.buffered());
}

test "pass manager pass limit and timing output are deterministic without an io clock" {
    const input =
        \\define i32 @limit(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(.{ .name = "first", .run = noopPass });
    try pm.add(.{ .name = "second", .run = noopPass });

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.runWithOptions(&module, &context, &output.writer, .{
        .timing = true,
        .pass_limit = 1,
    });

    try std.testing.expectEqualStrings("; time first: 0 ns\n", output.writer.buffered());
}

fn noopPass(_: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    return .unchanged;
}

test "target triple and datalayout parse supported x86_64 linux records" {
    const triple = try target.Triple.parse("x86_64-unknown-linux-gnu");
    try std.testing.expect(triple.isX86_64());
    try std.testing.expect(triple.isLinux());
    try std.testing.expectEqualStrings("gnu", triple.abi.?);

    const layout = try target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-p:64:64-i64:64-f80:128-n8:16:32:64-S128");
    try std.testing.expectEqual(@as(u16, 64), try layout.pointerSizeBits());
    try std.testing.expectEqual(@as(u16, 64), try layout.pointerAbiAlignmentBits());
    try std.testing.expectEqual(@as(u16, 64), try layout.integerAbiAlignmentBits(64));
}

test "target matrix matches clang emitted datalayout records" {
    const cases = [_]struct {
        triple_text: []const u8,
        supported: target.SupportedTarget,
        datalayout: []const u8,
        pointer_bits: u16,
        pointer_align_bits: u16,
        integer_bits: u16,
        integer_align_bits: u16,
    }{
        .{
            .triple_text = "x86_64-unknown-linux-gnu",
            .supported = .x86_64_linux_gnu,
            .datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128",
            .pointer_bits = 64,
            .pointer_align_bits = 64,
            .integer_bits = 128,
            .integer_align_bits = 128,
        },
        .{
            .triple_text = "x86_64-unknown-linux-musl",
            .supported = .x86_64_linux_musl,
            .datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128",
            .pointer_bits = 64,
            .pointer_align_bits = 64,
            .integer_bits = 128,
            .integer_align_bits = 128,
        },
        .{
            .triple_text = "aarch64-unknown-linux-gnu",
            .supported = .aarch64_linux_gnu,
            .datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32",
            .pointer_bits = 64,
            .pointer_align_bits = 64,
            .integer_bits = 16,
            .integer_align_bits = 16,
        },
        .{
            .triple_text = "wasm32-unknown-wasi",
            .supported = .wasm32_wasi,
            .datalayout = "e-m:e-p:32:32-p10:8:8-p20:8:8-i64:64-i128:128-n32:64-S128-ni:1:10:20",
            .pointer_bits = 32,
            .pointer_align_bits = 32,
            .integer_bits = 64,
            .integer_align_bits = 64,
        },
    };

    for (cases) |case| {
        const triple = try target.Triple.parse(case.triple_text);
        try std.testing.expectEqual(case.supported, triple.supportedTarget().?);
        try std.testing.expect(triple.isSupported());

        const layout = try target.DataLayout.parse(case.datalayout);
        try std.testing.expectEqual(case.pointer_bits, try layout.pointerSizeBits());
        try std.testing.expectEqual(case.pointer_align_bits, try layout.pointerAbiAlignmentBits());
        try std.testing.expectEqual(case.integer_align_bits, try layout.integerAbiAlignmentBits(case.integer_bits));
    }
}

test "datalayout computes ABI padded aggregate layout" {
    const layout = try target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32");
    const aggregate_ty: ir.Type = .{ .aggregate = "{ i8, i32 }" };

    try std.testing.expectEqual(@as(u16, 64), try layout.pointerPreferredAlignmentBits());
    try std.testing.expectEqual(@as(u16, 32), try layout.integerPreferredAlignmentBits(8));
    try std.testing.expectEqual(@as(u16, 32), try layout.typeAbiAlignmentBits(aggregate_ty));
    try std.testing.expectEqual(@as(u64, 8), try layout.typeStoreSizeBytes(aggregate_ty));
    try std.testing.expectEqual(@as(i128, 0), try layout.aggregateFieldOffsetBytes(aggregate_ty, 0));
    try std.testing.expectEqual(@as(i128, 4), try layout.aggregateFieldOffsetBytes(aggregate_ty, 1));

    const array_ty: ir.Type = .{ .aggregate = "[2 x { i8, i32 }]" };
    try std.testing.expectEqual(@as(u64, 16), try layout.typeStoreSizeBytes(array_ty));
}

test "memory location aggregate helpers classify array elements as fields" {
    const array_ty: ir.Type = .{ .aggregate = "[3 x i32]" };

    try std.testing.expect(memory_location.aggregateFieldType(array_ty, 0).?.eql(.{ .int = 32 }));
    try std.testing.expect(memory_location.aggregateFieldType(array_ty, 2).?.eql(.{ .int = 32 }));
    try std.testing.expectEqual(@as(?ir.Type, null), memory_location.aggregateFieldType(array_ty, 3));
    try std.testing.expectEqual(@as(?i128, 0), memory_location.aggregateFieldOffset(array_ty, 0));
    try std.testing.expectEqual(@as(?i128, 8), memory_location.aggregateFieldOffset(array_ty, 2));
    try std.testing.expectEqual(@as(?i128, null), memory_location.aggregateFieldOffset(array_ty, 3));
}

test "memory locations can use module DataLayout for aggregate GEP offsets" {
    const input =
        \\target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32"
        \\target triple = "aarch64-unknown-linux-gnu"
        \\
        \\define i32 @field_ptr() {
        \\entry:
        \\  %slot = alloca { i8, i32 }
        \\  %field = getelementptr { i8, i32 }, ptr %slot, i32 0, i32 1
        \\  %value = load i32, ptr %field
        \\  ret i32 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const layout = try target.DataLayout.parse(module.target_datalayout.?);
    const function = module.functions.items[0];
    const location = memory_location.forPointerWithLayout(function, layout, .{ .named = "field" }) orelse return error.TestExpectedMemoryLocation;
    try std.testing.expectEqual(@as(i128, 4), location.offset.?);
    try std.testing.expectEqual(@as(u64, 8), location.size.?);
}

test "target triple parser accepts compact wasm32 wasi spelling" {
    const triple = try target.Triple.parse("wasm32-wasi");
    try std.testing.expect(triple.isWasm32());
    try std.testing.expect(triple.isWasi());
    try std.testing.expectEqualStrings("unknown", triple.vendor);
    try std.testing.expectEqual(target.SupportedTarget.wasm32_wasi, triple.supportedTarget().?);
}

test "target library info exposes conservative per-target libcalls" {
    const linux = target_library_info.Info.init(try target.Triple.parse("x86_64-unknown-linux-gnu"));
    try std.testing.expect(linux.has(.memcpy));
    try std.testing.expect(linux.has(.sqrt));
    try std.testing.expect(linux.hasName("memset"));
    try std.testing.expect(!linux.hasName("unknown_libcall"));

    const wasi = target_library_info.Info.init(try target.Triple.parse("wasm32-wasi"));
    try std.testing.expect(wasi.has(.memcpy));
    try std.testing.expect(!wasi.has(.sqrt));
}

test "target ABI classifies scalar function signatures" {
    const cases = [_]struct {
        triple_text: []const u8,
        datalayout: []const u8,
        pointer_bits: u16,
    }{
        .{
            .triple_text = "x86_64-unknown-linux-gnu",
            .datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128",
            .pointer_bits = 64,
        },
        .{
            .triple_text = "x86_64-unknown-linux-musl",
            .datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128",
            .pointer_bits = 64,
        },
        .{
            .triple_text = "aarch64-unknown-linux-gnu",
            .datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32",
            .pointer_bits = 64,
        },
        .{
            .triple_text = "wasm32-unknown-wasi",
            .datalayout = "e-m:e-p:32:32-p10:8:8-p20:8:8-i64:64-i128:128-n32:64-S128-ni:1:10:20",
            .pointer_bits = 32,
        },
    };

    for (cases) |case| {
        const triple = try target.Triple.parse(case.triple_text);
        const layout = try target.DataLayout.parse(case.datalayout);

        const void_ret = try target.abi.classifyReturn(triple, layout, .void);
        try std.testing.expectEqual(target.AbiSlot.ret, void_ret.slot);
        try std.testing.expectEqual(target.AbiValueClass.ignore, void_ret.value_class);

        const int_ret = try target.abi.classifyReturn(triple, layout, .{ .int = 32 });
        try std.testing.expectEqual(target.AbiValueClass.integer, int_ret.value_class);
        try std.testing.expectEqual(@as(u16, 32), int_ret.size_bits);

        const ptr_param = try target.abi.classifyParam(triple, layout, .ptr);
        try std.testing.expectEqual(target.AbiSlot.param, ptr_param.slot);
        try std.testing.expectEqual(target.AbiValueClass.pointer, ptr_param.value_class);
        try std.testing.expectEqual(case.pointer_bits, ptr_param.size_bits);

        try std.testing.expectError(error.UnsupportedAbiType, target.abi.classifyParam(triple, layout, .void));
    }
}

test "target ABI classifies project IR function signatures" {
    const input =
        \\target datalayout = "e-m:e-p:64:64-i64:64"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define ptr @ptr_id(ptr %p, i32 %a) {
        \\entry:
        \\  ret ptr %p
        \\}
        \\
        \\define void @void_fn() {
        \\entry:
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const triple = try target.Triple.parse(module.target_triple.?);
    const layout = try target.DataLayout.parse(module.target_datalayout.?);

    var ptr_signature = try target.abi.classifyFunction(std.testing.allocator, triple, layout, module.functions.items[0]);
    defer ptr_signature.deinit(std.testing.allocator);
    try std.testing.expectEqual(target.AbiValueClass.pointer, ptr_signature.return_value.value_class);
    try std.testing.expectEqual(@as(u16, 64), ptr_signature.return_value.size_bits);
    try std.testing.expectEqual(@as(usize, 2), ptr_signature.params.items.len);
    try std.testing.expectEqual(target.AbiValueClass.pointer, ptr_signature.params.items[0].value_class);
    try std.testing.expectEqual(target.AbiValueClass.integer, ptr_signature.params.items[1].value_class);

    var void_signature = try target.abi.classifyFunction(std.testing.allocator, triple, layout, module.functions.items[1]);
    defer void_signature.deinit(std.testing.allocator);
    try std.testing.expectEqual(target.AbiValueClass.ignore, void_signature.return_value.value_class);
    try std.testing.expectEqual(@as(usize, 0), void_signature.params.items.len);
}

test "AIR-like bridge lowers scalar binary function" {
    const params = [_]air_bridge.Param{
        .{ .name = "a", .ty = .{ .int = 32 } },
        .{ .name = "b", .ty = .{ .int = 32 } },
    };
    const binaries = [_]air_bridge.Binary{
        .{
            .result = "sum",
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "a" },
            .rhs = .{ .named = "b" },
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "add",
            .ret_ty = .{ .int = 32 },
            .params = &params,
            .binaries = &binaries,
            .ret = .{ .named = "sum" },
        },
    };

    var module = try air_bridge.lowerModule(std.testing.allocator, .{
        .source_filename = "air-like",
        .target_triple = "x86_64-unknown-linux-gnu",
        .target_datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128",
        .functions = &functions,
    });
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\source_filename = "air-like"
        \\target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "AIR-like bridge lowers scalar arithmetic and casts" {
    const params = [_]air_bridge.Param{
        .{ .name = "a", .ty = .{ .int = 32 } },
        .{ .name = "b", .ty = .{ .int = 32 } },
    };
    const binaries = [_]air_bridge.Binary{
        .{
            .result = "sub",
            .op = .sub,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "a" },
            .rhs = .{ .named = "b" },
        },
        .{
            .result = "masked",
            .op = .@"and",
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "sub" },
            .rhs = .{ .int = 255 },
        },
        .{
            .result = "shifted",
            .op = .shl,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "masked" },
            .rhs = .{ .int = 1 },
        },
    };
    const casts = [_]air_bridge.Cast{
        .{
            .result = "wide",
            .op = .zext,
            .from_ty = .{ .int = 32 },
            .value = .{ .named = "shifted" },
            .to_ty = .{ .int = 64 },
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "arith",
            .ret_ty = .{ .int = 64 },
            .params = &params,
            .binaries = &binaries,
            .casts = &casts,
            .ret = .{ .named = "wide" },
        },
    };

    var module = try air_bridge.lowerModule(std.testing.allocator, .{
        .target_triple = "x86_64-unknown-linux-gnu",
        .functions = &functions,
    });
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @arith(i32 %a, i32 %b) {
        \\entry:
        \\  %sub = sub i32 %a, %b
        \\  %masked = and i32 %sub, 255
        \\  %shifted = shl i32 %masked, 1
        \\  %wide = zext i32 %shifted to i64
        \\  ret i64 %wide
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "AIR-like bridge lowers explicit control flow blocks" {
    const params = [_]air_bridge.Param{
        .{ .name = "cond", .ty = .{ .int = 1 } },
        .{ .name = "a", .ty = .{ .int = 32 } },
        .{ .name = "b", .ty = .{ .int = 32 } },
    };
    const then_binaries = [_]air_bridge.Binary{
        .{
            .result = "sum",
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "a" },
            .rhs = .{ .named = "b" },
        },
    };
    const blocks = [_]air_bridge.Block{
        .{
            .name = "entry",
            .terminator = .{ .condbr = .{
                .cond_ty = .{ .int = 1 },
                .cond = .{ .named = "cond" },
                .then_target = "then",
                .else_target = "trap",
            } },
        },
        .{
            .name = "then",
            .binaries = &then_binaries,
            .terminator = .{ .ret = .{
                .ty = .{ .int = 32 },
                .value = .{ .named = "sum" },
            } },
        },
        .{
            .name = "trap",
            .terminator = .@"unreachable",
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "branch",
            .ret_ty = .{ .int = 32 },
            .params = &params,
            .blocks = &blocks,
        },
    };

    var module = try air_bridge.lowerModule(std.testing.allocator, .{
        .target_triple = "x86_64-unknown-linux-gnu",
        .functions = &functions,
    });
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @branch(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %then, label %trap
        \\then:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\trap:
        \\  unreachable
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "AIR-like bridge lowers scalar stack memory" {
    const allocas = [_]air_bridge.Alloca{
        .{
            .result = "slot",
            .allocated_ty = .{ .int = 32 },
        },
    };
    const stores = [_]air_bridge.Store{
        .{
            .ty = .{ .int = 32 },
            .value = .{ .int = 7 },
            .ptr = .{ .named = "slot" },
            .attrs = .{ .@"align" = 4 },
        },
    };
    const loads = [_]air_bridge.Load{
        .{
            .result = "value",
            .ty = .{ .int = 32 },
            .ptr = .{ .named = "slot" },
            .attrs = .{ .@"align" = 4 },
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "stack",
            .ret_ty = .{ .int = 32 },
            .params = &.{},
            .allocas = &allocas,
            .stores = &stores,
            .loads = &loads,
            .ret = .{ .named = "value" },
        },
    };

    var module = try air_bridge.lowerModule(std.testing.allocator, .{
        .target_triple = "x86_64-unknown-linux-gnu",
        .functions = &functions,
    });
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack() {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 7, ptr %slot, align 4
        \\  %value = load i32, ptr %slot, align 4
        \\  ret i32 %value
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "AIR-like bridge lowers scalar GEP" {
    const indices = [_]ir.GepIndex{
        .{ .ty = .{ .int = 32 }, .value = .{ .int = 0 } },
    };
    const allocas = [_]air_bridge.Alloca{
        .{
            .result = "slot",
            .allocated_ty = .{ .int = 32 },
        },
    };
    const geps = [_]air_bridge.Gep{
        .{
            .result = "ptr",
            .source_ty = .{ .int = 32 },
            .ptr = .{ .named = "slot" },
            .indices = &indices,
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "gep",
            .ret_ty = .ptr,
            .params = &.{},
            .allocas = &allocas,
            .geps = &geps,
            .ret = .{ .named = "ptr" },
        },
    };

    var module = try air_bridge.lowerModule(std.testing.allocator, .{
        .target_triple = "x86_64-unknown-linux-gnu",
        .functions = &functions,
    });
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define ptr @gep() {
        \\entry:
        \\  %slot = alloca i32
        \\  %ptr = getelementptr i32, ptr %slot, i32 0
        \\  ret ptr %ptr
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "AIR-like bridge lowers canonical loop shape" {
    const params = [_]air_bridge.Param{
        .{ .name = "limit", .ty = .{ .int = 32 } },
    };
    const phi_incoming = [_]ir.PhiIncoming{
        .{ .value = .{ .int = 0 }, .block = "entry" },
        .{ .value = .{ .named = "next" }, .block = "latch" },
    };
    const header_phis = [_]air_bridge.Phi{
        .{
            .result = "i",
            .ty = .{ .int = 32 },
            .incoming = &phi_incoming,
        },
    };
    const header_icmps = [_]air_bridge.Icmp{
        .{
            .result = "more",
            .predicate = .slt,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "i" },
            .rhs = .{ .named = "limit" },
        },
    };
    const latch_binaries = [_]air_bridge.Binary{
        .{
            .result = "next",
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "i" },
            .rhs = .{ .int = 1 },
        },
    };
    const blocks = [_]air_bridge.Block{
        .{
            .name = "entry",
            .terminator = .{ .br = .{ .target = "header" } },
        },
        .{
            .name = "header",
            .phis = &header_phis,
            .icmps = &header_icmps,
            .terminator = .{ .condbr = .{
                .cond_ty = .{ .int = 1 },
                .cond = .{ .named = "more" },
                .then_target = "body",
                .else_target = "exit",
            } },
        },
        .{
            .name = "body",
            .terminator = .{ .br = .{ .target = "latch" } },
        },
        .{
            .name = "latch",
            .binaries = &latch_binaries,
            .terminator = .{ .br = .{ .target = "header" } },
        },
        .{
            .name = "exit",
            .terminator = .{ .ret = .{
                .ty = .{ .int = 32 },
                .value = .{ .named = "i" },
            } },
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "loop",
            .ret_ty = .{ .int = 32 },
            .params = &params,
            .blocks = &blocks,
        },
    };

    var module = try air_bridge.lowerModule(std.testing.allocator, .{
        .target_triple = "x86_64-unknown-linux-gnu",
        .functions = &functions,
    });
    defer module.deinit();
    try module.verify();
    const function = module.functions.items[0];

    var loops = try loop_info.LoopInfo.build(std.testing.allocator, function);
    defer loops.deinit();
    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();

    try std.testing.expectEqual(@as(usize, 1), loops.loops.items.len);
    const natural_loop = loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expectEqual(@as(usize, 1), natural_loop.headerBlock());
    try std.testing.expectEqual(@as(usize, 3), natural_loop.latchBlock());
    try std.testing.expectEqual(@as(?usize, 0), natural_loop.preheader(function, graph));

    var exiting = try natural_loop.exitingBlocks(std.testing.allocator, graph);
    defer exiting.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{1}, exiting.items);

    var exits = try natural_loop.exitBlocks(std.testing.allocator, graph);
    defer exits.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{4}, exits.items);
}

test "AIR-like bridge driver prints pre and post optimization IR" {
    const allocas = [_]air_bridge.Alloca{
        .{
            .result = "slot",
            .allocated_ty = .{ .int = 32 },
        },
    };
    const stores = [_]air_bridge.Store{
        .{
            .ty = .{ .int = 32 },
            .value = .{ .int = 7 },
            .ptr = .{ .named = "slot" },
        },
    };
    const loads = [_]air_bridge.Load{
        .{
            .result = "value",
            .ty = .{ .int = 32 },
            .ptr = .{ .named = "slot" },
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "stack_pipeline",
            .ret_ty = .{ .int = 32 },
            .params = &.{},
            .allocas = &allocas,
            .stores = &stores,
            .loads = &loads,
            .ret = .{ .named = "value" },
        },
    };

    var pre: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer pre.deinit();
    var post: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer post.deinit();

    try air_bridge.lowerPrintAndRunPipeline(std.testing.allocator, .{
        .target_triple = "x86_64-unknown-linux-gnu",
        .functions = &functions,
    }, "memory-foundation", &pre.writer, &post.writer);

    const expected_pre =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_pipeline() {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 7, ptr %slot
        \\  %value = load i32, ptr %slot
        \\  ret i32 %value
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected_pre, pre.writer.buffered());

    const expected_post =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_pipeline() {
        \\entry:
        \\  ret i32 7
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected_post, post.writer.buffered());
}

test "parser round-trips normalized Zig-emitted scalar LLVM IR" {
    const input = @embedFile("testdata/zig_tiny_scalar.normalized.ll");

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings("tiny_scalar", module.source_filename.?);
    try std.testing.expectEqualStrings("x86_64-unknown-linux5.10.0-gnu2.31.0", module.target_triple.?);
    try std.testing.expectEqual(@as(usize, 2), module.functions.items.len);
    try std.testing.expectEqual(ir.FunctionLinkage.internal, module.functions.items[0].linkage);
    try std.testing.expect(module.functions.items[0].ret_ty.eql(.void));
    try std.testing.expectEqual(ir.FunctionLinkage.internal, module.functions.items[1].linkage);
    try std.testing.expect(module.functions.items[1].ret_ty.eql(.{ .int = 32 }));
    try std.testing.expectEqual(@as(usize, 2), module.functions.items[1].params.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "AIR-like bridge fixture matches Zig-emitted scalar signatures" {
    const params = [_]air_bridge.Param{
        .{ .name = "0", .ty = .{ .int = 32 } },
        .{ .name = "1", .ty = .{ .int = 32 } },
    };
    const binaries = [_]air_bridge.Binary{
        .{
            .result = "2",
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "1" },
            .rhs = .{ .named = "0" },
        },
    };
    const side_effect_free_blocks = [_]air_bridge.Block{
        .{
            .name = "Entry",
            .terminator = .{ .ret = .{ .ty = .void } },
        },
    };
    const add_blocks = [_]air_bridge.Block{
        .{
            .name = "Entry",
            .binaries = &binaries,
            .terminator = .{ .ret = .{
                .ty = .{ .int = 32 },
                .value = .{ .named = "2" },
            } },
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "tiny_scalar.sideEffectFree",
            .ret_ty = .void,
            .linkage = .internal,
            .params = &.{},
            .blocks = &side_effect_free_blocks,
        },
        .{
            .name = "tiny_scalar.add",
            .ret_ty = .{ .int = 32 },
            .linkage = .internal,
            .params = &params,
            .blocks = &add_blocks,
        },
    };

    var pre: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer pre.deinit();
    var post: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer post.deinit();

    try air_bridge.lowerPrintAndRunPipeline(std.testing.allocator, .{
        .source_filename = "tiny_scalar",
        .target_datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128",
        .target_triple = "x86_64-unknown-linux5.10.0-gnu2.31.0",
        .functions = &functions,
    }, "zig-scalar-foundation", &pre.writer, &post.writer);

    const expected_lowered = @embedFile("testdata/zig_tiny_scalar.project_lowered.ll");
    const expected_optimized = @embedFile("testdata/zig_tiny_scalar.project_optimized.ll");
    try std.testing.expectEqualStrings(expected_lowered, pre.writer.buffered());
    try std.testing.expectEqualStrings(expected_optimized, post.writer.buffered());

    var zig_module = try ir.Module.parse(std.testing.allocator, @embedFile("testdata/zig_tiny_scalar.normalized.ll"));
    defer zig_module.deinit();
    var project_module = try ir.Module.parse(std.testing.allocator, expected_lowered);
    defer project_module.deinit();

    try std.testing.expectEqualStrings(zig_module.source_filename.?, project_module.source_filename.?);
    try std.testing.expectEqualStrings(zig_module.target_datalayout.?, project_module.target_datalayout.?);
    try std.testing.expectEqualStrings(zig_module.target_triple.?, project_module.target_triple.?);
    try std.testing.expectEqual(zig_module.functions.items.len, project_module.functions.items.len);
    for (zig_module.functions.items, project_module.functions.items) |zig_function, project_function| {
        try std.testing.expectEqualStrings(zig_function.name, project_function.name);
        try std.testing.expectEqual(zig_function.linkage, project_function.linkage);
        try std.testing.expect(zig_function.ret_ty.eql(project_function.ret_ty));
        try std.testing.expectEqual(zig_function.params.items.len, project_function.params.items.len);
        for (zig_function.params.items, project_function.params.items) |zig_param, project_param| {
            try std.testing.expect(zig_param.ty.eql(project_param.ty));
        }
    }
}

test "parser preserves module target records and void return" {
    const input =
        \\source_filename = "tiny.zig"
        \\target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @side_effect_free() {
        \\entry:
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const layout = try target.DataLayout.parse(module.target_datalayout.?);
    try std.testing.expectEqual(@as(u16, 64), try layout.pointerSizeBits());

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves function linkage and header attributes" {
    const input =
        \\source_filename = "attrs.zig"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal i32 @kept(i32 %a) local_unnamed_addr #0 {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    try std.testing.expectEqual(ir.FunctionLinkage.internal, function.linkage);
    try std.testing.expectEqualStrings("local_unnamed_addr #0", function.attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser accepts anonymous aggregate return function header" {
    const input =
        \\define private fastcc { ptr, i64 } @main.errorName(i16 %0) unnamed_addr #0 align 1 {
        \\  ret { ptr, i64 } undef
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    try std.testing.expectEqual(ir.FunctionLinkage.private, function.linkage);
    try std.testing.expectEqualStrings("fastcc", function.calling_conv.?);
    try std.testing.expect(function.ret_ty.eql(.{ .aggregate = "{ ptr, i64 }" }));
    try std.testing.expectEqualStrings("unnamed_addr #0 align 1", function.attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\define private fastcc { ptr, i64 } @main.errorName(i16 %0) unnamed_addr #0 align 1 {
        \\1:
        \\  ret { ptr, i64 } undef
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "parser preserves function visibility and parameter attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define external hidden i32 @visible(i32 noundef %a, ptr nonnull readonly captures(none) initializes((0, 4)) %p, ptr nonnull readnone align 1 captures(address) %q, ptr nonnull readnone align 1 captures(address, ret: address, provenance) %r) #1 {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    try std.testing.expectEqual(ir.FunctionLinkage.external, function.linkage);
    try std.testing.expectEqual(ir.FunctionVisibility.hidden, function.visibility);
    try std.testing.expectEqualStrings("noundef", function.params.items[0].attrs.?);
    try std.testing.expectEqualStrings("nonnull readonly captures(none) initializes((0, 4))", function.params.items[1].attrs.?);
    try std.testing.expectEqualStrings("nonnull readnone align 1 captures(address)", function.params.items[2].attrs.?);
    try std.testing.expectEqualStrings("nonnull readnone align 1 captures(address, ret: address, provenance)", function.params.items[3].attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves pointer ABI parameter attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\%Named.Sret = type { i16, i8 }
        \\
        \\declare void @takes_byval(ptr byval({ i32, i32 }), ptr sret({ i32, i32 }))
        \\
        \\define void @abi_attrs(ptr byval({ i32, i32 }) %src, ptr sret({ i32, i32 }) %dst) {
        \\entry:
        \\  ret void
        \\}
        \\
        \\define void @named_sret(ptr noalias sret({ i16, %Named.Sret }) captures(none) %out) {
        \\entry:
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings("byval({ i32, i32 })", module.declarations.items[0].params.items[0].attrs.?);
    try std.testing.expectEqualStrings("sret({ i32, i32 })", module.declarations.items[0].params.items[1].attrs.?);
    try std.testing.expectEqualStrings("byval({ i32, i32 })", module.functions.items[0].params.items[0].attrs.?);
    try std.testing.expectEqualStrings("sret({ i32, i32 })", module.functions.items[0].params.items[1].attrs.?);
    try std.testing.expectEqualStrings("noalias sret({ i16, %Named.Sret }) captures(none)", module.functions.items[1].params.items[0].attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves call argument attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @takes_ptrs(ptr, ptr)
        \\
        \\define void @caller(ptr %p, ptr %q) {
        \\entry:
        \\  call void @takes_ptrs(ptr nonnull %p, ptr nonnull readonly align 1 dereferenceable(1) %q)
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("nonnull", call.args.items[0].attrs.?);
    try std.testing.expectEqualStrings("nonnull readonly align 1 dereferenceable(1)", call.args.items[1].attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves call return attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i16 @llvm.ctpop.i16(i16)
        \\
        \\define i16 @caller(i16 %x) {
        \\entry:
        \\  %count = call range(i16 0, 17) i16 @llvm.ctpop.i16(i16 %x)
        \\  ret i16 %count
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("range(i16 0, 17)", call.ret_attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves inline asm call argument attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @target() {
        \\entry:
        \\  ret void
        \\}
        \\
        \\define void @caller() {
        \\entry:
        \\  tail call void asm sideeffect "", "X,X,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @caller, ptr nonnull @target) #0
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[1].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("nonnull", call.args.items[0].attrs.?);
    try std.testing.expectEqualStrings("nonnull", call.args.items[1].attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves call operand bundles" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.assume(i1)
        \\
        \\define void @caller() {
        \\entry:
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  call void @llvm.assume(i1 1) #0 [ "cold"() ], !noalias !0
        \\  ret void
        \\}
        \\
        \\attributes #0 = { nounwind }
        \\
        \\!0 = !{!1}
        \\!1 = distinct !{!1}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const plain_call = module.functions.items[0].blocks.items[0].instructions.items[0];
    try std.testing.expectEqualStrings("[ \"cold\"() ]", plain_call.kind.call.operand_bundle.?);
    try std.testing.expect(plain_call.kind.call.attrs == null);

    const attr_call = module.functions.items[0].blocks.items[0].instructions.items[1];
    try std.testing.expectEqualStrings("#0", attr_call.kind.call.attrs.?);
    try std.testing.expectEqualStrings("[ \"cold\"() ]", attr_call.kind.call.operand_bundle.?);
    try std.testing.expectEqualStrings("!noalias !0", attr_call.metadata.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser rejects malformed call operand bundles" {
    const unquoted =
        \\declare void @llvm.assume(i1)
        \\
        \\define void @caller() {
        \\entry:
        \\  call void @llvm.assume(i1 true) [ cold() ]
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedOperandBundle, ir.Module.parse(std.testing.allocator, unquoted));

    const inputs =
        \\declare void @llvm.assume(i1)
        \\
        \\define void @caller(i32 %x) {
        \\entry:
        \\  call void @llvm.assume(i1 true) [ "cold"(i32 %x) ]
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedOperandBundle, ir.Module.parse(std.testing.allocator, inputs));
}

test "verifier rejects unsupported call argument attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @takes_ptr(ptr)
        \\
        \\define void @caller(ptr %p) {
        \\entry:
        \\  call void @takes_ptr(ptr nocapture %p)
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.UnsupportedCallAttribute, module.verify());
}

test "verifier rejects invalid call argument attribute payloads" {
    const invalid_align =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @takes_ptr(ptr)
        \\
        \\define void @caller(ptr %p) {
        \\entry:
        \\  call void @takes_ptr(ptr align 3 %p)
        \\  ret void
        \\}
        \\
    ;

    var align_module = try ir.Module.parse(std.testing.allocator, invalid_align);
    defer align_module.deinit();
    try std.testing.expectError(error.InvalidAlignment, align_module.verify());

    const invalid_dereferenceable =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @takes_ptr(ptr)
        \\
        \\define void @caller(ptr %p) {
        \\entry:
        \\  call void @takes_ptr(ptr dereferenceable() %p)
        \\  ret void
        \\}
        \\
    ;

    var deref_module = try ir.Module.parse(std.testing.allocator, invalid_dereferenceable);
    defer deref_module.deinit();
    try std.testing.expectError(error.UnsupportedCallAttribute, deref_module.verify());
}

test "verifier rejects duplicate call argument attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @takes_ptr(ptr)
        \\
        \\define void @caller(ptr %p) {
        \\entry:
        \\  call void @takes_ptr(ptr nonnull nonnull %p)
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.UnsupportedCallAttribute, module.verify());
}

test "parser preserves switch terminators" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @select_switch(i32 %tag) {
        \\entry:
        \\  switch i32 %tag, label %default [
        \\    i32 0, label %zero
        \\    i32 7, label %seven
        \\  ]
        \\zero:
        \\  ret i32 10
        \\seven:
        \\  ret i32 17
        \\default:
        \\  ret i32 99
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const switch_term = module.functions.items[0].blocks.items[0].terminator.?.@"switch";
    try std.testing.expectEqualStrings("default", switch_term.default_target);
    try std.testing.expectEqual(@as(usize, 2), switch_term.cases.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves switch labels containing bracket characters" {
    const input =
        \\define i32 @switch_bracket_label(i32 %tag) {
        \\entry:
        \\  switch i32 %tag, label %default [
        \\    i32 0, label %"array_hash_map.Custom([]const u8).exit"
        \\  ], !prof !0
        \\"array_hash_map.Custom([]const u8).exit":
        \\  ret i32 7
        \\default:
        \\  ret i32 99
        \\}
        \\
        \\!0 = !{!"branch_weights", i32 1, i32 2}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const switch_term = module.functions.items[0].blocks.items[0].terminator.?.@"switch";
    try std.testing.expectEqual(@as(usize, 1), switch_term.cases.items.len);
    try std.testing.expectEqualStrings("\"array_hash_map.Custom([]const u8).exit\"", switch_term.cases.items[0].target);
    try std.testing.expectEqualStrings("!prof !0", switch_term.metadata.?);
}

test "parser preserves indirectbr terminators" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @dispatch(ptr %addr) {
        \\entry:
        \\  indirectbr ptr %addr, [label %left, label %right]
        \\left:
        \\  ret void
        \\right:
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const indirectbr = module.functions.items[0].blocks.items[0].terminator.?.indirectbr;
    try std.testing.expect(indirectbr.addr_ty.eql(.ptr));
    try std.testing.expectEqualStrings("addr", indirectbr.addr.named);
    try std.testing.expectEqual(@as(usize, 2), indirectbr.targets.items.len);
    try std.testing.expectEqualStrings("left", indirectbr.targets.items[0]);
    try std.testing.expectEqualStrings("right", indirectbr.targets.items[1]);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves vector splat call arguments" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare <4 x i32> @add_splat(<4 x i32>, <4 x i32>)
        \\
        \\define <4 x i32> @caller(<4 x i32> %x) {
        \\entry:
        \\  %sum = call <4 x i32> @add_splat(<4 x i32> %x, <4 x i32> splat (i32 16))
        \\  ret <4 x i32> %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("splat (i32 16)", call.args.items[1].value.vector);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves poison call arguments" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @takes_poison(i64)
        \\
        \\define i64 @caller() {
        \\entry:
        \\  %value = call i64 @takes_poison(i64 poison)
        \\  ret i64 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqual(call.args.items[0].value, .poison);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser infers numeric implicit entry block names" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i1 @implicit_entry_phi(i1 %cond) {
        \\  %1 = zext i1 %cond to i8
        \\  br i1 %cond, label %join, label %other
        \\other:
        \\  br label %join
        \\join:
        \\  %value = phi i1 [ true, %0 ], [ false, %other ]
        \\  ret i1 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings("0", module.functions.items[0].blocks.items[0].name);
}

test "parser infers zero implicit entry block before nonnumeric result" {
    const input =
        \\define i1 @implicit_zero_entry(i1 %cond) {
        \\  %.slot = alloca i8
        \\  br i1 %cond, label %then, label %join
        \\then:
        \\  br label %join
        \\join:
        \\  %value = phi i1 [ true, %then ], [ false, %0 ]
        \\  ret i1 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings("0", module.functions.items[0].blocks.items[0].name);
}

test "parser and verifier accept pointer integer casts" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define ptr @as_ptr(i64 %addr) {
        \\entry:
        \\  %p = inttoptr i64 %addr to ptr
        \\  ret ptr %p
        \\}
        \\
        \\define i64 @as_int(ptr %p) {
        \\entry:
        \\  %addr = ptrtoint ptr %p to i64
        \\  ret i64 %addr
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves pointer cast constant expressions in phis" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define ptr @constant_expr_phi(i1 %cond) {
        \\entry:
        \\  br i1 %cond, label %then, label %merge
        \\then:
        \\  br label %merge
        \\merge:
        \\  %p = phi ptr [ inttoptr (i64 1 to ptr), %entry ], [ null, %then ]
        \\  ret ptr %p
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser verifies and prints phi incoming poison" {
    const input =
        \\define i64 @phi_poison(i1 %cond, i64 %x) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %v = phi i64 [ poison, %left ], [ %x, %right ]
        \\  ret i64 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const phi = module.functions.items[0].blocks.items[3].instructions.items[0].kind.phi;
    try std.testing.expectEqual(ir.Value.poison, phi.incoming.items[0].value);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves icmp samesign flag" {
    const input =
        \\define i1 @cmp(i64 %a, i64 %b) {
        \\entry:
        \\  %r = icmp samesign ult i64 %a, %b
        \\  ret i1 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cmp = module.functions.items[0].blocks.items[0].instructions.items[0].kind.icmp;
    try std.testing.expect(cmp.samesign);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves integer constant expressions in icmp and binary operands" {
    const input =
        \\@start = external global i8
        \\@end = external global i8
        \\
        \\define i1 @constant_expr_cmp() {
        \\entry:
        \\  %cmp = icmp eq i64 sub (i64 ptrtoint (ptr @end to i64), i64 ptrtoint (ptr @start to i64)), 0
        \\  %shift = lshr exact i64 sub (i64 ptrtoint (ptr @end to i64), i64 ptrtoint (ptr @start to i64)), 3
        \\  ret i1 %cmp
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cmp = module.functions.items[0].blocks.items[0].instructions.items[0].kind.icmp;
    try std.testing.expect(cmp.lhs == .constant_expr);

    const shift = module.functions.items[0].blocks.items[0].instructions.items[1].kind.binary;
    try std.testing.expect(shift.lhs == .constant_expr);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser verifies and prints or disjoint flags" {
    const input =
        \\define i64 @or_disjoint(i8 %a, i64 %x) {
        \\entry:
        \\  %r = or disjoint i8 %a, 48
        \\  %wide = zext i8 %r to i64
        \\  %s = or disjoint i64 %x, 18014398509481984
        \\  %out = or i64 %s, %wide
        \\  ret i64 %out
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const byte_or = module.functions.items[0].blocks.items[0].instructions.items[0].kind.binary;
    try std.testing.expectEqual(ir.BinaryOp.@"or", byte_or.op);
    try std.testing.expect(byte_or.flags.disjoint);
    try std.testing.expectEqual(ir.Type{ .int = 8 }, byte_or.ty);

    const wide_or = module.functions.items[0].blocks.items[0].instructions.items[2].kind.binary;
    try std.testing.expectEqual(ir.BinaryOp.@"or", wide_or.op);
    try std.testing.expect(wide_or.flags.disjoint);
    try std.testing.expectEqual(ir.Type{ .int = 64 }, wide_or.ty);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier rejects invalid ABI parameter attributes" {
    const byval_non_pointer =
        \\declare void @bad(i32 byval({ i32 }))
        \\
    ;

    var byval_module = try ir.Module.parse(std.testing.allocator, byval_non_pointer);
    defer byval_module.deinit();
    try std.testing.expectError(error.UnsupportedAbiType, byval_module.verify());

    const sret_non_pointer =
        \\define void @bad(i32 sret({ i32 }) %result) {
        \\entry:
        \\  ret void
        \\}
        \\
    ;

    var sret_module = try ir.Module.parse(std.testing.allocator, sret_non_pointer);
    defer sret_module.deinit();
    try std.testing.expectError(error.UnsupportedAbiType, sret_module.verify());
}

test "parser preserves source-backed varargs declarations and calls" {
    const input =
        \\declare i32 @printf(ptr noundef nonnull readonly align 1 captures(none), ...)
        \\
        \\define i32 @caller(ptr %p) {
        \\entry:
        \\  %result = call i32 (ptr, ...) @printf(ptr nonnull readonly align 1 dereferenceable(1) %p, double 2.000000e+00)
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expect(module.declarations.items[0].is_varargs);
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("(ptr, ...)", call.callee_function_ty.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());

    const vararg_call =
        \\declare void @sink(ptr)
        \\
        \\define void @caller(ptr %p) {
        \\entry:
        \\  call void @sink(ptr %p, ...)
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedVarArgs, ir.Module.parse(std.testing.allocator, vararg_call));
}

test "verifier accepts source-backed naked function register-argument calls" {
    const input =
        \\define i64 @naked_target() #0 {
        \\entry:
        \\  unreachable
        \\}
        \\
        \\define i64 @caller(ptr %entry, i64 %stack) {
        \\entry:
        \\  %result = call i64 @naked_target(ptr %entry, i64 %stack, i32 8195840)
        \\  ret i64 %result
        \\}
        \\
        \\attributes #0 = { naked nounwind }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());

    const non_naked =
        \\define i64 @target() {
        \\entry:
        \\  unreachable
        \\}
        \\
        \\define i64 @caller(ptr %entry) {
        \\entry:
        \\  %result = call i64 @target(ptr %entry)
        \\  ret i64 %result
        \\}
        \\
    ;
    var bad_module = try ir.Module.parse(std.testing.allocator, non_naked);
    defer bad_module.deinit();
    try std.testing.expectError(error.CallSignatureMismatch, bad_module.verify());
}

test "parser preserves return attributes before function return type" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define private range(i32 0, -2147483648) i32 @bounded(i32 %a) #0 {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\attributes #0 = { nounwind memory(none) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    try std.testing.expectEqualStrings("range(i32 0, -2147483648)", function.ret_attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves address-space pointer function returns" {
    const input =
        \\define private fastcc ptr addrspace(256) @entry(ptr addrspace(256) align 4 %0) unnamed_addr #0 align 1 {
        \\entry:
        \\  %1 = alloca ptr addrspace(256), align 8
        \\  store ptr addrspace(256) %0, ptr %1, align 8
        \\  %2 = load ptr addrspace(256), ptr %1, align 8
        \\  %3 = getelementptr [4 x i8], ptr addrspace(256) %2, i64 0
        \\  ret ptr addrspace(256) %3
        \\}
        \\
        \\attributes #0 = { nounwind }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    try std.testing.expectEqualStrings("addrspace(256)", function.ret_attrs.?);
    try std.testing.expectEqualStrings("addrspace(256)", function.blocks.items[0].instructions.items[0].kind.alloca.allocated_ty_addrspace.?);
    try std.testing.expectEqualStrings("addrspace(256)", function.blocks.items[0].instructions.items[1].kind.store.ty_addrspace.?);
    try std.testing.expectEqualStrings("addrspace(256)", function.blocks.items[0].instructions.items[2].kind.load.ty_addrspace.?);
    try std.testing.expectEqualStrings("addrspace(256)", function.blocks.items[0].instructions.items[3].kind.gep.ptr_addrspace.?);
    try std.testing.expectEqualStrings("addrspace(256)", function.blocks.items[0].terminator.?.ret.ptr_addrspace.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves supported calling conventions" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal fastcc i32 @callconv(i32 %a) #2 {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    try std.testing.expectEqual(ir.FunctionLinkage.internal, function.linkage);
    try std.testing.expectEqualStrings("fastcc", function.calling_conv.?);
    try std.testing.expectEqualStrings("#2", function.attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves function declarations and direct calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32)
        \\
        \\declare void @sink(i32)
        \\
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = call i32 @callee(i32 %a)
        \\  call void @sink(i32 %r)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 2), module.declarations.items.len);
    try std.testing.expectEqualStrings("callee", module.declarations.items[0].name);
    try std.testing.expectEqual(ir.Type{ .int = 32 }, module.declarations.items[0].ret_ty);
    try std.testing.expectEqualStrings("sink", module.declarations.items[1].name);
    try std.testing.expectEqual(ir.Type.void, module.declarations.items[1].ret_ty);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves tail direct calls" {
    const input =
        \\declare i32 @llvm.smin.i32(i32, i32) #0
        \\
        \\define i32 @caller(i32 %a, i32 %b) {
        \\entry:
        \\  %r = tail call i32 @llvm.smin.i32(i32 %a, i32 %b)
        \\  ret i32 %r
        \\}
        \\
        \\attributes #0 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("tail", call.tail_kind.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves musttail and notail direct calls" {
    const input =
        \\declare i32 @callee(i32)
        \\
        \\declare void @sink()
        \\
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = musttail call i32 @callee(i32 %a)
        \\  notail call void @sink()
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const block = module.functions.items[0].blocks.items[0];
    try std.testing.expectEqualStrings("musttail", block.instructions.items[0].kind.call.tail_kind.?);
    try std.testing.expectEqualStrings("notail", block.instructions.items[1].kind.call.tail_kind.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves raw module metadata records" {
    const input =
        \\define i32 @with_metadata(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\!llvm.module.flags = !{!0}
        \\!0 = !{i32 2, !"Debug Info Version", i32 3}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expectEqual(@as(usize, 2), module.metadata.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier preserves unknown metadata nodes with valid references" {
    const input =
        \\define i32 @with_unknown_metadata(i32 %a) !dbg !1 {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\!0 = !{!"opaque", !1}
        \\!1 = distinct !DILocation(line: 1, column: 1, scope: !2)
        \\!2 = distinct !DISubprogram(name: "f", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1)
        \\!3 = !DIFile(filename: "opaque.zig", directory: ".")
        \\!4 = !DISubroutineType(types: !5)
        \\!5 = !{}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
}

test "verifier rejects dangling debug metadata references" {
    const input =
        \\define i32 @bad_debug_metadata(i32 %a) !dbg !4 {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\!4 = distinct !DISubprogram(name: "bad", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expectError(error.UnknownMetadata, module.verify());
}

test "verifier rejects impossible debug compile unit root" {
    const input =
        \\define i32 @bad_debug_cu(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!0 = !DIFile(filename: "not_cu.zig", directory: ".")
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expectError(error.InvalidDebugMetadata, module.verify());
}

test "verifier accepts sizeless debug basic types" {
    const input =
        \\define void @sizeless_basic_type() !dbg !4 {
        \\entry:
        \\  ret void
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!llvm.module.flags = !{!1}
        \\!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
        \\!1 = !{i32 2, !"Debug Info Version", i32 3}
        \\!2 = !DIFile(filename: "sizeless_basic_type.zig", directory: ".")
        \\!4 = distinct !DISubprogram(name: "sizeless_basic_type", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{!7}
        \\!7 = !DIBasicType(name: "void", encoding: DW_ATE_signed)
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
}

test "verifier accepts columnless debug locations" {
    const input =
        \\define void @columnless_location() !dbg !4 {
        \\entry:
        \\  ret void, !dbg !7
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!llvm.module.flags = !{!1}
        \\!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
        \\!1 = !{i32 2, !"Debug Info Version", i32 3}
        \\!2 = !DIFile(filename: "columnless_location.zig", directory: ".")
        \\!4 = distinct !DISubprogram(name: "columnless_location", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{}
        \\!7 = !DILocation(line: 0, scope: !4)
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
}

test "parser preserves instruction debug metadata attachments" {
    const input =
        \\source_filename = "debug_metadata"
        \\
        \\define i32 @debug_add(i32 %a) !dbg !4 {
        \\entry:
        \\  %sum = add i32 %a, 1, !dbg !8
        \\  ret i32 %sum
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!llvm.module.flags = !{!1}
        \\!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
        \\!1 = !{i32 2, !"Debug Info Version", i32 3}
        \\!2 = !DIFile(filename: "debug_metadata.zig", directory: ".")
        \\!4 = distinct !DISubprogram(name: "debug_add", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{}
        \\!8 = !DILocation(line: 2, column: 12, scope: !4)
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const instruction = module.functions.items[0].blocks.items[0].instructions.items[0];
    try std.testing.expectEqualStrings("!dbg !8", instruction.metadata.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves debug value intrinsics as variable-location boundary" {
    const input =
        \\declare void @llvm.dbg.value(metadata, metadata, metadata)
        \\
        \\define i32 @debug_value(i32 %a) !dbg !4 {
        \\entry:
        \\  call void @llvm.dbg.value(metadata i32 %a, metadata !9, metadata !DIExpression()), !dbg !8
        \\  ret i32 %a
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
        \\!2 = !DIFile(filename: "debug_value.zig", directory: ".")
        \\!4 = distinct !DISubprogram(name: "debug_value", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{}
        \\!8 = !DILocation(line: 2, column: 5, scope: !4)
        \\!9 = !DILocalVariable(name: "a", arg: 1, scope: !4, file: !2, line: 1, type: !10)
        \\!10 = !DIBasicType(name: "i32", size: 32, encoding: DW_ATE_signed)
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const instruction = module.functions.items[0].blocks.items[0].instructions.items[0];
    const call = instruction.kind.call;
    try std.testing.expect(call.isDebugVariableLocation());
    try std.testing.expectEqualStrings("metadata i32 %a, metadata !9, metadata !DIExpression()", call.raw_args.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves debug declare intrinsics as variable-location boundary" {
    const input =
        \\declare void @llvm.dbg.declare(metadata, metadata, metadata)
        \\
        \\define void @debug_declare(ptr %p) !dbg !4 {
        \\entry:
        \\  call void @llvm.dbg.declare(metadata ptr %p, metadata !9, metadata !DIExpression()), !dbg !8
        \\  ret void
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
        \\!2 = !DIFile(filename: "debug_declare.zig", directory: ".")
        \\!4 = distinct !DISubprogram(name: "debug_declare", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{}
        \\!8 = !DILocation(line: 2, column: 5, scope: !4)
        \\!9 = !DILocalVariable(name: "p", arg: 1, scope: !4, file: !2, line: 1, type: !10)
        \\!10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !11, size: 64)
        \\!11 = !DIBasicType(name: "i32", size: 32, encoding: DW_ATE_signed)
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const instruction = module.functions.items[0].blocks.items[0].instructions.items[0];
    const call = instruction.kind.call;
    try std.testing.expect(call.isDebugVariableLocation());
    try std.testing.expectEqualStrings("metadata ptr %p, metadata !9, metadata !DIExpression()", call.raw_args.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser rejects unsupported debug assign intrinsic" {
    const input =
        \\declare void @llvm.dbg.assign(metadata, metadata, metadata, metadata, metadata, metadata)
        \\
        \\define void @debug_assign(i32 %a) {
        \\entry:
        \\  call void @llvm.dbg.assign(metadata i32 %a, metadata !0, metadata !DIExpression(), metadata !1, metadata ptr undef, metadata !DIExpression())
        \\  ret void
        \\}
        \\
        \\!0 = !DILocalVariable(name: "a")
        \\!1 = distinct !DIAssignID()
        \\
    ;

    try std.testing.expectError(error.UnsupportedDebugIntrinsic, ir.Module.parse(std.testing.allocator, input));
}

test "parser preserves Debug lexical scope branch metadata opaquely" {
    const input =
        \\source_filename = "debug_scope_branch"
        \\
        \\define i32 @debug_scope_branch(i1 %cond, i32 %value) !dbg !4 {
        \\entry:
        \\  br i1 %cond, label %then, label %exit, !dbg !9
        \\then:
        \\  %inc = add i32 %value, 1, !dbg !11
        \\  br label %exit, !dbg !12
        \\exit:
        \\  %result = phi i32 [ %value, %entry ], [ %inc, %then ], !dbg !13
        \\  ret i32 %result
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!llvm.module.flags = !{!1}
        \\!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
        \\!1 = !{i32 2, !"Debug Info Version", i32 3}
        \\!2 = !DIFile(filename: "debug_scope_branch.zig", directory: ".")
        \\!4 = distinct !DISubprogram(name: "debug_scope_branch", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{}
        \\!8 = distinct !DILexicalBlock(scope: !4, file: !2, line: 2, column: 5)
        \\!9 = !DILocation(line: 2, column: 5, scope: !4)
        \\!11 = !DILocation(line: 3, column: 16, scope: !8)
        \\!12 = !DILocation(line: 4, column: 5, scope: !8)
        \\!13 = !DILocation(line: 6, column: 12, scope: !4)
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const entry = module.functions.items[0].blocks.items[0];
    try std.testing.expectEqualStrings("!dbg !9", entry.terminator.?.condbr.metadata.?);
    const then_block = module.functions.items[0].blocks.items[1];
    try std.testing.expectEqualStrings("!dbg !11", then_block.instructions.items[0].metadata.?);
    try std.testing.expectEqualStrings("!dbg !12", then_block.terminator.?.br.metadata.?);
    try std.testing.expectEqual(@as(usize, 13), module.metadata.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser verifies null pointer constants from optional lowering" {
    const input =
        \\define i32 @optional_ptr_value(ptr %p) {
        \\entry:
        \\  %is_null = icmp eq ptr %p, null
        \\  br i1 %is_null, label %none, label %some
        \\some:
        \\  %v = load i32, ptr %p, align 4
        \\  ret i32 %v
        \\none:
        \\  ret i32 -1
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cmp = module.functions.items[0].blocks.items[0].instructions.items[0].kind.icmp;
    try std.testing.expect(cmp.rhs == .null_value);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());

    const invalid =
        \\define i1 @bad_null_i32(i32 %x) {
        \\entry:
        \\  %bad = icmp eq i32 %x, null
        \\  ret i1 %bad
        \\}
        \\
    ;
    var invalid_module = try ir.Module.parse(std.testing.allocator, invalid);
    defer invalid_module.deinit();
    try std.testing.expectError(error.TypeMismatch, invalid_module.verify());
}

test "parser preserves observed scalar FP literal spellings without folding" {
    const input =
        \\define float @float_literal() {
        \\entry:
        \\  ret float 1.500000e+00
        \\}
        \\
        \\define double @double_literal() {
        \\entry:
        \\  ret double 2.250000e+00
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const float_ret = module.functions.items[0].blocks.items[0].terminator.?.ret.value.?;
    try std.testing.expectEqualStrings("1.500000e+00", float_ret.fp);
    const double_ret = module.functions.items[1].blocks.items[0].terminator.?.ret.value.?;
    try std.testing.expectEqualStrings("2.250000e+00", double_ret.fp);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser classifies special FP literal spellings without folding" {
    const input =
        \\define double @nan_literal() {
        \\entry:
        \\  ret double nan
        \\}
        \\
        \\define double @inf_literal() {
        \\entry:
        \\  ret double inf
        \\}
        \\
        \\define double @negative_zero_literal() {
        \\entry:
        \\  ret double -0.0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const nan_ret = module.functions.items[0].blocks.items[0].terminator.?.ret.value.?.fp;
    const inf_ret = module.functions.items[1].blocks.items[0].terminator.?.ret.value.?.fp;
    const neg_zero_ret = module.functions.items[2].blocks.items[0].terminator.?.ret.value.?.fp;
    try std.testing.expectEqual(fp_semantics.Category.nan, (try fp_semantics.classify(.double, nan_ret)).category);
    try std.testing.expectEqual(fp_semantics.Category.infinity, (try fp_semantics.classify(.double, inf_ret)).category);
    try std.testing.expectEqual(fp_semantics.Category.negative_zero, (try fp_semantics.classify(.double, neg_zero_ret)).category);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves fixed vector signatures and rejects unsupported vector boundaries" {
    const vector_add =
        \\define i32 @vector_add() {
        \\entry:
        \\  %v = add <2 x i32> undef, undef
        \\  ret i32 0
        \\}
        \\
    ;
    var vector_module = try ir.Module.parse(std.testing.allocator, vector_add);
    defer vector_module.deinit();
    try vector_module.verify();
    try std.testing.expect(vector_module.functions.items[0].blocks.items[0].instructions.items[0].kind.binary.ty.eql(.{ .vector = .{
        .len = 2,
        .elem_ty = .{ .int = 32 },
    } }));

    var printed: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer printed.deinit();
    try vector_module.print(&printed.writer);
    try std.testing.expectEqualStrings(vector_add, printed.writer.buffered());

    const shuffle =
        \\define i32 @shuffle() {
        \\entry:
        \\  %v = shufflevector <2 x i32> undef, <2 x i32> undef, <2 x i32> zeroinitializer
        \\  ret i32 0
        \\}
        \\
    ;
    var shuffle_module = try ir.Module.parse(std.testing.allocator, shuffle);
    defer shuffle_module.deinit();
    try shuffle_module.verify();

    const insert =
        \\define i32 @insert_lane(i32 %a) {
        \\entry:
        \\  %v = insertelement <2 x i32> undef, i32 %a, i32 0
        \\  ret i32 0
        \\}
        \\
    ;
    var insert_module = try ir.Module.parse(std.testing.allocator, insert);
    defer insert_module.deinit();
    try insert_module.verify();

    const extract =
        \\define i32 @extract_lane() {
        \\entry:
        \\  %v = extractelement <2 x i32> undef, i32 0
        \\  ret i32 0
        \\}
        \\
    ;
    var extract_module = try ir.Module.parse(std.testing.allocator, extract);
    defer extract_module.deinit();
    try extract_module.verify();

    const vector_constant =
        \\define <2 x i32> @vector_constant() {
        \\entry:
        \\  %v = freeze <2 x i32> <i32 1, i32 2>
        \\  ret <2 x i32> %v
        \\}
        \\
    ;
    var constant_module = try ir.Module.parse(std.testing.allocator, vector_constant);
    defer constant_module.deinit();
    try constant_module.verify();

    const vector_splat =
        \\define i1 @vector_splat_icmp(<16 x i8> %a) {
        \\entry:
        \\  %cmp = icmp eq <16 x i8> %a, splat (i8 10)
        \\  ret i1 1
        \\}
        \\
    ;
    var splat_module = try ir.Module.parse(std.testing.allocator, vector_splat);
    defer splat_module.deinit();
    try splat_module.verify();

    var splat_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer splat_output.deinit();
    try splat_module.print(&splat_output.writer);
    try std.testing.expectEqualStrings(vector_splat, splat_output.writer.buffered());

    const vector_compare_mask_bitcast =
        \\define i16 @vector_compare_mask_bitcast(<16 x i8> %a) {
        \\entry:
        \\  %cmp = icmp eq <16 x i8> %a, splat (i8 10)
        \\  %bits = bitcast <16 x i1> %cmp to i16
        \\  ret i16 %bits
        \\}
        \\
    ;
    var mask_bitcast_module = try ir.Module.parse(std.testing.allocator, vector_compare_mask_bitcast);
    defer mask_bitcast_module.deinit();
    try mask_bitcast_module.verify();
    try std.testing.expect(mask_bitcast_module.functions.items[0].blocks.items[0].instructions.items[0].resultType().?.eql(.{ .vector = .{
        .len = 16,
        .elem_ty = .{ .int = 1 },
    } }));

    var mask_bitcast_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer mask_bitcast_output.deinit();
    try mask_bitcast_module.print(&mask_bitcast_output.writer);
    try std.testing.expectEqualStrings(vector_compare_mask_bitcast, mask_bitcast_output.writer.buffered());

    const vector_select =
        \\define <16 x i4> @vector_select(<16 x i1> %mask, <16 x i4> %a, <16 x i4> %b) {
        \\entry:
        \\  %r = select <16 x i1> %mask, <16 x i4> %a, <16 x i4> %b
        \\  ret <16 x i4> %r
        \\}
        \\
    ;
    var vector_select_module = try ir.Module.parse(std.testing.allocator, vector_select);
    defer vector_select_module.deinit();
    try vector_select_module.verify();

    var vector_select_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer vector_select_output.deinit();
    try vector_select_module.print(&vector_select_output.writer);
    try std.testing.expectEqualStrings(vector_select, vector_select_output.writer.buffered());

    const bad_vector_select =
        \\define <8 x i4> @bad_vector_select(<16 x i1> %mask, <8 x i4> %a, <8 x i4> %b) {
        \\entry:
        \\  %r = select <16 x i1> %mask, <8 x i4> %a, <8 x i4> %b
        \\  ret <8 x i4> %r
        \\}
        \\
    ;
    var bad_vector_select_module = try ir.Module.parse(std.testing.allocator, bad_vector_select);
    defer bad_vector_select_module.deinit();
    try std.testing.expectError(error.SelectConditionTypeMismatch, bad_vector_select_module.verify());

    const bad_vector_splat =
        \\define i1 @bad_vector_splat_icmp(<16 x i8> %a) {
        \\entry:
        \\  %cmp = icmp eq <16 x i8> %a, splat (i16 10)
        \\  ret i1 1
        \\}
        \\
    ;
    var bad_splat_module = try ir.Module.parse(std.testing.allocator, bad_vector_splat);
    defer bad_splat_module.deinit();
    try std.testing.expectError(error.TypeMismatch, bad_splat_module.verify());

    const scalable =
        \\define <vscale x 2 x i32> @scalable(<vscale x 2 x i32> %a) {
        \\entry:
        \\  ret <vscale x 2 x i32> %a
        \\}
        \\
    ;
    try std.testing.expectError(error.InvalidFunctionHeader, ir.Module.parse(std.testing.allocator, scalable));

    const unsupported_element =
        \\define <2 x { i32 }> @bad_elem(<2 x { i32 }> %a) {
        \\entry:
        \\  ret <2 x { i32 }> %a
        \\}
        \\
    ;
    try std.testing.expectError(error.InvalidFunctionHeader, ir.Module.parse(std.testing.allocator, unsupported_element));

    const mismatch =
        \\define <2 x i32> @mismatch() {
        \\entry:
        \\  ret <2 x i32> 0
        \\}
        \\
    ;
    var mismatch_module = try ir.Module.parse(std.testing.allocator, mismatch);
    defer mismatch_module.deinit();
    try std.testing.expectError(error.TypeMismatch, mismatch_module.verify());

    const bad_lane =
        \\define i32 @bad_lane(<2 x i32> %a) {
        \\entry:
        \\  %v = extractelement <2 x i32> %a, i32 2
        \\  ret i32 %v
        \\}
        \\
    ;
    var bad_lane_module = try ir.Module.parse(std.testing.allocator, bad_lane);
    defer bad_lane_module.deinit();
    try std.testing.expectError(error.TypeMismatch, bad_lane_module.verify());

    const bad_shuffle =
        \\define <2 x i32> @bad_shuffle(<2 x i32> %a, <2 x i32> %b) {
        \\entry:
        \\  %v = shufflevector <2 x i32> %a, <2 x i32> %b, <2 x i32> <i32 0, i32 4>
        \\  ret <2 x i32> %v
        \\}
        \\
    ;
    var bad_shuffle_module = try ir.Module.parse(std.testing.allocator, bad_shuffle);
    defer bad_shuffle_module.deinit();
    try std.testing.expectError(error.TypeMismatch, bad_shuffle_module.verify());
}

test "parser preserves inert branch metadata attachments" {
    const input =
        \\define void @loop_metadata(i1 %cond) {
        \\entry:
        \\  br i1 %cond, label %loop, label %exit
        \\loop:
        \\  br i1 %cond, label %loop, label %exit, !llvm.loop !0
        \\exit:
        \\  ret void
        \\}
        \\
        \\!0 = distinct !{!0}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves quoted branch labels containing commas" {
    const input =
        \\define i32 @quoted_branch(i1 %cond) {
        \\entry:
        \\  br i1 %cond, label %"left,with,comma", label %"right,with,comma"
        \\"left,with,comma":
        \\  ret i32 1
        \\"right,with,comma":
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves alias metadata attachments opaquely" {
    const input =
        \\define i32 @alias_metadata(ptr %a, ptr %b) {
        \\entry:
        \\  %x = load i32, ptr %a, align 4, !tbaa !0, !alias.scope !3, !noalias !6
        \\  store i32 %x, ptr %b, align 4, !tbaa !0, !alias.scope !6, !noalias !3
        \\  %y = load ptr, ptr %b, align 8, !nonnull !8, !noundef !8
        \\  %z = select i1 1, i32 %x, i32 0, !unpredictable !8
        \\  ret i32 %x
        \\}
        \\
        \\!0 = !{!1, !1, i64 0}
        \\!1 = !{!"int", !2}
        \\!2 = !{!"Simple C/C++ TBAA"}
        \\!3 = !{!4}
        \\!4 = distinct !{!4, !5}
        \\!5 = distinct !{!5}
        \\!6 = !{!7}
        \\!7 = distinct !{!7, !5}
        \\!8 = !{}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings("!tbaa !0, !alias.scope !3, !noalias !6", module.functions.items[0].blocks.items[0].instructions.items[0].metadata.?);
    try std.testing.expectEqualStrings("!tbaa !0, !alias.scope !6, !noalias !3", module.functions.items[0].blocks.items[0].instructions.items[1].metadata.?);
    try std.testing.expectEqualStrings("!nonnull !8, !noundef !8", module.functions.items[0].blocks.items[0].instructions.items[2].metadata.?);
    try std.testing.expectEqualStrings("!unpredictable !8", module.functions.items[0].blocks.items[0].instructions.items[3].metadata.?);
    try std.testing.expectEqual(@as(usize, 9), module.metadata.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser rejects unsupported instruction metadata attachments" {
    const input =
        \\define i32 @unsupported_metadata(ptr %p) {
        \\entry:
        \\  %x = load i32, ptr %p, align 4, !range !0
        \\  ret i32 %x
        \\}
        \\
        \\!0 = !{i32 0, i32 10}
        \\
    ;

    try std.testing.expectError(error.UnsupportedInstructionMetadata, ir.Module.parse(std.testing.allocator, input));
}

test "parser drops non-semantic debug records" {
    const input =
        \\define i32 @debug_record(ptr %p) !dbg !4 {
        \\entry:
        \\  #dbg_declare(ptr %p, !8, !DIExpression(), !9)
        \\  ret i32 0, !dbg !9
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!llvm.module.flags = !{!1}
        \\!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
        \\!1 = !{i32 2, !"Debug Info Version", i32 3}
        \\!2 = !DIFile(filename: "debug_record.zig", directory: ".")
        \\!4 = distinct !DISubprogram(name: "debug_record", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{}
        \\!8 = !DILocalVariable(name: "p", arg: 1, scope: !4, file: !2, line: 1, type: !5)
        \\!9 = !DILocation(line: 1, column: 1, scope: !4)
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(@as(usize, 0), module.functions.items[0].blocks.items[0].instructions.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqual(null, std.mem.indexOf(u8, output.writer.buffered(), "#dbg_declare"));
}

test "parser accepts unreachable metadata" {
    const input =
        \\define void @unreachable_metadata() {
        \\entry:
        \\  unreachable, !dbg !0
        \\}
        \\
        \\!0 = !DILocation(line: 1, column: 1, scope: !1)
        \\!1 = distinct !DISubprogram(name: "unreachable_metadata", file: !2, type: !3)
        \\!2 = !DIFile(filename: "unreachable_metadata.zig", directory: ".")
        \\!3 = !DISubroutineType(types: !4)
        \\!4 = !{}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
}

test "parser accepts return metadata" {
    const input =
        \\define i32 @return_metadata() {
        \\entry:
        \\  ret i32 0, !dbg !0
        \\}
        \\
        \\!0 = !DILocation(line: 1, column: 1, scope: !1)
        \\!1 = distinct !DISubprogram(name: "return_metadata", file: !2, type: !3)
        \\!2 = !DIFile(filename: "return_metadata.zig", directory: ".")
        \\!3 = !DISubroutineType(types: !4)
        \\!4 = !{}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
}

test "parser preserves Zig raw aliases and attribute groups" {
    const input =
        \\source_filename = "tiny_scalar"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@add = alias i32 (i32, i32), ptr @tiny_scalar.add
        \\
        \\define private i32 @tiny_scalar.add(i32 %0, i32 %1) unnamed_addr #0 align 1 {
        \\entry:
        \\  %2 = add nsw i32 %1, %0
        \\  ret i32 %2
        \\}
        \\
        \\attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" }
        \\
        \\!llvm.module.flags = !{}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 1), module.aliases.items.len);
    try std.testing.expectEqualStrings("add", module.aliases.items[0].name);
    try std.testing.expectEqualStrings("i32 (i32, i32)", module.aliases.items[0].aliased_ty);
    try std.testing.expectEqualStrings("tiny_scalar.add", module.aliases.items[0].target);
    try std.testing.expectEqual(@as(usize, 1), module.attribute_groups.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser rejects unsupported sanitizer attribute groups explicitly" {
    const input =
        \\define void @with_sanitizer() #0 {
        \\entry:
        \\  ret void
        \\}
        \\
        \\attributes #0 = { sanitize_address }
        \\
    ;

    try std.testing.expectError(error.UnsupportedAttributeGroup, ir.Module.parse(std.testing.allocator, input));
}

test "parser preserves nosanitize coverage attribute group" {
    const input =
        \\define void @without_coverage() #0 {
        \\entry:
        \\  ret void
        \\}
        \\
        \\attributes #0 = { nosanitize_coverage nounwind }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser rejects sanitizer instrumentation calls explicitly" {
    const sanitizer_call =
        \\declare void @__sanitizer_cov_trace_pc_guard(ptr)
        \\
        \\define void @instrumented(ptr %guard) {
        \\entry:
        \\  call void @__sanitizer_cov_trace_pc_guard(ptr %guard)
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedInstrumentationCall, ir.Module.parse(std.testing.allocator, sanitizer_call));

    const tsan_call =
        \\declare void @__tsan_read4(ptr)
        \\
        \\define void @instrumented_tsan(ptr %p) {
        \\entry:
        \\  call void @__tsan_read4(ptr %p)
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedInstrumentationCall, ir.Module.parse(std.testing.allocator, tsan_call));

    const ubsan_call =
        \\declare void @__ubsan_handle_add_overflow(ptr, i64, i64)
        \\
        \\define void @instrumented_ubsan(ptr %data, i64 %lhs, i64 %rhs) {
        \\entry:
        \\  call void @__ubsan_handle_add_overflow(ptr %data, i64 %lhs, i64 %rhs)
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedInstrumentationCall, ir.Module.parse(std.testing.allocator, ubsan_call));
}

test "parser preserves llvm trap intrinsic call" {
    const trap_call =
        \\declare void @llvm.trap()
        \\
        \\define void @safety_trap() {
        \\entry:
        \\  call void @llvm.trap()
        \\  unreachable
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, trap_call);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("llvm.trap", call.callee);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(trap_call, output.writer.buffered());
}

test "parser preserves quoted direct callee names containing parentheses" {
    const input =
        \\define private fastcc void @"log.scoped(.default).err__anon_3522"(i16 %.0.val) unnamed_addr #0 align 1 {
        \\entry:
        \\  ret void
        \\}
        \\
        \\define void @caller(i16 %code) {
        \\entry:
        \\  call fastcc void @"log.scoped(.default).err__anon_3522"(i16 %code)
        \\  ret void
        \\}
        \\
        \\attributes #0 = { nounwind }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[1].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("\"log.scoped(.default).err__anon_3522\"", call.callee);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier preserves ReleaseSafe runtime call trap boundary" {
    const input =
        \\source_filename = "release_safe_call_boundary"
        \\
        \\declare void @zig_panic(ptr)
        \\
        \\define void @release_safe_call_boundary(i1 %ok, ptr %msg) {
        \\entry:
        \\  br i1 %ok, label %cont, label %panic, !prof !0
        \\panic:
        \\  call void @zig_panic(ptr %msg)
        \\  unreachable
        \\cont:
        \\  ret void
        \\}
        \\
        \\!0 = !{!"branch_weights", i32 1000, i32 1}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const panic_block = module.functions.items[0].blocks.items[1];
    try std.testing.expectEqual(@as(usize, 1), panic_block.instructions.items.len);
    try std.testing.expect(panic_block.instructions.items[0].kind == .call);
    try std.testing.expect(panic_block.terminator.? == .@"unreachable");

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier rejects direct call signature mismatch" {
    const input =
        \\declare i32 @callee(i32)
        \\
        \\define i32 @caller(ptr %p) {
        \\entry:
        \\  %r = call i32 @callee(ptr %p)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.CallSignatureMismatch, module.verify());
}

test "verifier rejects direct call calling convention mismatch" {
    const input =
        \\declare fastcc i32 @callee(i32)
        \\
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = call i32 @callee(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.CallSignatureMismatch, module.verify());
}

test "verifier accepts matching declaration and definition" {
    const input =
        \\declare i32 @callee(i32)
        \\
        \\define i32 @callee(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = call i32 @callee(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try module.verify();
}

test "call graph records direct call edges once" {
    const input =
        \\declare i32 @extern(i32)
        \\
        \\define i32 @helper(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %x = call i32 @helper(i32 %a)
        \\  %y = call i32 @helper(i32 %x)
        \\  %z = call i32 @extern(i32 %y)
        \\  ret i32 %z
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var graph = try call_graph.CallGraph.build(std.testing.allocator, module);
    defer graph.deinit();

    const callees = graph.calleesOf("caller") orelse return error.MissingCallGraphNode;
    try std.testing.expectEqual(@as(usize, 2), callees.len);
    try std.testing.expect(graph.hasDirectEdge("caller", "helper"));
    try std.testing.expect(graph.hasDirectEdge("caller", "extern"));
    try std.testing.expect(!graph.hasDirectEdge("helper", "extern"));
    try std.testing.expect(graph.hasDefinition("caller"));
    try std.testing.expect(graph.hasDefinition("helper"));
    try std.testing.expect(graph.hasDeclaration("extern"));
    try std.testing.expect(graph.isKnownCallee("extern"));

    const roots = [_][]const u8{"caller"};
    var reachable = try graph.reachableDefinitionsFromRoots(std.testing.allocator, &roots);
    defer reachable.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 2), reachable.items.len);
    try std.testing.expect(containsText(reachable.items, "caller"));
    try std.testing.expect(containsText(reachable.items, "helper"));
    try std.testing.expect(!containsText(reachable.items, "extern"));
}

test "function attributes classify direct call memory effects conservatively" {
    const input =
        \\declare i32 @pure(i32) readnone
        \\declare i32 @reads(ptr) readonly
        \\declare void @writes(ptr) writeonly
        \\declare i32 @unknown(i32)
        \\
        \\define i32 @caller(ptr %p, i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  %y = call i32 @reads(ptr %p)
        \\  call void @writes(ptr %p)
        \\  %z = call i32 @unknown(i32 %y)
        \\  ret i32 %z
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const block = module.functions.items[0].blocks.items[0];

    const pure_call = block.instructions.items[0].kind.call;
    const readonly_call = block.instructions.items[1].kind.call;
    const writeonly_call = block.instructions.items[2].kind.call;
    const unknown_call = block.instructions.items[3].kind.call;

    try std.testing.expectEqual(memory_effect.Effect.none, function_attrs.callMemoryEffect(module, pure_call));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, function_attrs.callMemoryEffect(module, readonly_call));
    try std.testing.expectEqual(memory_effect.Effect.memory_write, function_attrs.callMemoryEffect(module, writeonly_call));
    try std.testing.expectEqual(memory_effect.Effect.unknown, function_attrs.callMemoryEffect(module, unknown_call));
}

test "function attributes treat operand-bundled calls as unknown effects" {
    const input =
        \\declare i32 @pure() #0
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %x = call i32 @pure() [ "cold"() ]
        \\  ret i32 %x
        \\}
        \\
        \\attributes #0 = { memory(none) nounwind }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const bundled_call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqual(memory_effect.Effect.unknown, function_attrs.callMemoryEffect(module, bundled_call));
}

fn containsText(haystack: []const []const u8, needle: []const u8) bool {
    for (haystack) |item| {
        if (std.mem.eql(u8, item, needle)) return true;
    }
    return false;
}

test "function attributes resolve IPO attributes through groups" {
    const input =
        \\declare i32 @decl(i32) #0
        \\
        \\define internal i32 @helper(i32 %a) #1 {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\attributes #0 = { nofree nounwind memory(read) }
        \\attributes #1 = { alwaysinline nofree norecurse nosync nounwind memory(none) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const decl_attrs = function_attrs.resolvedDeclarationAttributes(module, module.declarations.items[0]);
    try std.testing.expect(decl_attrs.nofree);
    try std.testing.expect(decl_attrs.nounwind);
    try std.testing.expect(decl_attrs.readonly);

    const helper_attrs = function_attrs.resolvedFunctionAttributes(module, module.functions.items[0]);
    try std.testing.expect(helper_attrs.alwaysinline);
    try std.testing.expect(helper_attrs.nofree);
    try std.testing.expect(helper_attrs.norecurse);
    try std.testing.expect(helper_attrs.nosync);
    try std.testing.expect(helper_attrs.nounwind);
    try std.testing.expect(helper_attrs.readnone);
}

test "function attributes resolve attribute groups for call memory effects" {
    const input =
        \\declare i32 @pure(i32) #0
        \\declare i32 @reads(ptr) #1
        \\
        \\define i32 @caller(ptr %p, i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  %y = call i32 @reads(ptr %p)
        \\  ret i32 %x
        \\}
        \\
        \\attributes #0 = { nofree nosync nounwind willreturn memory(none) }
        \\attributes #1 = { nofree nosync nounwind willreturn memory(read) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const block = module.functions.items[0].blocks.items[0];

    const pure_call = block.instructions.items[0].kind.call;
    const readonly_call = block.instructions.items[1].kind.call;

    try std.testing.expectEqual(memory_effect.Effect.none, function_attrs.callMemoryEffect(module, pure_call));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, function_attrs.callMemoryEffect(module, readonly_call));
}

test "function attributes classify Zig memory effects conservatively" {
    const input =
        \\declare i32 @pure(i32) #0
        \\
        \\declare i32 @reads(ptr) #1
        \\
        \\declare i32 @arg_reads(ptr) #2
        \\
        \\declare void @arg_writes(ptr) #3
        \\
        \\declare void @readwrite(ptr) #4
        \\
        \\define i32 @caller(ptr %p, i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  %y = call i32 @reads(ptr %p)
        \\  %z = call i32 @arg_reads(ptr %p)
        \\  call void @arg_writes(ptr %p)
        \\  call void @readwrite(ptr %p)
        \\  ret i32 %z
        \\}
        \\
        \\attributes #0 = { mustprogress memory(none) "target-cpu"="x86-64" "target-features"="+sse2,-avx" }
        \\attributes #1 = { nounwind memory(read, argmem: none, inaccessiblemem: none, target_mem0: none) "frame-pointer"="all" }
        \\attributes #2 = { nounwind memory(argmem: read) }
        \\attributes #3 = { nounwind memory(argmem: write) }
        \\attributes #4 = { nounwind memory(readwrite, argmem: none, inaccessiblemem: none, target_mem0: none) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const block = module.functions.items[0].blocks.items[0];
    try std.testing.expectEqual(memory_effect.Effect.none, function_attrs.callMemoryEffect(module, block.instructions.items[0].kind.call));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, function_attrs.callMemoryEffect(module, block.instructions.items[1].kind.call));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, function_attrs.callMemoryEffect(module, block.instructions.items[2].kind.call));
    try std.testing.expectEqual(memory_effect.Effect.memory_write, function_attrs.callMemoryEffect(module, block.instructions.items[3].kind.call));
    try std.testing.expectEqual(memory_effect.Effect.unknown, function_attrs.callMemoryEffect(module, block.instructions.items[4].kind.call));

    const feature_attrs = target.features.parseAttributeText(module.attribute_groups.items[0]);
    try std.testing.expectEqualStrings("x86-64", feature_attrs.cpu.?);
    try std.testing.expect(feature_attrs.hasFeature("+sse2"));
    try std.testing.expect(feature_attrs.hasFeature("-avx"));

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "alias modref refines direct call memory effects" {
    const input =
        \\declare i32 @pure(i32) #0
        \\declare i32 @reads_all(ptr) #1
        \\declare void @arg_reads(ptr) #2
        \\declare void @arg_writes(ptr) #3
        \\declare void @inaccessible_write() #4
        \\declare void @unknown(ptr)
        \\
        \\define void @caller(i32 %seed) {
        \\entry:
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  %x = call i32 @pure(i32 %seed)
        \\  %y = call i32 @reads_all(ptr %left)
        \\  call void @arg_reads(ptr %left)
        \\  call void @arg_writes(ptr %right)
        \\  call void @arg_writes(ptr %left)
        \\  call void @inaccessible_write()
        \\  call void @unknown(ptr %left)
        \\  ret void
        \\}
        \\
        \\attributes #0 = { memory(none) }
        \\attributes #1 = { memory(read, argmem: none, inaccessiblemem: none, target_mem0: none) }
        \\attributes #2 = { memory(argmem: read) }
        \\attributes #3 = { memory(argmem: write) }
        \\attributes #4 = { memory(inaccessiblemem: write) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    const block = function.blocks.items[0];
    const left = ir.Value{ .named = "left" };

    try std.testing.expectEqual(alias.ModRefInfo.no_mod_ref, alias.modRefInModule(module, function, block.instructions.items[2], left));
    try std.testing.expectEqual(alias.ModRefInfo.ref, alias.modRefInModule(module, function, block.instructions.items[3], left));
    try std.testing.expectEqual(alias.ModRefInfo.ref, alias.modRefInModule(module, function, block.instructions.items[4], left));
    try std.testing.expectEqual(alias.ModRefInfo.no_mod_ref, alias.modRefInModule(module, function, block.instructions.items[5], left));
    try std.testing.expectEqual(alias.ModRefInfo.mod, alias.modRefInModule(module, function, block.instructions.items[6], left));
    try std.testing.expectEqual(alias.ModRefInfo.no_mod_ref, alias.modRefInModule(module, function, block.instructions.items[7], left));
    try std.testing.expectEqual(alias.ModRefInfo.unknown, alias.modRefInModule(module, function, block.instructions.items[8], left));
}

test "instcombine folds integer minmax intrinsics for same operands" {
    const input =
        \\declare i32 @llvm.smin.i32(i32, i32) #0
        \\
        \\define i32 @same_min(i32 %a) {
        \\entry:
        \\  %r = tail call i32 @llvm.smin.i32(i32 %a, i32 %a)
        \\  ret i32 %r
        \\}
        \\
        \\attributes #0 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, "instcombine,dce");
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace_output.deinit();
    _ = try pm.run(&module, &context, &trace_output.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\declare i32 @llvm.smin.i32(i32, i32) #0
        \\
        \\define i32 @same_min(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\attributes #0 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "globaldce removes unreferenced local functions and globals" {
    const input =
        \\@live_global = global i32 1
        \\@dead_global = internal global i32 2
        \\@exported_helper = alias i32 (i32), ptr @helper
        \\
        \\define internal i32 @helper(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
        \\define internal i32 @dead(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
        \\define i32 @entry(i32 %a) {
        \\entry:
        \\  %r = call i32 @helper(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, "globaldce");
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace.deinit();
    _ = try pm.run(&module, &context, &trace.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\@live_global = global i32 1
        \\
        \\@exported_helper = alias i32 (i32), ptr @helper
        \\
        \\define internal i32 @helper(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
        \\define i32 @entry(i32 %a) {
        \\entry:
        \\  %r = call i32 @helper(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "globaldce removes unreferenced local comdat members" {
    const input =
        \\$grp = comdat any
        \\
        \\@member = internal global i32 1, comdat($grp)
        \\@dead = internal global i32 2
        \\
        \\define internal i32 @helper(i32 %x) comdat($grp) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
        \\define internal i32 @dead_fn(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, "globaldce");
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace.deinit();
    _ = try pm.run(&module, &context, &trace.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings("", output.writer.buffered());
}

test "globaldce removes unreferenced local thread local globals" {
    const input =
        \\@tls = internal thread_local global i32 1
        \\@dead = internal global i32 2
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, "globaldce");
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace.deinit();
    _ = try pm.run(&module, &context, &trace.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings("", output.writer.buffered());
}

test "normalizer accepts empty modules after comparison noise stripping" {
    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator,
        \\; ModuleID = 'empty.ll'
        \\source_filename = "empty.ll"
        \\
    );
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings("", normalized);
}

test "normalizer canonicalizes numeric local SSA names" {
    const input =
        \\define i32 @renumber(i32 %0) {
        \\entry:
        \\  %2 = add i32 %0, 1
        \\  %3 = add i32 %2, 1
        \\  ret i32 %3
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    const expected =
        \\define i32 @renumber(i32 %0) {
        \\entry:
        \\  %1 = add i32 %0, 1
        \\  %2 = add i32 %1, 1
        \\  ret i32 %2
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, normalized);
}

test "verifier rejects use before definition in the same block" {
    const input =
        \\define i32 @bad(i32 %a) {
        \\entry:
        \\  %y = add i32 %x, 1
        \\  %x = add i32 %a, 1
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.ValueDoesNotDominateUse, module.verify());
}

test "verifier rejects value that does not dominate a merge use" {
    const input =
        \\define i32 @bad(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  %x = add i32 %a, 1
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  ret i32 %x
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.ValueDoesNotDominateUse, module.verify());
}

test "verifier rejects phi incoming blocks that are not exact predecessors" {
    const wrong_predecessor =
        \\define i32 @bad(i32 %a) {
        \\entry:
        \\  br label %merge
        \\unused:
        \\  ret i32 %a
        \\merge:
        \\  %v = phi i32 [ %a, %entry ], [ %a, %unused ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var wrong_module = try ir.Module.parse(std.testing.allocator, wrong_predecessor);
    defer wrong_module.deinit();
    try std.testing.expectError(error.PhiIncomingNotPredecessor, wrong_module.verify());

    const missing_predecessor =
        \\define i32 @bad(i32 %a) {
        \\entry:
        \\  br label %merge
        \\other:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %entry ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var missing_module = try ir.Module.parse(std.testing.allocator, missing_predecessor);
    defer missing_module.deinit();
    try std.testing.expectError(error.MissingPhiIncoming, missing_module.verify());

    const duplicate_predecessor =
        \\define i32 @bad(i32 %a) {
        \\entry:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %entry ], [ %a, %entry ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var duplicate_module = try ir.Module.parse(std.testing.allocator, duplicate_predecessor);
    defer duplicate_module.deinit();
    try std.testing.expectError(error.DuplicatePhiIncoming, duplicate_module.verify());

    const duplicate_edge_different_values =
        \\define i32 @bad(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %merge, label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %entry ], [ %b, %entry ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var duplicate_edge_module = try ir.Module.parse(std.testing.allocator, duplicate_edge_different_values);
    defer duplicate_edge_module.deinit();
    try std.testing.expectError(error.DuplicatePhiIncoming, duplicate_edge_module.verify());
}

test "verifier rejects phi after non-phi instructions" {
    const input =
        \\define i32 @bad(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %x = add i32 %a, 1
        \\  %v = phi i32 [ %a, %left ], [ %x, %right ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.PhiAfterNonPhi, module.verify());
}

test "verifier rejects entry block predecessors" {
    const input =
        \\define void @bad() {
        \\entry:
        \\  br label %entry
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.EntryBlockHasPredecessors, module.verify());
}

test "verifier rejects invalid memory alignment" {
    const input =
        \\define i32 @bad(ptr %p) {
        \\entry:
        \\  %v = load i32, ptr %p, align 3
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.InvalidAlignment, module.verify());
}

test "parser preserves indirect call form conservatively" {
    const indirect =
        \\define i32 @caller(ptr %fn, i32 %a) {
        \\entry:
        \\  %r = call i32 %fn(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, indirect);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(call.callee_value != null);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(indirect, output.writer.buffered());
}

test "parser rejects unsupported control-flow call forms" {
    const invoke =
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = invoke i32 @callee(i32 %a) to label %ok unwind label %bad
        \\ok:
        \\  ret i32 %r
        \\bad:
        \\  unreachable
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedCallTerminator, ir.Module.parse(std.testing.allocator, invoke));

    const callbr =
        \\define void @asm_goto() {
        \\entry:
        \\  callbr void asm sideeffect "", ""() to label %fallthrough [label %target]
        \\fallthrough:
        \\  ret void
        \\target:
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedCallTerminator, ir.Module.parse(std.testing.allocator, callbr));

    const landingpad =
        \\define ptr @eh_personality() {
        \\entry:
        \\  %lp = landingpad { ptr, i32 }
        \\          cleanup
        \\  ret ptr undef
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, landingpad));

    const resume_ir =
        \\define void @resume_eh() {
        \\entry:
        \\  resume ptr undef
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, resume_ir));

    const catchswitch =
        \\define void @catchswitch_eh() {
        \\entry:
        \\  catchswitch within none [label %handler] unwind to caller
        \\handler:
        \\  unreachable
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, catchswitch));

    const cleanupret =
        \\define void @cleanupret_eh() {
        \\entry:
        \\  cleanupret from none unwind to caller
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, cleanupret));

    const catchret =
        \\define void @catchret_eh(ptr %tok) {
        \\entry:
        \\  catchret from %tok to label %done
        \\done:
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, catchret));

    const catchpad =
        \\define ptr @catchpad_eh(ptr %tok) {
        \\entry:
        \\  %cp = catchpad within %tok []
        \\  ret ptr undef
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, catchpad));

    const cleanuppad =
        \\define ptr @cleanuppad_eh(ptr %tok) {
        \\entry:
        \\  %cp = cleanuppad within %tok []
        \\  ret ptr undef
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, cleanuppad));

    const personality =
        \\define void @personality_eh() personality ptr @__gxx_personality_v0 {
        \\entry:
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, personality));
}

test "parser preserves scalar global variables" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@g = internal global i32 42, align 4
        \\@c = private constant i8 undef
        \\@hidden = extern_weak hidden constant ptr, align 8
        \\
        \\define i32 @readable(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 3), module.globals.items.len);
    try std.testing.expectEqual(ir.FunctionLinkage.internal, module.globals.items[0].linkage);
    try std.testing.expectEqual(ir.GlobalKind.global, module.globals.items[0].kind);
    try std.testing.expectEqual(@as(i128, 42), module.globals.items[0].initializer.scalar.int);
    try std.testing.expectEqualStrings("align 4", module.globals.items[0].attrs.?);
    try std.testing.expectEqual(ir.FunctionLinkage.private, module.globals.items[1].linkage);
    try std.testing.expectEqual(ir.GlobalKind.constant, module.globals.items[1].kind);
    try std.testing.expectEqual(ir.Value.undef, module.globals.items[1].initializer.scalar);
    try std.testing.expectEqual(ir.FunctionLinkage.extern_weak, module.globals.items[2].linkage);
    try std.testing.expectEqualStrings("hidden", module.globals.items[2].address_attrs.?);
    try std.testing.expectEqual(ir.GlobalKind.constant, module.globals.items[2].kind);
    try std.testing.expect(module.globals.items[2].initializer == .none);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves scalar floating point global initializers" {
    const input =
        \\@gf = private unnamed_addr global float 1.250000e+00, align 4
        \\@gd = private unnamed_addr global double 1.230000e+00, align 8
        \\
        \\define double @read_double() {
        \\entry:
        \\  %v = load double, ptr @gd, align 8
        \\  ret double %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 2), module.globals.items.len);
    try std.testing.expectEqualStrings("1.250000e+00", module.globals.items[0].initializer.scalar.fp);
    try std.testing.expectEqualStrings("1.230000e+00", module.globals.items[1].initializer.scalar.fp);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier rejects mismatched scalar floating point global initializers" {
    const fp_on_int =
        \\@bad = global i32 1.250000e+00
        \\
    ;
    var int_module = try ir.Module.parse(std.testing.allocator, fp_on_int);
    defer int_module.deinit();
    try std.testing.expectError(error.UnsupportedGlobalVariable, int_module.verify());

    const int_on_fp =
        \\@bad = global double 1
        \\
    ;
    var fp_module = try ir.Module.parse(std.testing.allocator, int_on_fp);
    defer fp_module.deinit();
    try std.testing.expectError(error.UnsupportedGlobalVariable, fp_module.verify());
}

test "parser preserves module flags and comdat records" {
    const input =
        \\source_filename = "module.zig"
        \\
        \\$foo = comdat any
        \\
        \\@g = internal global i32 42, comdat($foo)
        \\
        \\!llvm.module.flags = !{!0}
        \\!0 = !{i32 2, !"Debug Info Version", i32 3}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectEqual(@as(usize, 1), module.comdats.items.len);
    try std.testing.expectEqualStrings("$foo = comdat any", module.comdats.items[0]);
    try std.testing.expectEqual(@as(usize, 2), module.metadata.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves weak linkage and verifier rejects unknown comdat references" {
    const weak_ir =
        \\@weak_global = weak global i32 1
        \\
        \\define weak i32 @weak_function() {
        \\entry:
        \\  ret i32 1
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, weak_ir);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(ir.FunctionLinkage.weak, module.globals.items[0].linkage);
    try std.testing.expectEqual(ir.FunctionLinkage.weak, module.functions.items[0].linkage);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(weak_ir, output.writer.buffered());

    const bad_comdat =
        \\@member = internal global i32 1, comdat($missing)
        \\
        \\define i32 @read_member() {
        \\entry:
        \\  %v = load i32, ptr @member, align 4
        \\  ret i32 %v
        \\}
        \\
    ;
    var bad_module = try ir.Module.parse(std.testing.allocator, bad_comdat);
    defer bad_module.deinit();
    try std.testing.expectError(error.InvalidComdat, bad_module.verify());
}

test "parser preserves size attributes and profile metadata opaquely" {
    const input =
        \\define minsize optsize i32 @small(i1 %cond, i32 %a) #0 {
        \\entry:
        \\  br i1 %cond, label %then, label %else, !prof !0
        \\then:
        \\  ret i32 %a
        \\else:
        \\  ret i32 0
        \\}
        \\
        \\attributes #0 = { minsize optsize nounwind }
        \\
        \\!0 = !{!"branch_weights", i32 1, i32 100}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "target feature attributes are extractable but not optimization inputs" {
    const attrs = target.features.parseAttributeText(
        \\attributes #0 = { minsize "target-cpu"="x86-64" "target-features"="+sse,+sse2,-avx" }
    );

    try std.testing.expectEqualStrings("x86-64", attrs.cpu.?);
    try std.testing.expectEqualStrings("+sse,+sse2,-avx", attrs.features.?);
    try std.testing.expect(attrs.hasFeature("+sse2"));
    try std.testing.expect(attrs.hasFeature("-avx"));
    try std.testing.expect(!attrs.hasFeature("+avx"));
}

test "verifier rejects unsupported aggregate globals explicitly" {
    const input =
        \\@s = private unnamed_addr constant [2 x i16] c"abc\00"
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expectError(error.UnsupportedGlobalVariable, module.verify());
}

test "parser preserves semicolons inside global C string literals" {
    const input =
        \\@ansi = private unnamed_addr constant [13 x i8] c"\1B[J\1B]9;4;0\1B\\\00", align 1
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings(
        "c\"\\1B[J\\1B]9;4;0\\1B\\\\\\00\"",
        module.globals.items[0].initializer.c_string,
    );

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves pointer global constant expression initializers" {
    const input =
        \\@vram = private unnamed_addr constant ptr inttoptr (i64 536870912 to ptr), align 8
        \\
        \\define void @write() {
        \\entry:
        \\  store volatile i8 88, ptr inttoptr (i64 536870912 to ptr), align 1
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings(
        "inttoptr (i64 536870912 to ptr)",
        module.globals.items[0].initializer.scalar.constant_expr,
    );

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves scalar array global constants from switch tables" {
    const input =
        \\@switch.table = private unnamed_addr constant [3 x i32] [i32 11, i32 13, i32 17], align 4
        \\
        \\define i32 @lookup(i8 %idx) {
        \\entry:
        \\  %wide = zext nneg i8 %idx to i64
        \\  %gep = getelementptr inbounds nuw i32, ptr @switch.table, i64 %wide
        \\  %value = load i32, ptr %gep, align 4
        \\  ret i32 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 1), module.globals.items.len);
    const initializer = module.globals.items[0].initializer.array;
    try std.testing.expectEqual(ir.Type{ .int = 32 }, initializer.elem_ty);
    try std.testing.expectEqual(@as(usize, 3), initializer.values.items.len);
    try std.testing.expectEqual(@as(i128, 13), initializer.values.items[1].int);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(
        \\@switch.table = private unnamed_addr constant [3 x i32] [i32 11, i32 13, i32 17], align 4
        \\
        \\define i32 @lookup(i8 %idx) {
        \\entry:
        \\  %wide = zext nneg i8 %idx to i64
        \\  %gep = getelementptr i32, ptr @switch.table, i64 %wide
        \\  %value = load i32, ptr %gep, align 4
        \\  ret i32 %value
        \\}
        \\
    , output.writer.buffered());
}

test "parser preserves source-backed cast flags" {
    const input =
        \\define i8 @narrow(i32 %x) {
        \\entry:
        \\  %t = trunc nuw i32 %x to i8
        \\  ret i8 %t
        \\}
        \\
        \\define i64 @widen(i8 %x) {
        \\entry:
        \\  %z = zext nneg i8 %x to i64
        \\  ret i64 %z
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser verifies and prints scalar bitcast instruction" {
    const input =
        \\define i64 @bitcast_double_to_i64(double %x) {
        \\entry:
        \\  %r = bitcast double %x to i64
        \\  ret i64 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cast = module.functions.items[0].blocks.items[0].instructions.items[0].kind.cast;
    try std.testing.expectEqual(ir.CastOp.bitcast, cast.op);
    try std.testing.expectEqual(@as(ir.Type, .double), cast.from_ty);
    try std.testing.expectEqual(ir.Type{ .int = 64 }, cast.to_ty);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser verifies and prints vector bitcast instruction" {
    const input =
        \\define i16 @bitcast_vector_mask(<16 x i1> %mask) {
        \\entry:
        \\  %r = bitcast <16 x i1> %mask to i16
        \\  ret i16 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cast = module.functions.items[0].blocks.items[0].instructions.items[0].kind.cast;
    try std.testing.expectEqual(ir.CastOp.bitcast, cast.op);
    try std.testing.expect(cast.from_ty.eql(ir.Type{ .vector = .{
        .len = 16,
        .elem_ty = .{ .int = 1 },
    } }));
    try std.testing.expectEqual(ir.Type{ .int = 16 }, cast.to_ty);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier accepts vector integer extension casts" {
    const input =
        \\define <2 x i64> @vector_zext(<2 x i32> %value) {
        \\entry:
        \\  %wide = zext <2 x i32> %value to <2 x i64>
        \\  ret <2 x i64> %wide
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cast = module.functions.items[0].blocks.items[0].instructions.items[0].kind.cast;
    try std.testing.expectEqual(ir.CastOp.zext, cast.op);
    try std.testing.expect(cast.from_ty.eql(ir.Type{ .vector = .{
        .len = 2,
        .elem_ty = .{ .int = 32 },
    } }));
    try std.testing.expect(cast.to_ty.eql(ir.Type{ .vector = .{
        .len = 2,
        .elem_ty = .{ .int = 64 },
    } }));
}

test "parser preserves vector global initializers and vector FP-to-int casts" {
    const input =
        \\@vec = private unnamed_addr global <2 x float> <float 1.000000e+02, float 5.120000e+02>, align 8
        \\
        \\define <2 x i10> @convert(<2 x float> %value) {
        \\entry:
        \\  %cmp = fcmp ole <2 x float> %value, <float 1.000000e+02, float 5.120000e+02>
        \\  %int = fptosi <2 x float> %value to <2 x i10>
        \\  ret <2 x i10> %int
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expect(module.globals.items[0].ty.eql(ir.Type{ .vector = .{
        .len = 2,
        .elem_ty = .float,
    } }));
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].kind.fcmp.operand_ty.eql(ir.Type{ .vector = .{
        .len = 2,
        .elem_ty = .float,
    } }));
    try std.testing.expectEqual(ir.CastOp.fptosi, module.functions.items[0].blocks.items[0].instructions.items[1].kind.cast.op);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier rejects invalid scalar bitcast shapes" {
    const width_mismatch =
        \\define i32 @bad_width(double %x) {
        \\entry:
        \\  %r = bitcast double %x to i32
        \\  ret i32 %r
        \\}
        \\
    ;
    const pointer_bitcast =
        \\define i64 @bad_ptr(ptr %x) {
        \\entry:
        \\  %r = bitcast ptr %x to i64
        \\  ret i64 %r
        \\}
        \\
    ;

    var bad_width = try ir.Module.parse(std.testing.allocator, width_mismatch);
    defer bad_width.deinit();
    try std.testing.expectError(error.InvalidCast, bad_width.verify());

    var bad_ptr = try ir.Module.parse(std.testing.allocator, pointer_bitcast);
    defer bad_ptr.deinit();
    try std.testing.expectError(error.InvalidCast, bad_ptr.verify());
}

test "parser and verifier reject invalid cast flags intentionally" {
    const duplicate_flag =
        \\define i8 @duplicate(i32 %x) {
        \\entry:
        \\  %t = trunc nuw nuw i32 %x to i8
        \\  ret i8 %t
        \\}
        \\
    ;
    const unsupported_flag =
        \\define i8 @unsupported(i32 %x) {
        \\entry:
        \\  %t = trunc exact i32 %x to i8
        \\  ret i8 %t
        \\}
        \\
    ;
    const invalid_trunc_flag =
        \\define i8 @invalid_trunc(i32 %x) {
        \\entry:
        \\  %t = trunc nneg i32 %x to i8
        \\  ret i8 %t
        \\}
        \\
    ;
    const invalid_zext_flag =
        \\define i64 @invalid_zext(i8 %x) {
        \\entry:
        \\  %z = zext nuw i8 %x to i64
        \\  ret i64 %z
        \\}
        \\
    ;

    try std.testing.expectError(error.InvalidInstructionFlag, ir.Module.parse(std.testing.allocator, duplicate_flag));
    try std.testing.expectError(error.InvalidInstructionFlag, ir.Module.parse(std.testing.allocator, unsupported_flag));

    var invalid_trunc = try ir.Module.parse(std.testing.allocator, invalid_trunc_flag);
    defer invalid_trunc.deinit();
    try std.testing.expectError(error.InvalidInstructionFlag, invalid_trunc.verify());

    var invalid_zext = try ir.Module.parse(std.testing.allocator, invalid_zext_flag);
    defer invalid_zext.deinit();
    try std.testing.expectError(error.InvalidInstructionFlag, invalid_zext.verify());
}

test "parser preserves scalar float arithmetic and compare IR" {
    const input =
        \\define float @float_add(float %a, float %b) {
        \\entry:
        \\  %sum = fadd float %a, %b
        \\  ret float %sum
        \\}
        \\
        \\define double @float_select(double %a, double %b, i1 %cond) {
        \\entry:
        \\  %value = select i1 %cond, double %a, double %b
        \\  ret double %value
        \\}
        \\
        \\define double @float_mul(double %a, double %b) {
        \\entry:
        \\  %product = fmul double %a, %b
        \\  ret double %product
        \\}
        \\
        \\define float @float_sub(float %a, float %b) {
        \\entry:
        \\  %difference = fsub float %a, %b
        \\  ret float %difference
        \\}
        \\
        \\define double @float_div(double %a, double %b) {
        \\entry:
        \\  %quotient = fdiv double %a, %b
        \\  ret double %quotient
        \\}
        \\
        \\define float @float_rem(float %a, float %b) {
        \\entry:
        \\  %remainder = frem float %a, %b
        \\  ret float %remainder
        \\}
        \\
        \\define i1 @float_less(float %a, float %b) {
        \\entry:
        \\  %less = fcmp olt float %a, %b
        \\  ret i1 %less
        \\}
        \\
        \\define double @float_extend(float %a) {
        \\entry:
        \\  %wide = fpext float %a to double
        \\  ret double %wide
        \\}
        \\
        \\define i32 @float_to_signed(float %a) {
        \\entry:
        \\  %int = fptosi float %a to i32
        \\  ret i32 %int
        \\}
        \\
        \\define i32 @float_to_unsigned(float %a) {
        \\entry:
        \\  %int = fptoui float %a to i32
        \\  ret i32 %int
        \\}
        \\
        \\define float @float_narrow(double %a) {
        \\entry:
        \\  %narrow = fptrunc double %a to float
        \\  ret float %narrow
        \\}
        \\
        \\define float @float_from_signed(i32 %a) {
        \\entry:
        \\  %value = sitofp i32 %a to float
        \\  ret float %value
        \\}
        \\
        \\define double @double_from_unsigned(i32 %a) {
        \\entry:
        \\  %value = uitofp i32 %a to double
        \\  ret double %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expect(module.functions.items[0].ret_ty.eql(.float));
    try std.testing.expect(module.functions.items[1].ret_ty.eql(.double));
    try std.testing.expect(module.functions.items[2].ret_ty.eql(.double));
    try std.testing.expect(module.functions.items[3].ret_ty.eql(.float));
    try std.testing.expect(module.functions.items[4].ret_ty.eql(.double));
    try std.testing.expect(module.functions.items[5].ret_ty.eql(.float));
    try std.testing.expect(module.functions.items[6].ret_ty.eql(.{ .int = 1 }));
    try std.testing.expectEqual(ir.CastOp.fpext, module.functions.items[7].blocks.items[0].instructions.items[0].kind.cast.op);
    try std.testing.expectEqual(ir.CastOp.fptosi, module.functions.items[8].blocks.items[0].instructions.items[0].kind.cast.op);
    try std.testing.expectEqual(ir.CastOp.fptoui, module.functions.items[9].blocks.items[0].instructions.items[0].kind.cast.op);
    try std.testing.expectEqual(ir.CastOp.fptrunc, module.functions.items[10].blocks.items[0].instructions.items[0].kind.cast.op);
    try std.testing.expectEqual(ir.CastOp.sitofp, module.functions.items[11].blocks.items[0].instructions.items[0].kind.cast.op);
    try std.testing.expectEqual(ir.CastOp.uitofp, module.functions.items[12].blocks.items[0].instructions.items[0].kind.cast.op);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves extended scalar FP ABI surface" {
    const input =
        \\declare i32 @__eqtf2(fp128, fp128)
        \\
        \\define fp128 @fp128_roundtrip(ptr %p, fp128 %x) {
        \\entry:
        \\  store fp128 %x, ptr %p, align 16
        \\  %loaded = load fp128, ptr %p, align 16
        \\  %cmp = call i32 @__eqtf2(fp128 %loaded, fp128 0xL00000000000000004002A00000000000)
        \\  ret fp128 0xL00000000000000004004100000000000
        \\}
        \\
        \\define void @longdouble_sink(x86_fp80 %x) {
        \\entry:
        \\  ret void
        \\}
        \\
        \\define void @longdouble_caller(x86_fp80 %x) {
        \\entry:
        \\  call void @longdouble_sink(x86_fp80 %x)
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expect(module.functions.items[0].ret_ty.eql(.fp128));
    try std.testing.expect(module.functions.items[0].params.items[1].ty.eql(.fp128));
    try std.testing.expect(module.functions.items[1].params.items[0].ty.eql(.x86_fp80));
    try std.testing.expect(module.functions.items[2].params.items[0].ty.eql(.x86_fp80));
    try std.testing.expectEqual(fp_semantics.Category.normal, (try fp_semantics.classify(.fp128, "0xL00000000000000004002A00000000000")).category);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser rejects unsupported floating point compare forms" {
    const fcmp_predicate_input =
        \\define i1 @cmp(float %a, float %b) {
        \\entry:
        \\  %r = fcmp bad float %a, %b
        \\  ret i1 %r
        \\}
        \\
    ;
    const fcmp_type_input =
        \\define i1 @cmp(float %a, float %b) {
        \\entry:
        \\  %r = fcmp olt i32 1, 2
        \\  ret i1 %r
        \\}
        \\
    ;

    try std.testing.expectError(error.UnsupportedPredicate, ir.Module.parse(std.testing.allocator, fcmp_predicate_input));

    var module = try ir.Module.parse(std.testing.allocator, fcmp_type_input);
    defer module.deinit();
    try std.testing.expectError(error.TypeMismatch, module.verify());
}

test "parser preserves scalar fcmp predicate surface" {
    const input =
        \\define i1 @float_predicates(float %a, float %b) {
        \\entry:
        \\  %p0 = fcmp false float %a, %b
        \\  %p1 = fcmp oeq float %a, %b
        \\  %p2 = fcmp ogt float %a, %b
        \\  %p3 = fcmp oge float %a, %b
        \\  %p4 = fcmp olt float %a, %b
        \\  %p5 = fcmp ole float %a, %b
        \\  %p6 = fcmp one float %a, %b
        \\  %p7 = fcmp ord float %a, %b
        \\  %p8 = fcmp uno float %a, %b
        \\  %p9 = fcmp ueq float %a, %b
        \\  %p10 = fcmp ugt float %a, %b
        \\  %p11 = fcmp uge float %a, %b
        \\  %p12 = fcmp ult float %a, %b
        \\  %p13 = fcmp ule float %a, %b
        \\  %p14 = fcmp une float %a, %b
        \\  %p15 = fcmp true float %a, %b
        \\  ret i1 %p15
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves fast-math flags without enabling FP folds" {
    const input =
        \\define float @fast_math_flags(float %a, float %b) {
        \\entry:
        \\  %sum = fadd fast float %a, %b
        \\  %product = fmul nnan ninf nsz arcp float %sum, %b
        \\  %quotient = fdiv contract afn reassoc float %product, %b
        \\  %cmp = fcmp nnan ninf olt float %sum, %quotient
        \\  %value = select i1 %cmp, float %sum, float %quotient
        \\  ret float %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser keeps unsupported FP surface closed" {
    const invalid_fast_mix_input =
        \\define float @invalid_fast_mix(float %a, float %b) {
        \\entry:
        \\  %r = fadd fast nnan float %a, %b
        \\  ret float %r
        \\}
        \\
    ;
    const integer_fast_math_input =
        \\define i32 @integer_fast_math(i32 %a, i32 %b) {
        \\entry:
        \\  %r = add nnan i32 %a, %b
        \\  ret i32 %r
        \\}
        \\
    ;
    const vector_fcmp_input =
        \\define i1 @vector_cmp(float %a, float %b) {
        \\entry:
        \\  %r = fcmp olt <4 x float> %a, %b
        \\  ret i1 %r
        \\}
        \\
    ;
    const vector_fp_binary_input =
        \\define <2 x float> @vector_fadd(<2 x float> %a, <2 x float> %b) {
        \\entry:
        \\  %r = fadd <2 x float> %a, %b
        \\  ret <2 x float> %r
        \\}
        \\
    ;
    const constrained_input =
        \\define float @constrained(float %a, float %b) {
        \\entry:
        \\  %r = call float @llvm.experimental.constrained.fadd.f32(float %a, float %b)
        \\  ret float %r
        \\}
        \\
    ;

    try std.testing.expectError(error.InvalidInstruction, ir.Module.parse(std.testing.allocator, invalid_fast_mix_input));
    var integer_fast_math = try ir.Module.parse(std.testing.allocator, integer_fast_math_input);
    defer integer_fast_math.deinit();
    try std.testing.expectError(error.InvalidInstructionFlag, integer_fast_math.verify());
    var vector_fcmp = try ir.Module.parse(std.testing.allocator, vector_fcmp_input);
    defer vector_fcmp.deinit();
    try std.testing.expectError(error.TypeMismatch, vector_fcmp.verify());

    var vector_fp_binary = try ir.Module.parse(std.testing.allocator, vector_fp_binary_input);
    defer vector_fp_binary.deinit();
    try std.testing.expectError(error.UnsupportedType, vector_fp_binary.verify());

    var constrained = try ir.Module.parse(std.testing.allocator, constrained_input);
    defer constrained.deinit();
    try std.testing.expectError(error.UnknownFunction, constrained.verify());
}

test "x86_64 codegen lowers add args to assembly" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add_args(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);

    const expected =
        "\t.text\n" ++
        "\t.globl add_args\n" ++
        "add_args:\n" ++
        "\tmovl %edi, %eax\n" ++
        "\taddl %esi, %eax\n" ++
        "\tretq\n";
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "x86_64 codegen lowers return constant and argument" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @return_constant() {
        \\entry:
        \\  ret i32 42
        \\}
        \\
        \\define i32 @return_arg(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var constant = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer constant.deinit(std.testing.allocator);
    var arg = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[1]);
    defer arg.deinit(std.testing.allocator);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(constant, &output.writer);
    try mc.assembly.printFunction(arg, &output.writer);

    const expected =
        "\t.text\n" ++
        "\t.globl return_constant\n" ++
        "return_constant:\n" ++
        "\tmovl $42, %eax\n" ++
        "\tretq\n" ++
        "\t.text\n" ++
        "\t.globl return_arg\n" ++
        "return_arg:\n" ++
        "\tmovl %edi, %eax\n" ++
        "\tretq\n";
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "x86_64 codegen lowers bitwise args to assembly" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @bitwise_args(i32 %a, i32 %b) {
        \\entry:
        \\  %v = xor i32 %a, %b
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);

    const expected =
        "\t.text\n" ++
        "\t.globl bitwise_args\n" ++
        "bitwise_args:\n" ++
        "\tmovl %edi, %eax\n" ++
        "\txorl %esi, %eax\n" ++
        "\tretq\n";
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "x86_64 codegen lowers simple conditional returns to assembly" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @select_return(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  ret i32 %a
        \\else:
        \\  ret i32 %b
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);

    const expected =
        "\t.text\n" ++
        "\t.globl select_return\n" ++
        "select_return:\n" ++
        "\ttestb %dil, %dil\n" ++
        "\tje .Lselect_return_else\n" ++
        ".Lselect_return_then:\n" ++
        "\tmovl %esi, %eax\n" ++
        "\tretq\n" ++
        ".Lselect_return_else:\n" ++
        "\tmovl %edx, %eax\n" ++
        "\tretq\n";
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "x86_64 encoding emits expected add args bytes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add_args(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{ 0x89, 0xf8, 0x01, 0xf0, 0xc3 }, bytes);
}

test "x86_64 elf writer emits relocatable object metadata" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add_args(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    const object = try mc.elf.buildObject(std.testing.allocator, &.{machine});
    defer std.testing.allocator.free(object);

    try std.testing.expect(object.len >= 64);
    try std.testing.expectEqualSlices(u8, "\x7fELF", object[0..4]);
    try std.testing.expectEqual(@as(u8, 2), object[4]);
    try std.testing.expect(std.mem.indexOf(u8, object, ".text") != null);
    try std.testing.expect(std.mem.indexOf(u8, object, ".symtab") != null);
    try std.testing.expect(std.mem.indexOf(u8, object, "add_args") != null);
}

test "x86_64 elf writer emits direct call relocation metadata" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee()
        \\
        \\define i32 @call_no_args() {
        \\entry:
        \\  %r = call i32 @callee()
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    const object = try mc.elf.buildObject(std.testing.allocator, &.{machine});
    defer std.testing.allocator.free(object);

    try std.testing.expect(std.mem.indexOf(u8, object, ".rela.text") != null);
    try std.testing.expect(std.mem.indexOf(u8, object, "callee") != null);
}

test "x86_64 elf writer emits selected local function aliases" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@public_add = alias i32 (i32, i32), ptr @internal_add
        \\
        \\define private i32 @internal_add(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    const object = try mc.elf.buildObjectWithAliases(std.testing.allocator, &.{machine}, module.aliases.items);
    defer std.testing.allocator.free(object);

    try std.testing.expect(std.mem.indexOf(u8, object, "internal_add") != null);
    try std.testing.expect(std.mem.indexOf(u8, object, "public_add") != null);
}

test "x86_64 codegen rejects unsupported control flow" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @branch(i32 %a) {
        \\entry:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectError(
        error.UnsupportedCodegenControlFlow,
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}

test "x86_64 codegen rejects stack-passed parameters" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_arg(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g) {
        \\entry:
        \\  ret i32 %g
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectError(
        error.UnsupportedCodegenAbi,
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}

test "x86_64 codegen rejects unsupported call ABI shapes" {
    const unsupported_cc_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare coldcc i32 @callee()
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %r = call coldcc i32 @callee()
        \\  ret i32 %r
        \\}
        \\
    ;
    var unsupported_cc_module = try ir.Module.parse(std.testing.allocator, unsupported_cc_input);
    defer unsupported_cc_module.deinit();
    try unsupported_cc_module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenCallingConvention,
        codegen.x86_64.lowerFunction(std.testing.allocator, unsupported_cc_module.target_triple.?, unsupported_cc_module.functions.items[0]),
    );

    const stack_arg_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32, i32, i32, i32, i32, i32, i32)
        \\
        \\define i32 @caller(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g) {
        \\entry:
        \\  %r = call i32 @callee(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g)
        \\  ret i32 %r
        \\}
        \\
    ;
    var stack_arg_module = try ir.Module.parse(std.testing.allocator, stack_arg_input);
    defer stack_arg_module.deinit();
    try stack_arg_module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenAbi,
        codegen.x86_64.lowerFunction(std.testing.allocator, stack_arg_module.target_triple.?, stack_arg_module.functions.items[0]),
    );
}

test "x86_64 codegen rejects unsupported call live pressure" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee()
        \\
        \\define i32 @caller(i32 %a, i32 %b) {
        \\entry:
        \\  %r = call i32 @callee()
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectError(
        error.UnsupportedLiveAcrossCall,
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}

test "x86_64 codegen lowers canonical accumulator loops without function-name dispatch" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @uncurated_accumulator(i32 %limit) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %index = phi i32 [ 0, %entry ], [ %index.next, %body ]
        \\  %sum = phi i32 [ 0, %entry ], [ %sum.next, %body ]
        \\  %continue = icmp ult i32 %index, %limit
        \\  br i1 %continue, label %body, label %exit
        \\body:
        \\  %sum.next = add i32 %sum, %index
        \\  %index.next = add i32 %index, 1
        \\  br label %loop
        \\exit:
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes checked guard cfg through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc void @expanded_numeric_casts.integerPartOutOfBounds()
        \\
        \\define i32 @expanded_numeric_casts.expanded_int_from_float(float %arg0) {
        \\entry:
        \\  %below_min = fcmp ole float %arg0, -2147483904.0
        \\  %above_max = fcmp oge float %arg0, 2147483648.0
        \\  %out_of_bounds = or i1 %below_min, %above_max
        \\  br i1 %out_of_bounds, label %panic, label %ok
        \\panic:
        \\  call fastcc void @expanded_numeric_casts.integerPartOutOfBounds()
        \\  unreachable
        \\ok:
        \\  %converted = fptosi float %arg0 to i32
        \\  ret i32 %converted
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes scalar numeric casts through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @widen(float %x) {
        \\entry:
        \\  %wide = fpext float %x to double
        \\  ret double %wide
        \\}
        \\
        \\define float @narrow(double %x) {
        \\entry:
        \\  %narrow = fptrunc double %x to float
        \\  ret float %narrow
        \\}
        \\
        \\define i32 @int_from_float(float %x) {
        \\entry:
        \\  %int = fptosi float %x to i32
        \\  ret i32 %int
        \\}
        \\
        \\define float @float_from_int(i32 %x) {
        \\entry:
        \\  %float = sitofp i32 %x to float
        \\  ret float %float
        \\}
        \\
        \\define double @double_from_unsigned(i32 %x) {
        \\entry:
        \\  %double = uitofp i32 %x to double
        \\  ret double %double
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items) |function| {
        var machine = try codegen.x86_64.lowerFunction(
            std.testing.allocator,
            module.target_triple.?,
            function,
        );
        defer machine.deinit(std.testing.allocator);
        try std.testing.expect(machine.instructions.items.len > 0);
        try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    }
}

test "x86_64 codegen routes smin intrinsic call through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @llvm.smin.i32(i32, i32)
        \\
        \\define i32 @any_signed_min(i32 %a, i32 %b) {
        \\entry:
        \\  %r = tail call i32 @llvm.smin.i32(i32 %a, i32 %b)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes signed-min select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_signed_min_select(i32 %a, i32 %b) {
        \\entry:
        \\  %lt = icmp slt i32 %a, %b
        \\  %r = select i1 %lt, i32 %a, i32 %b
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes nested i8 error select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @generic_error_select(i8 %tag) {
        \\entry:
        \\  %is_low = icmp eq i8 %tag, 1
        \\  %is_zero = icmp eq i8 %tag, 0
        \\  %error_value = select i1 %is_low, i32 -1, i32 -2
        \\  %result = select i1 %is_zero, i32 0, i32 %error_value
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes nested i8 i64 classifier select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @generic_i64_classifier(i8 %tag) {
        \\entry:
        \\  %is_low = icmp eq i8 %tag, 1
        \\  %is_zero = icmp eq i8 %tag, 0
        \\  %error_value = select i1 %is_low, i64 1, i64 2
        \\  %result = select i1 %is_zero, i64 0, i64 %error_value
        \\  ret i64 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes void global store through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@hidden = global i32 0
        \\
        \\define void @store_hidden(i32 %value) {
        \\entry:
        \\  store i32 %value, ptr @hidden
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes boolean branch-mix select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @generic_branch_mix(i32 %a, i32 %b, i1 %flag) {
        \\entry:
        \\  %neg = sub i32 0, %b
        \\  %delta = select i1 %flag, i32 %b, i32 %neg
        \\  %result = add i32 %a, %delta
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes constant i8 switch through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @generic_dense_switch(i8 %value) {
        \\entry:
        \\  switch i8 %value, label %default [
        \\    i8 0, label %case0
        \\    i8 1, label %case1
        \\    i8 2, label %case2
        \\  ]
        \\case0:
        \\  ret i32 11
        \\case1:
        \\  ret i32 13
        \\case2:
        \\  ret i32 17
        \\default:
        \\  ret i32 23
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes single-block fp binary through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @float_mul(double %a, double %b) {
        \\entry:
        \\  %product = fmul double %a, %b
        \\  ret double %product
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes single-block scalar select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @expanded_optional_branch(i32 %tag, i32 %payload) {
        \\entry:
        \\  %is_null = icmp eq i32 %tag, 0
        \\  %result = select i1 %is_null, i32 -5, i32 %payload
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);

    const expected =
        "\t.text\n" ++
        "\t.globl expanded_optional_branch\n" ++
        "expanded_optional_branch:\n" ++
        "\ttestl %edi, %edi\n" ++
        "\tje .Lexpanded_optional_branch_generic_cfg_select_true\n" ++
        "\tmovl %esi, %eax\n" ++
        "\tjmp .Lexpanded_optional_branch_generic_cfg_select_end\n" ++
        ".Lexpanded_optional_branch_generic_cfg_select_true:\n" ++
        "\tmovl $-5, %eax\n" ++
        ".Lexpanded_optional_branch_generic_cfg_select_end:\n" ++
        "\tretq\n";
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "x86_64 codegen rejects unsupported scalar select predicate explicitly" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @unsupported_select(i32 %a, i32 %b) {
        \\entry:
        \\  %is_le = icmp sle i32 %a, %b
        \\  %result = select i1 %is_le, i32 %a, i32 %b
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenInstruction,
        codegen.x86_64.lowerFunction(
            std.testing.allocator,
            module.target_triple.?,
            module.functions.items[0],
        ),
    );
}

test "x86_64 codegen routes global i32 load store reload through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@counter = global i32 3
        \\
        \\define i32 @update_global(i32 %arg0) {
        \\entry:
        \\  %loaded = load i32, ptr @counter
        \\  %next = add i32 %loaded, %arg0
        \\  store i32 %next, ptr @counter
        \\  %reloaded = load i32, ptr @counter
        \\  ret i32 %reloaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes pointer load branch through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @pointer_load_branch(i32 %flag, ptr %left, ptr %right) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %left_value = load i32, ptr %left
        \\  br label %merge
        \\else:
        \\  %right_value = load i32, ptr %right
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %left_value, %then ], [ %right_value, %else ]
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes branch phi immediate add through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @branch_phi_add(i32 %flag, ptr %payload) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %loaded = load i32, ptr %payload
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %loaded, %then ], [ -12, %else ]
        \\  %biased = add i32 %result, 1
        \\  ret i32 %biased
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes store branch load after store through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @store_branch_reload(i32 %flag, ptr %out, i32 %left, i32 %right) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  store i32 %left, ptr %out
        \\  br label %merge
        \\else:
        \\  store i32 %right, ptr %out
        \\  br label %merge
        \\merge:
        \\  %loaded = load i32, ptr %out
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes direct-call branch merge through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i32 @plus(i32)
        \\declare i32 @minus(i32)
        \\
        \\define i32 @call_branch_merge(i32 %flag, i32 %value) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %a = call fastcc i32 @plus(i32 %value)
        \\  br label %merge
        \\else:
        \\  %b = call i32 @minus(i32 %value)
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %a, %then ], [ %b, %else ]
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes pointer select load through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @pointer_select_load(i32 %flag, ptr %left, ptr %right) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  %chosen = select i1 %cond, ptr %left, ptr %right
        \\  %loaded = load i32, ptr %chosen
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes conditional slice accumulation loop through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @conditional_slice_sum(ptr %values, i64 %len, i32 %limit) {
        \\entry:
        \\  %is_empty = icmp eq i64 %len, 0
        \\  br i1 %is_empty, label %zero, label %loop
        \\loop:
        \\  ret i32 0
        \\zero:
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes alloca pointer struct field loads through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @field_a(ptr %pair) {
        \\entry:
        \\  %slot = alloca ptr
        \\  store ptr %pair, ptr %slot
        \\  %loaded_ptr = load ptr, ptr %slot
        \\  %loaded = load i32, ptr %loaded_ptr
        \\  ret i32 %loaded
        \\}
        \\
        \\define i32 @field_b(ptr %pair) {
        \\entry:
        \\  %slot = alloca ptr
        \\  store ptr %pair, ptr %slot
        \\  %loaded_ptr = load ptr, ptr %slot
        \\  %field_ptr = getelementptr i8, ptr %loaded_ptr, i64 4
        \\  %loaded = load i32, ptr %field_ptr
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items) |function| {
        var machine = try codegen.x86_64.lowerFunction(
            std.testing.allocator,
            module.target_triple.?,
            function,
        );
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    }
}

test "x86_64 codegen routes struct field branch update through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @branch_update(i32 %flag, ptr %pair) {
        \\entry:
        \\  %slot = alloca ptr
        \\  store ptr %pair, ptr %slot
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %then_ptr = load ptr, ptr %slot
        \\  %then_old = load i32, ptr %then_ptr
        \\  %then_new = add i32 %then_old, 5
        \\  store i32 %then_new, ptr %then_ptr
        \\  br label %merge
        \\else:
        \\  %else_ptr = load ptr, ptr %slot
        \\  %else_old = load i32, ptr %else_ptr
        \\  %else_new = add i32 %else_old, 7
        \\  store i32 %else_new, ptr %else_ptr
        \\  br label %merge
        \\merge:
        \\  %ret_ptr = load ptr, ptr %slot
        \\  %ret_value = load i32, ptr %ret_ptr
        \\  ret i32 %ret_value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen rejects unsupported aggregate field offset from generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @field_c(ptr %pair) {
        \\entry:
        \\  %slot = alloca ptr
        \\  store ptr %pair, ptr %slot
        \\  %loaded_ptr = load ptr, ptr %slot
        \\  %field_ptr = getelementptr i8, ptr %loaded_ptr, i64 8
        \\  %loaded = load i32, ptr %field_ptr
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    if (codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    )) |machine| {
        var owned = machine;
        defer owned.deinit(std.testing.allocator);
        try std.testing.expectEqual(codegen.x86_64.CodegenPath.structural_matcher, owned.codegen_path);
    } else |err| switch (err) {
        error.UnsupportedCodegenInstruction, error.UnsupportedCodegenValue => {},
        else => return err,
    }
}

test "x86_64 codegen routes single-block volatile roundtrip through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @volatile_roundtrip(ptr %ptr, i32 %value) {
        \\entry:
        \\  store volatile i32 %value, ptr %ptr
        \\  %loaded = load volatile i32, ptr %ptr
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes packed bit scalar helpers through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i8 @replace_low(i8 %a, i8 %b) {
        \\entry:
        \\  %high = and i8 %a, -8
        \\  %low = and i8 %b, 7
        \\  %result = or i8 %high, %low
        \\  ret i8 %result
        \\}
        \\
        \\define i1 @read_flag(i8 %a) {
        \\entry:
        \\  %flag = icmp slt i8 %a, 0
        \\  ret i1 %flag
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items) |function| {
        var machine = try codegen.x86_64.lowerFunction(
            std.testing.allocator,
            module.target_triple.?,
            function,
        );
        defer machine.deinit(std.testing.allocator);
        try std.testing.expect(machine.instructions.items.len > 0);
        try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    }
}

test "x86_64 codegen keeps multi-block volatile memory cfg out of generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @volatile_memory(i32 %flag, ptr %ptr) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %loaded = load volatile i32, ptr %ptr
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %loaded, %then ], [ 0, %else ]
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenControlFlow,
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}

test "x86_64 machine verifier checks call stack alignment and frame balance" {
    var misaligned = codegen.x86_64.MachineFunction.init("bad_call", .{ .int = 32 });
    defer misaligned.deinit(std.testing.allocator);
    try misaligned.instructions.append(std.testing.allocator, .{ .direct_call = .{
        .symbol = "callee",
        .ret_ty = .{ .int = 32 },
    } });
    try misaligned.instructions.append(std.testing.allocator, .ret);
    try std.testing.expectError(error.MisalignedStackBeforeCall, codegen.x86_64.verifyFunction(misaligned));

    var unbalanced = codegen.x86_64.MachineFunction.init("bad_frame", .{ .int = 32 });
    defer unbalanced.deinit(std.testing.allocator);
    try unbalanced.instructions.append(std.testing.allocator, .sub_rsp_8);
    try unbalanced.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 1 });
    try unbalanced.instructions.append(std.testing.allocator, .ret);
    try std.testing.expectError(error.UnbalancedStackFrame, codegen.x86_64.verifyFunction(unbalanced));
}

test "instcombine and dce remove identity arithmetic" {
    const input =
        \\define i32 @add_mul(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 0
        \\  %y = mul i32 %x, 1
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @add_mul(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "constant folding rewrites return value" {
    const input =
        \\define i32 @constant() {
        \\entry:
        \\  %x = add i32 1, 2
        \\  %y = mul i32 %x, 4
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @constant() {
        \\entry:
        \\  ret i32 12
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "dce updates use counts while removing instruction chains" {
    const input =
        \\define i32 @chain(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %y = mul i32 %x, 2
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @chain(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "sroa preserves volatile aggregate field accesses during scalarization" {
    const input =
        \\define i32 @sroa_struct_volatile_reject(i32 %a) {
        \\entry:
        \\  %agg = alloca { i32, i32 }
        \\  %p0 = getelementptr { i32, i32 }, ptr %agg, i32 0, i32 0
        \\  store volatile i32 %a, ptr %p0
        \\  %x = load i32, ptr %p0
        \\  ret i32 %x
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(sroa.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @sroa_struct_volatile_reject(i32 %a) {
        \\entry:
        \\  %agg.sroa.0 = alloca i32
        \\  store volatile i32 %a, ptr %agg.sroa.0
        \\  %agg.sroa.0.0.agg.sroa.0.0.x = load i32, ptr %agg.sroa.0
        \\  ret i32 %agg.sroa.0.0.agg.sroa.0.0.x
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "normalization preserves canonical LLVM-compatible fixture output" {
    const input = @embedFile("testdata/instcombine.ll");
    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "instcombine dce output matches golden file" {
    const input = @embedFile("testdata/instcombine.ll");
    const expected = @embedFile("testdata/instcombine_dce.ll");

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const normalized_actual = try normalize.llvmCompatibleIr(std.testing.allocator, output.writer.buffered());
    defer std.testing.allocator.free(normalized_actual);

    const normalized_expected = try normalize.llvmCompatibleIr(std.testing.allocator, expected);
    defer std.testing.allocator.free(normalized_expected);

    try std.testing.expectEqualStrings(normalized_expected, normalized_actual);
}

test "parser normalizes multiple functions and branch terminators" {
    const input =
        \\define i32 @branch(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  br label %exit
        \\else:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
        \\define i32 @second(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes unreachable terminator" {
    const input =
        \\define i32 @trap() {
        \\entry:
        \\  unreachable
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes icmp instructions" {
    const input =
        \\define i1 @cmp(i32 %a) {
        \\entry:
        \\  %c = icmp eq i32 %a, 0
        \\  ret i1 %c
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes select instructions" {
    const input =
        \\define i32 @choose(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  %v = select i1 %cond, i32 %a, i32 %b
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser preserves scalar casts div rem flags and freeze" {
    const input =
        \\define i32 @scalar_surface(i64 %wide, i8 %small, i32 %a, i32 %b) {
        \\entry:
        \\  %t = trunc i64 %wide to i32
        \\  %z = zext i8 %small to i32
        \\  %s = sext i8 %small to i32
        \\  %d = udiv exact i32 %a, 3
        \\  %r = srem i32 %b, 5
        \\  %sum0 = add nsw i32 %t, %z
        \\  %sum1 = add nuw i32 %sum0, %s
        \\  %sum2 = add i32 %sum1, %d
        \\  %sum3 = add i32 %sum2, %r
        \\  %sum4 = or disjoint i32 %sum3, 1
        \\  %f = freeze i32 %sum4
        \\  ret i32 %f
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser accepts array types and GEP prefixes from Zig aggregate IR" {
    const input =
        \\define i32 @array_gep(ptr %p, i64 %i) {
        \\entry:
        \\  %q = getelementptr inbounds [4 x i8], ptr %p, i64 %i
        \\  %r = getelementptr inbounds nuw i8, ptr %q, i64 4
        \\  %v = load i32, ptr %r, align 4
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const block = module.functions.items[0].blocks.items[0];
    try std.testing.expectEqualStrings("[4 x i8]", block.instructions.items[0].kind.gep.source_ty.aggregate);
    try std.testing.expectEqual(ir.Type{ .int = 8 }, block.instructions.items[1].kind.gep.source_ty);
}

test "parser accepts nested constant expression GEP pointer operands" {
    const input =
        \\@table = private unnamed_addr constant [4096 x i8] zeroinitializer, align 1
        \\
        \\define ptr @nested_gep(i64 %i) {
        \\entry:
        \\  %p = getelementptr inbounds nuw [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @table, i64 1024), i64 %i
        \\  ret ptr %p
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const gep = module.functions.items[0].blocks.items[0].instructions.items[0].kind.gep;
    try std.testing.expectEqualStrings("getelementptr inbounds nuw (i8, ptr @table, i64 1024)", gep.ptr.constant_expr);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\@table = private unnamed_addr constant [4096 x i8] zeroinitializer, align 1
        \\
        \\define ptr @nested_gep(i64 %i) {
        \\entry:
        \\  %p = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @table, i64 1024), i64 %i
        \\  ret ptr %p
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "parser rejects non-pointer typed nested constant expression GEP pointer operands" {
    const input =
        \\@table = private unnamed_addr constant [4096 x i8] zeroinitializer, align 1
        \\
        \\define ptr @bad_gep(i64 %i) {
        \\entry:
        \\  %p = getelementptr i8, i64 getelementptr (i8, ptr @table, i64 1), i64 %i
        \\  ret ptr %p
        \\}
        \\
    ;

    try std.testing.expectError(error.ExpectedPointerType, ir.Module.parse(std.testing.allocator, input));
}

test "instcombine preserves non-neutral flagged arithmetic and division" {
    const input =
        \\define i32 @conservative(i32 %a) {
        \\entry:
        \\  %x = add nsw i32 %a, 1
        \\  %y = udiv exact i32 %x, 2
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace.deinit();

    _ = try pm.run(&module, &context, &trace.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "instcombine folds safe division remainder and freeze constants" {
    const input =
        \\define i32 @safe_scalar(i32 %a) {
        \\entry:
        \\  %d = udiv i32 %a, 1
        \\  %r = srem i32 %d, 1
        \\  %f = freeze i32 42
        \\  %sum0 = add i32 %r, %f
        \\  %sum1 = add i32 %sum0, %d
        \\  ret i32 %sum1
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @safe_scalar(i32 %a) {
        \\entry:
        \\  %sum1 = add i32 %a, 42
        \\  ret i32 %sum1
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "instcombine preserves unsafe division folds" {
    const input =
        \\define i32 @unsafe_division() {
        \\entry:
        \\  %x = udiv i32 4, 0
        \\  %y = sdiv i32 -2147483648, -1
        \\  %z = udiv exact i32 5, 2
        \\  %sum0 = add i32 %x, %y
        \\  %sum1 = add i32 %sum0, %z
        \\  ret i32 %sum1
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace.deinit();

    _ = try pm.run(&module, &context, &trace.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "instcombine folds constant icmp" {
    const input =
        \\define i1 @cmp() {
        \\entry:
        \\  %c = icmp ne i32 1, 1
        \\  ret i1 %c
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i1 @cmp() {
        \\entry:
        \\  ret i1 0
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "instcombine folds simple select instructions" {
    const input =
        \\define i32 @select_fold(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  %x = select i1 1, i32 %a, i32 %b
        \\  %y = select i1 %cond, i32 %x, i32 %x
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @select_fold(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "parser normalizes phi instructions" {
    const input =
        \\define i32 @select(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %then ], [ %b, %else ]
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes memory instructions" {
    const input =
        \\define i32 @memory(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser prints load and store memory attributes" {
    const input =
        \\define i32 @memory_attrs(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store volatile i32 %a, ptr %slot, align 4
        \\  %v = load volatile i32, ptr %slot, align 4
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves load from constant-expression gep pointer" {
    const input =
        \\@global = internal global [8 x i8] c"abcdefgh", align 1
        \\
        \\define i8 @load_gep_constexpr() {
        \\entry:
        \\  %v = load i8, ptr getelementptr inbounds nuw (i8, ptr @global, i64 2), align 1
        \\  ret i8 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves atomic memory through constant-expression gep pointer" {
    const input =
        \\@global = internal global [8 x i8] zeroinitializer, align 4
        \\
        \\define i32 @atomic_gep_constexpr(i32 %value) {
        \\entry:
        \\  store atomic i32 %value, ptr getelementptr inbounds nuw (i8, ptr @global, i64 4) unordered, align 4
        \\  %v = load atomic i32, ptr getelementptr inbounds nuw (i8, ptr @global, i64 4) unordered, align 4
        \\  ret i32 %v
        \\}
        \\
    ;
    const expected =
        \\@global = internal global [8 x i8] zeroinitializer, align 4
        \\
        \\define i32 @atomic_gep_constexpr(i32 %value) {
        \\entry:
        \\  store atomic i32 %value, ptr getelementptr inbounds nuw (i8, ptr @global, i64 4) unordered, align 4
        \\  %v = load atomic i32, ptr getelementptr inbounds nuw (i8, ptr @global, i64 4) unordered, align 4
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "parser accepts narrow atomic load and store spelling as barriers" {
    const input =
        \\define i32 @memory_atomic(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store atomic i32 %a, ptr %slot release, align 4
        \\  %v = load atomic i32, ptr %slot acquire, align 4
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves known thread local models and rejects unknown TLS models" {
    const input =
        \\@tls = internal thread_local(localexec) unnamed_addr global i32 1, align 4
        \\
        \\define i32 @read_tls_model() {
        \\entry:
        \\  %v = load i32, ptr @tls, align 4
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());

    const invalid =
        \\@tls = internal thread_local(unsupported) global i32 1
        \\
        \\define i32 @read_bad_tls_model() {
        \\entry:
        \\  %v = load i32, ptr @tls, align 4
        \\  ret i32 %v
        \\}
        \\
    ;
    var invalid_module = try ir.Module.parse(std.testing.allocator, invalid);
    defer invalid_module.deinit();
    try std.testing.expectError(error.UnsupportedGlobalVariable, invalid_module.verify());
}

test "parser preserves atomicrmw cmpxchg and fence barriers" {
    const input =
        \\define i32 @memory_atomicrmw(ptr %p) {
        \\entry:
        \\  %v = atomicrmw add ptr %p, i32 1 monotonic
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(module.functions.items[0].blocks.items[0].instructions.items[0]));
    try std.testing.expectEqual(memory_effect.BarrierKind.atomic, memory_effect.barrierKind(module.functions.items[0].blocks.items[0].instructions.items[0]));

    const cmpxchg =
        \\define i32 @memory_cmpxchg(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %v = cmpxchg ptr %p, i32 %old, i32 %new monotonic monotonic
        \\  ret i32 %old
        \\}
        \\
    ;
    var cmpxchg_module = try ir.Module.parse(std.testing.allocator, cmpxchg);
    defer cmpxchg_module.deinit();
    try cmpxchg_module.verify();
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(cmpxchg_module.functions.items[0].blocks.items[0].instructions.items[0]));

    const cmpxchg_extractvalue =
        \\define i1 @cmpxchg_extractvalue(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %pair = cmpxchg ptr %p, i32 %old, i32 %new acquire monotonic
        \\  %success = extractvalue { i32, i1 } %pair, 1
        \\  ret i1 %success
        \\}
        \\
    ;
    var extractvalue_module = try ir.Module.parse(std.testing.allocator, cmpxchg_extractvalue);
    defer extractvalue_module.deinit();
    try extractvalue_module.verify();

    var extractvalue_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer extractvalue_output.deinit();
    try extractvalue_module.print(&extractvalue_output.writer);
    try std.testing.expectEqualStrings(cmpxchg_extractvalue, extractvalue_output.writer.buffered());

    const cmpxchg_i8_extractvalue =
        \\define i1 @cmpxchg_i8_extractvalue(ptr %p, i8 %old, i8 %new) {
        \\entry:
        \\  %pair = cmpxchg weak ptr %p, i8 %old, i8 %new seq_cst seq_cst
        \\  %success = extractvalue { i8, i1 } %pair, 1
        \\  ret i1 %success
        \\}
        \\
    ;
    var i8_extractvalue_module = try ir.Module.parse(std.testing.allocator, cmpxchg_i8_extractvalue);
    defer i8_extractvalue_module.deinit();
    try i8_extractvalue_module.verify();
    try std.testing.expect(i8_extractvalue_module.functions.items[0].blocks.items[0].instructions.items[0].resultType().?.eql(.{ .aggregate = "{ i8, i1 }" }));

    var i8_extractvalue_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer i8_extractvalue_output.deinit();
    try i8_extractvalue_module.print(&i8_extractvalue_output.writer);
    try std.testing.expectEqualStrings(cmpxchg_i8_extractvalue, i8_extractvalue_output.writer.buffered());

    const overflow_extractvalue =
        \\declare { i8, i1 } @llvm.umul.with.overflow.i8(i8, i8)
        \\
        \\define i1 @overflow_extractvalue(i8 %x) {
        \\entry:
        \\  %pair = call { i8, i1 } @llvm.umul.with.overflow.i8(i8 %x, i8 10)
        \\  %overflow = extractvalue { i8, i1 } %pair, 1
        \\  ret i1 %overflow
        \\}
        \\
    ;
    var overflow_module = try ir.Module.parse(std.testing.allocator, overflow_extractvalue);
    defer overflow_module.deinit();
    try overflow_module.verify();

    var overflow_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer overflow_output.deinit();
    try overflow_module.print(&overflow_output.writer);
    try std.testing.expectEqualStrings(overflow_extractvalue, overflow_output.writer.buffered());

    const insertvalue =
        \\define { ptr, i64 } @insert_aggregate(ptr %p) {
        \\entry:
        \\  %agg = insertvalue { ptr, i64 } poison, ptr %p, 0
        \\  ret { ptr, i64 } %agg
        \\}
        \\
    ;
    var insertvalue_module = try ir.Module.parse(std.testing.allocator, insertvalue);
    defer insertvalue_module.deinit();
    try insertvalue_module.verify();

    var insertvalue_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer insertvalue_output.deinit();
    try insertvalue_module.print(&insertvalue_output.writer);
    try std.testing.expectEqualStrings(insertvalue, insertvalue_output.writer.buffered());

    const bad_insertvalue =
        \\define { ptr, i64 } @bad_insert_aggregate(ptr %p) {
        \\entry:
        \\  %agg = insertvalue { ptr, i64 } poison, i64 1, 0
        \\  ret { ptr, i64 } %agg
        \\}
        \\
    ;
    try std.testing.expectError(error.TypeMismatch, ir.Module.parse(std.testing.allocator, bad_insertvalue));

    const aggregate_phi =
        \\define { ptr, i64 } @aggregate_phi(i1 %cond, { ptr, i64 } %value) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %result = phi { ptr, i64 } [ %value, %left ], [ { ptr inttoptr (i64 1 to ptr), i64 0 }, %right ]
        \\  ret { ptr, i64 } %result
        \\}
        \\
    ;
    var aggregate_phi_module = try ir.Module.parse(std.testing.allocator, aggregate_phi);
    defer aggregate_phi_module.deinit();
    try aggregate_phi_module.verify();

    var aggregate_phi_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aggregate_phi_output.deinit();
    try aggregate_phi_module.print(&aggregate_phi_output.writer);
    try std.testing.expectEqualStrings(aggregate_phi, aggregate_phi_output.writer.buffered());

    const bad_extractvalue =
        \\define i1 @bad_extractvalue(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %pair = cmpxchg ptr %p, i32 %old, i32 %new acquire monotonic
        \\  %success = extractvalue { i32, i1 } %pair, 2
        \\  ret i1 %success
        \\}
        \\
    ;
    try std.testing.expectError(error.TypeMismatch, ir.Module.parse(std.testing.allocator, bad_extractvalue));

    const fence =
        \\define void @memory_fence() {
        \\entry:
        \\  fence seq_cst
        \\  ret void
        \\}
        \\
    ;
    var fence_module = try ir.Module.parse(std.testing.allocator, fence);
    defer fence_module.deinit();
    try fence_module.verify();
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(fence_module.functions.items[0].blocks.items[0].instructions.items[0]));

    const source_backed_atomicrmw =
        \\source_filename = "atomics_inline_asm_debug"
        \\
        \\@atomics_inline_asm_debug.atomic_counter = private unnamed_addr global i32 0, align 4
        \\
        \\define i32 @atomics_inline_asm_debug.atomic_add(i32 %value) {
        \\entry:
        \\  %old = atomicrmw add ptr @atomics_inline_asm_debug.atomic_counter, i32 %value monotonic, align 4
        \\  ret i32 %old
        \\}
        \\
    ;
    var source_backed_module = try ir.Module.parse(std.testing.allocator, source_backed_atomicrmw);
    defer source_backed_module.deinit();
    try source_backed_module.verify();

    const constant_expr_atomic_pointer =
        \\@global = internal global [16 x i8] zeroinitializer, align 8
        \\
        \\define i32 @atomic_pointer_constexpr(i32 %old, i32 %new) {
        \\entry:
        \\  %rmw = atomicrmw xchg ptr getelementptr inbounds nuw (i8, ptr @global, i64 8), i32 %new release, align 4
        \\  %pair = cmpxchg ptr getelementptr inbounds nuw (i8, ptr @global, i64 8), i32 %old, i32 %new acquire monotonic, align 4
        \\  ret i32 %rmw
        \\}
        \\
    ;
    var constant_expr_module = try ir.Module.parse(std.testing.allocator, constant_expr_atomic_pointer);
    defer constant_expr_module.deinit();
    try constant_expr_module.verify();
}

test "parser preserves atomic syncscope on supported atomic operations" {
    const input =
        \\define i32 @memory_syncscope(i32 %a, ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  store atomic i32 %a, ptr %p syncscope("singlethread") release, align 4
        \\  %v = load atomic i32, ptr %p syncscope("singlethread") acquire, align 4
        \\  %rmw = atomicrmw add ptr %p, i32 %new syncscope("singlethread") monotonic, align 4
        \\  %pair = cmpxchg weak ptr %p, i32 %old, i32 %new syncscope("singlethread") acq_rel monotonic, align 4
        \\  fence syncscope("singlethread") seq_cst
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier accepts LLVM-shaped atomic type surfaces" {
    const input =
        \\define ptr @atomic_pointer_xchg(ptr %p) {
        \\entry:
        \\  %v = atomicrmw xchg ptr %p, ptr null monotonic
        \\  ret ptr %v
        \\}
        \\
        \\define float @atomic_float_load_store(ptr %p, float %value) {
        \\entry:
        \\  store atomic float %value, ptr %p release, align 4
        \\  %loaded = load atomic float, ptr %p acquire, align 4
        \\  ret float %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
}

test "verifier rejects invalid atomic ordering combinations" {
    const invalid_load =
        \\define i32 @bad_atomic_load(ptr %p) {
        \\entry:
        \\  %v = load atomic i32, ptr %p release, align 4
        \\  ret i32 %v
        \\}
        \\
    ;
    var load_module = try ir.Module.parse(std.testing.allocator, invalid_load);
    defer load_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, load_module.verify());

    const invalid_store =
        \\define void @bad_atomic_store(ptr %p) {
        \\entry:
        \\  store atomic i32 1, ptr %p acquire, align 4
        \\  ret void
        \\}
        \\
    ;
    var store_module = try ir.Module.parse(std.testing.allocator, invalid_store);
    defer store_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, store_module.verify());

    const invalid_fence =
        \\define void @bad_fence() {
        \\entry:
        \\  fence monotonic
        \\  ret void
        \\}
        \\
    ;
    var fence_module = try ir.Module.parse(std.testing.allocator, invalid_fence);
    defer fence_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, fence_module.verify());

    const invalid_cmpxchg =
        \\define void @bad_cmpxchg(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %pair = cmpxchg ptr %p, i32 %old, i32 %new acquire release
        \\  ret void
        \\}
        \\
    ;
    var cmpxchg_module = try ir.Module.parse(std.testing.allocator, invalid_cmpxchg);
    defer cmpxchg_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, cmpxchg_module.verify());
}

test "verifier rejects LLVM invalid atomic memory types" {
    const invalid_load_i1 =
        \\define i1 @bad_atomic_load_i1(ptr %p) {
        \\entry:
        \\  %v = load atomic i1, ptr %p acquire, align 1
        \\  ret i1 %v
        \\}
        \\
    ;
    var load_i1_module = try ir.Module.parse(std.testing.allocator, invalid_load_i1);
    defer load_i1_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, load_i1_module.verify());

    const invalid_store_i24 =
        \\define void @bad_atomic_store_i24(ptr %p) {
        \\entry:
        \\  store atomic i24 1, ptr %p release, align 4
        \\  ret void
        \\}
        \\
    ;
    var store_i24_module = try ir.Module.parse(std.testing.allocator, invalid_store_i24);
    defer store_i24_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, store_i24_module.verify());

    const invalid_rmw_add_ptr =
        \\define ptr @bad_atomicrmw_add_ptr(ptr %p) {
        \\entry:
        \\  %v = atomicrmw add ptr %p, ptr null monotonic
        \\  ret ptr %v
        \\}
        \\
    ;
    var rmw_add_ptr_module = try ir.Module.parse(std.testing.allocator, invalid_rmw_add_ptr);
    defer rmw_add_ptr_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, rmw_add_ptr_module.verify());

    const invalid_rmw_fadd_i32 =
        \\define i32 @bad_atomicrmw_fadd_i32(ptr %p, i32 %value) {
        \\entry:
        \\  %v = atomicrmw fadd ptr %p, i32 %value monotonic
        \\  ret i32 %v
        \\}
        \\
    ;
    var rmw_fadd_i32_module = try ir.Module.parse(std.testing.allocator, invalid_rmw_fadd_i32);
    defer rmw_fadd_i32_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, rmw_fadd_i32_module.verify());

    const invalid_cmpxchg_float =
        \\define void @bad_cmpxchg_float(ptr %p, float %old, float %new) {
        \\entry:
        \\  %pair = cmpxchg ptr %p, float %old, float %new monotonic monotonic
        \\  ret void
        \\}
        \\
    ;
    var cmpxchg_float_module = try ir.Module.parse(std.testing.allocator, invalid_cmpxchg_float);
    defer cmpxchg_float_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, cmpxchg_float_module.verify());
}

test "parser preserves inline asm calls as side-effecting barriers" {
    const input =
        \\define void @inline_asm_barrier() {
        \\entry:
        \\  call void asm sideeffect "", "~{memory}"()
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(call.inline_asm != null);
    try std.testing.expect(call.inline_asm.?.sideeffect);
    try std.testing.expect(call.inline_asm.?.has_memory_clobber);
    try std.testing.expect(call.inline_asm.?.may_load);
    try std.testing.expect(call.inline_asm.?.may_store);
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(module.functions.items[0].blocks.items[0].instructions.items[0]));
    try std.testing.expectEqual(memory_effect.BarrierKind.inline_asm, memory_effect.barrierKind(module.functions.items[0].blocks.items[0].instructions.items[0]));

    const source_backed_inline_asm =
        \\source_filename = "atomics_inline_asm_debug"
        \\
        \\define i32 @atomics_inline_asm_debug.inline_asm_barrier(i32 %value) {
        \\entry:
        \\  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"()
        \\  ret i32 %value
        \\}
        \\
    ;
    var source_backed_module = try ir.Module.parse(std.testing.allocator, source_backed_inline_asm);
    defer source_backed_module.deinit();
    try source_backed_module.verify();
    const source_backed_call = source_backed_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(source_backed_call.inline_asm != null);
    try std.testing.expect(source_backed_call.inline_asm.?.has_memory_clobber);
    try std.testing.expect(source_backed_call.inline_asm.?.may_load);
    try std.testing.expect(source_backed_call.inline_asm.?.may_store);
}

test "parser classifies inline asm side effects separately from memory constraints" {
    const input =
        \\define void @inline_asm_effects(ptr %p) {
        \\entry:
        \\  call void asm sideeffect "", "~{dirflag},~{fpsr},~{flags}"()
        \\  call void asm sideeffect "", "m"(ptr %p)
        \\  call void asm sideeffect "", "=*m"(ptr %p)
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const block = module.functions.items[0].blocks.items[0];
    const sideeffect_only = block.instructions.items[0].kind.call.inline_asm.?;
    try std.testing.expect(sideeffect_only.sideeffect);
    try std.testing.expect(!sideeffect_only.has_memory_clobber);
    try std.testing.expect(!sideeffect_only.may_load);
    try std.testing.expect(!sideeffect_only.may_store);
    try std.testing.expectEqual(memory_effect.Effect.side_effect, memory_effect.classify(block.instructions.items[0]));
    try std.testing.expectEqual(memory_effect.BarrierKind.none, memory_effect.barrierKind(block.instructions.items[0]));

    const memory_input = block.instructions.items[1].kind.call.inline_asm.?;
    try std.testing.expect(memory_input.may_load);
    try std.testing.expect(!memory_input.may_store);
    try std.testing.expectEqual(memory_effect.Effect.readonly_side_effect, memory_effect.classify(block.instructions.items[1]));
    try std.testing.expectEqual(memory_effect.BarrierKind.inline_asm, memory_effect.barrierKind(block.instructions.items[1]));

    const memory_output = block.instructions.items[2].kind.call.inline_asm.?;
    try std.testing.expect(!memory_output.may_load);
    try std.testing.expect(memory_output.may_store);
    try std.testing.expectEqual(memory_effect.Effect.memory_write, memory_effect.classify(block.instructions.items[2]));
    try std.testing.expectEqual(memory_effect.BarrierKind.inline_asm, memory_effect.barrierKind(block.instructions.items[2]));
}

test "parser preserves module-level asm records opaquely" {
    const input =
        \\source_filename = "behavior_asm"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\module asm ".globl this_is_my_alias;"
        \\module asm ".type this_is_my_alias, @function;"
        \\module asm ".set this_is_my_alias, derp;"
        \\
        \\define i32 @derp() {
        \\entry:
        \\  ret i32 1
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(@as(usize, 3), module.module_asm.items.len);
    try std.testing.expectEqualStrings("module asm \".globl this_is_my_alias;\"", module.module_asm.items[0]);
    try std.testing.expectEqualStrings("module asm \".type this_is_my_alias, @function;\"", module.module_asm.items[1]);
    try std.testing.expectEqualStrings("module asm \".set this_is_my_alias, derp;\"", module.module_asm.items[2]);
}

test "parser preserves named type definitions opaquely" {
    const input =
        \\source_filename = "named_types"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\%os.linux.rlimit = type { i64, i64 }
        \\%os.linux.stack_t__struct_3163 = type { ptr, i32, [4 x i8], i64 }
        \\
        \\define void @use_named_type(ptr %p) {
        \\entry:
        \\  %slot = alloca %os.linux.rlimit, align 8
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 2), module.named_types.items.len);
    try std.testing.expectEqualStrings("os.linux.rlimit", module.named_types.items[0].name);
    try std.testing.expectEqualStrings("{ i64, i64 }", module.named_types.items[0].body);
    try std.testing.expectEqualStrings("%os.linux.rlimit = type { i64, i64 }", module.named_types.items[0].raw);
    try std.testing.expectEqualStrings("os.linux.stack_t__struct_3163", module.named_types.items[1].name);
    try std.testing.expectEqualStrings("{ ptr, i32, [4 x i8], i64 }", module.named_types.items[1].body);
}

test "parser preserves quoted named type definitions with equals in names" {
    const input =
        \\%"hash_map.Custom(.{ .thread_safe = true })" = type { ptr, i32, i32 }
        \\@quoted_type_global = private unnamed_addr constant %"hash_map.Custom(.{ .thread_safe = true })" zeroinitializer, align 8
        \\
        \\define void @use_quoted_named_type(ptr %p) {
        \\entry:
        \\  %slot = alloca %"hash_map.Custom(.{ .thread_safe = true })", align 8
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 1), module.named_types.items.len);
    try std.testing.expectEqualStrings("\"hash_map.Custom(.{ .thread_safe = true })\"", module.named_types.items[0].name);
    try std.testing.expectEqualStrings("{ ptr, i32, i32 }", module.named_types.items[0].body);
    try std.testing.expectEqual(@as(usize, 1), module.globals.items.len);
    try std.testing.expectEqualStrings("%\"hash_map.Custom(.{ .thread_safe = true })\"", module.globals.items[0].ty.aggregate);
}

test "verifier rejects duplicate named type definitions" {
    const input =
        \\%os.linux.rlimit = type { i64, i64 }
        \\%os.linux.rlimit = type { ptr, i64 }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expectError(error.DuplicateNamedTypeDefinition, module.verify());
}

test "parser preserves source-backed global variable forms" {
    const input =
        \\source_filename = "global_variables"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\%os.linux.rlimit = type { i64, i64 }
        \\%os.linux.stack_t__struct_3163 = type { ptr, i32, [4 x i8], i64 }
        \\
        \\@__init_array_start = extern_weak constant ptr, align 8
        \\@__init_array_end = extern_weak constant ptr, align 8
        \\@os.linux.tls.area_desc.0 = internal unnamed_addr global i64 undef, align 8
        \\@os.linux.tls.area_desc.4 = internal unnamed_addr global ptr undef, align 8
        \\@os.linux.tls.main_thread_area_buffer = private unnamed_addr global [4096 x i8] undef, align 4096
        \\@__anon_3154 = private unnamed_addr constant [13 x i8] c"hello world!\00", align 1
        \\@Thread.maybeAttachSignalStack.global.signal_stack = private thread_local unnamed_addr global [262144 x i8] undef, align 1
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 7), module.globals.items.len);
    try std.testing.expectEqual(ir.FunctionLinkage.extern_weak, module.globals.items[0].linkage);
    try std.testing.expect(module.globals.items[0].initializer == .none);
    try std.testing.expectEqual(ir.Value.undef, module.globals.items[4].initializer.scalar);
    try std.testing.expectEqualStrings("c\"hello world!\\00\"", module.globals.items[5].initializer.c_string);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier rejects local initializerless globals" {
    const input =
        \\@bad = internal constant ptr, align 8
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expectError(error.UnsupportedGlobalVariable, module.verify());
}

test "parser rejects unsupported inline asm forms explicitly" {
    const missing_sideeffect =
        \\define void @inline_asm_barrier() {
        \\entry:
        \\  call void asm "", "~{memory}"()
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, missing_sideeffect);
    defer module.deinit();
    try std.testing.expectError(error.UnsupportedInlineAsm, module.verify());
}

test "parser normalizes getelementptr instructions" {
    const input =
        \\define i32 @gep(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  %p = getelementptr i32, ptr %slot, i32 0
        \\  store i32 %a, ptr %p
        \\  %v = load i32, ptr %p
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes undef values" {
    const input =
        \\define i32 @undef_value(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ undef, %left ], [ %a, %right ]
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "normalization strips LLVM comparison noise" {
    const input =
        \\; ModuleID = 'test/opt/inputs/memory_dce.ll'
        \\source_filename = "test/opt/inputs/memory_dce.ll"
        \\
        \\define i32 @memory_dce(i32 %a) {
        \\entry:
        \\  %slot = alloca i32, align 4
        \\  store i32 %a, ptr %slot, align 4
        \\  ret i32 %a
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    const expected =
        \\define i32 @memory_dce(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, normalized);
}

test "dce removes unused loads but keeps stores" {
    const input =
        \\define i32 @memory_dce(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  %dead = load i32, ptr %slot
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @memory_dce(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "dse preserves stores across unknown memory barriers" {
    const input =
        \\declare void @touch()
        \\
        \\define i32 @barriers(i32 %a, i32 %b, ptr %p) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  call void @touch()
        \\  store i32 %b, ptr %slot
        \\  store volatile i32 %a, ptr %slot
        \\  store i32 %b, ptr %p
        \\  store i32 %a, ptr %slot
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(dse.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "alias analysis classifies stack slots" {
    const input =
        \\define i32 @alias(ptr %arg) {
        \\entry:
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  store i32 1, ptr %left
        \\  store i32 2, ptr %right
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    try std.testing.expectEqual(
        alias.AliasResult.must_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "left" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.no_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "right" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.no_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "arg" }),
    );
}

test "alias analysis classifies gep-derived stack slots" {
    const input =
        \\define i32 @gep_alias(i32 %index) {
        \\entry:
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  %left0 = getelementptr i32, ptr %left, i32 0
        \\  %left1 = getelementptr i32, ptr %left, i32 1
        \\  %left_unknown = getelementptr i32, ptr %left, i32 %index
        \\  %right0 = getelementptr i32, ptr %right, i32 0
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    try std.testing.expectEqual(
        alias.AliasResult.must_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "left0" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.no_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "left1" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.may_alias,
        alias.alias(function, .{ .named = "left0" }, .{ .named = "left_unknown" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.no_alias,
        alias.alias(function, .{ .named = "left0" }, .{ .named = "right0" }),
    );

    const left1 = memory_location.forPointer(function, .{ .named = "left1" }) orelse return error.TestExpectedMemoryLocation;
    try std.testing.expectEqual(@as(i128, 4), left1.offset.?);
    try std.testing.expectEqual(@as(u64, 4), left1.size.?);
}

test "alias analysis classifies source-backed parameter gep offsets" {
    const input =
        \\define i32 @aggregate_param(ptr %p) {
        \\entry:
        \\  %field = getelementptr i8, ptr %p, i64 4
        \\  %a = load i32, ptr %p, align 4
        \\  %b = load i32, ptr %field, align 4
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    try std.testing.expectEqual(
        alias.AliasResult.may_alias,
        alias.alias(function, .{ .named = "p" }, .{ .named = "field" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.no_mod_ref,
        alias.modRefForAccess(function, function.blocks.items[0].instructions.items[2], .{ .named = "p" }, .{ .int = 32 }),
    );

    const field_location = memory_location.forPointer(function, .{ .named = "field" }) orelse return error.TestExpectedMemoryLocation;
    try std.testing.expectEqualStrings("p", field_location.root);
    try std.testing.expectEqual(@as(i128, 4), field_location.offset.?);
}

test "alias analysis classifies partial overlapping access ranges" {
    const input =
        \\define i32 @partial_alias(ptr %p) {
        \\entry:
        \\  %overlap = getelementptr i8, ptr %p, i64 2
        \\  %a = load i32, ptr %p, align 4
        \\  %b = load i32, ptr %overlap, align 1
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    try std.testing.expectEqual(
        alias.AliasResult.partial_alias,
        alias.accessAlias(function, .{ .named = "p" }, .{ .int = 32 }, .{ .named = "overlap" }, .{ .int = 32 }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.ref,
        alias.modRefForAccess(function, function.blocks.items[0].instructions.items[2], .{ .named = "p" }, .{ .int = 32 }),
    );
}

test "alias analysis classifies globals and aliases with module context" {
    const input =
        \\@global_a = internal global i32 0
        \\@global_b = internal global i32 0
        \\@alias_a = alias ptr, ptr @global_a
        \\
        \\define i32 @global_alias() {
        \\entry:
        \\  %v = load i32, ptr @global_a
        \\  store i32 %v, ptr @global_b
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    try std.testing.expectEqual(
        alias.AliasResult.must_alias,
        alias.aliasInModule(module, function, .{ .named = "global_a" }, .{ .named = "alias_a" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.no_alias,
        alias.aliasInModule(module, function, .{ .named = "global_a" }, .{ .named = "global_b" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.no_mod_ref,
        alias.modRefInModule(module, function, function.blocks.items[0].instructions.items[1], .{ .named = "global_a" }),
    );
}

test "memory effect and mod-ref classify memory instructions conservatively" {
    const input =
        \\define i32 @memory_effects(i32 %a, ptr %arg) {
        \\entry:
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  %left1 = getelementptr i32, ptr %left, i32 1
        \\  %pure = add i32 %a, 1
        \\  %load = load i32, ptr %left
        \\  %volatile_load = load volatile i32, ptr %arg
        \\  store i32 %pure, ptr %right
        \\  store atomic i32 %pure, ptr %arg release, align 4
        \\  ret i32 %load
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];
    const block = function.blocks.items[0];

    try std.testing.expectEqual(memory_effect.Effect.none, memory_effect.classify(block.instructions.items[3]));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, memory_effect.classify(block.instructions.items[4]));
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(block.instructions.items[5]));
    try std.testing.expectEqual(memory_effect.Effect.memory_write, memory_effect.classify(block.instructions.items[6]));
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(block.instructions.items[7]));
    try std.testing.expectEqual(memory_effect.BarrierKind.@"volatile", memory_effect.barrierKind(block.instructions.items[5]));
    try std.testing.expectEqual(memory_effect.BarrierKind.atomic, memory_effect.barrierKind(block.instructions.items[7]));
    try std.testing.expect(memory_effect.mayReadMemory(block.instructions.items[4]));
    try std.testing.expect(memory_effect.mayReadOrWriteMemory(block.instructions.items[7]));
    try std.testing.expect(!memory_effect.isSafeToDelete(block.instructions.items[7]));

    try std.testing.expectEqual(
        alias.ModRefInfo.no_mod_ref,
        alias.modRef(function, block.instructions.items[4], .{ .named = "right" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.no_mod_ref,
        alias.modRef(function, block.instructions.items[4], .{ .named = "left1" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.ref,
        alias.modRef(function, block.instructions.items[4], .{ .named = "left" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.no_mod_ref,
        alias.modRef(function, block.instructions.items[4], .{ .named = "arg" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.mod,
        alias.modRef(function, block.instructions.items[6], .{ .named = "right" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.unknown,
        alias.modRef(function, block.instructions.items[7], .{ .named = "arg" }),
    );
}

test "memory effect marks calls and trapping division conservatively" {
    const input =
        \\declare void @touch()
        \\
        \\define i32 @trap(i32 %a, i32 %b) {
        \\entry:
        \\  %q = sdiv i32 %a, %b
        \\  %safe = udiv i32 %a, 2
        \\  call void @touch()
        \\  ret i32 %q
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const block = module.functions.items[0].blocks.items[0];

    try std.testing.expect(memory_effect.mayTrap(block.instructions.items[0]));
    try std.testing.expect(!memory_effect.isSafeToSpeculativelyExecute(block.instructions.items[0]));
    try std.testing.expect(!memory_effect.mayTrap(block.instructions.items[1]));
    try std.testing.expect(memory_effect.mayThrow(block.instructions.items[2]));
    try std.testing.expect(!memory_effect.isSafeToDelete(block.instructions.items[2]));
}

test "memory ssa clobber helper covers accepted memory-dependence cases" {
    const input =
        \\declare void @unknown()
        \\declare void @readnone_call() readnone
        \\declare void @readonly_call() readonly
        \\
        \\define i32 @memory_ssa_clobber(ptr %p, ptr %q, i32 %v) {
        \\entry:
        \\  %l0 = load i32, ptr %p
        \\  %l1 = load i32, ptr %p
        \\  store i32 %v, ptr %p
        \\  %l2 = load i32, ptr %p
        \\  store i32 %v, ptr %q
        \\  %l3 = load i32, ptr %p
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  %left_load = load i32, ptr %left
        \\  store i32 %v, ptr %right
        \\  %left_load2 = load i32, ptr %left
        \\  call void @unknown()
        \\  %l4 = load i32, ptr %p
        \\  call void @readnone_call()
        \\  %l5 = load i32, ptr %p
        \\  call void @readonly_call()
        \\  %l6 = load i32, ptr %p
        \\  %volatile_load = load volatile i32, ptr %p
        \\  %l7 = load i32, ptr %p
        \\  %atomic_load = load atomic i32, ptr %p acquire, align 4
        \\  %l8 = load i32, ptr %p
        \\  ret i32 %l8
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var memory = try memory_ssa.MemorySSA.build(std.testing.allocator, module, function);
    defer memory.deinit();
    try std.testing.expect(memory.accesses.items.len >= 9);

    try std.testing.expect(!memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 0 }, .{ .block_index = 0, .instruction_index = 1 }, .{ .named = "p" }));
    try std.testing.expect(!memory.hasClobberBetween(.{ .block_index = 0, .instruction_index = 0 }, .{ .block_index = 0, .instruction_index = 1 }, .{ .named = "p" }));
    try std.testing.expect(memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 1 }, .{ .block_index = 0, .instruction_index = 3 }, .{ .named = "p" }));
    try std.testing.expect(memory.hasClobberBetween(.{ .block_index = 0, .instruction_index = 1 }, .{ .block_index = 0, .instruction_index = 3 }, .{ .named = "p" }));
    try std.testing.expect(memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 3 }, .{ .block_index = 0, .instruction_index = 5 }, .{ .named = "p" }));
    try std.testing.expect(!memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 8 }, .{ .block_index = 0, .instruction_index = 10 }, .{ .named = "left" }));
    try std.testing.expect(memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 10 }, .{ .block_index = 0, .instruction_index = 12 }, .{ .named = "p" }));
    try std.testing.expect(!memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 12 }, .{ .block_index = 0, .instruction_index = 14 }, .{ .named = "p" }));
    try std.testing.expect(!memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 14 }, .{ .block_index = 0, .instruction_index = 16 }, .{ .named = "p" }));
    try std.testing.expect(memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 16 }, .{ .block_index = 0, .instruction_index = 18 }, .{ .named = "p" }));
    try std.testing.expect(memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 18 }, .{ .block_index = 0, .instruction_index = 20 }, .{ .named = "p" }));
}

test "memory ssa records narrow phi facts at joins" {
    const input =
        \\define i32 @memory_join(i1 %cond, ptr %p, i32 %v) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  store i32 %v, ptr %p
        \\  br label %join
        \\right:
        \\  br label %join
        \\join:
        \\  %loaded = load i32, ptr %p
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var memory = try memory_ssa.MemorySSA.build(std.testing.allocator, module, function);
    defer memory.deinit();

    var saw_phi = false;
    for (memory.accesses.items) |access| {
        if (access.kind == .phi and access.block_index == 3) saw_phi = true;
    }
    try std.testing.expect(saw_phi);
    try std.testing.expect(memory.hasClobberBetween(.{ .block_index = 1, .instruction_index = 0 }, .{ .block_index = 3, .instruction_index = 0 }, .{ .named = "p" }));
}

test "memory ssa walker reports clobbering access or live-on-entry" {
    const input =
        \\define i32 @memory_walker(i32 %v) {
        \\entry:
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  %first = load i32, ptr %left
        \\  store i32 %v, ptr %right
        \\  %second = load i32, ptr %left
        \\  store i32 %v, ptr %left
        \\  %third = load i32, ptr %left
        \\  ret i32 %third
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var memory = try memory_ssa.MemorySSA.build(std.testing.allocator, module, function);
    defer memory.deinit();
    const walker = memory.getWalker();

    try std.testing.expectEqual(@as(usize, 5), memory.accesses.items.len);
    try std.testing.expectEqual(
        memory_ssa.ClobberResult.live_on_entry,
        walker.getClobberBetween(
            .{ .block_index = 0, .instruction_index = 2 },
            .{ .block_index = 0, .instruction_index = 4 },
            .{ .named = "left" },
            .{ .int = 32 },
        ),
    );

    const clobber = walker.getClobberBetween(
        .{ .block_index = 0, .instruction_index = 4 },
        .{ .block_index = 0, .instruction_index = 6 },
        .{ .named = "left" },
        .{ .int = 32 },
    );
    switch (clobber) {
        .live_on_entry => return error.ExpectedMemoryClobber,
        .access => |access| {
            try std.testing.expectEqual(memory_ssa.AccessKind.def, access.kind);
            try std.testing.expectEqual(@as(usize, 0), access.block_index);
            try std.testing.expectEqual(@as(?usize, 5), access.instruction_index);
        },
    }

    const third_access = memory.findAccessIndex(.{ .block_index = 0, .instruction_index = 6 }) orelse return error.ExpectedMemoryAccess;
    const clobber_for_use = walker.getClobberingMemoryAccessForAccess(third_access, .{ .named = "left" }, .{ .int = 32 });
    switch (clobber_for_use) {
        .live_on_entry => return error.ExpectedMemoryClobber,
        .access => |access| {
            try std.testing.expectEqual(memory_ssa.AccessKind.def, access.kind);
            try std.testing.expectEqual(@as(?usize, 5), access.instruction_index);
        },
    }
}

test "memory ssa walker reports memory phi as clobber" {
    const input =
        \\define i32 @memory_walker_phi(i1 %cond, ptr %p, i32 %v) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  store i32 %v, ptr %p
        \\  br label %join
        \\right:
        \\  br label %join
        \\join:
        \\  %loaded = load i32, ptr %p
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var memory = try memory_ssa.MemorySSA.build(std.testing.allocator, module, function);
    defer memory.deinit();
    const walker = memory.getWalker();

    const clobber = walker.getClobberingMemoryAccess(.{ .block_index = 3, .instruction_index = 0 }, .{ .named = "p" }, .{ .int = 32 });
    switch (clobber) {
        .live_on_entry => return error.ExpectedMemoryClobber,
        .access => |access| {
            try std.testing.expectEqual(memory_ssa.AccessKind.phi, access.kind);
            try std.testing.expectEqual(@as(usize, 3), access.block_index);
            try std.testing.expectEqual(@as(?usize, null), access.instruction_index);
        },
    }
}

test "memory ssa skips phis for pure predecessor diamonds" {
    const input =
        \\define i32 @memory_pure_diamond(i1 %cond, ptr %p) {
        \\entry:
        \\  %first = load i32, ptr %p
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %join
        \\right:
        \\  br label %join
        \\join:
        \\  %second = load i32, ptr %p
        \\  ret i32 %second
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var memory = try memory_ssa.MemorySSA.build(std.testing.allocator, module, function);
    defer memory.deinit();

    for (memory.accesses.items) |access| {
        try std.testing.expect(access.kind != .phi);
    }
    try std.testing.expect(!memory.hasClobberBetween(
        .{ .block_index = 0, .instruction_index = 0 },
        .{ .block_index = 3, .instruction_index = 0 },
        .{ .named = "p" },
    ));
}

test "memory ssa updater deletes accesses and dumps expectations" {
    const input =
        \\define i32 @memory_updater(ptr %p, i32 %a, i32 %b) {
        \\entry:
        \\  store i32 %a, ptr %p
        \\  store i32 %b, ptr %p
        \\  %loaded = load i32, ptr %p
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    var function = &module.functions.items[0];

    var memory = try memory_ssa.MemorySSA.build(std.testing.allocator, module, function.*);
    defer memory.deinit();
    try std.testing.expectEqual(@as(usize, 3), memory.accesses.items.len);
    try memory.verifyConsistent();

    function.blocks.items[0].instructions.items[0].removed = true;
    try std.testing.expect(memory.deleteAccess(0, 0));
    try memory.verifyConsistent();

    var dump: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer dump.deinit();
    try memory.dump(&dump.writer);
    try std.testing.expectEqualStrings(
        \\def block=0 inst=1 ptr=%p
        \\use block=0 inst=2 ptr=%p
        \\
    , dump.writer.buffered());
}

test "mem2reg promotes single-block stack slot" {
    const input =
        \\define i32 @promote(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @promote(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "mem2reg replaces uninitialized stack loads with undef" {
    const input =
        \\define i32 @promote_undef() {
        \\entry:
        \\  %slot = alloca i32
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @promote_undef() {
        \\entry:
        \\  ret i32 undef
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "mem2reg promotes if-else stack slot with phi" {
    const input =
        \\define i32 @promote_if(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  %slot = alloca i32
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  store i32 %a, ptr %slot
        \\  br label %merge
        \\right:
        \\  store i32 %b, ptr %slot
        \\  br label %merge
        \\merge:
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @promote_if(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %slot.0 = phi i32 [ %a, %left ], [ %b, %right ]
        \\  ret i32 %slot.0
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "mem2reg promotes loop-carried stack slot" {
    const input =
        \\define i32 @promote_loop(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  br label %loop
        \\loop:
        \\  %v = load i32, ptr %slot
        \\  %more = icmp ne i32 %v, 0
        \\  br i1 %more, label %body, label %exit
        \\body:
        \\  %next = sub i32 %v, 1
        \\  store i32 %next, ptr %slot
        \\  br label %loop
        \\exit:
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @promote_loop(i32 %a) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %slot.0 = phi i32 [ %a, %entry ], [ %next, %body ]
        \\  %more = icmp ne i32 %slot.0, 0
        \\  br i1 %more, label %body, label %exit
        \\body:
        \\  %next = sub i32 %slot.0, 1
        \\  br label %loop
        \\exit:
        \\  ret i32 %slot.0
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "mem2reg promotes multiple independent stack slots" {
    const input =
        \\define i32 @promote_two(i1 %cond, i32 %a, i32 %b, i32 %c, i32 %d) {
        \\entry:
        \\  %x = alloca i32
        \\  %y = alloca i32
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  store i32 %a, ptr %x
        \\  store i32 %b, ptr %y
        \\  br label %merge
        \\right:
        \\  store i32 %c, ptr %x
        \\  store i32 %d, ptr %y
        \\  br label %merge
        \\merge:
        \\  %vx = load i32, ptr %x
        \\  %vy = load i32, ptr %y
        \\  %sum = add i32 %vx, %vy
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @promote_two(i1 %cond, i32 %a, i32 %b, i32 %c, i32 %d) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %y.0 = phi i32 [ %b, %left ], [ %d, %right ]
        \\  %x.0 = phi i32 [ %a, %left ], [ %c, %right ]
        \\  %sum = add i32 %x.0, %y.0
        \\  ret i32 %sum
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "mem2reg rejects escaped stack slot" {
    const input =
        \\define ptr @escape() {
        \\entry:
        \\  %slot = alloca i32
        \\  ret ptr %slot
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "mem2reg rejects stores of the stack slot pointer" {
    const input =
        \\define i32 @store_slot(ptr %sink) {
        \\entry:
        \\  %slot = alloca i32
        \\  store ptr %slot, ptr %sink
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "mem2reg ignores non-entry allocas" {
    const input =
        \\define i32 @non_entry_alloca(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\else:
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "mem2reg rejects volatile alloca users" {
    const input =
        \\define i32 @volatile_alloca(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store volatile i32 %a, ptr %slot, align 4
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "mem2reg rejects atomic alloca users as local barriers" {
    const input =
        \\define i32 @atomic_alloca(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store atomic i32 %a, ptr %slot release, align 4
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "simplifycfg folds constant branch and removes unreachable blocks" {
    const input =
        \\define i32 @branch(i32 %a) {
        \\entry:
        \\  br i1 1, label %then, label %else
        \\then:
        \\  ret i32 %a
        \\else:
        \\  %dead = add i32 %a, 1
        \\  ret i32 %dead
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @branch(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "simplifycfg prunes unreachable phi incoming and removes trivial phi" {
    const input =
        \\define i32 @phi_cleanup(i32 %a, i32 %b) {
        \\entry:
        \\  br i1 1, label %then, label %else
        \\then:
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %then ], [ %b, %else ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @phi_cleanup(i32 %a, i32 %b) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "simplifycfg merges matching return blocks" {
    const input =
        \\define i32 @common_ret(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  ret i32 %a
        \\else:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @common_ret(i1 %cond, i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "simplifycfg collapses same-target branch PHI edges when values match" {
    const input =
        \\define i32 @same_target_same_phi(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %merge, label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %entry ], [ %a, %entry ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @same_target_same_phi(i1 %cond, i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "simplifycfg does not thread phi predecessor through multiple edges" {
    const input =
        \\define i32 @switch_duplicate_edge(i2 %cond, i32 %a) {
        \\entry:
        \\  switch i2 %cond, label %empty [
        \\    i2 0, label %empty
        \\  ]
        \\empty:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %empty ]
        \\  ret i32 %v
        \\}
        \\
    ;
    const expected =
        \\define i32 @switch_duplicate_edge(i2 %cond, i32 %a) {
        \\entry:
        \\  switch i2 %cond, label %empty [
        \\    i2 0, label %empty
        \\  ]
        \\empty:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "simplifycfg keeps phi-distinct duplicate predecessor edges" {
    const input =
        \\define i32 @switch_distinct_phi_edges(i2 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  switch i2 %cond, label %empty_a [
        \\    i2 0, label %empty_b
        \\  ]
        \\empty_a:
        \\  br label %merge
        \\empty_b:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %empty_a ], [ %b, %empty_b ]
        \\  ret i32 %v
        \\}
        \\
    ;
    const expected =
        \\define i32 @switch_distinct_phi_edges(i2 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  switch i2 %cond, label %merge [
        \\    i2 0, label %empty_b
        \\  ]
        \\empty_b:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %entry ], [ %b, %empty_b ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "cfg analysis reports successors predecessors and reachability" {
    const input =
        \\define i32 @cfg(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %exit
        \\right:
        \\  br label %exit
        \\dead:
        \\  ret i32 0
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();

    try std.testing.expectEqualSlices(usize, &.{ 1, 2 }, graph.successors(0));
    try std.testing.expectEqualSlices(usize, &.{0}, graph.predecessors(1));
    try std.testing.expectEqualSlices(usize, &.{ 1, 2 }, graph.predecessors(4));

    const reachable = try graph.reachableFromEntry(std.testing.allocator);
    defer std.testing.allocator.free(reachable);

    try std.testing.expectEqualSlices(bool, &.{ true, true, true, false, true }, reachable);
}

test "dominator analysis answers dominance queries" {
    const input =
        \\define i32 @dom(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %exit
        \\right:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var dom = try dominator.Dominators.build(std.testing.allocator, function);
    defer dom.deinit();

    try std.testing.expect(dom.dominates(0, 0));
    try std.testing.expect(dom.dominates(0, 1));
    try std.testing.expect(dom.dominates(0, 2));
    try std.testing.expect(dom.dominates(0, 3));
    try std.testing.expect(dom.dominates(1, 1));
    try std.testing.expect(!dom.dominates(1, 3));
    try std.testing.expect(!dom.dominates(2, 3));
}

test "dominator analysis reports immediate dominators and frontiers" {
    const input =
        \\define i32 @frontier(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var dom = try dominator.Dominators.build(std.testing.allocator, function);
    defer dom.deinit();

    try std.testing.expectEqual(@as(?usize, null), dom.immediateDominator(0));
    try std.testing.expectEqual(@as(?usize, 0), dom.immediateDominator(1));
    try std.testing.expectEqual(@as(?usize, 0), dom.immediateDominator(2));
    try std.testing.expectEqual(@as(?usize, 0), dom.immediateDominator(3));

    var frontiers = try dominator.DominanceFrontiers.build(std.testing.allocator, function, dom);
    defer frontiers.deinit();

    try std.testing.expectEqualSlices(usize, &.{}, frontiers.frontier(0));
    try std.testing.expectEqualSlices(usize, &.{3}, frontiers.frontier(1));
    try std.testing.expectEqualSlices(usize, &.{3}, frontiers.frontier(2));
    try std.testing.expectEqualSlices(usize, &.{}, frontiers.frontier(3));
}

test "postdominator analysis answers postdominance queries" {
    const input =
        \\define i32 @postdom(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %exit
        \\right:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var postdom = try postdominator.PostDominators.build(std.testing.allocator, function);
    defer postdom.deinit();

    try std.testing.expect(postdom.postdominates(3, 0));
    try std.testing.expect(postdom.postdominates(3, 1));
    try std.testing.expect(postdom.postdominates(3, 2));
    try std.testing.expect(postdom.postdominates(3, 3));
    try std.testing.expect(postdom.postdominates(1, 1));
    try std.testing.expect(!postdom.postdominates(1, 0));
    try std.testing.expect(!postdom.postdominates(1, 2));

    try std.testing.expectEqual(@as(?usize, 3), postdom.immediatePostDominator(0));
    try std.testing.expectEqual(@as(?usize, 3), postdom.immediatePostDominator(1));
    try std.testing.expectEqual(@as(?usize, 3), postdom.immediatePostDominator(2));
    try std.testing.expectEqual(@as(?usize, null), postdom.immediatePostDominator(3));
}

test "control dependence reports branch-controlled blocks" {
    const input =
        \\define i32 @control_dep(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %then, label %exit
        \\then:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();

    var postdom = try postdominator.PostDominators.build(std.testing.allocator, function);
    defer postdom.deinit();

    const dependence: postdominator.ControlDependence = .{
        .graph = graph,
        .postdom = postdom,
    };

    try std.testing.expect(dependence.isControlDependentOn(1, 0));
    try std.testing.expect(!dependence.isControlDependentOn(2, 0));
    try std.testing.expect(!dependence.isControlDependentOn(0, 0));
}

test "postdominator analysis covers nested diamonds loops multiple exits and unreachable blocks" {
    const nested_diamond =
        \\define i32 @nested(i1 %a, i1 %b, i32 %v) {
        \\entry:
        \\  br i1 %a, label %left, label %right
        \\left:
        \\  br i1 %b, label %left_inner, label %left_join
        \\left_inner:
        \\  br label %left_join
        \\left_join:
        \\  br label %exit
        \\right:
        \\  br label %exit
        \\exit:
        \\  ret i32 %v
        \\}
        \\
    ;
    var nested_module = try ir.Module.parse(std.testing.allocator, nested_diamond);
    defer nested_module.deinit();
    const nested_function = nested_module.functions.items[0];
    var nested_postdom = try postdominator.PostDominators.build(std.testing.allocator, nested_function);
    defer nested_postdom.deinit();
    try std.testing.expectEqual(@as(?usize, 5), nested_postdom.immediatePostDominator(0));
    try std.testing.expectEqual(@as(?usize, 3), nested_postdom.immediatePostDominator(1));
    try std.testing.expectEqual(@as(?usize, 3), nested_postdom.immediatePostDominator(2));
    try std.testing.expectEqual(@as(?usize, 5), nested_postdom.immediatePostDominator(3));

    var nested_graph = try cfg.Graph.build(std.testing.allocator, nested_function);
    defer nested_graph.deinit();
    const nested_dependence: postdominator.ControlDependence = .{
        .graph = nested_graph,
        .postdom = nested_postdom,
    };
    try std.testing.expect(nested_dependence.isControlDependentOn(1, 0));
    try std.testing.expect(nested_dependence.isControlDependentOn(4, 0));
    try std.testing.expect(nested_dependence.isControlDependentOn(2, 1));
    try std.testing.expect(!nested_dependence.isControlDependentOn(3, 1));

    const loop_cfg =
        \\define i32 @loop_postdom(i1 %cond, i32 %v) {
        \\entry:
        \\  br label %header
        \\header:
        \\  br i1 %cond, label %body, label %exit
        \\body:
        \\  br label %header
        \\exit:
        \\  ret i32 %v
        \\}
        \\
    ;
    var loop_module = try ir.Module.parse(std.testing.allocator, loop_cfg);
    defer loop_module.deinit();
    const loop_function = loop_module.functions.items[0];
    var loop_postdom = try postdominator.PostDominators.build(std.testing.allocator, loop_function);
    defer loop_postdom.deinit();
    try std.testing.expectEqual(@as(?usize, 1), loop_postdom.immediatePostDominator(0));
    try std.testing.expectEqual(@as(?usize, 3), loop_postdom.immediatePostDominator(1));
    try std.testing.expectEqual(@as(?usize, 1), loop_postdom.immediatePostDominator(2));
    try std.testing.expectEqual(@as(?usize, null), loop_postdom.immediatePostDominator(3));

    const multi_exit =
        \\define i32 @multi_exit(i1 %cond, i32 %v) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  ret i32 %v
        \\right:
        \\  ret i32 0
        \\}
        \\
    ;
    var multi_module = try ir.Module.parse(std.testing.allocator, multi_exit);
    defer multi_module.deinit();
    const multi_function = multi_module.functions.items[0];
    var multi_postdom = try postdominator.PostDominators.build(std.testing.allocator, multi_function);
    defer multi_postdom.deinit();
    try std.testing.expectEqual(@as(?usize, null), multi_postdom.immediatePostDominator(0));
    try std.testing.expectEqual(@as(?usize, null), multi_postdom.immediatePostDominator(1));
    try std.testing.expectEqual(@as(?usize, null), multi_postdom.immediatePostDominator(2));

    const unreachable_cfg =
        \\define i32 @unreachable_postdom(i1 %cond, i32 %v) {
        \\entry:
        \\  br label %exit
        \\dead:
        \\  br label %exit
        \\exit:
        \\  ret i32 %v
        \\}
        \\
    ;
    var unreachable_module = try ir.Module.parse(std.testing.allocator, unreachable_cfg);
    defer unreachable_module.deinit();
    const unreachable_function = unreachable_module.functions.items[0];
    var unreachable_postdom = try postdominator.PostDominators.build(std.testing.allocator, unreachable_function);
    defer unreachable_postdom.deinit();
    try std.testing.expectEqual(@as(?usize, 2), unreachable_postdom.immediatePostDominator(0));
    try std.testing.expectEqual(@as(?usize, null), unreachable_postdom.immediatePostDominator(1));
    try std.testing.expectEqual(@as(?usize, null), unreachable_postdom.immediatePostDominator(2));
}

test "loop info finds a natural loop from a dominator backedge" {
    const input =
        \\define i32 @loop(i1 %cond, i32 %a) {
        \\entry:
        \\  br label %header
        \\header:
        \\  br i1 %cond, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var loops = try loop_info.LoopInfo.build(std.testing.allocator, function);
    defer loops.deinit();
    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();

    try std.testing.expectEqual(@as(usize, 1), loops.loops.items.len);
    const natural_loop = loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expectEqual(@as(usize, 1), natural_loop.header);
    try std.testing.expectEqual(@as(usize, 3), natural_loop.latch);
    try std.testing.expectEqual(@as(usize, 1), natural_loop.headerBlock());
    try std.testing.expectEqual(@as(usize, 3), natural_loop.latchBlock());
    try std.testing.expectEqual(@as(usize, 1), natural_loop.depthLevel());
    try std.testing.expectEqualSlices(usize, &.{ 1, 2, 3 }, natural_loop.blocks.items);
    try std.testing.expect(natural_loop.contains(2));
    try std.testing.expect(natural_loop.containsBlock(2));
    try std.testing.expect(!natural_loop.contains(4));
    try std.testing.expectEqual(@as(?usize, 0), natural_loop.preheader(function, graph));

    var latches = try natural_loop.latchBlocks(std.testing.allocator);
    defer latches.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{3}, latches.items);

    const backedge = natural_loop.backedge();
    try std.testing.expectEqual(@as(usize, 3), backedge.latch);
    try std.testing.expectEqual(@as(usize, 1), backedge.header);

    try std.testing.expectEqual(@as(usize, 1), loops.loopDepth(2));
    try std.testing.expectEqual(@as(usize, 0), loops.loopDepth(4));

    var header_latches = try loops.latchesForHeader(std.testing.allocator, 1);
    defer header_latches.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{3}, header_latches.items);

    var backedges = try loops.backedges(std.testing.allocator);
    defer backedges.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), backedges.items.len);
    try std.testing.expectEqual(@as(usize, 3), backedges.items[0].latch);
    try std.testing.expectEqual(@as(usize, 1), backedges.items[0].header);

    var def_blocks = std.StringHashMap(usize).init(std.testing.allocator);
    defer def_blocks.deinit();
    try def_blocks.put("a", std.math.maxInt(usize));
    try def_blocks.put("x", 2);
    try std.testing.expect(natural_loop.isLoopInvariantValue(.{ .named = "a" }, def_blocks));
    try std.testing.expect(natural_loop.isLoopInvariantValue(.{ .int = 1 }, def_blocks));
    try std.testing.expect(!natural_loop.isLoopInvariantValue(.{ .named = "x" }, def_blocks));

    var exiting = try natural_loop.exitingBlocks(std.testing.allocator, graph);
    defer exiting.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{1}, exiting.items);

    var exits = try natural_loop.exitBlocks(std.testing.allocator, graph);
    defer exits.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{4}, exits.items);
}

test "licm leaves loops without an existing preheader unchanged" {
    const input =
        \\define i32 @licm_no_preheader(i32 %a) {
        \\entry:
        \\  br i1 1, label %header, label %exit
        \\header:
        \\  %x = icmp sgt i32 %a, 0
        \\  br i1 %x, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(licm.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "loop info checks LCSSA form for outside loop uses" {
    const accepted =
        \\define i32 @lcssa_ok(i1 %cond) {
        \\entry:
        \\  br label %header
        \\header:
        \\  %i = phi i32 [ 0, %entry ], [ %next, %latch ]
        \\  br i1 %cond, label %latch, label %exit
        \\latch:
        \\  %next = add i32 %i, 1
        \\  br label %header
        \\exit:
        \\  %i.lcssa = phi i32 [ %i, %header ]
        \\  ret i32 %i.lcssa
        \\}
        \\
    ;

    var accepted_module = try ir.Module.parse(std.testing.allocator, accepted);
    defer accepted_module.deinit();
    const accepted_function = accepted_module.functions.items[0];

    var accepted_loops = try loop_info.LoopInfo.build(std.testing.allocator, accepted_function);
    defer accepted_loops.deinit();
    var accepted_graph = try cfg.Graph.build(std.testing.allocator, accepted_function);
    defer accepted_graph.deinit();

    const accepted_loop = accepted_loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expect(try accepted_loop.hasLcssaForm(std.testing.allocator, accepted_function, accepted_graph));

    const rejected =
        \\define i32 @lcssa_bad(i1 %cond) {
        \\entry:
        \\  br label %header
        \\header:
        \\  %i = phi i32 [ 0, %entry ], [ %next, %latch ]
        \\  br i1 %cond, label %latch, label %exit
        \\latch:
        \\  %next = add i32 %i, 1
        \\  br label %header
        \\exit:
        \\  ret i32 %i
        \\}
        \\
    ;

    var rejected_module = try ir.Module.parse(std.testing.allocator, rejected);
    defer rejected_module.deinit();
    const rejected_function = rejected_module.functions.items[0];

    var rejected_loops = try loop_info.LoopInfo.build(std.testing.allocator, rejected_function);
    defer rejected_loops.deinit();
    var rejected_graph = try cfg.Graph.build(std.testing.allocator, rejected_function);
    defer rejected_graph.deinit();

    const rejected_loop = rejected_loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expect(!try rejected_loop.hasLcssaForm(std.testing.allocator, rejected_function, rejected_graph));

    var rewrite_module = try ir.Module.parse(std.testing.allocator, rejected);
    defer rewrite_module.deinit();
    var rewrite_graph = try cfg.Graph.build(std.testing.allocator, rewrite_module.functions.items[0]);
    defer rewrite_graph.deinit();
    var rewrite_loops = try loop_info.LoopInfo.build(std.testing.allocator, rewrite_module.functions.items[0]);
    defer rewrite_loops.deinit();
    const rewrite_loop = rewrite_loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expect(try loop_info.formSimpleLcssa(&rewrite_module, 0, rewrite_loop.*, rewrite_graph));
    try rewrite_module.verify();

    var verify_graph = try cfg.Graph.build(std.testing.allocator, rewrite_module.functions.items[0]);
    defer verify_graph.deinit();
    var verify_loops = try loop_info.LoopInfo.build(std.testing.allocator, rewrite_module.functions.items[0]);
    defer verify_loops.deinit();
    const verify_loop = verify_loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expect(try verify_loop.hasLcssaForm(std.testing.allocator, rewrite_module.functions.items[0], verify_graph));

    const non_dedicated =
        \\define i32 @lcssa_non_dedicated(i1 %cond, i1 %side) {
        \\entry:
        \\  br i1 %side, label %outside, label %header
        \\outside:
        \\  br label %exit
        \\header:
        \\  %i = phi i32 [ 0, %entry ], [ %next, %latch ]
        \\  br i1 %cond, label %latch, label %exit
        \\latch:
        \\  %next = add i32 %i, 1
        \\  br label %header
        \\exit:
        \\  ret i32 %i
        \\}
        \\
    ;

    var non_dedicated_module = try ir.Module.parse(std.testing.allocator, non_dedicated);
    defer non_dedicated_module.deinit();
    var non_dedicated_graph = try cfg.Graph.build(std.testing.allocator, non_dedicated_module.functions.items[0]);
    defer non_dedicated_graph.deinit();
    var non_dedicated_loops = try loop_info.LoopInfo.build(std.testing.allocator, non_dedicated_module.functions.items[0]);
    defer non_dedicated_loops.deinit();
    const non_dedicated_loop = non_dedicated_loops.loopForHeader(2) orelse return error.MissingLoop;
    try std.testing.expect(!try non_dedicated_loop.hasDedicatedExits(std.testing.allocator, non_dedicated_graph));
    try std.testing.expect(!try loop_info.formSimpleLcssa(&non_dedicated_module, 0, non_dedicated_loop.*, non_dedicated_graph));
}

test "loop info classifies reduced Zig corpus loop shape" {
    const input =
        \\define i32 @corpus_loop(i32 %n) {
        \\1:
        \\  %.not = icmp eq i32 %n, 0
        \\  br i1 %.not, label %._crit_edge, label %.lr.ph.preheader
        \\.lr.ph.preheader:
        \\  br label %.lr.ph
        \\.lr.ph:
        \\  %.01 = phi i32 [ 0, %.lr.ph.preheader ], [ %next, %.lr.ph ]
        \\  %next = add nuw i32 %.01, 1
        \\  %done = icmp eq i32 %next, %n
        \\  br i1 %done, label %._crit_edge, label %.lr.ph, !llvm.loop !0
        \\._crit_edge:
        \\  %.0.lcssa = phi i32 [ 0, %1 ], [ %next, %.lr.ph ]
        \\  ret i32 %.0.lcssa
        \\}
        \\
        \\!0 = distinct !{!0}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const function = module.functions.items[0];

    var loops = try loop_info.LoopInfo.build(std.testing.allocator, function);
    defer loops.deinit();
    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();

    const natural_loop = loops.loopForHeader(2) orelse return error.MissingLoop;
    try std.testing.expectEqual(@as(usize, 2), natural_loop.header);
    try std.testing.expectEqual(@as(usize, 2), natural_loop.latch);

    var exiting = try natural_loop.exitingBlocks(std.testing.allocator, graph);
    defer exiting.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{2}, exiting.items);

    var exits = try natural_loop.exitBlocks(std.testing.allocator, graph);
    defer exits.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{3}, exits.items);
    try std.testing.expect(try natural_loop.hasLcssaForm(std.testing.allocator, function, graph));

    var inductions = try natural_loop.simpleInductionVariables(std.testing.allocator, function);
    defer inductions.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), inductions.items.len);
    try std.testing.expectEqualStrings(".01", inductions.items[0].phi_result);
    try std.testing.expectEqual(ir.Value{ .int = 0 }, inductions.items[0].initial_value);
    try std.testing.expectEqual(ir.Value{ .int = 1 }, inductions.items[0].step_value);
    try std.testing.expectEqualStrings("next", inductions.items[0].next_value);
    try std.testing.expect(natural_loop.isSideEffectFreeDeletionCandidate(function));
    try std.testing.expectEqual(loop_info.LoopRotateStatus.unsupported_self_latch_header, natural_loop.rotationStatus(function, graph));
    try std.testing.expectEqual(loop_info.LoopDeletionStatus.eligible_not_implemented, try natural_loop.deletionStatus(std.testing.allocator, function, graph));
}

test "loop info rejects side-effecting loop deletion candidates" {
    const input =
        \\define void @loop_store(i1 %cond, ptr %p, i32 %v) {
        \\entry:
        \\  br label %header
        \\header:
        \\  br i1 %cond, label %body, label %exit
        \\body:
        \\  store i32 %v, ptr %p
        \\  br label %header
        \\exit:
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var loops = try loop_info.LoopInfo.build(std.testing.allocator, function);
    defer loops.deinit();
    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();
    const natural_loop = loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expect(!natural_loop.isSideEffectFreeDeletionCandidate(function));
    try std.testing.expectEqual(loop_info.LoopDeletionStatus.rejected_side_effects, try natural_loop.deletionStatus(std.testing.allocator, function, graph));
}

test "loop info reports nested loop depth and innermost block ownership" {
    const input =
        \\define i32 @nested_loops(i1 %outer_cond, i1 %inner_cond, i32 %a) {
        \\entry:
        \\  br label %outer_header
        \\outer_header:
        \\  br i1 %outer_cond, label %inner_preheader, label %exit
        \\inner_preheader:
        \\  br label %inner_header
        \\inner_header:
        \\  br i1 %inner_cond, label %inner_latch, label %outer_latch
        \\inner_latch:
        \\  br label %inner_header
        \\outer_latch:
        \\  br label %outer_header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var loops = try loop_info.LoopInfo.build(std.testing.allocator, function);
    defer loops.deinit();

    try std.testing.expectEqual(@as(usize, 2), loops.loops.items.len);
    const outer = loops.loopForHeader(1) orelse return error.MissingLoop;
    const inner = loops.loopForHeader(3) orelse return error.MissingLoop;

    try std.testing.expectEqual(@as(usize, 1), outer.depthLevel());
    try std.testing.expectEqual(@as(usize, 2), inner.depthLevel());
    try std.testing.expectEqual(@as(?usize, outer.header), if (inner.parent_index) |parent_index| loops.loops.items[parent_index].header else null);
    try std.testing.expectEqual(@as(usize, 1), loops.loopDepth(5));
    try std.testing.expectEqual(@as(usize, 2), loops.loopDepth(4));

    const inner_owner = loops.loopForBlock(4) orelse return error.MissingLoop;
    try std.testing.expectEqual(@as(usize, 3), inner_owner.header);
}

test "licm leaves side-effecting stores in the loop" {
    const input =
        \\define i32 @licm_store_reject(i32 %a) {
        \\entry:
        \\  %p = alloca i32
        \\  br label %header
        \\header:
        \\  %i = phi i32 [ 0, %entry ], [ %next, %latch ]
        \\  store i32 %i, ptr %p
        \\  br i1 1, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  %next = add i32 %i, 1
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(licm.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "licm leaves memory loads in the loop" {
    const input =
        \\define i32 @licm_load_reject(i32 %a) {
        \\entry:
        \\  %p = alloca i32
        \\  store i32 %a, ptr %p
        \\  br label %header
        \\header:
        \\  %v = load i32, ptr %p
        \\  store i32 %v, ptr %p
        \\  br i1 1, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(licm.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "licm hoists invariant aligned header loads when memory is not clobbered" {
    const input =
        \\define i32 @licm_aligned_load_reject(i32 %a, ptr %p) {
        \\entry:
        \\  br label %header
        \\header:
        \\  %v = load i32, ptr %p, align 4
        \\  %c = icmp sgt i32 %v, 0
        \\  br i1 %c, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;
    const expected =
        \\define i32 @licm_aligned_load_reject(i32 %a, ptr %p) {
        \\entry:
        \\  %v = load i32, ptr %p, align 4
        \\  %c = icmp sgt i32 %v, 0
        \\  br label %header
        \\header:
        \\  br i1 %c, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(licm.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "licm leaves trapping divisions in the loop" {
    const input =
        \\define i32 @licm_trap_reject(i32 %a, i32 %b) {
        \\entry:
        \\  br label %header
        \\header:
        \\  %q = sdiv i32 %a, %b
        \\  br i1 1, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(licm.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "dce preserves atomic memory barriers" {
    const input =
        \\define i32 @memory_atomic_barrier_reject(i32 %a, ptr %p) {
        \\entry:
        \\  store atomic i32 %a, ptr %p release, align 4
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "licm skips multi-latch loops until canonical loop support exists" {
    const input =
        \\define i32 @licm_multi_latch(i32 %a) {
        \\entry:
        \\  br label %header
        \\header:
        \\  %x = icmp sgt i32 %a, 0
        \\  br i1 %x, label %left, label %right
        \\left:
        \\  br label %latch_left
        \\latch_left:
        \\  br label %header
        \\right:
        \\  br label %latch_right
        \\latch_right:
        \\  br label %header
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(licm.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "early-cse removes repeated pure expressions in a block" {
    const input =
        \\define i32 @cse(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %y = add i32 %a, 1
        \\  %z = mul i32 %y, 2
        \\  ret i32 %z
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(early_cse.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @cse(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %z = mul i32 %x, 2
        \\  ret i32 %z
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "early-cse removes dominating pure and safe load expressions" {
    const input =
        \\define i32 @cse_dom_load(i1 %cond, ptr %p, i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %l0 = load i32, ptr %p
        \\  br i1 %cond, label %then, label %exit
        \\then:
        \\  %y = add i32 %a, 1
        \\  %l1 = load i32, ptr %p
        \\  %z = add i32 %y, %l1
        \\  ret i32 %z
        \\exit:
        \\  ret i32 %l0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(early_cse.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @cse_dom_load(i1 %cond, ptr %p, i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %l0 = load i32, ptr %p
        \\  br i1 %cond, label %then, label %exit
        \\then:
        \\  %z = add i32 %x, %l0
        \\  ret i32 %z
        \\exit:
        \\  ret i32 %l0
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "early-cse removes matching readnone calls" {
    const input =
        \\declare i32 @pure(i32) readnone
        \\
        \\define i32 @cse_readnone_call(i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  %y = call i32 @pure(i32 %a)
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(early_cse.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\declare i32 @pure(i32) readnone
        \\
        \\define i32 @cse_readnone_call(i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  ret i32 %x
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "early-cse preserves operand-bundled readnone calls conservatively" {
    const input =
        \\declare i32 @pure() #0
        \\
        \\define i32 @cse_bundled_readnone_call() {
        \\entry:
        \\  %x = call i32 @pure() [ "cold"() ]
        \\  %y = call i32 @pure() [ "deopt"() ]
        \\  %z = add i32 %x, %y
        \\  ret i32 %z
        \\}
        \\
        \\attributes #0 = { memory(none) nounwind }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(early_cse.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "gvn removes equivalent phi nodes and safe loads" {
    const input =
        \\define i32 @gvn_phi_load(i1 %cond, ptr %p, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %join
        \\right:
        \\  br label %join
        \\join:
        \\  %p0 = phi i32 [ %a, %left ], [ %b, %right ]
        \\  %p1 = phi i32 [ %a, %left ], [ %b, %right ]
        \\  %l0 = load i32, ptr %p
        \\  %l1 = load i32, ptr %p
        \\  %x = add i32 %p1, %l1
        \\  ret i32 %x
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(gvn.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @gvn_phi_load(i1 %cond, ptr %p, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %join
        \\right:
        \\  br label %join
        \\join:
        \\  %p0 = phi i32 [ %a, %left ], [ %b, %right ]
        \\  %l0 = load i32, ptr %p
        \\  %x = add i32 %p0, %l0
        \\  ret i32 %x
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "gvn removes matching readnone calls" {
    const input =
        \\declare i32 @pure(i32) readnone
        \\
        \\define i32 @gvn_readnone_call(i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  %y = call i32 @pure(i32 %a)
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(gvn.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\declare i32 @pure(i32) readnone
        \\
        \\define i32 @gvn_readnone_call(i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  ret i32 %x
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "sccp folds direct calls to constant-return functions" {
    const input =
        \\define internal i32 @constant() {
        \\entry:
        \\  ret i32 7
        \\}
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %x = call i32 @constant()
        \\  ret i32 %x
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(sccp.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define internal i32 @constant() {
        \\entry:
        \\  ret i32 7
        \\}
        \\
        \\define i32 @caller() {
        \\entry:
        \\  ret i32 7
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "slp vectorizer recognizes same-op scalar bundles and reports unsupported transform" {
    const input =
        \\define i32 @slp_seed(i32 %a, i32 %b, i32 %c, i32 %d) {
        \\entry:
        \\  %x0 = add i32 %a, %b
        \\  %x1 = add i32 %c, %d
        \\  %sum = add i32 %x0, %x1
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    const candidate = slp_vectorizer.findCandidate(module.functions.items[0]) orelse return error.ExpectedSlpCandidate;
    try std.testing.expectEqualStrings("slp_seed", candidate.function_name);
    try std.testing.expectEqualStrings("entry", candidate.block_name);
    try std.testing.expectEqualStrings("x0", candidate.first_result);
    try std.testing.expectEqualStrings("x1", candidate.second_result);
    try std.testing.expectEqual(ir.BinaryOp.add, candidate.opcode);
    try std.testing.expectEqual(@as(usize, 2), candidate.lanes);

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(slp_vectorizer.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    const result = try pm.run(&module, &context, &output.writer, false);
    try std.testing.expectEqual(pass_manager.PassResult.unchanged, result);
    try std.testing.expectEqual(@as(usize, 1), context.diagnostic_count);
    const diagnostic = context.last_diagnostic orelse return error.ExpectedSlpDiagnostic;
    try std.testing.expectEqualStrings("slp-vectorizer", diagnostic.pass_name);
    try std.testing.expectEqualStrings("slp_seed", diagnostic.function_name);
    try std.testing.expectEqualStrings("x0", diagnostic.value_name.?);
    try std.testing.expectEqualStrings(slp_vectorizer.diagnostic_message, diagnostic.message);
}
