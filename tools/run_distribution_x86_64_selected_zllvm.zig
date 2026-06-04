const std = @import("std");
const common = @import("tool_common.zig");

const downstream_marker = "llvm-module=not-used;llvm-optimizer=not-used;llvm-targetmachine=not-used;object-emission=z_llvm;linker=zig-native-fno-lld";
const expected_selected_rows = 146;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const argv = [_][]const u8{
        "zig",
        "run",
        "tools/run_distribution_zig_integrated_object.zig",
        "--",
        "--ir-writer",
    };
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(256 * 1024 * 1024),
        .stderr_limit = .limited(64 * 1024 * 1024),
    });
    defer common.freeRunResult(allocator, result);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    if (!common.termOk(result.term)) {
        const first_error = firstFailureError(result.stderr, result.stdout);
        const case_id = firstCaseId(result.stderr) orelse firstCaseId(result.stdout) orelse "-";
        const pipeline = parsePipeline(result.stdout) orelse "preopt";
        try stdout_writer.interface.print(
            "selected-zllvm status=fail total=- executable_ok=- link_only_ok=- structured_direct_rows=- structured_textual_rows=- textual_boundary_rows=- generic_codegen_rows=- case_specific_codegen_rows=- minimal-ret0=- ownership={s} first_failure_case_id={s} first_failure_wrapper=- first_failure_mode=- first_failure_pipeline={s} first_failure_error=\"{s}\"\n",
            .{ downstream_marker, case_id, pipeline, first_error },
        );
        try stdout_writer.interface.flush();
        std.process.exit(1);
    }

    const summary = findLine(result.stdout, "summary zig-integrated-object") orelse {
        try common.validationError(io, "selected zllvm compact gate missing integrated-object summary\n", .{});
    };
    const ownership = findLine(result.stdout, "ownership-summary ") orelse {
        try common.validationError(io, "selected zllvm compact gate missing ownership summary\n", .{});
    };
    const surfaces = findLine(result.stdout, "surface-counts") orelse {
        try common.validationError(io, "selected zllvm compact gate missing surface counts\n", .{});
    };
    const total = valueAfter(summary, "total=") orelse "-";
    const executable_ok = valueAfter(summary, "executable_ok=") orelse "-";
    const link_only_ok = valueAfter(summary, "link_only_ok=") orelse "-";
    const structured_direct_rows = valueAfter(summary, "structured_direct_rows=") orelse valueAfter(summary, "structured_builder_rows=") orelse "-";
    const structured_textual_rows = valueAfter(summary, "structured_textual_rows=") orelse "-";
    const textual_boundary_rows = valueAfter(summary, "textual_boundary_rows=") orelse valueAfter(summary, "textual_subset_rows=") orelse "-";
    const generic_codegen_rows = valueAfter(summary, "generic_codegen_rows=") orelse "-";
    const case_specific_codegen_rows = valueAfter(summary, "case_specific_codegen_rows=") orelse "-";
    const minimal_ret0 = valueAfter(surfaces, "minimal-ret0=") orelse valueAfter(summary, "minimal_wrapper_rows=") orelse "-";
    const ownership_value = std.mem.trim(u8, ownership["ownership-summary ".len..], " \t\r\n");
    if (std.mem.indexOf(u8, ownership_value, downstream_marker) == null or
        std.mem.indexOf(u8, ownership_value, "libLLVM") != null or
        std.mem.indexOf(u8, ownership_value, "TargetMachine") != null)
    {
        try stdout_writer.interface.print(
            "selected-zllvm status=fail total={s} executable_ok={s} link_only_ok={s} structured_direct_rows={s} structured_textual_rows={s} textual_boundary_rows={s} generic_codegen_rows={s} case_specific_codegen_rows={s} minimal-ret0={s} ownership={s} first_failure_case_id=- first_failure_wrapper=- first_failure_mode=- first_failure_pipeline=preopt first_failure_error=\"ownership-marker-mismatch\"\n",
            .{ total, executable_ok, link_only_ok, structured_direct_rows, structured_textual_rows, textual_boundary_rows, generic_codegen_rows, case_specific_codegen_rows, minimal_ret0, ownership_value },
        );
        try stdout_writer.interface.flush();
        std.process.exit(1);
    }
    const structured_count = std.fmt.parseInt(usize, structured_direct_rows, 10) catch 0;
    if (structured_count != expected_selected_rows) {
        try stdout_writer.interface.print(
            "selected-zllvm status=fail total={s} executable_ok={s} link_only_ok={s} structured_direct_rows={s} structured_textual_rows={s} textual_boundary_rows={s} generic_codegen_rows={s} case_specific_codegen_rows={s} minimal-ret0={s} ownership={s} first_failure_case_id=- first_failure_wrapper=- first_failure_mode=- first_failure_pipeline=preopt first_failure_error=\"structured-direct-row-exactness\"\n",
            .{ total, executable_ok, link_only_ok, structured_direct_rows, structured_textual_rows, textual_boundary_rows, generic_codegen_rows, case_specific_codegen_rows, minimal_ret0, ownership_value },
        );
        try stdout_writer.interface.flush();
        std.process.exit(1);
    }
    if (!std.mem.eql(u8, structured_textual_rows, "0")) {
        try stdout_writer.interface.print(
            "selected-zllvm status=fail total={s} executable_ok={s} link_only_ok={s} structured_direct_rows={s} structured_textual_rows={s} textual_boundary_rows={s} generic_codegen_rows={s} case_specific_codegen_rows={s} minimal-ret0={s} ownership={s} first_failure_case_id=- first_failure_wrapper=- first_failure_mode=- first_failure_pipeline=preopt first_failure_error=\"structured-textual-nonzero\"\n",
            .{ total, executable_ok, link_only_ok, structured_direct_rows, structured_textual_rows, textual_boundary_rows, generic_codegen_rows, case_specific_codegen_rows, minimal_ret0, ownership_value },
        );
        try stdout_writer.interface.flush();
        std.process.exit(1);
    }
    if (!std.mem.eql(u8, textual_boundary_rows, "0")) {
        try stdout_writer.interface.print(
            "selected-zllvm status=fail total={s} executable_ok={s} link_only_ok={s} structured_direct_rows={s} structured_textual_rows={s} textual_boundary_rows={s} generic_codegen_rows={s} case_specific_codegen_rows={s} minimal-ret0={s} ownership={s} first_failure_case_id=- first_failure_wrapper=- first_failure_mode=- first_failure_pipeline=preopt first_failure_error=\"textual-boundary-row-count\"\n",
            .{ total, executable_ok, link_only_ok, structured_direct_rows, structured_textual_rows, textual_boundary_rows, generic_codegen_rows, case_specific_codegen_rows, minimal_ret0, ownership_value },
        );
        try stdout_writer.interface.flush();
        std.process.exit(1);
    }
    const generic_codegen_count = std.fmt.parseInt(usize, generic_codegen_rows, 10) catch 0;
    const case_specific_codegen_count = std.fmt.parseInt(usize, case_specific_codegen_rows, 10) catch std.math.maxInt(usize);
    if (generic_codegen_count != expected_selected_rows or case_specific_codegen_count != 0) {
        try stdout_writer.interface.print(
            "selected-zllvm status=fail total={s} executable_ok={s} link_only_ok={s} structured_direct_rows={s} structured_textual_rows={s} textual_boundary_rows={s} generic_codegen_rows={s} case_specific_codegen_rows={s} minimal-ret0={s} ownership={s} first_failure_case_id=- first_failure_wrapper=- first_failure_mode=- first_failure_pipeline=preopt first_failure_error=\"generic-codegen-row-exactness\"\n",
            .{ total, executable_ok, link_only_ok, structured_direct_rows, structured_textual_rows, textual_boundary_rows, generic_codegen_rows, case_specific_codegen_rows, minimal_ret0, ownership_value },
        );
        try stdout_writer.interface.flush();
        std.process.exit(1);
    }
    if (!std.mem.eql(u8, minimal_ret0, "0")) {
        try stdout_writer.interface.print(
            "selected-zllvm status=fail total={s} executable_ok={s} link_only_ok={s} structured_direct_rows={s} structured_textual_rows={s} textual_boundary_rows={s} generic_codegen_rows={s} case_specific_codegen_rows={s} minimal-ret0={s} ownership={s} first_failure_case_id=- first_failure_wrapper=- first_failure_mode=- first_failure_pipeline=preopt first_failure_error=\"minimal-ret0-nonzero\"\n",
            .{ total, executable_ok, link_only_ok, structured_direct_rows, structured_textual_rows, textual_boundary_rows, generic_codegen_rows, case_specific_codegen_rows, minimal_ret0, ownership_value },
        );
        try stdout_writer.interface.flush();
        std.process.exit(1);
    }

    try stdout_writer.interface.print(
        "selected-zllvm status=ok total={s} executable_ok={s} link_only_ok={s} structured_direct_rows={s} structured_textual_rows={s} textual_boundary_rows={s} generic_codegen_rows={s} case_specific_codegen_rows={s} minimal-ret0={s} ownership={s} first_failure_case_id=- first_failure_wrapper=- first_failure_mode=- first_failure_pipeline=- first_failure_error=-\n",
        .{ total, executable_ok, link_only_ok, structured_direct_rows, structured_textual_rows, textual_boundary_rows, generic_codegen_rows, case_specific_codegen_rows, minimal_ret0, ownership_value },
    );
    try stdout_writer.interface.flush();
}

fn findLine(text: []const u8, prefix: []const u8) ?[]const u8 {
    var start: usize = 0;
    while (start <= text.len) {
        const newline = std.mem.indexOfScalarPos(u8, text, start, '\n');
        const end = newline orelse text.len;
        const line = std.mem.trimEnd(u8, text[start..end], "\r");
        if (std.mem.startsWith(u8, line, prefix)) return line;
        if (newline == null) break;
        start = end + 1;
    }
    return null;
}

fn valueAfter(line: []const u8, key: []const u8) ?[]const u8 {
    const start = std.mem.indexOf(u8, line, key) orelse return null;
    const value_start = start + key.len;
    const rest = line[value_start..];
    const value_len = std.mem.indexOfAny(u8, rest, " \t\r\n") orelse rest.len;
    return rest[0..value_len];
}

fn firstFailureError(stderr: []const u8, stdout: []const u8) []const u8 {
    const source = if (stderr.len != 0) stderr else stdout;
    const line = common.firstLine(source);
    if (line.len == 0) return "process-exited-without-diagnostics";
    return line[0..@min(line.len, 240)];
}

fn parsePipeline(stdout: []const u8) ?[]const u8 {
    const header = findLine(stdout, "zig-integrated-object ") orelse return null;
    return valueAfter(header, "pipeline=");
}

fn firstCaseId(text: []const u8) ?[]const u8 {
    const starts = [_][]const u8{ "releasefast_", "releasesafe_", "releasesmall_" };
    var best: ?usize = null;
    for (starts) |prefix| {
        if (std.mem.indexOf(u8, text, prefix)) |index| {
            if (best == null or index < best.?) best = index;
        }
    }
    const start = best orelse return null;
    var end = start;
    while (end < text.len) : (end += 1) {
        const byte = text[end];
        if (!(std.ascii.isAlphanumeric(byte) or byte == '_' or byte == '-')) break;
    }
    return text[start..end];
}
