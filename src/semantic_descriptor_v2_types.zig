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
    global_load,
    runtime_phi_merge,
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
    float_mul,
    float_add,
    float_select,
    float_sub,
    double_div,
    float_rem,
    void_noop_call,
    volatile_roundtrip,
    i64_arithmetic,
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

pub const ReleaseCanonicalizationSummary = struct {
    ran: bool = false,
    constant_folded_int_ops: usize = 0,
    constant_folded_fp_ops: usize = 0,
    dead_local_computations: usize = 0,
    canonicalized_select_fcmp: usize = 0,
    simplified_branch_to_return: usize = 0,
    simplified_single_pred_phi: usize = 0,
    checked_boundaries_seen: usize = 0,
    checked_boundaries_preserved: usize = 0,
};

pub const ReleaseCanonicalizationReport = struct {
    observed: ReleaseCanonicalizationSummary = .{},
    applied: ReleaseCanonicalizationSummary = .{},
    after: ReleaseCanonicalizationSummary = .{},
    checks_preserved: bool = false,
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
    ReleaseSafeCheckRemoved,
    DuplicateSsaValue,
    UndefinedValue,
    UnknownBranchTarget,
    PhiPredecessorMismatch,
    CallSignatureMismatch,
    MemoryTypeMismatch,
    ReturnTypeMismatch,
};

