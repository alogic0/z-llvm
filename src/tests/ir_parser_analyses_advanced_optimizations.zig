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

test "early-cse preserves operand-bundled readnone calls conservatively" {
    const input =
        \\declare i32 @pure() #0
        \\
        \\define i32 @cse_bundled_readnone_call() {
        \\entry:
        \\  %x = call i32 @pure() [ "cold"() ]
        \\  %y = call i32 @pure() [ "deopt"() ]
        \\  %z = add i32 %x, %y
        \\  ret i32 %z
        \\}
        \\
        \\attributes #0 = { memory(none) nounwind }
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

    try std.testing.expectEqualStrings(input, output.writer.buffered());
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

test "slp vectorizer recognizes same-op scalar bundles and reports unsupported transform" {
    const input =
        \\define i32 @slp_seed(i32 %a, i32 %b, i32 %c, i32 %d) {
        \\entry:
        \\  %x0 = add i32 %a, %b
        \\  %x1 = add i32 %c, %d
        \\  %sum = add i32 %x0, %x1
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    const candidate = slp_vectorizer.findCandidate(module.functions.items[0]) orelse return error.ExpectedSlpCandidate;
    try std.testing.expectEqualStrings("slp_seed", candidate.function_name);
    try std.testing.expectEqualStrings("entry", candidate.block_name);
    try std.testing.expectEqualStrings("x0", candidate.first_result);
    try std.testing.expectEqualStrings("x1", candidate.second_result);
    try std.testing.expectEqual(ir.BinaryOp.add, candidate.opcode);
    try std.testing.expectEqual(@as(usize, 2), candidate.lanes);

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(slp_vectorizer.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    const result = try pm.run(&module, &context, &output.writer, false);
    try std.testing.expectEqual(pass_manager.PassResult.unchanged, result);
    try std.testing.expectEqual(@as(usize, 1), context.diagnostic_count);
    const diagnostic = context.last_diagnostic orelse return error.ExpectedSlpDiagnostic;
    try std.testing.expectEqualStrings("slp-vectorizer", diagnostic.pass_name);
    try std.testing.expectEqualStrings("slp_seed", diagnostic.function_name);
    try std.testing.expectEqualStrings("x0", diagnostic.value_name.?);
    try std.testing.expectEqualStrings(slp_vectorizer.diagnostic_message, diagnostic.message);
}
