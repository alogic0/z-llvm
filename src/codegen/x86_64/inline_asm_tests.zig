const std = @import("std");
const ir = @import("../../ir.zig");
const asm_forms = @import("inline_asm.zig");
const codegen = @import("../../codegen.zig");
const encoding = @import("../../mc/encoding.zig");

test "system assembly validates constraints and preserves simultaneous inputs" {
    for (0..7) |count| {
        var source: std.Io.Writer.Allocating = .init(std.testing.allocator);
        defer source.deinit();
        const w = &source.writer;
        try w.writeAll("define i64 @f(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {\nentry:\n %r = call i64 asm sideeffect \"syscall\", \"={rax}");
        for (asm_forms.syscall_inputs[0 .. count + 1]) |constraint| try w.print(",{s}", .{constraint});
        try w.print(",{s}\"(i64 39", .{asm_forms.syscall_clobbers});
        const values = [_][]const u8{ "%f", "%e", "%d", "%c", "%b", "%a" };
        for (values[0..count]) |value| try w.print(", i64 {s}", .{value});
        try w.writeAll(")\n %sum = add i64 %r, %c\n ret i64 %sum\n}\n");
        var module = try ir.Module.parse(std.testing.allocator, source.written());
        defer module.deinit();
        try module.verify();
        const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
        try std.testing.expectEqual(@as(u3, @intCast(count)), asm_forms.classify(call).?.linux_syscall);
        for (0..8) |mutation| {
            var invalid = call;
            switch (mutation) {
                0 => invalid.inline_asm.?.sideeffect = false,
                1 => invalid.inline_asm.?.template = "syscall; ret",
                2 => invalid.inline_asm.?.constraints = "={rax},{rax},~{memory}",
                3 => invalid.ret_ty = .{ .int = 32 },
                4 => invalid.calling_conv = "fastcc",
                5 => invalid.operand_bundle = "[ \"deopt\"() ]",
                6 => invalid.raw_args = "i64 39",
                7 => invalid.tail_kind = "musttail",
                else => unreachable,
            }
            try std.testing.expect(asm_forms.classify(invalid) == null);
        }
        var machine = try codegen.x86_64.lowerFunctionWithOptions(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
        defer machine.deinit(std.testing.allocator);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        try std.testing.expect(std.mem.indexOf(u8, bytes, &.{ 0x0f, 0x05 }) != null);
        if (count >= 4) try std.testing.expect(std.mem.indexOf(u8, bytes, &.{ 0x49, 0x89, 0xca, 0x0f, 0x05 }) != null);
    }
}

test "system assembly snapshot validates full layout and an unused syscall result" {
    const text = try std.fmt.allocPrint(std.testing.allocator, "define void @snapshot(ptr %p) {{\nentry:\n call void asm sideeffect \"{s}\", \"{s}\"(ptr %p)\n %unused = call i64 asm sideeffect \"syscall\", \"={{rax}},{{rax}},{s}\"(i64 39)\n ret void\n}}\n", .{ asm_forms.snapshot_template, asm_forms.snapshot_constraints, asm_forms.syscall_clobbers });
    defer std.testing.allocator.free(text);
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(asm_forms.classify(call).? == .register_snapshot);
    var invalid = call;
    invalid.inline_asm.?.constraints = "{rdi},~{memory}";
    try std.testing.expect(asm_forms.classify(invalid) == null);
    var machine = try codegen.x86_64.lowerFunctionWithOptions(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
    defer machine.deinit(std.testing.allocator);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    var size: usize = 0;
    for (machine.instructions.items) |inst| size += encoding.instructionSize(inst);
    try std.testing.expectEqual(size, bytes.len);
    try std.testing.expect(std.mem.indexOf(u8, bytes, &.{ 0x48, 0x89, 0x87, 0x80, 0, 0, 0 }) != null);
}
