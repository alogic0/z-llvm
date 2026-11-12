const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("integer_vectors.zig");

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
        "declare void @callee(<8 x i32>)\ndefine void @f(ptr %p) {\nentry:\n %v = load <8 x i32>, ptr %p\n call void @callee(<8 x i32> %v)\n ret void\n}\n",
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
