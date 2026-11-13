const std = @import("std");
const ir = @import("../../ir.zig");
const x86 = @import("../x86_64.zig");
const elf = @import("../../mc/elf.zig");
const assembly = @import("../../mc/assembly.zig");
fn read(comptime T: type, bytes: []const u8, at: usize) T {
    return std.mem.readInt(T, bytes[at..][0..@sizeOf(T)], .little);
}
test "function placement keeps symbols relocations and section alignment consistent" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a, "@address = global ptr @aligned, align 8\n" ++
        "define i32 @first() {\nentry:\n ret i32 1\n}\n" ++
        "define i32 @aligned() align 64 {\nentry:\n ret i32 42\n}\n" ++
        "define i32 @caller() {\nentry:\n %r = call i32 @aligned()\n ret i32 %r\n}\n");
    defer module.deinit();
    try module.verify();
    const context: x86.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = &.{}, .target_datalayout = null, .functions = module.functions.items, .emit_all_globals = true };
    var functions: [3]x86.MachineFunction = undefined;
    var count: usize = 0;
    defer for (functions[0..count]) |*f| f.deinit(a);
    for (module.functions.items, 0..) |f, i| {
        functions[i] = try x86.lowerFunctionWithOptions(a, "x86_64-unknown-linux-gnu", f, .{ .generic_cfg_selector = true, .module_context = &context });
        count += 1;
    }
    try std.testing.expectEqual(@as(u32, 1), functions[0].symbol_alignment);
    try std.testing.expectEqual(@as(u32, 64), functions[1].symbol_alignment);
    const object = try elf.buildObjectWithModuleContext(a, &functions, &.{}, context);
    defer a.free(object);
    const shoff: usize = @intCast(read(u64, object, 40));
    const text = object[shoff + 64 ..][0..64];
    const symtab = object[shoff + 5 * 64 ..][0..64];
    const rela = object[shoff + 4 * 64 ..][0..64];
    try std.testing.expectEqual(@as(u64, 64), read(u64, text, 48));
    try std.testing.expectEqual(@as(u64, 0), read(u64, text, 24) % 64);
    const symbols_at: usize = @intCast(read(u64, symtab, 24));
    const aligned = read(u64, object, symbols_at + 2 * 24 + 8);
    const first_size = read(u64, object, symbols_at + 24 + 16);
    try std.testing.expect(aligned > first_size);
    try std.testing.expectEqual(@as(u64, 0), aligned % 64);
    const caller = read(u64, object, symbols_at + 3 * 24 + 8);
    const caller_size = read(u64, object, symbols_at + 3 * 24 + 16);
    const relocation_at: usize = @intCast(read(u64, rela, 24));
    const offset = read(u64, object, relocation_at);
    try std.testing.expect(offset >= caller and offset < caller + caller_size);
    var text_assembly: std.Io.Writer.Allocating = .init(a);
    defer text_assembly.deinit();
    try assembly.printFunction(functions[1], &text_assembly.writer);
    try std.testing.expect(std.mem.indexOf(u8, text_assembly.written(), "\t.balign 64\n") != null);
    functions[1].symbol_alignment = 3;
    try std.testing.expectError(error.UnsupportedFunctionAlignment, x86.verifyFunction(functions[1]));
    try std.testing.expectError(error.UnsupportedFunctionAlignment, elf.buildObject(a, &functions));
}
