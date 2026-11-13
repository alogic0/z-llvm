//! Exact IEEE binary16/binary128 class masks through integer representation.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const sysv = @import("../sysv_abi.zig");
const word: ir.Type = .{ .int = 32 };
fn mask(call: ir.CallInst) ?i128 {
    if (call.args.items.len != 2) return null;
    const quad = call.args.items[0].ty == .fp128;
    if (!ir.identifiers.eql(call.callee, if (quad) "llvm.is.fpclass.f128" else "llvm.is.fpclass.f16") or !call.ret_ty.eql(.{ .int = 1 }) or
        (!quad and call.args.items[0].ty != .half) or !call.args.items[1].ty.eql(word) or call.args.items[1].value != .int or call.args.items[1].value.int < 0 or call.args.items[1].value.int > 1023 or
        call.callee_value != null or call.callee_function_ty != null or call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or call.calling_conv != null) return null;
    sysv.rejectUnsupportedCallEnvelope(call) catch return null;
    for (call.args.items) |arg| sysv.rejectUnsupportedCallArgAttrs(arg) catch return null;
    if (quad) for (call.args.items) |arg| if (arg.abi_x87_memory or arg.abi_split_integer) return null;
    switch (call.args.items[0].value) {
        .named => |name| if (std.mem.startsWith(u8, name, "@")) return null,
        .fp, .undef, .poison, .zero_initializer => {},
        else => return null,
    }
    return call.args.items[1].value.int;
}
const Builder = struct {
    a: std.mem.Allocator,
    f: ir.Function,
    block: *ir.BasicBlock,
    names: *forms.TemporaryNames,
    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.a, b.f, b.names);
        try b.block.instructions.append(b.a, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn bin(b: Builder, op: ir.BinaryOp, lhs: ir.Value, rhs: i128) !ir.Value {
        return b.emit(.{ .binary = .{ .op = op, .ty = word, .lhs = lhs, .rhs = .{ .int = rhs } } });
    }
    fn eq(b: Builder, lhs: ir.Value, rhs: i128) !ir.Value {
        return b.emit(.{ .icmp = .{ .predicate = .eq, .operand_ty = word, .lhs = lhs, .rhs = .{ .int = rhs } } });
    }
    fn rawAnd(b: Builder, ty: ir.Type, lhs: ir.Value, rhs: i128) !ir.Value {
        return b.emit(.{ .binary = .{ .op = .@"and", .ty = ty, .lhs = lhs, .rhs = .{ .int = rhs } } });
    }
    fn rawEq(b: Builder, ty: ir.Type, lhs: ir.Value, rhs: i128) !ir.Value {
        return b.emit(.{ .icmp = .{ .predicate = .eq, .operand_ty = ty, .lhs = lhs, .rhs = .{ .int = rhs } } });
    }
    fn choose(b: Builder, condition: ir.Value, yes: ir.Value, no: ir.Value) !ir.Value {
        return b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = condition, .ty = word, .true_value = yes, .false_value = no } });
    }
    fn signedClass(b: Builder, negative: ir.Value, negative_bit: i128, positive_bit: i128) !ir.Value {
        return b.choose(negative, .{ .int = negative_bit }, .{ .int = positive_bit });
    }
    fn classify(b: Builder, inst: ir.Instruction, bits_mask: i128) !void {
        const source = inst.kind.call.args.items[0].value;
        const quad = inst.kind.call.args.items[0].ty == .fp128;
        const raw_ty: ir.Type = if (quad) .{ .int = 128 } else word;
        const raw = if (quad) switch (source) {
            .named, .fp => try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = .fp128, .value = source, .to_ty = raw_ty } }),
            .undef, .poison, .zero_initializer => try b.emit(.{ .binary = .{ .op = .add, .ty = raw_ty, .lhs = .{ .int = 0 }, .rhs = .{ .int = 0 } } }),
            else => return error.UnsupportedHalfClassification,
        } else switch (source) {
            .named => try b.emit(.{ .cast = .{ .op = .zext, .from_ty = .{ .int = 16 }, .value = try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = .half, .value = source, .to_ty = .{ .int = 16 } } }), .to_ty = word } }),
            .fp => try b.bin(.add, .{ .int = try @import("../../../analysis/fp_semantics.zig").halfLiteralBits(source.fp) }, 0),
            .undef, .poison, .zero_initializer => try b.bin(.add, .{ .int = 0 }, 0),
            else => return error.UnsupportedHalfClassification,
        };
        const sign_mask: i128 = if (quad) std.math.minInt(i128) else 32768;
        const exponent_mask: i128 = if (quad) @as(i128, 32767) << 112 else 31744;
        const fraction_mask: i128 = if (quad) (@as(i128, 1) << 112) - 1 else 1023;
        const quiet_mask: i128 = if (quad) @as(i128, 1) << 111 else 512;
        const negative = try b.rawEq(raw_ty, try b.rawAnd(raw_ty, raw, sign_mask), sign_mask);
        const exponent = try b.rawAnd(raw_ty, raw, exponent_mask);
        const fraction = try b.rawAnd(raw_ty, raw, fraction_mask);
        const no_fraction = try b.rawEq(raw_ty, fraction, 0);
        const zero = try b.signedClass(negative, 32, 64);
        const subnormal = try b.signedClass(negative, 16, 128);
        const normal = try b.signedClass(negative, 8, 256);
        const infinity = try b.signedClass(negative, 4, 512);
        const nan = try b.choose(try b.rawEq(raw_ty, try b.rawAnd(raw_ty, fraction, quiet_mask), quiet_mask), .{ .int = 2 }, .{ .int = 1 });
        const finite = try b.choose(try b.rawEq(raw_ty, exponent, 0), try b.choose(no_fraction, zero, subnormal), normal);
        const classification = try b.choose(try b.rawEq(raw_ty, exponent, exponent_mask), try b.choose(no_fraction, infinity, nan), finite);
        const selected = try b.bin(.@"and", classification, bits_mask);
        try b.block.instructions.append(b.a, .{ .result = inst.result, .kind = .{ .icmp = .{ .predicate = .ne, .operand_ty = word, .lhs = selected, .rhs = .{ .int = 0 } } } });
    }
};
pub fn legalize(a: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var candidate = Candidate.init(a, function);
    var names: forms.TemporaryNames = .{};
    defer names.deinit(a);
    for (function.blocks.items, 0..) |original, bi| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .a = a, .f = function, .block = &block, .names = &names };
        for (original.instructions.items, 0..) |inst, ii| {
            if (!inst.removed and inst.result != null and inst.kind == .call) if (mask(inst.kind.call)) |bits_mask| {
                try candidate.begin(&block, bi, ii);
                try b.classify(inst, bits_mask);
                continue;
            };
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}

test "half and quad classification keep source masks immutable and reject invalid masks" {
    for ([_][]const u8{ "half", "fp128" }, [_]usize{ 16, 128 }) |ty, bits| for ([_]i128{ 0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1023, 1024, -1 }) |bits_mask| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare i1 @llvm.is.fpclass.f{0d}({1s},i32)\ndefine i1 @classify({1s} %value) {{\nentry:\n %r = call i1 @llvm.is.fpclass.f{0d}({1s} %value,i32 {2d})\n ret i1 %r\n}}\n", .{ bits, ty, bits_mask });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const original = module.functions.items[0];
        const result = try legalize(arena.allocator(), original);
        try std.testing.expect((result != null) == (bits_mask >= 0 and bits_mask <= 1023));
        try std.testing.expect(original.blocks.items[0].instructions.items[0].kind == .call);
    };
}

test "quad classification keeps mandatory tails dynamic masks and unproved call envelopes closed" {
    const a = std.testing.allocator;
    for (0..9) |variant| {
        var module = try ir.Module.parse(a,
            \\declare i1 @llvm.is.fpclass.f128(fp128,i32)
            \\define i1 @classify(fp128 %value) {
            \\entry:
            \\ %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 64)
            \\ ret i1 %r
            \\}
        );
        defer module.deinit();
        try module.verify();
        const call = &module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
        switch (variant) {
            0 => {},
            1 => call.tail_kind = "musttail",
            2 => call.calling_conv = "fastcc",
            3 => call.args.items[0].attrs = "inreg",
            4 => call.args.items[0].abi_x87_memory = true,
            5 => call.args.items[1].value = .{ .named = "dynamic_mask" },
            6 => call.callee_function_ty = "i1 (fp128, i32)",
            7 => call.ret_ty = word,
            8 => call.callee_value = .{ .named = "indirect" },
            else => unreachable,
        }
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const private = try legalize(arena.allocator(), module.functions.items[0]);
        try std.testing.expect((private != null) == (variant == 0));
        try std.testing.expectEqualStrings(if (variant == 1) "musttail" else "tail", call.tail_kind.?);
        try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].kind == .call);
    }
}
