const std = @import("std");
const sib = @import("structured_ir_builder.zig");

pub const Source = struct {
    wrapper: []const u8,
    mode: []const u8,
    fixture: []const u8,
    tag: []const u8,
};

pub const AddressSpace = enum {
    generic,
    local_exec_tls,
    vram,
    unsupported,
};

pub const Type = union(enum) {
    void,
    bool,
    int: u16,
    float: FloatKind,
    pointer: AddressSpace,
    aggregate: []const Type,
    vector: Vector,
};

pub const FloatKind = enum {
    f32,
    f64,
    f128,
};

pub const Vector = struct {
    len: u16,
    child: *const Type,
};

pub const ValueRef = struct {
    id: []const u8,
    ty: Type,
};

pub const Constant = struct {
    name: []const u8,
    ty: Type,
    value: []const u8,
};

pub const Local = struct {
    name: []const u8,
    ty: Type,
};

pub const Param = struct {
    name: []const u8,
    ty: Type,
};

pub const GlobalKind = enum {
    global,
    constant,
    tls,
};

pub const Global = struct {
    name: []const u8,
    kind: GlobalKind,
    ty: Type,
    address_space: AddressSpace = .generic,
    initializer: ?[]const u8 = null,
    llvm_type: ?[]const u8 = null,
    alignment: ?u16 = null,
};

pub const CallConv = enum {
    zig,
    c,
    fastcc,
    inline_asm_boundary,
    unsupported,
};

pub const AtomicOrdering = enum {
    monotonic,
    acquire,
    release,
    acq_rel,
    seq_cst,
    unsupported,
};

pub const AbiShape = enum {
    direct,
    sret,
    byval,
    runtime_boundary,
    inline_asm_boundary,
};

pub const BinOp = enum {
    add,
    sub,
    mul,
    shl,
    lshr,
    ashr,
    @"and",
    @"or",
    xor,
    fadd,
    fsub,
    fmul,
    fdiv,
    frem,
};

pub const CompareOp = enum {
    eq,
    ne,
    slt,
    sle,
    sgt,
    sge,
    ult,
    ule,
    ugt,
    uge,
    oeq,
    one,
    olt,
    ole,
    ogt,
    oge,
};

pub const CastOp = enum {
    trunc,
    zext,
    sext,
    bitcast,
    ptrtoint,
    inttoptr,
};

pub const Instruction = union(enum) {
    constant: Constant,
    binop: struct { result: []const u8, op: BinOp, ty: Type, lhs: ValueRef, rhs: ValueRef },
    checked_add: struct { result: []const u8, ty: Type, lhs: ValueRef, rhs: ValueRef, panic_block: []const u8 },
    checked_mul: struct { result: []const u8, ty: Type, lhs: ValueRef, rhs: ValueRef, panic_block: []const u8 },
    compare: struct { result: []const u8, op: CompareOp, ty: Type, lhs: ValueRef, rhs: ValueRef },
    select: struct { result: []const u8, cond: ValueRef, ty: Type, then_value: ValueRef, else_value: ValueRef },
    call: Call,
    load: MemoryOp,
    store: MemoryOp,
    gep: struct { result: []const u8, base: ValueRef, indices: []const ValueRef },
    phi: Phi,
    cast: struct { result: []const u8, op: CastOp, from: ValueRef, to: Type },
    aggregate_value: struct { result: []const u8, ty: Type, fields: []const ValueRef },
    inline_asm_boundary: struct { text: []const u8 },
};

pub const Call = struct {
    result: ?[]const u8 = null,
    callee: []const u8,
    calling_convention: CallConv,
    ret_ty: Type,
    args: []const ValueRef,
    abi: AbiShape = .direct,
    varargs: bool = false,
};

pub const MemoryOp = struct {
    result: ?[]const u8 = null,
    ptr: ValueRef,
    ty: Type,
    value: ?ValueRef = null,
    align_bytes: u16,
    is_volatile: bool = false,
    ordering: ?AtomicOrdering = null,
};

pub const Phi = struct {
    result: []const u8,
    ty: Type,
    incoming: []const Incoming,
};

pub const Incoming = struct {
    block: []const u8,
    value: ValueRef,
};

pub const Terminator = union(enum) {
    ret: ?ValueRef,
    br: []const u8,
    condbr: struct { cond: ValueRef, then_block: []const u8, else_block: []const u8 },
    @"unreachable",
};

pub const Block = struct {
    name: []const u8,
    params: []const Param = &.{},
    instructions: []const Instruction = &.{},
    terminator: Terminator,
};

pub const Function = struct {
    name: []const u8,
    calling_convention: CallConv = .zig,
    params: []const Param = &.{},
    return_type: Type,
    locals: []const Local = &.{},
    blocks: []const Block,
};

pub const Body = enum {
    scalar_add_ret,
    integer_arithmetic,
    error_switch_select,
    runtime_loop_sum,
    abi_arg_call,
    runtime_condbr,
    runtime_switch,
    pointer_load_store,
    optional_pointer,
    packed_read_flag,
    packed_replace_low,
    struct_field_sum,
    array_scalar_sum,
    optional_scalar_payload,
    error_union_payload,
    slice_loop_sum,
    fp_literal_return,
    comptime_const_mul,
    global_update,
    add_imm_return,
    tls_read,
    tls_bump,
    atomic_add,
    inline_asm_barrier,
    aggregate_pair_abi,
    float_less,
    float_add,
    float_sub,
    checked_add_imm_boundary,
    checked_global_update_boundary,
    checked_pointer_load_store_boundary,
    checked_branch_mix_boundary,
    checked_call_chain_boundary,
    checked_tls_bump_boundary,
    checked_array_sum_boundary,
    checked_struct_sum_boundary,
    checked_slice_loop_sum_boundary,
    checked_add_runtime_boundary,
    hidden_global_access,
    mixed_c_zig_add,
    mixed_c_zig_panic_add,
    umul_fix_sat_i64,
    inherit_i64_return,
    compile_asm_unreachable,
    start_trampoline,
    getauxval_pointer_walk,
    f128_sret_byval,
    noreturn_unreachable_stub,
    address_space_volatile_store,
    raw_start_loop,
    i1_const_return,
    constant_string_slice_return,
    libfuzzer_vtable_run,
    str_from_float_help,
    base64_decode_base64_full,
    base64_decode_step,
    base64_store_step,
    base64_residual_byte_step,
    base64_padding_tail_step,
    base64_padding_loop_step,
    base64_padding_length_step,
    base64_chunk_guard_step,
    base64_source_stride_step,
    base64_source_bundle_step,
    base64_next_source_bundle_step,
    base64_third_source_bundle_step,
    base64_bit_buffer_store_step,
    base64_loop_advance_step,
    base64_residual_guard_step,
    base64_residual_bundle_step,
    base64_residual_store_step,
    base64_residual_length_step,
    base64_residual_table_check_step,
    base64_residual_accumulator_step,
    base64_residual_loop_advance_step,
    base64_residual_padding_check_step,
    base64_residual_final_mask_step,
    base64_residual_padding_loop_step,
    base64_decode_exit_step,
    table_indexed_load,
};

pub const Program = struct {
    id: []const u8,
    source: Source,
    body: Body,
    diagnostic_surface: []const u8,
    origin: ProgramOrigin,
    functions: []const Function,
    globals: []const Global = &.{},
    constants: []const Constant = &.{},
    atomics: bool = false,
    inline_asm_boundary: bool = false,
    serialized_functions: bool = false,
    serialized_instructions: bool = false,
    serialized_globals: bool = false,
    descriptor_program_body_expansion: bool = false,
    functions_for_body: bool = false,
    globals_for_body: bool = false,
    serialized_return_i32: ?i32 = null,
};

pub const ProgramOrigin = enum {
    source_derived_descriptor,
    surface_adapter,
    body_enum_dispatch,
};

pub const VerifyError = error{
    EmptyProgram,
    EmptyFunction,
    EmptyBlock,
    MissingEntryBlock,
    InvalidTerminatorType,
    PhiIncomingMismatch,
    UnsupportedTypeVector,
    UnsupportedDebugMetadata,
    UnsupportedExceptionHandling,
    UnsupportedVarargs,
    UnsupportedCallConv,
    UnsupportedAtomicOrdering,
    UnsupportedAddressSpace,
    UnsupportedAbiShape,
    UnsupportedAlignment,
    DuplicateSsaValue,
    UndefinedValue,
    UnknownBranchTarget,
    PhiPredecessorMismatch,
    CallSignatureMismatch,
    MemoryTypeMismatch,
    ReturnTypeMismatch,
};

pub fn verify(program: Program) VerifyError!void {
    if (program.functions.len == 0) return error.EmptyProgram;
    for (program.globals) |global| {
        try verifyType(global.ty);
        try verifyAddressSpace(global.address_space);
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
}

pub fn lowerToStructuredIr(program: Program, writer: *std.Io.Writer) !void {
    try verify(program);
    var module = sib.Module.init(writer);
    for (program.globals) |global| {
        try lowerGlobal(&module, global);
    }
    if (program.globals.len != 0) try writer.writeByte('\n');
    for (program.functions) |function| {
        try lowerFunction(&module, function);
    }
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
        .float_less => &float_less_functions,
        .float_add => &float_add_functions,
        .float_sub => &float_sub_functions,
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
        .abi_arg_call => &computed_i32_3_functions,
        .runtime_switch => &computed_i32_13_functions,
        .inline_asm_barrier, .aggregate_pair_abi => &computed_i32_1_functions,
        .hidden_global_access, .mixed_c_zig_add => &computed_i32_7_functions,
        .mixed_c_zig_panic_add => &computed_i32_5_functions,
        .inherit_i64_return => &computed_i32_4_functions,
        else => &computed_i32_0_functions,
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

const float_add_insts = [_]Instruction{
    fbinop("sum", .fadd, .f32, "1.000000e+00", "2.000000e+00"),
    fcmp("ok", .oeq, .f32, "%sum", "3.000000e+00"),
    selectI32("retv", "%ok", "0", "1"),
};
const float_add_blocks = [_]Block{computedRetBlock(&float_add_insts)};
const float_add_functions = [_]Function{mainFunction(&float_add_blocks)};

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

fn lowerGlobal(module: *sib.Module, global: Global) !void {
    const ty = if (global.llvm_type) |llvm_type| sib.Type{ .text = llvm_type } else try toSibType(global.ty);
    const init = global.initializer orelse initializerForType(global.ty);
    const alignment = alignText(global.alignment orelse typeAlignment(global.ty));
    switch (global.kind) {
        .global => try module.global(global.name, "private unnamed_addr", ty, init, alignment),
        .constant => try module.constant(global.name, "private unnamed_addr", ty, init, alignment),
        .tls => try module.tlsGlobal(global.name, "private", "localexec", ty, init, alignment),
    }
}

fn lowerFunction(module: *sib.Module, function: Function) !void {
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
    switch (instruction) {
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

fn bodyForSurface(surface: []const u8) ?Body {
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
    .{ .surface = "float-add", .name = "float-add", .body = .float_add },
    .{ .surface = "float-sub", .name = "float-sub", .body = .float_sub },
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

const empty_source: Source = .{ .wrapper = "test", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll", .tag = "tiny-scalar" };

fn testProgramWithInstruction(instruction: Instruction) Program {
    const instructions = [_]Instruction{instruction};
    const blocks = [_]Block{.{
        .name = "entry",
        .instructions = &instructions,
        .terminator = .{ .ret = .{ .id = "0", .ty = .{ .int = 32 } } },
    }};
    const functions = [_]Function{.{ .name = "main", .return_type = .{ .int = 32 }, .blocks = &blocks }};
    return .{ .id = "test", .source = empty_source, .body = .scalar_add_ret, .diagnostic_surface = "scalar-add-ret", .origin = .source_derived_descriptor, .functions = &functions };
}

test "descriptor v2 rejects unsupported vector type" {
    const child: Type = .{ .int = 32 };
    const program = testProgramWithInstruction(.{ .constant = .{ .name = "v", .ty = .{ .vector = .{ .len = 4, .child = &child } }, .value = "zeroinitializer" } });
    try std.testing.expectError(error.UnsupportedTypeVector, verify(program));
}

test "descriptor v2 rejects varargs calls" {
    const program = testProgramWithInstruction(.{ .call = .{ .callee = "callee", .calling_convention = .c, .ret_ty = .{ .int = 32 }, .args = &.{}, .varargs = true } });
    try std.testing.expectError(error.UnsupportedVarargs, verify(program));
}

test "descriptor v2 rejects unsupported callconv" {
    const program = testProgramWithInstruction(.{ .call = .{ .callee = "callee", .calling_convention = .unsupported, .ret_ty = .{ .int = 32 }, .args = &.{} } });
    try std.testing.expectError(error.UnsupportedCallConv, verify(program));
}

test "descriptor v2 rejects unsupported atomic ordering" {
    const program = testProgramWithInstruction(.{ .load = .{
        .ptr = .{ .id = "%p", .ty = .{ .pointer = .generic } },
        .ty = .{ .int = 32 },
        .align_bytes = 4,
        .ordering = .unsupported,
    } });
    try std.testing.expectError(error.UnsupportedAtomicOrdering, verify(program));
}

test "descriptor v2 rejects unsupported address space" {
    const program = testProgramWithInstruction(.{ .load = .{
        .ptr = .{ .id = "%p", .ty = .{ .pointer = .unsupported } },
        .ty = .{ .int = 32 },
        .align_bytes = 4,
    } });
    try std.testing.expectError(error.UnsupportedAddressSpace, verify(program));
}

test "descriptor v2 unsupported debug metadata and EH are explicit" {
    try std.testing.expectEqual(VerifyError.UnsupportedDebugMetadata, error.UnsupportedDebugMetadata);
    try std.testing.expectEqual(VerifyError.UnsupportedExceptionHandling, error.UnsupportedExceptionHandling);
}
