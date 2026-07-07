const common = @import("codegen_x86_64_common.zig");

const std = common.std;
const codegen = common.codegen;
const ir = common.ir;
const selector = @import("../codegen/x86_64/generic_cfg_selector.zig");

test "generic cfg selector skeleton reports no emitter for supported straight-line integer shape" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add32(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    const result = selector.inspectFunction(module.functions.items[0]);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("no_emitter", diagnostic.tagName());
    try std.testing.expectEqualStrings("selector-skeleton-has-no-emitters", diagnostic.detail());
}

test "generic cfg selector skeleton preserves recognizer fallback while opt-in" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add32(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = try codegen.x86_64.lowerFunctionWithOptions(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
        .{ .generic_cfg_selector = true },
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "generic cfg selector skeleton fails closed with first unsupported instruction form" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define float @float_add(float %a, float %b) {
        \\entry:
        \\  %sum = fadd float %a, %b
        \\  ret float %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    const result = selector.inspectFunction(module.functions.items[0]);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("unsupported_type", diagnostic.tagName());
    try std.testing.expectEqualStrings("unsupported-return-type", diagnostic.detail());
}

test "generic cfg selector planning accepts scalar phi and overflow extracts" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @phi_overflow(i64 %a, i1 %cond) {
        \\entry:
        \\  br i1 %cond, label %then, label %merge
        \\then:
        \\  %pair = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %a, i64 1)
        \\  %sum = extractvalue { i64, i1 } %pair, 0
        \\  %overflow = extractvalue { i64, i1 } %pair, 1
        \\  call void @llvm.assume(i1 %overflow)
        \\  br label %merge
        \\merge:
        \\  %value = phi i64 [ %a, %entry ], [ %sum, %then ]
        \\  ret i64 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    const result = selector.inspectFunction(module.functions.items[0]);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("no_emitter", diagnostic.tagName());
    try std.testing.expectEqualStrings("selector-skeleton-has-no-emitters", diagnostic.detail());
}

test "generic cfg selector rejects unsupported aggregate extract" {
    var function = ir.Function.init("bad_extract", .{ .int = 32 });
    defer function.deinit(std.testing.allocator);

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(std.testing.allocator);
    try block.instructions.append(std.testing.allocator, .{
        .result = "value",
        .kind = .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = "{ i32, i32 }" },
            .aggregate = .undef,
            .indices = "0",
            .result_ty = .{ .int = 32 },
        } },
    });
    block.terminator = .{ .ret = .{
        .ty = .{ .int = 32 },
        .value = .{ .named = "value" },
    } };
    try function.blocks.append(std.testing.allocator, block);

    const result = selector.inspectFunction(function);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("unsupported_type", diagnostic.tagName());
    try std.testing.expectEqualStrings("extractvalue-aggregate", diagnostic.detail());
}
