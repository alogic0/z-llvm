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

test "parser preserves address-space pointer function returns" {
    const input =
        \\define private fastcc ptr addrspace(256) @entry(ptr addrspace(256) align 4 %0) unnamed_addr #0 align 1 {
        \\entry:
        \\  %1 = alloca ptr addrspace(256), align 8
        \\  store ptr addrspace(256) %0, ptr %1, align 8
        \\  %2 = load ptr addrspace(256), ptr %1, align 8
        \\  %3 = getelementptr [4 x i8], ptr addrspace(256) %2, i64 0
        \\  ret ptr addrspace(256) %3
        \\}
        \\
        \\attributes #0 = { nounwind }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    try std.testing.expectEqualStrings("addrspace(256)", function.ret_attrs.?);
    try std.testing.expectEqualStrings("addrspace(256)", function.blocks.items[0].instructions.items[0].kind.alloca.allocated_ty_addrspace.?);
    try std.testing.expectEqualStrings("addrspace(256)", function.blocks.items[0].instructions.items[1].kind.store.ty_addrspace.?);
    try std.testing.expectEqualStrings("addrspace(256)", function.blocks.items[0].instructions.items[2].kind.load.ty_addrspace.?);
    try std.testing.expectEqualStrings("addrspace(256)", function.blocks.items[0].instructions.items[3].kind.gep.ptr_addrspace.?);
    try std.testing.expectEqualStrings("addrspace(256)", function.blocks.items[0].terminator.?.ret.ptr_addrspace.?);

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

test "parser preserves musttail and notail direct calls" {
    const input =
        \\declare i32 @callee(i32)
        \\
        \\declare void @sink()
        \\
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = musttail call i32 @callee(i32 %a)
        \\  notail call void @sink()
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const block = module.functions.items[0].blocks.items[0];
    try std.testing.expectEqualStrings("musttail", block.instructions.items[0].kind.call.tail_kind.?);
    try std.testing.expectEqualStrings("notail", block.instructions.items[1].kind.call.tail_kind.?);

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

test "verifier preserves unknown metadata nodes with valid references" {
    const input =
        \\define i32 @with_unknown_metadata(i32 %a) !dbg !1 {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\!0 = !{!"opaque", !1}
        \\!1 = distinct !DILocation(line: 1, column: 1, scope: !2)
        \\!2 = distinct !DISubprogram(name: "f", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1)
        \\!3 = !DIFile(filename: "opaque.zig", directory: ".")
        \\!4 = !DISubroutineType(types: !5)
        \\!5 = !{}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
}

test "verifier rejects dangling debug metadata references" {
    const input =
        \\define i32 @bad_debug_metadata(i32 %a) !dbg !4 {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\!4 = distinct !DISubprogram(name: "bad", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expectError(error.UnknownMetadata, module.verify());
}

test "verifier rejects impossible debug compile unit root" {
    const input =
        \\define i32 @bad_debug_cu(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!0 = !DIFile(filename: "not_cu.zig", directory: ".")
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expectError(error.InvalidDebugMetadata, module.verify());
}

test "verifier accepts sizeless debug basic types" {
    const input =
        \\define void @sizeless_basic_type() !dbg !4 {
        \\entry:
        \\  ret void
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!llvm.module.flags = !{!1}
        \\!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
        \\!1 = !{i32 2, !"Debug Info Version", i32 3}
        \\!2 = !DIFile(filename: "sizeless_basic_type.zig", directory: ".")
        \\!4 = distinct !DISubprogram(name: "sizeless_basic_type", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{!7}
        \\!7 = !DIBasicType(name: "void", encoding: DW_ATE_signed)
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
}

test "verifier accepts columnless debug locations" {
    const input =
        \\define void @columnless_location() !dbg !4 {
        \\entry:
        \\  ret void, !dbg !7
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!llvm.module.flags = !{!1}
        \\!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
        \\!1 = !{i32 2, !"Debug Info Version", i32 3}
        \\!2 = !DIFile(filename: "columnless_location.zig", directory: ".")
        \\!4 = distinct !DISubprogram(name: "columnless_location", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{}
        \\!7 = !DILocation(line: 0, scope: !4)
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
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

test "parser preserves debug value intrinsics as variable-location boundary" {
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

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const instruction = module.functions.items[0].blocks.items[0].instructions.items[0];
    const call = instruction.kind.call;
    try std.testing.expect(call.isDebugVariableLocation());
    try std.testing.expectEqualStrings("metadata i32 %a, metadata !9, metadata !DIExpression()", call.raw_args.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves debug declare intrinsics as variable-location boundary" {
    const input =
        \\declare void @llvm.dbg.declare(metadata, metadata, metadata)
        \\
        \\define void @debug_declare(ptr %p) !dbg !4 {
        \\entry:
        \\  call void @llvm.dbg.declare(metadata ptr %p, metadata !9, metadata !DIExpression()), !dbg !8
        \\  ret void
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
        \\!2 = !DIFile(filename: "debug_declare.zig", directory: ".")
        \\!4 = distinct !DISubprogram(name: "debug_declare", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{}
        \\!8 = !DILocation(line: 2, column: 5, scope: !4)
        \\!9 = !DILocalVariable(name: "p", arg: 1, scope: !4, file: !2, line: 1, type: !10)
        \\!10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !11, size: 64)
        \\!11 = !DIBasicType(name: "i32", size: 32, encoding: DW_ATE_signed)
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const instruction = module.functions.items[0].blocks.items[0].instructions.items[0];
    const call = instruction.kind.call;
    try std.testing.expect(call.isDebugVariableLocation());
    try std.testing.expectEqualStrings("metadata ptr %p, metadata !9, metadata !DIExpression()", call.raw_args.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser rejects unsupported debug assign intrinsic" {
    const input =
        \\declare void @llvm.dbg.assign(metadata, metadata, metadata, metadata, metadata, metadata)
        \\
        \\define void @debug_assign(i32 %a) {
        \\entry:
        \\  call void @llvm.dbg.assign(metadata i32 %a, metadata !0, metadata !DIExpression(), metadata !1, metadata ptr undef, metadata !DIExpression())
        \\  ret void
        \\}
        \\
        \\!0 = !DILocalVariable(name: "a")
        \\!1 = distinct !DIAssignID()
        \\
    ;

    try std.testing.expectError(error.UnsupportedDebugIntrinsic, ir.Module.parse(std.testing.allocator, input));
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

test "parser preserves observed scalar FP literal spellings without folding" {
    const input =
        \\define float @float_literal() {
        \\entry:
        \\  ret float 1.500000e+00
        \\}
        \\
        \\define double @double_literal() {
        \\entry:
        \\  ret double 2.250000e+00
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const float_ret = module.functions.items[0].blocks.items[0].terminator.?.ret.value.?;
    try std.testing.expectEqualStrings("1.500000e+00", float_ret.fp);
    const double_ret = module.functions.items[1].blocks.items[0].terminator.?.ret.value.?;
    try std.testing.expectEqualStrings("2.250000e+00", double_ret.fp);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser classifies special FP literal spellings without folding" {
    const input =
        \\define double @nan_literal() {
        \\entry:
        \\  ret double nan
        \\}
        \\
        \\define double @inf_literal() {
        \\entry:
        \\  ret double inf
        \\}
        \\
        \\define double @negative_zero_literal() {
        \\entry:
        \\  ret double -0.0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const nan_ret = module.functions.items[0].blocks.items[0].terminator.?.ret.value.?.fp;
    const inf_ret = module.functions.items[1].blocks.items[0].terminator.?.ret.value.?.fp;
    const neg_zero_ret = module.functions.items[2].blocks.items[0].terminator.?.ret.value.?.fp;
    try std.testing.expectEqual(fp_semantics.Category.nan, (try fp_semantics.classify(.double, nan_ret)).category);
    try std.testing.expectEqual(fp_semantics.Category.infinity, (try fp_semantics.classify(.double, inf_ret)).category);
    try std.testing.expectEqual(fp_semantics.Category.negative_zero, (try fp_semantics.classify(.double, neg_zero_ret)).category);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves fixed vector signatures and rejects unsupported vector boundaries" {
    const vector_add =
        \\define i32 @vector_add() {
        \\entry:
        \\  %v = add <2 x i32> undef, undef
        \\  ret i32 0
        \\}
        \\
    ;
    var vector_module = try ir.Module.parse(std.testing.allocator, vector_add);
    defer vector_module.deinit();
    try vector_module.verify();
    try std.testing.expect(vector_module.functions.items[0].blocks.items[0].instructions.items[0].kind.binary.ty.eql(.{ .vector = .{
        .len = 2,
        .elem_ty = .{ .int = 32 },
    } }));

    var printed: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer printed.deinit();
    try vector_module.print(&printed.writer);
    try std.testing.expectEqualStrings(vector_add, printed.writer.buffered());

    const shuffle =
        \\define i32 @shuffle() {
        \\entry:
        \\  %v = shufflevector <2 x i32> undef, <2 x i32> undef, <2 x i32> zeroinitializer
        \\  ret i32 0
        \\}
        \\
    ;
    var shuffle_module = try ir.Module.parse(std.testing.allocator, shuffle);
    defer shuffle_module.deinit();
    try shuffle_module.verify();

    const insert =
        \\define i32 @insert_lane(i32 %a) {
        \\entry:
        \\  %v = insertelement <2 x i32> undef, i32 %a, i32 0
        \\  ret i32 0
        \\}
        \\
    ;
    var insert_module = try ir.Module.parse(std.testing.allocator, insert);
    defer insert_module.deinit();
    try insert_module.verify();

    const extract =
        \\define i32 @extract_lane() {
        \\entry:
        \\  %v = extractelement <2 x i32> undef, i32 0
        \\  ret i32 0
        \\}
        \\
    ;
    var extract_module = try ir.Module.parse(std.testing.allocator, extract);
    defer extract_module.deinit();
    try extract_module.verify();

    const half_insert_extract =
        \\define half @half_lane(half %a) {
        \\entry:
        \\  %v = insertelement <4 x half> poison, half %a, i64 0
        \\  %r = extractelement <4 x half> %v, i64 0
        \\  ret half %r
        \\}
        \\
    ;
    var half_module = try ir.Module.parse(std.testing.allocator, half_insert_extract);
    defer half_module.deinit();
    try half_module.verify();

    var half_printed: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer half_printed.deinit();
    try half_module.print(&half_printed.writer);
    try std.testing.expectEqualStrings(half_insert_extract, half_printed.writer.buffered());

    const fp128_insert_extract =
        \\define fp128 @fp128_lane(fp128 %a) {
        \\entry:
        \\  %v = insertelement <4 x fp128> poison, fp128 %a, i64 0
        \\  %r = extractelement <4 x fp128> %v, i64 0
        \\  ret fp128 %r
        \\}
        \\
    ;
    var fp128_module = try ir.Module.parse(std.testing.allocator, fp128_insert_extract);
    defer fp128_module.deinit();
    try fp128_module.verify();

    var fp128_printed: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer fp128_printed.deinit();
    try fp128_module.print(&fp128_printed.writer);
    try std.testing.expectEqualStrings(fp128_insert_extract, fp128_printed.writer.buffered());

    const vector_constant =
        \\define <2 x i32> @vector_constant() {
        \\entry:
        \\  %v = freeze <2 x i32> <i32 1, i32 2>
        \\  ret <2 x i32> %v
        \\}
        \\
    ;
    var constant_module = try ir.Module.parse(std.testing.allocator, vector_constant);
    defer constant_module.deinit();
    try constant_module.verify();

    const vector_splat =
        \\define i1 @vector_splat_icmp(<16 x i8> %a) {
        \\entry:
        \\  %cmp = icmp eq <16 x i8> %a, splat (i8 10)
        \\  ret i1 1
        \\}
        \\
    ;
    var splat_module = try ir.Module.parse(std.testing.allocator, vector_splat);
    defer splat_module.deinit();
    try splat_module.verify();

    var splat_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer splat_output.deinit();
    try splat_module.print(&splat_output.writer);
    try std.testing.expectEqualStrings(vector_splat, splat_output.writer.buffered());

    const vector_compare_mask_bitcast =
        \\define i16 @vector_compare_mask_bitcast(<16 x i8> %a) {
        \\entry:
        \\  %cmp = icmp eq <16 x i8> %a, splat (i8 10)
        \\  %bits = bitcast <16 x i1> %cmp to i16
        \\  ret i16 %bits
        \\}
        \\
    ;
    var mask_bitcast_module = try ir.Module.parse(std.testing.allocator, vector_compare_mask_bitcast);
    defer mask_bitcast_module.deinit();
    try mask_bitcast_module.verify();
    try std.testing.expect(mask_bitcast_module.functions.items[0].blocks.items[0].instructions.items[0].resultType().?.eql(.{ .vector = .{
        .len = 16,
        .elem_ty = .{ .int = 1 },
    } }));

    var mask_bitcast_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer mask_bitcast_output.deinit();
    try mask_bitcast_module.print(&mask_bitcast_output.writer);
    try std.testing.expectEqualStrings(vector_compare_mask_bitcast, mask_bitcast_output.writer.buffered());

    const vector_select =
        \\define <16 x i4> @vector_select(<16 x i1> %mask, <16 x i4> %a, <16 x i4> %b) {
        \\entry:
        \\  %r = select <16 x i1> %mask, <16 x i4> %a, <16 x i4> %b
        \\  ret <16 x i4> %r
        \\}
        \\
    ;
    var vector_select_module = try ir.Module.parse(std.testing.allocator, vector_select);
    defer vector_select_module.deinit();
    try vector_select_module.verify();

    var vector_select_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer vector_select_output.deinit();
    try vector_select_module.print(&vector_select_output.writer);
    try std.testing.expectEqualStrings(vector_select, vector_select_output.writer.buffered());

    const bad_vector_select =
        \\define <8 x i4> @bad_vector_select(<16 x i1> %mask, <8 x i4> %a, <8 x i4> %b) {
        \\entry:
        \\  %r = select <16 x i1> %mask, <8 x i4> %a, <8 x i4> %b
        \\  ret <8 x i4> %r
        \\}
        \\
    ;
    var bad_vector_select_module = try ir.Module.parse(std.testing.allocator, bad_vector_select);
    defer bad_vector_select_module.deinit();
    try std.testing.expectError(error.SelectConditionTypeMismatch, bad_vector_select_module.verify());

    const bad_vector_splat =
        \\define i1 @bad_vector_splat_icmp(<16 x i8> %a) {
        \\entry:
        \\  %cmp = icmp eq <16 x i8> %a, splat (i16 10)
        \\  ret i1 1
        \\}
        \\
    ;
    var bad_splat_module = try ir.Module.parse(std.testing.allocator, bad_vector_splat);
    defer bad_splat_module.deinit();
    try std.testing.expectError(error.TypeMismatch, bad_splat_module.verify());

    const scalable =
        \\define <vscale x 2 x i32> @scalable(<vscale x 2 x i32> %a) {
        \\entry:
        \\  ret <vscale x 2 x i32> %a
        \\}
        \\
    ;
    try std.testing.expectError(error.InvalidFunctionHeader, ir.Module.parse(std.testing.allocator, scalable));

    const unsupported_element =
        \\define <2 x { i32 }> @bad_elem(<2 x { i32 }> %a) {
        \\entry:
        \\  ret <2 x { i32 }> %a
        \\}
        \\
    ;
    try std.testing.expectError(error.InvalidFunctionHeader, ir.Module.parse(std.testing.allocator, unsupported_element));

    const mismatch =
        \\define <2 x i32> @mismatch() {
        \\entry:
        \\  ret <2 x i32> 0
        \\}
        \\
    ;
    var mismatch_module = try ir.Module.parse(std.testing.allocator, mismatch);
    defer mismatch_module.deinit();
    try std.testing.expectError(error.TypeMismatch, mismatch_module.verify());

    const bad_lane =
        \\define i32 @bad_lane(<2 x i32> %a) {
        \\entry:
        \\  %v = extractelement <2 x i32> %a, i32 2
        \\  ret i32 %v
        \\}
        \\
    ;
    var bad_lane_module = try ir.Module.parse(std.testing.allocator, bad_lane);
    defer bad_lane_module.deinit();
    try std.testing.expectError(error.TypeMismatch, bad_lane_module.verify());

    const bad_shuffle =
        \\define <2 x i32> @bad_shuffle(<2 x i32> %a, <2 x i32> %b) {
        \\entry:
        \\  %v = shufflevector <2 x i32> %a, <2 x i32> %b, <2 x i32> <i32 0, i32 4>
        \\  ret <2 x i32> %v
        \\}
        \\
    ;
    var bad_shuffle_module = try ir.Module.parse(std.testing.allocator, bad_shuffle);
    defer bad_shuffle_module.deinit();
    try std.testing.expectError(error.TypeMismatch, bad_shuffle_module.verify());
}
