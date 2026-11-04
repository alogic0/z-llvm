const std = @import("std");
const ir = @import("../ir.zig");
const normalize = @import("../normalize.zig");

const reordered =
    \\source_filename = "numeric %1.ll"
    \\target datalayout = "e-p:64:64-i64:64-n8:16:32:64-S128"
    \\target triple = "x86_64-unknown-linux-gnu"
    \\%1 = type { i32 }
    \\@record = global %1 zeroinitializer, align 4
    \\@scalar = global i32 42, align 4
    \\define i32 @reordered(i32 %0) #0 {
    \\entry:
    \\  %2 = load i32, ptr @scalar, align 4, !noundef !1
    \\  %1 = add i32 %2, %0
    \\  ret i32 %1
    \\}
    \\attributes #0 = { nounwind "literal"="%1" }
    \\!0 = !{!"literal %1"}
    \\!1 = !{}
;

fn printed(allocator: std.mem.Allocator, module: ir.Module, canonical: bool) ![]u8 {
    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();
    try ir.printer.printWithOptions(module, &output.writer, .{ .numeric_names = if (canonical) .canonical else .repair });
    return allocator.dupe(u8, output.written());
}

fn contains(text: []const u8, expected: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, text, expected) != null);
}

fn verifyPrinted(text: []const u8) !void {
    var reparsed = try ir.Module.parse(std.testing.allocator, text);
    defer reparsed.deinit();
    try reparsed.verify();
}

test "numeric serialization repairs reordered values without changing IR or module records" {
    var module = try ir.Module.parse(std.testing.allocator, reordered);
    defer module.deinit();
    try module.verify();
    const strings_before = module.owned_strings.items.len;
    const output = try printed(std.testing.allocator, module, false);
    defer std.testing.allocator.free(output);
    try contains(output, "%1 = load i32, ptr @scalar, align 4, !noundef !1\n  %2 = add i32 %1, %0\n  ret i32 %2");
    for ([_][]const u8{
        "source_filename = \"numeric %1.ll\"",
        "target datalayout = \"e-p:64:64-i64:64-n8:16:32:64-S128\"",
        "target triple = \"x86_64-unknown-linux-gnu\"",
        "%1 = type { i32 }",
        "@record = global %1 zeroinitializer, align 4",
        "attributes #0 = { nounwind \"literal\"=\"%1\" }",
        "!0 = !{!\"literal %1\"}",
    }) |record| try contains(output, record);
    try std.testing.expectEqualStrings("2", module.functions.items[0].blocks.items[0].instructions.items[0].result.?);
    try std.testing.expectEqualStrings("1", module.functions.items[0].blocks.items[0].instructions.items[1].result.?);
    try std.testing.expectEqual(strings_before, module.owned_strings.items.len);
    const again = try printed(std.testing.allocator, module, false);
    defer std.testing.allocator.free(again);
    try std.testing.expectEqualStrings(output, again);
    try verifyPrinted(output);
}

test "numeric serialization preserves ordered gaps while comparison output is dense" {
    const input =
        \\define i32 @gaps(i32 %0) {
        \\entry:
        \\  %9 = add i32 %0, 3
        \\  ret i32 %9
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const output = try printed(std.testing.allocator, module, false);
    defer std.testing.allocator.free(output);
    try std.testing.expectEqualStrings(input, output);
    const canonical = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(canonical);
    try contains(canonical, "%1 = add i32 %0, 3\n  ret i32 %1");
}

test "numeric serialization counts the implicit entry block" {
    const output = try normalize.llvmCompatibleIr(std.testing.allocator,
        \\define i32 @implicit(i32 %0) {
        \\  %2 = add i32 %0, 1
        \\  ret i32 %2
        \\}
    );
    defer std.testing.allocator.free(output);
    try contains(output, "1:\n  %2 = add i32 %0, 1\n  ret i32 %2");
    try verifyPrinted(output);
}

test "numeric serialization follows forward references after block reordering" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @forward(i32 %0) {
        \\1:
        \\  br label %4
        \\2:
        \\  %3 = add i32 %5, 3
        \\  ret i32 %3
        \\4:
        \\  %5 = xor i32 %0, 7
        \\  br label %2
        \\}
    );
    defer module.deinit();
    const blocks = module.functions.items[0].blocks.items;
    std.mem.swap(ir.BasicBlock, &blocks[1], &blocks[2]);
    try module.verify();
    const output = try printed(std.testing.allocator, module, false);
    defer std.testing.allocator.free(output);
    try contains(output, "1:\n  br label %2\n2:\n  %3 = xor i32 %0, 7\n  br label %4\n4:\n  %5 = add i32 %3, 3\n  ret i32 %5");
    try verifyPrinted(output);
    try std.testing.expectEqualStrings("4", blocks[1].name);
    try std.testing.expectEqualStrings("2", blocks[2].name);
}

test "numeric serialization rewrites cyclic PHI values and predecessor labels once" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @loop(i32 %0) {
        \\1:
        \\  br label %2
        \\2:
        \\  %3 = phi i32 [ 0, %1 ], [ %6, %5 ]
        \\  %4 = icmp ult i32 %3, %0
        \\  br i1 %4, label %5, label %7
        \\5:
        \\  %6 = add i32 %3, 1
        \\  br label %2
        \\7:
        \\  ret i32 %3
        \\}
    );
    defer module.deinit();
    const blocks = module.functions.items[0].blocks.items;
    std.mem.swap(ir.BasicBlock, &blocks[2], &blocks[3]);
    try module.verify();
    const output = try printed(std.testing.allocator, module, false);
    defer std.testing.allocator.free(output);
    try contains(output, "%3 = phi i32 [ 0, %1 ], [ %7, %6 ]");
    try contains(output, "br i1 %4, label %6, label %5");
    try contains(output, "6:\n  %7 = add i32 %3, 1\n  br label %2");
    try verifyPrinted(output);
}

test "numeric serialization maps switch and indirect branch targets" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @switching(i32 %0) {
        \\1:
        \\  switch i32 %0, label %4 [
        \\    i32 0, label %2
        \\  ]
        \\4:
        \\  ret i32 9
        \\2:
        \\  ret i32 7
        \\}
        \\define void @indirect(ptr %0) {
        \\1:
        \\  indirectbr ptr %0, [label %4, label %2]
        \\4:
        \\  ret void
        \\2:
        \\  ret void
        \\}
    );
    defer module.deinit();
    try module.verify();
    const output = try printed(std.testing.allocator, module, false);
    defer std.testing.allocator.free(output);
    try contains(output, "switch i32 %0, label %2 [\n    i32 0, label %3");
    try contains(output, "indirectbr ptr %0, [label %2, label %3]");
    try verifyPrinted(output);
}

test "numeric serialization skips removed definitions and preserves quoted numeric names" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @quoted(i32 %0, i32 %"1") {
        \\entry:
        \\  %2 = add i32 %0, 1
        \\  %3 = xor i32 %0, 7
        \\  %1 = add i32 %3, %"1"
        \\  ret i32 %1
        \\}
    );
    defer module.deinit();
    module.functions.items[0].blocks.items[0].instructions.items[0].removed = true;
    try module.verify();
    const output = try printed(std.testing.allocator, module, true);
    defer std.testing.allocator.free(output);
    try contains(output, "@quoted(i32 %0, i32 %\"1\")");
    try contains(output, "%1 = xor i32 %0, 7\n  %2 = add i32 %1, %\"1\"\n  ret i32 %2");
    try verifyPrinted(output);
}

test "numeric serialization rejects opaque references before writing any module records" {
    const prefixes = [_][]const u8{
        "source_filename = \"reject.ll\"\n",
        "@block = global ptr null\n",
    };
    const bodies = [_][]const u8{
        \\declare void @external()
        \\define i32 @opaque(i32 %0) {
        \\entry:
        \\  %2 = xor i32 %0, 7
        \\  call void @external() [ "deopt"() ]
        \\  %1 = add i32 %2, 3
        \\  ret i32 %1
        \\}
        ,
        \\define void @opaque() {
        \\0:
        \\  br label %4
        \\4:
        \\  br label %2
        \\2:
        \\  ret void
        \\}
        ,
    };
    for (prefixes, bodies) |prefix, body| {
        const input = try std.mem.concat(std.testing.allocator, u8, &.{ prefix, body });
        defer std.testing.allocator.free(input);
        var module = try ir.Module.parse(std.testing.allocator, input);
        defer module.deinit();
        if (std.mem.startsWith(u8, prefix, "source_filename")) {
            // Nonempty bundles retain a parser boundary; exercise the printer
            // on structured IR carrying an opaque bundle from another producer.
            module.functions.items[0].blocks.items[0].instructions.items[1].kind.call.operand_bundle = "[ \"deopt\"(i32 %2) ]";
        } else {
            // A blockaddress must resolve its function as well as its block.
            module.globals.items[0].initializer = .{ .@"opaque" = "blockaddress(@missing, %4)" };
        }
        var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
        defer output.deinit();
        try std.testing.expectError(error.UnsupportedNumericLocalReference, module.print(&output.writer));
        try std.testing.expectEqual(@as(usize, 0), output.written().len);
    }
}

test "numeric serialization retains the unnamed nonvoid call verifier boundary" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare i32 @external()
        \\define i32 @unused(i32 %0) {
        \\entry:
        \\  call i32 @external()
        \\  %2 = add i32 %0, 3
        \\  ret i32 %2
        \\}
    );
    defer module.deinit();
    try std.testing.expectError(error.InstructionNeedsResult, module.verify());
}

test "numeric serialization rewrites value callees and typed call arguments" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @indirect_call(ptr %4, i32 %9) {
        \\entry:
        \\  %12 = call i32 %4(i32 %9)
        \\  ret i32 %12
        \\}
    );
    defer module.deinit();
    try module.verify();
    const output = try printed(std.testing.allocator, module, true);
    defer std.testing.allocator.free(output);
    try contains(output, "@indirect_call(ptr %0, i32 %1)");
    try contains(output, "%2 = call i32 %0(i32 %1)\n  ret i32 %2");
    try verifyPrinted(output);
}

test "numeric serialization rejects raw debug uses and permits unchanged opaque names" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare void @llvm.dbg.value(metadata, metadata, metadata)
        \\define i32 @debug_use(i32 %0) {
        \\entry:
        \\  %2 = xor i32 %0, 7
        \\  call void @llvm.dbg.value(metadata i32 %2, metadata !0, metadata !DIExpression())
        \\  %1 = add i32 %2, 3
        \\  ret i32 %1
        \\}
        \\!0 = !{}
    );
    defer module.deinit();
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try std.testing.expectError(error.UnsupportedNumericLocalReference, module.print(&output.writer));
    try std.testing.expectEqual(@as(usize, 0), output.written().len);
    const instructions = module.functions.items[0].blocks.items[0].instructions.items;
    // %0 retains its spelling, and %20 is a complete different token.
    instructions[1].kind.call.raw_args = "metadata i32 %0, metadata !0, metadata !DIExpression()";
    instructions[2].metadata = "!dbg !{!\"%2\", i32 %20}";
    try module.print(&output.writer);
    try contains(output.written(), "metadata i32 %0, metadata !0");
    try contains(output.written(), "!dbg !{!\"%2\", i32 %20}");
}

const block_addresses =
    \\@table = constant [3 x ptr] [ptr blockaddress(@"first fn", %4), ptr blockaddress(@other, %4), ptr blockaddress(@"first fn", %2)]
    \\define void @"first fn"() {
    \\0:
    \\  br label %4
    \\4:
    \\  br label %2
    \\2:
    \\  ret void
    \\}
    \\define i32 @other() {
    \\0:
    \\  br label %4
    \\4:
    \\  ret i32 7
    \\}
    \\!0 = !{!"blockaddress(@other, %4)"}
    \\!blockaddress = !{!0}
;

test "numeric serialization binds jump-table block addresses to their owning functions" {
    var module = try ir.Module.parse(std.testing.allocator, block_addresses);
    defer module.deinit();
    try module.verify();
    const original = module.globals.items[0].initializer.@"opaque";
    const output = try printed(std.testing.allocator, module, false);
    defer std.testing.allocator.free(output);
    try contains(output, "[ptr blockaddress(@\"first fn\", %1), ptr blockaddress(@other, %4), ptr blockaddress(@\"first fn\", %2)]");
    try contains(output, "!0 = !{!\"blockaddress(@other, %4)\"}");
    try contains(output, "!blockaddress = !{!0}");
    try std.testing.expectEqualStrings(original, module.globals.items[0].initializer.@"opaque");
    try std.testing.expectEqualStrings("4", module.functions.items[0].blocks.items[1].name);
    try verifyPrinted(output);
    var reparsed = try ir.Module.parse(std.testing.allocator, output);
    defer reparsed.deinit();
    const again = try printed(std.testing.allocator, reparsed, false);
    defer std.testing.allocator.free(again);
    try std.testing.expectEqualStrings(output, again);
    const canonical = try printed(std.testing.allocator, module, true);
    defer std.testing.allocator.free(canonical);
    try contains(canonical, "ptr blockaddress(@other, %1)");
    try verifyPrinted(canonical);
}

test "numeric serialization rewrites block addresses inside structured values and raw records" {
    var module = try ir.Module.parse(std.testing.allocator, block_addresses ++ "\n" ++
        \\declare void @consume(ptr)
        \\define ptr @use() {
        \\entry:
        \\  call void @consume(ptr null)
        \\  ret ptr null
        \\}
    );
    defer module.deinit();
    const raw = "blockaddress( @\"first fn\", %4 )";
    module.globals.items[0].initializer = .{ .array = .{ .elem_ty = .ptr, .values = .empty } };
    try module.globals.items[0].initializer.array.values.appendSlice(std.testing.allocator, &.{ .{ .constant_expr = raw }, .null_value, .{ .constant_expr = raw } });
    var function = &module.functions.items[2];
    function.attrs = "prefix ptr blockaddress(@\"first fn\", %4)";
    function.blocks.items[0].instructions.items[0].kind.call.raw_args = "ptr blockaddress(@\"first fn\", %4)";
    function.blocks.items[0].instructions.items[0].metadata = "!annotation !{ptr blockaddress(@\"first fn\", %4)}";
    function.blocks.items[0].terminator.?.ret.value = .{ .constant_expr = raw };
    try module.metadata.append(std.testing.allocator, "!1 = !{ptr blockaddress(@\"first fn\", %4)}");
    const output = try printed(std.testing.allocator, module, false);
    defer std.testing.allocator.free(output);
    try contains(output, "[ptr blockaddress( @\"first fn\", %1 ), ptr null, ptr blockaddress( @\"first fn\", %1 )]");
    try contains(output, "prefix ptr blockaddress(@\"first fn\", %1)");
    try contains(output, "call void @consume(ptr blockaddress(@\"first fn\", %1)), !annotation !{ptr blockaddress(@\"first fn\", %1)}");
    try contains(output, "ret ptr blockaddress( @\"first fn\", %1 )");
    try contains(output, "!1 = !{ptr blockaddress(@\"first fn\", %1)}");
    try std.testing.expectEqualStrings(raw, function.blocks.items[0].terminator.?.ret.value.?.constant_expr);
}

test "numeric serialization rejects malformed and unresolved block addresses before output" {
    var module = try ir.Module.parse(std.testing.allocator, block_addresses);
    defer module.deinit();
    for ([_][]const u8{
        "blockaddress(@missing, %4)",
        "blockaddress(@other, %999)",
        "blockaddress(@other %4)",
        "blockaddress(@other, %4",
        "blockaddress(@other, %4 extra)",
        "blockaddress(@\"unterminated, %4)",
        "ptrtoint (ptr %4 to i64)",
    }) |raw| {
        module.globals.items[0].initializer = .{ .@"opaque" = raw };
        var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
        defer output.deinit();
        try std.testing.expectError(error.UnsupportedNumericLocalReference, module.print(&output.writer));
        try std.testing.expectEqual(@as(usize, 0), output.written().len);
    }
}

fn allocationCheck(allocator: std.mem.Allocator, module: ir.Module, first_result: ?[]const u8) !void {
    var borrowed = module;
    borrowed.allocator = allocator;
    // Allocating writer maps allocation failure to WriteFailed; restore the
    // allocator-test contract without hiding either failure in production.
    const output = printed(allocator, borrowed, false) catch |err| switch (err) {
        error.WriteFailed => return error.OutOfMemory,
        else => return err,
    };
    defer allocator.free(output);
    if (first_result) |expected| try std.testing.expectEqualStrings(expected, module.functions.items[0].blocks.items[0].instructions.items[0].result.?);
}

test "numeric serialization cleans up every print allocation failure" {
    var module = try ir.Module.parse(std.testing.allocator, reordered);
    defer module.deinit();
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocationCheck, .{ module, @as(?[]const u8, "2") });
    var blocks = try ir.Module.parse(std.testing.allocator, block_addresses);
    defer blocks.deinit();
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocationCheck, .{ blocks, @as(?[]const u8, null) });
}
