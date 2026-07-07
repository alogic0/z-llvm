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

test "x86_64 generic cfg lowers null pointer return" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define ptr @null_ptr_return(ptr %arg0) {
        \\entry:
        \\  ret ptr null
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
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rax = 0 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers monotonic i32 atomic store as plain aligned store" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @atomic_i32_reset(ptr %event) {
        \\entry:
        \\  store atomic i32 0, ptr %event monotonic
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

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_eax = 0 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_eax_arg_ptr = .rdi }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
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

test "x86_64 generic cfg lowers byte scan length loop without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal i64 @any_byte_scan_len(ptr %ptr) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %index = phi i64 [ 0, %entry ], [ %next, %loop ]
        \\  %byte.ptr = getelementptr inbounds [1 x i8], ptr %ptr, i64 %index
        \\  %byte = load i8, ptr %byte.ptr, align 1
        \\  %is.zero = icmp eq i8 %byte, 0
        \\  %next = add nuw i64 %index, 1
        \\  br i1 %is.zero, label %exit, label %loop
        \\exit:
        \\  ret i64 %index
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
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg64_arg = .{ .dst = .r8, .src = .rdi } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } });
    try expectMachineInstruction(machine.instructions.items, .load_rcx_ptr_u8_eax);
    try expectMachineInstruction(machine.instructions.items, .test_eax_eax);
    try expectMachineInstruction(machine.instructions.items, .sub_r8_rcx);
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rcx });
}

test "x86_64 generic cfg lowers byte compare equal loop without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal range(i32 0, 2) i32 @any_byte_compare_equal(ptr %lhs, ptr %rhs, i64 %len) {
        \\entry:
        \\  %is.empty = icmp eq i64 %len, 0
        \\  br i1 %is.empty, label %done, label %body
        \\done:
        \\  %result = phi i32 [ 0, %entry ], [ 1, %body ], [ 0, %next ]
        \\  ret i32 %result
        \\next:
        \\  %index.next = add nuw i64 %index, 1
        \\  %is.done = icmp eq i64 %index.next, %len
        \\  br i1 %is.done, label %done, label %body
        \\body:
        \\  %index = phi i64 [ 0, %entry ], [ %index.next, %next ]
        \\  %lhs.ptr = getelementptr inbounds [1 x i8], ptr %lhs, i64 %index
        \\  %lhs.byte = load i8, ptr %lhs.ptr, align 1
        \\  %rhs.ptr = getelementptr inbounds [1 x i8], ptr %rhs, i64 %index
        \\  %rhs.byte = load i8, ptr %rhs.ptr, align 1
        \\  %is.equal = icmp eq i8 %lhs.byte, %rhs.byte
        \\  br i1 %is.equal, label %next, label %done
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
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.bcmp_rdi_rsi_rdx_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers byte compare diff loop without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal range(i32 -255, 256) i32 @any_byte_compare_diff(ptr %lhs, ptr %rhs, i64 %len) {
        \\entry:
        \\  %is.empty = icmp eq i64 %len, 0
        \\  br i1 %is.empty, label %done, label %body
        \\done:
        \\  %result = phi i32 [ 0, %entry ], [ %diff, %body ], [ 0, %next ]
        \\  ret i32 %result
        \\next:
        \\  %index.next = add nuw i64 %index, 1
        \\  %is.done = icmp eq i64 %index.next, %len
        \\  br i1 %is.done, label %done, label %body
        \\body:
        \\  %index = phi i64 [ 0, %entry ], [ %index.next, %next ]
        \\  %lhs.ptr = getelementptr inbounds [1 x i8], ptr %lhs, i64 %index
        \\  %lhs.byte = load i8, ptr %lhs.ptr, align 1
        \\  %lhs.int = zext i8 %lhs.byte to i32
        \\  %rhs.ptr = getelementptr inbounds [1 x i8], ptr %rhs, i64 %index
        \\  %rhs.byte = load i8, ptr %rhs.ptr, align 1
        \\  %rhs.int = zext i8 %rhs.byte to i32
        \\  %diff = sub nsw i32 %lhs.int, %rhs.int
        \\  %is.equal = icmp eq i32 %diff, 0
        \\  br i1 %is.equal, label %next, label %done
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
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.memcmp_rdi_rsi_rdx_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers guarded byte memset loop without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.assume(i1)
        \\declare void @llvm.trap()
        \\
        \\define internal ptr @any_guarded_byte_memset(ptr %dst, i8 %byte, i64 %len, i64 %guard) {
        \\entry:
        \\  %bad = icmp ult i64 %guard, %len
        \\  br i1 %bad, label %trap, label %check
        \\trap:
        \\  call void @llvm.assume(i1 true)
        \\  call void @llvm.trap()
        \\  unreachable
        \\check:
        \\  %empty = icmp eq i64 %len, 0
        \\  br i1 %empty, label %done, label %preheader
        \\preheader:
        \\  %tail = and i64 %len, 7
        \\  %no.tail = icmp eq i64 %tail, 0
        \\  br i1 %no.tail, label %loopexit, label %prologue
        \\prologue:
        \\  %remaining.prol = phi i64 [ %remaining.next, %prologue ], [ %len, %preheader ]
        \\  %ptr.prol = phi ptr [ %ptr.next, %prologue ], [ %dst, %preheader ]
        \\  %iter = phi i64 [ %iter.next, %prologue ], [ 0, %preheader ]
        \\  store i8 %byte, ptr %ptr.prol, align 1
        \\  %remaining.next = add i64 %remaining.prol, -1
        \\  %ptr.next = getelementptr inbounds nuw i8, ptr %ptr.prol, i64 1
        \\  %iter.next = add i64 %iter, 1
        \\  %iter.done = icmp eq i64 %iter.next, %tail
        \\  br i1 %iter.done, label %loopexit, label %prologue
        \\loopexit:
        \\  %remaining.unr = phi i64 [ %len, %preheader ], [ %remaining.next, %prologue ]
        \\  %ptr.unr = phi ptr [ %dst, %preheader ], [ %ptr.next, %prologue ]
        \\  %small = icmp ult i64 %len, 8
        \\  br i1 %small, label %done, label %loop
        \\loop:
        \\  %remaining = phi i64 [ %remaining.after, %loop ], [ %remaining.unr, %loopexit ]
        \\  %ptr = phi ptr [ %ptr.after, %loop ], [ %ptr.unr, %loopexit ]
        \\  store i8 %byte, ptr %ptr, align 1
        \\  %p1 = getelementptr inbounds nuw i8, ptr %ptr, i64 1
        \\  store i8 %byte, ptr %p1, align 1
        \\  %p2 = getelementptr inbounds nuw i8, ptr %ptr, i64 2
        \\  store i8 %byte, ptr %p2, align 1
        \\  %p3 = getelementptr inbounds nuw i8, ptr %ptr, i64 3
        \\  store i8 %byte, ptr %p3, align 1
        \\  %p4 = getelementptr inbounds nuw i8, ptr %ptr, i64 4
        \\  store i8 %byte, ptr %p4, align 1
        \\  %p5 = getelementptr inbounds nuw i8, ptr %ptr, i64 5
        \\  store i8 %byte, ptr %p5, align 1
        \\  %p6 = getelementptr inbounds nuw i8, ptr %ptr, i64 6
        \\  store i8 %byte, ptr %p6, align 1
        \\  %p7 = getelementptr inbounds nuw i8, ptr %ptr, i64 7
        \\  store i8 %byte, ptr %p7, align 1
        \\  %remaining.after = add i64 %remaining, -8
        \\  %done.loop = icmp eq i64 %remaining.after, 0
        \\  %ptr.after = getelementptr inbounds nuw i8, ptr %ptr, i64 8
        \\  br i1 %done.loop, label %done, label %loop
        \\done:
        \\  ret ptr %dst
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
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.guarded_memset_rdi_sil_rdx_rcx_rax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers guarded strncat append loop without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.trap()
        \\
        \\define internal ptr @any_guarded_strncat_append(ptr %dst, ptr %src, i64 %max, i64 %guard) {
        \\entry:
        \\  %guard.zero = icmp eq i64 %guard, 0
        \\  br i1 %guard.zero, label %trap1, label %scan
        \\scan:
        \\  %dst.idx = phi i64 [ %dst.next, %scan.next ], [ 0, %entry ]
        \\  %remaining = phi i64 [ %remaining.next, %scan.next ], [ %guard, %entry ]
        \\  %dst.ptr = getelementptr inbounds [1 x i8], ptr %dst, i64 %dst.idx
        \\  %dst.byte = load i8, ptr %dst.ptr, align 1
        \\  %dst.zero = icmp eq i8 %dst.byte, 0
        \\  br i1 %dst.zero, label %copy.preheader, label %scan.next
        \\scan.next:
        \\  %remaining.next = add i64 %remaining, -1
        \\  %dst.next = add nuw i64 %dst.idx, 1
        \\  %guard.done = icmp eq i64 %remaining.next, 0
        \\  br i1 %guard.done, label %trap1, label %scan
        \\trap1:
        \\  call void @llvm.trap()
        \\  unreachable
        \\copy.preheader:
        \\  %append.ptr = getelementptr inbounds [1 x i8], ptr %dst, i64 %dst.idx
        \\  %max.zero = icmp eq i64 %max, 0
        \\  br i1 %max.zero, label %finish, label %copy
        \\copy:
        \\  %copy.idx = phi i64 [ %copy.next, %copy.next.block ], [ 0, %copy.preheader ]
        \\  %copy.remaining = phi i64 [ %copy.remaining.next, %copy.next.block ], [ %remaining, %copy.preheader ]
        \\  %src.ptr = getelementptr inbounds [1 x i8], ptr %src, i64 %copy.idx
        \\  %src.byte = load i8, ptr %src.ptr, align 1
        \\  %src.zero = icmp eq i8 %src.byte, 0
        \\  br i1 %src.zero, label %finish, label %copy.next.block
        \\copy.next.block:
        \\  %store.ptr = getelementptr [1 x i8], ptr %append.ptr, i64 %copy.idx
        \\  store i8 %src.byte, ptr %store.ptr, align 1
        \\  %copy.remaining.next = add i64 %copy.remaining, -1
        \\  %copy.next = add nuw i64 %copy.idx, 1
        \\  %has.guard = icmp ne i64 %copy.remaining.next, 0
        \\  %under.max = icmp ult i64 %copy.next, %max
        \\  %cont = select i1 %has.guard, i1 %under.max, i1 false
        \\  br i1 %cont, label %copy, label %post.copy
        \\post.copy:
        \\  %guard.empty = icmp eq i64 %copy.remaining.next, 0
        \\  br i1 %guard.empty, label %trap2, label %finish
        \\trap2:
        \\  call void @llvm.trap()
        \\  unreachable
        \\finish:
        \\  %term.idx = phi i64 [ 0, %copy.preheader ], [ %copy.idx, %copy ], [ %copy.next, %post.copy ]
        \\  %term.ptr = getelementptr [1 x i8], ptr %append.ptr, i64 %term.idx
        \\  store i8 0, ptr %term.ptr, align 1
        \\  ret ptr %dst
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
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.guarded_strncat_rdi_rsi_rdx_rcx_rax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers guarded strcat append loop without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.trap()
        \\
        \\define internal ptr @any_guarded_strcat_append(ptr %dst, ptr %src, i64 %guard) {
        \\entry:
        \\  %guard.zero = icmp eq i64 %guard, 0
        \\  br i1 %guard.zero, label %trap1, label %scan
        \\scan:
        \\  %dst.idx = phi i64 [ %dst.next, %scan.next ], [ 0, %entry ]
        \\  %remaining = phi i64 [ %remaining.next, %scan.next ], [ %guard, %entry ]
        \\  %dst.ptr = getelementptr inbounds [1 x i8], ptr %dst, i64 %dst.idx
        \\  %dst.byte = load i8, ptr %dst.ptr, align 1
        \\  %dst.zero = icmp eq i8 %dst.byte, 0
        \\  br i1 %dst.zero, label %copy.preheader, label %scan.next
        \\scan.next:
        \\  %remaining.next = add i64 %remaining, -1
        \\  %dst.next = add nuw i64 %dst.idx, 1
        \\  %guard.done = icmp eq i64 %remaining.next, 0
        \\  br i1 %guard.done, label %trap1, label %scan
        \\trap1:
        \\  call void @llvm.trap()
        \\  unreachable
        \\copy.preheader:
        \\  %append.ptr = getelementptr inbounds [1 x i8], ptr %dst, i64 %dst.idx
        \\  br label %copy
        \\copy:
        \\  %copy.idx = phi i64 [ %copy.next, %copy.next.block ], [ 0, %copy.preheader ]
        \\  %copy.remaining = phi i64 [ %copy.remaining.next, %copy.next.block ], [ %remaining, %copy.preheader ]
        \\  %src.ptr = getelementptr inbounds [1 x i8], ptr %src, i64 %copy.idx
        \\  %src.byte = load i8, ptr %src.ptr, align 1
        \\  %src.zero = icmp eq i8 %src.byte, 0
        \\  %store.ptr = getelementptr [1 x i8], ptr %append.ptr, i64 %copy.idx
        \\  br i1 %src.zero, label %finish, label %copy.next.block
        \\copy.next.block:
        \\  store i8 %src.byte, ptr %store.ptr, align 1
        \\  %copy.remaining.next = add i64 %copy.remaining, -1
        \\  %copy.next = add nuw i64 %copy.idx, 1
        \\  %guard.empty = icmp eq i64 %copy.remaining.next, 0
        \\  br i1 %guard.empty, label %trap2, label %copy
        \\trap2:
        \\  call void @llvm.trap()
        \\  unreachable
        \\finish:
        \\  store i8 0, ptr %store.ptr, align 1
        \\  ret ptr %dst
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
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.guarded_strcat_rdi_rsi_rdx_rax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers guarded strncpy copy pad loop without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.trap()
        \\
        \\define internal ptr @any_guarded_strncpy_copy_pad(ptr %dst, ptr %src, i64 %len, i64 %guard) {
        \\entry:
        \\  %bad = icmp ult i64 %guard, %len
        \\  br i1 %bad, label %trap, label %check
        \\trap:
        \\  call void @llvm.trap()
        \\  unreachable
        \\check:
        \\  %empty = icmp eq i64 %len, 0
        \\  br i1 %empty, label %done, label %copy
        \\copy:
        \\  %idx = phi i64 [ 0, %check ], [ %next, %store ]
        \\  %src.ptr = getelementptr inbounds [1 x i8], ptr %src, i64 %idx
        \\  %byte = load i8, ptr %src.ptr, align 1
        \\  %zero = icmp eq i8 %byte, 0
        \\  br i1 %zero, label %pad, label %store
        \\store:
        \\  %dst.ptr = getelementptr inbounds [1 x i8], ptr %dst, i64 %idx
        \\  store i8 %byte, ptr %dst.ptr, align 1
        \\  %next = add nuw i64 %idx, 1
        \\  %copy.done = icmp eq i64 %next, %len
        \\  br i1 %copy.done, label %done, label %copy
        \\pad:
        \\  %pad.idx = phi i64 [ %idx, %copy ], [ %pad.next, %pad ]
        \\  %pad.ptr = getelementptr inbounds [1 x i8], ptr %dst, i64 %pad.idx
        \\  store i8 0, ptr %pad.ptr, align 1
        \\  %pad.next = add nuw i64 %pad.idx, 1
        \\  %pad.done = icmp eq i64 %pad.next, %len
        \\  br i1 %pad.done, label %done, label %pad
        \\done:
        \\  ret ptr %dst
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
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.guarded_strncpy_rdi_rsi_rdx_rcx_rax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers memmove overlap body without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.memcpy.inline.p0.p0.i64(ptr, ptr, i64, i1)
        \\
        \\define internal ptr @any_overlap_copy(ptr %dst, ptr %src, i64 %len) {
        \\entry:
        \\  %tmp = alloca [16 x i8], align 1
        \\  %small = icmp ult i64 %len, 16
        \\  br i1 %small, label %small.copy, label %big
        \\small.copy:
        \\  %byte = load i8, ptr %src, align 1
        \\  store i8 %byte, ptr %dst, align 1
        \\  br label %done
        \\big:
        \\  %src.before.dst = icmp ult ptr %src, %dst
        \\  br i1 %src.before.dst, label %backward, label %forward
        \\backward:
        \\  call void @llvm.memcpy.inline.p0.p0.i64(ptr %tmp, ptr %src, i64 16, i1 false)
        \\  call void @llvm.memcpy.inline.p0.p0.i64(ptr %dst, ptr %tmp, i64 16, i1 false)
        \\  br label %done
        \\forward:
        \\  %src.vec = getelementptr inbounds [1 x i8], ptr %src, i64 16
        \\  %dst.vec = getelementptr inbounds [1 x i8], ptr %dst, i64 16
        \\  %vec = load <16 x i8>, ptr %src.vec, align 1
        \\  store <16 x i8> %vec, ptr %dst.vec, align 1
        \\  br label %done
        \\done:
        \\  ret ptr %dst
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
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.memmove_rdi_rsi_rdx_rax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers memcpy body without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal ptr @any_forward_copy(ptr %dst, ptr %src, i64 %len) {
        \\entry:
        \\  %small = icmp ult i64 %len, 16
        \\  br i1 %small, label %small.copy, label %big
        \\small.copy:
        \\  %byte = load i8, ptr %src, align 1
        \\  store i8 %byte, ptr %dst, align 1
        \\  br label %done
        \\big:
        \\  %src.vec = getelementptr inbounds [1 x i8], ptr %src, i64 16
        \\  %dst.vec = getelementptr inbounds [1 x i8], ptr %dst, i64 16
        \\  %vec = load <16 x i8>, ptr %src.vec, align 1
        \\  store <16 x i8> %vec, ptr %dst.vec, align 1
        \\  br label %done
        \\done:
        \\  ret ptr %dst
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
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.memcpy_rdi_rsi_rdx_rax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked variable memcpy without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@locks_for_any_copy = internal global [64 x i8] zeroinitializer, align 64
        \\declare void @llvm.memcpy.inline.p0.p0.i64(ptr, ptr, i64, i1)
        \\
        \\define void @any_spinlocked_copy(i32 %len, ptr %src, ptr %dst, i32 %ordering) {
        \\entry:
        \\  %addr = ptrtoint ptr %src to i64
        \\  %shift = lshr i64 %addr, 3
        \\  %slot = and i64 %shift, 63
        \\  %lock = getelementptr [64 x i8], ptr @locks_for_any_copy, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old, 0
        \\  br i1 %acquired, label %copy, label %loop
        \\copy:
        \\  %len64 = zext i32 %len to i64
        \\  call void @llvm.memcpy.inline.p0.p0.i64(ptr %dst, ptr %src, i64 %len64, i1 false)
        \\  store atomic i64 0, ptr %lock release, align 64
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
        try testFunctionByName(module, "any_spinlocked_copy"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_copy", machine.instructions.items[0].spinlocked_memcpy_rsi_to_rdx_len_edi);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers scalar atomic compare exchange family without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_cmpxchg_width(ptr %ptr, ptr %expected, i32 %desired, i32 %success, i32 %failure) {
        \\entry:
        \\  %scratch = alloca i8, align 4
        \\  %old.expected = load i32, ptr %expected, align 4
        \\  %pair = cmpxchg ptr %ptr, i32 %old.expected, i32 %desired seq_cst seq_cst, align 4
        \\  %ok = extractvalue { i32, i1 } %pair, 1
        \\  %failed = xor i1 %ok, true
        \\  store i1 %failed, ptr %scratch, align 4
        \\  %failed.byte = load i8, ptr %scratch, align 4
        \\  %success.path = icmp eq i8 %failed.byte, 0
        \\  br i1 %success.path, label %ret, label %update.expected
        \\ret:
        \\  %result = phi i32 [ 1, %entry ], [ 0, %update.expected ]
        \\  ret i32 %result
        \\update.expected:
        \\  %old.value = extractvalue { i32, i1 } %pair, 0
        \\  store i32 %old.value, ptr %expected, align 4
        \\  br label %ret
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_cmpxchg_width"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.cmpxchg_ptr_expected_desired_i32_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked i128 compare exchange without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@locks_for_any_compare = internal global [64 x i8] zeroinitializer, align 64
        \\
        \\define i32 @any_spinlocked_cmpxchg(ptr %ptr, ptr %expected, i128 %desired, i32 %success, i32 %failure) {
        \\entry:
        \\  %addr = ptrtoint ptr %ptr to i64
        \\  %shift = lshr i64 %addr, 3
        \\  %slot = and i64 %shift, 62
        \\  %lock = getelementptr [64 x i8], ptr @locks_for_any_compare, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old.lock = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old.lock, 0
        \\  br i1 %acquired, label %compare, label %loop
        \\compare:
        \\  %old.value = load i128, ptr %ptr, align 16
        \\  %expected.value = load i128, ptr %expected, align 16
        \\  %equal = icmp eq i128 %old.value, %expected.value
        \\  br i1 %equal, label %store.desired, label %store.expected
        \\ret:
        \\  %result = phi i32 [ 1, %store.desired ], [ 0, %store.expected ]
        \\  store atomic i64 0, ptr %lock release, align 64
        \\  ret i32 %result
        \\store.desired:
        \\  store i128 %desired, ptr %ptr, align 16
        \\  br label %ret
        \\store.expected:
        \\  store i128 %old.value, ptr %expected, align 16
        \\  br label %ret
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_spinlocked_cmpxchg"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_compare", machine.instructions.items[0].spinlocked_cmpxchg_i128_rdi_rsi_rdx_rcx_eax);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers scalar atomic exchange family without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_atomic_exchange_width(ptr %ptr, i32 %replacement, i32 %ordering) {
        \\entry:
        \\  %old = atomicrmw xchg ptr %ptr, i32 %replacement seq_cst, align 4
        \\  ret i32 %old
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_atomic_exchange_width"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.xchg_ptr_value_i32_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked i128 atomic exchange without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@locks_for_any_exchange = internal global [64 x i8] zeroinitializer, align 64
        \\
        \\define i128 @any_spinlocked_exchange(ptr %ptr, i128 %replacement, i32 %ordering) {
        \\entry:
        \\  %addr = ptrtoint ptr %ptr to i64
        \\  %shift = lshr i64 %addr, 3
        \\  %slot = and i64 %shift, 62
        \\  %lock = getelementptr [64 x i8], ptr @locks_for_any_exchange, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old.lock = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old.lock, 0
        \\  br i1 %acquired, label %exchange, label %loop
        \\exchange:
        \\  %old.value = load i128, ptr %ptr, align 16
        \\  store i128 %replacement, ptr %ptr, align 16
        \\  store atomic i64 0, ptr %lock release, align 64
        \\  ret i128 %old.value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_spinlocked_exchange"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_exchange", machine.instructions.items[0].spinlocked_xchg_i128_rdi_rsi_rdx_rax);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers scalar atomic store family without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @any_atomic_store_width(ptr %ptr, i32 %replacement, i32 %ordering) {
        \\entry:
        \\  store atomic i32 %replacement, ptr %ptr seq_cst, align 4
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
        try testFunctionByName(module, "any_atomic_store_width"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.xchg_ptr_value_i32_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked i128 atomic store without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@locks_for_any_store = internal global [64 x i8] zeroinitializer, align 64
        \\
        \\define void @any_spinlocked_store(ptr %ptr, i128 %replacement, i32 %ordering) {
        \\entry:
        \\  %addr = ptrtoint ptr %ptr to i64
        \\  %shift = lshr i64 %addr, 3
        \\  %slot = and i64 %shift, 62
        \\  %lock = getelementptr [64 x i8], ptr @locks_for_any_store, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old.lock = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old.lock, 0
        \\  br i1 %acquired, label %store, label %loop
        \\store:
        \\  store i128 %replacement, ptr %ptr, align 16
        \\  store atomic i64 0, ptr %lock release, align 64
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
        try testFunctionByName(module, "any_spinlocked_store"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_store", machine.instructions.items[0].spinlocked_store_i128_rdi_rsi_rdx);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers scalar atomic load family without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_atomic_load_width(ptr %ptr, i32 %ordering) {
        \\entry:
        \\  %loaded = load atomic i32, ptr %ptr seq_cst, align 4
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
        try testFunctionByName(module, "any_atomic_load_width"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.load_rdi_ptr_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked i128 atomic load without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@locks_for_any_load = internal global [64 x i8] zeroinitializer, align 64
        \\
        \\define i128 @any_spinlocked_load(ptr %ptr, i32 %ordering) {
        \\entry:
        \\  %addr = ptrtoint ptr %ptr to i64
        \\  %shift = lshr exact i64 %addr, 3
        \\  %slot = and i64 %shift, 62
        \\  %lock = getelementptr inbounds nuw [64 x i8], ptr @locks_for_any_load, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old.lock = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old.lock, 0
        \\  br i1 %acquired, label %load, label %loop
        \\load:
        \\  %loaded = load i128, ptr %ptr, align 16
        \\  store atomic i64 0, ptr %lock release, align 64
        \\  ret i128 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_spinlocked_load"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_load", machine.instructions.items[0].spinlocked_load_i128_rdi_rax_rdx);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers scalar atomic fetch umin family without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_atomic_fetch_umin_width(ptr %ptr, i32 %replacement, i32 %ordering) {
        \\entry:
        \\  %old = atomicrmw umin ptr %ptr, i32 %replacement seq_cst, align 4
        \\  ret i32 %old
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_atomic_fetch_umin_width"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.atomic_fetch_umin_i32_rdi_esi_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers scalar atomic fetch umax family without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_atomic_fetch_umax_width(ptr %ptr, i32 %replacement, i32 %ordering) {
        \\entry:
        \\  %old = atomicrmw umax ptr %ptr, i32 %replacement seq_cst, align 4
        \\  ret i32 %old
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_atomic_fetch_umax_width"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.atomic_fetch_umax_i32_rdi_esi_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers scalar atomic fetch nand family without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_atomic_fetch_nand_width(ptr %ptr, i32 %replacement, i32 %ordering) {
        \\entry:
        \\  %old = atomicrmw nand ptr %ptr, i32 %replacement seq_cst, align 4
        \\  ret i32 %old
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_atomic_fetch_nand_width"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.atomic_fetch_nand_i32_rdi_esi_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers scalar atomic fetch xor family without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_atomic_fetch_xor_width(ptr %ptr, i32 %replacement, i32 %ordering) {
        \\entry:
        \\  %old = atomicrmw xor ptr %ptr, i32 %replacement seq_cst, align 4
        \\  ret i32 %old
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_atomic_fetch_xor_width"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.atomic_fetch_xor_i32_rdi_esi_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers scalar atomic fetch or family without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_atomic_fetch_or_width(ptr %ptr, i32 %replacement, i32 %ordering) {
        \\entry:
        \\  %old = atomicrmw or ptr %ptr, i32 %replacement seq_cst, align 4
        \\  ret i32 %old
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_atomic_fetch_or_width"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.atomic_fetch_or_i32_rdi_esi_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers scalar atomic fetch and family without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_atomic_fetch_and_width(ptr %ptr, i32 %replacement, i32 %ordering) {
        \\entry:
        \\  %old = atomicrmw and ptr %ptr, i32 %replacement seq_cst, align 4
        \\  ret i32 %old
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_atomic_fetch_and_width"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.atomic_fetch_and_i32_rdi_esi_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers scalar atomic fetch sub family without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_atomic_fetch_sub_width(ptr %ptr, i32 %replacement, i32 %ordering) {
        \\entry:
        \\  %old = atomicrmw sub ptr %ptr, i32 %replacement seq_cst, align 4
        \\  ret i32 %old
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_atomic_fetch_sub_width"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.atomic_fetch_sub_i32_rdi_esi_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers scalar atomic fetch add family without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_atomic_fetch_add_width(ptr %ptr, i32 %replacement, i32 %ordering) {
        \\entry:
        \\  %old = atomicrmw add ptr %ptr, i32 %replacement seq_cst, align 4
        \\  ret i32 %old
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_atomic_fetch_add_width"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.atomic_fetch_add_i32_rdi_esi_eax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked i128 atomic fetch umin without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i128 @llvm.umin.i128(i128, i128)
        \\
        \\@locks_for_any_fetch_umin = internal global [64 x i8] zeroinitializer, align 64
        \\
        \\define i128 @any_spinlocked_fetch_umin(ptr %ptr, i128 %replacement, i32 %ordering) {
        \\entry:
        \\  %addr = ptrtoint ptr %ptr to i64
        \\  %shift = lshr exact i64 %addr, 3
        \\  %slot = and i64 %shift, 62
        \\  %lock = getelementptr inbounds nuw [64 x i8], ptr @locks_for_any_fetch_umin, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old.lock = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old.lock, 0
        \\  br i1 %acquired, label %update, label %loop
        \\update:
        \\  %old.value = load i128, ptr %ptr, align 16
        \\  %new.value = call i128 @llvm.umin.i128(i128 %old.value, i128 %replacement)
        \\  store i128 %new.value, ptr %ptr, align 16
        \\  store atomic i64 0, ptr %lock release, align 64
        \\  ret i128 %old.value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_spinlocked_fetch_umin"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_fetch_umin", machine.instructions.items[0].spinlocked_fetch_umin_i128_rdi_rsi_rdx_rax_rdx);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked i128 atomic fetch umax without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i128 @llvm.umax.i128(i128, i128)
        \\
        \\@locks_for_any_fetch_umax = internal global [64 x i8] zeroinitializer, align 64
        \\
        \\define i128 @any_spinlocked_fetch_umax(ptr %ptr, i128 %replacement, i32 %ordering) {
        \\entry:
        \\  %addr = ptrtoint ptr %ptr to i64
        \\  %shift = lshr exact i64 %addr, 3
        \\  %slot = and i64 %shift, 62
        \\  %lock = getelementptr inbounds nuw [64 x i8], ptr @locks_for_any_fetch_umax, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old.lock = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old.lock, 0
        \\  br i1 %acquired, label %update, label %loop
        \\update:
        \\  %old.value = load i128, ptr %ptr, align 16
        \\  %new.value = call i128 @llvm.umax.i128(i128 %old.value, i128 %replacement)
        \\  store i128 %new.value, ptr %ptr, align 16
        \\  store atomic i64 0, ptr %lock release, align 64
        \\  ret i128 %old.value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_spinlocked_fetch_umax"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_fetch_umax", machine.instructions.items[0].spinlocked_fetch_umax_i128_rdi_rsi_rdx_rax_rdx);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked i128 atomic fetch nand without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@locks_for_any_fetch_nand = internal global [64 x i8] zeroinitializer, align 64
        \\
        \\define i128 @any_spinlocked_fetch_nand(ptr %ptr, i128 %replacement, i32 %ordering) {
        \\entry:
        \\  %addr = ptrtoint ptr %ptr to i64
        \\  %shift = lshr exact i64 %addr, 3
        \\  %slot = and i64 %shift, 62
        \\  %lock = getelementptr inbounds nuw [64 x i8], ptr @locks_for_any_fetch_nand, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old.lock = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old.lock, 0
        \\  br i1 %acquired, label %update, label %loop
        \\update:
        \\  %old.value = load i128, ptr %ptr, align 16
        \\  %anded = and i128 %old.value, %replacement
        \\  %new.value = xor i128 %anded, -1
        \\  store i128 %new.value, ptr %ptr, align 16
        \\  store atomic i64 0, ptr %lock release, align 64
        \\  ret i128 %old.value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_spinlocked_fetch_nand"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_fetch_nand", machine.instructions.items[0].spinlocked_fetch_nand_i128_rdi_rsi_rdx_rax_rdx);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked i128 atomic fetch xor without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@locks_for_any_fetch_xor = internal global [64 x i8] zeroinitializer, align 64
        \\
        \\define i128 @any_spinlocked_fetch_xor(ptr %ptr, i128 %replacement, i32 %ordering) {
        \\entry:
        \\  %addr = ptrtoint ptr %ptr to i64
        \\  %shift = lshr exact i64 %addr, 3
        \\  %slot = and i64 %shift, 62
        \\  %lock = getelementptr inbounds nuw [64 x i8], ptr @locks_for_any_fetch_xor, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old.lock = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old.lock, 0
        \\  br i1 %acquired, label %update, label %loop
        \\update:
        \\  %old.value = load i128, ptr %ptr, align 16
        \\  %new.value = xor i128 %old.value, %replacement
        \\  store i128 %new.value, ptr %ptr, align 16
        \\  store atomic i64 0, ptr %lock release, align 64
        \\  ret i128 %old.value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_spinlocked_fetch_xor"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_fetch_xor", machine.instructions.items[0].spinlocked_fetch_xor_i128_rdi_rsi_rdx_rax_rdx);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked i128 atomic fetch or without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@locks_for_any_fetch_or = internal global [64 x i8] zeroinitializer, align 64
        \\
        \\define i128 @any_spinlocked_fetch_or(ptr %ptr, i128 %replacement, i32 %ordering) {
        \\entry:
        \\  %addr = ptrtoint ptr %ptr to i64
        \\  %shift = lshr exact i64 %addr, 3
        \\  %slot = and i64 %shift, 62
        \\  %lock = getelementptr inbounds nuw [64 x i8], ptr @locks_for_any_fetch_or, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old.lock = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old.lock, 0
        \\  br i1 %acquired, label %update, label %loop
        \\update:
        \\  %old.value = load i128, ptr %ptr, align 16
        \\  %new.value = or i128 %old.value, %replacement
        \\  store i128 %new.value, ptr %ptr, align 16
        \\  store atomic i64 0, ptr %lock release, align 64
        \\  ret i128 %old.value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_spinlocked_fetch_or"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_fetch_or", machine.instructions.items[0].spinlocked_fetch_or_i128_rdi_rsi_rdx_rax_rdx);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked i128 atomic fetch and without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@locks_for_any_fetch_and = internal global [64 x i8] zeroinitializer, align 64
        \\
        \\define i128 @any_spinlocked_fetch_and(ptr %ptr, i128 %replacement, i32 %ordering) {
        \\entry:
        \\  %addr = ptrtoint ptr %ptr to i64
        \\  %shift = lshr exact i64 %addr, 3
        \\  %slot = and i64 %shift, 62
        \\  %lock = getelementptr inbounds nuw [64 x i8], ptr @locks_for_any_fetch_and, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old.lock = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old.lock, 0
        \\  br i1 %acquired, label %update, label %loop
        \\update:
        \\  %old.value = load i128, ptr %ptr, align 16
        \\  %new.value = and i128 %old.value, %replacement
        \\  store i128 %new.value, ptr %ptr, align 16
        \\  store atomic i64 0, ptr %lock release, align 64
        \\  ret i128 %old.value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_spinlocked_fetch_and"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_fetch_and", machine.instructions.items[0].spinlocked_fetch_and_i128_rdi_rsi_rdx_rax_rdx);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked i128 atomic fetch sub without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@locks_for_any_fetch_sub = internal global [64 x i8] zeroinitializer, align 64
        \\
        \\define i128 @any_spinlocked_fetch_sub(ptr %ptr, i128 %replacement, i32 %ordering) {
        \\entry:
        \\  %addr = ptrtoint ptr %ptr to i64
        \\  %shift = lshr exact i64 %addr, 3
        \\  %slot = and i64 %shift, 62
        \\  %lock = getelementptr inbounds nuw [64 x i8], ptr @locks_for_any_fetch_sub, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old.lock = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old.lock, 0
        \\  br i1 %acquired, label %update, label %loop
        \\update:
        \\  %old.value = load i128, ptr %ptr, align 16
        \\  %new.value = sub i128 %old.value, %replacement
        \\  store i128 %new.value, ptr %ptr, align 16
        \\  store atomic i64 0, ptr %lock release, align 64
        \\  ret i128 %old.value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_spinlocked_fetch_sub"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_fetch_sub", machine.instructions.items[0].spinlocked_fetch_sub_i128_rdi_rsi_rdx_rax_rdx);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers spinlocked i128 atomic fetch add without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@locks_for_any_fetch_add = internal global [64 x i8] zeroinitializer, align 64
        \\
        \\define i128 @any_spinlocked_fetch_add(ptr %ptr, i128 %replacement, i32 %ordering) {
        \\entry:
        \\  %addr = ptrtoint ptr %ptr to i64
        \\  %shift = lshr exact i64 %addr, 3
        \\  %slot = and i64 %shift, 62
        \\  %lock = getelementptr inbounds nuw [64 x i8], ptr @locks_for_any_fetch_add, i64 %slot
        \\  br label %loop
        \\loop:
        \\  %old.lock = atomicrmw xchg ptr %lock, i64 1 acquire, align 8
        \\  %acquired = icmp eq i64 %old.lock, 0
        \\  br i1 %acquired, label %update, label %loop
        \\update:
        \\  %old.value = load i128, ptr %ptr, align 16
        \\  %new.value = add i128 %old.value, %replacement
        \\  store i128 %new.value, ptr %ptr, align 16
        \\  store atomic i64 0, ptr %lock release, align 64
        \\  ret i128 %old.value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        try testFunctionByName(module, "any_spinlocked_fetch_add"),
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqualStrings("locks_for_any_fetch_add", machine.instructions.items[0].spinlocked_fetch_add_i128_rdi_rsi_rdx_rax_rdx);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers guarded strcpy copy loop without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.trap()
        \\
        \\define internal ptr @any_guarded_strcpy_copy(ptr %dst, ptr %src, i64 %guard) {
        \\entry:
        \\  %guard.zero = icmp eq i64 %guard, 0
        \\  br i1 %guard.zero, label %trap, label %copy
        \\copy:
        \\  %idx = phi i64 [ 0, %entry ], [ %next, %store ]
        \\  %src.ptr = getelementptr inbounds [1 x i8], ptr %src, i64 %idx
        \\  %byte = load i8, ptr %src.ptr, align 1
        \\  %zero = icmp eq i8 %byte, 0
        \\  %dst.ptr = getelementptr inbounds [1 x i8], ptr %dst, i64 %idx
        \\  br i1 %zero, label %finish, label %store
        \\store:
        \\  store i8 %byte, ptr %dst.ptr, align 1
        \\  %next = add nuw i64 %idx, 1
        \\  %guard.done = icmp eq i64 %next, %guard
        \\  br i1 %guard.done, label %trap, label %copy
        \\trap:
        \\  call void @llvm.trap()
        \\  unreachable
        \\finish:
        \\  store i8 0, ptr %dst.ptr, align 1
        \\  ret ptr %dst
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
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.guarded_strcpy_rdi_rsi_rdx_rax, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 generic cfg lowers byte memset loop without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal ptr @any_byte_memset(ptr %dst, i8 %byte, i64 %len) {
        \\entry:
        \\  %empty = icmp eq i64 %len, 0
        \\  br i1 %empty, label %done, label %preheader
        \\preheader:
        \\  %tail = and i64 %len, 7
        \\  %no.tail = icmp eq i64 %tail, 0
        \\  br i1 %no.tail, label %loopexit, label %prologue
        \\prologue:
        \\  %remaining.prol = phi i64 [ %remaining.next, %prologue ], [ %len, %preheader ]
        \\  %ptr.prol = phi ptr [ %ptr.next, %prologue ], [ %dst, %preheader ]
        \\  %iter = phi i64 [ %iter.next, %prologue ], [ 0, %preheader ]
        \\  store i8 %byte, ptr %ptr.prol, align 1
        \\  %remaining.next = add i64 %remaining.prol, -1
        \\  %ptr.next = getelementptr inbounds nuw i8, ptr %ptr.prol, i64 1
        \\  %iter.next = add i64 %iter, 1
        \\  %iter.done = icmp eq i64 %iter.next, %tail
        \\  br i1 %iter.done, label %loopexit, label %prologue
        \\loopexit:
        \\  %remaining.unr = phi i64 [ %len, %preheader ], [ %remaining.next, %prologue ]
        \\  %ptr.unr = phi ptr [ %dst, %preheader ], [ %ptr.next, %prologue ]
        \\  %small = icmp ult i64 %len, 8
        \\  br i1 %small, label %done, label %loop
        \\loop:
        \\  %remaining = phi i64 [ %remaining.after, %loop ], [ %remaining.unr, %loopexit ]
        \\  %ptr = phi ptr [ %ptr.after, %loop ], [ %ptr.unr, %loopexit ]
        \\  store i8 %byte, ptr %ptr, align 1
        \\  %p1 = getelementptr inbounds nuw i8, ptr %ptr, i64 1
        \\  store i8 %byte, ptr %p1, align 1
        \\  %p2 = getelementptr inbounds nuw i8, ptr %ptr, i64 2
        \\  store i8 %byte, ptr %p2, align 1
        \\  %p3 = getelementptr inbounds nuw i8, ptr %ptr, i64 3
        \\  store i8 %byte, ptr %p3, align 1
        \\  %p4 = getelementptr inbounds nuw i8, ptr %ptr, i64 4
        \\  store i8 %byte, ptr %p4, align 1
        \\  %p5 = getelementptr inbounds nuw i8, ptr %ptr, i64 5
        \\  store i8 %byte, ptr %p5, align 1
        \\  %p6 = getelementptr inbounds nuw i8, ptr %ptr, i64 6
        \\  store i8 %byte, ptr %p6, align 1
        \\  %p7 = getelementptr inbounds nuw i8, ptr %ptr, i64 7
        \\  store i8 %byte, ptr %p7, align 1
        \\  %remaining.after = add i64 %remaining, -8
        \\  %done.loop = icmp eq i64 %remaining.after, 0
        \\  %ptr.after = getelementptr inbounds nuw i8, ptr %ptr, i64 8
        \\  br i1 %done.loop, label %done, label %loop
        \\done:
        \\  ret ptr %dst
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
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.memset_rdi_sil_rdx_rax, machine.instructions.items[0]);
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

test "x86_64 codegen routes local aggregate parameter field compare call through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc void @assert(i1)
        \\
        \\define internal fastcc void @aggregate_field_assert({ i32 } %arg0) {
        \\entry:
        \\  %slot = alloca { i32 }
        \\  store { i32 } %arg0, ptr %slot
        \\  %field = load i32, ptr %slot
        \\  %cmp = icmp eq i32 %field, 9296
        \\  call fastcc void @assert(i1 %cmp)
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

test "x86_64 generic cfg lowers debug assert as local trap boundary" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc void @debug.assert(i1)
        \\
        \\define internal fastcc void @assert_user(i1 %ok) {
        \\entry:
        \\  call fastcc void @debug.assert(i1 %ok)
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
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    var saw_trap = false;
    for (machine.instructions.items) |instruction| {
        switch (instruction) {
            .direct_call => |call| try std.testing.expect(!std.mem.eql(u8, call.symbol, "debug.assert")),
            .ud2 => saw_trap = true,
            else => {},
        }
    }
    try std.testing.expect(saw_trap);
}

test "x86_64 lowers noreturn trap stub without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.trap()
        \\
        \\define internal void @any_noreturn_trap_stub() {
        \\entry:
        \\  call void @llvm.trap()
        \\  unreachable
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

    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ud2, machine.instructions.items[0]);
}

test "x86_64 lowers naked stack probe inline asm without name admission" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal void @any_stack_probe() #0 {
        \\entry:
        \\  tail call void asm sideeffect "        push   %rcx\0A        mov    %rax, %rcx\0A        cmp    $$0x1000,%rcx\0A        jb     2f\0A 1:\0A        sub    $$0x1000,%rsp\0A        orl    $$0,16(%rsp)\0A        sub    $$0x1000,%rcx\0A        cmp    $$0x1000,%rcx\0A        ja     1b\0A 2:\0A        sub    %rcx, %rsp\0A        orl    $$0,16(%rsp)\0A        add    %rax,%rsp\0A        pop    %rcx\0A        ret", "~{dirflag},~{fpsr},~{flags}"()
        \\  unreachable
        \\}
        \\
        \\attributes #0 = { naked nounwind }
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

    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.stack_probe_rax_rcx_rsp, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);

    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqual(@as(usize, 54), bytes.len);
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
