const ir_common = @import("ir_common.zig");

const std = ir_common.std;
const air_bridge = ir_common.air_bridge;
const alias = ir_common.alias;
const call_graph = ir_common.call_graph;
const cfg = ir_common.cfg;
const codegen = ir_common.codegen;
const dominator = ir_common.dominator;
const function_attrs = ir_common.function_attrs;
const fp_semantics = ir_common.fp_semantics;
const loop_info = ir_common.loop_info;
const memory_effect = ir_common.memory_effect;
const memory_location = ir_common.memory_location;
const memory_ssa = ir_common.memory_ssa;
const ir = ir_common.ir;
const normalize = ir_common.normalize;
const mc = ir_common.mc;
const pass_manager = ir_common.pass_manager;
const pipelines = ir_common.pipelines;
const postdominator = ir_common.postdominator;
const semantic_descriptor_v2 = ir_common.semantic_descriptor_v2;
const target = ir_common.target;
const target_library_info = ir_common.target_library_info;
const target_transform_info = ir_common.target_transform_info;
const instcombine = ir_common.instcombine;
const zig_air_export = ir_common.zig_air_export;
const zig_air_lowering = ir_common.zig_air_lowering;
const dce = ir_common.dce;
const dse = ir_common.dse;
const early_cse = ir_common.early_cse;
const gvn = ir_common.gvn;
const licm = ir_common.licm;
const mem2reg = ir_common.mem2reg;
const sccp = ir_common.sccp;
const simplifycfg = ir_common.simplifycfg;
const slp_vectorizer = ir_common.slp_vectorizer;
const sroa = ir_common.sroa;
test {
    _ = zig_air_export;
    _ = zig_air_lowering;
}

fn expectMachineInstruction(instructions: []const codegen.x86_64.Instruction, expected: codegen.x86_64.Instruction) !void {
    for (instructions) |instruction| {
        if (std.meta.eql(instruction, expected)) return;
    }
    return error.TestExpectedEqual;
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

test "x86_64 SysV aggregate classifier covers register and memory classes" {
    const pair = try codegen.x86_64.classifySysVAggregateForTest(.{ .aggregate = "{ i64, i64 }" });
    try std.testing.expectEqual(codegen.x86_64.SysVAggregateKind.register, pair.kind);
    try std.testing.expectEqual(@as(u2, 2), pair.eightbyte_count);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .integer), pair.eightbytes[0]);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .integer), pair.eightbytes[1]);

    const mixed = try codegen.x86_64.classifySysVAggregateForTest(.{ .aggregate = "{ i64, double }" });
    try std.testing.expectEqual(codegen.x86_64.SysVAggregateKind.register, mixed.kind);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .integer), mixed.eightbytes[0]);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .sse), mixed.eightbytes[1]);

    const reversed = try codegen.x86_64.classifySysVAggregateForTest(.{ .aggregate = "{ double, i64 }" });
    try std.testing.expectEqual(codegen.x86_64.SysVAggregateKind.register, reversed.kind);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .sse), reversed.eightbytes[0]);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .integer), reversed.eightbytes[1]);

    const sse_pair = try codegen.x86_64.classifySysVAggregateForTest(.{ .aggregate = "{ double, double }" });
    try std.testing.expectEqual(codegen.x86_64.SysVAggregateKind.register, sse_pair.kind);
    try std.testing.expect(sse_pair.isSseOnly());
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .sse), sse_pair.eightbytes[0]);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .sse), sse_pair.eightbytes[1]);

    const f32_pair = try codegen.x86_64.classifySysVAggregateForTest(.{ .aggregate = "{ float, float }" });
    try std.testing.expectEqual(codegen.x86_64.SysVAggregateKind.register, f32_pair.kind);
    try std.testing.expectEqual(@as(u2, 1), f32_pair.eightbyte_count);
    try std.testing.expect(f32_pair.isSseOnly());
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .sse), f32_pair.eightbytes[0]);

    const array = try codegen.x86_64.classifySysVAggregateForTest(.{ .aggregate = "[2 x i64]" });
    try std.testing.expectEqual(codegen.x86_64.SysVAggregateKind.register, array.kind);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .integer), array.eightbytes[0]);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .integer), array.eightbytes[1]);

    const double_array = try codegen.x86_64.classifySysVAggregateForTest(.{ .aggregate = "{ [2 x double] }" });
    try std.testing.expectEqual(codegen.x86_64.SysVAggregateKind.register, double_array.kind);
    try std.testing.expect(double_array.isSseOnly());
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .sse), double_array.eightbytes[0]);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .sse), double_array.eightbytes[1]);

    const nested_double = try codegen.x86_64.classifySysVAggregateForTest(.{ .aggregate = "{ { double }, { double } }" });
    try std.testing.expectEqual(codegen.x86_64.SysVAggregateKind.register, nested_double.kind);
    try std.testing.expect(nested_double.isSseOnly());
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .sse), nested_double.eightbytes[0]);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .sse), nested_double.eightbytes[1]);

    const nested = try codegen.x86_64.classifySysVAggregateForTest(.{ .aggregate = "{ { i32, i32 }, i64 }" });
    try std.testing.expectEqual(codegen.x86_64.SysVAggregateKind.register, nested.kind);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .integer), nested.eightbytes[0]);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .integer), nested.eightbytes[1]);

    const nested_mixed = try codegen.x86_64.classifySysVAggregateForTest(.{ .aggregate = "{ { i32, i32 }, double }" });
    try std.testing.expectEqual(codegen.x86_64.SysVAggregateKind.register, nested_mixed.kind);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .integer), nested_mixed.eightbytes[0]);
    try std.testing.expectEqual(@as(?codegen.x86_64.SysVAggregateEightbyteClass, .sse), nested_mixed.eightbytes[1]);

    const too_large = try codegen.x86_64.classifySysVAggregateForTest(.{ .aggregate = "{ i64, i64, i64 }" });
    try std.testing.expectEqual(codegen.x86_64.SysVAggregateKind.memory, too_large.kind);

    const packed_struct = try codegen.x86_64.classifySysVAggregateForTest(.{ .aggregate = "<{ i8, i64 }>" });
    try std.testing.expectEqual(codegen.x86_64.SysVAggregateKind.memory, packed_struct.kind);
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

test "parser round-trips normalized Zig-emitted scalar LLVM IR" {
    const input = @embedFile("../testdata/zig_tiny_scalar.normalized.ll");

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
