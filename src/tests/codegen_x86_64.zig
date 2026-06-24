const codegen_x86_64_common = @import("codegen_x86_64_common.zig");

const std = codegen_x86_64_common.std;
const air_bridge = codegen_x86_64_common.air_bridge;
const alias = codegen_x86_64_common.alias;
const call_graph = codegen_x86_64_common.call_graph;
const cfg = codegen_x86_64_common.cfg;
const codegen = codegen_x86_64_common.codegen;
const dominator = codegen_x86_64_common.dominator;
const function_attrs = codegen_x86_64_common.function_attrs;
const fp_semantics = codegen_x86_64_common.fp_semantics;
const loop_info = codegen_x86_64_common.loop_info;
const memory_effect = codegen_x86_64_common.memory_effect;
const memory_location = codegen_x86_64_common.memory_location;
const memory_ssa = codegen_x86_64_common.memory_ssa;
const ir = codegen_x86_64_common.ir;
const normalize = codegen_x86_64_common.normalize;
const mc = codegen_x86_64_common.mc;
const pass_manager = codegen_x86_64_common.pass_manager;
const pipelines = codegen_x86_64_common.pipelines;
const postdominator = codegen_x86_64_common.postdominator;
const semantic_descriptor_v2 = codegen_x86_64_common.semantic_descriptor_v2;
const target = codegen_x86_64_common.target;
const target_library_info = codegen_x86_64_common.target_library_info;
const target_transform_info = codegen_x86_64_common.target_transform_info;
const instcombine = codegen_x86_64_common.instcombine;
const zig_air_export = codegen_x86_64_common.zig_air_export;
const zig_air_lowering = codegen_x86_64_common.zig_air_lowering;
const dce = codegen_x86_64_common.dce;
const dse = codegen_x86_64_common.dse;
const early_cse = codegen_x86_64_common.early_cse;
const gvn = codegen_x86_64_common.gvn;
const licm = codegen_x86_64_common.licm;
const mem2reg = codegen_x86_64_common.mem2reg;
const sccp = codegen_x86_64_common.sccp;
const simplifycfg = codegen_x86_64_common.simplifycfg;
const slp_vectorizer = codegen_x86_64_common.slp_vectorizer;
const sroa = codegen_x86_64_common.sroa;
const expectMachineInstruction = codegen_x86_64_common.expectMachineInstruction;

const codegen_x86_64_slice_1_assembly = @import("codegen_x86_64_slice_1_assembly.zig");
const codegen_x86_64_slice_1_encoding = @import("codegen_x86_64_slice_1_encoding.zig");
const codegen_x86_64_slice_1_elf = @import("codegen_x86_64_slice_1_elf.zig");
const codegen_x86_64_slice_1_aggregates = @import("codegen_x86_64_slice_1_aggregates.zig");
const codegen_x86_64_slice_1_calls = @import("codegen_x86_64_slice_1_calls.zig");
const codegen_x86_64_slice_2 = @import("codegen_x86_64_slice_2.zig");
const codegen_x86_64_slice_3 = @import("codegen_x86_64_slice_3.zig");

test {
    _ = codegen_x86_64_slice_1_assembly;
    _ = codegen_x86_64_slice_1_encoding;
    _ = codegen_x86_64_slice_1_elf;
    _ = codegen_x86_64_slice_1_aggregates;
    _ = codegen_x86_64_slice_1_calls;
    _ = codegen_x86_64_slice_2;
    _ = codegen_x86_64_slice_3;
}
