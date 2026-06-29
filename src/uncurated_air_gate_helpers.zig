const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_roots = @import("zig_air_roots.zig");
const codegen = @import("codegen.zig");
const mc = @import("mc.zig");
const runtime_boundaries = @import("runtime_boundaries.zig");

pub fn rootFunctionCount(module: air_export.Module) usize {
    return air_roots.moduleRootFunctionCount(module);
}

pub const Options = struct {
    mode: Mode = .ReleaseFast,
    all_release_modes: bool = false,
    corpus: Corpus = .inputs,
    object_progress: bool = false,
    object_inspection: bool = false,
    native_link_progress: bool = false,
    executable_progress: bool = false,
    strict_finish: bool = false,
    abi_boundary_expectations: bool = false,
};

pub const Mode = enum {
    ReleaseFast,
    ReleaseSafe,
    ReleaseSmall,

    pub fn name(self: Mode) []const u8 {
        return switch (self) {
            .ReleaseFast => "ReleaseFast",
            .ReleaseSafe => "ReleaseSafe",
            .ReleaseSmall => "ReleaseSmall",
        };
    }

    pub fn lowerName(self: Mode) []const u8 {
        return switch (self) {
            .ReleaseFast => "releasefast",
            .ReleaseSafe => "releasesafe",
            .ReleaseSmall => "releasesmall",
        };
    }

    pub fn zigOptimizeArg(self: Mode) []const u8 {
        return switch (self) {
            .ReleaseFast => "-OReleaseFast",
            .ReleaseSafe => "-OReleaseSafe",
            .ReleaseSmall => "-OReleaseSmall",
        };
    }
};

pub const Corpus = enum {
    inputs,
    broad,
    expanded,
    scale,
    frontier,
    frontier_boundaries,

    pub fn name(self: Corpus) []const u8 {
        return switch (self) {
            .inputs => "inputs",
            .broad => "broad",
            .expanded => "expanded",
            .scale => "scale",
            .frontier => "frontier",
            .frontier_boundaries => "frontier-boundaries",
        };
    }
};

pub fn parseOptions(args: std.process.Args) !Options {
    var options: Options = .{};
    var iterator = std.process.Args.Iterator.init(args);
    _ = iterator.skip();
    while (iterator.next()) |arg| {
        if (std.mem.eql(u8, arg, "--mode=ReleaseFast")) {
            options.mode = .ReleaseFast;
        } else if (std.mem.eql(u8, arg, "--mode=ReleaseSafe")) {
            options.mode = .ReleaseSafe;
        } else if (std.mem.eql(u8, arg, "--mode=ReleaseSmall")) {
            options.mode = .ReleaseSmall;
        } else if (std.mem.eql(u8, arg, "--all-release-modes")) {
            options.all_release_modes = true;
        } else if (std.mem.eql(u8, arg, "--corpus=inputs")) {
            options.corpus = .inputs;
        } else if (std.mem.eql(u8, arg, "--corpus=broad")) {
            options.corpus = .broad;
        } else if (std.mem.eql(u8, arg, "--corpus=expanded")) {
            options.corpus = .expanded;
        } else if (std.mem.eql(u8, arg, "--corpus=scale")) {
            options.corpus = .scale;
        } else if (std.mem.eql(u8, arg, "--corpus=frontier")) {
            options.corpus = .frontier;
        } else if (std.mem.eql(u8, arg, "--corpus=frontier-boundaries")) {
            options.corpus = .frontier_boundaries;
        } else if (std.mem.eql(u8, arg, "--object-progress")) {
            options.object_progress = true;
        } else if (std.mem.eql(u8, arg, "--object-inspection")) {
            options.object_inspection = true;
        } else if (std.mem.eql(u8, arg, "--native-link-progress")) {
            options.native_link_progress = true;
        } else if (std.mem.eql(u8, arg, "--executable-progress")) {
            options.executable_progress = true;
        } else if (std.mem.eql(u8, arg, "--strict-finish")) {
            options.strict_finish = true;
        } else if (std.mem.eql(u8, arg, "--abi-boundary-expectations")) {
            options.abi_boundary_expectations = true;
        } else {
            return error.UnsupportedUncuratedAirArgument;
        }
    }
    return options;
}

pub const StrictFinishCounters = struct {
    mode: Mode,
    corpus: Corpus,
    object_progress: bool,
    executable_progress: bool,
    source_rows: usize,
    discovered_functions: usize,
    structured_functions: usize,
    generic_codegen_functions: usize,
    generic_cfg_functions: usize,
    structural_matcher_functions: usize,
    structured_air_v2_functions: usize,
    typed_air_operand_functions: usize,
    legacy_air_text_lowering_functions: usize,
    typed_v2_fallback_functions: usize,
    generic_lowering_functions: usize,
    shape_recognizer_functions: usize,
    unsupported_functions: usize,
    codegen_failures: usize,
    object_emitted_functions: usize,
    object_failures: usize,
    native_link_accepted_rows: usize,
    executable_ok_rows: usize,
    link_only_rows: usize,
    runtime_boundary_rows: usize,
    unsupported_zig_linker_feature_rows: usize,
    native_link_failures: usize,
};

pub fn validateStrictFinish(counters: StrictFinishCounters) !void {
    const expected = strictExpectations(counters.corpus) orelse {
        std.debug.print(
            "strict-finish-failure mode={s} field=corpus expected=broad-expanded-scale-or-frontier actual={s}\n",
            .{ counters.mode.name(), counters.corpus.name() },
        );
        return error.StrictFinishFailed;
    };
    try expectStrict(counters.mode, "source_rows", counters.source_rows, expected.source_rows);
    try expectStrict(counters.mode, "discovered_functions", counters.discovered_functions, expected.functions);
    try expectStrict(counters.mode, "structured_functions", counters.structured_functions, expected.functions);
    try expectStrict(counters.mode, "generic_codegen_functions", counters.generic_codegen_functions, expected.functions);
    try expectStrict(counters.mode, "generic_cfg_functions", counters.generic_cfg_functions, expected.functions);
    try expectStrict(counters.mode, "structural_matcher_functions", counters.structural_matcher_functions, 0);
    try expectStrict(counters.mode, "structured_air_v2_functions", counters.structured_air_v2_functions, expected.functions);
    try expectStrict(counters.mode, "typed_air_operand_functions", counters.typed_air_operand_functions, expected.functions);
    try expectStrict(counters.mode, "legacy_air_text_lowering_functions", counters.legacy_air_text_lowering_functions, 0);
    try expectStrict(counters.mode, "typed_v2_fallback_functions", counters.typed_v2_fallback_functions, 0);
    try expectStrict(counters.mode, "generic_lowering_functions", counters.generic_lowering_functions, expected.functions);
    try expectStrict(counters.mode, "shape_recognizer_functions", counters.shape_recognizer_functions, 0);
    try expectStrict(counters.mode, "unsupported_functions", counters.unsupported_functions, 0);
    try expectStrict(counters.mode, "codegen_failures", counters.codegen_failures, 0);
    if (counters.object_progress) {
        try expectStrict(counters.mode, "object_emitted_functions", counters.object_emitted_functions, expected.functions);
        try expectStrict(counters.mode, "object_failures", counters.object_failures, 0);
    }
    if (counters.executable_progress) {
        const exec = expected.executable orelse {
            std.debug.print(
                "strict-finish-failure mode={s} field=executable_progress expected=unsupported actual={s}\n",
                .{ counters.mode.name(), counters.corpus.name() },
            );
            return error.StrictFinishFailed;
        };
        try expectStrict(counters.mode, "native_link_accepted_rows", counters.native_link_accepted_rows, exec.native_link_accepted_rows);
        try expectStrict(counters.mode, "executable_ok_rows", counters.executable_ok_rows, exec.executable_ok_rows);
        try expectStrict(counters.mode, "link_only_rows", counters.link_only_rows, exec.link_only_rows);
        try expectStrict(counters.mode, "runtime_boundary_rows", counters.runtime_boundary_rows, exec.runtime_boundary_rows);
        try expectStrict(counters.mode, "unsupported_zig_linker_feature_rows", counters.unsupported_zig_linker_feature_rows, 0);
        try expectStrict(counters.mode, "native_link_failures", counters.native_link_failures, 0);
    }
}

const StrictExpectations = struct {
    source_rows: usize,
    functions: usize,
    executable: ?StrictExecutableExpectations = null,
};

const StrictExecutableExpectations = struct {
    native_link_accepted_rows: usize,
    executable_ok_rows: usize,
    link_only_rows: usize,
    runtime_boundary_rows: usize,
};

fn strictExpectations(corpus: Corpus) ?StrictExpectations {
    return switch (corpus) {
        .broad => .{
            .source_rows = 101,
            .functions = 152,
            .executable = .{
                .native_link_accepted_rows = 100,
                .executable_ok_rows = 100,
                .link_only_rows = 0,
                .runtime_boundary_rows = 1,
            },
        },
        .expanded => .{
            .source_rows = 109,
            .functions = 199,
            .executable = .{
                .native_link_accepted_rows = 108,
                .executable_ok_rows = 108,
                .link_only_rows = 0,
                .runtime_boundary_rows = 1,
            },
        },
        .scale => .{
            .source_rows = 112,
            .functions = 216,
            .executable = .{
                .native_link_accepted_rows = 111,
                .executable_ok_rows = 111,
                .link_only_rows = 0,
                .runtime_boundary_rows = 1,
            },
        },
        .frontier => .{
            .source_rows = 13,
            .functions = 641,
            .executable = .{
                .native_link_accepted_rows = 13,
                .executable_ok_rows = 13,
                .link_only_rows = 0,
                .runtime_boundary_rows = 0,
            },
        },
        .inputs, .frontier_boundaries => null,
    };
}

pub fn expectStrict(mode: Mode, field: []const u8, actual: usize, expected: usize) !void {
    if (actual == expected) return;
    std.debug.print(
        "strict-finish-failure mode={s} field={s} expected={} actual={}\n",
        .{ mode.name(), field, expected, actual },
    );
    return error.StrictFinishFailed;
}

pub const ObjectInspection = struct {
    has_relocations: bool,
    has_tls: bool,
    has_undefined_imports: bool,
};

pub fn inspectObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    object_path: []const u8,
    mode: Mode,
    source: []const u8,
) !ObjectInspection {
    const readelf_argv = [_][]const u8{ "readelf", "-W", "-h", "-S", "-s", "-r", object_path };
    const readelf_result = try std.process.run(allocator, io, .{
        .argv = &readelf_argv,
        .stdout_limit = .limited(32 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer {
        allocator.free(readelf_result.stdout);
        allocator.free(readelf_result.stderr);
    }
    if (!termOk(readelf_result.term)) {
        std.debug.print(
            "object-inspection-failure source={s} mode={s} category=readelf stderr={s}\n",
            .{ source, mode.name(), firstLine(readelf_result.stderr) },
        );
        return error.ObjectInspectionFailed;
    }

    const objdump_argv = [_][]const u8{ "objdump", "-dr", object_path };
    const objdump_result = try std.process.run(allocator, io, .{
        .argv = &objdump_argv,
        .stdout_limit = .limited(32 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer {
        allocator.free(objdump_result.stdout);
        allocator.free(objdump_result.stderr);
    }
    if (!termOk(objdump_result.term)) {
        std.debug.print(
            "object-inspection-failure source={s} mode={s} category=objdump stderr={s}\n",
            .{ source, mode.name(), firstLine(objdump_result.stderr) },
        );
        return error.ObjectInspectionFailed;
    }

    try validateObjectHeader(mode, source, readelf_result.stdout);
    try validateObjectSections(mode, source, readelf_result.stdout);
    try validateObjectSymbols(mode, source, readelf_result.stdout);
    try validateObjectRelocations(mode, source, readelf_result.stdout);
    try validateObjectDisassembly(mode, source, objdump_result.stdout);

    return .{
        .has_relocations = std.mem.indexOf(u8, readelf_result.stdout, "R_X86_64_") != null,
        .has_tls = std.mem.indexOf(u8, readelf_result.stdout, " TLS     GLOBAL DEFAULT") != null or
            std.mem.indexOf(u8, readelf_result.stdout, "R_X86_64_TPOFF32") != null,
        .has_undefined_imports = hasUndefinedImports(readelf_result.stdout),
    };
}

pub fn validateObjectHeader(mode: Mode, source: []const u8, readelf: []const u8) !void {
    if (std.mem.indexOf(u8, readelf, "Class:                             ELF64") == null)
        return objectInspectionFailure(mode, source, "object-format", "missing ELF64 header class");
    if (std.mem.indexOf(u8, readelf, "Data:                              2's complement, little endian") == null)
        return objectInspectionFailure(mode, source, "object-format", "missing little-endian ELF data marker");
    if (std.mem.indexOf(u8, readelf, "Type:                              REL (Relocatable file)") == null)
        return objectInspectionFailure(mode, source, "object-format", "object is not ELF REL relocatable");
    if (std.mem.indexOf(u8, readelf, "Machine:                           Advanced Micro Devices X86-64") == null)
        return objectInspectionFailure(mode, source, "object-format", "object machine is not x86-64");
    if (std.mem.indexOf(u8, readelf, "Number of program headers:         0") == null)
        return objectInspectionFailure(mode, source, "section-layout", "relocatable handoff object must not contain program headers");
}

pub fn validateObjectSections(mode: Mode, source: []const u8, readelf: []const u8) !void {
    if (!sectionLineHas(readelf, ".text", "PROGBITS", "AX", "16"))
        return objectInspectionFailure(mode, source, "section-flag-alignment", "missing .text PROGBITS AX align=16 section");
    if (!sectionLineHas(readelf, ".data", "PROGBITS", "WA", "16"))
        return objectInspectionFailure(mode, source, "section-flag-alignment", "missing .data PROGBITS WA align=16 section");
    if (!sectionLineHas(readelf, ".tdata", "PROGBITS", "WAT", "4"))
        return objectInspectionFailure(mode, source, "tls-model", "missing .tdata PROGBITS WAT align=4 section");
    if (!sectionLineHas(readelf, ".rela.text", "RELA", "", "8"))
        return objectInspectionFailure(mode, source, "relocation", "missing .rela.text RELA align=8 section");
    if (!sectionLineHas(readelf, ".symtab", "SYMTAB", "", "8"))
        return objectInspectionFailure(mode, source, "symbol", "missing .symtab SYMTAB align=8 section");
    if (!sectionLineHas(readelf, ".strtab", "STRTAB", "", "1"))
        return objectInspectionFailure(mode, source, "section-layout", "missing .strtab STRTAB align=1 section");
    if (!sectionLineHas(readelf, ".shstrtab", "STRTAB", "", "1"))
        return objectInspectionFailure(mode, source, "section-layout", "missing .shstrtab STRTAB align=1 section");
    if (std.mem.indexOf(u8, readelf, ".group") != null or std.mem.indexOf(u8, readelf, "COMDAT") != null)
        return objectInspectionFailure(mode, source, "comdat", "COMDAT/group sections are outside the current broad AIR handoff contract");
    if (std.mem.indexOf(u8, readelf, ".eh_frame") != null)
        return objectInspectionFailure(mode, source, "unwind-boundary", ".eh_frame is outside the current broad AIR handoff contract");
}

pub fn sectionLineHas(readelf: []const u8, name: []const u8, kind: []const u8, flags: []const u8, alignment: []const u8) bool {
    var lines = std.mem.splitScalar(u8, readelf, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, name) == null) continue;
        if (std.mem.indexOf(u8, line, kind) == null) continue;
        if (flags.len != 0 and std.mem.indexOf(u8, line, flags) == null) continue;
        if (!std.mem.endsWith(u8, std.mem.trim(u8, line, " \t\r"), alignment)) continue;
        return true;
    }
    return false;
}

pub fn validateObjectSymbols(mode: Mode, source: []const u8, readelf: []const u8) !void {
    if (std.mem.indexOf(u8, readelf, "Symbol table '.symtab' contains") == null)
        return objectInspectionFailure(mode, source, "symbol", "missing symbol table dump");
    var has_global_function = false;
    var lines = std.mem.splitScalar(u8, readelf, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, " FUNC    GLOBAL DEFAULT") != null) has_global_function = true;
        if (std.mem.indexOf(u8, line, " UND ") != null and std.mem.indexOf(u8, line, "NOTYPE  LOCAL  DEFAULT  UND") == null) {
            if (std.mem.indexOf(u8, line, "GLOBAL DEFAULT  UND") == null)
                return objectInspectionFailure(mode, source, "bad-symbol-binding-type", "undefined import is not GLOBAL DEFAULT UND");
        }
    }
    if (!has_global_function)
        return objectInspectionFailure(mode, source, "symbol", "missing global function symbol");
    if (std.mem.indexOf(u8, readelf, "R_X86_64_TPOFF32") != null and std.mem.indexOf(u8, readelf, " TLS     GLOBAL DEFAULT") == null)
        return objectInspectionFailure(mode, source, "tls-model", "TLS relocation exists without a TLS GLOBAL symbol");
}

pub fn validateObjectRelocations(mode: Mode, source: []const u8, readelf: []const u8) !void {
    var rest = readelf;
    while (std.mem.indexOf(u8, rest, "R_X86_64_")) |index| {
        const start = index;
        var end = start;
        while (end < rest.len and (std.ascii.isAlphanumeric(rest[end]) or rest[end] == '_')) : (end += 1) {}
        const relocation = rest[start..end];
        if (!isAllowedRelocation(relocation)) {
            std.debug.print(
                "object-inspection-failure source={s} mode={s} category=missing-relocation-support relocation={s}\n",
                .{ source, mode.name(), relocation },
            );
            return error.ObjectInspectionFailed;
        }
        rest = rest[end..];
    }
}

pub fn isAllowedRelocation(relocation: []const u8) bool {
    return std.mem.eql(u8, relocation, "R_X86_64_PC32") or
        std.mem.eql(u8, relocation, "R_X86_64_PLT32") or
        std.mem.eql(u8, relocation, "R_X86_64_TPOFF32");
}

pub fn validateObjectDisassembly(mode: Mode, source: []const u8, objdump: []const u8) !void {
    if (std.mem.indexOf(u8, objdump, "file format elf64-x86-64") == null)
        return objectInspectionFailure(mode, source, "object-format", "objdump did not recognize elf64-x86-64");
    if (std.mem.indexOf(u8, objdump, "Disassembly of section .text:") == null)
        return objectInspectionFailure(mode, source, "section-layout", "objdump missing .text disassembly");
}

pub fn hasUndefinedImports(readelf: []const u8) bool {
    var lines = std.mem.splitScalar(u8, readelf, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, " UND ") != null and std.mem.indexOf(u8, line, "NOTYPE  LOCAL  DEFAULT  UND") == null) return true;
    }
    return false;
}

pub fn objectInspectionFailure(mode: Mode, source: []const u8, category: []const u8, message: []const u8) error{ObjectInspectionFailed} {
    std.debug.print(
        "object-inspection-failure source={s} mode={s} category={s}: {s}\n",
        .{ source, mode.name(), category, message },
    );
    return error.ObjectInspectionFailed;
}

pub const ExecutableHarness = struct {
    abi_mode: []const u8,
    expected: []const u8,
    c_path: ?[]const u8 = null,
    module_main: ?ModuleMainHarness = null,
};

pub const ModuleMainHarness = struct {
    source: []const u8,
    return_type: ModuleMainReturnType = .c_int,
    expected_exit: i64 = 0,
};

pub const ModuleMainReturnType = enum {
    c_int,
    c_long,

    fn cType(self: ModuleMainReturnType) []const u8 {
        return switch (self) {
            .c_int => "int",
            .c_long => "long",
        };
    }
};

pub fn executableHarnessForSource(source: []const u8) ?ExecutableHarness {
    if (std.mem.eql(u8, source, "test/zig/inputs/aggregate_abi.zig")) return .{ .abi_mode = "c-stable-module", .expected = "aggregate ABI pair", .c_path = "test/zig/harnesses/inputs_aggregate_abi.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/aggregates.zig")) return .{ .abi_mode = "c-stable-module", .expected = "array/struct/slice/optional/error-union checks", .c_path = "test/zig/harnesses/inputs_aggregates.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/atomics_inline_asm_debug.zig")) return .{ .abi_mode = "c-stable-module", .expected = "atomic add, inline asm barrier, debug location", .c_path = "test/zig/harnesses/inputs_atomics_inline_asm_debug.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/base64_table_lookup.zig")) return .{ .abi_mode = "c-stable-module", .expected = "base64 table lookup", .c_path = "test/zig/harnesses/inputs_base64_table_lookup.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/control_flow_calls.zig")) return .{ .abi_mode = "c-stable-module", .expected = "call chain and loop sum", .c_path = "test/zig/harnesses/inputs_control_flow_calls.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/error_switch.zig")) return .{ .abi_mode = "c-stable-module", .expected = "error switch payload", .c_path = "test/zig/harnesses/inputs_error_switch.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/float_compare.zig")) return .{ .abi_mode = "c-stable-module", .expected = "float compare and f64 multiply", .c_path = "test/zig/harnesses/inputs_float_compare.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/floats_math.zig")) return .{ .abi_mode = "c-stable-module", .expected = "float add/select", .c_path = "test/zig/harnesses/inputs_floats_math.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/fp_constants.zig")) return .{ .abi_mode = "c-stable-module", .expected = "fp constants", .c_path = "test/zig/harnesses/inputs_fp_constants.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/fp_extended_ops.zig")) return .{ .abi_mode = "c-stable-module", .expected = "fp sub/div/rem", .c_path = "test/zig/harnesses/inputs_fp_extended_ops.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/globals_comptime.zig")) return .{ .abi_mode = "c-stable-module", .expected = "global initializer/update and comptime constant", .c_path = "test/zig/harnesses/inputs_globals_comptime.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/i64_arithmetic.zig")) return .{ .abi_mode = "c-stable-module", .expected = "i64 return", .c_path = "test/zig/harnesses/inputs_i64_arithmetic.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/integers.zig")) return .{ .abi_mode = "c-stable-module", .expected = "integer arithmetic", .c_path = "test/zig/harnesses/inputs_integers.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/optional_pointer.zig")) return .{ .abi_mode = "c-stable-module", .expected = "optional pointer", .c_path = "test/zig/harnesses/inputs_optional_pointer.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/packed_bits.zig")) return .{ .abi_mode = "c-stable-module", .expected = "packed bit values", .c_path = "test/zig/harnesses/inputs_packed_bits.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/pointers_memory.zig")) return .{ .abi_mode = "c-stable-module", .expected = "pointer load/store", .c_path = "test/zig/harnesses/inputs_pointers_memory.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/switch_control.zig")) return .{ .abi_mode = "c-stable-module", .expected = "switch and branch", .c_path = "test/zig/harnesses/inputs_switch_control.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/tls_concurrency.zig")) return .{ .abi_mode = "c-stable-module", .expected = "TLS initializer/read/bump", .c_path = "test/zig/harnesses/inputs_tls_concurrency.c" };
    if (std.mem.eql(u8, source, "test/zig/inputs/tiny_scalar.zig")) return .{ .abi_mode = "c-stable-module", .expected = "tiny scalar add", .c_path = "test/zig/harnesses/inputs_tiny_scalar.c" };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_error_optional.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded optional/error values", .c_path = "test/zig/harnesses/expanded_expanded_error_optional.c" };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_branch_arrays.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded optional branch value", .c_path = "test/zig/harnesses/expanded_expanded_branch_arrays.c" };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_abi_frontier.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded stack/mixed SysV ABI frontier", .c_path = "test/zig/harnesses/expanded_expanded_abi_frontier.c" };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_cfg_memory_aggregates.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded CFG memory/call values", .c_path = "test/zig/harnesses/expanded_expanded_cfg_memory_aggregates.c" };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_float_calls.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded FP pipeline", .c_path = "test/zig/harnesses/expanded_expanded_float_calls.c" };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_numeric_casts.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded int/float conversion family with checked panic-edge death proof", .c_path = "test/zig/harnesses/expanded_expanded_numeric_casts.c" };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_pointer_slices.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded pointer and slice operations", .c_path = "test/zig/harnesses/expanded_expanded_pointer_slices.c" };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_records_memory.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded aggregate/global/TLS operations", .c_path = "test/zig/harnesses/expanded_expanded_records_memory.c" };
    if (std.mem.eql(u8, source, "test/zig/scale/scale_abi_calls.zig")) return .{ .abi_mode = "c-stable-module", .expected = "scale stack/mixed ABI calls", .c_path = "test/zig/harnesses/scale_scale_abi_calls.c" };
    if (std.mem.eql(u8, source, "test/zig/scale/scale_memory_loops.zig")) return .{ .abi_mode = "c-stable-module", .expected = "scale memory loops and branch pointer operations", .c_path = "test/zig/harnesses/scale_scale_memory_loops.c" };
    if (std.mem.eql(u8, source, "test/zig/scale/scale_records_globals.zig")) return .{ .abi_mode = "c-stable-module", .expected = "scale records globals TLS and branch calls", .c_path = "test/zig/harnesses/scale_scale_records_globals.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_nested_loops.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier scalarized loop frontier values", .c_path = "test/zig/harnesses/frontier_frontier_nested_loops.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_nested_records.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier record scalar values", .c_path = "test/zig/harnesses/frontier_frontier_nested_records.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_optionals_errors.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier optional/error control flow", .c_path = "test/zig/harnesses/frontier_frontier_optionals_errors.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_slice_pointer_arith.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier pointer load forms", .c_path = "test/zig/harnesses/frontier_frontier_slice_pointer_arith.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_comptime_constants.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier comptime constants", .c_path = "test/zig/harnesses/frontier_frontier_comptime_constants.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_helper_graph.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier private helper graph", .c_path = "test/zig/harnesses/frontier_frontier_helper_graph.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_mixed_numeric.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier mixed numeric FP", .c_path = "test/zig/harnesses/frontier_frontier_mixed_numeric.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_globals_tls.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier global TLS updates", .c_path = "test/zig/harnesses/frontier_frontier_globals_tls.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_branch_memory.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier branch-local memory", .c_path = "test/zig/harnesses/frontier_frontier_branch_memory.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_safety_edges.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier safety-edge-adjacent values", .c_path = "test/zig/harnesses/frontier_frontier_safety_edges.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_sysv_abi.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier SysV aggregate and multi-spill ABI", .c_path = "test/zig/harnesses/frontier_frontier_sysv_abi.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_sysv_sret_byval.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier SysV sret/byval ABI", .c_path = "test/zig/harnesses/frontier_frontier_sysv_sret_byval.c" };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_sysv_aggregate_classes.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier mixed integer/SSE and nested INTEGER aggregate ABI", .c_path = "test/zig/harnesses/frontier_frontier_sysv_aggregate_classes.c" };
    if (integratedModuleMainHarness(source)) |module_main| return .{
        .abi_mode = "c-stable-integrated-main",
        .expected = "module main expected return",
        .module_main = module_main,
    };
    return null;
}

pub fn integratedModuleMainHarness(source: []const u8) ?ModuleMainHarness {
    if (!std.mem.startsWith(u8, source, "test/zig/integrated/")) return null;
    const basename = std.fs.path.basename(source);
    if (std.mem.eql(u8, basename, "runtime_mix_c_add_may_panic_main.zig")) return null;

    if (std.mem.eql(u8, basename, "runtime_aggregate_pair_main.zig")) return .{ .source = source, .expected_exit = 1 };
    if (std.mem.eql(u8, basename, "runtime_hidden_access_main.zig")) return .{ .source = source, .expected_exit = 7 };
    if (std.mem.eql(u8, basename, "runtime_inherit_want_safety_i64_main.zig")) return .{ .source = source, .return_type = .c_long, .expected_exit = 4 };
    if (std.mem.eql(u8, basename, "runtime_mix_c_add_zig_main.zig")) return .{ .source = source, .expected_exit = 7 };
    if (std.mem.eql(u8, basename, "runtime_tls_bump_main.zig")) return .{ .source = source, .expected_exit = 2 };
    if (std.mem.eql(u8, basename, "runtime_umul_fix_sat_i64_main.zig")) return .{ .source = source, .return_type = .c_long };

    return .{ .source = source };
}

pub fn executableHarnessBody(allocator: std.mem.Allocator, harness: ExecutableHarness) ![]const u8 {
    const module_main = harness.module_main orelse return error.MissingExecutableHarnessBody;
    const stem = std.fs.path.stem(module_main.source);
    const symbol = try std.fmt.allocPrint(allocator, "{s}.main", .{stem});
    defer allocator.free(symbol);
    return std.fmt.allocPrint(
        allocator,
        \\extern {s} z_module_main(void) __asm__("{s}");
        \\int main(void) {{
        \\    return z_module_main() == {d} ? 0 : 1;
        \\}}
        \\
    ,
        .{ module_main.return_type.cType(), symbol, module_main.expected_exit },
    );
}

pub fn nativeLinkObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_exe: []const u8,
    mode: Mode,
    object_path: []const u8,
    exe_path: []const u8,
) !std.process.RunResult {
    return linkObjectWithHarness(
        allocator,
        io,
        zig_exe,
        mode,
        object_path,
        exe_path,
        "int main(void) { return 0; }\n",
    );
}

pub fn linkObjectWithHarness(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_exe: []const u8,
    mode: Mode,
    object_path: []const u8,
    exe_path: []const u8,
    harness_body: []const u8,
) !std.process.RunResult {
    const harness_c = try std.fmt.allocPrint(allocator, "{s}.c", .{exe_path});
    defer allocator.free(harness_c);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = harness_c, .data = harness_body });
    return linkObjectWithHarnessFile(allocator, io, zig_exe, mode, object_path, exe_path, harness_c);
}

pub fn linkObjectWithHarnessFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_exe: []const u8,
    mode: Mode,
    object_path: []const u8,
    exe_path: []const u8,
    harness_c: []const u8,
) !std.process.RunResult {
    const harness_o = try std.fmt.allocPrint(allocator, "{s}.harness.o", .{exe_path});
    defer allocator.free(harness_o);
    const mode_define = try std.fmt.allocPrint(allocator, "-DZLLVM_HARNESS_MODE_{s}", .{mode.name()});
    defer allocator.free(mode_define);
    const cc_argv = [_][]const u8{
        zig_exe,
        "cc",
        "-target",
        "x86_64-linux-gnu",
        mode_define,
        "-c",
        harness_c,
        "-o",
        harness_o,
    };
    const cc_result = try std.process.run(allocator, io, .{
        .argv = &cc_argv,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    });
    if (!termOk(cc_result.term)) return cc_result;
    allocator.free(cc_result.stdout);
    allocator.free(cc_result.stderr);

    const emit_bin_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{exe_path});
    defer allocator.free(emit_bin_arg);
    const argv = [_][]const u8{
        zig_exe,
        "build-exe",
        "-target",
        "x86_64-linux-gnu",
        "-fno-lld",
        harness_o,
        object_path,
        "-lc",
        emit_bin_arg,
    };
    return std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    });
}

pub fn runExecutable(
    allocator: std.mem.Allocator,
    io: std.Io,
    exe_path: []const u8,
) !std.process.RunResult {
    const argv = [_][]const u8{exe_path};
    return std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    });
}

pub fn termOk(term: std.process.Child.Term) bool {
    return switch (term) {
        .exited => |code| code == 0,
        else => false,
    };
}

pub fn termName(term: std.process.Child.Term) []const u8 {
    return switch (term) {
        .exited => "nonzero-exit",
        .signal => "signal",
        .stopped => "stopped",
        .unknown => "unknown",
    };
}

pub fn termExitCode(term: std.process.Child.Term) i32 {
    return switch (term) {
        .exited => |code| @intCast(code),
        .signal, .stopped, .unknown => -1,
    };
}

pub const NativeLinkFailure = union(enum) {
    runtime_boundary: []const u8,
    unsupported_zig_linker_feature: []const u8,
    local_failure: []const u8,
};

pub fn classifyNativeLinkFailure(stderr: []const u8) NativeLinkFailure {
    if (firstUndefinedSymbol(stderr)) |symbol| {
        if (isRuntimeBoundarySymbol(symbol)) return .{ .runtime_boundary = symbol };
        return .{ .local_failure = "unresolved-symbol" };
    }
    const line = firstLine(stderr);
    if (std.mem.indexOf(u8, line, "relocation") != null) return .{ .unsupported_zig_linker_feature = "unsupported-relocation" };
    if (std.mem.indexOf(u8, line, "TLS") != null or std.mem.indexOf(u8, line, "thread-local") != null) return .{ .unsupported_zig_linker_feature = "tls-model" };
    if (std.mem.indexOf(u8, line, "COMDAT") != null or std.mem.indexOf(u8, line, "group") != null) return .{ .unsupported_zig_linker_feature = "comdat-group" };
    return .{ .local_failure = "unclassified-link-failed" };
}

pub fn firstUndefinedSymbol(stderr: []const u8) ?[]const u8 {
    const needle = "undefined symbol: ";
    const start = std.mem.indexOf(u8, stderr, needle) orelse return null;
    var rest = stderr[start + needle.len ..];
    rest = std.mem.trim(u8, rest, " \t'`\"");
    const end = std.mem.indexOfAny(u8, rest, "\r\n'`\" ") orelse rest.len;
    return rest[0..end];
}

pub fn isRuntimeBoundarySymbol(symbol: []const u8) bool {
    return runtime_boundaries.isRuntimeBoundarySymbol(symbol);
}

pub fn firstLine(text: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, text, " \t\r\n");
    const end = std.mem.indexOfAny(u8, trimmed, "\r\n") orelse trimmed.len;
    return trimmed[0..end];
}

pub fn collectSources(allocator: std.mem.Allocator, io: std.Io, corpus: Corpus) ![][]const u8 {
    var sources: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (sources.items) |source| allocator.free(source);
        sources.deinit(allocator);
    }
    if (corpus == .frontier) {
        try collectSourcesFromRoot(allocator, io, &sources, "test/zig/frontier");
        std.mem.sort([]const u8, sources.items, {}, struct {
            fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
                return std.mem.lessThan(u8, lhs, rhs);
            }
        }.lessThan);
        return sources.toOwnedSlice(allocator);
    }
    if (corpus == .frontier_boundaries) {
        try collectSourcesFromRoot(allocator, io, &sources, "test/zig/frontier_boundaries");
        std.mem.sort([]const u8, sources.items, {}, struct {
            fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
                return std.mem.lessThan(u8, lhs, rhs);
            }
        }.lessThan);
        return sources.toOwnedSlice(allocator);
    }
    try collectSourcesFromRoot(allocator, io, &sources, "test/zig/inputs");
    if (corpus == .broad or corpus == .expanded or corpus == .scale or corpus == .frontier) {
        try collectSourcesFromRoot(allocator, io, &sources, "test/zig/integrated");
    }
    if (corpus == .expanded or corpus == .scale or corpus == .frontier) {
        try collectSourcesFromRoot(allocator, io, &sources, "test/zig/expanded");
    }
    if (corpus == .scale or corpus == .frontier) {
        try collectSourcesFromRoot(allocator, io, &sources, "test/zig/scale");
    }
    std.mem.sort([]const u8, sources.items, {}, struct {
        fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
            return std.mem.lessThan(u8, lhs, rhs);
        }
    }.lessThan);
    return sources.toOwnedSlice(allocator);
}

pub fn collectSourcesFromRoot(
    allocator: std.mem.Allocator,
    io: std.Io,
    sources: *std.ArrayList([]const u8),
    root: []const u8,
) !void {
    var dir = try std.Io.Dir.cwd().openDir(io, root, .{ .iterate = true });
    defer dir.close(io);
    var iterator = dir.iterate();
    while (try iterator.next(io)) |entry| {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.name, ".zig")) continue;
        try sources.append(allocator, try std.fs.path.join(allocator, &.{ root, entry.name }));
    }
}

pub fn incrementCount(
    allocator: std.mem.Allocator,
    counts: *std.StringHashMap(usize),
    key: []const u8,
) !void {
    const entry = try counts.getOrPut(key);
    if (entry.found_existing) {
        entry.value_ptr.* += 1;
    } else {
        entry.key_ptr.* = try allocator.dupe(u8, key);
        entry.value_ptr.* = 1;
    }
}

pub fn cloneEnvironment(
    allocator: std.mem.Allocator,
    source: *const std.process.Environ.Map,
) !std.process.Environ.Map {
    var result = std.process.Environ.Map.init(allocator);
    errdefer result.deinit();
    for (source.keys(), source.values()) |key, value| try result.put(key, value);
    return result;
}
