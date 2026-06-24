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
