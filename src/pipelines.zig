const std = @import("std");
const pass_manager = @import("pass_manager.zig");
const adce = @import("passes/adce.zig");
const instcombine = @import("passes/instcombine.zig");
const dce = @import("passes/dce.zig");
const early_cse = @import("passes/early_cse.zig");
const gvn = @import("passes/gvn.zig");
const licm = @import("passes/licm.zig");
const mem2reg = @import("passes/mem2reg.zig");
const placeholder = @import("passes/placeholder.zig");
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
    "gvn",
    "dse",
    "adce",
    "licm",
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
    "gvn",
    "dse",
    "adce",
    "licm",
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
        .notes = "LTO-specific global canonicalization is represented by placeholders",
    },
    .{
        .name = "lto-prelink-oz",
        .passes = &lto_prelink_oz_passes,
        .mode = "ReleaseSmall LTO pre-link",
        .llvm_analogue = "PassBuilder::buildLTOPreLinkDefaultPipeline(Oz)",
        .intended_level = "Zig release LTO pre-link Oz",
        .notes = "LTO-specific global canonicalization is represented by placeholders",
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
    } else if (std.mem.eql(u8, name, "verify")) {
        try pm.add(verify.pass);
    } else if (std.mem.eql(u8, name, "dce")) {
        try pm.add(dce.pass);
    } else if (std.mem.eql(u8, name, "adce")) {
        try pm.add(adce.pass);
    } else if (std.mem.eql(u8, name, "early-cse")) {
        try pm.add(early_cse.pass);
    } else if (std.mem.eql(u8, name, "gvn")) {
        try pm.add(gvn.pass);
    } else if (std.mem.eql(u8, name, "licm")) {
        try pm.add(licm.pass);
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
    if (std.mem.eql(u8, name, "always-inline")) return placeholder.make("always-inline", .ipo, "llvm/lib/Transforms/IPO/AlwaysInliner.cpp");
    if (std.mem.eql(u8, name, "aggressive-instcombine")) return placeholder.make("aggressive-instcombine", .canonicalization, "llvm/lib/Transforms/AggressiveInstCombine/");
    if (std.mem.eql(u8, name, "lower-constant-intrinsics")) return placeholder.make("lower-constant-intrinsics", .canonicalization, "llvm/lib/Transforms/Scalar/LowerConstantIntrinsics.cpp");
    if (std.mem.eql(u8, name, "drop-unnecessary-assumes")) return placeholder.make("drop-unnecessary-assumes", .canonicalization, "llvm/lib/Transforms/Scalar/DropUnnecessaryAssumes.cpp");
    if (std.mem.eql(u8, name, "jump-threading")) return placeholder.make("jump-threading", .scalar, "llvm/lib/Transforms/Scalar/JumpThreading.cpp");
    if (std.mem.eql(u8, name, "correlated-propagation")) return placeholder.make("correlated-propagation", .scalar, "llvm/lib/Transforms/Scalar/CorrelatedValuePropagation.cpp");
    if (std.mem.eql(u8, name, "tailcallelim")) return placeholder.make("tailcallelim", .codegen_prep, "llvm/lib/Transforms/Scalar/TailRecursionElimination.cpp");
    if (std.mem.eql(u8, name, "ee-instrument")) return placeholder.make("ee-instrument", .instrumentation, "llvm/lib/Transforms/Utils/EntryExitInstrumenter.cpp");
    if (std.mem.eql(u8, name, "alloc-token")) return placeholder.make("alloc-token", .instrumentation, "llvm/lib/Transforms/Instrumentation/AllocToken.cpp");
    if (std.mem.eql(u8, name, "annotation-remarks")) return placeholder.make("annotation-remarks", .instrumentation, "llvm/lib/Transforms/Scalar/AnnotationRemarks.cpp");
    if (std.mem.eql(u8, name, "add-discriminators")) return placeholder.make("add-discriminators", .instrumentation, "llvm/lib/Transforms/Utils/AddDiscriminators.cpp");
    if (std.mem.eql(u8, name, "forceattrs")) return placeholder.make("forceattrs", .ipo, "llvm/lib/Transforms/IPO/ForceFunctionAttrs.cpp");
    if (std.mem.eql(u8, name, "inferattrs")) return placeholder.make("inferattrs", .ipo, "llvm/lib/Transforms/IPO/InferFunctionAttrs.cpp");
    if (std.mem.eql(u8, name, "function-attrs")) return placeholder.make("function-attrs", .ipo, "llvm/lib/Transforms/IPO/FunctionAttrs.cpp");
    if (std.mem.eql(u8, name, "rpo-function-attrs")) return placeholder.make("rpo-function-attrs", .ipo, "llvm/lib/Transforms/IPO/FunctionAttrs.cpp");
    if (std.mem.eql(u8, name, "dse")) return placeholder.make("dse", .memory, "llvm/lib/Transforms/Scalar/DeadStoreElimination.cpp");
    if (std.mem.eql(u8, name, "globalopt")) return placeholder.make("globalopt", .ipo, "llvm/lib/Transforms/IPO/GlobalOpt.cpp");
    if (std.mem.eql(u8, name, "globaldce")) return placeholder.make("globaldce", .ipo, "llvm/lib/Transforms/IPO/GlobalDCE.cpp");
    if (std.mem.eql(u8, name, "mergefunc")) return placeholder.make("mergefunc", .ipo, "llvm/lib/Transforms/IPO/MergeFunctions.cpp");
    if (std.mem.eql(u8, name, "canonicalize-aliases")) return placeholder.make("canonicalize-aliases", .lto, "llvm/lib/Transforms/Utils/CanonicalizeAliases.cpp");
    if (std.mem.eql(u8, name, "name-anon-globals")) return placeholder.make("name-anon-globals", .lto, "llvm/lib/Transforms/Utils/NameAnonGlobals.cpp");
    if (std.mem.eql(u8, name, "require<globals-aa>")) return placeholder.make("require<globals-aa>", .analysis, "llvm/include/llvm/IR/PassManager.h");
    if (std.mem.eql(u8, name, "invalidate<aa>")) return placeholder.make("invalidate<aa>", .analysis, "llvm/include/llvm/IR/PassManager.h");
    if (std.mem.eql(u8, name, "require<profile-summary>")) return placeholder.make("require<profile-summary>", .analysis, "llvm/include/llvm/IR/PassManager.h");
    if (std.mem.eql(u8, name, "require<should-not-run-function-passes>")) return placeholder.make("require<should-not-run-function-passes>", .pipeline_guard, "llvm/lib/Passes/PassBuilderPipelines.cpp");
    return null;
}
