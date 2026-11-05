const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

fn executable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("pointer flow {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const code = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}

const pointer_values = @import("pointer_values.zig");
const pair_values = @import("word_pair_values.zig");
const Pair = extern struct { first: u64, second: u64 };

test "pointer flow returns two word PHIs with all integer pointer field combinations" {
    for ([_][2][]const u8{ .{ "ptr", "i64" }, .{ "i64", "ptr" }, .{ "ptr", "ptr" }, .{ "i64", "i64" } }) |types| {
        const ty = try std.fmt.allocPrint(std.testing.allocator, "{{ {s}, {s} }}", .{ types[0], types[1] });
        defer std.testing.allocator.free(ty);
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define {s} @choose(i64 %a, i64 %b, i64 %choice) {{
            \\entry:
            \\  %pa = inttoptr i64 %a to ptr
            \\  %pb = inttoptr i64 %b to ptr
            \\  %c = trunc i64 %choice to i1
            \\  %v0 = insertvalue {s} poison, {s} {s}, 0
            \\  %v = insertvalue {s} %v0, {s} {s}, 1
            \\  br i1 %c, label %yes, label %no
            \\merge:
            \\  %r = phi {s} [ %v, %yes ], [ zeroinitializer, %no ]
            \\  ret {s} %r
            \\yes:
            \\  br label %merge
            \\no:
            \\  br label %merge
            \\}}
        , .{ ty, ty, types[0], if (std.mem.eql(u8, types[0], "ptr")) "%pa" else "%a", ty, types[1], if (std.mem.eql(u8, types[1], "ptr")) "%pb" else "%b", ty, ty });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u64, u64, u64) callconv(.c) Pair = @ptrCast(code.ptr);
        const inputs = [_]u64{ 0, 1, 255, 0x8000000000000000, 0xdeadbeef01234567, std.math.maxInt(u64) };
        for (inputs) |a| for (inputs) |b| for ([_]u64{ 0, 1, 0xffffffffffffffff, 0xfffffffffffffffe }) |choice| {
            const result = run(a, b, choice);
            try std.testing.expectEqual(if (choice & 1 != 0) a else 0, result.first);
            try std.testing.expectEqual(if (choice & 1 != 0) b else 0, result.second);
        };
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try pair_values.legalize(arena.allocator(), module.functions.items[0], null)).?;
        try std.testing.expect(try pair_values.legalize(arena.allocator(), view, null) == null);
        try module.verify();
    }
}

test "pointer flow constants on PHI edges retain the original SSA and avoid name collisions" {
    const text =
        \\define i64 @choose(i64 %__zllvm_scalar_form_0) {
        \\entry:
        \\  %c = trunc i64 %__zllvm_scalar_form_0 to i1
        \\  br i1 %c, label %yes, label %no
        \\merge:
        \\  %p = phi ptr [ inttoptr (i64 -1 to ptr), %yes ], [ null, %no ]
        \\  %r = ptrtoint ptr %p to i64
        \\  ret i64 %r
        \\yes:
        \\  br label %merge
        \\no:
        \\  br label %merge
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u64{ 0, 1, 2, 3, std.math.maxInt(u64) }) |choice|
        try std.testing.expectEqual(if (choice & 1 != 0) std.math.maxInt(u64) else @as(u64, 0), run(choice));
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try pointer_values.legalize(arena.allocator(), module.functions.items[0], null)).?;
    try std.testing.expect(try pointer_values.legalize(arena.allocator(), view, null) == null);
    const original_phi = module.functions.items[0].blocks.items[1].instructions.items[0].kind.phi;
    try std.testing.expect(original_phi.incoming.items[0].value == .constant_expr);
    try std.testing.expect(original_phi.incoming.items[1].value == .null_value);
    try module.verify();
}

test "pointer flow rejects incompatible pointer layouts and flagged casts" {
    const text = "define i64 @f() {\nentry:\n  %r = ptrtoint ptr null to i64\n  ret i64 %r\n}\n";
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    for ([_][]const u8{ "E-p:64:64", "e-p:32:32", "e-ni:0", "e-p:64:64:64:32" }) |layout| {
        var context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = layout };
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try pointer_values.legalize(arena.allocator(), module.functions.items[0], &context) == null);
    }
    module.functions.items[0].blocks.items[0].instructions.items[0].kind.cast.flags.nneg = true;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect(try pointer_values.legalize(arena.allocator(), module.functions.items[0], null) == null);
}

test "pointer flow boolean truncations branch on bit zero and preserve live input bits" {
    for ([_]u16{ 8, 16, 32, 64, 128 }) |bits| {
        const conversion = if (bits == 64) try std.testing.allocator.dupe(u8, "") else
            try std.fmt.allocPrint(std.testing.allocator, "  %source = {s} i64 %input to i{d}\n", .{ if (bits < 64) "trunc" else "zext", bits });
        defer std.testing.allocator.free(conversion);
        const text = try std.fmt.allocPrint(std.testing.allocator,
            "define i64 @choose(i64 %input, i64 %live) {{\nentry:\n{s}  %condition = trunc i{d} {s} to i1\n  br i1 %condition, label %yes, label %no\nyes:\n  ret i64 %input\nno:\n  ret i64 %live\n}}\n",
            .{ conversion, bits, if (bits == 64) "%input" else "%source" });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const memory = try executable(module);
        defer std.posix.munmap(memory);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        for ([_]u64{ 0, 1, 2, 3, 128, 255, 256, 257, 0x8000000000000000, 0xfffffffffffffffe, std.math.maxInt(u64) }) |input|
            try std.testing.expectEqual(if (input & 1 != 0) input else @as(u64, 42), run(input, 42));
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try @import("boolean_values.zig").legalize(arena.allocator(), module.functions.items[0])).?;
        try std.testing.expect(try @import("boolean_values.zig").legalize(arena.allocator(), view) == null);
        try module.verify();
    }
}

test "pointer flow byte boolean loads ignore dirty upper bits and reject volatile access" {
    for ([_][]const u8{ "", "volatile " }) |qualifier| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            "define i64 @choose(ptr %p, i64 %live) {{\nentry:\n  %condition = load {s}i1, ptr %p, align 1\n  %r = select i1 %condition, i64 %live, i64 42\n  ret i64 %r\n}}\n", .{qualifier});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        if (qualifier.len != 0) {
            var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer arena.deinit();
            try std.testing.expect(try @import("boolean_values.zig").legalize(arena.allocator(), module.functions.items[0]) == null);
            var output = machine.MachineFunction.init("choose", .{ .int = 64 });
            defer output.deinit(std.testing.allocator);
            const selected = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
            try std.testing.expect(selected == .unsupported);
            continue;
        }
        const memory = try executable(module);
        defer std.posix.munmap(memory);
        const run: *const fn (*const u8, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        for (0..256) |bits| {
            const input: u8 = @intCast(bits);
            try std.testing.expectEqual(if (input & 1 != 0) @as(u64, 0xdeadbeef01234567) else 42, run(&input, 0xdeadbeef01234567));
        }
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try @import("boolean_values.zig").legalize(arena.allocator(), module.functions.items[0])).?;
        try std.testing.expectEqual(module.functions.items[0].blocks.items[0].instructions.items[0].kind.load.attrs, view.blocks.items[0].instructions.items[0].kind.load.attrs);
    }
}

test "pointer flow constant boolean truncations preserve only their low bit" {
    for ([_]i64{ 0, 1, 2, 3, -1, -2, std.math.minInt(i64) }) |input| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            "define i64 @choose() {{\nentry:\n  %condition = trunc i64 {d} to i1\n  %r = select i1 %condition, i64 7, i64 42\n  ret i64 %r\n}}\n", .{input});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const memory = try executable(module);
        defer std.posix.munmap(memory);
        const run: *const fn () callconv(.c) u64 = @ptrCast(memory.ptr);
        try std.testing.expectEqual(if (input & 1 != 0) @as(u64, 7) else 42, run());
    }
}
