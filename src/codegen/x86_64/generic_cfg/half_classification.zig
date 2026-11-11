//! Exact IEEE binary16 class masks through immutable integer representation.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const sysv = @import("../sysv_abi.zig");
const word: ir.Type = .{ .int = 32 };
fn mask(call: ir.CallInst) ?i128 {
    if (!ir.identifiers.eql(call.callee, "llvm.is.fpclass.f16") or !call.ret_ty.eql(.{ .int = 1 }) or call.args.items.len != 2 or
        call.args.items[0].ty != .half or !call.args.items[1].ty.eql(word) or call.args.items[1].value != .int or call.args.items[1].value.int < 0 or call.args.items[1].value.int > 1023 or
        call.callee_value != null or call.callee_function_ty != null or call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or call.calling_conv != null) return null;
    sysv.rejectUnsupportedCallEnvelope(call) catch return null;
    for (call.args.items) |arg| sysv.rejectUnsupportedCallArgAttrs(arg) catch return null;
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
    fn choose(b: Builder, condition: ir.Value, yes: ir.Value, no: ir.Value) !ir.Value {
        return b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = condition, .ty = word, .true_value = yes, .false_value = no } });
    }
    fn signedClass(b: Builder, negative: ir.Value, negative_bit: i128, positive_bit: i128) !ir.Value {
        return b.choose(negative, .{ .int = negative_bit }, .{ .int = positive_bit });
    }
    fn classify(b: Builder, inst: ir.Instruction, bits_mask: i128) !void {
        const source = inst.kind.call.args.items[0].value;
        const raw = switch (source) {
            .named => try b.emit(.{ .cast = .{ .op = .zext, .from_ty = .{ .int = 16 }, .value = try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = .half, .value = source, .to_ty = .{ .int = 16 } } }), .to_ty = word } }),
            .fp => try b.bin(.add, .{ .int = try @import("../../../analysis/fp_semantics.zig").halfLiteralBits(source.fp) }, 0),
            .undef, .poison, .zero_initializer => try b.bin(.add, .{ .int = 0 }, 0),
            else => return error.UnsupportedHalfClassification,
        };
        const negative = try b.eq(try b.bin(.@"and", raw, 32768), 32768);
        const exponent = try b.bin(.@"and", raw, 31744);
        const fraction = try b.bin(.@"and", raw, 1023);
        const no_fraction = try b.eq(fraction, 0);
        const zero = try b.signedClass(negative, 32, 64);
        const subnormal = try b.signedClass(negative, 16, 128);
        const normal = try b.signedClass(negative, 8, 256);
        const infinity = try b.signedClass(negative, 4, 512);
        const nan = try b.choose(try b.eq(try b.bin(.@"and", fraction, 512), 512), .{ .int = 2 }, .{ .int = 1 });
        const finite = try b.choose(try b.eq(exponent, 0), try b.choose(no_fraction, zero, subnormal), normal);
        const classification = try b.choose(try b.eq(exponent, 31744), try b.choose(no_fraction, infinity, nan), finite);
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

test "half classification keeps all source masks immutable and rejects invalid masks" {
    for ([_]i128{ 0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1023, 1024, -1 }) |bits_mask| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare i1 @llvm.is.fpclass.f16(half,i32)\ndefine i1 @classify(half %value) {{\nentry:\n %r = call i1 @llvm.is.fpclass.f16(half %value,i32 {d})\n ret i1 %r\n}}\n", .{bits_mask});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const original = module.functions.items[0];
        const result = try legalize(arena.allocator(), original);
        try std.testing.expect((result != null) == (bits_mask >= 0 and bits_mask <= 1023));
        try std.testing.expect(original.blocks.items[0].instructions.items[0].kind == .call);
    }
}
