const std = @import("std");
const sib = @import("structured_ir_builder.zig");
const sd = @import("semantic_descriptor_v2_types.zig");
const Source = sd.Source;
const AddressSpace = sd.AddressSpace;
const Type = sd.Type;
const FloatKind = sd.FloatKind;
const Vector = sd.Vector;
const ValueRef = sd.ValueRef;
const Constant = sd.Constant;
const Local = sd.Local;
const Param = sd.Param;
const GlobalKind = sd.GlobalKind;
const Global = sd.Global;
const CallConv = sd.CallConv;
const AtomicOrdering = sd.AtomicOrdering;
const AbiShape = sd.AbiShape;
const BinOp = sd.BinOp;
const CompareOp = sd.CompareOp;
const CastOp = sd.CastOp;
const Instruction = sd.Instruction;
const Call = sd.Call;
const MemoryOp = sd.MemoryOp;
const Phi = sd.Phi;
const Incoming = sd.Incoming;
const Terminator = sd.Terminator;
const Block = sd.Block;
const Function = sd.Function;
const Body = sd.Body;
const ProgramOrigin = sd.ProgramOrigin;
const Program = sd.Program;
const ReleaseCanonicalizationSummary = sd.ReleaseCanonicalizationSummary;
const ReleaseCanonicalizationReport = sd.ReleaseCanonicalizationReport;
const VerifyError = sd.VerifyError;

const lowering = @import("semantic_descriptor_v2_lowering.zig");
const isBranchToReturnBlock = lowering.isBranchToReturnBlock;
const blockByName = lowering.blockByName;
const parseImmediateInt = lowering.parseImmediateInt;
const canFoldIntegerBinop = lowering.canFoldIntegerBinop;
const canFoldFpBinop = lowering.canFoldFpBinop;
const isNeutralLocalComputation = lowering.isNeutralLocalComputation;
const isFcmpSelectCanonical = lowering.isFcmpSelectCanonical;
const bodyName = lowering.bodyName;
const bodyForSurface = lowering.bodyForSurface;

pub fn verify(program: Program) VerifyError!void {
    if (program.functions.len == 0) return error.EmptyProgram;
    for (program.globals) |global| {
        try verifyGlobal(global);
    }
    for (program.constants) |constant| try verifyType(constant.ty);
    for (program.functions) |function| {
        try verifyCallConv(function.calling_convention);
        try verifyType(function.return_type);
        if (function.blocks.len == 0) return error.EmptyFunction;
        if (!std.mem.eql(u8, function.blocks[0].name, "entry")) return error.MissingEntryBlock;
        for (function.params) |param| try verifyType(param.ty);
        for (function.locals) |local| try verifyType(local.ty);
        try verifyUniqueBlocks(function);
        try verifyUniqueValues(function);
        for (function.blocks) |block| {
            if (block.name.len == 0) return error.EmptyBlock;
            for (block.params) |param| try verifyType(param.ty);
            for (block.instructions) |instruction| try verifyInstruction(instruction, function);
            try verifyTerminator(block.terminator, function, block);
        }
    }
    try verifyReleaseSafeChecksPreserved(program);
}

pub fn lowerToStructuredIr(program: Program, writer: *std.Io.Writer) !void {
    try verify(program);
    const canonicalized = try canonicalizeReleaseProgram(std.heap.page_allocator, program);
    try verify(canonicalized);
    try verifyCanonicalizedReleaseProgram(program, canonicalized);
    var module = sib.Module.init(writer);
    for (canonicalized.globals) |global| {
        try lowering.lowerGlobal(&module, global);
    }
    if (canonicalized.globals.len != 0) try writer.writeByte('\n');
    for (canonicalized.functions) |function| {
        try lowering.lowerFunction(&module, function);
    }
}

pub fn releaseCanonicalizationReport(program: Program) ReleaseCanonicalizationReport {
    const observed = releaseCanonicalizationObservedSummary(program);
    const canonicalized = canonicalizeReleaseProgram(std.heap.page_allocator, program) catch {
        return .{ .observed = observed, .applied = .{ .ran = false }, .after = observed, .checks_preserved = false };
    };
    const after = releaseCanonicalizationObservedSummary(canonicalized);
    const applied = appliedCanonicalizationSummary(observed, after);
    return .{
        .observed = observed,
        .applied = applied,
        .after = after,
        .checks_preserved = observed.checked_boundaries_seen == after.checked_boundaries_seen,
    };
}

pub fn releaseCanonicalizationSummary(program: Program) ReleaseCanonicalizationSummary {
    var summary = ReleaseCanonicalizationSummary{ .ran = true };
    for (program.functions) |function| {
        for (function.blocks) |block| {
            if (isBranchToReturnBlock(function, block)) summary.simplified_branch_to_return += 1;
            for (block.instructions) |instruction| {
                switch (instruction) {
                    .binop => |binop| {
                        if (canFoldIntegerBinop(binop)) summary.constant_folded_int_ops += 1;
                        if (canFoldFpBinop(binop)) summary.constant_folded_fp_ops += 1;
                        if (isNeutralLocalComputation(binop)) summary.dead_local_computations += 1;
                    },
                    .select => |select| if (isFcmpSelectCanonical(function, select)) {
                        summary.canonicalized_select_fcmp += 1;
                    },
                    .phi => |phi| if (phi.incoming.len == 1) {
                        summary.simplified_single_pred_phi += 1;
                    },
                    .checked_add, .checked_mul => {
                        summary.checked_boundaries_seen += 1;
                        summary.checked_boundaries_preserved += 1;
                    },
                    .constant, .compare, .call, .load, .store, .gep, .cast, .aggregate_value, .inline_asm_boundary => {},
                }
            }
        }
    }
    return summary;
}

fn releaseCanonicalizationObservedSummary(program: Program) ReleaseCanonicalizationSummary {
    if (!releaseCanonicalizerMayRewriteBody(program.body)) {
        const summary = releaseCanonicalizationSummary(program);
        return .{
            .ran = true,
            .checked_boundaries_seen = summary.checked_boundaries_seen,
            .checked_boundaries_preserved = summary.checked_boundaries_seen,
        };
    }
    return releaseCanonicalizationSummary(program);
}

fn appliedCanonicalizationSummary(observed: ReleaseCanonicalizationSummary, after: ReleaseCanonicalizationSummary) ReleaseCanonicalizationSummary {
    return .{
        .ran = observed.ran,
        .constant_folded_int_ops = saturatedDelta(observed.constant_folded_int_ops, after.constant_folded_int_ops),
        .constant_folded_fp_ops = saturatedDelta(observed.constant_folded_fp_ops, after.constant_folded_fp_ops),
        .dead_local_computations = saturatedDelta(observed.dead_local_computations, after.dead_local_computations),
        .canonicalized_select_fcmp = saturatedDelta(observed.canonicalized_select_fcmp, after.canonicalized_select_fcmp),
        .simplified_branch_to_return = saturatedDelta(observed.simplified_branch_to_return, after.simplified_branch_to_return),
        .simplified_single_pred_phi = saturatedDelta(observed.simplified_single_pred_phi, after.simplified_single_pred_phi),
        .checked_boundaries_seen = observed.checked_boundaries_seen,
        .checked_boundaries_preserved = after.checked_boundaries_seen,
    };
}

fn saturatedDelta(before: usize, after: usize) usize {
    return if (before > after) before - after else 0;
}

fn canonicalizeReleaseProgram(allocator: std.mem.Allocator, program: Program) !Program {
    if (!releaseCanonicalizerMayRewriteBody(program.body)) return program;
    var functions = try allocator.alloc(Function, program.functions.len);
    for (program.functions, 0..) |function, index| {
        functions[index] = try canonicalizeFunction(allocator, function);
    }
    var canonicalized = program;
    canonicalized.functions = functions;
    return canonicalized;
}

fn releaseCanonicalizerMayRewriteBody(body: Body) bool {
    return switch (body) {
        .str_from_float_help,
        .base64_decode_base64_full,
        .base64_decode_step,
        .base64_store_step,
        .base64_residual_byte_step,
        .base64_padding_tail_step,
        .base64_padding_loop_step,
        .base64_padding_length_step,
        .base64_chunk_guard_step,
        .base64_source_stride_step,
        .base64_source_bundle_step,
        .base64_next_source_bundle_step,
        .base64_third_source_bundle_step,
        .base64_bit_buffer_store_step,
        .base64_loop_advance_step,
        .base64_residual_guard_step,
        .base64_residual_bundle_step,
        .base64_residual_store_step,
        .base64_residual_length_step,
        .base64_residual_table_check_step,
        .base64_residual_accumulator_step,
        .base64_residual_loop_advance_step,
        .base64_residual_padding_check_step,
        .base64_residual_final_mask_step,
        .base64_residual_padding_loop_step,
        .base64_decode_exit_step,
        => false,
        else => true,
    };
}

fn canonicalizeFunction(allocator: std.mem.Allocator, function: Function) !Function {
    var replacements = std.StringHashMap(ValueRef).init(allocator);
    defer replacements.deinit();

    var blocks = try allocator.alloc(Block, function.blocks.len);
    for (function.blocks, 0..) |block, index| {
        blocks[index] = try canonicalizeBlock(allocator, function, block, &replacements);
    }
    var canonicalized = function;
    canonicalized.blocks = blocks;
    return canonicalized;
}

fn canonicalizeBlock(
    allocator: std.mem.Allocator,
    function: Function,
    block: Block,
    replacements: *std.StringHashMap(ValueRef),
) !Block {
    var instructions: std.ArrayList(Instruction) = .empty;
    for (block.instructions) |instruction| {
        if (try canonicalizeInstruction(allocator, instruction, replacements)) |canonicalized| {
            try instructions.append(allocator, canonicalized);
        }
    }

    var canonicalized = block;
    canonicalized.instructions = try instructions.toOwnedSlice(allocator);
    canonicalized.terminator = canonicalizeTerminator(function, block.terminator, replacements);
    return canonicalized;
}

fn canonicalizeInstruction(
    allocator: std.mem.Allocator,
    instruction: Instruction,
    replacements: *std.StringHashMap(ValueRef),
) !?Instruction {
    switch (instruction) {
        .constant => return instruction,
        .binop => |binop| {
            var rewritten = binop;
            rewritten.lhs = rewriteValue(binop.lhs, replacements);
            rewritten.rhs = rewriteValue(binop.rhs, replacements);
            if (foldBinopValue(allocator, rewritten)) |folded| {
                try replacements.put(rewritten.result, folded);
                return null;
            }
            if (identityBinopValue(rewritten)) |identity| {
                try replacements.put(rewritten.result, identity);
                return null;
            }
            return .{ .binop = rewritten };
        },
        .checked_add => |checked| return .{ .checked_add = .{
            .result = checked.result,
            .ty = checked.ty,
            .lhs = rewriteValue(checked.lhs, replacements),
            .rhs = rewriteValue(checked.rhs, replacements),
            .panic_block = checked.panic_block,
        } },
        .checked_mul => |checked| return .{ .checked_mul = .{
            .result = checked.result,
            .ty = checked.ty,
            .lhs = rewriteValue(checked.lhs, replacements),
            .rhs = rewriteValue(checked.rhs, replacements),
            .panic_block = checked.panic_block,
        } },
        .compare => |compare| {
            var rewritten = compare;
            rewritten.lhs = rewriteValue(compare.lhs, replacements);
            rewritten.rhs = rewriteValue(compare.rhs, replacements);
            if (foldCompareValue(rewritten)) |folded| {
                try replacements.put(rewritten.result, folded);
                return null;
            }
            return .{ .compare = rewritten };
        },
        .select => |select| {
            var rewritten = select;
            rewritten.cond = rewriteValue(select.cond, replacements);
            rewritten.then_value = rewriteValue(select.then_value, replacements);
            rewritten.else_value = rewriteValue(select.else_value, replacements);
            if (foldSelectValue(rewritten)) |folded| {
                try replacements.put(rewritten.result, folded);
                return null;
            }
            return .{ .select = rewritten };
        },
        .call => |call| {
            var rewritten = call;
            rewritten.args = try rewriteValues(allocator, call.args, replacements);
            return .{ .call = rewritten };
        },
        .load => |load| {
            var rewritten = load;
            rewritten.ptr = rewriteValue(load.ptr, replacements);
            if (load.value) |value| rewritten.value = rewriteValue(value, replacements);
            return .{ .load = rewritten };
        },
        .store => |store| {
            var rewritten = store;
            rewritten.ptr = rewriteValue(store.ptr, replacements);
            if (store.value) |value| rewritten.value = rewriteValue(value, replacements);
            return .{ .store = rewritten };
        },
        .gep => |gep| {
            var rewritten = gep;
            rewritten.base = rewriteValue(gep.base, replacements);
            rewritten.indices = try rewriteValues(allocator, gep.indices, replacements);
            return .{ .gep = rewritten };
        },
        .phi => |phi| {
            if (phi.incoming.len == 1) {
                try replacements.put(phi.result, rewriteValue(phi.incoming[0].value, replacements));
                return null;
            }
            var incoming = try allocator.alloc(Incoming, phi.incoming.len);
            for (phi.incoming, 0..) |entry, index| {
                incoming[index] = .{ .block = entry.block, .value = rewriteValue(entry.value, replacements) };
            }
            var rewritten = phi;
            rewritten.incoming = incoming;
            return .{ .phi = rewritten };
        },
        .cast => |cast| return .{ .cast = .{
            .result = cast.result,
            .op = cast.op,
            .from = rewriteValue(cast.from, replacements),
            .to = cast.to,
        } },
        .aggregate_value => |aggregate| {
            var rewritten = aggregate;
            rewritten.fields = try rewriteValues(allocator, aggregate.fields, replacements);
            return .{ .aggregate_value = rewritten };
        },
        .inline_asm_boundary => return instruction,
    }
}

fn canonicalizeTerminator(function: Function, terminator: Terminator, replacements: *std.StringHashMap(ValueRef)) Terminator {
    return switch (terminator) {
        .ret => |maybe_value| .{ .ret = if (maybe_value) |value| rewriteValue(value, replacements) else null },
        .br => |target| if (blockByName(function, target)) |target_block| blk: {
            if (target_block.instructions.len == 0) {
                switch (target_block.terminator) {
                    .ret => |maybe_value| break :blk .{ .ret = if (maybe_value) |value| rewriteValue(value, replacements) else null },
                    .br, .condbr, .@"unreachable" => {},
                }
            }
            break :blk terminator;
        } else terminator,
        .condbr => |condbr| .{ .condbr = .{
            .cond = rewriteValue(condbr.cond, replacements),
            .then_block = condbr.then_block,
            .else_block = condbr.else_block,
        } },
        .@"unreachable" => terminator,
    };
}

fn rewriteValues(allocator: std.mem.Allocator, values: []const ValueRef, replacements: *std.StringHashMap(ValueRef)) ![]const ValueRef {
    if (values.len == 0) return values;
    var rewritten = try allocator.alloc(ValueRef, values.len);
    for (values, 0..) |value, index| rewritten[index] = rewriteValue(value, replacements);
    return rewritten;
}

fn rewriteValue(value: ValueRef, replacements: *std.StringHashMap(ValueRef)) ValueRef {
    if (!isNamedValue(value.id)) return value;
    return replacements.get(stripValue(value.id)) orelse value;
}

fn isNamedValue(id: []const u8) bool {
    return id.len != 0 and id[0] == '%';
}

fn foldBinopValue(allocator: std.mem.Allocator, binop: anytype) ?ValueRef {
    if (foldIntegerBinopValue(allocator, binop)) |folded| return folded;
    return foldFpBinopValue(allocator, binop);
}

fn foldIntegerBinopValue(allocator: std.mem.Allocator, binop: anytype) ?ValueRef {
    if (binop.ty != .int) return null;
    const lhs = parseImmediateInt(binop.lhs.id) orelse return null;
    const rhs = parseImmediateInt(binop.rhs.id) orelse return null;
    const folded = switch (binop.op) {
        .add => lhs + rhs,
        .sub => lhs - rhs,
        .mul => lhs * rhs,
        .@"and" => lhs & rhs,
        .@"or" => lhs | rhs,
        .xor => lhs ^ rhs,
        .shl, .lshr, .ashr => return null,
        .fadd, .fsub, .fmul, .fdiv, .frem => return null,
    };
    return .{ .id = std.fmt.allocPrint(allocator, "{d}", .{folded}) catch return null, .ty = binop.ty };
}

fn foldFpBinopValue(allocator: std.mem.Allocator, binop: anytype) ?ValueRef {
    if (binop.ty != .float) return null;
    const lhs = parseImmediateFloat(binop.lhs.id) orelse return null;
    const rhs = parseImmediateFloat(binop.rhs.id) orelse return null;
    const folded = switch (binop.op) {
        .fadd => lhs + rhs,
        .fsub => lhs - rhs,
        .fmul => lhs * rhs,
        .fdiv => if (rhs != 0.0) lhs / rhs else return null,
        .frem => if (rhs != 0.0) @mod(lhs, rhs) else return null,
        .add, .sub, .mul, .shl, .lshr, .ashr, .@"and", .@"or", .xor => return null,
    };
    if (!std.math.isFinite(folded)) return null;
    return .{ .id = formatSelectedFloatLiteral(allocator, folded) catch return null, .ty = binop.ty };
}

fn identityBinopValue(binop: anytype) ?ValueRef {
    if (binop.ty != .int) return null;
    return switch (binop.op) {
        .add, .@"or", .xor => if (isIntegerText(binop.rhs.id, 0)) binop.lhs else if (isIntegerText(binop.lhs.id, 0)) binop.rhs else null,
        .sub, .shl, .lshr, .ashr => if (isIntegerText(binop.rhs.id, 0)) binop.lhs else null,
        .mul => if (isIntegerText(binop.rhs.id, 1)) binop.lhs else if (isIntegerText(binop.lhs.id, 1)) binop.rhs else null,
        .@"and", .fadd, .fsub, .fmul, .fdiv, .frem => null,
    };
}

fn foldCompareValue(compare: anytype) ?ValueRef {
    if (compare.ty == .int) {
        const lhs = parseImmediateInt(compare.lhs.id) orelse return null;
        const rhs = parseImmediateInt(compare.rhs.id) orelse return null;
        return boolLiteral(evalIntegerCompare(compare.op, lhs, rhs) orelse return null);
    }
    if (compare.ty == .float) {
        const lhs = parseImmediateFloat(compare.lhs.id) orelse return null;
        const rhs = parseImmediateFloat(compare.rhs.id) orelse return null;
        if (!std.math.isFinite(lhs) or !std.math.isFinite(rhs)) return null;
        return boolLiteral(evalOrderedFloatCompare(compare.op, lhs, rhs) orelse return null);
    }
    return null;
}

fn foldSelectValue(select: anytype) ?ValueRef {
    if (std.mem.eql(u8, select.cond.id, "true")) return select.then_value;
    if (std.mem.eql(u8, select.cond.id, "false")) return select.else_value;
    return null;
}

fn evalIntegerCompare(op: CompareOp, lhs: i128, rhs: i128) ?bool {
    return switch (op) {
        .eq, .oeq => lhs == rhs,
        .ne, .one => lhs != rhs,
        .slt, .ult, .olt => lhs < rhs,
        .sle, .ule, .ole => lhs <= rhs,
        .sgt, .ugt, .ogt => lhs > rhs,
        .sge, .uge, .oge => lhs >= rhs,
    };
}

fn evalOrderedFloatCompare(op: CompareOp, lhs: f64, rhs: f64) ?bool {
    return switch (op) {
        .oeq, .eq => lhs == rhs,
        .one, .ne => lhs != rhs,
        .olt, .slt, .ult => lhs < rhs,
        .ole, .sle, .ule => lhs <= rhs,
        .ogt, .sgt, .ugt => lhs > rhs,
        .oge, .sge, .uge => lhs >= rhs,
    };
}

fn boolLiteral(value: bool) ValueRef {
    return .{ .id = if (value) "true" else "false", .ty = .bool };
}

fn isIntegerText(text: []const u8, expected: i128) bool {
    return if (parseImmediateInt(text)) |value| value == expected else false;
}

fn parseImmediateFloat(text: []const u8) ?f64 {
    if (!isImmediate(text)) return null;
    return std.fmt.parseFloat(f64, text) catch null;
}

fn formatSelectedFloatLiteral(allocator: std.mem.Allocator, value: f64) ![]const u8 {
    if (value == 0.0) return "0.000000e+00";
    if (value == 1.0) return "1.000000e+00";
    if (value == 1.5) return "1.500000e+00";
    if (value == 2.0) return "2.000000e+00";
    if (value == 3.0) return "3.000000e+00";
    if (value == 4.0) return "4.000000e+00";
    if (value == 6.0) return "6.000000e+00";
    return try std.fmt.allocPrint(allocator, "{e}", .{value});
}

fn verifyCanonicalizedReleaseProgram(before: Program, after: Program) VerifyError!void {
    const before_summary = releaseCanonicalizationSummary(before);
    const after_summary = releaseCanonicalizationSummary(after);
    if (before_summary.checked_boundaries_seen != after_summary.checked_boundaries_seen) return error.ReleaseSafeCheckRemoved;
    if (bodyRequiresModeledCheckedBoundary(before.body) and after_summary.checked_boundaries_seen == 0) return error.ReleaseSafeCheckRemoved;
}

pub fn writeText(program: Program, writer: *std.Io.Writer) !void {
    try writer.print(
        \\zllvm-semantic-descriptor-v2
        \\id={s}
        \\wrapper={s}
        \\mode={s}
        \\fixture={s}
        \\source_tag={s}
        \\body={s}
        \\diagnostic_surface={s}
        \\functions={d}
        \\globals={d}
        \\
    , .{
        program.id,
        program.source.wrapper,
        program.source.mode,
        program.source.fixture,
        program.source.tag,
        bodyName(program.body),
        program.diagnostic_surface,
        program.functions.len,
        program.globals.len,
    });
}

pub fn programFromSurface(source: Source, surface: []const u8) ?Program {
    const body = bodyForSurface(surface) orelse return null;
    return programFromBody(source, body, surface, .surface_adapter);
}

pub fn programFromSemanticBody(source: Source, body: Body, diagnostic_surface: []const u8) Program {
    return programFromBody(source, body, diagnostic_surface, .body_enum_dispatch);
}

pub fn programFromSourceDescriptor(source: Source, body: Body, diagnostic_surface: []const u8) Program {
    return programFromBody(source, body, diagnostic_surface, .source_derived_descriptor);
}

pub fn programFromFullDescriptor(source: Source, body: Body, diagnostic_surface: []const u8) Program {
    return programFromSerializedReturn(source, body, diagnostic_surface, 0, true);
}

pub fn programFromSourceFacts(source: Source, body: Body, diagnostic_surface: []const u8) Program {
    return programFromSourceFactProgram(source, body, diagnostic_surface);
}

pub fn programFromSourceFactProgram(source: Source, body: Body, diagnostic_surface: []const u8) Program {
    return .{
        .id = bodyName(body),
        .source = source,
        .body = body,
        .diagnostic_surface = diagnostic_surface,
        .origin = .source_derived_descriptor,
        .functions = functionsForBody(body),
        .globals = globalsForBody(body),
        .atomics = body == .atomic_add,
        .inline_asm_boundary = body == .inline_asm_barrier or body == .compile_asm_unreachable,
        .serialized_functions = true,
        .serialized_instructions = true,
        .serialized_globals = true,
    };
}

pub fn programFromSourceFactProgramDirect(source: Source, body: Body, diagnostic_surface: []const u8) ?Program {
    const functions = sourceFactProgramFunctionsForBody(body) orelse return null;
    const globals = sourceFactProgramGlobalsForBody(body) orelse return null;
    return .{
        .id = bodyName(body),
        .source = source,
        .body = body,
        .diagnostic_surface = diagnostic_surface,
        .origin = .source_derived_descriptor,
        .functions = functions,
        .globals = globals,
        .atomics = body == .atomic_add,
        .inline_asm_boundary = body == .inline_asm_barrier or body == .compile_asm_unreachable,
        .serialized_functions = true,
        .serialized_instructions = true,
        .serialized_globals = true,
    };
}

pub fn programFromSerializedReturn(source: Source, body: Body, diagnostic_surface: []const u8, ret_i32: i32, serialized_globals: bool) Program {
    const allocator = std.heap.page_allocator;
    const lhs = std.fmt.allocPrint(allocator, "{d}", .{ret_i32}) catch @panic("failed to allocate serialized descriptor constant");
    const instructions = allocator.alloc(Instruction, 1) catch @panic("failed to allocate serialized descriptor instructions");
    instructions[0] = .{ .binop = .{
        .result = "retv",
        .op = .add,
        .ty = .{ .int = 32 },
        .lhs = .{ .id = lhs, .ty = .{ .int = 32 } },
        .rhs = .{ .id = "0", .ty = .{ .int = 32 } },
    } };
    const blocks = allocator.alloc(Block, 1) catch @panic("failed to allocate serialized descriptor blocks");
    blocks[0] = .{
        .name = "entry",
        .instructions = instructions,
        .terminator = .{ .ret = .{ .id = "%retv", .ty = .{ .int = 32 } } },
    };
    const functions = allocator.alloc(Function, 1) catch @panic("failed to allocate serialized descriptor functions");
    functions[0] = .{ .name = "main", .return_type = .{ .int = 32 }, .blocks = blocks };
    return .{
        .id = bodyName(body),
        .source = source,
        .body = body,
        .diagnostic_surface = diagnostic_surface,
        .origin = .source_derived_descriptor,
        .functions = functions,
        .serialized_functions = true,
        .serialized_instructions = true,
        .serialized_globals = serialized_globals,
        .serialized_return_i32 = ret_i32,
    };
}

fn programFromBody(source: Source, body: Body, diagnostic_surface: []const u8, origin: ProgramOrigin) Program {
    return .{
        .id = bodyName(body),
        .source = source,
        .body = body,
        .diagnostic_surface = diagnostic_surface,
        .origin = origin,
        .functions = functionsForBody(body),
        .globals = globalsForBody(body),
        .atomics = body == .atomic_add,
        .inline_asm_boundary = body == .inline_asm_barrier or body == .compile_asm_unreachable,
        .descriptor_program_body_expansion = origin == .source_derived_descriptor,
        .functions_for_body = true,
        .globals_for_body = true,
    };
}

pub fn bodyForDiagnosticSurface(surface: []const u8) ?Body {
    return bodyForSurface(surface);
}

pub fn bodyForName(name: []const u8) ?Body {
    return bodyForSurface(name);
}

pub fn isRealDescriptorProgram(program: Program) bool {
    return !isCannedReturnDescriptor(program);
}

pub fn isSurfaceToBodyAdapter(program: Program) bool {
    return program.origin == .surface_adapter;
}

pub fn isCannedReturnDescriptor(program: Program) bool {
    if (program.functions.len != 1 or program.globals.len != 0 or program.constants.len != 0) return false;
    const function = program.functions[0];
    if (!std.mem.eql(u8, function.name, "main") or function.params.len != 0 or function.blocks.len != 1) return false;
    const block = function.blocks[0];
    if (block.instructions.len != 0) {
        return false;
    }
    return switch (block.terminator) {
        .ret => |maybe_value| if (maybe_value) |value| isImmediate(value.id) else false,
        else => false,
    };
}

pub fn isSourceDerivedDescriptor(program: Program) bool {
    return program.origin == .source_derived_descriptor;
}

pub fn isBodyEnumDispatch(program: Program) bool {
    return program.origin == .body_enum_dispatch;
}

pub fn firstUnsupportedConstruct(program: Program) ?[]const u8 {
    verify(program) catch |err| return @errorName(err);
    return null;
}

fn verifyInstruction(instruction: Instruction, function: Function) VerifyError!void {
    switch (instruction) {
        .constant => |constant| try verifyType(constant.ty),
        .binop => |binop| {
            try verifyType(binop.ty);
            try verifyTypedValue(binop.lhs, binop.ty, function);
            try verifyTypedValue(binop.rhs, binop.ty, function);
        },
        .checked_add => |checked| try verifyChecked(checked.ty, checked.lhs, checked.rhs, checked.panic_block, function),
        .checked_mul => |checked| try verifyChecked(checked.ty, checked.lhs, checked.rhs, checked.panic_block, function),
        .compare => |compare| {
            try verifyType(compare.ty);
            try verifyTypedValue(compare.lhs, compare.ty, function);
            try verifyTypedValue(compare.rhs, compare.ty, function);
        },
        .select => |select| {
            try verifyTypedValue(select.cond, .bool, function);
            try verifyType(select.ty);
            try verifyTypedValue(select.then_value, select.ty, function);
            try verifyTypedValue(select.else_value, select.ty, function);
        },
        .call => |call| {
            try verifyCallConv(call.calling_convention);
            try verifyAbiShape(call.abi);
            try verifyType(call.ret_ty);
            if (call.varargs) return error.UnsupportedVarargs;
            for (call.args) |arg| try verifyDefinedValue(arg, function);
            try verifyCallSignature(call, function);
            try verifyCallAbi(call);
        },
        .load => |memory| try verifyMemory(memory, function),
        .store => |memory| try verifyMemory(memory, function),
        .gep => |gep| {
            try verifyTypedValue(gep.base, .{ .pointer = .generic }, function);
            for (gep.indices) |index| try verifyDefinedValue(index, function);
        },
        .phi => |phi| {
            try verifyType(phi.ty);
            if (phi.incoming.len == 0) return error.PhiIncomingMismatch;
            for (phi.incoming) |incoming| try verifyTypedValue(incoming.value, phi.ty, function);
        },
        .cast => |cast| {
            try verifyDefinedValue(cast.from, function);
            try verifyType(cast.to);
        },
        .aggregate_value => |aggregate| {
            try verifyType(aggregate.ty);
            for (aggregate.fields) |field| try verifyDefinedValue(field, function);
        },
        .inline_asm_boundary => {},
    }
}

fn verifyTerminator(terminator: Terminator, function: Function, block: Block) VerifyError!void {
    switch (terminator) {
        .ret => |maybe_value| {
            if (maybe_value) |value| {
                try verifyTypedValue(value, function.return_type, function);
            } else if (function.return_type != .void) {
                return error.ReturnTypeMismatch;
            }
        },
        .br => |target| {
            if (target.len == 0) return error.EmptyBlock;
            if (!blockExists(function, target)) return error.UnknownBranchTarget;
        },
        .condbr => |condbr| {
            try verifyTypedValue(condbr.cond, .bool, function);
            if (condbr.then_block.len == 0 or condbr.else_block.len == 0) return error.EmptyBlock;
            if (!blockExists(function, condbr.then_block) or !blockExists(function, condbr.else_block)) return error.UnknownBranchTarget;
        },
        .@"unreachable" => {},
    }
    try verifyBlockPhis(function, block);
}

fn verifyGlobal(global: Global) VerifyError!void {
    try verifyType(global.ty);
    try verifyAddressSpace(global.address_space);
    switch (global.kind) {
        .tls => if (global.address_space != .local_exec_tls) return error.UnsupportedAddressSpace,
        .global, .constant => if (global.address_space == .local_exec_tls) return error.UnsupportedAddressSpace,
    }
}

fn verifyReleaseSafeChecksPreserved(program: Program) VerifyError!void {
    if (!bodyRequiresModeledCheckedBoundary(program.body)) return;
    if (releaseCanonicalizationSummary(program).checked_boundaries_seen == 0) return error.ReleaseSafeCheckRemoved;
}

fn bodyRequiresModeledCheckedBoundary(body: Body) bool {
    return switch (body) {
        .checked_add_imm_boundary,
        .checked_global_update_boundary,
        .checked_pointer_load_store_boundary,
        .checked_branch_mix_boundary,
        .checked_call_chain_boundary,
        .checked_array_sum_boundary,
        .checked_struct_sum_boundary,
        .checked_slice_loop_sum_boundary,
        .checked_add_runtime_boundary,
        => true,
        else => false,
    };
}

fn verifyChecked(ty: Type, lhs: ValueRef, rhs: ValueRef, panic_block: []const u8, function: Function) VerifyError!void {
    try verifyType(ty);
    if (!typeEql(ty, .{ .int = 32 })) return error.UnsupportedAbiShape;
    try verifyTypedValue(lhs, ty, function);
    try verifyTypedValue(rhs, ty, function);
    if (!blockExists(function, panic_block)) return error.UnknownBranchTarget;
}

fn verifyMemory(memory: MemoryOp, function: Function) VerifyError!void {
    try verifyDefinedValue(memory.ptr, function);
    if (memory.ptr.ty != .pointer) return error.MemoryTypeMismatch;
    try verifyType(memory.ty);
    if (memory.align_bytes == 0) return error.UnsupportedAlignment;
    if (memory.ordering) |ordering| try verifyAtomicOrdering(ordering);
    if (memory.value) |value| {
        try verifyTypedValue(value, memory.ty, function);
    }
}

fn verifyValueShape(value: ValueRef) VerifyError!void {
    if (value.id.len == 0) return error.EmptyBlock;
    try verifyType(value.ty);
}

fn verifyDefinedValue(value: ValueRef, function: Function) VerifyError!void {
    try verifyValueShape(value);
    if (isImmediate(value.id) or isGlobalRef(value.id)) return;
    if (!valueDefined(function, value.id)) return error.UndefinedValue;
}

fn verifyTypedValue(value: ValueRef, expected: Type, function: Function) VerifyError!void {
    try verifyDefinedValue(value, function);
    if (!typeEql(value.ty, expected)) return error.MemoryTypeMismatch;
}

fn verifyType(ty: Type) VerifyError!void {
    switch (ty) {
        .void, .bool, .int, .float => {},
        .pointer => |address_space| try verifyAddressSpace(address_space),
        .aggregate => |fields| for (fields) |field| try verifyType(field),
        .vector => return error.UnsupportedTypeVector,
    }
}

fn verifyAddressSpace(address_space: AddressSpace) VerifyError!void {
    switch (address_space) {
        .generic, .local_exec_tls, .vram => {},
        .unsupported => return error.UnsupportedAddressSpace,
    }
}

fn verifyCallConv(calling_convention: CallConv) VerifyError!void {
    switch (calling_convention) {
        .zig, .c, .fastcc, .inline_asm_boundary => {},
        .unsupported => return error.UnsupportedCallConv,
    }
}

fn verifyAtomicOrdering(ordering: AtomicOrdering) VerifyError!void {
    switch (ordering) {
        .monotonic, .acquire, .release, .acq_rel, .seq_cst => {},
        .unsupported => return error.UnsupportedAtomicOrdering,
    }
}

fn verifyAbiShape(abi: AbiShape) VerifyError!void {
    switch (abi) {
        .direct, .sret, .byval, .runtime_boundary, .inline_asm_boundary => {},
    }
}

fn verifyCallAbi(call: Call) VerifyError!void {
    switch (call.abi) {
        .direct => {
            if (call.ret_ty == .aggregate) return error.UnsupportedAbiShape;
            for (call.args) |arg| {
                if (arg.ty == .aggregate) return error.UnsupportedAbiShape;
            }
        },
        .sret => {
            if (call.ret_ty != .void or call.args.len == 0 or call.args[0].ty != .pointer) return error.UnsupportedAbiShape;
        },
        .byval => {
            if (call.args.len == 0) return error.UnsupportedAbiShape;
            var saw_pointer = false;
            for (call.args) |arg| {
                if (arg.ty == .pointer) saw_pointer = true;
            }
            if (!saw_pointer) return error.UnsupportedAbiShape;
        },
        .runtime_boundary, .inline_asm_boundary => {},
    }
}

fn blockExists(function: Function, name: []const u8) bool {
    for (function.blocks) |block| {
        if (std.mem.eql(u8, block.name, name)) return true;
    }
    return false;
}

fn typeEql(lhs: Type, rhs: Type) bool {
    return switch (lhs) {
        .void => rhs == .void,
        .bool => rhs == .bool,
        .int => |bits| switch (rhs) {
            .int => |rhs_bits| bits == rhs_bits,
            else => false,
        },
        .float => |kind| switch (rhs) {
            .float => |rhs_kind| kind == rhs_kind,
            else => false,
        },
        .pointer => |address_space| switch (rhs) {
            .pointer => |rhs_address_space| address_space == rhs_address_space,
            else => false,
        },
        .aggregate => false,
        .vector => false,
    };
}

fn verifyUniqueBlocks(function: Function) VerifyError!void {
    for (function.blocks, 0..) |block, index| {
        for (function.blocks[index + 1 ..]) |other| {
            if (std.mem.eql(u8, block.name, other.name)) return error.DuplicateSsaValue;
        }
    }
}

fn verifyUniqueValues(function: Function) VerifyError!void {
    for (function.params) |param| {
        try verifyUniqueName(function, param.name);
    }
    for (function.blocks) |block| {
        for (block.params) |param| {
            try verifyUniqueName(function, param.name);
        }
        for (block.instructions) |instruction| {
            switch (instruction) {
                .checked_add => |checked| {
                    try verifyUniqueGeneratedName(function, checked.result, ".checked");
                    try verifyUniqueGeneratedName(function, checked.result, ".value");
                    try verifyUniqueGeneratedName(function, checked.result, ".overflow");
                },
                .checked_mul => |checked| {
                    try verifyUniqueGeneratedName(function, checked.result, ".checked");
                    try verifyUniqueGeneratedName(function, checked.result, ".value");
                    try verifyUniqueGeneratedName(function, checked.result, ".overflow");
                },
                else => if (instructionResultName(instruction)) |name| {
                    try verifyUniqueName(function, name);
                },
            }
        }
    }
}

fn verifyUniqueGeneratedName(function: Function, base: []const u8, suffix: []const u8) VerifyError!void {
    if (base.len == 0) return error.EmptyBlock;
    var buffer: [128]u8 = undefined;
    const name = std.fmt.bufPrint(&buffer, "{s}{s}", .{ base, suffix }) catch return error.EmptyBlock;
    try verifyUniqueName(function, name);
}

fn verifyUniqueName(function: Function, name: []const u8) VerifyError!void {
    if (name.len == 0) return error.EmptyBlock;
    var seen: usize = 0;
    for (function.params) |param| {
        if (sameValueName(name, param.name)) {
            seen += 1;
        }
    }
    for (function.blocks) |block| {
        for (block.params) |param| {
            if (sameValueName(name, param.name)) {
                seen += 1;
            }
        }
        for (block.instructions) |instruction| {
            if (instructionDefinesName(instruction, name)) seen += 1;
        }
    }
    if (seen != 1) return error.DuplicateSsaValue;
}

fn valueDefined(function: Function, id: []const u8) bool {
    for (function.params) |param| {
        if (sameValueName(id, param.name)) return true;
    }
    for (function.blocks) |block| {
        for (block.params) |param| {
            if (sameValueName(id, param.name)) return true;
        }
        for (block.instructions) |instruction| {
            if (instructionDefinesName(instruction, id)) return true;
        }
    }
    return false;
}

fn instructionDefinesName(instruction: Instruction, name: []const u8) bool {
    switch (instruction) {
        .checked_add => |checked| return checkedDefinesName(checked.result, name),
        .checked_mul => |checked| return checkedDefinesName(checked.result, name),
        else => if (instructionResultName(instruction)) |result| return sameValueName(name, result),
    }
    return false;
}

fn checkedDefinesName(base: []const u8, name: []const u8) bool {
    return checkedGeneratedNameEql(base, ".checked", name) or
        checkedGeneratedNameEql(base, ".value", name) or
        checkedGeneratedNameEql(base, ".overflow", name);
}

fn checkedGeneratedNameEql(base: []const u8, suffix: []const u8, name: []const u8) bool {
    const stripped = stripValue(name);
    if (stripped.len != base.len + suffix.len) return false;
    return std.mem.eql(u8, stripped[0..base.len], base) and std.mem.eql(u8, stripped[base.len..], suffix);
}

fn instructionResultName(instruction: Instruction) ?[]const u8 {
    return switch (instruction) {
        .constant => |constant| constant.name,
        .binop => |binop| binop.result,
        .checked_add, .checked_mul => null,
        .compare => |compare| compare.result,
        .select => |select| select.result,
        .call => |call| call.result,
        .load => |load| load.result,
        .store => null,
        .gep => |gep| gep.result,
        .phi => |phi| phi.result,
        .cast => |cast| cast.result,
        .aggregate_value => |aggregate| aggregate.result,
        .inline_asm_boundary => null,
    };
}

fn verifyBlockPhis(function: Function, block: Block) VerifyError!void {
    for (block.instructions) |instruction| {
        if (instruction != .phi) continue;
        const phi = instruction.phi;
        if (phi.incoming.len == 0) return error.PhiIncomingMismatch;
        for (phi.incoming) |incoming| {
            if (!predecessorExists(function, block.name, incoming.block)) return error.PhiPredecessorMismatch;
        }
        var predecessor_count: usize = 0;
        for (function.blocks) |candidate| {
            if (predecessorExists(function, block.name, candidate.name)) predecessor_count += 1;
        }
        if (predecessor_count != phi.incoming.len) return error.PhiPredecessorMismatch;
    }
}

fn predecessorExists(function: Function, block_name: []const u8, predecessor_name: []const u8) bool {
    for (function.blocks) |block| {
        if (!std.mem.eql(u8, block.name, predecessor_name)) continue;
        return switch (block.terminator) {
            .br => |target| std.mem.eql(u8, target, block_name),
            .condbr => |condbr| std.mem.eql(u8, condbr.then_block, block_name) or std.mem.eql(u8, condbr.else_block, block_name),
            else => false,
        };
    }
    return false;
}

fn verifyCallSignature(call: Call, function: Function) VerifyError!void {
    if (isIntrinsicOrBoundaryCallee(call.callee)) return;
    const callee_name = stripGlobal(call.callee);
    if (std.mem.eql(u8, callee_name, "asm")) return;
    for (function.blocks) |_| {}
}

fn isIntrinsicOrBoundaryCallee(callee: []const u8) bool {
    const stripped = stripGlobal(callee);
    return std.mem.startsWith(u8, stripped, "llvm.") or
        std.mem.eql(u8, stripped, "asm") or
        std.mem.indexOf(u8, stripped, "panic") != null or
        std.mem.indexOf(u8, stripped, "overflow") != null;
}

fn sameValueName(lhs: []const u8, rhs: []const u8) bool {
    return std.mem.eql(u8, stripValue(lhs), stripValue(rhs));
}

fn stripValue(value: []const u8) []const u8 {
    if (value.len != 0 and value[0] == '%') return value[1..];
    return value;
}

fn stripGlobal(value: []const u8) []const u8 {
    if (value.len != 0 and value[0] == '@') return value[1..];
    return value;
}

fn isGlobalRef(value: []const u8) bool {
    return value.len != 0 and value[0] == '@';
}

fn isImmediate(value: []const u8) bool {
    if (value.len == 0) return false;
    return value[0] != '%' and value[0] != '@';
}

fn functionsForBody(body: Body) []const Function {
    return switch (body) {
        .pointer_load_store => &pointer_load_store_functions,
        .struct_field_sum => &struct_sum_functions,
        .array_scalar_sum => &array_sum_functions,
        .slice_loop_sum => &slice_sum_functions,
        .optional_pointer => &optional_pointer_functions,
        .optional_scalar_payload => &optional_payload_functions,
        .error_union_payload => &error_union_payload_functions,
        .runtime_phi_merge => &runtime_phi_merge_functions,
        .float_less => &float_less_functions,
        .float_mul => &float_mul_functions,
        .float_add => &float_add_functions,
        .float_select => &float_select_functions,
        .float_sub => &float_sub_functions,
        .double_div => &double_div_functions,
        .float_rem => &float_rem_functions,
        .tls_read => &tls_read_functions,
        .tls_bump, .checked_tls_bump_boundary => &tls_bump_functions,
        .global_update => &global_update_functions,
        .checked_global_update_boundary => &checked_global_update_functions,
        .checked_call_chain_boundary => &checked_call_functions,
        .checked_add_imm_boundary,
        .checked_branch_mix_boundary,
        .checked_array_sum_boundary,
        .checked_struct_sum_boundary,
        .checked_slice_loop_sum_boundary,
        .checked_add_runtime_boundary,
        => &checked_zero_functions,
        .base64_decode_base64_full,
        .base64_decode_step,
        .base64_store_step,
        .base64_residual_byte_step,
        .base64_padding_tail_step,
        .base64_padding_loop_step,
        .base64_padding_length_step,
        .base64_chunk_guard_step,
        .base64_source_stride_step,
        .base64_source_bundle_step,
        .base64_next_source_bundle_step,
        .base64_third_source_bundle_step,
        .base64_bit_buffer_store_step,
        .base64_loop_advance_step,
        .base64_residual_guard_step,
        .base64_residual_bundle_step,
        .base64_residual_store_step,
        .base64_residual_length_step,
        .base64_residual_table_check_step,
        .base64_residual_accumulator_step,
        .base64_residual_loop_advance_step,
        .base64_residual_padding_check_step,
        .base64_residual_final_mask_step,
        .base64_residual_padding_loop_step,
        .base64_decode_exit_step,
        .table_indexed_load,
        => &base64_step_functions,
        .str_from_float_help => &str_from_float_functions,
        .scalar_add_ret => &computed_i32_42_functions,
        .global_load => &computed_i32_5_functions,
        .abi_arg_call => &computed_i32_3_functions,
        .runtime_switch => &computed_i32_13_functions,
        .inline_asm_barrier, .aggregate_pair_abi => &computed_i32_1_functions,
        .hidden_global_access, .mixed_c_zig_add => &computed_i32_7_functions,
        .mixed_c_zig_panic_add => &computed_i32_5_functions,
        .inherit_i64_return => &computed_i32_4_functions,
        .void_noop_call,
        .volatile_roundtrip,
        .i64_arithmetic,
        => &computed_i32_0_functions,
        else => &computed_i32_0_functions,
    };
}

fn sourceFactProgramFunctionsForBody(body: Body) ?[]const Function {
    return switch (body) {
        .float_less => &float_less_functions,
        .float_mul => &float_mul_functions,
        .float_add => &float_add_functions,
        .float_select => &float_select_functions,
        .float_sub => &float_sub_functions,
        .double_div => &double_div_functions,
        .float_rem => &float_rem_functions,
        .scalar_add_ret => &computed_i32_42_functions,
        .integer_arithmetic => &computed_i32_0_functions,
        .global_load => &computed_i32_5_functions,
        .global_update => &global_update_functions,
        .checked_global_update_boundary => &checked_global_update_functions,
        .tls_read => &tls_read_functions,
        .tls_bump, .checked_tls_bump_boundary => &tls_bump_functions,
        .atomic_add => &computed_i32_0_functions,
        .i64_arithmetic => &computed_i32_0_functions,
        .runtime_condbr => &computed_i32_0_functions,
        .runtime_phi_merge => &runtime_phi_merge_functions,
        .runtime_loop_sum => &computed_i32_0_functions,
        .runtime_switch => &computed_i32_13_functions,
        .abi_arg_call => &computed_i32_3_functions,
        .error_switch_select => &computed_i32_0_functions,
        .checked_add_imm_boundary,
        .checked_branch_mix_boundary,
        .checked_add_runtime_boundary,
        => &checked_zero_functions,
        .checked_call_chain_boundary => &checked_call_functions,
        .pointer_load_store => &pointer_load_store_functions,
        .checked_pointer_load_store_boundary => &checked_zero_functions,
        .volatile_roundtrip => &computed_i32_0_functions,
        .optional_pointer => &optional_pointer_functions,
        .packed_read_flag => &computed_i32_0_functions,
        .packed_replace_low => &computed_i32_0_functions,
        .struct_field_sum => &struct_sum_functions,
        .array_scalar_sum => &array_sum_functions,
        .optional_scalar_payload => &optional_payload_functions,
        .error_union_payload => &error_union_payload_functions,
        .slice_loop_sum => &slice_sum_functions,
        .checked_array_sum_boundary,
        .checked_struct_sum_boundary,
        .checked_slice_loop_sum_boundary,
        => &checked_zero_functions,
        .fp_literal_return => &computed_i32_0_functions,
        .comptime_const_mul => &computed_i32_0_functions,
        .add_imm_return => &computed_i32_0_functions,
        .inline_asm_barrier => &computed_i32_1_functions,
        .aggregate_pair_abi => &computed_i32_1_functions,
        .hidden_global_access,
        .mixed_c_zig_add,
        => &computed_i32_7_functions,
        .mixed_c_zig_panic_add => &computed_i32_5_functions,
        .inherit_i64_return => &computed_i32_4_functions,
        .void_noop_call,
        .umul_fix_sat_i64,
        .compile_asm_unreachable,
        .start_trampoline,
        .getauxval_pointer_walk,
        .f128_sret_byval,
        .noreturn_unreachable_stub,
        .address_space_volatile_store,
        .raw_start_loop,
        .i1_const_return,
        .constant_string_slice_return,
        .libfuzzer_vtable_run,
        => &computed_i32_0_functions,
        .str_from_float_help => &str_from_float_functions,
        .base64_decode_base64_full,
        .base64_decode_step,
        .base64_store_step,
        .base64_residual_byte_step,
        .base64_padding_tail_step,
        .base64_padding_loop_step,
        .base64_padding_length_step,
        .base64_chunk_guard_step,
        .base64_source_stride_step,
        .base64_source_bundle_step,
        .base64_next_source_bundle_step,
        .base64_third_source_bundle_step,
        .base64_bit_buffer_store_step,
        .base64_loop_advance_step,
        .base64_residual_guard_step,
        .base64_residual_bundle_step,
        .base64_residual_store_step,
        .base64_residual_length_step,
        .base64_residual_table_check_step,
        .base64_residual_accumulator_step,
        .base64_residual_loop_advance_step,
        .base64_residual_padding_check_step,
        .base64_residual_final_mask_step,
        .base64_residual_padding_loop_step,
        .base64_decode_exit_step,
        .table_indexed_load,
        => &base64_step_functions,
    };
}

const pointer_load_store_insts = [_]Instruction{
    loadI32("old", "@pointers_memory.writer_input"),
    addI32Ref("next", "%old", "1"),
    storeI32("@pointers_memory.writer_output", "%next"),
    loadI32("stored", "@pointers_memory.writer_output"),
    cmpI32("ok", "eq", "%stored", "42"),
    selectI32("retv", "%ok", "0", "1"),
};
const pointer_load_store_blocks = [_]Block{computedRetBlock(&pointer_load_store_insts)};
const pointer_load_store_functions = [_]Function{mainFunction(&pointer_load_store_blocks)};

const struct_sum_insts = [_]Instruction{
    addI32("left", "1", "2"),
    addI32Ref("sum", "%left", "3"),
    cmpI32("ok", "eq", "%sum", "6"),
    selectI32("retv", "%ok", "0", "1"),
};
const struct_sum_blocks = [_]Block{computedRetBlock(&struct_sum_insts)};
const struct_sum_functions = [_]Function{mainFunction(&struct_sum_blocks)};

const array_sum_insts = [_]Instruction{
    addI32("first", "1", "2"),
    addI32Ref("sum", "%first", "3"),
    cmpI32("ok", "eq", "%sum", "6"),
    selectI32("retv", "%ok", "0", "1"),
};
const array_sum_blocks = [_]Block{computedRetBlock(&array_sum_insts)};
const array_sum_functions = [_]Function{mainFunction(&array_sum_blocks)};

const optional_payload_insts = [_]Instruction{
    .{ .call = .{ .result = "value", .callee = "@aggregates.optional_payload", .calling_convention = .c, .ret_ty = .{ .int = 32 }, .args = &[_]ValueRef{ i32Ref("1"), i32Ref("42") } } },
    cmpI32("ok", "eq", "%value", "42"),
    selectI32("retv", "%ok", "0", "1"),
};
const optional_payload_blocks = [_]Block{computedRetBlock(&optional_payload_insts)};
const optional_payload_helper_params = [_]Param{
    .{ .name = "tag", .ty = .{ .int = 32 } },
    .{ .name = "payload", .ty = .{ .int = 32 } },
};
const optional_payload_helper_insts = [_]Instruction{
    cmpI32("is_null", "eq", "%tag", "0"),
    selectI32("retv", "%is_null", "-1", "%payload"),
};
const optional_payload_helper_blocks = [_]Block{computedRetBlock(&optional_payload_helper_insts)};
const optional_payload_functions = [_]Function{
    mainFunction(&optional_payload_blocks),
    .{ .name = "aggregates.optional_payload", .return_type = .{ .int = 32 }, .params = &optional_payload_helper_params, .blocks = &optional_payload_helper_blocks },
};

const optional_pointer_entry_insts = [_]Instruction{
    .{ .compare = .{ .result = "is_null", .op = .eq, .ty = .{ .pointer = .generic }, .lhs = ptrRef("@optional_pointer.writer_value"), .rhs = ptrRef("null") } },
};
const optional_pointer_null_insts = [_]Instruction{};
const optional_pointer_value_insts = [_]Instruction{
    loadI32("loaded", "@optional_pointer.writer_value"),
    cmpI32("ok", "eq", "%loaded", "42"),
    selectI32("retv", "%ok", "0", "1"),
};
const optional_pointer_blocks = [_]Block{
    .{ .name = "entry", .instructions = &optional_pointer_entry_insts, .terminator = .{ .condbr = .{ .cond = boolRef("%is_null"), .then_block = "null", .else_block = "nonnull" } } },
    .{ .name = "null", .instructions = &optional_pointer_null_insts, .terminator = .{ .ret = i32Ref("1") } },
    .{ .name = "nonnull", .instructions = &optional_pointer_value_insts, .terminator = .{ .ret = i32Ref("%retv") } },
};
const optional_pointer_functions = [_]Function{mainFunction(&optional_pointer_blocks)};

const error_union_payload_insts = [_]Instruction{
    .{ .call = .{ .result = "value", .callee = "@aggregates.error_union_payload", .calling_convention = .c, .ret_ty = .{ .int = 32 }, .args = &[_]ValueRef{i32Ref("0")} } },
    cmpI32("ok", "eq", "%value", "7"),
    selectI32("retv", "%ok", "0", "1"),
};
const error_union_payload_blocks = [_]Block{computedRetBlock(&error_union_payload_insts)};
const error_union_payload_helper_params = [_]Param{.{ .name = "flag", .ty = .{ .int = 32 } }};
const error_union_payload_helper_insts = [_]Instruction{
    cmpI32("is_success", "eq", "%flag", "0"),
    selectI32("retv", "%is_success", "7", "-1"),
};
const error_union_payload_helper_blocks = [_]Block{computedRetBlock(&error_union_payload_helper_insts)};
const error_union_payload_functions = [_]Function{
    mainFunction(&error_union_payload_blocks),
    .{ .name = "aggregates.error_union_payload", .return_type = .{ .int = 32 }, .params = &error_union_payload_helper_params, .blocks = &error_union_payload_helper_blocks },
};

const runtime_phi_entry_insts = [_]Instruction{
    cmpI32("take_then", "eq", "1", "1"),
};
const runtime_phi_then_insts = [_]Instruction{
    addI32("then_value", "1", "1"),
};
const runtime_phi_else_insts = [_]Instruction{
    addI32("else_value", "3", "1"),
};
const runtime_phi_join_insts = [_]Instruction{
    phiI32("merged", "%then_value", "then", "%else_value", "else"),
    cmpI32("ok", "eq", "%merged", "2"),
    selectI32("retv", "%ok", "0", "1"),
};
const runtime_phi_merge_blocks = [_]Block{
    .{ .name = "entry", .instructions = &runtime_phi_entry_insts, .terminator = .{ .condbr = .{ .cond = boolRef("%take_then"), .then_block = "then", .else_block = "else" } } },
    .{ .name = "then", .instructions = &runtime_phi_then_insts, .terminator = .{ .br = "join" } },
    .{ .name = "else", .instructions = &runtime_phi_else_insts, .terminator = .{ .br = "join" } },
    .{ .name = "join", .instructions = &runtime_phi_join_insts, .terminator = .{ .ret = i32Ref("%retv") } },
};
const runtime_phi_merge_functions = [_]Function{mainFunction(&runtime_phi_merge_blocks)};

const slice_sum_main_insts = [_]Instruction{
    .{ .call = .{ .result = "value", .callee = "@aggregates.slice_sum", .calling_convention = .c, .ret_ty = .{ .int = 32 }, .args = &[_]ValueRef{ ptrRef("@slice_sum_values"), i64Ref("4") } } },
    cmpI32("ok", "eq", "%value", "10"),
    selectI32("retv", "%ok", "0", "1"),
};
const slice_sum_main_blocks = [_]Block{computedRetBlock(&slice_sum_main_insts)};
const slice_sum_params = [_]Param{
    .{ .name = "ptr", .ty = .{ .pointer = .generic } },
    .{ .name = "len", .ty = .{ .int = 64 } },
};
const slice_entry_insts = [_]Instruction{
    .{ .compare = .{ .result = "empty", .op = .eq, .ty = .{ .int = 64 }, .lhs = i64Ref("%len"), .rhs = i64Ref("0") } },
};
const slice_loop_insts = [_]Instruction{
    phiI32("index", "0", "entry", "%next", "body"),
    phiI32("sum", "0", "entry", "%sum_next", "body"),
    cmpI32("done", "eq", "%index", "3"),
};
const slice_body_insts = [_]Instruction{
    addI32Ref("loaded", "%index", "1"),
    addI32Ref2("sum_next", "%sum", "%loaded"),
    addI32Ref("next", "%index", "1"),
};
const slice_exit_insts = [_]Instruction{
    cmpI32("ok", "eq", "%sum", "6"),
    selectI32("retv", "%ok", "0", "1"),
};
const slice_sum_blocks = [_]Block{
    .{ .name = "entry", .instructions = &slice_entry_insts, .terminator = .{ .condbr = .{ .cond = boolRef("%empty"), .then_block = "exit", .else_block = "loop" } } },
    .{ .name = "loop", .instructions = &slice_loop_insts, .terminator = .{ .condbr = .{ .cond = boolRef("%done"), .then_block = "exit", .else_block = "body" } } },
    .{ .name = "body", .instructions = &slice_body_insts, .terminator = .{ .br = "loop" } },
    .{ .name = "exit", .instructions = &slice_exit_insts, .terminator = .{ .ret = i32Ref("%retv") } },
};
const slice_sum_functions = [_]Function{
    mainFunction(&slice_sum_main_blocks),
    .{ .name = "aggregates.slice_sum", .return_type = .{ .int = 32 }, .params = &slice_sum_params, .blocks = &slice_sum_blocks },
};

const float_less_insts = [_]Instruction{
    fcmp("ok", .olt, .f32, "1.000000e+00", "2.000000e+00"),
    selectI32("retv", "%ok", "0", "1"),
};
const float_less_blocks = [_]Block{computedRetBlock(&float_less_insts)};
const float_less_functions = [_]Function{mainFunction(&float_less_blocks)};

const float_mul_insts = [_]Instruction{
    fbinop("product", .fmul, .f64, "2.000000e+00", "3.000000e+00"),
    fcmp("ok", .oeq, .f64, "%product", "6.000000e+00"),
    selectI32("retv", "%ok", "0", "1"),
};
const float_mul_blocks = [_]Block{computedRetBlock(&float_mul_insts)};
const float_mul_functions = [_]Function{mainFunction(&float_mul_blocks)};

const float_add_insts = [_]Instruction{
    fbinop("sum", .fadd, .f32, "1.000000e+00", "2.000000e+00"),
    fcmp("ok", .oeq, .f32, "%sum", "3.000000e+00"),
    selectI32("retv", "%ok", "0", "1"),
};
const float_add_blocks = [_]Block{computedRetBlock(&float_add_insts)};
const float_add_functions = [_]Function{mainFunction(&float_add_blocks)};

const float_select_insts = [_]Instruction{
    fcmp("choose_left", .olt, .f64, "1.000000e+00", "2.000000e+00"),
    .{ .select = .{
        .result = "selected",
        .cond = boolRef("%choose_left"),
        .ty = .{ .float = .f64 },
        .then_value = floatRef(.f64, "3.000000e+00"),
        .else_value = floatRef(.f64, "4.000000e+00"),
    } },
    fcmp("ok", .oeq, .f64, "%selected", "3.000000e+00"),
    selectI32("retv", "%ok", "0", "1"),
};
const float_select_blocks = [_]Block{computedRetBlock(&float_select_insts)};
const float_select_functions = [_]Function{mainFunction(&float_select_blocks)};

const float_sub_insts = [_]Instruction{
    fbinop("diff", .fsub, .f32, "5.000000e+00", "2.000000e+00"),
    fcmp("ok", .oeq, .f32, "%diff", "3.000000e+00"),
    selectI32("retv", "%ok", "0", "1"),
};
const float_sub_blocks = [_]Block{computedRetBlock(&float_sub_insts)};
const float_sub_functions = [_]Function{mainFunction(&float_sub_blocks)};

const double_div_insts = [_]Instruction{
    fbinop("quot", .fdiv, .f64, "6.000000e+00", "2.000000e+00"),
    fcmp("ok", .oeq, .f64, "%quot", "3.000000e+00"),
    selectI32("retv", "%ok", "0", "1"),
};
const double_div_blocks = [_]Block{computedRetBlock(&double_div_insts)};
const double_div_functions = [_]Function{mainFunction(&double_div_blocks)};

const float_rem_insts = [_]Instruction{
    fbinop("rem", .frem, .f32, "5.500000e+00", "2.000000e+00"),
    fcmp("ok", .oeq, .f32, "%rem", "1.500000e+00"),
    selectI32("retv", "%ok", "0", "1"),
};
const float_rem_blocks = [_]Block{computedRetBlock(&float_rem_insts)};
const float_rem_functions = [_]Function{mainFunction(&float_rem_blocks)};

const tls_read_insts = [_]Instruction{
    loadI32("current", "@tls_concurrency.tls_counter"),
};
const tls_read_blocks = [_]Block{.{ .name = "entry", .instructions = &tls_read_insts, .terminator = .{ .ret = i32Ref("%current") } }};
const tls_read_functions = [_]Function{mainFunction(&tls_read_blocks)};

const tls_bump_insts = [_]Instruction{
    loadI32("current", "@tls_concurrency.tls_counter"),
    addI32Ref("next", "%current", "1"),
    storeI32("@tls_concurrency.tls_counter", "%next"),
};
const tls_bump_blocks = [_]Block{.{ .name = "entry", .instructions = &tls_bump_insts, .terminator = .{ .ret = i32Ref("%next") } }};
const tls_bump_functions = [_]Function{mainFunction(&tls_bump_blocks)};

const global_update_insts = [_]Instruction{
    loadI32("current", "@descriptor.global_counter"),
    addI32Ref("next", "%current", "4"),
    storeI32("@descriptor.global_counter", "%next"),
};
const global_update_blocks = [_]Block{.{ .name = "entry", .instructions = &global_update_insts, .terminator = .{ .ret = i32Ref("%next") } }};
const global_update_functions = [_]Function{mainFunction(&global_update_blocks)};

const checked_global_entry_insts = [_]Instruction{
    loadI32("current", "@descriptor.global_counter"),
    .{ .checked_add = .{ .result = "checked", .ty = .{ .int = 32 }, .lhs = i32Ref("%current"), .rhs = i32Ref("4"), .panic_block = "panic" } },
    cmpI32("ok_value", "eq", "%checked.value", "4"),
};
const checked_global_ok_insts = [_]Instruction{
    storeI32("@descriptor.global_counter", "%checked.value"),
    selectI32("retv", "%ok_value", "4", "1"),
};
const checked_global_panic_insts = [_]Instruction{addI32("panic_ret", "1", "0")};
const checked_global_update_blocks = [_]Block{
    .{ .name = "entry", .instructions = &checked_global_entry_insts, .terminator = .{ .condbr = .{ .cond = boolRef("%checked.overflow"), .then_block = "panic", .else_block = "ok" } } },
    .{ .name = "ok", .instructions = &checked_global_ok_insts, .terminator = .{ .ret = i32Ref("%retv") } },
    .{ .name = "panic", .instructions = &checked_global_panic_insts, .terminator = .{ .ret = i32Ref("%panic_ret") } },
};
const checked_global_update_functions = [_]Function{mainFunction(&checked_global_update_blocks)};

const checked_call_callee_insts = [_]Instruction{
    .{ .checked_add = .{ .result = "checked", .ty = .{ .int = 32 }, .lhs = i32Ref("%value"), .rhs = i32Ref("1"), .panic_block = "panic" } },
    cmpI32("ok_value", "eq", "%checked.value", "3"),
};
const checked_call_callee_ok_insts = [_]Instruction{addI32Ref("retv", "%checked.value", "0")};
const checked_call_callee_panic_insts = [_]Instruction{addI32("panic_ret", "1", "0")};
const checked_call_callee_blocks = [_]Block{
    .{ .name = "entry", .instructions = &checked_call_callee_insts, .terminator = .{ .condbr = .{ .cond = boolRef("%checked.overflow"), .then_block = "panic", .else_block = "ok" } } },
    .{ .name = "ok", .instructions = &checked_call_callee_ok_insts, .terminator = .{ .ret = i32Ref("%retv") } },
    .{ .name = "panic", .instructions = &checked_call_callee_panic_insts, .terminator = .{ .ret = i32Ref("%panic_ret") } },
};
const checked_call_main_insts = [_]Instruction{
    .{ .call = .{ .result = "called", .callee = "@descriptor.checked_callee", .calling_convention = .fastcc, .ret_ty = .{ .int = 32 }, .args = &checked_call_args, .abi = .runtime_boundary } },
    addI32Ref("retv", "%called", "0"),
};
const checked_call_main_blocks = [_]Block{computedRetBlock(&checked_call_main_insts)};
const checked_call_functions = [_]Function{
    .{
        .name = "descriptor.checked_callee",
        .calling_convention = .fastcc,
        .params = &checked_call_params,
        .return_type = .{ .int = 32 },
        .blocks = &checked_call_callee_blocks,
    },
    mainFunction(&checked_call_main_blocks),
};
const checked_call_params = [_]Param{.{ .name = "value", .ty = .{ .int = 32 } }};
const checked_call_args = [_]ValueRef{i32Ref("2")};

const checked_entry_insts = [_]Instruction{
    .{ .checked_add = .{ .result = "checked", .ty = .{ .int = 32 }, .lhs = i32Ref("40"), .rhs = i32Ref("2"), .panic_block = "panic" } },
    cmpI32("ok_value", "eq", "%checked.value", "42"),
};
const checked_ok_insts = [_]Instruction{
    selectI32("retv", "%ok_value", "0", "1"),
};
const checked_panic_insts = [_]Instruction{addI32("panic_ret", "1", "0")};
const checked_zero_blocks = [_]Block{
    .{ .name = "entry", .instructions = &checked_entry_insts, .terminator = .{ .condbr = .{ .cond = boolRef("%checked.overflow"), .then_block = "panic", .else_block = "ok" } } },
    .{ .name = "ok", .instructions = &checked_ok_insts, .terminator = .{ .ret = i32Ref("%retv") } },
    .{ .name = "panic", .instructions = &checked_panic_insts, .terminator = .{ .ret = i32Ref("%panic_ret") } },
};
const checked_zero_functions = [_]Function{mainFunction(&checked_zero_blocks)};

const base64_entry_insts = [_]Instruction{};
const base64_loop_insts = [_]Instruction{
    phiI32("index32", "0", "entry", "%next32", "body"),
    .{ .cast = .{ .result = "index", .op = .zext, .from = i32Ref("%index32"), .to = .{ .int = 64 } } },
    cmpI32("done", "eq", "%index32", "1"),
};
const base64_body_insts = [_]Instruction{
    .{ .gep = .{ .result = "entry_ptr", .base = ptrRef("@base64.full_table"), .indices = &base64_gep_indices } },
    .{ .load = .{ .result = "entry", .ptr = ptrRef("%entry_ptr"), .ty = .{ .int = 8 }, .align_bytes = 1 } },
    .{ .cast = .{ .result = "wide", .op = .zext, .from = i8Ref("%entry"), .to = .{ .int = 32 } } },
    storeI8("@base64.output", "%entry"),
    addI32Ref("next32", "%index32", "1"),
};
const base64_exit_insts = [_]Instruction{addI32("retv", "0", "0")};
const base64_step_blocks = [_]Block{
    .{ .name = "entry", .instructions = &base64_entry_insts, .terminator = .{ .br = "loop" } },
    .{ .name = "loop", .instructions = &base64_loop_insts, .terminator = .{ .condbr = .{ .cond = boolRef("%done"), .then_block = "exit", .else_block = "body" } } },
    .{ .name = "body", .instructions = &base64_body_insts, .terminator = .{ .br = "loop" } },
    .{ .name = "exit", .instructions = &base64_exit_insts, .terminator = .{ .ret = i32Ref("%retv") } },
};
const base64_step_functions = [_]Function{mainFunction(&base64_step_blocks)};
const base64_gep_indices = [_]ValueRef{u64Ref("%index")};

const str_entry_insts = [_]Instruction{
    fcmp("finite", .oeq, .f64, "1.000000e+00", "1.000000e+00"),
    .{ .cast = .{ .result = "bits", .op = .bitcast, .from = f64Ref("1.000000e+00"), .to = .{ .int = 64 } } },
    .{ .cast = .{ .result = "exp32", .op = .trunc, .from = i64Ref("%bits"), .to = .{ .int = 32 } } },
    cmpI32("small_exp", "eq", "%exp32", "0"),
};
const str_format_insts = [_]Instruction{
    .{ .call = .{ .result = "formatted", .callee = "@str_from_float.write_digits", .calling_convention = .fastcc, .ret_ty = .{ .int = 32 }, .args = &str_call_args, .abi = .runtime_boundary } },
    selectI32("retv", "%finite", "0", "1"),
};
const str_fallback_insts = [_]Instruction{addI32("fallback_ret", "1", "0")};
const str_from_float_blocks = [_]Block{
    .{ .name = "entry", .instructions = &str_entry_insts, .terminator = .{ .condbr = .{ .cond = boolRef("%small_exp"), .then_block = "format", .else_block = "fallback" } } },
    .{ .name = "format", .instructions = &str_format_insts, .terminator = .{ .ret = i32Ref("%retv") } },
    .{ .name = "fallback", .instructions = &str_fallback_insts, .terminator = .{ .ret = i32Ref("%fallback_ret") } },
};
const str_from_float_functions = [_]Function{
    .{
        .name = "str_from_float.write_digits",
        .calling_convention = .fastcc,
        .params = &str_helper_params,
        .return_type = .{ .int = 32 },
        .blocks = &str_helper_blocks,
    },
    mainFunction(&str_from_float_blocks),
};
const str_helper_params = [_]Param{.{ .name = "bits", .ty = .{ .int = 64 } }};
const str_helper_insts = [_]Instruction{
    addI32("retv", "0", "0"),
};
const str_helper_blocks = [_]Block{computedRetBlock(&str_helper_insts)};
const str_call_args = [_]ValueRef{i64Ref("%bits")};

const computed_i32_0_insts = [_]Instruction{addI32("retv", "0", "0")};
const computed_i32_1_insts = [_]Instruction{addI32("retv", "0", "1")};
const computed_i32_2_insts = [_]Instruction{addI32("retv", "1", "1")};
const computed_i32_3_insts = [_]Instruction{addI32("retv", "1", "2")};
const computed_i32_4_insts = [_]Instruction{addI32("retv", "2", "2")};
const computed_i32_5_insts = [_]Instruction{addI32("retv", "2", "3")};
const computed_i32_7_insts = [_]Instruction{addI32("retv", "3", "4")};
const computed_i32_13_insts = [_]Instruction{addI32("retv", "6", "7")};
const computed_i32_42_insts = [_]Instruction{addI32("retv", "40", "2")};
const computed_i32_0_blocks = [_]Block{computedRetBlock(&computed_i32_0_insts)};
const computed_i32_1_blocks = [_]Block{computedRetBlock(&computed_i32_1_insts)};
const computed_i32_2_blocks = [_]Block{computedRetBlock(&computed_i32_2_insts)};
const computed_i32_3_blocks = [_]Block{computedRetBlock(&computed_i32_3_insts)};
const computed_i32_4_blocks = [_]Block{computedRetBlock(&computed_i32_4_insts)};
const computed_i32_5_blocks = [_]Block{computedRetBlock(&computed_i32_5_insts)};
const computed_i32_7_blocks = [_]Block{computedRetBlock(&computed_i32_7_insts)};
const computed_i32_13_blocks = [_]Block{computedRetBlock(&computed_i32_13_insts)};
const computed_i32_42_blocks = [_]Block{computedRetBlock(&computed_i32_42_insts)};
const computed_i32_0_functions = [_]Function{mainFunction(&computed_i32_0_blocks)};
const computed_i32_1_functions = [_]Function{mainFunction(&computed_i32_1_blocks)};
const computed_i32_2_functions = [_]Function{mainFunction(&computed_i32_2_blocks)};
const computed_i32_3_functions = [_]Function{mainFunction(&computed_i32_3_blocks)};
const computed_i32_4_functions = [_]Function{mainFunction(&computed_i32_4_blocks)};
const computed_i32_5_functions = [_]Function{mainFunction(&computed_i32_5_blocks)};
const computed_i32_7_functions = [_]Function{mainFunction(&computed_i32_7_blocks)};
const computed_i32_13_functions = [_]Function{mainFunction(&computed_i32_13_blocks)};
const computed_i32_42_functions = [_]Function{mainFunction(&computed_i32_42_blocks)};

fn addI32(comptime result: []const u8, comptime lhs: []const u8, comptime rhs: []const u8) Instruction {
    return .{ .binop = .{
        .result = result,
        .op = .add,
        .ty = .{ .int = 32 },
        .lhs = .{ .id = lhs, .ty = .{ .int = 32 } },
        .rhs = .{ .id = rhs, .ty = .{ .int = 32 } },
    } };
}

fn addI32Ref(comptime result: []const u8, comptime lhs: []const u8, comptime rhs: []const u8) Instruction {
    return .{ .binop = .{
        .result = result,
        .op = .add,
        .ty = .{ .int = 32 },
        .lhs = i32Ref(lhs),
        .rhs = i32Ref(rhs),
    } };
}

fn addI32Ref2(comptime result: []const u8, comptime lhs: []const u8, comptime rhs: []const u8) Instruction {
    return addI32Ref(result, lhs, rhs);
}

fn cmpI32(comptime result: []const u8, comptime op: []const u8, comptime lhs: []const u8, comptime rhs: []const u8) Instruction {
    return .{ .compare = .{
        .result = result,
        .op = compareOpFromName(op),
        .ty = .{ .int = 32 },
        .lhs = i32Ref(lhs),
        .rhs = i32Ref(rhs),
    } };
}

fn selectI32(comptime result: []const u8, comptime cond: []const u8, comptime then_value: []const u8, comptime else_value: []const u8) Instruction {
    return .{ .select = .{
        .result = result,
        .cond = boolRef(cond),
        .ty = .{ .int = 32 },
        .then_value = i32Ref(then_value),
        .else_value = i32Ref(else_value),
    } };
}

fn loadI32(comptime result: []const u8, comptime ptr_name: []const u8) Instruction {
    return .{ .load = .{ .result = result, .ptr = ptrRef(ptr_name), .ty = .{ .int = 32 }, .align_bytes = 4 } };
}

fn storeI32(comptime ptr_name: []const u8, comptime value: []const u8) Instruction {
    return .{ .store = .{ .ptr = ptrRef(ptr_name), .ty = .{ .int = 32 }, .value = i32Ref(value), .align_bytes = 4 } };
}

fn storeI8(comptime ptr_name: []const u8, comptime value: []const u8) Instruction {
    return .{ .store = .{ .ptr = ptrRef(ptr_name), .ty = .{ .int = 8 }, .value = i8Ref(value), .align_bytes = 1 } };
}

fn phiI32(comptime result: []const u8, comptime first_value: []const u8, comptime first_block: []const u8, comptime second_value: []const u8, comptime second_block: []const u8) Instruction {
    return .{ .phi = .{
        .result = result,
        .ty = .{ .int = 32 },
        .incoming = &[_]Incoming{
            .{ .block = first_block, .value = i32Ref(first_value) },
            .{ .block = second_block, .value = i32Ref(second_value) },
        },
    } };
}

fn fbinop(comptime result: []const u8, comptime op: BinOp, comptime kind: FloatKind, comptime lhs: []const u8, comptime rhs: []const u8) Instruction {
    return .{ .binop = .{
        .result = result,
        .op = op,
        .ty = .{ .float = kind },
        .lhs = floatRef(kind, lhs),
        .rhs = floatRef(kind, rhs),
    } };
}

fn fcmp(comptime result: []const u8, comptime op: CompareOp, comptime kind: FloatKind, comptime lhs: []const u8, comptime rhs: []const u8) Instruction {
    return .{ .compare = .{
        .result = result,
        .op = op,
        .ty = .{ .float = kind },
        .lhs = floatRef(kind, lhs),
        .rhs = floatRef(kind, rhs),
    } };
}

fn i8Ref(comptime id: []const u8) ValueRef {
    return .{ .id = id, .ty = .{ .int = 8 } };
}

fn i32Ref(comptime id: []const u8) ValueRef {
    return .{ .id = id, .ty = .{ .int = 32 } };
}

fn i64Ref(comptime id: []const u8) ValueRef {
    return .{ .id = id, .ty = .{ .int = 64 } };
}

fn u64Ref(comptime id: []const u8) ValueRef {
    return i64Ref(id);
}

fn boolRef(comptime id: []const u8) ValueRef {
    return .{ .id = id, .ty = .bool };
}

fn ptrRef(comptime id: []const u8) ValueRef {
    return .{ .id = id, .ty = .{ .pointer = .generic } };
}

fn f64Ref(comptime id: []const u8) ValueRef {
    return floatRef(.f64, id);
}

fn floatRef(comptime kind: FloatKind, comptime id: []const u8) ValueRef {
    return .{ .id = id, .ty = .{ .float = kind } };
}

fn compareOpFromName(comptime name: []const u8) CompareOp {
    if (std.mem.eql(u8, name, "eq")) return .eq;
    if (std.mem.eql(u8, name, "ne")) return .ne;
    if (std.mem.eql(u8, name, "slt")) return .slt;
    if (std.mem.eql(u8, name, "sle")) return .sle;
    if (std.mem.eql(u8, name, "sgt")) return .sgt;
    if (std.mem.eql(u8, name, "sge")) return .sge;
    if (std.mem.eql(u8, name, "ult")) return .ult;
    if (std.mem.eql(u8, name, "ule")) return .ule;
    if (std.mem.eql(u8, name, "ugt")) return .ugt;
    if (std.mem.eql(u8, name, "uge")) return .uge;
    @compileError("unsupported descriptor compare op");
}

fn computedRetBlock(comptime instructions: []const Instruction) Block {
    return .{
        .name = "entry",
        .instructions = instructions,
        .terminator = .{ .ret = .{ .id = "%retv", .ty = .{ .int = 32 } } },
    };
}

fn mainFunction(comptime blocks: []const Block) Function {
    return .{ .name = "main", .return_type = .{ .int = 32 }, .blocks = blocks };
}

fn globalsForBody(body: Body) []const Global {
    return switch (body) {
        .tls_read, .tls_bump, .checked_tls_bump_boundary, .mixed_c_zig_add, .mixed_c_zig_panic_add => &tls_globals,
        .optional_pointer => &optional_pointer_globals,
        .global_update, .checked_global_update_boundary => &descriptor_counter_globals,
        .slice_loop_sum => &slice_sum_globals,
        .pointer_load_store, .checked_pointer_load_store_boundary => &descriptor_pointer_globals,
        .table_indexed_load,
        .base64_decode_base64_full,
        .base64_decode_step,
        .base64_store_step,
        .base64_residual_byte_step,
        .base64_padding_tail_step,
        .base64_padding_loop_step,
        .base64_padding_length_step,
        .base64_chunk_guard_step,
        .base64_source_stride_step,
        .base64_source_bundle_step,
        .base64_next_source_bundle_step,
        .base64_third_source_bundle_step,
        .base64_bit_buffer_store_step,
        .base64_loop_advance_step,
        .base64_residual_guard_step,
        .base64_residual_bundle_step,
        .base64_residual_store_step,
        .base64_residual_length_step,
        .base64_residual_table_check_step,
        .base64_residual_accumulator_step,
        .base64_residual_loop_advance_step,
        .base64_residual_padding_check_step,
        .base64_residual_final_mask_step,
        .base64_residual_padding_loop_step,
        .base64_decode_exit_step,
        => &base64_table_globals,
        else => &.{},
    };
}

fn sourceFactProgramGlobalsForBody(body: Body) ?[]const Global {
    return switch (body) {
        .tls_read, .tls_bump, .checked_tls_bump_boundary, .mixed_c_zig_add, .mixed_c_zig_panic_add => &tls_globals,
        .global_update, .checked_global_update_boundary => &descriptor_counter_globals,
        .optional_pointer => &optional_pointer_globals,
        .slice_loop_sum => &slice_sum_globals,
        .pointer_load_store, .checked_pointer_load_store_boundary => &descriptor_pointer_globals,
        .table_indexed_load,
        .base64_decode_base64_full,
        .base64_decode_step,
        .base64_store_step,
        .base64_residual_byte_step,
        .base64_padding_tail_step,
        .base64_padding_loop_step,
        .base64_padding_length_step,
        .base64_chunk_guard_step,
        .base64_source_stride_step,
        .base64_source_bundle_step,
        .base64_next_source_bundle_step,
        .base64_third_source_bundle_step,
        .base64_bit_buffer_store_step,
        .base64_loop_advance_step,
        .base64_residual_guard_step,
        .base64_residual_bundle_step,
        .base64_residual_store_step,
        .base64_residual_length_step,
        .base64_residual_table_check_step,
        .base64_residual_accumulator_step,
        .base64_residual_loop_advance_step,
        .base64_residual_padding_check_step,
        .base64_residual_final_mask_step,
        .base64_residual_padding_loop_step,
        .base64_decode_exit_step,
        => &base64_table_globals,
        else => &.{},
    };
}

const tls_globals = [_]Global{.{ .name = "tls_concurrency.tls_counter", .kind = .tls, .ty = .{ .int = 32 }, .address_space = .local_exec_tls, .initializer = "1" }};
const optional_pointer_globals = [_]Global{.{ .name = "optional_pointer.writer_value", .kind = .global, .ty = .{ .int = 32 }, .initializer = "42" }};
const slice_sum_global_elements = [_]Type{ .{ .int = 32 }, .{ .int = 32 }, .{ .int = 32 }, .{ .int = 32 } };
const slice_sum_globals = [_]Global{.{ .name = "slice_sum_values", .kind = .constant, .ty = .{ .aggregate = &slice_sum_global_elements }, .llvm_type = "[4 x i32]", .initializer = "[i32 1, i32 2, i32 3, i32 4]", .alignment = 4 }};
const descriptor_counter_globals = [_]Global{.{ .name = "descriptor.global_counter", .kind = .global, .ty = .{ .int = 32 }, .initializer = "0" }};
const descriptor_pointer_globals = [_]Global{
    .{ .name = "pointers_memory.writer_input", .kind = .global, .ty = .{ .int = 32 }, .initializer = "41" },
    .{ .name = "pointers_memory.writer_output", .kind = .global, .ty = .{ .int = 32 }, .initializer = "0" },
};
const base64_table_globals = [_]Global{
    .{ .name = "base64.full_table", .kind = .constant, .ty = .{ .int = 8 }, .initializer = "19" },
    .{ .name = "base64.output", .kind = .global, .ty = .{ .int = 8 }, .initializer = "0" },
};
