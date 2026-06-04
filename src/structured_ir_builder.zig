const std = @import("std");
const ir = @import("ir.zig");

var active_direct: ?*DirectBuilder = null;

pub const Type = union(enum) {
    void,
    i1,
    i4,
    i8,
    i12,
    i16,
    i32,
    i64,
    i128,
    v2i64,
    f32,
    f64,
    fp128,
    ptr,
    text: []const u8,

    pub fn llvm(self: Type) []const u8 {
        return switch (self) {
            .void => "void",
            .i1 => "i1",
            .i4 => "i4",
            .i8 => "i8",
            .i12 => "i12",
            .i16 => "i16",
            .i32 => "i32",
            .i64 => "i64",
            .i128 => "i128",
            .v2i64 => "<2 x i64>",
            .f32 => "float",
            .f64 => "double",
            .fp128 => "fp128",
            .ptr => "ptr",
            .text => |text| text,
        };
    }

    pub fn toIr(self: Type) ir.Type {
        return switch (self) {
            .void => .void,
            .i1 => .{ .int = 1 },
            .i4 => .{ .int = 4 },
            .i8 => .{ .int = 8 },
            .i12 => .{ .int = 12 },
            .i16 => .{ .int = 16 },
            .i32 => .{ .int = 32 },
            .i64 => .{ .int = 64 },
            .i128 => .{ .int = 128 },
            .v2i64 => .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 64 } } },
            .f32 => .float,
            .f64 => .double,
            .fp128 => .fp128,
            .ptr => .ptr,
            .text => |text| .{ .aggregate = text },
        };
    }
};

pub const Value = struct {
    ty: Type,
    ref: []const u8,

    pub fn local(ty: Type, name: []const u8) Value {
        return .{ .ty = ty, .ref = name };
    }

    pub fn global(ty: Type, name: []const u8) Value {
        return .{ .ty = ty, .ref = name };
    }

    pub fn constant(ty: Type, text: []const u8) Value {
        return .{ .ty = ty, .ref = text };
    }

    pub fn pointerIntConstant(address: []const u8) Value {
        return .{ .ty = .ptr, .ref = address };
    }
};

pub const Constant = struct {
    name: []const u8,
    ty: Type,
    initializer: []const u8,
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
    initializer: []const u8,
};

pub const Module = struct {
    writer: *std.Io.Writer,

    pub fn init(writer: *std.Io.Writer) Module {
        return .{ .writer = writer };
    }

    pub fn alias(self: *Module, public_name: []const u8, ty: Type, target: []const u8) !void {
        try self.writer.print("@{s} = alias {s}, ptr {s}\n", .{ public_name, ty.llvm(), target });
        if (active_direct) |direct| try direct.alias(public_name, ty, target);
    }

    pub fn global(self: *Module, name: []const u8, linkage: []const u8, ty: Type, initializer: []const u8, align_text: []const u8) !void {
        if (linkage.len == 0) {
            try self.writer.print("@{s} = global {s} {s}, align {s}\n", .{ name, ty.llvm(), initializer, align_text });
        } else {
            try self.writer.print("@{s} = {s} global {s} {s}, align {s}\n", .{ name, linkage, ty.llvm(), initializer, align_text });
        }
        if (active_direct) |direct| try direct.global(name, linkage, .global, ty, initializer, align_text, null);
    }

    pub fn constant(self: *Module, name: []const u8, linkage: []const u8, ty: Type, initializer: []const u8, align_text: []const u8) !void {
        if (linkage.len == 0) {
            try self.writer.print("@{s} = constant {s} {s}, align {s}\n", .{ name, ty.llvm(), initializer, align_text });
        } else {
            try self.writer.print("@{s} = {s} constant {s} {s}, align {s}\n", .{ name, linkage, ty.llvm(), initializer, align_text });
        }
        if (active_direct) |direct| try direct.global(name, linkage, .constant, ty, initializer, align_text, null);
    }

    pub fn stringConstant(self: *Module, name: []const u8, linkage: []const u8, bytes_ty: []const u8, c_string_initializer: []const u8) !void {
        try self.constant(name, linkage, .{ .text = bytes_ty }, c_string_initializer, "1");
    }

    pub fn tlsGlobal(self: *Module, name: []const u8, linkage: []const u8, model: []const u8, ty: Type, initializer: []const u8, align_text: []const u8) !void {
        if (linkage.len == 0) {
            try self.writer.print("@{s} = thread_local({s}) global {s} {s}, align {s}\n", .{ name, model, ty.llvm(), initializer, align_text });
        } else {
            try self.writer.print("@{s} = {s} thread_local({s}) global {s} {s}, align {s}\n", .{ name, linkage, model, ty.llvm(), initializer, align_text });
        }
        if (active_direct) |direct| {
            const address_attrs = try direct.formatArgs("thread_local {s}", .{model});
            try direct.global(name, linkage, .global, ty, initializer, align_text, address_attrs);
        }
    }

    pub fn declare(self: *Module, ret_ty: Type, name: []const u8, params: []const u8) !void {
        try self.writer.print("declare {s} @{s}({s})\n", .{ ret_ty.llvm(), name, params });
        if (active_direct) |direct| try direct.declare(ret_ty, name, params);
    }

    pub fn function(self: *Module, linkage: []const u8, ret_ty: Type, name: []const u8, params: []const u8, attrs: []const u8) !Function {
        try self.writer.print("define {s}{s} @{s}({s}){s} {{\n", .{ linkage, ret_ty.llvm(), name, params, attrs });
        if (active_direct) |direct| try direct.beginFunction(linkage, ret_ty, name, params, attrs);
        return .{ .writer = self.writer };
    }
};

pub const Function = struct {
    writer: *std.Io.Writer,

    pub fn block(self: *Function, name: []const u8) !Block {
        try self.writer.print("{s}:\n", .{name});
        if (active_direct) |direct| try direct.beginBlock(name);
        return .{ .writer = self.writer };
    }

    pub fn end(self: *Function) !void {
        try self.writer.writeAll("}\n\n");
        if (active_direct) |direct| direct.endFunction();
    }
};

pub const Block = struct {
    writer: *std.Io.Writer,

    pub fn br(self: *Block, target: []const u8) !void {
        try self.writer.print("  br label %{s}\n", .{target});
        if (active_direct) |direct| try direct.setTerminator(.{ .br = .{ .target = target } });
    }

    pub fn condBr(self: *Block, cond: Value, then_target: []const u8, else_target: []const u8) !void {
        try self.writer.print("  br i1 {s}, label %{s}, label %{s}\n", .{ cond.ref, then_target, else_target });
        if (active_direct) |direct| try direct.setTerminator(.{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = directValue(cond),
            .then_target = then_target,
            .else_target = else_target,
        } });
    }

    pub fn ret(self: *Block, value: Value) !void {
        try self.writer.print("  ret {s} {s}\n", .{ value.ty.llvm(), value.ref });
        if (active_direct) |direct| try direct.setTerminator(.{ .ret = .{
            .ty = value.ty.toIr(),
            .value = directValue(value),
        } });
    }

    pub fn retVoid(self: *Block) !void {
        try self.writer.writeAll("  ret void\n");
        if (active_direct) |direct| try direct.setTerminator(.{ .ret = .{ .ty = .void } });
    }

    pub fn emitUnreachable(self: *Block) !void {
        try self.writer.writeAll("  unreachable\n");
        if (active_direct) |direct| try direct.setTerminator(.@"unreachable");
    }

    pub fn phi2(self: *Block, result: []const u8, ty: Type, first_value: Value, first_block: []const u8, second_value: Value, second_block: []const u8) !Value {
        try self.writer.print("  %{s} = phi {s} [ {s}, %{s} ], [ {s}, %{s} ]\n", .{ result, ty.llvm(), first_value.ref, first_block, second_value.ref, second_block });
        if (active_direct) |direct| try direct.phi2(result, ty, first_value, first_block, second_value, second_block);
        return Value.local(ty, result);
    }

    pub fn phi3(
        self: *Block,
        result: []const u8,
        ty: Type,
        first_value: Value,
        first_block: []const u8,
        second_value: Value,
        second_block: []const u8,
        third_value: Value,
        third_block: []const u8,
    ) !Value {
        try self.writer.print("  %{s} = phi {s} [ {s}, %{s} ], [ {s}, %{s} ], [ {s}, %{s} ]\n", .{ result, ty.llvm(), first_value.ref, first_block, second_value.ref, second_block, third_value.ref, third_block });
        if (active_direct) |direct| try direct.phi3(result, ty, first_value, first_block, second_value, second_block, third_value, third_block);
        return Value.local(ty, result);
    }

    pub fn binary(self: *Block, result: []const u8, op: []const u8, ty: Type, lhs: Value, rhs: Value) !Value {
        try self.writer.print("  %{s} = {s} {s} {s}, {s}\n", .{ result, op, ty.llvm(), lhs.ref, rhs.ref });
        if (active_direct) |direct| try direct.binary(result, op, ty, lhs, rhs);
        return Value.local(ty, result);
    }

    pub fn binaryFlags(self: *Block, result: []const u8, op_and_flags: []const u8, ty: Type, lhs: Value, rhs: Value) !Value {
        return self.binary(result, op_and_flags, ty, lhs, rhs);
    }

    pub fn cast(self: *Block, result: []const u8, op: []const u8, from: Value, to_ty: Type) !Value {
        try self.writer.print("  %{s} = {s} {s} {s} to {s}\n", .{ result, op, from.ty.llvm(), from.ref, to_ty.llvm() });
        if (active_direct) |direct| try direct.cast(result, op, from, to_ty);
        return Value.local(to_ty, result);
    }

    pub fn castFlags(self: *Block, result: []const u8, op_and_flags: []const u8, from: Value, to_ty: Type) !Value {
        return self.cast(result, op_and_flags, from, to_ty);
    }

    pub fn icmp(self: *Block, result: []const u8, pred: []const u8, ty: Type, lhs: Value, rhs: Value) !Value {
        try self.writer.print("  %{s} = icmp {s} {s} {s}, {s}\n", .{ result, pred, ty.llvm(), lhs.ref, rhs.ref });
        if (active_direct) |direct| try direct.icmp(result, pred, ty, lhs, rhs);
        return Value.local(.i1, result);
    }

    pub fn fcmp(self: *Block, result: []const u8, pred: []const u8, ty: Type, lhs: Value, rhs: Value) !Value {
        try self.writer.print("  %{s} = fcmp {s} {s} {s}, {s}\n", .{ result, pred, ty.llvm(), lhs.ref, rhs.ref });
        if (active_direct) |direct| try direct.fcmp(result, pred, ty, lhs, rhs);
        return Value.local(.i1, result);
    }

    pub fn fcmpLocalName(self: *Block, result: []const u8, pred: []const u8, ty: Type, lhs_name: []const u8, rhs: Value) !Value {
        try self.writer.print("  %{s} = fcmp {s} {s} %{s}, {s}\n", .{ result, pred, ty.llvm(), lhs_name, rhs.ref });
        if (active_direct) |direct| try direct.fcmp(result, pred, ty, Value.local(ty, lhs_name), rhs);
        return Value.local(.i1, result);
    }

    pub fn select(self: *Block, result: []const u8, cond: Value, ty: Type, then_value: Value, else_value: Value) !Value {
        try self.writer.print("  %{s} = select i1 {s}, {s} {s}, {s} {s}\n", .{ result, cond.ref, ty.llvm(), then_value.ref, ty.llvm(), else_value.ref });
        if (active_direct) |direct| try direct.select(result, cond, ty, then_value, else_value);
        return Value.local(ty, result);
    }

    pub fn call(self: *Block, result: ?[]const u8, attrs: []const u8, ret_ty: Type, callee: []const u8, args: []const u8) !?Value {
        if (result) |name| {
            try self.writer.print("  %{s} = {s}call {s} {s}({s})\n", .{ name, attrs, ret_ty.llvm(), callee, args });
            if (active_direct) |direct| try direct.call(name, attrs, ret_ty, callee, args);
            return Value.local(ret_ty, name);
        }
        try self.writer.print("  {s}call {s} {s}({s})\n", .{ attrs, ret_ty.llvm(), callee, args });
        if (active_direct) |direct| try direct.call(null, attrs, ret_ty, callee, args);
        return null;
    }

    pub fn inlineAsmBarrier(self: *Block) !void {
        try self.writer.writeAll("  tail call void asm sideeffect \"\", \"~{memory},~{dirflag},~{fpsr},~{flags}\"()\n");
        if (active_direct) |direct| try direct.inlineAsmBarrier();
    }

    pub fn startTrampolineInlineAsm(self: *Block, self_symbol: []const u8, target_symbol: []const u8) !void {
        try self.writer.writeAll("  tail call void asm sideeffect \".cfi_undefined %rip\", \"~{dirflag},~{fpsr},~{flags}\"()\n");
        try self.writer.print("  tail call void asm sideeffect \" xorl %ebp, %ebp\\0A movq %rsp, %rdi\\0A andq $$-16, %rsp\\0A callq ${{1:P}}\", \"X,X,~{{dirflag}},~{{fpsr}},~{{flags}}\"(ptr nonnull @{s}, ptr nonnull @{s})\n", .{ self_symbol, target_symbol });
        if (active_direct) |direct| {
            try direct.inlineAsmStartCfi();
            try direct.inlineAsmStartTrampoline(self_symbol, target_symbol);
        }
    }

    pub fn alloca(self: *Block, result: []const u8, ty: Type, align_text: []const u8) !Value {
        try self.writer.print("  %{s} = alloca {s}, align {s}\n", .{ result, ty.llvm(), align_text });
        if (active_direct) |direct| try direct.alloca(result, ty, align_text);
        return Value.local(.ptr, result);
    }

    pub fn gep(self: *Block, result: []const u8, elem_ty: Type, base: Value, index_ty: Type, index: Value) !Value {
        try self.writer.print("  %{s} = getelementptr {s}, ptr {s}, {s} {s}\n", .{ result, elem_ty.llvm(), base.ref, index_ty.llvm(), index.ref });
        if (active_direct) |direct| try direct.gep(result, elem_ty, base, &.{.{ .ty = index_ty.toIr(), .value = directValue(index) }});
        return Value.local(.ptr, result);
    }

    pub fn gep2(self: *Block, result: []const u8, elem_ty: Type, base: Value, first_index: Value, second_index: Value) !Value {
        try self.writer.print("  %{s} = getelementptr {s}, ptr {s}, i64 {s}, i64 {s}\n", .{ result, elem_ty.llvm(), base.ref, first_index.ref, second_index.ref });
        if (active_direct) |direct| try direct.gep(result, elem_ty, base, &.{
            .{ .ty = .{ .int = 64 }, .value = directValue(first_index) },
            .{ .ty = .{ .int = 64 }, .value = directValue(second_index) },
        });
        return Value.local(.ptr, result);
    }

    pub fn load(self: *Block, result: []const u8, ty: Type, ptr_value: Value, align_text: []const u8) !Value {
        try self.writer.print("  %{s} = load {s}, ptr {s}, align {s}\n", .{ result, ty.llvm(), ptr_value.ref, align_text });
        if (active_direct) |direct| try direct.load(result, ty, ptr_value, align_text, false);
        return Value.local(ty, result);
    }

    pub fn volatileLoad(self: *Block, result: []const u8, ty: Type, ptr_value: Value, align_text: []const u8) !Value {
        try self.writer.print("  %{s} = load volatile {s}, ptr {s}, align {s}\n", .{ result, ty.llvm(), ptr_value.ref, align_text });
        if (active_direct) |direct| try direct.load(result, ty, ptr_value, align_text, true);
        return Value.local(ty, result);
    }

    pub fn store(self: *Block, value: Value, ptr_value: Value, align_text: []const u8) !void {
        try self.writer.print("  store {s} {s}, ptr {s}, align {s}\n", .{ value.ty.llvm(), value.ref, ptr_value.ref, align_text });
        if (active_direct) |direct| try direct.store(value, ptr_value, align_text, false);
    }

    pub fn volatileStore(self: *Block, value: Value, ptr_value: Value, align_text: []const u8) !void {
        try self.writer.print("  store volatile {s} {s}, ptr {s}, align {s}\n", .{ value.ty.llvm(), value.ref, ptr_value.ref, align_text });
        if (active_direct) |direct| try direct.store(value, ptr_value, align_text, true);
    }

    pub fn extractValue(self: *Block, result: []const u8, aggregate_ty: []const u8, aggregate: []const u8, index: usize, result_ty: Type) !Value {
        try self.writer.print("  %{s} = extractvalue {s} {s}, {}\n", .{ result, aggregate_ty, aggregate, index });
        if (active_direct) |direct| try direct.extractValue(result, aggregate_ty, aggregate, index, result_ty);
        return Value.local(result_ty, result);
    }

    pub fn atomicRmwAdd(self: *Block, result: []const u8, ptr_value: Value, value: Value, ordering: []const u8, align_text: []const u8) !Value {
        try self.writer.print("  %{s} = atomicrmw add ptr {s}, {s} {s} {s}, align {s}\n", .{ result, ptr_value.ref, value.ty.llvm(), value.ref, ordering, align_text });
        if (active_direct) |direct| try direct.atomicRmwAdd(result, ptr_value, value, ordering, align_text);
        return Value.local(value.ty, result);
    }

    pub fn lifetimeStart(self: *Block, ptr_value: Value) !void {
        try self.writer.print("  call void @llvm.lifetime.start.p0(ptr {s})\n", .{ptr_value.ref});
        if (active_direct) |direct| try direct.call(null, "", .void, "@llvm.lifetime.start.p0", try direct.formatArgs("ptr {s}", .{ptr_value.ref}));
    }

    pub fn lifetimeEnd(self: *Block, ptr_value: Value) !void {
        try self.writer.print("  call void @llvm.lifetime.end.p0(ptr {s})\n", .{ptr_value.ref});
        if (active_direct) |direct| try direct.call(null, "", .void, "@llvm.lifetime.end.p0", try direct.formatArgs("ptr {s}", .{ptr_value.ref}));
    }

    pub fn memcpy(self: *Block, dst: Value, src: Value, len: Value, is_volatile: Value) !void {
        try self.writer.print("  call void @llvm.memcpy.p0.p0.i64(ptr {s}, ptr {s}, i64 {s}, i1 {s})\n", .{ dst.ref, src.ref, len.ref, is_volatile.ref });
        if (active_direct) |direct| try direct.call(null, "", .void, "@llvm.memcpy.p0.p0.i64", try direct.formatArgs("ptr {s}, ptr {s}, i64 {s}, i1 {s}", .{ dst.ref, src.ref, len.ref, is_volatile.ref }));
    }

    pub fn memset(self: *Block, dst: Value, byte: Value, len: Value, is_volatile: Value) !void {
        try self.writer.print("  call void @llvm.memset.p0.i64(ptr {s}, i8 {s}, i64 {s}, i1 {s})\n", .{ dst.ref, byte.ref, len.ref, is_volatile.ref });
        if (active_direct) |direct| try direct.call(null, "", .void, "@llvm.memset.p0.i64", try direct.formatArgs("ptr {s}, i8 {s}, i64 {s}, i1 {s}", .{ dst.ref, byte.ref, len.ref, is_volatile.ref }));
    }

    pub fn checkedSAddI32(self: *Block, result: []const u8, lhs: Value, rhs: Value) !CheckedResult {
        try self.writer.print(
            \\  %{s}.checked = tail call {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32 {s}, i32 {s})
            \\  %{s}.value = extractvalue {{ i32, i1 }} %{s}.checked, 0
            \\  %{s}.overflow = extractvalue {{ i32, i1 }} %{s}.checked, 1
            \\
        , .{ result, lhs.ref, rhs.ref, result, result, result, result });
        if (active_direct) |direct| try direct.checkedOverflowCall("sadd", result, lhs, rhs);
        return .{
            .value = Value.local(.i32, result),
            .overflow = Value.local(.i1, result),
        };
    }

    pub fn checkedSMulI32(self: *Block, result: []const u8, lhs: Value, rhs: Value) !CheckedResult {
        try self.writer.print(
            \\  %{s}.checked = tail call {{ i32, i1 }} @llvm.smul.with.overflow.i32(i32 {s}, i32 {s})
            \\  %{s}.value = extractvalue {{ i32, i1 }} %{s}.checked, 0
            \\  %{s}.overflow = extractvalue {{ i32, i1 }} %{s}.checked, 1
            \\
        , .{ result, lhs.ref, rhs.ref, result, result, result, result });
        if (active_direct) |direct| try direct.checkedOverflowCall("smul", result, lhs, rhs);
        return .{
            .value = Value.local(.i32, result),
            .overflow = Value.local(.i1, result),
        };
    }

    pub fn panicEdge(self: *Block, overflow: Value, ok_block: []const u8, panic_block: []const u8) !void {
        try self.condBr(overflow, panic_block, ok_block);
    }
};

pub const CheckedResult = struct {
    value: Value,
    overflow: Value,
};

pub fn int(ty: Type, text: []const u8) Value {
    return Value.constant(ty, text);
}

pub fn local(ty: Type, name: []const u8) Value {
    return Value.local(ty, name);
}

pub fn global(ty: Type, name: []const u8) Value {
    return Value.global(ty, name);
}

pub const DirectBuilder = struct {
    allocator: std.mem.Allocator,
    module: ir.Module,
    current_function: ?usize = null,
    current_block: ?usize = null,
    owned_args: std.ArrayList([]const u8) = .empty,

    pub fn init(allocator: std.mem.Allocator, source_filename: ?[]const u8, target_triple: ?[]const u8) !DirectBuilder {
        return .{
            .allocator = allocator,
            .module = .{
                .allocator = allocator,
                .source = try allocator.dupe(u8, ""),
                .owned_strings = .empty,
                .source_filename = source_filename,
                .target_triple = target_triple,
                .target_datalayout = null,
                .module_asm = .empty,
                .named_types = .empty,
                .globals = .empty,
                .aliases = .empty,
                .comdats = .empty,
                .declarations = .empty,
                .functions = .empty,
                .attribute_groups = .empty,
                .metadata = .empty,
            },
        };
    }

    pub fn activate(self: *DirectBuilder) void {
        active_direct = self;
    }

    pub fn deactivate(self: *DirectBuilder) void {
        if (active_direct == self) active_direct = null;
    }

    pub fn deinit(self: *DirectBuilder) void {
        self.module.deinit();
        for (self.owned_args.items) |arg| self.allocator.free(arg);
        self.owned_args.deinit(self.allocator);
    }

    pub fn finish(self: *DirectBuilder) ir.Module {
        self.deactivate();
        const module = self.module;
        self.module = .{
            .allocator = self.allocator,
            .source = self.allocator.dupe(u8, "") catch @panic("failed to reset direct builder source"),
            .owned_strings = .empty,
            .source_filename = null,
            .target_triple = null,
            .target_datalayout = null,
            .module_asm = .empty,
            .named_types = .empty,
            .globals = .empty,
            .aliases = .empty,
            .comdats = .empty,
            .declarations = .empty,
            .functions = .empty,
            .attribute_groups = .empty,
            .metadata = .empty,
        };
        self.owned_args.clearRetainingCapacity();
        return module;
    }

    pub fn alias(self: *DirectBuilder, public_name: []const u8, ty: Type, target: []const u8) !void {
        try self.module.aliases.append(self.allocator, .{
            .name = public_name,
            .aliased_ty = ty.llvm(),
            .target_ty = .ptr,
            .target = stripGlobalPrefix(target),
        });
    }

    pub fn global(
        self: *DirectBuilder,
        name: []const u8,
        linkage_text: []const u8,
        kind: ir.GlobalKind,
        ty: Type,
        initializer_text: []const u8,
        align_text: []const u8,
        attrs_override: ?[]const u8,
    ) !void {
        const attrs = try self.formatArgs("align {s}", .{align_text});
        try self.module.globals.append(self.allocator, .{
            .name = name,
            .linkage = parseLinkage(linkage_text),
            .address_attrs = attrs_override,
            .kind = kind,
            .ty = ty.toIr(),
            .initializer = try self.parseGlobalInitializer(ty.toIr(), initializer_text),
            .attrs = attrs,
        });
    }

    pub fn declare(self: *DirectBuilder, ret_ty: Type, name: []const u8, params_text: []const u8) !void {
        var decl = ir.FunctionDecl.init(stripGlobalPrefix(name), ret_ty.toIr());
        errdefer decl.deinit(self.allocator);
        var iter = std.mem.splitScalar(u8, params_text, ',');
        while (iter.next()) |raw_param| {
            const param_text = std.mem.trim(u8, raw_param, " \t");
            if (param_text.len == 0) continue;
            const ty_text = firstToken(param_text) orelse continue;
            try decl.params.append(self.allocator, .{ .ty = parseIrType(ty_text) orelse .ptr });
        }
        try self.module.declarations.append(self.allocator, decl);
    }

    pub fn beginFunction(self: *DirectBuilder, linkage_text: []const u8, ret_ty: Type, name: []const u8, params_text: []const u8, attrs_text: []const u8) !void {
        var fn_ir = ir.Function.init(stripGlobalPrefix(name), ret_ty.toIr());
        errdefer fn_ir.deinit(self.allocator);
        fn_ir.linkage = parseLinkage(linkage_text);
        fn_ir.visibility = parseVisibility(linkage_text);
        fn_ir.calling_conv = parseCallingConv(linkage_text);
        fn_ir.attrs = normalizeAttrs(attrs_text);
        var iter = std.mem.splitScalar(u8, params_text, ',');
        while (iter.next()) |raw_param| {
            const param_text = std.mem.trim(u8, raw_param, " \t");
            if (param_text.len == 0) continue;
            const ty_text = firstToken(param_text) orelse continue;
            const name_text = lastToken(param_text) orelse "";
            try fn_ir.params.append(self.allocator, .{
                .ty = parseIrType(ty_text) orelse .ptr,
                .name = stripValuePrefix(name_text),
            });
        }
        try self.module.functions.append(self.allocator, fn_ir);
        self.current_function = self.module.functions.items.len - 1;
        self.current_block = null;
    }

    pub fn endFunction(self: *DirectBuilder) void {
        self.current_function = null;
        self.current_block = null;
    }

    pub fn beginBlock(self: *DirectBuilder, name: []const u8) !void {
        const fn_ir = self.function();
        try fn_ir.blocks.append(self.allocator, ir.BasicBlock.init(name));
        self.current_block = fn_ir.blocks.items.len - 1;
    }

    pub fn setTerminator(self: *DirectBuilder, terminator: ir.Terminator) !void {
        self.block().terminator = terminator;
    }

    pub fn phi2(self: *DirectBuilder, result: []const u8, ty: Type, first_value: Value, first_block: []const u8, second_value: Value, second_block: []const u8) !void {
        var phi: ir.PhiInst = .{ .ty = ty.toIr(), .incoming = .empty };
        errdefer phi.deinit(self.allocator);
        try phi.incoming.append(self.allocator, .{ .value = directValue(first_value), .block = first_block });
        try phi.incoming.append(self.allocator, .{ .value = directValue(second_value), .block = second_block });
        try self.appendInstruction(result, .{ .phi = phi });
    }

    pub fn phi3(
        self: *DirectBuilder,
        result: []const u8,
        ty: Type,
        first_value: Value,
        first_block: []const u8,
        second_value: Value,
        second_block: []const u8,
        third_value: Value,
        third_block: []const u8,
    ) !void {
        var phi: ir.PhiInst = .{ .ty = ty.toIr(), .incoming = .empty };
        errdefer phi.deinit(self.allocator);
        try phi.incoming.append(self.allocator, .{ .value = directValue(first_value), .block = first_block });
        try phi.incoming.append(self.allocator, .{ .value = directValue(second_value), .block = second_block });
        try phi.incoming.append(self.allocator, .{ .value = directValue(third_value), .block = third_block });
        try self.appendInstruction(result, .{ .phi = phi });
    }

    pub fn binary(self: *DirectBuilder, result: []const u8, op_text: []const u8, ty: Type, lhs: Value, rhs: Value) !void {
        const parsed = parseBinaryOpAndFlags(op_text) orelse return;
        try self.appendInstruction(result, .{ .binary = .{
            .op = parsed.op,
            .flags = parsed.flags,
            .fp_flags = parsed.fp_flags,
            .ty = ty.toIr(),
            .lhs = directValue(lhs),
            .rhs = directValue(rhs),
        } });
    }

    pub fn cast(self: *DirectBuilder, result: []const u8, op_text: []const u8, from: Value, to_ty: Type) !void {
        const parsed = parseCastOpAndFlags(op_text);
        try self.appendInstruction(result, .{ .cast = .{
            .op = parsed.op,
            .flags = parsed.flags,
            .from_ty = from.ty.toIr(),
            .value = directValue(from),
            .to_ty = to_ty.toIr(),
        } });
    }

    pub fn icmp(self: *DirectBuilder, result: []const u8, pred_text: []const u8, ty: Type, lhs: Value, rhs: Value) !void {
        try self.appendInstruction(result, .{ .icmp = .{
            .predicate = ir.IcmpPredicate.parse(pred_text) orelse .eq,
            .operand_ty = ty.toIr(),
            .lhs = directValue(lhs),
            .rhs = directValue(rhs),
        } });
    }

    pub fn fcmp(self: *DirectBuilder, result: []const u8, pred_text: []const u8, ty: Type, lhs: Value, rhs: Value) !void {
        try self.appendInstruction(result, .{ .fcmp = .{
            .predicate = ir.FcmpPredicate.parse(pred_text) orelse .oeq,
            .operand_ty = ty.toIr(),
            .lhs = directValue(lhs),
            .rhs = directValue(rhs),
        } });
    }

    pub fn select(self: *DirectBuilder, result: []const u8, cond: Value, ty: Type, then_value: Value, else_value: Value) !void {
        try self.appendInstruction(result, .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = directValue(cond),
            .ty = ty.toIr(),
            .true_value = directValue(then_value),
            .false_value = directValue(else_value),
        } });
    }

    pub fn call(self: *DirectBuilder, result: ?[]const u8, attrs_text: []const u8, ret_ty: Type, callee: []const u8, args_text: []const u8) !void {
        var call_inst: ir.CallInst = .{
            .ret_ty = ret_ty.toIr(),
            .callee = stripGlobalPrefix(callee),
            .calling_conv = parseCallingConv(attrs_text),
            .tail_kind = parseTailKind(attrs_text),
            .args = .empty,
        };
        errdefer call_inst.deinit(self.allocator);
        try self.appendCallArgs(&call_inst, args_text);
        try self.appendInstructionOptional(result, .{ .call = call_inst });
    }

    pub fn inlineAsmBarrier(self: *DirectBuilder) !void {
        var call_inst: ir.CallInst = .{
            .ret_ty = .void,
            .callee = "asm",
            .tail_kind = "tail",
            .inline_asm = .{
                .template = "",
                .constraints = "~{memory},~{dirflag},~{fpsr},~{flags}",
                .sideeffect = true,
                .has_memory_clobber = true,
            },
            .args = .empty,
        };
        errdefer call_inst.deinit(self.allocator);
        try self.appendInstructionOptional(null, .{ .call = call_inst });
    }

    pub fn inlineAsmStartCfi(self: *DirectBuilder) !void {
        var call_inst: ir.CallInst = .{
            .ret_ty = .void,
            .callee = "asm",
            .tail_kind = "tail",
            .inline_asm = .{
                .template = ".cfi_undefined %rip",
                .constraints = "~{dirflag},~{fpsr},~{flags}",
                .sideeffect = true,
            },
            .args = .empty,
        };
        errdefer call_inst.deinit(self.allocator);
        try self.appendInstructionOptional(null, .{ .call = call_inst });
    }

    pub fn inlineAsmStartTrampoline(self: *DirectBuilder, self_symbol: []const u8, target_symbol: []const u8) !void {
        var call_inst: ir.CallInst = .{
            .ret_ty = .void,
            .callee = "asm",
            .tail_kind = "tail",
            .inline_asm = .{
                .template = " xorl %ebp, %ebp\\0A movq %rsp, %rdi\\0A andq $$-16, %rsp\\0A callq ${1:P}",
                .constraints = "X,X,~{dirflag},~{fpsr},~{flags}",
                .sideeffect = true,
            },
            .args = .empty,
        };
        errdefer call_inst.deinit(self.allocator);
        try call_inst.args.append(self.allocator, .{
            .ty = .ptr,
            .attrs = "nonnull",
            .value = .{ .named = try self.formatArgs("@{s}", .{self_symbol}) },
        });
        try call_inst.args.append(self.allocator, .{
            .ty = .ptr,
            .attrs = "nonnull",
            .value = .{ .named = try self.formatArgs("@{s}", .{target_symbol}) },
        });
        try self.appendInstructionOptional(null, .{ .call = call_inst });
    }

    pub fn alloca(self: *DirectBuilder, result: []const u8, ty: Type, align_text: []const u8) !void {
        try self.appendInstruction(result, .{ .alloca = .{
            .allocated_ty = ty.toIr(),
            .attrs = try self.formatArgs("align {s}", .{align_text}),
        } });
    }

    pub fn gep(self: *DirectBuilder, result: []const u8, elem_ty: Type, base: Value, indices: []const ir.GepIndex) !void {
        var gep_inst: ir.GepInst = .{
            .source_ty = elem_ty.toIr(),
            .ptr = directValue(base),
            .indices = .empty,
        };
        errdefer gep_inst.deinit(self.allocator);
        for (indices) |index| try gep_inst.indices.append(self.allocator, index);
        try self.appendInstruction(result, .{ .gep = gep_inst });
    }

    pub fn load(self: *DirectBuilder, result: []const u8, ty: Type, ptr_value: Value, align_text: []const u8, is_volatile: bool) !void {
        try self.appendInstruction(result, .{ .load = .{
            .ty = ty.toIr(),
            .ptr = directValue(ptr_value),
            .attrs = .{ .is_volatile = is_volatile, .@"align" = parseU64(align_text) },
        } });
    }

    pub fn store(self: *DirectBuilder, value: Value, ptr_value: Value, align_text: []const u8, is_volatile: bool) !void {
        try self.appendInstructionOptional(null, .{ .store = .{
            .ty = value.ty.toIr(),
            .value = directValue(value),
            .ptr = directValue(ptr_value),
            .attrs = .{ .is_volatile = is_volatile, .@"align" = parseU64(align_text) },
        } });
    }

    pub fn extractValue(self: *DirectBuilder, result: []const u8, aggregate_ty: []const u8, aggregate: []const u8, index: usize, result_ty: Type) !void {
        try self.appendInstruction(result, .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = aggregate_ty },
            .aggregate = parseValueRef(aggregate),
            .indices = try self.formatArgs("{}", .{index}),
            .result_ty = result_ty.toIr(),
        } });
    }

    pub fn atomicRmwAdd(self: *DirectBuilder, result: []const u8, ptr_value: Value, value: Value, ordering: []const u8, align_text: []const u8) !void {
        try self.appendInstruction(result, .{ .atomicrmw = .{
            .op = "add",
            .ty = value.ty.toIr(),
            .ptr = directValue(ptr_value),
            .value = directValue(value),
            .ordering = ordering,
            .@"align" = parseU64(align_text),
        } });
    }

    pub fn checkedOverflowCall(self: *DirectBuilder, op: []const u8, result: []const u8, lhs: Value, rhs: Value) !void {
        const checked_result = try self.formatArgs("{s}.checked", .{result});
        const value_result = try self.formatArgs("{s}.value", .{result});
        const overflow_result = try self.formatArgs("{s}.overflow", .{result});
        try self.call(checked_result, "tail ", .{ .text = "{ i32, i1 }" }, try self.formatArgs("@llvm.{s}.with.overflow.i32", .{op}), try self.formatArgs("i32 {s}, i32 {s}", .{ lhs.ref, rhs.ref }));
        try self.extractValue(value_result, "{ i32, i1 }", try self.formatArgs("%{s}", .{checked_result}), 0, .i32);
        try self.extractValue(overflow_result, "{ i32, i1 }", try self.formatArgs("%{s}", .{checked_result}), 1, .i1);
    }

    pub fn formatArgs(self: *DirectBuilder, comptime fmt: []const u8, args: anytype) ![]const u8 {
        const text = try std.fmt.allocPrint(self.allocator, fmt, args);
        return try self.module.ownString(text);
    }

    fn parseGlobalInitializer(self: *DirectBuilder, ty: ir.Type, text: []const u8) !ir.GlobalInitializer {
        const trimmed = std.mem.trim(u8, text, " \t");
        switch (ty) {
            .int => {
                if (std.fmt.parseInt(i128, trimmed, 10)) |value| return .{ .scalar = .{ .int = value } } else |_| {}
            },
            .ptr => return .{ .scalar = parseValueRef(trimmed) },
            .float, .double, .x86_fp80, .fp128 => return .{ .scalar = .{ .fp = trimmed } },
            .aggregate => {
                if (std.mem.eql(u8, trimmed, "zeroinitializer")) return .{ .scalar = .zero_initializer };
                if (std.mem.eql(u8, trimmed, "undef")) return .{ .scalar = .undef };
                if (std.mem.startsWith(u8, trimmed, "c\"")) return .{ .c_string = trimmed };
                if (std.mem.startsWith(u8, trimmed, "[") and std.mem.endsWith(u8, trimmed, "]")) {
                    const array = self.parseGlobalArrayInitializer(ty, trimmed) catch return .{ .@"opaque" = trimmed };
                    return .{ .array = array };
                }
            },
            .void, .metadata, .vector => {},
        }
        return .{ .@"opaque" = trimmed };
    }

    fn parseGlobalArrayInitializer(self: *DirectBuilder, ty: ir.Type, text: []const u8) !ir.GlobalArrayInitializer {
        const array_ty = parseArrayType(ty) orelse return error.UnsupportedGlobalVariable;
        var initializer: ir.GlobalArrayInitializer = .{
            .elem_ty = array_ty.elem_ty,
            .values = .empty,
        };
        errdefer initializer.deinit(self.allocator);

        var rest = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
        while (rest.len != 0) {
            const comma = std.mem.indexOfScalar(u8, rest, ',');
            const item = std.mem.trim(u8, if (comma) |index| rest[0..index] else rest, " \t");
            var item_parts = std.mem.tokenizeAny(u8, item, " \t");
            const elem_ty = parseIrType(item_parts.next() orelse return error.UnsupportedGlobalVariable) orelse return error.UnsupportedGlobalVariable;
            if (!elem_ty.eql(array_ty.elem_ty)) return error.UnsupportedGlobalVariable;
            const value = parseValueRef(item_parts.next() orelse return error.UnsupportedGlobalVariable);
            if (item_parts.next() != null) return error.UnsupportedGlobalVariable;
            switch (value) {
                .int, .undef, .poison, .null_value => try initializer.values.append(self.allocator, value),
                .named, .fp, .zero_initializer, .vector, .constant_expr => return error.UnsupportedGlobalVariable,
            }
            rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
        }

        if (initializer.values.items.len != array_ty.len) return error.UnsupportedGlobalVariable;
        return initializer;
    }

    fn appendCallArgs(self: *DirectBuilder, call_inst: *ir.CallInst, args_text: []const u8) !void {
        var iter = std.mem.splitScalar(u8, args_text, ',');
        while (iter.next()) |raw_arg| {
            const arg_text = std.mem.trim(u8, raw_arg, " \t");
            if (arg_text.len == 0) continue;
            const ty_text = firstToken(arg_text) orelse continue;
            const value_text = restAfterFirstToken(arg_text) orelse continue;
            try call_inst.args.append(self.allocator, .{
                .ty = parseIrType(ty_text) orelse .ptr,
                .value = parseValueRef(std.mem.trim(u8, value_text, " \t")),
            });
        }
    }

    fn appendInstruction(self: *DirectBuilder, result: []const u8, kind: @TypeOf(@as(ir.Instruction, undefined).kind)) !void {
        try self.appendInstructionOptional(result, kind);
    }

    fn appendInstructionOptional(self: *DirectBuilder, result: ?[]const u8, kind: @TypeOf(@as(ir.Instruction, undefined).kind)) !void {
        try self.block().instructions.append(self.allocator, .{
            .result = result,
            .kind = kind,
        });
    }

    fn function(self: *DirectBuilder) *ir.Function {
        return &self.module.functions.items[self.current_function.?];
    }

    fn block(self: *DirectBuilder) *ir.BasicBlock {
        const function_ptr = self.function();
        return &function_ptr.blocks.items[self.current_block.?];
    }
};

fn directValue(value: Value) ir.Value {
    return parseValueRef(value.ref);
}

fn parseValueRef(text: []const u8) ir.Value {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return .undef;
    if (std.mem.eql(u8, trimmed, "true")) return .{ .int = 1 };
    if (std.mem.eql(u8, trimmed, "false")) return .{ .int = 0 };
    if (std.mem.eql(u8, trimmed, "undef")) return .undef;
    if (std.mem.eql(u8, trimmed, "poison")) return .poison;
    if (std.mem.eql(u8, trimmed, "null")) return .null_value;
    if (std.mem.eql(u8, trimmed, "zeroinitializer")) return .zero_initializer;
    if (trimmed[0] == '%') return .{ .named = trimmed[1..] };
    if (trimmed[0] == '@') return .{ .named = trimmed };
    if (std.mem.startsWith(u8, trimmed, "inttoptr (") or std.mem.startsWith(u8, trimmed, "ptrtoint (")) return .{ .constant_expr = trimmed };
    if (trimmed[0] == '[' or trimmed[0] == '<' or trimmed[0] == '{') return .{ .constant_expr = trimmed };
    if (std.mem.indexOfAny(u8, trimmed, ".xX") != null) return .{ .fp = trimmed };
    if (std.fmt.parseInt(i128, trimmed, 10)) |value| return .{ .int = value } else |_| {}
    return .{ .named = stripValuePrefix(trimmed) };
}

fn parseIrType(text: []const u8) ?ir.Type {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (std.mem.eql(u8, trimmed, "void")) return .void;
    if (std.mem.eql(u8, trimmed, "ptr")) return .ptr;
    if (std.mem.eql(u8, trimmed, "float")) return .float;
    if (std.mem.eql(u8, trimmed, "double")) return .double;
    if (std.mem.eql(u8, trimmed, "fp128")) return .fp128;
    if (trimmed.len > 1 and trimmed[0] == 'i') {
        const bits = std.fmt.parseInt(u16, trimmed[1..], 10) catch return null;
        return .{ .int = bits };
    }
    return .{ .aggregate = trimmed };
}

const ParsedArrayType = struct {
    len: usize,
    elem_ty: ir.Type,
};

fn parseArrayType(ty: ir.Type) ?ParsedArrayType {
    const text = switch (ty) {
        .aggregate => |text| text,
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return null,
    };
    const trimmed = std.mem.trim(u8, text, " \t");
    if (!std.mem.startsWith(u8, trimmed, "[") or !std.mem.endsWith(u8, trimmed, "]")) return null;
    const inner = std.mem.trim(u8, trimmed[1 .. trimmed.len - 1], " \t");
    const x_index = std.mem.indexOf(u8, inner, " x ") orelse return null;
    const len = std.fmt.parseInt(usize, std.mem.trim(u8, inner[0..x_index], " \t"), 10) catch return null;
    const elem_ty = parseIrType(std.mem.trim(u8, inner[x_index + 3 ..], " \t")) orelse return null;
    return .{ .len = len, .elem_ty = elem_ty };
}

fn parseLinkage(text: []const u8) ir.FunctionLinkage {
    var iter = std.mem.tokenizeAny(u8, text, " \t");
    while (iter.next()) |token| {
        if (ir.FunctionLinkage.parse(token)) |linkage| return linkage;
    }
    return .default;
}

fn parseVisibility(text: []const u8) ir.FunctionVisibility {
    var iter = std.mem.tokenizeAny(u8, text, " \t");
    while (iter.next()) |token| {
        if (ir.FunctionVisibility.parse(token)) |visibility| return visibility;
    }
    return .default;
}

fn parseCallingConv(text: []const u8) ?[]const u8 {
    var iter = std.mem.tokenizeAny(u8, text, " \t");
    while (iter.next()) |token| {
        if (std.mem.eql(u8, token, "ccc") or std.mem.eql(u8, token, "fastcc") or std.mem.eql(u8, token, "coldcc")) return token;
    }
    return null;
}

fn parseTailKind(text: []const u8) ?[]const u8 {
    var iter = std.mem.tokenizeAny(u8, text, " \t");
    while (iter.next()) |token| {
        if (std.mem.eql(u8, token, "tail") or std.mem.eql(u8, token, "musttail") or std.mem.eql(u8, token, "notail")) return token;
    }
    return null;
}

const ParsedBinary = struct {
    op: ir.BinaryOp,
    flags: ir.BinaryFlags = .{},
    fp_flags: ir.FastMathFlags = .{},
};

const ParsedCast = struct {
    op: ir.CastOp,
    flags: ir.CastFlags = .{},
};

fn parseBinaryOpAndFlags(text: []const u8) ?ParsedBinary {
    var parsed: ParsedBinary = .{ .op = .add };
    var saw_op = false;
    var iter = std.mem.tokenizeAny(u8, text, " \t");
    while (iter.next()) |token| {
        if (ir.BinaryOp.parse(token)) |op| {
            parsed.op = op;
            saw_op = true;
        } else if (std.mem.eql(u8, token, "nsw")) {
            parsed.flags.nsw = true;
        } else if (std.mem.eql(u8, token, "nuw")) {
            parsed.flags.nuw = true;
        } else if (std.mem.eql(u8, token, "exact")) {
            parsed.flags.exact = true;
        } else if (std.mem.eql(u8, token, "disjoint")) {
            parsed.flags.disjoint = true;
        } else if (std.mem.eql(u8, token, "fast")) {
            parsed.fp_flags.fast = true;
        }
    }
    return if (saw_op) parsed else null;
}

fn parseCastOpAndFlags(text: []const u8) ParsedCast {
    var parsed: ParsedCast = .{ .op = .bitcast };
    var iter = std.mem.tokenizeAny(u8, text, " \t");
    while (iter.next()) |token| {
        if (ir.CastOp.parse(token)) |op| {
            parsed.op = op;
        } else if (std.mem.eql(u8, token, "nneg")) {
            parsed.flags.nneg = true;
        } else if (std.mem.eql(u8, token, "nsw")) {
            parsed.flags.nsw = true;
        } else if (std.mem.eql(u8, token, "nuw")) {
            parsed.flags.nuw = true;
        }
    }
    return parsed;
}

fn parseU64(text: []const u8) ?u64 {
    return std.fmt.parseInt(u64, std.mem.trim(u8, text, " \t"), 10) catch null;
}

fn firstToken(text: []const u8) ?[]const u8 {
    var iter = std.mem.tokenizeAny(u8, text, " \t");
    return iter.next();
}

fn lastToken(text: []const u8) ?[]const u8 {
    var iter = std.mem.tokenizeAny(u8, text, " \t");
    var last: ?[]const u8 = null;
    while (iter.next()) |token| last = token;
    return last;
}

fn restAfterFirstToken(text: []const u8) ?[]const u8 {
    const first = firstToken(text) orelse return null;
    const start = std.mem.indexOf(u8, text, first).? + first.len;
    return text[start..];
}

fn stripValuePrefix(text: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len != 0 and trimmed[0] == '%') return trimmed[1..];
    return trimmed;
}

fn stripGlobalPrefix(text: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, text, " \t");
    const without_at = if (trimmed.len != 0 and trimmed[0] == '@') trimmed[1..] else trimmed;
    if (without_at.len >= 2 and without_at[0] == '"' and without_at[without_at.len - 1] == '"') {
        return without_at[1 .. without_at.len - 1];
    }
    return without_at;
}

fn parseGlobalInitializer(ty: ir.Type, text: []const u8) ir.GlobalInitializer {
    const trimmed = std.mem.trim(u8, text, " \t");
    switch (ty) {
        .int => {
            if (std.fmt.parseInt(i128, trimmed, 10)) |value| return .{ .scalar = .{ .int = value } } else |_| {}
        },
        .ptr => return .{ .scalar = parseValueRef(trimmed) },
        .float, .double, .x86_fp80, .fp128 => return .{ .scalar = .{ .fp = trimmed } },
        .aggregate => {
            if (std.mem.eql(u8, trimmed, "zeroinitializer")) return .{ .scalar = .zero_initializer };
            if (std.mem.eql(u8, trimmed, "undef")) return .{ .scalar = .undef };
            if (std.mem.startsWith(u8, trimmed, "c\"")) return .{ .c_string = trimmed };
        },
        .void, .metadata, .vector => {},
    }
    return .{ .@"opaque" = trimmed };
}

fn normalizeAttrs(text: []const u8) ?[]const u8 {
    const trimmed = std.mem.trim(u8, text, " \t");
    return if (trimmed.len == 0) null else trimmed;
}
