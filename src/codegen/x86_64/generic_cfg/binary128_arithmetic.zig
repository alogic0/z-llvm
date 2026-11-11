//! LLVM-compatible binary128 compiler-rt calls. The separate payload pass owns
//! exact XMM transport; this pass also widens binary16 products and quotients.
const std = @import("std");
const ir = @import("../../../ir.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");
const fp_semantics = @import("../../../analysis/fp_semantics.zig");
const word: ir.Type = .{ .int = 64 };

fn negationSpelling(binary: ir.BinaryInst) bool {
    // The parser currently represents fneg with this synthetic fsub operand.
    // Preserve its exact bitwise fallback rather than introducing FP arithmetic.
    return binary.op == .fsub and binary.lhs == .fp and
        std.mem.eql(u8, binary.lhs.fp, "-0.000000e+00");
}

const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    serial: *forms.TemporaryNames,

    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.allocator, b.function, b.serial);
        try b.block.instructions.append(b.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn halfOperand(b: Builder, source: ir.Value) !ir.Value {
        if (source == .named) return b.emit(.{ .cast = .{ .op = .fpext, .from_ty = .half, .value = source, .to_ty = .float } });
        const raw = try fp_semantics.halfLiteralBits(source.fp);
        const exact: f64 = @as(f16, @bitCast(raw));
        // LLVM spells a binary32 hexadecimal literal with its exact binary64
        // encoding. Every finite binary16 value has an exact wider encoding.
        return .{ .fp = try std.fmt.allocPrint(b.allocator, "0x{X:0>16}", .{@as(u64, @bitCast(exact))}) };
    }
    fn integerArgument(b: Builder, cast: ir.CastInst) !ir.Value {
        if (!cast.from_ty.eql(.{ .int = 128 }) or cast.value != .int) return cast.value;
        const raw: u128 = @bitCast(cast.value.int);
        var words: [2]ir.Value = undefined;
        for (&words, 0..) |*value, index| {
            const part: u64 = @truncate(raw >> @as(u7, @intCast(index * 64)));
            const scalar = try b.emit(.{ .binary = .{ .op = .add, .ty = word, .lhs = .{ .int = part }, .rhs = .{ .int = 0 } } });
            value.* = try b.emit(.{ .cast = .{ .op = .zext, .from_ty = word, .value = scalar, .to_ty = cast.from_ty } });
        }
        const high = try b.emit(.{ .binary = .{ .op = .shl, .ty = cast.from_ty, .lhs = words[1], .rhs = .{ .int = 64 } } });
        return b.emit(.{ .binary = .{ .op = .@"or", .ty = cast.from_ty, .lhs = words[0], .rhs = high } });
    }
    fn extendedIntegerCast(b: Builder, original: ir.Instruction, symbol: []const u8) !void {
        const cast = original.kind.cast;
        const pair: ir.Type = .{ .int = 128 };
        if (cast.to_ty == .x86_fp80) {
            const argument = if (cast.from_ty.eql(pair)) try b.integerArgument(cast) else try b.emit(.{ .cast = .{ .op = if (cast.op == .sitofp) .sext else .zext, .from_ty = cast.from_ty, .value = cast.value, .to_ty = pair } });
            var call: ir.CallInst = .{ .callee = symbol, .ret_ty = .x86_fp80, .args = .empty };
            try call.args.append(b.allocator, .{ .ty = pair, .value = argument });
            try b.block.instructions.append(b.allocator, .{ .result = original.result, .kind = .{ .call = call } });
        } else {
            var call: ir.CallInst = .{ .callee = symbol, .ret_ty = pair, .args = .empty };
            try call.args.append(b.allocator, .{ .ty = .x86_fp80, .value = cast.value });
            if (cast.to_ty.eql(pair)) {
                try b.block.instructions.append(b.allocator, .{ .result = original.result, .kind = .{ .call = call } });
            } else {
                // Every defined narrower conversion is representable in the
                // wider helper result. Truncation retains its exact integer.
                const wide = try b.emit(.{ .call = call });
                const narrow_word = cast.to_ty.int < 64;
                const source = if (narrow_word) try b.emit(.{ .cast = .{ .op = .trunc, .from_ty = pair, .value = wide, .to_ty = word } }) else wide;
                try b.block.instructions.append(b.allocator, .{ .result = original.result, .kind = .{ .cast = .{ .op = .trunc, .from_ty = if (narrow_word) word else pair, .value = source, .to_ty = cast.to_ty } } });
            }
        }
    }
    fn floatingBridge(b: Builder, original: ir.Instruction, symbols: [2][]const u8) !void {
        const cast = original.kind.cast;
        var widen: ir.CallInst = .{ .callee = symbols[0], .ret_ty = .fp128, .args = .empty };
        try widen.args.append(b.allocator, .{ .ty = cast.from_ty, .value = cast.value });
        const exact = try b.emit(.{ .call = widen });
        var narrow: ir.CallInst = .{ .callee = symbols[1], .ret_ty = cast.to_ty, .args = .empty };
        try narrow.args.append(b.allocator, .{ .ty = .fp128, .value = exact });
        try b.block.instructions.append(b.allocator, .{ .result = original.result, .kind = .{ .call = narrow } });
    }
    fn relation(b: Builder, source: ir.FcmpInst, symbol: []const u8, predicate: ir.IcmpPredicate) !ir.Value {
        // compiler-rt's CMP_RESULT is long on the selected x86-64 SysV ABI.
        var call: ir.CallInst = .{ .callee = symbol, .ret_ty = word, .args = .empty };
        try call.args.appendSlice(b.allocator, &.{
            .{ .ty = .fp128, .value = source.lhs }, .{ .ty = .fp128, .value = source.rhs },
        });
        const ordering = try b.emit(.{ .call = call });
        return b.emit(.{ .icmp = .{ .predicate = predicate, .operand_ty = word, .lhs = ordering, .rhs = .{ .int = 0 } } });
    }
    fn comparison(b: Builder, original: ir.Instruction) !void {
        const source = original.kind.fcmp;
        const condition: ir.Value = switch (source.predicate) {
            .false => .{ .int = 0 },
            .true => .{ .int = 1 },
            .oeq => try b.relation(source, "__eqtf2", .eq),
            .une => try b.relation(source, "__eqtf2", .ne),
            .olt => try b.relation(source, "__letf2", .slt),
            .ole => try b.relation(source, "__letf2", .sle),
            .ugt => try b.relation(source, "__letf2", .sgt),
            .uge => try b.relation(source, "__letf2", .sge),
            .ogt => try b.relation(source, "__getf2", .sgt),
            .oge => try b.relation(source, "__getf2", .sge),
            .ult => try b.relation(source, "__getf2", .slt),
            .ule => try b.relation(source, "__getf2", .sle),
            .ord => try b.relation(source, "__unordtf2", .eq),
            .uno => try b.relation(source, "__unordtf2", .ne),
            .one, .ueq => blk: {
                const is_unordered = try b.relation(source, "__unordtf2", if (source.predicate == .one) .eq else .ne);
                const equal = try b.relation(source, "__eqtf2", if (source.predicate == .one) .ne else .eq);
                break :blk try b.emit(.{ .binary = .{
                    .op = if (source.predicate == .one) .@"and" else .@"or",
                    .ty = .{ .int = 1 },
                    .lhs = is_unordered,
                    .rhs = equal,
                } });
            },
        };
        const concrete = if (condition == .int) try b.emit(.{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = condition,
            .rhs = .{ .int = 0 },
        } }) else condition;
        // Keep the source identity while exposing an ordinary typed boolean.
        try b.block.instructions.append(b.allocator, .{ .result = original.result, .kind = .{ .icmp = .{
            .predicate = .ne,
            .operand_ty = .{ .int = if (condition == .int) @as(u16, 32) else 1 },
            .lhs = concrete,
            .rhs = .{ .int = 0 },
        } } });
    }
};

fn halfOperandSupported(value: ir.Value) bool {
    return switch (value) {
        .named => !std.mem.startsWith(u8, value.named, "@"),
        .fp => |text| if (fp_semantics.halfLiteralBits(text)) |_| true else |_| false,
        else => false,
    };
}

fn conversion(cast: ir.CastInst) ?[]const u8 {
    if (cast.op == .fptrunc and cast.from_ty == .double and cast.to_ty == .half) return "__truncdfhf2";
    if (cast.op == .fpext and cast.from_ty == .half and cast.to_ty == .x86_fp80) return "__extendhfxf2";
    if (cast.op == .fptrunc and cast.from_ty == .x86_fp80 and cast.to_ty == .half) return "__truncxfhf2";
    if (cast.to_ty == .fp128) {
        if (cast.op == .fpext) return switch (cast.from_ty) {
            .half => "__extendhftf2",
            .float => "__extendsftf2",
            .double => "__extenddftf2",
            .x86_fp80 => "__extendxftf2",
            else => null,
        };
        if (cast.from_ty == .int) return switch (cast.op) {
            .sitofp => switch (cast.from_ty.int) {
                32 => "__floatsitf",
                64 => "__floatditf",
                128 => "__floattitf",
                else => null,
            },
            .uitofp => switch (cast.from_ty.int) {
                32 => "__floatunsitf",
                64 => "__floatunditf",
                128 => "__floatuntitf",
                else => null,
            },
            else => null,
        };
    }
    if (cast.from_ty == .fp128) {
        if (cast.op == .fptrunc) return switch (cast.to_ty) {
            .half => "__trunctfhf2",
            .float => "__trunctfsf2",
            .double => "__trunctfdf2",
            .x86_fp80 => "__trunctfxf2",
            else => null,
        };
        if (cast.to_ty == .int) return switch (cast.op) {
            .fptosi => switch (cast.to_ty.int) {
                32 => "__fixtfsi",
                64 => "__fixtfdi",
                128 => "__fixtfti",
                else => null,
            },
            .fptoui => switch (cast.to_ty.int) {
                32 => "__fixunstfsi",
                64 => "__fixunstfdi",
                128 => "__fixunstfti",
                else => null,
            },
            else => null,
        };
    }
    return null;
}

fn extendedIntegerConversion(cast: ir.CastInst) ?[]const u8 {
    if (cast.to_ty == .x86_fp80 and cast.from_ty == .int and cast.from_ty.int > 0 and cast.from_ty.int <= 128) return switch (cast.op) {
        .sitofp => "__floattixf",
        .uitofp => "__floatuntixf",
        else => null,
    };
    if (cast.from_ty == .x86_fp80 and cast.to_ty == .int and cast.to_ty.int > 0 and cast.to_ty.int <= 128) return switch (cast.op) {
        .fptosi => "__fixxfti",
        .fptoui => "__fixunsxfti",
        else => null,
    };
    return null;
}

fn floatingBridge(cast: ir.CastInst) ?[2][]const u8 {
    if (cast.op == .fpext and cast.to_ty == .x86_fp80) return switch (cast.from_ty) {
        .float => .{ "__extendsftf2", "__trunctfxf2" },
        .double => .{ "__extenddftf2", "__trunctfxf2" },
        else => null,
    };
    if (cast.op == .fptrunc and cast.from_ty == .x86_fp80) return switch (cast.to_ty) {
        .float => .{ "__extendxftf2", "__trunctfsf2" },
        .double => .{ "__extendxftf2", "__trunctfdf2" },
        else => null,
    };
    return null;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    if (try @import("floating_signs.zig").legalize(allocator, function)) |signed| return signed;
    var candidate = Candidate.init(allocator, function);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .allocator = allocator, .function = function, .block = &block, .serial = &serial };
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null and inst.kind == .fcmp and inst.kind.fcmp.operand_ty == .half and
                halfOperandSupported(inst.kind.fcmp.lhs) and halfOperandSupported(inst.kind.fcmp.rhs))
            {
                try candidate.begin(&block, block_index, instruction_index);
                var copy = inst;
                copy.kind.fcmp.operand_ty = .float;
                copy.kind.fcmp.lhs = try b.halfOperand(inst.kind.fcmp.lhs);
                copy.kind.fcmp.rhs = try b.halfOperand(inst.kind.fcmp.rhs);
                copy.metadata = null;
                try block.instructions.append(allocator, copy);
                continue;
            }
            if (!inst.removed and inst.result != null and inst.kind == .cast) if (floatingBridge(inst.kind.cast)) |symbols| {
                if (!ir.identifiers.eql(function.name, symbols[0]) and !ir.identifiers.eql(function.name, symbols[1])) {
                    try candidate.begin(&block, block_index, instruction_index);
                    // Binary128 exactly contains every finite source value.
                    // Narrow once to the requested target without double rounding.
                    try b.floatingBridge(inst, symbols);
                    continue;
                }
            };
            if (!inst.removed and inst.result != null and inst.kind == .cast) if (extendedIntegerConversion(inst.kind.cast)) |symbol| {
                if (!ir.identifiers.eql(function.name, symbol)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    try b.extendedIntegerCast(inst, symbol);
                    continue;
                }
            };
            if (!inst.removed and inst.result != null and inst.kind == .binary and inst.kind.binary.ty == .half and
                negationSpelling(inst.kind.binary) and halfOperandSupported(inst.kind.binary.rhs))
            {
                try candidate.begin(&block, block_index, instruction_index);
                const source = inst.kind.binary.rhs;
                const raw = if (source == .named)
                    try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = .half, .value = source, .to_ty = .{ .int = 16 } } })
                else
                    try b.emit(.{ .binary = .{ .op = .add, .ty = .{ .int = 16 }, .lhs = .{ .int = try fp_semantics.halfLiteralBits(source.fp) }, .rhs = .{ .int = 0 } } });
                const flipped = try b.emit(.{ .binary = .{ .op = .xor, .ty = .{ .int = 16 }, .lhs = raw, .rhs = .{ .int = 0x8000 } } });
                var copy = inst;
                // fneg is a bit operation, including signaling NaNs and zeros.
                copy.kind = .{ .cast = .{ .op = .bitcast, .from_ty = .{ .int = 16 }, .value = flipped, .to_ty = .half } };
                copy.metadata = null;
                try block.instructions.append(allocator, copy);
                continue;
            }
            if (!inst.removed and inst.result != null and inst.kind == .binary and inst.kind.binary.ty == .half and
                (inst.kind.binary.op == .fmul or inst.kind.binary.op == .fdiv) and
                halfOperandSupported(inst.kind.binary.lhs) and halfOperandSupported(inst.kind.binary.rhs))
            {
                try candidate.begin(&block, block_index, instruction_index);
                // A finite product has at most22 significand bits and exponent
                // range[-48,31], so binary32 represents it exactly. Round once
                // back to binary16 through the existing native conversion.
                // For division the significands are integers below2048. A
                // quotient that is not exactly a half midpoint is separated
                // from it by at least1/4096 half ULP, while binary32 rounding
                // contributes at most1/16384 half ULP. Thus double rounding
                // cannot cross a half midpoint. All finite nonzero quotients
                // lie within binary32's normal exponent range.
                const product = try b.emit(.{ .binary = .{
                    .op = inst.kind.binary.op,
                    .ty = .float,
                    .lhs = try b.halfOperand(inst.kind.binary.lhs),
                    .rhs = try b.halfOperand(inst.kind.binary.rhs),
                } });
                var copy = inst;
                copy.kind = .{ .cast = .{ .op = .fptrunc, .from_ty = .float, .value = product, .to_ty = .half } };
                copy.metadata = null;
                try block.instructions.append(allocator, copy);
                continue;
            }
            if (!inst.removed and inst.kind == .fcmp and inst.kind.fcmp.operand_ty == .fp128) {
                try candidate.begin(&block, block_index, instruction_index);
                try b.comparison(inst);
                continue;
            }
            const callee: ?[]const u8 = if (inst.removed) null else switch (inst.kind) {
                .binary => |binary| if (binary.ty == .fp128) switch (binary.op) {
                    .fadd => "__addtf3",
                    .fsub => if (negationSpelling(binary)) null else "__subtf3",
                    .fmul => "__multf3",
                    .fdiv => "__divtf3",
                    else => null,
                } else null,
                .cast => |cast| conversion(cast),
                else => null,
            };
            if (callee) |symbol| {
                // A helper body must not outline its own implementation into
                // an immediate recursive call, including quoted identifiers.
                if (ir.identifiers.eql(function.name, symbol)) {
                    try candidate.keep(&block, inst);
                    continue;
                }
                try candidate.begin(&block, block_index, instruction_index);
                var call: ir.CallInst = .{ .callee = symbol, .ret_ty = inst.resultType().?, .args = .empty };
                switch (inst.kind) {
                    .binary => |binary| try call.args.appendSlice(allocator, &.{
                        .{ .ty = binary.ty, .value = binary.lhs }, .{ .ty = binary.ty, .value = binary.rhs },
                    }),
                    .cast => |cast| try call.args.append(allocator, .{ .ty = cast.from_ty, .value = try b.integerArgument(cast) }),
                    else => unreachable,
                }
                // Source-only floating assumptions cannot decorate a new call.
                try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .call = call } });
            } else try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
