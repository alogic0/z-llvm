const std = @import("std");
const pass_manager = @import("pass_manager.zig");
const aggressive_instcombine = @import("passes/aggressive_instcombine.zig");
const adce = @import("passes/adce.zig");
const always_inline = @import("passes/always_inline.zig");
const bdce = @import("passes/bdce.zig");
const correlated_propagation = @import("passes/correlated_propagation.zig");
const canonicalize_aliases = @import("passes/canonicalize_aliases.zig");
const constmerge = @import("passes/constmerge.zig");
const function_attrs = @import("passes/function_attrs.zig");
const instcombine = @import("passes/instcombine.zig");
const dce = @import("passes/dce.zig");
const dse = @import("passes/dse.zig");
const early_cse = @import("passes/early_cse.zig");
const globaldce = @import("passes/globaldce.zig");
const globalopt = @import("passes/globalopt.zig");
const gvn = @import("passes/gvn.zig");
const indvars = @import("passes/indvars.zig");
const inferattrs = @import("passes/inferattrs.zig");
const inline_pass = @import("passes/inline.zig");
const jump_threading = @import("passes/jump_threading.zig");
const licm = @import("passes/licm.zig");
const loop_instsimplify = @import("passes/loop_instsimplify.zig");
const loop_deletion = @import("passes/loop_deletion.zig");
const loop_rotate = @import("passes/loop_rotate.zig");
const loop_simplifycfg = @import("passes/loop_simplifycfg.zig");
const lower_constant_intrinsics = @import("passes/lower_constant_intrinsics.zig");
const lower_expect = @import("passes/lower_expect.zig");
const mem2reg = @import("passes/mem2reg.zig");
const placeholder = @import("passes/placeholder.zig");
const sccp = @import("passes/sccp.zig");
const simplifycfg = @import("passes/simplifycfg.zig");
const slp_vectorizer = @import("passes/slp_vectorizer.zig");
const sroa = @import("passes/sroa.zig");
const verify = @import("passes/verify.zig");
const vector_combine = @import("passes/vector_combine.zig");

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

pub const PassStatus = enum {
    implemented,
    placeholder,
    conservative,
    boundary_noop,
    out_of_scope,
};

pub const PassStatusCounts = struct {
    implemented: usize = 0,
    placeholder: usize = 0,
    conservative: usize = 0,
    boundary_noop: usize = 0,
    out_of_scope: usize = 0,
    unknown: usize = 0,

    pub fn note(counts: *PassStatusCounts, status: ?PassStatus) void {
        switch (status orelse {
            counts.unknown += 1;
            return;
        }) {
            .implemented => counts.implemented += 1,
            .placeholder => counts.placeholder += 1,
            .conservative => counts.conservative += 1,
            .boundary_noop => counts.boundary_noop += 1,
            .out_of_scope => counts.out_of_scope += 1,
        }
    }
};

pub const PassRegistryEntry = struct {
    name: []const u8,
    category: pass_manager.PassCategory,
    status: PassStatus,
    upstream_path: []const u8,
    pass: pass_manager.ModulePass,
};

fn implemented(pass: pass_manager.ModulePass) PassRegistryEntry {
    return .{
        .name = pass.name,
        .category = pass.category,
        .status = .implemented,
        .upstream_path = pass.upstream_owner,
        .pass = pass,
    };
}

fn conservative(pass: pass_manager.ModulePass) PassRegistryEntry {
    return .{
        .name = pass.name,
        .category = pass.category,
        .status = .conservative,
        .upstream_path = pass.upstream_owner,
        .pass = pass,
    };
}

fn placeholderEntry(
    comptime name: []const u8,
    comptime category: pass_manager.PassCategory,
    comptime upstream_path: []const u8,
) PassRegistryEntry {
    return .{
        .name = name,
        .category = category,
        .status = .placeholder,
        .upstream_path = upstream_path,
        .pass = placeholder.make(name, category, upstream_path),
    };
}

fn boundaryNoopEntry(
    comptime name: []const u8,
    comptime category: pass_manager.PassCategory,
    comptime upstream_path: []const u8,
) PassRegistryEntry {
    return .{
        .name = name,
        .category = category,
        .status = .boundary_noop,
        .upstream_path = upstream_path,
        .pass = placeholder.makeBoundaryNoop(name, category, upstream_path),
    };
}

fn outOfScopeEntry(
    comptime name: []const u8,
    comptime category: pass_manager.PassCategory,
    comptime upstream_path: []const u8,
) PassRegistryEntry {
    return .{
        .name = name,
        .category = category,
        .status = .out_of_scope,
        .upstream_path = upstream_path,
        .pass = placeholder.makeOutOfScope(name, category, upstream_path),
    };
}

pub const pass_registry = [_]PassRegistryEntry{
    implemented(instcombine.pass),
    implemented(always_inline.pass),
    implemented(jump_threading.pass),
    implemented(correlated_propagation.pass),
    implemented(lower_expect.pass),
    implemented(verify.pass),
    implemented(dce.pass),
    implemented(dse.pass),
    implemented(adce.pass),
    implemented(bdce.pass),
    implemented(early_cse.pass),
    implemented(sccp.pass),
    implemented(gvn.pass),
    implemented(globalopt.pass),
    implemented(globaldce.pass),
    implemented(constmerge.pass),
    implemented(function_attrs.pass),
    implemented(inline_pass.pass),
    implemented(vector_combine.pass),
    conservative(slp_vectorizer.pass),
    implemented(licm.pass),
    implemented(loop_instsimplify.pass),
    implemented(loop_simplifycfg.pass),
    implemented(loop_rotate.pass),
    implemented(loop_deletion.pass),
    implemented(indvars.pass),
    implemented(simplifycfg.pass),
    implemented(mem2reg.pass),
    implemented(sroa.pass),
    conservative(canonicalize_aliases.pass),
    conservative(aggressive_instcombine.pass),
    conservative(lower_constant_intrinsics.pass),
    placeholderEntry("drop-unnecessary-assumes", .canonicalization, "llvm/lib/Transforms/Scalar/DropUnnecessaryAssumes.cpp"),
    placeholderEntry("tailcallelim", .codegen_prep, "llvm/lib/Transforms/Scalar/TailRecursionElimination.cpp"),
    placeholderEntry("div-rem-pairs", .codegen_prep, "llvm/lib/Transforms/Scalar/DivRemPairs.cpp"),
    placeholderEntry("float2int", .codegen_prep, "llvm/lib/Transforms/Scalar/Float2Int.cpp"),
    placeholderEntry("libcalls-shrinkwrap", .codegen_prep, "llvm/lib/Transforms/Utils/LibCallsShrinkWrap.cpp"),
    placeholderEntry("inject-tli-mappings", .codegen_prep, "llvm/lib/Transforms/Utils/InjectTLIMappings.cpp"),
    placeholderEntry("rel-lookup-table-converter", .codegen_prep, "llvm/lib/Transforms/Utils/RelLookupTableConverter.cpp"),
    placeholderEntry("memcpyopt", .memory, "llvm/lib/Transforms/Scalar/MemCpyOptimizer.cpp"),
    placeholderEntry("mldst-motion", .memory, "llvm/lib/Transforms/Scalar/MergedLoadStoreMotion.cpp"),
    placeholderEntry("infer-alignment", .memory, "llvm/lib/Transforms/Scalar/InferAlignment.cpp"),
    placeholderEntry("alignment-from-assumptions", .memory, "llvm/lib/Transforms/Scalar/AlignmentFromAssumptions.cpp"),
    placeholderEntry("move-auto-init", .memory, "llvm/lib/Transforms/Scalar/MoveAutoInit.cpp"),
    placeholderEntry("ipsccp", .ipo, "llvm/lib/Transforms/IPO/SCCP.cpp"),
    placeholderEntry("reassociate", .scalar, "llvm/lib/Transforms/Scalar/Reassociate.cpp"),
    placeholderEntry("constraint-elimination", .scalar, "llvm/lib/Transforms/Scalar/ConstraintElimination.cpp"),
    placeholderEntry("speculative-execution", .scalar, "llvm/lib/Transforms/Scalar/SpeculativeExecution.cpp"),
    placeholderEntry("simple-loop-unswitch", .loop, "llvm/lib/Transforms/Scalar/SimpleLoopUnswitch.cpp"),
    placeholderEntry("loop-idiom", .loop, "llvm/lib/Transforms/Scalar/LoopIdiomRecognize.cpp"),
    placeholderEntry("loop-sink", .loop, "llvm/lib/Transforms/Scalar/LoopSink.cpp"),
    placeholderEntry("loop-unroll", .loop, "llvm/lib/Transforms/Scalar/LoopUnrollPass.cpp"),
    placeholderEntry("loop-unroll-full", .loop, "llvm/lib/Transforms/Scalar/LoopUnrollPass.cpp"),
    placeholderEntry("loop-distribute", .loop, "llvm/lib/Transforms/Scalar/LoopDistribute.cpp"),
    placeholderEntry("loop-load-elim", .loop, "llvm/lib/Transforms/Scalar/LoopLoadElimination.cpp"),
    placeholderEntry("extra-simple-loop-unswitch-passes", .loop, "llvm/lib/Passes/PassBuilderPipelines.cpp"),
    placeholderEntry("ee-instrument", .instrumentation, "llvm/lib/Transforms/Utils/EntryExitInstrumenter.cpp"),
    placeholderEntry("alloc-token", .instrumentation, "llvm/lib/Transforms/Instrumentation/AllocToken.cpp"),
    outOfScopeEntry("annotation-remarks", .instrumentation, "llvm/lib/Transforms/Scalar/AnnotationRemarks.cpp"),
    outOfScopeEntry("add-discriminators", .instrumentation, "llvm/lib/Transforms/Utils/AddDiscriminators.cpp"),
    placeholderEntry("annotation2metadata", .instrumentation, "llvm/lib/Transforms/IPO/Annotation2Metadata.cpp"),
    placeholderEntry("sancov", .instrumentation, "llvm/lib/Transforms/Instrumentation/SanitizerCoverage.cpp"),
    placeholderEntry("module-tsan", .instrumentation, "llvm/lib/Transforms/Instrumentation/ThreadSanitizer.cpp"),
    placeholderEntry("tsan", .instrumentation, "llvm/lib/Transforms/Instrumentation/ThreadSanitizer.cpp"),
    placeholderEntry("memprof-remove-attributes", .instrumentation, "llvm/lib/Transforms/Instrumentation/MemProfUse.cpp"),
    placeholderEntry("cg-profile", .instrumentation, "llvm/lib/Transforms/Instrumentation/CGProfile.cpp"),
    placeholderEntry("chr", .instrumentation, "llvm/lib/Transforms/Instrumentation/ControlHeightReduction.cpp"),
    placeholderEntry("transform-warning", .instrumentation, "llvm/lib/Transforms/Scalar/WarnMissedTransforms.cpp"),
    placeholderEntry("loop-vectorize", .vector, "llvm/lib/Transforms/Vectorize/LoopVectorize.cpp"),
    placeholderEntry("coro-early", .ipo, "llvm/lib/Transforms/Coroutines/CoroEarly.cpp"),
    placeholderEntry("coro-split", .ipo, "llvm/lib/Transforms/Coroutines/CoroSplit.cpp"),
    placeholderEntry("coro-elide", .ipo, "llvm/lib/Transforms/Coroutines/CoroElide.cpp"),
    placeholderEntry("coro-cleanup", .ipo, "llvm/lib/Transforms/Coroutines/CoroCleanup.cpp"),
    placeholderEntry("coro-annotation-elide", .ipo, "llvm/lib/Transforms/Coroutines/CoroAnnotationElide.cpp"),
    placeholderEntry("openmp-opt", .ipo, "llvm/lib/Transforms/IPO/OpenMPOpt.cpp"),
    placeholderEntry("openmp-opt-cgscc", .ipo, "llvm/lib/Transforms/IPO/OpenMPOpt.cpp"),
    boundaryNoopEntry("forceattrs", .ipo, "llvm/lib/Transforms/IPO/ForceFunctionAttrs.cpp"),
    conservative(inferattrs.pass),
    placeholderEntry("rpo-function-attrs", .ipo, "llvm/lib/Transforms/IPO/FunctionAttrs.cpp"),
    placeholderEntry("argpromotion", .ipo, "llvm/lib/Transforms/IPO/ArgumentPromotion.cpp"),
    placeholderEntry("called-value-propagation", .ipo, "llvm/lib/Transforms/IPO/CalledValuePropagation.cpp"),
    placeholderEntry("callsite-splitting", .scalar, "llvm/lib/Transforms/Scalar/CallSiteSplitting.cpp"),
    placeholderEntry("deadargelim", .ipo, "llvm/lib/Transforms/IPO/DeadArgumentElimination.cpp"),
    placeholderEntry("elim-avail-extern", .ipo, "llvm/lib/Transforms/IPO/ElimAvailExtern.cpp"),
    placeholderEntry("recompute-globalsaa", .analysis, "llvm/lib/Analysis/GlobalsModRef.cpp"),
    placeholderEntry("globals-aa", .analysis, "llvm/lib/Analysis/GlobalsModRef.cpp"),
    boundaryNoopEntry("mergefunc", .ipo, "llvm/lib/Transforms/IPO/MergeFunctions.cpp"),
    placeholderEntry("name-anon-globals", .lto, "llvm/lib/Transforms/Utils/NameAnonGlobals.cpp"),
    placeholderEntry("require<globals-aa>", .analysis, "llvm/include/llvm/IR/PassManager.h"),
    placeholderEntry("invalidate<aa>", .analysis, "llvm/include/llvm/IR/PassManager.h"),
    placeholderEntry("require<profile-summary>", .analysis, "llvm/include/llvm/IR/PassManager.h"),
    placeholderEntry("require<branch-probability>", .analysis, "llvm/lib/Analysis/BranchProbabilityInfo.cpp"),
    placeholderEntry("require<block-frequency>", .analysis, "llvm/lib/Analysis/BlockFrequencyInfo.cpp"),
    placeholderEntry("require<should-not-run-function-passes>", .pipeline_guard, "llvm/lib/Passes/PassBuilderPipelines.cpp"),
};

pub fn findPass(name: []const u8) ?PassRegistryEntry {
    for (pass_registry) |entry| {
        if (std.mem.eql(u8, name, entry.name)) return entry;
    }
    return null;
}

pub fn summarizePipeline(pipeline: Pipeline) PassStatusCounts {
    var counts: PassStatusCounts = .{};
    for (pipeline.passes) |pass_name| {
        counts.note(if (findPass(pass_name)) |entry| entry.status else null);
    }
    return counts;
}

pub const PlaceholderBudget = struct {
    pipeline_name: []const u8,
    expected_placeholders: usize,
    expected_boundary_noop: usize = 0,
    expected_out_of_scope: usize = 0,
};

pub const placeholder_budgets = [_]PlaceholderBudget{
    .{ .pipeline_name = "release-o3", .expected_placeholders = 0, .expected_boundary_noop = 2, .expected_out_of_scope = 2 },
    .{ .pipeline_name = "release-oz", .expected_placeholders = 0, .expected_boundary_noop = 2, .expected_out_of_scope = 2 },
    .{ .pipeline_name = "lto-prelink-o3", .expected_placeholders = 1, .expected_boundary_noop = 1, .expected_out_of_scope = 1 },
    .{ .pipeline_name = "lto-prelink-oz", .expected_placeholders = 1, .expected_boundary_noop = 1, .expected_out_of_scope = 1 },
};

pub const release_policy_pipeline_names = [_][]const u8{
    "zig-release-safe-accepted",
    "zig-release-fast-accepted",
    "zig-release-small-accepted",
    "release-o3",
    "release-oz",
    "lto-prelink-o3",
    "lto-prelink-oz",
};

pub fn expectedPlaceholderBudget(pipeline_name: []const u8) ?usize {
    for (placeholder_budgets) |budget| {
        if (std.mem.eql(u8, pipeline_name, budget.pipeline_name)) return budget.expected_placeholders;
    }
    return null;
}

pub fn expectedReleasePolicyBudget(pipeline_name: []const u8) ?PlaceholderBudget {
    for (placeholder_budgets) |budget| {
        if (std.mem.eql(u8, pipeline_name, budget.pipeline_name)) return budget;
    }
    return null;
}

pub fn verifyPlaceholderBudgets() !void {
    for (placeholder_budgets) |budget| {
        const pipeline = find(budget.pipeline_name) orelse return error.UnknownPipeline;
        const counts = summarizePipeline(pipeline);
        if (counts.unknown != 0) return error.UnknownPass;
        if (counts.placeholder != budget.expected_placeholders) return error.PlaceholderBudgetChanged;
        if (counts.boundary_noop != budget.expected_boundary_noop) return error.PlaceholderBudgetChanged;
        if (counts.out_of_scope != budget.expected_out_of_scope) return error.PlaceholderBudgetChanged;
    }
}

fn addPass(pm: *pass_manager.ModulePassManager, name: []const u8) !void {
    const entry = findPass(name) orelse return error.UnknownPass;
    try pm.add(entry.pass);
}
