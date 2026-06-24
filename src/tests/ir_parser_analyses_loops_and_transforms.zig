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
    try std.testing.expectEqualSlices(usize, &.{2}, exiting.items);

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

test "licm hoists invariant aligned header loads when memory is not clobbered" {
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
    const expected =
        \\define i32 @licm_aligned_load_reject(i32 %a, ptr %p) {
        \\entry:
        \\  %v = load i32, ptr %p, align 4
        \\  %c = icmp sgt i32 %v, 0
        \\  br label %header
        \\header:
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
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
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
        \\  store atomic i32 %a, ptr %p release, align 4
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
