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

test "release pipeline placeholder budgets are explicit policy" {
    try pipelines.verifyPlaceholderBudgets();

    const expected = [_]struct {
        name: []const u8,
        placeholders: usize,
    }{
        .{ .name = "release-o3", .placeholders = 7 },
        .{ .name = "release-oz", .placeholders = 7 },
        .{ .name = "lto-prelink-o3", .placeholders = 6 },
        .{ .name = "lto-prelink-oz", .placeholders = 4 },
    };

    for (expected) |row| {
        const pipeline = pipelines.find(row.name).?;
        const counts = pipelines.summarizePipeline(pipeline);
        try std.testing.expectEqual(row.placeholders, counts.placeholder);
        try std.testing.expectEqual(@as(usize, 0), counts.unknown);
        try std.testing.expectEqual(row.placeholders, pipelines.expectedPlaceholderBudget(row.name).?);
    }
}

test "pass registry exposes implementation status and upstream path" {
    const instcombine_entry = pipelines.findPass("instcombine").?;
    try std.testing.expectEqual(pipelines.PassStatus.implemented, instcombine_entry.status);
    try std.testing.expectEqual(pass_manager.PassCategory.canonicalization, instcombine_entry.category);
    try std.testing.expect(std.mem.indexOf(u8, instcombine_entry.upstream_path, "InstCombine") != null);

    const placeholder_entry = pipelines.findPass("aggressive-instcombine").?;
    try std.testing.expectEqual(pipelines.PassStatus.placeholder, placeholder_entry.status);
    try std.testing.expectEqualStrings("placeholder", placeholder_entry.pass.target_status);
    try std.testing.expect(std.mem.indexOf(u8, placeholder_entry.upstream_path, "AggressiveInstCombine") != null);

    try std.testing.expect(pipelines.findPass("definitely-not-a-pass") == null);
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

test "debug variable-location intrinsics skip transform passes with cached scan" {
    const input =
        \\declare void @llvm.dbg.value(metadata, metadata, metadata)
        \\
        \\define i32 @debug_value(i32 %a) !dbg !4 {
        \\entry:
        \\  call void @llvm.dbg.value(metadata i32 %a, metadata !9, metadata !DIExpression()), !dbg !8
        \\  %x = add i32 %a, 0
        \\  ret i32 %x
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

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(.{ .name = "transform-one", .category = .scalar, .run = diagnosticTransformPass });
    try pm.add(.{ .name = "transform-two", .category = .memory, .run = diagnosticTransformPass });
    try pm.add(.{ .name = "mandatory", .category = .mandatory, .run = diagnosticMandatoryPass });

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    const result = try pm.runWithOptions(&module, &context, &output.writer, .{});
    try std.testing.expectEqual(pass_manager.PassResult.unchanged, result);
    try std.testing.expectEqual(@as(usize, 1), context.debug_variable_location_scan_count);
    try std.testing.expectEqual(@as(usize, 2), context.skipped_transform_passes);
    try std.testing.expectEqual(@as(usize, 1), context.diagnostic_count);
    try std.testing.expect(std.mem.indexOf(u8, output.writer.buffered(), "skipped_transform_passes=2") != null);
}

fn noopPass(_: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    return .unchanged;
}

fn diagnosticTransformPass(_: *ir.Module, context: *pass_manager.Context) !pass_manager.PassResult {
    context.emitDiagnostic("transform", "debug_value", null, "should have been skipped");
    return .changed;
}

fn diagnosticMandatoryPass(_: *ir.Module, context: *pass_manager.Context) !pass_manager.PassResult {
    context.emitDiagnostic("mandatory", "debug_value", null, "mandatory pass ran");
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
