const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");
const intrinsics = @import("integer_intrinsics.zig");

test "right funnels execute scalar widths with full counts zero and live sources" {
    for ([_]u16{ 1, 6, 8, 16, 23, 32, 33, 63, 64 }) |bits| for ([_]bool{ false, true }) |literal| {
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const a = arena.allocator();
        const inputs = if (bits == 64) " %x = add i64 %a,0\n %y = add i64 %b,0\n %n = add i64 %count,0\n" else try std.fmt.allocPrint(a, " %x = trunc i64 %a to i{0d}\n %y = trunc i64 %b to i{0d}\n %n = trunc i64 %count to i{0d}\n", .{bits});
        const finish = if (bits == 64) " %wide = add i64 %v,0\n" else try std.fmt.allocPrint(a, " %wide = zext i{d} %v to i64\n", .{bits});
        const text = try std.fmt.allocPrint(a, "declare i{0d} @llvm.fshr.i{0d}(i{0d},i{0d},i{0d})\ndefine i64 @right(i64 %a,i64 %b,i64 %count,i64 %live) {{\nentry:\n{1s} %v = call i{0d} @llvm.fshr.i{0d}(i{0d} %x,i{0d} %y,i{0d} {2s})\n{3s} %r = xor i64 %wide,%live\n ret i64 %r\n}}\n", .{ bits, inputs, if (literal) "-1" else "%n", finish });
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const mask: u64 = @intCast((@as(u128, 1) << @as(u7, @intCast(bits))) - 1);
        const samples = [_]u64{ 0, 1, mask, 0x8000000000000000, 0x123456789abcdef0, 0xfedcba9876543210 };
        for (samples) |x| for (samples) |y| for ([_]u64{ 0, 1, bits - 1, bits, bits + 1, 63, 64, std.math.maxInt(u64) }) |count| {
            const s: u7 = @intCast((if (literal) mask else count & mask) % bits);
            const concatenated = (@as(u128, x & mask) << @as(u7, @intCast(bits))) | (y & mask);
            const expected: u64 = @intCast((concatenated >> s) & mask);
            const live = x ^ y ^ count;
            try std.testing.expectEqual(expected ^ live, run(x, y, count, live));
        };
    };
}

test "integer frontier wide byte swaps reverse every byte and retain literal bits" {
    const values = [_]u128{ 0, 1, 0x8000000000000000, 0x80000000000000000000, 0x0123456789abcdeffedcba9876543210, 0xfedcba98765432100123456789abcdef, std.math.maxInt(u128) };
    for ([_]u16{ 80, 96, 112, 128 }) |bits| for ([_]bool{ false, true }) |literal| {
        const mask: u128 = if (bits == 128) std.math.maxInt(u128) else (@as(u128, 1) << @as(u7, @intCast(bits))) - 1;
        const fixed = values[5] & mask;
        const constant: i128 = @bitCast(fixed);
        const operand = if (literal) try std.fmt.allocPrint(std.testing.allocator, "{d}", .{constant}) else try std.testing.allocator.dupe(u8, "%narrow");
        defer std.testing.allocator.free(operand);
        const start = if (bits == 128) " %narrow = add i128 %input,0\n" else try std.fmt.allocPrint(std.testing.allocator, " %narrow = trunc i128 %input to i{d}\n", .{bits});
        defer if (bits != 128) std.testing.allocator.free(start);
        const finish = if (bits == 128) " %answer = add i128 %swapped,0\n" else try std.fmt.allocPrint(std.testing.allocator, " %answer = zext i{d} %swapped to i128\n", .{bits});
        defer if (bits != 128) std.testing.allocator.free(finish);
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare i{d} @llvm.bswap.i{d}(i{d})\ndefine i128 @swap(i128 %input) {{\nentry:\n{s} %swapped = call i{d} @llvm.bswap.i{d}(i{d} {s})\n{s} ret i128 %answer\n}}\n", .{ bits, bits, bits, start, bits, bits, bits, operand, finish });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u128) callconv(.c) u128 = @ptrCast(code.ptr);
        for (values) |input| {
            const raw = if (literal) fixed else input & mask;
            var expected: u128 = 0;
            for (0..bits / 8) |byte| expected = (expected << 8) | ((raw >> @as(u7, @intCast(8 * byte))) & 255);
            try std.testing.expectEqual(expected, run(input));
        }
    };
}

fn executable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("integer frontier {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..bytes.len], bytes);
    return memory;
}

test "runtime wide count and minmax intrinsics preserve full pair values" {
    const values = [_]u128{ 0, 1, 0x8000000000000000, 0x10000000000000000, 0x80000000000000000000000000000000, 0x0123456789abcdeffedcba9876543210, std.math.maxInt(u128) };
    for ([_][]const u8{ "umin", "umax", "cttz" }) |op| {
        const count = std.mem.eql(u8, op, "cttz");
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare i128 @llvm.{s}.i128(i128,{s})\ndefine i128 @probe(i128 %a,i128 %b) {{\nentry:\n %v = call i128 @llvm.{s}.i128(i128 %a,{s})\n ret i128 %v\n}}\n", .{ op, if (count) "i1" else "i128", op, if (count) "i1 false" else "i128 %b" });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u128, u128) callconv(.c) u128 = @ptrCast(code.ptr);
        for (values) |a| for (values) |b| try std.testing.expectEqual(if (count) @as(u128, @ctz(a)) else if (std.mem.eql(u8, op, "umin")) @min(a, b) else @max(a, b), run(a, b));
    }
}

test "runtime wide constant funnels retain both sources across word boundaries" {
    const values = [_]u128{ 0, 1, 0x8000000000000000, 0x10000000000000000, 0x0123456789abcdeffedcba9876543210, std.math.maxInt(u128) };
    for ([_]i128{ 0, 1, 63, 64, 65, 127, 128, 129, -1 }) |amount| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare i128 @llvm.fshl.i128(i128,i128,i128)\ndefine i128 @probe(i128 %a,i128 %b) {{\nentry:\n %v = call i128 @llvm.fshl.i128(i128 %a,i128 %b,i128 {d})\n ret i128 %v\n}}\n", .{amount});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u128, u128) callconv(.c) u128 = @ptrCast(code.ptr);
        const shift: u7 = @truncate(@as(u128, @bitCast(amount)));
        for (values) |a| for (values) |b| try std.testing.expectEqual(if (shift == 0) a else (a << shift) | (b >> @as(u7, @intCast(128 - @as(u8, shift)))), run(a, b));
    }
}

test "integer frontier native matrix checks saturation comparison wide counts poison abs and live carriers" {
    const declarations =
        \\declare i8 @llvm.ssub.sat.i8(i8, i8)
        \\declare i32 @llvm.ssub.sat.i32(i32, i32)
        \\declare i32 @llvm.scmp.i32.i32(i32, i32)
        \\declare i128 @llvm.ctlz.i128(i128, i1 immarg)
        \\declare i32 @llvm.abs.i32(i32, i1 immarg)
        \\declare i64 @llvm.abs.i64(i64, i1 immarg)
        \\declare i16 @llvm.umul.fix.sat.i16(i16, i16, i32 immarg)
        \\declare i64 @llvm.ushl.sat.i64(i64, i64)
        \\
    ;
    for (0..8) |kind| for ([_]bool{ false, true }) |constant| {
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const a = arena.allocator();
        const prefix = switch (kind) {
            0 => " %x = trunc i64 %a to i8\n %y = trunc i64 %b to i8\n",
            1, 2, 4 => " %x = trunc i64 %a to i32\n %y = trunc i64 %b to i32\n",
            3 => " %lo = zext i64 %a to i128\n %hi = zext i64 %b to i128\n %shift = shl i128 %hi, 64\n %pair = or i128 %lo, %shift\n",
            6 => " %x = trunc i64 %a to i16\n %y = trunc i64 %b to i16\n",
            else => "",
        };
        const call = switch (kind) {
            0 => if (constant) "call i8 @llvm.ssub.sat.i8(i8 128, i8 255)" else "call i8 @llvm.ssub.sat.i8(i8 %x, i8 %y)",
            1 => if (constant) "call i32 @llvm.ssub.sat.i32(i32 2147483648, i32 4294967295)" else "call i32 @llvm.ssub.sat.i32(i32 %x, i32 %y)",
            2 => if (constant) "call i32 @llvm.scmp.i32.i32(i32 0, i32 %y)" else "call i32 @llvm.scmp.i32.i32(i32 %x, i32 %y)",
            3 => if (constant) "call range(i128 0, 129) i128 @llvm.ctlz.i128(i128 -1, i1 false)" else "call range(i128 0, 129) i128 @llvm.ctlz.i128(i128 %pair, i1 false)",
            4 => if (constant) "call noundef i32 @llvm.abs.i32(i32 -1, i1 true)" else "call noundef i32 @llvm.abs.i32(i32 %x, i1 true)",
            5 => if (constant) "call noundef i64 @llvm.abs.i64(i64 -1, i1 true)" else "call noundef i64 @llvm.abs.i64(i64 %a, i1 true)",
            6 => if (constant) "call i16 @llvm.umul.fix.sat.i16(i16 65535, i16 65535, i32 0)" else "call i16 @llvm.umul.fix.sat.i16(i16 %x, i16 %y, i32 0)",
            else => if (constant) "call i64 @llvm.ushl.sat.i64(i64 -1, i64 1)" else "call i64 @llvm.ushl.sat.i64(i64 %a, i64 1)",
        };
        const result = switch (kind) {
            0 => " %value = zext i8 %raw to i64\n %upper = add i64 0, 0\n",
            1, 2, 4 => " %value = zext i32 %raw to i64\n %upper = add i64 0, 0\n",
            3 => " %value = trunc i128 %raw to i64\n %shifted = lshr i128 %raw, 64\n %upper = trunc i128 %shifted to i64\n",
            6 => " %value = zext i16 %raw to i64\n %upper = add i64 0, 0\n",
            else => " %value = add i64 %raw, 0\n %upper = add i64 0, 0\n",
        };
        const source = try std.fmt.allocPrint(
            a,
            "{s}define i64 @probe(i64 %a, i64 %b, ptr %out, i64 %salt) {{\nentry:\n{s} %raw = {s}\n{s}" ++
                " store i64 %value, ptr %out\n %next = getelementptr i8, ptr %out, i64 8\n store i64 %upper, ptr %next\n" ++
                " %live0 = xor i64 %a, %b\n %live = xor i64 %live0, %salt\n ret i64 %live\n}}\n",
            .{ declarations, prefix, call, result },
        );
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const code = executable(module) catch |err| {
            std.debug.print("integer frontier kind={d} constant={}\n", .{ kind, constant });
            return err;
        };
        defer std.posix.munmap(code);
        const run: *const fn (u64, u64, *[2]u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const values = [_]u64{ 0, 1, 2, 0x7f, 0x80, 0xff, 0x7fffffff, 0x80000000, 0xffffffff, 0x7fffffffffffffff, 0x8000000000000000, 0xdeadbeef89abcdef, std.math.maxInt(u64) };
        for (values) |x| for (values) |y| {
            const expected: u64 = switch (kind) {
                0, 1 => blk: {
                    const bits: u7 = if (kind == 0) 8 else 32;
                    const modulus = @as(i128, 1) << bits;
                    const sign = @divExact(modulus, 2);
                    const mask: u64 = @intCast(modulus - 1);
                    const raw_x: i128 = if (constant) sign else x & mask;
                    const raw_y: i128 = if (constant) mask else y & mask;
                    const sx = if (raw_x >= sign) raw_x - modulus else raw_x;
                    const sy = if (raw_y >= sign) raw_y - modulus else raw_y;
                    const value = @max(-sign, @min(sign - 1, sx - sy));
                    break :blk @intCast(@as(u128, @bitCast(value)) & mask);
                },
                2 => blk: {
                    const sx: i32 = if (constant) 0 else @bitCast(@as(u32, @truncate(x)));
                    const sy: i32 = @bitCast(@as(u32, @truncate(y)));
                    const value: i32 = if (sx < sy) -1 else if (sx > sy) 1 else 0;
                    break :blk @as(u32, @bitCast(value));
                },
                3 => if (constant) 0 else @clz(@as(u128, x) | (@as(u128, y) << 64)),
                4, 5 => blk: {
                    const bits: u7 = if (kind == 4) 32 else 64;
                    const mask: u64 = @intCast((@as(u128, 1) << bits) - 1);
                    const sign = @as(u64, 1) << @as(u6, @intCast(bits - 1));
                    const value = if (constant) mask else x & mask;
                    if (value == sign) continue;
                    break :blk if (value & sign == 0) value else (0 -% value) & mask;
                },
                6 => blk: {
                    const left: u64 = if (constant) 65535 else x & 65535;
                    const right: u64 = if (constant) 65535 else y & 65535;
                    break :blk @min(left * right, 65535);
                },
                7 => blk: {
                    const value = if (constant) std.math.maxInt(u64) else x;
                    break :blk if (value > std.math.maxInt(u64) / 2) std.math.maxInt(u64) else value * 2;
                },
                else => unreachable,
            };
            var out: [2]u64 = @splat(0xaaaaaaaa55555555);
            const salt: u64 = 0x123456789abcdef0;
            try std.testing.expectEqual(x ^ y ^ salt, run(x, y, &out, salt));
            try std.testing.expectEqual(expected, out[0]);
            try std.testing.expectEqual(@as(u64, 0), out[1]);
        };
    };
}

fn allocationAttempt(allocator: std.mem.Allocator, function: ir.Function) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const candidate = (try intrinsics.legalize(arena.allocator(), function)).?;
    try std.testing.expect(candidate.blocks.items.ptr != function.blocks.items.ptr);
}

test "integer frontier rewrites preserve source ownership idempotence and allocation rollback" {
    for ([_][]const u8{
        "call i8 @llvm.ssub.sat.i8(i8 128, i8 255)",
        "call i32 @llvm.ssub.sat.i32(i32 2147483648, i32 -1)",
        "call i16 @llvm.sadd.sat.i16(i16 32767, i16 1)",
        "call i64 @llvm.sadd.sat.i64(i64 9223372036854775807, i64 1)",
        "call i64 @llvm.ssub.sat.i64(i64 9223372036854775808, i64 1)",
        "call i96 @llvm.ssub.sat.i96(i96 1, i96 -1)",
        "call i32 @llvm.scmp.i32.i32(i32 0, i32 -1)",
        "call range(i128 0, 129) i128 @llvm.ctlz.i128(i128 -1, i1 false)",
        "call noundef i32 @llvm.abs.i32(i32 1, i1 true)",
        "call noundef i64 @llvm.abs.i64(i64 -1, i1 true)",
        "call i16 @llvm.umul.fix.sat.i16(i16 65535, i16 65535, i32 0)",
        "call i64 @llvm.ushl.sat.i64(i64 -1, i64 1)",
    }) |instruction| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define void @forms() {{\nentry:\n %value = {s}\n ret void\n}}\n", .{instruction});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        const original = module.functions.items[0];
        const call = original.blocks.items[0].instructions.items[0].kind.call;
        var moving = std.testing.FailingAllocator.init(std.testing.allocator, .{ .resize_fail_index = 0 });
        try std.testing.checkAllAllocationFailures(moving.allocator(), allocationAttempt, .{original});
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try intrinsics.legalize(arena.allocator(), original)).?;
        try std.testing.expect(try intrinsics.legalize(arena.allocator(), view) == null);
        try std.testing.expectEqual(@as(usize, 1), original.blocks.items[0].instructions.items.len);
        try std.testing.expectEqualDeep(call, original.blocks.items[0].instructions.items[0].kind.call);
        try std.testing.expect(view.blocks.items[0].instructions.items.ptr != original.blocks.items[0].instructions.items.ptr);
        if (std.mem.startsWith(u8, call.callee, "llvm.abs.")) {
            const private_call = for (view.blocks.items[0].instructions.items) |inst| {
                if (inst.kind == .call) break inst.kind.call;
            } else return error.MissingPrivateCall;
            try std.testing.expect(private_call.args.items.ptr != call.args.items.ptr);
            try std.testing.expectEqual(@as(i128, 0), private_call.args.items[1].value.int);
            try std.testing.expectEqual(@as(i128, 1), call.args.items[1].value.int);
        }
        view.blocks.items[0].instructions.items[0].removed = true;
        try std.testing.expect(!original.blocks.items[0].instructions.items[0].removed);
    }
}

test "integer frontier rejects unimplemented widths flags and semantic envelopes" {
    for ([_][]const u8{
        "call i48 @llvm.ssub.sat.i48(i48 1, i48 2)",
        "call i128 @llvm.ssub.sat.i128(i128 1, i128 2)",
        "call fastcc i8 @llvm.ssub.sat.i8(i8 1, i8 2)",
        "musttail call i32 @llvm.scmp.i32.i32(i32 1, i32 2)",
        "call i16 @llvm.scmp.i16.i32(i32 1, i32 2)",
        "call i32 @llvm.scmp.i32.i48(i48 1, i48 2)",
        "call zeroext i32 @llvm.scmp.i32.i32(i32 1, i32 2)",
        "call i8 @llvm.ssub.sat.i8(i8 inreg 1, i8 2)",
        "call i8 @llvm.ssub.sat.i8(i8 256, i8 2)",
        "call i128 @llvm.ctlz.i128(i128 0, i1 %flag)",
        "call i128 @llvm.ctlz.i128(i128 0, i1 2)",
        "call i128 @llvm.ctlz.i128(i128 0, i32 0)",
        "call range(i64 0, 129) i128 @llvm.ctlz.i128(i128 0, i1 false)",
        "call i128 @llvm.ctpop.i128(i128 0)",
        "call i128 @llvm.abs.i128(i128 0, i1 true)",
        "call i32 @llvm.abs.i32(i32 0, i1 %flag)",
        "call fastcc i64 @llvm.abs.i64(i64 1, i1 true)",
        "call signext i32 @llvm.abs.i32(i32 1, i1 true)",
        "call i16 @llvm.umul.fix.sat.i16(i16 1, i16 2, i32 1)",
        "call i16 @llvm.umul.fix.sat.i16(i16 1, i16 2, i16 0)",
        "call fastcc i64 @llvm.ushl.sat.i64(i64 1, i64 0)",
        "call i64 @llvm.ushl.sat.i64(i64 inreg 1, i64 64)",
        "call i32 @llvm.ushl.sat.i32(i32 1, i64 1)",
    }) |instruction| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define void @decline(i1 %flag) {{\nentry:\n %value = {s}\n ret void\n}}\n", .{instruction});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try intrinsics.legalize(arena.allocator(), module.functions.items[0]) == null);
    }
}

test "saturating shifts execute signed unsigned logical widths and live carriers" {
    const a = std.testing.allocator;
    for ([_]u16{ 1, 4, 8, 16, 25, 32, 33, 63, 64 }) |bits| for ([_]bool{ false, true }) |signed| for (0..3) |constant_side| {
        const inputs = if (bits == 64) try a.dupe(u8, " %x = add i64 %input,0\n %n = add i64 %amount,0\n") else try std.fmt.allocPrint(a, " %x = trunc i64 %input to i{0d}\n %n = trunc i64 %amount to i{0d}\n", .{bits});
        defer a.free(inputs);
        const finish = if (bits == 64) try a.dupe(u8, " %wide = add i64 %v,0\n") else try std.fmt.allocPrint(a, " %wide = zext i{d} %v to i64\n", .{bits});
        defer a.free(finish);
        const text = try std.fmt.allocPrint(a, "declare i{0d} @llvm.{1s}.sat.i{0d}(i{0d},i{0d})\ndefine i64 @probe(i64 %input,i64 %amount,i64 %live) {{\nentry:\n{2s} %v = call i{0d} @llvm.{1s}.sat.i{0d}(i{0d} {3s},i{0d} {4s})\n{5s} %answer = xor i64 %wide,%live\n ret i64 %answer\n}}\n", .{ bits, if (signed) "sshl" else "ushl", inputs, if (constant_side == 1) "-1" else "%x", if (constant_side == 2) "0" else "%n", finish });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        const code = executable(module) catch |err| {
            std.debug.print("saturating shift bits={d} signed={} constant={d}\n", .{ bits, signed, constant_side });
            return err;
        };
        defer std.posix.munmap(code);
        const run: *const fn (u64, u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const sign: u64 = @as(u64, 1) << @as(u6, @intCast(bits - 1));
        const mask = (sign - 1) | sign;
        for ([_]u64{ 0, 1, sign - 1, sign, sign +% 1, mask - 1, mask, 0x123456789abcdef0 }) |input| for (0..bits) |amount| {
            const x = if (constant_side == 1) mask else input & mask;
            const count: u7 = if (constant_side == 2) 0 else @intCast(amount);
            const expected: u64 = if (signed) blk: {
                const sx: i128 = if (x & sign != 0) @as(i128, x) - (@as(i128, 1) << @as(u7, @intCast(bits))) else x;
                const min: i128 = -(@as(i128, 1) << @as(u7, @intCast(bits - 1)));
                const result = std.math.clamp(sx << count, min, -min - 1);
                break :blk @intCast(@as(u128, @bitCast(result)) & mask);
            } else @intCast(@min(@as(u128, x) << count, mask));
            const live: u64 = input ^ 0x9e3779b97f4a7c15;
            try std.testing.expectEqual(expected ^ live, run(input, @intCast(amount), live));
        };
    };
}

test "saturating multiply scale zero executes full signed unsigned products and live values" {
    const a = std.testing.allocator;
    for ([_]u16{ 1, 4, 8, 16, 25, 32, 33, 63, 64 }) |bits| for ([_]bool{ false, true }) |signed| for (0..3) |constant_side| {
        const inputs = if (bits == 64) try a.dupe(u8, " %x = add i64 %input,0\n %y = add i64 %other,0\n") else try std.fmt.allocPrint(a, " %x = trunc i64 %input to i{0d}\n %y = trunc i64 %other to i{0d}\n", .{bits});
        defer a.free(inputs);
        const finish = if (bits == 64) try a.dupe(u8, " %wide = add i64 %v,0\n") else try std.fmt.allocPrint(a, " %wide = zext i{d} %v to i64\n", .{bits});
        defer a.free(finish);
        const text = try std.fmt.allocPrint(a, "declare i{0d} @llvm.{1s}.fix.sat.i{0d}(i{0d},i{0d},i32 immarg)\ndefine i64 @probe(i64 %input,i64 %other,i64 %live) {{\nentry:\n{2s} %v = call i{0d} @llvm.{1s}.fix.sat.i{0d}(i{0d} {3s},i{0d} {4s},i32 0)\n{5s} %answer = xor i64 %wide,%live\n ret i64 %answer\n}}\n", .{ bits, if (signed) "smul" else "umul", inputs, if (constant_side == 1) "-1" else "%x", if (constant_side == 2) "-1" else "%y", finish });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        const code = executable(module) catch |err| {
            std.debug.print("saturating multiply bits={d} signed={} constant={d}\n", .{ bits, signed, constant_side });
            return err;
        };
        defer std.posix.munmap(code);
        const run: *const fn (u64, u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const sign: u64 = @as(u64, 1) << @as(u6, @intCast(bits - 1));
        const mask = (sign - 1) | sign;
        const samples = [_]u64{ 0, 1, sign - 1, sign, sign +% 1, mask - 1, mask, 0x123456789abcdef0 };
        for (samples) |input| for (samples) |other| {
            const x = if (constant_side == 1) mask else input & mask;
            const y = if (constant_side == 2) mask else other & mask;
            const expected: u64 = if (signed) blk: {
                const modulus = @as(i128, 1) << @as(u7, @intCast(bits));
                const sx: i128 = if (x & sign != 0) @as(i128, x) - modulus else x;
                const sy: i128 = if (y & sign != 0) @as(i128, y) - modulus else y;
                const minimum = -@as(i128, sign);
                const product = sx * sy;
                break :blk @intCast(@as(u128, @bitCast(std.math.clamp(product, minimum, -minimum - 1))) & mask);
            } else @intCast(@min(@as(u128, x) * y, mask));
            const live = input ^ other ^ 0x9e3779b97f4a7c15;
            try std.testing.expectEqual(expected ^ live, run(input, other, live));
        };
    };
}

test "saturating multiply retains nonzero scales and ABI envelopes closed" {
    for ([_][]const u8{
        "call i64 @llvm.smul.fix.sat.i64(i64 1,i64 2,i32 1)",
        "call i64 @llvm.umul.fix.sat.i64(i64 1,i64 2,i32 %scale)",
        "call i128 @llvm.smul.fix.sat.i128(i128 1,i128 2,i32 0)",
        "call i8 @llvm.smul.fix.sat.i8(i8 inreg 1,i8 2,i32 0)",
        "call fastcc i8 @llvm.smul.fix.sat.i8(i8 1,i8 2,i32 0)",
        "call i8 @llvm.smul.fix.sat.i8(i8 256,i8 2,i32 0)",
        "call i8 @llvm.smul.fix.sat.i8(i8 1,i8 2,i16 0)",
    }) |instruction| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define void @probe(i32 %scale) {{\nentry:\n %v = {s}\n ret void\n}}\n", .{instruction});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try intrinsics.legalize(arena.allocator(), module.functions.items[0]) == null);
    }
}

test "integer frontier wide counts and absolute values retain logical width bits" {
    for ([_]u16{ 65, 80, 113, 127 }) |bits| for ([_][]const u8{ "abs", "ctlz", "cttz", "ctpop" }) |operation| for ([_]bool{ false, true }) |literal| {
        const mask: u128 = (@as(u128, 1) << @as(u7, @intCast(bits))) - 1;
        const fixed: u128 = 0xfedcba98765432100123456789abcdef & mask;
        const input = if (literal) try std.fmt.allocPrint(std.testing.allocator, "{d}", .{fixed}) else try std.testing.allocator.dupe(u8, "%narrow");
        defer std.testing.allocator.free(input);
        const flagged = !std.mem.eql(u8, operation, "ctpop");
        const source = try std.fmt.allocPrint(std.testing.allocator, "declare i{d} @llvm.{s}.i{d}(i{d}{s})\ndefine i128 @calculate(i128 %raw) {{\nentry:\n %narrow = trunc i128 %raw to i{d}\n %result = call i{d} @llvm.{s}.i{d}(i{d} {s}{s})\n %wide = zext i{d} %result to i128\n ret i128 %wide\n}}\n", .{ bits, operation, bits, bits, if (flagged) ",i1" else "", bits, bits, operation, bits, bits, input, if (flagged) ",i1 false" else "", bits });
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const code = executable(module) catch |err| {
            std.debug.print("wide intrinsic width={d} operation={s} literal={}\n", .{ bits, operation, literal });
            return err;
        };
        defer std.posix.munmap(code);
        const run: *const fn (u128) callconv(.c) u128 = @ptrCast(code.ptr);
        for ([_]u128{ 0, 1, 2, @as(u128, 1) << 64, @as(u128, 1) << @as(u7, @intCast(bits - 1)), fixed, std.math.maxInt(u128) }) |raw| {
            const value = if (literal) fixed else raw & mask;
            const expected: u128 = if (std.mem.eql(u8, operation, "abs")) (if (value & (@as(u128, 1) << @as(u7, @intCast(bits - 1))) != 0) (~value +% 1) & mask else value) else if (std.mem.eql(u8, operation, "ctlz")) @as(u128, @clz(value)) - (128 - bits) else if (std.mem.eql(u8, operation, "cttz")) (if (value == 0) bits else @as(u128, @ctz(value))) else @popCount(value);
            try std.testing.expectEqual(expected, run(raw));
        }
    };
}
