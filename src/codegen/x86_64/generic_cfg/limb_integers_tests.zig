const std = @import("std");
const ir = @import("../../../ir.zig");
const limb = @import("limb_integers.zig");
const machine = @import("../machine.zig");
const layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128";

test "bounded limb division keeps source immutable and verifies its runtime call ABI" {
    for ([_]u16{ 129, 140, 200, 256, 495, 512 }) |bits| for ([_][]const u8{ "udiv", "urem", "sdiv", "srem" }) |op| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare void @__udivei4(ptr,ptr,ptr,i64)\ndeclare void @__umodei4(ptr,ptr,ptr,i64)\ndeclare void @__divei4(ptr,ptr,ptr,i64)\ndeclare void @__modei4(ptr,ptr,ptr,i64)\ndefine i64 @divide(ptr %out,ptr %xp,ptr %yp,i64 %live) {{\nentry:\n %x = load i{0d},ptr %xp,align 1\n %y = load i{0d},ptr %yp,align 1\n %z = {1s} i{0d} %x,%y\n store i{0d} %z,ptr %out,align 1\n %a = trunc i{0d} %x to i64\n %b = trunc i{0d} %y to i64\n %c = xor i64 %a,%b\n %r = xor i64 %c,%live\n ret i64 %r\n}}\n", .{ bits, op });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = layout, .functions = module.functions.items, .declarations = module.declarations.items, .aliases = module.aliases.items };
        const source = module.functions.items[0];
        const view = (try limb.legalize(arena.allocator(), source, &context)).?;
        try std.testing.expect(source.params.items.ptr != view.params.items.ptr);
        try std.testing.expect(source.blocks.items.ptr != view.blocks.items.ptr);
        try std.testing.expectEqualStrings(source.name, view.name);
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = view;
        try private.verify();
        try module.verify();
        try std.testing.expect(source.blocks.items[0].instructions.items[2].kind == .binary);
        try std.testing.expectEqual(source.params.items.len, view.params.items.len);
        var calls: usize = 0;
        for (view.blocks.items) |block| for (block.instructions.items) |inst| if (inst.kind == .call) {
            calls += 1;
            const call = inst.kind.call;
            try std.testing.expect(call.ret_ty == .void);
            try std.testing.expectEqual(@as(usize, 4), call.args.items.len);
            try std.testing.expectEqual(@as(i128, (try std.math.ceilPowerOfTwo(usize, (bits + 63) / 64)) * 64), call.args.items[3].value.int);
            try std.testing.expectEqual(@as(u16, 64), call.args.items[3].ty.int);
            for (0..3) |i| {
                try std.testing.expect(call.args.items[i].ty == .ptr);
                for (i + 1..3) |j| try std.testing.expect(!std.mem.eql(u8, call.args.items[i].value.named, call.args.items[j].value.named));
            }
        };
        try std.testing.expectEqual(@as(usize, 1), calls);
    };
}

test "bounded limb division rejects shadowed runtime providers and incompatible declarations" {
    for ([_][]const u8{
        "declare void @__udivei4(ptr,ptr,ptr,i32)\n",
        "declare fastcc void @__udivei4(ptr,ptr,ptr,i64)\n",
        "declare void @__udivei4(ptr,ptr,ptr,i64,...)\n",
        "declare i64 @__udivei4(ptr,ptr,ptr,i64)\n",
        "@__udivei4 = global i64 0\n",
        "define void @__udivei4(ptr %r,ptr %x,ptr %y,i64 %n) {\nentry:\n ret void\n}\n",
    }) |provider| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "{s}define i64 @divide(ptr %p) {{\nentry:\n %x = load i140,ptr %p,align 1\n %z = udiv i140 %x,%x\n %r = trunc i140 %z to i64\n ret i64 %r\n}}\n", .{provider});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = layout, .functions = module.functions.items, .declarations = module.declarations.items, .aliases = module.aliases.items };
        try std.testing.expect(try limb.legalize(arena.allocator(), module.functions.items[module.functions.items.len - 1], &context) == null);
    }
}

fn executable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const source = module.functions.items[0];
    var output = machine.MachineFunction.init(source.name, source.ret_ty);
    defer output.deinit(std.testing.allocator);
    const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = layout };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    if (try limb.legalize(arena.allocator(), source, &context)) |view| {
        var checked = module;
        checked.functions = try module.functions.clone(arena.allocator());
        checked.functions.items[0] = view;
        try checked.verify();
    }
    const selected = try @import("../generic_cfg_selector.zig").tryLowerWithContext(std.testing.allocator, &output, source, &context);
    if (selected == .unsupported) std.debug.print("limb selection: {s}\n", .{selected.unsupported.detail()});
    try std.testing.expect(selected == .selected);
    try @import("../verify.zig").verifyFunction(output);
    const code = try @import("../../../mc/encoding.zig").encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}

test "bounded limb integers execute exact tails carry borrow and cross word shifts" {
    inline for ([_]u16{ 129, 140, 200, 256, 495, 512 }) |bits| {
        const U = @Int(.unsigned, bits);
        const S = @Int(.signed, bits);
        for ([_][]const u8{ "add", "sub", "and", "or", "xor", "shl", "lshr", "ashr" }, 0..) |op, oi| {
            const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @limbs(ptr %out, ptr %a, ptr %b, i64 %amount) {{\nentry:\n" ++
                " %x = load i{0d}, ptr %a, align 1\n %y = load i{0d}, ptr %b, align 1\n" ++
                " %s = zext i64 %amount to i{0d}\n %r = {1s} i{0d} %x, %{2s}\n" ++
                " store i{0d} %r, ptr %out, align 1\n" ++
                " %live = xor i64 %amount, 23\n ret i64 %live\n}}\n", .{ bits, op, if (oi >= 5) "s" else "y" });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            const code = executable(module) catch |err| {
                std.debug.print("limbs i{d} {s}: {s}\n", .{ bits, op, @errorName(err) });
                return err;
            };
            defer std.posix.munmap(code);
            const run: *const fn ([*]u8, [*]const u8, [*]const u8, u64) callconv(.c) u64 = @ptrCast(code.ptr);
            for (0..8) |seed| {
                var a: [64]u8 = @splat(0);
                var c: [64]u8 = @splat(0);
                var x: U = 0;
                var y: U = 0;
                for (0..(bits + 7) / 8) |i| {
                    a[i] = @truncate((seed * 73 + i * 131) ^ (seed * 19 + 255));
                    c[i] = @truncate((seed * 17 + i * 13) ^ (seed * 67 + 255));
                    x |= @as(U, a[i]) << @intCast(i * 8);
                    y |= @as(U, c[i]) << @intCast(i * 8);
                }
                const before_a = a;
                const before_c = c;
                for ([_]u16{ 0, 1, 31, 63, 64, 65, bits - 1 }) |amount| {
                    const expected: U = switch (oi) {
                        0 => x +% y,
                        1 => x -% y,
                        2 => x & y,
                        3 => x | y,
                        4 => x ^ y,
                        5 => x << @intCast(amount),
                        6 => x >> @intCast(amount),
                        7 => @bitCast(@as(S, @bitCast(x)) >> @intCast(amount)),
                        else => unreachable,
                    };
                    var out: [80]u8 = @splat(0xa5);
                    try std.testing.expectEqual(@as(u64, amount) ^ 23, run(out[8..].ptr, &a, &c, amount));
                    for (0..(bits + 7) / 8) |i| {
                        const want: u8 = @truncate(expected >> @intCast(i * 8));
                        std.testing.expectEqual(want, out[8 + i]) catch |err| {
                            std.debug.print("limbs i{d} {s} seed={d} shift={d} byte={d}\n", .{ bits, op, seed, amount, i });
                            return err;
                        };
                    }
                    try std.testing.expectEqualSlices(u8, &@as([8]u8, @splat(0xa5)), out[0..8]);
                    for (out[8 + (bits + 7) / 8 ..]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
                    try std.testing.expectEqualSlices(u8, &before_a, &a);
                    try std.testing.expectEqualSlices(u8, &before_c, &c);
                }
            }
            try module.verify();
        }
    }
}

test "bounded limb integer intrinsics execute counts permutations saturation and full width funnels" {
    inline for ([_]u16{ 129, 140, 144, 200, 256, 495, 512 }) |bits| {
        const U = @Int(.unsigned, bits);
        const S = @Int(.signed, bits);
        const names = [_][]const u8{ "abs", "ctpop", "ctlz", "cttz", "bitreverse", "bswap", "uadd.sat", "usub.sat", "sadd.sat", "ssub.sat", "fshl", "fshr" };
        for (names, 0..) |name, op| {
            if (op == 5 and bits % 16 != 0) continue;
            var strings = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer strings.deinit();
            const ta = strings.allocator();
            const unary = op <= 5;
            const flag = op == 0 or op == 2 or op == 3;
            const funnel = op >= 10;
            const args = try std.fmt.allocPrint(ta, "i{d} %x{s}{s}", .{ bits, if (flag) ", i1 0" else if (unary) "" else try std.fmt.allocPrint(ta, ", i{d} %y", .{bits}), if (funnel) try std.fmt.allocPrint(ta, ", i{d} %a", .{bits}) else "" });
            var text: std.ArrayList(u8) = .empty;
            defer text.deinit(std.testing.allocator);
            const header = try std.fmt.allocPrint(ta, "declare i{0d} @llvm.{1s}.i{0d}({2s})\ndefine i64 @intrinsic(ptr %out, ptr %xp, ptr %yp, ptr %ap, i64 %salt) {{\nentry:\n %x = load i{0d}, ptr %xp, align 1\n %y = load i{0d}, ptr %yp, align 1\n %a = load i{0d}, ptr %ap, align 1\n %r = call i{0d} @llvm.{1s}.i{0d}({3s})\n store i{0d} %r, ptr %out, align 1\n %live = xor i64 %salt, 90\n ret i64 %live\n}}\n", .{ bits, name, if (flag) try std.fmt.allocPrint(ta, "i{0d}, i1", .{bits}) else if (funnel) try std.fmt.allocPrint(ta, "i{0d}, i{0d}, i{0d}", .{bits}) else if (unary) try std.fmt.allocPrint(ta, "i{d}", .{bits}) else try std.fmt.allocPrint(ta, "i{0d}, i{0d}", .{bits}), args });
            try text.appendSlice(std.testing.allocator, header);
            var module = try ir.Module.parse(std.testing.allocator, text.items);
            defer module.deinit();
            try module.verify();
            // These are exact existing scalar intrinsic signatures in the
            // private expanded view. They add no function bodies or providers.
            var declarations = try ir.Module.parse(std.testing.allocator, "declare i64 @llvm.ctpop.i64(i64)\ndeclare i64 @llvm.ctlz.i64(i64,i1)\ndeclare i64 @llvm.cttz.i64(i64,i1)\ndeclare i64 @llvm.bswap.i64(i64)\ndeclare i64 @llvm.bitreverse.i64(i64)\n");
            defer declarations.deinit();
            // The verifier fixture owns the added declaration payloads until
            // selection is done; the original source function stays untouched.
            const original_declaration_count = module.declarations.items.len;
            try module.declarations.appendSlice(std.testing.allocator, declarations.declarations.items);
            defer module.declarations.items.len = original_declaration_count;
            const code = executable(module) catch |err| {
                std.debug.print("limb intrinsic {s} i{d}: {s}\n", .{ name, bits, @errorName(err) });
                return err;
            };
            defer std.posix.munmap(code);
            const run: *const fn ([*]u8, [*]const u8, [*]const u8, [*]const u8, u64) callconv(.c) u64 = @ptrCast(code.ptr);
            const sign = @as(U, 1) << @intCast(bits - 1);
            const inputs = [_]U{ 0, 1, std.math.maxInt(U), sign, sign - 1, sign + 1, ~@as(U, 1), (@as(U, 1) << 64) | 17 };
            for (inputs, 0..) |x, seed| {
                const y = inputs[(seed + 3) % inputs.len];
                const amount = (@as(U, seed) << 64) | @as(U, seed * 65);
                const shift: std.math.Log2Int(U) = @intCast(amount % bits);
                const sx: S = @bitCast(x);
                const sy: S = @bitCast(y);
                const expected: U = switch (op) {
                    0 => @abs(sx),
                    1 => @popCount(x),
                    2 => @clz(x),
                    3 => @ctz(x),
                    4 => @bitReverse(x),
                    5 => if (bits % 16 == 0) @byteSwap(x) else unreachable,
                    6 => x +| y,
                    7 => x -| y,
                    8 => @bitCast(sx +| sy),
                    9 => @bitCast(sx -| sy),
                    10 => if (shift == 0) x else (x << shift) | (y >> @intCast(bits - shift)),
                    11 => if (shift == 0) y else (y >> shift) | (x << @intCast(bits - shift)),
                    else => unreachable,
                };
                var a: [64]u8 = @splat(0);
                var b: [64]u8 = @splat(0);
                var n: [64]u8 = @splat(0);
                for (0..(bits + 7) / 8) |i| {
                    a[i] = @truncate(x >> @intCast(i * 8));
                    b[i] = @truncate(y >> @intCast(i * 8));
                    n[i] = @truncate(amount >> @intCast(i * 8));
                }
                const before_a = a;
                const before_b = b;
                const before_n = n;
                var out: [80]u8 = @splat(0xa5);
                try std.testing.expectEqual(@as(u64, seed) ^ 90, run(out[8..].ptr, &a, &b, &n, seed));
                for (0..(bits + 7) / 8) |i| std.testing.expectEqual(@as(u8, @truncate(expected >> @intCast(i * 8))), out[8 + i]) catch |err| {
                    std.debug.print("limb intrinsic {s} i{d} seed={d} byte={d}\n", .{ name, bits, seed, i });
                    return err;
                };
                for (out[0..8]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
                for (out[8 + (bits + 7) / 8 ..]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
                try std.testing.expectEqualSlices(u8, &before_a, &a);
                try std.testing.expectEqualSlices(u8, &before_b, &b);
                try std.testing.expectEqualSlices(u8, &before_n, &n);
            }
        }
    }
}

test "bounded limb overflow tuples execute exact modular results and signed unsigned flags" {
    inline for ([_]u16{ 129, 140, 200, 256, 495, 512 }) |bits| {
        const U = @Int(.unsigned, bits);
        const S = @Int(.signed, bits);
        for ([_][]const u8{ "uadd", "usub", "sadd", "ssub" }, 0..) |name, op| {
            const text = try std.fmt.allocPrint(std.testing.allocator, "declare {{i{0d},i1}} @llvm.{1s}.with.overflow.i{0d}(i{0d},i{0d})\n" ++
                "define i64 @checked(ptr %out,ptr %flag,ptr %xp,ptr %yp,i64 %salt) {{\nentry:\n" ++
                " %x = load i{0d},ptr %xp,align 1\n %y = load i{0d},ptr %yp,align 1\n" ++
                " %tuple = call {{i{0d},i1}} @llvm.{1s}.with.overflow.i{0d}(i{0d} %x,i{0d} %y)\n" ++
                " %value = extractvalue {{i{0d},i1}} %tuple,0\n %overflow = extractvalue {{i{0d},i1}} %tuple,1\n" ++
                " %byte = zext i1 %overflow to i8\n store i{0d} %value,ptr %out,align 1\n store i8 %byte,ptr %flag,align 1\n" ++
                " %live = xor i64 %salt,90\n ret i64 %live\n}}\n", .{ bits, name });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            const code = executable(module) catch |err| {
                std.debug.print("overflow {s} i{d}: {s}\n", .{ name, bits, @errorName(err) });
                return err;
            };
            defer std.posix.munmap(code);
            const run: *const fn ([*]u8, [*]u8, [*]const u8, [*]const u8, u64) callconv(.c) u64 = @ptrCast(code.ptr);
            const sign = @as(U, 1) << @intCast(bits - 1);
            const values = [_]U{ 0, 1, std.math.maxInt(U), sign, sign - 1, sign + 1 };
            for (values, 0..) |x, xi| for (values, 0..) |y, yi| {
                const got = if (op < 2) (if (op == 0) @addWithOverflow(x, y) else @subWithOverflow(x, y)) else blk: {
                    const pair = if (op == 2) @addWithOverflow(@as(S, @bitCast(x)), @as(S, @bitCast(y))) else @subWithOverflow(@as(S, @bitCast(x)), @as(S, @bitCast(y)));
                    break :blk .{ @as(U, @bitCast(pair[0])), pair[1] };
                };
                var a: [64]u8 = @splat(0);
                var b: [64]u8 = @splat(0);
                for (0..(bits + 7) / 8) |i| {
                    a[i] = @truncate(x >> @intCast(i * 8));
                    b[i] = @truncate(y >> @intCast(i * 8));
                }
                const before_a = a;
                const before_b = b;
                var out: [80]u8 = @splat(0xa5);
                var flags: [3]u8 = @splat(0xa5);
                const salt: u64 = xi * 37 + yi * 131;
                try std.testing.expectEqual(salt ^ 90, run(out[8..].ptr, flags[1..].ptr, &a, &b, salt));
                for (0..(bits + 7) / 8) |i| try std.testing.expectEqual(@as(u8, @truncate(got[0] >> @intCast(i * 8))), out[8 + i]);
                try std.testing.expectEqual(@as(u8, got[1]), flags[1]);
                try std.testing.expectEqual(@as(u8, 0xa5), flags[0]);
                try std.testing.expectEqual(flags[0], flags[2]);
                for (out[0..8]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
                for (out[8 + (bits + 7) / 8 ..]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
                try std.testing.expectEqualSlices(u8, &before_a, &a);
                try std.testing.expectEqualSlices(u8, &before_b, &b);
            };
            try module.verify();
        }
    }
}

test "bounded limb overflow tuples reject aggregate escapes phis and unsupported operations" {
    const snippets = [_][]const u8{
        "declare {i140,i1} @llvm.uadd.with.overflow.i140(i140,i140)\ndefine {i140,i1} @escape(i140 %a,i140 %b) {\nentry:\n %t = call {i140,i1} @llvm.uadd.with.overflow.i140(i140 %a,i140 %b)\n ret {i140,i1} %t\n}\n",
        "declare {i140,i1} @llvm.uadd.with.overflow.i140(i140,i140)\ndefine void @escape(ptr %out,i140 %a,i140 %b) {\nentry:\n %t = call {i140,i1} @llvm.uadd.with.overflow.i140(i140 %a,i140 %b)\n store {i140,i1} %t,ptr %out,align 1\n ret void\n}\n",
        "declare {i140,i1} @llvm.uadd.with.overflow.i140(i140,i140)\ndefine void @escape(ptr %out,i140 %a,i140 %b) {\nentry:\n %t = call {i140,i1} @llvm.uadd.with.overflow.i140(i140 %a,i140 %b)\n br label %merge\nmerge:\n %p = phi {i140,i1} [%t,%entry]\n %v = extractvalue {i140,i1} %p,0\n store i140 %v,ptr %out,align 1\n ret void\n}\n",
        "declare {i140,i1} @llvm.umul.with.overflow.i140(i140,i140)\ndefine void @escape(ptr %out,i140 %a,i140 %b) {\nentry:\n %t = call {i140,i1} @llvm.umul.with.overflow.i140(i140 %a,i140 %b)\n %v = extractvalue {i140,i1} %t,0\n store i140 %v,ptr %out,align 1\n ret void\n}\n",
    };
    for (snippets) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = layout };
        try std.testing.expect(try limb.legalize(arena.allocator(), module.functions.items[0], &context) == null);
        try module.verify();
    }
}

test "bounded limb integers preserve pair casts signed extension and exact store tails" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i128 @casts(i128 %input, ptr %out) {
        \\entry:
        \\ %z = zext i128 %input to i256
        \\ %s = sext i128 %input to i200
        \\ store i256 %z, ptr %out, align 1
        \\ %p = getelementptr i8, ptr %out, i64 32
        \\ store i200 %s, ptr %p, align 1
        \\ %r = trunc i256 %z to i128
        \\ ret i128 %r
        \\}
    );
    defer module.deinit();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const call: *const fn (u128, [*]u8) callconv(.c) u128 = @ptrCast(code.ptr);
    for ([_]u128{ 0, 1, 0x7fffffffffffffffffffffffffffffff, 0x80000000000000000000000000000000, std.math.maxInt(u128) }) |input| {
        var output: [80]u8 = @splat(0xa5);
        try std.testing.expectEqual(input, call(input, output[8..].ptr));
        for (0..57) |i| {
            const original = if (i < 32) i else i - 32;
            const expected: u8 = if (original < 16) @truncate(input >> @as(u7, @intCast(original * 8))) else if (i >= 32 and input >> 127 != 0) 255 else 0;
            try std.testing.expectEqual(expected, output[8 + i]);
        }
        for (output[0..8]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
        for (output[65..]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
    }
}

test "bounded limb integers execute loop carried values and bounded private storage" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i64 @loop(ptr %out, ptr %input) {
        \\entry:
        \\ %box = alloca i200, align 16
        \\ %initial = load i200, ptr %input, align 1
        \\ br label %body
        \\body:
        \\ %value = phi i200 [ %initial, %entry ], [ %sum, %body ]
        \\ %index = phi i64 [ 0, %entry ], [ %next, %body ]
        \\ %sum = add i200 %value, 18446744073709551617
        \\ %next = add i64 %index, 1
        \\ %again = icmp ult i64 %next, 9
        \\ br i1 %again, label %body, label %exit
        \\exit:
        \\ store i200 %sum, ptr %box, align 16
        \\ %copy = load i200, ptr %box, align 16
        \\ store i200 %copy, ptr %out, align 1
        \\ ret i64 %next
        \\}
    );
    defer module.deinit();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const call: *const fn ([*]u8, [*]const u8) callconv(.c) u64 = @ptrCast(code.ptr);
    for (0..16) |seed| {
        var input: [25]u8 = undefined;
        var x: u200 = 0;
        for (&input, 0..) |*byte, i| {
            byte.* = @truncate(seed * 73 + i * 131);
            x |= @as(u200, byte.*) << @intCast(i * 8);
        }
        const expected = x +% (@as(u200, 18446744073709551617) * 9);
        var output: [48]u8 = @splat(0xa5);
        try std.testing.expectEqual(@as(u64, 9), call(output[8..].ptr, &input));
        for (0..25) |i| try std.testing.expectEqual(@as(u8, @truncate(expected >> @intCast(i * 8))), output[8 + i]);
        for (output[0..8]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
        for (output[33..]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
    }
}

test "bounded limb integers execute signed and unsigned comparison predicates" {
    inline for ([_]u16{ 140, 200, 512 }) |bits| {
        const U = @Int(.unsigned, bits);
        const S = @Int(.signed, bits);
        const high = @as(U, 1) << (bits - 1);
        for (std.enums.values(ir.IcmpPredicate)) |predicate| {
            const text = try std.fmt.allocPrint(std.testing.allocator, "define i32 @cmp(ptr %a, ptr %b) {{\nentry:\n %x = load i{0d}, ptr %a, align 1\n %y = load i{0d}, ptr %b, align 1\n %c = icmp {1s} i{0d} %x, %y\n %r = zext i1 %c to i32\n ret i32 %r\n}}\n", .{ bits, @tagName(predicate) });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            const code = try executable(module);
            defer std.posix.munmap(code);
            const call: *const fn ([*]const u8, [*]const u8) callconv(.c) u32 = @ptrCast(code.ptr);
            for ([_]U{ 0, 1, high - 1, high, std.math.maxInt(U) }) |x| for ([_]U{ 0, 1, high - 1, high, std.math.maxInt(U) }) |y| {
                const sx: S = @bitCast(x);
                const sy: S = @bitCast(y);
                const expected = switch (predicate) {
                    .eq => x == y,
                    .ne => x != y,
                    .ult => x < y,
                    .ule => x <= y,
                    .ugt => x > y,
                    .uge => x >= y,
                    .slt => sx < sy,
                    .sle => sx <= sy,
                    .sgt => sx > sy,
                    .sge => sx >= sy,
                };
                var a: [(bits + 7) / 8]u8 = undefined;
                var b: [(bits + 7) / 8]u8 = undefined;
                for (&a, &b, 0..) |*left, *right, i| {
                    left.* = @truncate(x >> @intCast(i * 8));
                    right.* = @truncate(y >> @intCast(i * 8));
                }
                try std.testing.expectEqual(@as(u32, @intFromBool(expected)), call(&a, &b));
            };
        }
    }
}

test "bounded limb integer view owns its physical signature and preserves source" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define fastcc i256 @identity(i256 %a) {
        \\entry:
        \\ ret i256 %a
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const source = module.functions.items[0];
    const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = layout };
    const view = (try limb.legalize(arena.allocator(), source, &context)) orelse return error.ExpectedPrivateView;
    try std.testing.expectEqual(ir.Type.ptr, view.ret_ty);
    try std.testing.expectEqual(@as(usize, 5), view.params.items.len);
    try std.testing.expect(source.params.items.ptr != view.params.items.ptr);
    try std.testing.expectEqual(@as(usize, 1), source.params.items.len);
    try std.testing.expectEqual(@as(u16, 256), source.params.items[0].ty.int);
    try std.testing.expectEqual(@as(u16, 256), module.functions.items[0].ret_ty.int);
    try std.testing.expect(try limb.legalize(arena.allocator(), view, &context) == null);
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    private.functions.items[0] = view;
    try private.verify();
    try module.verify();
}

test "bounded limb integers keep unproved returns barriers and layouts closed" {
    const cases = [_][]const u8{
        "define i140 @return3(i140 %a) {\nentry:\n ret i140 %a\n}\n",
        "define i64 @large(i513 %a) {\nentry:\n %r = trunc i513 %a to i64\n ret i64 %r\n}\n",
        "define i64 @barrier(ptr %a) {\nentry:\n %v = load volatile i200, ptr %a\n %r = trunc i200 %v to i64\n ret i64 %r\n}\n",
    };
    for (cases) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = layout };
        try std.testing.expect(try limb.legalize(arena.allocator(), module.functions.items[0], &context) == null);
        try module.verify();
    }
}
