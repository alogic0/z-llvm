const std = @import("std");
const ir = @import("../ir.zig");
const closure = @import("direct_symbol_closure.zig");
const base = "define internal fastcc void @f(<64 x i128> %x) {\nentry:\n ret void\n}\ndefine void @caller() {\nentry:\n call fastcc void @f(<64 x i128> zeroinitializer)\n ret void\n}\n";
fn check(text: []const u8, expected: bool) !void {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a, text);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const result = try closure.prove(arena.allocator(), module, &.{"f"});
    try std.testing.expectEqual(expected, result[0]);
}
test "closed signature proof accepts complete direct uses and escaped identity" {
    try check(base, true);
    const quoted = "define internal fastcc void @f(<64 x i128> %x) {\nentry:\n ret void\n}\ndefine void @caller() {\nentry:\n call fastcc void @\"\\66\"(<64 x i128> zeroinitializer)\n ret void\n}\n";
    try check(quoted, true);
    try check("@data = internal constant [2 x i8] c\"@f\"\n" ++ base ++ "; @f is only a comment\n", true);
}
test "closed signature proof rejects global alias metadata bundle and unknown assembly" {
    try check("@escaped = global ptr @f\n" ++ base, false);
    try check("@escaped = internal alias void (<64 x i128>), ptr @f\n" ++ base, false);
    try check(base ++ "!0 = !{ptr @f}\n", false);
    try check("define internal fastcc void @f(<64 x i128> %x) {\nentry:\n ret void\n}\ndefine void @caller() {\nentry:\n call fastcc void @f(<64 x i128> zeroinitializer) [\"clobber\"()]\n ret void\n}\n", false);
    try check(base ++ "define void @assembly() {\nentry:\n call void asm sideeffect \".macro hidden\", \"\"()\n ret void\n}\n", false);
}
test "closed signature proof rejects helper attributes and unknown syntax" {
    try check(base ++ "attributes #0 = { \"probe-stack\"=\"f\" }\n", false);
    try check(base ++ "attributes #0 = { \"probe-stack\"=\"\\66\" }\n", false);
    try check(base ++ "attributes #0 = { \"unclassified\"=\"f\" }\n", false);
    try check(base ++ "!0 = !{ptr @\"f\\ZZ\"}\n", false);
}
test "closed signature proof counts live module mutations rather than original source" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a, base);
    defer module.deinit();
    try module.aliases.append(a, .{ .name = "escaped", .aliased_ty = "void (<64 x i128>)", .target_ty = .ptr, .target = "f", .linkage = .internal });
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    try std.testing.expect(!(try closure.prove(arena.allocator(), module, &.{"f"}))[0]);
}
test "closed signature proof excludes implicit providers and public boundaries" {
    try check("define fastcc void @f(<64 x i128> %x) {\nentry:\n ret void\n}\ndefine void @caller() {\nentry:\n call fastcc void @f(<64 x i128> zeroinitializer)\n ret void\n}\n", false);
    const a = std.testing.allocator;
    for ([_][]const u8{ "memcpy", "fmodf128", "sqrtf", "__zig_probe_stack", "zig.target.intByteSize" }) |name| {
        const text = try std.fmt.allocPrint(a, "define internal fastcc void @{0s}(<64 x i128> %x) {{\nentry:\n ret void\n}}\ndefine void @caller() {{\nentry:\n call fastcc void @{0s}(<64 x i128> zeroinitializer)\n ret void\n}}\n", .{name});
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        try std.testing.expect(!(try closure.prove(arena.allocator(), module, &.{name}))[0]);
    }
}
