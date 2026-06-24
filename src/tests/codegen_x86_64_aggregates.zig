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
test "x86_64 codegen stores selected sret i64 aggregate fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @make(ptr sret({ i64, i64, i64 }) %out, i64 %a, i64 %b, i64 %c) {
        \\entry:
        \\  %field0 = getelementptr { i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %a, ptr %field0
        \\  %field1 = getelementptr { i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %b, ptr %field1
        \\  %field2 = getelementptr { i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %c, ptr %field2
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rdx, .offset = 8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rcx, .offset = 16 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[3]);
}

test "x86_64 codegen stores four-field sret i64 aggregate fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @make(ptr sret({ i64, i64, i64, i64 }) %out, i64 %a, i64 %b, i64 %c, i64 %d) {
        \\entry:
        \\  %field0 = getelementptr { i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %a, ptr %field0
        \\  %field1 = getelementptr { i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %b, ptr %field1
        \\  %field2 = getelementptr { i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %c, ptr %field2
        \\  %field3 = getelementptr { i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %d, ptr %field3
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rdx, .offset = 8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rcx, .offset = 16 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r8, .offset = 24 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[4]);
}

test "x86_64 codegen stores five-field sret i64 aggregate fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @make(ptr sret({ i64, i64, i64, i64, i64 }) %out, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e) {
        \\entry:
        \\  %field0 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %a, ptr %field0
        \\  %field1 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %b, ptr %field1
        \\  %field2 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %c, ptr %field2
        \\  %field3 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %d, ptr %field3
        \\  %field4 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %e, ptr %field4
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rdx, .offset = 8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rcx, .offset = 16 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r8, .offset = 24 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r9, .offset = 32 } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[5]);
}

test "x86_64 codegen stores six-field sret i64 aggregate fields with stack arg" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @make(ptr sret({ i64, i64, i64, i64, i64, i64 }) %out, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
        \\entry:
        \\  %field0 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %a, ptr %field0
        \\  %field1 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %b, ptr %field1
        \\  %field2 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %c, ptr %field2
        \\  %field3 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %d, ptr %field3
        \\  %field4 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %e, ptr %field4
        \\  %field5 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 5
        \\  store i64 %f, ptr %field5
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rdx, .offset = 8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rcx, .offset = 16 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r8, .offset = 24 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r9, .offset = 32 } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 40 } }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[7]);
}

test "x86_64 codegen stores seven-field sret i64 aggregate fields with multiple stack args" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @make(ptr sret({ i64, i64, i64, i64, i64, i64, i64 }) %out, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
        \\entry:
        \\  %field0 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %a, ptr %field0
        \\  %field1 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %b, ptr %field1
        \\  %field2 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %c, ptr %field2
        \\  %field3 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %d, ptr %field3
        \\  %field4 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %e, ptr %field4
        \\  %field5 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 5
        \\  store i64 %f, ptr %field5
        \\  %field6 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 6
        \\  store i64 %g, ptr %field6
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rdx, .offset = 8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rcx, .offset = 16 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r8, .offset = 24 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r9, .offset = 32 } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 40 } }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 48 } }, machine.instructions.items[8]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[9]);
}

test "x86_64 codegen stores eight-field sret i64 aggregate fields with multiple stack args" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @make(ptr sret({ i64, i64, i64, i64, i64, i64, i64, i64 }) %out, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) {
        \\entry:
        \\  %field0 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %a, ptr %field0
        \\  %field1 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %b, ptr %field1
        \\  %field2 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %c, ptr %field2
        \\  %field3 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %d, ptr %field3
        \\  %field4 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %e, ptr %field4
        \\  %field5 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 5
        \\  store i64 %f, ptr %field5
        \\  %field6 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 6
        \\  store i64 %g, ptr %field6
        \\  %field7 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 7
        \\  store i64 %h, ptr %field7
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rdx, .offset = 8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rcx, .offset = 16 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r8, .offset = 24 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r9, .offset = 32 } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 40 } }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 48 } }, machine.instructions.items[8]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 24 }, machine.instructions.items[9]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 56 } }, machine.instructions.items[10]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[11]);
}

test "x86_64 codegen copies five-field memory aggregate from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr sret({ i64, i64, i64, i64, i64 }) %out, ptr byval({ i64, i64, i64, i64, i64 }) %value) {
        \\entry:
        \\  %src0 = getelementptr { i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 0
        \\  %load0 = load i64, ptr %src0
        \\  %dst0 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %load0, ptr %dst0
        \\  %src1 = getelementptr { i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 1
        \\  %load1 = load i64, ptr %src1
        \\  %dst1 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %load1, ptr %dst1
        \\  %src2 = getelementptr { i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 2
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %load2, ptr %dst2
        \\  %src3 = getelementptr { i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 3
        \\  %load3 = load i64, ptr %src3
        \\  %dst3 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %load3, ptr %dst3
        \\  %src4 = getelementptr { i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 4
        \\  %load4 = load i64, ptr %src4
        \\  %dst4 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %load4, ptr %dst4
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 8 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 24 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16 } }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 32 }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 24 } }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 40 }, machine.instructions.items[8]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 32 } }, machine.instructions.items[9]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[10]);
}

test "x86_64 codegen copies six-field memory aggregate from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ i64, i64, i64, i64, i64, i64 }) %out, ptr byval({ i64, i64, i64, i64, i64, i64 }) %value) {
        \\entry:
        \\  %src0 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 0
        \\  %load0 = load i64, ptr %src0
        \\  %dst0 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %load0, ptr %dst0
        \\  %src1 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 1
        \\  %load1 = load i64, ptr %src1
        \\  %dst1 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %load1, ptr %dst1
        \\  %src2 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 2
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %load2, ptr %dst2
        \\  %src3 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 3
        \\  %load3 = load i64, ptr %src3
        \\  %dst3 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %load3, ptr %dst3
        \\  %src4 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 4
        \\  %load4 = load i64, ptr %src4
        \\  %dst4 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %load4, ptr %dst4
        \\  %src5 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 5
        \\  %load5 = load i64, ptr %src5
        \\  %dst5 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 5
        \\  store i64 %load5, ptr %dst5
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 8 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 24 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16 } }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 32 }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 24 } }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 40 }, machine.instructions.items[8]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 32 } }, machine.instructions.items[9]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 48 }, machine.instructions.items[10]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 40 } }, machine.instructions.items[11]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[12]);
}

test "x86_64 codegen copies seven-field memory aggregate from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ i64, i64, i64, i64, i64, i64, i64 }) %out, ptr byval({ i64, i64, i64, i64, i64, i64, i64 }) %value) {
        \\entry:
        \\  %src0 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 0
        \\  %load0 = load i64, ptr %src0
        \\  %dst0 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %load0, ptr %dst0
        \\  %src1 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 1
        \\  %load1 = load i64, ptr %src1
        \\  %dst1 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %load1, ptr %dst1
        \\  %src2 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 2
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %load2, ptr %dst2
        \\  %src3 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 3
        \\  %load3 = load i64, ptr %src3
        \\  %dst3 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %load3, ptr %dst3
        \\  %src4 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 4
        \\  %load4 = load i64, ptr %src4
        \\  %dst4 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %load4, ptr %dst4
        \\  %src5 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 5
        \\  %load5 = load i64, ptr %src5
        \\  %dst5 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 5
        \\  store i64 %load5, ptr %dst5
        \\  %src6 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 6
        \\  %load6 = load i64, ptr %src6
        \\  %dst6 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 6
        \\  store i64 %load6, ptr %dst6
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
    var field_index: usize = 0;
    while (field_index < 7) : (field_index += 1) {
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = @intCast(8 + field_index * 8) }, machine.instructions.items[field_index * 2]);
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = @intCast(field_index * 8) } }, machine.instructions.items[field_index * 2 + 1]);
    }
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[14]);
}

test "x86_64 codegen copies eight-field memory aggregate from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ i64, i64, i64, i64, i64, i64, i64, i64 }) %out, ptr byval({ i64, i64, i64, i64, i64, i64, i64, i64 }) %value) {
        \\entry:
        \\  %src0 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 0
        \\  %load0 = load i64, ptr %src0
        \\  %dst0 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %load0, ptr %dst0
        \\  %src1 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 1
        \\  %load1 = load i64, ptr %src1
        \\  %dst1 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %load1, ptr %dst1
        \\  %src2 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 2
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %load2, ptr %dst2
        \\  %src3 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 3
        \\  %load3 = load i64, ptr %src3
        \\  %dst3 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %load3, ptr %dst3
        \\  %src4 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 4
        \\  %load4 = load i64, ptr %src4
        \\  %dst4 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %load4, ptr %dst4
        \\  %src5 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 5
        \\  %load5 = load i64, ptr %src5
        \\  %dst5 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 5
        \\  store i64 %load5, ptr %dst5
        \\  %src6 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 6
        \\  %load6 = load i64, ptr %src6
        \\  %dst6 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 6
        \\  store i64 %load6, ptr %dst6
        \\  %src7 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 7
        \\  %load7 = load i64, ptr %src7
        \\  %dst7 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 7
        \\  store i64 %load7, ptr %dst7
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
    var field_index: usize = 0;
    while (field_index < 8) : (field_index += 1) {
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = @intCast(8 + field_index * 8) }, machine.instructions.items[field_index * 2]);
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = @intCast(field_index * 8) } }, machine.instructions.items[field_index * 2 + 1]);
    }
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[16]);
}

test "x86_64 codegen copies nested memory aggregate leaves from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ { i64, i64, i64 }, { i64, i64, i64 } }) %out, ptr byval({ { i64, i64, i64 }, { i64, i64, i64 } }) %value) {
        \\entry:
        \\  %src0 = getelementptr i8, ptr %value, i64 0
        \\  %load0 = load i64, ptr %src0
        \\  %dst0 = getelementptr i8, ptr %out, i64 0
        \\  store i64 %load0, ptr %dst0
        \\  %src1 = getelementptr i8, ptr %value, i64 8
        \\  %load1 = load i64, ptr %src1
        \\  %dst1 = getelementptr i8, ptr %out, i64 8
        \\  store i64 %load1, ptr %dst1
        \\  %src2 = getelementptr i8, ptr %value, i64 16
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr i8, ptr %out, i64 16
        \\  store i64 %load2, ptr %dst2
        \\  %src3 = getelementptr i8, ptr %value, i64 24
        \\  %load3 = load i64, ptr %src3
        \\  %dst3 = getelementptr i8, ptr %out, i64 24
        \\  store i64 %load3, ptr %dst3
        \\  %src4 = getelementptr i8, ptr %value, i64 32
        \\  %load4 = load i64, ptr %src4
        \\  %dst4 = getelementptr i8, ptr %out, i64 32
        \\  store i64 %load4, ptr %dst4
        \\  %src5 = getelementptr i8, ptr %value, i64 40
        \\  %load5 = load i64, ptr %src5
        \\  %dst5 = getelementptr i8, ptr %out, i64 40
        \\  store i64 %load5, ptr %dst5
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
    var field_index: usize = 0;
    while (field_index < 6) : (field_index += 1) {
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = @intCast(8 + field_index * 8) }, machine.instructions.items[field_index * 2]);
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = @intCast(field_index * 8) } }, machine.instructions.items[field_index * 2 + 1]);
    }
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[12]);
}

test "x86_64 codegen reads selected memory aggregate by-value fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @edges({ i64, i64, i64 } %value) {
        \\entry:
        \\  %slot = alloca { i64, i64, i64 }
        \\  store { i64, i64, i64 } %value, ptr %slot
        \\  %field0 = getelementptr { i64, i64, i64 }, ptr %slot, i64 0, i32 0
        \\  %a = load i64, ptr %field0
        \\  %field2 = getelementptr { i64, i64, i64 }, ptr %slot, i64 0, i32 2
        \\  %c = load i64, ptr %field2
        \\  %sum = add i64 %a, %c
        \\  ret i64 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_stack_disp8_rax = 24 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "x86_64 codegen reads four-field memory aggregate by-value fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @edges({ i64, i64, i64, i64 } %value) {
        \\entry:
        \\  %slot = alloca { i64, i64, i64, i64 }
        \\  store { i64, i64, i64, i64 } %value, ptr %slot
        \\  %field0 = getelementptr { i64, i64, i64, i64 }, ptr %slot, i64 0, i32 0
        \\  %a = load i64, ptr %field0
        \\  %field3 = getelementptr { i64, i64, i64, i64 }, ptr %slot, i64 0, i32 3
        \\  %d = load i64, ptr %field3
        \\  %sum = add i64 %a, %d
        \\  ret i64 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_stack_disp8_rax = 32 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "x86_64 codegen reads five-field memory aggregate by-value fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @edges({ i64, i64, i64, i64, i64 } %value) {
        \\entry:
        \\  %slot = alloca { i64, i64, i64, i64, i64 }
        \\  store { i64, i64, i64, i64, i64 } %value, ptr %slot
        \\  %field1 = getelementptr { i64, i64, i64, i64, i64 }, ptr %slot, i64 0, i32 1
        \\  %b = load i64, ptr %field1
        \\  %field4 = getelementptr { i64, i64, i64, i64, i64 }, ptr %slot, i64 0, i32 4
        \\  %e = load i64, ptr %field4
        \\  %sum = add i64 %b, %e
        \\  ret i64 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_stack_disp8_rax = 40 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "x86_64 codegen reads sixteen-field memory aggregate by-value fields with disp32" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @inner({ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 } %value) {
        \\entry:
        \\  %slot = alloca { i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }
        \\  store { i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 } %value, ptr %slot
        \\  %field3 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %slot, i64 0, i32 3
        \\  %d = load i64, ptr %field3
        \\  %field10 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %slot, i64 0, i32 10
        \\  %k = load i64, ptr %field10
        \\  %sum = add i64 %d, %k
        \\  %field15 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %slot, i64 0, i32 15
        \\  %p = load i64, ptr %field15
        \\  %total = add i64 %sum, %p
        \\  ret i64 %total
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 32 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_stack_disp8_rax = 88 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_stack_disp32_rax = 128 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[3]);
}

test "x86_64 codegen reads nested memory aggregate by-value fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @sum({ { i64, i64, i64 }, { i64, i64, i64 } } %value) {
        \\entry:
        \\  %slot = alloca { { i64, i64, i64 }, { i64, i64, i64 } }
        \\  store { { i64, i64, i64 }, { i64, i64, i64 } } %value, ptr %slot
        \\  %left_b_ptr = getelementptr i8, ptr %slot, i64 8
        \\  %left_b = load i64, ptr %left_b_ptr
        \\  %right_ptr = getelementptr i8, ptr %slot, i64 24
        \\  %right_c_ptr = getelementptr i8, ptr %right_ptr, i64 16
        \\  %right_c = load i64, ptr %right_c_ptr
        \\  %sum = add i64 %left_b, %right_c
        \\  ret i64 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_stack_disp8_rax = 48 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "x86_64 codegen sums nested INTEGER aggregate fields from SysV GPR pair" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @nested_sum({ { i32, i32 }, { i32, i32 } } %value) {
        \\entry:
        \\  %slot = alloca { { i32, i32 }, { i32, i32 } }
        \\  store { { i32, i32 }, { i32, i32 } } %value, ptr %slot
        \\  %a = load i32, ptr %slot
        \\  %b_ptr = getelementptr i8, ptr %slot, i64 4
        \\  %b = load i32, ptr %b_ptr
        \\  %ab = add i32 %a, %b
        \\  %c_ptr = getelementptr i8, ptr %slot, i64 8
        \\  %c = load i32, ptr %c_ptr
        \\  %abc = add i32 %ab, %c
        \\  %right_ptr = getelementptr i8, ptr %slot, i64 8
        \\  %d_ptr = getelementptr i8, ptr %right_ptr, i64 4
        \\  %d = load i32, ptr %d_ptr
        \\  %sum = add i32 %abc, %d
        \\  ret i32 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_arg_high32_eax = .rdi }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .binary_arg_eax = .{ .op = .add, .reg = .rsi } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_arg_high32_eax = .rsi }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[4]);
}

test "x86_64 codegen sums array-in-struct INTEGER aggregate fields from SysV GPR pair" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @array_sum({ [2 x i64] } %value) {
        \\entry:
        \\  %slot = alloca { [2 x i64] }
        \\  store { [2 x i64] } %value, ptr %slot
        \\  %a_ptr = getelementptr i64, ptr %slot, i64 0
        \\  %a = load i64, ptr %a_ptr
        \\  %b_ptr = getelementptr i64, ptr %slot, i64 1
        \\  %b = load i64, ptr %b_ptr
        \\  %sum = add i64 %a, %b
        \\  ret i64 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_arg64_rax = .rsi }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "x86_64 codegen sums f32 fields from single-eightbyte SSE aggregate" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define float @sum({ float, float } %value) {
        \\entry:
        \\  %slot = alloca { float, float }
        \\  store { float, float } %value, ptr %slot
        \\  %a = load float, ptr %slot
        \\  %b_ptr = getelementptr i8, ptr %slot, i64 4
        \\  %b = load float, ptr %b_ptr
        \\  %sum = fadd float %a, %b
        \\  ret float %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shufps_high_f32_to_low = .xmm1 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.addss_xmm1_xmm0, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[3]);
}

test "x86_64 codegen lowers mixed integer to FP arithmetic pipelines" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define float @f32_add(i32 %value, float %addend) {
        \\entry:
        \\  %cast = sitofp i32 %value to float
        \\  %sum = fadd float %cast, %addend
        \\  ret float %sum
        \\}
        \\
        \\define float @f32_mul_add(i32 %value, float %scale, float %addend) {
        \\entry:
        \\  %cast = sitofp i32 %value to float
        \\  %product = fmul float %cast, %scale
        \\  %sum = fadd float %product, %addend
        \\  ret float %sum
        \\}
        \\
        \\define double @f64_mul_add(i32 %value, double %scale, double %addend) {
        \\entry:
        \\  %cast = sitofp i32 %value to double
        \\  %product = fmul double %cast, %scale
        \\  %sum = fadd double %product, %addend
        \\  ret double %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var f32_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer f32_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, f32_machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } }, f32_machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.cvtsi2ss_edi_xmm0, f32_machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.addss_xmm1_xmm0, f32_machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, f32_machine.instructions.items[3]);

    var f32_mul_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[1]);
    defer f32_mul_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, f32_mul_machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm2, .src = .xmm1 } }, f32_mul_machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } }, f32_mul_machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.cvtsi2ss_edi_xmm0, f32_mul_machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.mulss_xmm1_xmm0, f32_mul_machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm2 } }, f32_mul_machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.addss_xmm1_xmm0, f32_mul_machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, f32_mul_machine.instructions.items[6]);

    var f64_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[2]);
    defer f64_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, f64_machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm2, .src = .xmm1 } }, f64_machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } }, f64_machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.cvtsi2sd_edi_xmm0, f64_machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.mulsd_xmm1_xmm0, f64_machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm2 } }, f64_machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.addsd_xmm1_xmm0, f64_machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, f64_machine.instructions.items[6]);
}

test "x86_64 codegen returns i32 fields from mixed SysV aggregate classes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @small_mixed_int({ i32, double } %value) {
        \\entry:
        \\  %slot = alloca { i32, double }
        \\  store { i32, double } %value, ptr %slot
        \\  %a_ptr = getelementptr { i32, double }, ptr %slot, i64 0, i32 0
        \\  %a = load i32, ptr %a_ptr
        \\  ret i32 %a
        \\}
        \\
        \\define i32 @small_reverse_mixed_int({ double, i32 } %value) {
        \\entry:
        \\  %slot = alloca { double, i32 }
        \\  store { double, i32 } %value, ptr %slot
        \\  %b_ptr = getelementptr { double, i32 }, ptr %slot, i64 0, i32 1
        \\  %b = load i32, ptr %b_ptr
        \\  ret i32 %b
        \\}
        \\
        \\define i32 @packed_mixed_high_int({ i32, i32, double } %value) {
        \\entry:
        \\  %slot = alloca { i32, i32, double }
        \\  store { i32, i32, double } %value, ptr %slot
        \\  %b_ptr = getelementptr { i32, i32, double }, ptr %slot, i64 0, i32 1
        \\  %b = load i32, ptr %b_ptr
        \\  ret i32 %b
        \\}
        \\
        \\define i32 @packed_reverse_mixed_high_int({ double, i32, i32 } %value) {
        \\entry:
        \\  %slot = alloca { double, i32, i32 }
        \\  store { double, i32, i32 } %value, ptr %slot
        \\  %c_ptr = getelementptr { double, i32, i32 }, ptr %slot, i64 0, i32 2
        \\  %c = load i32, ptr %c_ptr
        \\  ret i32 %c
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var small_mixed = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer small_mixed.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, small_mixed.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .rdi }, small_mixed.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, small_mixed.instructions.items[1]);

    var small_reverse = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[1]);
    defer small_reverse.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, small_reverse.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .rdi }, small_reverse.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, small_reverse.instructions.items[1]);

    var packed_mixed = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[2]);
    defer packed_mixed.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, packed_mixed.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, packed_mixed.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shr_rax_imm6 = 32 }, packed_mixed.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, packed_mixed.instructions.items[2]);

    var packed_reverse = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[3]);
    defer packed_reverse.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, packed_reverse.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, packed_reverse.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shr_rax_imm6 = 32 }, packed_reverse.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, packed_reverse.instructions.items[2]);
}

test "x86_64 codegen copies mixed-width memory aggregate leaves from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ i64, i32, i64, i32 }) %out, ptr byval({ i64, i32, i64, i32 }) %value) {
        \\entry:
        \\  %src0 = getelementptr i8, ptr %value, i64 0
        \\  %load0 = load i64, ptr %src0
        \\  %dst0 = getelementptr i8, ptr %out, i64 0
        \\  store i64 %load0, ptr %dst0
        \\  %src1 = getelementptr i8, ptr %value, i64 8
        \\  %load1 = load i32, ptr %src1
        \\  %dst1 = getelementptr i8, ptr %out, i64 8
        \\  store i32 %load1, ptr %dst1
        \\  %src2 = getelementptr i8, ptr %value, i64 16
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr i8, ptr %out, i64 16
        \\  store i64 %load2, ptr %dst2
        \\  %src3 = getelementptr i8, ptr %value, i64 24
        \\  %load3 = load i32, ptr %src3
        \\  %dst3 = getelementptr i8, ptr %out, i64 24
        \\  store i32 %load3, ptr %dst3
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_eax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 8 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 24 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16 } }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 32 }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_eax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 24 } }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[8]);
}

test "x86_64 codegen copies narrow nested memory aggregate leaves from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ i8, { i16, i32 }, i64 }) %out, ptr byval({ i8, { i16, i32 }, i64 }) %value) {
        \\entry:
        \\  %src0 = getelementptr i8, ptr %value, i64 0
        \\  %load0 = load i8, ptr %src0
        \\  %dst0 = getelementptr i8, ptr %out, i64 0
        \\  store i8 %load0, ptr %dst0
        \\  %src1 = getelementptr i8, ptr %value, i64 4
        \\  %load1 = load i16, ptr %src1
        \\  %dst1 = getelementptr i8, ptr %out, i64 4
        \\  store i16 %load1, ptr %dst1
        \\  %src2 = getelementptr i8, ptr %value, i64 8
        \\  %load2 = load i32, ptr %src2
        \\  %dst2 = getelementptr i8, ptr %out, i64 8
        \\  store i32 %load2, ptr %dst2
        \\  %src3 = getelementptr i8, ptr %value, i64 16
        \\  %load3 = load i64, ptr %src3
        \\  %dst3 = getelementptr i8, ptr %out, i64 16
        \\  store i64 %load3, ptr %dst3
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_u8_eax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_al_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_u16_eax = 12 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_ax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 4 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_eax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 8 } }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 24 }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16 } }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[8]);
}

test "x86_64 codegen copies pointer and double memory aggregate leaves from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ ptr, double, i64 }) %out, ptr byval({ ptr, double, i64 }) %value) {
        \\entry:
        \\  %src0 = getelementptr i8, ptr %value, i64 0
        \\  %load0 = load ptr, ptr %src0
        \\  %dst0 = getelementptr i8, ptr %out, i64 0
        \\  store ptr %load0, ptr %dst0
        \\  %src1 = getelementptr i8, ptr %value, i64 8
        \\  %load1 = load double, ptr %src1
        \\  %dst1 = getelementptr i8, ptr %out, i64 8
        \\  store double %load1, ptr %dst1
        \\  %src2 = getelementptr i8, ptr %value, i64 16
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr i8, ptr %out, i64 16
        \\  store i64 %load2, ptr %dst2
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_xmm0 = 16 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_xmm0_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 8 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 24 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16 } }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[6]);
}

test "x86_64 codegen copies f32 memory aggregate leaves from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ float, float, float, float, float }) %out, ptr byval({ float, float, float, float, float }) %value) {
        \\entry:
        \\  %src0 = getelementptr i8, ptr %value, i64 0
        \\  %load0 = load float, ptr %src0
        \\  %dst0 = getelementptr i8, ptr %out, i64 0
        \\  store float %load0, ptr %dst0
        \\  %src1 = getelementptr i8, ptr %value, i64 4
        \\  %load1 = load float, ptr %src1
        \\  %dst1 = getelementptr i8, ptr %out, i64 4
        \\  store float %load1, ptr %dst1
        \\  %src2 = getelementptr i8, ptr %value, i64 8
        \\  %load2 = load float, ptr %src2
        \\  %dst2 = getelementptr i8, ptr %out, i64 8
        \\  store float %load2, ptr %dst2
        \\  %src3 = getelementptr i8, ptr %value, i64 12
        \\  %load3 = load float, ptr %src3
        \\  %dst3 = getelementptr i8, ptr %out, i64 12
        \\  store float %load3, ptr %dst3
        \\  %src4 = getelementptr i8, ptr %value, i64 16
        \\  %load4 = load float, ptr %src4
        \\  %dst4 = getelementptr i8, ptr %out, i64 16
        \\  store float %load4, ptr %dst4
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
    var field_index: usize = 0;
    while (field_index < 5) : (field_index += 1) {
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_xmm0_f32 = @intCast(8 + field_index * 4) }, machine.instructions.items[field_index * 2]);
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = .rdi, .offset = @intCast(field_index * 4) } }, machine.instructions.items[field_index * 2 + 1]);
    }
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[10]);
}
