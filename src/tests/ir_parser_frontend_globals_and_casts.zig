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

test "parser preserves hidden global aliases" {
    const input =
        \\@memmove = weak_odr hidden alias ptr (ptr, ptr, i64), ptr @compiler_rt.memmove.memmoveFast
        \\
        \\define internal ptr @compiler_rt.memmove.memmoveFast(ptr %dest, ptr %src, i64 %len) {
        \\entry:
        \\  ret ptr %dest
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqual(@as(usize, 1), module.aliases.items.len);
    try std.testing.expectEqual(ir.FunctionLinkage.weak_odr, module.aliases.items[0].linkage);
    try std.testing.expectEqual(ir.FunctionVisibility.hidden, module.aliases.items[0].visibility);
    try std.testing.expectEqualStrings("ptr (ptr, ptr, i64)", module.aliases.items[0].aliased_ty);
    try std.testing.expectEqualStrings("compiler_rt.memmove.memmoveFast", module.aliases.items[0].target);

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
