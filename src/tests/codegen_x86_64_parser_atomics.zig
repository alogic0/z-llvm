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

test "parser normalizes multiple functions and branch terminators" {
    const input =
        \\define i32 @branch(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  br label %exit
        \\else:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
        \\define i32 @second(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes unreachable terminator" {
    const input =
        \\define i32 @trap() {
        \\entry:
        \\  unreachable
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes icmp instructions" {
    const input =
        \\define i1 @cmp(i32 %a) {
        \\entry:
        \\  %c = icmp eq i32 %a, 0
        \\  ret i1 %c
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes select instructions" {
    const input =
        \\define i32 @choose(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  %v = select i1 %cond, i32 %a, i32 %b
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser preserves scalar casts div rem flags and freeze" {
    const input =
        \\define i32 @scalar_surface(i64 %wide, i8 %small, i32 %a, i32 %b) {
        \\entry:
        \\  %t = trunc i64 %wide to i32
        \\  %z = zext i8 %small to i32
        \\  %s = sext i8 %small to i32
        \\  %d = udiv exact i32 %a, 3
        \\  %r = srem i32 %b, 5
        \\  %sum0 = add nsw i32 %t, %z
        \\  %sum1 = add nuw i32 %sum0, %s
        \\  %sum2 = add i32 %sum1, %d
        \\  %sum3 = add i32 %sum2, %r
        \\  %sum4 = or disjoint i32 %sum3, 1
        \\  %f = freeze i32 %sum4
        \\  ret i32 %f
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

test "parser accepts array types and GEP prefixes from Zig aggregate IR" {
    const input =
        \\define i32 @array_gep(ptr %p, i64 %i) {
        \\entry:
        \\  %q = getelementptr inbounds [4 x i8], ptr %p, i64 %i
        \\  %r = getelementptr inbounds nuw i8, ptr %q, i64 4
        \\  %v = load i32, ptr %r, align 4
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const block = module.functions.items[0].blocks.items[0];
    try std.testing.expectEqualStrings("[4 x i8]", block.instructions.items[0].kind.gep.source_ty.aggregate);
    try std.testing.expectEqual(ir.Type{ .int = 8 }, block.instructions.items[1].kind.gep.source_ty);
}

test "parser accepts nested constant expression GEP pointer operands" {
    const input =
        \\@table = private unnamed_addr constant [4096 x i8] zeroinitializer, align 1
        \\
        \\define ptr @nested_gep(i64 %i) {
        \\entry:
        \\  %p = getelementptr inbounds nuw [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @table, i64 1024), i64 %i
        \\  ret ptr %p
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const gep = module.functions.items[0].blocks.items[0].instructions.items[0].kind.gep;
    try std.testing.expectEqualStrings("getelementptr inbounds nuw (i8, ptr @table, i64 1024)", gep.ptr.constant_expr);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\@table = private unnamed_addr constant [4096 x i8] zeroinitializer, align 1
        \\
        \\define ptr @nested_gep(i64 %i) {
        \\entry:
        \\  %p = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @table, i64 1024), i64 %i
        \\  ret ptr %p
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "parser rejects non-pointer typed nested constant expression GEP pointer operands" {
    const input =
        \\@table = private unnamed_addr constant [4096 x i8] zeroinitializer, align 1
        \\
        \\define ptr @bad_gep(i64 %i) {
        \\entry:
        \\  %p = getelementptr i8, i64 getelementptr (i8, ptr @table, i64 1), i64 %i
        \\  ret ptr %p
        \\}
        \\
    ;

    try std.testing.expectError(error.ExpectedPointerType, ir.Module.parse(std.testing.allocator, input));
}

test "instcombine preserves non-neutral flagged arithmetic and division" {
    const input =
        \\define i32 @conservative(i32 %a) {
        \\entry:
        \\  %x = add nsw i32 %a, 1
        \\  %y = udiv exact i32 %x, 2
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace.deinit();

    _ = try pm.run(&module, &context, &trace.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "instcombine folds safe division remainder and freeze constants" {
    const input =
        \\define i32 @safe_scalar(i32 %a) {
        \\entry:
        \\  %d = udiv i32 %a, 1
        \\  %r = srem i32 %d, 1
        \\  %f = freeze i32 42
        \\  %sum0 = add i32 %r, %f
        \\  %sum1 = add i32 %sum0, %d
        \\  ret i32 %sum1
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @safe_scalar(i32 %a) {
        \\entry:
        \\  %sum1 = add i32 %a, 42
        \\  ret i32 %sum1
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "instcombine preserves unsafe division folds" {
    const input =
        \\define i32 @unsafe_division() {
        \\entry:
        \\  %x = udiv i32 4, 0
        \\  %y = sdiv i32 -2147483648, -1
        \\  %z = udiv exact i32 5, 2
        \\  %sum0 = add i32 %x, %y
        \\  %sum1 = add i32 %sum0, %z
        \\  ret i32 %sum1
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace.deinit();

    _ = try pm.run(&module, &context, &trace.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "instcombine folds constant icmp" {
    const input =
        \\define i1 @cmp() {
        \\entry:
        \\  %c = icmp ne i32 1, 1
        \\  ret i1 %c
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i1 @cmp() {
        \\entry:
        \\  ret i1 0
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "instcombine folds simple select instructions" {
    const input =
        \\define i32 @select_fold(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  %x = select i1 1, i32 %a, i32 %b
        \\  %y = select i1 %cond, i32 %x, i32 %x
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @select_fold(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "parser normalizes phi instructions" {
    const input =
        \\define i32 @select(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %then ], [ %b, %else ]
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes memory instructions" {
    const input =
        \\define i32 @memory(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser prints load and store memory attributes" {
    const input =
        \\define i32 @memory_attrs(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store volatile i32 %a, ptr %slot, align 4
        \\  %v = load volatile i32, ptr %slot, align 4
        \\  ret i32 %v
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

test "parser preserves load from constant-expression gep pointer" {
    const input =
        \\@global = internal global [8 x i8] c"abcdefgh", align 1
        \\
        \\define i8 @load_gep_constexpr() {
        \\entry:
        \\  %v = load i8, ptr getelementptr inbounds nuw (i8, ptr @global, i64 2), align 1
        \\  ret i8 %v
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

test "parser preserves atomic memory through constant-expression gep pointer" {
    const input =
        \\@global = internal global [8 x i8] zeroinitializer, align 4
        \\
        \\define i32 @atomic_gep_constexpr(i32 %value) {
        \\entry:
        \\  store atomic i32 %value, ptr getelementptr inbounds nuw (i8, ptr @global, i64 4) unordered, align 4
        \\  %v = load atomic i32, ptr getelementptr inbounds nuw (i8, ptr @global, i64 4) unordered, align 4
        \\  ret i32 %v
        \\}
        \\
    ;
    const expected =
        \\@global = internal global [8 x i8] zeroinitializer, align 4
        \\
        \\define i32 @atomic_gep_constexpr(i32 %value) {
        \\entry:
        \\  store atomic i32 %value, ptr getelementptr inbounds nuw (i8, ptr @global, i64 4) unordered, align 4
        \\  %v = load atomic i32, ptr getelementptr inbounds nuw (i8, ptr @global, i64 4) unordered, align 4
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "parser accepts narrow atomic load and store spelling as barriers" {
    const input =
        \\define i32 @memory_atomic(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store atomic i32 %a, ptr %slot release, align 4
        \\  %v = load atomic i32, ptr %slot acquire, align 4
        \\  ret i32 %v
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

test "parser preserves known thread local models and rejects unknown TLS models" {
    const input =
        \\@tls = internal thread_local(localexec) unnamed_addr global i32 1, align 4
        \\
        \\define i32 @read_tls_model() {
        \\entry:
        \\  %v = load i32, ptr @tls, align 4
        \\  ret i32 %v
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

    const invalid =
        \\@tls = internal thread_local(unsupported) global i32 1
        \\
        \\define i32 @read_bad_tls_model() {
        \\entry:
        \\  %v = load i32, ptr @tls, align 4
        \\  ret i32 %v
        \\}
        \\
    ;
    var invalid_module = try ir.Module.parse(std.testing.allocator, invalid);
    defer invalid_module.deinit();
    try std.testing.expectError(error.UnsupportedGlobalVariable, invalid_module.verify());
}

test "parser preserves atomicrmw cmpxchg and fence barriers" {
    const input =
        \\define i32 @memory_atomicrmw(ptr %p) {
        \\entry:
        \\  %v = atomicrmw add ptr %p, i32 1 monotonic
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(module.functions.items[0].blocks.items[0].instructions.items[0]));
    try std.testing.expectEqual(memory_effect.BarrierKind.atomic, memory_effect.barrierKind(module.functions.items[0].blocks.items[0].instructions.items[0]));

    const cmpxchg =
        \\define i32 @memory_cmpxchg(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %v = cmpxchg ptr %p, i32 %old, i32 %new monotonic monotonic
        \\  ret i32 %old
        \\}
        \\
    ;
    var cmpxchg_module = try ir.Module.parse(std.testing.allocator, cmpxchg);
    defer cmpxchg_module.deinit();
    try cmpxchg_module.verify();
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(cmpxchg_module.functions.items[0].blocks.items[0].instructions.items[0]));

    const cmpxchg_extractvalue =
        \\define i1 @cmpxchg_extractvalue(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %pair = cmpxchg ptr %p, i32 %old, i32 %new acquire monotonic
        \\  %success = extractvalue { i32, i1 } %pair, 1
        \\  ret i1 %success
        \\}
        \\
    ;
    var extractvalue_module = try ir.Module.parse(std.testing.allocator, cmpxchg_extractvalue);
    defer extractvalue_module.deinit();
    try extractvalue_module.verify();

    var extractvalue_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer extractvalue_output.deinit();
    try extractvalue_module.print(&extractvalue_output.writer);
    try std.testing.expectEqualStrings(cmpxchg_extractvalue, extractvalue_output.writer.buffered());

    const cmpxchg_i8_extractvalue =
        \\define i1 @cmpxchg_i8_extractvalue(ptr %p, i8 %old, i8 %new) {
        \\entry:
        \\  %pair = cmpxchg weak ptr %p, i8 %old, i8 %new seq_cst seq_cst
        \\  %success = extractvalue { i8, i1 } %pair, 1
        \\  ret i1 %success
        \\}
        \\
    ;
    var i8_extractvalue_module = try ir.Module.parse(std.testing.allocator, cmpxchg_i8_extractvalue);
    defer i8_extractvalue_module.deinit();
    try i8_extractvalue_module.verify();
    try std.testing.expect(i8_extractvalue_module.functions.items[0].blocks.items[0].instructions.items[0].resultType().?.eql(.{ .aggregate = "{ i8, i1 }" }));

    var i8_extractvalue_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer i8_extractvalue_output.deinit();
    try i8_extractvalue_module.print(&i8_extractvalue_output.writer);
    try std.testing.expectEqualStrings(cmpxchg_i8_extractvalue, i8_extractvalue_output.writer.buffered());

    const overflow_extractvalue =
        \\declare { i8, i1 } @llvm.umul.with.overflow.i8(i8, i8)
        \\
        \\define i1 @overflow_extractvalue(i8 %x) {
        \\entry:
        \\  %pair = call { i8, i1 } @llvm.umul.with.overflow.i8(i8 %x, i8 10)
        \\  %overflow = extractvalue { i8, i1 } %pair, 1
        \\  ret i1 %overflow
        \\}
        \\
    ;
    var overflow_module = try ir.Module.parse(std.testing.allocator, overflow_extractvalue);
    defer overflow_module.deinit();
    try overflow_module.verify();

    var overflow_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer overflow_output.deinit();
    try overflow_module.print(&overflow_output.writer);
    try std.testing.expectEqualStrings(overflow_extractvalue, overflow_output.writer.buffered());

    const insertvalue =
        \\define { ptr, i64 } @insert_aggregate(ptr %p) {
        \\entry:
        \\  %agg = insertvalue { ptr, i64 } poison, ptr %p, 0
        \\  ret { ptr, i64 } %agg
        \\}
        \\
    ;
    var insertvalue_module = try ir.Module.parse(std.testing.allocator, insertvalue);
    defer insertvalue_module.deinit();
    try insertvalue_module.verify();

    var insertvalue_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer insertvalue_output.deinit();
    try insertvalue_module.print(&insertvalue_output.writer);
    try std.testing.expectEqualStrings(insertvalue, insertvalue_output.writer.buffered());

    const bad_insertvalue =
        \\define { ptr, i64 } @bad_insert_aggregate(ptr %p) {
        \\entry:
        \\  %agg = insertvalue { ptr, i64 } poison, i64 1, 0
        \\  ret { ptr, i64 } %agg
        \\}
        \\
    ;
    try std.testing.expectError(error.TypeMismatch, ir.Module.parse(std.testing.allocator, bad_insertvalue));

    const aggregate_phi =
        \\define { ptr, i64 } @aggregate_phi(i1 %cond, { ptr, i64 } %value) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %result = phi { ptr, i64 } [ %value, %left ], [ { ptr inttoptr (i64 1 to ptr), i64 0 }, %right ]
        \\  ret { ptr, i64 } %result
        \\}
        \\
    ;
    var aggregate_phi_module = try ir.Module.parse(std.testing.allocator, aggregate_phi);
    defer aggregate_phi_module.deinit();
    try aggregate_phi_module.verify();

    var aggregate_phi_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aggregate_phi_output.deinit();
    try aggregate_phi_module.print(&aggregate_phi_output.writer);
    try std.testing.expectEqualStrings(aggregate_phi, aggregate_phi_output.writer.buffered());

    const bad_extractvalue =
        \\define i1 @bad_extractvalue(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %pair = cmpxchg ptr %p, i32 %old, i32 %new acquire monotonic
        \\  %success = extractvalue { i32, i1 } %pair, 2
        \\  ret i1 %success
        \\}
        \\
    ;
    try std.testing.expectError(error.TypeMismatch, ir.Module.parse(std.testing.allocator, bad_extractvalue));

    const fence =
        \\define void @memory_fence() {
        \\entry:
        \\  fence seq_cst
        \\  ret void
        \\}
        \\
    ;
    var fence_module = try ir.Module.parse(std.testing.allocator, fence);
    defer fence_module.deinit();
    try fence_module.verify();
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(fence_module.functions.items[0].blocks.items[0].instructions.items[0]));

    const source_backed_atomicrmw =
        \\source_filename = "atomics_inline_asm_debug"
        \\
        \\@atomics_inline_asm_debug.atomic_counter = private unnamed_addr global i32 0, align 4
        \\
        \\define i32 @atomics_inline_asm_debug.atomic_add(i32 %value) {
        \\entry:
        \\  %old = atomicrmw add ptr @atomics_inline_asm_debug.atomic_counter, i32 %value monotonic, align 4
        \\  ret i32 %old
        \\}
        \\
    ;
    var source_backed_module = try ir.Module.parse(std.testing.allocator, source_backed_atomicrmw);
    defer source_backed_module.deinit();
    try source_backed_module.verify();

    const constant_expr_atomic_pointer =
        \\@global = internal global [16 x i8] zeroinitializer, align 8
        \\
        \\define i32 @atomic_pointer_constexpr(i32 %old, i32 %new) {
        \\entry:
        \\  %rmw = atomicrmw xchg ptr getelementptr inbounds nuw (i8, ptr @global, i64 8), i32 %new release, align 4
        \\  %pair = cmpxchg ptr getelementptr inbounds nuw (i8, ptr @global, i64 8), i32 %old, i32 %new acquire monotonic, align 4
        \\  ret i32 %rmw
        \\}
        \\
    ;
    var constant_expr_module = try ir.Module.parse(std.testing.allocator, constant_expr_atomic_pointer);
    defer constant_expr_module.deinit();
    try constant_expr_module.verify();
}

test "parser preserves atomic syncscope on supported atomic operations" {
    const input =
        \\define i32 @memory_syncscope(i32 %a, ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  store atomic i32 %a, ptr %p syncscope("singlethread") release, align 4
        \\  %v = load atomic i32, ptr %p syncscope("singlethread") acquire, align 4
        \\  %rmw = atomicrmw add ptr %p, i32 %new syncscope("singlethread") monotonic, align 4
        \\  %pair = cmpxchg weak ptr %p, i32 %old, i32 %new syncscope("singlethread") acq_rel monotonic, align 4
        \\  fence syncscope("singlethread") seq_cst
        \\  ret i32 %v
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

test "verifier accepts LLVM-shaped atomic type surfaces" {
    const input =
        \\define ptr @atomic_pointer_xchg(ptr %p) {
        \\entry:
        \\  %v = atomicrmw xchg ptr %p, ptr null monotonic
        \\  ret ptr %v
        \\}
        \\
        \\define float @atomic_float_load_store(ptr %p, float %value) {
        \\entry:
        \\  store atomic float %value, ptr %p release, align 4
        \\  %loaded = load atomic float, ptr %p acquire, align 4
        \\  ret float %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
}

test "verifier rejects invalid atomic ordering combinations" {
    const invalid_load =
        \\define i32 @bad_atomic_load(ptr %p) {
        \\entry:
        \\  %v = load atomic i32, ptr %p release, align 4
        \\  ret i32 %v
        \\}
        \\
    ;
    var load_module = try ir.Module.parse(std.testing.allocator, invalid_load);
    defer load_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, load_module.verify());

    const invalid_store =
        \\define void @bad_atomic_store(ptr %p) {
        \\entry:
        \\  store atomic i32 1, ptr %p acquire, align 4
        \\  ret void
        \\}
        \\
    ;
    var store_module = try ir.Module.parse(std.testing.allocator, invalid_store);
    defer store_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, store_module.verify());

    const invalid_fence =
        \\define void @bad_fence() {
        \\entry:
        \\  fence monotonic
        \\  ret void
        \\}
        \\
    ;
    var fence_module = try ir.Module.parse(std.testing.allocator, invalid_fence);
    defer fence_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, fence_module.verify());

    const invalid_cmpxchg =
        \\define void @bad_cmpxchg(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %pair = cmpxchg ptr %p, i32 %old, i32 %new acquire release
        \\  ret void
        \\}
        \\
    ;
    var cmpxchg_module = try ir.Module.parse(std.testing.allocator, invalid_cmpxchg);
    defer cmpxchg_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, cmpxchg_module.verify());
}

test "verifier rejects LLVM invalid atomic memory types" {
    const invalid_load_i1 =
        \\define i1 @bad_atomic_load_i1(ptr %p) {
        \\entry:
        \\  %v = load atomic i1, ptr %p acquire, align 1
        \\  ret i1 %v
        \\}
        \\
    ;
    var load_i1_module = try ir.Module.parse(std.testing.allocator, invalid_load_i1);
    defer load_i1_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, load_i1_module.verify());

    const invalid_store_i24 =
        \\define void @bad_atomic_store_i24(ptr %p) {
        \\entry:
        \\  store atomic i24 1, ptr %p release, align 4
        \\  ret void
        \\}
        \\
    ;
    var store_i24_module = try ir.Module.parse(std.testing.allocator, invalid_store_i24);
    defer store_i24_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, store_i24_module.verify());

    const invalid_rmw_add_ptr =
        \\define ptr @bad_atomicrmw_add_ptr(ptr %p) {
        \\entry:
        \\  %v = atomicrmw add ptr %p, ptr null monotonic
        \\  ret ptr %v
        \\}
        \\
    ;
    var rmw_add_ptr_module = try ir.Module.parse(std.testing.allocator, invalid_rmw_add_ptr);
    defer rmw_add_ptr_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, rmw_add_ptr_module.verify());

    const invalid_rmw_fadd_i32 =
        \\define i32 @bad_atomicrmw_fadd_i32(ptr %p, i32 %value) {
        \\entry:
        \\  %v = atomicrmw fadd ptr %p, i32 %value monotonic
        \\  ret i32 %v
        \\}
        \\
    ;
    var rmw_fadd_i32_module = try ir.Module.parse(std.testing.allocator, invalid_rmw_fadd_i32);
    defer rmw_fadd_i32_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, rmw_fadd_i32_module.verify());

    const invalid_cmpxchg_float =
        \\define void @bad_cmpxchg_float(ptr %p, float %old, float %new) {
        \\entry:
        \\  %pair = cmpxchg ptr %p, float %old, float %new monotonic monotonic
        \\  ret void
        \\}
        \\
    ;
    var cmpxchg_float_module = try ir.Module.parse(std.testing.allocator, invalid_cmpxchg_float);
    defer cmpxchg_float_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, cmpxchg_float_module.verify());
}

test "parser preserves inline asm calls as side-effecting barriers" {
    const input =
        \\define void @inline_asm_barrier() {
        \\entry:
        \\  call void asm sideeffect "", "~{memory}"()
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(call.inline_asm != null);
    try std.testing.expect(call.inline_asm.?.sideeffect);
    try std.testing.expect(call.inline_asm.?.has_memory_clobber);
    try std.testing.expect(call.inline_asm.?.may_load);
    try std.testing.expect(call.inline_asm.?.may_store);
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(module.functions.items[0].blocks.items[0].instructions.items[0]));
    try std.testing.expectEqual(memory_effect.BarrierKind.inline_asm, memory_effect.barrierKind(module.functions.items[0].blocks.items[0].instructions.items[0]));

    const source_backed_inline_asm =
        \\source_filename = "atomics_inline_asm_debug"
        \\
        \\define i32 @atomics_inline_asm_debug.inline_asm_barrier(i32 %value) {
        \\entry:
        \\  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"()
        \\  ret i32 %value
        \\}
        \\
    ;
    var source_backed_module = try ir.Module.parse(std.testing.allocator, source_backed_inline_asm);
    defer source_backed_module.deinit();
    try source_backed_module.verify();
    const source_backed_call = source_backed_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(source_backed_call.inline_asm != null);
    try std.testing.expect(source_backed_call.inline_asm.?.has_memory_clobber);
    try std.testing.expect(source_backed_call.inline_asm.?.may_load);
    try std.testing.expect(source_backed_call.inline_asm.?.may_store);
}
