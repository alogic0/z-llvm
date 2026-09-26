const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const pipelines = @import("../pipelines.zig");

fn optimize(source: []const u8, passes: []const u8) !ir.Module {
    var module = try ir.Module.parse(std.testing.allocator, source);
    errdefer module.deinit();
    try module.verify();
    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, passes);
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer output.deinit();
    _ = try pm.run(&module, &context, &output.writer, false);
    try module.verify();
    return module;
}

test "review boundaries: signed minmax uses the declared integer width" {
    for ([_][]const u8{ "instcombine", "sccp", "release-o3" }) |passes| {
        for ([_]u16{ 1, 8, 16, 64, 127, 128 }) |bits| {
            const negative: i128 = if (bits == 128) -1 else @intCast((@as(u128, 1) << @intCast(bits)) - 1);
            for ([_][]const u8{ "smin", "smax" }, [_]i128{ -1, 0 }) |op, expected| {
                const source = try std.fmt.allocPrint(std.testing.allocator, "declare i{d} @llvm.{s}.i{d}(i{d}, i{d})\ndefine i{d} @f() {{\nentry:\n %r = call i{d} @llvm.{s}.i{d}(i{d} {d}, i{d} 0)\n ret i{d} %r\n}}\n", .{ bits, op, bits, bits, bits, bits, bits, op, bits, bits, negative, bits, bits });
                defer std.testing.allocator.free(source);
                var module = try optimize(source, passes);
                defer module.deinit();
                const result = module.functions.items[0].blocks.items[0].terminator.?.ret.value.?;
                try std.testing.expect(result == .int);
                const integer = @import("../analysis/integer_semantics.zig").Integer.initBits(bits).?;
                try std.testing.expectEqual(expected, integer.normalize(result.int));
            }
        }
    }
}

test "review boundaries: wide unsigned division folds without signed host overflow" {
    var module = try optimize(
        \\define i127 @f() {
        \\entry:
        \\ %r = udiv i127 -1, 2
        \\ ret i127 %r
        \\}
    , "instcombine");
    defer module.deinit();
    try std.testing.expectEqual(@as(i128, (1 << 126) - 1), module.functions.items[0].blocks.items[0].terminator.?.ret.value.?.int);
}

test "review boundaries: allocation counts keep their live definitions" {
    for ([_][]const u8{ "dce", "instcombine,dce", "release-o3" }) |passes| {
        var module = try optimize(
            \\declare void @consume(ptr)
            \\define void @f(i64 %n) {
            \\entry:
            \\ %count = add i64 %n, 1
            \\ %unused = add i64 %n, 9
            \\ %buf = alloca i8, i64 %count, align 1
            \\ call void @consume(ptr %buf)
            \\ ret void
            \\}
        , passes);
        defer module.deinit();
        var count_live = false;
        var unused_live = false;
        for (module.functions.items[0].blocks.items) |block| {
            for (block.instructions.items) |inst| {
                if (inst.removed) continue;
                if (inst.result) |name| {
                    if (std.mem.eql(u8, name, "count")) count_live = true;
                    if (std.mem.eql(u8, name, "unused")) unused_live = true;
                }
            }
        }
        try std.testing.expect(count_live);
        try std.testing.expect(!unused_live);
    }
}

test "review boundaries: unsigned folding covers widths spellings and exactness" {
    const simplify = @import("../passes/inst_simplify.zig").simplify;
    const Integer = @import("../analysis/integer_semantics.zig").Integer;
    for ([_]u16{ 1, 8, 64, 127, 128 }) |bits| {
        const integer = Integer.initBits(bits).?;
        for ([_]i128{ -1, 0, 1, std.math.minInt(i128), std.math.maxInt(i128) }) |lhs| {
            for ([_]i128{ 1, 2, -1 }) |rhs| {
                const a = integer.unsigned(lhs);
                const b = integer.unsigned(rhs);
                if (b == 0) continue;
                for ([_]ir.BinaryOp{ .udiv, .urem }) |op| {
                    const result = simplify(.{ .result = "r", .kind = .{ .binary = .{
                        .op = op,
                        .ty = .{ .int = bits },
                        .lhs = .{ .int = lhs },
                        .rhs = .{ .int = rhs },
                    } } }).?;
                    try std.testing.expectEqual(if (op == .udiv) a / b else a % b, integer.unsigned(result.int));
                }
            }
        }
    }
    for ([_]u16{ 127, 128 }) |bits| {
        for ([_]i128{ 0, 2 }) |rhs| {
            const result = simplify(.{ .result = "r", .kind = .{ .binary = .{
                .op = .udiv,
                .ty = .{ .int = bits },
                .lhs = .{ .int = -1 },
                .rhs = .{ .int = rhs },
                .flags = .{ .exact = true },
            } } });
            try std.testing.expect(result == null);
        }
    }
}

test "review boundaries: alloca counts participate in replacement and round trips" {
    const Case = struct { passes: []const u8, producer: []const u8, expected: ir.Value };
    for ([_]Case{
        .{ .passes = "instcombine", .producer = "%count = add i64 %n, 0", .expected = .{ .named = "n" } },
        .{ .passes = "sccp", .producer = "%count = add i64 3, 4", .expected = .{ .int = 7 } },
        .{ .passes = "gvn", .producer = "%first = add i64 %n, 1\n %count = add i64 %n, 1", .expected = .{ .named = "first" } },
        .{ .passes = "mem2reg", .producer = "%slot = alloca i64\n store i64 %n, ptr %slot\n %count = load i64, ptr %slot", .expected = .{ .named = "n" } },
        .{ .passes = "simplifycfg", .producer = "br label %next\nnext:\n %count = phi i64 [ %n, %entry ]", .expected = .{ .named = "n" } },
    }) |case| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "declare void @consume(ptr)\ndefine void @f(i64 %n) {{\nentry:\n {s}\n %buf = alloca i8, i64 %count, align 16\n call void @consume(ptr %buf)\n ret void\n}}\n", .{case.producer});
        defer std.testing.allocator.free(source);
        var module = try optimize(source, case.passes);
        defer module.deinit();
        var found = false;
        for (module.functions.items[0].blocks.items) |block| for (block.instructions.items) |inst| {
            if (!inst.removed and inst.kind == .alloca and inst.kind.alloca.count != null) {
                try std.testing.expect(inst.kind.alloca.count.?.value.eql(case.expected));
                found = true;
            }
        };
        try std.testing.expect(found);
        var output = std.Io.Writer.Allocating.init(std.testing.allocator);
        defer output.deinit();
        try module.print(&output.writer);
        var reparsed = try ir.Module.parse(std.testing.allocator, output.written());
        defer reparsed.deinit();
        try reparsed.verify();
    }
}

test "review boundaries: verifier rejects undefined and mistyped alloca counts" {
    for ([_][]const u8{ "%missing", "%p" }) |value| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define void @f(ptr %p) {{\nentry:\n %buf = alloca i8, i64 {s}\n ret void\n}}\n", .{value});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        if (std.mem.eql(u8, value, "%missing")) {
            try std.testing.expectError(error.UnknownValue, module.verify());
        } else {
            try std.testing.expectError(error.TypeMismatch, module.verify());
        }
    }
    try std.testing.expectError(error.InvalidAllocaCount, ir.Module.parse(std.testing.allocator, "define void @f(ptr %p) {\nentry:\n %buf = alloca i8, ptr %p\n ret void\n}\n"));
}

test "review boundaries: multi-element allocations stay outside single-object lowering" {
    const codegen = @import("../codegen/x86_64.zig");
    for ([_][]const u8{ "%n", "0", "2" }) |count| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define i32 @f(i64 %n) {{\nentry:\n %buf = alloca i32, i64 {s}\n store i32 7, ptr %buf\n %v = load i32, ptr %buf\n ret i32 %v\n}}\n", .{count});
        defer std.testing.allocator.free(source);
        var module = try optimize(source, "mem2reg,sroa");
        defer module.deinit();
        try std.testing.expect(!module.functions.items[0].blocks.items[0].instructions.items[0].removed);
        try std.testing.expectError(error.UnsupportedAllocaCount, codegen.lowerFunction(std.testing.allocator, "x86_64-linux", module.functions.items[0]));
    }
}

test "review boundaries: loop allocation counts remain dominated" {
    for ([_][]const u8{ "licm", "loop-simplifycfg", "indvars", "release-o3" }) |passes| {
        var module = try optimize(
            \\declare void @consume(ptr)
            \\define i64 @f(i64 %n) {
            \\entry:
            \\ br label %loop
            \\loop:
            \\ %i = phi i64 [ 0, %entry ], [ %next, %loop ]
            \\ %next = add i64 %i, 1
            \\ %buf = alloca i8, i64 %next
            \\ call void @consume(ptr %buf)
            \\ %done = icmp eq i64 %next, %n
            \\ br i1 %done, label %exit, label %loop
            \\exit:
            \\ %out = alloca i8, i64 %next
            \\ call void @consume(ptr %out)
            \\ ret i64 %next
            \\}
        , passes);
        defer module.deinit();
        // Exercise the standalone LCSSA helper as well as pass-local use walks.
        if (std.mem.eql(u8, passes, "licm")) {
            const cfg = @import("../analysis/cfg.zig");
            const loop_info = @import("../analysis/loop_info.zig");
            var graph = try cfg.Graph.build(std.testing.allocator, module.functions.items[0]);
            defer graph.deinit();
            var loops = try loop_info.LoopInfo.build(std.testing.allocator, module.functions.items[0]);
            defer loops.deinit();
            try std.testing.expect(try loop_info.formSimpleLcssa(&module, 0, loops.loops.items[0], graph));
            try std.testing.expect(try loops.loops.items[0].hasLcssaForm(std.testing.allocator, module.functions.items[0], graph));
        }
        try module.verify();
    }
}

test "review boundaries: explicit singleton and alignment-only allocas still work" {
    for ([_][]const u8{ "", ", align\t8", ", i64 1, align 8" }) |suffix| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define i32 @f() {{\nentry:\n %buf = alloca i32{s}\n store i32 7, ptr %buf\n %v = load i32, ptr %buf\n ret i32 %v\n}}\n", .{suffix});
        defer std.testing.allocator.free(source);
        var module = try optimize(source, "mem2reg");
        defer module.deinit();
        try std.testing.expect(module.functions.items[0].blocks.items[0].terminator.?.ret.value.?.eql(.{ .int = 7 }));
    }
}
