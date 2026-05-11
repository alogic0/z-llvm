const std = @import("std");

pub const Type = union(enum) {
    void,
    int: u16,
    ptr,
    aggregate: []const u8,

    pub fn eql(a: Type, b: Type) bool {
        return switch (a) {
            .void => b == .void,
            .int => |bits| switch (b) {
                .int => |other_bits| bits == other_bits,
                .void, .ptr, .aggregate => false,
            },
            .ptr => b == .ptr,
            .aggregate => |text| switch (b) {
                .aggregate => |other_text| std.mem.eql(u8, text, other_text),
                .void, .int, .ptr => false,
            },
        };
    }

    pub fn format(ty: Type, writer: anytype) !void {
        switch (ty) {
            .void => try writer.writeAll("void"),
            .int => |bits| try writer.print("i{}", .{bits}),
            .ptr => try writer.writeAll("ptr"),
            .aggregate => |text| try writer.writeAll(text),
        }
    }
};

pub const Value = union(enum) {
    named: []const u8,
    int: i128,
    undef,

    pub fn eql(a: Value, b: Value) bool {
        return switch (a) {
            .named => |name| switch (b) {
                .named => |other_name| std.mem.eql(u8, name, other_name),
                .int, .undef => false,
            },
            .int => |value| switch (b) {
                .named, .undef => false,
                .int => |other_value| value == other_value,
            },
            .undef => b == .undef,
        };
    }

    pub fn format(value: Value, writer: anytype) !void {
        switch (value) {
            .named => |name| try writer.print("%{s}", .{name}),
            .int => |int| try writer.print("{}", .{int}),
            .undef => try writer.writeAll("undef"),
        }
    }
};

pub const BinaryOp = enum {
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

    pub fn any(flags: BinaryFlags) bool {
        return flags.nsw or flags.nuw or flags.exact;
    }
};

pub const CastOp = enum {
    trunc,
    zext,
    sext,

    pub fn parse(text: []const u8) ?CastOp {
        if (std.mem.eql(u8, text, "trunc")) return .trunc;
        if (std.mem.eql(u8, text, "zext")) return .zext;
        if (std.mem.eql(u8, text, "sext")) return .sext;
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

    pub fn parse(text: []const u8) ?FunctionLinkage {
        if (std.mem.eql(u8, text, "internal")) return .internal;
        if (std.mem.eql(u8, text, "private")) return .private;
        if (std.mem.eql(u8, text, "external")) return .external;
        return null;
    }

    pub fn format(linkage: FunctionLinkage, writer: anytype) !void {
        switch (linkage) {
            .default => {},
            .internal => try writer.writeAll("internal "),
            .private => try writer.writeAll("private "),
            .external => try writer.writeAll("external "),
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
    kind: GlobalKind,
    ty: Type,
    initializer: Value,
    attrs: ?[]const u8 = null,
};

pub const FunctionDecl = struct {
    name: []const u8,
    ret_ty: Type,
    linkage: FunctionLinkage = .default,
    visibility: FunctionVisibility = .default,
    calling_conv: ?[]const u8 = null,
    attrs: ?[]const u8 = null,
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
    ty: Type,
    lhs: Value,
    rhs: Value,
};

pub const CastInst = struct {
    op: CastOp,
    from_ty: Type,
    value: Value,
    to_ty: Type,
};

pub const FreezeInst = struct {
    ty: Type,
    value: Value,
};

pub const IcmpInst = struct {
    predicate: IcmpPredicate,
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
};

pub const MemoryAttrs = struct {
    is_volatile: bool = false,
    atomic_ordering: ?[]const u8 = null,
    @"align": ?u32 = null,

    pub fn isAtomic(attrs: MemoryAttrs) bool {
        return attrs.atomic_ordering != null;
    }

    pub fn isBarrier(attrs: MemoryAttrs) bool {
        return attrs.is_volatile or attrs.isAtomic();
    }
};

pub const LoadInst = struct {
    ty: Type,
    ptr: Value,
    attrs: MemoryAttrs = .{},
};

pub const StoreInst = struct {
    ty: Type,
    value: Value,
    ptr: Value,
    attrs: MemoryAttrs = .{},
};

pub const GepIndex = struct {
    ty: Type,
    value: Value,
};

pub const GepInst = struct {
    source_ty: Type,
    ptr: Value,
    indices: std.ArrayList(GepIndex),

    pub fn deinit(gep: *GepInst, allocator: std.mem.Allocator) void {
        gep.indices.deinit(allocator);
    }
};

pub const CallArg = struct {
    ty: Type,
    value: Value,
};

pub const CallInst = struct {
    ret_ty: Type,
    callee: []const u8,
    calling_conv: ?[]const u8 = null,
    args: std.ArrayList(CallArg),

    pub fn deinit(call: *CallInst, allocator: std.mem.Allocator) void {
        call.args.deinit(allocator);
    }
};

pub const Instruction = struct {
    result: ?[]const u8,
    kind: union(enum) {
        binary: BinaryInst,
        cast: CastInst,
        freeze: FreezeInst,
        icmp: IcmpInst,
        select: SelectInst,
        phi: PhiInst,
        alloca: AllocaInst,
        load: LoadInst,
        store: StoreInst,
        gep: GepInst,
        call: CallInst,
    },
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
            .icmp => .{ .int = 1 },
            .select => |select| select.ty,
            .phi => |phi| phi.ty,
            .alloca => .ptr,
            .load => |load| load.ty,
            .gep => .ptr,
            .call => |call| if (call.ret_ty == .void) null else call.ret_ty,
            .store => null,
        };
    }

    pub fn mapOperands(instruction: *Instruction, aliases: std.StringHashMap(Value)) void {
        switch (instruction.kind) {
            .binary => |*binary| {
                binary.lhs = resolveValue(aliases, binary.lhs);
                binary.rhs = resolveValue(aliases, binary.rhs);
            },
            .cast => |*cast| cast.value = resolveValue(aliases, cast.value),
            .freeze => |*freeze| freeze.value = resolveValue(aliases, freeze.value),
            .icmp => |*icmp| {
                icmp.lhs = resolveValue(aliases, icmp.lhs);
                icmp.rhs = resolveValue(aliases, icmp.rhs);
            },
            .select => |*select| {
                select.cond = resolveValue(aliases, select.cond);
                select.true_value = resolveValue(aliases, select.true_value);
                select.false_value = resolveValue(aliases, select.false_value);
            },
            .phi => |*phi| for (phi.incoming.items) |*incoming| {
                incoming.value = resolveValue(aliases, incoming.value);
            },
            .alloca => {},
            .load => |*load| load.ptr = resolveValue(aliases, load.ptr),
            .store => |*store| {
                store.value = resolveValue(aliases, store.value);
                store.ptr = resolveValue(aliases, store.ptr);
            },
            .gep => |*gep| {
                gep.ptr = resolveValue(aliases, gep.ptr);
                for (gep.indices.items) |*index| {
                    index.value = resolveValue(aliases, index.value);
                }
            },
            .call => |*call| for (call.args.items) |*arg| {
                arg.value = resolveValue(aliases, arg.value);
            },
        }
    }

    pub fn deinit(instruction: *Instruction, allocator: std.mem.Allocator) void {
        switch (instruction.kind) {
            .binary, .cast, .freeze, .icmp, .select, .alloca, .load, .store => {},
            .phi => |*phi| phi.deinit(allocator),
            .gep => |*gep| gep.deinit(allocator),
            .call => |*call| call.deinit(allocator),
        }
    }
};

fn resolveValue(aliases: std.StringHashMap(Value), value: Value) Value {
    return switch (value) {
        .int, .undef => value,
        .named => |name| aliases.get(name) orelse value,
    };
}

pub const Terminator = union(enum) {
    ret: struct {
        ty: Type,
        value: ?Value = null,
    },
    br: struct {
        target: []const u8,
    },
    condbr: struct {
        cond_ty: Type,
        cond: Value,
        then_target: []const u8,
        else_target: []const u8,
    },
    @"unreachable",
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
        block.instructions.deinit(allocator);
    }
};

pub const Function = struct {
    name: []const u8,
    ret_ty: Type,
    linkage: FunctionLinkage = .default,
    visibility: FunctionVisibility = .default,
    calling_conv: ?[]const u8 = null,
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
    globals: std.ArrayList(Global),
    declarations: std.ArrayList(FunctionDecl),
    functions: std.ArrayList(Function),
    metadata: std.ArrayList([]const u8),

    pub fn parse(allocator: std.mem.Allocator, text: []const u8) !Module {
        return @import("parser.zig").parse(allocator, text);
    }

    pub fn deinit(module: *Module) void {
        module.globals.deinit(module.allocator);
        for (module.declarations.items) |*decl| decl.deinit(module.allocator);
        module.declarations.deinit(module.allocator);
        for (module.functions.items) |*function| function.deinit(module.allocator);
        module.functions.deinit(module.allocator);
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
};
