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

fn testFunctionByName(module: ir.Module, name: []const u8) !ir.Function {
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, name)) return function;
    }
    return error.MissingTestFunction;
}
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

test "x86_64 generic cfg treats debug value intrinsic as object-code no-op" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
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
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 codegen lowers canonical accumulator loops without function-name dispatch" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @uncurated_accumulator(i32 %limit) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %index = phi i32 [ 0, %entry ], [ %index.next, %body ]
        \\  %sum = phi i32 [ 0, %entry ], [ %sum.next, %body ]
        \\  %continue = icmp ult i32 %index, %limit
        \\  br i1 %continue, label %body, label %exit
        \\body:
        \\  %sum.next = add i32 %sum, %index
        \\  %index.next = add i32 %index, 1
        \\  br label %loop
        \\exit:
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen lowers slice length extracted from typed AIR slice stack" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @slice_len_from_ptr(ptr %arg0, i64 %arg1) {
        \\entry:
        \\  %air2 = alloca ptr
        \\  store ptr %arg0, ptr %air2
        \\  %air6 = load ptr, ptr %air2
        \\  %air8 = sub i64 %arg1, 0
        \\  %air9_slice_ptr = insertvalue { ptr, i64 } undef, ptr %air6, 0
        \\  %air9 = insertvalue { ptr, i64 } %air9_slice_ptr, i64 %air8, 1
        \\  %air10 = alloca { ptr, i64 }
        \\  store { ptr, i64 } %air9, ptr %air10
        \\  %air15_slice_len_aggregate = load { ptr, i64 }, ptr %air10
        \\  %air16 = extractvalue { ptr, i64 } %air15_slice_len_aggregate, 1
        \\  ret i64 %air16
        \\}
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rsi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 codegen routes checked guard cfg through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc void @expanded_numeric_casts.integerPartOutOfBounds()
        \\
        \\define i32 @expanded_numeric_casts.expanded_int_from_float(float %arg0) {
        \\entry:
        \\  %below_min = fcmp ole float %arg0, -2147483904.0
        \\  %above_max = fcmp oge float %arg0, 2147483648.0
        \\  %out_of_bounds = or i1 %below_min, %above_max
        \\  br i1 %out_of_bounds, label %panic, label %ok
        \\panic:
        \\  call fastcc void @expanded_numeric_casts.integerPartOutOfBounds()
        \\  unreachable
        \\ok:
        \\  %converted = fptosi float %arg0 to i32
        \\  ret i32 %converted
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes guarded global add panic edges through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@message = private unnamed_addr constant [9 x i8] c"bad arg!!"
        \\@global_value = global i32 3
        \\
        \\declare void @debug.defaultPanic(ptr, i64)
        \\declare void @overflow()
        \\declare void @llvm.assume(i1)
        \\declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)
        \\
        \\define fastcc i32 @guarded_global_add(i32 %arg0) {
        \\entry:
        \\  %negative = icmp slt i32 %arg0, 0
        \\  br i1 %negative, label %panic, label %ok
        \\panic:
        \\  call void @llvm.assume(i1 1)
        \\  call void @debug.defaultPanic(ptr @message, i64 9)
        \\  unreachable
        \\ok:
        \\  %loaded = load i32, ptr @global_value
        \\  %sum = add i32 %loaded, %arg0
        \\  ret i32 %sum
        \\}
        \\
        \\define fastcc i32 @guarded_global_checked_add(i32 %arg0) {
        \\entry:
        \\  %negative = icmp slt i32 %arg0, 0
        \\  br i1 %negative, label %panic, label %ok
        \\panic:
        \\  call void @llvm.assume(i1 1)
        \\  call void @debug.defaultPanic(ptr @message, i64 9)
        \\  unreachable
        \\ok:
        \\  %loaded = load i32, ptr @global_value
        \\  %checked = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %loaded, i32 %arg0)
        \\  %overflowed = extractvalue { i32, i1 } %checked, 1
        \\  br i1 %overflowed, label %overflow, label %ret
        \\overflow:
        \\  call void @llvm.assume(i1 1)
        \\  call void @overflow()
        \\  unreachable
        \\ret:
        \\  %value = extractvalue { i32, i1 } %checked, 0
        \\  ret i32 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var unchecked = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer unchecked.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, unchecked.codegen_path);
    try expectMachineInstruction(unchecked.instructions.items, .{ .mov_imm_rsi = 9 });

    var checked = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[1],
    );
    defer checked.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, checked.codegen_path);
    try expectMachineInstruction(checked.instructions.items, .{ .mov_imm_rsi = 9 });
}

test "x86_64 codegen routes scalar numeric casts through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @widen(float %x) {
        \\entry:
        \\  %wide = fpext float %x to double
        \\  ret double %wide
        \\}
        \\
        \\define float @narrow(double %x) {
        \\entry:
        \\  %narrow = fptrunc double %x to float
        \\  ret float %narrow
        \\}
        \\
        \\define i32 @int_from_float(float %x) {
        \\entry:
        \\  %int = fptosi float %x to i32
        \\  ret i32 %int
        \\}
        \\
        \\define float @float_from_int(i32 %x) {
        \\entry:
        \\  %float = sitofp i32 %x to float
        \\  ret float %float
        \\}
        \\
        \\define double @double_from_unsigned(i32 %x) {
        \\entry:
        \\  %double = uitofp i32 %x to double
        \\  ret double %double
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items) |function| {
        var machine = try codegen.x86_64.lowerFunction(
            std.testing.allocator,
            module.target_triple.?,
            function,
        );
        defer machine.deinit(std.testing.allocator);
        try std.testing.expect(machine.instructions.items.len > 0);
        try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    }
}

test "x86_64 codegen routes smin intrinsic call through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @llvm.smin.i32(i32, i32)
        \\
        \\define i32 @any_signed_min(i32 %a, i32 %b) {
        \\entry:
        \\  %r = tail call i32 @llvm.smin.i32(i32 %a, i32 %b)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes unsigned saturating shift-left intrinsic through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @llvm.ushl.sat.i32(i32, i32)
        \\
        \\define i32 @any_unsigned_shl_sat(i32 %a) {
        \\entry:
        \\  %r = call i32 @llvm.ushl.sat.i32(i32 %a, i32 1)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const selected_function = try testFunctionByName(module, "any_unsigned_shl_sat");
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        selected_function,
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(
        codegen.x86_64.Instruction{ .ushl_sat_i32_edi_imm_eax = 1 },
        machine.instructions.items[0],
    );
}

test "x86_64 codegen routes signed-min select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_signed_min_select(i32 %a, i32 %b) {
        \\entry:
        \\  %lt = icmp slt i32 %a, %b
        \\  %r = select i1 %lt, i32 %a, i32 %b
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes nested i8 error select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @generic_error_select(i8 %tag) {
        \\entry:
        \\  %is_low = icmp eq i8 %tag, 1
        \\  %is_zero = icmp eq i8 %tag, 0
        \\  %error_value = select i1 %is_low, i32 -1, i32 -2
        \\  %result = select i1 %is_zero, i32 0, i32 %error_value
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes nested i8 i64 classifier select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @generic_i64_classifier(i8 %tag) {
        \\entry:
        \\  %is_low = icmp eq i8 %tag, 1
        \\  %is_zero = icmp eq i8 %tag, 0
        \\  %error_value = select i1 %is_low, i64 1, i64 2
        \\  %result = select i1 %is_zero, i64 0, i64 %error_value
        \\  ret i64 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes void global store through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@hidden = global i32 0
        \\
        \\define void @store_hidden(i32 %value) {
        \\entry:
        \\  store i32 %value, ptr @hidden
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes aggregate pair pack through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @make_pair(i32 %a, i32 %b) {
        \\entry:
        \\  %high = zext i32 %b to i64
        \\  %shift = shl i64 %high, 32
        \\  %low = zext i32 %a to i64
        \\  %result = or i64 %shift, %low
        \\  ret i64 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes aggregate pair first-field unpack through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @pair_first(i64 %pair) {
        \\entry:
        \\  %first = trunc i64 %pair to i32
        \\  ret i32 %first
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes boolean branch-mix select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @generic_branch_mix(i32 %a, i32 %b, i1 %flag) {
        \\entry:
        \\  %neg = sub i32 0, %b
        \\  %delta = select i1 %flag, i32 %b, i32 %neg
        \\  %result = add i32 %a, %delta
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes constant i8 switch through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @generic_dense_switch(i8 %value) {
        \\entry:
        \\  switch i8 %value, label %default [
        \\    i8 0, label %case0
        \\    i8 1, label %case1
        \\    i8 2, label %case2
        \\  ]
        \\case0:
        \\  ret i32 11
        \\case1:
        \\  ret i32 13
        \\case2:
        \\  ret i32 17
        \\default:
        \\  ret i32 23
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes single-block fp binary through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @float_mul(double %a, double %b) {
        \\entry:
        \\  %product = fmul double %a, %b
        \\  ret double %product
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes single-block scalar select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @expanded_optional_branch(i32 %tag, i32 %payload) {
        \\entry:
        \\  %is_null = icmp eq i32 %tag, 0
        \\  %result = select i1 %is_null, i32 -5, i32 %payload
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);

    const expected =
        "\t.text\n" ++
        "\t.globl expanded_optional_branch\n" ++
        "expanded_optional_branch:\n" ++
        "\ttestl %edi, %edi\n" ++
        "\tje .Lexpanded_optional_branch_generic_cfg_select_true\n" ++
        "\tmovl %esi, %eax\n" ++
        "\tjmp .Lexpanded_optional_branch_generic_cfg_select_end\n" ++
        ".Lexpanded_optional_branch_generic_cfg_select_true:\n" ++
        "\tmovl $-5, %eax\n" ++
        ".Lexpanded_optional_branch_generic_cfg_select_end:\n" ++
        "\tretq\n";
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "x86_64 codegen rejects unsupported scalar select predicate explicitly" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @unsupported_select(i32 %a, i32 %b) {
        \\entry:
        \\  %is_le = icmp sle i32 %a, %b
        \\  %result = select i1 %is_le, i32 %a, i32 %b
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenInstruction,
        codegen.x86_64.lowerFunction(
            std.testing.allocator,
            module.target_triple.?,
            module.functions.items[0],
        ),
    );
}

test "x86_64 codegen routes global i32 load store reload through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@counter = global i32 3
        \\
        \\define i32 @update_global(i32 %arg0) {
        \\entry:
        \\  %loaded = load i32, ptr @counter
        \\  %next = add i32 %loaded, %arg0
        \\  store i32 %next, ptr @counter
        \\  %reloaded = load i32, ptr @counter
        \\  ret i32 %reloaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes pointer load branch through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @pointer_load_branch(i32 %flag, ptr %left, ptr %right) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %left_value = load i32, ptr %left
        \\  br label %merge
        \\else:
        \\  %right_value = load i32, ptr %right
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %left_value, %then ], [ %right_value, %else ]
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes guarded dynamic pointer load through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @guarded_dynamic_load(ptr %values, i64 %len, i64 %index) {
        \\entry:
        \\  %cmp = icmp uge i64 %index, %len
        \\  br i1 %cmp, label %fail, label %ok
        \\fail:
        \\  ret i32 -1
        \\ok:
        \\  %element = getelementptr i32, ptr %values, i64 %index
        \\  %loaded = load i32, ptr %element
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes branch phi immediate add through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @branch_phi_add(i32 %flag, ptr %payload) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %loaded = load i32, ptr %payload
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %loaded, %then ], [ -12, %else ]
        \\  %biased = add i32 %result, 1
        \\  ret i32 %biased
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes optional pointer load plus add through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @optional_pointer_add(ptr %arg0) {
        \\entry:
        \\  %is_null = icmp eq ptr %arg0, null
        \\  br i1 %is_null, label %merge, label %load
        \\load:
        \\  %loaded = load i32, ptr %arg0
        \\  %adjusted = add i32 %loaded, 8
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ -1, %entry ], [ %adjusted, %load ]
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes fp binary with unused scalar param through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define float @float_add_unused_bool(float %a, float %b, i1 %unused) {
        \\entry:
        \\  %sum = fadd float %a, %b
        \\  ret float %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes byte table lookup through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@__anon_test_table = private unnamed_addr constant [4 x i8] c"\00\04\08\0C", align 4
        \\
        \\define i32 @byte_table_lookup(i8 %index) {
        \\entry:
        \\  %masked = and i8 %index, 3
        \\  %idx = zext i8 %masked to i64
        \\  %ptr = getelementptr inbounds [4 x i8], ptr @__anon_test_table, i64 0, i64 %idx
        \\  %byte = load i8, ptr %ptr
        \\  %value = zext i8 %byte to i32
        \\  ret i32 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes store branch load after store through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @store_branch_reload(i32 %flag, ptr %out, i32 %left, i32 %right) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  store i32 %left, ptr %out
        \\  br label %merge
        \\else:
        \\  store i32 %right, ptr %out
        \\  br label %merge
        \\merge:
        \\  %loaded = load i32, ptr %out
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes direct-call branch merge through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i32 @plus(i32)
        \\declare i32 @minus(i32)
        \\
        \\define i32 @call_branch_merge(i32 %flag, i32 %value) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %a = call fastcc i32 @plus(i32 %value)
        \\  br label %merge
        \\else:
        \\  %b = call i32 @minus(i32 %value)
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %a, %then ], [ %b, %else ]
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes pointer select load through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @pointer_select_load(i32 %flag, ptr %left, ptr %right) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  %chosen = select i1 %cond, ptr %left, ptr %right
        \\  %loaded = load i32, ptr %chosen
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes conditional slice accumulation loop through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @conditional_slice_sum(ptr %values, i64 %len, i32 %limit) {
        \\entry:
        \\  %is_empty = icmp eq i64 %len, 0
        \\  br i1 %is_empty, label %zero, label %loop
        \\loop:
        \\  ret i32 0
        \\zero:
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}
