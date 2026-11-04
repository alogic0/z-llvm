const std = @import("std");
const ir = @import("../ir.zig");

test "parser preserves complete quoted parameter names and nested attributes" {
    const input =
        \\%"record type" = type { i32 }
        \\define i32 @parameters(ptr byval(%"record type") align 4 %"record pointer", i32 noundef %"source value", i32 %"escaped\20name") {
        \\entry:
        \\  ret i32 %"source value"
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const params = module.functions.items[0].params.items;
    try std.testing.expectEqualStrings("\"record pointer\"", params[0].name);
    try std.testing.expectEqualStrings("byval(%\"record type\") align 4", params[0].attrs.?);
    try std.testing.expectEqualStrings("\"source value\"", params[1].name);
    try std.testing.expectEqualStrings("noundef", params[1].attrs.?);
    try std.testing.expectEqualStrings("\"escaped\\20name\"", params[2].name);
    try std.testing.expectEqual(null, params[2].attrs);
    try module.verify();
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    var reparsed = try ir.Module.parse(std.testing.allocator, output.written());
    defer reparsed.deinit();
    try reparsed.verify();
    for (params, reparsed.functions.items[0].params.items) |original, round_trip| {
        try std.testing.expectEqualStrings(original.name, round_trip.name);
        try std.testing.expectEqualStrings(original.attrs orelse "", round_trip.attrs orelse "");
    }
}

test "parser rejects trailing parameter text without slicing before the name" {
    try std.testing.expectError(error.InvalidParameter, ir.Module.parse(std.testing.allocator,
        \\define i32 @invalid(i32 %x noundef) {
        \\entry:
        \\  ret i32 %x
        \\}
    ));
}
