const std = @import("std");
const ir = @import("../ir.zig");
const pm = @import("../pass_manager.zig");
const instcombine = @import("../passes/instcombine.zig");
const pipelines = @import("../pipelines.zig");

fn combine(module: *ir.Module) !pm.PassResult {
    var context: pm.Context = .{ .allocator = std.testing.allocator };
    return instcombine.pass.run(module, &context);
}

fn liveBinaries(function: ir.Function) usize {
    var count: usize = 0;
    for (function.blocks.items) |block| for (block.instructions.items) |instruction| {
        if (!instruction.removed and instruction.kind == .binary) count += 1;
    };
    return count;
}

test "floating cancellation requires promises on both operations and preserves strict rounding" {
    const flags = [_]struct { first: []const u8, second: []const u8, folded: bool }{
        .{ .first = "fast", .second = "fast", .folded = true },
        .{ .first = "reassoc nnan ninf nsz", .second = "reassoc nnan ninf nsz", .folded = true },
        .{ .first = "", .second = "", .folded = false },
        .{ .first = "fast", .second = "", .folded = false },
        .{ .first = "", .second = "fast", .folded = false },
        .{ .first = "nnan ninf nsz", .second = "fast", .folded = false },
        .{ .first = "fast", .second = "reassoc nnan ninf", .folded = false },
        .{ .first = "reassoc ninf nsz", .second = "fast", .folded = false },
        .{ .first = "fast", .second = "reassoc nnan nsz", .folded = false },
        .{ .first = "reassoc", .second = "reassoc", .folded = false },
        .{ .first = "nsz", .second = "nsz", .folded = false },
    };
    const shapes = [_]struct { first: []const u8, second: []const u8 }{
        .{ .first = "fadd {s} {s} %x,{s}", .second = "fsub {s} {s} %first,{s}" },
        .{ .first = "fadd {s} {s} {s},%x", .second = "fsub {s} {s} %first,{s}" },
        .{ .first = "fsub {s} {s} %x,{s}", .second = "fadd {s} {s} %first,{s}" },
        .{ .first = "fsub {s} {s} %x,{s}", .second = "fadd {s} {s} {s},%first" },
    };
    inline for (shapes) |shape| for (flags) |case| for ([_]struct { ty: []const u8, decimal: []const u8, hex: []const u8 }{
        .{ .ty = "double", .decimal = "1099511627776.0", .hex = "0x4270000000000000" },
        .{ .ty = "float", .decimal = "16777216.0", .hex = "0x4170000000000000" },
    }) |format| {
        const first = try std.fmt.allocPrint(std.testing.allocator, shape.first, .{ case.first, format.ty, format.decimal });
        defer std.testing.allocator.free(first);
        const second = try std.fmt.allocPrint(std.testing.allocator, shape.second, .{ case.second, format.ty, format.hex });
        defer std.testing.allocator.free(second);
        const text = try std.fmt.allocPrint(std.testing.allocator, "define {s} @cancel({s} %x) {{\nentry:\n %first = {s}\n %result = {s}\n ret {s} %result\n}}\n", .{ format.ty, format.ty, first, second, format.ty });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        _ = try combine(&module);
        try module.verify();
        try std.testing.expectEqual(@as(usize, if (case.folded) 0 else 2), liveBinaries(module.functions.items[0]));
        const result = module.functions.items[0].blocks.items[0].terminator.?.ret.value.?;
        try std.testing.expect(result == .named);
        try std.testing.expectEqualStrings(if (case.folded) "x" else "result", result.named);
        try std.testing.expectEqual(pm.PassResult.unchanged, try combine(&module));
    };
}

test "floating cancellation rejects nonfinite unequal unknown and cross block operands" {
    for ([_]struct { first: []const u8, second: []const u8, gap: []const u8 = "" }{
        .{ .first = "1.0", .second = "2.0" },
        .{ .first = "0x7FF0000000000000", .second = "0x7FF0000000000000" },
        .{ .first = "0xFFF0000000000000", .second = "0xFFF0000000000000" },
        .{ .first = "0x7FF8000000000000", .second = "0x7FF8000000000000" },
        .{ .first = "%other", .second = "%other" },
        .{ .first = "1.0", .second = "1.0", .gap = "br label %next\nnext:" },
    }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define double @boundary(double %x,double %other) {{\nentry:\n %first = fadd fast double %x,{s}\n {s}\n %result = fsub fast double %first,{s}\n ret double %result\n}}\n", .{ case.first, case.gap, case.second });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        _ = try combine(&module);
        try module.verify();
        try std.testing.expectEqual(@as(usize, 2), liveBinaries(module.functions.items[0]));
    }
}

test "floating cancellation retains a shared producer and rewrites later block uses" {
    const text =
        \\define double @shared(double %x,ptr %p) {
        \\entry:
        \\ %first = fadd fast double %x,0x4270000000000000
        \\ store double %first,ptr %p
        \\ %result = fsub fast double %first,0x4270000000000000
        \\ br label %next
        \\next:
        \\ ret double %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    _ = try combine(&module);
    try module.verify();
    const function = module.functions.items[0];
    try std.testing.expectEqual(@as(usize, 1), liveBinaries(function));
    try std.testing.expectEqualStrings("first", function.blocks.items[0].instructions.items[1].kind.store.value.named);
    try std.testing.expectEqualStrings("x", function.blocks.items[1].terminator.?.ret.value.?.named);
    try std.testing.expectEqual(pm.PassResult.unchanged, try combine(&module));
}

test "floating cancellation in the release pipeline preserves observed SSA results and debug locations" {
    const observed =
        \\declare void @llvm.dbg.value(metadata, metadata, metadata)
        \\define double @observed(double %x) !dbg !4 {
        \\entry:
        \\  %intermediate = fadd fast double %x, 0x4270000000000000, !dbg !8
        \\  call void @llvm.dbg.value(metadata double %intermediate, metadata !9, metadata !DIExpression()), !dbg !8
        \\  %result = fsub fast double %intermediate, 0x4270000000000000, !dbg !11
        \\  call void @llvm.dbg.value(metadata double %result, metadata !12, metadata !DIExpression()), !dbg !11
        \\  ret double %result
        \\}
        \\
    ;
    const math_format =
        \\define double @math(double %x) {{
        \\entry:
        \\  %first = fadd {s} double %x, 0x4270000000000000
        \\  %second = fsub {s} double %first, {s}
        \\  ret double %second
        \\}}
        \\
    ;
    const unrelated =
        \\define i32 @unrelated(i32 %v) !dbg !13 {
        \\entry:
        \\  %identity = add i32 %v, 0
        \\  call void @llvm.dbg.value(metadata i32 %identity, metadata !15, metadata !DIExpression()), !dbg !14
        \\  ret i32 %identity
        \\}
        \\!llvm.dbg.cu = !{!0}
        \\!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug)
        \\!2 = !DIFile(filename: "debug_float.zig", directory: ".")
        \\!4 = distinct !DISubprogram(name: "observed", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
        \\!5 = !DISubroutineType(types: !6)
        \\!6 = !{}
        \\!8 = !DILocation(line: 2, column: 5, scope: !4)
        \\!9 = !DILocalVariable(name: "intermediate", scope: !4, file: !2, line: 2, type: !10)
        \\!10 = !DIBasicType(name: "f64", size: 64, encoding: DW_ATE_float)
        \\!11 = !DILocation(line: 3, column: 5, scope: !4)
        \\!12 = !DILocalVariable(name: "result", scope: !4, file: !2, line: 3, type: !10)
        \\!13 = distinct !DISubprogram(name: "unrelated", scope: !2, file: !2, line: 6, type: !5, scopeLine: 6, spFlags: DISPFlagDefinition, unit: !0)
        \\!14 = !DILocation(line: 7, column: 5, scope: !13)
        \\!15 = !DILocalVariable(name: "identity", scope: !13, file: !2, line: 7, type: !16)
        \\!16 = !DIBasicType(name: "i32", size: 32, encoding: DW_ATE_signed)
        \\
    ;
    for ([_]struct { first: []const u8, second: []const u8, constant: []const u8 = "0x4270000000000000", fold: bool = false }{
        .{ .first = "fast", .second = "fast", .fold = true },
        .{ .first = "reassoc nnan ninf nsz", .second = "reassoc nnan ninf nsz", .fold = true },
        .{ .first = "", .second = "" },
        .{ .first = "fast", .second = "reassoc nnan ninf" },
        .{ .first = "reassoc nnan nsz", .second = "fast" },
        .{ .first = "fast", .second = "fast", .constant = "0x4260000000000000" },
    }) |case| {
        const math = try std.fmt.allocPrint(std.testing.allocator, math_format, .{ case.first, case.second, case.constant });
        defer std.testing.allocator.free(math);
        const text = try std.mem.concat(std.testing.allocator, u8, &.{ observed, math, unrelated });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var manager = pm.ModulePassManager.init(std.testing.allocator);
        defer manager.deinit();
        try pipelines.addPasses(&manager, "zig-release-fast-accepted");
        var context: pm.Context = .{ .allocator = std.testing.allocator };
        var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
        defer output.deinit();
        try std.testing.expectEqual(pm.PassResult.changed, try manager.runWithOptions(&module, &context, &output.writer, .{}));
        try std.testing.expectEqual(@as(usize, 1), context.debug_variable_location_scan_count);
        for (module.functions.items) |function| {
            if (std.mem.eql(u8, function.name, "observed")) {
                const instructions = function.blocks.items[0].instructions.items;
                try std.testing.expectEqual(@as(usize, 4), instructions.len);
                try std.testing.expect(instructions[0].kind == .binary and instructions[2].kind == .select);
                try std.testing.expectEqualStrings("!dbg !8", instructions[0].metadata.?);
                try std.testing.expectEqualStrings("!dbg !11", instructions[2].metadata.?);
                try std.testing.expectEqualStrings("x", instructions[2].kind.select.true_value.named);
                try std.testing.expectEqualStrings("x", instructions[2].kind.select.false_value.named);
            } else if (std.mem.eql(u8, function.name, "math")) {
                try std.testing.expectEqual(@as(usize, if (case.fold) 1 else 2), liveBinaries(function));
                try std.testing.expectEqualStrings("second", function.blocks.items[0].terminator.?.ret.value.?.named);
            }
        }
        try module.print(&output.writer);
        for ([_][]const u8{
            "metadata double %intermediate, metadata !9, metadata !DIExpression()), !dbg !8",
            "metadata double %result, metadata !12, metadata !DIExpression()), !dbg !11",
            "ret double %result",
            "%identity = add i32 %v, 0",
            "metadata i32 %identity, metadata !15, metadata !DIExpression()), !dbg !14",
        }) |kept| try std.testing.expect(std.mem.indexOf(u8, output.writer.buffered(), kept) != null);
        try std.testing.expectEqual(pm.PassResult.unchanged, try manager.runWithOptions(&module, &context, &output.writer, .{}));
    }
}
