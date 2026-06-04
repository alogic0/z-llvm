const std = @import("std");

pub const Type = union(enum) {
    void,
    i1,
    i8,
    i16,
    i32,
    i64,
    i128,
    f32,
    f64,
    ptr,
    text: []const u8,

    pub fn llvm(self: Type) []const u8 {
        return switch (self) {
            .void => "void",
            .i1 => "i1",
            .i8 => "i8",
            .i16 => "i16",
            .i32 => "i32",
            .i64 => "i64",
            .i128 => "i128",
            .f32 => "float",
            .f64 => "double",
            .ptr => "ptr",
            .text => |text| text,
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
    }

    pub fn global(self: *Module, name: []const u8, linkage: []const u8, ty: Type, initializer: []const u8, align_text: []const u8) !void {
        if (linkage.len == 0) {
            try self.writer.print("@{s} = global {s} {s}, align {s}\n", .{ name, ty.llvm(), initializer, align_text });
        } else {
            try self.writer.print("@{s} = {s} global {s} {s}, align {s}\n", .{ name, linkage, ty.llvm(), initializer, align_text });
        }
    }

    pub fn constant(self: *Module, name: []const u8, linkage: []const u8, ty: Type, initializer: []const u8, align_text: []const u8) !void {
        if (linkage.len == 0) {
            try self.writer.print("@{s} = constant {s} {s}, align {s}\n", .{ name, ty.llvm(), initializer, align_text });
        } else {
            try self.writer.print("@{s} = {s} constant {s} {s}, align {s}\n", .{ name, linkage, ty.llvm(), initializer, align_text });
        }
    }

    pub fn tlsGlobal(self: *Module, name: []const u8, linkage: []const u8, model: []const u8, ty: Type, initializer: []const u8, align_text: []const u8) !void {
        if (linkage.len == 0) {
            try self.writer.print("@{s} = thread_local({s}) global {s} {s}, align {s}\n", .{ name, model, ty.llvm(), initializer, align_text });
        } else {
            try self.writer.print("@{s} = {s} thread_local({s}) global {s} {s}, align {s}\n", .{ name, linkage, model, ty.llvm(), initializer, align_text });
        }
    }

    pub fn declare(self: *Module, ret_ty: Type, name: []const u8, params: []const u8) !void {
        try self.writer.print("declare {s} @{s}({s})\n", .{ ret_ty.llvm(), name, params });
    }

    pub fn function(self: *Module, linkage: []const u8, ret_ty: Type, name: []const u8, params: []const u8, attrs: []const u8) !Function {
        try self.writer.print("define {s}{s} @{s}({s}){s} {{\n", .{ linkage, ret_ty.llvm(), name, params, attrs });
        return .{ .writer = self.writer };
    }
};

pub const Function = struct {
    writer: *std.Io.Writer,

    pub fn block(self: *Function, name: []const u8) !Block {
        try self.writer.print("{s}:\n", .{name});
        return .{ .writer = self.writer };
    }

    pub fn end(self: *Function) !void {
        try self.writer.writeAll("}\n\n");
    }
};

pub const Block = struct {
    writer: *std.Io.Writer,

    pub fn br(self: *Block, target: []const u8) !void {
        try self.writer.print("  br label %{s}\n", .{target});
    }

    pub fn condBr(self: *Block, cond: Value, then_target: []const u8, else_target: []const u8) !void {
        try self.writer.print("  br i1 {s}, label %{s}, label %{s}\n", .{ cond.ref, then_target, else_target });
    }

    pub fn ret(self: *Block, value: Value) !void {
        try self.writer.print("  ret {s} {s}\n", .{ value.ty.llvm(), value.ref });
    }

    pub fn retVoid(self: *Block) !void {
        try self.writer.writeAll("  ret void\n");
    }

    pub fn emitUnreachable(self: *Block) !void {
        try self.writer.writeAll("  unreachable\n");
    }

    pub fn phi2(self: *Block, result: []const u8, ty: Type, first_value: Value, first_block: []const u8, second_value: Value, second_block: []const u8) !Value {
        try self.writer.print("  %{s} = phi {s} [ {s}, %{s} ], [ {s}, %{s} ]\n", .{ result, ty.llvm(), first_value.ref, first_block, second_value.ref, second_block });
        return Value.local(ty, result);
    }

    pub fn binary(self: *Block, result: []const u8, op: []const u8, ty: Type, lhs: Value, rhs: Value) !Value {
        try self.writer.print("  %{s} = {s} {s} {s}, {s}\n", .{ result, op, ty.llvm(), lhs.ref, rhs.ref });
        return Value.local(ty, result);
    }

    pub fn binaryFlags(self: *Block, result: []const u8, op_and_flags: []const u8, ty: Type, lhs: Value, rhs: Value) !Value {
        return self.binary(result, op_and_flags, ty, lhs, rhs);
    }

    pub fn cast(self: *Block, result: []const u8, op: []const u8, from: Value, to_ty: Type) !Value {
        try self.writer.print("  %{s} = {s} {s} {s} to {s}\n", .{ result, op, from.ty.llvm(), from.ref, to_ty.llvm() });
        return Value.local(to_ty, result);
    }

    pub fn icmp(self: *Block, result: []const u8, pred: []const u8, ty: Type, lhs: Value, rhs: Value) !Value {
        try self.writer.print("  %{s} = icmp {s} {s} {s}, {s}\n", .{ result, pred, ty.llvm(), lhs.ref, rhs.ref });
        return Value.local(.i1, result);
    }

    pub fn fcmp(self: *Block, result: []const u8, pred: []const u8, ty: Type, lhs: Value, rhs: Value) !Value {
        try self.writer.print("  %{s} = fcmp {s} {s} {s}, {s}\n", .{ result, pred, ty.llvm(), lhs.ref, rhs.ref });
        return Value.local(.i1, result);
    }

    pub fn fcmpLocalName(self: *Block, result: []const u8, pred: []const u8, ty: Type, lhs_name: []const u8, rhs: Value) !Value {
        try self.writer.print("  %{s} = fcmp {s} {s} %{s}, {s}\n", .{ result, pred, ty.llvm(), lhs_name, rhs.ref });
        return Value.local(.i1, result);
    }

    pub fn select(self: *Block, result: []const u8, cond: Value, ty: Type, then_value: Value, else_value: Value) !Value {
        try self.writer.print("  %{s} = select i1 {s}, {s} {s}, {s} {s}\n", .{ result, cond.ref, ty.llvm(), then_value.ref, ty.llvm(), else_value.ref });
        return Value.local(ty, result);
    }

    pub fn call(self: *Block, result: ?[]const u8, attrs: []const u8, ret_ty: Type, callee: []const u8, args: []const u8) !?Value {
        if (result) |name| {
            try self.writer.print("  %{s} = {s}call {s} {s}({s})\n", .{ name, attrs, ret_ty.llvm(), callee, args });
            return Value.local(ret_ty, name);
        }
        try self.writer.print("  {s}call {s} {s}({s})\n", .{ attrs, ret_ty.llvm(), callee, args });
        return null;
    }

    pub fn alloca(self: *Block, result: []const u8, ty: Type, align_text: []const u8) !Value {
        try self.writer.print("  %{s} = alloca {s}, align {s}\n", .{ result, ty.llvm(), align_text });
        return Value.local(.ptr, result);
    }

    pub fn gep(self: *Block, result: []const u8, elem_ty: Type, base: Value, index_ty: Type, index: Value) !Value {
        try self.writer.print("  %{s} = getelementptr {s}, ptr {s}, {s} {s}\n", .{ result, elem_ty.llvm(), base.ref, index_ty.llvm(), index.ref });
        return Value.local(.ptr, result);
    }

    pub fn gep2(self: *Block, result: []const u8, elem_ty: Type, base: Value, first_index: Value, second_index: Value) !Value {
        try self.writer.print("  %{s} = getelementptr {s}, ptr {s}, i64 {s}, i64 {s}\n", .{ result, elem_ty.llvm(), base.ref, first_index.ref, second_index.ref });
        return Value.local(.ptr, result);
    }

    pub fn load(self: *Block, result: []const u8, ty: Type, ptr_value: Value, align_text: []const u8) !Value {
        try self.writer.print("  %{s} = load {s}, ptr {s}, align {s}\n", .{ result, ty.llvm(), ptr_value.ref, align_text });
        return Value.local(ty, result);
    }

    pub fn store(self: *Block, value: Value, ptr_value: Value, align_text: []const u8) !void {
        try self.writer.print("  store {s} {s}, ptr {s}, align {s}\n", .{ value.ty.llvm(), value.ref, ptr_value.ref, align_text });
    }

    pub fn lifetimeStart(self: *Block, ptr_value: Value) !void {
        try self.writer.print("  call void @llvm.lifetime.start.p0(ptr {s})\n", .{ptr_value.ref});
    }

    pub fn lifetimeEnd(self: *Block, ptr_value: Value) !void {
        try self.writer.print("  call void @llvm.lifetime.end.p0(ptr {s})\n", .{ptr_value.ref});
    }

    pub fn memcpy(self: *Block, dst: Value, src: Value, len: Value, is_volatile: Value) !void {
        try self.writer.print("  call void @llvm.memcpy.p0.p0.i64(ptr {s}, ptr {s}, i64 {s}, i1 {s})\n", .{ dst.ref, src.ref, len.ref, is_volatile.ref });
    }

    pub fn memset(self: *Block, dst: Value, byte: Value, len: Value, is_volatile: Value) !void {
        try self.writer.print("  call void @llvm.memset.p0.i64(ptr {s}, i8 {s}, i64 {s}, i1 {s})\n", .{ dst.ref, byte.ref, len.ref, is_volatile.ref });
    }

    pub fn checkedSAddI32(self: *Block, result: []const u8, lhs: Value, rhs: Value) !CheckedResult {
        try self.writer.print(
            \\  %{s}.checked = tail call {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32 {s}, i32 {s})
            \\  %{s}.value = extractvalue {{ i32, i1 }} %{s}.checked, 0
            \\  %{s}.overflow = extractvalue {{ i32, i1 }} %{s}.checked, 1
            \\
        , .{ result, lhs.ref, rhs.ref, result, result, result, result });
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
