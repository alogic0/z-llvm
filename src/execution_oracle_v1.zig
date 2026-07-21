const std = @import("std");
const builtin = @import("builtin");
const real_rows = @import("distribution_real_rows_gate.zig");
const air_export = @import("zig_air_export.zig");
const air_types = @import("zig_air_types.zig");
const project_target = @import("target.zig");
const acceptance = @import("execution_oracle_v1_acceptance.zig");

const Sha256 = std.crypto.hash.sha2.Sha256;

const schema = "execution-oracle-v1";
const repository_root = "/home/oleg/prog/z_llvm";
const zig_repository_root = "/home/oleg/prog/ziglang";
const zig_revision = "bdee02bc0c7f227c0f11bc9a449df673fe803540";
const zig_build_path = "build.zig";
const definition_path = "lib/std/coff.zig";
const std_path = "lib/std/std.zig";
const use_path = "src/libs/mingw/implib.zig";
const function_name = "coff.Symbol.sizeOf";
const expected_result: usize = 18;
const expected_execution_stdout = "execution-oracle-v1 result=18 witness=61\n";
const generation_root = "local-state/validations/inbox206co/generation-v5";
const retained_diagnostic_generation_root = "local-state/validations/inbox206co/generation-v3";
const retained_reference_generation_root = "local-state/validations/inbox206co/generation-v4";
const execution_target = "x86_64-linux-gnu";
const source_max_bytes = 4 * 1024 * 1024;
const descriptor_max_bytes = 2 * 1024 * 1024 * 1024;
const process_output_max = 16 * 1024 * 1024;
const zig_max_bytes = 512 * 1024 * 1024;
const version_max_bytes = 128;
const peak_storage_bytes: u64 = 6 * 1024 * 1024 * 1024;
const peak_storage_files: u64 = 100_000;
const build_phase_frame_magic = "ZLBPFV1\x00";
const build_phase_frame_header_size = build_phase_frame_magic.len + 24;
const build_phase_frame_max_bytes = build_phase_frame_header_size + 2 * process_output_max;
const reference_build_frame_temporary = "reference-build-result-v1.tmp";
const reference_build_frame_final = "reference-build-result-v1.bin";
const linked_build_frame_temporary = "linked-build-result-v1.tmp";
const linked_build_frame_final = "linked-build-result-v1.bin";
const linked_frame_inspector_mode = "--inspect-generation-v3-linked-frame";
const reference_output_inspector_mode = "--inspect-generation-v4-reference-output";
const diagnostic_stream_max_bytes = 64 * 1024;
const diagnostic_render_max_bytes = 256 * 1024;

const OracleError = error{
    AbiMismatch,
    AirBindingDuplicate,
    AirBindingMissing,
    CallOccurrenceMissing,
    CandidateBindingMismatch,
    CandidateAdmissionMissing,
    BuildPhaseFrameBoundExceeded,
    BuildPhaseFrameMalformed,
    BuildPhaseFramePublicationOrder,
    BuildPhaseFrameReadBackMismatch,
    ChildFailed,
    ChildOutputBoundExceeded,
    DescriptorInvalid,
    DiagnosticContentOmitted,
    DiagnosticFrameWrongPhase,
    ExternalRepositoryDirty,
    ExternalRevisionMismatch,
    ExternalVersionUnavailable,
    GenerationCollision,
    GenerationLayoutInvalid,
    InsufficientStorage,
    InvalidArguments,
    InvalidSourceDefinition,
    OracleMismatch,
    ProcessInconsistent,
    SourceDefinitionDuplicate,
    SourceDefinitionMissing,
    SourceImportMismatch,
    SourceUseMismatch,
    SelectorDrift,
    ZigExecutableInvalid,
    ZigSelectorInvalid,
    ZigVersionMismatch,
};

const BoundPath = struct {
    bytes: [std.Io.Dir.max_path_bytes]u8 = [_]u8{0} ** std.Io.Dir.max_path_bytes,
    length: usize = 0,

    fn init(path: []const u8) OracleError!BoundPath {
        if (path.len == 0 or path.len > std.Io.Dir.max_path_bytes or std.mem.indexOfScalar(u8, path, 0) != null) {
            return error.GenerationLayoutInvalid;
        }
        var result: BoundPath = .{};
        @memcpy(result.bytes[0..path.len], path);
        result.length = path.len;
        return result;
    }

    fn child(parent: *const BoundPath, name: []const u8) OracleError!BoundPath {
        if (name.len == 0 or std.fs.path.isAbsolute(name) or std.mem.indexOfScalar(u8, name, '/') != null or
            std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, ".."))
        {
            return error.GenerationLayoutInvalid;
        }
        var result: BoundPath = .{};
        const rendered = std.fmt.bufPrint(&result.bytes, "{s}/{s}", .{ parent.slice(), name }) catch
            return error.GenerationLayoutInvalid;
        result.length = rendered.len;
        return result;
    }

    fn absolute(relative: *const BoundPath) OracleError!BoundPath {
        if (std.fs.path.isAbsolute(relative.slice())) return error.GenerationLayoutInvalid;
        var result: BoundPath = .{};
        const rendered = std.fmt.bufPrint(&result.bytes, "{s}/{s}", .{ repository_root, relative.slice() }) catch
            return error.GenerationLayoutInvalid;
        result.length = rendered.len;
        return result;
    }

    fn slice(self: *const BoundPath) []const u8 {
        return self.bytes[0..self.length];
    }
};

const GenerationLayout = struct {
    root: BoundPath,
    descriptor: BoundPath,
    local_cache: BoundPath,
    global_cache: BoundPath,
    home: BoundPath,
    temporary: BoundPath,
    reference_source: BoundPath,
    linked_source: BoundPath,
    object: BoundPath,
    reference_executable: BoundPath,
    linked_executable: BoundPath,
    reference_stdout: BoundPath,
    reference_stderr: BoundPath,
    linked_stdout: BoundPath,
    linked_stderr: BoundPath,
    reference_build_frame: BoundPath,
    linked_build_frame: BoundPath,

    fn init(root_text: []const u8) OracleError!GenerationLayout {
        try validateRelativeGenerationRoot(root_text);
        const root = try BoundPath.init(root_text);
        var layout: GenerationLayout = .{
            .root = root,
            .descriptor = undefined,
            .local_cache = undefined,
            .global_cache = undefined,
            .home = undefined,
            .temporary = undefined,
            .reference_source = undefined,
            .linked_source = undefined,
            .object = undefined,
            .reference_executable = undefined,
            .linked_executable = undefined,
            .reference_stdout = undefined,
            .reference_stderr = undefined,
            .linked_stdout = undefined,
            .linked_stderr = undefined,
            .reference_build_frame = undefined,
            .linked_build_frame = undefined,
        };
        layout.descriptor = try BoundPath.child(&layout.root, "compiler.air");
        layout.local_cache = try BoundPath.child(&layout.root, "zig-local-cache");
        layout.global_cache = try BoundPath.child(&layout.root, "zig-global-cache");
        layout.home = try BoundPath.child(&layout.root, "home");
        layout.temporary = try BoundPath.child(&layout.root, "tmp");
        layout.reference_source = try BoundPath.child(&layout.root, "reference.zig");
        layout.linked_source = try BoundPath.child(&layout.root, "linked.zig");
        layout.object = try BoundPath.child(&layout.root, "coff.Symbol.sizeOf.o");
        layout.reference_executable = try BoundPath.child(&layout.root, "reference");
        layout.linked_executable = try BoundPath.child(&layout.root, "linked");
        layout.reference_stdout = try BoundPath.child(&layout.root, "reference.stdout");
        layout.reference_stderr = try BoundPath.child(&layout.root, "reference.stderr");
        layout.linked_stdout = try BoundPath.child(&layout.root, "linked.stdout");
        layout.linked_stderr = try BoundPath.child(&layout.root, "linked.stderr");
        layout.reference_build_frame = try BoundPath.child(&layout.root, reference_build_frame_final);
        layout.linked_build_frame = try BoundPath.child(&layout.root, linked_build_frame_final);
        try layout.validate();
        return layout;
    }

    fn validate(self: *const GenerationLayout) OracleError!void {
        const paths = [_]*const BoundPath{
            &self.descriptor,
            &self.local_cache,
            &self.global_cache,
            &self.home,
            &self.temporary,
            &self.reference_source,
            &self.linked_source,
            &self.object,
            &self.reference_executable,
            &self.linked_executable,
            &self.reference_stdout,
            &self.reference_stderr,
            &self.linked_stdout,
            &self.linked_stderr,
            &self.reference_build_frame,
            &self.linked_build_frame,
        };
        for (paths) |path| {
            if (!isStrictDescendant(self.root.slice(), path.slice())) return error.GenerationLayoutInvalid;
        }
    }

    fn descriptorForExport(self: *const GenerationLayout) []const u8 {
        return self.descriptor.slice();
    }

    fn descriptorForRead(self: *const GenerationLayout) []const u8 {
        return self.descriptor.slice();
    }

    fn descriptorForAdmission(self: *const GenerationLayout) []const u8 {
        return self.descriptor.slice();
    }

    fn descriptorForFinalRead(self: *const GenerationLayout) []const u8 {
        return self.descriptor.slice();
    }
};

fn validateRelativeGenerationRoot(root: []const u8) OracleError!void {
    if (root.len == 0 or std.fs.path.isAbsolute(root) or std.mem.indexOfScalar(u8, root, 0) != null) {
        return error.GenerationLayoutInvalid;
    }
    var components = std.mem.splitScalar(u8, root, '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or std.mem.eql(u8, component, "..")) {
            return error.GenerationLayoutInvalid;
        }
    }
}

fn requireFixedGenerationLayout(layout: *const GenerationLayout) OracleError!void {
    if (!std.mem.eql(u8, layout.root.slice(), generation_root)) return error.GenerationLayoutInvalid;
    try layout.validate();
}

fn requireAcceptanceGenerationLayout(layout: *const GenerationLayout) OracleError!void {
    if (!std.mem.eql(u8, layout.root.slice(), acceptance.generation_root)) return error.GenerationLayoutInvalid;
    try layout.validate();
}

fn requireRetainedDiagnosticGenerationLayout(layout: *const GenerationLayout) OracleError!void {
    if (!std.mem.eql(u8, layout.root.slice(), retained_diagnostic_generation_root)) return error.GenerationLayoutInvalid;
    try layout.validate();
}

fn requireRetainedReferenceGenerationLayout(layout: *const GenerationLayout) OracleError!void {
    if (!std.mem.eql(u8, layout.root.slice(), retained_reference_generation_root)) return error.GenerationLayoutInvalid;
    try layout.validate();
}

fn isStrictDescendant(root: []const u8, path: []const u8) bool {
    return path.len > root.len and std.mem.startsWith(u8, path, root) and path[root.len] == '/';
}

const SourceProof = struct {
    definition_sha256: [Sha256.digest_length]u8,
    import_sha256: [Sha256.digest_length]u8,
    use_sha256: [Sha256.digest_length]u8,
    definition_count: usize,
    use_count: usize,
};

const DescriptorProof = struct {
    descriptor_sha256: [Sha256.digest_length]u8,
    function_type_sha256: [Sha256.digest_length]u8,
    instruction_count: usize,
    parameter_count: usize,
    return_bits: u16,
    calling_convention: CallingConvention,
};

const CallingConvention = enum {
    default,
    c,
};

const ExecutionBridgeFunction = fn () callconv(.{ .x86_64_sysv = .{} }) usize;

const BridgeResultType = enum {
    usize,
    u64,
};

const BridgeCallingConvention = enum {
    x86_64_sysv,
    c,
    auto,
};

const ExecutionBridgeContract = struct {
    target: []const u8,
    candidate_calling_convention: CallingConvention,
    parameter_count: usize,
    return_bits: u16,
    result_type: BridgeResultType,
    bridge_calling_convention: BridgeCallingConvention,
};

const ExecutionRecord = struct {
    termination: Termination,
    status: u8,
    stdout_sha256: [Sha256.digest_length]u8,
    stderr_sha256: [Sha256.digest_length]u8,
    stdout_length: usize,
    stderr_length: usize,
    semantic_result: usize,
    call_occurrence: bool,
};

const Termination = enum {
    exited,
    signaled,
    stopped,
    unknown,
};

const Counters = struct {
    real_functions_lowered: usize = 0,
    real_objects_emitted: usize = 0,
    real_native_linked: usize = 0,
    real_executed: usize = 0,
    real_programs_ok: usize = 0,
    local_fail: usize = 0,

    fn noteLowered(self: *Counters) void {
        self.real_functions_lowered += 1;
    }

    fn noteEmitted(self: *Counters) void {
        self.real_objects_emitted += 1;
    }

    fn noteLinked(self: *Counters) void {
        self.real_native_linked += 1;
    }

    fn noteBothExecuted(self: *Counters, reference: ExecutionRecord, linked: ExecutionRecord) OracleError!void {
        if (reference.termination != .exited or linked.termination != .exited or reference.status != 0 or linked.status != 0) {
            return error.ProcessInconsistent;
        }
        self.real_executed += 1;
    }

    fn noteOracleAccepted(self: *Counters, reference: ExecutionRecord, linked: ExecutionRecord) OracleError!void {
        if (self.real_executed != 1) return error.ProcessInconsistent;
        if (!reference.call_occurrence or !linked.call_occurrence) return error.CallOccurrenceMissing;
        if (!std.meta.eql(reference, linked)) return error.OracleMismatch;
        self.real_programs_ok += 1;
    }
};

const OracleOutcome = struct {
    selector_initial: ZigIdentity,
    selector_final: ZigIdentity,
    source_initial: SourceProof,
    source_final: SourceProof,
    descriptor_initial: DescriptorProof,
    descriptor_final: DescriptorProof,
    admission: CandidateAdmission,
    reference_record: ExecutionRecord,
    linked_record: ExecutionRecord,
    counters: Counters,
};

const OwnedProcessResult = struct {
    term: std.process.Child.Term,
    stdout: []u8,
    stderr: []u8,

    fn deinit(self: *OwnedProcessResult, allocator: std.mem.Allocator) void {
        allocator.free(self.stdout);
        allocator.free(self.stderr);
        self.* = undefined;
    }
};

const BuildPhase = enum(u8) {
    reference = 1,
    linked = 2,

    fn temporaryName(self: BuildPhase) []const u8 {
        return switch (self) {
            .reference => reference_build_frame_temporary,
            .linked => linked_build_frame_temporary,
        };
    }

    fn finalName(self: BuildPhase) []const u8 {
        return switch (self) {
            .reference => reference_build_frame_final,
            .linked => linked_build_frame_final,
        };
    }
};

const BuildTermination = enum(u8) {
    exited = 1,
    signal = 2,
    stopped = 3,
    unknown = 4,
};

const CanonicalBuildTermination = struct {
    kind: BuildTermination,
    status: u32,
};

const BuildPhaseFrame = struct {
    phase: BuildPhase,
    termination: BuildTermination,
    status: u32,
    stdout: []const u8,
    stderr: []const u8,
};

const OwnedBuildPhaseFrame = struct {
    bytes: []u8,
    frame: BuildPhaseFrame,

    fn deinit(self: *OwnedBuildPhaseFrame, allocator: std.mem.Allocator) void {
        allocator.free(self.bytes);
        self.* = undefined;
    }
};

const DiagnosticDisposition = enum {
    complete,
    omitted,
};

const BuildPhasePublicationStage = enum {
    none,
    temporary_created,
    temporary_synced,
    renamed,
    directory_synced,
    read_back_verified,
};

const VerifiedBuildPhasePublication = struct {
    phase: BuildPhase,
    stage: BuildPhasePublicationStage,
    exact_length: u64,
    sha256: [Sha256.digest_length]u8,
};

fn canonicalBuildTermination(term: std.process.Child.Term) CanonicalBuildTermination {
    return switch (term) {
        .exited => |status| .{ .kind = .exited, .status = status },
        .signal => |signal| .{ .kind = .signal, .status = @intFromEnum(signal) },
        .stopped => |signal| .{ .kind = .stopped, .status = @intFromEnum(signal) },
        .unknown => |status| .{ .kind = .unknown, .status = status },
    };
}

fn validateBuildPhaseFrameBounds(stdout_length: usize, stderr_length: usize) OracleError!usize {
    if (stdout_length > process_output_max or stderr_length > process_output_max) {
        return error.BuildPhaseFrameBoundExceeded;
    }
    const payload_length = std.math.add(usize, stdout_length, stderr_length) catch
        return error.BuildPhaseFrameBoundExceeded;
    return std.math.add(usize, build_phase_frame_header_size, payload_length) catch
        return error.BuildPhaseFrameBoundExceeded;
}

fn encodeBuildPhaseFrame(
    allocator: std.mem.Allocator,
    phase: BuildPhase,
    result: *const OwnedProcessResult,
) ![]u8 {
    const exact_length = try validateBuildPhaseFrameBounds(result.stdout.len, result.stderr.len);
    var encoded = try allocator.alloc(u8, exact_length);
    errdefer allocator.free(encoded);
    @memcpy(encoded[0..build_phase_frame_magic.len], build_phase_frame_magic);
    encoded[build_phase_frame_magic.len] = @intFromEnum(phase);
    const termination = canonicalBuildTermination(result.term);
    encoded[build_phase_frame_magic.len + 1] = @intFromEnum(termination.kind);
    encoded[build_phase_frame_magic.len + 2] = 0;
    encoded[build_phase_frame_magic.len + 3] = 0;
    std.mem.writeInt(u32, encoded[build_phase_frame_magic.len + 4 ..][0..4], termination.status, .little);
    std.mem.writeInt(u64, encoded[build_phase_frame_magic.len + 8 ..][0..8], @intCast(result.stdout.len), .little);
    std.mem.writeInt(u64, encoded[build_phase_frame_magic.len + 16 ..][0..8], @intCast(result.stderr.len), .little);
    const stdout_start = build_phase_frame_header_size;
    const stderr_start = stdout_start + result.stdout.len;
    @memcpy(encoded[stdout_start..stderr_start], result.stdout);
    @memcpy(encoded[stderr_start..], result.stderr);
    return encoded;
}

fn decodeBuildPhaseFrame(encoded: []const u8) OracleError!BuildPhaseFrame {
    if (encoded.len > build_phase_frame_max_bytes) return error.BuildPhaseFrameBoundExceeded;
    if (encoded.len < build_phase_frame_header_size or
        !std.mem.eql(u8, encoded[0..build_phase_frame_magic.len], build_phase_frame_magic) or
        encoded[build_phase_frame_magic.len + 2] != 0 or
        encoded[build_phase_frame_magic.len + 3] != 0)
    {
        return error.BuildPhaseFrameMalformed;
    }
    const phase = std.enums.fromInt(BuildPhase, encoded[build_phase_frame_magic.len]) orelse
        return error.BuildPhaseFrameMalformed;
    const termination = std.enums.fromInt(BuildTermination, encoded[build_phase_frame_magic.len + 1]) orelse
        return error.BuildPhaseFrameMalformed;
    const status = std.mem.readInt(u32, encoded[build_phase_frame_magic.len + 4 ..][0..4], .little);
    switch (termination) {
        .exited => if (status > std.math.maxInt(u8)) return error.BuildPhaseFrameMalformed,
        .signal, .stopped => _ = std.enums.fromInt(std.posix.SIG, status) orelse
            return error.BuildPhaseFrameMalformed,
        .unknown => {},
    }
    const stdout_u64 = std.mem.readInt(u64, encoded[build_phase_frame_magic.len + 8 ..][0..8], .little);
    const stderr_u64 = std.mem.readInt(u64, encoded[build_phase_frame_magic.len + 16 ..][0..8], .little);
    const stdout_length = std.math.cast(usize, stdout_u64) orelse return error.BuildPhaseFrameBoundExceeded;
    const stderr_length = std.math.cast(usize, stderr_u64) orelse return error.BuildPhaseFrameBoundExceeded;
    const exact_length = try validateBuildPhaseFrameBounds(stdout_length, stderr_length);
    if (encoded.len != exact_length) return error.BuildPhaseFrameMalformed;
    const stdout_start = build_phase_frame_header_size;
    const stderr_start = stdout_start + stdout_length;
    return .{
        .phase = phase,
        .termination = termination,
        .status = status,
        .stdout = encoded[stdout_start..stderr_start],
        .stderr = encoded[stderr_start..],
    };
}

fn requireBuildPhaseFrameBinding(
    frame: BuildPhaseFrame,
    phase: BuildPhase,
    result: *const OwnedProcessResult,
) OracleError!void {
    const termination = canonicalBuildTermination(result.term);
    if (frame.phase != phase or frame.termination != termination.kind or frame.status != termination.status or
        !std.mem.eql(u8, frame.stdout, result.stdout) or !std.mem.eql(u8, frame.stderr, result.stderr))
    {
        return error.BuildPhaseFrameReadBackMismatch;
    }
}

fn requireBuildPhaseFrameReadBack(
    expected: []const u8,
    observed: []const u8,
    phase: BuildPhase,
    result: *const OwnedProcessResult,
) OracleError!void {
    if (!std.mem.eql(u8, expected, observed)) return error.BuildPhaseFrameReadBackMismatch;
    const decoded = try decodeBuildPhaseFrame(observed);
    try requireBuildPhaseFrameBinding(decoded, phase, result);
}

fn terminationName(termination: BuildTermination) []const u8 {
    return switch (termination) {
        .exited => "exited",
        .signal => "signal",
        .stopped => "stopped",
        .unknown => "unknown",
    };
}

fn writeLowerHex(writer: *std.Io.Writer, bytes: []const u8) !void {
    const alphabet = "0123456789abcdef";
    var buffer: [4096]u8 = undefined;
    var offset: usize = 0;
    while (offset < bytes.len) {
        const count = @min(bytes.len - offset, buffer.len / 2);
        for (bytes[offset..][0..count], 0..) |byte, index| {
            buffer[index * 2] = alphabet[byte >> 4];
            buffer[index * 2 + 1] = alphabet[byte & 0x0f];
        }
        try writer.writeAll(buffer[0 .. count * 2]);
        offset += count;
    }
}

fn renderLinkedBuildFrame(
    writer: *std.Io.Writer,
    frame: BuildPhaseFrame,
) !DiagnosticDisposition {
    if (frame.phase != .linked) return error.DiagnosticFrameWrongPhase;
    const stdout_digest = sha256(frame.stdout);
    const stderr_digest = sha256(frame.stderr);
    const stdout_hex_digest = std.fmt.bytesToHex(stdout_digest, .lower);
    const stderr_hex_digest = std.fmt.bytesToHex(stderr_digest, .lower);
    var metadata_buffer: [512]u8 = undefined;
    const metadata = try std.fmt.bufPrint(
        &metadata_buffer,
        "linked_build_frame_diagnostic_v1\nphase=linked\ntermination={s}\nstatus={}\nstdout_length={}\nstdout_sha256={s}\nstderr_length={}\nstderr_sha256={s}\n",
        .{
            terminationName(frame.termination),
            frame.status,
            frame.stdout.len,
            &stdout_hex_digest,
            frame.stderr.len,
            &stderr_hex_digest,
        },
    );
    const complete_overhead = "content=complete\nstdout_hex=\nstderr_hex=\n".len;
    const stdout_rendered = std.math.mul(usize, frame.stdout.len, 2) catch diagnostic_render_max_bytes + 1;
    const stderr_rendered = std.math.mul(usize, frame.stderr.len, 2) catch diagnostic_render_max_bytes + 1;
    const combined_rendered = std.math.add(
        usize,
        metadata.len + complete_overhead,
        std.math.add(usize, stdout_rendered, stderr_rendered) catch diagnostic_render_max_bytes + 1,
    ) catch diagnostic_render_max_bytes + 1;
    const disposition: DiagnosticDisposition = if (frame.stdout.len <= diagnostic_stream_max_bytes and
        frame.stderr.len <= diagnostic_stream_max_bytes and combined_rendered <= diagnostic_render_max_bytes)
        .complete
    else
        .omitted;

    try writer.writeAll(metadata);
    switch (disposition) {
        .complete => {
            try writer.writeAll("content=complete\nstdout_hex=");
            try writeLowerHex(writer, frame.stdout);
            try writer.writeAll("\nstderr_hex=");
            try writeLowerHex(writer, frame.stderr);
            try writer.writeByte('\n');
        },
        .omitted => try writer.writeAll("content=omitted\nstdout_hex=omitted\nstderr_hex=omitted\n"),
    }
    return disposition;
}

fn requireCompleteDiagnostic(disposition: DiagnosticDisposition) OracleError!void {
    if (disposition == .omitted) return error.DiagnosticContentOmitted;
}

fn readLinkedBuildFrame(
    allocator: std.mem.Allocator,
    generation_directory: std.Io.Dir,
    io: std.Io,
    layout: *const GenerationLayout,
) !OwnedBuildPhaseFrame {
    try requireFixedGenerationLayout(layout);
    if (!std.mem.eql(u8, std.fs.path.basename(layout.linked_build_frame.slice()), linked_build_frame_final)) {
        return error.GenerationLayoutInvalid;
    }
    var file = try generation_directory.openFile(io, linked_build_frame_final, .{
        .mode = .read_only,
        .allow_directory = false,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer file.close(io);
    const metadata = try file.stat(io);
    if (metadata.kind != .file or metadata.size > build_phase_frame_max_bytes) {
        return error.BuildPhaseFrameBoundExceeded;
    }
    const exact_length = std.math.cast(usize, metadata.size) orelse return error.BuildPhaseFrameBoundExceeded;
    const bytes = try allocator.alloc(u8, exact_length);
    errdefer allocator.free(bytes);
    if (try file.readPositionalAll(io, bytes, 0) != exact_length) return error.BuildPhaseFrameReadBackMismatch;
    var trailing: [1]u8 = undefined;
    if (try file.readPositionalAll(io, &trailing, exact_length) != 0) return error.BuildPhaseFrameMalformed;
    const frame = try decodeBuildPhaseFrame(bytes);
    if (frame.phase != .linked) return error.DiagnosticFrameWrongPhase;
    return .{ .bytes = bytes, .frame = frame };
}

fn inspectLinkedBuildFrameInDirectory(
    allocator: std.mem.Allocator,
    generation_directory: std.Io.Dir,
    io: std.Io,
    layout: *const GenerationLayout,
    writer: *std.Io.Writer,
) !DiagnosticDisposition {
    var owned = try readLinkedBuildFrame(allocator, generation_directory, io, layout);
    defer owned.deinit(allocator);
    return renderLinkedBuildFrame(writer, owned.frame);
}

fn advanceBuildPhasePublication(
    stage: *BuildPhasePublicationStage,
    expected: BuildPhasePublicationStage,
    next: BuildPhasePublicationStage,
) OracleError!void {
    if (stage.* != expected) return error.BuildPhaseFramePublicationOrder;
    stage.* = next;
}

fn syncOwnedDirectory(directory: std.Io.Dir, io: std.Io) !void {
    const owned_directory_file = try directory.openFile(io, ".", .{
        .mode = .read_only,
        .allow_directory = true,
        .path_only = false,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer owned_directory_file.close(io);
    try owned_directory_file.sync(io);
}

fn publishBuildPhaseFrame(
    allocator: std.mem.Allocator,
    generation_directory: std.Io.Dir,
    io: std.Io,
    phase: BuildPhase,
    result: *const OwnedProcessResult,
) !VerifiedBuildPhasePublication {
    const encoded = try encodeBuildPhaseFrame(allocator, phase, result);
    defer allocator.free(encoded);
    _ = try decodeBuildPhaseFrame(encoded);
    var stage: BuildPhasePublicationStage = .none;

    var temporary_file = try generation_directory.createFile(io, phase.temporaryName(), .{
        .read = false,
        .truncate = false,
        .exclusive = true,
    });
    try advanceBuildPhasePublication(&stage, .none, .temporary_created);
    var temporary_open = true;
    defer if (temporary_open) temporary_file.close(io);
    try temporary_file.writeStreamingAll(io, encoded);
    try temporary_file.sync(io);
    try advanceBuildPhasePublication(&stage, .temporary_created, .temporary_synced);
    temporary_file.close(io);
    temporary_open = false;

    try generation_directory.renamePreserve(
        phase.temporaryName(),
        generation_directory,
        phase.finalName(),
        io,
    );
    try advanceBuildPhasePublication(&stage, .temporary_synced, .renamed);
    try syncOwnedDirectory(generation_directory, io);
    try advanceBuildPhasePublication(&stage, .renamed, .directory_synced);

    const final_file = try generation_directory.openFile(io, phase.finalName(), .{
        .mode = .read_only,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer final_file.close(io);
    const read_back = try allocator.alloc(u8, encoded.len);
    defer allocator.free(read_back);
    const count = try final_file.readPositionalAll(io, read_back, 0);
    if (count != encoded.len) return error.BuildPhaseFrameReadBackMismatch;
    var trailing: [1]u8 = undefined;
    if (try final_file.readPositionalAll(io, &trailing, encoded.len) != 0) {
        return error.BuildPhaseFrameReadBackMismatch;
    }
    try requireBuildPhaseFrameReadBack(encoded, read_back, phase, result);
    try advanceBuildPhasePublication(&stage, .directory_synced, .read_back_verified);
    return .{
        .phase = phase,
        .stage = stage,
        .exact_length = @intCast(encoded.len),
        .sha256 = sha256(encoded),
    };
}

fn persistBuildPhaseThenRequireSuccess(
    allocator: std.mem.Allocator,
    generation_directory: std.Io.Dir,
    io: std.Io,
    phase: BuildPhase,
    result: *const OwnedProcessResult,
) !VerifiedBuildPhasePublication {
    const publication = try publishBuildPhaseFrame(allocator, generation_directory, io, phase, result);
    try requireExitedZero(result.*);
    return publication;
}

fn syntheticLinkedBuildThenExecution(
    allocator: std.mem.Allocator,
    generation_directory: std.Io.Dir,
    io: std.Io,
    result: *const OwnedProcessResult,
    execution_count: *usize,
) !void {
    _ = try persistBuildPhaseThenRequireSuccess(allocator, generation_directory, io, .linked, result);
    execution_count.* += 1;
}

const ZigIdentity = struct {
    version: [version_max_bytes]u8,
    version_length: u8,
    length: u64,
    sha256: [Sha256.digest_length]u8,

    fn versionSlice(self: *const ZigIdentity) []const u8 {
        return self.version[0..self.version_length];
    }
};

const ExpectedExternalVersion = struct {
    bytes: [version_max_bytes]u8,
    length: u8,

    fn slice(self: *const ExpectedExternalVersion) []const u8 {
        return self.bytes[0..self.length];
    }
};

const CandidateClaim = struct {
    revision: []const u8,
    target: []const u8,
    definition: []const u8,
    function: []const u8,
    input_count: usize,
    result: usize,
};

const HarnessContract = struct {
    parameter_count: usize,
    return_bits: u16,
    calling_convention: CallingConvention,
    return_value_drives_output: bool,
};

const CandidateAdmission = struct {
    source: SourceProof,
    descriptor: DescriptorProof,
    harness: HarnessContract,
    bridge: ExecutionBridgeContract,
};

const ProcessBoundaryObservation = struct {
    launched: bool,
    termination: Termination,
    status: u8,
    stdout_length: usize,
    stderr_length: usize,
    exact_eof: bool,
};

fn openFixedGenerationV3AtRoot(root: std.Io.Dir, io: std.Io) !std.Io.Dir {
    var local_state = try root.openDir(io, "local-state", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer local_state.close(io);
    var validations = try local_state.openDir(io, "validations", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer validations.close(io);
    var inbox = try validations.openDir(io, "inbox206co", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer inbox.close(io);
    return inbox.openDir(io, "generation-v3", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
}

fn inspectRetainedGenerationV3LinkedFrame(
    allocator: std.mem.Allocator,
    io: std.Io,
    writer: *std.Io.Writer,
) !DiagnosticDisposition {
    const layout = try GenerationLayout.init(retained_diagnostic_generation_root);
    try requireRetainedDiagnosticGenerationLayout(&layout);
    var root = try std.Io.Dir.openDirAbsolute(io, repository_root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(io);
    var generation_directory = try openFixedGenerationV3AtRoot(root, io);
    defer generation_directory.close(io);
    return inspectLinkedBuildFrameInDirectory(allocator, generation_directory, io, &layout, writer);
}

const OwnedReferenceOutputs = struct {
    stdout: []u8,
    stderr: []u8,

    fn deinit(self: *OwnedReferenceOutputs, allocator: std.mem.Allocator) void {
        allocator.free(self.stdout);
        allocator.free(self.stderr);
        self.* = undefined;
    }
};

fn openFixedGenerationV4AtRoot(root: std.Io.Dir, io: std.Io) !std.Io.Dir {
    var local_state = try root.openDir(io, "local-state", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer local_state.close(io);
    var validations = try local_state.openDir(io, "validations", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer validations.close(io);
    var inbox = try validations.openDir(io, "inbox206co", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer inbox.close(io);
    return inbox.openDir(io, "generation-v4", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
}

fn readReferenceOutputOnce(
    allocator: std.mem.Allocator,
    generation_directory: std.Io.Dir,
    io: std.Io,
    name: []const u8,
) ![]u8 {
    var file = try generation_directory.openFile(io, name, .{
        .mode = .read_only,
        .allow_directory = false,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer file.close(io);
    const metadata = try file.stat(io);
    if (metadata.kind != .file or metadata.size > process_output_max) return error.ChildOutputBoundExceeded;
    const exact_length = std.math.cast(usize, metadata.size) orelse return error.ChildOutputBoundExceeded;
    const bytes = try allocator.alloc(u8, exact_length);
    errdefer allocator.free(bytes);
    if (try file.readPositionalAll(io, bytes, 0) != exact_length) return error.ProcessInconsistent;
    return bytes;
}

fn readReferenceOutputs(
    allocator: std.mem.Allocator,
    generation_directory: std.Io.Dir,
    io: std.Io,
    layout: *const GenerationLayout,
    expected_root: []const u8,
) !OwnedReferenceOutputs {
    if (!std.mem.eql(u8, layout.root.slice(), expected_root)) return error.GenerationLayoutInvalid;
    try layout.validate();
    const stdout_name = std.fs.path.basename(layout.reference_stdout.slice());
    const stderr_name = std.fs.path.basename(layout.reference_stderr.slice());
    if (!std.mem.eql(u8, stdout_name, "reference.stdout") or
        !std.mem.eql(u8, stderr_name, "reference.stderr"))
    {
        return error.GenerationLayoutInvalid;
    }
    const stdout = try readReferenceOutputOnce(allocator, generation_directory, io, stdout_name);
    errdefer allocator.free(stdout);
    const stderr = try readReferenceOutputOnce(allocator, generation_directory, io, stderr_name);
    return .{ .stdout = stdout, .stderr = stderr };
}

fn firstDifferingOffset(expected: []const u8, actual: []const u8) ?usize {
    const common_length = @min(expected.len, actual.len);
    for (expected[0..common_length], actual[0..common_length], 0..) |expected_byte, actual_byte, offset| {
        if (expected_byte != actual_byte) return offset;
    }
    return if (expected.len == actual.len) null else common_length;
}

fn renderReferenceOutputDiagnostic(
    writer: *std.Io.Writer,
    stdout: []const u8,
    stderr: []const u8,
) !DiagnosticDisposition {
    const expected_digest = std.fmt.bytesToHex(sha256(expected_execution_stdout), .lower);
    const stdout_digest = std.fmt.bytesToHex(sha256(stdout), .lower);
    const stderr_digest = std.fmt.bytesToHex(sha256(stderr), .lower);
    const difference = firstDifferingOffset(expected_execution_stdout, stdout);
    var difference_buffer: [32]u8 = undefined;
    const difference_text = if (difference) |offset|
        try std.fmt.bufPrint(&difference_buffer, "{}", .{offset})
    else
        "none";
    var metadata_buffer: [1024]u8 = undefined;
    const metadata = try std.fmt.bufPrint(
        &metadata_buffer,
        "reference_output_diagnostic_v1\nphase=reference\nexpected_record_sha256={s}\nstdout_length={}\nstdout_sha256={s}\nstderr_length={}\nstderr_sha256={s}\nstdout_equal={}\nstderr_empty={}\nfirst_differing_stdout_offset={s}\n",
        .{
            &expected_digest,
            stdout.len,
            &stdout_digest,
            stderr.len,
            &stderr_digest,
            std.mem.eql(u8, stdout, expected_execution_stdout),
            stderr.len == 0,
            difference_text,
        },
    );
    const complete_overhead = "content=complete\nstdout_hex=\nstderr_hex=\n".len;
    const stdout_rendered = std.math.mul(usize, stdout.len, 2) catch diagnostic_render_max_bytes + 1;
    const stderr_rendered = std.math.mul(usize, stderr.len, 2) catch diagnostic_render_max_bytes + 1;
    const combined_rendered = std.math.add(
        usize,
        metadata.len + complete_overhead,
        std.math.add(usize, stdout_rendered, stderr_rendered) catch diagnostic_render_max_bytes + 1,
    ) catch diagnostic_render_max_bytes + 1;
    const disposition: DiagnosticDisposition = if (stdout.len <= diagnostic_stream_max_bytes and
        stderr.len <= diagnostic_stream_max_bytes and combined_rendered <= diagnostic_render_max_bytes)
        .complete
    else
        .omitted;

    try writer.writeAll(metadata);
    switch (disposition) {
        .complete => {
            try writer.writeAll("content=complete\nstdout_hex=");
            try writeLowerHex(writer, stdout);
            try writer.writeAll("\nstderr_hex=");
            try writeLowerHex(writer, stderr);
            try writer.writeByte('\n');
        },
        .omitted => try writer.writeAll("content=omitted\nstdout_hex=omitted\nstderr_hex=omitted\n"),
    }
    return disposition;
}

fn inspectReferenceOutputsInDirectory(
    allocator: std.mem.Allocator,
    generation_directory: std.Io.Dir,
    io: std.Io,
    layout: *const GenerationLayout,
    expected_root: []const u8,
    writer: *std.Io.Writer,
) !DiagnosticDisposition {
    var outputs = try readReferenceOutputs(allocator, generation_directory, io, layout, expected_root);
    defer outputs.deinit(allocator);
    return renderReferenceOutputDiagnostic(writer, outputs.stdout, outputs.stderr);
}

fn inspectRetainedGenerationV4ReferenceOutputs(
    allocator: std.mem.Allocator,
    io: std.Io,
    writer: *std.Io.Writer,
) !DiagnosticDisposition {
    const layout = try GenerationLayout.init(retained_reference_generation_root);
    try requireRetainedReferenceGenerationLayout(&layout);
    var root = try std.Io.Dir.openDirAbsolute(io, repository_root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(io);
    var generation_directory = try openFixedGenerationV4AtRoot(root, io);
    defer generation_directory.close(io);
    return inspectReferenceOutputsInDirectory(
        allocator,
        generation_directory,
        io,
        &layout,
        retained_reference_generation_root,
        writer,
    );
}

pub fn main(init: std.process.Init) !void {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa);
    defer args.deinit();
    _ = args.next() orelse return error.InvalidArguments;
    const selector = args.next() orelse return error.InvalidArguments;
    if (std.mem.eql(u8, selector, linked_frame_inspector_mode)) {
        if (args.next() != null) return error.InvalidArguments;
        var stdout_buffer: [4096]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
        const disposition = try inspectRetainedGenerationV3LinkedFrame(
            init.gpa,
            init.io,
            &stdout_writer.interface,
        );
        try stdout_writer.interface.flush();
        try requireCompleteDiagnostic(disposition);
        return;
    }
    if (std.mem.eql(u8, selector, reference_output_inspector_mode)) {
        if (args.next() != null) return error.InvalidArguments;
        var stdout_buffer: [4096]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
        _ = try inspectRetainedGenerationV4ReferenceOutputs(
            init.gpa,
            init.io,
            &stdout_writer.interface,
        );
        try stdout_writer.interface.flush();
        return;
    }
    if (std.mem.eql(u8, selector, acceptance.dispatch_mode)) {
        const acceptance_selector = args.next() orelse return error.InvalidArguments;
        if (args.next() != null) return error.InvalidArguments;
        try runAcceptanceOracle(init.gpa, init.io, acceptance_selector);
        return;
    }
    if (args.next() != null) return error.InvalidArguments;
    try runRealOracle(init.gpa, init.io, selector);
}

comptime {
    if (builtin.zig_version.major != 0 or builtin.zig_version.minor != 16 or builtin.zig_version.patch != 0) {
        @compileError("execution-oracle-v1 controller requires exact Zig 0.16.0");
    }
}

fn runRealOracle(allocator: std.mem.Allocator, io: std.Io, selector: []const u8) !void {
    const outcome = try executeOracle(allocator, io, selector, generation_root);
    try writeSummary(io, &outcome);
}

fn executeOracle(
    allocator: std.mem.Allocator,
    io: std.Io,
    selector: []const u8,
    selected_generation_root: []const u8,
) !OracleOutcome {
    try requireAbsoluteSelector(selector);
    const layout = try GenerationLayout.init(selected_generation_root);
    if (std.mem.eql(u8, selected_generation_root, generation_root)) {
        try requireFixedGenerationLayout(&layout);
    } else if (std.mem.eql(u8, selected_generation_root, acceptance.generation_root)) {
        try requireAcceptanceGenerationLayout(&layout);
    } else {
        return error.GenerationLayoutInvalid;
    }
    try createFreshGeneration(std.Io.Dir.cwd(), io, &layout);
    const expected_external_version = try requireExternalRevisionAndVersion(allocator, io, &layout);
    var canonical_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const canonical_length = try std.Io.Dir.realPathFileAbsolute(io, selector, &canonical_buffer);
    const canonical_zig = canonical_buffer[0..canonical_length];
    const zig_identity = try observeZig(allocator, io, canonical_zig, expected_external_version.slice(), &layout);
    try requireStorageHeadroom(allocator, io, &layout);

    const source_proof = try proveCurrentSource(allocator, io);
    try exportFreshDescriptor(allocator, io, canonical_zig, &layout);
    try requireZigStable(zig_identity, try observeZig(allocator, io, canonical_zig, expected_external_version.slice(), &layout));
    if (!std.mem.eql(u8, layout.descriptorForRead(), layout.descriptorForAdmission())) return error.GenerationLayoutInvalid;
    const descriptor = try std.Io.Dir.cwd().readFileAlloc(io, layout.descriptorForRead(), allocator, .limited(descriptor_max_bytes));
    defer allocator.free(descriptor);
    const descriptor_proof = try proveDescriptor(allocator, descriptor);

    const admission = try admitCandidate(.{
        .revision = zig_revision,
        .target = execution_target,
        .definition = definition_path,
        .function = function_name,
        .input_count = 0,
        .result = expected_result,
    }, source_proof, descriptor_proof, .{
        .parameter_count = 0,
        .return_bits = 64,
        .calling_convention = .default,
        .return_value_drives_output = true,
    }, expectedExecutionBridge());
    try requireCandidateAdmission(admission);

    const filtered = try real_rows.extractOracleFunctionDescriptor(allocator, descriptor, function_name);
    defer allocator.free(filtered);
    var object_outcome = try real_rows.lowerOracleFunctionToObject(allocator, filtered);
    defer object_outcome.deinit(allocator);
    const object = switch (object_outcome) {
        .failure => return error.DescriptorInvalid,
        .success => |bytes| bytes,
    };
    var counters: Counters = .{};
    counters.noteLowered();
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = layout.object.slice(), .data = object });
    counters.noteEmitted();

    try writeHarnesses(io, admission, &layout);
    try buildReferenceExecutable(allocator, io, canonical_zig, &layout);
    try requireZigStable(zig_identity, try observeZig(allocator, io, canonical_zig, expected_external_version.slice(), &layout));
    try buildLinkedExecutable(allocator, io, canonical_zig, &layout);
    try requireZigStable(zig_identity, try observeZig(allocator, io, canonical_zig, expected_external_version.slice(), &layout));
    counters.noteLinked();
    var execution_environment = try closedEnvironment(allocator, false, &layout);
    defer execution_environment.deinit();
    const reference_executable = try BoundPath.absolute(&layout.reference_executable);
    const linked_executable = try BoundPath.absolute(&layout.linked_executable);
    var reference_result = try runBounded(allocator, io, &.{reference_executable.slice()}, &execution_environment);
    defer reference_result.deinit(allocator);
    var linked_result = try runBounded(allocator, io, &.{linked_executable.slice()}, &execution_environment);
    defer linked_result.deinit(allocator);
    try writeExecutionOutputs(io, &layout, reference_result, linked_result);
    const reference_record = try canonicalExecutionRecord(reference_result, admission);
    const linked_record = try canonicalExecutionRecord(linked_result, admission);
    try counters.noteBothExecuted(reference_record, linked_record);
    try counters.noteOracleAccepted(reference_record, linked_record);

    const final_external_version = try requireExternalRevisionAndVersion(allocator, io, &layout);
    if (!std.mem.eql(u8, expected_external_version.slice(), final_external_version.slice())) return error.ExternalVersionUnavailable;
    const final_zig_identity = try observeZig(allocator, io, canonical_zig, expected_external_version.slice(), &layout);
    try requireZigStable(zig_identity, final_zig_identity);
    const final_source_proof = try proveCurrentSource(allocator, io);
    if (!std.mem.eql(u8, layout.descriptorForAdmission(), layout.descriptorForFinalRead())) return error.GenerationLayoutInvalid;
    const final_descriptor = try std.Io.Dir.cwd().readFileAlloc(io, layout.descriptorForFinalRead(), allocator, .limited(descriptor_max_bytes));
    defer allocator.free(final_descriptor);
    const final_descriptor_proof = try proveDescriptor(allocator, final_descriptor);
    try requireCandidateStable(admission, final_source_proof, final_descriptor_proof, expectedExecutionBridge());

    return .{
        .selector_initial = zig_identity,
        .selector_final = final_zig_identity,
        .source_initial = source_proof,
        .source_final = final_source_proof,
        .descriptor_initial = descriptor_proof,
        .descriptor_final = final_descriptor_proof,
        .admission = admission,
        .reference_record = reference_record,
        .linked_record = linked_record,
        .counters = counters,
    };
}

fn writeSummary(io: std.Io, outcome: *const OracleOutcome) !void {
    var stdout_buffer: [4096]u8 = undefined;
    var writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    var source_hex: [Sha256.digest_length * 2]u8 = undefined;
    var descriptor_hex: [Sha256.digest_length * 2]u8 = undefined;
    var zig_hex: [Sha256.digest_length * 2]u8 = undefined;
    _ = std.fmt.bufPrint(&source_hex, "{x}", .{outcome.source_initial.definition_sha256}) catch unreachable;
    _ = std.fmt.bufPrint(&descriptor_hex, "{x}", .{outcome.descriptor_initial.descriptor_sha256}) catch unreachable;
    _ = std.fmt.bufPrint(&zig_hex, "{x}", .{outcome.selector_initial.sha256}) catch unreachable;
    try writer.interface.print(
        "summary {s} row={s} revision={s} definition={s} source_sha256={s} descriptor_sha256={s} instructions={} selector_version={s} selector_bytes={} selector_sha256={s} peak_storage_bytes={} peak_storage_files={} real_functions_lowered={} real_objects_emitted={} real_native_linked={} real_executed={} real_programs_ok={} local_fail={}\n",
        .{
            schema,
            function_name,
            zig_revision,
            definition_path,
            &source_hex,
            &descriptor_hex,
            outcome.descriptor_initial.instruction_count,
            outcome.selector_initial.versionSlice(),
            outcome.selector_initial.length,
            &zig_hex,
            peak_storage_bytes,
            peak_storage_files,
            outcome.counters.real_functions_lowered,
            outcome.counters.real_objects_emitted,
            outcome.counters.real_native_linked,
            outcome.counters.real_executed,
            outcome.counters.real_programs_ok,
            outcome.counters.local_fail,
        },
    );
    try writer.interface.flush();
}

fn decodeRevisionNibble(byte: u8) u8 {
    return switch (byte) {
        '0'...'9' => byte - '0',
        'a'...'f' => byte - 'a' + 10,
        else => unreachable,
    };
}

fn externalRevisionIdentity() acceptance.Identity20 {
    var result: acceptance.Identity20 = undefined;
    for (&result.bytes, 0..) |*byte, index| {
        byte.* = (decodeRevisionNibble(zig_revision[index * 2]) << 4) |
            decodeRevisionNibble(zig_revision[index * 2 + 1]);
    }
    return result;
}

fn acceptanceSelector(identity: ZigIdentity) !acceptance.SelectorIdentity {
    return acceptance.SelectorIdentity.init(identity.versionSlice(), identity.length, identity.sha256);
}

fn acceptanceSource(proof: SourceProof) acceptance.SourceEvidence {
    return .{
        .definition_sha256 = .{ .bytes = proof.definition_sha256 },
        .import_sha256 = .{ .bytes = proof.import_sha256 },
        .use_sha256 = .{ .bytes = proof.use_sha256 },
        .definition_count = @intCast(proof.definition_count),
        .use_count = @intCast(proof.use_count),
    };
}

fn acceptanceCandidateConvention(convention: CallingConvention) acceptance.CandidateConvention {
    return switch (convention) {
        .default => .default,
        .c => .c,
    };
}

fn acceptanceDescriptor(proof: DescriptorProof) acceptance.DescriptorEvidence {
    return .{
        .descriptor_sha256 = .{ .bytes = proof.descriptor_sha256 },
        .function_type_sha256 = .{ .bytes = proof.function_type_sha256 },
        .instruction_count = @intCast(proof.instruction_count),
        .parameter_count = @intCast(proof.parameter_count),
        .return_bits = proof.return_bits,
        .calling_convention = acceptanceCandidateConvention(proof.calling_convention),
    };
}

fn acceptanceTermination(termination: Termination) acceptance.Termination {
    return switch (termination) {
        .exited => .exited,
        .signaled => .signaled,
        .stopped => .stopped,
        .unknown => .unknown,
    };
}

fn acceptanceRecord(record: ExecutionRecord) acceptance.ExecutionRecord {
    return .{
        .termination = acceptanceTermination(record.termination),
        .status = record.status,
        .stdout_sha256 = .{ .bytes = record.stdout_sha256 },
        .stderr_sha256 = .{ .bytes = record.stderr_sha256 },
        .stdout_length = @intCast(record.stdout_length),
        .stderr_length = @intCast(record.stderr_length),
        .semantic_result = @intCast(record.semantic_result),
        .call_occurrence = record.call_occurrence,
    };
}

fn constructAcceptanceEvidence(outcome: *const OracleOutcome) !acceptance.RunEvidence {
    const proof = try deriveOracleAbiProof();
    try validateOracleAbiProof(execution_target, proof);
    return .{
        .external_revision = externalRevisionIdentity(),
        .selector_initial = try acceptanceSelector(outcome.selector_initial),
        .selector_final = try acceptanceSelector(outcome.selector_final),
        .source_initial = acceptanceSource(outcome.source_initial),
        .source_final = acceptanceSource(outcome.source_final),
        .descriptor_initial = acceptanceDescriptor(outcome.descriptor_initial),
        .descriptor_final = acceptanceDescriptor(outcome.descriptor_final),
        .admission = .{
            .target = .x86_64_linux_gnu,
            .candidate_calling_convention = acceptanceCandidateConvention(outcome.admission.descriptor.calling_convention),
            .parameter_count = @intCast(outcome.admission.harness.parameter_count),
            .return_bits = outcome.admission.harness.return_bits,
            .result_type = switch (outcome.admission.bridge.result_type) {
                .usize => .usize,
                .u64 => .u64,
            },
            .bridge_calling_convention = switch (outcome.admission.bridge.bridge_calling_convention) {
                .x86_64_sysv => .x86_64_sysv,
                .c => .c,
                .auto => .auto,
            },
            .return_value_drives_output = outcome.admission.harness.return_value_drives_output,
            .expected_result = expected_result,
            .planner_gpr_returns = @intCast(proof.gpr_returns),
            .planner_sse_returns = @intCast(proof.sse_returns),
            .planner_memory_return = proof.memory_return,
        },
        .reference_record = acceptanceRecord(outcome.reference_record),
        .linked_record = acceptanceRecord(outcome.linked_record),
        .counters = .{
            .real_functions_lowered = @intCast(outcome.counters.real_functions_lowered),
            .real_objects_emitted = @intCast(outcome.counters.real_objects_emitted),
            .real_native_linked = @intCast(outcome.counters.real_native_linked),
            .real_executed = @intCast(outcome.counters.real_executed),
            .real_programs_ok = @intCast(outcome.counters.real_programs_ok),
            .local_fail = @intCast(outcome.counters.local_fail),
        },
    };
}

fn runAcceptanceOracle(allocator: std.mem.Allocator, io: std.Io, selector: []const u8) !void {
    try requireAbsoluteSelector(selector);
    const initial = try acceptance.observeLiveClosure(allocator, io);
    const outcome = try executeOracle(allocator, io, selector, acceptance.generation_root);
    const final = try acceptance.observeLiveClosure(allocator, io);
    const evidence = try constructAcceptanceEvidence(&outcome);
    const layout = try GenerationLayout.init(acceptance.generation_root);
    try requireAcceptanceGenerationLayout(&layout);
    var generation_directory = try std.Io.Dir.cwd().openDir(io, layout.root.slice(), .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer generation_directory.close(io);
    _ = try acceptance.finalizeAndPublish(
        allocator,
        io,
        generation_directory,
        &initial,
        &final,
        &evidence,
    );
}

fn requireAbsoluteSelector(selector: []const u8) OracleError!void {
    if (!std.fs.path.isAbsolute(selector) or std.mem.eql(u8, selector, "zig") or std.mem.indexOfScalar(u8, selector, 0) != null) {
        return error.ZigSelectorInvalid;
    }
}

fn requireGenerationRootAbsent(parent: std.Io.Dir, io: std.Io, layout: *const GenerationLayout) !void {
    _ = parent.statFile(io, layout.root.slice(), .{ .follow_symlinks = false }) catch |failure| switch (failure) {
        error.FileNotFound => return,
        else => return failure,
    };
    return error.GenerationCollision;
}

fn createFreshGeneration(parent: std.Io.Dir, io: std.Io, layout: *const GenerationLayout) !void {
    try requireGenerationRootAbsent(parent, io, layout);
    parent.createDir(io, layout.root.slice(), .default_dir) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.GenerationCollision,
        else => return failure,
    };
    try parent.createDir(io, layout.local_cache.slice(), .default_dir);
    try parent.createDir(io, layout.global_cache.slice(), .default_dir);
    try parent.createDir(io, layout.home.slice(), .default_dir);
    try parent.createDir(io, layout.temporary.slice(), .default_dir);
}

fn markSyntheticLaunchAfterFreshness(
    parent: std.Io.Dir,
    io: std.Io,
    layout: *const GenerationLayout,
    launch_count: *usize,
) !void {
    try requireGenerationRootAbsent(parent, io, layout);
    launch_count.* += 1;
}

fn closedEnvironment(
    allocator: std.mem.Allocator,
    include_export: bool,
    layout: *const GenerationLayout,
) !std.process.Environ.Map {
    const home = try BoundPath.absolute(&layout.home);
    const temporary = try BoundPath.absolute(&layout.temporary);
    const local_cache = try BoundPath.absolute(&layout.local_cache);
    const global_cache = try BoundPath.absolute(&layout.global_cache);
    const descriptor = try BoundPath.absolute(&layout.descriptor);
    var environment = std.process.Environ.Map.init(allocator);
    errdefer environment.deinit();
    try environment.put("LC_ALL", "C");
    try environment.put("LANG", "C");
    try environment.put("TZ", "UTC0");
    try environment.put("HOME", home.slice());
    try environment.put("TMPDIR", temporary.slice());
    try environment.put("ZIG_LOCAL_CACHE_DIR", local_cache.slice());
    try environment.put("ZIG_GLOBAL_CACHE_DIR", global_cache.slice());
    try environment.put("GIT_OPTIONAL_LOCKS", "0");
    try environment.put("GIT_CONFIG_NOSYSTEM", "1");
    try environment.put("GIT_CONFIG_SYSTEM", "/dev/null");
    try environment.put("GIT_CONFIG_GLOBAL", "/dev/null");
    try environment.put("GIT_TERMINAL_PROMPT", "0");
    if (include_export) try environment.put("ZLLVM_AIR_EXPORT_PATH", descriptor.slice());
    return environment;
}

fn runBounded(
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

fn requireExitedZero(result: OwnedProcessResult) OracleError!void {
    switch (result.term) {
        .exited => |code| if (code != 0) return error.ChildFailed,
        else => return error.ChildFailed,
    }
}

fn observeZig(
    allocator: std.mem.Allocator,
    io: std.Io,
    canonical_path: []const u8,
    expected_version: []const u8,
    layout: *const GenerationLayout,
) !ZigIdentity {
    try requireAbsoluteSelector(canonical_path);
    var file = try std.Io.Dir.openFileAbsolute(io, canonical_path, .{ .mode = .read_only, .follow_symlinks = false });
    defer file.close(io);
    const metadata = try file.stat(io);
    if (metadata.kind != .file or
        (std.Io.File.Permissions.has_executable_bit and metadata.permissions.toMode() & 0o111 == 0) or
        metadata.size == 0 or metadata.size > zig_max_bytes)
    {
        return error.ZigExecutableInvalid;
    }
    var reader = file.reader(io, &.{});
    const bytes = try reader.interface.allocRemaining(allocator, .limited(zig_max_bytes));
    defer allocator.free(bytes);
    if (bytes.len != metadata.size) return error.ZigExecutableInvalid;
    var environment = try closedEnvironment(allocator, false, layout);
    defer environment.deinit();
    var version = try runBounded(allocator, io, &.{ canonical_path, "version" }, &environment);
    defer version.deinit(allocator);
    try requireExitedZero(version);
    try validateExactVersionOutput(expected_version, version.stdout, version.stderr);
    var identity: ZigIdentity = .{
        .version = [_]u8{0} ** version_max_bytes,
        .version_length = @intCast(expected_version.len),
        .length = metadata.size,
        .sha256 = sha256(bytes),
    };
    @memcpy(identity.version[0..expected_version.len], expected_version);
    return identity;
}

fn validateExactVersionOutput(expected: []const u8, stdout: []const u8, stderr: []const u8) OracleError!void {
    if (expected.len == 0 or expected.len > version_max_bytes or stdout.len != expected.len + 1 or
        stdout[expected.len] != '\n' or !std.mem.eql(u8, stdout[0..expected.len], expected) or stderr.len != 0)
    {
        return error.ZigVersionMismatch;
    }
}

fn requireZigStable(expected: ZigIdentity, observed: ZigIdentity) OracleError!void {
    if (!std.meta.eql(expected, observed)) return error.SelectorDrift;
}

fn requireExternalRevisionAndVersion(
    allocator: std.mem.Allocator,
    io: std.Io,
    layout: *const GenerationLayout,
) !ExpectedExternalVersion {
    var environment = try closedEnvironment(allocator, false, layout);
    defer environment.deinit();
    const prefix = [_][]const u8{
        "/usr/bin/git", "--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "core.untrackedCache=false", "-C", zig_repository_root,
    };
    const head_argv = prefix ++ [_][]const u8{ "rev-parse", "HEAD" };
    var head = try runBounded(allocator, io, &head_argv, &environment);
    defer head.deinit(allocator);
    try requireExitedZero(head);
    if (!std.mem.eql(u8, head.stdout, zig_revision ++ "\n")) return error.ExternalRevisionMismatch;
    const status_argv = prefix ++ [_][]const u8{ "status", "--porcelain=v1", "--untracked-files=all" };
    var status = try runBounded(allocator, io, &status_argv, &environment);
    defer status.deinit(allocator);
    try requireExitedZero(status);
    if (status.stdout.len != 0) return error.ExternalRepositoryDirty;

    const describe_argv = prefix ++ [_][]const u8{ "describe", "--match", "*.*.*", "--tags", "--abbrev=9" };
    var describe = try runBounded(allocator, io, &describe_argv, &environment);
    defer describe.deinit(allocator);
    try requireExitedZero(describe);
    if (describe.stderr.len != 0) return error.ExternalVersionUnavailable;

    var root = try std.Io.Dir.openDirAbsolute(io, zig_repository_root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(io);
    const build_source = try root.readFileAlloc(io, zig_build_path, allocator, .limited(source_max_bytes));
    defer allocator.free(build_source);
    return deriveExternalVersion(build_source, describe.stdout);
}

fn deriveExternalVersion(build_source: []const u8, describe_untrimmed: []const u8) OracleError!ExpectedExternalVersion {
    const prefix = "const zig_version: std.SemanticVersion = .{ .major = ";
    const minor_separator = ", .minor = ";
    const patch_separator = ", .patch = ";
    const suffix = " };";
    const declaration_start = std.mem.indexOf(u8, build_source, prefix) orelse return error.ExternalVersionUnavailable;
    if (std.mem.indexOfPos(u8, build_source, declaration_start + prefix.len, prefix) != null) return error.ExternalVersionUnavailable;
    const line_end = std.mem.indexOfScalarPos(u8, build_source, declaration_start, '\n') orelse return error.ExternalVersionUnavailable;
    const line = build_source[declaration_start..line_end];
    if (!std.mem.endsWith(u8, line, suffix)) return error.ExternalVersionUnavailable;
    const major_start = prefix.len;
    const minor_at = std.mem.indexOfPos(u8, line, major_start, minor_separator) orelse return error.ExternalVersionUnavailable;
    const minor_start = minor_at + minor_separator.len;
    const patch_at = std.mem.indexOfPos(u8, line, minor_start, patch_separator) orelse return error.ExternalVersionUnavailable;
    const patch_start = patch_at + patch_separator.len;
    const patch_end = line.len - suffix.len;
    const major = std.fmt.parseUnsigned(u32, line[major_start..minor_at], 10) catch return error.ExternalVersionUnavailable;
    const minor = std.fmt.parseUnsigned(u32, line[minor_start..patch_at], 10) catch return error.ExternalVersionUnavailable;
    const patch = std.fmt.parseUnsigned(u32, line[patch_start..patch_end], 10) catch return error.ExternalVersionUnavailable;
    const source_version: std.SemanticVersion = .{ .major = major, .minor = minor, .patch = patch };

    const describe = std.mem.trim(u8, describe_untrimmed, " \t\r\n");
    if (describe.len == 0 or std.mem.countScalar(u8, describe, '-') != 2) return error.ExternalVersionUnavailable;
    var parts = std.mem.splitScalar(u8, describe, '-');
    const ancestor_text = parts.first();
    const height = parts.next() orelse return error.ExternalVersionUnavailable;
    const git_id = parts.next() orelse return error.ExternalVersionUnavailable;
    if (parts.next() != null or height.len == 0 or git_id.len != 10 or git_id[0] != 'g') return error.ExternalVersionUnavailable;
    _ = std.fmt.parseUnsigned(u64, height, 10) catch return error.ExternalVersionUnavailable;
    for (git_id[1..]) |byte| {
        if (!std.ascii.isHex(byte) or std.ascii.isUpper(byte)) return error.ExternalVersionUnavailable;
    }
    const ancestor = std.SemanticVersion.parse(ancestor_text) catch return error.ExternalVersionUnavailable;
    if (source_version.order(ancestor) != .gt) return error.ExternalVersionUnavailable;

    var result: ExpectedExternalVersion = .{ .bytes = [_]u8{0} ** version_max_bytes, .length = 0 };
    const rendered = std.fmt.bufPrint(&result.bytes, "{}.{}.{}-dev.{s}+{s}", .{
        source_version.major,
        source_version.minor,
        source_version.patch,
        height,
        git_id[1..],
    }) catch return error.ExternalVersionUnavailable;
    result.length = @intCast(rendered.len);
    return result;
}

fn proveCurrentSource(allocator: std.mem.Allocator, io: std.Io) !SourceProof {
    var root = try std.Io.Dir.openDirAbsolute(io, zig_repository_root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(io);
    const definition = try root.readFileAlloc(io, definition_path, allocator, .limited(source_max_bytes));
    defer allocator.free(definition);
    const std_source = try root.readFileAlloc(io, std_path, allocator, .limited(source_max_bytes));
    defer allocator.free(std_source);
    const uses = try root.readFileAlloc(io, use_path, allocator, .limited(source_max_bytes));
    defer allocator.free(uses);
    return proveSourceBytes(allocator, definition, std_source, uses);
}

fn proveSourceBytes(
    allocator: std.mem.Allocator,
    definition: []const u8,
    std_source: []const u8,
    uses: []const u8,
) !SourceProof {
    const exact_import = "pub const coff = @import(\"coff.zig\");";
    const exact_use = "std.coff.Symbol.sizeOf()";
    try proveSymbolSizeOfAst(allocator, definition);
    if (countExact(std_source, exact_import) != 1) return error.SourceImportMismatch;
    const use_count = countExact(uses, exact_use);
    if (use_count != 4) return error.SourceUseMismatch;
    return .{
        .definition_sha256 = sha256(definition),
        .import_sha256 = sha256(std_source),
        .use_sha256 = sha256(uses),
        .definition_count = 1,
        .use_count = use_count,
    };
}

fn proveSymbolSizeOfAst(allocator: std.mem.Allocator, source: []const u8) !void {
    const sentinel = try allocator.dupeZ(u8, source);
    defer allocator.free(sentinel);
    var tree = try std.zig.Ast.parse(allocator, sentinel, .zig);
    defer tree.deinit(allocator);
    if (tree.errors.len != 0) return error.InvalidSourceDefinition;

    var symbol_count: usize = 0;
    var symbol_members: ?[]const std.zig.Ast.Node.Index = null;
    for (tree.rootDecls()) |decl| {
        if (functionName(&tree, decl)) |name| {
            if (std.mem.eql(u8, name, "sizeOf")) return error.InvalidSourceDefinition;
        }
        const var_decl = tree.fullVarDecl(decl) orelse continue;
        if (!std.mem.eql(u8, tree.tokenSlice(var_decl.ast.mut_token + 1), "Symbol")) continue;
        symbol_count += 1;
        if (symbol_count != 1) return error.SourceDefinitionDuplicate;
        if (tree.tokenTag(var_decl.ast.mut_token) != .keyword_const or
            var_decl.visib_token == null or tree.tokenTag(var_decl.visib_token.?) != .keyword_pub or
            var_decl.extern_export_token != null or var_decl.threadlocal_token != null or var_decl.comptime_token != null or
            var_decl.ast.type_node != .none or var_decl.ast.align_node != .none or var_decl.ast.addrspace_node != .none or
            var_decl.ast.section_node != .none)
        {
            return error.InvalidSourceDefinition;
        }
        const init = var_decl.ast.init_node.unwrap() orelse return error.InvalidSourceDefinition;
        var container_buffer: [2]std.zig.Ast.Node.Index = undefined;
        const container = tree.fullContainerDecl(&container_buffer, init) orelse return error.InvalidSourceDefinition;
        if (tree.tokenTag(container.ast.main_token) != .keyword_struct or container.layout_token != null or container.ast.arg != .none) {
            return error.InvalidSourceDefinition;
        }
        symbol_members = container.ast.members;
    }
    if (symbol_count == 0) return error.SourceDefinitionMissing;

    var method_count: usize = 0;
    for (symbol_members.?) |member| {
        if (functionName(&tree, member)) |name| {
            if (!std.mem.eql(u8, name, "sizeOf")) continue;
            method_count += 1;
            if (method_count != 1) return error.SourceDefinitionDuplicate;
            try proveSizeOfMethod(&tree, member);
            continue;
        }
        if (containsNestedFunctionNamed(&tree, member, "sizeOf")) return error.InvalidSourceDefinition;
    }
    if (method_count == 0) return error.SourceDefinitionMissing;
}

fn functionName(tree: *const std.zig.Ast, node: std.zig.Ast.Node.Index) ?[]const u8 {
    var proto_buffer: [1]std.zig.Ast.Node.Index = undefined;
    const proto = tree.fullFnProto(&proto_buffer, node) orelse return null;
    const name_token = proto.name_token orelse return null;
    return tree.tokenSlice(name_token);
}

fn containsNestedFunctionNamed(tree: *const std.zig.Ast, node: std.zig.Ast.Node.Index, name: []const u8) bool {
    const var_decl = tree.fullVarDecl(node) orelse return false;
    const init = var_decl.ast.init_node.unwrap() orelse return false;
    var container_buffer: [2]std.zig.Ast.Node.Index = undefined;
    const container = tree.fullContainerDecl(&container_buffer, init) orelse return false;
    for (container.ast.members) |member| {
        if (functionName(tree, member)) |member_name| {
            if (std.mem.eql(u8, member_name, name)) return true;
        }
        if (containsNestedFunctionNamed(tree, member, name)) return true;
    }
    return false;
}

fn proveSizeOfMethod(tree: *const std.zig.Ast, node: std.zig.Ast.Node.Index) OracleError!void {
    if (tree.nodeTag(node) != .fn_decl) return error.InvalidSourceDefinition;
    var proto_buffer: [1]std.zig.Ast.Node.Index = undefined;
    const proto = tree.fullFnProto(&proto_buffer, node) orelse return error.InvalidSourceDefinition;
    if (proto.visib_token == null or tree.tokenTag(proto.visib_token.?) != .keyword_pub or
        proto.extern_export_inline_token != null or proto.lib_name != null or
        proto.ast.align_expr != .none or proto.ast.addrspace_expr != .none or proto.ast.section_expr != .none or
        proto.ast.callconv_expr != .none)
    {
        return error.InvalidSourceDefinition;
    }
    var params = proto.iterate(tree);
    if (params.next() != null) return error.InvalidSourceDefinition;
    const return_type = proto.ast.return_type.unwrap() orelse return error.InvalidSourceDefinition;
    if (tree.nodeTag(return_type) != .identifier or
        !std.mem.eql(u8, tree.tokenSlice(tree.nodeMainToken(return_type)), "usize"))
    {
        return error.InvalidSourceDefinition;
    }

    const body = tree.nodeData(node).node_and_node[1];
    var statement_buffer: [2]std.zig.Ast.Node.Index = undefined;
    const statements = tree.blockStatements(&statement_buffer, body) orelse return error.InvalidSourceDefinition;
    if (statements.len != 1 or tree.nodeTag(statements[0]) != .@"return") return error.InvalidSourceDefinition;
    const operand = tree.nodeData(statements[0]).opt_node.unwrap() orelse return error.InvalidSourceDefinition;
    if (tree.nodeTag(operand) != .number_literal) return error.InvalidSourceDefinition;
    switch (std.zig.parseNumberLiteral(tree.tokenSlice(tree.nodeMainToken(operand)))) {
        .int => |value| if (value != expected_result) return error.InvalidSourceDefinition,
        else => return error.InvalidSourceDefinition,
    }
}

fn proveDescriptor(allocator: std.mem.Allocator, descriptor: []const u8) !DescriptorProof {
    var module = try air_export.parse(allocator, descriptor);
    defer module.deinit();
    var found: ?air_export.Function = null;
    var count: usize = 0;
    for (module.functions) |function| {
        if (!std.mem.eql(u8, function.name, function_name)) continue;
        count += 1;
        found = function;
    }
    if (count == 0) return error.AirBindingMissing;
    if (count != 1) return error.AirBindingDuplicate;
    const function = found.?;
    var function_type = try air_types.parseFunctionType(allocator, function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 0 or function_type.c_calling_convention or function_type.non_default_calling_convention or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }))
    {
        return error.AbiMismatch;
    }
    if (function.instruction_count == 0 or function.structured_air_v2 == null) return error.DescriptorInvalid;
    return .{
        .descriptor_sha256 = sha256(descriptor),
        .function_type_sha256 = sha256(function.type_text),
        .instruction_count = function.instruction_count,
        .parameter_count = function_type.params.len,
        .return_bits = 64,
        .calling_convention = .default,
    };
}

fn expectedExecutionBridge() ExecutionBridgeContract {
    return .{
        .target = execution_target,
        .candidate_calling_convention = .default,
        .parameter_count = 0,
        .return_bits = 64,
        .result_type = .usize,
        .bridge_calling_convention = .x86_64_sysv,
    };
}

fn executionBridgeEqual(a: ExecutionBridgeContract, b: ExecutionBridgeContract) bool {
    return std.mem.eql(u8, a.target, b.target) and
        a.candidate_calling_convention == b.candidate_calling_convention and
        a.parameter_count == b.parameter_count and
        a.return_bits == b.return_bits and
        a.result_type == b.result_type and
        a.bridge_calling_convention == b.bridge_calling_convention;
}

fn canonicalSupportedTarget(text: []const u8) OracleError!project_target.SupportedTarget {
    var parts = std.mem.splitScalar(u8, text, '-');
    const arch = parts.next() orelse return error.CandidateBindingMismatch;
    const os = parts.next() orelse return error.CandidateBindingMismatch;
    const abi = parts.next() orelse return error.CandidateBindingMismatch;
    if (parts.next() != null or arch.len == 0 or os.len == 0 or abi.len == 0) {
        return error.CandidateBindingMismatch;
    }
    var canonical_buffer: [128]u8 = undefined;
    const canonical = std.fmt.bufPrint(&canonical_buffer, "{s}-unknown-{s}-{s}", .{ arch, os, abi }) catch
        return error.CandidateBindingMismatch;
    const parsed = project_target.Triple.parse(canonical) catch return error.CandidateBindingMismatch;
    return parsed.supportedTarget() orelse error.CandidateBindingMismatch;
}

fn validateOracleAbiProof(target_text: []const u8, proof: real_rows.OracleAbiProof) OracleError!void {
    const canonical_target = try canonicalSupportedTarget(target_text);
    if (canonical_target != .x86_64_linux_gnu or
        proof.supported_target != canonical_target or
        proof.parameter_count != 0 or
        proof.return_shape != .integer or
        proof.return_bits != 64 or
        proof.gpr_returns != 1 or
        proof.sse_returns != 0 or
        proof.memory_return)
    {
        return error.CandidateBindingMismatch;
    }
}

fn deriveOracleAbiProof() OracleError!real_rows.OracleAbiProof {
    const proof = real_rows.oracleAbiProof() catch return error.CandidateBindingMismatch;
    return proof;
}

fn validateExecutionBridgeAgainstProof(
    bridge: ExecutionBridgeContract,
    descriptor: DescriptorProof,
    harness: HarnessContract,
    proof: real_rows.OracleAbiProof,
) OracleError!void {
    const function_info = @typeInfo(ExecutionBridgeFunction).@"fn";
    try validateOracleAbiProof(bridge.target, proof);
    if (function_info.params.len != 0 or
        function_info.return_type == null or function_info.return_type.? != usize or
        !std.builtin.CallingConvention.eql(function_info.calling_convention, .{ .x86_64_sysv = .{} }) or
        !executionBridgeEqual(bridge, expectedExecutionBridge()) or
        bridge.candidate_calling_convention != descriptor.calling_convention or
        bridge.candidate_calling_convention != harness.calling_convention or
        bridge.parameter_count != descriptor.parameter_count or
        bridge.parameter_count != harness.parameter_count or
        bridge.return_bits != descriptor.return_bits or
        bridge.return_bits != harness.return_bits)
    {
        return error.CandidateBindingMismatch;
    }
}

fn validateExecutionBridge(
    bridge: ExecutionBridgeContract,
    descriptor: DescriptorProof,
    harness: HarnessContract,
) OracleError!void {
    try validateExecutionBridgeAgainstProof(bridge, descriptor, harness, try deriveOracleAbiProof());
}

fn admitCandidate(
    claim: CandidateClaim,
    source: SourceProof,
    descriptor: DescriptorProof,
    harness: HarnessContract,
    bridge: ExecutionBridgeContract,
) OracleError!CandidateAdmission {
    if (!std.mem.eql(u8, claim.revision, zig_revision) or
        !std.mem.eql(u8, claim.target, execution_target) or
        !std.mem.eql(u8, claim.definition, definition_path) or
        !std.mem.eql(u8, claim.function, function_name) or
        claim.input_count != 0 or claim.result != expected_result or
        descriptor.parameter_count != claim.input_count or
        descriptor.return_bits != harness.return_bits or
        descriptor.calling_convention != harness.calling_convention or
        harness.parameter_count != claim.input_count or
        !harness.return_value_drives_output)
    {
        return error.CandidateBindingMismatch;
    }
    try validateExecutionBridge(bridge, descriptor, harness);
    return .{
        .source = source,
        .descriptor = descriptor,
        .harness = harness,
        .bridge = bridge,
    };
}

fn requireCandidateAdmission(admission: ?CandidateAdmission) OracleError!void {
    if (admission == null) return error.CandidateAdmissionMissing;
    try validateExecutionBridge(admission.?.bridge, admission.?.descriptor, admission.?.harness);
}

fn requireCandidateStable(
    admission: CandidateAdmission,
    source: SourceProof,
    descriptor: DescriptorProof,
    bridge: ExecutionBridgeContract,
) OracleError!void {
    if (!std.meta.eql(admission.source, source) or
        !std.meta.eql(admission.descriptor, descriptor) or
        !executionBridgeEqual(admission.bridge, bridge) or
        admission.harness.parameter_count != descriptor.parameter_count or
        admission.harness.return_bits != descriptor.return_bits or
        admission.harness.calling_convention != descriptor.calling_convention)
    {
        return error.CandidateBindingMismatch;
    }
    try validateExecutionBridge(bridge, descriptor, admission.harness);
}

fn exportFreshDescriptor(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_path: []const u8,
    layout: *const GenerationLayout,
) !void {
    var environment = try closedEnvironment(allocator, true, layout);
    defer environment.deinit();
    const local_cache = try BoundPath.absolute(&layout.local_cache);
    const argv = [_][]const u8{
        zig_path,
        "build",
        "--build-file",
        zig_repository_root ++ "/build.zig",
        "--cache-dir",
        local_cache.slice(),
        "-Dno-bin",
        "-Dno-lib",
        "-Dno-langref",
        "-Ddebug-extensions=true",
        "-Dtarget=x86_64-linux-gnu",
        "-Doptimize=ReleaseFast",
    };
    var result = try runBounded(allocator, io, &argv, &environment);
    defer result.deinit(allocator);
    try requireExitedZero(result);
}

fn requireStorageHeadroom(
    allocator: std.mem.Allocator,
    io: std.Io,
    layout: *const GenerationLayout,
) !void {
    var environment = try closedEnvironment(allocator, false, layout);
    defer environment.deinit();
    const root = try BoundPath.absolute(&layout.root);
    const argv = [_][]const u8{ "/usr/bin/df", "--output=avail", "--block-size=1", root.slice() };
    var result = try runBounded(allocator, io, &argv, &environment);
    defer result.deinit(allocator);
    try requireExitedZero(result);
    var lines = std.mem.tokenizeAny(u8, result.stdout, " \t\r\n");
    _ = lines.next() orelse return error.InsufficientStorage;
    const available_text = lines.next() orelse return error.InsufficientStorage;
    if (lines.next() != null) return error.InsufficientStorage;
    const available = std.fmt.parseUnsigned(u64, available_text, 10) catch return error.InsufficientStorage;
    if (available < peak_storage_bytes) return error.InsufficientStorage;
}

const reference_harness_source =
    \\const std = @import("std");
    \\pub fn main(init: std.process.Init) !void {
    \\    const result: usize = 18;
    \\    const witness = result *% 3 +% 7;
    \\    var buffer: [128]u8 = undefined;
    \\    var writer = std.Io.File.stdout().writer(init.io, &buffer);
    \\    try writer.interface.print("execution-oracle-v1 result={} witness={}\n", .{ result, witness });
    \\    try writer.interface.flush();
    \\}
    \\
;

const linked_harness_source =
    \\const std = @import("std");
    \\const size_of = @extern(*const fn () callconv(.{ .x86_64_sysv = .{} }) usize, .{ .name = "coff.Symbol.sizeOf" });
    \\pub fn main(init: std.process.Init) !void {
    \\    const result = size_of();
    \\    const witness = result *% 3 +% 7;
    \\    var buffer: [128]u8 = undefined;
    \\    var writer = std.Io.File.stdout().writer(init.io, &buffer);
    \\    try writer.interface.print("execution-oracle-v1 result={} witness={}\n", .{ result, witness });
    \\    try writer.interface.flush();
    \\}
    \\
;

fn proveHarnessNewlineAst(allocator: std.mem.Allocator, source: []const u8) !void {
    const sentinel = try allocator.dupeZ(u8, source);
    defer allocator.free(sentinel);
    var tree = try std.zig.Ast.parse(allocator, sentinel, .zig);
    defer tree.deinit(allocator);
    if (tree.errors.len != 0 or
        countExact(source, "witness={}\\n") != 1 or
        countExact(source, "witness={}\\\\n") != 0)
    {
        return error.CandidateBindingMismatch;
    }
}

fn proveReferenceHarnessAst(allocator: std.mem.Allocator, source: []const u8) !void {
    if (!std.mem.eql(u8, source, reference_harness_source)) return error.CandidateBindingMismatch;
    try proveHarnessNewlineAst(allocator, source);
}

fn proveLinkedHarnessAst(allocator: std.mem.Allocator, source: []const u8) !void {
    if (!std.mem.eql(u8, source, linked_harness_source)) return error.CandidateBindingMismatch;
    try proveHarnessNewlineAst(allocator, source);
    const sentinel = try allocator.dupeZ(u8, source);
    defer allocator.free(sentinel);
    var tree = try std.zig.Ast.parse(allocator, sentinel, .zig);
    defer tree.deinit(allocator);
    if (tree.errors.len != 0) return error.CandidateBindingMismatch;

    var bridge_declarations: usize = 0;
    for (tree.rootDecls()) |decl| {
        const var_decl = tree.fullVarDecl(decl) orelse continue;
        if (!std.mem.eql(u8, tree.tokenSlice(var_decl.ast.mut_token + 1), "size_of")) continue;
        bridge_declarations += 1;
        if (var_decl.ast.type_node != .none or var_decl.ast.init_node == .none) {
            return error.CandidateBindingMismatch;
        }
    }
    if (bridge_declarations != 1 or countExact(source, "@extern(") != 1 or
        countExact(source, "callconv(.{ .x86_64_sysv = .{} })") != 1)
    {
        return error.CandidateBindingMismatch;
    }
}

fn writeHarnesses(io: std.Io, admission: CandidateAdmission, layout: *const GenerationLayout) !void {
    try requireCandidateAdmission(admission);
    try proveReferenceHarnessAst(std.heap.page_allocator, reference_harness_source);
    try proveLinkedHarnessAst(std.heap.page_allocator, linked_harness_source);
    const cwd = std.Io.Dir.cwd();
    try cwd.writeFile(io, .{ .sub_path = layout.reference_source.slice(), .data = reference_harness_source });
    try cwd.writeFile(io, .{ .sub_path = layout.linked_source.slice(), .data = linked_harness_source });
}

fn buildReferenceExecutable(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_path: []const u8,
    layout: *const GenerationLayout,
) !void {
    var environment = try closedEnvironment(allocator, false, layout);
    defer environment.deinit();
    const source = try BoundPath.absolute(&layout.reference_source);
    const executable = try BoundPath.absolute(&layout.reference_executable);
    var reference_emit_buffer: [std.Io.Dir.max_path_bytes + 32]u8 = undefined;
    const reference_emit = try std.fmt.bufPrint(&reference_emit_buffer, "-femit-bin={s}", .{executable.slice()});
    const reference_argv = [_][]const u8{
        zig_path, "build-exe", source.slice(), "-OReleaseFast", reference_emit,
    };
    var reference = try runBounded(allocator, io, &reference_argv, &environment);
    defer reference.deinit(allocator);
    var generation_directory = try std.Io.Dir.cwd().openDir(io, layout.root.slice(), .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer generation_directory.close(io);
    _ = try persistBuildPhaseThenRequireSuccess(
        allocator,
        generation_directory,
        io,
        .reference,
        &reference,
    );
}

fn buildLinkedExecutable(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_path: []const u8,
    layout: *const GenerationLayout,
) !void {
    var environment = try closedEnvironment(allocator, false, layout);
    defer environment.deinit();
    const source = try BoundPath.absolute(&layout.linked_source);
    const object = try BoundPath.absolute(&layout.object);
    const executable = try BoundPath.absolute(&layout.linked_executable);
    var linked_emit_buffer: [std.Io.Dir.max_path_bytes + 32]u8 = undefined;
    const linked_emit = try std.fmt.bufPrint(&linked_emit_buffer, "-femit-bin={s}", .{executable.slice()});
    const linked_argv = [_][]const u8{
        zig_path,
        "build-exe",
        "-fno-lld",
        source.slice(),
        object.slice(),
        "-OReleaseFast",
        linked_emit,
    };
    var linked = try runBounded(allocator, io, &linked_argv, &environment);
    defer linked.deinit(allocator);
    var generation_directory = try std.Io.Dir.cwd().openDir(io, layout.root.slice(), .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer generation_directory.close(io);
    _ = try persistBuildPhaseThenRequireSuccess(
        allocator,
        generation_directory,
        io,
        .linked,
        &linked,
    );
}

fn writeExecutionOutputs(
    io: std.Io,
    layout: *const GenerationLayout,
    reference: OwnedProcessResult,
    linked: OwnedProcessResult,
) !void {
    const cwd = std.Io.Dir.cwd();
    try cwd.writeFile(io, .{ .sub_path = layout.reference_stdout.slice(), .data = reference.stdout });
    try cwd.writeFile(io, .{ .sub_path = layout.reference_stderr.slice(), .data = reference.stderr });
    try cwd.writeFile(io, .{ .sub_path = layout.linked_stdout.slice(), .data = linked.stdout });
    try cwd.writeFile(io, .{ .sub_path = layout.linked_stderr.slice(), .data = linked.stderr });
}

fn canonicalExecutionRecord(result: OwnedProcessResult, admission: CandidateAdmission) OracleError!ExecutionRecord {
    try requireCandidateAdmission(admission);
    if (!admission.harness.return_value_drives_output) return error.CallOccurrenceMissing;
    const termination: Termination, const status: u8 = switch (result.term) {
        .exited => |code| .{ .exited, code },
        .signal => .{ .signaled, 0 },
        .stopped => .{ .stopped, 0 },
        .unknown => .{ .unknown, 0 },
    };
    try validateProcessBoundary(.{
        .launched = true,
        .termination = termination,
        .status = status,
        .stdout_length = result.stdout.len,
        .stderr_length = result.stderr.len,
        .exact_eof = true,
    });
    if (!std.mem.eql(u8, result.stdout, expected_execution_stdout) or result.stderr.len != 0) {
        return error.ProcessInconsistent;
    }
    return .{
        .termination = termination,
        .status = status,
        .stdout_sha256 = sha256(result.stdout),
        .stderr_sha256 = sha256(result.stderr),
        .stdout_length = result.stdout.len,
        .stderr_length = result.stderr.len,
        .semantic_result = expected_result,
        .call_occurrence = true,
    };
}

fn validateProcessBoundary(observation: ProcessBoundaryObservation) OracleError!void {
    if (!observation.launched or observation.termination != .exited or observation.status != 0 or !observation.exact_eof) {
        return error.ProcessInconsistent;
    }
    if (observation.stdout_length > process_output_max or observation.stderr_length > process_output_max) {
        return error.ChildOutputBoundExceeded;
    }
}

fn sha256(bytes: []const u8) [Sha256.digest_length]u8 {
    var digest: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(bytes, &digest, .{});
    return digest;
}

fn countExact(haystack: []const u8, needle: []const u8) usize {
    var count: usize = 0;
    var start: usize = 0;
    while (std.mem.indexOfPos(u8, haystack, start, needle)) |index| {
        count += 1;
        start = index + needle.len;
    }
    return count;
}

fn syntheticRecord(status: u8, result: usize, called: bool) ExecutionRecord {
    const stdout = "execution-oracle-v1 result=18 witness=61\n";
    return .{
        .termination = .exited,
        .status = status,
        .stdout_sha256 = sha256(stdout),
        .stderr_sha256 = sha256(""),
        .stdout_length = stdout.len,
        .stderr_length = 0,
        .semantic_result = result,
        .call_occurrence = called,
    };
}

fn syntheticDescriptor(
    allocator: std.mem.Allocator,
    names: []const []const u8,
    function_type: []const u8,
) ![]u8 {
    const air_text = "  %0!= ret(<usize, 18>)\n";
    const structured_v2 =
        "structured_air-v2\n" ++
        "typed_inst|0|ret|8|noreturn|un_op|1|const|2|18|5|usize\n" ++
        "structured_air_v2_end\n";
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    const header = try std.fmt.allocPrint(
        allocator,
        "zllvm-air-export-v1\ncontract_version=1\npayload=zig-air-print-v1\nproducer=test\nroot_source=test.zig\nwrapper=test.zig\nmode=ReleaseFast\ntarget=x86_64-linux-gnu\nfunction_count={}\nglobal_count=0\n",
        .{names.len},
    );
    defer allocator.free(header);
    try output.appendSlice(allocator, header);
    for (names) |name| {
        const frame = try std.fmt.allocPrint(
            allocator,
            "function_begin\nname_bytes={}\n{s}\ntype_bytes={}\n{s}\ninstruction_count=1\nmain_body_count=1\nliveness=present\nair_bytes={}\n{s}\nstructured_air_v2_bytes={}\n{s}\nfunction_end\n",
            .{ name.len, name, function_type.len, function_type, air_text.len, air_text, structured_v2.len, structured_v2 },
        );
        defer allocator.free(frame);
        try output.appendSlice(allocator, frame);
    }
    return output.toOwnedSlice(allocator);
}

test "ownership-aware source admission accepts a sibling sizeOf decoy" {
    const allocator = std.testing.allocator;
    const definition =
        "pub const Symbol = struct {\n" ++
        "    pub fn sizeOf() usize {\n" ++
        "        return 18;\n" ++
        "    }\n" ++
        "};\n" ++
        "pub const WeakExternalDefinition = struct {\n" ++
        "    pub fn sizeOf() usize {\n" ++
        "        return 18;\n" ++
        "    }\n" ++
        "};\n";
    const import_line = "pub const coff = @import(\"coff.zig\");";
    const uses = "std.coff.Symbol.sizeOf() std.coff.Symbol.sizeOf() std.coff.Symbol.sizeOf() std.coff.Symbol.sizeOf()";
    const proof = try proveSourceBytes(allocator, definition, import_line, uses);
    try std.testing.expectEqual(@as(usize, 1), proof.definition_count);
    try std.testing.expectEqual(@as(usize, 4), proof.use_count);
    try std.testing.expectError(error.SourceImportMismatch, proveSourceBytes(allocator, definition, "", uses));
    try std.testing.expectError(error.SourceUseMismatch, proveSourceBytes(allocator, definition, import_line, "std.coff.Symbol.sizeOf()"));
}

test "ownership-aware source admission rejects every structural and semantic drift" {
    const allocator = std.testing.allocator;
    const valid =
        "pub const Symbol = struct {\n" ++
        "    pub fn sizeOf() usize {\n" ++
        "        return 18;\n" ++
        "    }\n" ++
        "};\n";
    try proveSymbolSizeOfAst(allocator, valid);
    try std.testing.expectError(error.InvalidSourceDefinition, proveSymbolSizeOfAst(allocator, "pub const Symbol = struct {"));
    try std.testing.expectError(error.SourceDefinitionMissing, proveSymbolSizeOfAst(allocator, "pub const Other = struct {};\n"));
    try std.testing.expectError(error.SourceDefinitionDuplicate, proveSymbolSizeOfAst(allocator, valid ++ valid));
    try std.testing.expectError(error.SourceDefinitionMissing, proveSymbolSizeOfAst(allocator, "pub const Symbol = struct { pub fn other() usize { return 18; } };\n"));
    try std.testing.expectError(error.SourceDefinitionDuplicate, proveSymbolSizeOfAst(allocator, "pub const Symbol = struct { pub fn sizeOf() usize { return 18; } pub fn sizeOf() usize { return 18; } };\n"));
    try std.testing.expectError(error.InvalidSourceDefinition, proveSymbolSizeOfAst(allocator, valid ++ "pub fn sizeOf() usize { return 18; }\n"));
    try std.testing.expectError(error.InvalidSourceDefinition, proveSymbolSizeOfAst(allocator, "pub const Symbol = struct { const Nested = struct { pub fn sizeOf() usize { return 18; } }; };\n"));
    try std.testing.expectError(error.InvalidSourceDefinition, proveSymbolSizeOfAst(allocator, "const Symbol = struct { pub fn sizeOf() usize { return 18; } };\n"));
    try std.testing.expectError(error.InvalidSourceDefinition, proveSymbolSizeOfAst(allocator, "pub const Symbol = struct { fn sizeOf() usize { return 18; } };\n"));
    try std.testing.expectError(error.InvalidSourceDefinition, proveSymbolSizeOfAst(allocator, "pub const Symbol = struct { pub fn sizeOf(value: usize) usize { return value; } };\n"));
    try std.testing.expectError(error.InvalidSourceDefinition, proveSymbolSizeOfAst(allocator, "pub const Symbol = struct { pub fn sizeOf() u64 { return 18; } };\n"));
    try std.testing.expectError(error.InvalidSourceDefinition, proveSymbolSizeOfAst(allocator, "pub const Symbol = struct { pub fn sizeOf() callconv(.c) usize { return 18; } };\n"));
    try std.testing.expectError(error.InvalidSourceDefinition, proveSymbolSizeOfAst(allocator, "pub const Symbol = struct { pub fn sizeOf() usize { const extra = 18; return extra; } };\n"));
    try std.testing.expectError(error.InvalidSourceDefinition, proveSymbolSizeOfAst(allocator, "pub const Symbol = struct { pub fn sizeOf() usize { return 19; } };\n"));
    try std.testing.expectError(error.InvalidSourceDefinition, proveSymbolSizeOfAst(allocator, "pub const Symbol = struct { pub fn sizeOf() usize { return 9 + 9; } };\n"));
}

test "explicit Zig selector rejects missing relative bare and NUL paths" {
    try std.testing.expectError(error.ZigSelectorInvalid, requireAbsoluteSelector("zig"));
    try std.testing.expectError(error.ZigSelectorInvalid, requireAbsoluteSelector("relative/zig"));
    try std.testing.expectError(error.ZigSelectorInvalid, requireAbsoluteSelector("/abs/zig\x00tail"));
    try requireAbsoluteSelector("/abs/zig");
}

test "external version derivation is exact and rejects source Git disagreement" {
    const source = "const zig_version: std.SemanticVersion = .{ .major = 0, .minor = 17, .patch = 0 };\n";
    const expected = try deriveExternalVersion(source, "0.16.0-364-gbdee02bc0\n");
    try std.testing.expectEqualStrings("0.17.0-dev.364+bdee02bc0", expected.slice());
    try std.testing.expectError(error.ExternalVersionUnavailable, deriveExternalVersion(source, "0.17.0-1-gbdee02bc0\n"));
    try std.testing.expectError(error.ExternalVersionUnavailable, deriveExternalVersion(source, "0.16.0-364-gbdee02bc\n"));
    try std.testing.expectError(error.ExternalVersionUnavailable, deriveExternalVersion(source ++ source, "0.16.0-364-gbdee02bc0\n"));
}

test "selector version is exact and measured identity drift is rejected" {
    const selector_version = "0.17.0-dev.364+bdee02bc0";
    try validateExactVersionOutput(selector_version, selector_version ++ "\n", "");
    try std.testing.expectError(error.ZigVersionMismatch, validateExactVersionOutput(selector_version, "0.17.0-dev.365+bdee02bc0\n", ""));
    try std.testing.expectError(error.ZigVersionMismatch, validateExactVersionOutput(selector_version, selector_version ++ "-extra\n", ""));
    try std.testing.expectError(error.ZigVersionMismatch, validateExactVersionOutput(selector_version, selector_version ++ "\n", "warning"));

    var first: ZigIdentity = .{
        .version = [_]u8{0} ** version_max_bytes,
        .version_length = selector_version.len,
        .length = 100,
        .sha256 = sha256("selector"),
    };
    @memcpy(first.version[0..selector_version.len], selector_version);
    try requireZigStable(first, first);
    var drifted = first;
    drifted.sha256 = sha256("changed selector");
    try std.testing.expectError(error.SelectorDrift, requireZigStable(first, drifted));
}

test "closed child environment is deterministic and excludes poisoned parent entries" {
    const layout = try GenerationLayout.init(generation_root);
    var environment = try closedEnvironment(std.testing.allocator, false, &layout);
    defer environment.deinit();
    try std.testing.expectEqualStrings("C", environment.get("LC_ALL").?);
    try std.testing.expectEqualStrings("UTC0", environment.get("TZ").?);
    try std.testing.expectEqualStrings("0", environment.get("GIT_OPTIONAL_LOCKS").?);
    try std.testing.expect(environment.get("PATH") == null);
    try std.testing.expect(environment.get("ZLLVM_PARENT_POISON") == null);
    try std.testing.expectEqualStrings(
        repository_root ++ "/local-state/validations/inbox206co/generation-v5/zig-local-cache",
        environment.get("ZIG_LOCAL_CACHE_DIR").?,
    );
    try std.testing.expectEqualStrings(
        repository_root ++ "/local-state/validations/inbox206co/generation-v5/zig-global-cache",
        environment.get("ZIG_GLOBAL_CACHE_DIR").?,
    );
}

test "generation-v5 layout contains every named state and has no alternate fallback" {
    const layout = try GenerationLayout.init(generation_root);
    try requireFixedGenerationLayout(&layout);
    const paths = [_]*const BoundPath{
        &layout.descriptor,
        &layout.local_cache,
        &layout.global_cache,
        &layout.home,
        &layout.temporary,
        &layout.reference_source,
        &layout.linked_source,
        &layout.object,
        &layout.reference_executable,
        &layout.linked_executable,
        &layout.reference_stdout,
        &layout.reference_stderr,
        &layout.linked_stdout,
        &layout.linked_stderr,
        &layout.reference_build_frame,
        &layout.linked_build_frame,
    };
    for (paths) |path| {
        try std.testing.expect(isStrictDescendant(generation_root, path.slice()));
        try std.testing.expect(std.mem.indexOf(u8, path.slice(), "generation-v2") == null);
        try std.testing.expect(std.mem.indexOf(u8, path.slice(), "generation-v3") == null);
        try std.testing.expect(std.mem.indexOf(u8, path.slice(), "generation-v4") == null);
    }
    try std.testing.expectEqualStrings(layout.descriptorForExport(), layout.descriptorForRead());
    try std.testing.expectEqualStrings(layout.descriptorForRead(), layout.descriptorForAdmission());
    try std.testing.expectEqualStrings(layout.descriptorForAdmission(), layout.descriptorForFinalRead());

    const alternate = try GenerationLayout.init("local-state/validations/inbox206co/generation-v4");
    try std.testing.expectError(error.GenerationLayoutInvalid, requireFixedGenerationLayout(&alternate));
    try std.testing.expectError(error.GenerationLayoutInvalid, GenerationLayout.init("/absolute/generation-v5"));
    try std.testing.expectError(error.GenerationLayoutInvalid, GenerationLayout.init("local-state//generation-v5"));
    try std.testing.expectError(error.GenerationLayoutInvalid, GenerationLayout.init("local-state/../generation-v5"));
}

test "generation root absence is required and complete or partial collisions precede launch" {
    const io = std.testing.io;

    var absent_fixture = std.testing.tmpDir(.{});
    defer absent_fixture.cleanup();
    const fixture_layout = try GenerationLayout.init("generation-v5");
    try requireGenerationRootAbsent(absent_fixture.dir, io, &fixture_layout);
    var launch_count: usize = 0;
    try markSyntheticLaunchAfterFreshness(absent_fixture.dir, io, &fixture_layout, &launch_count);
    try std.testing.expectEqual(@as(usize, 1), launch_count);
    try createFreshGeneration(absent_fixture.dir, io, &fixture_layout);
    try std.testing.expectError(error.GenerationCollision, requireGenerationRootAbsent(absent_fixture.dir, io, &fixture_layout));
    launch_count = 0;
    try std.testing.expectError(
        error.GenerationCollision,
        markSyntheticLaunchAfterFreshness(absent_fixture.dir, io, &fixture_layout, &launch_count),
    );
    try std.testing.expectEqual(@as(usize, 0), launch_count);
    for ([_]*const BoundPath{
        &fixture_layout.local_cache,
        &fixture_layout.global_cache,
        &fixture_layout.home,
        &fixture_layout.temporary,
    }) |path| {
        const metadata = try absent_fixture.dir.statFile(io, path.slice(), .{ .follow_symlinks = false });
        try std.testing.expectEqual(std.Io.File.Kind.directory, metadata.kind);
    }

    var partial_fixture = std.testing.tmpDir(.{});
    defer partial_fixture.cleanup();
    try partial_fixture.dir.createDir(io, fixture_layout.root.slice(), .default_dir);
    try partial_fixture.dir.createDir(io, fixture_layout.local_cache.slice(), .default_dir);
    launch_count = 0;
    try std.testing.expectError(
        error.GenerationCollision,
        markSyntheticLaunchAfterFreshness(partial_fixture.dir, io, &fixture_layout, &launch_count),
    );
    try std.testing.expectEqual(@as(usize, 0), launch_count);
}

test "temporary generation fixtures remain confined without repository-root access" {
    const io = std.testing.io;
    var fixture = std.testing.tmpDir(.{});
    defer fixture.cleanup();
    const fixture_layout = try GenerationLayout.init("generation-v5");
    try createFreshGeneration(fixture.dir, io, &fixture_layout);
    const metadata = try fixture.dir.statFile(io, fixture_layout.root.slice(), .{ .follow_symlinks = false });
    try std.testing.expectEqual(std.Io.File.Kind.directory, metadata.kind);
}

test "versioned build phase frame round trips binary-safe exact bindings" {
    const allocator = std.testing.allocator;
    var result: OwnedProcessResult = .{
        .term = .{ .unknown = 0x1234abcd },
        .stdout = try allocator.dupe(u8, &.{ 0, '|', 0xff, '\n', 0 }),
        .stderr = try allocator.dupe(u8, &.{ '|', 0, 0x80, '\r' }),
    };
    defer result.deinit(allocator);
    const encoded = try encodeBuildPhaseFrame(allocator, .linked, &result);
    defer allocator.free(encoded);
    const decoded = try decodeBuildPhaseFrame(encoded);
    try requireBuildPhaseFrameBinding(decoded, .linked, &result);
    try std.testing.expectEqual(BuildPhase.linked, decoded.phase);
    try std.testing.expectEqual(BuildTermination.unknown, decoded.termination);
    try std.testing.expectEqual(@as(u32, 0x1234abcd), decoded.status);
    try std.testing.expectEqualSlices(u8, result.stdout, decoded.stdout);
    try std.testing.expectEqualSlices(u8, result.stderr, decoded.stderr);
    try std.testing.expectEqual(@as(u64, result.stdout.len), std.mem.readInt(
        u64,
        encoded[build_phase_frame_magic.len + 8 ..][0..8],
        .little,
    ));
    try std.testing.expectEqual(@as(u64, result.stderr.len), std.mem.readInt(
        u64,
        encoded[build_phase_frame_magic.len + 16 ..][0..8],
        .little,
    ));

    const altered = try allocator.dupe(u8, encoded);
    defer allocator.free(altered);
    altered[altered.len - 1] ^= 0xff;
    try std.testing.expectError(
        error.BuildPhaseFrameReadBackMismatch,
        requireBuildPhaseFrameReadBack(encoded, altered, .linked, &result),
    );
    try std.testing.expectError(
        error.BuildPhaseFrameReadBackMismatch,
        requireBuildPhaseFrameBinding(decoded, .reference, &result),
    );
}

test "build phase frame rejects malformed trailing and bounded-length drift" {
    const allocator = std.testing.allocator;
    var result: OwnedProcessResult = .{
        .term = .{ .exited = 0 },
        .stdout = try allocator.dupe(u8, "ok"),
        .stderr = try allocator.dupe(u8, ""),
    };
    defer result.deinit(allocator);
    const encoded = try encodeBuildPhaseFrame(allocator, .reference, &result);
    defer allocator.free(encoded);

    const invalid_magic = try allocator.dupe(u8, encoded);
    defer allocator.free(invalid_magic);
    invalid_magic[0] ^= 1;
    try std.testing.expectError(error.BuildPhaseFrameMalformed, decodeBuildPhaseFrame(invalid_magic));

    const invalid_reserved = try allocator.dupe(u8, encoded);
    defer allocator.free(invalid_reserved);
    invalid_reserved[build_phase_frame_magic.len + 2] = 1;
    try std.testing.expectError(error.BuildPhaseFrameMalformed, decodeBuildPhaseFrame(invalid_reserved));
    try std.testing.expectError(error.BuildPhaseFrameMalformed, decodeBuildPhaseFrame(encoded[0 .. encoded.len - 1]));

    const trailing = try allocator.alloc(u8, encoded.len + 1);
    defer allocator.free(trailing);
    @memcpy(trailing[0..encoded.len], encoded);
    trailing[encoded.len] = 0;
    try std.testing.expectError(error.BuildPhaseFrameMalformed, decodeBuildPhaseFrame(trailing));

    const overflow_length = try allocator.dupe(u8, encoded);
    defer allocator.free(overflow_length);
    std.mem.writeInt(
        u64,
        overflow_length[build_phase_frame_magic.len + 8 ..][0..8],
        std.math.maxInt(u64),
        .little,
    );
    try std.testing.expectError(error.BuildPhaseFrameBoundExceeded, decodeBuildPhaseFrame(overflow_length));
    try std.testing.expectEqual(
        @as(usize, build_phase_frame_max_bytes),
        try validateBuildPhaseFrameBounds(process_output_max, process_output_max),
    );
    try std.testing.expectError(
        error.BuildPhaseFrameBoundExceeded,
        validateBuildPhaseFrameBounds(process_output_max + 1, 0),
    );
    try std.testing.expectError(
        error.BuildPhaseFrameBoundExceeded,
        validateBuildPhaseFrameBounds(0, process_output_max + 1),
    );
}

test "build phase publication is ordered verified and no-replace" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var fixture = std.testing.tmpDir(.{});
    defer fixture.cleanup();
    var result: OwnedProcessResult = .{
        .term = .{ .exited = 0 },
        .stdout = try allocator.dupe(u8, &.{ 0, '|', 1 }),
        .stderr = try allocator.dupe(u8, &.{ 0xff, 0 }),
    };
    defer result.deinit(allocator);

    const publication = try publishBuildPhaseFrame(allocator, fixture.dir, io, .reference, &result);
    try std.testing.expectEqual(BuildPhase.reference, publication.phase);
    try std.testing.expectEqual(BuildPhasePublicationStage.read_back_verified, publication.stage);
    try std.testing.expect(publication.exact_length > build_phase_frame_header_size);

    try std.testing.expectError(
        error.PathAlreadyExists,
        publishBuildPhaseFrame(allocator, fixture.dir, io, .reference, &result),
    );
    var stage: BuildPhasePublicationStage = .none;
    try std.testing.expectError(
        error.BuildPhaseFramePublicationOrder,
        advanceBuildPhasePublication(&stage, .temporary_synced, .renamed),
    );

    var temporary_collision = std.testing.tmpDir(.{});
    defer temporary_collision.cleanup();
    var temporary_file = try temporary_collision.dir.createFile(io, reference_build_frame_temporary, .{
        .read = false,
        .truncate = false,
        .exclusive = true,
    });
    temporary_file.close(io);
    try std.testing.expectError(
        error.PathAlreadyExists,
        publishBuildPhaseFrame(allocator, temporary_collision.dir, io, .reference, &result),
    );
}

test "failed linked build retains verified frame and cannot reach execution" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var fixture = std.testing.tmpDir(.{});
    defer fixture.cleanup();
    var result: OwnedProcessResult = .{
        .term = .{ .exited = 9 },
        .stdout = try allocator.dupe(u8, "linked stdout\x00|"),
        .stderr = try allocator.dupe(u8, "linked failure\x00|"),
    };
    defer result.deinit(allocator);
    var execution_count: usize = 0;
    try std.testing.expectError(
        error.ChildFailed,
        syntheticLinkedBuildThenExecution(allocator, fixture.dir, io, &result, &execution_count),
    );
    try std.testing.expectEqual(@as(usize, 0), execution_count);
    const retained = try fixture.dir.readFileAlloc(
        io,
        linked_build_frame_final,
        allocator,
        .limited(build_phase_frame_max_bytes),
    );
    defer allocator.free(retained);
    try requireBuildPhaseFrameBinding(try decodeBuildPhaseFrame(retained), .linked, &result);

    var collision_fixture = std.testing.tmpDir(.{});
    defer collision_fixture.cleanup();
    var collision = try collision_fixture.dir.createFile(io, linked_build_frame_temporary, .{
        .read = false,
        .truncate = false,
        .exclusive = true,
    });
    collision.close(io);
    execution_count = 0;
    try std.testing.expectError(
        error.PathAlreadyExists,
        syntheticLinkedBuildThenExecution(allocator, collision_fixture.dir, io, &result, &execution_count),
    );
    try std.testing.expectEqual(@as(usize, 0), execution_count);
}

fn writeFixtureBytes(directory: std.Io.Dir, io: std.Io, name: []const u8, bytes: []const u8) !void {
    var file = try directory.createFile(io, name, .{
        .read = false,
        .truncate = false,
        .exclusive = true,
    });
    defer file.close(io);
    try file.writeStreamingAll(io, bytes);
}

fn countFixtureEntries(directory: std.Io.Dir, io: std.Io) !usize {
    var iterable = try directory.openDir(io, ".", .{
        .access_sub_paths = false,
        .iterate = true,
        .follow_symlinks = false,
    });
    defer iterable.close(io);
    var iterator = iterable.iterate();
    var count: usize = 0;
    while (try iterator.next(io)) |_| count += 1;
    return count;
}

test "linked frame inspector emits exact canonical binary hex and performs no writes" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const layout = try GenerationLayout.init(generation_root);
    var fixture = std.testing.tmpDir(.{});
    defer fixture.cleanup();
    var result: OwnedProcessResult = .{
        .term = .{ .exited = 7 },
        .stdout = try allocator.dupe(u8, &.{ 0, '|', 0xff }),
        .stderr = try allocator.dupe(u8, &.{ 0x80, '\n' }),
    };
    defer result.deinit(allocator);
    _ = try publishBuildPhaseFrame(allocator, fixture.dir, io, .linked, &result);
    const before = try fixture.dir.statFile(io, linked_build_frame_final, .{ .follow_symlinks = false });
    const entries_before = try countFixtureEntries(fixture.dir, io);

    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();
    try std.testing.expectEqual(
        DiagnosticDisposition.complete,
        try inspectLinkedBuildFrameInDirectory(allocator, fixture.dir, io, &layout, &output.writer),
    );
    const stdout_digest = std.fmt.bytesToHex(sha256(result.stdout), .lower);
    const stderr_digest = std.fmt.bytesToHex(sha256(result.stderr), .lower);
    var expected_buffer: [1024]u8 = undefined;
    const expected = try std.fmt.bufPrint(
        &expected_buffer,
        "linked_build_frame_diagnostic_v1\nphase=linked\ntermination=exited\nstatus=7\nstdout_length=3\nstdout_sha256={s}\nstderr_length=2\nstderr_sha256={s}\ncontent=complete\nstdout_hex=007cff\nstderr_hex=800a\n",
        .{ &stdout_digest, &stderr_digest },
    );
    try std.testing.expectEqualStrings(expected, output.written());
    const after = try fixture.dir.statFile(io, linked_build_frame_final, .{ .follow_symlinks = false });
    try std.testing.expectEqual(before.kind, after.kind);
    try std.testing.expectEqual(before.size, after.size);
    try std.testing.expectEqual(entries_before, try countFixtureEntries(fixture.dir, io));
}

test "linked frame inspector omits all content at small caps with distinct result" {
    const allocator = std.testing.allocator;
    const stdout = try allocator.alloc(u8, diagnostic_stream_max_bytes + 1);
    defer allocator.free(stdout);
    @memset(stdout, 0xa5);
    const frame: BuildPhaseFrame = .{
        .phase = .linked,
        .termination = .exited,
        .status = 1,
        .stdout = stdout,
        .stderr = "secret|\x00",
    };
    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();
    const disposition = try renderLinkedBuildFrame(&output.writer, frame);
    try std.testing.expectEqual(DiagnosticDisposition.omitted, disposition);
    try std.testing.expectError(error.DiagnosticContentOmitted, requireCompleteDiagnostic(disposition));
    try std.testing.expect(std.mem.endsWith(
        u8,
        output.written(),
        "content=omitted\nstdout_hex=omitted\nstderr_hex=omitted\n",
    ));
    try std.testing.expect(std.mem.indexOf(u8, output.written(), "a5a5") == null);
    try std.testing.expect(std.mem.indexOf(u8, output.written(), "736563726574") == null);
}

test "linked frame inspector rejects missing malformed trailing wrong-phase and oversize files" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const layout = try GenerationLayout.init(generation_root);
    var output: std.Io.Writer.Discarding = .init(&.{});

    var missing = std.testing.tmpDir(.{});
    defer missing.cleanup();
    try std.testing.expectError(
        error.FileNotFound,
        inspectLinkedBuildFrameInDirectory(allocator, missing.dir, io, &layout, &output.writer),
    );

    var malformed = std.testing.tmpDir(.{});
    defer malformed.cleanup();
    try writeFixtureBytes(malformed.dir, io, linked_build_frame_final, "malformed");
    try std.testing.expectError(
        error.BuildPhaseFrameMalformed,
        inspectLinkedBuildFrameInDirectory(allocator, malformed.dir, io, &layout, &output.writer),
    );

    var result: OwnedProcessResult = .{
        .term = .{ .exited = 1 },
        .stdout = try allocator.dupe(u8, "stdout"),
        .stderr = try allocator.dupe(u8, "stderr"),
    };
    defer result.deinit(allocator);
    const linked = try encodeBuildPhaseFrame(allocator, .linked, &result);
    defer allocator.free(linked);

    var trailing = std.testing.tmpDir(.{});
    defer trailing.cleanup();
    const with_trailing = try allocator.alloc(u8, linked.len + 1);
    defer allocator.free(with_trailing);
    @memcpy(with_trailing[0..linked.len], linked);
    with_trailing[linked.len] = 0;
    try writeFixtureBytes(trailing.dir, io, linked_build_frame_final, with_trailing);
    try std.testing.expectError(
        error.BuildPhaseFrameMalformed,
        inspectLinkedBuildFrameInDirectory(allocator, trailing.dir, io, &layout, &output.writer),
    );

    var wrong_phase = std.testing.tmpDir(.{});
    defer wrong_phase.cleanup();
    const reference = try encodeBuildPhaseFrame(allocator, .reference, &result);
    defer allocator.free(reference);
    try writeFixtureBytes(wrong_phase.dir, io, linked_build_frame_final, reference);
    try std.testing.expectError(
        error.DiagnosticFrameWrongPhase,
        inspectLinkedBuildFrameInDirectory(allocator, wrong_phase.dir, io, &layout, &output.writer),
    );

    var noncanonical = std.testing.tmpDir(.{});
    defer noncanonical.cleanup();
    const invalid_status = try allocator.dupe(u8, linked);
    defer allocator.free(invalid_status);
    std.mem.writeInt(u32, invalid_status[build_phase_frame_magic.len + 4 ..][0..4], 256, .little);
    try writeFixtureBytes(noncanonical.dir, io, linked_build_frame_final, invalid_status);
    try std.testing.expectError(
        error.BuildPhaseFrameMalformed,
        inspectLinkedBuildFrameInDirectory(allocator, noncanonical.dir, io, &layout, &output.writer),
    );

    var oversize = std.testing.tmpDir(.{});
    defer oversize.cleanup();
    var oversize_file = try oversize.dir.createFile(io, linked_build_frame_final, .{
        .read = true,
        .truncate = false,
        .exclusive = true,
    });
    try oversize_file.writePositionalAll(io, &.{0}, build_phase_frame_max_bytes);
    oversize_file.close(io);
    try std.testing.expectError(
        error.BuildPhaseFrameBoundExceeded,
        inspectLinkedBuildFrameInDirectory(allocator, oversize.dir, io, &layout, &output.writer),
    );
}

test "linked frame inspector rejects symlink files and symlinked fixed components" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const layout = try GenerationLayout.init(generation_root);
    var output: std.Io.Writer.Discarding = .init(&.{});

    var file_link = std.testing.tmpDir(.{});
    defer file_link.cleanup();
    try writeFixtureBytes(file_link.dir, io, "target.bin", "target");
    try file_link.dir.symLink(io, "target.bin", linked_build_frame_final, .{});
    try std.testing.expectError(
        error.SymLinkLoop,
        inspectLinkedBuildFrameInDirectory(allocator, file_link.dir, io, &layout, &output.writer),
    );

    var component_link = std.testing.tmpDir(.{});
    defer component_link.cleanup();
    try component_link.dir.createDir(io, "actual", .default_dir);
    try component_link.dir.symLink(io, "actual", "local-state", .{ .is_directory = true });
    if (openFixedGenerationV3AtRoot(component_link.dir, io)) |opened| {
        opened.close(io);
        return error.TestUnexpectedResult;
    } else |failure| switch (failure) {
        error.SymLinkLoop, error.NotDir => {},
        else => return failure,
    }

    var confined = std.testing.tmpDir(.{});
    defer confined.cleanup();
    try confined.dir.createDir(io, "generation-v3", .default_dir);
    try std.testing.expectError(error.FileNotFound, openFixedGenerationV3AtRoot(confined.dir, io));
}

test "reference output inspector emits exact canonical binary-safe output without writes" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const layout = try GenerationLayout.init(generation_root);
    var fixture = std.testing.tmpDir(.{});
    defer fixture.cleanup();
    try writeFixtureBytes(fixture.dir, io, "reference.stdout", expected_execution_stdout);
    try writeFixtureBytes(fixture.dir, io, "reference.stderr", "");
    const entries_before = try countFixtureEntries(fixture.dir, io);
    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();
    try std.testing.expectEqual(
        DiagnosticDisposition.complete,
        try inspectReferenceOutputsInDirectory(allocator, fixture.dir, io, &layout, generation_root, &output.writer),
    );
    const digest = std.fmt.bytesToHex(sha256(expected_execution_stdout), .lower);
    const empty_digest = std.fmt.bytesToHex(sha256(""), .lower);
    const stdout_hex = std.fmt.bytesToHex(expected_execution_stdout, .lower);
    var expected_buffer: [2048]u8 = undefined;
    const expected = try std.fmt.bufPrint(
        &expected_buffer,
        "reference_output_diagnostic_v1\nphase=reference\nexpected_record_sha256={s}\nstdout_length={}\nstdout_sha256={s}\nstderr_length=0\nstderr_sha256={s}\nstdout_equal=true\nstderr_empty=true\nfirst_differing_stdout_offset=none\ncontent=complete\nstdout_hex={s}\nstderr_hex=\n",
        .{ &digest, expected_execution_stdout.len, &digest, &empty_digest, &stdout_hex },
    );
    try std.testing.expectEqualStrings(expected, output.written());
    try std.testing.expectEqual(entries_before, try countFixtureEntries(fixture.dir, io));
}

test "reference output diagnostic reports byte and length differences independently" {
    const allocator = std.testing.allocator;
    var changed = try allocator.dupe(u8, expected_execution_stdout);
    defer allocator.free(changed);
    changed[10] ^= 1;
    try std.testing.expectEqual(@as(?usize, 10), firstDifferingOffset(expected_execution_stdout, changed));
    var changed_output: std.Io.Writer.Allocating = .init(allocator);
    defer changed_output.deinit();
    _ = try renderReferenceOutputDiagnostic(&changed_output.writer, changed, "");
    try std.testing.expect(std.mem.indexOf(u8, changed_output.written(), "stdout_equal=false\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, changed_output.written(), "first_differing_stdout_offset=10\n") != null);

    const missing_newline = expected_execution_stdout[0 .. expected_execution_stdout.len - 1];
    try std.testing.expectEqual(
        @as(?usize, missing_newline.len),
        firstDifferingOffset(expected_execution_stdout, missing_newline),
    );
    var short_output: std.Io.Writer.Allocating = .init(allocator);
    defer short_output.deinit();
    _ = try renderReferenceOutputDiagnostic(&short_output.writer, missing_newline, "");
    var expected_offset_buffer: [64]u8 = undefined;
    const expected_offset = try std.fmt.bufPrint(
        &expected_offset_buffer,
        "first_differing_stdout_offset={}\n",
        .{missing_newline.len},
    );
    try std.testing.expect(std.mem.indexOf(u8, short_output.written(), expected_offset) != null);
}

test "reference output diagnostic reports nonempty stderr and omits all oversized content" {
    const allocator = std.testing.allocator;
    var stderr_output: std.Io.Writer.Allocating = .init(allocator);
    defer stderr_output.deinit();
    _ = try renderReferenceOutputDiagnostic(&stderr_output.writer, expected_execution_stdout, "problem\x00");
    try std.testing.expect(std.mem.indexOf(u8, stderr_output.written(), "stderr_length=8\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, stderr_output.written(), "stderr_empty=false\n") != null);

    const oversized = try allocator.alloc(u8, diagnostic_stream_max_bytes + 1);
    defer allocator.free(oversized);
    @memset(oversized, 0xa5);
    var oversized_output: std.Io.Writer.Allocating = .init(allocator);
    defer oversized_output.deinit();
    try std.testing.expectEqual(
        DiagnosticDisposition.omitted,
        try renderReferenceOutputDiagnostic(&oversized_output.writer, oversized, "secret\x00"),
    );
    try std.testing.expect(std.mem.endsWith(
        u8,
        oversized_output.written(),
        "content=omitted\nstdout_hex=omitted\nstderr_hex=omitted\n",
    ));
    try std.testing.expect(std.mem.indexOf(u8, oversized_output.written(), "a5a5") == null);
    try std.testing.expect(std.mem.indexOf(u8, oversized_output.written(), "736563726574") == null);
}

test "reference output inspector rejects missing exact files and wrong or symlinked roots" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const layout = try GenerationLayout.init(generation_root);
    var missing = std.testing.tmpDir(.{});
    defer missing.cleanup();
    try writeFixtureBytes(missing.dir, io, "reference.stdout", expected_execution_stdout);
    var output: std.Io.Writer.Discarding = .init(&.{});
    try std.testing.expectError(
        error.FileNotFound,
        inspectReferenceOutputsInDirectory(allocator, missing.dir, io, &layout, generation_root, &output.writer),
    );

    var wrong_root = std.testing.tmpDir(.{});
    defer wrong_root.cleanup();
    try std.testing.expectError(error.FileNotFound, openFixedGenerationV4AtRoot(wrong_root.dir, io));

    var symlinked_root = std.testing.tmpDir(.{});
    defer symlinked_root.cleanup();
    try symlinked_root.dir.createDir(io, "actual", .default_dir);
    try symlinked_root.dir.symLink(io, "actual", "local-state", .{ .is_directory = true });
    if (openFixedGenerationV4AtRoot(symlinked_root.dir, io)) |opened| {
        opened.close(io);
        return error.TestUnexpectedResult;
    } else |failure| switch (failure) {
        error.SymLinkLoop, error.NotDir => {},
        else => return failure,
    }
}

test "candidate admission binds current pin definition ABI input and semantics" {
    const accepted: CandidateClaim = .{
        .revision = zig_revision,
        .target = execution_target,
        .definition = definition_path,
        .function = function_name,
        .input_count = 0,
        .result = expected_result,
    };
    const source: SourceProof = .{
        .definition_sha256 = sha256("definition"),
        .import_sha256 = sha256("import"),
        .use_sha256 = sha256("use"),
        .definition_count = 1,
        .use_count = 4,
    };
    const descriptor: DescriptorProof = .{
        .descriptor_sha256 = sha256("descriptor"),
        .function_type_sha256 = sha256("fn () usize"),
        .instruction_count = 1,
        .parameter_count = 0,
        .return_bits = 64,
        .calling_convention = .default,
    };
    const harness: HarnessContract = .{
        .parameter_count = 0,
        .return_bits = 64,
        .calling_convention = .default,
        .return_value_drives_output = true,
    };
    const bridge = expectedExecutionBridge();
    const admission = try admitCandidate(accepted, source, descriptor, harness, bridge);
    try requireCandidateAdmission(admission);
    try requireCandidateStable(admission, source, descriptor, bridge);
    try std.testing.expectError(error.CandidateAdmissionMissing, requireCandidateAdmission(null));
    var drifted_source = source;
    drifted_source.use_sha256 = sha256("changed use");
    try std.testing.expectError(error.CandidateBindingMismatch, requireCandidateStable(admission, drifted_source, descriptor, bridge));
    var drifted_descriptor = descriptor;
    drifted_descriptor.descriptor_sha256 = sha256("changed descriptor");
    try std.testing.expectError(error.CandidateBindingMismatch, requireCandidateStable(admission, source, drifted_descriptor, bridge));
    var changed = accepted;
    changed.revision = "wrong";
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(changed, source, descriptor, harness, bridge));
    changed = accepted;
    changed.target = "aarch64-linux-gnu";
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(changed, source, descriptor, harness, bridge));
    changed = accepted;
    changed.definition = "src/main.zig";
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(changed, source, descriptor, harness, bridge));
    changed = accepted;
    changed.input_count = 1;
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(changed, source, descriptor, harness, bridge));
    changed = accepted;
    changed.result = 19;
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(changed, source, descriptor, harness, bridge));

    var wrong_abi = descriptor;
    wrong_abi.calling_convention = .c;
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(accepted, source, wrong_abi, harness, bridge));
    var c_harness = harness;
    c_harness.calling_convention = .c;
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(accepted, source, descriptor, c_harness, bridge));
    var independent_output = harness;
    independent_output.return_value_drives_output = false;
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(accepted, source, descriptor, independent_output, bridge));

    var drifted_bridge = bridge;
    drifted_bridge.target = "aarch64-linux-gnu";
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(accepted, source, descriptor, harness, drifted_bridge));
    drifted_bridge = bridge;
    drifted_bridge.candidate_calling_convention = .c;
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(accepted, source, descriptor, harness, drifted_bridge));
    drifted_bridge = bridge;
    drifted_bridge.parameter_count = 1;
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(accepted, source, descriptor, harness, drifted_bridge));
    drifted_bridge = bridge;
    drifted_bridge.return_bits = 32;
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(accepted, source, descriptor, harness, drifted_bridge));
    drifted_bridge = bridge;
    drifted_bridge.result_type = .u64;
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(accepted, source, descriptor, harness, drifted_bridge));
    drifted_bridge = bridge;
    drifted_bridge.bridge_calling_convention = .auto;
    try std.testing.expectError(error.CandidateBindingMismatch, admitCandidate(accepted, source, descriptor, harness, drifted_bridge));
    drifted_bridge = bridge;
    drifted_bridge.bridge_calling_convention = .c;
    try std.testing.expectError(error.CandidateBindingMismatch, requireCandidateStable(admission, source, descriptor, drifted_bridge));
}

test "candidate bridge derives and validates the actual SysV return planner proof" {
    const proof = try real_rows.oracleAbiProof();
    try validateOracleAbiProof(execution_target, proof);
    try std.testing.expectEqual(project_target.SupportedTarget.x86_64_linux_gnu, proof.supported_target);
    try std.testing.expectEqual(@as(usize, 0), proof.parameter_count);
    try std.testing.expectEqual(real_rows.OracleAbiReturnShape.integer, proof.return_shape);
    try std.testing.expectEqual(@as(u16, 64), proof.return_bits);
    try std.testing.expectEqual(@as(usize, 1), proof.gpr_returns);
    try std.testing.expectEqual(@as(usize, 0), proof.sse_returns);
    try std.testing.expect(!proof.memory_return);

    try std.testing.expectError(error.CandidateBindingMismatch, validateOracleAbiProof("x86_64-linux-musl", proof));
    try std.testing.expectError(error.CandidateBindingMismatch, validateOracleAbiProof("not-a-target", proof));
    var drifted = proof;
    drifted.supported_target = .aarch64_linux_gnu;
    try std.testing.expectError(error.CandidateBindingMismatch, validateOracleAbiProof(execution_target, drifted));
    drifted = proof;
    drifted.parameter_count = 1;
    try std.testing.expectError(error.CandidateBindingMismatch, validateOracleAbiProof(execution_target, drifted));
    drifted = proof;
    drifted.return_shape = .floating;
    try std.testing.expectError(error.CandidateBindingMismatch, validateOracleAbiProof(execution_target, drifted));
    drifted = proof;
    drifted.return_bits = 32;
    try std.testing.expectError(error.CandidateBindingMismatch, validateOracleAbiProof(execution_target, drifted));
    drifted = proof;
    drifted.gpr_returns = 0;
    try std.testing.expectError(error.CandidateBindingMismatch, validateOracleAbiProof(execution_target, drifted));
    drifted = proof;
    drifted.sse_returns = 1;
    try std.testing.expectError(error.CandidateBindingMismatch, validateOracleAbiProof(execution_target, drifted));
    drifted = proof;
    drifted.memory_return = true;
    try std.testing.expectError(error.CandidateBindingMismatch, validateOracleAbiProof(execution_target, drifted));
}

test "reference and linked harness ASTs require one newline escape and reject doubled form" {
    try proveReferenceHarnessAst(std.testing.allocator, reference_harness_source);
    try proveLinkedHarnessAst(std.testing.allocator, linked_harness_source);
    try std.testing.expectEqual(@as(usize, 1), countExact(reference_harness_source, "witness={}\\n"));
    try std.testing.expectEqual(@as(usize, 1), countExact(linked_harness_source, "witness={}\\n"));
    try std.testing.expectEqual(@as(usize, 0), countExact(reference_harness_source, "witness={}\\\\n"));
    try std.testing.expectEqual(@as(usize, 0), countExact(linked_harness_source, "witness={}\\\\n"));

    const doubled_reference = try std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        reference_harness_source,
        "witness={}\\n",
        "witness={}\\\\n",
    );
    defer std.testing.allocator.free(doubled_reference);
    try std.testing.expectError(
        error.CandidateBindingMismatch,
        proveReferenceHarnessAst(std.testing.allocator, doubled_reference),
    );

    const doubled_linked = try std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        linked_harness_source,
        "witness={}\\n",
        "witness={}\\\\n",
    );
    defer std.testing.allocator.free(doubled_linked);
    try std.testing.expectError(
        error.CandidateBindingMismatch,
        proveLinkedHarnessAst(std.testing.allocator, doubled_linked),
    );
}

test "linked harness source and compiled bridge agree on explicit x86_64 SysV ABI" {
    try proveLinkedHarnessAst(std.testing.allocator, linked_harness_source);
    const function_info = @typeInfo(ExecutionBridgeFunction).@"fn";
    try std.testing.expectEqual(@as(usize, 0), function_info.params.len);
    try std.testing.expectEqual(usize, function_info.return_type.?);
    try std.testing.expect(std.builtin.CallingConvention.eql(
        .{ .x86_64_sysv = .{} },
        function_info.calling_convention,
    ));
    try std.testing.expect(std.mem.indexOf(u8, linked_harness_source, "fn () usize") == null);

    const implicit = std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        linked_harness_source,
        " callconv(.{ .x86_64_sysv = .{} })",
        "",
    ) catch return error.OutOfMemory;
    defer std.testing.allocator.free(implicit);
    try std.testing.expectError(error.CandidateBindingMismatch, proveLinkedHarnessAst(std.testing.allocator, implicit));
    const wrong_convention = std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        linked_harness_source,
        "callconv(.{ .x86_64_sysv = .{} })",
        "callconv(.c)",
    ) catch return error.OutOfMemory;
    defer std.testing.allocator.free(wrong_convention);
    try std.testing.expectError(error.CandidateBindingMismatch, proveLinkedHarnessAst(std.testing.allocator, wrong_convention));
}

test "descriptor admission rejects missing duplicate and ABI-mismatched AIR bindings" {
    const allocator = std.testing.allocator;
    const one = try syntheticDescriptor(allocator, &.{function_name}, "fn () usize");
    defer allocator.free(one);
    const proof = try proveDescriptor(allocator, one);
    try std.testing.expectEqual(@as(usize, 1), proof.instruction_count);
    try std.testing.expectEqual(CallingConvention.default, proof.calling_convention);
    try std.testing.expectEqual(@as(usize, 0), proof.parameter_count);
    try std.testing.expectEqual(@as(u16, 64), proof.return_bits);

    const missing = try syntheticDescriptor(allocator, &.{"other"}, "fn () usize");
    defer allocator.free(missing);
    try std.testing.expectError(error.AirBindingMissing, proveDescriptor(allocator, missing));

    const duplicate = try syntheticDescriptor(allocator, &.{ function_name, function_name }, "fn () usize");
    defer allocator.free(duplicate);
    try std.testing.expectError(error.AirBindingDuplicate, proveDescriptor(allocator, duplicate));

    const wrong_abi = try syntheticDescriptor(allocator, &.{function_name}, "fn (u8) usize");
    defer allocator.free(wrong_abi);
    try std.testing.expectError(error.AbiMismatch, proveDescriptor(allocator, wrong_abi));
}

test "process boundary rejects launch status bounds and incomplete EOF independently" {
    const accepted: ProcessBoundaryObservation = .{
        .launched = true,
        .termination = .exited,
        .status = 0,
        .stdout_length = process_output_max,
        .stderr_length = process_output_max,
        .exact_eof = true,
    };
    try validateProcessBoundary(accepted);
    var changed = accepted;
    changed.launched = false;
    try std.testing.expectError(error.ProcessInconsistent, validateProcessBoundary(changed));
    changed = accepted;
    changed.status = 1;
    try std.testing.expectError(error.ProcessInconsistent, validateProcessBoundary(changed));
    changed = accepted;
    changed.stdout_length = process_output_max + 1;
    try std.testing.expectError(error.ChildOutputBoundExceeded, validateProcessBoundary(changed));
    changed = accepted;
    changed.stderr_length = process_output_max + 1;
    try std.testing.expectError(error.ChildOutputBoundExceeded, validateProcessBoundary(changed));
    changed = accepted;
    changed.exact_eof = false;
    try std.testing.expectError(error.ProcessInconsistent, validateProcessBoundary(changed));
}

test "truthful counters advance only after both executions and exact oracle equality" {
    const good = syntheticRecord(0, 18, true);
    var counters: Counters = .{};
    counters.noteLowered();
    counters.noteEmitted();
    counters.noteLinked();
    try counters.noteBothExecuted(good, good);
    try counters.noteOracleAccepted(good, good);
    try std.testing.expectEqual(@as(usize, 1), counters.real_functions_lowered);
    try std.testing.expectEqual(@as(usize, 1), counters.real_objects_emitted);
    try std.testing.expectEqual(@as(usize, 1), counters.real_native_linked);
    try std.testing.expectEqual(@as(usize, 1), counters.real_executed);
    try std.testing.expectEqual(@as(usize, 1), counters.real_programs_ok);

    var failed: Counters = .{};
    var nonzero = good;
    nonzero.status = 1;
    try std.testing.expectError(error.ProcessInconsistent, failed.noteBothExecuted(good, nonzero));
    try std.testing.expectEqual(@as(usize, 0), failed.real_executed);
}

test "oracle rejects output semantic and optimized-away call mismatches" {
    const good = syntheticRecord(0, 18, true);
    var changed = good;
    changed.semantic_result = 19;
    var counters: Counters = .{ .real_executed = 1 };
    try std.testing.expectError(error.OracleMismatch, counters.noteOracleAccepted(good, changed));
    try std.testing.expectEqual(@as(usize, 0), counters.real_programs_ok);

    changed = good;
    changed.call_occurrence = false;
    try std.testing.expectError(error.CallOccurrenceMissing, counters.noteOracleAccepted(good, changed));
    try std.testing.expectEqual(@as(usize, 0), counters.real_programs_ok);
}

test "canonical process record rejects status stdout stderr and termination mismatch" {
    const allocator = std.testing.allocator;
    var good: OwnedProcessResult = .{
        .term = .{ .exited = 0 },
        .stdout = try allocator.dupe(u8, "execution-oracle-v1 result=18 witness=61\n"),
        .stderr = try allocator.dupe(u8, ""),
    };
    defer good.deinit(allocator);
    const admission: CandidateAdmission = .{
        .source = .{
            .definition_sha256 = sha256("definition"),
            .import_sha256 = sha256("import"),
            .use_sha256 = sha256("use"),
            .definition_count = 1,
            .use_count = 4,
        },
        .descriptor = .{
            .descriptor_sha256 = sha256("descriptor"),
            .function_type_sha256 = sha256("fn () usize"),
            .instruction_count = 1,
            .parameter_count = 0,
            .return_bits = 64,
            .calling_convention = .default,
        },
        .harness = .{
            .parameter_count = 0,
            .return_bits = 64,
            .calling_convention = .default,
            .return_value_drives_output = true,
        },
        .bridge = expectedExecutionBridge(),
    };
    _ = try canonicalExecutionRecord(good, admission);

    var bad_status = good;
    bad_status.term = .{ .exited = 1 };
    try std.testing.expectError(error.ProcessInconsistent, canonicalExecutionRecord(bad_status, admission));
    var bad_term = good;
    bad_term.term = .{ .signal = @enumFromInt(9) };
    try std.testing.expectError(error.ProcessInconsistent, canonicalExecutionRecord(bad_term, admission));
    var bad_stdout = good;
    bad_stdout.stdout = @constCast("wrong\n");
    try std.testing.expectError(error.ProcessInconsistent, canonicalExecutionRecord(bad_stdout, admission));
    var bad_stderr = good;
    bad_stderr.stderr = @constCast("unexpected");
    try std.testing.expectError(error.ProcessInconsistent, canonicalExecutionRecord(bad_stderr, admission));

    var independent = admission;
    independent.harness.return_value_drives_output = false;
    try std.testing.expectError(error.CallOccurrenceMissing, canonicalExecutionRecord(good, independent));
}

test "finite storage bound is explicit and checked arithmetically" {
    try std.testing.expect(peak_storage_bytes >= descriptor_max_bytes);
    try std.testing.expect(peak_storage_files >= 1);
    try std.testing.expectError(error.Overflow, std.math.mul(u64, std.math.maxInt(u64), 2));
}

test "private acceptance bootstrap module tests" {
    _ = acceptance;
}
