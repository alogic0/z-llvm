const std = @import("std");
const common = @import("tool_common.zig");

const usage =
    \\usage: zig run tools/update_doc_counters.zig -- --gate=distribution-air-release-frontier --from-log=<log>
    \\
    \\Updates documented counter snapshots from a saved gate log.
    \\The frontier gate log must contain complete ReleaseFast, ReleaseSafe, and ReleaseSmall summaries.
    \\Currently supported gates:
    \\  distribution-air-release-frontier
    \\  distribution-air-release-frontier-boundaries
    \\
;

const Mode = enum {
    ReleaseFast,
    ReleaseSafe,
    ReleaseSmall,

    fn parse(text: []const u8) ?Mode {
        if (std.mem.eql(u8, text, "ReleaseFast")) return .ReleaseFast;
        if (std.mem.eql(u8, text, "ReleaseSafe")) return .ReleaseSafe;
        if (std.mem.eql(u8, text, "ReleaseSmall")) return .ReleaseSmall;
        return null;
    }

    fn index(mode: Mode) usize {
        return switch (mode) {
            .ReleaseFast => 0,
            .ReleaseSafe => 1,
            .ReleaseSmall => 2,
        };
    }
};

const CounterSet = struct {
    source_rows: usize = 0,
    discovered_functions: usize = 0,
    structured_functions: usize = 0,
    generic_codegen_functions: usize = 0,
    generic_cfg_functions: usize = 0,
    structural_matcher_functions: usize = 0,
    structured_air_v2_functions: usize = 0,
    typed_air_operand_functions: usize = 0,
    legacy_air_text_lowering_functions: usize = 0,
    typed_v2_fallback_functions: usize = 0,
    generic_lowering_functions: usize = 0,
    shape_recognizer_functions: usize = 0,
    unsupported_functions: usize = 0,
    codegen_failures: usize = 0,
    object_emitted_functions: usize = 0,
    object_failures: usize = 0,
    native_link_accepted_rows: usize = 0,
    executable_ok_rows: usize = 0,
    link_only_rows: usize = 0,
    runtime_boundary_rows: usize = 0,
    unsupported_zig_linker_feature_rows: usize = 0,
    native_link_failures: usize = 0,
    llvm_targetmachine_rows: usize = 0,
    lld_rows: usize = 0,
    local_fail: usize = 0,
};

const BoundaryCounterSet = struct {
    source_rows: usize = 0,
    discovered_functions: usize = 0,
    varargs_boundary_rows: usize = 0,
    vector_boundary_rows: usize = 0,
    x87_boundary_rows: usize = 0,
    packed_aggregate_boundary_rows: usize = 0,
    tail_call_boundary_rows: usize = 0,
    callconv_boundary_rows: usize = 0,
    stack_pressure_boundary_rows: usize = 0,
    safety_edge_boundary_rows: usize = 0,
    pointer_slice_boundary_rows: usize = 0,
    tag_name_boundary_rows: usize = 0,
    unexpected_accept_rows: usize = 0,
    wrong_diagnostic_rows: usize = 0,
    llvm_targetmachine_rows: usize = 0,
    lld_rows: usize = 0,
    local_fail: usize = 0,
};

const ParsedMode = struct {
    air: ?CounterSet = null,
    object: ?CounterSet = null,
    executable: ?CounterSet = null,
};

const ParsedGate = struct {
    modes: [3]ParsedMode = .{ .{}, .{}, .{} },

    fn merged(parsed: ParsedGate, io: std.Io) !CounterSet {
        var result: ?CounterSet = null;
        var complete_modes: usize = 0;
        for (parsed.modes, 0..) |mode_result, mode_index| {
            const has_any = mode_result.air != null or mode_result.object != null or mode_result.executable != null;
            if (!has_any) continue;
            const air = mode_result.air orelse try common.validationError(io, "incomplete frontier summary for mode index {}: missing uncurated-zig-air\n", .{mode_index});
            const object = mode_result.object orelse try common.validationError(io, "incomplete frontier summary for mode index {}: missing uncurated-zig-air-object\n", .{mode_index});
            const executable = mode_result.executable orelse try common.validationError(io, "incomplete frontier summary for mode index {}: missing uncurated-zig-air-executable\n", .{mode_index});
            complete_modes += 1;

            var combined = air;
            combined.object_emitted_functions = object.object_emitted_functions;
            combined.object_failures = object.object_failures;
            combined.llvm_targetmachine_rows = object.llvm_targetmachine_rows;
            combined.native_link_accepted_rows = executable.native_link_accepted_rows;
            combined.executable_ok_rows = executable.executable_ok_rows;
            combined.link_only_rows = executable.link_only_rows;
            combined.runtime_boundary_rows = executable.runtime_boundary_rows;
            combined.unsupported_zig_linker_feature_rows = executable.unsupported_zig_linker_feature_rows;
            combined.native_link_failures = executable.native_link_failures;
            combined.lld_rows = executable.lld_rows;
            combined.local_fail = @max(air.local_fail, @max(object.local_fail, executable.local_fail));

            if (result) |expected| {
                try expectSameCounters(io, expected, combined);
            } else {
                result = combined;
            }
        }
        if (complete_modes == 0) {
            try common.validationError(io, "missing frontier gate summaries in log\n", .{});
        }
        if (complete_modes != 3) {
            try common.validationError(io, "incomplete frontier gate log: expected 3 complete release mode summaries, found {}\n", .{complete_modes});
        }
        return result orelse unreachable;
    }
};

const Field = struct {
    name: []const u8,
    value: *const fn (CounterSet) usize,
};

const BoundaryField = struct {
    name: []const u8,
    value: *const fn (BoundaryCounterSet) usize,
};

const fields = [_]Field{
    .{ .name = "source_rows", .value = fieldSourceRows },
    .{ .name = "discovered_functions", .value = fieldDiscoveredFunctions },
    .{ .name = "structured_functions", .value = fieldStructuredFunctions },
    .{ .name = "generic_codegen_functions", .value = fieldGenericCodegenFunctions },
    .{ .name = "generic_cfg_functions", .value = fieldGenericCfgFunctions },
    .{ .name = "structural_matcher_functions", .value = fieldStructuralMatcherFunctions },
    .{ .name = "structured_air_v2_functions", .value = fieldStructuredAirV2Functions },
    .{ .name = "typed_air_operand_functions", .value = fieldTypedAirOperandFunctions },
    .{ .name = "legacy_air_text_lowering_functions", .value = fieldLegacyAirTextLoweringFunctions },
    .{ .name = "typed_v2_fallback_functions", .value = fieldTypedV2FallbackFunctions },
    .{ .name = "generic_lowering_functions", .value = fieldGenericLoweringFunctions },
    .{ .name = "shape_recognizer_functions", .value = fieldShapeRecognizerFunctions },
    .{ .name = "unsupported_functions", .value = fieldUnsupportedFunctions },
    .{ .name = "codegen_failures", .value = fieldCodegenFailures },
    .{ .name = "object_emitted_functions", .value = fieldObjectEmittedFunctions },
    .{ .name = "object_failures", .value = fieldObjectFailures },
    .{ .name = "native_link_accepted_rows", .value = fieldNativeLinkAcceptedRows },
    .{ .name = "executable_ok_rows", .value = fieldExecutableOkRows },
    .{ .name = "link_only_rows", .value = fieldLinkOnlyRows },
    .{ .name = "runtime_boundary_rows", .value = fieldRuntimeBoundaryRows },
    .{ .name = "unsupported_zig_linker_feature_rows", .value = fieldUnsupportedZigLinkerFeatureRows },
    .{ .name = "native_link_failures", .value = fieldNativeLinkFailures },
    .{ .name = "llvm_targetmachine_rows", .value = fieldLlvmTargetmachineRows },
    .{ .name = "lld_rows", .value = fieldLldRows },
    .{ .name = "local_fail", .value = fieldLocalFail },
};

const boundary_fields = [_]BoundaryField{
    .{ .name = "source_rows", .value = boundaryFieldSourceRows },
    .{ .name = "discovered_functions", .value = boundaryFieldDiscoveredFunctions },
    .{ .name = "varargs_boundary_rows", .value = boundaryFieldVarargsRows },
    .{ .name = "vector_boundary_rows", .value = boundaryFieldVectorRows },
    .{ .name = "x87_boundary_rows", .value = boundaryFieldX87Rows },
    .{ .name = "packed_aggregate_boundary_rows", .value = boundaryFieldPackedRows },
    .{ .name = "tail_call_boundary_rows", .value = boundaryFieldTailCallRows },
    .{ .name = "callconv_boundary_rows", .value = boundaryFieldCallConvRows },
    .{ .name = "stack_pressure_boundary_rows", .value = boundaryFieldStackPressureRows },
    .{ .name = "safety_edge_boundary_rows", .value = boundaryFieldSafetyEdgeRows },
    .{ .name = "pointer_slice_boundary_rows", .value = boundaryFieldPointerSliceRows },
    .{ .name = "tag_name_boundary_rows", .value = boundaryFieldTagNameRows },
    .{ .name = "unexpected_accept_rows", .value = boundaryFieldUnexpectedAcceptRows },
    .{ .name = "wrong_diagnostic_rows", .value = boundaryFieldWrongDiagnosticRows },
    .{ .name = "llvm_targetmachine_rows", .value = boundaryFieldLlvmTargetmachineRows },
    .{ .name = "lld_rows", .value = boundaryFieldLldRows },
    .{ .name = "local_fail", .value = boundaryFieldLocalFail },
};

const Section = struct {
    start: []const u8,
    end: ?[]const u8 = null,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const options = try parseArgs(allocator, io, init);
    if (!std.mem.eql(u8, options.gate, "distribution-air-release-frontier") and
        !std.mem.eql(u8, options.gate, "distribution-air-release-frontier-boundaries"))
    {
        try common.validationError(io, "unsupported gate: {s}\n{s}", .{ options.gate, usage });
    }

    const log = try std.Io.Dir.cwd().readFileAlloc(io, options.from_log, allocator, .limited(128 * 1024 * 1024));
    defer allocator.free(log);

    if (std.mem.eql(u8, options.gate, "distribution-air-release-frontier-boundaries")) {
        const counters = try parseFrontierBoundaryGateLog(io, log);
        var changed_files: usize = 0;
        changed_files += try updateBoundaryLineFilteredFile(allocator, io, "docs/build_steps.md", counters, &.{
            "`zig build distribution-air-release-frontier-boundaries`",
        });
        changed_files += try updateBoundarySectionFile(allocator, io, "docs/roadmap/x86_64_frontier_air_corpus.md", counters, &.{
            .{ .start = "Source-backed ABI and pointer/slice boundary proof is green", .end = "Executable ABI proof" },
        });
        changed_files += try updateBoundarySectionFile(allocator, io, "docs/upstream_integration_readiness.md", counters, &.{
            .{ .start = "Source-backed ABI and pointer/slice boundary proof is tracked separately", .end = "The selected slice-panic" },
        });
        changed_files += try updateBoundarySectionFile(allocator, io, "docs/next_steps.md", counters, &.{
            .{ .start = "Source-backed ABI and pointer/slice boundaries are now measured separately", .end = "Typed AIR v2 pointer-callee" },
        });
        changed_files += try updateBoundarySectionFile(allocator, io, "docs/roadmap/x86_64_distribution_replacement_matrix.md", counters, &.{
            .{ .start = "source-backed fail-closed varargs/vector/X87/packed aggregate/tail-call/callconv boundary proof", .end = "while arbitrary" },
        });

        var stdout_buffer: [512]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
        try stdout_writer.interface.print(
            "updated-doc-counters gate={s} source_rows={} discovered_functions={} varargs_boundary_rows={} vector_boundary_rows={} x87_boundary_rows={} packed_aggregate_boundary_rows={} tail_call_boundary_rows={} callconv_boundary_rows={} stack_pressure_boundary_rows={} safety_edge_boundary_rows={} pointer_slice_boundary_rows={} tag_name_boundary_rows={} changed_files={}\n",
            .{
                options.gate,
                counters.source_rows,
                counters.discovered_functions,
                counters.varargs_boundary_rows,
                counters.vector_boundary_rows,
                counters.x87_boundary_rows,
                counters.packed_aggregate_boundary_rows,
                counters.tail_call_boundary_rows,
                counters.callconv_boundary_rows,
                counters.stack_pressure_boundary_rows,
                counters.safety_edge_boundary_rows,
                counters.pointer_slice_boundary_rows,
                counters.tag_name_boundary_rows,
                changed_files,
            },
        );
        try stdout_writer.interface.flush();
        return;
    }

    const counters = try parseFrontierGateLog(io, log);
    var changed_files: usize = 0;
    changed_files += try updateSectionFile(allocator, io, "docs/roadmap/x86_64_frontier_air_corpus.md", counters, &.{
        .{ .start = "Current ReleaseFast, ReleaseSafe, and ReleaseSmall counters:", .end = "Object inspection is green" },
        .{ .start = "Object inspection is green", .end = "Native-link progress is green" },
        .{ .start = "Native-link progress is green", .end = "Source-backed ABI and pointer/slice boundary proof" },
        .{ .start = "Executable ABI proof is green", .end = "Closed in the current runtime/safety-edge slice:" },
    });
    changed_files += try updateLineFilteredFile(allocator, io, "docs/build_steps.md", counters, &.{
        "`zig build distribution-zig-air-uncurated-releasefast-frontier`",
        "`zig build distribution-zig-air-uncurated-releasesafe-frontier`",
        "`zig build distribution-zig-air-uncurated-releasesmall-frontier`",
        "`zig build distribution-zig-air-uncurated-release-frontier`",
        "`zig build distribution-air-release-frontier`",
    });
    changed_files += try updateSectionFile(allocator, io, "docs/next_steps.md", counters, &.{
        .{ .start = "Next corpus frontier:", .end = "Strict release baselines" },
    });
    changed_files += try updateSectionFile(allocator, io, "docs/upstream_integration_readiness.md", counters, &.{
        .{ .start = "`distribution-zig-air-uncurated-release-frontier` covers only", .end = "Source-backed ABI and pointer/slice boundary proof" },
    });
    changed_files += try updateSectionFile(allocator, io, "docs/roadmap/x86_64_distribution_replacement_matrix.md", counters, &.{
        .{ .start = "The next corpus frontier is isolated", .end = "source-backed fail-closed" },
    });

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print(
        "updated-doc-counters gate={s} source_rows={} discovered_functions={} object_emitted_functions={} executable_ok_rows={} changed_files={}\n",
        .{
            options.gate,
            counters.source_rows,
            counters.discovered_functions,
            counters.object_emitted_functions,
            counters.executable_ok_rows,
            changed_files,
        },
    );
    try stdout_writer.interface.flush();
}

const Options = struct {
    gate: []const u8,
    from_log: []const u8,
};

fn parseArgs(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Options {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var gate: ?[]const u8 = null;
    var from_log: ?[]const u8 = null;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [512]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll(usage);
            try stdout_writer.interface.flush();
            std.process.exit(0);
        } else if (std.mem.startsWith(u8, arg, "--gate=")) {
            gate = arg["--gate=".len..];
        } else if (std.mem.startsWith(u8, arg, "--from-log=")) {
            from_log = arg["--from-log=".len..];
        } else {
            try common.validationError(io, "unexpected argument: {s}\n{s}", .{ arg, usage });
        }
    }
    return .{
        .gate = gate orelse try common.validationError(io, "missing --gate\n{s}", .{usage}),
        .from_log = from_log orelse try common.validationError(io, "missing --from-log\n{s}", .{usage}),
    };
}

fn parseFrontierGateLog(io: std.Io, log: []const u8) !CounterSet {
    var parsed: ParsedGate = .{};
    var lines = std.mem.splitScalar(u8, log, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        if (!std.mem.startsWith(u8, line, "summary uncurated-zig-air")) continue;
        if (!hasToken(line, "corpus=frontier") and !std.mem.startsWith(u8, line, "summary uncurated-zig-air-object") and !std.mem.startsWith(u8, line, "summary uncurated-zig-air-executable")) continue;
        const mode = parseModeToken(line) orelse continue;
        const mode_index = mode.index();
        if (std.mem.startsWith(u8, line, "summary uncurated-zig-air-object")) {
            parsed.modes[mode_index].object = parseCounterLine(line);
        } else if (std.mem.startsWith(u8, line, "summary uncurated-zig-air-executable")) {
            parsed.modes[mode_index].executable = parseCounterLine(line);
        } else if (hasToken(line, "corpus=frontier")) {
            parsed.modes[mode_index].air = parseCounterLine(line);
        }
    }
    return parsed.merged(io);
}

fn parseFrontierBoundaryGateLog(io: std.Io, log: []const u8) !BoundaryCounterSet {
    var result: ?BoundaryCounterSet = null;
    var complete_modes: usize = 0;
    var lines = std.mem.splitScalar(u8, log, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        if (!std.mem.startsWith(u8, line, "summary uncurated-zig-air-abi-boundaries")) continue;
        if (!hasToken(line, "corpus=frontier-boundaries")) continue;
        _ = parseModeToken(line) orelse continue;
        const counters = parseBoundaryCounterLine(line);
        complete_modes += 1;
        if (result) |expected| {
            try expectSameBoundaryCounters(io, expected, counters);
        } else {
            result = counters;
        }
    }
    if (complete_modes != 3) {
        try common.validationError(io, "incomplete frontier boundary gate log: expected 3 complete release mode summaries, found {}\n", .{complete_modes});
    }
    return result orelse try common.validationError(io, "missing frontier boundary gate summaries in log\n", .{});
}

fn parseModeToken(line: []const u8) ?Mode {
    const prefix = "mode=";
    const start = (std.mem.indexOf(u8, line, prefix) orelse return null) + prefix.len;
    const rest = line[start..];
    const end = std.mem.indexOfScalar(u8, rest, ' ') orelse rest.len;
    return Mode.parse(rest[0..end]);
}

fn parseCounterLine(line: []const u8) CounterSet {
    return .{
        .source_rows = parseField(line, "source_rows") orelse 0,
        .discovered_functions = parseField(line, "discovered_functions") orelse 0,
        .structured_functions = parseField(line, "structured_functions") orelse 0,
        .generic_codegen_functions = parseField(line, "generic_codegen_functions") orelse 0,
        .generic_cfg_functions = parseField(line, "generic_cfg_functions") orelse 0,
        .structural_matcher_functions = parseField(line, "structural_matcher_functions") orelse 0,
        .structured_air_v2_functions = parseField(line, "structured_air_v2_functions") orelse 0,
        .typed_air_operand_functions = parseField(line, "typed_air_operand_functions") orelse 0,
        .legacy_air_text_lowering_functions = parseField(line, "legacy_air_text_lowering_functions") orelse 0,
        .typed_v2_fallback_functions = parseField(line, "typed_v2_fallback_functions") orelse 0,
        .generic_lowering_functions = parseField(line, "generic_lowering_functions") orelse 0,
        .shape_recognizer_functions = parseField(line, "shape_recognizer_functions") orelse 0,
        .unsupported_functions = parseField(line, "unsupported_functions") orelse 0,
        .codegen_failures = parseField(line, "codegen_failures") orelse 0,
        .object_emitted_functions = parseField(line, "object_emitted_functions") orelse 0,
        .object_failures = parseField(line, "object_failures") orelse 0,
        .native_link_accepted_rows = parseField(line, "native_link_accepted_rows") orelse 0,
        .executable_ok_rows = parseField(line, "executable_ok_rows") orelse 0,
        .link_only_rows = parseField(line, "link_only_rows") orelse 0,
        .runtime_boundary_rows = parseField(line, "runtime_boundary_rows") orelse 0,
        .unsupported_zig_linker_feature_rows = parseField(line, "unsupported_zig_linker_feature_rows") orelse 0,
        .native_link_failures = parseField(line, "native_link_failures") orelse 0,
        .llvm_targetmachine_rows = parseField(line, "llvm_targetmachine_rows") orelse 0,
        .lld_rows = parseField(line, "lld_rows") orelse 0,
        .local_fail = parseField(line, "local_fail") orelse 0,
    };
}

fn parseBoundaryCounterLine(line: []const u8) BoundaryCounterSet {
    return .{
        .source_rows = parseField(line, "source_rows") orelse 0,
        .discovered_functions = parseField(line, "discovered_functions") orelse 0,
        .varargs_boundary_rows = parseField(line, "varargs_boundary_rows") orelse 0,
        .vector_boundary_rows = parseField(line, "vector_boundary_rows") orelse 0,
        .x87_boundary_rows = parseField(line, "x87_boundary_rows") orelse 0,
        .packed_aggregate_boundary_rows = parseField(line, "packed_aggregate_boundary_rows") orelse 0,
        .tail_call_boundary_rows = parseField(line, "tail_call_boundary_rows") orelse 0,
        .callconv_boundary_rows = parseField(line, "callconv_boundary_rows") orelse 0,
        .stack_pressure_boundary_rows = parseField(line, "stack_pressure_boundary_rows") orelse 0,
        .safety_edge_boundary_rows = parseField(line, "safety_edge_boundary_rows") orelse 0,
        .pointer_slice_boundary_rows = parseField(line, "pointer_slice_boundary_rows") orelse 0,
        .tag_name_boundary_rows = parseField(line, "tag_name_boundary_rows") orelse 0,
        .unexpected_accept_rows = parseField(line, "unexpected_accept_rows") orelse 0,
        .wrong_diagnostic_rows = parseField(line, "wrong_diagnostic_rows") orelse 0,
        .llvm_targetmachine_rows = parseField(line, "llvm_targetmachine_rows") orelse 0,
        .lld_rows = parseField(line, "lld_rows") orelse 0,
        .local_fail = parseField(line, "local_fail") orelse 0,
    };
}

fn parseField(line: []const u8, field: []const u8) ?usize {
    const start = std.mem.indexOf(u8, line, field) orelse return null;
    if (start + field.len >= line.len or line[start + field.len] != '=') return null;
    var end = start + field.len + 1;
    while (end < line.len and std.ascii.isDigit(line[end])) end += 1;
    if (end == start + field.len + 1) return null;
    return std.fmt.parseInt(usize, line[start + field.len + 1 .. end], 10) catch null;
}

fn hasToken(line: []const u8, token: []const u8) bool {
    return std.mem.indexOf(u8, line, token) != null;
}

fn updateWholeFile(allocator: std.mem.Allocator, io: std.Io, path: []const u8, counters: CounterSet) !usize {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(16 * 1024 * 1024));
    defer allocator.free(contents);
    const updated = try updateTextCounters(allocator, contents, counters, .all);
    defer allocator.free(updated);
    return try writeIfChanged(io, path, contents, updated);
}

fn updateLineFilteredFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    counters: CounterSet,
    required_texts: []const []const u8,
) !usize {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(16 * 1024 * 1024));
    defer allocator.free(contents);
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);

    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const update_mode: UpdateMode = if (containsAny(line, required_texts)) .all else .none;
        const updated_line = try updateTextCounters(allocator, line, counters, update_mode);
        defer allocator.free(updated_line);
        try output.appendSlice(allocator, updated_line);
        if (lines.index != null) try output.append(allocator, '\n');
    }
    const updated = try output.toOwnedSlice(allocator);
    defer allocator.free(updated);
    return try writeIfChanged(io, path, contents, updated);
}

fn containsAny(line: []const u8, needles: []const []const u8) bool {
    for (needles) |needle| {
        if (std.mem.indexOf(u8, line, needle) != null) return true;
    }
    return false;
}

fn updateSectionFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    counters: CounterSet,
    sections: []const Section,
) !usize {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(16 * 1024 * 1024));
    defer allocator.free(contents);
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);

    var active: ?usize = null;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        if (active == null) {
            for (sections, 0..) |section, index| {
                if (std.mem.indexOf(u8, line, section.start) != null) {
                    active = index;
                    break;
                }
            }
        }

        const updated_line = try updateTextCounters(allocator, line, counters, if (active != null) .all else .none);
        defer allocator.free(updated_line);
        try output.appendSlice(allocator, updated_line);
        if (lines.index != null) try output.append(allocator, '\n');

        if (active) |section_index| {
            if (sections[section_index].end) |end_marker| {
                if (std.mem.indexOf(u8, line, end_marker) != null) active = null;
            }
        }
    }
    const updated = try output.toOwnedSlice(allocator);
    defer allocator.free(updated);
    return try writeIfChanged(io, path, contents, updated);
}

fn updateBoundaryLineFilteredFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    counters: BoundaryCounterSet,
    required_texts: []const []const u8,
) !usize {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(16 * 1024 * 1024));
    defer allocator.free(contents);
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);

    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const updated_line = if (containsAny(line, required_texts))
            try updateBoundaryTextCounters(allocator, line, counters, .all)
        else
            try allocator.dupe(u8, line);
        defer allocator.free(updated_line);
        try output.appendSlice(allocator, updated_line);
        if (lines.index != null) try output.append(allocator, '\n');
    }
    const updated = try output.toOwnedSlice(allocator);
    defer allocator.free(updated);
    return try writeIfChanged(io, path, contents, updated);
}

fn updateBoundarySectionFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    counters: BoundaryCounterSet,
    sections: []const Section,
) !usize {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(16 * 1024 * 1024));
    defer allocator.free(contents);
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);

    var active: ?usize = null;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        if (active == null) {
            for (sections, 0..) |section, index| {
                if (std.mem.indexOf(u8, line, section.start) != null) {
                    active = index;
                    break;
                }
            }
        }

        const updated_line = if (active != null)
            try updateBoundaryTextCounters(allocator, line, counters, .all)
        else
            try allocator.dupe(u8, line);
        defer allocator.free(updated_line);
        try output.appendSlice(allocator, updated_line);
        if (lines.index != null) try output.append(allocator, '\n');

        if (active) |section_index| {
            if (sections[section_index].end) |end_marker| {
                if (std.mem.indexOf(u8, line, end_marker) != null) active = null;
            }
        }
    }
    const updated = try output.toOwnedSlice(allocator);
    defer allocator.free(updated);
    return try writeIfChanged(io, path, contents, updated);
}

const UpdateMode = enum { none, all };

fn updateTextCounters(
    allocator: std.mem.Allocator,
    text: []const u8,
    counters: CounterSet,
    mode: UpdateMode,
) ![]u8 {
    if (mode == .none) return allocator.dupe(u8, text);
    var current = try allocator.dupe(u8, text);
    errdefer allocator.free(current);
    for (fields) |field| {
        const next = try replaceCounterField(allocator, current, field.name, field.value(counters));
        allocator.free(current);
        current = next;
    }
    const compact = try replaceCompactSourceFunction(allocator, current, counters);
    allocator.free(current);
    return compact;
}

fn updateBoundaryTextCounters(
    allocator: std.mem.Allocator,
    text: []const u8,
    counters: BoundaryCounterSet,
    mode: UpdateMode,
) ![]u8 {
    if (mode == .none) return allocator.dupe(u8, text);
    var current = try allocator.dupe(u8, text);
    errdefer allocator.free(current);
    for (boundary_fields) |field| {
        const next = try replaceCounterField(allocator, current, field.name, field.value(counters));
        allocator.free(current);
        current = next;
    }
    return current;
}

fn replaceCounterField(allocator: std.mem.Allocator, text: []const u8, field: []const u8, value: usize) ![]u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    var index: usize = 0;
    while (std.mem.indexOfPos(u8, text, index, field)) |field_start| {
        const equals_index = field_start + field.len;
        if (equals_index >= text.len or text[equals_index] != '=') {
            try output.appendSlice(allocator, text[index .. field_start + field.len]);
            index = field_start + field.len;
            continue;
        }
        const value_start = equals_index + 1;
        var value_end = value_start;
        while (value_end < text.len and std.ascii.isDigit(text[value_end])) value_end += 1;
        if (value_end == value_start) {
            try output.appendSlice(allocator, text[index .. field_start + field.len]);
            index = field_start + field.len;
            continue;
        }
        try output.appendSlice(allocator, text[index..value_start]);
        const formatted = try std.fmt.allocPrint(allocator, "{}", .{value});
        defer allocator.free(formatted);
        try output.appendSlice(allocator, formatted);
        index = value_end;
    }
    try output.appendSlice(allocator, text[index..]);
    return output.toOwnedSlice(allocator);
}

fn replaceCompactSourceFunction(allocator: std.mem.Allocator, text: []const u8, counters: CounterSet) ![]u8 {
    const source_suffix = "-source / ";
    const function_suffix = "-function";
    const source_suffix_start = std.mem.indexOf(u8, text, source_suffix) orelse return allocator.dupe(u8, text);
    const function_suffix_start = std.mem.indexOfPos(u8, text, source_suffix_start + source_suffix.len, function_suffix) orelse return allocator.dupe(u8, text);

    var source_start = source_suffix_start;
    while (source_start > 0 and std.ascii.isDigit(text[source_start - 1])) source_start -= 1;
    if (source_start == source_suffix_start) return allocator.dupe(u8, text);

    var function_start = function_suffix_start;
    while (function_start > source_suffix_start + source_suffix.len and std.ascii.isDigit(text[function_start - 1])) function_start -= 1;
    if (function_start == function_suffix_start) return allocator.dupe(u8, text);

    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    try output.appendSlice(allocator, text[0..source_start]);
    const formatted = try std.fmt.allocPrint(allocator, "{}-source / {}-function", .{ counters.source_rows, counters.discovered_functions });
    defer allocator.free(formatted);
    try output.appendSlice(allocator, formatted);
    try output.appendSlice(allocator, text[function_suffix_start + function_suffix.len ..]);
    return output.toOwnedSlice(allocator);
}

fn writeIfChanged(io: std.Io, path: []const u8, old: []const u8, new: []const u8) !usize {
    if (std.mem.eql(u8, old, new)) return 0;
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = new });
    return 1;
}

fn expectSameCounters(io: std.Io, expected: CounterSet, actual: CounterSet) !void {
    inline for (std.meta.fields(CounterSet)) |field| {
        if (@field(expected, field.name) != @field(actual, field.name)) {
            try common.validationError(
                io,
                "frontier mode counter mismatch field={s} expected={} actual={}\n",
                .{ field.name, @field(expected, field.name), @field(actual, field.name) },
            );
        }
    }
}

fn expectSameBoundaryCounters(io: std.Io, expected: BoundaryCounterSet, actual: BoundaryCounterSet) !void {
    inline for (std.meta.fields(BoundaryCounterSet)) |field| {
        if (@field(expected, field.name) != @field(actual, field.name)) {
            try common.validationError(
                io,
                "frontier boundary mode counter mismatch field={s} expected={} actual={}\n",
                .{ field.name, @field(expected, field.name), @field(actual, field.name) },
            );
        }
    }
}

fn fieldSourceRows(c: CounterSet) usize {
    return c.source_rows;
}
fn fieldDiscoveredFunctions(c: CounterSet) usize {
    return c.discovered_functions;
}
fn fieldStructuredFunctions(c: CounterSet) usize {
    return c.structured_functions;
}
fn fieldGenericCodegenFunctions(c: CounterSet) usize {
    return c.generic_codegen_functions;
}
fn fieldGenericCfgFunctions(c: CounterSet) usize {
    return c.generic_cfg_functions;
}
fn fieldStructuralMatcherFunctions(c: CounterSet) usize {
    return c.structural_matcher_functions;
}
fn fieldStructuredAirV2Functions(c: CounterSet) usize {
    return c.structured_air_v2_functions;
}
fn fieldTypedAirOperandFunctions(c: CounterSet) usize {
    return c.typed_air_operand_functions;
}
fn fieldLegacyAirTextLoweringFunctions(c: CounterSet) usize {
    return c.legacy_air_text_lowering_functions;
}
fn fieldTypedV2FallbackFunctions(c: CounterSet) usize {
    return c.typed_v2_fallback_functions;
}
fn fieldGenericLoweringFunctions(c: CounterSet) usize {
    return c.generic_lowering_functions;
}
fn fieldShapeRecognizerFunctions(c: CounterSet) usize {
    return c.shape_recognizer_functions;
}
fn fieldUnsupportedFunctions(c: CounterSet) usize {
    return c.unsupported_functions;
}
fn fieldCodegenFailures(c: CounterSet) usize {
    return c.codegen_failures;
}
fn fieldObjectEmittedFunctions(c: CounterSet) usize {
    return c.object_emitted_functions;
}
fn fieldObjectFailures(c: CounterSet) usize {
    return c.object_failures;
}
fn fieldNativeLinkAcceptedRows(c: CounterSet) usize {
    return c.native_link_accepted_rows;
}
fn fieldExecutableOkRows(c: CounterSet) usize {
    return c.executable_ok_rows;
}
fn fieldLinkOnlyRows(c: CounterSet) usize {
    return c.link_only_rows;
}
fn fieldRuntimeBoundaryRows(c: CounterSet) usize {
    return c.runtime_boundary_rows;
}
fn fieldUnsupportedZigLinkerFeatureRows(c: CounterSet) usize {
    return c.unsupported_zig_linker_feature_rows;
}
fn fieldNativeLinkFailures(c: CounterSet) usize {
    return c.native_link_failures;
}
fn fieldLlvmTargetmachineRows(c: CounterSet) usize {
    return c.llvm_targetmachine_rows;
}
fn fieldLldRows(c: CounterSet) usize {
    return c.lld_rows;
}
fn fieldLocalFail(c: CounterSet) usize {
    return c.local_fail;
}

fn boundaryFieldSourceRows(c: BoundaryCounterSet) usize {
    return c.source_rows;
}
fn boundaryFieldDiscoveredFunctions(c: BoundaryCounterSet) usize {
    return c.discovered_functions;
}
fn boundaryFieldVarargsRows(c: BoundaryCounterSet) usize {
    return c.varargs_boundary_rows;
}
fn boundaryFieldVectorRows(c: BoundaryCounterSet) usize {
    return c.vector_boundary_rows;
}
fn boundaryFieldX87Rows(c: BoundaryCounterSet) usize {
    return c.x87_boundary_rows;
}
fn boundaryFieldPackedRows(c: BoundaryCounterSet) usize {
    return c.packed_aggregate_boundary_rows;
}
fn boundaryFieldTailCallRows(c: BoundaryCounterSet) usize {
    return c.tail_call_boundary_rows;
}
fn boundaryFieldCallConvRows(c: BoundaryCounterSet) usize {
    return c.callconv_boundary_rows;
}
fn boundaryFieldStackPressureRows(c: BoundaryCounterSet) usize {
    return c.stack_pressure_boundary_rows;
}
fn boundaryFieldSafetyEdgeRows(c: BoundaryCounterSet) usize {
    return c.safety_edge_boundary_rows;
}
fn boundaryFieldPointerSliceRows(c: BoundaryCounterSet) usize {
    return c.pointer_slice_boundary_rows;
}
fn boundaryFieldTagNameRows(c: BoundaryCounterSet) usize {
    return c.tag_name_boundary_rows;
}
fn boundaryFieldUnexpectedAcceptRows(c: BoundaryCounterSet) usize {
    return c.unexpected_accept_rows;
}
fn boundaryFieldWrongDiagnosticRows(c: BoundaryCounterSet) usize {
    return c.wrong_diagnostic_rows;
}
fn boundaryFieldLlvmTargetmachineRows(c: BoundaryCounterSet) usize {
    return c.llvm_targetmachine_rows;
}
fn boundaryFieldLldRows(c: BoundaryCounterSet) usize {
    return c.lld_rows;
}
fn boundaryFieldLocalFail(c: BoundaryCounterSet) usize {
    return c.local_fail;
}
