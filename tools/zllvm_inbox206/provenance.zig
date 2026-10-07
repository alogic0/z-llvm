const std = @import("std");

pub const canonical_repository_path_max = 256;
pub const canonical_git_sha1_algorithm: u8 = 1;
pub const canonical_provenance_protocol_version: u16 = 1;
pub const capability_source_count = 5;
pub const capability_source_mode: u32 = 0o100644;

pub const capability_source_paths = [capability_source_count][]const u8{
    "tools/zllvm_inbox206/acceptance_driver.zig",
    "tools/zllvm_inbox206/acceptance_driver_test.zig",
    "tools/zllvm_inbox206/provenance.zig",
    "tools/zllvm_inbox206/receipt.zig",
    "tools/zllvm_inbox206_materialize.zig",
};

pub const GitSha1Identity = struct {
    bytes: [20]u8,
};

pub const RawSha256Identity = struct {
    bytes: [std.crypto.hash.sha2.Sha256.digest_length]u8,
};

pub const ProducerIdentity = struct {
    bytes: [32]u8,
};

pub const ProtocolIdentity = struct {
    bytes: [32]u8,
};

pub const CanonicalRepositoryPath = struct {
    length: u16,
    bytes: [canonical_repository_path_max]u8,
};

pub const CanonicalSourceIdentity = struct {
    path: CanonicalRepositoryPath,
    mode: u32,
    git_blob_identity: GitSha1Identity,
    raw_sha256: RawSha256Identity,
    exact_length: u64,
};

pub const CanonicalSourceSet = struct {
    entries: [capability_source_count]CanonicalSourceIdentity,
};

pub const CanonicalProvenanceTuple = struct {
    commit: GitSha1Identity,
    tree: GitSha1Identity,
    repository_relative_path: CanonicalRepositoryPath,
    git_object_id: GitSha1Identity,
    git_object_hash_algorithm: u8,
    raw_sha256: RawSha256Identity,
    exact_raw_length: u64,
    producer_identity: ProducerIdentity,
    protocol_identity: ProtocolIdentity,
    protocol_version: u16,
};

pub const ProvenanceAuthorityOrigin = enum {
    independent,
    tuple_self_asserted,
};

pub const TrustedProducerAuthority = struct {
    origin: ProvenanceAuthorityOrigin,
    identity: ProducerIdentity,
};

pub const TrustedProtocolAuthority = struct {
    origin: ProvenanceAuthorityOrigin,
    identity: ProtocolIdentity,
    version: u16,
};

pub const TrustedProvenanceAuthority = struct {
    binding_origin: ProvenanceAuthorityOrigin,
    producer: ?TrustedProducerAuthority,
    protocol: ?TrustedProtocolAuthority,
    expected: CanonicalProvenanceTuple,
};

pub const ProvenanceError = error{
    ProvenanceAuthorityMissing,
    ProvenanceProducerAuthorityMissing,
    ProvenanceProtocolAuthorityMissing,
    ProvenanceCircularAuthority,
    ProvenancePathMalformed,
    ProvenanceGitObjectHashAlgorithmUnsupported,
    ProvenanceProtocolVersionUnsupported,
    ProvenanceCommitMismatch,
    ProvenanceTreeMismatch,
    ProvenancePathMismatch,
    ProvenanceGitObjectMismatch,
    ProvenanceGitObjectHashAlgorithmMismatch,
    ProvenanceRawSha256Mismatch,
    ProvenanceRawLengthMismatch,
    ProvenanceProducerIdentityMismatch,
    ProvenanceProtocolIdentityMismatch,
    ProvenanceProtocolVersionMismatch,
    SourceSetPathMismatch,
    SourceSetModeMismatch,
    SourceSetBlobMismatch,
    SourceSetRawDigestMismatch,
    SourceSetLengthMismatch,
};

pub fn fixedIdentity(comptime length: usize, seed: u8) [length]u8 {
    var result: [length]u8 = undefined;
    for (&result, 0..) |*byte, index| {
        byte.* = seed +% @as(u8, @truncate(index * 17));
    }
    return result;
}

pub fn validateCanonicalRepositoryPath(path: *const CanonicalRepositoryPath) ProvenanceError!void {
    const length = @as(usize, path.length);
    if (length == 0 or length > path.bytes.len) return error.ProvenancePathMalformed;
    const used = path.bytes[0..length];
    if (used[0] == '/' or used[length - 1] == '/') return error.ProvenancePathMalformed;

    var component_start: usize = 0;
    for (used, 0..) |byte, index| {
        if (byte == 0) return error.ProvenancePathMalformed;
        if (byte != '/') continue;
        if (index == component_start) return error.ProvenancePathMalformed;
        const component = used[component_start..index];
        if (std.mem.eql(u8, component, ".") or std.mem.eql(u8, component, "..")) {
            return error.ProvenancePathMalformed;
        }
        component_start = index + 1;
    }
    const final_component = used[component_start..];
    if (std.mem.eql(u8, final_component, ".") or
        std.mem.eql(u8, final_component, ".."))
    {
        return error.ProvenancePathMalformed;
    }
    for (path.bytes[length..]) |byte| {
        if (byte != 0) return error.ProvenancePathMalformed;
    }
}

pub fn canonicalRepositoryPath(input: []const u8) ProvenanceError!CanonicalRepositoryPath {
    if (input.len == 0 or input.len > canonical_repository_path_max) {
        return error.ProvenancePathMalformed;
    }
    var result = CanonicalRepositoryPath{
        .length = @intCast(input.len),
        .bytes = @splat(0),
    };
    @memcpy(result.bytes[0..input.len], input);
    try validateCanonicalRepositoryPath(&result);
    return result;
}

pub fn equalGitIdentity(a: GitSha1Identity, b: GitSha1Identity) bool {
    return std.mem.eql(u8, &a.bytes, &b.bytes);
}

pub fn equalRawIdentity(a: RawSha256Identity, b: RawSha256Identity) bool {
    return std.mem.eql(u8, &a.bytes, &b.bytes);
}

pub fn equalProducerIdentity(a: ProducerIdentity, b: ProducerIdentity) bool {
    return std.mem.eql(u8, &a.bytes, &b.bytes);
}

pub fn equalProtocolIdentity(a: ProtocolIdentity, b: ProtocolIdentity) bool {
    return std.mem.eql(u8, &a.bytes, &b.bytes);
}

pub fn equalCanonicalPath(a: *const CanonicalRepositoryPath, b: *const CanonicalRepositoryPath) bool {
    return a.length == b.length and std.mem.eql(u8, &a.bytes, &b.bytes);
}

pub fn equalCanonicalSourceIdentity(
    left: *const CanonicalSourceIdentity,
    right: *const CanonicalSourceIdentity,
) bool {
    return equalCanonicalPath(&left.path, &right.path) and
        left.mode == right.mode and
        equalGitIdentity(left.git_blob_identity, right.git_blob_identity) and
        equalRawIdentity(left.raw_sha256, right.raw_sha256) and
        left.exact_length == right.exact_length;
}

pub fn equalCanonicalSourceSet(
    left: *const CanonicalSourceSet,
    right: *const CanonicalSourceSet,
) bool {
    for (&left.entries, &right.entries) |*left_entry, *right_entry| {
        if (!equalCanonicalSourceIdentity(left_entry, right_entry)) return false;
    }
    return true;
}

pub fn validateCanonicalSourceSet(source_set: *const CanonicalSourceSet) ProvenanceError!void {
    for (&source_set.entries, capability_source_paths) |*entry, expected_path| {
        try validateCanonicalRepositoryPath(&entry.path);
        const canonical_path = try canonicalRepositoryPath(expected_path);
        if (!equalCanonicalPath(&entry.path, &canonical_path)) {
            return error.SourceSetPathMismatch;
        }
        if (entry.mode != capability_source_mode) return error.SourceSetModeMismatch;
        if (entry.exact_length == 0) return error.SourceSetLengthMismatch;
    }
}

pub fn gitBlobIdentity(bytes: []const u8) GitSha1Identity {
    var length_buffer: [32]u8 = undefined;
    const length = std.fmt.bufPrint(&length_buffer, "{d}", .{bytes.len}) catch unreachable;
    var hasher = std.crypto.hash.Sha1.init(.{});
    hasher.update("blob ");
    hasher.update(length);
    hasher.update(&.{0});
    hasher.update(bytes);
    return .{ .bytes = hasher.finalResult() };
}

pub fn canonicalSourceIdentity(
    path: []const u8,
    bytes: []const u8,
) ProvenanceError!CanonicalSourceIdentity {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    return .{
        .path = try canonicalRepositoryPath(path),
        .mode = capability_source_mode,
        .git_blob_identity = gitBlobIdentity(bytes),
        .raw_sha256 = .{ .bytes = digest },
        .exact_length = @intCast(bytes.len),
    };
}

pub fn canonicalSourceSetFromBytes(
    source_bytes: [capability_source_count][]const u8,
) ProvenanceError!CanonicalSourceSet {
    var result: CanonicalSourceSet = undefined;
    for (capability_source_paths, source_bytes, 0..) |path, bytes, index| {
        result.entries[index] = try canonicalSourceIdentity(path, bytes);
    }
    try validateCanonicalSourceSet(&result);
    return result;
}

pub fn validateProvenanceAuthority(
    claimed: *const CanonicalProvenanceTuple,
    supplied_authority: ?*const TrustedProvenanceAuthority,
) ProvenanceError!void {
    const authority = supplied_authority orelse return error.ProvenanceAuthorityMissing;
    if (authority.binding_origin != .independent) return error.ProvenanceCircularAuthority;
    const producer = authority.producer orelse return error.ProvenanceProducerAuthorityMissing;
    const protocol = authority.protocol orelse return error.ProvenanceProtocolAuthorityMissing;
    if (producer.origin != .independent or protocol.origin != .independent) {
        return error.ProvenanceCircularAuthority;
    }

    try validateCanonicalRepositoryPath(&claimed.repository_relative_path);
    try validateCanonicalRepositoryPath(&authority.expected.repository_relative_path);

    if (!equalProducerIdentity(producer.identity, authority.expected.producer_identity)) {
        return error.ProvenanceProducerIdentityMismatch;
    }
    if (!equalProtocolIdentity(protocol.identity, authority.expected.protocol_identity)) {
        return error.ProvenanceProtocolIdentityMismatch;
    }
    if (protocol.version != authority.expected.protocol_version) {
        return error.ProvenanceProtocolVersionMismatch;
    }

    if (!equalGitIdentity(claimed.commit, authority.expected.commit)) {
        return error.ProvenanceCommitMismatch;
    }
    if (!equalGitIdentity(claimed.tree, authority.expected.tree)) {
        return error.ProvenanceTreeMismatch;
    }
    if (!equalCanonicalPath(
        &claimed.repository_relative_path,
        &authority.expected.repository_relative_path,
    )) {
        return error.ProvenancePathMismatch;
    }
    if (!equalGitIdentity(claimed.git_object_id, authority.expected.git_object_id)) {
        return error.ProvenanceGitObjectMismatch;
    }
    if (claimed.git_object_hash_algorithm != authority.expected.git_object_hash_algorithm) {
        return error.ProvenanceGitObjectHashAlgorithmMismatch;
    }
    if (!equalRawIdentity(claimed.raw_sha256, authority.expected.raw_sha256)) {
        return error.ProvenanceRawSha256Mismatch;
    }
    if (claimed.exact_raw_length != authority.expected.exact_raw_length) {
        return error.ProvenanceRawLengthMismatch;
    }
    if (!equalProducerIdentity(claimed.producer_identity, authority.expected.producer_identity)) {
        return error.ProvenanceProducerIdentityMismatch;
    }
    if (!equalProtocolIdentity(claimed.protocol_identity, authority.expected.protocol_identity)) {
        return error.ProvenanceProtocolIdentityMismatch;
    }
    if (claimed.protocol_version != authority.expected.protocol_version) {
        return error.ProvenanceProtocolVersionMismatch;
    }

    if (claimed.git_object_hash_algorithm != canonical_git_sha1_algorithm) {
        return error.ProvenanceGitObjectHashAlgorithmUnsupported;
    }
    if (claimed.protocol_version != canonical_provenance_protocol_version) {
        return error.ProvenanceProtocolVersionUnsupported;
    }
}

pub fn syntheticCanonicalProvenance(
    bytes: []const u8,
    path: []const u8,
) ProvenanceError!CanonicalProvenanceTuple {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    return .{
        .commit = .{ .bytes = fixedIdentity(20, 0x11) },
        .tree = .{ .bytes = fixedIdentity(20, 0x22) },
        .repository_relative_path = try canonicalRepositoryPath(path),
        .git_object_id = .{ .bytes = fixedIdentity(20, 0x33) },
        .git_object_hash_algorithm = canonical_git_sha1_algorithm,
        .raw_sha256 = .{ .bytes = digest },
        .exact_raw_length = @intCast(bytes.len),
        .producer_identity = .{ .bytes = fixedIdentity(32, 0x44) },
        .protocol_identity = .{ .bytes = fixedIdentity(32, 0x55) },
        .protocol_version = canonical_provenance_protocol_version,
    };
}

pub fn independentProvenanceAuthority(
    expected: CanonicalProvenanceTuple,
) TrustedProvenanceAuthority {
    return .{
        .binding_origin = .independent,
        .producer = .{
            .origin = .independent,
            .identity = expected.producer_identity,
        },
        .protocol = .{
            .origin = .independent,
            .identity = expected.protocol_identity,
            .version = expected.protocol_version,
        },
        .expected = expected,
    };
}
