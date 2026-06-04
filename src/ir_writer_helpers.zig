const std = @import("std");

pub fn functionHeader(writer: *std.Io.Writer, linkage: []const u8, ret_ty: []const u8, name: []const u8, params: []const u8, attrs: []const u8) !void {
    try writer.print("define {s}{s} @{s}({s}){s} {{\n", .{ linkage, ret_ty, name, params, attrs });
}

pub fn functionEnd(writer: *std.Io.Writer) !void {
    try writer.writeAll("}\n\n");
}

pub fn alias(writer: *std.Io.Writer, public_name: []const u8, ty: []const u8, target: []const u8) !void {
    try writer.print("@{s} = alias {s}, ptr @{s}\n", .{ public_name, ty, target });
}

pub fn global(writer: *std.Io.Writer, name: []const u8, linkage: []const u8, ty: []const u8, initializer: []const u8, align_text: []const u8) !void {
    try writer.print("@{s} = {s} global {s} {s}, align {s}\n", .{ name, linkage, ty, initializer, align_text });
}

pub fn constant(writer: *std.Io.Writer, name: []const u8, linkage: []const u8, ty: []const u8, initializer: []const u8, align_text: []const u8) !void {
    try writer.print("@{s} = {s} constant {s} {s}, align {s}\n", .{ name, linkage, ty, initializer, align_text });
}

pub fn tlsGlobal(writer: *std.Io.Writer, name: []const u8, linkage: []const u8, model: []const u8, ty: []const u8, initializer: []const u8, align_text: []const u8) !void {
    if (linkage.len == 0) {
        try writer.print("@{s} = thread_local({s}) global {s} {s}, align {s}\n", .{ name, model, ty, initializer, align_text });
    } else {
        try writer.print("@{s} = {s} thread_local({s}) global {s} {s}, align {s}\n", .{ name, linkage, model, ty, initializer, align_text });
    }
}

pub fn block(writer: *std.Io.Writer, name: []const u8) !void {
    try writer.print("{s}:\n", .{name});
}

pub fn br(writer: *std.Io.Writer, target_block: []const u8) !void {
    try writer.print("  br label %{s}\n", .{target_block});
}

pub fn condBr(writer: *std.Io.Writer, cond: []const u8, then_target: []const u8, else_target: []const u8) !void {
    try writer.print("  br i1 %{s}, label %{s}, label %{s}\n", .{ cond, then_target, else_target });
}

pub fn ret(writer: *std.Io.Writer, ty: []const u8, value: []const u8) !void {
    try writer.print("  ret {s} {s}\n", .{ ty, value });
}

pub fn retVoid(writer: *std.Io.Writer) !void {
    try writer.writeAll("  ret void\n");
}

pub fn phi2(
    writer: *std.Io.Writer,
    name: []const u8,
    ty: []const u8,
    first_value: []const u8,
    first_block: []const u8,
    second_value: []const u8,
    second_block: []const u8,
) !void {
    try writer.print("  %{s} = phi {s} [ {s}, %{s} ], [ {s}, %{s} ]\n", .{ name, ty, first_value, first_block, second_value, second_block });
}

pub fn loopHeader2(
    writer: *std.Io.Writer,
    block_name: []const u8,
    first_phi: []const u8,
    first_ty: []const u8,
    first_entry_value: []const u8,
    first_next_value: []const u8,
    second_phi: []const u8,
    second_ty: []const u8,
    second_entry_value: []const u8,
    second_next_value: []const u8,
    entry_block: []const u8,
    latch_block: []const u8,
) !void {
    try block(writer, block_name);
    try phi2(writer, first_phi, first_ty, first_entry_value, entry_block, first_next_value, latch_block);
    try phi2(writer, second_phi, second_ty, second_entry_value, entry_block, second_next_value, latch_block);
}

pub fn gep(writer: *std.Io.Writer, result: []const u8, elem_ty: []const u8, base: []const u8, index: []const u8) !void {
    try writer.print("  %{s} = getelementptr {s}, ptr {s}, i64 {s}\n", .{ result, elem_ty, base, index });
}

pub fn gep2(
    writer: *std.Io.Writer,
    result: []const u8,
    elem_ty: []const u8,
    base: []const u8,
    first_index: []const u8,
    second_index: []const u8,
) !void {
    try writer.print("  %{s} = getelementptr {s}, ptr {s}, i64 {s}, i64 {s}\n", .{ result, elem_ty, base, first_index, second_index });
}

pub fn load(writer: *std.Io.Writer, result: []const u8, ty: []const u8, ptr_name: []const u8, align_text: []const u8) !void {
    try writer.print("  %{s} = load {s}, ptr {s}, align {s}\n", .{ result, ty, ptr_name, align_text });
}

pub fn store(writer: *std.Io.Writer, ty: []const u8, value: []const u8, ptr_name: []const u8, align_text: []const u8) !void {
    try writer.print("  store {s} {s}, ptr {s}, align {s}\n", .{ ty, value, ptr_name, align_text });
}

pub fn alloca(writer: *std.Io.Writer, result: []const u8, ty: []const u8, align_text: []const u8) !void {
    try writer.print("  %{s} = alloca {s}, align {s}\n", .{ result, ty, align_text });
}

pub fn pointerIndexAdvance(writer: *std.Io.Writer, result: []const u8, base: []const u8, delta: []const u8) !void {
    try writer.print("  %{s} = add nuw i64 {s}, {s}\n", .{ result, base, delta });
}

pub fn byteMask(writer: *std.Io.Writer, result: []const u8, value: []const u8, mask: []const u8) !void {
    try writer.print("  %{s} = and i8 {s}, {s}\n", .{ result, value, mask });
}

pub fn shift(writer: *std.Io.Writer, result: []const u8, op: []const u8, ty: []const u8, value: []const u8, amount: []const u8) !void {
    try writer.print("  %{s} = {s} {s} {s}, {s}\n", .{ result, op, ty, value, amount });
}

pub fn trunc(writer: *std.Io.Writer, result: []const u8, from_ty: []const u8, value: []const u8, to_ty: []const u8) !void {
    try writer.print("  %{s} = trunc {s} {s} to {s}\n", .{ result, from_ty, value, to_ty });
}

pub fn indexedTableLoadI32(
    writer: *std.Io.Writer,
    prefix: []const u8,
    table: []const u8,
    byte_name: []const u8,
) !void {
    try writer.print(
        \\  %{s}.idx = zext i8 %{s} to i64
        \\  %{s}.entry = getelementptr [4 x i8], ptr @{s}, i64 %{s}.idx
        \\  %{s}.word = load i32, ptr %{s}.entry, align 4
        \\
    , .{ prefix, byte_name, prefix, table, prefix, prefix, prefix });
}

pub fn indexedTableLoadI8(
    writer: *std.Io.Writer,
    prefix: []const u8,
    table: []const u8,
    byte_name: []const u8,
) !void {
    try writer.print(
        \\  %{s}.idx = zext i8 %{s} to i64
        \\  %{s}.entry = getelementptr [256 x i8], ptr @{s}, i64 0, i64 %{s}.idx
        \\  %{s}.word = load i8, ptr %{s}.entry, align 1
        \\
    , .{ prefix, byte_name, prefix, table, prefix, prefix, prefix });
}

pub fn call(writer: *std.Io.Writer, result: ?[]const u8, attrs: []const u8, ret_ty: []const u8, callee: []const u8, args: []const u8) !void {
    if (result) |name| {
        try writer.print("  %{s} = {s}call {s} {s}({s})\n", .{ name, attrs, ret_ty, callee, args });
    } else {
        try writer.print("  {s}call {s} {s}({s})\n", .{ attrs, ret_ty, callee, args });
    }
}

pub fn inlineAsmBarrier(writer: *std.Io.Writer) !void {
    try writer.writeAll("  tail call void asm sideeffect \"\", \"~{memory},~{dirflag},~{fpsr},~{flags}\"()\n");
}

pub fn lifetimeStart(writer: *std.Io.Writer, ptr_name: []const u8) !void {
    try writer.print("  call void @llvm.lifetime.start.p0(ptr {s})\n", .{ptr_name});
}

pub fn lifetimeEnd(writer: *std.Io.Writer, ptr_name: []const u8) !void {
    try writer.print("  call void @llvm.lifetime.end.p0(ptr {s})\n", .{ptr_name});
}

pub fn memcpy(writer: *std.Io.Writer, dst: []const u8, src: []const u8, len: []const u8, is_volatile: []const u8) !void {
    try writer.print("  call void @llvm.memcpy.p0.p0.i64(ptr {s}, ptr {s}, i64 {s}, i1 {s})\n", .{ dst, src, len, is_volatile });
}

pub fn memset(writer: *std.Io.Writer, dst: []const u8, byte: []const u8, len: []const u8, is_volatile: []const u8) !void {
    try writer.print("  call void @llvm.memset.p0.i64(ptr {s}, i8 {s}, i64 {s}, i1 {s})\n", .{ dst, byte, len, is_volatile });
}

pub fn checkedSAddI32(writer: *std.Io.Writer, result: []const u8, lhs: []const u8, rhs: []const u8) !void {
    try writer.print(
        \\  %{s}.checked = tail call {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32 {s}, i32 {s})
        \\  %{s}.value = extractvalue {{ i32, i1 }} %{s}.checked, 0
        \\  %{s}.overflow = extractvalue {{ i32, i1 }} %{s}.checked, 1
        \\
    , .{ result, lhs, rhs, result, result, result, result });
}

pub fn checkedSAddI32Value(writer: *std.Io.Writer, result: []const u8, lhs: []const u8, rhs: []const u8, overflow: []const u8, value: []const u8) !void {
    try writer.print(
        \\  %{s} = tail call {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32 {s}, i32 {s})
        \\  %{s} = extractvalue {{ i32, i1 }} %{s}, 1
        \\  %{s} = extractvalue {{ i32, i1 }} %{s}, 0
        \\
    , .{ result, lhs, rhs, overflow, result, value, result });
}

pub fn checkedSMulI32Value(writer: *std.Io.Writer, result: []const u8, lhs: []const u8, rhs: []const u8, overflow: []const u8, value: []const u8) !void {
    try writer.print(
        \\  %{s} = tail call {{ i32, i1 }} @llvm.smul.with.overflow.i32(i32 {s}, i32 {s})
        \\  %{s} = extractvalue {{ i32, i1 }} %{s}, 1
        \\  %{s} = extractvalue {{ i32, i1 }} %{s}, 0
        \\
    , .{ result, lhs, rhs, overflow, result, value, result });
}

pub fn panicEdge(writer: *std.Io.Writer, overflow_flag: []const u8, ok_block: []const u8, panic_block: []const u8) !void {
    try condBr(writer, overflow_flag, panic_block, ok_block);
}

pub fn integerOverflowDeclarations(writer: *std.Io.Writer) !void {
    try writer.writeAll(
        \\declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)
        \\declare void @llvm.assume(i1)
        \\
    );
}

pub fn integerOverflowPanicFunction(writer: *std.Io.Writer) !void {
    try writer.writeAll(
        \\define fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"() {
        \\entry:
        \\  ret void
        \\}
        \\
    );
}

pub fn integerOverflowPanicBlock(writer: *std.Io.Writer, block_name: []const u8) !void {
    try block(writer, block_name);
    try writer.writeAll(
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
        \\  unreachable
        \\
    );
}

pub fn compareMainI32(writer: *std.Io.Writer, value_expr: []const u8, expected: []const u8) !void {
    try functionHeader(writer, "dso_local ", "i32", "main", "", " local_unnamed_addr");
    try block(writer, "entry");
    try writer.print(
        \\  %value = {s}
        \\  %ok = icmp eq i32 %value, {s}
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\
    , .{ value_expr, expected });
    try ret(writer, "i32", "%ret");
    try functionEnd(writer);
}
