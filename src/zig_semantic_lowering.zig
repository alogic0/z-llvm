const std = @import("std");
const sib = @import("structured_ir_builder.zig");

pub const ExternalWriterFn = *const fn (std.Io, *std.Io.Writer, []const u8) anyerror!void;

pub const Program = enum {
    tiny_scalar,
    integer_arithmetic,
    error_switch_select,
    direct_call,
    call_chain,
    cond_branch,
    phi_merge,
    loop_sum,
    global_update,
    pointer_load_store,
    struct_sum,
    array_sum,
    optional_payload,
    error_union_payload,
    slice_sum,
    fp_literals,
    comptime_const,
    debug_location,
    tls_read,
    atomic_add,
};

pub fn emitExternalRecord(
    surface: []const u8,
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
    write: ExternalWriterFn,
) !void {
    _ = surface;
    try write(io, writer, ir_path);
}

pub fn emit(program: Program, writer: *std.Io.Writer) !void {
    switch (program) {
        .tiny_scalar => try tinyScalar(writer),
        .integer_arithmetic => try integerArithmetic(writer),
        .error_switch_select => try errorSwitchSelect(writer),
        .direct_call => try directCall(writer),
        .call_chain => try callChain(writer),
        .cond_branch => try condBranch(writer),
        .phi_merge => try phiMerge(writer),
        .loop_sum => try loopSum(writer),
        .global_update => try globalUpdate(writer),
        .pointer_load_store => try pointerLoadStore(writer),
        .struct_sum => try structSum(writer),
        .array_sum => try arraySum(writer),
        .optional_payload => try optionalPayload(writer),
        .error_union_payload => try errorUnionPayload(writer),
        .slice_sum => try sliceSum(writer),
        .fp_literals => try fpLiterals(writer),
        .comptime_const => try comptimeConst(writer),
        .debug_location => try debugLocation(writer),
        .tls_read => try tlsRead(writer),
        .atomic_add => try atomicAdd(writer),
    }
}

fn tinyScalar(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.binary("v", "add", .i32, sib.int(.i32, "40"), sib.int(.i32, "2"));
    try entry.ret(sib.local(.i32, "%v"));
    try function.end();
}

fn integerArithmetic(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.binary("wrap", "add", .i32, sib.int(.i32, "2147483647"), sib.int(.i32, "1"));
    _ = try entry.icmp("wrap_ok", "eq", .i32, sib.local(.i32, "%wrap"), sib.int(.i32, "-2147483648"));
    _ = try entry.icmp("cmp", "slt", .i32, sib.int(.i32, "7"), sib.int(.i32, "3"));
    _ = try entry.select("sel", sib.local(.i1, "%cmp"), .i32, sib.int(.i32, "7"), sib.int(.i32, "3"));
    _ = try entry.icmp("sel_ok", "eq", .i32, sib.local(.i32, "%sel"), sib.int(.i32, "3"));
    _ = try entry.binary("shift", "and", .i32, sib.int(.i32, "4"), sib.int(.i32, "31"));
    _ = try entry.binary("left", "shl", .i32, sib.int(.i32, "305419896"), sib.local(.i32, "%shift"));
    _ = try entry.binary("right", "lshr", .i32, sib.int(.i32, "305419896"), sib.local(.i32, "%shift"));
    _ = try entry.binary("mixed", "xor", .i32, sib.local(.i32, "%left"), sib.local(.i32, "%right"));
    _ = try entry.icmp("mixed_ok", "eq", .i32, sib.local(.i32, "%mixed"), sib.int(.i32, "577118951"));
    _ = try entry.binary("ok_a", "and", .i1, sib.local(.i1, "%wrap_ok"), sib.local(.i1, "%sel_ok"));
    _ = try entry.binary("ok", "and", .i1, sib.local(.i1, "%ok_a"), sib.local(.i1, "%mixed_ok"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn errorSwitchSelect(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.icmp("is_one", "eq", .i8, sib.int(.i8, "1"), sib.int(.i8, "1"));
    _ = try entry.select("first", sib.local(.i1, "%is_one"), .i32, sib.int(.i32, "-1"), sib.int(.i32, "-2"));
    _ = try entry.icmp("first_ok", "eq", .i32, sib.local(.i32, "%first"), sib.int(.i32, "-1"));
    _ = try entry.icmp("is_zero", "eq", .i8, sib.int(.i8, "0"), sib.int(.i8, "0"));
    _ = try entry.select("second", sib.local(.i1, "%is_zero"), .i32, sib.int(.i32, "0"), sib.local(.i32, "%first"));
    _ = try entry.icmp("second_ok", "eq", .i32, sib.local(.i32, "%second"), sib.int(.i32, "0"));
    _ = try entry.binary("ok", "and", .i1, sib.local(.i1, "%first_ok"), sib.local(.i1, "%second_ok"));
    try entry.condBr(sib.local(.i1, "%ok"), "success", "failure");
    try writer.writeAll("\n");
    var success = try function.block("success");
    try success.ret(sib.int(.i32, "0"));
    try writer.writeAll("\n");
    var failure = try function.block("failure");
    try failure.ret(sib.int(.i32, "1"));
    try function.end();
}

fn directCall(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    var callee = try module.function("internal ", .i32, "control_flow_calls.writer_callee", "", " local_unnamed_addr");
    var callee_entry = try callee.block("entry");
    try callee_entry.ret(sib.int(.i32, "41"));
    try callee.end();
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try main_fn.block("entry");
    _ = try entry.call("base", "", .i32, "@control_flow_calls.writer_callee", "");
    _ = try entry.binary("ret", "add", .i32, sib.local(.i32, "%base"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
}

fn callChain(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i32 (i32)" }, "@control_flow_calls.call_chain");
    try writer.writeAll("\n");
    var callee = try module.function("dso_local ", .i32, "control_flow_calls.callee", "i32 %value", " local_unnamed_addr");
    var callee_entry = try callee.block("entry");
    _ = try callee_entry.binary("doubled", "add", .i32, sib.local(.i32, "%value"), sib.local(.i32, "%value"));
    try callee_entry.ret(sib.local(.i32, "%doubled"));
    try callee.end();
    var chain = try module.function("private ", .i32, "control_flow_calls.call_chain", "i32 %value", " local_unnamed_addr");
    var entry = try chain.block("entry");
    _ = try entry.call("base", "", .i32, "@control_flow_calls.callee", "i32 %value");
    _ = try entry.binary("ret", "add", .i32, sib.local(.i32, "%base"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try chain.end();
}

fn condBranch(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "i1 zeroext %flag", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.condBr(sib.local(.i1, "%flag"), "then", "else");
    try writer.writeAll("\n");
    var then_block = try function.block("then");
    try then_block.ret(sib.int(.i32, "0"));
    try writer.writeAll("\n");
    var else_block = try function.block("else");
    try else_block.ret(sib.int(.i32, "1"));
    try function.end();
}

fn phiMerge(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "i1 zeroext %flag", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.condBr(sib.local(.i1, "%flag"), "then", "else");
    try writer.writeAll("\n");
    var then_block = try function.block("then");
    try then_block.br("merge");
    try writer.writeAll("\n");
    var else_block = try function.block("else");
    try else_block.br("merge");
    try writer.writeAll("\n");
    var merge = try function.block("merge");
    _ = try merge.phi2("ret", .i32, sib.int(.i32, "0"), "then", sib.int(.i32, "1"), "else");
    try merge.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn loopSum(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i32 (i32)" }, "@control_flow_calls.loop_sum");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i32, "control_flow_calls.loop_sum", "i32 %limit", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.icmp("is_zero", "eq", .i32, sib.local(.i32, "%limit"), sib.int(.i32, "0"));
    try entry.condBr(sib.local(.i1, "%is_zero"), "exit_zero", "loop");
    try writer.writeAll("\n");
    var loop = try function.block("loop");
    _ = try loop.phi2("index", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%next"), "loop");
    _ = try loop.phi2("sum", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%sum_next"), "loop");
    _ = try loop.binary("sum_next", "add", .i32, sib.local(.i32, "%sum"), sib.local(.i32, "%index"));
    _ = try loop.binary("next", "add", .i32, sib.local(.i32, "%index"), sib.int(.i32, "1"));
    _ = try loop.icmp("done", "eq", .i32, sib.local(.i32, "%next"), sib.local(.i32, "%limit"));
    try loop.condBr(sib.local(.i1, "%done"), "exit", "loop");
    try writer.writeAll("\n");
    var exit_zero = try function.block("exit_zero");
    try exit_zero.ret(sib.int(.i32, "0"));
    try writer.writeAll("\n");
    var exit = try function.block("exit");
    try exit.ret(sib.local(.i32, "%sum_next"));
    try function.end();
}

fn globalUpdate(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("globals_comptime.global_counter", "private", .i32, "3", "4");
    try module.alias("main", .{ .text = "i32 (i32)" }, "@globals_comptime.update_global");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i32, "globals_comptime.update_global", "i32 %value", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("current", .i32, sib.global(.ptr, "@globals_comptime.global_counter"), "4");
    _ = try entry.binary("updated", "add", .i32, sib.local(.i32, "%current"), sib.local(.i32, "%value"));
    try entry.store(sib.local(.i32, "%updated"), sib.global(.ptr, "@globals_comptime.global_counter"), "4");
    try entry.ret(sib.local(.i32, "%updated"));
    try function.end();
}

fn pointerLoadStore(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("pointers_memory.writer_input", "dso_local", .i32, "41", "4");
    try module.global("pointers_memory.writer_output", "dso_local", .i32, "0", "4");
    try module.alias("load_store", .{ .text = "i32 (ptr, ptr)" }, "@pointers_memory.load_store");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.load("value", .i32, sib.global(.ptr, "@pointers_memory.writer_input"), "4");
    _ = try main_entry.binary("updated", "add", .i32, sib.local(.i32, "%value"), sib.int(.i32, "1"));
    try main_entry.store(sib.local(.i32, "%updated"), sib.global(.ptr, "@pointers_memory.writer_output"), "4");
    _ = try main_entry.load("stored", .i32, sib.global(.ptr, "@pointers_memory.writer_output"), "4");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%stored"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "pointers_memory.load_store", "ptr %0, ptr %1", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.load("3", .i32, sib.local(.ptr, "%0"), "4");
    _ = try entry.binary("4", "add", .i32, sib.local(.i32, "%3"), sib.int(.i32, "1"));
    try entry.store(sib.local(.i32, "%4"), sib.local(.ptr, "%1"), "4");
    try entry.ret(sib.local(.i32, "%4"));
    try callee.end();
}

fn structSum(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("struct_sum", .{ .text = "i32 (ptr)" }, "@aggregates.struct_sum");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.binary("sum", "add", .i32, sib.int(.i32, "20"), sib.int(.i32, "22"));
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%sum"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "aggregates.struct_sum", "ptr %0", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.load("2", .i32, sib.local(.ptr, "%0"), "4");
    _ = try entry.gep("3", .i8, sib.local(.ptr, "%0"), .i64, sib.int(.i64, "4"));
    _ = try entry.load("4", .i32, sib.local(.ptr, "%3"), "4");
    _ = try entry.binary("5", "add", .i32, sib.local(.i32, "%4"), sib.local(.i32, "%2"));
    try entry.ret(sib.local(.i32, "%5"));
    try callee.end();
}

fn arraySum(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("array_sum", .{ .text = "i32 (i32, i32, i32)" }, "@aggregates.array_sum");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@aggregates.array_sum", "i32 10, i32 20, i32 12");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "aggregates.array_sum", "i32 %0, i32 %1, i32 %2", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.binary("4", "add", .i32, sib.local(.i32, "%1"), sib.local(.i32, "%0"));
    _ = try entry.binary("5", "add", .i32, sib.local(.i32, "%4"), sib.local(.i32, "%2"));
    try entry.ret(sib.local(.i32, "%5"));
    try callee.end();
}

fn optionalPayload(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("optional_payload", .{ .text = "i32 (i32, i32)" }, "@aggregates.optional_payload");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@aggregates.optional_payload", "i32 1, i32 42");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "aggregates.optional_payload", "i32 %0, i32 %1", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.icmp(".not", "eq", .i32, sib.local(.i32, "%0"), sib.int(.i32, "0"));
    _ = try entry.select("spec.select", sib.local(.i1, "%.not"), .i32, sib.int(.i32, "-1"), sib.local(.i32, "%1"));
    try entry.ret(sib.local(.i32, "%spec.select"));
    try callee.end();
}

fn errorUnionPayload(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("error_union_payload", .{ .text = "i32 (i32)" }, "@aggregates.error_union_payload");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@aggregates.error_union_payload", "i32 0");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "7"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "aggregates.error_union_payload", "i32 %0", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.icmp(".not.i", "eq", .i32, sib.local(.i32, "%0"), sib.int(.i32, "0"));
    _ = try entry.select("2", sib.local(.i1, "%.not.i"), .i32, sib.int(.i32, "7"), sib.int(.i32, "-1"));
    try entry.ret(sib.local(.i32, "%2"));
    try callee.end();
}

fn sliceSum(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("slice_sum_values", "", .{ .text = "[4 x i32]" }, "[i32 1, i32 2, i32 3, i32 4]", "4");
    try module.alias("slice_sum", .{ .text = "i32 (ptr, i64)" }, "@aggregates.slice_sum");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@aggregates.slice_sum", "ptr @slice_sum_values, i64 4");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "10"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "aggregates.slice_sum", "ptr %0, i64 %1", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.icmp(".not", "eq", .i64, sib.local(.i64, "%1"), sib.int(.i64, "0"));
    try entry.condBr(sib.local(.i1, "%.not"), "exit", "loop");
    try writer.writeAll("\n");
    var loop = try callee.block("loop");
    _ = try loop.phi2("sum", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%sum_next"), "loop");
    _ = try loop.phi2("index", .i64, sib.int(.i64, "0"), "entry", sib.local(.i64, "%next"), "loop");
    _ = try loop.gep("ptr", .{ .text = "[4 x i8]" }, sib.local(.ptr, "%0"), .i64, sib.local(.i64, "%index"));
    _ = try loop.load("loaded", .i32, sib.local(.ptr, "%ptr"), "4");
    _ = try loop.binary("sum_next", "add", .i32, sib.local(.i32, "%loaded"), sib.local(.i32, "%sum"));
    _ = try loop.binary("next", "add", .i64, sib.local(.i64, "%index"), sib.int(.i64, "1"));
    _ = try loop.icmp("done", "eq", .i64, sib.local(.i64, "%next"), sib.local(.i64, "%1"));
    try loop.condBr(sib.local(.i1, "%done"), "exit", "loop");
    try writer.writeAll("\n");
    var exit = try callee.block("exit");
    _ = try exit.phi2("result", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%sum_next"), "loop");
    try exit.ret(sib.local(.i32, "%result"));
    try callee.end();
}

fn fpLiterals(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("double_literal", .{ .text = "double ()" }, "@fp_constants.double_literal");
    try module.alias("float_literal", .{ .text = "float ()" }, "@fp_constants.float_literal");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    try main_entry.ret(sib.int(.i32, "0"));
    try main_fn.end();
    var double_fn = try module.function("private ", .f64, "fp_constants.double_literal", "", " unnamed_addr align 1");
    var double_entry = try double_fn.block("entry");
    try double_entry.ret(sib.int(.f64, "2.250000e+00"));
    try double_fn.end();
    var float_fn = try module.function("private ", .f32, "fp_constants.float_literal", "", " unnamed_addr align 1");
    var float_entry = try float_fn.block("entry");
    try float_entry.ret(sib.int(.f32, "1.500000e+00"));
    try float_fn.end();
}

fn comptimeConst(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("comptime_const", .{ .text = "i32 (i32)" }, "@globals_comptime.comptime_const");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@globals_comptime.comptime_const", "i32 7");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "35"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "globals_comptime.comptime_const", "i32 %value", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.binary("scaled", "mul nsw", .i32, sib.local(.i32, "%value"), sib.int(.i32, "5"));
    try entry.ret(sib.local(.i32, "%scaled"));
    try callee.end();
}

fn debugLocation(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("debug_location", .{ .text = "i32 (i32)" }, "@atomics_inline_asm_debug.debug_location");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@atomics_inline_asm_debug.debug_location", "i32 41");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "atomics_inline_asm_debug.debug_location", "i32 %value", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.binary("next", "add nsw", .i32, sib.local(.i32, "%value"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%next"));
    try callee.end();
}

fn tlsRead(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.tlsGlobal("tls_concurrency.tls_counter", "internal", "localexec", .i32, "1", "4");
    try module.alias("main", .{ .text = "i32 ()" }, "@tls_concurrency.read_tls");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i32, "tls_concurrency.read_tls", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("value", .i32, sib.global(.ptr, "@tls_concurrency.tls_counter"), "4");
    try entry.ret(sib.local(.i32, "%value"));
    try function.end();
}

fn atomicAdd(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("atomics_inline_asm_debug.atomic_counter", "private", .i32, "0", "4");
    try module.alias("main", .{ .text = "i32 (i32)" }, "@atomics_inline_asm_debug.atomic_add");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i32, "atomics_inline_asm_debug.atomic_add", "i32 %value", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.atomicRmwAdd("old", sib.global(.ptr, "@atomics_inline_asm_debug.atomic_counter"), sib.local(.i32, "%value"), "monotonic", "4");
    try entry.ret(sib.local(.i32, "%old"));
    try function.end();
}
