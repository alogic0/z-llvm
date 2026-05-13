const std = @import("std");
const pass_manager = @import("pass_manager.zig");
const adce = @import("passes/adce.zig");
const always_inline = @import("passes/always_inline.zig");
const bdce = @import("passes/bdce.zig");
const instcombine = @import("passes/instcombine.zig");
const dce = @import("passes/dce.zig");
const dse = @import("passes/dse.zig");
const early_cse = @import("passes/early_cse.zig");
const globaldce = @import("passes/globaldce.zig");
const gvn = @import("passes/gvn.zig");
const jump_threading = @import("passes/jump_threading.zig");
const licm = @import("passes/licm.zig");
const loop_instsimplify = @import("passes/loop_instsimplify.zig");
const mem2reg = @import("passes/mem2reg.zig");
const placeholder = @import("passes/placeholder.zig");
const sccp = @import("passes/sccp.zig");
const simplifycfg = @import("passes/simplifycfg.zig");
const sroa = @import("passes/sroa.zig");
const verify = @import("passes/verify.zig");

pub const Pipeline = struct {
    name: []const u8,
    passes: []const []const u8,
    mode: []const u8,
    llvm_analogue: []const u8,
    intended_level: []const u8,
    notes: []const u8,
};

const scalar_foundation_passes = [_][]const u8{
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

const memory_foundation_passes = [_][]const u8{
    "simplifycfg",
    "sroa",
    "mem2reg",
    "dce",
};

const debug_o0_passes = [_][]const u8{
    "verify",
    "ee-instrument",
    "always-inline",
    "alloc-token",
    "annotation-remarks",
    "verify",
};

const zig_debug_accepted_passes = [_][]const u8{
    "verify",
};

const zig_release_accepted_passes = [_][]const u8{
    "verify",
    "simplifycfg",
    "instcombine",
    "dce",
    "verify",
};

const aarch64_target_independent_passes = [_][]const u8{
    "verify",
    "instcombine",
    "dce",
    "verify",
};

const release_o3_passes = [_][]const u8{
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

const release_oz_passes = [_][]const u8{
    "verify",
    "add-discriminators",
    "forceattrs",
    "inferattrs",
    "sroa",
    "mem2reg",
    "simplifycfg",
    "instcombine",
    "simplifycfg",
    "instcombine",
    "aggressive-instcombine",
    "lower-constant-intrinsics",
    "early-cse",
    "sccp",
    "gvn",
    "dce",
    "adce",
    "globalopt",
    "globaldce",
    "mergefunc",
    "annotation-remarks",
    "verify",
};

const lto_prelink_o3_passes = [_][]const u8{
    "verify",
    "canonicalize-aliases",
    "name-anon-globals",
    "add-discriminators",
    "forceattrs",
    "inferattrs",
    "sroa",
    "mem2reg",
    "simplifycfg",
    "instcombine",
    "simplifycfg",
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
    "verify",
};

const lto_prelink_oz_passes = [_][]const u8{
    "verify",
    "canonicalize-aliases",
    "name-anon-globals",
    "add-discriminators",
    "forceattrs",
    "inferattrs",
    "sroa",
    "mem2reg",
    "simplifycfg",
    "instcombine",
    "early-cse",
    "sccp",
    "gvn",
    "dce",
    "adce",
    "globalopt",
    "globaldce",
    "verify",
};

pub const all = [_]Pipeline{
    .{
        .name = "scalar-foundation",
        .passes = &scalar_foundation_passes,
        .mode = "development",
        .llvm_analogue = "early scalar cleanup pipeline slices from InstCombine, SimplifyCFG, EarlyCSE, GVN, DCE, and ADCE",
        .intended_level = "phase-zero scalar optimization foundation",
        .notes = "conservative subset without target data layout, calls, vectors, or full poison semantics",
    },
    .{
        .name = "memory-foundation",
        .passes = &memory_foundation_passes,
        .mode = "development",
        .llvm_analogue = "SROA/PromoteMemToReg-oriented stack cleanup plus DCE",
        .intended_level = "phase-zero stack-memory cleanup foundation",
        .notes = "direct stack-slot and zero-offset GEP subset only; no MemorySSA or general memory motion",
    },
    .{
        .name = "zig-scalar-foundation",
        .passes = &scalar_foundation_passes,
        .mode = "development",
        .llvm_analogue = "Zig AIR-like scalar cleanup over target-aware project IR",
        .intended_level = "target-aware AIR-like scalar optimization foundation",
        .notes = "currently reuses scalar-foundation passes after target/module records are available",
    },
    .{
        .name = "debug-o0",
        .passes = &debug_o0_passes,
        .mode = "Debug",
        .llvm_analogue = "PassBuilder::buildO0DefaultPipeline plus Zig extension points",
        .intended_level = "Zig Debug / LLVM O0",
        .notes = "mandatory and instrumentation passes are explicit placeholders except verifier",
    },
    .{
        .name = "zig-debug-accepted",
        .passes = &zig_debug_accepted_passes,
        .mode = "Debug",
        .llvm_analogue = "Zig Debug / LLVM O0 accepted corpus subset",
        .intended_level = "raw Zig-emitted IR corpus validation for Debug rows",
        .notes = "verifier-only until debug metadata and O0 instrumentation rows are accepted",
    },
    .{
        .name = "zig-release-safe-accepted",
        .passes = &zig_release_accepted_passes,
        .mode = "ReleaseSafe",
        .llvm_analogue = "Zig ReleaseSafe / LLVM O3 accepted corpus subset",
        .intended_level = "accepted ReleaseSafe corpus validation",
        .notes = "limited to implemented canonicalization and DCE over accepted safety-control fixtures",
    },
    .{
        .name = "zig-release-fast-accepted",
        .passes = &zig_release_accepted_passes,
        .mode = "ReleaseFast",
        .llvm_analogue = "Zig ReleaseFast / LLVM O3 accepted corpus subset",
        .intended_level = "accepted ReleaseFast corpus validation",
        .notes = "keeps full release-o3 placeholders and target-cost-sensitive transforms out of reduced corpus validation until roots, IPO, and TTI semantics are fixture-ready",
    },
    .{
        .name = "zig-release-small-accepted",
        .passes = &zig_release_accepted_passes,
        .mode = "ReleaseSmall",
        .llvm_analogue = "Zig ReleaseSmall / LLVM Oz accepted corpus subset",
        .intended_level = "accepted ReleaseSmall corpus validation",
        .notes = "uses the same implemented subset as ReleaseFast until size-specific cost, TTI, and global passes are fixture-ready",
    },
    .{
        .name = "aarch64-target-independent",
        .passes = &aarch64_target_independent_passes,
        .mode = "ReleaseFast AArch64",
        .llvm_analogue = "AArch64 Zig ReleaseFast target-independent scalar subset",
        .intended_level = "accepted non-host AArch64 corpus validation",
        .notes = "runs only verifier, integer InstCombine, and DCE; excludes ABI, codegen, TTI, vector, and DataLayout-sensitive memory transforms",
    },
    .{
        .name = "release-o3",
        .passes = &release_o3_passes,
        .mode = "ReleaseFast/ReleaseSafe",
        .llvm_analogue = "PassBuilder::buildPerModuleDefaultPipeline(O3) plus Zig extension points",
        .intended_level = "Zig non-LTO release O3",
        .notes = "implemented scalar/memory foundations are interleaved with inventory placeholders",
    },
    .{
        .name = "release-oz",
        .passes = &release_oz_passes,
        .mode = "ReleaseSmall",
        .llvm_analogue = "PassBuilder::buildPerModuleDefaultPipeline(Oz) plus Zig extension points",
        .intended_level = "Zig non-LTO release Oz",
        .notes = "size-oriented mode omits local LICM until code-size gates exist",
    },
    .{
        .name = "lto-prelink-o3",
        .passes = &lto_prelink_o3_passes,
        .mode = "ReleaseFast/ReleaseSafe LTO pre-link",
        .llvm_analogue = "PassBuilder::buildLTOPreLinkDefaultPipeline(O3)",
        .intended_level = "Zig release LTO pre-link O3",
        .notes = "LTO-specific global canonicalization is represented by placeholders; no bitcode writer or ThinLTO summary is modeled",
    },
    .{
        .name = "lto-prelink-oz",
        .passes = &lto_prelink_oz_passes,
        .mode = "ReleaseSmall LTO pre-link",
        .llvm_analogue = "PassBuilder::buildLTOPreLinkDefaultPipeline(Oz)",
        .intended_level = "Zig release LTO pre-link Oz",
        .notes = "LTO-specific global canonicalization is represented by placeholders; no bitcode writer or ThinLTO summary is modeled",
    },
};

pub fn find(name: []const u8) ?Pipeline {
    for (all) |pipeline| {
        if (std.mem.eql(u8, name, pipeline.name)) return pipeline;
    }
    return null;
}

pub fn addPasses(pm: *pass_manager.ModulePassManager, pass_list: []const u8) anyerror!void {
    var start: usize = 0;
    var depth: usize = 0;
    for (pass_list, 0..) |byte, index| {
        switch (byte) {
            '(' => depth += 1,
            ')' => {
                if (depth == 0) return error.InvalidPassPipeline;
                depth -= 1;
            },
            ',' => if (depth == 0) {
                try addPassExpression(pm, pass_list[start..index]);
                start = index + 1;
            },
            else => {},
        }
    }
    if (depth != 0) return error.InvalidPassPipeline;
    try addPassExpression(pm, pass_list[start..]);
}

fn addPassExpression(pm: *pass_manager.ModulePassManager, raw_expression: []const u8) anyerror!void {
    const expression = std.mem.trim(u8, raw_expression, " \t");
    if (expression.len == 0) return;

    if (find(expression)) |pipeline| {
        for (pipeline.passes) |pass_name| try addPass(pm, pass_name);
    } else if (nestedPipelineBody(expression)) |body| {
        try addPasses(pm, body);
    } else {
        try addPass(pm, expression);
    }
}

fn nestedPipelineBody(expression: []const u8) ?[]const u8 {
    const prefixes = [_][]const u8{
        "module(",
        "function(",
        "loop(",
        "cgscc(",
    };
    for (prefixes) |prefix| {
        if (!std.mem.startsWith(u8, expression, prefix)) continue;
        if (!std.mem.endsWith(u8, expression, ")")) return null;
        return expression[prefix.len .. expression.len - 1];
    }
    return null;
}

fn addPass(pm: *pass_manager.ModulePassManager, name: []const u8) !void {
    if (std.mem.eql(u8, name, "instcombine")) {
        try pm.add(instcombine.pass);
    } else if (std.mem.eql(u8, name, "always-inline")) {
        try pm.add(always_inline.pass);
    } else if (std.mem.eql(u8, name, "jump-threading")) {
        try pm.add(jump_threading.pass);
    } else if (std.mem.eql(u8, name, "verify")) {
        try pm.add(verify.pass);
    } else if (std.mem.eql(u8, name, "dce")) {
        try pm.add(dce.pass);
    } else if (std.mem.eql(u8, name, "dse")) {
        try pm.add(dse.pass);
    } else if (std.mem.eql(u8, name, "adce")) {
        try pm.add(adce.pass);
    } else if (std.mem.eql(u8, name, "bdce")) {
        try pm.add(bdce.pass);
    } else if (std.mem.eql(u8, name, "early-cse")) {
        try pm.add(early_cse.pass);
    } else if (std.mem.eql(u8, name, "sccp")) {
        try pm.add(sccp.pass);
    } else if (std.mem.eql(u8, name, "gvn")) {
        try pm.add(gvn.pass);
    } else if (std.mem.eql(u8, name, "globaldce")) {
        try pm.add(globaldce.pass);
    } else if (std.mem.eql(u8, name, "licm")) {
        try pm.add(licm.pass);
    } else if (std.mem.eql(u8, name, "loop-instsimplify")) {
        try pm.add(loop_instsimplify.pass);
    } else if (std.mem.eql(u8, name, "simplifycfg")) {
        try pm.add(simplifycfg.pass);
    } else if (std.mem.eql(u8, name, "mem2reg")) {
        try pm.add(mem2reg.pass);
    } else if (std.mem.eql(u8, name, "sroa")) {
        try pm.add(sroa.pass);
    } else if (placeholderPass(name)) |pass| {
        try pm.add(pass);
    } else {
        return error.UnknownPass;
    }
}

fn placeholderPass(name: []const u8) ?pass_manager.ModulePass {
    if (std.mem.eql(u8, name, "aggressive-instcombine")) return placeholder.make("aggressive-instcombine", .canonicalization, "llvm/lib/Transforms/AggressiveInstCombine/");
    if (std.mem.eql(u8, name, "lower-constant-intrinsics")) return placeholder.make("lower-constant-intrinsics", .canonicalization, "llvm/lib/Transforms/Scalar/LowerConstantIntrinsics.cpp");
    if (std.mem.eql(u8, name, "drop-unnecessary-assumes")) return placeholder.make("drop-unnecessary-assumes", .canonicalization, "llvm/lib/Transforms/Scalar/DropUnnecessaryAssumes.cpp");
    if (std.mem.eql(u8, name, "correlated-propagation")) return placeholder.make("correlated-propagation", .scalar, "llvm/lib/Transforms/Scalar/CorrelatedValuePropagation.cpp");
    if (std.mem.eql(u8, name, "tailcallelim")) return placeholder.make("tailcallelim", .codegen_prep, "llvm/lib/Transforms/Scalar/TailRecursionElimination.cpp");
    if (std.mem.eql(u8, name, "lower-expect")) return placeholder.make("lower-expect", .codegen_prep, "llvm/lib/Transforms/Scalar/LowerExpectIntrinsic.cpp");
    if (std.mem.eql(u8, name, "div-rem-pairs")) return placeholder.make("div-rem-pairs", .codegen_prep, "llvm/lib/Transforms/Scalar/DivRemPairs.cpp");
    if (std.mem.eql(u8, name, "float2int")) return placeholder.make("float2int", .codegen_prep, "llvm/lib/Transforms/Scalar/Float2Int.cpp");
    if (std.mem.eql(u8, name, "libcalls-shrinkwrap")) return placeholder.make("libcalls-shrinkwrap", .codegen_prep, "llvm/lib/Transforms/Utils/LibCallsShrinkWrap.cpp");
    if (std.mem.eql(u8, name, "inject-tli-mappings")) return placeholder.make("inject-tli-mappings", .codegen_prep, "llvm/lib/Transforms/Utils/InjectTLIMappings.cpp");
    if (std.mem.eql(u8, name, "rel-lookup-table-converter")) return placeholder.make("rel-lookup-table-converter", .codegen_prep, "llvm/lib/Transforms/Utils/RelLookupTableConverter.cpp");
    if (std.mem.eql(u8, name, "memcpyopt")) return placeholder.make("memcpyopt", .memory, "llvm/lib/Transforms/Scalar/MemCpyOptimizer.cpp");
    if (std.mem.eql(u8, name, "mldst-motion")) return placeholder.make("mldst-motion", .memory, "llvm/lib/Transforms/Scalar/MergedLoadStoreMotion.cpp");
    if (std.mem.eql(u8, name, "infer-alignment")) return placeholder.make("infer-alignment", .memory, "llvm/lib/Transforms/Scalar/InferAlignment.cpp");
    if (std.mem.eql(u8, name, "alignment-from-assumptions")) return placeholder.make("alignment-from-assumptions", .memory, "llvm/lib/Transforms/Scalar/AlignmentFromAssumptions.cpp");
    if (std.mem.eql(u8, name, "move-auto-init")) return placeholder.make("move-auto-init", .memory, "llvm/lib/Transforms/Scalar/MoveAutoInit.cpp");
    if (std.mem.eql(u8, name, "ipsccp")) return placeholder.make("ipsccp", .ipo, "llvm/lib/Transforms/IPO/SCCP.cpp");
    if (std.mem.eql(u8, name, "reassociate")) return placeholder.make("reassociate", .scalar, "llvm/lib/Transforms/Scalar/Reassociate.cpp");
    if (std.mem.eql(u8, name, "constraint-elimination")) return placeholder.make("constraint-elimination", .scalar, "llvm/lib/Transforms/Scalar/ConstraintElimination.cpp");
    if (std.mem.eql(u8, name, "speculative-execution")) return placeholder.make("speculative-execution", .scalar, "llvm/lib/Transforms/Scalar/SpeculativeExecution.cpp");
    if (std.mem.eql(u8, name, "loop-simplifycfg")) return placeholder.make("loop-simplifycfg", .loop, "llvm/lib/Transforms/Scalar/LoopSimplifyCFG.cpp");
    if (std.mem.eql(u8, name, "loop-rotate")) return placeholder.make("loop-rotate", .loop, "llvm/lib/Transforms/Scalar/LoopRotation.cpp");
    if (std.mem.eql(u8, name, "loop-deletion")) return placeholder.make("loop-deletion", .loop, "llvm/lib/Transforms/Scalar/LoopDeletion.cpp");
    if (std.mem.eql(u8, name, "indvars")) return placeholder.make("indvars", .loop, "llvm/lib/Transforms/Scalar/IndVarSimplify.cpp");
    if (std.mem.eql(u8, name, "simple-loop-unswitch")) return placeholder.make("simple-loop-unswitch", .loop, "llvm/lib/Transforms/Scalar/SimpleLoopUnswitch.cpp");
    if (std.mem.eql(u8, name, "loop-idiom")) return placeholder.make("loop-idiom", .loop, "llvm/lib/Transforms/Scalar/LoopIdiomRecognize.cpp");
    if (std.mem.eql(u8, name, "loop-sink")) return placeholder.make("loop-sink", .loop, "llvm/lib/Transforms/Scalar/LoopSink.cpp");
    if (std.mem.eql(u8, name, "loop-unroll")) return placeholder.make("loop-unroll", .loop, "llvm/lib/Transforms/Scalar/LoopUnrollPass.cpp");
    if (std.mem.eql(u8, name, "loop-unroll-full")) return placeholder.make("loop-unroll-full", .loop, "llvm/lib/Transforms/Scalar/LoopUnrollPass.cpp");
    if (std.mem.eql(u8, name, "loop-distribute")) return placeholder.make("loop-distribute", .loop, "llvm/lib/Transforms/Scalar/LoopDistribute.cpp");
    if (std.mem.eql(u8, name, "loop-load-elim")) return placeholder.make("loop-load-elim", .loop, "llvm/lib/Transforms/Scalar/LoopLoadElimination.cpp");
    if (std.mem.eql(u8, name, "extra-simple-loop-unswitch-passes")) return placeholder.make("extra-simple-loop-unswitch-passes", .loop, "llvm/lib/Passes/PassBuilderPipelines.cpp");
    if (std.mem.eql(u8, name, "ee-instrument")) return placeholder.make("ee-instrument", .instrumentation, "llvm/lib/Transforms/Utils/EntryExitInstrumenter.cpp");
    if (std.mem.eql(u8, name, "alloc-token")) return placeholder.make("alloc-token", .instrumentation, "llvm/lib/Transforms/Instrumentation/AllocToken.cpp");
    if (std.mem.eql(u8, name, "annotation-remarks")) return placeholder.make("annotation-remarks", .instrumentation, "llvm/lib/Transforms/Scalar/AnnotationRemarks.cpp");
    if (std.mem.eql(u8, name, "add-discriminators")) return placeholder.make("add-discriminators", .instrumentation, "llvm/lib/Transforms/Utils/AddDiscriminators.cpp");
    if (std.mem.eql(u8, name, "annotation2metadata")) return placeholder.make("annotation2metadata", .instrumentation, "llvm/lib/Transforms/IPO/Annotation2Metadata.cpp");
    if (std.mem.eql(u8, name, "sancov")) return placeholder.make("sancov", .instrumentation, "llvm/lib/Transforms/Instrumentation/SanitizerCoverage.cpp");
    if (std.mem.eql(u8, name, "module-tsan")) return placeholder.make("module-tsan", .instrumentation, "llvm/lib/Transforms/Instrumentation/ThreadSanitizer.cpp");
    if (std.mem.eql(u8, name, "tsan")) return placeholder.make("tsan", .instrumentation, "llvm/lib/Transforms/Instrumentation/ThreadSanitizer.cpp");
    if (std.mem.eql(u8, name, "memprof-remove-attributes")) return placeholder.make("memprof-remove-attributes", .instrumentation, "llvm/lib/Transforms/Instrumentation/MemProfUse.cpp");
    if (std.mem.eql(u8, name, "cg-profile")) return placeholder.make("cg-profile", .instrumentation, "llvm/lib/Transforms/Instrumentation/CGProfile.cpp");
    if (std.mem.eql(u8, name, "chr")) return placeholder.make("chr", .instrumentation, "llvm/lib/Transforms/Instrumentation/ControlHeightReduction.cpp");
    if (std.mem.eql(u8, name, "transform-warning")) return placeholder.make("transform-warning", .instrumentation, "llvm/lib/Transforms/Scalar/WarnMissedTransforms.cpp");
    if (std.mem.eql(u8, name, "loop-vectorize")) return placeholder.make("loop-vectorize", .vector, "llvm/lib/Transforms/Vectorize/LoopVectorize.cpp");
    if (std.mem.eql(u8, name, "slp-vectorizer")) return placeholder.make("slp-vectorizer", .vector, "llvm/lib/Transforms/Vectorize/SLPVectorizer.cpp");
    if (std.mem.eql(u8, name, "vector-combine")) return placeholder.make("vector-combine", .vector, "llvm/lib/Transforms/Vectorize/VectorCombine.cpp");
    if (std.mem.eql(u8, name, "coro-early")) return placeholder.make("coro-early", .ipo, "llvm/lib/Transforms/Coroutines/CoroEarly.cpp");
    if (std.mem.eql(u8, name, "coro-split")) return placeholder.make("coro-split", .ipo, "llvm/lib/Transforms/Coroutines/CoroSplit.cpp");
    if (std.mem.eql(u8, name, "coro-elide")) return placeholder.make("coro-elide", .ipo, "llvm/lib/Transforms/Coroutines/CoroElide.cpp");
    if (std.mem.eql(u8, name, "coro-cleanup")) return placeholder.make("coro-cleanup", .ipo, "llvm/lib/Transforms/Coroutines/CoroCleanup.cpp");
    if (std.mem.eql(u8, name, "coro-annotation-elide")) return placeholder.make("coro-annotation-elide", .ipo, "llvm/lib/Transforms/Coroutines/CoroAnnotationElide.cpp");
    if (std.mem.eql(u8, name, "openmp-opt")) return placeholder.make("openmp-opt", .ipo, "llvm/lib/Transforms/IPO/OpenMPOpt.cpp");
    if (std.mem.eql(u8, name, "openmp-opt-cgscc")) return placeholder.make("openmp-opt-cgscc", .ipo, "llvm/lib/Transforms/IPO/OpenMPOpt.cpp");
    if (std.mem.eql(u8, name, "forceattrs")) return placeholder.make("forceattrs", .ipo, "llvm/lib/Transforms/IPO/ForceFunctionAttrs.cpp");
    if (std.mem.eql(u8, name, "inferattrs")) return placeholder.make("inferattrs", .ipo, "llvm/lib/Transforms/IPO/InferFunctionAttrs.cpp");
    if (std.mem.eql(u8, name, "function-attrs")) return placeholder.make("function-attrs", .ipo, "llvm/lib/Transforms/IPO/FunctionAttrs.cpp");
    if (std.mem.eql(u8, name, "rpo-function-attrs")) return placeholder.make("rpo-function-attrs", .ipo, "llvm/lib/Transforms/IPO/FunctionAttrs.cpp");
    if (std.mem.eql(u8, name, "inline")) return placeholder.make("inline", .ipo, "llvm/lib/Transforms/IPO/Inliner.cpp");
    if (std.mem.eql(u8, name, "argpromotion")) return placeholder.make("argpromotion", .ipo, "llvm/lib/Transforms/IPO/ArgumentPromotion.cpp");
    if (std.mem.eql(u8, name, "called-value-propagation")) return placeholder.make("called-value-propagation", .ipo, "llvm/lib/Transforms/IPO/CalledValuePropagation.cpp");
    if (std.mem.eql(u8, name, "callsite-splitting")) return placeholder.make("callsite-splitting", .scalar, "llvm/lib/Transforms/Scalar/CallSiteSplitting.cpp");
    if (std.mem.eql(u8, name, "deadargelim")) return placeholder.make("deadargelim", .ipo, "llvm/lib/Transforms/IPO/DeadArgumentElimination.cpp");
    if (std.mem.eql(u8, name, "dse")) return placeholder.make("dse", .memory, "llvm/lib/Transforms/Scalar/DeadStoreElimination.cpp");
    if (std.mem.eql(u8, name, "globalopt")) return placeholder.make("globalopt", .ipo, "llvm/lib/Transforms/IPO/GlobalOpt.cpp");
    if (std.mem.eql(u8, name, "constmerge")) return placeholder.make("constmerge", .ipo, "llvm/lib/Transforms/IPO/ConstantMerge.cpp");
    if (std.mem.eql(u8, name, "elim-avail-extern")) return placeholder.make("elim-avail-extern", .ipo, "llvm/lib/Transforms/IPO/ElimAvailExtern.cpp");
    if (std.mem.eql(u8, name, "recompute-globalsaa")) return placeholder.make("recompute-globalsaa", .analysis, "llvm/lib/Analysis/GlobalsModRef.cpp");
    if (std.mem.eql(u8, name, "globals-aa")) return placeholder.make("globals-aa", .analysis, "llvm/lib/Analysis/GlobalsModRef.cpp");
    if (std.mem.eql(u8, name, "mergefunc")) return placeholder.make("mergefunc", .ipo, "llvm/lib/Transforms/IPO/MergeFunctions.cpp");
    if (std.mem.eql(u8, name, "canonicalize-aliases")) return placeholder.make("canonicalize-aliases", .lto, "llvm/lib/Transforms/Utils/CanonicalizeAliases.cpp");
    if (std.mem.eql(u8, name, "name-anon-globals")) return placeholder.make("name-anon-globals", .lto, "llvm/lib/Transforms/Utils/NameAnonGlobals.cpp");
    if (std.mem.eql(u8, name, "require<globals-aa>")) return placeholder.make("require<globals-aa>", .analysis, "llvm/include/llvm/IR/PassManager.h");
    if (std.mem.eql(u8, name, "invalidate<aa>")) return placeholder.make("invalidate<aa>", .analysis, "llvm/include/llvm/IR/PassManager.h");
    if (std.mem.eql(u8, name, "require<profile-summary>")) return placeholder.make("require<profile-summary>", .analysis, "llvm/include/llvm/IR/PassManager.h");
    if (std.mem.eql(u8, name, "require<branch-probability>")) return placeholder.make("require<branch-probability>", .analysis, "llvm/lib/Analysis/BranchProbabilityInfo.cpp");
    if (std.mem.eql(u8, name, "require<block-frequency>")) return placeholder.make("require<block-frequency>", .analysis, "llvm/lib/Analysis/BlockFrequencyInfo.cpp");
    if (std.mem.eql(u8, name, "require<should-not-run-function-passes>")) return placeholder.make("require<should-not-run-function-passes>", .pipeline_guard, "llvm/lib/Passes/PassBuilderPipelines.cpp");
    return null;
}
