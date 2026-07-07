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
