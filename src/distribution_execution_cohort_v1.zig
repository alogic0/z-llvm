const std = @import("std");
const air_export = @import("zig_air_export.zig");

const Sha256 = std.crypto.hash.sha2.Sha256;

pub const schema = "distribution-execution-cohort-v3";
pub const repository_root = "/home/oleg/prog/z_llvm";
pub const external_repository_root = "/home/oleg/prog/ziglang";
pub const external_revision = "1c08b09d1c847f4f02c8216e3b62df323861a437";
pub const definition_path = "lib/std/coff.zig";
pub const import_path = "lib/std/std.zig";
pub const use_path = "src/libs/mingw/implib.zig";
pub const requirements_definition_path = "src/link/MachO/CodeSignature.zig";
pub const requirements_import_path = "src/link/MachO.zig";
pub const ascii_definition_path = "lib/std/ascii.zig";
pub const expected_result: usize = 8;
pub const expected_witness: usize = 31;
pub const expected_stdout = "execution-oracle-v2 result=8 witness=31\n";
pub const process_output_max: usize = 16 * 1024 * 1024;
pub const selector_version = "0.17.0-dev.11+1c08b09d1";
pub const selector_length: u64 = 149_918_648;
pub const selector_sha256 = [_]u8{
    0xd5, 0x05, 0xfc, 0x64, 0xb5, 0xb4, 0x2b, 0xa1,
    0xbf, 0x38, 0xa4, 0x6d, 0x44, 0xa6, 0x88, 0x99,
    0xe4, 0x78, 0x30, 0x6d, 0x18, 0xfd, 0xc8, 0x60,
    0x51, 0x26, 0xa9, 0xc2, 0xc3, 0x04, 0x98, 0x2e,
};

pub const Program = enum {
    signature_size,
    signature_slot_type,
    requirements_size,
    requirements_slot_type,
    ascii_is_ascii,

    pub fn functionName(program: Program) []const u8 {
        return switch (program) {
            .signature_size => "link.MachO.CodeSignature.Signature.size",
            .signature_slot_type => "link.MachO.CodeSignature.Signature.slotType",
            .requirements_size => "link.MachO.CodeSignature.Requirements.size",
            .requirements_slot_type => "link.MachO.CodeSignature.Requirements.slotType",
            .ascii_is_ascii => "ascii.isAscii",
        };
    }

    pub fn denominatorSource(program: Program) []const u8 {
        _ = program;
        return "../ziglang/src/main.zig";
    }

    pub fn linkedHarness(program: Program) []const u8 {
        return switch (program) {
            .signature_size => symbol_linked_harness_source,
            .signature_slot_type => weak_external_linked_harness_source,
            .requirements_size => requirements_linked_harness_source,
            .requirements_slot_type => requirements_slot_type_linked_harness_source,
            .ascii_is_ascii => ascii_linked_harness_source,
        };
    }

    pub fn referenceHarness(program: Program) []const u8 {
        return switch (program) {
            .signature_size => reference_harness_source,
            .signature_slot_type => signature_slot_reference_harness_source,
            .requirements_size => requirements_reference_harness_source,
            .requirements_slot_type => requirements_slot_type_reference_harness_source,
            .ascii_is_ascii => ascii_reference_harness_source,
        };
    }

    pub fn expectedResult(program: Program) usize {
        return switch (program) {
            .signature_size => 8,
            .signature_slot_type => 65536,
            .requirements_size => 12,
            .requirements_slot_type => 2,
            .ascii_is_ascii => 128,
        };
    }

    pub fn expectedWitness(program: Program) usize {
        if (program == .ascii_is_ascii) return 8256;
        return program.expectedResult() *% 3 +% 7;
    }

    pub fn observations(program: Program) usize {
        return if (program == .ascii_is_ascii) 256 else 1;
    }

    pub fn expectedStdout(program: Program) []const u8 {
        return switch (program) {
            .signature_size => expected_stdout,
            .signature_slot_type => signature_slot_expected_stdout,
            .requirements_size => requirements_expected_stdout,
            .requirements_slot_type => requirements_slot_type_expected_stdout,
            .ascii_is_ascii => ascii_expected_stdout,
        };
    }

    fn descriptorType(program: Program) []const u8 {
        return switch (program) {
            .signature_size, .signature_slot_type => "fn (link.MachO.CodeSignature.Signature) u32",
            .requirements_size, .requirements_slot_type => "fn (link.MachO.CodeSignature.Requirements) u32",
            .ascii_is_ascii => "fn (u8) bool",
        };
    }

    fn descriptorReturnType(program: Program) []const u8 {
        return switch (program) {
            .signature_size, .signature_slot_type => "u32",
            .requirements_size, .requirements_slot_type => "u32",
            .ascii_is_ascii => "bool",
        };
    }
};

pub const programs = [_]Program{
    .signature_size,
    .signature_slot_type,
    .requirements_size,
    .requirements_slot_type,
    .ascii_is_ascii,
};

// Only harnesses are generated here. Every called definition is authenticated
// against the unchanged source and the selected typed AIR descriptor.
fn makeReferenceHarness(comptime result: usize) []const u8 {
    return "const std = @import(\"std\");\npub fn main(init: std.process.Init) !void {\n    const result: u32 = " ++
        std.fmt.comptimePrint("{d};\n", .{result}) ++ harness_body;
}

fn makeLinkedHarness(comptime symbol: []const u8) []const u8 {
    return "const std = @import(\"std\");\nconst size_of = @extern(*const fn () callconv(.{ .x86_64_sysv = .{} }) u32, .{ .name = \"" ++ symbol ++
        "\" });\npub fn main(init: std.process.Init) !void {\n    const result = size_of();\n" ++ harness_body;
}

const harness_body =
    \\    const witness = result *% 3 +% 7;
    \\    var buffer: [128]u8 = undefined;
    \\    var writer = std.Io.File.stdout().writer(init.io, &buffer);
    \\    try writer.interface.print("execution-oracle-v2 result={} witness={}\n", .{ result, witness });
    \\    try writer.interface.flush();
    \\}
    \\
;

pub const reference_harness_source = makeReferenceHarness(8);
pub const signature_slot_reference_harness_source = makeReferenceHarness(65536);
pub const requirements_reference_harness_source = makeReferenceHarness(12);
pub const requirements_slot_type_reference_harness_source = makeReferenceHarness(2);
pub const symbol_linked_harness_source = makeLinkedHarness("link.MachO.CodeSignature.Signature.size");
pub const weak_external_linked_harness_source = makeLinkedHarness("link.MachO.CodeSignature.Signature.slotType");
pub const requirements_linked_harness_source = makeLinkedHarness("link.MachO.CodeSignature.Requirements.size");
pub const requirements_slot_type_linked_harness_source = makeLinkedHarness("link.MachO.CodeSignature.Requirements.slotType");
pub const signature_slot_expected_stdout = "execution-oracle-v2 result=65536 witness=196615\n";
pub const requirements_expected_stdout = "execution-oracle-v2 result=12 witness=43\n";
pub const requirements_slot_type_expected_stdout = "execution-oracle-v2 result=2 witness=13\n";

const ascii_reference_harness_source = makeAsciiHarness(false);
const ascii_linked_harness_source = makeAsciiHarness(true);
const ascii_expected_stdout = "execution-oracle-v3 cases=256 result=128 witness=8256 bits=" ++
    @as([128]u8, @splat('1')) ++ @as([128]u8, @splat('0')) ++ "\n";

fn makeAsciiHarness(comptime linked: bool) []const u8 {
    return "const std = @import(\"std\");\n" ++
        (if (linked) "const is_ascii = @extern(*const fn (u8) callconv(.{ .x86_64_sysv = .{} }) bool, .{ .name = \"ascii.isAscii\" });\n" else "") ++
        \\pub fn main(init: std.process.Init) !void {
        \\    var result: u32 = 0;
        \\    var witness: usize = 0;
        \\    var bits: [256]u8 = undefined;
        \\    for (0..256) |input| {
        \\        const byte: u8 = @intCast(input);
        \\
    ++ (if (linked) "        const actual = is_ascii(byte);\n" else "        const actual = (input & 128) == 0;\n        _ = byte;\n") ++
        \\        if (actual != ((input & 128) == 0)) return error.AsciiOracleMismatch;
        \\        bits[input] = if (actual) '1' else '0';
        \\        result += @intFromBool(actual);
        \\        witness += if (actual) input + 1 else 0;
        \\    }
        \\    var buffer: [1024]u8 = undefined;
        \\    var writer = std.Io.File.stdout().writer(init.io, &buffer);
        \\    try writer.interface.print("execution-oracle-v3 cases=256 result={} witness={} bits={s}\n", .{ result, witness, &bits });
        \\    try writer.interface.flush();
        \\}
        \\
    ;
}

pub const Termination = enum {
    exited,
    signaled,
    stopped,
    unknown,
};

pub const ExecutionRecord = struct {
    termination: Termination,
    status: u8,
    stdout_sha256: [Sha256.digest_length]u8,
    stderr_sha256: [Sha256.digest_length]u8,
    stdout_length: usize,
    stderr_length: usize,
    semantic_result: usize,
    call_occurrence: bool,
};

pub const PairCounters = struct {
    real_executed: usize = 0,
    real_programs_ok: usize = 0,

    pub fn noteBothExecuted(counters: *PairCounters, reference: ExecutionRecord, linked: ExecutionRecord) !void {
        if (reference.termination != .exited or linked.termination != .exited or
            reference.status != 0 or linked.status != 0)
        {
            return error.ProcessInconsistent;
        }
        counters.real_executed += 1;
    }

    pub fn noteOracleAccepted(counters: *PairCounters, reference: ExecutionRecord, linked: ExecutionRecord) !void {
        if (counters.real_executed != 1) return error.ProcessInconsistent;
        if (!reference.call_occurrence or !linked.call_occurrence) return error.CallOccurrenceMissing;
        if (!std.meta.eql(reference, linked)) return error.OracleMismatch;
        counters.real_programs_ok += 1;
    }
};

pub const OwnedProcessResult = struct {
    term: std.process.Child.Term,
    stdout: []u8,
    stderr: []u8,

    pub fn deinit(result: *OwnedProcessResult, allocator: std.mem.Allocator) void {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
        result.* = undefined;
    }
};

pub const ArtifactIdentity = struct {
    length: u64,
    sha256: [Sha256.digest_length]u8,
    executable: bool,
};

pub const SelectorIdentity = struct {
    version: [128]u8,
    version_length: u8,
    length: u64,
    sha256: [Sha256.digest_length]u8,

    pub fn versionSlice(identity: *const SelectorIdentity) []const u8 {
        return identity.version[0..identity.version_length];
    }
};

pub const BuildPaths = struct {
    reference_source: []const u8,
    linked_source: []const u8,
    object: []const u8,
    reference_executable: []const u8,
    linked_executable: []const u8,
};

pub const EnvironmentPaths = struct {
    home: []const u8,
    temporary: []const u8,
    local_cache: []const u8,
    global_cache: []const u8,
};

pub const SourceIdentity = struct {
    definition_sha256: [Sha256.digest_length]u8,
    import_sha256: [Sha256.digest_length]u8,
    use_sha256: [Sha256.digest_length]u8,
    requirements_definition_sha256: [Sha256.digest_length]u8,
    requirements_import_sha256: [Sha256.digest_length]u8,
    ascii_definition_sha256: [Sha256.digest_length]u8,
};

pub const OwnedSourceFiles = struct {
    definition: []u8,
    import_source: []u8,
    use_source: []u8,
    requirements_definition: []u8,
    requirements_import_source: []u8,
    ascii_definition: []u8,

    pub fn deinit(files: *OwnedSourceFiles, allocator: std.mem.Allocator) void {
        allocator.free(files.ascii_definition);
        allocator.free(files.requirements_import_source);
        allocator.free(files.requirements_definition);
        allocator.free(files.use_source);
        allocator.free(files.import_source);
        allocator.free(files.definition);
        files.* = undefined;
    }

    pub fn identity(files: *const OwnedSourceFiles) SourceIdentity {
        return .{
            .definition_sha256 = sha256(files.definition),
            .import_sha256 = sha256(files.import_source),
            .use_sha256 = sha256(files.use_source),
            .requirements_definition_sha256 = sha256(files.requirements_definition),
            .requirements_import_sha256 = sha256(files.requirements_import_source),
            .ascii_definition_sha256 = sha256(files.ascii_definition),
        };
    }

    pub fn validate(files: *const OwnedSourceFiles) !void {
        try validateRequirementsSources(files.requirements_definition, files.requirements_import_source);
        try validateSignatureSource(files.requirements_definition);
        try validateAsciiSource(files.ascii_definition, files.import_source);
    }
};

fn validateAsciiSource(definition: []const u8, import_source: []const u8) !void {
    const body =
        \\pub fn isAscii(c: u8) bool {
        \\    return c < 128;
        \\}
    ;
    if (std.mem.count(u8, definition, body) != 1 or
        std.mem.count(u8, definition, "pub fn isAscii(") != 1 or
        std.mem.count(u8, import_source, "pub const ascii = @import(\"ascii.zig\");") != 1)
        return error.CohortSourceBindingMismatch;
}

fn validateSignatureSource(definition: []const u8) !void {
    const size_block =
        \\    fn size(self: Signature) u32 {
        \\        _ = self;
        \\        return 2 * @sizeOf(u32);
        \\    }
    ;
    const slot_block =
        \\    fn slotType(self: Signature) u32 {
        \\        _ = self;
        \\        return macho.CSSLOT_SIGNATURESLOT;
        \\    }
    ;
    if (std.mem.count(u8, definition, "const Signature = struct {") != 1 or
        std.mem.count(u8, definition, size_block) != 1 or
        std.mem.count(u8, definition, slot_block) != 1)
        return error.CohortSourceBindingMismatch;
}

fn validateRequirementsSources(definition: []const u8, import_source: []const u8) !void {
    const definition_block =
        \\const Requirements = struct {
        \\    fn deinit(self: *Requirements, allocator: Allocator) void {
    ;
    const size_block =
        \\    fn size(self: Requirements) u32 {
        \\        _ = self;
        \\        return 3 * @sizeOf(u32);
        \\    }
    ;
    const slot_type_block =
        \\    fn slotType(self: Requirements) u32 {
        \\        _ = self;
        \\        return macho.CSSLOT_REQUIREMENTS;
        \\    }
    ;
    const write_block =
        \\    fn write(self: Requirements, writer: anytype) !void {
        \\        try writer.writeInt(u32, macho.CSMAGIC_REQUIREMENTS, .big);
        \\        try writer.writeInt(u32, self.size(), .big);
        \\        try writer.writeInt(u32, 0, .big);
        \\    }
    ;
    const import_line = "const CodeSignature = @import(\"MachO/CodeSignature.zig\");";
    if (std.mem.count(u8, definition, definition_block) != 1 or
        std.mem.count(u8, definition, slot_type_block) != 1 or
        std.mem.count(u8, definition, size_block) != 1 or
        std.mem.count(u8, definition, write_block) != 1 or
        std.mem.count(u8, import_source, import_line) != 1)
    {
        return error.CohortSourceBindingMismatch;
    }
}

pub fn sha256(bytes: []const u8) [Sha256.digest_length]u8 {
    var digest: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(bytes, &digest, .{});
    return digest;
}

pub fn validateHarnesses(program: Program) !void {
    const reference = program.referenceHarness();
    if (program == .ascii_is_ascii) {
        const linked = program.linkedHarness();
        if (std.mem.count(u8, reference, "const actual = (input & 128) == 0;") != 1 or
            std.mem.count(u8, reference, "ascii.isAscii") != 0 or
            std.mem.count(u8, linked, "ascii.isAscii") != 1 or
            std.mem.count(u8, linked, "const actual = is_ascii(byte);") != 1 or
            std.mem.count(u8, linked, "fn (u8) callconv(.{ .x86_64_sysv = .{} }) bool") != 1)
            return error.HarnessBindingMismatch;
        for ([_][]const u8{ reference, linked }) |harness| {
            if (std.mem.count(u8, harness, "for (0..256)") != 1 or
                std.mem.count(u8, harness, "return error.AsciiOracleMismatch;") != 1 or
                std.mem.count(u8, harness, "bits[input] = if (actual) '1' else '0';") != 1)
                return error.HarnessBindingMismatch;
        }
        return;
    }
    const reference_result = switch (program) {
        .signature_size => "const result: u32 = 8;",
        .signature_slot_type => "const result: u32 = 65536;",
        .requirements_size => "const result: u32 = 12;",
        .requirements_slot_type => "const result: u32 = 2;",
        .ascii_is_ascii => unreachable,
    };
    if (std.mem.count(u8, reference, reference_result) != 1 or
        std.mem.count(u8, reference, "witness={}\\n") != 1 or
        std.mem.count(u8, reference, "witness={}\\\\n") != 0)
    {
        return error.HarnessBindingMismatch;
    }
    const linked = program.linkedHarness();
    if (std.mem.count(u8, linked, program.functionName()) != 1 or
        std.mem.count(u8, linked, "size_of()") != 1 or
        std.mem.count(u8, linked, "callconv(.{ .x86_64_sysv = .{} })") != 1 or
        std.mem.count(u8, linked, "const witness = result *% 3 +% 7;") != 1 or
        std.mem.count(u8, linked, "witness={}\\n") != 1 or
        std.mem.count(u8, linked, "witness={}\\\\n") != 0)
    {
        return error.HarnessBindingMismatch;
    }
}

pub fn writeHarnesses(io: std.Io, program: Program, paths: BuildPaths) !void {
    try validateHarnesses(program);
    const cwd = std.Io.Dir.cwd();
    try cwd.writeFile(io, .{ .sub_path = paths.reference_source, .data = program.referenceHarness() });
    try cwd.writeFile(io, .{ .sub_path = paths.linked_source, .data = program.linkedHarness() });
}

pub fn closedEnvironment(allocator: std.mem.Allocator, paths: EnvironmentPaths) !std.process.Environ.Map {
    var environment = std.process.Environ.Map.init(allocator);
    errdefer environment.deinit();
    try environment.put("LC_ALL", "C");
    try environment.put("LANG", "C");
    try environment.put("TZ", "UTC0");
    try environment.put("HOME", paths.home);
    try environment.put("TMPDIR", paths.temporary);
    try environment.put("ZIG_LOCAL_CACHE_DIR", paths.local_cache);
    try environment.put("ZIG_GLOBAL_CACHE_DIR", paths.global_cache);
    try environment.put("GIT_OPTIONAL_LOCKS", "0");
    try environment.put("GIT_CONFIG_NOSYSTEM", "1");
    try environment.put("GIT_CONFIG_SYSTEM", "/dev/null");
    try environment.put("GIT_CONFIG_GLOBAL", "/dev/null");
    try environment.put("GIT_TERMINAL_PROMPT", "0");
    return environment;
}

pub fn runBounded(
    allocator: std.mem.Allocator,
    io: std.Io,
    argv: []const []const u8,
    environment: ?*const std.process.Environ.Map,
) !OwnedProcessResult {
    if (argv.len == 0 or !std.fs.path.isAbsolute(argv[0])) return error.ChildFailed;
    const result = std.process.run(allocator, io, .{
        .argv = argv,
        .cwd = .{ .path = repository_root },
        .environ_map = environment,
        .stdout_limit = .limited(process_output_max),
        .stderr_limit = .limited(process_output_max),
    }) catch |failure| switch (failure) {
        error.StreamTooLong => return error.ChildOutputBoundExceeded,
        else => return error.ChildFailed,
    };
    return .{ .term = result.term, .stdout = result.stdout, .stderr = result.stderr };
}

pub fn requireExitedZero(result: OwnedProcessResult) !void {
    switch (result.term) {
        .exited => |code| if (code != 0) return error.ChildFailed,
        else => return error.ChildFailed,
    }
}

pub fn buildReference(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_path: []const u8,
    optimize_arg: []const u8,
    paths: BuildPaths,
    environment: *const std.process.Environ.Map,
) !OwnedProcessResult {
    var emit_buffer: [std.Io.Dir.max_path_bytes + 32]u8 = undefined;
    const emit = try std.fmt.bufPrint(&emit_buffer, "-femit-bin={s}", .{paths.reference_executable});
    return runBounded(allocator, io, &.{ zig_path, "build-exe", paths.reference_source, optimize_arg, emit }, environment);
}

pub fn buildLinked(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_path: []const u8,
    optimize_arg: []const u8,
    paths: BuildPaths,
    environment: *const std.process.Environ.Map,
) !OwnedProcessResult {
    var emit_buffer: [std.Io.Dir.max_path_bytes + 32]u8 = undefined;
    const emit = try std.fmt.bufPrint(&emit_buffer, "-femit-bin={s}", .{paths.linked_executable});
    return runBounded(
        allocator,
        io,
        &.{ zig_path, "build-exe", "-fno-lld", paths.linked_source, paths.object, optimize_arg, emit },
        environment,
    );
}

const artifact_hash_chunk_bytes = 64 * 1024;

const ArtifactFileState = struct {
    kind: std.Io.File.Kind,
    length: u64,
    executable: bool,
};

fn artifactFileState(metadata: std.Io.File.Stat) ArtifactFileState {
    return .{
        .kind = metadata.kind,
        .length = metadata.size,
        .executable = std.Io.File.Permissions.has_executable_bit and metadata.permissions.toMode() & 0o111 != 0,
    };
}

fn requireArtifactFileState(state: ArtifactFileState, require_executable: bool, max_bytes: usize) !void {
    if (state.kind != .file or state.length == 0 or state.length > max_bytes or
        state.executable != require_executable)
    {
        return error.ExecutionArtifactInvalid;
    }
}

fn requireStableArtifactFileState(
    initial: ArtifactFileState,
    final: ArtifactFileState,
    streamed_length: u64,
    require_executable: bool,
    max_bytes: usize,
) !void {
    try requireArtifactFileState(initial, require_executable, max_bytes);
    try requireArtifactFileState(final, require_executable, max_bytes);
    if (final.kind != initial.kind or final.length != initial.length or
        final.executable != initial.executable or streamed_length != initial.length)
    {
        return error.ExecutionArtifactInvalid;
    }
}

pub fn observeArtifact(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    require_executable: bool,
    max_bytes: usize,
) !ArtifactIdentity {
    _ = allocator;
    var file = try std.Io.Dir.openFileAbsolute(io, path, .{ .mode = .read_only, .follow_symlinks = false });
    defer file.close(io);
    const initial = artifactFileState(try file.stat(io));
    try requireArtifactFileState(initial, require_executable, max_bytes);

    var hasher = Sha256.init(.{});
    var reader = file.readerStreaming(io, &.{});
    var chunk: [artifact_hash_chunk_bytes]u8 = undefined;
    var streamed_length: u64 = 0;
    while (true) {
        const length = try reader.interface.readSliceShort(&chunk);
        if (length == 0) break;
        streamed_length = std.math.add(u64, streamed_length, length) catch
            return error.ExecutionArtifactInvalid;
        if (streamed_length > initial.length or streamed_length > max_bytes) {
            return error.ExecutionArtifactInvalid;
        }
        hasher.update(chunk[0..length]);
    }
    const final = artifactFileState(try file.stat(io));
    try requireStableArtifactFileState(initial, final, streamed_length, require_executable, max_bytes);
    var digest: [Sha256.digest_length]u8 = undefined;
    hasher.final(&digest);
    return .{ .length = initial.length, .sha256 = digest, .executable = initial.executable };
}

pub fn observeSelector(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    environment: *const std.process.Environ.Map,
) !SelectorIdentity {
    if (!std.fs.path.isAbsolute(path)) return error.SelectorDrift;
    const artifact = try observeArtifact(allocator, io, path, true, 512 * 1024 * 1024);
    var version_result = try runBounded(allocator, io, &.{ path, "version" }, environment);
    defer version_result.deinit(allocator);
    try requireExitedZero(version_result);
    if (version_result.stderr.len != 0) return error.SelectorDrift;
    const version = std.mem.trim(u8, version_result.stdout, " \t\r\n");
    if (version.len == 0 or version.len > 128) return error.SelectorDrift;
    var identity: SelectorIdentity = .{
        .version = @splat(0),
        .version_length = @intCast(version.len),
        .length = artifact.length,
        .sha256 = artifact.sha256,
    };
    @memcpy(identity.version[0..version.len], version);
    return identity;
}

pub fn requireSelector(identity: SelectorIdentity) !void {
    if (!std.mem.eql(u8, identity.versionSlice(), selector_version) or identity.length != selector_length or
        !std.mem.eql(u8, &identity.sha256, &selector_sha256))
    {
        return error.SelectorDrift;
    }
}

pub fn requireExternalRepositoryClean(
    allocator: std.mem.Allocator,
    io: std.Io,
    environment: *const std.process.Environ.Map,
) !void {
    const prefix = [_][]const u8{
        "/usr/bin/git", "--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "core.untrackedCache=false", "-C", external_repository_root,
    };
    const head_argv = prefix ++ [_][]const u8{ "rev-parse", "HEAD" };
    var head = try runBounded(allocator, io, &head_argv, environment);
    defer head.deinit(allocator);
    try requireExitedZero(head);
    if (!std.mem.eql(u8, head.stdout, external_revision ++ "\n") or head.stderr.len != 0) {
        return error.ExternalRevisionMismatch;
    }
    const status_argv = prefix ++ [_][]const u8{ "status", "--porcelain=v1", "--untracked-files=all" };
    var status = try runBounded(allocator, io, &status_argv, environment);
    defer status.deinit(allocator);
    try requireExitedZero(status);
    if (status.stdout.len != 0 or status.stderr.len != 0) return error.ExternalRepositoryDirty;
}

pub fn readCurrentSources(allocator: std.mem.Allocator, io: std.Io, max_bytes: usize) !OwnedSourceFiles {
    var root = try std.Io.Dir.openDirAbsolute(io, external_repository_root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(io);
    const definition = try root.readFileAlloc(io, definition_path, allocator, .limited(max_bytes));
    errdefer allocator.free(definition);
    const import_source = try root.readFileAlloc(io, import_path, allocator, .limited(max_bytes));
    errdefer allocator.free(import_source);
    const use_source = try root.readFileAlloc(io, use_path, allocator, .limited(max_bytes));
    errdefer allocator.free(use_source);
    const requirements_definition = try root.readFileAlloc(io, requirements_definition_path, allocator, .limited(max_bytes));
    errdefer allocator.free(requirements_definition);
    const requirements_import_source = try root.readFileAlloc(io, requirements_import_path, allocator, .limited(max_bytes));
    errdefer allocator.free(requirements_import_source);
    const ascii_definition = try root.readFileAlloc(io, ascii_definition_path, allocator, .limited(max_bytes));
    return .{
        .definition = definition,
        .import_source = import_source,
        .use_source = use_source,
        .requirements_definition = requirements_definition,
        .requirements_import_source = requirements_import_source,
        .ascii_definition = ascii_definition,
    };
}

const SemanticReturn = struct {
    type_text: []const u8,
    value: usize,
};

fn parseSemanticReturn(text: []const u8) !SemanticReturn {
    const trimmed = std.mem.trim(u8, text, " \t\r\n");
    if (trimmed.len < 5 or trimmed[0] != '<' or trimmed[trimmed.len - 1] != '>') {
        return error.CohortDescriptorBindingMismatch;
    }
    const fields = trimmed[1 .. trimmed.len - 1];
    const comma = std.mem.indexOfScalar(u8, fields, ',') orelse return error.CohortDescriptorBindingMismatch;
    if (std.mem.indexOfScalarPos(u8, fields, comma + 1, ',') != null) {
        return error.CohortDescriptorBindingMismatch;
    }
    const type_text = std.mem.trim(u8, fields[0..comma], " \t\r\n");
    const value_text = std.mem.trim(u8, fields[comma + 1 ..], " \t\r\n");
    if (type_text.len == 0 or value_text.len == 0) return error.CohortDescriptorBindingMismatch;
    return .{
        .type_text = type_text,
        .value = std.fmt.parseUnsigned(usize, value_text, 10) catch
            return error.CohortDescriptorBindingMismatch,
    };
}

fn requireSemanticReturn(program: Program, function: air_export.Function) !void {
    const structured = function.structured_air_v2 orelse return error.CohortDescriptorBindingMismatch;
    var matching_return_count: usize = 0;
    for (structured.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "ret") and
            !std.mem.eql(u8, instruction.opcode, "ret_safe")) continue;
        matching_return_count += 1;
        if (matching_return_count != 1 or
            !std.mem.eql(u8, instruction.result_type, "noreturn") or
            !std.mem.eql(u8, instruction.data_kind, "un_op") or
            instruction.operands.len != 1)
        {
            return error.CohortDescriptorBindingMismatch;
        }
        const operand = instruction.operands[0];
        if (!std.mem.eql(u8, operand.kind, "const") or
            !std.mem.eql(u8, operand.type_text, program.descriptorReturnType()))
        {
            return error.CohortDescriptorBindingMismatch;
        }
        var semantic_text: ?[]const u8 = null;
        for (instruction.details) |detail| {
            if (!std.mem.eql(u8, detail.key, "operand0_text")) continue;
            if (semantic_text != null) return error.CohortDescriptorBindingMismatch;
            semantic_text = detail.value;
        }
        const semantic_return = try parseSemanticReturn(semantic_text orelse
            return error.CohortDescriptorBindingMismatch);
        if (!std.mem.eql(u8, semantic_return.type_text, program.descriptorReturnType()) or
            semantic_return.value != program.expectedResult())
        {
            return error.CohortDescriptorBindingMismatch;
        }
    }
    if (matching_return_count != 1) return error.CohortDescriptorBindingMismatch;
}

fn requireAsciiDescriptor(function: air_export.Function) !void {
    const structured = function.structured_air_v2 orelse return error.CohortDescriptorBindingMismatch;
    var argument: ?air_export.TypedInstruction = null;
    var comparison: ?air_export.TypedInstruction = null;
    var returned: ?air_export.TypedInstruction = null;
    for (structured.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "arg")) {
            if (argument != null or !std.mem.eql(u8, instruction.result_type, "u8") or
                !std.mem.eql(u8, instruction.data_kind, "arg") or instruction.operands.len != 0)
                return error.CohortDescriptorBindingMismatch;
            argument = instruction;
        } else if (std.mem.eql(u8, instruction.opcode, "cmp_lt")) {
            if (comparison != null or !std.mem.eql(u8, instruction.result_type, "bool") or
                !std.mem.eql(u8, instruction.data_kind, "bin_op") or instruction.operands.len != 2)
                return error.CohortDescriptorBindingMismatch;
            comparison = instruction;
        } else if (std.mem.eql(u8, instruction.opcode, "ret") or std.mem.eql(u8, instruction.opcode, "ret_safe")) {
            if (returned != null or !std.mem.eql(u8, instruction.result_type, "noreturn") or
                !std.mem.eql(u8, instruction.data_kind, "un_op") or instruction.operands.len != 1)
                return error.CohortDescriptorBindingMismatch;
            returned = instruction;
        } else if (!std.mem.eql(u8, instruction.opcode, "dbg_stmt") or
            !std.mem.eql(u8, instruction.result_type, "void") or instruction.operands.len != 0)
            return error.CohortDescriptorBindingMismatch;
    }
    const arg = argument orelse return error.CohortDescriptorBindingMismatch;
    const cmp = comparison orelse return error.CohortDescriptorBindingMismatch;
    const ret = returned orelse return error.CohortDescriptorBindingMismatch;
    if (!std.mem.eql(u8, cmp.operands[0].kind, "inst") or !std.mem.eql(u8, cmp.operands[0].type_text, "u8") or
        (std.fmt.parseUnsigned(u32, cmp.operands[0].value, 10) catch return error.CohortDescriptorBindingMismatch) != arg.index or
        !std.mem.eql(u8, cmp.operands[1].kind, "const") or !std.mem.eql(u8, cmp.operands[1].type_text, "u8") or
        !std.mem.eql(u8, ret.operands[0].kind, "inst") or !std.mem.eql(u8, ret.operands[0].type_text, "bool") or
        (std.fmt.parseUnsigned(u32, ret.operands[0].value, 10) catch return error.CohortDescriptorBindingMismatch) != cmp.index)
        return error.CohortDescriptorBindingMismatch;
    var literal: ?[]const u8 = null;
    for (cmp.details) |detail| {
        if (!std.mem.eql(u8, detail.key, "operand1_text")) continue;
        if (literal != null) return error.CohortDescriptorBindingMismatch;
        literal = detail.value;
    }
    const threshold = try parseSemanticReturn(literal orelse return error.CohortDescriptorBindingMismatch);
    if (!std.mem.eql(u8, threshold.type_text, "u8") or threshold.value != 128)
        return error.CohortDescriptorBindingMismatch;
}

pub fn validateDescriptor(allocator: std.mem.Allocator, program: Program, descriptor: []const u8) !void {
    var module = air_export.parse(allocator, descriptor) catch
        return error.CohortDescriptorBindingMismatch;
    defer module.deinit();
    if (module.functions.len != 1) return error.CohortDescriptorBindingMismatch;
    const function = module.functions[0];
    if (!std.mem.eql(u8, function.name, program.functionName()) or
        !std.mem.eql(u8, function.type_text, program.descriptorType()))
    {
        return error.CohortDescriptorBindingMismatch;
    }
    if (program == .ascii_is_ascii) try requireAsciiDescriptor(function) else try requireSemanticReturn(program, function);
}

pub fn canonicalExecutionRecord(
    result: OwnedProcessResult,
    semantic_result: usize,
    call_occurrence: bool,
) !ExecutionRecord {
    return canonicalExecutionRecordWithExpected(result, semantic_result, expected_stdout, call_occurrence);
}

pub fn canonicalProgramExecutionRecord(
    result: OwnedProcessResult,
    program: Program,
    call_occurrence: bool,
) !ExecutionRecord {
    const record = try canonicalExecutionRecordWithExpected(
        result,
        program.expectedResult(),
        program.expectedStdout(),
        call_occurrence,
    );
    return record;
}

fn canonicalExecutionRecordWithExpected(
    result: OwnedProcessResult,
    semantic_result: usize,
    expected_output: []const u8,
    call_occurrence: bool,
) !ExecutionRecord {
    const termination: Termination, const status: u8 = switch (result.term) {
        .exited => |code| .{ .exited, code },
        .signal => .{ .signaled, 0 },
        .stopped => .{ .stopped, 0 },
        .unknown => .{ .unknown, 0 },
    };
    if (result.stdout.len > process_output_max or result.stderr.len > process_output_max) {
        return error.ChildOutputBoundExceeded;
    }
    if (termination != .exited or status != 0 or !std.mem.eql(u8, result.stdout, expected_output) or result.stderr.len != 0) {
        return error.ProcessInconsistent;
    }
    return .{
        .termination = termination,
        .status = status,
        .stdout_sha256 = sha256(result.stdout),
        .stderr_sha256 = sha256(result.stderr),
        .stdout_length = result.stdout.len,
        .stderr_length = result.stderr.len,
        .semantic_result = semantic_result,
        .call_occurrence = call_occurrence,
    };
}

test "artifact identity streams with bounded memory and preserves exact boundaries" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var payload: [artifact_hash_chunk_bytes * 3 + 17]u8 = undefined;
    for (&payload, 0..) |*byte, index| byte.* = @truncate(index);
    try tmp.dir.writeFile(io, .{ .sub_path = "artifact", .data = &payload });
    try tmp.dir.writeFile(io, .{
        .sub_path = "executable",
        .data = "executable",
        .flags = .{ .permissions = .fromMode(0o755) },
    });

    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try tmp.dir.realPath(io, &root_buffer);
    const root = root_buffer[0..root_length];
    var artifact_path_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const artifact_path = try std.fmt.bufPrint(&artifact_path_buffer, "{s}/artifact", .{root});
    var executable_path_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const executable_path = try std.fmt.bufPrint(&executable_path_buffer, "{s}/executable", .{root});

    const identity = try observeArtifact(std.testing.failing_allocator, io, artifact_path, false, payload.len);
    try std.testing.expectEqual(@as(u64, payload.len), identity.length);
    try std.testing.expectEqualSlices(u8, &sha256(&payload), &identity.sha256);
    try std.testing.expect(!identity.executable);
    try std.testing.expectError(
        error.ExecutionArtifactInvalid,
        observeArtifact(std.testing.failing_allocator, io, artifact_path, false, payload.len - 1),
    );
    try std.testing.expectError(
        error.ExecutionArtifactInvalid,
        observeArtifact(std.testing.failing_allocator, io, artifact_path, true, payload.len),
    );
    const executable_identity = try observeArtifact(std.testing.failing_allocator, io, executable_path, true, "executable".len);
    try std.testing.expect(executable_identity.executable);
    try std.testing.expectError(
        error.ExecutionArtifactInvalid,
        observeArtifact(std.testing.failing_allocator, io, executable_path, false, "executable".len),
    );
}

test "artifact identity rejects symlinks non-files and final metadata drift" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "artifact", .data = "artifact" });
    try tmp.dir.symLink(io, "artifact", "artifact-link", .{});
    try tmp.dir.createDir(io, "directory", .default_dir);

    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try tmp.dir.realPath(io, &root_buffer);
    const root = root_buffer[0..root_length];
    var symlink_path_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const symlink_path = try std.fmt.bufPrint(&symlink_path_buffer, "{s}/artifact-link", .{root});
    var directory_path_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const directory_path = try std.fmt.bufPrint(&directory_path_buffer, "{s}/directory", .{root});

    if (observeArtifact(std.testing.failing_allocator, io, symlink_path, false, 8)) |_| {
        return error.TestExpectedError;
    } else |_| {}
    try std.testing.expectError(
        error.ExecutionArtifactInvalid,
        observeArtifact(std.testing.failing_allocator, io, directory_path, false, 8),
    );

    const initial = ArtifactFileState{ .kind = .file, .length = 8, .executable = false };
    try requireStableArtifactFileState(initial, initial, 8, false, 8);
    try std.testing.expectError(
        error.ExecutionArtifactInvalid,
        requireStableArtifactFileState(initial, .{ .kind = .file, .length = 7, .executable = false }, 8, false, 8),
    );
    try std.testing.expectError(
        error.ExecutionArtifactInvalid,
        requireStableArtifactFileState(initial, .{ .kind = .directory, .length = 8, .executable = false }, 8, false, 8),
    );
    try std.testing.expectError(
        error.ExecutionArtifactInvalid,
        requireStableArtifactFileState(initial, .{ .kind = .file, .length = 8, .executable = true }, 8, false, 8),
    );
    try std.testing.expectError(
        error.ExecutionArtifactInvalid,
        requireStableArtifactFileState(initial, initial, 7, false, 8),
    );
}

const SemanticDescriptorFixture = struct {
    program: Program,
    mode: []const u8 = "ReleaseFast",
    opcode: []const u8 = "ret",
    instruction_count: usize = 2,
    main_body_count: usize = 2,
    function_name: ?[]const u8 = null,
    type_text: ?[]const u8 = null,
    return_type: ?[]const u8 = null,
    return_value: ?usize = null,
    duplicate_function: bool = false,
};

fn semanticDescriptorForTest(allocator: std.mem.Allocator, fixture: SemanticDescriptorFixture) ![]u8 {
    const function_name = fixture.function_name orelse fixture.program.functionName();
    const type_text = fixture.type_text orelse fixture.program.descriptorType();
    const return_type = fixture.return_type orelse fixture.program.descriptorReturnType();
    const return_value = fixture.return_value orelse fixture.program.expectedResult();
    const return_index = fixture.instruction_count - 1;
    const semantic_text = try std.fmt.allocPrint(allocator, "<{s}, {}>", .{ return_type, return_value });
    defer allocator.free(semantic_text);
    const air_text = try std.fmt.allocPrint(allocator, "  %{}!= {s}({s})\n", .{ return_index, fixture.opcode, semantic_text });
    defer allocator.free(air_text);
    const structured_text = try std.fmt.allocPrint(
        allocator,
        "structured_air-v2\ntyped_inst|{}|{s}|8|noreturn|un_op|1|const|4|1361|{}|{s}|1|operand0_text|{}|{s}\nstructured_air_v2_end\n",
        .{ return_index, fixture.opcode, return_type.len, return_type, semantic_text.len, semantic_text },
    );
    defer allocator.free(structured_text);
    const function_frame = try std.fmt.allocPrint(
        allocator,
        "function_begin\nname_bytes={}\n{s}\ntype_bytes={}\n{s}\ninstruction_count={}\nmain_body_count={}\nliveness=present\nair_bytes={}\n{s}\nstructured_air_v2_bytes={}\n{s}\nfunction_end\n",
        .{
            function_name.len,
            function_name,
            type_text.len,
            type_text,
            fixture.instruction_count,
            fixture.main_body_count,
            air_text.len,
            air_text,
            structured_text.len,
            structured_text,
        },
    );
    defer allocator.free(function_frame);
    const functions = if (fixture.duplicate_function)
        try std.fmt.allocPrint(allocator, "{s}{s}", .{ function_frame, function_frame })
    else
        try allocator.dupe(u8, function_frame);
    defer allocator.free(functions);
    return std.fmt.allocPrint(
        allocator,
        "zllvm-air-export-v1\ncontract_version=1\npayload=zig-air-print-v1\nproducer=test\nroot_source=test.zig\nwrapper=test.zig\nmode={s}\ntarget=x86_64-unknown-linux-gnu\nfunction_count={}\nglobal_count=0\n{s}",
        .{ fixture.mode, @as(usize, if (fixture.duplicate_function) 2 else 1), functions },
    );
}

test "fixed cohort identities and harnesses are exact" {
    try std.testing.expectEqual(@as(usize, 5), programs.len);
    try std.testing.expectEqualStrings("link.MachO.CodeSignature.Signature.size", programs[0].functionName());
    try std.testing.expectEqualStrings("link.MachO.CodeSignature.Signature.slotType", programs[1].functionName());
    try std.testing.expectEqualStrings("link.MachO.CodeSignature.Requirements.size", programs[2].functionName());
    try std.testing.expectEqualStrings(
        "link.MachO.CodeSignature.Requirements.slotType",
        programs[3].functionName(),
    );
    for (programs) |program| try validateHarnesses(program);
    for (programs, 0..) |program, index| for (programs, 0..) |other, other_index| {
        if (index != other_index) try std.testing.expectEqual(@as(usize, 0), std.mem.count(u8, program.linkedHarness(), other.functionName()));
    };
    try std.testing.expectEqual(@as(usize, 12), programs[2].expectedResult());
    try std.testing.expectEqual(@as(usize, 43), programs[2].expectedWitness());
    try std.testing.expectEqual(@as(usize, 2), programs[3].expectedResult());
    try std.testing.expectEqual(@as(usize, 13), programs[3].expectedWitness());
    try std.testing.expectEqual(@as(usize, 256), programs[4].observations());
    try std.testing.expectEqual(@as(usize, 128), programs[4].expectedResult());
    try std.testing.expectEqual(@as(usize, 8256), programs[4].expectedWitness());
}

test "ASCII source binding rejects threshold signature import and duplicate drift" {
    const definition = "pub fn isAscii(c: u8) bool {\n    return c < 128;\n}";
    const import_source = "pub const ascii = @import(\"ascii.zig\");";
    try validateAsciiSource(definition, import_source);
    try std.testing.expectError(error.CohortSourceBindingMismatch, validateAsciiSource("pub fn isAscii(c: u8) bool {\n    return c < 127;\n}", import_source));
    try std.testing.expectError(error.CohortSourceBindingMismatch, validateAsciiSource("pub fn isAscii(c: i8) bool {\n    return c < 128;\n}", import_source));
    try std.testing.expectError(error.CohortSourceBindingMismatch, validateAsciiSource(definition, ""));
    try std.testing.expectError(error.CohortSourceBindingMismatch, validateAsciiSource(definition ++ definition, import_source));
}

test "ASCII descriptor binds argument unsigned comparison threshold and return in every mode" {
    const fixtures = [_][]const u8{
        @embedFile("testdata/ascii_ReleaseFast.air"),
        @embedFile("testdata/ascii_ReleaseSafe.air"),
        @embedFile("testdata/ascii_ReleaseSmall.air"),
    };
    for (fixtures) |fixture| {
        try validateDescriptor(std.testing.allocator, .ascii_is_ascii, fixture);
        var module = try air_export.parse(std.testing.allocator, fixture);
        defer module.deinit();
        const function = module.functions[0];
        for (function.structured_air_v2.?.instructions) |*instruction| {
            if (!std.mem.eql(u8, instruction.opcode, "cmp_lt")) continue;
            const old_opcode = instruction.opcode;
            instruction.opcode = "cmp_lte";
            try std.testing.expectError(error.CohortDescriptorBindingMismatch, requireAsciiDescriptor(function));
            instruction.opcode = old_opcode;
            for (@constCast(instruction.details)) |*detail| {
                if (!std.mem.eql(u8, detail.key, "operand1_text")) continue;
                const old_value = detail.value;
                detail.value = "<u8, 127>";
                try std.testing.expectError(error.CohortDescriptorBindingMismatch, requireAsciiDescriptor(function));
                detail.value = old_value;
            }
            const operand = &@constCast(instruction.operands)[0];
            const old_value = operand.value;
            operand.value = "999";
            try std.testing.expectError(error.CohortDescriptorBindingMismatch, requireAsciiDescriptor(function));
            operand.value = old_value;
        }
        var wrong_signature = function;
        wrong_signature.type_text = "fn (i8) bool";
        // The production entry validates the signature before inspecting the body.
        const changed = try std.mem.replaceOwned(u8, std.testing.allocator, fixture, "fn (u8) bool", wrong_signature.type_text);
        defer std.testing.allocator.free(changed);
        try std.testing.expectError(error.CohortDescriptorBindingMismatch, validateDescriptor(std.testing.allocator, .ascii_is_ascii, changed));
    }
}

test "ASCII execution transcript requires all 256 bits including the 127 to 128 boundary" {
    const program: Program = .ascii_is_ascii;
    const stdout = try std.testing.allocator.dupe(u8, program.expectedStdout());
    defer std.testing.allocator.free(stdout);
    var result: OwnedProcessResult = .{ .term = .{ .exited = 0 }, .stdout = stdout, .stderr = @constCast("") };
    _ = try canonicalProgramExecutionRecord(result, program, true);
    const start = std.mem.indexOf(u8, stdout, "bits=").? + "bits=".len;
    for ([_]usize{ 0, 127, 128, 255 }) |input| {
        const old = stdout[start + input];
        stdout[start + input] = if (old == '1') '0' else '1';
        try std.testing.expectError(error.ProcessInconsistent, canonicalProgramExecutionRecord(result, program, true));
        stdout[start + input] = old;
    }
    result.stdout = stdout[0 .. stdout.len - 1];
    try std.testing.expectError(error.ProcessInconsistent, canonicalProgramExecutionRecord(result, program, true));
}

test "signature source binding rejects changed constants and duplicate definitions" {
    const definition =
        \\const Signature = struct {
        \\    fn size(self: Signature) u32 {
        \\        _ = self;
        \\        return 2 * @sizeOf(u32);
        \\    }
        \\    fn slotType(self: Signature) u32 {
        \\        _ = self;
        \\        return macho.CSSLOT_SIGNATURESLOT;
        \\    }
        \\};
    ;
    try validateSignatureSource(definition);
    try std.testing.expectError(error.CohortSourceBindingMismatch, validateSignatureSource("const Signature = struct {};"));
    const changed = try std.mem.replaceOwned(u8, std.testing.allocator, definition, "2 *", "3 *");
    defer std.testing.allocator.free(changed);
    try std.testing.expectError(error.CohortSourceBindingMismatch, validateSignatureSource(changed));
    try std.testing.expectError(error.CohortSourceBindingMismatch, validateSignatureSource(definition ++ definition));
}

test "requirements source and bridge admission are exact" {
    const definition =
        \\const Requirements = struct {
        \\    fn deinit(self: *Requirements, allocator: Allocator) void {
        \\    }
        \\    fn slotType(self: Requirements) u32 {
        \\        _ = self;
        \\        return macho.CSSLOT_REQUIREMENTS;
        \\    }
        \\    fn size(self: Requirements) u32 {
        \\        _ = self;
        \\        return 3 * @sizeOf(u32);
        \\    }
        \\    fn write(self: Requirements, writer: anytype) !void {
        \\        try writer.writeInt(u32, macho.CSMAGIC_REQUIREMENTS, .big);
        \\        try writer.writeInt(u32, self.size(), .big);
        \\        try writer.writeInt(u32, 0, .big);
        \\    }
        \\};
    ;
    const import_source = "const CodeSignature = @import(\"MachO/CodeSignature.zig\");\n";
    try validateRequirementsSources(definition, import_source);
    const blank_line_drifted_definition =
        \\const Requirements = struct {
        \\
        \\    fn deinit(self: *Requirements, allocator: Allocator) void {
        \\    }
        \\    fn slotType(self: Requirements) u32 {
        \\        _ = self;
        \\        return macho.CSSLOT_REQUIREMENTS;
        \\    }
        \\    fn size(self: Requirements) u32 {
        \\        _ = self;
        \\        return 3 * @sizeOf(u32);
        \\    }
        \\    fn write(self: Requirements, writer: anytype) !void {
        \\        try writer.writeInt(u32, macho.CSMAGIC_REQUIREMENTS, .big);
        \\        try writer.writeInt(u32, self.size(), .big);
        \\        try writer.writeInt(u32, 0, .big);
        \\    }
        \\};
    ;
    try std.testing.expectError(error.CohortSourceBindingMismatch, validateRequirementsSources(blank_line_drifted_definition, import_source));
    const unqualified_write_definition =
        \\const Requirements = struct {
        \\    fn deinit(self: *Requirements, allocator: Allocator) void {
        \\    }
        \\    fn slotType(self: Requirements) u32 {
        \\        _ = self;
        \\        return macho.CSSLOT_REQUIREMENTS;
        \\    }
        \\    fn size(self: Requirements) u32 {
        \\        _ = self;
        \\        return 3 * @sizeOf(u32);
        \\    }
        \\};
        \\        try writer.writeInt(u32, self.size(), .big);
    ;
    try std.testing.expectError(error.CohortSourceBindingMismatch, validateRequirementsSources(unqualified_write_definition, import_source));
    const other_owner_write_definition =
        \\const Requirements = struct {
        \\    fn deinit(self: *Requirements, allocator: Allocator) void {
        \\    }
        \\    fn slotType(self: Requirements) u32 {
        \\        _ = self;
        \\        return macho.CSSLOT_REQUIREMENTS;
        \\    }
        \\    fn size(self: Requirements) u32 {
        \\        _ = self;
        \\        return 3 * @sizeOf(u32);
        \\    }
        \\};
        \\const Entitlements = struct {
        \\    fn write(self: Entitlements, writer: anytype) !void {
        \\        try writer.writeInt(u32, self.size(), .big);
        \\    }
        \\};
    ;
    try std.testing.expectError(error.CohortSourceBindingMismatch, validateRequirementsSources(other_owner_write_definition, import_source));
    const drifted_write_definition =
        \\const Requirements = struct {
        \\    fn deinit(self: *Requirements, allocator: Allocator) void {
        \\    }
        \\    fn slotType(self: Requirements) u32 {
        \\        _ = self;
        \\        return macho.CSSLOT_REQUIREMENTS;
        \\    }
        \\    fn size(self: Requirements) u32 {
        \\        _ = self;
        \\        return 3 * @sizeOf(u32);
        \\    }
        \\    fn write(self: Requirements, writer: anytype) !void {
        \\        try writer.writeInt(u32, macho.CSMAGIC_REQUIREMENTS, .big);
        \\        try writer.writeInt(u32, self.size(), .big);
        \\        try writer.writeInt(u32, 1, .big);
        \\    }
        \\};
    ;
    try std.testing.expectError(error.CohortSourceBindingMismatch, validateRequirementsSources(drifted_write_definition, import_source));
    const drifted_slot_type_definition =
        \\const Requirements = struct {
        \\    fn deinit(self: *Requirements, allocator: Allocator) void {
        \\    }
        \\    fn slotType(self: Requirements) u32 {
        \\        _ = self;
        \\        return macho.CSSLOT_SIGNATURESLOT;
        \\    }
        \\    fn size(self: Requirements) u32 {
        \\        _ = self;
        \\        return 3 * @sizeOf(u32);
        \\    }
        \\    fn write(self: Requirements, writer: anytype) !void {
        \\        try writer.writeInt(u32, macho.CSMAGIC_REQUIREMENTS, .big);
        \\        try writer.writeInt(u32, self.size(), .big);
        \\        try writer.writeInt(u32, 0, .big);
        \\    }
        \\};
    ;
    try std.testing.expectError(
        error.CohortSourceBindingMismatch,
        validateRequirementsSources(drifted_slot_type_definition, import_source),
    );
    const drifted_definition =
        \\const Requirements = struct {
        \\    fn size(self: Requirements) u32 {
        \\        _ = self;
        \\        return 8;
        \\    }
        \\};
    ;
    try std.testing.expectError(error.CohortSourceBindingMismatch, validateRequirementsSources(drifted_definition, import_source));
}

test "semantic cohort descriptor binding accepts Fast and Safe shapes" {
    const allocator = std.testing.allocator;
    const fast = try semanticDescriptorForTest(allocator, .{ .program = .signature_size });
    defer allocator.free(fast);
    try validateDescriptor(allocator, .signature_size, fast);

    const safe = try semanticDescriptorForTest(allocator, .{
        .program = .requirements_size,
        .mode = "ReleaseSafe",
        .opcode = "ret_safe",
        .instruction_count = 5,
        .main_body_count = 3,
    });
    defer allocator.free(safe);
    try validateDescriptor(allocator, .requirements_size, safe);

    const slot_type = try semanticDescriptorForTest(allocator, .{
        .program = .requirements_slot_type,
        .mode = "ReleaseSmall",
    });
    defer allocator.free(slot_type);
    try validateDescriptor(allocator, .requirements_slot_type, slot_type);
}

test "semantic cohort descriptor binding rejects function signature return multiplicity and malformed drift" {
    const allocator = std.testing.allocator;
    const fixtures = [_]SemanticDescriptorFixture{
        .{ .program = .signature_size, .function_name = "coff.Symbol.other" },
        .{ .program = .signature_size, .type_text = "fn () u64" },
        .{ .program = .signature_size, .return_type = "u64" },
        .{ .program = .signature_size, .return_value = 19 },
        .{ .program = .signature_size, .duplicate_function = true },
    };
    for (fixtures) |fixture| {
        const descriptor = try semanticDescriptorForTest(allocator, fixture);
        defer allocator.free(descriptor);
        try std.testing.expectError(
            error.CohortDescriptorBindingMismatch,
            validateDescriptor(allocator, .signature_size, descriptor),
        );
    }
    try std.testing.expectError(
        error.CohortDescriptorBindingMismatch,
        validateDescriptor(allocator, .signature_size, "malformed"),
    );
}

test "paired counters reject partial status semantic and call drift" {
    const good = ExecutionRecord{
        .termination = .exited,
        .status = 0,
        .stdout_sha256 = sha256(expected_stdout),
        .stderr_sha256 = sha256(""),
        .stdout_length = expected_stdout.len,
        .stderr_length = 0,
        .semantic_result = expected_result,
        .call_occurrence = true,
    };
    var counters: PairCounters = .{};
    try counters.noteBothExecuted(good, good);
    try counters.noteOracleAccepted(good, good);
    try std.testing.expectEqual(@as(usize, 1), counters.real_executed);
    try std.testing.expectEqual(@as(usize, 1), counters.real_programs_ok);

    var nonzero = good;
    nonzero.status = 1;
    var failed: PairCounters = .{};
    try std.testing.expectError(error.ProcessInconsistent, failed.noteBothExecuted(good, nonzero));
    var semantic = good;
    semantic.semantic_result = 19;
    failed.real_executed = 1;
    try std.testing.expectError(error.OracleMismatch, failed.noteOracleAccepted(good, semantic));
    var missing_call = good;
    missing_call.call_occurrence = false;
    try std.testing.expectError(error.CallOccurrenceMissing, failed.noteOracleAccepted(good, missing_call));
}

test "canonical execution records are bounded exact and binary sensitive" {
    const allocator = std.testing.allocator;
    var stdout = try allocator.dupe(u8, expected_stdout);
    defer allocator.free(stdout);
    const stderr = try allocator.dupe(u8, "");
    defer allocator.free(stderr);
    const good = OwnedProcessResult{ .term = .{ .exited = 0 }, .stdout = stdout, .stderr = stderr };
    const record = try canonicalExecutionRecord(good, expected_result, true);
    try std.testing.expectEqual(expected_result, record.semantic_result);
    stdout[0] ^= 1;
    try std.testing.expectError(error.ProcessInconsistent, canonicalExecutionRecord(good, expected_result, true));
}
