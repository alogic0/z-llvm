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

test "symbolic volatile scalar loads keep one exact memory event after pointer normalization" {
    const a = std.testing.allocator;
    for ([_][]const u8{ "i8", "i16", "i32", "i64", "ptr" }, [_]usize{ 8, 16, 32, 64, 64 }) |ty, bits| {
        const pointer = if (std.mem.eql(u8, ty, "ptr")) "getelementptr (i8,ptr @\"volatile cell\",i64 8)" else "@\"volatile cell\"";
        const conversion = if (std.mem.eql(u8, ty, "ptr")) " %wide = ptrtoint ptr %value to i64\n" else if (bits < 64) try std.fmt.allocPrint(a, " %wide = zext {s} %value to i64\n", .{ty}) else " %wide = add i64 %value,0\n";
        defer if (bits < 64) a.free(conversion);
        const text = try std.fmt.allocPrint(a, "@\"volatile cell\" = global [16 x i8] zeroinitializer,align 16\ndefine i64 @read() {{\nentry:\n %value = load volatile {s},ptr {s},align 1\n{s} ret i64 %wide\n}}\n", .{ ty, pointer, conversion });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        const source = module.functions.items[0];
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout, .functions = module.functions.items };
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const view = (try pointer_values.legalize(arena.allocator(), source, &context)).?;
        var loads: usize = 0;
        for (view.blocks.items) |block| for (block.instructions.items) |inst| {
            if (inst.kind != .load) continue;
            loads += 1;
            try std.testing.expect(inst.kind.load.ptr == .named);
            try std.testing.expect(inst.kind.load.attrs.is_volatile);
            try std.testing.expect(!inst.kind.load.attrs.isAtomic());
            try std.testing.expectEqual(@as(?u64, 1), inst.kind.load.attrs.@"align");
        };
        try std.testing.expectEqual(@as(usize, 1), loads);
        var selected = try @import("../../../compilation.zig").select(a, "x86_64-unknown-linux-gnu", source, .{ .generic_cfg_selector = true, .module_context = &context });
        defer selected.deinit(a);
        try verify.verifyFunction(selected);
        try std.testing.expect(source.blocks.items[0].instructions.items[0].kind.load.attrs.is_volatile);
        try module.verify();
    }
}

test "symbolic volatile pointer views keep atomic scoped wide and nonnative layouts closed" {
    const a = std.testing.allocator;
    for (0..6) |variant| {
        var module = try ir.Module.parse(a,
            \\@cell = global [32 x i8] zeroinitializer,align 16
            \\define void @closed() {
            \\entry:
            \\ %value = load volatile i32,ptr @cell,align 4
            \\ ret void
            \\}
        );
        defer module.deinit();
        try module.verify();
        const load = &module.functions.items[0].blocks.items[0].instructions.items[0].kind.load;
        var context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
        switch (variant) {
            0 => load.attrs.atomic_ordering = "acquire",
            1 => load.attrs.syncscope = "syncscope(\"singlethread\")",
            2 => load.ty = .{ .int = 128 },
            3 => load.ty = .{ .vector = .{ .len = 4, .elem_ty = .{ .int = 32 } } },
            4 => load.ptr_addrspace = "addrspace(1)",
            5 => context.target_datalayout = "e-p:32:32",
            else => unreachable,
        }
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        try std.testing.expect((try pointer_values.legalize(arena.allocator(), module.functions.items[0], &context)) == null);
    }
}

test "absolute volatile native pointers retain event types and exact memory extents" {
    for ([_][]const u8{ "i8", "i16", "i32", "i64", "ptr" }, [_]usize{ 1, 2, 4, 8, 8 }) |ty, bytes| {
        var storage: [32]u8 = @splat(165);
        const address = @intFromPtr(&storage[9]);
        const load_cast = if (bytes == 8 and std.mem.eql(u8, ty, "ptr")) "ptrtoint ptr" else if (bytes < 8) try std.fmt.allocPrint(std.testing.allocator, "zext {s}", .{ty}) else "add i64";
        defer if (bytes < 8) std.testing.allocator.free(load_cast);
        const input = if (std.mem.eql(u8, ty, "ptr")) " %small = inttoptr i64 %value to ptr\n" else if (bytes < 8) try std.fmt.allocPrint(std.testing.allocator, " %small = trunc i64 %value to {s}\n", .{ty}) else " %small = add i64 %value,0\n";
        defer if (bytes < 8 and !std.mem.eql(u8, ty, "ptr")) std.testing.allocator.free(input);
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @absolute(i64 %value,i64 %salt) {{\nentry:\n{s} %before = load volatile {s},ptr inttoptr (i64 {d} to ptr),align 1\n store volatile {s} %small,ptr inttoptr (i64 {d} to ptr),align 1\n %after = load volatile {s},ptr inttoptr (i64 {d} to ptr),align 1\n %a = {s} %before{s}\n %b = {s} %after{s}\n %pair = xor i64 %a,%b\n %r = xor i64 %pair,%salt\n ret i64 %r\n}}\n", .{ input, ty, address, ty, address, ty, address, load_cast, if (std.mem.eql(u8, ty, "ptr") or bytes < 8) " to i64" else ",0", load_cast, if (std.mem.eql(u8, ty, "ptr") or bytes < 8) " to i64" else ",0" });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try pointer_values.legalize(arena.allocator(), original, null)).?;
        try std.testing.expect((try pointer_values.legalize(arena.allocator(), view, null)) == null);
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = view;
        try private.verify();
        var loads: usize = 0;
        var stores: usize = 0;
        for (view.blocks.items[0].instructions.items) |inst| switch (inst.kind) {
            .load => |x| {
                try std.testing.expect(x.attrs.is_volatile and x.ptr == .named);
                loads += 1;
            },
            .store => |x| {
                try std.testing.expect(x.attrs.is_volatile and x.ptr == .named);
                stores += 1;
            },
            else => {},
        };
        try std.testing.expectEqual(@as(usize, 2), loads);
        try std.testing.expectEqual(@as(usize, 1), stores);
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        for (0..64) |seed| {
            @memset(&storage, 165);
            const before: u64 = 0x1928374655aa80ff;
            const after = @as(u64, seed) *% 0x8123456789abcdef;
            @memcpy(storage[9..][0..bytes], std.mem.asBytes(&before)[0..bytes]);
            const salt: u64 = 0xf06dea67e461de5b;
            const mask: u64 = if (bytes == 8) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(bytes * 8))) - 1;
            try std.testing.expectEqual(((before ^ after) & mask) ^ salt, run(after, salt));
            try std.testing.expectEqualSlices(u8, std.mem.asBytes(&after)[0..bytes], storage[9..][0..bytes]);
            for (storage[0..9]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
            for (storage[9 + bytes ..]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
        }
        try module.verify();
    }
}

test "absolute volatile address normalization keeps atomics address spaces and vector widths closed" {
    for ([_][]const u8{
        "define i32 @closed() {\nentry:\n %r = load atomic volatile i32,ptr inttoptr (i64 4096 to ptr) monotonic,align 4\n ret i32 %r\n}\n",
        "define i8 @closed() {\nentry:\n %r = load volatile i8,ptr addrspace(1) inttoptr (i64 4096 to ptr addrspace(1)),align 1\n ret i8 %r\n}\n",
        "define <2 x i64> @closed() {\nentry:\n %r = load volatile <2 x i64>,ptr inttoptr (i64 4096 to ptr),align 1\n ret <2 x i64> %r\n}\n",
    }) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try pointer_values.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
}

test "integer symbolic operands retain source identities and closed layout boundaries" {
    const text =
        \\@table = internal global [64 x i8] zeroinitializer, align 16
        \\define i64 @choose(i64 %__zllvm_scalar_form_0) {
        \\entry:
        \\ %left = sub i64 ptrtoint (ptr getelementptr (i8, ptr @table, i64 17) to i64), %__zllvm_scalar_form_0
        \\ %right = sub i64 %left, ptrtoint (ptr @table to i64)
        \\ ret i64 %right
        \\}
        \\define i32 @narrow() {
        \\entry:
        \\ %result = sub i32 ptrtoint (ptr @table to i32), 1
        \\ ret i32 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const original = module.functions.items[0];
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = &.{}, .target_datalayout = module.target_datalayout };
    const view = (try pointer_values.legalize(arena.allocator(), original, &context)) orelse return error.TestExpectedRewrite;
    try std.testing.expect(try pointer_values.legalize(arena.allocator(), view, &context) == null);
    try std.testing.expect(try pointer_values.legalize(arena.allocator(), module.functions.items[1], &context) == null);
    try std.testing.expectEqual(@as(usize, 2), original.blocks.items[0].instructions.items.len);
    try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.binary.lhs == .constant_expr);
    try std.testing.expect(original.blocks.items[0].instructions.items[1].kind.binary.rhs == .constant_expr);
    {
        module.functions.items[0] = view;
        defer module.functions.items[0] = original;
        try module.verify();
    }
    for ([_][]const u8{ "E-p:64:64", "e-p:32:32", "e-ni:0", "e-p:64:64:64:32" }) |layout| {
        context.target_datalayout = layout;
        try std.testing.expect(try pointer_values.legalize(arena.allocator(), original, &context) == null);
    }
    try module.verify();
}

test "pointer frontier keeps independent frame address selection beside a dynamic copy" {
    const text =
        \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
        \\define i64 @choose(ptr %external, i64 %value, i1 %take_local, i64 %length, i64 %seed) {
        \\entry:
        \\ %slot = alloca i32, align 4
        \\ %other = alloca [3 x i32], align 4
        \\ %small = trunc i64 %value to i32
        \\ store i32 %small, ptr %slot, align 4
        \\ store i32 %small, ptr %other, align 4
        \\ call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
        \\ %p = select i1 %take_local, ptr %slot, ptr %external
        \\ %read = load i32, ptr %p, align 4
        \\ %wide = zext i32 %read to i64
        \\ %r = xor i64 %wide, %seed
        \\ ret i64 %r
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (*u32, u64, bool, u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u64{ 0, 0x0123456789abcdef, std.math.maxInt(u64) }) |value| {
        const small: u32 = @truncate(value);
        const seed: u64 = 0xa55aa55a12345678;
        for (0..5) |length| for ([_]bool{ false, true }) |take_local| {
            var external = [_]u32{ 0x19283746, small ^ 0x80000001, 0xabcdef12 };
            var expected = external;
            @memcpy(std.mem.asBytes(&expected[1])[0..length], std.mem.asBytes(&small)[0..length]);
            const result = run(&external[1], value, take_local, length, seed);
            try std.testing.expectEqual(@as(u64, if (take_local) small else expected[1]) ^ seed, result);
            try std.testing.expectEqualSlices(u32, &expected, &external);
        };
    }
}

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
        const conversion = if (bits == 64) try std.testing.allocator.dupe(u8, "") else try std.fmt.allocPrint(std.testing.allocator, "  %source = {s} i64 %input to i{d}\n", .{ if (bits < 64) "trunc" else "zext", bits });
        defer std.testing.allocator.free(conversion);
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @choose(i64 %input, i64 %live) {{\nentry:\n{s}  %condition = trunc i{d} {s} to i1\n  br i1 %condition, label %yes, label %no\nyes:\n  ret i64 %input\nno:\n  ret i64 %live\n}}\n", .{ conversion, bits, if (bits == 64) "%input" else "%source" });
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
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @choose(ptr %p, i64 %live) {{\nentry:\n  %condition = load {s}i1, ptr %p, align 1\n  %r = select i1 %condition, i64 %live, i64 42\n  ret i64 %r\n}}\n", .{qualifier});
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
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @choose() {{\nentry:\n  %condition = trunc i64 {d} to i1\n  %r = select i1 %condition, i64 7, i64 42\n  ret i64 %r\n}}\n", .{input});
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
