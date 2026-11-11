//! Match LLVM22's baseline half-math promotion, including double FMA rounding.
const std = @import("std");
const ir = @import("../../../ir.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");
const math = @import("extended_math_intrinsics.zig");

fn binaryOperation(call: ir.CallInst) ?bool {
    const copy_sign = std.mem.eql(u8, call.callee, "llvm.copysign.f16");
    if (!copy_sign and !std.mem.eql(u8, call.callee, "llvm.maxnum.f16")) return null;
    if (call.ret_ty != .half or call.args.items.len != 2 or call.inline_asm != null or call.callee_value != null or call.callee_function_ty != null or call.raw_args != null or call.operand_bundle != null or call.calling_conv != null or call.ret_attrs != null) return null;
    if (call.tail_kind) |tail| if (std.mem.eql(u8, tail, "musttail")) return null;
    for (call.args.items) |arg| if (arg.ty != .half or arg.attrs != null or
        (arg.value != .named and arg.value != .fp and arg.value != .undef and arg.value != .poison and arg.value != .zero_initializer)) return null;
    return copy_sign;
}
const callees: [math.operations.len][]const u8 = names: {
    @setEvalBranchQuota(10000);
    var result: [math.operations.len][]const u8 = undefined;
    for (math.operations, 0..) |name, index| result[index] = std.fmt.comptimePrint("llvm.{s}.f{d}", .{ name, if (std.mem.eql(u8, name, "fma")) @as(usize, 64) else 32 });
    break :names result;
};

const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    names: *forms.TemporaryNames,
    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.allocator, b.function, b.names);
        try b.block.instructions.append(b.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn rewrite(b: Builder, original: ir.Instruction, index: usize) !void {
        const fma = std.mem.eql(u8, math.operations[index], "fma");
        const ty: ir.Type = if (fma) .double else .float;
        var call: ir.CallInst = .{ .callee = callees[index], .ret_ty = ty, .args = .empty };
        for (original.kind.call.args.items) |arg| {
            const input: ir.Value = switch (arg.value) {
                .undef, .poison, .zero_initializer => .{ .fp = "0.000000e+00" },
                else => arg.value,
            };
            var value = try @import("binary128_arithmetic.zig").materializeHalfArgument(b.allocator, b.function, b.block, b.names, input);
            if (fma) value = try b.emit(.{ .cast = .{ .op = .fpext, .from_ty = .float, .value = value, .to_ty = .double } });
            try call.args.append(b.allocator, .{ .ty = ty, .value = value });
        }
        const value = try b.emit(.{ .call = call });
        try b.block.instructions.append(b.allocator, .{ .result = original.result, .kind = .{ .cast = .{ .op = .fptrunc, .from_ty = ty, .value = value, .to_ty = .half } } });
    }

    fn binary(b: Builder, original: ir.Instruction, copy_sign: bool) !void {
        var inputs: [2]ir.Value = undefined;
        for (original.kind.call.args.items, &inputs) |arg, *input| {
            const stable: ir.Value = if (arg.value == .undef or arg.value == .poison or arg.value == .zero_initializer) .{ .fp = "0xH0000" } else arg.value;
            input.* = if (copy_sign)
                try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = .half, .value = stable, .to_ty = .{ .int = 16 } } })
            else
                try @import("binary128_arithmetic.zig").materializeHalfArgument(b.allocator, b.function, b.block, b.names, stable);
        }
        if (copy_sign) {
            const word: ir.Type = .{ .int = 16 };
            const magnitude = try b.emit(.{ .binary = .{ .op = .@"and", .ty = word, .lhs = inputs[0], .rhs = .{ .int = 32767 } } });
            const sign = try b.emit(.{ .binary = .{ .op = .@"and", .ty = word, .lhs = inputs[1], .rhs = .{ .int = 32768 } } });
            const bits = try b.emit(.{ .binary = .{ .op = .@"or", .ty = word, .lhs = magnitude, .rhs = sign } });
            try b.block.instructions.append(b.allocator, .{ .result = original.result, .kind = .{ .cast = .{ .op = .bitcast, .from_ty = word, .value = bits, .to_ty = .half } } });
        } else {
            var call: ir.CallInst = .{ .callee = "llvm.maxnum.f32", .ret_ty = .float, .args = .empty };
            for (inputs) |input| try call.args.append(b.allocator, .{ .ty = .float, .value = input });
            const result = try b.emit(.{ .call = call });
            try b.block.instructions.append(b.allocator, .{ .result = original.result, .kind = .{ .cast = .{ .op = .fptrunc, .from_ty = .float, .value = result, .to_ty = .half } } });
        }
    }
};

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var names: forms.TemporaryNames = .{};
    defer names.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        const builder: Builder = .{ .allocator = allocator, .function = function, .block = &block, .names = &names };
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null and inst.kind == .call) if (binaryOperation(inst.kind.call)) |copy_sign| {
                try candidate.begin(&block, block_index, instruction_index);
                try builder.binary(inst, copy_sign);
                continue;
            };
            if (!inst.removed and inst.result != null and inst.kind == .call) if (math.ordinaryOperation(inst.kind.call, .half, 16, true)) |index| {
                if (math.resultUsed(function, inst.result.?)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    try builder.rewrite(inst, index);
                    continue;
                }
            };
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}

test "half math promotes unary operations to float and fused multiply add to double" {
    for (math.operations, 0..) |name, index| {
        const fma = std.mem.eql(u8, name, "fma");
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare half @llvm.{s}.f16(half{s})\ndefine half @bridge(half %a,half %b,half %c) {{\nentry:\n %r = tail call noundef half @llvm.{s}.f16(half noundef %a{s})\n ret half %r\n}}\n", .{ name, if (fma) ",half,half" else "", name, if (fma) ",half %b,half %c" else "" });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const original = module.functions.items[0];
        const rewritten = (try legalize(arena.allocator(), original)).?;
        const instructions = rewritten.blocks.items[0].instructions.items;
        const call = instructions[instructions.len - 2].kind.call;
        const expected_type: ir.Type = if (fma) .double else .float;
        try std.testing.expectEqualStrings(callees[index], call.callee);
        try std.testing.expect(expected_type.eql(call.ret_ty));
        try std.testing.expectEqual(if (fma) @as(usize, 3) else 1, call.args.items.len);
        try std.testing.expectEqual(@as(usize, if (fma) 8 else 3), instructions.len);
        try std.testing.expect(expected_type.eql(instructions[instructions.len - 1].kind.cast.from_ty));
        try std.testing.expect(call.tail_kind == null and call.ret_attrs == null);
        try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.call.tail_kind != null);
        try std.testing.expect((try legalize(arena.allocator(), rewritten)) == null);
    }
}

test "half math keeps unsupported call envelopes and unused results closed" {
    for ([_][]const u8{
        "musttail call half @llvm.sin.f16(half %a)",
        "call fastcc half @llvm.sin.f16(half %a)",
        "call half @llvm.sin.f16(float 0.0)",
        "call half @llvm.sin.f16(half inreg %a)",
        "call half @llvm.fma.f16(half %a)",
        "call half @llvm.experimental.constrained.sin.f16(half %a)",
    }) |expression| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define half @closed(half %a) {{\nentry:\n %r = {s}\n ret half %r\n}}\n", .{expression});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try legalize(arena.allocator(), module.functions.items[0])) == null);
    }
    var module = try ir.Module.parse(std.testing.allocator, "define half @unused(half %a) {\nentry:\n %r = call half @llvm.sin.f16(half %a)\n ret half %a\n}\n");
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect((try legalize(arena.allocator(), module.functions.items[0])) == null);
}

test "half math promoted square roots use native scalar instructions without libm" {
    inline for (.{ f32, f64 }) |Float| {
        const bits = @bitSizeOf(Float);
        const Integer = if (bits == 32) u32 else u64;
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare {s} @llvm.sqrt.f{d}({s})\ndefine {s} @root({s} %a) {{\nentry:\n %r = call {s} @llvm.sqrt.f{d}({s} %a)\n ret {s} %r\n}}\n", .{ if (bits == 32) "float" else "double", bits, if (bits == 32) "float" else "double", if (bits == 32) "float" else "double", if (bits == 32) "float" else "double", if (bits == 32) "float" else "double", bits, if (bits == 32) "float" else "double", if (bits == 32) "float" else "double" });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const selector = @import("../generic_cfg_selector.zig");
        var output = @import("../machine.zig").MachineFunction.init("root", if (bits == 32) .float else .double);
        defer output.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]));
        try @import("../verify.zig").verifyFunction(output);
        const bytes = try @import("../../../mc/encoding.zig").encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(code);
        @memcpy(code[0..bytes.len], bytes);
        const run: *const fn (Float) callconv(.c) Float = @ptrCast(code.ptr);
        var state: u64 = 0x8123456789abcdef;
        for (0..4096) |index| {
            state ^= state << 13;
            state ^= state >> 7;
            state ^= state << 17;
            const raw: Integer = switch (index) {
                0 => 0,
                1 => @as(Integer, 1) << (bits - 1),
                2 => 1,
                3 => @bitCast(@as(Float, 1)),
                4 => @bitCast(@as(Float, -1)),
                5 => @bitCast(std.math.inf(Float)),
                else => @truncate(state),
            };
            const value: Float = @bitCast(raw);
            const expected = @sqrt(value);
            const actual = run(value);
            if (std.math.isNan(expected)) try std.testing.expect(std.math.isNan(actual)) else try std.testing.expectEqual(@as(Integer, @bitCast(expected)), @as(Integer, @bitCast(actual)));
        }
        for (output.instructions.items) |inst| try std.testing.expect(inst != .direct_call);
    }
}
