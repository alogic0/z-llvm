const std = @import("std");
const ir = @import("../ir.zig");

test "runtime vector floating casts verify lane counts element types and width direction" {
    for ([_]struct { op: []const u8, from: []const u8, to: []const u8, err: ?anyerror = null }{
        .{ .op = "fpext", .from = "<2 x float>", .to = "<2 x double>" },
        .{ .op = "fptrunc", .from = "<2 x double>", .to = "<2 x float>" },
        .{ .op = "fpext", .from = "<4 x half>", .to = "<4 x fp128>" },
        .{ .op = "fptrunc", .from = "<4 x fp128>", .to = "<4 x half>" },
        .{ .op = "fpext", .from = "float", .to = "double" },
        .{ .op = "fptrunc", .from = "double", .to = "float" },
        .{ .op = "fpext", .from = "<2 x double>", .to = "<2 x float>", .err = error.InvalidCast },
        .{ .op = "fptrunc", .from = "<2 x float>", .to = "<2 x double>", .err = error.InvalidCast },
        .{ .op = "fptrunc", .from = "<2 x float>", .to = "<2 x float>", .err = error.InvalidCast },
        .{ .op = "fptrunc", .from = "<2 x double>", .to = "<4 x float>", .err = error.TypeMismatch },
        .{ .op = "fpext", .from = "<2 x float>", .to = "double", .err = error.TypeMismatch },
        .{ .op = "fptrunc", .from = "double", .to = "<2 x float>", .err = error.TypeMismatch },
        .{ .op = "fptrunc", .from = "<2 x i64>", .to = "<2 x float>", .err = error.InvalidCast },
        .{ .op = "fpext", .from = "<2 x ptr>", .to = "<2 x double>", .err = error.InvalidCast },
    }) |case| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define {s} @cast({s} %value) {{\nentry:\n %result = {s} {s} %value to {s}\n ret {s} %result\n}}\n", .{ case.to, case.from, case.op, case.from, case.to, case.to });
        defer std.testing.allocator.free(source);
        var module = try roundTrip(source);
        defer module.deinit();
        if (case.err) |err| try std.testing.expectError(err, module.verify()) else try module.verify();
    }
}

fn roundTrip(source: []const u8) !ir.Module {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    return ir.Module.parse(std.testing.allocator, output.written());
}

test "compiler parser switch delimiters ignore quoted brackets and escaped quotes" {
    const source =
        \\define i32 @quoted_switch(i8 %"input[0]") {
        \\entry:
        \\  switch i8 %"input[0]", label %"exit[0..4]\22name" [
        \\    i8 1, label %"case]1"
        \\  ]
        \\"case]1":
        \\  ret i32 1
        \\"exit[0..4]\22name":
        \\  ret i32 0
        \\}
    ;
    var module = try roundTrip(source);
    defer module.deinit();
    try module.verify();
    const term = module.functions.items[0].blocks.items[0].terminator.?.@"switch";
    try std.testing.expectEqualStrings("\"exit[0..4]\\22name\"", term.default_target);
    try std.testing.expectEqualStrings("\"case]1\"", term.cases.items[0].target);
    try std.testing.expectError(error.InvalidSwitch, ir.Module.parse(std.testing.allocator,
        \\define void @missing(i8 %x) {
        \\entry:
        \\  switch i8 %x, label %"quoted[only]"
        \\}
    ));
}

test "compiler parser preserves switch loop metadata and rejects unknown attachments" {
    const source =
        \\define void @loop(i8 %x) {
        \\entry:
        \\  br label %body
        \\body:
        \\  switch i8 %x, label %body [
        \\    i8 0, label %exit
        \\  ], !prof !0, !llvm.loop !1
        \\exit:
        \\  ret void
        \\}
        \\!0 = !{!"branch_weights", i32 2, i32 1}
        \\!1 = distinct !{!1}
    ;
    var module = try roundTrip(source);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqualStrings("!prof !0, !llvm.loop !1", module.functions.items[0].blocks.items[1].terminator.?.@"switch".metadata.?);
    const unknown = try std.mem.replaceOwned(u8, std.testing.allocator, source, "!llvm.loop", "!unrecognized.loop");
    defer std.testing.allocator.free(unknown);
    try std.testing.expectError(error.UnsupportedInstructionMetadata, ir.Module.parse(std.testing.allocator, unknown));
}

test "compiler parser preserves vector GEP syntax without granting scalar verification" {
    const source =
        \\define void @vector_index(ptr %base) {
        \\entry:
        \\  %addresses = getelementptr i8, ptr %base, <4 x i64> <i64 856, i64 680, i64 1216, i64 728>
        \\  ret void
        \\}
    ;
    var module = try roundTrip(source);
    defer module.deinit();
    const index = module.functions.items[0].blocks.items[0].instructions.items[0].kind.gep.indices.items[0];
    try std.testing.expect(index.ty.eql(.{ .vector = .{ .len = 4, .elem_ty = .{ .int = 64 } } }));
    try std.testing.expectEqualStrings("<i64 856, i64 680, i64 1216, i64 728>", index.value.vector);
    try std.testing.expectError(error.UnsupportedVectorGetElementPtr, module.verify());
}

test "compiler parser indirect branch targets preserve quoted spaces commas and brackets" {
    const source =
        \\define void @jump(ptr %address) {
        \\entry:
        \\  indirectbr ptr %address, [label %"target ] with, spaces", label %"target [ with spaces"]
        \\"target ] with, spaces":
        \\  ret void
        \\"target [ with spaces":
        \\  ret void
        \\}
    ;
    var module = try roundTrip(source);
    defer module.deinit();
    try module.verify();
    const targets = module.functions.items[0].blocks.items[0].terminator.?.indirectbr.targets.items;
    try std.testing.expectEqualStrings("\"target ] with, spaces\"", targets[0]);
    try std.testing.expectEqualStrings("\"target [ with spaces\"", targets[1]);
    const bad = try std.mem.replaceOwned(u8, std.testing.allocator, source, "spaces\"]", "spaces\" trailing]");
    defer std.testing.allocator.free(bad);
    try std.testing.expectError(error.InvalidLabel, ir.Module.parse(std.testing.allocator, bad));
}

test "compiler parser GEP scalar indices retain quoted names and reject trailing text" {
    const source =
        \\define ptr @scalar_index(ptr %base, i64 %"index with space") {
        \\entry:
        \\  %address = getelementptr i8, ptr %base, i64 %"index with space"
        \\  ret ptr %address
        \\}
    ;
    var module = try roundTrip(source);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqualStrings("\"index with space\"", module.functions.items[0].blocks.items[0].instructions.items[0].kind.gep.indices.items[0].value.named);
    const bad = try std.mem.replaceOwned(u8, std.testing.allocator, source, "ptr %base, i64 %\"index with space\"\n", "ptr %base, i64 1 extra\n");
    defer std.testing.allocator.free(bad);
    if (ir.Module.parse(std.testing.allocator, bad)) |parsed| {
        var unexpected = parsed;
        defer unexpected.deinit();
        return error.ExpectedMalformedIndexRejection;
    } else |_| {}
}
