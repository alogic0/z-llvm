const std = @import("std");
const pass_manager = @import("pass_manager.zig");
const adce = @import("passes/adce.zig");
const instcombine = @import("passes/instcombine.zig");
const dce = @import("passes/dce.zig");
const early_cse = @import("passes/early_cse.zig");
const gvn = @import("passes/gvn.zig");
const licm = @import("passes/licm.zig");
const mem2reg = @import("passes/mem2reg.zig");
const simplifycfg = @import("passes/simplifycfg.zig");
const sroa = @import("passes/sroa.zig");

pub const Pipeline = struct {
    name: []const u8,
    passes: []const []const u8,
    llvm_analogue: []const u8,
    intended_level: []const u8,
    notes: []const u8,
};

const scalar_foundation_passes = [_][]const u8{
    "simplifycfg",
    "instcombine",
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

pub const all = [_]Pipeline{
    .{
        .name = "scalar-foundation",
        .passes = &scalar_foundation_passes,
        .llvm_analogue = "early scalar cleanup pipeline slices from InstCombine, SimplifyCFG, EarlyCSE, GVN, DCE, and ADCE",
        .intended_level = "phase-zero scalar optimization foundation",
        .notes = "conservative subset without target data layout, calls, vectors, or full poison semantics",
    },
    .{
        .name = "memory-foundation",
        .passes = &memory_foundation_passes,
        .llvm_analogue = "SROA/PromoteMemToReg-oriented stack cleanup plus DCE",
        .intended_level = "phase-zero stack-memory cleanup foundation",
        .notes = "direct stack-slot and zero-offset GEP subset only; no MemorySSA or general memory motion",
    },
};

pub fn find(name: []const u8) ?Pipeline {
    for (all) |pipeline| {
        if (std.mem.eql(u8, name, pipeline.name)) return pipeline;
    }
    return null;
}

pub fn addPasses(pm: *pass_manager.ModulePassManager, pass_list: []const u8) !void {
    var names = std.mem.splitScalar(u8, pass_list, ',');
    while (names.next()) |raw_name| {
        const name = std.mem.trim(u8, raw_name, " \t");
        if (name.len == 0) continue;
        if (find(name)) |pipeline| {
            for (pipeline.passes) |pass_name| try addPass(pm, pass_name);
        } else {
            try addPass(pm, name);
        }
    }
}

fn addPass(pm: *pass_manager.ModulePassManager, name: []const u8) !void {
    if (std.mem.eql(u8, name, "instcombine")) {
        try pm.add(instcombine.pass);
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
    } else {
        return error.UnknownPass;
    }
}
