//! AIR carries literal symbol bytes; IR carries complete LLVM spellings.
//! Convert at the producer boundary before canonical verification/lookup.
const std = @import("std");
const ir = @import("ir.zig");

fn name(module: *ir.Module, bytes: []const u8) ![]const u8 {
    if (bytes.len != 0 and bytes[0] != '"' and !std.ascii.isDigit(bytes[0]) and ir.identifiers.isValid(bytes)) return bytes;
    return module.ownString(try ir.identifiers.fromBytes(module.allocator, bytes));
}

const Values = struct {
    module: *ir.Module,
    pub const Error = anyerror;

    pub fn visit(values: Values, value: *ir.Value, _: ir.Type) Error!void {
        if (value.* != .named or !std.mem.startsWith(u8, value.named, "@")) return;
        const spelling = try name(values.module, value.named[1..]);
        if (spelling.ptr == value.named[1..].ptr) return;
        value.* = .{ .named = try values.module.ownString(try std.fmt.allocPrint(values.module.allocator, "@{s}", .{spelling})) };
    }
};

pub fn normalize(module: *ir.Module) !void {
    const values: Values = .{ .module = module };
    for (module.globals.items) |*global| {
        global.name = try name(module, global.name);
        if (global.initializer == .scalar) try values.visit(&global.initializer.scalar, global.ty);
    }
    for (module.functions.items) |*function| {
        function.name = try name(module, function.name);
        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                if (instruction.kind == .call) {
                    const call = &instruction.kind.call;
                    if (call.inline_asm == null and call.callee_value == null) call.callee = try name(module, call.callee);
                }
                _ = try ir.operands.instruction(instruction, values);
            }
            if (block.terminator) |*term| _ = try ir.operands.terminator(term, values);
        }
    }
}

test "AIR literal symbols become complete IR spellings without decoding literal escapes" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\@object = global i64 9
        \\define ptr @helper() {
        \\entry:
        \\ ret ptr @object
        \\}
        \\define ptr @caller() {
        \\entry:
        \\ %p = call ptr @helper()
        \\ ret ptr %p
        \\}
    );
    defer module.deinit();
    const raw = "literal\\31,\"name";
    module.globals.items[0].name = raw;
    module.functions.items[0].name = "generic(ptr,usize).helper";
    module.functions.items[0].blocks.items[0].terminator.?.ret.value = .{ .named = "@" ++ raw };
    module.functions.items[1].blocks.items[0].instructions.items[0].kind.call.callee = module.functions.items[0].name;
    try normalize(&module);
    try module.verify();
    try std.testing.expectEqualStrings("\"literal\\5C31,\\22name\"", module.globals.items[0].name);
    try std.testing.expectEqualStrings("@\"literal\\5C31,\\22name\"", module.functions.items[0].blocks.items[0].terminator.?.ret.value.?.named);
    try std.testing.expectEqualStrings("\"generic(ptr,usize).helper\"", module.functions.items[0].name);
    try std.testing.expectEqualStrings(module.functions.items[0].name, module.functions.items[1].blocks.items[0].instructions.items[0].kind.call.callee);
}
