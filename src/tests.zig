const std = @import("std");
const air_bridge = @import("air_bridge.zig");
const alias = @import("analysis/alias.zig");
const call_graph = @import("analysis/call_graph.zig");
const cfg = @import("analysis/cfg.zig");
const codegen = @import("codegen.zig");
const dominator = @import("analysis/dominator.zig");
const function_attrs = @import("analysis/function_attrs.zig");
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
const target = @import("target.zig");
const target_library_info = @import("analysis/target_library_info.zig");
const instcombine = @import("passes/instcombine.zig");
const dce = @import("passes/dce.zig");
const dse = @import("passes/dse.zig");
const early_cse = @import("passes/early_cse.zig");
const gvn = @import("passes/gvn.zig");
const licm = @import("passes/licm.zig");
const mem2reg = @import("passes/mem2reg.zig");
const sccp = @import("passes/sccp.zig");
const simplifycfg = @import("passes/simplifycfg.zig");
const sroa = @import("passes/sroa.zig");

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
        .{ .name = "always-inline", .category = .ipo, .status = "placeholder" },
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

test "parser preserves function visibility and parameter attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define external hidden i32 @visible(i32 noundef %a, ptr nonnull readonly captures(none) initializes((0, 4)) %p) #1 {
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

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
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

test "parser rejects debug value intrinsics until salvage is represented" {
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

    try std.testing.expectError(error.UnsupportedType, ir.Module.parse(std.testing.allocator, input));
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

test "parser rejects vector IR boundary forms deliberately" {
    const vector_add =
        \\define i32 @vector_add() {
        \\entry:
        \\  %v = add <2 x i32> undef, undef
        \\  ret i32 0
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedType, ir.Module.parse(std.testing.allocator, vector_add));

    const shuffle =
        \\define i32 @shuffle() {
        \\entry:
        \\  %v = shufflevector <2 x i32> undef, <2 x i32> undef, <2 x i32> zeroinitializer
        \\  ret i32 0
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedInstruction, ir.Module.parse(std.testing.allocator, shuffle));

    const insert =
        \\define i32 @insert_lane(i32 %a) {
        \\entry:
        \\  %v = insertelement <2 x i32> undef, i32 %a, i32 0
        \\  ret i32 0
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedInstruction, ir.Module.parse(std.testing.allocator, insert));

    const extract =
        \\define i32 @extract_lane() {
        \\entry:
        \\  %v = extractelement <2 x i32> undef, i32 0
        \\  ret i32 0
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedInstruction, ir.Module.parse(std.testing.allocator, extract));

    const vector_constant =
        \\define i32 @vector_constant() {
        \\entry:
        \\  %v = freeze <2 x i32> <i32 1, i32 2>
        \\  ret i32 0
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedType, ir.Module.parse(std.testing.allocator, vector_constant));
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

test "parser rejects sanitizer and trap instrumentation calls explicitly" {
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
    try std.testing.expectError(error.UnsupportedInstrumentationCall, ir.Module.parse(std.testing.allocator, trap_call));
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
        \\declare i32 @unknown(i32)
        \\
        \\define i32 @caller(ptr %p, i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  %y = call i32 @reads(ptr %p)
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
    const unknown_call = block.instructions.items[2].kind.call;

    try std.testing.expectEqual(memory_effect.Effect.none, function_attrs.callMemoryEffect(module, pure_call));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, function_attrs.callMemoryEffect(module, readonly_call));
    try std.testing.expectEqual(memory_effect.Effect.unknown, function_attrs.callMemoryEffect(module, unknown_call));
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
        \\declare void @readwrite(ptr) #3
        \\
        \\define i32 @caller(ptr %p, i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  %y = call i32 @reads(ptr %p)
        \\  %z = call i32 @arg_reads(ptr %p)
        \\  call void @readwrite(ptr %p)
        \\  ret i32 %z
        \\}
        \\
        \\attributes #0 = { mustprogress memory(none) "target-cpu"="x86-64" "target-features"="+sse2,-avx" }
        \\attributes #1 = { nounwind memory(read, argmem: none, inaccessiblemem: none, target_mem0: none) "frame-pointer"="all" }
        \\attributes #2 = { nounwind memory(argmem: read) }
        \\attributes #3 = { nounwind memory(readwrite, argmem: none, inaccessiblemem: none, target_mem0: none) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const block = module.functions.items[0].blocks.items[0];
    try std.testing.expectEqual(memory_effect.Effect.none, function_attrs.callMemoryEffect(module, block.instructions.items[0].kind.call));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, function_attrs.callMemoryEffect(module, block.instructions.items[1].kind.call));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, function_attrs.callMemoryEffect(module, block.instructions.items[2].kind.call));
    try std.testing.expectEqual(memory_effect.Effect.unknown, function_attrs.callMemoryEffect(module, block.instructions.items[3].kind.call));

    const feature_attrs = target.features.parseAttributeText(module.attribute_groups.items[0]);
    try std.testing.expectEqualStrings("x86-64", feature_attrs.cpu.?);
    try std.testing.expect(feature_attrs.hasFeature("+sse2"));
    try std.testing.expect(feature_attrs.hasFeature("-avx"));

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
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

test "globaldce preserves comdat members conservatively" {
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

    const expected =
        \\$grp = comdat any
        \\
        \\@member = internal global i32 1, comdat($grp)
        \\
        \\define internal i32 @helper(i32 %x) comdat($grp) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "globaldce preserves thread local globals conservatively" {
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

    const expected =
        \\@tls = internal thread_local global i32 1
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
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

test "parser rejects unsupported indirect and control-flow call forms" {
    const indirect =
        \\define i32 @caller(ptr %fn, i32 %a) {
        \\entry:
        \\  %r = call i32 %fn(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedIndirectCall, ir.Module.parse(std.testing.allocator, indirect));

    const musttail =
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = musttail call i32 @callee(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedCallAttribute, ir.Module.parse(std.testing.allocator, musttail));

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
}

test "parser preserves scalar global variables" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@g = internal global i32 42, align 4
        \\@c = private constant i8 undef
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

    try std.testing.expectEqual(@as(usize, 2), module.globals.items.len);
    try std.testing.expectEqual(ir.FunctionLinkage.internal, module.globals.items[0].linkage);
    try std.testing.expectEqual(ir.GlobalKind.global, module.globals.items[0].kind);
    try std.testing.expectEqual(@as(i128, 42), module.globals.items[0].initializer.scalar.int);
    try std.testing.expectEqualStrings("align 4", module.globals.items[0].attrs.?);
    try std.testing.expectEqual(ir.FunctionLinkage.private, module.globals.items[1].linkage);
    try std.testing.expectEqual(ir.GlobalKind.constant, module.globals.items[1].kind);
    try std.testing.expectEqual(ir.Value.undef, module.globals.items[1].initializer.scalar);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
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

test "parser rejects unsupported aggregate globals explicitly" {
    const input =
        \\@s = private unnamed_addr constant [4 x i8] c"abc\00"
        \\
    ;

    try std.testing.expectError(error.UnsupportedGlobalVariable, ir.Module.parse(std.testing.allocator, input));
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
        \\  %wide = zext i8 %idx to i64
        \\  %gep = getelementptr i32, ptr @switch.table, i64 %wide
        \\  %value = load i32, ptr %gep, align 4
        \\  ret i32 %value
        \\}
        \\
    , output.writer.buffered());
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
        \\define i1 @float_less(float %a, float %b) {
        \\entry:
        \\  %less = fcmp olt float %a, %b
        \\  ret i1 %less
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expect(module.functions.items[0].ret_ty.eql(.float));
    try std.testing.expect(module.functions.items[1].ret_ty.eql(.double));
    try std.testing.expect(module.functions.items[2].ret_ty.eql(.double));
    try std.testing.expect(module.functions.items[3].ret_ty.eql(.{ .int = 1 }));

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

test "parser keeps unsupported FP surface closed" {
    const fsub_input =
        \\define float @sub(float %a, float %b) {
        \\entry:
        \\  %r = fsub float %a, %b
        \\  ret float %r
        \\}
        \\
    ;
    const fdiv_input =
        \\define float @div(float %a, float %b) {
        \\entry:
        \\  %r = fdiv float %a, %b
        \\  ret float %r
        \\}
        \\
    ;
    const fast_fcmp_input =
        \\define i1 @fast_cmp(float %a, float %b) {
        \\entry:
        \\  %r = fcmp fast olt float %a, %b
        \\  ret i1 %r
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
    const constrained_input =
        \\define float @constrained(float %a, float %b) {
        \\entry:
        \\  %r = call float @llvm.experimental.constrained.fadd.f32(float %a, float %b)
        \\  ret float %r
        \\}
        \\
    ;

    try std.testing.expectError(error.UnsupportedInstruction, ir.Module.parse(std.testing.allocator, fsub_input));
    try std.testing.expectError(error.UnsupportedInstruction, ir.Module.parse(std.testing.allocator, fdiv_input));
    try std.testing.expectError(error.UnsupportedPredicate, ir.Module.parse(std.testing.allocator, fast_fcmp_input));
    try std.testing.expectError(error.UnsupportedType, ir.Module.parse(std.testing.allocator, vector_fcmp_input));

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
    const fastcc_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i32 @callee()
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %r = call fastcc i32 @callee()
        \\  ret i32 %r
        \\}
        \\
    ;
    var fastcc_module = try ir.Module.parse(std.testing.allocator, fastcc_input);
    defer fastcc_module.deinit();
    try fastcc_module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenCallingConvention,
        codegen.x86_64.lowerFunction(std.testing.allocator, fastcc_module.target_triple.?, fastcc_module.functions.items[0]),
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

test "sroa rejects volatile aggregate field accesses locally" {
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

    try std.testing.expectEqualStrings(input, output.writer.buffered());
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

test "instcombine preserves flagged arithmetic and division" {
    const input =
        \\define i32 @conservative(i32 %a) {
        \\entry:
        \\  %x = add nsw i32 %a, 0
        \\  %y = add i32 %x, 1
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

test "parser accepts narrow atomic load and store spelling as barriers" {
    const input =
        \\define i32 @memory_atomic(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store atomic i32 %a, ptr %slot, release, align 4
        \\  %v = load atomic i32, ptr %slot, acquire, align 4
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

test "parser rejects unsupported atomic memory operations" {
    const input =
        \\define i32 @memory_atomicrmw(ptr %p) {
        \\entry:
        \\  %v = atomicrmw add ptr %p, i32 1 monotonic
        \\  ret i32 %v
        \\}
        \\
    ;

    try std.testing.expectError(error.UnsupportedAtomicMemory, ir.Module.parse(std.testing.allocator, input));

    const cmpxchg =
        \\define i32 @memory_cmpxchg(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %v = cmpxchg ptr %p, i32 %old, i32 %new monotonic monotonic
        \\  ret i32 %old
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedAtomicMemory, ir.Module.parse(std.testing.allocator, cmpxchg));

    const fence =
        \\define void @memory_fence() {
        \\entry:
        \\  fence seq_cst
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedAtomicMemory, ir.Module.parse(std.testing.allocator, fence));

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
    try std.testing.expectError(error.UnsupportedAtomicMemory, ir.Module.parse(std.testing.allocator, source_backed_atomicrmw));
}

test "parser rejects inline asm calls explicitly" {
    const input =
        \\define void @inline_asm_barrier() {
        \\entry:
        \\  call void asm sideeffect "", "~{memory}"()
        \\  ret void
        \\}
        \\
    ;

    try std.testing.expectError(error.UnsupportedInlineAsm, ir.Module.parse(std.testing.allocator, input));

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
    try std.testing.expectError(error.UnsupportedInlineAsm, ir.Module.parse(std.testing.allocator, source_backed_inline_asm));
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
        alias.AliasResult.may_alias,
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
        \\  store atomic i32 %pure, ptr %arg, release, align 4
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
        alias.ModRefInfo.ref,
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
        \\  store atomic i32 %a, ptr %slot, release, align 4
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
    try std.testing.expectEqualSlices(usize, &.{ 0, 2 }, exiting.items);

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

test "licm leaves aligned loads in the loop until memory LICM is implemented" {
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
        \\  store atomic i32 %a, ptr %p, release, align 4
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
