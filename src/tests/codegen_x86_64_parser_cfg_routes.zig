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

test "x86_64 codegen lowers mix C panic helper with slice panic block" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@runtime_mix_c_add_may_panic_main.zig_k = private unnamed_addr global i32 1, align 4
        \\@__anon_186 = private unnamed_addr constant [13 x i8] c"negative int\00", align 1
        \\@__anon_310 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
        \\
        \\declare void @llvm.assume(i1)
        \\declare fastcc void @debug.defaultPanic(ptr, i64, ptr)
        \\
        \\define private fastcc i32 @runtime_mix_c_add_may_panic_main.add_may_panic(i32 %0) unnamed_addr align 1 {
        \\1:
        \\  %2 = icmp slt i32 %0, 0
        \\  br i1 %2, label %6, label %3
        \\
        \\3:
        \\  %4 = load i32, ptr getelementptr inbounds (i8, ptr @runtime_mix_c_add_may_panic_main.zig_k, i64 0), align 4
        \\  %5 = add nsw i32 %4, %0
        \\  ret i32 %5
        \\
        \\6:
        \\  call void @llvm.assume(i1 true) [ "cold"() ]
        \\  %7 = extractvalue { ptr, i64 } { ptr getelementptr inbounds (i8, ptr @__anon_186, i64 0), i64 13 }, 0
        \\  %8 = extractvalue { ptr, i64 } { ptr getelementptr inbounds (i8, ptr @__anon_186, i64 0), i64 13 }, 1
        \\  call fastcc void @debug.defaultPanic(ptr readonly nonnull %7, i64 %8, ptr align 8 readonly nonnull @__anon_310)
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

    try expectMachineInstruction(machine.instructions.items, .{ .test_arg32 = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_imm_rsi = 13 });
    var saw_zig_k_load = false;
    var saw_panic_message = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .load_global_i32_eax => |symbol| saw_zig_k_load = saw_zig_k_load or std.mem.eql(u8, symbol, "runtime_mix_c_add_may_panic_main.zig_k"),
        .lea_global_rdi => |symbol| saw_panic_message = saw_panic_message or std.mem.eql(u8, symbol, "__anon_186"),
        else => {},
    };
    try std.testing.expect(saw_zig_k_load);
    try std.testing.expect(saw_panic_message);
}

test "x86_64 codegen routes alloca pointer struct field loads through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @field_a(ptr %pair) {
        \\entry:
        \\  %slot = alloca ptr
        \\  store ptr %pair, ptr %slot
        \\  %loaded_ptr = load ptr, ptr %slot
        \\  %loaded = load i32, ptr %loaded_ptr
        \\  ret i32 %loaded
        \\}
        \\
        \\define i32 @field_b(ptr %pair) {
        \\entry:
        \\  %slot = alloca ptr
        \\  store ptr %pair, ptr %slot
        \\  %loaded_ptr = load ptr, ptr %slot
        \\  %field_ptr = getelementptr i8, ptr %loaded_ptr, i64 4
        \\  %loaded = load i32, ptr %field_ptr
        \\  ret i32 %loaded
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
        try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    }
}

test "x86_64 codegen routes struct field branch update through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @branch_update(i32 %flag, ptr %pair) {
        \\entry:
        \\  %slot = alloca ptr
        \\  store ptr %pair, ptr %slot
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %then_ptr = load ptr, ptr %slot
        \\  %then_old = load i32, ptr %then_ptr
        \\  %then_new = add i32 %then_old, 5
        \\  store i32 %then_new, ptr %then_ptr
        \\  br label %merge
        \\else:
        \\  %else_ptr = load ptr, ptr %slot
        \\  %else_old = load i32, ptr %else_ptr
        \\  %else_new = add i32 %else_old, 7
        \\  store i32 %else_new, ptr %else_ptr
        \\  br label %merge
        \\merge:
        \\  %ret_ptr = load ptr, ptr %slot
        \\  %ret_value = load i32, ptr %ret_ptr
        \\  ret i32 %ret_value
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

test "x86_64 codegen rejects unsupported aggregate field offset from generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @field_c(ptr %pair) {
        \\entry:
        \\  %slot = alloca ptr
        \\  store ptr %pair, ptr %slot
        \\  %loaded_ptr = load ptr, ptr %slot
        \\  %field_ptr = getelementptr i8, ptr %loaded_ptr, i64 12
        \\  %loaded = load i32, ptr %field_ptr
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    if (codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    )) |machine| {
        var owned = machine;
        defer owned.deinit(std.testing.allocator);
        try std.testing.expectEqual(codegen.x86_64.CodegenPath.structural_matcher, owned.codegen_path);
    } else |err| switch (err) {
        error.UnsupportedCodegenInstruction, error.UnsupportedCodegenValue => {},
        else => return err,
    }
}

test "x86_64 codegen routes single-block volatile roundtrip through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @volatile_roundtrip(ptr %ptr, i32 %value) {
        \\entry:
        \\  store volatile i32 %value, ptr %ptr
        \\  %loaded = load volatile i32, ptr %ptr
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
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes packed bit scalar helpers through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i8 @replace_low(i8 %a, i8 %b) {
        \\entry:
        \\  %high = and i8 %a, -8
        \\  %low = and i8 %b, 7
        \\  %result = or i8 %high, %low
        \\  ret i8 %result
        \\}
        \\
        \\define i1 @read_flag(i8 %a) {
        \\entry:
        \\  %flag = icmp slt i8 %a, 0
        \\  ret i1 %flag
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

test "x86_64 codegen keeps multi-block volatile memory cfg out of generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @volatile_memory(i32 %flag, ptr %ptr) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %loaded = load volatile i32, ptr %ptr
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %loaded, %then ], [ 0, %else ]
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenControlFlow,
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}

test "x86_64 machine verifier checks call stack alignment and frame balance" {
    var misaligned = codegen.x86_64.MachineFunction.init("bad_call", .{ .int = 32 });
    defer misaligned.deinit(std.testing.allocator);
    try misaligned.instructions.append(std.testing.allocator, .{ .direct_call = .{
        .symbol = "callee",
        .ret_ty = .{ .int = 32 },
    } });
    try misaligned.instructions.append(std.testing.allocator, .ret);
    try std.testing.expectError(error.MisalignedStackBeforeCall, codegen.x86_64.verifyFunction(misaligned));

    var unbalanced = codegen.x86_64.MachineFunction.init("bad_frame", .{ .int = 32 });
    defer unbalanced.deinit(std.testing.allocator);
    try unbalanced.instructions.append(std.testing.allocator, .sub_rsp_8);
    try unbalanced.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 1 });
    try unbalanced.instructions.append(std.testing.allocator, .ret);
    try std.testing.expectError(error.UnbalancedStackFrame, codegen.x86_64.verifyFunction(unbalanced));
}
