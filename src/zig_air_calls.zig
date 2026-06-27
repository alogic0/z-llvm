const std = @import("std");
const ir = @import("ir.zig");

pub fn addMissingCallDeclarations(allocator: std.mem.Allocator, module: *ir.Module) !void {
    for (module.functions.items) |function| {
        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                const call = switch (instruction.kind) {
                    .call => |call| call,
                    else => continue,
                };
                if (call.callee_value != null or call.inline_asm != null) continue;
                if (moduleHasFunctionOrDeclaration(module.*, call.callee)) continue;
                var decl = ir.FunctionDecl.init(call.callee, call.ret_ty);
                errdefer decl.deinit(allocator);
                decl.calling_conv = call.calling_conv;
                for (call.args.items) |arg| {
                    try decl.params.append(allocator, .{
                        .ty = arg.ty,
                        .attrs = arg.attrs,
                    });
                }
                try module.declarations.append(allocator, decl);
            }
        }
    }
}

pub fn moduleHasFunctionOrDeclaration(module: ir.Module, name: []const u8) bool {
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, name)) return true;
    }
    for (module.declarations.items) |decl| {
        if (std.mem.eql(u8, decl.name, name)) return true;
    }
    return false;
}

test "add missing direct call declarations" {
    const input =
        \\define i32 @caller(i32 %x) {
        \\entry:
        \\  %r = call fastcc i32 @callee(i32 %x)
        \\  ret i32 %r
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expect(!moduleHasFunctionOrDeclaration(module, "callee"));
    try addMissingCallDeclarations(std.testing.allocator, &module);
    try std.testing.expect(moduleHasFunctionOrDeclaration(module, "callee"));
    try std.testing.expectEqual(@as(usize, 1), module.declarations.items.len);
    try std.testing.expectEqualStrings("fastcc", module.declarations.items[0].calling_conv.?);
    try std.testing.expectEqual(ir.Type{ .int = 32 }, module.declarations.items[0].ret_ty);
    try std.testing.expectEqual(@as(usize, 1), module.declarations.items[0].params.items.len);
}
