const std = @import("std");
const ir = @import("../../../ir.zig");
const compilation = @import("../../../compilation.zig");
const encoding = @import("../../../mc/encoding.zig");
const verify = @import("../verify.zig");
const vectors = @import("floating_vectors.zig");

test "scalar floating minimum uses typed maximum ownership without mutating source" {
    for ([_][]const u8{ "half", "float", "double", "x86_fp80", "fp128" }, [_]u16{ 16, 32, 64, 80, 128 }) |ty, bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare {0s} @llvm.minnum.f{1d}({0s},{0s})\ndeclare {0s} @llvm.maxnum.f{1d}({0s},{0s})\ndefine {0s} @minimum({0s} %a,{0s} %b) {{\nentry:\n %r = call {0s} @llvm.minnum.f{1d}({0s} %a,{0s} %b)\n ret {0s} %r\n}}\n", .{ ty, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const source = module.functions.items[0];
        const view = (try vectors.legalize(arena.allocator(), source, null)).?;
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = view;
        try private.verify();
        try std.testing.expect((try vectors.legalize(arena.allocator(), view, null)) == null);
        try std.testing.expectEqualStrings(try std.fmt.allocPrint(arena.allocator(), "llvm.minnum.f{d}", .{bits}), source.blocks.items[0].instructions.items[0].kind.call.callee);
        var calls: usize = 0;
        for (view.blocks.items) |block| for (block.instructions.items) |inst| if (inst.kind == .call) {
            try std.testing.expectEqualStrings(try std.fmt.allocPrint(arena.allocator(), "llvm.maxnum.f{d}", .{bits}), inst.kind.call.callee);
            calls += 1;
        };
        try std.testing.expectEqual(@as(usize, 1), calls);
        try module.verify();
    }
}

test "scalar floating minimum keeps mismatched call envelopes closed" {
    for (0..6) |variant| {
        var module = try ir.Module.parse(std.testing.allocator, "declare float @llvm.minnum.f32(float,float)\ndefine float @bad(float %a,float %b) {\nentry:\n %r = call float @llvm.minnum.f32(float %a,float %b)\n ret float %r\n}\n");
        defer module.deinit();
        const call = &module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
        switch (variant) {
            0 => call.ret_attrs = "nnan",
            1 => call.calling_conv = "fastcc",
            2 => call.tail_kind = "musttail",
            3 => call.args.items[0].attrs = "noundef",
            4 => call.args.items[1].ty = .double,
            5 => call.callee = "llvm.minimum.f32",
            else => unreachable,
        }
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try vectors.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
}

test "small floating vector ABI preserves raw scalar packed and padded payloads" {
    const a = std.testing.allocator;
    for ([_][]const u8{ "half", "half", "half", "half", "float", "float", "double", "float" }, [_]u16{ 16, 16, 16, 16, 32, 32, 64, 32 }, [_]u16{ 1, 2, 4, 8, 1, 3, 1, 2 }) |ty, bits, n| for ([_]bool{ false, true }) |fast| {
        var text: std.Io.Writer.Allocating = .init(a);
        defer text.deinit();
        try text.writer.print("define {0s}<{1d} x {2s}> @permutation(<{1d} x {2s}> %a,<{1d} x {2s}> %b) {{\nentry:\n %r = shufflevector <{1d} x {2s}> %a,<{1d} x {2s}> %b,<{1d} x i32> <", .{ if (fast) "fastcc " else "", n, ty });
        for (0..n) |i| {
            if (i != 0) try text.writer.writeAll(",");
            try text.writer.print("i32 {d}", .{(if (i % 2 == 0) @as(usize, n) else 0) + n - 1 - i});
        }
        try text.writer.print(">\n ret <{d} x {s}> %r\n}}\n", .{ n, ty });
        var module = try ir.Module.parse(a, text.written());
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const source = module.functions.items[0];
        const view = (try vectors.legalize(arena.allocator(), source, null)).?;
        try std.testing.expect(try vectors.legalize(arena.allocator(), view, null) == null);
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = view;
        try private.verify();
        try module.verify();
        const machine = @import("../machine.zig");
        var output = machine.MachineFunction.init(source.name, source.ret_ty);
        defer output.deinit(a);
        const selection = try @import("../generic_cfg_selector.zig").tryLower(a, &output, source);
        if (selection == .unsupported) std.debug.print("small FP ABI {s} n={d} fast={}: {s}\n", .{ ty, n, fast, selection.unsupported.detail() });
        try std.testing.expect(selection == .selected);
        try verify.verifyFunction(output);
        const code = try encoding.encodeFunction(a, output);
        defer a.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (@Vector(2, u64), @Vector(2, u64)) callconv(.c) @Vector(2, u64) = @ptrCast(memory.ptr);
        const mask = if (bits == 64) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
        for (0..64) |seed| {
            const x: [2]u64 = .{ @as(u64, seed) *% 0x9e3779b97f4a7c15, ~(@as(u64, seed) *% 0x8123456789abcdef) };
            const y: [2]u64 = .{ ~(@as(u64, seed) *% 0xf06dea67e461de5b), @as(u64, seed) *% 0x361962e2b9c8b6a5 };
            const actual: [2]u64 = @bitCast(run(@bitCast(x), @bitCast(y)));
            for (0..n) |i| {
                const source_lane = n - 1 - i;
                const input = if (i % 2 == 0) y else x;
                const expected = (input[source_lane * bits / 64] >> @as(u6, @intCast(source_lane * bits % 64))) & mask;
                try std.testing.expectEqual(expected, (actual[i * bits / 64] >> @as(u6, @intCast(i * bits % 64))) & mask);
            }
        }
    };
}

test "small floating vector ABI keeps unproved wider and scalarized shapes closed" {
    for ([_][]const u8{ "<3 x half>", "<4 x double>", "<4 x x86_fp80>", "<4 x fp128>" }) |ty| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define {0s} @closed({0s} %v) {{\nentry:\n ret {0s} %v\n}}\n", .{ty});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try vectors.legalize(arena.allocator(), module.functions.items[0], null) == null);
    }
}

test "floating lane math preserves scalar intrinsic types arities and source IR" {
    for ([_][]const u8{ "half", "float", "double", "x86_fp80", "fp128" }, [_]u16{ 16, 32, 64, 80, 128 }) |ty, bits| {
        for ([_]usize{ 1, 2, 3, 4 }) |count| for (@import("extended_math_intrinsics.zig").operations) |op| {
            const fma = std.mem.eql(u8, op, "fma");
            var formatting = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer formatting.deinit();
            const text = try std.fmt.allocPrint(std.testing.allocator, "declare {0s} @llvm.{1s}.f{3d}({0s}{4s})\ndeclare <{2d} x {0s}> @llvm.{1s}.v{2d}f{3d}(<{2d} x {0s}>{5s})\ndefine void @lanes(ptr %out,ptr %ap,ptr %bp,ptr %cp) {{\nentry:\n %a = load <{2d} x {0s}>,ptr %ap,align 1\n %b = load <{2d} x {0s}>,ptr %bp,align 1\n %c = load <{2d} x {0s}>,ptr %cp,align 1\n %r = call <{2d} x {0s}> @llvm.{1s}.v{2d}f{3d}(<{2d} x {0s}> %a{6s})\n store <{2d} x {0s}> %r,ptr %out,align 1\n ret void\n}}\n", .{
                ty,                                                                                   op,                                                                                                              count,                                                                                                                 bits,
                if (fma) try std.fmt.allocPrint(formatting.allocator(), ",{0s},{0s}", .{ty}) else "", if (fma) try std.fmt.allocPrint(formatting.allocator(), ",<{0d} x {1s}>,<{0d} x {1s}>", .{ count, ty }) else "", if (fma) try std.fmt.allocPrint(formatting.allocator(), ",<{0d} x {1s}> %b,<{0d} x {1s}> %c", .{ count, ty }) else "",
            });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer arena.deinit();
            const source = module.functions.items[0];
            const view = (try vectors.legalize(arena.allocator(), source, null)).?;
            try std.testing.expect(try vectors.legalize(arena.allocator(), view, null) == null);
            var private = module;
            private.functions = try module.functions.clone(arena.allocator());
            private.functions.items[0] = view;
            try private.verify();
            var calls: usize = 0;
            for (view.blocks.items) |block| for (block.instructions.items) |inst| if (inst.kind == .call) {
                const call = inst.kind.call;
                try std.testing.expectEqualStrings(try std.fmt.allocPrint(arena.allocator(), "llvm.{s}.f{d}", .{ op, bits }), call.callee);
                try std.testing.expectEqual(if (fma) @as(usize, 3) else 1, call.args.items.len);
                try std.testing.expect(call.ret_ty.eql(source.blocks.items[0].instructions.items[3].kind.call.ret_ty.vector.elem_ty.toType()));
                for (call.args.items) |arg| try std.testing.expect(arg.ty.eql(call.ret_ty));
                calls += 1;
            };
            try std.testing.expectEqual(count, calls);
            try std.testing.expect(source.blocks.items[0].instructions.items[3].kind.call.ret_ty == .vector);
            try std.testing.expectEqualStrings("r", source.blocks.items[0].instructions.items[3].result.?);
            try module.verify();
        };
    }
}

test "floating lane math rejects unproved call envelopes and mismatched lane types" {
    for (0..7) |variant| {
        var module = try ir.Module.parse(std.testing.allocator, "declare <4 x float> @llvm.trunc.v4f32(<4 x float>)\ndefine void @bad(ptr %out,ptr %in) {\nentry:\n %v = load <4 x float>,ptr %in,align 1\n %r = call <4 x float> @llvm.trunc.v4f32(<4 x float> %v)\n store <4 x float> %r,ptr %out,align 1\n ret void\n}\n");
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const call = &module.functions.items[0].blocks.items[0].instructions.items[1].kind.call;
        switch (variant) {
            0 => call.tail_kind = "musttail",
            1 => call.ret_attrs = "noundef",
            2 => call.args.items[0].attrs = "noundef",
            3 => call.args.items[0].ty.vector.len = 3,
            4 => call.callee = "llvm.trunc.v4f64",
            5 => call.calling_conv = "fastcc",
            6 => call.operand_bundle = "[ \"cold\"() ]",
            else => unreachable,
        }
        try std.testing.expect(try vectors.legalize(arena.allocator(), module.functions.items[0], null) == null);
    }
}

test "floating minmax reductions retain scalar maxnum owners and exact sign bit views" {
    for ([_][]const u8{ "half", "float", "double", "x86_fp80", "fp128" }, [_]u16{ 16, 32, 64, 80, 128 }) |ty, bits| {
        for ([_]usize{ 2, 3, 4 }) |count| for ([_][]const u8{ "fmin", "fmax" }) |op| {
            const text = try std.fmt.allocPrint(std.testing.allocator, "declare {0s} @llvm.maxnum.f{3d}({0s},{0s})\ndeclare {0s} @llvm.vector.reduce.{1s}.v{2d}f{3d}(<{2d} x {0s}>)\ndefine void @reduce(ptr %out,ptr %in) {{\nentry:\n %v = load <{2d} x {0s}>,ptr %in,align 1\n %r = call {0s} @llvm.vector.reduce.{1s}.v{2d}f{3d}(<{2d} x {0s}> %v)\n store {0s} %r,ptr %out,align 1\n ret void\n}}\n", .{ ty, op, count, bits });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer arena.deinit();
            const source = module.functions.items[0];
            const view = (try vectors.legalize(arena.allocator(), source, null)).?;
            try std.testing.expect(try vectors.legalize(arena.allocator(), view, null) == null);
            var private = module;
            private.functions = try module.functions.clone(arena.allocator());
            private.functions.items[0] = view;
            try private.verify();
            var calls: usize = 0;
            var negations: usize = 0;
            for (view.blocks.items) |block| for (block.instructions.items) |inst| {
                if (inst.kind == .call) {
                    const call = inst.kind.call;
                    const spelling = try std.fmt.allocPrint(arena.allocator(), "llvm.maxnum.f{d}", .{bits});
                    try std.testing.expectEqualStrings(spelling, call.callee);
                    try std.testing.expect(call.ret_ty.eql(source.blocks.items[0].instructions.items[1].kind.call.ret_ty));
                    try std.testing.expectEqual(@as(usize, 2), call.args.items.len);
                    calls += 1;
                }
                if (inst.kind == .binary and inst.kind.binary.op == .xor) negations += 1;
            };
            try std.testing.expectEqual(count - 1, calls);
            try std.testing.expectEqual(if (std.mem.eql(u8, op, "fmin")) 3 * (count - 1) else @as(usize, 0), negations);
            try std.testing.expect(source.ret_ty.eql(view.ret_ty));
            try std.testing.expectEqual(source.params.items.len, view.params.items.len);
            for (source.params.items, view.params.items) |original, replacement| {
                try std.testing.expectEqualStrings(original.name, replacement.name);
                try std.testing.expect(original.ty.eql(replacement.ty));
                try std.testing.expectEqual(original.attrs, replacement.attrs);
            }
            try std.testing.expect(source.blocks.items[0].instructions.items[1].kind == .call);
            try module.verify();
        };
    }
}

test "floating reductions preserve ordered scalar steps seed and source identities" {
    for ([_][]const u8{ "half", "float", "double", "x86_fp80", "fp128" }, [_]u16{ 16, 32, 64, 80, 128 }) |ty, bits| {
        for ([_]usize{ 2, 3, 4 }) |count| for ([_][]const u8{ "fadd", "fmul" }) |op| {
            const text = try std.fmt.allocPrint(std.testing.allocator, "declare {0s} @llvm.vector.reduce.{1s}.v{2d}f{3d}({0s},<{2d} x {0s}>)\ndefine void @reduce(ptr %out,ptr %in,ptr %seed) {{\nentry:\n %v = load <{2d} x {0s}>,ptr %in,align 1\n %s = load {0s},ptr %seed,align 1\n %r = call {0s} @llvm.vector.reduce.{1s}.v{2d}f{3d}({0s} %s,<{2d} x {0s}> %v)\n store {0s} %r,ptr %out,align 1\n ret void\n}}\n", .{ ty, op, count, bits });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer arena.deinit();
            const source = module.functions.items[0];
            const view = (try vectors.legalize(arena.allocator(), source, null)).?;
            try std.testing.expect(try vectors.legalize(arena.allocator(), view, null) == null);
            var private = module;
            private.functions = try module.functions.clone(arena.allocator());
            private.functions.items[0] = view;
            try private.verify();
            var steps: usize = 0;
            var previous: ?[]const u8 = null;
            for (view.blocks.items) |block| for (block.instructions.items) |inst| {
                if (inst.kind != .binary) continue;
                const binary = inst.kind.binary;
                if (binary.op != .fadd and binary.op != .fmul) continue;
                try std.testing.expectEqual(if (std.mem.eql(u8, op, "fadd")) ir.BinaryOp.fadd else .fmul, binary.op);
                try std.testing.expect(binary.ty.eql(source.blocks.items[0].instructions.items[1].kind.load.ty));
                try std.testing.expect(!binary.fp_flags.any());
                if (previous) |name| try std.testing.expectEqualStrings(name, binary.lhs.named) else try std.testing.expectEqualStrings("s", binary.lhs.named);
                previous = inst.result;
                steps += 1;
            };
            try std.testing.expectEqual(count, steps);
            try std.testing.expectEqualStrings("r", source.blocks.items[0].instructions.items[2].result.?);
            try std.testing.expect(source.blocks.items[0].instructions.items[2].kind == .call);
            try module.verify();
        };
    }
}

fn executable(source: []const u8) ![]align(std.heap.page_size_min) u8 {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const expanded = (try vectors.legalize(arena.allocator(), module.functions.items[0], null)).?;
    try std.testing.expect((try vectors.legalize(arena.allocator(), expanded, null)) == null);
    var output = try compilation.select(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
    defer output.deinit(std.testing.allocator);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..bytes.len], bytes);
    return memory;
}

test "native width floating vector allocas activate private lane lowering" {
    const a = std.testing.allocator;
    inline for (.{ .{ "half", 16, 8 }, .{ "float", 32, 4 }, .{ "double", 64, 2 } }) |shape| {
        const source = try std.fmt.allocPrint(
            a,
            "declare <{0d} x {1s}> @llvm.fabs.v{0d}f{2d}(<{0d} x {1s}>)\n" ++
                "define void @owned_absolute(ptr %input, ptr %output) {{\nentry:\n" ++
                " %slot = alloca <{0d} x {1s}>, align 16\n %value = load <{0d} x {1s}>, ptr %input, align 1\n" ++
                " store <{0d} x {1s}> %value, ptr %slot, align 16\n %again = load <{0d} x {1s}>, ptr %slot, align 16\n" ++
                " %absolute = call <{0d} x {1s}> @llvm.fabs.v{0d}f{2d}(<{0d} x {1s}> %again)\n" ++
                " store <{0d} x {1s}> %absolute, ptr %output, align 1\n ret void\n}}\n",
            .{ shape[2], shape[0], shape[1] },
        );
        defer a.free(source);
        const memory = try executable(source);
        defer std.posix.munmap(memory);
        const run: *const fn (*const u8, *u8) callconv(.c) void = @ptrCast(memory.ptr);
        var input: [18]u8 = @splat(0xa5);
        var output: [32]u8 = @splat(0xa5);
        for (0..64) |seed| {
            for (input[1..17], 0..) |*byte, i| byte.* = @truncate(seed * 71 + i * 29);
            const before = input;
            @memset(&output, 0xa5);
            run(&input[1], &output[3]);
            for (0..16) |i| {
                const expected = if (i % (shape[1] / 8) == shape[1] / 8 - 1) input[1 + i] & 0x7f else input[1 + i];
                try std.testing.expectEqual(expected, output[3 + i]);
            }
            try std.testing.expectEqualSlices(u8, &before, &input);
            for (output[0..3]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
            for (output[19..]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
        }
    }
}

test "floating vector owned storage keeps dynamic objects and barrier loads closed" {
    const a = std.testing.allocator;
    for ([_][]const u8{
        "define void @dynamic(i64 %count,ptr %out) {\nentry:\n %slot = alloca <4 x float>, i64 %count, align 16\n %v = load <4 x float>,ptr %slot,align 16\n store <4 x float> %v,ptr %out,align 1\n ret void\n}\n",
        "define void @barrier(ptr %input,ptr %out) {\nentry:\n %slot = alloca <4 x float>,align 16\n %v = load volatile <4 x float>,ptr %input,align 1\n store <4 x float> %v,ptr %slot,align 16\n ret void\n}\n",
    }) |source| {
        var module = try ir.Module.parse(a, source);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        try std.testing.expect((try vectors.legalize(arena.allocator(), module.functions.items[0], null)) == null);
        try module.verify();
    }
}

test "owned vector activation preserves native quad argument payloads" {
    const source =
        \\define i128 @quad_bits(ptr %unused, fp128 %value) {
        \\entry:
        \\ %slot = alloca fp128, align 16
        \\ store fp128 %value, ptr %slot, align 16
        \\ %bits = bitcast fp128 %value to i128
        \\ ret i128 %bits
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var output = try compilation.select(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
    defer output.deinit(std.testing.allocator);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    @memcpy(memory[0..bytes.len], bytes);
    const run: *const fn (?*anyopaque, f128) callconv(.c) u128 = @ptrCast(memory.ptr);
    for ([_]u128{ 0, 1, @as(u128, 1) << 127, 0x7fff800000000000123456789abcdef0, 0xbfff13579bdf2468fedcba9876543210 }) |bits|
        try std.testing.expectEqual(bits, run(null, @bitCast(bits)));
}

test "runtime x87 vectors keep packed ten byte lanes exact under wide scalarization" {
    for ([_]u32{ 1, 3, 16, 64 }) |count| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "declare <{d} x x86_fp80> @llvm.fabs.v{d}f80(<{d} x x86_fp80>)\ndefine void @absolute(ptr %input, ptr %output) {{\nentry:\n %slot = alloca <{d} x x86_fp80>, align 16\n %v = load <{d} x x86_fp80>, ptr %input, align 1\n store <{d} x x86_fp80> %v, ptr %slot, align 1\n %again = load <{d} x x86_fp80>, ptr %slot, align 1\n %positive = call <{d} x x86_fp80> @llvm.fabs.v{d}f80(<{d} x x86_fp80> %again)\n store <{d} x x86_fp80> %positive, ptr %output, align 1\n ret void\n}}\n", .{ count, count, count, count, count, count, count, count, count, count, count });
        defer std.testing.allocator.free(source);
        const memory = try executable(source);
        defer std.posix.munmap(memory);
        const run: *const fn (*const u8, *u8) callconv(.c) void = @ptrCast(memory.ptr);
        var input: [640]u8 = undefined;
        var output: [656]u8 = @splat(165);
        const payloads = [_]u80{ 0, 1 << 79, 1, 0x3fff8000000000000000, 0xbfff8000000000000000, 0xffff8000000000000000, 0xffffc000000000000123, 0xffff8000000000000001 };
        for (0..payloads.len) |seed| {
            for (0..count) |lane| std.mem.writeInt(u80, input[lane * 10 ..][0..10], payloads[(seed + lane) % payloads.len], .little);
            @memset(&output, 165);
            run(&input[0], &output[8]);
            for (0..count) |lane| try std.testing.expectEqual(payloads[(seed + lane) % payloads.len] & ((@as(u80, 1) << 79) - 1), std.mem.readInt(u80, output[8 + lane * 10 ..][0..10], .little));
            for (output[0..8]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
            for (output[8 + count * 10 ..]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
        }
    }
}

test "runtime floating vectors shuffle wide payloads without changing NaNs zeros or store guards" {
    const source =
        \\define double @shuffle(double %a,double %b,double %c,double %d,ptr %out,double %live) {
        \\entry:
        \\ %v0 = insertelement <4 x double> poison,double %a,i64 0
        \\ %v1 = insertelement <4 x double> %v0,double %b,i64 1
        \\ %v2 = insertelement <4 x double> %v1,double %c,i64 2
        \\ %v3 = insertelement <4 x double> %v2,double %d,i64 3
        \\ %v = shufflevector <4 x double> %v3,<4 x double> poison,<4 x i32> <i32 3,i32 0,i32 2,i32 1>
        \\ store <4 x double> %v,ptr %out,align 1
        \\ ret double %live
        \\}
    ;
    const memory = try executable(source);
    defer std.posix.munmap(memory);
    const run: *const fn (f64, f64, f64, f64, *anyopaque, f64) callconv(.c) f64 = @ptrCast(memory.ptr);
    const values = [_]u64{ 0, 0x8000000000000000, 1, 0x7ff0000000000123, 0xfff8000000004567 };
    for (values) |a| for (values) |b| {
        const c = a ^ 0x8000000000000000;
        const d = b ^ 0x8000000000000000;
        var output: [48]u8 = @splat(165);
        try std.testing.expectEqual(a, @as(u64, @bitCast(run(@bitCast(a), @bitCast(b), @bitCast(c), @bitCast(d), &output[8], @bitCast(a)))));
        for ([_]u64{ d, a, c, b }, 0..) |expected, i| try std.testing.expectEqual(expected, std.mem.readInt(u64, output[8 + i * 8 ..][0..8], .little));
        for (output[0..8]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
        for (output[40..48]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
    };
}

test "runtime floating vectors retain the low64 packed float return ABI" {
    const source =
        \\define <2 x float> @packed(float %a,float %b) {
        \\entry:
        \\ %v0 = insertelement <2 x float> poison,float %a,i64 0
        \\ %v1 = insertelement <2 x float> %v0,float %b,i64 1
        \\ ret <2 x float> %v1
        \\}
    ;
    const memory = try executable(source);
    defer std.posix.munmap(memory);
    const run: *const fn (f32, f32) callconv(.c) f64 = @ptrCast(memory.ptr);
    const values = [_]u32{ 0, 0x80000000, 1, 0x7f800123, 0xffc04567 };
    for (values) |a| for (values) |b| try std.testing.expectEqual((@as(u64, b) << 32) | a, @as(u64, @bitCast(run(@bitCast(a), @bitCast(b)))));
}

test "runtime floating vectors reject explicit vector layout overrides" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define <2 x float> @packed(float %x) {
        \\entry:
        \\ %v = insertelement <2 x float> poison,float %x,i64 0
        \\ ret <2 x float> %v
        \\}
    );
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const context: @import("../machine.zig").ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = "e-v64:128" };
    try std.testing.expect((try vectors.legalize(arena.allocator(), module.functions.items[0], &context)) == null);
}

test "four lane floating inputs retain physical pieces exact payloads and six live GP prefixes" {
    const a = std.testing.allocator;
    inline for (.{ .{ "double", 64 }, .{ "fp128", 128 }, .{ "x86_fp80", 80 } }) |format| {
        const ty = format[0];
        const bits = format[1];
        const bytes = bits / 8;
        var text: std.Io.Writer.Allocating = .init(a);
        defer text.deinit();
        try text.writer.print("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\ndefine i64 @fp_pieces(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x {0s}> %a,<4 x {0s}> %b,i64 %tail,ptr %out) {{\nentry:\n store <4 x {0s}> %a,ptr %out,align 1\n %next = getelementptr i8,ptr %out,i64 {1d}\n store <4 x {0s}> %b,ptr %next,align 1\n", .{ ty, 4 * bytes });
        for (0..6) |i| {
            const previous = if (i == 0) "%tail" else try std.fmt.allocPrint(a, "%r{d}", .{i - 1});
            defer if (i != 0) a.free(previous);
            try text.writer.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n", .{ i, previous });
        }
        try text.writer.writeAll(" ret i64 %r5\n}\n");
        var module = try ir.Module.parse(a, text.written());
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const view = (try vectors.legalize(arena.allocator(), original, null)).?;
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = view;
        try private.verify();
        try std.testing.expect((try vectors.legalize(arena.allocator(), view, null)) == null);
        const context: @import("../machine.zig").ReadOnlyModuleContext = .{ .globals = module.globals.items, .aliases = module.aliases.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout, .functions = module.functions.items, .declarations = module.declarations.items };
        var selected = try compilation.select(a, "x86_64-unknown-linux-gnu", original, .{ .generic_cfg_selector = true, .module_context = &context });
        defer selected.deinit(a);
        try verify.verifyFunction(selected);
        const code = try encoding.encodeFunction(a, selected);
        defer a.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        for (0..16) |seed| {
            const prefixes = [_]u64{ 0x9182736455aaccdd ^ seed, 0xfedcba9876543211 +% seed, seed *% 0x123456789abcdef1, ~@as(u64, seed), seed, 0x8000000000000000 | seed };
            const tail = @as(u64, seed) *% 0x3456789abcdef011;
            var expected = tail;
            for (prefixes) |p| expected = (expected *% 1099511628211) ^ p;
            var output: [160]u8 = @splat(0xa5);
            var payload: [128]u8 = @splat(0);
            const result = if (bits == 64) blk: {
                const V = @Vector(2, u64);
                var pieces: [4]V = undefined;
                for (&pieces, 0..) |*piece, i| {
                    const words = [2]u64{ (@as(u64, seed) *% 0x9182736455aaccdd) ^ i, (@as(u64, i) *% 0x123456789abcdef1) ^ seed };
                    piece.* = words;
                    @memcpy(payload[i * 16 ..][0..16], std.mem.asBytes(&words));
                }
                const run: *const fn (u64, u64, u64, u64, u64, u64, V, V, V, V, u64, *u8) callconv(.c) u64 = @ptrCast(memory.ptr);
                break :blk run(prefixes[0], prefixes[1], prefixes[2], prefixes[3], prefixes[4], prefixes[5], pieces[0], pieces[1], pieces[2], pieces[3], tail, &output[8]);
            } else blk: {
                const F = if (bits == 128) f128 else f80;
                const U = if (bits == 128) u128 else u80;
                var pieces: [8]F = undefined;
                for (&pieces, 0..) |*piece, i| {
                    const raw: U = if (bits == 128) ((@as(u128, seed) *% 0x9182736455aaccdd) << 64) | (@as(u128, i) *% 0x123456789abcdef1) else (@as(u80, 0x3fff) << 64) | (@as(u80, 1) << 63) | (@as(u80, i * 17 + seed) << 40);
                    piece.* = @bitCast(raw);
                    for (0..bytes) |byte| payload[i * bytes + byte] = @truncate(raw >> @as(std.math.Log2Int(U), @intCast(byte * 8)));
                }
                const run: *const fn (u64, u64, u64, u64, u64, u64, F, F, F, F, F, F, F, F, u64, *u8) callconv(.c) u64 = @ptrCast(memory.ptr);
                break :blk run(prefixes[0], prefixes[1], prefixes[2], prefixes[3], prefixes[4], prefixes[5], pieces[0], pieces[1], pieces[2], pieces[3], pieces[4], pieces[5], pieces[6], pieces[7], tail, &output[8]);
            };
            try std.testing.expectEqual(expected, result);
            try std.testing.expectEqualSlices(u8, payload[0 .. 8 * bytes], output[8..][0 .. 8 * bytes]);
            for (output[0..8]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
            for (output[8 + 8 * bytes ..]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
        }
        try module.verify();
        try std.testing.expectEqual(@as(usize, 10), original.params.items.len);
        try std.testing.expect(original.params.items[6].ty == .vector);
    }
}
test "floating input piece calls admit optional fastcc hints and preserve source envelopes" {
    const a = std.testing.allocator;
    for ([_][]const u8{ "double", "x86_fp80", "fp128" }) |ty| for ([_][]const u8{ "tail", "notail" }) |hint| for (0..5) |variant| {
        const text = try std.fmt.allocPrint(a, "declare fastcc void @take(ptr, <4 x {0s}>)\ndefine void @probe(ptr %out,ptr %source) {{\nentry:\n %v = load <4 x {0s}>,ptr %source,align 1\n {1s} call fastcc void @take(ptr %out, <4 x {0s}> %v)\n ret void\n}}\n", .{ ty, hint });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        const call = &module.functions.items[0].blocks.items[0].instructions.items[1].kind.call;
        switch (variant) {
            0 => {},
            1 => call.tail_kind = "musttail",
            2 => call.calling_conv = null,
            3 => call.args.items[1].attrs = "inreg",
            4 => call.tail_kind = "unknown",
            else => unreachable,
        }
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const original = module.functions.items[0];
        const view = try vectors.legalize(arena.allocator(), original, null);
        try std.testing.expectEqualStrings(if (variant == 1) "musttail" else if (variant == 4) "unknown" else hint, call.tail_kind.?);
        try std.testing.expect(call.args.items[1].ty == .vector);
        if (variant != 0) {
            try std.testing.expect(view == null);
            continue;
        }
        var count: usize = 0;
        for (view.?.blocks.items) |block| for (block.instructions.items) |inst| {
            if (inst.kind != .call) continue;
            count += 1;
            try std.testing.expect(inst.kind.call.tail_kind == null);
            try std.testing.expectEqual(@as(usize, if (std.mem.eql(u8, ty, "double")) 3 else 5), inst.kind.call.args.items.len);
        };
        try std.testing.expectEqual(@as(usize, 1), count);
        const context: @import("../machine.zig").ReadOnlyModuleContext = .{ .globals = module.globals.items, .aliases = module.aliases.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout, .functions = module.functions.items, .declarations = module.declarations.items };
        var selected = try compilation.select(a, "x86_64-unknown-linux-gnu", original, .{ .generic_cfg_selector = true, .module_context = &context });
        defer selected.deinit(a);
        try verify.verifyFunction(selected);
        try module.verify();
    };
}

test "floating input pieces keep wide returns layouts ABI facts and ninth SSE argument closed" {
    const a = std.testing.allocator;
    for (0..6) |variant| {
        const input = if (variant == 0) "define <4 x double> @closed(<4 x double> %a) {\nentry:\n ret <4 x double> %a\n}\n" else if (variant == 5) "define void @closed(ptr %out,<4 x fp128> %a,<4 x fp128> %b,float %ninth) {\nentry:\n store <4 x fp128> %a,ptr %out,align 1\n ret void\n}\n" else "define void @closed(ptr %out,<4 x double> %a) {\nentry:\n store <4 x double> %a,ptr %out,align 1\n ret void\n}\n";
        var module = try ir.Module.parse(a, input);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        var context: @import("../machine.zig").ReadOnlyModuleContext = .{ .globals = module.globals.items, .aliases = module.aliases.items, .named_types = module.named_types.items, .target_datalayout = "e-m:e-p:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128", .functions = module.functions.items, .declarations = module.declarations.items };
        const f = &module.functions.items[0];
        if (variant >= 1 and variant <= 4) try std.testing.expect((try vectors.legalize(arena.allocator(), f.*, &context)) != null);
        switch (variant) {
            0 => {},
            1 => f.params.items[1].attrs = "inreg",
            2 => f.is_varargs = true,
            3 => f.params.items[1].abi_x87_memory = true,
            4 => context.target_datalayout = "e-m:e-p:64:64-v256:128-i64:64-i128:128-f80:128-n8:16:32:64-S128",
            5 => {},
            else => unreachable,
        }
        if (variant == 5) {
            const machine = @import("../machine.zig");
            const selector = @import("../generic_cfg_selector.zig");
            var output = machine.MachineFunction.init(f.name, f.ret_ty);
            defer output.deinit(a);
            const selected = try selector.tryLower(a, &output, f.*);
            try std.testing.expect(selected == .unsupported);
        } else try std.testing.expect((try vectors.legalize(arena.allocator(), f.*, &context)) == null);
    }
}

test "floating native masks preserve physical XMM payloads and ordered comparison" {
    const a = std.testing.allocator;
    inline for (.{ .{ "float", 32, 4 }, .{ "double", 64, 2 } }) |format| {
        const bits = format[1];
        const count = format[2];
        const U = if (bits == 32) u32 else u64;
        const F = if (bits == 32) f32 else f64;
        const V = @Vector(count, U);
        const text = try std.fmt.allocPrint(a, "define <{0d} x {1s}> @mask_select(<{0d} x {1s}> %a,<{0d} x {1s}> %b) {{\nentry:\n %test = fcmp olt <{0d} x {1s}> %a,%b\n %value = select <{0d} x i1> %test,<{0d} x {1s}> %a,<{0d} x {1s}> %b\n ret <{0d} x {1s}> %value\n}}\n", .{ count, format[0] });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const private = (try vectors.legalize(arena.allocator(), original, null)).?;
        var private_module = module;
        private_module.functions = try module.functions.clone(arena.allocator());
        private_module.functions.items[0] = private;
        try private_module.verify();
        try std.testing.expect((try vectors.legalize(arena.allocator(), private, null)) == null);
        var failure_tag: ?[]const u8 = null;
        var failure_detail: ?[]const u8 = null;
        var selected = compilation.select(a, "x86_64-unknown-linux-gnu", original, .{ .generic_cfg_selector = true, .generic_cfg_selector_diagnostic_tag = &failure_tag, .generic_cfg_selector_diagnostic_detail = &failure_detail }) catch |err| {
            std.debug.print("native-mask selector {s}: {s}\n", .{ failure_tag orelse "none", failure_detail orelse "none" });
            return err;
        };
        defer selected.deinit(a);
        try verify.verifyFunction(selected);
        const code = try encoding.encodeFunction(a, selected);
        defer a.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (V, V) callconv(.c) V = @ptrCast(memory.ptr);
        const sign: U = @as(U, 1) << (bits - 1);
        const infinity: U = if (bits == 32) 0x7f800000 else 0x7ff0000000000000;
        const quiet: U = infinity | (@as(U, 1) << (if (bits == 32) 22 else 51)) | 0x123;
        const one: U = @bitCast(@as(F, 1));
        const values = [_]U{ 0, sign, 1, one, sign | one, infinity, sign | infinity, quiet, sign | quiet };
        for (values, 0..) |x, i| for (values, 0..) |y, j| {
            var left: [count]U = undefined;
            var right: [count]U = undefined;
            var expected: [count]U = undefined;
            for (0..count) |lane| {
                left[lane] = if (lane == 0) x else values[(i + lane) % values.len];
                right[lane] = if (lane == 0) y else values[(j + lane) % values.len];
                const l: F = @bitCast(left[lane]);
                const r: F = @bitCast(right[lane]);
                expected[lane] = if (l < r) left[lane] else right[lane];
            }
            const actual: [count]U = run(left, right);
            try std.testing.expectEqualSlices(U, &expected, &actual);
        };
        try module.verify();
        try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.fcmp.operand_ty == .vector);
    }
}

test "floating native storage activation leaves two double quad carriers closed" {
    const a = std.testing.allocator;
    for ([_][]const u8{ "float", "double" }, [_]usize{ 4, 2 }) |ty, count| {
        const text = try std.fmt.allocPrint(a, "define void @store_native(<{0d} x {1s}> %a,ptr %out) {{\nentry:\n %home = alloca <{0d} x {1s}>,align 16\n store <{0d} x {1s}> %a,ptr %home,align 16\n %copy = load <{0d} x {1s}>,ptr %home,align 16\n store <{0d} x {1s}> %copy,ptr %out,align 1\n ret void\n}}\n", .{ count, ty });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const private = try vectors.legalize(arena.allocator(), module.functions.items[0], null);
        if (count == 2) try std.testing.expect(private == null) else try std.testing.expect(private != null);
        try module.verify();
    }
}
