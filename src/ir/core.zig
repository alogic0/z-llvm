const std = @import("std");

pub const Type = union(enum) {
    void,
    int: u16,
    half,
    float,
    double,
    x86_fp80,
    fp128,
    metadata,
    ptr,
    aggregate: []const u8,
    vector: VectorType,

    pub fn eql(a: Type, b: Type) bool {
        return switch (a) {
            .void => b == .void,
            .int => |bits| switch (b) {
                .int => |other_bits| bits == other_bits,
                .void, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => false,
            },
            .half => b == .half,
            .float => b == .float,
            .double => b == .double,
            .x86_fp80 => b == .x86_fp80,
            .fp128 => b == .fp128,
            .metadata => b == .metadata,
            .ptr => b == .ptr,
            .aggregate => |text| switch (b) {
                .aggregate => |other_text| std.mem.eql(u8, text, other_text),
                .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
            },
            .vector => |vector| switch (b) {
                .vector => |other_vector| vector.eql(other_vector),
                .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => false,
            },
        };
    }

    pub fn isVector(ty: Type) bool {
        return ty == .vector;
    }

    pub fn format(ty: Type, writer: anytype) !void {
        switch (ty) {
            .void => try writer.writeAll("void"),
            .int => |bits| try writer.print("i{}", .{bits}),
            .half => try writer.writeAll("half"),
            .float => try writer.writeAll("float"),
            .double => try writer.writeAll("double"),
            .x86_fp80 => try writer.writeAll("x86_fp80"),
            .fp128 => try writer.writeAll("fp128"),
            .metadata => try writer.writeAll("metadata"),
            .ptr => try writer.writeAll("ptr"),
            .aggregate => |text| try writer.writeAll(text),
            .vector => |vector| try vector.format(writer),
        }
    }
};

pub const VectorElementType = union(enum) {
    int: u16,
    half,
    float,
    double,
    fp128,
    ptr,

    pub fn eql(a: VectorElementType, b: VectorElementType) bool {
        return switch (a) {
            .int => |bits| switch (b) {
                .int => |other_bits| bits == other_bits,
                .half, .float, .double, .fp128, .ptr => false,
            },
            .half => b == .half,
            .float => b == .float,
            .double => b == .double,
            .fp128 => b == .fp128,
            .ptr => b == .ptr,
        };
    }

    pub fn toType(elem_ty: VectorElementType) Type {
        return switch (elem_ty) {
            .int => |bits| .{ .int = bits },
            .half => .half,
            .float => .float,
            .double => .double,
            .fp128 => .fp128,
            .ptr => .ptr,
        };
    }

    pub fn format(elem_ty: VectorElementType, writer: anytype) !void {
        switch (elem_ty) {
            .int => |bits| try writer.print("i{}", .{bits}),
            .half => try writer.writeAll("half"),
            .float => try writer.writeAll("float"),
            .double => try writer.writeAll("double"),
            .fp128 => try writer.writeAll("fp128"),
            .ptr => try writer.writeAll("ptr"),
        }
    }
};

pub const VectorType = struct {
    len: u32,
    elem_ty: VectorElementType,

    pub fn eql(a: VectorType, b: VectorType) bool {
        return a.len == b.len and a.elem_ty.eql(b.elem_ty);
    }

    pub fn format(vector: VectorType, writer: anytype) !void {
        try writer.print("<{} x ", .{vector.len});
        try vector.elem_ty.format(writer);
        try writer.writeAll(">");
    }
};

pub const Value = union(enum) {
    named: []const u8,
    int: i128,
    fp: []const u8,
    undef,
    poison,
    null_value,
    zero_initializer,
    vector: []const u8,
    constant_expr: []const u8,

    pub fn eql(a: Value, b: Value) bool {
        return switch (a) {
            .named => |name| switch (b) {
                .named => |other_name| std.mem.eql(u8, name, other_name),
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
            },
            .int => |value| switch (b) {
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
                .int => |other_value| value == other_value,
            },
            .fp => |text| switch (b) {
                .fp => |other_text| std.mem.eql(u8, text, other_text),
                .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
            },
            .undef => b == .undef,
            .poison => b == .poison,
            .null_value => b == .null_value,
            .zero_initializer => b == .zero_initializer,
            .vector => |text| switch (b) {
                .vector => |other_text| std.mem.eql(u8, text, other_text),
                .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .constant_expr => false,
            },
            .constant_expr => |text| switch (b) {
                .constant_expr => |other_text| std.mem.eql(u8, text, other_text),
                .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => false,
            },
        };
    }

    pub fn format(value: Value, writer: anytype) !void {
        switch (value) {
            .named => |name| {
                if (std.mem.startsWith(u8, name, "@") or std.mem.startsWith(u8, name, "!")) {
                    try writer.writeAll(name);
                } else {
                    try writer.print("%{s}", .{name});
                }
            },
            .int => |int| try writer.print("{}", .{int}),
            .fp => |text| try writer.writeAll(text),
            .undef => try writer.writeAll("undef"),
            .poison => try writer.writeAll("poison"),
            .null_value => try writer.writeAll("null"),
            .zero_initializer => try writer.writeAll("zeroinitializer"),
            .vector => |text| try writer.writeAll(text),
            .constant_expr => |text| try writer.writeAll(text),
        }
    }
};

pub const BinaryOp = enum {
    fadd,
    fsub,
    fmul,
    fdiv,
    frem,
    add,
    sub,
    mul,
    @"and",
    @"or",
    xor,
    shl,
    lshr,
    ashr,
    udiv,
    sdiv,
    urem,
    srem,

    pub fn parse(text: []const u8) ?BinaryOp {
        if (std.mem.eql(u8, text, "fadd")) return .fadd;
        if (std.mem.eql(u8, text, "fsub")) return .fsub;
        if (std.mem.eql(u8, text, "fmul")) return .fmul;
        if (std.mem.eql(u8, text, "fdiv")) return .fdiv;
        if (std.mem.eql(u8, text, "frem")) return .frem;
        if (std.mem.eql(u8, text, "add")) return .add;
        if (std.mem.eql(u8, text, "sub")) return .sub;
        if (std.mem.eql(u8, text, "mul")) return .mul;
        if (std.mem.eql(u8, text, "and")) return .@"and";
        if (std.mem.eql(u8, text, "or")) return .@"or";
        if (std.mem.eql(u8, text, "xor")) return .xor;
        if (std.mem.eql(u8, text, "shl")) return .shl;
        if (std.mem.eql(u8, text, "lshr")) return .lshr;
        if (std.mem.eql(u8, text, "ashr")) return .ashr;
        if (std.mem.eql(u8, text, "udiv")) return .udiv;
        if (std.mem.eql(u8, text, "sdiv")) return .sdiv;
        if (std.mem.eql(u8, text, "urem")) return .urem;
        if (std.mem.eql(u8, text, "srem")) return .srem;
        return null;
    }

    pub fn name(op: BinaryOp) []const u8 {
        return @tagName(op);
    }
};

pub const BinaryFlags = struct {
    nsw: bool = false,
    nuw: bool = false,
    exact: bool = false,
    disjoint: bool = false,

    pub fn any(flags: BinaryFlags) bool {
        return flags.nsw or flags.nuw or flags.exact or flags.disjoint;
    }
};

pub const FastMathFlags = struct {
    fast: bool = false,
    nnan: bool = false,
    ninf: bool = false,
    nsz: bool = false,
    arcp: bool = false,
    contract: bool = false,
    afn: bool = false,
    reassoc: bool = false,

    pub fn any(flags: FastMathFlags) bool {
        return flags.fast or flags.nnan or flags.ninf or flags.nsz or
            flags.arcp or flags.contract or flags.afn or flags.reassoc;
    }
};

pub const CastOp = enum {
    trunc,
    zext,
    sext,
    fpext,
    fptrunc,
    fptosi,
    fptoui,
    sitofp,
    uitofp,
    bitcast,
    ptrtoint,
    inttoptr,

    pub fn parse(text: []const u8) ?CastOp {
        if (std.mem.eql(u8, text, "trunc")) return .trunc;
        if (std.mem.eql(u8, text, "zext")) return .zext;
        if (std.mem.eql(u8, text, "sext")) return .sext;
        if (std.mem.eql(u8, text, "fpext")) return .fpext;
        if (std.mem.eql(u8, text, "fptrunc")) return .fptrunc;
        if (std.mem.eql(u8, text, "fptosi")) return .fptosi;
        if (std.mem.eql(u8, text, "fptoui")) return .fptoui;
        if (std.mem.eql(u8, text, "sitofp")) return .sitofp;
        if (std.mem.eql(u8, text, "uitofp")) return .uitofp;
        if (std.mem.eql(u8, text, "bitcast")) return .bitcast;
        if (std.mem.eql(u8, text, "ptrtoint")) return .ptrtoint;
        if (std.mem.eql(u8, text, "inttoptr")) return .inttoptr;
        return null;
    }

    pub fn name(op: CastOp) []const u8 {
        return @tagName(op);
    }
};

pub const IcmpPredicate = enum {
    eq,
    ne,
    sgt,
    sge,
    slt,
    sle,
    ugt,
    uge,
    ult,
    ule,

    pub fn parse(text: []const u8) ?IcmpPredicate {
        if (std.mem.eql(u8, text, "eq")) return .eq;
        if (std.mem.eql(u8, text, "ne")) return .ne;
        if (std.mem.eql(u8, text, "sgt")) return .sgt;
        if (std.mem.eql(u8, text, "sge")) return .sge;
        if (std.mem.eql(u8, text, "slt")) return .slt;
        if (std.mem.eql(u8, text, "sle")) return .sle;
        if (std.mem.eql(u8, text, "ugt")) return .ugt;
        if (std.mem.eql(u8, text, "uge")) return .uge;
        if (std.mem.eql(u8, text, "ult")) return .ult;
        if (std.mem.eql(u8, text, "ule")) return .ule;
        return null;
    }

    pub fn name(predicate: IcmpPredicate) []const u8 {
        return @tagName(predicate);
    }
};

pub const Param = struct {
    ty: Type,
    attrs: ?[]const u8 = null,
    name: []const u8,
};

pub const DeclParam = struct {
    ty: Type,
    attrs: ?[]const u8 = null,
};

pub const FunctionLinkage = enum {
    default,
    internal,
    private,
    external,
    extern_weak,
    weak,
    weak_odr,

    pub fn parse(text: []const u8) ?FunctionLinkage {
        if (std.mem.eql(u8, text, "internal")) return .internal;
        if (std.mem.eql(u8, text, "private")) return .private;
        if (std.mem.eql(u8, text, "external")) return .external;
        if (std.mem.eql(u8, text, "extern_weak")) return .extern_weak;
        if (std.mem.eql(u8, text, "weak")) return .weak;
        if (std.mem.eql(u8, text, "weak_odr")) return .weak_odr;
        return null;
    }

    pub fn format(linkage: FunctionLinkage, writer: anytype) !void {
        switch (linkage) {
            .default => {},
            .internal => try writer.writeAll("internal "),
            .private => try writer.writeAll("private "),
            .external => try writer.writeAll("external "),
            .extern_weak => try writer.writeAll("extern_weak "),
            .weak => try writer.writeAll("weak "),
            .weak_odr => try writer.writeAll("weak_odr "),
        }
    }
};

pub const FunctionVisibility = enum {
    default,
    hidden,
    protected,

    pub fn parse(text: []const u8) ?FunctionVisibility {
        if (std.mem.eql(u8, text, "hidden")) return .hidden;
        if (std.mem.eql(u8, text, "protected")) return .protected;
        return null;
    }

    pub fn format(visibility: FunctionVisibility, writer: anytype) !void {
        switch (visibility) {
            .default => {},
            .hidden => try writer.writeAll("hidden "),
            .protected => try writer.writeAll("protected "),
        }
    }
};

pub fn isSupportedCallingConvention(text: []const u8) bool {
    return std.mem.eql(u8, text, "ccc") or
        std.mem.eql(u8, text, "fastcc") or
        std.mem.eql(u8, text, "coldcc");
}

pub const GlobalKind = enum {
    global,
    constant,

    pub fn parse(text: []const u8) ?GlobalKind {
        if (std.mem.eql(u8, text, "global")) return .global;
        if (std.mem.eql(u8, text, "constant")) return .constant;
        return null;
    }

    pub fn name(kind: GlobalKind) []const u8 {
        return @tagName(kind);
    }
};

pub const Global = struct {
    name: []const u8,
    linkage: FunctionLinkage = .default,
    address_attrs: ?[]const u8 = null,
    kind: GlobalKind,
    ty: Type,
    initializer: GlobalInitializer,
    attrs: ?[]const u8 = null,

    pub fn deinit(global: *Global, allocator: std.mem.Allocator) void {
        global.initializer.deinit(allocator);
    }
};

pub const GlobalAlias = struct {
    name: []const u8,
    linkage: FunctionLinkage = .default,
    visibility: FunctionVisibility = .default,
    aliased_ty: []const u8,
    target_ty: Type,
    target: []const u8,
};

pub const GlobalArrayInitializer = struct {
    elem_ty: Type,
    values: std.ArrayList(Value),

    pub fn deinit(initializer: *GlobalArrayInitializer, allocator: std.mem.Allocator) void {
        initializer.values.deinit(allocator);
    }
};

pub const GlobalInitializer = union(enum) {
    none,
    scalar: Value,
    array: GlobalArrayInitializer,
    c_string: []const u8,
    @"opaque": []const u8,

    pub fn deinit(initializer: *GlobalInitializer, allocator: std.mem.Allocator) void {
        switch (initializer.*) {
            .none, .scalar, .c_string, .@"opaque" => {},
            .array => |*array| array.deinit(allocator),
        }
    }

    pub fn format(initializer: GlobalInitializer, writer: anytype) !void {
        switch (initializer) {
            .none => {},
            .scalar => |value| try value.format(writer),
            .c_string => |text| try writer.writeAll(text),
            .@"opaque" => |text| try writer.writeAll(text),
            .array => |array| {
                try writer.writeByte('[');
                for (array.values.items, 0..) |value, index| {
                    if (index != 0) try writer.writeAll(", ");
                    try array.elem_ty.format(writer);
                    try writer.writeByte(' ');
                    try value.format(writer);
                }
                try writer.writeByte(']');
            },
        }
    }
};

pub const FunctionDecl = struct {
    name: []const u8,
    ret_ty: Type,
    linkage: FunctionLinkage = .default,
    visibility: FunctionVisibility = .default,
    calling_conv: ?[]const u8 = null,
    ret_attrs: ?[]const u8 = null,
    attrs: ?[]const u8 = null,
    is_varargs: bool = false,
    params: std.ArrayList(DeclParam),

    pub fn init(name: []const u8, ret_ty: Type) FunctionDecl {
        return .{
            .name = name,
            .ret_ty = ret_ty,
            .params = .empty,
        };
    }

    pub fn deinit(decl: *FunctionDecl, allocator: std.mem.Allocator) void {
        decl.params.deinit(allocator);
    }
};

pub const BinaryInst = struct {
    op: BinaryOp,
    flags: BinaryFlags = .{},
    fp_flags: FastMathFlags = .{},
    ty: Type,
    lhs: Value,
    rhs: Value,
};

pub const CastInst = struct {
    op: CastOp,
    flags: CastFlags = .{},
    from_ty: Type,
    value: Value,
    to_ty: Type,
};

pub const CastFlags = struct {
    nneg: bool = false,
    nsw: bool = false,
    nuw: bool = false,

    pub fn eql(a: CastFlags, b: CastFlags) bool {
        return a.nneg == b.nneg and a.nsw == b.nsw and a.nuw == b.nuw;
    }

    pub fn any(flags: CastFlags) bool {
        return flags.nneg or flags.nsw or flags.nuw;
    }
};

pub const FreezeInst = struct {
    ty: Type,
    value: Value,
};

pub const IcmpInst = struct {
    predicate: IcmpPredicate,
    samesign: bool = false,
    operand_ty: Type,
    lhs: Value,
    rhs: Value,
};

pub const FcmpPredicate = enum {
    false,
    oeq,
    ogt,
    oge,
    olt,
    ole,
    one,
    ord,
    uno,
    ueq,
    ugt,
    uge,
    ult,
    ule,
    une,
    true,

    pub fn parse(text: []const u8) ?FcmpPredicate {
        if (std.mem.eql(u8, text, "false")) return .false;
        if (std.mem.eql(u8, text, "oeq")) return .oeq;
        if (std.mem.eql(u8, text, "ogt")) return .ogt;
        if (std.mem.eql(u8, text, "oge")) return .oge;
        if (std.mem.eql(u8, text, "olt")) return .olt;
        if (std.mem.eql(u8, text, "ole")) return .ole;
        if (std.mem.eql(u8, text, "one")) return .one;
        if (std.mem.eql(u8, text, "ord")) return .ord;
        if (std.mem.eql(u8, text, "uno")) return .uno;
        if (std.mem.eql(u8, text, "ueq")) return .ueq;
        if (std.mem.eql(u8, text, "ugt")) return .ugt;
        if (std.mem.eql(u8, text, "uge")) return .uge;
        if (std.mem.eql(u8, text, "ult")) return .ult;
        if (std.mem.eql(u8, text, "ule")) return .ule;
        if (std.mem.eql(u8, text, "une")) return .une;
        if (std.mem.eql(u8, text, "true")) return .true;
        return null;
    }

    pub fn name(predicate: FcmpPredicate) []const u8 {
        return @tagName(predicate);
    }
};

pub const FcmpInst = struct {
    fp_flags: FastMathFlags = .{},
    predicate: FcmpPredicate,
    operand_ty: Type,
    lhs: Value,
    rhs: Value,
};

pub const SelectInst = struct {
    cond_ty: Type,
    cond: Value,
    ty: Type,
    true_value: Value,
    false_value: Value,
};

pub const PhiIncoming = struct {
    value: Value,
    block: []const u8,
};

pub const PhiInst = struct {
    ty: Type,
    incoming: std.ArrayList(PhiIncoming),

    pub fn deinit(phi: *PhiInst, allocator: std.mem.Allocator) void {
        phi.incoming.deinit(allocator);
    }
};

pub const AllocaInst = struct {
    allocated_ty: Type,
    allocated_ty_addrspace: ?[]const u8 = null,
    attrs: ?[]const u8 = null,
};

pub const MemoryAttrs = struct {
    is_volatile: bool = false,
    atomic_ordering: ?[]const u8 = null,
    syncscope: ?[]const u8 = null,
    @"align": ?u64 = null,

    pub fn isAtomic(attrs: MemoryAttrs) bool {
        return attrs.atomic_ordering != null;
    }

    pub fn isBarrier(attrs: MemoryAttrs) bool {
        return attrs.is_volatile or attrs.isAtomic();
    }
};

pub const LoadInst = struct {
    ty: Type,
    ty_addrspace: ?[]const u8 = null,
    ptr: Value,
    ptr_addrspace: ?[]const u8 = null,
    attrs: MemoryAttrs = .{},
};

pub const StoreInst = struct {
    ty: Type,
    ty_addrspace: ?[]const u8 = null,
    value: Value,
    ptr: Value,
    ptr_addrspace: ?[]const u8 = null,
    attrs: MemoryAttrs = .{},
};

pub const AtomicRmwInst = struct {
    op: []const u8,
    ty: Type,
    ptr: Value,
    value: Value,
    ordering: []const u8,
    syncscope: ?[]const u8 = null,
    is_volatile: bool = false,
    @"align": ?u64 = null,
};

pub const CmpxchgInst = struct {
    ptr: Value,
    ty: Type,
    result_ty: Type,
    expected: Value,
    replacement: Value,
    success_ordering: []const u8,
    failure_ordering: []const u8,
    syncscope: ?[]const u8 = null,
    is_weak: bool = false,
    is_volatile: bool = false,
    @"align": ?u64 = null,

    pub fn deinit(cmpxchg: *CmpxchgInst, allocator: std.mem.Allocator) void {
        if (cmpxchg.result_ty == .aggregate) allocator.free(cmpxchg.result_ty.aggregate);
    }
};

pub const FenceInst = struct {
    ordering: []const u8,
    syncscope: ?[]const u8 = null,
};

pub const ExtractElementInst = struct {
    vector_ty: Type,
    vector: Value,
    index_ty: Type,
    index: Value,
};

pub const InsertElementInst = struct {
    vector_ty: Type,
    vector: Value,
    value_ty: Type,
    value: Value,
    index_ty: Type,
    index: Value,
};

pub const ShuffleVectorInst = struct {
    lhs_ty: Type,
    lhs: Value,
    rhs_ty: Type,
    rhs: Value,
    mask_ty: Type,
    mask: Value,
};

pub const ExtractValueInst = struct {
    aggregate_ty: Type,
    aggregate: Value,
    indices: []const u8,
    result_ty: Type,
};

pub const InsertValueInst = struct {
    aggregate_ty: Type,
    aggregate: Value,
    value_ty: Type,
    value: Value,
    indices: []const u8,
};

pub const GepIndex = struct {
    ty: Type,
    value: Value,
};

pub const GepInst = struct {
    source_ty: Type,
    ptr: Value,
    ptr_addrspace: ?[]const u8 = null,
    indices: std.ArrayList(GepIndex),

    pub fn deinit(gep: *GepInst, allocator: std.mem.Allocator) void {
        gep.indices.deinit(allocator);
    }
};

pub const CallArg = struct {
    ty: Type,
    attrs: ?[]const u8 = null,
    value: Value,
};

pub const InlineAsm = struct {
    template: []const u8,
    constraints: []const u8,
    sideeffect: bool = false,
    has_memory_clobber: bool = false,
    may_load: bool = false,
    may_store: bool = false,
};

pub const CallInst = struct {
    ret_ty: Type,
    callee: []const u8,
    callee_value: ?Value = null,
    callee_function_ty: ?[]const u8 = null,
    calling_conv: ?[]const u8 = null,
    ret_attrs: ?[]const u8 = null,
    tail_kind: ?[]const u8 = null,
    inline_asm: ?InlineAsm = null,
    attrs: ?[]const u8 = null,
    operand_bundle: ?[]const u8 = null,
    raw_args: ?[]const u8 = null,
    args: std.ArrayList(CallArg),

    pub fn deinit(call: *CallInst, allocator: std.mem.Allocator) void {
        call.args.deinit(allocator);
    }

    pub fn isDebugVariableLocation(call: CallInst) bool {
        return std.mem.eql(u8, call.callee, "llvm.dbg.value") or
            std.mem.eql(u8, call.callee, "llvm.dbg.declare");
    }
};

pub const Instruction = struct {
    result: ?[]const u8,
    kind: union(enum) {
        binary: BinaryInst,
        cast: CastInst,
        freeze: FreezeInst,
        icmp: IcmpInst,
        fcmp: FcmpInst,
        select: SelectInst,
        phi: PhiInst,
        alloca: AllocaInst,
        load: LoadInst,
        store: StoreInst,
        atomicrmw: AtomicRmwInst,
        cmpxchg: CmpxchgInst,
        fence: FenceInst,
        extractelement: ExtractElementInst,
        insertelement: InsertElementInst,
        shufflevector: ShuffleVectorInst,
        extractvalue: ExtractValueInst,
        insertvalue: InsertValueInst,
        gep: GepInst,
        call: CallInst,
    },
    metadata: ?[]const u8 = null,
    removed: bool = false,
    replacement: ?Value = null,

    pub fn hasSideEffects(instruction: Instruction) bool {
        return instruction.mayWriteMemory() or instruction.kind == .call;
    }

    pub fn mayReadMemory(instruction: Instruction) bool {
        return instruction.kind == .load;
    }

    pub fn mayWriteMemory(instruction: Instruction) bool {
        return instruction.kind == .store;
    }

    pub fn resultType(instruction: Instruction) ?Type {
        return switch (instruction.kind) {
            .binary => |binary| binary.ty,
            .cast => |cast| cast.to_ty,
            .freeze => |freeze| freeze.ty,
            .icmp => |icmp| compareResultType(icmp.operand_ty),
            .fcmp => |fcmp| compareResultType(fcmp.operand_ty),
            .select => |select| select.ty,
            .phi => |phi| phi.ty,
            .alloca => .ptr,
            .load => |load| load.ty,
            .atomicrmw => |atomicrmw| atomicrmw.ty,
            .cmpxchg => |cmpxchg| cmpxchg.result_ty,
            .extractelement => |extract| switch (extract.vector_ty) {
                .vector => |vector| vector.elem_ty.toType(),
                else => null,
            },
            .insertelement => |insert| insert.vector_ty,
            .shufflevector => |shuffle| switch (shuffle.lhs_ty) {
                .vector => |lhs_vector| switch (shuffle.mask_ty) {
                    .vector => |mask_vector| .{ .vector = .{
                        .len = mask_vector.len,
                        .elem_ty = lhs_vector.elem_ty,
                    } },
                    else => null,
                },
                else => null,
            },
            .extractvalue => |extract| extract.result_ty,
            .insertvalue => |insert| insert.aggregate_ty,
            .gep => .ptr,
            .call => |call| if (call.ret_ty == .void) null else call.ret_ty,
            .store, .fence => null,
        };
    }

    pub fn mapOperands(instruction: *Instruction, aliases: std.StringHashMap(Value)) void {
        // Compatibility wrapper: callers historically ignore opaque references.
        _ = @import("operands.zig").mapInstruction(instruction, aliases);
    }

    pub fn deinit(instruction: *Instruction, allocator: std.mem.Allocator) void {
        switch (instruction.kind) {
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => {},
            .cmpxchg => |*cmpxchg| cmpxchg.deinit(allocator),
            .phi => |*phi| phi.deinit(allocator),
            .gep => |*gep| gep.deinit(allocator),
            .call => |*call| call.deinit(allocator),
        }
    }
};

fn compareResultType(operand_ty: Type) Type {
    return switch (operand_ty) {
        .vector => |vector| .{ .vector = .{
            .len = vector.len,
            .elem_ty = .{ .int = 1 },
        } },
        else => .{ .int = 1 },
    };
}

pub const Terminator = union(enum) {
    ret: struct {
        ty: Type,
        value: ?Value = null,
        ptr_addrspace: ?[]const u8 = null,
    },
    br: struct {
        target: []const u8,
        metadata: ?[]const u8 = null,
    },
    condbr: struct {
        cond_ty: Type,
        cond: Value,
        then_target: []const u8,
        else_target: []const u8,
        metadata: ?[]const u8 = null,
    },
    @"switch": SwitchTerminator,
    indirectbr: IndirectBrTerminator,
    @"unreachable",

    pub fn deinit(terminator: *Terminator, allocator: std.mem.Allocator) void {
        switch (terminator.*) {
            .@"switch" => |*switch_term| switch_term.cases.deinit(allocator),
            .indirectbr => |*indirectbr| indirectbr.targets.deinit(allocator),
            .ret, .br, .condbr, .@"unreachable" => {},
        }
    }
};

pub const SwitchCase = struct {
    value_ty: Type,
    value: Value,
    target: []const u8,
};

pub const SwitchTerminator = struct {
    cond_ty: Type,
    cond: Value,
    default_target: []const u8,
    cases: std.ArrayList(SwitchCase),
    metadata: ?[]const u8 = null,
};

pub const IndirectBrTerminator = struct {
    addr_ty: Type,
    addr: Value,
    targets: std.ArrayList([]const u8),
    metadata: ?[]const u8 = null,
};

pub const BasicBlock = struct {
    name: []const u8,
    instructions: std.ArrayList(Instruction),
    terminator: ?Terminator = null,

    pub fn init(name: []const u8) BasicBlock {
        return .{
            .name = name,
            .instructions = .empty,
        };
    }

    pub fn deinit(block: *BasicBlock, allocator: std.mem.Allocator) void {
        for (block.instructions.items) |*instruction| instruction.deinit(allocator);
        if (block.terminator) |*terminator| terminator.deinit(allocator);
        block.instructions.deinit(allocator);
    }
};

pub const Function = struct {
    name: []const u8,
    ret_ty: Type,
    linkage: FunctionLinkage = .default,
    visibility: FunctionVisibility = .default,
    calling_conv: ?[]const u8 = null,
    ret_attrs: ?[]const u8 = null,
    attrs: ?[]const u8 = null,
    params: std.ArrayList(Param),
    blocks: std.ArrayList(BasicBlock),

    pub fn init(name: []const u8, ret_ty: Type) Function {
        return .{
            .name = name,
            .ret_ty = ret_ty,
            .params = .empty,
            .blocks = .empty,
        };
    }

    pub fn deinit(function: *Function, allocator: std.mem.Allocator) void {
        function.params.deinit(allocator);
        for (function.blocks.items) |*block| block.deinit(allocator);
        function.blocks.deinit(allocator);
    }

    pub fn blockIndex(function: Function, name: []const u8) ?usize {
        for (function.blocks.items, 0..) |block, index| {
            if (std.mem.eql(u8, block.name, name)) return index;
        }
        return null;
    }
};

pub const Module = struct {
    allocator: std.mem.Allocator,
    source: []u8,
    owned_strings: std.ArrayList([]u8),
    source_filename: ?[]const u8 = null,
    target_triple: ?[]const u8 = null,
    target_datalayout: ?[]const u8 = null,
    module_asm: std.ArrayList([]const u8),
    named_types: std.ArrayList(NamedTypeDefinition),
    globals: std.ArrayList(Global),
    aliases: std.ArrayList(GlobalAlias),
    comdats: std.ArrayList([]const u8),
    declarations: std.ArrayList(FunctionDecl),
    functions: std.ArrayList(Function),
    attribute_groups: std.ArrayList([]const u8),
    metadata: std.ArrayList([]const u8),

    pub fn parse(allocator: std.mem.Allocator, text: []const u8) !Module {
        return @import("parser.zig").parse(allocator, text);
    }

    pub fn deinit(module: *Module) void {
        for (module.globals.items) |*global| global.deinit(module.allocator);
        module.module_asm.deinit(module.allocator);
        module.named_types.deinit(module.allocator);
        module.globals.deinit(module.allocator);
        module.aliases.deinit(module.allocator);
        module.comdats.deinit(module.allocator);
        for (module.declarations.items) |*decl| decl.deinit(module.allocator);
        module.declarations.deinit(module.allocator);
        for (module.functions.items) |*function| function.deinit(module.allocator);
        module.functions.deinit(module.allocator);
        module.attribute_groups.deinit(module.allocator);
        module.metadata.deinit(module.allocator);
        for (module.owned_strings.items) |owned| module.allocator.free(owned);
        module.owned_strings.deinit(module.allocator);
        module.allocator.free(module.source);
    }

    pub fn ownString(module: *Module, value: []u8) ![]const u8 {
        errdefer module.allocator.free(value);
        try module.owned_strings.append(module.allocator, value);
        return value;
    }

    pub fn print(module: Module, writer: anytype) !void {
        return @import("printer.zig").print(module, writer);
    }

    pub fn verify(module: Module) !void {
        return @import("verifier.zig").verify(module);
    }

    pub fn hasDebugVariableLocationIntrinsics(module: Module) bool {
        for (module.functions.items) |function| {
            for (function.blocks.items) |block| {
                for (block.instructions.items) |instruction| {
                    const call = switch (instruction.kind) {
                        .call => |call| call,
                        else => continue,
                    };
                    if (call.isDebugVariableLocation()) return true;
                }
            }
        }
        return false;
    }
};

pub const NamedTypeDefinition = struct {
    name: []const u8,
    body: []const u8,
    raw: []const u8,
};
