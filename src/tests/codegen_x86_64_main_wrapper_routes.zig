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

test "x86_64 codegen routes monotonic atomic add through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
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
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes inline asm memory barrier through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @atomics_inline_asm_debug.inline_asm_barrier(i32 %value) {
        \\entry:
        \\  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"()
        \\  ret i32 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes empty void return through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @tiny_scalar.sideEffectFree() {
        \\entry:
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes void-call main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc void @sample.sideEffectFree()
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  call fastcc void @sample.sideEffectFree()
        \\  ret i32 0
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes fp call-check main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc float @sample.floatAdd(float, float)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %call = call fastcc float @sample.floatAdd(float 1.000000e+00, float 2.000000e+00)
        \\  %ok = fcmp oeq float %call, 3.000000e+00
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes integer call-check main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i32 @sample.add(i32, i32)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %call = call fastcc i32 @sample.add(i32 20, i32 22)
        \\  %ok = icmp eq i32 %call, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes pointer literal call-check main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@sample.values = global [4 x i32] zeroinitializer
        \\
        \\declare fastcc i32 @sample.sum(ptr, i64)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %call = call fastcc i32 @sample.sum(ptr @sample.values, i64 4)
        \\  %ok = icmp eq i32 %call, 10
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes narrow integer call-check main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i8 @sample.replace(i8, i8)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %call = call fastcc i8 @sample.replace(i8 8, i8 3)
        \\  %ok = icmp eq i8 %call, 11
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes bool call-check main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i1 @sample.floatLess(float, float)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %call = call fastcc i1 @sample.floatLess(float 1.000000e+00, float 2.000000e+00)
        \\  %ret = select i1 %call, i32 0, i32 1
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes sibling update-get main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc void @sample.update(i32)
        \\declare fastcc i32 @sample.get()
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  call fastcc void @sample.update(i32 7)
        \\  %value = call fastcc i32 @sample.get()
        \\  ret i32 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes direct-call main wrapper with identity cast through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i32 @sample.add(i32)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %call = call fastcc i32 @sample.add(i32 4)
        \\  %retv = bitcast i32 %call to i32
        \\  ret i32 %retv
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes i64 to i32 call-chain main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i64 @sample.pack(i32, i32)
        \\declare fastcc i32 @sample.first(i64)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %pair = call fastcc i64 @sample.pack(i32 1, i32 2)
        \\  %first = call fastcc i32 @sample.first(i64 %pair)
        \\  %retv = bitcast i32 %first to i32
        \\  ret i32 %retv
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes call plus global load check main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@sample.input = internal global i32 41
        \\@sample.output = internal global i32 0
        \\
        \\declare fastcc i32 @sample.loadStore(ptr, ptr)
        \\
        \\define i32 @sample.main() {
        \\0:
        \\  %call = call fastcc i32 @sample.loadStore(ptr @sample.input, ptr @sample.output)
        \\  %first.ok = icmp eq i32 %call, 42
        \\  br i1 %first.ok, label %7, label %5
        \\
        \\5:
        \\  %both.ok = phi i1 [ %output.ok, %7 ], [ 0, %0 ]
        \\  %result = select i1 %both.ok, i32 0, i32 1
        \\  ret i32 %result
        \\
        \\7:
        \\  %output = load i32, ptr @sample.output
        \\  %output.ok = icmp eq i32 %output, 42
        \\  br label %5
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes two unary pointer call checks through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@sample.value = internal global i32 42
        \\
        \\declare fastcc i32 @sample.optionalPtrValue(ptr)
        \\
        \\define i32 @sample.main() {
        \\0:
        \\  %first = call fastcc i32 @sample.optionalPtrValue(ptr @sample.value)
        \\  %first.ok = icmp eq i32 %first, 42
        \\  br i1 %first.ok, label %7, label %5
        \\
        \\5:
        \\  %both.ok = phi i1 [ %second.ok, %7 ], [ 0, %0 ]
        \\  %result = select i1 %both.ok, i32 0, i32 1
        \\  ret i32 %result
        \\
        \\7:
        \\  %second = call fastcc i32 @sample.optionalPtrValue(ptr null)
        \\  %second.ok = icmp eq i32 %second, -1
        \\  br label %5
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes shift mix through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @integers.shift_mix(i32 %a, i32 %b) {
        \\entry:
        \\  %mask = and i32 %b, 31
        \\  %left = shl i32 %a, %mask
        \\  %right = lshr i32 %a, %mask
        \\  %mixed = xor i32 %left, %right
        \\  ret i32 %mixed
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes scalar multiply-by-constant through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @control_flow_calls.callee(i32 %value) {
        \\entry:
        \\  %doubled = mul i32 %value, 2
        \\  ret i32 %doubled
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes i64 constant return through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @i64_arithmetic.i64_value() {
        \\entry:
        \\  ret i64 1234567890123
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes i64 logical shift return through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal fastcc i64 @i64_arithmetic.index_mask(i64 %index) {
        \\entry:
        \\  %word = lshr i64 %index, 6
        \\  ret i64 %word
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .shr_rax_imm6 = 6 });
    try expectMachineInstruction(machine.instructions.items, .ret);
}

test "x86_64 codegen routes i64 logical shift with extended shift count through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal fastcc i64 @i64_arithmetic.index_mask_extended(i64 %index) {
        \\entry:
        \\  %shift = zext i6 6 to i64
        \\  %word = lshr i64 %index, %shift
        \\  ret i64 %word
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .shr_rax_imm6 = 6 });
    try expectMachineInstruction(machine.instructions.items, .ret);
}

test "x86_64 codegen routes narrow enum encoding return through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal fastcc i32 @Air.VectorCmp.encodeOp(i3 %op) {
        \\entry:
        \\  %bits = bitcast i3 %op to i3
        \\  %wide = zext i3 %bits to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_eax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .and_eax_imm32 = 7 });
    try expectMachineInstruction(machine.instructions.items, .ret);
}

test "x86_64 codegen routes nominal enum bool less-than return through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal fastcc i1 @codegen.x86_64.bits.FrameIndex.isNamed(%codegen.x86_64.bits.FrameIndex %fi) {
        \\entry:
        \\  %bits = bitcast %codegen.x86_64.bits.FrameIndex %fi to i32
        \\  %named = icmp ult i32 %bits, 5
        \\  ret i1 %named
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_eax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .cmp_eax_imm32 = 5 });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_imm_eax = 0 });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_imm_eax = 1 });
    try expectMachineInstruction(machine.instructions.items, .ret);
    var saw_unsigned_branch = false;
    for (machine.instructions.items) |instruction| {
        if (std.meta.activeTag(instruction) == .jc) saw_unsigned_branch = true;
    }
    try std.testing.expect(saw_unsigned_branch);
}

test "x86_64 codegen routes sub-byte unsigned nonzero bool return through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal fastcc i1 @link.Diags.Flags.anySet(i3 %flags) {
        \\entry:
        \\  %bits = bitcast i3 %flags to i3
        \\  %any = icmp ugt i3 %bits, 0
        \\  ret i1 %any
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_eax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .and_eax_imm32 = 7 });
    try expectMachineInstruction(machine.instructions.items, .{ .cmp_eax_imm32 = 0 });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_imm_eax = 0 });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_imm_eax = 1 });
    try expectMachineInstruction(machine.instructions.items, .ret);
    var saw_nonzero_branch = false;
    for (machine.instructions.items) |instruction| {
        if (std.meta.activeTag(instruction) == .jne) saw_nonzero_branch = true;
    }
    try std.testing.expect(saw_nonzero_branch);
}

test "x86_64 codegen routes masked i16 equality bool return through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal fastcc i1 @masked_i16_eq(i16 %value) {
        \\entry:
        \\  %masked = and i16 %value, 64512
        \\  %is_high = icmp eq i16 %masked, 55296
        \\  ret i1 %is_high
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_eax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .and_eax_imm32 = 64512 });
    try expectMachineInstruction(machine.instructions.items, .{ .cmp_eax_imm32 = 55296 });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_imm_eax = 0 });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_imm_eax = 1 });
    try expectMachineInstruction(machine.instructions.items, .ret);
    var saw_equal_branch = false;
    for (machine.instructions.items) |instruction| {
        if (std.meta.activeTag(instruction) == .je) saw_equal_branch = true;
    }
    try std.testing.expect(saw_equal_branch);
}

test "x86_64 codegen routes i64 equality bool returns through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal fastcc i1 @Io.Limit.nonzero(i64 %limit) {
        \\entry:
        \\  %nonzero = icmp ne i64 %limit, 0
        \\  ret i1 %nonzero
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .test_arg64 = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_imm_eax = 0 });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_imm_eax = 1 });
    try expectMachineInstruction(machine.instructions.items, .ret);
}
