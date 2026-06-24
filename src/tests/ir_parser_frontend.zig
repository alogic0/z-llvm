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
test "parser preserves inert branch metadata attachments" {
    const input =
        \\define void @loop_metadata(i1 %cond) {
        \\entry:
        \\  br i1 %cond, label %loop, label %exit
        \\loop:
        \\  br i1 %cond, label %loop, label %exit, !llvm.loop !0
        \\exit:
        \\  ret void
        \\}
        \\
        \\!0 = distinct !{!0}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves quoted branch labels containing commas" {
    const input =
        \\define i32 @quoted_branch(i1 %cond) {
        \\entry:
        \\  br i1 %cond, label %"left,with,comma", label %"right,with,comma"
        \\"left,with,comma":
        \\  ret i32 1
        \\"right,with,comma":
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves alias metadata attachments opaquely" {
    const input =
        \\define i32 @alias_metadata(ptr %a, ptr %b) {
        \\entry:
        \\  %x = load i32, ptr %a, align 4, !tbaa !0, !alias.scope !3, !noalias !6
        \\  store i32 %x, ptr %b, align 4, !tbaa !0, !alias.scope !6, !noalias !3
        \\  %y = load ptr, ptr %b, align 8, !nonnull !8, !noundef !8
        \\  %z = select i1 1, i32 %x, i32 0, !unpredictable !8
        \\  ret i32 %x
        \\}
        \\
        \\!0 = !{!1, !1, i64 0}
        \\!1 = !{!"int", !2}
        \\!2 = !{!"Simple C/C++ TBAA"}
        \\!3 = !{!4}
        \\!4 = distinct !{!4, !5}
        \\!5 = distinct !{!5}
        \\!6 = !{!7}
        \\!7 = distinct !{!7, !5}
        \\!8 = !{}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings("!tbaa !0, !alias.scope !3, !noalias !6", module.functions.items[0].blocks.items[0].instructions.items[0].metadata.?);
    try std.testing.expectEqualStrings("!tbaa !0, !alias.scope !6, !noalias !3", module.functions.items[0].blocks.items[0].instructions.items[1].metadata.?);
    try std.testing.expectEqualStrings("!nonnull !8, !noundef !8", module.functions.items[0].blocks.items[0].instructions.items[2].metadata.?);
    try std.testing.expectEqualStrings("!unpredictable !8", module.functions.items[0].blocks.items[0].instructions.items[3].metadata.?);
    try std.testing.expectEqual(@as(usize, 9), module.metadata.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser rejects unsupported instruction metadata attachments" {
    const input =
        \\define i32 @unsupported_metadata(ptr %p) {
        \\entry:
        \\  %x = load i32, ptr %p, align 4, !range !0
        \\  ret i32 %x
        \\}
        \\
        \\!0 = !{i32 0, i32 10}
        \\
    ;

    try std.testing.expectError(error.UnsupportedInstructionMetadata, ir.Module.parse(std.testing.allocator, input));
}

test "parser drops non-semantic debug records" {
    const input =
        \\define i32 @debug_record(ptr %p) !dbg !4 {
        \\entry:
        \\  #dbg_declare(ptr %p, !8, !DIExpression(), !9)
        \\  ret i32 0, !dbg !9
        \\}
        \\
        \\!llvm.dbg.cu = !{!0}
        \\!llvm.module.flags = !{!1}
        \\!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
        \\!1 = !{i32 2, !"Debug Info Version", i32 3}
        \\!2 = !DIFile(filename: "debug_record.zig", directory: ".")
        \\!4 = distinct !DISubprogram(name: "debug_record", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{}
        \\!8 = !DILocalVariable(name: "p", arg: 1, scope: !4, file: !2, line: 1, type: !5)
        \\!9 = !DILocation(line: 1, column: 1, scope: !4)
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(@as(usize, 0), module.functions.items[0].blocks.items[0].instructions.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqual(null, std.mem.indexOf(u8, output.writer.buffered(), "#dbg_declare"));
}

test "parser accepts unreachable metadata" {
    const input =
        \\define void @unreachable_metadata() {
        \\entry:
        \\  unreachable, !dbg !0
        \\}
        \\
        \\!0 = !DILocation(line: 1, column: 1, scope: !1)
        \\!1 = distinct !DISubprogram(name: "unreachable_metadata", file: !2, type: !3)
        \\!2 = !DIFile(filename: "unreachable_metadata.zig", directory: ".")
        \\!3 = !DISubroutineType(types: !4)
        \\!4 = !{}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
}

test "parser accepts return metadata" {
    const input =
        \\define i32 @return_metadata() {
        \\entry:
        \\  ret i32 0, !dbg !0
        \\}
        \\
        \\!0 = !DILocation(line: 1, column: 1, scope: !1)
        \\!1 = distinct !DISubprogram(name: "return_metadata", file: !2, type: !3)
        \\!2 = !DIFile(filename: "return_metadata.zig", directory: ".")
        \\!3 = !DISubroutineType(types: !4)
        \\!4 = !{}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
}

test "parser preserves Zig raw aliases and attribute groups" {
    const input =
        \\source_filename = "tiny_scalar"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@add = alias i32 (i32, i32), ptr @tiny_scalar.add
        \\
        \\define private i32 @tiny_scalar.add(i32 %0, i32 %1) unnamed_addr #0 align 1 {
        \\entry:
        \\  %2 = add nsw i32 %1, %0
        \\  ret i32 %2
        \\}
        \\
        \\attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" }
        \\
        \\!llvm.module.flags = !{}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 1), module.aliases.items.len);
    try std.testing.expectEqualStrings("add", module.aliases.items[0].name);
    try std.testing.expectEqualStrings("i32 (i32, i32)", module.aliases.items[0].aliased_ty);
    try std.testing.expectEqualStrings("tiny_scalar.add", module.aliases.items[0].target);
    try std.testing.expectEqual(@as(usize, 1), module.attribute_groups.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser rejects unsupported sanitizer attribute groups explicitly" {
    const input =
        \\define void @with_sanitizer() #0 {
        \\entry:
        \\  ret void
        \\}
        \\
        \\attributes #0 = { sanitize_address }
        \\
    ;

    try std.testing.expectError(error.UnsupportedAttributeGroup, ir.Module.parse(std.testing.allocator, input));
}

test "parser preserves nosanitize coverage attribute group" {
    const input =
        \\define void @without_coverage() #0 {
        \\entry:
        \\  ret void
        \\}
        \\
        \\attributes #0 = { nosanitize_coverage nounwind }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser rejects sanitizer instrumentation calls explicitly" {
    const sanitizer_call =
        \\declare void @__sanitizer_cov_trace_pc_guard(ptr)
        \\
        \\define void @instrumented(ptr %guard) {
        \\entry:
        \\  call void @__sanitizer_cov_trace_pc_guard(ptr %guard)
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedInstrumentationCall, ir.Module.parse(std.testing.allocator, sanitizer_call));

    const tsan_call =
        \\declare void @__tsan_read4(ptr)
        \\
        \\define void @instrumented_tsan(ptr %p) {
        \\entry:
        \\  call void @__tsan_read4(ptr %p)
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedInstrumentationCall, ir.Module.parse(std.testing.allocator, tsan_call));

    const ubsan_call =
        \\declare void @__ubsan_handle_add_overflow(ptr, i64, i64)
        \\
        \\define void @instrumented_ubsan(ptr %data, i64 %lhs, i64 %rhs) {
        \\entry:
        \\  call void @__ubsan_handle_add_overflow(ptr %data, i64 %lhs, i64 %rhs)
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedInstrumentationCall, ir.Module.parse(std.testing.allocator, ubsan_call));
}

test "parser preserves llvm trap intrinsic call" {
    const trap_call =
        \\declare void @llvm.trap()
        \\
        \\define void @safety_trap() {
        \\entry:
        \\  call void @llvm.trap()
        \\  unreachable
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, trap_call);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("llvm.trap", call.callee);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(trap_call, output.writer.buffered());
}

test "parser preserves quoted direct callee names containing parentheses" {
    const input =
        \\define private fastcc void @"log.scoped(.default).err__anon_3522"(i16 %.0.val) unnamed_addr #0 align 1 {
        \\entry:
        \\  ret void
        \\}
        \\
        \\define void @caller(i16 %code) {
        \\entry:
        \\  call fastcc void @"log.scoped(.default).err__anon_3522"(i16 %code)
        \\  ret void
        \\}
        \\
        \\attributes #0 = { nounwind }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[1].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("\"log.scoped(.default).err__anon_3522\"", call.callee);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier preserves ReleaseSafe runtime call trap boundary" {
    const input =
        \\source_filename = "release_safe_call_boundary"
        \\
        \\declare void @zig_panic(ptr)
        \\
        \\define void @release_safe_call_boundary(i1 %ok, ptr %msg) {
        \\entry:
        \\  br i1 %ok, label %cont, label %panic, !prof !0
        \\panic:
        \\  call void @zig_panic(ptr %msg)
        \\  unreachable
        \\cont:
        \\  ret void
        \\}
        \\
        \\!0 = !{!"branch_weights", i32 1000, i32 1}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const panic_block = module.functions.items[0].blocks.items[1];
    try std.testing.expectEqual(@as(usize, 1), panic_block.instructions.items.len);
    try std.testing.expect(panic_block.instructions.items[0].kind == .call);
    try std.testing.expect(panic_block.terminator.? == .@"unreachable");

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier rejects direct call signature mismatch" {
    const input =
        \\declare i32 @callee(i32)
        \\
        \\define i32 @caller(ptr %p) {
        \\entry:
        \\  %r = call i32 @callee(ptr %p)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.CallSignatureMismatch, module.verify());
}

test "verifier rejects direct call calling convention mismatch" {
    const input =
        \\declare fastcc i32 @callee(i32)
        \\
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = call i32 @callee(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.CallSignatureMismatch, module.verify());
}

test "verifier accepts matching declaration and definition" {
    const input =
        \\declare i32 @callee(i32)
        \\
        \\define i32 @callee(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = call i32 @callee(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try module.verify();
}

test "call graph records direct call edges once" {
    const input =
        \\declare i32 @extern(i32)
        \\
        \\define i32 @helper(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %x = call i32 @helper(i32 %a)
        \\  %y = call i32 @helper(i32 %x)
        \\  %z = call i32 @extern(i32 %y)
        \\  ret i32 %z
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var graph = try call_graph.CallGraph.build(std.testing.allocator, module);
    defer graph.deinit();

    const callees = graph.calleesOf("caller") orelse return error.MissingCallGraphNode;
    try std.testing.expectEqual(@as(usize, 2), callees.len);
    try std.testing.expect(graph.hasDirectEdge("caller", "helper"));
    try std.testing.expect(graph.hasDirectEdge("caller", "extern"));
    try std.testing.expect(!graph.hasDirectEdge("helper", "extern"));
    try std.testing.expect(graph.hasDefinition("caller"));
    try std.testing.expect(graph.hasDefinition("helper"));
    try std.testing.expect(graph.hasDeclaration("extern"));
    try std.testing.expect(graph.isKnownCallee("extern"));

    const roots = [_][]const u8{"caller"};
    var reachable = try graph.reachableDefinitionsFromRoots(std.testing.allocator, &roots);
    defer reachable.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 2), reachable.items.len);
    try std.testing.expect(containsText(reachable.items, "caller"));
    try std.testing.expect(containsText(reachable.items, "helper"));
    try std.testing.expect(!containsText(reachable.items, "extern"));
}

test "function attributes classify direct call memory effects conservatively" {
    const input =
        \\declare i32 @pure(i32) readnone
        \\declare i32 @reads(ptr) readonly
        \\declare void @writes(ptr) writeonly
        \\declare i32 @unknown(i32)
        \\
        \\define i32 @caller(ptr %p, i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  %y = call i32 @reads(ptr %p)
        \\  call void @writes(ptr %p)
        \\  %z = call i32 @unknown(i32 %y)
        \\  ret i32 %z
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const block = module.functions.items[0].blocks.items[0];

    const pure_call = block.instructions.items[0].kind.call;
    const readonly_call = block.instructions.items[1].kind.call;
    const writeonly_call = block.instructions.items[2].kind.call;
    const unknown_call = block.instructions.items[3].kind.call;

    try std.testing.expectEqual(memory_effect.Effect.none, function_attrs.callMemoryEffect(module, pure_call));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, function_attrs.callMemoryEffect(module, readonly_call));
    try std.testing.expectEqual(memory_effect.Effect.memory_write, function_attrs.callMemoryEffect(module, writeonly_call));
    try std.testing.expectEqual(memory_effect.Effect.unknown, function_attrs.callMemoryEffect(module, unknown_call));
}

test "function attributes treat operand-bundled calls as unknown effects" {
    const input =
        \\declare i32 @pure() #0
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %x = call i32 @pure() [ "cold"() ]
        \\  ret i32 %x
        \\}
        \\
        \\attributes #0 = { memory(none) nounwind }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const bundled_call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqual(memory_effect.Effect.unknown, function_attrs.callMemoryEffect(module, bundled_call));
}

fn containsText(haystack: []const []const u8, needle: []const u8) bool {
    for (haystack) |item| {
        if (std.mem.eql(u8, item, needle)) return true;
    }
    return false;
}

test "function attributes resolve IPO attributes through groups" {
    const input =
        \\declare i32 @decl(i32) #0
        \\
        \\define internal i32 @helper(i32 %a) #1 {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\attributes #0 = { nofree nounwind memory(read) }
        \\attributes #1 = { alwaysinline nofree norecurse nosync nounwind memory(none) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const decl_attrs = function_attrs.resolvedDeclarationAttributes(module, module.declarations.items[0]);
    try std.testing.expect(decl_attrs.nofree);
    try std.testing.expect(decl_attrs.nounwind);
    try std.testing.expect(decl_attrs.readonly);

    const helper_attrs = function_attrs.resolvedFunctionAttributes(module, module.functions.items[0]);
    try std.testing.expect(helper_attrs.alwaysinline);
    try std.testing.expect(helper_attrs.nofree);
    try std.testing.expect(helper_attrs.norecurse);
    try std.testing.expect(helper_attrs.nosync);
    try std.testing.expect(helper_attrs.nounwind);
    try std.testing.expect(helper_attrs.readnone);
}

test "function attributes resolve attribute groups for call memory effects" {
    const input =
        \\declare i32 @pure(i32) #0
        \\declare i32 @reads(ptr) #1
        \\
        \\define i32 @caller(ptr %p, i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  %y = call i32 @reads(ptr %p)
        \\  ret i32 %x
        \\}
        \\
        \\attributes #0 = { nofree nosync nounwind willreturn memory(none) }
        \\attributes #1 = { nofree nosync nounwind willreturn memory(read) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const block = module.functions.items[0].blocks.items[0];

    const pure_call = block.instructions.items[0].kind.call;
    const readonly_call = block.instructions.items[1].kind.call;

    try std.testing.expectEqual(memory_effect.Effect.none, function_attrs.callMemoryEffect(module, pure_call));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, function_attrs.callMemoryEffect(module, readonly_call));
}

test "function attributes classify Zig memory effects conservatively" {
    const input =
        \\declare i32 @pure(i32) #0
        \\
        \\declare i32 @reads(ptr) #1
        \\
        \\declare i32 @arg_reads(ptr) #2
        \\
        \\declare void @arg_writes(ptr) #3
        \\
        \\declare void @readwrite(ptr) #4
        \\
        \\define i32 @caller(ptr %p, i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  %y = call i32 @reads(ptr %p)
        \\  %z = call i32 @arg_reads(ptr %p)
        \\  call void @arg_writes(ptr %p)
        \\  call void @readwrite(ptr %p)
        \\  ret i32 %z
        \\}
        \\
        \\attributes #0 = { mustprogress memory(none) "target-cpu"="x86-64" "target-features"="+sse2,-avx" }
        \\attributes #1 = { nounwind memory(read, argmem: none, inaccessiblemem: none, target_mem0: none) "frame-pointer"="all" }
        \\attributes #2 = { nounwind memory(argmem: read) }
        \\attributes #3 = { nounwind memory(argmem: write) }
        \\attributes #4 = { nounwind memory(readwrite, argmem: none, inaccessiblemem: none, target_mem0: none) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const block = module.functions.items[0].blocks.items[0];
    try std.testing.expectEqual(memory_effect.Effect.none, function_attrs.callMemoryEffect(module, block.instructions.items[0].kind.call));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, function_attrs.callMemoryEffect(module, block.instructions.items[1].kind.call));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, function_attrs.callMemoryEffect(module, block.instructions.items[2].kind.call));
    try std.testing.expectEqual(memory_effect.Effect.memory_write, function_attrs.callMemoryEffect(module, block.instructions.items[3].kind.call));
    try std.testing.expectEqual(memory_effect.Effect.unknown, function_attrs.callMemoryEffect(module, block.instructions.items[4].kind.call));

    const feature_attrs = target.features.parseAttributeText(module.attribute_groups.items[0]);
    try std.testing.expectEqualStrings("x86-64", feature_attrs.cpu.?);
    try std.testing.expect(feature_attrs.hasFeature("+sse2"));
    try std.testing.expect(feature_attrs.hasFeature("-avx"));

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "alias modref refines direct call memory effects" {
    const input =
        \\declare i32 @pure(i32) #0
        \\declare i32 @reads_all(ptr) #1
        \\declare void @arg_reads(ptr) #2
        \\declare void @arg_writes(ptr) #3
        \\declare void @inaccessible_write() #4
        \\declare void @unknown(ptr)
        \\
        \\define void @caller(i32 %seed) {
        \\entry:
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  %x = call i32 @pure(i32 %seed)
        \\  %y = call i32 @reads_all(ptr %left)
        \\  call void @arg_reads(ptr %left)
        \\  call void @arg_writes(ptr %right)
        \\  call void @arg_writes(ptr %left)
        \\  call void @inaccessible_write()
        \\  call void @unknown(ptr %left)
        \\  ret void
        \\}
        \\
        \\attributes #0 = { memory(none) }
        \\attributes #1 = { memory(read, argmem: none, inaccessiblemem: none, target_mem0: none) }
        \\attributes #2 = { memory(argmem: read) }
        \\attributes #3 = { memory(argmem: write) }
        \\attributes #4 = { memory(inaccessiblemem: write) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    const block = function.blocks.items[0];
    const left = ir.Value{ .named = "left" };

    try std.testing.expectEqual(alias.ModRefInfo.no_mod_ref, alias.modRefInModule(module, function, block.instructions.items[2], left));
    try std.testing.expectEqual(alias.ModRefInfo.ref, alias.modRefInModule(module, function, block.instructions.items[3], left));
    try std.testing.expectEqual(alias.ModRefInfo.ref, alias.modRefInModule(module, function, block.instructions.items[4], left));
    try std.testing.expectEqual(alias.ModRefInfo.no_mod_ref, alias.modRefInModule(module, function, block.instructions.items[5], left));
    try std.testing.expectEqual(alias.ModRefInfo.mod, alias.modRefInModule(module, function, block.instructions.items[6], left));
    try std.testing.expectEqual(alias.ModRefInfo.no_mod_ref, alias.modRefInModule(module, function, block.instructions.items[7], left));
    try std.testing.expectEqual(alias.ModRefInfo.unknown, alias.modRefInModule(module, function, block.instructions.items[8], left));
}

test "instcombine folds integer minmax intrinsics for same operands" {
    const input =
        \\declare i32 @llvm.smin.i32(i32, i32) #0
        \\
        \\define i32 @same_min(i32 %a) {
        \\entry:
        \\  %r = tail call i32 @llvm.smin.i32(i32 %a, i32 %a)
        \\  ret i32 %r
        \\}
        \\
        \\attributes #0 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, "instcombine,dce");
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace_output.deinit();
    _ = try pm.run(&module, &context, &trace_output.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\declare i32 @llvm.smin.i32(i32, i32) #0
        \\
        \\define i32 @same_min(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
        \\attributes #0 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "globaldce removes unreferenced local functions and globals" {
    const input =
        \\@live_global = global i32 1
        \\@dead_global = internal global i32 2
        \\@exported_helper = alias i32 (i32), ptr @helper
        \\
        \\define internal i32 @helper(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
        \\define internal i32 @dead(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
        \\define i32 @entry(i32 %a) {
        \\entry:
        \\  %r = call i32 @helper(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, "globaldce");
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace.deinit();
    _ = try pm.run(&module, &context, &trace.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\@live_global = global i32 1
        \\
        \\@exported_helper = alias i32 (i32), ptr @helper
        \\
        \\define internal i32 @helper(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
        \\define i32 @entry(i32 %a) {
        \\entry:
        \\  %r = call i32 @helper(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "globaldce removes unreferenced local comdat members" {
    const input =
        \\$grp = comdat any
        \\
        \\@member = internal global i32 1, comdat($grp)
        \\@dead = internal global i32 2
        \\
        \\define internal i32 @helper(i32 %x) comdat($grp) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
        \\define internal i32 @dead_fn(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, "globaldce");
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace.deinit();
    _ = try pm.run(&module, &context, &trace.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings("", output.writer.buffered());
}

test "globaldce removes unreferenced local thread local globals" {
    const input =
        \\@tls = internal thread_local global i32 1
        \\@dead = internal global i32 2
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, "globaldce");
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace.deinit();
    _ = try pm.run(&module, &context, &trace.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings("", output.writer.buffered());
}

test "normalizer accepts empty modules after comparison noise stripping" {
    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator,
        \\; ModuleID = 'empty.ll'
        \\source_filename = "empty.ll"
        \\
    );
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings("", normalized);
}

test "normalizer canonicalizes numeric local SSA names" {
    const input =
        \\define i32 @renumber(i32 %0) {
        \\entry:
        \\  %2 = add i32 %0, 1
        \\  %3 = add i32 %2, 1
        \\  ret i32 %3
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    const expected =
        \\define i32 @renumber(i32 %0) {
        \\entry:
        \\  %1 = add i32 %0, 1
        \\  %2 = add i32 %1, 1
        \\  ret i32 %2
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, normalized);
}

test "verifier rejects use before definition in the same block" {
    const input =
        \\define i32 @bad(i32 %a) {
        \\entry:
        \\  %y = add i32 %x, 1
        \\  %x = add i32 %a, 1
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.ValueDoesNotDominateUse, module.verify());
}

test "verifier rejects value that does not dominate a merge use" {
    const input =
        \\define i32 @bad(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  %x = add i32 %a, 1
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  ret i32 %x
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.ValueDoesNotDominateUse, module.verify());
}

test "verifier rejects phi incoming blocks that are not exact predecessors" {
    const wrong_predecessor =
        \\define i32 @bad(i32 %a) {
        \\entry:
        \\  br label %merge
        \\unused:
        \\  ret i32 %a
        \\merge:
        \\  %v = phi i32 [ %a, %entry ], [ %a, %unused ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var wrong_module = try ir.Module.parse(std.testing.allocator, wrong_predecessor);
    defer wrong_module.deinit();
    try std.testing.expectError(error.PhiIncomingNotPredecessor, wrong_module.verify());

    const missing_predecessor =
        \\define i32 @bad(i32 %a) {
        \\entry:
        \\  br label %merge
        \\other:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %entry ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var missing_module = try ir.Module.parse(std.testing.allocator, missing_predecessor);
    defer missing_module.deinit();
    try std.testing.expectError(error.MissingPhiIncoming, missing_module.verify());

    const duplicate_predecessor =
        \\define i32 @bad(i32 %a) {
        \\entry:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %entry ], [ %a, %entry ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var duplicate_module = try ir.Module.parse(std.testing.allocator, duplicate_predecessor);
    defer duplicate_module.deinit();
    try std.testing.expectError(error.DuplicatePhiIncoming, duplicate_module.verify());

    const duplicate_edge_different_values =
        \\define i32 @bad(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %merge, label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %entry ], [ %b, %entry ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var duplicate_edge_module = try ir.Module.parse(std.testing.allocator, duplicate_edge_different_values);
    defer duplicate_edge_module.deinit();
    try std.testing.expectError(error.DuplicatePhiIncoming, duplicate_edge_module.verify());
}

test "verifier rejects phi after non-phi instructions" {
    const input =
        \\define i32 @bad(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %x = add i32 %a, 1
        \\  %v = phi i32 [ %a, %left ], [ %x, %right ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.PhiAfterNonPhi, module.verify());
}

test "verifier rejects entry block predecessors" {
    const input =
        \\define void @bad() {
        \\entry:
        \\  br label %entry
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.EntryBlockHasPredecessors, module.verify());
}

test "verifier rejects invalid memory alignment" {
    const input =
        \\define i32 @bad(ptr %p) {
        \\entry:
        \\  %v = load i32, ptr %p, align 3
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.InvalidAlignment, module.verify());
}

test "parser preserves indirect call form conservatively" {
    const indirect =
        \\define i32 @caller(ptr %fn, i32 %a) {
        \\entry:
        \\  %r = call i32 %fn(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, indirect);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(call.callee_value != null);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(indirect, output.writer.buffered());
}

test "parser rejects unsupported control-flow call forms" {
    const invoke =
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = invoke i32 @callee(i32 %a) to label %ok unwind label %bad
        \\ok:
        \\  ret i32 %r
        \\bad:
        \\  unreachable
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedCallTerminator, ir.Module.parse(std.testing.allocator, invoke));

    const callbr =
        \\define void @asm_goto() {
        \\entry:
        \\  callbr void asm sideeffect "", ""() to label %fallthrough [label %target]
        \\fallthrough:
        \\  ret void
        \\target:
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedCallTerminator, ir.Module.parse(std.testing.allocator, callbr));

    const landingpad =
        \\define ptr @eh_personality() {
        \\entry:
        \\  %lp = landingpad { ptr, i32 }
        \\          cleanup
        \\  ret ptr undef
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, landingpad));

    const resume_ir =
        \\define void @resume_eh() {
        \\entry:
        \\  resume ptr undef
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, resume_ir));

    const catchswitch =
        \\define void @catchswitch_eh() {
        \\entry:
        \\  catchswitch within none [label %handler] unwind to caller
        \\handler:
        \\  unreachable
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, catchswitch));

    const cleanupret =
        \\define void @cleanupret_eh() {
        \\entry:
        \\  cleanupret from none unwind to caller
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, cleanupret));

    const catchret =
        \\define void @catchret_eh(ptr %tok) {
        \\entry:
        \\  catchret from %tok to label %done
        \\done:
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, catchret));

    const catchpad =
        \\define ptr @catchpad_eh(ptr %tok) {
        \\entry:
        \\  %cp = catchpad within %tok []
        \\  ret ptr undef
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, catchpad));

    const cleanuppad =
        \\define ptr @cleanuppad_eh(ptr %tok) {
        \\entry:
        \\  %cp = cleanuppad within %tok []
        \\  ret ptr undef
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, cleanuppad));

    const personality =
        \\define void @personality_eh() personality ptr @__gxx_personality_v0 {
        \\entry:
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedExceptionHandling, ir.Module.parse(std.testing.allocator, personality));
}

test "parser preserves scalar global variables" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@g = internal global i32 42, align 4
        \\@c = private constant i8 undef
        \\@hidden = extern_weak hidden constant ptr, align 8
        \\
        \\define i32 @readable(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 3), module.globals.items.len);
    try std.testing.expectEqual(ir.FunctionLinkage.internal, module.globals.items[0].linkage);
    try std.testing.expectEqual(ir.GlobalKind.global, module.globals.items[0].kind);
    try std.testing.expectEqual(@as(i128, 42), module.globals.items[0].initializer.scalar.int);
    try std.testing.expectEqualStrings("align 4", module.globals.items[0].attrs.?);
    try std.testing.expectEqual(ir.FunctionLinkage.private, module.globals.items[1].linkage);
    try std.testing.expectEqual(ir.GlobalKind.constant, module.globals.items[1].kind);
    try std.testing.expectEqual(ir.Value.undef, module.globals.items[1].initializer.scalar);
    try std.testing.expectEqual(ir.FunctionLinkage.extern_weak, module.globals.items[2].linkage);
    try std.testing.expectEqualStrings("hidden", module.globals.items[2].address_attrs.?);
    try std.testing.expectEqual(ir.GlobalKind.constant, module.globals.items[2].kind);
    try std.testing.expect(module.globals.items[2].initializer == .none);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves scalar floating point global initializers" {
    const input =
        \\@gf = private unnamed_addr global float 1.250000e+00, align 4
        \\@gd = private unnamed_addr global double 1.230000e+00, align 8
        \\
        \\define double @read_double() {
        \\entry:
        \\  %v = load double, ptr @gd, align 8
        \\  ret double %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 2), module.globals.items.len);
    try std.testing.expectEqualStrings("1.250000e+00", module.globals.items[0].initializer.scalar.fp);
    try std.testing.expectEqualStrings("1.230000e+00", module.globals.items[1].initializer.scalar.fp);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier rejects mismatched scalar floating point global initializers" {
    const fp_on_int =
        \\@bad = global i32 1.250000e+00
        \\
    ;
    var int_module = try ir.Module.parse(std.testing.allocator, fp_on_int);
    defer int_module.deinit();
    try std.testing.expectError(error.UnsupportedGlobalVariable, int_module.verify());

    const int_on_fp =
        \\@bad = global double 1
        \\
    ;
    var fp_module = try ir.Module.parse(std.testing.allocator, int_on_fp);
    defer fp_module.deinit();
    try std.testing.expectError(error.UnsupportedGlobalVariable, fp_module.verify());
}

test "parser preserves module flags and comdat records" {
    const input =
        \\source_filename = "module.zig"
        \\
        \\$foo = comdat any
        \\
        \\@g = internal global i32 42, comdat($foo)
        \\
        \\!llvm.module.flags = !{!0}
        \\!0 = !{i32 2, !"Debug Info Version", i32 3}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectEqual(@as(usize, 1), module.comdats.items.len);
    try std.testing.expectEqualStrings("$foo = comdat any", module.comdats.items[0]);
    try std.testing.expectEqual(@as(usize, 2), module.metadata.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves weak linkage and verifier rejects unknown comdat references" {
    const weak_ir =
        \\@weak_global = weak global i32 1
        \\
        \\define weak i32 @weak_function() {
        \\entry:
        \\  ret i32 1
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, weak_ir);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(ir.FunctionLinkage.weak, module.globals.items[0].linkage);
    try std.testing.expectEqual(ir.FunctionLinkage.weak, module.functions.items[0].linkage);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(weak_ir, output.writer.buffered());

    const bad_comdat =
        \\@member = internal global i32 1, comdat($missing)
        \\
        \\define i32 @read_member() {
        \\entry:
        \\  %v = load i32, ptr @member, align 4
        \\  ret i32 %v
        \\}
        \\
    ;
    var bad_module = try ir.Module.parse(std.testing.allocator, bad_comdat);
    defer bad_module.deinit();
    try std.testing.expectError(error.InvalidComdat, bad_module.verify());
}

test "parser preserves size attributes and profile metadata opaquely" {
    const input =
        \\define minsize optsize i32 @small(i1 %cond, i32 %a) #0 {
        \\entry:
        \\  br i1 %cond, label %then, label %else, !prof !0
        \\then:
        \\  ret i32 %a
        \\else:
        \\  ret i32 0
        \\}
        \\
        \\attributes #0 = { minsize optsize nounwind }
        \\
        \\!0 = !{!"branch_weights", i32 1, i32 100}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "target feature attributes are extractable but not optimization inputs" {
    const attrs = target.features.parseAttributeText(
        \\attributes #0 = { minsize "target-cpu"="x86-64" "target-features"="+sse,+sse2,-avx" }
    );

    try std.testing.expectEqualStrings("x86-64", attrs.cpu.?);
    try std.testing.expectEqualStrings("+sse,+sse2,-avx", attrs.features.?);
    try std.testing.expect(attrs.hasFeature("+sse2"));
    try std.testing.expect(attrs.hasFeature("-avx"));
    try std.testing.expect(!attrs.hasFeature("+avx"));
}

test "verifier rejects unsupported aggregate globals explicitly" {
    const input =
        \\@s = private unnamed_addr constant [2 x i16] c"abc\00"
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expectError(error.UnsupportedGlobalVariable, module.verify());
}

test "parser preserves semicolons inside global C string literals" {
    const input =
        \\@ansi = private unnamed_addr constant [13 x i8] c"\1B[J\1B]9;4;0\1B\\\00", align 1
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings(
        "c\"\\1B[J\\1B]9;4;0\\1B\\\\\\00\"",
        module.globals.items[0].initializer.c_string,
    );

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves pointer global constant expression initializers" {
    const input =
        \\@vram = private unnamed_addr constant ptr inttoptr (i64 536870912 to ptr), align 8
        \\
        \\define void @write() {
        \\entry:
        \\  store volatile i8 88, ptr inttoptr (i64 536870912 to ptr), align 1
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings(
        "inttoptr (i64 536870912 to ptr)",
        module.globals.items[0].initializer.scalar.constant_expr,
    );

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves scalar array global constants from switch tables" {
    const input =
        \\@switch.table = private unnamed_addr constant [3 x i32] [i32 11, i32 13, i32 17], align 4
        \\
        \\define i32 @lookup(i8 %idx) {
        \\entry:
        \\  %wide = zext nneg i8 %idx to i64
        \\  %gep = getelementptr inbounds nuw i32, ptr @switch.table, i64 %wide
        \\  %value = load i32, ptr %gep, align 4
        \\  ret i32 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 1), module.globals.items.len);
    const initializer = module.globals.items[0].initializer.array;
    try std.testing.expectEqual(ir.Type{ .int = 32 }, initializer.elem_ty);
    try std.testing.expectEqual(@as(usize, 3), initializer.values.items.len);
    try std.testing.expectEqual(@as(i128, 13), initializer.values.items[1].int);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(
        \\@switch.table = private unnamed_addr constant [3 x i32] [i32 11, i32 13, i32 17], align 4
        \\
        \\define i32 @lookup(i8 %idx) {
        \\entry:
        \\  %wide = zext nneg i8 %idx to i64
        \\  %gep = getelementptr i32, ptr @switch.table, i64 %wide
        \\  %value = load i32, ptr %gep, align 4
        \\  ret i32 %value
        \\}
        \\
    , output.writer.buffered());
}

test "parser preserves source-backed cast flags" {
    const input =
        \\define i8 @narrow(i32 %x) {
        \\entry:
        \\  %t = trunc nuw i32 %x to i8
        \\  ret i8 %t
        \\}
        \\
        \\define i64 @widen(i8 %x) {
        \\entry:
        \\  %z = zext nneg i8 %x to i64
        \\  ret i64 %z
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser verifies and prints scalar bitcast instruction" {
    const input =
        \\define i64 @bitcast_double_to_i64(double %x) {
        \\entry:
        \\  %r = bitcast double %x to i64
        \\  ret i64 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cast = module.functions.items[0].blocks.items[0].instructions.items[0].kind.cast;
    try std.testing.expectEqual(ir.CastOp.bitcast, cast.op);
    try std.testing.expectEqual(@as(ir.Type, .double), cast.from_ty);
    try std.testing.expectEqual(ir.Type{ .int = 64 }, cast.to_ty);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser verifies and prints vector bitcast instruction" {
    const input =
        \\define i16 @bitcast_vector_mask(<16 x i1> %mask) {
        \\entry:
        \\  %r = bitcast <16 x i1> %mask to i16
        \\  ret i16 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cast = module.functions.items[0].blocks.items[0].instructions.items[0].kind.cast;
    try std.testing.expectEqual(ir.CastOp.bitcast, cast.op);
    try std.testing.expect(cast.from_ty.eql(ir.Type{ .vector = .{
        .len = 16,
        .elem_ty = .{ .int = 1 },
    } }));
    try std.testing.expectEqual(ir.Type{ .int = 16 }, cast.to_ty);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier accepts vector integer extension casts" {
    const input =
        \\define <2 x i64> @vector_zext(<2 x i32> %value) {
        \\entry:
        \\  %wide = zext <2 x i32> %value to <2 x i64>
        \\  ret <2 x i64> %wide
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cast = module.functions.items[0].blocks.items[0].instructions.items[0].kind.cast;
    try std.testing.expectEqual(ir.CastOp.zext, cast.op);
    try std.testing.expect(cast.from_ty.eql(ir.Type{ .vector = .{
        .len = 2,
        .elem_ty = .{ .int = 32 },
    } }));
    try std.testing.expect(cast.to_ty.eql(ir.Type{ .vector = .{
        .len = 2,
        .elem_ty = .{ .int = 64 },
    } }));
}

test "parser preserves vector global initializers and vector FP-to-int casts" {
    const input =
        \\@vec = private unnamed_addr global <2 x float> <float 1.000000e+02, float 5.120000e+02>, align 8
        \\
        \\define <2 x i10> @convert(<2 x float> %value) {
        \\entry:
        \\  %cmp = fcmp ole <2 x float> %value, <float 1.000000e+02, float 5.120000e+02>
        \\  %int = fptosi <2 x float> %value to <2 x i10>
        \\  ret <2 x i10> %int
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expect(module.globals.items[0].ty.eql(ir.Type{ .vector = .{
        .len = 2,
        .elem_ty = .float,
    } }));
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].kind.fcmp.operand_ty.eql(ir.Type{ .vector = .{
        .len = 2,
        .elem_ty = .float,
    } }));
    try std.testing.expectEqual(ir.CastOp.fptosi, module.functions.items[0].blocks.items[0].instructions.items[1].kind.cast.op);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier rejects invalid scalar bitcast shapes" {
    const width_mismatch =
        \\define i32 @bad_width(double %x) {
        \\entry:
        \\  %r = bitcast double %x to i32
        \\  ret i32 %r
        \\}
        \\
    ;
    const pointer_bitcast =
        \\define i64 @bad_ptr(ptr %x) {
        \\entry:
        \\  %r = bitcast ptr %x to i64
        \\  ret i64 %r
        \\}
        \\
    ;

    var bad_width = try ir.Module.parse(std.testing.allocator, width_mismatch);
    defer bad_width.deinit();
    try std.testing.expectError(error.InvalidCast, bad_width.verify());

    var bad_ptr = try ir.Module.parse(std.testing.allocator, pointer_bitcast);
    defer bad_ptr.deinit();
    try std.testing.expectError(error.InvalidCast, bad_ptr.verify());
}

test "parser and verifier reject invalid cast flags intentionally" {
    const duplicate_flag =
        \\define i8 @duplicate(i32 %x) {
        \\entry:
        \\  %t = trunc nuw nuw i32 %x to i8
        \\  ret i8 %t
        \\}
        \\
    ;
    const unsupported_flag =
        \\define i8 @unsupported(i32 %x) {
        \\entry:
        \\  %t = trunc exact i32 %x to i8
        \\  ret i8 %t
        \\}
        \\
    ;
    const invalid_trunc_flag =
        \\define i8 @invalid_trunc(i32 %x) {
        \\entry:
        \\  %t = trunc nneg i32 %x to i8
        \\  ret i8 %t
        \\}
        \\
    ;
    const invalid_zext_flag =
        \\define i64 @invalid_zext(i8 %x) {
        \\entry:
        \\  %z = zext nuw i8 %x to i64
        \\  ret i64 %z
        \\}
        \\
    ;

    try std.testing.expectError(error.InvalidInstructionFlag, ir.Module.parse(std.testing.allocator, duplicate_flag));
    try std.testing.expectError(error.InvalidInstructionFlag, ir.Module.parse(std.testing.allocator, unsupported_flag));

    var invalid_trunc = try ir.Module.parse(std.testing.allocator, invalid_trunc_flag);
    defer invalid_trunc.deinit();
    try std.testing.expectError(error.InvalidInstructionFlag, invalid_trunc.verify());

    var invalid_zext = try ir.Module.parse(std.testing.allocator, invalid_zext_flag);
    defer invalid_zext.deinit();
    try std.testing.expectError(error.InvalidInstructionFlag, invalid_zext.verify());
}

test "parser preserves scalar float arithmetic and compare IR" {
    const input =
        \\define float @float_add(float %a, float %b) {
        \\entry:
        \\  %sum = fadd float %a, %b
        \\  ret float %sum
        \\}
        \\
        \\define double @float_select(double %a, double %b, i1 %cond) {
        \\entry:
        \\  %value = select i1 %cond, double %a, double %b
        \\  ret double %value
        \\}
        \\
        \\define double @float_mul(double %a, double %b) {
        \\entry:
        \\  %product = fmul double %a, %b
        \\  ret double %product
        \\}
        \\
        \\define float @float_sub(float %a, float %b) {
        \\entry:
        \\  %difference = fsub float %a, %b
        \\  ret float %difference
        \\}
        \\
        \\define double @float_div(double %a, double %b) {
        \\entry:
        \\  %quotient = fdiv double %a, %b
        \\  ret double %quotient
        \\}
        \\
        \\define float @float_rem(float %a, float %b) {
        \\entry:
        \\  %remainder = frem float %a, %b
        \\  ret float %remainder
        \\}
        \\
        \\define i1 @float_less(float %a, float %b) {
        \\entry:
        \\  %less = fcmp olt float %a, %b
        \\  ret i1 %less
        \\}
        \\
        \\define double @float_extend(float %a) {
        \\entry:
        \\  %wide = fpext float %a to double
        \\  ret double %wide
        \\}
        \\
        \\define i32 @float_to_signed(float %a) {
        \\entry:
        \\  %int = fptosi float %a to i32
        \\  ret i32 %int
        \\}
        \\
        \\define i32 @float_to_unsigned(float %a) {
        \\entry:
        \\  %int = fptoui float %a to i32
        \\  ret i32 %int
        \\}
        \\
        \\define float @float_narrow(double %a) {
        \\entry:
        \\  %narrow = fptrunc double %a to float
        \\  ret float %narrow
        \\}
        \\
        \\define float @float_from_signed(i32 %a) {
        \\entry:
        \\  %value = sitofp i32 %a to float
        \\  ret float %value
        \\}
        \\
        \\define double @double_from_unsigned(i32 %a) {
        \\entry:
        \\  %value = uitofp i32 %a to double
        \\  ret double %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expect(module.functions.items[0].ret_ty.eql(.float));
    try std.testing.expect(module.functions.items[1].ret_ty.eql(.double));
    try std.testing.expect(module.functions.items[2].ret_ty.eql(.double));
    try std.testing.expect(module.functions.items[3].ret_ty.eql(.float));
    try std.testing.expect(module.functions.items[4].ret_ty.eql(.double));
    try std.testing.expect(module.functions.items[5].ret_ty.eql(.float));
    try std.testing.expect(module.functions.items[6].ret_ty.eql(.{ .int = 1 }));
    try std.testing.expectEqual(ir.CastOp.fpext, module.functions.items[7].blocks.items[0].instructions.items[0].kind.cast.op);
    try std.testing.expectEqual(ir.CastOp.fptosi, module.functions.items[8].blocks.items[0].instructions.items[0].kind.cast.op);
    try std.testing.expectEqual(ir.CastOp.fptoui, module.functions.items[9].blocks.items[0].instructions.items[0].kind.cast.op);
    try std.testing.expectEqual(ir.CastOp.fptrunc, module.functions.items[10].blocks.items[0].instructions.items[0].kind.cast.op);
    try std.testing.expectEqual(ir.CastOp.sitofp, module.functions.items[11].blocks.items[0].instructions.items[0].kind.cast.op);
    try std.testing.expectEqual(ir.CastOp.uitofp, module.functions.items[12].blocks.items[0].instructions.items[0].kind.cast.op);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves extended scalar FP ABI surface" {
    const input =
        \\declare i32 @__eqtf2(fp128, fp128)
        \\
        \\define fp128 @fp128_roundtrip(ptr %p, fp128 %x) {
        \\entry:
        \\  store fp128 %x, ptr %p, align 16
        \\  %loaded = load fp128, ptr %p, align 16
        \\  %cmp = call i32 @__eqtf2(fp128 %loaded, fp128 0xL00000000000000004002A00000000000)
        \\  ret fp128 0xL00000000000000004004100000000000
        \\}
        \\
        \\define void @longdouble_sink(x86_fp80 %x) {
        \\entry:
        \\  ret void
        \\}
        \\
        \\define void @longdouble_caller(x86_fp80 %x) {
        \\entry:
        \\  call void @longdouble_sink(x86_fp80 %x)
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expect(module.functions.items[0].ret_ty.eql(.fp128));
    try std.testing.expect(module.functions.items[0].params.items[1].ty.eql(.fp128));
    try std.testing.expect(module.functions.items[1].params.items[0].ty.eql(.x86_fp80));
    try std.testing.expect(module.functions.items[2].params.items[0].ty.eql(.x86_fp80));
    try std.testing.expectEqual(fp_semantics.Category.normal, (try fp_semantics.classify(.fp128, "0xL00000000000000004002A00000000000")).category);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser rejects unsupported floating point compare forms" {
    const fcmp_predicate_input =
        \\define i1 @cmp(float %a, float %b) {
        \\entry:
        \\  %r = fcmp bad float %a, %b
        \\  ret i1 %r
        \\}
        \\
    ;
    const fcmp_type_input =
        \\define i1 @cmp(float %a, float %b) {
        \\entry:
        \\  %r = fcmp olt i32 1, 2
        \\  ret i1 %r
        \\}
        \\
    ;

    try std.testing.expectError(error.UnsupportedPredicate, ir.Module.parse(std.testing.allocator, fcmp_predicate_input));

    var module = try ir.Module.parse(std.testing.allocator, fcmp_type_input);
    defer module.deinit();
    try std.testing.expectError(error.TypeMismatch, module.verify());
}

test "parser preserves scalar fcmp predicate surface" {
    const input =
        \\define i1 @float_predicates(float %a, float %b) {
        \\entry:
        \\  %p0 = fcmp false float %a, %b
        \\  %p1 = fcmp oeq float %a, %b
        \\  %p2 = fcmp ogt float %a, %b
        \\  %p3 = fcmp oge float %a, %b
        \\  %p4 = fcmp olt float %a, %b
        \\  %p5 = fcmp ole float %a, %b
        \\  %p6 = fcmp one float %a, %b
        \\  %p7 = fcmp ord float %a, %b
        \\  %p8 = fcmp uno float %a, %b
        \\  %p9 = fcmp ueq float %a, %b
        \\  %p10 = fcmp ugt float %a, %b
        \\  %p11 = fcmp uge float %a, %b
        \\  %p12 = fcmp ult float %a, %b
        \\  %p13 = fcmp ule float %a, %b
        \\  %p14 = fcmp une float %a, %b
        \\  %p15 = fcmp true float %a, %b
        \\  ret i1 %p15
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves fast-math flags without enabling FP folds" {
    const input =
        \\define float @fast_math_flags(float %a, float %b) {
        \\entry:
        \\  %sum = fadd fast float %a, %b
        \\  %product = fmul nnan ninf nsz arcp float %sum, %b
        \\  %quotient = fdiv contract afn reassoc float %product, %b
        \\  %cmp = fcmp nnan ninf olt float %sum, %quotient
        \\  %value = select i1 %cmp, float %sum, float %quotient
        \\  ret float %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser keeps unsupported FP surface closed" {
    const invalid_fast_mix_input =
        \\define float @invalid_fast_mix(float %a, float %b) {
        \\entry:
        \\  %r = fadd fast nnan float %a, %b
        \\  ret float %r
        \\}
        \\
    ;
    const integer_fast_math_input =
        \\define i32 @integer_fast_math(i32 %a, i32 %b) {
        \\entry:
        \\  %r = add nnan i32 %a, %b
        \\  ret i32 %r
        \\}
        \\
    ;
    const vector_fcmp_input =
        \\define i1 @vector_cmp(float %a, float %b) {
        \\entry:
        \\  %r = fcmp olt <4 x float> %a, %b
        \\  ret i1 %r
        \\}
        \\
    ;
    const vector_fp_binary_input =
        \\define <2 x float> @vector_fadd(<2 x float> %a, <2 x float> %b) {
        \\entry:
        \\  %r = fadd <2 x float> %a, %b
        \\  ret <2 x float> %r
        \\}
        \\
    ;
    const constrained_input =
        \\define float @constrained(float %a, float %b) {
        \\entry:
        \\  %r = call float @llvm.experimental.constrained.fadd.f32(float %a, float %b)
        \\  ret float %r
        \\}
        \\
    ;

    try std.testing.expectError(error.InvalidInstruction, ir.Module.parse(std.testing.allocator, invalid_fast_mix_input));
    var integer_fast_math = try ir.Module.parse(std.testing.allocator, integer_fast_math_input);
    defer integer_fast_math.deinit();
    try std.testing.expectError(error.InvalidInstructionFlag, integer_fast_math.verify());
    var vector_fcmp = try ir.Module.parse(std.testing.allocator, vector_fcmp_input);
    defer vector_fcmp.deinit();
    try std.testing.expectError(error.TypeMismatch, vector_fcmp.verify());

    var vector_fp_binary = try ir.Module.parse(std.testing.allocator, vector_fp_binary_input);
    defer vector_fp_binary.deinit();
    try std.testing.expectError(error.UnsupportedType, vector_fp_binary.verify());

    var constrained = try ir.Module.parse(std.testing.allocator, constrained_input);
    defer constrained.deinit();
    try std.testing.expectError(error.UnknownFunction, constrained.verify());
}

test "parser classifies inline asm side effects separately from memory constraints" {
    const input =
        \\define void @inline_asm_effects(ptr %p) {
        \\entry:
        \\  call void asm sideeffect "", "~{dirflag},~{fpsr},~{flags}"()
        \\  call void asm sideeffect "", "m"(ptr %p)
        \\  call void asm sideeffect "", "=*m"(ptr %p)
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const block = module.functions.items[0].blocks.items[0];
    const sideeffect_only = block.instructions.items[0].kind.call.inline_asm.?;
    try std.testing.expect(sideeffect_only.sideeffect);
    try std.testing.expect(!sideeffect_only.has_memory_clobber);
    try std.testing.expect(!sideeffect_only.may_load);
    try std.testing.expect(!sideeffect_only.may_store);
    try std.testing.expectEqual(memory_effect.Effect.side_effect, memory_effect.classify(block.instructions.items[0]));
    try std.testing.expectEqual(memory_effect.BarrierKind.none, memory_effect.barrierKind(block.instructions.items[0]));

    const memory_input = block.instructions.items[1].kind.call.inline_asm.?;
    try std.testing.expect(memory_input.may_load);
    try std.testing.expect(!memory_input.may_store);
    try std.testing.expectEqual(memory_effect.Effect.readonly_side_effect, memory_effect.classify(block.instructions.items[1]));
    try std.testing.expectEqual(memory_effect.BarrierKind.inline_asm, memory_effect.barrierKind(block.instructions.items[1]));

    const memory_output = block.instructions.items[2].kind.call.inline_asm.?;
    try std.testing.expect(!memory_output.may_load);
    try std.testing.expect(memory_output.may_store);
    try std.testing.expectEqual(memory_effect.Effect.memory_write, memory_effect.classify(block.instructions.items[2]));
    try std.testing.expectEqual(memory_effect.BarrierKind.inline_asm, memory_effect.barrierKind(block.instructions.items[2]));
}

test "parser preserves module-level asm records opaquely" {
    const input =
        \\source_filename = "behavior_asm"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\module asm ".globl this_is_my_alias;"
        \\module asm ".type this_is_my_alias, @function;"
        \\module asm ".set this_is_my_alias, derp;"
        \\
        \\define i32 @derp() {
        \\entry:
        \\  ret i32 1
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(@as(usize, 3), module.module_asm.items.len);
    try std.testing.expectEqualStrings("module asm \".globl this_is_my_alias;\"", module.module_asm.items[0]);
    try std.testing.expectEqualStrings("module asm \".type this_is_my_alias, @function;\"", module.module_asm.items[1]);
    try std.testing.expectEqualStrings("module asm \".set this_is_my_alias, derp;\"", module.module_asm.items[2]);
}

test "parser preserves named type definitions opaquely" {
    const input =
        \\source_filename = "named_types"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\%os.linux.rlimit = type { i64, i64 }
        \\%os.linux.stack_t__struct_3163 = type { ptr, i32, [4 x i8], i64 }
        \\
        \\define void @use_named_type(ptr %p) {
        \\entry:
        \\  %slot = alloca %os.linux.rlimit, align 8
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 2), module.named_types.items.len);
    try std.testing.expectEqualStrings("os.linux.rlimit", module.named_types.items[0].name);
    try std.testing.expectEqualStrings("{ i64, i64 }", module.named_types.items[0].body);
    try std.testing.expectEqualStrings("%os.linux.rlimit = type { i64, i64 }", module.named_types.items[0].raw);
    try std.testing.expectEqualStrings("os.linux.stack_t__struct_3163", module.named_types.items[1].name);
    try std.testing.expectEqualStrings("{ ptr, i32, [4 x i8], i64 }", module.named_types.items[1].body);
}

test "parser preserves quoted named type definitions with equals in names" {
    const input =
        \\%"hash_map.Custom(.{ .thread_safe = true })" = type { ptr, i32, i32 }
        \\@quoted_type_global = private unnamed_addr constant %"hash_map.Custom(.{ .thread_safe = true })" zeroinitializer, align 8
        \\
        \\define void @use_quoted_named_type(ptr %p) {
        \\entry:
        \\  %slot = alloca %"hash_map.Custom(.{ .thread_safe = true })", align 8
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 1), module.named_types.items.len);
    try std.testing.expectEqualStrings("\"hash_map.Custom(.{ .thread_safe = true })\"", module.named_types.items[0].name);
    try std.testing.expectEqualStrings("{ ptr, i32, i32 }", module.named_types.items[0].body);
    try std.testing.expectEqual(@as(usize, 1), module.globals.items.len);
    try std.testing.expectEqualStrings("%\"hash_map.Custom(.{ .thread_safe = true })\"", module.globals.items[0].ty.aggregate);
}

test "verifier rejects duplicate named type definitions" {
    const input =
        \\%os.linux.rlimit = type { i64, i64 }
        \\%os.linux.rlimit = type { ptr, i64 }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expectError(error.DuplicateNamedTypeDefinition, module.verify());
}

test "parser preserves source-backed global variable forms" {
    const input =
        \\source_filename = "global_variables"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\%os.linux.rlimit = type { i64, i64 }
        \\%os.linux.stack_t__struct_3163 = type { ptr, i32, [4 x i8], i64 }
        \\
        \\@__init_array_start = extern_weak constant ptr, align 8
        \\@__init_array_end = extern_weak constant ptr, align 8
        \\@os.linux.tls.area_desc.0 = internal unnamed_addr global i64 undef, align 8
        \\@os.linux.tls.area_desc.4 = internal unnamed_addr global ptr undef, align 8
        \\@os.linux.tls.main_thread_area_buffer = private unnamed_addr global [4096 x i8] undef, align 4096
        \\@__anon_3154 = private unnamed_addr constant [13 x i8] c"hello world!\00", align 1
        \\@Thread.maybeAttachSignalStack.global.signal_stack = private thread_local unnamed_addr global [262144 x i8] undef, align 1
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 7), module.globals.items.len);
    try std.testing.expectEqual(ir.FunctionLinkage.extern_weak, module.globals.items[0].linkage);
    try std.testing.expect(module.globals.items[0].initializer == .none);
    try std.testing.expectEqual(ir.Value.undef, module.globals.items[4].initializer.scalar);
    try std.testing.expectEqualStrings("c\"hello world!\\00\"", module.globals.items[5].initializer.c_string);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier rejects local initializerless globals" {
    const input =
        \\@bad = internal constant ptr, align 8
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expectError(error.UnsupportedGlobalVariable, module.verify());
}

test "parser rejects unsupported inline asm forms explicitly" {
    const missing_sideeffect =
        \\define void @inline_asm_barrier() {
        \\entry:
        \\  call void asm "", "~{memory}"()
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, missing_sideeffect);
    defer module.deinit();
    try std.testing.expectError(error.UnsupportedInlineAsm, module.verify());
}

test "parser normalizes getelementptr instructions" {
    const input =
        \\define i32 @gep(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  %p = getelementptr i32, ptr %slot, i32 0
        \\  store i32 %a, ptr %p
        \\  %v = load i32, ptr %p
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes undef values" {
    const input =
        \\define i32 @undef_value(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ undef, %left ], [ %a, %right ]
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "normalization strips LLVM comparison noise" {
    const input =
        \\; ModuleID = 'test/opt/inputs/memory_dce.ll'
        \\source_filename = "test/opt/inputs/memory_dce.ll"
        \\
        \\define i32 @memory_dce(i32 %a) {
        \\entry:
        \\  %slot = alloca i32, align 4
        \\  store i32 %a, ptr %slot, align 4
        \\  ret i32 %a
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    const expected =
        \\define i32 @memory_dce(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, normalized);
}

test "dce removes unused loads but keeps stores" {
    const input =
        \\define i32 @memory_dce(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  %dead = load i32, ptr %slot
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

    const expected =
        \\define i32 @memory_dce(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "dse preserves stores across unknown memory barriers" {
    const input =
        \\declare void @touch()
        \\
        \\define i32 @barriers(i32 %a, i32 %b, ptr %p) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  call void @touch()
        \\  store i32 %b, ptr %slot
        \\  store volatile i32 %a, ptr %slot
        \\  store i32 %b, ptr %p
        \\  store i32 %a, ptr %slot
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(dse.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "alias analysis classifies stack slots" {
    const input =
        \\define i32 @alias(ptr %arg) {
        \\entry:
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  store i32 1, ptr %left
        \\  store i32 2, ptr %right
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    try std.testing.expectEqual(
        alias.AliasResult.must_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "left" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.no_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "right" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.no_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "arg" }),
    );
}

test "alias analysis classifies gep-derived stack slots" {
    const input =
        \\define i32 @gep_alias(i32 %index) {
        \\entry:
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  %left0 = getelementptr i32, ptr %left, i32 0
        \\  %left1 = getelementptr i32, ptr %left, i32 1
        \\  %left_unknown = getelementptr i32, ptr %left, i32 %index
        \\  %right0 = getelementptr i32, ptr %right, i32 0
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    try std.testing.expectEqual(
        alias.AliasResult.must_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "left0" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.no_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "left1" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.may_alias,
        alias.alias(function, .{ .named = "left0" }, .{ .named = "left_unknown" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.no_alias,
        alias.alias(function, .{ .named = "left0" }, .{ .named = "right0" }),
    );

    const left1 = memory_location.forPointer(function, .{ .named = "left1" }) orelse return error.TestExpectedMemoryLocation;
    try std.testing.expectEqual(@as(i128, 4), left1.offset.?);
    try std.testing.expectEqual(@as(u64, 4), left1.size.?);
}
