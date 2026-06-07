const std = @import("std");
const common = @import("tool_common.zig");
const native_cases = @import("native_link_cases.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const filters = try parseFilters(allocator, io, init);
    defer filters.deinit(allocator);

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";
    if (!std.mem.startsWith(u8, target, "x86_64-")) {
        try common.validationError(io, "native-link object inspection supports x86_64 ELF only; target={s}\n", .{target});
    }

    const temp = try common.TempDir.init(allocator, io, "native_link_object_inspection");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    var inspected: usize = 0;
    var relocation_rows: usize = 0;
    var tls_rows: usize = 0;
    var undefined_import_rows: usize = 0;

    for (native_cases.cases) |case| {
        if (!filters.matches(case)) continue;
        inspected += 1;
        const result = try inspectCase(allocator, io, temp, target, case);
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

    const mode_label = filters.mode orelse "all";
    const case_label = filters.case_id orelse "all";
    try stdout_writer.interface.print(
        "summary native-link-object-inspection target={s} mode={s} case={s} inspected={} elf64_rel={} relocation_rows={} tls_rows={} undefined_import_rows={} comdat_rows=0 eh_frame_rows=0 unsupported_relocation_rows=0 local_fail=0\n",
        .{ target, mode_label, case_label, inspected, inspected, relocation_rows, tls_rows, undefined_import_rows },
    );
    try stdout_writer.interface.flush();
}

const Filters = struct {
    mode: ?[]const u8 = null,
    case_id: ?[]const u8 = null,

    fn deinit(filters: Filters, allocator: std.mem.Allocator) void {
        if (filters.mode) |value| allocator.free(value);
        if (filters.case_id) |value| allocator.free(value);
    }

    fn matches(filters: Filters, case: native_cases.Case) bool {
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
            try stdout_writer.interface.writeAll("usage: zig build distribution-native-link-object-inspection -- [--mode=ReleaseFast|ReleaseSafe|ReleaseSmall|Debug] [--case=<case-id>]\n");
            try stdout_writer.interface.flush();
            std.process.exit(0);
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

const Inspection = struct {
    has_relocations: bool,
    has_tls: bool,
    has_undefined_imports: bool,
};

fn inspectCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    case: native_cases.Case,
) !Inspection {
    const object = try common.allocTempFile(allocator, temp, case.id, ".o");
    defer allocator.free(object);
    const readelf_summary = try common.allocTempFile(allocator, temp, case.id, ".readelf.txt");
    defer allocator.free(readelf_summary);
    const objdump_summary = try common.allocTempFile(allocator, temp, case.id, ".objdump.txt");
    defer allocator.free(objdump_summary);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const emit_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, "--input-limit=67108864", case.fixture };
    try common.runToFile(allocator, io, &emit_argv, "zig build run --emit=obj", object);

    const readelf_argv = [_][]const u8{ "readelf", "-W", "-h", "-S", "-s", "-r", object };
    try common.runToFile(allocator, io, &readelf_argv, "readelf -W -h -S -s -r", readelf_summary);
    const objdump_argv = [_][]const u8{ "objdump", "-dr", object };
    try common.runToFile(allocator, io, &objdump_argv, "objdump -dr", objdump_summary);

    const readelf = try std.Io.Dir.cwd().readFileAlloc(io, readelf_summary, allocator, .limited(128 * 1024 * 1024));
    defer allocator.free(readelf);
    const objdump = try std.Io.Dir.cwd().readFileAlloc(io, objdump_summary, allocator, .limited(128 * 1024 * 1024));
    defer allocator.free(objdump);

    try validateElfHeader(io, case, readelf);
    try validateSections(io, case, readelf);
    try validateSymbols(io, case, readelf);
    try validateRelocations(io, case, readelf);
    try validateObjdump(io, case, objdump);

    return .{
        .has_relocations = std.mem.indexOf(u8, readelf, "R_X86_64_") != null,
        .has_tls = std.mem.indexOf(u8, readelf, " TLS     GLOBAL DEFAULT") != null or std.mem.indexOf(u8, readelf, "R_X86_64_TPOFF32") != null,
        .has_undefined_imports = hasUndefinedImports(readelf),
    };
}

fn validateElfHeader(io: std.Io, case: native_cases.Case, readelf: []const u8) !void {
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

fn validateSections(io: std.Io, case: native_cases.Case, readelf: []const u8) !void {
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

fn validateSymbols(io: std.Io, case: native_cases.Case, readelf: []const u8) !void {
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

fn validateRelocations(io: std.Io, case: native_cases.Case, readelf: []const u8) !void {
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

fn validateObjdump(io: std.Io, case: native_cases.Case, objdump: []const u8) !void {
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

fn failObject(io: std.Io, case: native_cases.Case, category: []const u8, message: []const u8) !noreturn {
    try common.validationError(io, "native-link object inspection failed case_id={s} mode={s} category={s}: {s}\n", .{ case.id, case.mode, category, message });
}

fn yesNo(value: bool) []const u8 {
    return if (value) "yes" else "no";
}
