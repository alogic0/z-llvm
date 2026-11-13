const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("integer_vectors.zig");

test "pair vector saturation preserves aligned owned storage and exact lane results" {
    const a = std.testing.allocator;
    const samples = [_]u128{ 0, 1, 0xffffffffffffffff, 0x10000000000000000, 0x7fffffffffffffffffffffffffffffff, 0x80000000000000000000000000000000, std.math.maxInt(u128), 0x123456789abcdef0fedcba9876543210 };
    for ([_]u32{ 2, 3, 4, 8, 16, 32 }) |n| for ([_][]const u8{ "uadd.sat", "usub.sat", "sadd.sat", "ssub.sat", "umin", "umax", "smin", "smax" }, 0..) |op, kind| {
        const alignment = try std.math.ceilPowerOfTwo(u32, n * 16);
        const text = try std.fmt.allocPrint(a, "declare i128 @llvm.{0s}.i128(i128,i128)\ndeclare <{1d} x i128> @llvm.{0s}.v{1d}i128(<{1d} x i128>,<{1d} x i128>)\ndefine i64 @pair_vectors(ptr %out,ptr %ap,ptr %bp,i64 %salt) {{\nentry:\n %slot = alloca <{1d} x i128>,align {2d}\n %a = load <{1d} x i128>,ptr %ap,align 1\n %b = load <{1d} x i128>,ptr %bp,align 1\n store <{1d} x i128> %a,ptr %slot,align 1\n %again = load <{1d} x i128>,ptr %slot,align 1\n %r = call <{1d} x i128> @llvm.{0s}.v{1d}i128(<{1d} x i128> %again,<{1d} x i128> %b)\n store <{1d} x i128> %r,ptr %out,align 1\n %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ op, n, alignment });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const original = module.functions.items[0];
        const view = (try forms.legalize(arena.allocator(), original, null)).?;
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = view;
        try private.verify();
        try std.testing.expect((try forms.legalize(arena.allocator(), view, null)) == null);
        const machine = @import("../machine.zig");
        const selector = @import("../generic_cfg_selector.zig");
        var output = machine.MachineFunction.init("pair_vectors", .{ .int = 64 });
        defer output.deinit(a);
        const selected = try selector.tryLower(a, &output, original);
        if (selected == .unsupported) std.debug.print("pair vectors {d} {s}: {s}\n", .{ n, op, selected.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        try @import("../verify.zig").verifyFunction(output);
        const bytes = try @import("../../../mc/encoding.zig").encodeFunction(a, output);
        defer a.free(bytes);
        const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(code);
        @memcpy(code[0..bytes.len], bytes);
        const run: *const fn (*u8, *const u128, *const u128, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        for (0..samples.len) |seed| {
            var x: [32]u128 = undefined;
            var y: [32]u128 = undefined;
            for (0..n) |i| {
                x[i] = samples[(i + seed) % samples.len];
                y[i] = samples[(i * 3 + seed) % samples.len];
            }
            const before_x = x;
            const before_y = y;
            var guarded: [528]u8 = @splat(165);
            const salt: u64 = seed *% 0xf06dea67e461de5b;
            try std.testing.expectEqual(salt ^ 90, run(&guarded[8], &x[0], &y[0], salt));
            for (0..n) |i| {
                const sx: i128 = @bitCast(x[i]);
                const sy: i128 = @bitCast(y[i]);
                const expected: u128 = switch (kind) {
                    0 => x[i] +| y[i],
                    1 => x[i] -| y[i],
                    2 => @bitCast(sx +| sy),
                    3 => @bitCast(sx -| sy),
                    4 => @min(x[i], y[i]),
                    5 => @max(x[i], y[i]),
                    6 => @bitCast(@min(sx, sy)),
                    7 => @bitCast(@max(sx, sy)),
                    else => unreachable,
                };
                try std.testing.expectEqual(expected, std.mem.readInt(u128, guarded[8 + i * 16 ..][0..16], .little));
            }
            for (guarded[0..8]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
            for (guarded[8 + n * 16 ..]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
            try std.testing.expectEqualSlices(u128, before_x[0..n], x[0..n]);
            try std.testing.expectEqualSlices(u128, before_y[0..n], y[0..n]);
        }
        try module.verify();
    };
}

test "pair vector owned storage keeps larger dynamic and excessive alignment closed" {
    for ([_][]const u8{ "alloca <64 x i128>,align 1024", "alloca <4 x i128>,i64 %n,align 64", "alloca <4 x i128>,align 8192" }) |expression| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define void @closed(i64 %n) {{\nentry:\n %slot = {s}\n ret void\n}}\n", .{expression});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
}

test "promoted vector ABI executes expanded XMM cells and ignores non-payload bits" {
    const a = std.testing.allocator;
    const machine = @import("../machine.zig");
    const selector = @import("../generic_cfg_selector.zig");
    var shapes: std.ArrayList([2]u16) = .empty;
    defer shapes.deinit(a);
    for ([_]u16{ 2, 4, 8, 16 }) |n| for (1..128 / n) |bits| {
        if (bits == 8 or bits == 16 or bits == 32 or bits == 51 or bits == 52 or bits == 64) continue;
        try shapes.append(a, .{ n, @intCast(bits) });
    };
    try shapes.append(a, .{ 3, 32 });
    try std.testing.expectEqual(@as(usize, 109), shapes.items.len);
    for ([_]u16{ 51, 52 }) |bits| try std.testing.expect(forms.privateAbiType(.{ .vector = .{ .len = 2, .elem_ty = .{ .int = bits } } }) == null);
    for (shapes.items) |shape| for ([_]bool{ false, true }) |fast| {
        const n = shape[0];
        const bits = shape[1];
        const text = try std.fmt.allocPrint(a, "define {0s}<{1d} x i{2d}> @promoted(<{1d} x i{2d}> %a,<{1d} x i{2d}> %b) {{\nentry:\n %r = add <{1d} x i{2d}> %a,%b\n ret <{1d} x i{2d}> %r\n}}\n", .{ if (fast) "fastcc " else "", n, bits });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const source = module.functions.items[0];
        const view = (try forms.legalize(arena.allocator(), source, null)).?;
        try std.testing.expect(source.params.items.ptr != view.params.items.ptr);
        try std.testing.expectEqual(@as(u32, n), source.ret_ty.vector.len);
        try std.testing.expectEqual(@as(u16, bits), source.ret_ty.vector.elem_ty.int);
        try std.testing.expect(view.ret_ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .double } }));
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = view;
        try private.verify();
        try module.verify();
        var selected = machine.MachineFunction.init(source.name, source.ret_ty);
        defer selected.deinit(a);
        const selection = try selector.tryLower(a, &selected, source);
        if (selection == .unsupported) std.debug.print("promoted <{d}xi{d}>: {s}\n", .{ n, bits, selection.unsupported.detail() });
        try std.testing.expect(selection == .selected);
        try @import("../verify.zig").verifyFunction(selected);
        const code = try @import("../../../mc/encoding.zig").encodeFunction(a, selected);
        defer a.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (@Vector(2, u64), @Vector(2, u64)) callconv(.c) @Vector(2, u64) = @ptrCast(memory.ptr);
        const stride: u16 = if (n == 3) 32 else @intCast(128 / n);
        const mask = (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
        for (0..64) |seed| {
            const x: @Vector(2, u64) = .{ @as(u64, seed) *% 0x9e3779b97f4a7c15, ~(@as(u64, seed) *% 0x8123456789abcdef) };
            const y: @Vector(2, u64) = .{ ~(@as(u64, seed) *% 0xf06dea67e461de5b), @as(u64, seed) *% 0x361962e2b9c8b6a5 };
            const actual = run(x, y);
            const x_words: [2]u64 = @bitCast(x);
            const y_words: [2]u64 = @bitCast(y);
            const actual_words: [2]u64 = @bitCast(actual);
            for (0..n) |i| {
                const word = i * stride / 64;
                const offset: u6 = @intCast(i * stride % 64);
                const expected = (((x_words[word] >> offset) & mask) + ((y_words[word] >> offset) & mask)) & mask;
                try std.testing.expectEqual(expected, (actual_words[word] >> offset) & mask);
            }
        }
    };
}

test "promoted vector ABI retains scalarized layouts and ninth XMM arguments closed" {
    for ([_][2]u16{ .{ 3, 1 }, .{ 3, 8 }, .{ 3, 16 }, .{ 4, 48 }, .{ 64, 4 }, .{ 2, 51 }, .{ 2, 52 } }) |shape| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define <{0d} x i{1d}> @closed(<{0d} x i{1d}> %v) {{\nentry:\n ret <{0d} x i{1d}> %v\n}}\n", .{ shape[0], shape[1] });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try forms.legalize(arena.allocator(), module.functions.items[0], null) == null);
    }
    var module = try ir.Module.parse(std.testing.allocator, "define <2 x i1> @ninth(<2 x i1> %a,<2 x i1> %b,<2 x i1> %c,<2 x i1> %d,<2 x i1> %e,<2 x i1> %f,<2 x i1> %g,<2 x i1> %h,<2 x i1> %i) {\nentry:\n %sum = add <2 x i1> %a,%i\n ret <2 x i1> %sum\n}\n");
    defer module.deinit();
    try module.verify();
    const machine = @import("../machine.zig");
    var selected = machine.MachineFunction.init("ninth", module.functions.items[0].ret_ty);
    defer selected.deinit(std.testing.allocator);
    const selection = @import("../generic_cfg_selector.zig").tryLower(std.testing.allocator, &selected, module.functions.items[0]) catch |err| {
        try std.testing.expectEqual(error.UnsupportedVectorAbi, err);
        return;
    };
    try std.testing.expect(selection == .unsupported);
}

test "vector intrinsic lanes preserve source facts exact scalar signatures and immediate flags" {
    const names = [_][]const u8{ "abs", "ctpop", "ctlz", "cttz", "bitreverse", "bswap", "uadd.sat", "usub.sat", "sadd.sat", "ssub.sat", "fshl", "fshr", "umin", "umax", "smin", "smax", "ushl.sat", "sshl.sat", "umul.fix.sat", "smul.fix.sat" };
    for ([_]u16{ 8, 16, 32, 64 }) |bits| for (names, 0..) |name, index| {
        if (index == 5 and bits == 8) continue;
        const unary = index < 6;
        const flag = index == 0 or index == 2 or index == 3;
        const scale = index >= 18;
        const funnel = index == 10 or index == 11;
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const a = arena.allocator();
        const ty = try std.fmt.allocPrint(a, "<4 x i{d}>", .{bits});
        const scalar = try std.fmt.allocPrint(a, "i{d}", .{bits});
        const extra = if (flag) ",i1" else if (scale) ",i32" else "";
        const actual_extra = if (flag) ",i1 false" else if (scale) ",i32 0" else "";
        const vector_types = if (unary) ty else try std.fmt.allocPrint(a, "{0s},{0s}{1s}", .{ ty, if (funnel) try std.fmt.allocPrint(a, ",{s}", .{ty}) else "" });
        const scalar_types = if (unary) scalar else try std.fmt.allocPrint(a, "{0s},{0s}{1s}", .{ scalar, if (funnel) try std.fmt.allocPrint(a, ",{s}", .{scalar}) else "" });
        const operands = if (unary) try std.fmt.allocPrint(a, "{s} %x{s}", .{ ty, actual_extra }) else try std.fmt.allocPrint(a, "{0s} %x,{0s} %y{1s}{2s}", .{ ty, if (funnel) try std.fmt.allocPrint(a, ",{s} %y", .{ty}) else "", actual_extra });
        const text = try std.fmt.allocPrint(a, "declare {0s} @llvm.{1s}.v4i{2d}({3s}{4s})\ndeclare i{2d} @llvm.{1s}.i{2d}({5s}{4s})\ndefine i64 @probe(ptr %input,ptr %output,i64 %live) {{\nentry:\n %x = load {0s},ptr %input,align 1\n %y = xor {0s} %x,splat (i{2d} -1)\n %v = call {0s} @llvm.{1s}.v4i{2d}({6s})\n store {0s} %v,ptr %output,align 1\n ret i64 %live\n}}\n", .{ ty, name, bits, vector_types, extra, scalar_types, operands });
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const source = module.functions.items[0];
        const view = (try forms.legalize(a, source, null)).?;
        var private = module;
        private.functions = try module.functions.clone(a);
        private.functions.items[0] = view;
        try private.verify();
        try module.verify();
        try std.testing.expect(source.blocks.items.ptr != view.blocks.items.ptr);
        try std.testing.expect(source.blocks.items[0].instructions.items[2].kind.call.ret_ty == .vector);
        var scalar_calls: usize = 0;
        for (view.blocks.items) |block| for (block.instructions.items) |inst| if (inst.kind == .call) {
            scalar_calls += 1;
            try std.testing.expectEqual(bits, inst.kind.call.ret_ty.int);
            try std.testing.expectEqualStrings(try std.fmt.allocPrint(a, "llvm.{s}.i{d}", .{ name, bits }), inst.kind.call.callee);
            if (flag or scale) {
                const last = inst.kind.call.args.items[inst.kind.call.args.items.len - 1];
                try std.testing.expectEqual(@as(i128, 0), last.value.int);
                try std.testing.expectEqual(@as(u16, if (flag) 1 else 32), last.ty.int);
            }
        };
        try std.testing.expectEqual(@as(usize, 4), scalar_calls);
        try std.testing.expect(try forms.legalize(a, view, null) == null);
    };
}

test "vector intrinsic lanes retain malformed flags scales attributes and widths closed" {
    for ([_][]const u8{
        "call <4 x i8> @llvm.abs.v4i8(<4 x i8> %x,i1 %flag)",
        "call <4 x i8> @llvm.abs.v4i8(<4 x i8> %x,i1 2)",
        "call <4 x i8> @llvm.ctlz.v4i8(<4 x i8> %x,i32 0)",
        "call <4 x i8> @llvm.bswap.v4i8(<4 x i8> %x)",
        "call fastcc <4 x i8> @llvm.umin.v4i8(<4 x i8> %x,<4 x i8> %x)",
        "call <4 x i8> @llvm.umul.fix.sat.v4i8(<4 x i8> %x,<4 x i8> %x,i32 1)",
        "call <4 x i8> @llvm.smul.fix.sat.v4i8(<4 x i8> %x,<4 x i8> %x,i32 %scale)",
    }) |instruction| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define void @probe(ptr %p,i1 %flag,i32 %scale) {{\nentry:\n %x = load <4 x i8>,ptr %p,align 1\n %v = {s}\n ret void\n}}\n", .{instruction});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try forms.legalize(arena.allocator(), module.functions.items[0], null) == null);
    }
}

test "small vector ABI executes packed low XMM lanes and retains SSE stack overflow closed" {
    const a = std.testing.allocator;
    const machine = @import("../machine.zig");
    const selector = @import("../generic_cfg_selector.zig");
    for ([_][2]u16{ .{ 2, 8 }, .{ 4, 8 }, .{ 8, 8 }, .{ 2, 16 }, .{ 4, 16 }, .{ 2, 32 } }) |s| for ([_]bool{ false, true }) |fast| for ([_]bool{ false, true }) |ninth| {
        const args = if (ninth) try std.fmt.allocPrint(a, "<{0d} x i{1d}> %a,<{0d} x i{1d}> %b,<{0d} x i{1d}> %c,<{0d} x i{1d}> %d,<{0d} x i{1d}> %e,<{0d} x i{1d}> %f,<{0d} x i{1d}> %g,<{0d} x i{1d}> %h,<{0d} x i{1d}> %i", .{ s[0], s[1] }) else try std.fmt.allocPrint(a, "<{0d} x i{1d}> %a,<{0d} x i{1d}> %b", .{ s[0], s[1] });
        defer a.free(args);
        const text = try std.fmt.allocPrint(a, "define {0s}<{1d} x i{2d}> @small({3s}) {{\nentry:\n %v = add <{1d} x i{2d}> %a,%{4s}\n ret <{1d} x i{2d}> %v\n}}\n", .{ if (fast) "fastcc " else "", s[0], s[1], args, if (ninth) "i" else "b" });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const source = module.functions.items[0];
        const view = (try forms.legalize(arena.allocator(), source, null)).?;
        try std.testing.expect(source.params.items.ptr != view.params.items.ptr);
        try std.testing.expect(source.ret_ty == .vector);
        try std.testing.expect(view.ret_ty == .double);
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = view;
        try private.verify();
        try module.verify();
        var selected = machine.MachineFunction.init(source.name, source.ret_ty);
        defer selected.deinit(a);
        const selection = try selector.tryLower(a, &selected, source);
        if (ninth) {
            // SSE overflow is closed in the existing shared physical layout.
            // Proving a double-sized private boundary does not open that rule.
            try std.testing.expect(selection == .unsupported);
            continue;
        }
        if (selection == .unsupported) std.debug.print("small ABI <{d}xi{d}> fast={} ninth={}: {s}\n", .{ s[0], s[1], fast, ninth, selection.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selection);
        try std.testing.expect(selected.ret_ty == .double);
        try @import("../verify.zig").verifyFunction(selected);
        const code = try @import("../../../mc/encoding.zig").encodeFunction(a, selected);
        defer a.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const mask: u64 = (@as(u64, 1) << @as(u6, @intCast(s[1]))) - 1;
        for ([_]u64{ 0, 1, std.math.maxInt(u64), 0x123456789abcdef0 }) |x| for ([_]u64{ 0, 1, std.math.maxInt(u64), 0xfedcba9876543210 }) |y| {
            var expected: u64 = 0;
            for (0..s[0]) |lane| {
                const shift: u6 = @intCast(lane * s[1]);
                expected |= ((((x >> shift) & mask) +% ((y >> shift) & mask)) & mask) << shift;
            }
            const got: f64 = if (ninth) blk: {
                const run: *const fn (f64, f64, f64, f64, f64, f64, f64, f64, f64) callconv(.c) f64 = @ptrCast(memory.ptr);
                break :blk run(@bitCast(x), 0, 0, 0, 0, 0, 0, 0, @bitCast(y));
            } else blk: {
                const run: *const fn (f64, f64) callconv(.c) f64 = @ptrCast(memory.ptr);
                break :blk run(@bitCast(x), @bitCast(y));
            };
            try std.testing.expectEqual(expected, @as(u64, @bitCast(got)));
        };
    };
}

test "packed vector memory executes exact odd byte extents with dirty tail bits and live values" {
    const a = std.testing.allocator;
    for ([_][2]u16{ .{ 3, 1 }, .{ 8, 3 }, .{ 7, 9 }, .{ 5, 17 }, .{ 3, 33 } }) |dimensions| {
        const count = dimensions[0];
        const bits = dimensions[1];
        const total = count * bits;
        const bytes = (total + 7) / 8;
        const text = try std.fmt.allocPrint(a, "declare i{1d} @llvm.vector.reduce.umin.v{0d}i{1d}(<{0d} x i{1d}>)\ndefine i64 @packed(ptr %input,ptr %output,i64 %live) {{\nentry:\n %v = load <{0d} x i{1d}>,ptr %input,align 1\n %w = xor <{0d} x i{1d}> %v,splat (i{1d} -1)\n store <{0d} x i{1d}> %w,ptr %output,align 1\n %r = call i{1d} @llvm.vector.reduce.umin.v{0d}i{1d}(<{0d} x i{1d}> %v)\n %wide = zext i{1d} %r to i64\n %answer = xor i64 %wide,%live\n ret i64 %answer\n}}\n", .{ count, bits });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const view = (try forms.legalize(arena.allocator(), module.functions.items[0], null)) orelse return error.ExpectedPackedMemory;
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = view;
        try private.verify();
        try module.verify();
        const machine = @import("../machine.zig");
        const selector = @import("../generic_cfg_selector.zig");
        var selected = machine.MachineFunction.init("packed", .{ .int = 64 });
        defer selected.deinit(a);
        const selection = try selector.tryLower(a, &selected, module.functions.items[0]);
        if (selection == .unsupported) std.debug.print("packed <{d}xi{d}>: {s}\n", .{ count, bits, selection.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selection);
        try @import("../verify.zig").verifyFunction(selected);
        const code = try @import("../../../mc/encoding.zig").encodeFunction(a, selected);
        defer a.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn ([*]const u8, [*]u8, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        for (0..32) |seed| {
            var input: [32]u8 = undefined;
            for (&input, 0..) |*v, i| v.* = @truncate(seed * 73 + i * 131 + 255);
            const original = input;
            var output: [32]u8 = @splat(0xa5);
            var minimum: u64 = std.math.maxInt(u64);
            for (0..count) |lane| {
                var value: u64 = 0;
                for (0..bits) |bit| {
                    const at = lane * bits + bit;
                    value |= @as(u64, (input[1 + at / 8] >> @as(u3, @intCast(at % 8))) & 1) << @as(u6, @intCast(bit));
                }
                minimum = @min(minimum, value);
            }
            const live: u64 = seed *% 0x9e3779b97f4a7c15;
            try std.testing.expectEqual(minimum ^ live, run(input[1..].ptr, output[1..].ptr, live));
            for (0..bytes) |byte| {
                const valid: u8 = if (byte + 1 == bytes and total % 8 != 0) @intCast((@as(u16, 1) << @as(u4, @intCast(total % 8))) - 1) else 255;
                try std.testing.expectEqual((~input[1 + byte]) & valid, output[1 + byte] & valid);
            }
            try std.testing.expectEqual(@as(u8, 0xa5), output[0]);
            for (output[1 + bytes ..]) |v| try std.testing.expectEqual(@as(u8, 0xa5), v);
            try std.testing.expectEqualDeep(original, input);
        }
    }
}

test "packed vector memory retains barriers address spaces and oversized packs closed" {
    for ([_][]const u8{
        "define void @f(ptr %p) {\nentry:\n %v = load <43 x i3>,ptr %p,align 1\n ret void\n}\n",
        "define void @f(ptr %p) {\nentry:\n %v = load volatile <8 x i3>,ptr %p,align 1\n ret void\n}\n",
        "define void @f(ptr %p) {\nentry:\n store volatile <8 x i3> zeroinitializer,ptr %p,align 1\n ret void\n}\n",
        "define void @f(ptr addrspace(1) %p) {\nentry:\n %v = load <8 x i3>,ptr addrspace(1) %p,align 1\n ret void\n}\n",
    }) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try forms.legalize(arena.allocator(), module.functions.items[0], null) == null);
    }
}

test "integer vector byte and halfword ABI views own only changed private parameters" {
    for ([_][]const u8{ "<16 x i8>", "<8 x i16>" }) |spelling| {
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const text = try std.fmt.allocPrint(arena.allocator(), "define {s} @lanes({s} %a, {s} %b) {{\nentry:\n %sum = add {s} %a, %b\n ret {s} %sum\n}}\n", .{ spelling, spelling, spelling, spelling, spelling });
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const source = module.functions.items[0];
        const view = (try forms.legalize(arena.allocator(), source, null)).?;
        try std.testing.expect(source.params.items.ptr != view.params.items.ptr);
        try std.testing.expectEqualStrings(spelling, try std.fmt.allocPrint(arena.allocator(), "{f}", .{source.params.items[0].ty}));
        try std.testing.expect(source.params.items[0].ty.eql(source.ret_ty));
        const raw: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .double } };
        try std.testing.expect(view.ret_ty.eql(raw));
        try std.testing.expect(view.params.items[0].ty.eql(raw));
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = view;
        try private.verify();
    }
}

test "integer vector GEP indices preserve scalar source strides and pointer lanes" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i64 @offsets(ptr %base, i64 %offset) {
        \\entry:
        \\ %one = insertelement <4 x i64> <i64 -8, i64 0, i64 8, i64 16>, i64 %offset, i64 1
        \\ %pointers = getelementptr i8, ptr %base, <4 x i64> %one
        \\ %picked = extractelement <4 x ptr> %pointers, i64 1
        \\ %value = load i64, ptr %picked, align 1
        \\ ret i64 %value
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const expanded = (try forms.legalize(arena.allocator(), module.functions.items[0], null)).?;
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    private.functions.items[0] = expanded;
    try private.verify();
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[1].kind.gep.resultType() == .vector);
    for (expanded.blocks.items[0].instructions.items) |inst| if (inst.kind == .gep) {
        try std.testing.expect(inst.kind.gep.resultType() == .ptr);
        try std.testing.expect(inst.kind.gep.source_ty.eql(.{ .int = 8 }));
    };
    try std.testing.expect((try forms.legalize(arena.allocator(), expanded, null)) == null);
}

test "integer vector aliases retain non-native wide carrier compatibility" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i64 @bytes(i80 %raw, ptr %out) {
        \\entry:
        \\ %one = insertelement <8 x i80> poison, i80 %raw, i64 0
        \\ %all = shufflevector <8 x i80> %one, <8 x i80> poison, <8 x i32> zeroinitializer
        \\ %parts = lshr <8 x i80> %all, <i80 0, i80 8, i80 16, i80 24, i80 32, i80 40, i80 48, i80 56>
        \\ %small = trunc <8 x i80> %parts to <8 x i8>
        \\ store <8 x i8> %small, ptr %out, align 1
        \\ %result = trunc i80 %raw to i64
        \\ ret i64 %result
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const expanded = (try forms.legalize(arena.allocator(), module.functions.items[0], null)).?;
    const widened = (try @import("wide_integer_forms.zig").legalizeForPhysicalAbi(arena.allocator(), expanded)) orelse return error.TestExpectedWideRewrite;
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    private.functions.items[0] = widened;
    try private.verify();
    try module.verify();
    try std.testing.expectEqual(@as(u16, 80), module.functions.items[0].params.items[0].ty.int);
}

test "integer vector lane expansion verifies privately and preserves source definitions" {
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/integer_vectors.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(source);
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    for (module.functions.items, private.functions.items) |original, *replacement| {
        replacement.* = (try forms.legalize(arena.allocator(), original, null)).?;
        try std.testing.expectEqual(original.params.items.ptr, replacement.params.items.ptr);
        try std.testing.expect(original.ret_ty.eql(replacement.ret_ty));
        try std.testing.expect((try forms.legalize(arena.allocator(), replacement.*, null)) == null);
        try std.testing.expect(replacement.blocks.items.ptr != original.blocks.items.ptr);
    }
    try private.verify();
    try module.verify();
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].kind == .insertelement);
}

test "integer vector lane expansion rejects unsupported memory ABI and indices" {
    for ([_][]const u8{
        "define <8 x i32> @f(<8 x i32> %v) {\nentry:\n ret <8 x i32> %v\n}\n",
        "define void @f(ptr %p) {\nentry:\n %v = load volatile <4 x i32>, ptr %p\n ret void\n}\n",
        "define void @f(ptr %p) {\nentry:\n %v = load volatile <2 x ptr>, ptr %p\n ret void\n}\n",
        "define void @f(ptr %p) {\nentry:\n %v = load <4 x i32>, ptr addrspace(1) %p\n ret void\n}\n",
        "define <2 x i128> @f(<2 x i128> %v) {\nentry:\n ret <2 x i128> %v\n}\n",
        "define i32 @f(ptr %p, i128 %index) {\nentry:\n %v = load <4 x i32>, ptr %p\n %r = extractelement <4 x i32> %v, i128 %index\n ret i32 %r\n}\n",
        "declare <8 x i32> @callee(<8 x i32>)\ndefine void @f(ptr %p) {\nentry:\n %v = load <8 x i32>, ptr %p\n %unproved = call <8 x i32> @callee(<8 x i32> %v)\n ret void\n}\n",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
}

test "integer vector ABI expansion keeps public signatures and verifies private lane bridges" {
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/vector_abi.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(source);
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    for (module.functions.items, private.functions.items) |original, *replacement| {
        replacement.* = (try forms.legalize(arena.allocator(), original, null)).?;
        try std.testing.expectEqual(original.params.items.ptr, replacement.params.items.ptr);
        try std.testing.expect(original.ret_ty.eql(replacement.ret_ty));
        try std.testing.expect((try forms.legalize(arena.allocator(), replacement.*, null)) == null);
    }
    try private.verify();
    try module.verify();
}

test "integer vector scalar bitcasts preserve exact source widths and private ownership" {
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/vector_masks.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(source);
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    for (module.functions.items, private.functions.items) |original, *replacement| {
        replacement.* = (try forms.legalize(arena.allocator(), original, null)).?;
        try std.testing.expectEqual(original.params.items.ptr, replacement.params.items.ptr);
        try std.testing.expect(original.ret_ty.eql(replacement.ret_ty));
        try std.testing.expect((try forms.legalize(arena.allocator(), replacement.*, null)) == null);
        try std.testing.expect(replacement.blocks.items.ptr != original.blocks.items.ptr);
    }
    try private.verify();
    try module.verify();
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[4].kind.cast.from_ty == .vector);
}

test "integer vector graphs retain forward PHI identities and typed pointer lanes" {
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/vector_graphs.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(source);
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    var scalar_freezes: usize = 0;
    for (module.functions.items, private.functions.items) |original, *replacement| {
        replacement.* = (try forms.legalize(arena.allocator(), original, null)).?;
        try std.testing.expectEqual(original.params.items.ptr, replacement.params.items.ptr);
        try std.testing.expect(original.ret_ty.eql(replacement.ret_ty));
        try std.testing.expect((try forms.legalize(arena.allocator(), replacement.*, null)) == null);
        for (replacement.blocks.items) |block| for (block.instructions.items) |inst| {
            if (!inst.removed and inst.kind == .phi) try std.testing.expect(inst.kind.phi.ty != .vector);
            if (!inst.removed and inst.kind == .freeze) {
                try std.testing.expect(inst.kind.freeze.ty != .vector);
                scalar_freezes += 1;
            }
        };
    }
    try std.testing.expect(scalar_freezes > 0);
    try private.verify();
    try module.verify();
    try std.testing.expect(module.functions.items[0].blocks.items[1].instructions.items[1].kind.phi.ty == .vector);
}

fn vectorInputCode(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const m = @import("../machine.zig");
    const select = @import("../generic_cfg_selector.zig");
    const source = module.functions.items[0];
    var machine = m.MachineFunction.init(source.name, source.ret_ty);
    defer machine.deinit(std.testing.allocator);
    const context: m.ReadOnlyModuleContext = .{ .globals = module.globals.items, .aliases = module.aliases.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout, .functions = module.functions.items, .declarations = module.declarations.items };
    const result = try select.tryLowerWithContext(std.testing.allocator, &machine, source, &context);
    if (result == .unsupported) std.debug.print("vector inputs: {s}\n", .{result.unsupported.detail()});
    try std.testing.expect(result == .selected);
    try @import("../verify.zig").verifyFunction(machine);
    const code = try @import("../../../mc/encoding.zig").encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}
fn vectorInputText(a: std.mem.Allocator, n: u32, bits: u16, pointer: bool) ![]const u8 {
    var text: std.Io.Writer.Allocating = .init(a);
    const scalar = if (pointer) "ptr" else try std.fmt.allocPrint(a, "i{d}", .{bits});
    try text.writer.print("define i64 @fragment_probe(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<{d} x {s}> %v,i64 %salt) {{\nentry:\n %s0 = xor i64 %salt,%p0\n", .{ n, scalar });
    for (1..6) |i| try text.writer.print(" %s{d} = xor i64 %s{d},%p{d}\n", .{ i, i - 1, i });
    for (0..n) |i| {
        try text.writer.print(" %lane{0d} = extractelement <{1d} x {2s}> %v,i64 {0d}\n", .{ i, n, scalar });
        if (pointer) try text.writer.print(" %word{0d} = ptrtoint ptr %lane{0d} to i64\n", .{i}) else if (bits == 64) try text.writer.print(" %word{0d} = add i64 %lane{0d},0\n", .{i}) else try text.writer.print(" %word{0d} = zext i{1d} %lane{0d} to i64\n", .{ i, bits });
        const previous = if (i == 0) "%s5" else try std.fmt.allocPrint(a, "%r{d}", .{i - 1});
        try text.writer.print(" %mix{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %mix{0d},%word{0d}\n", .{ i, previous });
    }
    try text.writer.print(" ret i64 %r{d}\n}}\n", .{n - 1});
    return a.dupe(u8, text.written());
}
test "fragment vector inputs preserve split XMM words and six live GP prefixes" {
    const Carrier = @Vector(2, u64);
    inline for ([_][2]u16{ .{ 32, 8 }, .{ 64, 8 }, .{ 16, 16 }, .{ 32, 16 }, .{ 64, 16 }, .{ 8, 32 }, .{ 16, 32 }, .{ 32, 32 }, .{ 4, 64 }, .{ 8, 64 }, .{ 16, 64 } }) |dimensions| {
        const n = dimensions[0];
        const bits = dimensions[1];
        const pieces = n * bits / 128;
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const a = arena.allocator();
        const text = try vectorInputText(a, n, bits, false);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        const view = (try forms.legalize(a, original, null)).?;
        try std.testing.expectEqual(@as(usize, 7 + pieces), view.params.items.len);
        var private = module;
        private.functions = try module.functions.clone(a);
        private.functions.items[0] = view;
        try private.verify();
        try std.testing.expect((try forms.legalize(a, view, null)) == null);
        const code = try vectorInputCode(module);
        defer std.posix.munmap(code);
        for (0..16) |seed| {
            var words: [8]Carrier = undefined;
            var bytes: [128]u8 = undefined;
            for (&bytes, 0..) |*byte, i| byte.* = @truncate((i + seed * 31) *% 173 ^ 0xa5);
            for (words[0..pieces], 0..) |*word, i| word.* = .{ std.mem.readInt(u64, bytes[i * 16 ..][0..8], .little), std.mem.readInt(u64, bytes[i * 16 + 8 ..][0..8], .little) };
            var prefix: [6]u64 = undefined;
            for (&prefix, 0..) |*value, i| value.* = @as(u64, @intCast(seed + i)) *% 0x9e3779b97f4a7c15;
            const salt: u64 = @as(u64, @intCast(seed)) *% 0xf06dea67e461de5b;
            var expected = salt;
            for (prefix) |value| expected ^= value;
            for (0..n) |i| {
                var lane: u64 = 0;
                for (0..bits / 8) |j| lane |= @as(u64, bytes[i * (bits / 8) + j]) << @as(u6, @intCast(j * 8));
                expected = (expected *% 1099511628211) ^ lane;
            }
            const result = if (pieces == 2) blk: {
                const run: *const fn (u64, u64, u64, u64, u64, u64, Carrier, Carrier, u64) callconv(.c) u64 = @ptrCast(code.ptr);
                break :blk run(prefix[0], prefix[1], prefix[2], prefix[3], prefix[4], prefix[5], words[0], words[1], salt);
            } else if (pieces == 4) blk: {
                const run: *const fn (u64, u64, u64, u64, u64, u64, Carrier, Carrier, Carrier, Carrier, u64) callconv(.c) u64 = @ptrCast(code.ptr);
                break :blk run(prefix[0], prefix[1], prefix[2], prefix[3], prefix[4], prefix[5], words[0], words[1], words[2], words[3], salt);
            } else blk: {
                const run: *const fn (u64, u64, u64, u64, u64, u64, Carrier, Carrier, Carrier, Carrier, Carrier, Carrier, Carrier, Carrier, u64) callconv(.c) u64 = @ptrCast(code.ptr);
                break :blk run(prefix[0], prefix[1], prefix[2], prefix[3], prefix[4], prefix[5], words[0], words[1], words[2], words[3], words[4], words[5], words[6], words[7], salt);
            };
            try std.testing.expectEqual(expected, result);
        }
        try std.testing.expectEqual(@as(usize, 8), original.params.items.len);
        try std.testing.expectEqual(@as(u32, n), original.params.items[6].ty.vector.len);
        try module.verify();
    }
}
test "fragment vector inputs preserve scalarized GP lanes and incoming stack words" {
    inline for ([_][3]u16{ .{ 3, 8, 0 }, .{ 3, 16, 0 }, .{ 3, 64, 0 }, .{ 5, 32, 0 }, .{ 3, 64, 1 } }) |dimensions| {
        const n = dimensions[0];
        const bits = dimensions[1];
        const pointer = dimensions[2] != 0;
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const a = arena.allocator();
        const text = try vectorInputText(a, n, bits, pointer);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        const view = (try forms.legalize(a, original, null)).?;
        try std.testing.expectEqual(@as(usize, 7 + n), view.params.items.len);
        var private = module;
        private.functions = try module.functions.clone(a);
        private.functions.items[0] = view;
        try private.verify();
        try std.testing.expect((try forms.legalize(a, view, null)) == null);
        const code = try vectorInputCode(module);
        defer std.posix.munmap(code);
        for (0..32) |seed| {
            var values: [5]u64 = undefined;
            for (&values, 0..) |*value, i| value.* = if (pointer) 0x1000 + (seed + i) * 64 else @as(u64, @intCast(seed + i)) *% 0xf06dea67e461de5b;
            const prefix = [_]u64{ 0x123456789abcdef0, 0xfedcba9876543210, 0x1122334455667788, 0xabcd0123456789ef, 0x87654321fedcba98, 0x1020304050607080 };
            const salt: u64 = @as(u64, @intCast(seed)) *% 0x9e3779b97f4a7c15;
            var expected = salt;
            for (prefix) |value| expected ^= value;
            const mask: u64 = if (bits == 64) std.math.maxInt(u64) else (@as(u64, 1) << bits) - 1;
            for (values[0..n]) |value| expected = (expected *% 1099511628211) ^ (value & mask);
            const result = if (n == 3) blk: {
                const run: *const fn (u64, u64, u64, u64, u64, u64, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
                break :blk run(prefix[0], prefix[1], prefix[2], prefix[3], prefix[4], prefix[5], values[0], values[1], values[2], salt);
            } else blk: {
                const run: *const fn (u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
                break :blk run(prefix[0], prefix[1], prefix[2], prefix[3], prefix[4], prefix[5], values[0], values[1], values[2], values[3], values[4], salt);
            };
            try std.testing.expectEqual(expected, result);
        }
        try std.testing.expectEqual(@as(usize, 8), original.params.items.len);
        try module.verify();
    }
}

test "fragment vector inputs retain unproved returns layouts and ABI facts closed" {
    for ([_][]const u8{
        "define <4 x i64> @closed(<4 x i64> %v) {\nentry:\n ret <4 x i64> %v\n}\n",
        "define <3 x i8> @closed(<3 x i8> %v) {\nentry:\n ret <3 x i8> %v\n}\n",
        "define void @closed(<64 x i64> %v) {\nentry:\n ret void\n}\n",
        "define void @closed(<3 x i9> %v) {\nentry:\n ret void\n}\n",
        "define void @closed(<4 x i64> inreg %v) {\nentry:\n ret void\n}\n",
        "define void @closed(<4 x i64> %v,...) {\nentry:\n ret void\n}\n",
    }) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
    var module = try ir.Module.parse(std.testing.allocator, "define i64 @ninth_fragment(double %prefix,<64 x i16> %v) {\nentry:\n %bits = bitcast double %prefix to i64\n %lane = extractelement <64 x i16> %v,i64 63\n %word = zext i16 %lane to i64\n %answer = xor i64 %word,%bits\n ret i64 %answer\n}\n");
    defer module.deinit();
    const m = @import("../machine.zig");
    var output = m.MachineFunction.init("ninth_fragment", .{ .int = 64 });
    defer output.deinit(std.testing.allocator);
    const outcome = @import("../generic_cfg_selector.zig").tryLower(std.testing.allocator, &output, module.functions.items[0]) catch |err| {
        try std.testing.expectEqual(error.UnsupportedVectorAbi, err);
        return;
    };
    try std.testing.expect(outcome == .unsupported);
}
fn checkedVectorExecutable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const a = std.testing.allocator;
    const machine = @import("../machine.zig");
    const selector = @import("../generic_cfg_selector.zig");
    const encoding = @import("../../../mc/encoding.zig");
    const f = module.functions.items[0];
    var output = machine.MachineFunction.init(f.name, f.ret_ty);
    defer output.deinit(a);
    const result = try selector.tryLower(a, &output, f);
    if (result == .unsupported) std.debug.print("checked vector: {s}\n", .{result.unsupported.detail()});
    try std.testing.expect(result == .selected);
    try @import("../verify.zig").verifyFunction(output);
    const code = try encoding.encodeFunction(a, output);
    defer a.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}
test "checked vector arithmetic preserves wrapped lanes packed flags and live values" {
    const shapes = [_][2]u16{ .{ 2, 32 }, .{ 3, 32 }, .{ 4, 8 }, .{ 2, 8 }, .{ 4, 16 }, .{ 8, 8 }, .{ 4, 32 }, .{ 8, 32 }, .{ 1, 8 }, .{ 64, 32 } };
    for (shapes) |s| for ([_][]const u8{ "uadd", "usub", "umul", "sadd", "ssub", "smul" }, 0..) |op, kind| for ([_]bool{ false, true }) |zero| {
        const n = s[0];
        const bits = s[1];
        const bytes = bits / 8;
        const a = std.testing.allocator;
        const text = try std.fmt.allocPrint(a, "declare {{<{0d} x i{1d}>,<{0d} x i1>}} @llvm.{2s}.with.overflow.v{0d}i{1d}(<{0d} x i{1d}>,<{0d} x i{1d}>)\ndeclare i1 @llvm.vector.reduce.or.v{0d}i1(<{0d} x i1>)\ndefine i64 @checked(ptr %a,ptr %b,ptr %out,i64 %live) {{\nentry:\n %x = load <{0d} x i{1d}>,ptr %a,align 1\n %y = load <{0d} x i{1d}>,ptr %b,align 1\n %pair = call {{<{0d} x i{1d}>,<{0d} x i1>}} @llvm.{2s}.with.overflow.v{0d}i{1d}(<{0d} x i{1d}> {3s},<{0d} x i{1d}> %y)\n %v = extractvalue {{<{0d} x i{1d}>,<{0d} x i1>}} %pair,0\n %flags = extractvalue {{<{0d} x i{1d}>,<{0d} x i1>}} %pair,1\n store <{0d} x i{1d}> %v,ptr %out,align 1\n %fptr = getelementptr i8,ptr %out,i64 {4d}\n store <{0d} x i1> %flags,ptr %fptr,align 1\n %any = call i1 @llvm.vector.reduce.or.v{0d}i1(<{0d} x i1> %flags)\n %wide = zext i1 %any to i64\n %r = xor i64 %wide,%live\n ret i64 %r\n}}\n", .{ n, bits, op, if (zero) "zeroinitializer" else "%x", n * bytes });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const original = module.functions.items[0];
        const private = (try forms.legalize(arena.allocator(), original, null)).?;
        var view = module;
        view.functions = try module.functions.clone(arena.allocator());
        view.functions.items[0] = private;
        try view.verify();
        const code = try checkedVectorExecutable(module);
        defer std.posix.munmap(code);
        const run: *const fn (*const u8, *const u8, *u8, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const mask = (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
        const sign = @as(u64, 1) << @as(u6, @intCast(bits - 1));
        const signed = kind >= 3;
        const minimum: i128 = if (signed) -@as(i128, sign) else 0;
        const maximum: i128 = if (signed) sign - 1 else mask;
        for (0..32) |seed| {
            var left: [256]u8 = @splat(0);
            var right: [256]u8 = @splat(0);
            var output: [288]u8 = @splat(0xa5);
            var expected: [272]u8 = @splat(0);
            var any = false;
            for (0..n) |i| {
                const edges = [_]u64{ 0, 1, sign - 1, sign, mask - 1, mask, mask / 3, mask / 5 };
                const x = if (seed < 8) edges[(seed + i) % 8] else ((@as(u64, seed) *% 0x9182736455aaccdd) ^ (@as(u64, i) *% 0x123456789abcdef1)) & mask;
                const y = if (seed < 8) edges[(seed + 3 + i * 3) % 8] else ~x & mask;
                for (0..bytes) |byte| {
                    left[i * bytes + byte] = @truncate(x >> @as(u6, @intCast(byte * 8)));
                    right[i * bytes + byte] = @truncate(y >> @as(u6, @intCast(byte * 8)));
                }
                const l: i128 = if (zero) 0 else if (signed and x & sign != 0) @as(i128, x) - (@as(i128, 1) << @as(u7, @intCast(bits))) else x;
                const r: i128 = if (signed and y & sign != 0) @as(i128, y) - (@as(i128, 1) << @as(u7, @intCast(bits))) else y;
                const full = switch (kind % 3) {
                    0 => l + r,
                    1 => l - r,
                    2 => l * r,
                    else => unreachable,
                };
                const raw: u64 = @truncate(@as(u128, @bitCast(full)) & mask);
                const overflow = full < minimum or full > maximum;
                any = any or overflow;
                for (0..bytes) |byte| expected[i * bytes + byte] = @truncate(raw >> @as(u6, @intCast(byte * 8)));
                if (overflow) expected[n * bytes + i / 8] |= @as(u8, 1) << @as(u3, @intCast(i % 8));
            }
            const live = @as(u64, seed) *% 0xfedcba9876543211;
            try std.testing.expectEqual(live ^ @intFromBool(any), run(&left[0], &right[0], &output[7], live));
            const extent = n * bytes + (n + 7) / 8;
            for (output, 0..) |byte, index| {
                if (index >= 7 and index < 7 + extent) {
                    const byte_mask: u8 = if (index == 7 + extent - 1 and n % 8 != 0) (@as(u8, 1) << @as(u3, @intCast(n % 8))) - 1 else 255;
                    try std.testing.expectEqual(expected[index - 7] & byte_mask, byte & byte_mask);
                } else try std.testing.expectEqual(@as(u8, 0xa5), byte);
            }
        }
        try module.verify();
        try std.testing.expect(original.blocks.items[0].instructions.items[2].kind.call.ret_ty == .aggregate);
    };
}
test "checked vector expansion rejects escaping aggregates and unproved envelopes" {
    const a = std.testing.allocator;
    for (0..6) |variant| {
        const input = if (variant == 0)
            "declare {<4 x i8>,<4 x i1>} @llvm.uadd.with.overflow.v4i8(<4 x i8>,<4 x i8>)\ndefine {<4 x i8>,<4 x i1>} @closed(ptr %p) {\nentry:\n %x = load <4 x i8>,ptr %p,align 1\n %pair = call {<4 x i8>,<4 x i1>} @llvm.uadd.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %x)\n ret {<4 x i8>,<4 x i1>} %pair\n}\n"
        else
            "declare {<4 x i8>,<4 x i1>} @llvm.uadd.with.overflow.v4i8(<4 x i8>,<4 x i8>)\ndefine void @closed(ptr %p) {\nentry:\n %x = load <4 x i8>,ptr %p,align 1\n %pair = call {<4 x i8>,<4 x i1>} @llvm.uadd.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %x)\n %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0\n store <4 x i8> %v,ptr %p,align 1\n ret void\n}\n";
        var module = try ir.Module.parse(a, input);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        if (variant != 0) try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0], null)) != null);
        const call = &module.functions.items[0].blocks.items[0].instructions.items[1].kind.call;
        switch (variant) {
            0 => {},
            1 => call.tail_kind = "musttail",
            2 => call.calling_conv = "fastcc",
            3 => call.args.items[0].attrs = "inreg",
            4 => call.ret_attrs = "noundef",
            5 => call.args.items[1].ty = .{ .vector = .{ .len = 4, .elem_ty = .{ .int = 16 } } },
            else => unreachable,
        }
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
}

test "integer vector products retain modular lanes exact stores and source" {
    const a = std.testing.allocator;
    inline for ([_]u16{ 8, 16, 24, 32, 48, 64, 128 }) |bits| for ([_]usize{ 4, 64 }) |count| {
        const text = try std.fmt.allocPrint(a, "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ndeclare i{0d} @llvm.vector.reduce.mul.v{1d}i{0d}(<{1d} x i{0d}>)\ndefine i64 @product(ptr %out,ptr %input,i64 %salt) {{\nentry:\n %v = load <{1d} x i{0d}>,ptr %input,align 1\n %r = call i{0d} @llvm.vector.reduce.mul.v{1d}i{0d}(<{1d} x i{0d}> %v)\n store i{0d} %r,ptr %out,align 1\n %answer = xor i64 %salt,90\n ret i64 %answer\n}}\n", .{ bits, count });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const view = (try forms.legalize(arena.allocator(), original, null)).?;
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = view;
        try private.verify();
        const machine = @import("../machine.zig");
        const selector = @import("../generic_cfg_selector.zig");
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .aliases = module.aliases.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout, .functions = module.functions.items, .declarations = module.declarations.items };
        var selected = machine.MachineFunction.init(original.name, original.ret_ty);
        defer selected.deinit(a);
        const selection = try selector.tryLowerWithContext(a, &selected, original, &context);
        if (selection == .unsupported) std.debug.print("product i{d}x{d}: {s}\n", .{ bits, count, selection.unsupported.detail() });
        try std.testing.expect(selection == .selected);
        try @import("../verify.zig").verifyFunction(selected);
        const code = try @import("../../../mc/encoding.zig").encodeFunction(a, selected);
        defer a.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (*u8, *const u8, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        const mask = std.math.maxInt(u128) >> @as(u7, @intCast(128 - bits));
        for (0..32) |seed| {
            var input: [1024]u8 = @splat(0);
            var expected: u128 = 1;
            for (0..count) |lane| {
                var value = if (seed == 0) 0 else if (seed == 1) mask else (((@as(u128, seed) *% 0x9182736455aaccdd) << 64) ^ (@as(u128, lane) *% 0x123456789abcdef1) ^ seed) & mask;
                if (seed == 2) value = 3;
                expected = (expected *% value) & mask;
                for (0..bits / 8) |byte| input[lane * (bits / 8) + byte] = @truncate(value >> @as(u7, @intCast(byte * 8)));
            }
            const saved = input;
            var output: [32]u8 = @splat(0xa5);
            const salt: u64 = seed *% 0x9182736455aaccdd;
            try std.testing.expectEqual(salt ^ 90, run(&output[8], &input[0], salt));
            for (0..bits / 8) |byte| try std.testing.expectEqual(@as(u8, @truncate(expected >> @as(u7, @intCast(byte * 8)))), output[8 + byte]);
            for (output[0..8]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
            for (output[8 + bits / 8 ..]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
            try std.testing.expectEqualSlices(u8, &saved, &input);
        }
        try module.verify();
        try std.testing.expect(original.blocks.items[0].instructions.items[1].kind == .call);
    };
}

test "integer vector products keep call envelopes and unsupported scalar widths closed" {
    const a = std.testing.allocator;
    for (0..7) |variant| {
        const bits: usize = if (variant == 6) 51 else 16;
        const text = try std.fmt.allocPrint(a, "declare i{0d} @llvm.vector.reduce.mul.v4i{0d}(<4 x i{0d}>)\ndefine i{0d} @product(<4 x i{0d}> %a) {{\nentry:\n %r = call i{0d} @llvm.vector.reduce.mul.v4i{0d}(<4 x i{0d}> %a)\n ret i{0d} %r\n}}\n", .{bits});
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const f = &module.functions.items[0];
        if (variant != 6) try std.testing.expect((try forms.legalize(arena.allocator(), f.*, null)) != null);
        const call = &f.blocks.items[0].instructions.items[0].kind.call;
        switch (variant) {
            0 => call.tail_kind = "musttail",
            1 => call.callee_function_ty = "i16 (<4 x i16>)",
            2 => call.args.items[0].attrs = "noundef",
            3 => call.args.items[0].abi_x87_memory = true,
            4 => call.args.items[0].abi_split_integer = true,
            5 => call.raw_args = "<4 x i16> %a",
            6 => {},
            else => unreachable,
        }
        try std.testing.expect((try forms.legalize(arena.allocator(), f.*, null)) == null);
    }
}
