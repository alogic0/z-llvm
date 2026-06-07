const std = @import("std");
const common = @import("tool_common.zig");
const native_cases = @import("native_link_cases.zig");
const source_owned = @import("run_distribution_zig_integrated_object.zig");

const source_wrapper_dispatch_case_id = "source-wrapper-dispatch";
const expected_release_source_owned_rows = 100;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const filters = try parseFilters(allocator, io, init);
    defer filters.deinit(allocator);

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const target = if (filters.release_source_owned) normalizeZigTarget(target_env orelse "x86_64-linux-gnu") else target_env orelse "x86_64-unknown-linux-gnu";
    if (!std.mem.startsWith(u8, target, "x86_64-")) {
        try common.validationError(io, "native-link object inspection supports x86_64 ELF only; target={s}\n", .{target});
    }
    const source_context = if (filters.release_source_owned) try SourceOwnedContext.init(allocator, io, init, target) else null;
    defer if (source_context) |context| context.deinit(allocator);

    const temp = try common.TempDir.init(allocator, io, "native_link_object_inspection");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    var inspected: usize = 0;
    var relocation_rows: usize = 0;
    var tls_rows: usize = 0;
    var undefined_import_rows: usize = 0;

    if (filters.release_source_owned) {
        const context = source_context.?;
        for (source_owned.cases) |case| {
            if (!source_owned.isReleaseSourceOwnedCase(case) or !filters.matchesSourceOwned(case)) continue;
            inspected += 1;
            const result = try inspectSourceOwnedCase(allocator, io, temp, context, case);
            if (result.has_relocations) relocation_rows += 1;
            if (result.has_tls) tls_rows += 1;
            if (result.has_undefined_imports) undefined_import_rows += 1;
            try stdout_writer.interface.print("ok native-link-object-inspection source-owned {s} [{s}] relocations={s} tls={s} undefined_imports={s}\n", .{
                case.id,
                case.mode,
                yesNo(result.has_relocations),
                yesNo(result.has_tls),
                yesNo(result.has_undefined_imports),
            });
            try stdout_writer.interface.flush();
        }
    } else for (native_cases.cases) |case| {
        if (!filters.matchesNative(case)) continue;
        inspected += 1;
        const result = try inspectNativeCase(allocator, io, temp, target, case);
        if (result.has_relocations) relocation_rows += 1;
        if (result.has_tls) tls_rows += 1;
        if (result.has_undefined_imports) undefined_import_rows += 1;
        try stdout_writer.interface.print("ok native-link-object-inspection {s} [{s}] relocations={s} tls={s} undefined_imports={s}\n", .{
            case.id,
            case.mode,
            yesNo(result.has_relocations),
            yesNo(result.has_tls),
            yesNo(result.has_undefined_imports),
        });
        try stdout_writer.interface.flush();
    }

    if (inspected == 0) {
        try common.validationError(io, "no native-link object inspection cases selected\n", .{});
    }
    if (filters.release_source_owned and filters.mode == null and filters.case_id == null and inspected != expected_release_source_owned_rows) {
        try common.validationError(io, "release source-owned object inspection requires inspected={} rows; inspected={}\n", .{ expected_release_source_owned_rows, inspected });
    }

    const mode_label = filters.mode orelse "all";
    const case_label = filters.case_id orelse "all";
    const inventory_label = if (filters.release_source_owned) "release-source-owned" else "selected-native-link";
    try stdout_writer.interface.print(
        "summary native-link-object-inspection inventory={s} target={s} mode={s} case={s} inspected={} elf64_rel={} relocation_rows={} tls_rows={} undefined_import_rows={} comdat_rows=0 eh_frame_rows=0 unsupported_relocation_rows=0 local_fail=0\n",
        .{ inventory_label, target, mode_label, case_label, inspected, inspected, relocation_rows, tls_rows, undefined_import_rows },
    );
    try stdout_writer.interface.flush();
}

const Filters = struct {
    mode: ?[]const u8 = null,
    case_id: ?[]const u8 = null,
    release_source_owned: bool = false,

    fn deinit(filters: Filters, allocator: std.mem.Allocator) void {
        if (filters.mode) |value| allocator.free(value);
        if (filters.case_id) |value| allocator.free(value);
    }

    fn matchesNative(filters: Filters, case: native_cases.Case) bool {
        if (filters.mode) |mode| {
            if (!std.mem.eql(u8, mode, case.mode)) return false;
        }
        if (filters.case_id) |case_id| {
            if (!std.mem.eql(u8, case_id, case.id)) return false;
        }
        return true;
    }

    fn matchesSourceOwned(filters: Filters, case: source_owned.Case) bool {
        if (filters.mode) |mode| {
            if (!std.mem.eql(u8, mode, case.mode)) return false;
        }
        if (filters.case_id) |case_id| {
            if (!std.mem.eql(u8, case_id, case.id)) return false;
        }
        return true;
    }
};

fn parseFilters(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Filters {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var filters: Filters = .{};
    errdefer filters.deinit(allocator);

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [512]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll("usage: zig build distribution-native-link-object-inspection -- [--release-source-owned] [--mode=ReleaseFast|ReleaseSafe|ReleaseSmall|Debug] [--case=<case-id>]\n");
            try stdout_writer.interface.flush();
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "--release-source-owned")) {
            filters.release_source_owned = true;
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            if (filters.mode != null) try common.validationError(io, "duplicate --mode argument\n", .{});
            const value = arg["--mode=".len..];
            if (!isKnownMode(value)) try common.validationError(io, "unknown native-link object inspection mode: {s}\n", .{value});
            filters.mode = try allocator.dupe(u8, value);
        } else if (std.mem.startsWith(u8, arg, "--case=")) {
            if (filters.case_id != null) try common.validationError(io, "duplicate --case argument\n", .{});
            filters.case_id = try allocator.dupe(u8, arg["--case=".len..]);
        } else {
            try common.validationError(io, "unexpected native-link object inspection argument: {s}\n", .{arg});
        }
    }

    return filters;
}

fn isKnownMode(mode: []const u8) bool {
    return std.mem.eql(u8, mode, "ReleaseFast") or
        std.mem.eql(u8, mode, "ReleaseSafe") or
        std.mem.eql(u8, mode, "ReleaseSmall") or
        std.mem.eql(u8, mode, "Debug");
}

const SourceOwnedContext = struct {
    target: []const u8,
    zig_emitter: []const u8,
    zllvm_exe: []const u8,
    env_map: std.process.Environ.Map,

    fn init(allocator: std.mem.Allocator, io: std.Io, init_process: std.process.Init, target: []const u8) !SourceOwnedContext {
        const zig_source_env = try common.getEnvOwnedOrNull(allocator, init_process.minimal.environ, "ZIG_SOURCE_DIR");
        defer if (zig_source_env) |value| allocator.free(value);
        const zig_emitter_env = try common.getEnvOwnedOrNull(allocator, init_process.minimal.environ, "ZIG_EMITTER");
        errdefer if (zig_emitter_env) |value| allocator.free(value);
        const zllvm_env = try common.getEnvOwnedOrNull(allocator, init_process.minimal.environ, "ZLLVM_EXE");
        errdefer if (zllvm_env) |value| allocator.free(value);

        const zig_source_dir = zig_source_env orelse "../ziglang";
        const zig_emitter = zig_emitter_env orelse try std.fs.path.join(allocator, &.{ zig_source_dir, "build/stage4/bin/zig" });
        errdefer if (zig_emitter_env == null) allocator.free(zig_emitter);

        const zllvm_exe = zllvm_env orelse try allocator.dupe(u8, "zig-out/bin/z_llvm");
        errdefer if (zllvm_env == null) allocator.free(zllvm_exe);

        const check_argv = [_][]const u8{ "zig", "run", "tools/check_zig_stage4_emitter.zig" };
        const check_result = try common.runCapture(allocator, io, &check_argv, "tools/check_zig_stage4_emitter.zig");
        common.freeRunResult(allocator, check_result);

        const build_argv = [_][]const u8{ "zig", "build" };
        const build_result = try common.runCapture(allocator, io, &build_argv, "zig build");
        common.freeRunResult(allocator, build_result);

        var env_map = std.process.Environ.Map.init(allocator);
        errdefer env_map.deinit();
        try copyEnvironment(&env_map, init_process.environ_map);
        try env_map.put("ZIG_USE_ZLLVM_IR_WRITER", "1");
        try env_map.put("ZLLVM_IR_WRITER_MODE", "external");
        try env_map.put("ZLLVM_PIPELINE", "preopt");
        try env_map.put("ZLLVM_EXE", zllvm_exe);

        return .{
            .target = target,
            .zig_emitter = zig_emitter,
            .zllvm_exe = zllvm_exe,
            .env_map = env_map,
        };
    }

    fn deinit(context: SourceOwnedContext, allocator: std.mem.Allocator) void {
        var env_map = context.env_map;
        env_map.deinit();
        allocator.free(context.zig_emitter);
        allocator.free(context.zllvm_exe);
    }
};

const Inspection = struct {
    has_relocations: bool,
    has_tls: bool,
    has_undefined_imports: bool,
};

const RowInfo = struct {
    id: []const u8,
    mode: []const u8,
};

fn inspectNativeCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    case: native_cases.Case,
) !Inspection {
    const object = try common.allocTempFile(allocator, temp, case.id, ".o");
    defer allocator.free(object);
    try emitNativeObject(allocator, io, target, case, object);
    return inspectObject(allocator, io, temp, .{ .id = case.id, .mode = case.mode }, object);
}

fn inspectSourceOwnedCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    context: SourceOwnedContext,
    case: source_owned.Case,
) !Inspection {
    const object = try common.allocTempFile(allocator, temp, case.id, ".o");
    defer allocator.free(object);
    const marker = try common.allocTempFile(allocator, temp, case.id, "_zllvm_marker.txt");
    defer allocator.free(marker);
    const ir_path = try common.allocTempFile(allocator, temp, case.id, ".external.ll");
    defer allocator.free(ir_path);
    const descriptor_path = try common.allocTempFile(allocator, temp, case.id, ".semantic_descriptor");
    defer allocator.free(descriptor_path);

    var env_map = try cloneEnvironment(allocator, &context.env_map);
    defer env_map.deinit();
    try env_map.put("ZLLVM_MARKER_PATH", marker);
    try env_map.put("ZLLVM_ZIG_MODE", case.mode);
    try env_map.put("ZLLVM_CASE_ID", source_wrapper_dispatch_case_id);
    try env_map.put("ZLLVM_WRAPPER", case.wrapper);
    try env_map.put("ZLLVM_IR_WRITER_DISPATCH", "source-owned");
    try env_map.put("ZLLVM_SOURCE_FIXTURE", case.covered_fixture);
    try env_map.put("ZLLVM_SEMANTIC_DESCRIPTOR_PATH", descriptor_path);
    try env_map.put("ZLLVM_IR_PATH", ir_path);

    try emitSourceOwnedObject(allocator, io, context, case, object, &env_map);
    try requireSourceOwnedHookArtifacts(allocator, io, .{ .id = case.id, .mode = case.mode }, marker, descriptor_path);
    return inspectObject(allocator, io, temp, .{ .id = case.id, .mode = case.mode }, object);
}

fn emitNativeObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    target: []const u8,
    case: native_cases.Case,
    object: []const u8,
) !void {
    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const emit_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, "--input-limit=67108864", case.fixture };
    try common.runToFile(allocator, io, &emit_argv, "zig build run --emit=obj", object);
}

fn emitSourceOwnedObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    context: SourceOwnedContext,
    case: source_owned.Case,
    object: []const u8,
    env_map: *const std.process.Environ.Map,
) !void {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{object});
    defer allocator.free(emit_arg);

    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.appendSlice(allocator, &.{
        context.zig_emitter,
        "build-obj",
        "-fllvm",
        "-flibllvm",
        "-fno-compiler-rt",
    });
    if (shouldStrip(case.mode)) try argv.append(allocator, "-fstrip");
    try argv.appendSlice(allocator, &.{
        "-O",
        case.mode,
        "-target",
        context.target,
        case.wrapper,
        emit_arg,
    });
    const label = try std.fmt.allocPrint(allocator, "patched Zig source-owned object inspection build-obj {s}", .{case.id});
    defer allocator.free(label);
    const result = try common.runCaptureEnv(allocator, io, argv.items, label, env_map);
    common.freeRunResult(allocator, result);
}

fn requireSourceOwnedHookArtifacts(
    allocator: std.mem.Allocator,
    io: std.Io,
    row: RowInfo,
    marker: []const u8,
    descriptor_path: []const u8,
) !void {
    const marker_contents = std.Io.Dir.cwd().readFileAlloc(io, marker, allocator, .limited(1024 * 1024)) catch |err| {
        try common.validationError(io, "source-owned object inspection missing z_llvm marker for {s}: {t}\n", .{ row.id, err });
    };
    defer allocator.free(marker_contents);
    if (std.mem.indexOf(u8, marker_contents, "case_id=source-wrapper-dispatch") == null) {
        try common.validationError(io, "source-owned object inspection row {s} did not use source-wrapper dispatch marker\n", .{row.id});
    }
    if (std.mem.indexOf(u8, marker_contents, "pipeline=preopt") == null) {
        try common.validationError(io, "source-owned object inspection row {s} did not use preopt pipeline marker\n", .{row.id});
    }
    if (std.mem.indexOf(u8, marker_contents, "ir_writer=external") == null) {
        try common.validationError(io, "source-owned object inspection row {s} did not use external IR writer marker\n", .{row.id});
    }

    const emitter = readDescriptorInputValue(allocator, io, descriptor_path, row, "facts_emitter") catch |err| switch (err) {
        error.MissingDescriptorInputValue => try readDescriptorInputValue(allocator, io, descriptor_path, row, "descriptor_emitter"),
        else => return err,
    };
    defer allocator.free(emitter);
    if (!std.mem.eql(u8, emitter, "patched-zig-hook")) {
        try common.validationError(io, "source-owned object inspection row {s} descriptor emitter is {s}, expected patched-zig-hook\n", .{ row.id, emitter });
    }
}

fn inspectObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    row: RowInfo,
    object: []const u8,
) !Inspection {
    const readelf_summary = try common.allocTempFile(allocator, temp, row.id, ".readelf.txt");
    defer allocator.free(readelf_summary);
    const objdump_summary = try common.allocTempFile(allocator, temp, row.id, ".objdump.txt");
    defer allocator.free(objdump_summary);

    const readelf_argv = [_][]const u8{ "readelf", "-W", "-h", "-S", "-s", "-r", object };
    try common.runToFile(allocator, io, &readelf_argv, "readelf -W -h -S -s -r", readelf_summary);
    const objdump_argv = [_][]const u8{ "objdump", "-dr", object };
    try common.runToFile(allocator, io, &objdump_argv, "objdump -dr", objdump_summary);

    const readelf = try std.Io.Dir.cwd().readFileAlloc(io, readelf_summary, allocator, .limited(128 * 1024 * 1024));
    defer allocator.free(readelf);
    const objdump = try std.Io.Dir.cwd().readFileAlloc(io, objdump_summary, allocator, .limited(128 * 1024 * 1024));
    defer allocator.free(objdump);

    try validateElfHeader(io, row, readelf);
    try validateSections(io, row, readelf);
    try validateSymbols(io, row, readelf);
    try validateRelocations(io, row, readelf);
    try validateObjdump(io, row, objdump);

    return .{
        .has_relocations = std.mem.indexOf(u8, readelf, "R_X86_64_") != null,
        .has_tls = std.mem.indexOf(u8, readelf, " TLS     GLOBAL DEFAULT") != null or std.mem.indexOf(u8, readelf, "R_X86_64_TPOFF32") != null,
        .has_undefined_imports = hasUndefinedImports(readelf),
    };
}

fn validateElfHeader(io: std.Io, case: RowInfo, readelf: []const u8) !void {
    if (std.mem.indexOf(u8, readelf, "Class:                             ELF64") == null) {
        try failObject(io, case, "object-format", "missing ELF64 header class");
    }
    if (std.mem.indexOf(u8, readelf, "Data:                              2's complement, little endian") == null) {
        try failObject(io, case, "object-format", "missing little-endian ELF data marker");
    }
    if (std.mem.indexOf(u8, readelf, "Type:                              REL (Relocatable file)") == null) {
        try failObject(io, case, "object-format", "object is not ELF REL relocatable");
    }
    if (std.mem.indexOf(u8, readelf, "Machine:                           Advanced Micro Devices X86-64") == null) {
        try failObject(io, case, "object-format", "object machine is not x86-64");
    }
    if (std.mem.indexOf(u8, readelf, "Number of program headers:         0") == null) {
        try failObject(io, case, "section-layout", "relocatable handoff object must not contain program headers");
    }
}

fn validateSections(io: std.Io, case: RowInfo, readelf: []const u8) !void {
    if (!sectionLineHas(readelf, ".text", "PROGBITS", "AX", "16")) {
        try failObject(io, case, "section-flag-alignment", "missing .text PROGBITS AX align=16 section");
    }
    if (!sectionLineHas(readelf, ".data", "PROGBITS", "WA", "16")) {
        try failObject(io, case, "section-flag-alignment", "missing .data PROGBITS WA align=16 section");
    }
    if (!sectionLineHas(readelf, ".tdata", "PROGBITS", "WAT", "4")) {
        try failObject(io, case, "tls-model", "missing .tdata PROGBITS WAT align=4 section");
    }
    if (!sectionLineHas(readelf, ".rela.text", "RELA", "", "8")) {
        try failObject(io, case, "relocation", "missing .rela.text RELA align=8 section");
    }
    if (!sectionLineHas(readelf, ".symtab", "SYMTAB", "", "8")) {
        try failObject(io, case, "symbol", "missing .symtab SYMTAB align=8 section");
    }
    if (!sectionLineHas(readelf, ".strtab", "STRTAB", "", "1")) {
        try failObject(io, case, "section-layout", "missing .strtab STRTAB align=1 section");
    }
    if (!sectionLineHas(readelf, ".shstrtab", "STRTAB", "", "1")) {
        try failObject(io, case, "section-layout", "missing .shstrtab STRTAB align=1 section");
    }
    if (std.mem.indexOf(u8, readelf, ".group") != null or std.mem.indexOf(u8, readelf, "COMDAT") != null) {
        try failObject(io, case, "comdat", "COMDAT/group sections are not part of the current z_llvm handoff contract");
    }
    if (std.mem.indexOf(u8, readelf, ".eh_frame") != null) {
        try failObject(io, case, "unwind-boundary", ".eh_frame is not part of the current z_llvm native-link handoff contract");
    }
}

fn sectionLineHas(readelf: []const u8, name: []const u8, kind: []const u8, flags: []const u8, alignment: []const u8) bool {
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

fn validateSymbols(io: std.Io, case: RowInfo, readelf: []const u8) !void {
    if (std.mem.indexOf(u8, readelf, "Symbol table '.symtab' contains") == null) {
        try failObject(io, case, "symbol", "missing symbol table dump");
    }
    var has_global_function = false;
    var lines = std.mem.splitScalar(u8, readelf, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, " FUNC    GLOBAL DEFAULT") != null) has_global_function = true;
        if (std.mem.indexOf(u8, line, " UND ") != null and std.mem.indexOf(u8, line, "NOTYPE  LOCAL  DEFAULT  UND") == null) {
            if (std.mem.indexOf(u8, line, "GLOBAL DEFAULT  UND") == null) {
                try failObject(io, case, "bad-symbol-binding-type", "undefined import is not GLOBAL DEFAULT UND");
            }
        }
    }
    if (!has_global_function) {
        try failObject(io, case, "symbol", "missing global function symbol");
    }
    if (std.mem.indexOf(u8, readelf, "R_X86_64_TPOFF32") != null and std.mem.indexOf(u8, readelf, " TLS     GLOBAL DEFAULT") == null) {
        try failObject(io, case, "tls-model", "TLS relocation exists without a TLS GLOBAL symbol");
    }
}

fn validateRelocations(io: std.Io, case: RowInfo, readelf: []const u8) !void {
    var rest = readelf;
    while (std.mem.indexOf(u8, rest, "R_X86_64_")) |index| {
        const start = index;
        var end = start;
        while (end < rest.len and (std.ascii.isAlphanumeric(rest[end]) or rest[end] == '_')) : (end += 1) {}
        const relocation = rest[start..end];
        if (!isAllowedRelocation(relocation)) {
            try common.validationError(
                io,
                "native-link object inspection failed case_id={s} mode={s} category=missing-relocation-support relocation={s}\n",
                .{ case.id, case.mode, relocation },
            );
        }
        rest = rest[end..];
    }
}

fn isAllowedRelocation(relocation: []const u8) bool {
    return std.mem.eql(u8, relocation, "R_X86_64_PC32") or
        std.mem.eql(u8, relocation, "R_X86_64_PLT32") or
        std.mem.eql(u8, relocation, "R_X86_64_TPOFF32");
}

fn validateObjdump(io: std.Io, case: RowInfo, objdump: []const u8) !void {
    if (std.mem.indexOf(u8, objdump, "file format elf64-x86-64") == null) {
        try failObject(io, case, "object-format", "objdump did not recognize elf64-x86-64");
    }
    if (std.mem.indexOf(u8, objdump, "Disassembly of section .text:") == null) {
        try failObject(io, case, "section-layout", "objdump missing .text disassembly");
    }
}

fn hasUndefinedImports(readelf: []const u8) bool {
    var lines = std.mem.splitScalar(u8, readelf, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, " UND ") != null and std.mem.indexOf(u8, line, "NOTYPE  LOCAL  DEFAULT  UND") == null) return true;
    }
    return false;
}

fn failObject(io: std.Io, case: RowInfo, category: []const u8, message: []const u8) !noreturn {
    try common.validationError(io, "native-link object inspection failed case_id={s} mode={s} category={s}: {s}\n", .{ case.id, case.mode, category, message });
}

fn yesNo(value: bool) []const u8 {
    return if (value) "yes" else "no";
}

fn cloneEnvironment(allocator: std.mem.Allocator, src: *const std.process.Environ.Map) !std.process.Environ.Map {
    var dst = std.process.Environ.Map.init(allocator);
    errdefer dst.deinit();
    try copyEnvironment(&dst, src);
    return dst;
}

fn copyEnvironment(dst: *std.process.Environ.Map, src: *const std.process.Environ.Map) !void {
    const keys = src.keys();
    const values = src.values();
    for (keys, values) |key, value| {
        try dst.put(key, value);
    }
}

fn readDescriptorInputValue(
    allocator: std.mem.Allocator,
    io: std.Io,
    descriptor_path: []const u8,
    row: RowInfo,
    key: []const u8,
) ![]const u8 {
    const contents = std.Io.Dir.cwd().readFileAlloc(io, descriptor_path, allocator, .limited(1024 * 1024)) catch |err| {
        try common.validationError(io, "missing Zig-emitted semantic descriptor for {s}: {t}\n", .{ row.id, err });
    };
    defer allocator.free(contents);
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const separator = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        if (std.mem.eql(u8, line[0..separator], key)) {
            return try allocator.dupe(u8, line[separator + 1 ..]);
        }
    }
    return error.MissingDescriptorInputValue;
}

fn shouldStrip(mode: []const u8) bool {
    return std.mem.eql(u8, mode, "ReleaseFast") or std.mem.eql(u8, mode, "ReleaseSmall");
}

fn normalizeZigTarget(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) return "x86_64-linux-gnu";
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-musl")) return "x86_64-linux-musl";
    return target;
}
