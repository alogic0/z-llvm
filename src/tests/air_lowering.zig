const air_lowering_common = @import("air_lowering_common.zig");

const std = air_lowering_common.std;
const air_bridge = air_lowering_common.air_bridge;
const alias = air_lowering_common.alias;
const call_graph = air_lowering_common.call_graph;
const cfg = air_lowering_common.cfg;
const codegen = air_lowering_common.codegen;
const dominator = air_lowering_common.dominator;
const function_attrs = air_lowering_common.function_attrs;
const fp_semantics = air_lowering_common.fp_semantics;
const loop_info = air_lowering_common.loop_info;
const memory_effect = air_lowering_common.memory_effect;
const memory_location = air_lowering_common.memory_location;
const memory_ssa = air_lowering_common.memory_ssa;
const ir = air_lowering_common.ir;
const normalize = air_lowering_common.normalize;
const mc = air_lowering_common.mc;
const pass_manager = air_lowering_common.pass_manager;
const pipelines = air_lowering_common.pipelines;
const postdominator = air_lowering_common.postdominator;
const semantic_descriptor_v2 = air_lowering_common.semantic_descriptor_v2;
const target = air_lowering_common.target;
const target_library_info = air_lowering_common.target_library_info;
const target_transform_info = air_lowering_common.target_transform_info;
const instcombine = air_lowering_common.instcombine;
const zig_air_export = air_lowering_common.zig_air_export;
const zig_air_lowering = air_lowering_common.zig_air_lowering;
const dce = air_lowering_common.dce;
const dse = air_lowering_common.dse;
const early_cse = air_lowering_common.early_cse;
const gvn = air_lowering_common.gvn;
const licm = air_lowering_common.licm;
const mem2reg = air_lowering_common.mem2reg;
const sccp = air_lowering_common.sccp;
const simplifycfg = air_lowering_common.simplifycfg;
const slp_vectorizer = air_lowering_common.slp_vectorizer;
const sroa = air_lowering_common.sroa;

const air_lowering_slice_1 = @import("air_lowering_slice_1.zig");
const air_lowering_slice_2 = @import("air_lowering_slice_2.zig");

test {
    _ = air_lowering_slice_1;
    _ = air_lowering_slice_2;
}
