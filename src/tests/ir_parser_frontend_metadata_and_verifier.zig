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
