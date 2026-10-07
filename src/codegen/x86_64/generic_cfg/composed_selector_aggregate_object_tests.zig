const std = @import("std");
const ir = @import("../../../ir.zig");
const encoding = @import("../../../mc/encoding.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("composed_selector_impl.zig");

const FloatVectorPair = extern struct {
    value: [2]f32,
};

test "exact f32 aggregate objects execute stores pointer phis and packed loads" {
    const input =
        \\%pair = type { float, float }
        \\
        \\define { <2 x float> } @choose_pair(i32 %choose, float %left0, float %left1, float %right0, float %right1, float %replacement) {
        \\entry:
        \\  %left = alloca %pair, align 4
        \\  %right = alloca %pair, align 4
        \\  %left1.ptr = getelementptr i8, ptr %left, i64 4
        \\  %right1.ptr = getelementptr i8, ptr %right, i64 4
        \\  store float %left0, ptr %left, align 4
        \\  store float %left1, ptr %left1.ptr, align 4
        \\  store float %right0, ptr %right, align 4
        \\  store float %right1, ptr %right1.ptr, align 4
        \\  %condition = icmp ne i32 %choose, 0
        \\  br i1 %condition, label %take_left, label %take_right
        \\take_left:
        \\  br label %merge
        \\take_right:
        \\  br label %merge
        \\merge:
        \\  %base = phi ptr [ %left, %take_left ], [ %right, %take_right ]
        \\  %field = phi ptr [ %left1.ptr, %take_left ], [ %right1.ptr, %take_right ]
        \\  store float %replacement, ptr %field, align 4
        \\  %lanes = load <2 x float>, ptr %base, align 4
        \\  %result = insertvalue { <2 x float> } poison, <2 x float> %lanes, 0
        \\  ret { <2 x float> } %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const context = moduleContext(module);

    const function = module.functions.items[0];
    var lowered = machine.MachineFunction.init(function.name, function.ret_ty);
    defer lowered.deinit(std.testing.allocator);
    const selection = try selector.tryLowerComposedCfgWithContext(std.testing.allocator, &lowered, function, &context);
    switch (selection) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("aggregate-object canary: {any}\n", .{diagnostic});
            return error.TestUnexpectedResult;
        },
    }
    try verify.verifyFunction(lowered);

    var stack_pointer_count: usize = 0;
    var pointer_spill_count: usize = 0;
    var saw_packed_load = false;
    for (lowered.instructions.items) |instruction| switch (instruction) {
        .mov_rsp_arg64 => stack_pointer_count += 1,
        .spill_arg64_rsp => pointer_spill_count += 1,
        .load_arg_ptr_disp8_xmm, .load_stack_disp8_xmm0, .load_stack_disp32_xmm0 => saw_packed_load = true,
        else => {},
    };
    try std.testing.expect(stack_pointer_count >= 2 and pointer_spill_count >= 2 and saw_packed_load);

    const bytes = try encoding.encodeFunction(std.testing.allocator, lowered);
    defer std.testing.allocator.free(bytes);
    const mapping = try executableMapping(bytes);
    defer std.posix.munmap(mapping);
    const choose_pair: *const fn (u32, f32, f32, f32, f32, f32) callconv(.c) FloatVectorPair = @ptrCast(mapping.ptr);

    const left0_bits: u32 = 0x7fa0_1234;
    const left1_bits: u32 = 0x8000_0000;
    const right0_bits: u32 = 0x0000_0001;
    const right1_bits: u32 = 0x7f80_0000;
    const replacement_bits: u32 = 0xffc1_5678;
    const args = .{
        @as(f32, @bitCast(left0_bits)),
        @as(f32, @bitCast(left1_bits)),
        @as(f32, @bitCast(right0_bits)),
        @as(f32, @bitCast(right1_bits)),
        @as(f32, @bitCast(replacement_bits)),
    };
    const left = choose_pair(1, args[0], args[1], args[2], args[3], args[4]).value;
    try std.testing.expectEqual(left0_bits, @as(u32, @bitCast(left[0])));
    try std.testing.expectEqual(replacement_bits, @as(u32, @bitCast(left[1])));
    const right = choose_pair(0, args[0], args[1], args[2], args[3], args[4]).value;
    try std.testing.expectEqual(right0_bits, @as(u32, @bitCast(right[0])));
    try std.testing.expectEqual(replacement_bits, @as(u32, @bitCast(right[1])));
}

test "exact f32 aggregate objects reject unproved shapes alignment and bounds" {
    const input =
        \\%pair = type { float, float }
        \\%triple = type { float, float, float }
        \\
        \\define void @wrong_shape(float %value) {
        \\entry:
        \\  %slot = alloca %triple, align 4
        \\  store float %value, ptr %slot, align 4
        \\  ret void
        \\}
        \\
        \\define void @overaligned(float %value) {
        \\entry:
        \\  %slot = alloca %pair, align 8
        \\  store float %value, ptr %slot, align 4
        \\  ret void
        \\}
        \\
        \\define void @out_of_bounds(float %value) {
        \\entry:
        \\  %slot = alloca %pair, align 4
        \\  %end = getelementptr i8, ptr %slot, i64 8
        \\  store float %value, ptr %end, align 4
        \\  ret void
        \\}
        \\
        \\define void @mixed_phi_view(i32 %choose, float %value) {
        \\entry:
        \\  %left = alloca %pair, align 4
        \\  %right = alloca %pair, align 4
        \\  %right1.ptr = getelementptr i8, ptr %right, i64 4
        \\  %condition = icmp ne i32 %choose, 0
        \\  br i1 %condition, label %take_left, label %take_right
        \\take_left:
        \\  br label %merge
        \\take_right:
        \\  br label %merge
        \\merge:
        \\  %field = phi ptr [ %left, %take_left ], [ %right1.ptr, %take_right ]
        \\  store float %value, ptr %field, align 4
        \\  ret void
        \\}
        \\
        \\define { <2 x float> } @partial_vector_load() {
        \\entry:
        \\  %slot = alloca %pair, align 4
        \\  %field = getelementptr i8, ptr %slot, i64 4
        \\  %lanes = load <2 x float>, ptr %field, align 4
        \\  %result = insertvalue { <2 x float> } poison, <2 x float> %lanes, 0
        \\  ret { <2 x float> } %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const context = moduleContext(module);

    const expected = [_][]const u8{
        "composed-block-alloca-form",
        "composed-block-aggregate-alloca-align",
        "composed-block-store-f32-pair-bounds",
        "composed-block-store-fp-ptr",
        "composed-block-load-f32-pair-bounds",
    };
    for (module.functions.items, expected) |function, expected_detail| {
        var rejected = machine.MachineFunction.init(function.name, function.ret_ty);
        defer rejected.deinit(std.testing.allocator);
        const selection = try selector.tryLowerComposedCfgWithContext(
            std.testing.allocator,
            &rejected,
            function,
            &context,
        );
        switch (selection) {
            .selected => return error.TestUnexpectedResult,
            .unsupported => |diagnostic| try std.testing.expectEqualStrings(expected_detail, diagnostic.detail()),
        }
    }
}

fn moduleContext(module: ir.Module) machine.ReadOnlyModuleContext {
    return .{
        .globals = module.globals.items,
        .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
    };
}

fn executableMapping(bytes: []const u8) ![]align(std.heap.page_size_min) u8 {
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(mapping, bytes);
    return mapping;
}
