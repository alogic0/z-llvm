const std = @import("std");
const contract = @import("../o2_compiler_rt_v1_baseline_validation.zig");
const process = @import("process.zig");

pub const maximum_input_bytes: u64 = 64 * 1024 * 1024;
pub const maximum_artifact_bytes: u64 = 1024 * 1024 * 1024;
pub const expected_zig_version = "0.17.0";
pub const accepted_registered_worktree_count: usize = 43;

pub const FileIdentity = struct {
    bytes: u64,
    mode: u32,
    inode: std.Io.File.INode,
    sha256: contract.Digest,
};

pub const ToolRole = enum { zig, git, llvm_extract, objcopy, objdump, readelf };

pub fn toolRoleName(role: ToolRole) []const u8 {
    return @tagName(role);
}

pub const ToolSelector = struct {
    role: ToolRole,
    path: []const u8,
    authorized_bytes: u64,
    authorized_sha256: contract.Digest,
    authorized_version: ?[]const u8,
};

pub const PortableToolIdentity = struct {
    role: ToolRole,
    bytes: u64,
    sha256: contract.Digest,
    version: ?[]const u8,
};

pub const AuthenticatedSubject = struct {
    path: []const u8,
    identity: FileIdentity,
    portable_tool: ?PortableToolIdentity = null,
};

pub const SubjectSet = struct {
    zig: AuthenticatedSubject,
    git: AuthenticatedSubject,
    llvm_extract: AuthenticatedSubject,
    objcopy: AuthenticatedSubject,
    objdump: AuthenticatedSubject,
    readelf: AuthenticatedSubject,
};

pub const InputSet = struct {
    raw: FileIdentity,
    adoption: FileIdentity,
    bundle_manifest: FileIdentity,
    combined_patch: FileIdentity,
    reproduction: FileIdentity,
    retention_pins: FileIdentity,
    retention_policy: FileIdentity,
    cleanup_source: FileIdentity,
    bypass_inventory: FileIdentity,
    facade_manifest: FileIdentity,
    facade_source: FileIdentity,
    external_stage4: FileIdentity,
};

pub const ExpectedFile = struct {
    bytes: u64,
    sha256_hex: []const u8,
    executable: bool = false,
};

pub const PathKind = enum { file, directory };
pub const ManifestLine = struct { digest: contract.Digest, path: []const u8 };

pub const accepted_bundle_manifest_prefix =
    "tmp/o2_calls_perf/compiler_rt_v1/inbox187_baseline_validation_contract_bundle/";

pub fn decodeSha256(hex: []const u8) !contract.Digest {
    if (hex.len != 64) return error.InputIdentityMismatch;
    var digest: contract.Digest = undefined;
    for (&digest, 0..) |*byte, index| {
        const high = std.fmt.charToDigit(hex[index * 2], 16) catch
            return error.InputIdentityMismatch;
        const low = std.fmt.charToDigit(hex[index * 2 + 1], 16) catch
            return error.InputIdentityMismatch;
        byte.* = @intCast(high * 16 + low);
    }
    return digest;
}

fn isPathWithin(path: []const u8, prefix: []const u8) bool {
    if (std.mem.eql(u8, path, prefix)) return true;
    return path.len > prefix.len and std.mem.startsWith(u8, path, prefix) and
        path[prefix.len] == '/';
}

pub fn validateRegisteredWorktreePrefixes(prefixes: []const []const u8) !void {
    if (prefixes.len != accepted_registered_worktree_count) return error.InvalidArguments;
    for (prefixes, 0..) |prefix, index| {
        try process.validateCanonicalAbsolute(prefix);
        for (prefixes[0..index]) |prior| {
            if (std.mem.eql(u8, prefix, prior)) return error.PathAlias;
        }
    }
}

pub fn registeredWorktreeAccessExclusions(
    allocator: std.mem.Allocator,
    registered: []const []const u8,
    repository: []const u8,
) ![]const []const u8 {
    try validateRegisteredWorktreePrefixes(registered);
    try process.validateCanonicalAbsolute(repository);
    var result = std.array_list.Managed([]const u8).init(allocator);
    errdefer result.deinit();
    var repository_matches: usize = 0;
    for (registered) |path| {
        if (std.mem.eql(u8, path, repository)) repository_matches += 1 else try result.append(path);
    }
    if (repository_matches != 1 or result.items.len + 1 != accepted_registered_worktree_count)
        return error.WorktreeSetMismatch;
    return result.toOwnedSlice();
}

pub fn validateExplicitPath(
    io: std.Io,
    absolute_path: []const u8,
    expected_kind: PathKind,
    registered_worktree_prefixes: []const []const u8,
) !u64 {
    try process.validateCanonicalAbsolute(absolute_path);
    for (registered_worktree_prefixes) |prefix| {
        try process.validateCanonicalAbsolute(prefix);
        if (isPathWithin(absolute_path, prefix)) return error.RegisteredWorktreeRejected;
    }
    var file = std.Io.Dir.openFileAbsolute(io, absolute_path, .{
        .mode = .read_only,
        .allow_directory = true,
        .path_only = true,
        .follow_symlinks = false,
    }) catch |failure| switch (failure) {
        error.SymLinkLoop => return error.SymlinkRejected,
        else => return error.PathEscape,
    };
    defer file.close(io);
    const metadata = file.stat(io) catch return error.PathEscape;
    const actual_kind: PathKind = switch (metadata.kind) {
        .file => .file,
        .directory => .directory,
        .sym_link => return error.SymlinkRejected,
        else => return error.WrongPathKind,
    };
    if (actual_kind != expected_kind) return error.WrongPathKind;
    var canonical_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const canonical_length = std.Io.Dir.realPathFileAbsolute(io, absolute_path, &canonical_buffer) catch
        return error.PathEscape;
    if (!std.mem.eql(u8, absolute_path, canonical_buffer[0..canonical_length]))
        return error.NonCanonicalPath;
    return @intCast(metadata.inode);
}

pub fn joinAbsolute(allocator: std.mem.Allocator, base: []const u8, relative: []const u8) ![]u8 {
    try process.validateCanonicalAbsolute(base);
    if (relative.len == 0 or std.fs.path.isAbsolute(relative) or
        std.mem.indexOfScalar(u8, relative, 0) != null) return error.PathEscape;
    var components = std.mem.splitScalar(u8, relative, '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or
            std.mem.eql(u8, component, "..")) return error.PathEscape;
    }
    return std.fs.path.join(allocator, &.{ base, relative });
}

pub fn observeFile(
    io: std.Io,
    absolute_path: []const u8,
    executable: bool,
    maximum_bytes: u64,
    registered_worktrees: []const []const u8,
) !FileIdentity {
    _ = try validateExplicitPath(io, absolute_path, .file, registered_worktrees);
    var file = std.Io.Dir.openFileAbsolute(io, absolute_path, .{
        .mode = .read_only,
        .follow_symlinks = false,
    }) catch return error.PathEscape;
    defer file.close(io);
    const metadata = try file.stat(io);
    if (metadata.kind != .file or metadata.size == 0 or metadata.size > maximum_bytes)
        return error.InputIdentityMismatch;
    const mode: u32 = @intCast(metadata.permissions.toMode() & 0o7777);
    if (executable and std.Io.File.Permissions.has_executable_bit and mode & 0o111 == 0)
        return error.WrongExecutable;
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    var offset: u64 = 0;
    var buffer: [64 * 1024]u8 = undefined;
    while (true) {
        const count = try file.readPositional(io, &.{&buffer}, offset);
        if (count == 0) break;
        hasher.update(buffer[0..count]);
        offset = std.math.add(u64, offset, count) catch return error.StorageOverflow;
        if (offset > maximum_bytes) return error.FileCapExceeded;
    }
    if (offset != metadata.size) return error.InputIdentityMismatch;
    var digest: contract.Digest = undefined;
    hasher.final(&digest);
    return .{ .bytes = offset, .mode = mode, .inode = metadata.inode, .sha256 = digest };
}

pub fn authenticateFile(
    io: std.Io,
    absolute_path: []const u8,
    expected: ExpectedFile,
    maximum_bytes: u64,
    registered_worktrees: []const []const u8,
) !FileIdentity {
    const identity = try observeFile(io, absolute_path, expected.executable, maximum_bytes, registered_worktrees);
    if (identity.bytes != expected.bytes or
        !std.mem.eql(u8, &identity.sha256, &(try decodeSha256(expected.sha256_hex))))
        return error.InputIdentityMismatch;
    return identity;
}

pub fn authenticateSubject(
    io: std.Io,
    selector: ToolSelector,
    registered_worktrees: []const []const u8,
) !AuthenticatedSubject {
    const identity = try observeFile(io, selector.path, true, maximum_artifact_bytes, registered_worktrees);
    if (identity.bytes != selector.authorized_bytes or
        !std.mem.eql(u8, &identity.sha256, &selector.authorized_sha256))
        return error.SubjectIdentityMismatch;
    if (selector.role == .zig) {
        const version = selector.authorized_version orelse return error.SubjectAuthorityMismatch;
        if (!std.mem.eql(u8, version, expected_zig_version)) return error.SubjectAuthorityMismatch;
    } else if (selector.authorized_version != null) return error.SubjectAuthorityMismatch;
    return .{
        .path = selector.path,
        .identity = identity,
        .portable_tool = .{
            .role = selector.role,
            .bytes = selector.authorized_bytes,
            .sha256 = selector.authorized_sha256,
            .version = selector.authorized_version,
        },
    };
}

pub fn requireSubjectStable(
    io: std.Io,
    subject: AuthenticatedSubject,
    registered_worktrees: []const []const u8,
) !void {
    const current = try observeFile(io, subject.path, true, maximum_artifact_bytes, registered_worktrees);
    if (!std.meta.eql(subject.identity, current)) return error.SubjectIdentityMismatch;
    if (subject.portable_tool) |portable| {
        if (portable.bytes != current.bytes or !std.mem.eql(u8, &portable.sha256, &current.sha256))
            return error.SubjectIdentityMismatch;
    }
}

pub fn readBoundedAbsolute(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    maximum: usize,
) ![]u8 {
    var file = try std.Io.Dir.openFileAbsolute(io, path, .{ .mode = .read_only, .follow_symlinks = false });
    defer file.close(io);
    const stat = try file.stat(io);
    if (stat.kind != .file or stat.size > maximum) return error.FileCapExceeded;
    const bytes = try allocator.alloc(u8, @intCast(stat.size));
    errdefer allocator.free(bytes);
    if (try file.readPositionalAll(io, bytes, 0) != bytes.len) return error.IncompleteCapture;
    var trailing: [1]u8 = undefined;
    if (try file.readPositionalAll(io, &trailing, bytes.len) != 0) return error.IncompleteCapture;
    return bytes;
}

pub fn parseManifestLine(line: []const u8) !ManifestLine {
    if (line.len < 67) return error.ManifestMismatch;
    const digest = try decodeSha256(line[0..64]);
    if (line[64] != ' ' or (line[65] != ' ' and line[65] != '*')) return error.ManifestMismatch;
    const path = line[66..];
    if (path.len == 0 or std.fs.path.isAbsolute(path) or std.mem.indexOfScalar(u8, path, 0) != null)
        return error.ManifestMismatch;
    var components = std.mem.splitScalar(u8, path, '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or
            std.mem.eql(u8, component, "..")) return error.ManifestMismatch;
    }
    return .{ .digest = digest, .path = path };
}

fn manifestPathMatchesBundleMember(manifest_path: []const u8, required_path: []const u8) bool {
    const expected_length = std.math.add(usize, accepted_bundle_manifest_prefix.len, required_path.len) catch return false;
    return manifest_path.len == expected_length and
        std.mem.startsWith(u8, manifest_path, accepted_bundle_manifest_prefix) and
        std.mem.eql(u8, manifest_path[accepted_bundle_manifest_prefix.len..], required_path);
}

pub fn readAuthenticatedBundleMember(
    allocator: std.mem.Allocator,
    io: std.Io,
    bundle_root: []const u8,
    bundle_manifest: []const u8,
    required_path: []const u8,
    registered_worktrees: []const []const u8,
) ![]u8 {
    var found: ?contract.Digest = null;
    var previous: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, bundle_manifest, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const entry = try parseManifestLine(line);
        if (previous) |prior| if (std.mem.order(u8, prior, entry.path) != .lt) return error.ManifestMismatch;
        previous = entry.path;
        if (manifestPathMatchesBundleMember(entry.path, required_path)) {
            if (found != null) return error.ManifestMismatch;
            found = entry.digest;
        }
    }
    const expected = found orelse return error.ManifestMismatch;
    const absolute = try joinAbsolute(allocator, bundle_root, required_path);
    defer allocator.free(absolute);
    const identity = try observeFile(io, absolute, false, maximum_input_bytes, registered_worktrees);
    if (!std.mem.eql(u8, &identity.sha256, &expected)) return error.ManifestMismatch;
    return readBoundedAbsolute(allocator, io, absolute, maximum_input_bytes);
}

pub fn verifySourceManifest(
    allocator: std.mem.Allocator,
    io: std.Io,
    source_root: []const u8,
    manifest: []const u8,
    registered_worktrees: []const []const u8,
) !contract.Digest {
    var seen = std.StringHashMap(void).init(allocator);
    defer seen.deinit();
    var count: usize = 0;
    var total: u64 = 0;
    var lines = std.mem.splitScalar(u8, manifest, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const entry = try parseManifestLine(line);
        count = std.math.add(usize, count, 1) catch return error.StorageOverflow;
        if (count > 1_000_000) return error.RootCapExceeded;
        const result = try seen.getOrPut(entry.path);
        if (result.found_existing) return error.ManifestMismatch;
        const absolute = try joinAbsolute(allocator, source_root, entry.path);
        defer allocator.free(absolute);
        const identity = try observeFile(io, absolute, false, maximum_artifact_bytes, registered_worktrees);
        if (!std.mem.eql(u8, &identity.sha256, &entry.digest)) return error.ManifestMismatch;
        total = std.math.add(u64, total, identity.bytes) catch return error.StorageOverflow;
        if (total > maximum_artifact_bytes) return error.RootCapExceeded;
    }
    if (count == 0) return error.ManifestMismatch;
    return sha256(manifest);
}

pub fn verifyCompatibilityBundleMembers(
    allocator: std.mem.Allocator,
    io: std.Io,
    bundle_root: []const u8,
    bundle_manifest: []const u8,
    registered_worktrees: []const []const u8,
) !void {
    inline for (.{
        "manifests/baseline-source.sha256",         "manifests/bundled-source.sha256",
        "manifests/combined-apply-source.sha256",   "manifests/future-tool-identities.sha256",
        "manifests/patch-manifest.tsv",             "manifests/payload-final-modes.tsv",
        "manifests/preflight-and-apply-proof.txt",  "manifests/restored-source.sha256",
        "manifests/sequential-apply-source.sha256", "manifests/touched-paths.txt",
        "patches/01-aggregate-consumer.patch",      "patches/02-fixed-observer.patch",
        "patches/03-exact-combined-guard.patch",    "patches/aggregate-consumer-observer-guard.patch",
    }) |relative| {
        const bytes = try readAuthenticatedBundleMember(allocator, io, bundle_root, bundle_manifest, relative, registered_worktrees);
        allocator.free(bytes);
    }
}

fn sha256(bytes: []const u8) contract.Digest {
    var digest: contract.Digest = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    return digest;
}

test "manifest parser rejects malformed and escaping identities" {
    const zero64 = "0000000000000000000000000000000000000000000000000000000000000000";
    const valid = zero64 ++ "  src/a.zig";
    const parsed = try parseManifestLine(valid);
    try std.testing.expectEqualStrings("src/a.zig", parsed.path);
    try std.testing.expectError(error.ManifestMismatch, parseManifestLine("00  src/a.zig"));
    try std.testing.expectError(error.ManifestMismatch, parseManifestLine(zero64 ++ "  ../escape"));
    try std.testing.expectError(error.ManifestMismatch, parseManifestLine(zero64 ++ "  /absolute"));
}

test "bundle manifest namespace requires exact accepted prefix" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const required_path = "manifests/member.txt";
    const contents = "authenticated bundle member\n";
    try temporary.dir.createDirPath(io, "bundle/manifests");
    try temporary.dir.writeFile(io, .{ .sub_path = "bundle/" ++ required_path, .data = contents });
    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try temporary.dir.realPath(io, &root_buffer);
    const bundle_root = try std.fmt.allocPrint(allocator, "{s}/bundle", .{root_buffer[0..root_length]});
    defer allocator.free(bundle_root);
    const digest_hex = std.fmt.bytesToHex(sha256(contents), .lower);
    const exact = try std.fmt.allocPrint(allocator, "{s}  {s}{s}\n", .{ &digest_hex, accepted_bundle_manifest_prefix, required_path });
    defer allocator.free(exact);
    const member = try readAuthenticatedBundleMember(allocator, io, bundle_root, exact, required_path, &.{});
    defer allocator.free(member);
    try std.testing.expectEqualStrings(contents, member);

    const absent = try std.fmt.allocPrint(allocator, "{s}  {s}manifests/other.txt\n", .{ &digest_hex, accepted_bundle_manifest_prefix });
    defer allocator.free(absent);
    try std.testing.expectError(error.ManifestMismatch, readAuthenticatedBundleMember(allocator, io, bundle_root, absent, required_path, &.{}));
    const unprefixed = try std.fmt.allocPrint(allocator, "{s}  {s}\n", .{ &digest_hex, required_path });
    defer allocator.free(unprefixed);
    try std.testing.expectError(error.ManifestMismatch, readAuthenticatedBundleMember(allocator, io, bundle_root, unprefixed, required_path, &.{}));
    const wrong_prefix = try std.fmt.allocPrint(allocator, "{s}  wrong/{s}\n", .{ &digest_hex, required_path });
    defer allocator.free(wrong_prefix);
    try std.testing.expectError(error.ManifestMismatch, readAuthenticatedBundleMember(allocator, io, bundle_root, wrong_prefix, required_path, &.{}));
    const duplicate = try std.fmt.allocPrint(allocator, "{s}{s}", .{ exact, exact });
    defer allocator.free(duplicate);
    try std.testing.expectError(error.ManifestMismatch, readAuthenticatedBundleMember(allocator, io, bundle_root, duplicate, required_path, &.{}));
    var wrong_digest = sha256(contents);
    wrong_digest[0] ^= 1;
    const wrong_hex = std.fmt.bytesToHex(wrong_digest, .lower);
    const mismatch = try std.fmt.allocPrint(allocator, "{s}  {s}{s}\n", .{ &wrong_hex, accepted_bundle_manifest_prefix, required_path });
    defer allocator.free(mismatch);
    try std.testing.expectError(error.ManifestMismatch, readAuthenticatedBundleMember(allocator, io, bundle_root, mismatch, required_path, &.{}));
}

test "source manifest preserves accepted nonlexical order and rejects duplicates" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    try temporary.dir.writeFile(io, .{ .sub_path = "z.zig", .data = "z\n" });
    try temporary.dir.writeFile(io, .{ .sub_path = "a.zig", .data = "a\n" });
    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try temporary.dir.realPath(io, &root_buffer);
    const source_root = root_buffer[0..root_length];
    const z_hex = std.fmt.bytesToHex(sha256("z\n"), .lower);
    const a_hex = std.fmt.bytesToHex(sha256("a\n"), .lower);
    const manifest = try std.fmt.allocPrint(allocator, "{s}  z.zig\n{s}  a.zig\n", .{ &z_hex, &a_hex });
    defer allocator.free(manifest);
    try std.testing.expectEqual(sha256(manifest), try verifySourceManifest(allocator, io, source_root, manifest, &.{}));
    const duplicate = try std.fmt.allocPrint(allocator, "{s}  z.zig\n{s}  z.zig\n", .{ &z_hex, &z_hex });
    defer allocator.free(duplicate);
    try std.testing.expectError(error.ManifestMismatch, verifySourceManifest(allocator, io, source_root, duplicate, &.{}));
}
