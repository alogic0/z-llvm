pub const std = @import("std");
pub const air_bridge = @import("../air_bridge.zig");
pub const alias = @import("../analysis/alias.zig");
pub const call_graph = @import("../analysis/call_graph.zig");
pub const cfg = @import("../analysis/cfg.zig");
pub const codegen = @import("../codegen.zig");
pub const dominator = @import("../analysis/dominator.zig");
pub const function_attrs = @import("../analysis/function_attrs.zig");
pub const fp_semantics = @import("../analysis/fp_semantics.zig");
pub const loop_info = @import("../analysis/loop_info.zig");
pub const memory_effect = @import("../analysis/memory_effect.zig");
pub const memory_location = @import("../analysis/memory_location.zig");
pub const memory_ssa = @import("../analysis/memory_ssa.zig");
pub const ir = @import("../ir.zig");
pub const normalize = @import("../normalize.zig");
pub const mc = @import("../mc.zig");
pub const pass_manager = @import("../pass_manager.zig");
pub const pipelines = @import("../pipelines.zig");
pub const postdominator = @import("../analysis/postdominator.zig");
pub const semantic_descriptor_v2 = @import("../semantic_descriptor_v2.zig");
pub const target = @import("../target.zig");
pub const target_library_info = @import("../analysis/target_library_info.zig");
pub const target_transform_info = @import("../analysis/target_transform_info.zig");
pub const instcombine = @import("../passes/instcombine.zig");
pub const zig_air_export = @import("../zig_air_export.zig");
pub const zig_air_lowering = @import("../zig_air_lowering.zig");
pub const dce = @import("../passes/dce.zig");
pub const dse = @import("../passes/dse.zig");
pub const early_cse = @import("../passes/early_cse.zig");
pub const gvn = @import("../passes/gvn.zig");
pub const licm = @import("../passes/licm.zig");
pub const mem2reg = @import("../passes/mem2reg.zig");
pub const sccp = @import("../passes/sccp.zig");
pub const simplifycfg = @import("../passes/simplifycfg.zig");
pub const slp_vectorizer = @import("../passes/slp_vectorizer.zig");
pub const sroa = @import("../passes/sroa.zig");

pub fn expectMachineInstruction(instructions: []const codegen.x86_64.Instruction, expected: codegen.x86_64.Instruction) !void {
    for (instructions) |instruction| {
        if (std.meta.eql(instruction, expected)) return;
    }
    return error.TestExpectedEqual;
}

test {
    _ = std;
    _ = air_bridge;
    _ = alias;
    _ = call_graph;
    _ = cfg;
    _ = codegen;
    _ = dominator;
    _ = function_attrs;
    _ = fp_semantics;
    _ = loop_info;
    _ = memory_effect;
    _ = memory_location;
    _ = memory_ssa;
    _ = ir;
    _ = normalize;
    _ = mc;
    _ = pass_manager;
    _ = pipelines;
    _ = postdominator;
    _ = semantic_descriptor_v2;
    _ = target;
    _ = target_library_info;
    _ = target_transform_info;
    _ = instcombine;
    _ = zig_air_export;
    _ = zig_air_lowering;
    _ = dce;
    _ = dse;
    _ = early_cse;
    _ = gvn;
    _ = licm;
    _ = mem2reg;
    _ = sccp;
    _ = simplifycfg;
    _ = slp_vectorizer;
    _ = sroa;
    _ = expectMachineInstruction;
}
