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

pub fn lowerGlobal(module: *sib.Module, global: Global) !void {
    const ty = if (global.llvm_type) |llvm_type| sib.Type{ .text = llvm_type } else try toSibType(global.ty);
    const init = global.initializer orelse initializerForType(global.ty);
    const alignment = alignText(global.alignment orelse typeAlignment(global.ty));
    switch (global.kind) {
        .global => try module.global(global.name, "private unnamed_addr", ty, init, alignment),
        .constant => try module.constant(global.name, "private unnamed_addr", ty, init, alignment),
        .tls => try module.tlsGlobal(global.name, "private", "localexec", ty, init, alignment),
    }
}

pub fn lowerFunction(module: *sib.Module, function: Function) !void {
    const ret_ty = try toSibType(function.return_type);
    var params_buf: [1024]u8 = undefined;
    const params = try formatParams(&params_buf, function.params);
    var lowered = try module.function(functionLinkage(function), ret_ty, function.name, params, functionAttrs(function));
    for (function.blocks) |block| {
        var lowered_block = try lowered.block(block.name);
        for (block.instructions) |instruction| try lowerInstruction(&lowered_block, instruction);
        try lowerTerminator(&lowered_block, block.terminator);
        if (!std.mem.eql(u8, block.name, function.blocks[function.blocks.len - 1].name)) {
            try module.writer.writeAll("\n");
        }
    }
    try lowered.end();
}

fn initializerForType(ty: Type) []const u8 {
    return switch (ty) {
        .bool => "false",
        .int, .float, .pointer => "0",
        .aggregate => "zeroinitializer",
        .void, .vector => "zeroinitializer",
    };
}

fn typeAlignment(ty: Type) u16 {
    return switch (ty) {
        .bool => 1,
        .int => |bits| if (bits <= 8) 1 else if (bits <= 16) 2 else if (bits <= 32) 4 else 8,
        .float => |kind| switch (kind) {
            .f32 => 4,
            .f64 => 8,
            .f128 => 16,
        },
        .pointer => 8,
        .aggregate => 1,
        .void, .vector => 1,
    };
}

fn lowerInstruction(block: *sib.Block, instruction: Instruction) !void {
    switch (canonicalizedInstruction(instruction)) {
        .constant => {},
        .binop => |binop| {
            _ = try block.binary(binop.result, binOpName(binop.op), try toSibType(binop.ty), valueRef(binop.lhs), valueRef(binop.rhs));
        },
        .checked_add => |checked| {
            _ = try block.checkedSAddI32(checked.result, valueRef(checked.lhs), valueRef(checked.rhs));
        },
        .checked_mul => |checked| {
            _ = try block.checkedSMulI32(checked.result, valueRef(checked.lhs), valueRef(checked.rhs));
        },
        .compare => |compare| {
            const ty = try toSibType(compare.ty);
            if (isFloatType(compare.ty)) {
                _ = try block.fcmp(compare.result, compareOpName(compare.op), ty, valueRef(compare.lhs), valueRef(compare.rhs));
            } else {
                _ = try block.icmp(compare.result, compareOpName(compare.op), ty, valueRef(compare.lhs), valueRef(compare.rhs));
            }
        },
        .select => |select| {
            _ = try block.select(select.result, valueRef(select.cond), try toSibType(select.ty), valueRef(select.then_value), valueRef(select.else_value));
        },
        .call => |call| {
            var args_buf: [1024]u8 = undefined;
            _ = try block.call(call.result, callConvAttrs(call.calling_convention), try toSibType(call.ret_ty), call.callee, try formatCallArgs(&args_buf, call.args));
        },
        .load => |load| {
            if (load.is_volatile) {
                _ = try block.volatileLoad(loadResultName(load), try toSibType(load.ty), valueRef(load.ptr), alignText(load.align_bytes));
            } else {
                _ = try block.load(loadResultName(load), try toSibType(load.ty), valueRef(load.ptr), alignText(load.align_bytes));
            }
        },
        .store => |store| {
            const value = if (store.value) |store_value| valueRef(store_value) else sib.Value.constant(try toSibType(store.ty), "0");
            if (store.is_volatile) {
                try block.volatileStore(value, valueRef(store.ptr), alignText(store.align_bytes));
            } else {
                try block.store(value, valueRef(store.ptr), alignText(store.align_bytes));
            }
        },
        .gep => |gep| {
            if (gep.indices.len == 0) return;
            _ = try block.gep(gep.result, .i8, valueRef(gep.base), try toSibType(gep.indices[0].ty), valueRef(gep.indices[0]));
        },
        .phi => |phi| {
            if (phi.incoming.len == 2) {
                _ = try block.phi2(phi.result, try toSibType(phi.ty), valueRef(phi.incoming[0].value), phi.incoming[0].block, valueRef(phi.incoming[1].value), phi.incoming[1].block);
            } else if (phi.incoming.len == 3) {
                _ = try block.phi3(phi.result, try toSibType(phi.ty), valueRef(phi.incoming[0].value), phi.incoming[0].block, valueRef(phi.incoming[1].value), phi.incoming[1].block, valueRef(phi.incoming[2].value), phi.incoming[2].block);
            } else {
                return error.UnsupportedDescriptorConstruct;
            }
        },
        .cast => |cast| {
            _ = try block.cast(cast.result, castOpName(cast.op), valueRef(cast.from), try toSibType(cast.to));
        },
        .aggregate_value => {},
        .inline_asm_boundary => try block.inlineAsmBarrier(),
    }
}

fn canonicalizedInstruction(instruction: Instruction) Instruction {
    return switch (instruction) {
        .binop => |binop| if (foldIntegerBinop(binop)) |folded| folded else instruction,
        else => instruction,
    };
}

fn foldIntegerBinop(binop: anytype) ?Instruction {
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
    const folded_text = std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{folded}) catch return null;
    return .{ .binop = .{
        .result = binop.result,
        .op = .add,
        .ty = binop.ty,
        .lhs = .{ .id = folded_text, .ty = binop.ty },
        .rhs = .{ .id = "0", .ty = binop.ty },
    } };
}

pub fn canFoldIntegerBinop(binop: anytype) bool {
    if (binop.ty != .int) return false;
    _ = parseImmediateInt(binop.lhs.id) orelse return false;
    _ = parseImmediateInt(binop.rhs.id) orelse return false;
    return switch (binop.op) {
        .add, .sub, .mul, .@"and", .@"or", .xor => true,
        .shl, .lshr, .ashr, .fadd, .fsub, .fmul, .fdiv, .frem => false,
    };
}

pub fn canFoldFpBinop(binop: anytype) bool {
    if (binop.ty != .float) return false;
    return isImmediate(binop.lhs.id) and isImmediate(binop.rhs.id) and switch (binop.op) {
        .fadd, .fsub, .fmul, .fdiv, .frem => true,
        .add, .sub, .mul, .shl, .lshr, .ashr, .@"and", .@"or", .xor => false,
    };
}

fn isImmediate(value: []const u8) bool {
    if (value.len == 0) return false;
    return value[0] != '%' and value[0] != '@';
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

pub fn isNeutralLocalComputation(binop: anytype) bool {
    return switch (binop.op) {
        .add, .@"or", .xor => std.mem.eql(u8, binop.rhs.id, "0") or std.mem.eql(u8, binop.lhs.id, "0"),
        .sub, .shl, .lshr, .ashr => std.mem.eql(u8, binop.rhs.id, "0"),
        .mul => std.mem.eql(u8, binop.rhs.id, "1") or std.mem.eql(u8, binop.lhs.id, "1"),
        .@"and" => false,
        .fadd, .fsub, .fmul, .fdiv, .frem => false,
    };
}

pub fn isBranchToReturnBlock(function: Function, block: Block) bool {
    const target = switch (block.terminator) {
        .br => |target| target,
        else => return false,
    };
    const target_block = blockByName(function, target) orelse return false;
    return target_block.instructions.len == 0 and switch (target_block.terminator) {
        .ret => true,
        .br, .condbr, .@"unreachable" => false,
    };
}

pub fn isFcmpSelectCanonical(function: Function, select: anytype) bool {
    if (!typeEql(select.cond.ty, .bool)) return false;
    const cond_name = select.cond.id;
    if (!std.mem.startsWith(u8, cond_name, "%")) return false;
    for (function.blocks) |block| {
        for (block.instructions) |instruction| switch (instruction) {
            .compare => |compare| {
                if (!isFloatType(compare.ty)) continue;
                if (cond_name.len > 1 and std.mem.eql(u8, cond_name[1..], compare.result)) return true;
            },
            else => {},
        };
    }
    return false;
}

pub fn blockByName(function: Function, name: []const u8) ?Block {
    for (function.blocks) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

pub fn parseImmediateInt(text: []const u8) ?i128 {
    if (!isImmediate(text)) return null;
    return std.fmt.parseInt(i128, text, 10) catch null;
}

fn lowerTerminator(block: *sib.Block, terminator: Terminator) !void {
    switch (terminator) {
        .ret => |maybe_value| {
            if (maybe_value) |value| {
                try block.ret(valueRef(value));
            } else {
                try block.retVoid();
            }
        },
        .br => |target| try block.br(target),
        .condbr => |condbr| try block.condBr(valueRef(condbr.cond), condbr.then_block, condbr.else_block),
        .@"unreachable" => try block.emitUnreachable(),
    }
}

fn toSibType(ty: Type) !sib.Type {
    return switch (ty) {
        .void => .void,
        .bool => .i1,
        .int => |bits| switch (bits) {
            1 => .i1,
            4 => .i4,
            8 => .i8,
            12 => .i12,
            16 => .i16,
            32 => .i32,
            64 => .i64,
            128 => .i128,
            else => error.UnsupportedDescriptorConstruct,
        },
        .float => |kind| switch (kind) {
            .f32 => .f32,
            .f64 => .f64,
            .f128 => .fp128,
        },
        .pointer => .ptr,
        .aggregate => .{ .text = "{}" },
        .vector => error.UnsupportedTypeVector,
    };
}

fn valueRef(value: ValueRef) sib.Value {
    return sib.Value.constant(toSibType(value.ty) catch .i32, value.id);
}

fn formatParams(buf: []u8, params: []const Param) ![]const u8 {
    var used: usize = 0;
    for (params, 0..) |param, index| {
        if (index != 0) used = try appendBuf(buf, used, ", ", .{});
        used = try appendBuf(buf, used, "{s} %{s}", .{ (try toSibType(param.ty)).llvm(), param.name });
    }
    return buf[0..used];
}

fn formatCallArgs(buf: []u8, args: []const ValueRef) ![]const u8 {
    var used: usize = 0;
    for (args, 0..) |arg, index| {
        if (index != 0) used = try appendBuf(buf, used, ", ", .{});
        used = try appendBuf(buf, used, "{s} {s}", .{ (try toSibType(arg.ty)).llvm(), arg.id });
    }
    return buf[0..used];
}

fn appendBuf(buf: []u8, used: usize, comptime fmt: []const u8, args: anytype) !usize {
    const written = try std.fmt.bufPrint(buf[used..], fmt, args);
    return used + written.len;
}

fn functionLinkage(function: Function) []const u8 {
    return if (std.mem.eql(u8, function.name, "main")) "dso_local " else "internal ";
}

fn functionAttrs(function: Function) []const u8 {
    return if (function.calling_convention == .fastcc) " fastcc" else " local_unnamed_addr";
}

fn callConvAttrs(cc: CallConv) []const u8 {
    return switch (cc) {
        .fastcc => "fastcc ",
        .c, .zig, .inline_asm_boundary => "",
        .unsupported => "",
    };
}

fn binOpName(op: BinOp) []const u8 {
    return switch (op) {
        .add => "add",
        .sub => "sub",
        .mul => "mul",
        .shl => "shl",
        .lshr => "lshr",
        .ashr => "ashr",
        .@"and" => "and",
        .@"or" => "or",
        .xor => "xor",
        .fadd => "fadd",
        .fsub => "fsub",
        .fmul => "fmul",
        .fdiv => "fdiv",
        .frem => "frem",
    };
}

fn compareOpName(op: CompareOp) []const u8 {
    return switch (op) {
        .eq => "eq",
        .ne => "ne",
        .slt => "slt",
        .sle => "sle",
        .sgt => "sgt",
        .sge => "sge",
        .ult => "ult",
        .ule => "ule",
        .ugt => "ugt",
        .uge => "uge",
        .oeq => "oeq",
        .one => "one",
        .olt => "olt",
        .ole => "ole",
        .ogt => "ogt",
        .oge => "oge",
    };
}

fn castOpName(op: CastOp) []const u8 {
    return switch (op) {
        .trunc => "trunc",
        .zext => "zext",
        .sext => "sext",
        .bitcast => "bitcast",
        .ptrtoint => "ptrtoint",
        .inttoptr => "inttoptr",
    };
}

fn isFloatType(ty: Type) bool {
    return switch (ty) {
        .float => true,
        else => false,
    };
}

fn alignText(align_bytes: u16) []const u8 {
    return switch (align_bytes) {
        1 => "1",
        2 => "2",
        4 => "4",
        8 => "8",
        16 => "16",
        else => "1",
    };
}

fn loadResultName(load: MemoryOp) []const u8 {
    return load.result orelse "load";
}

pub fn bodyForSurface(surface: []const u8) ?Body {
    inline for (surface_body_map) |entry| {
        if (std.mem.eql(u8, surface, entry.surface)) return entry.body;
    }
    return null;
}

pub fn bodyName(body: Body) []const u8 {
    inline for (surface_body_map) |entry| {
        if (body == entry.body) return entry.name;
    }
    return "unknown";
}

const SurfaceBody = struct {
    surface: []const u8,
    name: []const u8,
    body: Body,
};

const surface_body_map = [_]SurfaceBody{
    .{ .surface = "scalar-add-ret", .name = "scalar-add-ret", .body = .scalar_add_ret },
    .{ .surface = "integer-arithmetic", .name = "integer-arithmetic", .body = .integer_arithmetic },
    .{ .surface = "error-switch-select", .name = "error-switch-select", .body = .error_switch_select },
    .{ .surface = "global-load", .name = "global-load", .body = .global_load },
    .{ .surface = "runtime-phi-merge", .name = "runtime-phi-merge", .body = .runtime_phi_merge },
    .{ .surface = "runtime-loop-sum", .name = "runtime-loop-sum", .body = .runtime_loop_sum },
    .{ .surface = "abi-arg-call", .name = "abi-arg-call", .body = .abi_arg_call },
    .{ .surface = "runtime-condbr", .name = "runtime-condbr", .body = .runtime_condbr },
    .{ .surface = "runtime-switch", .name = "runtime-switch", .body = .runtime_switch },
    .{ .surface = "pointer-load-store", .name = "pointer-load-store", .body = .pointer_load_store },
    .{ .surface = "optional-pointer", .name = "optional-pointer", .body = .optional_pointer },
    .{ .surface = "packed-read-flag", .name = "packed-read-flag", .body = .packed_read_flag },
    .{ .surface = "packed-replace-low", .name = "packed-replace-low", .body = .packed_replace_low },
    .{ .surface = "struct-field-sum", .name = "struct-field-sum", .body = .struct_field_sum },
    .{ .surface = "array-scalar-sum", .name = "array-scalar-sum", .body = .array_scalar_sum },
    .{ .surface = "optional-scalar-payload", .name = "optional-scalar-payload", .body = .optional_scalar_payload },
    .{ .surface = "error-union-payload", .name = "error-union-payload", .body = .error_union_payload },
    .{ .surface = "slice-loop-sum", .name = "slice-loop-sum", .body = .slice_loop_sum },
    .{ .surface = "fp-literal-return", .name = "fp-literal-return", .body = .fp_literal_return },
    .{ .surface = "comptime-const-mul", .name = "comptime-const-mul", .body = .comptime_const_mul },
    .{ .surface = "global-update", .name = "global-update", .body = .global_update },
    .{ .surface = "add-imm-return", .name = "add-imm-return", .body = .add_imm_return },
    .{ .surface = "tls-read", .name = "tls-read", .body = .tls_read },
    .{ .surface = "tls-bump", .name = "tls-bump", .body = .tls_bump },
    .{ .surface = "atomic-add", .name = "atomic-add", .body = .atomic_add },
    .{ .surface = "inline-asm-barrier", .name = "inline-asm-barrier", .body = .inline_asm_barrier },
    .{ .surface = "aggregate-pair-abi", .name = "aggregate-pair-abi", .body = .aggregate_pair_abi },
    .{ .surface = "float-less", .name = "float-less", .body = .float_less },
    .{ .surface = "float-mul", .name = "float-mul", .body = .float_mul },
    .{ .surface = "float-add", .name = "float-add", .body = .float_add },
    .{ .surface = "float-select", .name = "float-select", .body = .float_select },
    .{ .surface = "float-sub", .name = "float-sub", .body = .float_sub },
    .{ .surface = "double-div", .name = "double-div", .body = .double_div },
    .{ .surface = "float-rem", .name = "float-rem", .body = .float_rem },
    .{ .surface = "void-noop-call", .name = "void-noop-call", .body = .void_noop_call },
    .{ .surface = "volatile-roundtrip", .name = "volatile-roundtrip", .body = .volatile_roundtrip },
    .{ .surface = "i64-arithmetic", .name = "i64-arithmetic", .body = .i64_arithmetic },
    .{ .surface = "checked-add-imm-boundary", .name = "checked-add-imm-boundary", .body = .checked_add_imm_boundary },
    .{ .surface = "checked-global-update-boundary", .name = "checked-global-update-boundary", .body = .checked_global_update_boundary },
    .{ .surface = "checked-pointer-load-store-boundary", .name = "checked-pointer-load-store-boundary", .body = .checked_pointer_load_store_boundary },
    .{ .surface = "checked-branch-mix-boundary", .name = "checked-branch-mix-boundary", .body = .checked_branch_mix_boundary },
    .{ .surface = "checked-call-chain-boundary", .name = "checked-call-chain-boundary", .body = .checked_call_chain_boundary },
    .{ .surface = "checked-tls-bump-boundary", .name = "checked-tls-bump-boundary", .body = .checked_tls_bump_boundary },
    .{ .surface = "checked-array-sum-boundary", .name = "checked-array-sum-boundary", .body = .checked_array_sum_boundary },
    .{ .surface = "checked-struct-sum-boundary", .name = "checked-struct-sum-boundary", .body = .checked_struct_sum_boundary },
    .{ .surface = "checked-slice-loop-sum-boundary", .name = "checked-slice-loop-sum-boundary", .body = .checked_slice_loop_sum_boundary },
    .{ .surface = "checked-add-runtime-boundary", .name = "checked-add-runtime-boundary", .body = .checked_add_runtime_boundary },
    .{ .surface = "hidden-global-access", .name = "hidden-global-access", .body = .hidden_global_access },
    .{ .surface = "mixed-c-zig-add", .name = "mixed-c-zig-add", .body = .mixed_c_zig_add },
    .{ .surface = "mixed-c-zig-panic-add", .name = "mixed-c-zig-panic-add", .body = .mixed_c_zig_panic_add },
    .{ .surface = "umul-fix-sat-i64", .name = "umul-fix-sat-i64", .body = .umul_fix_sat_i64 },
    .{ .surface = "inherit-i64-return", .name = "inherit-i64-return", .body = .inherit_i64_return },
    .{ .surface = "compile-asm-unreachable", .name = "compile-asm-unreachable", .body = .compile_asm_unreachable },
    .{ .surface = "start-trampoline", .name = "start-trampoline", .body = .start_trampoline },
    .{ .surface = "getauxval-pointer-walk", .name = "getauxval-pointer-walk", .body = .getauxval_pointer_walk },
    .{ .surface = "f128-sret-byval", .name = "f128-sret-byval", .body = .f128_sret_byval },
    .{ .surface = "noreturn-unreachable-stub", .name = "noreturn-unreachable-stub", .body = .noreturn_unreachable_stub },
    .{ .surface = "address-space-volatile-store", .name = "address-space-volatile-store", .body = .address_space_volatile_store },
    .{ .surface = "raw-start-loop", .name = "raw-start-loop", .body = .raw_start_loop },
    .{ .surface = "i1-const-return", .name = "i1-const-return", .body = .i1_const_return },
    .{ .surface = "constant-string-slice-return", .name = "constant-string-slice-return", .body = .constant_string_slice_return },
    .{ .surface = "libfuzzer-vtable-run", .name = "libfuzzer-vtable-run", .body = .libfuzzer_vtable_run },
    .{ .surface = "str-from-float-help", .name = "str-from-float-help", .body = .str_from_float_help },
    .{ .surface = "base64-decode-base64-full", .name = "base64-decode-base64-full", .body = .base64_decode_base64_full },
    .{ .surface = "base64-decode-step", .name = "base64-decode-step", .body = .base64_decode_step },
    .{ .surface = "base64-store-step", .name = "base64-store-step", .body = .base64_store_step },
    .{ .surface = "base64-residual-byte-step", .name = "base64-residual-byte-step", .body = .base64_residual_byte_step },
    .{ .surface = "base64-padding-tail-step", .name = "base64-padding-tail-step", .body = .base64_padding_tail_step },
    .{ .surface = "base64-padding-loop-step", .name = "base64-padding-loop-step", .body = .base64_padding_loop_step },
    .{ .surface = "base64-padding-length-step", .name = "base64-padding-length-step", .body = .base64_padding_length_step },
    .{ .surface = "base64-chunk-guard-step", .name = "base64-chunk-guard-step", .body = .base64_chunk_guard_step },
    .{ .surface = "base64-source-stride-step", .name = "base64-source-stride-step", .body = .base64_source_stride_step },
    .{ .surface = "base64-source-bundle-step", .name = "base64-source-bundle-step", .body = .base64_source_bundle_step },
    .{ .surface = "base64-next-source-bundle-step", .name = "base64-next-source-bundle-step", .body = .base64_next_source_bundle_step },
    .{ .surface = "base64-third-source-bundle-step", .name = "base64-third-source-bundle-step", .body = .base64_third_source_bundle_step },
    .{ .surface = "base64-bit-buffer-store-step", .name = "base64-bit-buffer-store-step", .body = .base64_bit_buffer_store_step },
    .{ .surface = "base64-loop-advance-step", .name = "base64-loop-advance-step", .body = .base64_loop_advance_step },
    .{ .surface = "base64-residual-guard-step", .name = "base64-residual-guard-step", .body = .base64_residual_guard_step },
    .{ .surface = "base64-residual-bundle-step", .name = "base64-residual-bundle-step", .body = .base64_residual_bundle_step },
    .{ .surface = "base64-residual-store-step", .name = "base64-residual-store-step", .body = .base64_residual_store_step },
    .{ .surface = "base64-residual-length-step", .name = "base64-residual-length-step", .body = .base64_residual_length_step },
    .{ .surface = "base64-residual-table-check-step", .name = "base64-residual-table-check-step", .body = .base64_residual_table_check_step },
    .{ .surface = "base64-residual-accumulator-step", .name = "base64-residual-accumulator-step", .body = .base64_residual_accumulator_step },
    .{ .surface = "base64-residual-loop-advance-step", .name = "base64-residual-loop-advance-step", .body = .base64_residual_loop_advance_step },
    .{ .surface = "base64-residual-padding-check-step", .name = "base64-residual-padding-check-step", .body = .base64_residual_padding_check_step },
    .{ .surface = "base64-residual-final-mask-step", .name = "base64-residual-final-mask-step", .body = .base64_residual_final_mask_step },
    .{ .surface = "base64-residual-padding-loop-step", .name = "base64-residual-padding-loop-step", .body = .base64_residual_padding_loop_step },
    .{ .surface = "base64-decode-exit-step", .name = "base64-decode-exit-step", .body = .base64_decode_exit_step },
    .{ .surface = "table-indexed-load", .name = "table-indexed-load", .body = .table_indexed_load },
};
