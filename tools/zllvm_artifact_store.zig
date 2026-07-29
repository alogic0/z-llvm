const std = @import("std");
const capacity = @import("zllvm_artifact_store/capacity.zig");
const canonical_source = @import("zllvm_artifact_store/canonical_source.zig");
const exact_real_test_support =
    @import("zllvm_artifact_store/exact_real_test_support.zig");
const filesystem = @import("zllvm_artifact_store/filesystem.zig");
const identity_model = @import("zllvm_artifact_store/identity.zig");
const manifest_model = @import("zllvm_artifact_store/manifest.zig");
const registration = @import("zllvm_artifact_store/registration.zig");
const readiness_test_support =
    @import("zllvm_artifact_store/readiness_test_support.zig");
const store_model = @import("zllvm_artifact_store/store.zig");
const store_test_support = @import("zllvm_artifact_store/store_test_support.zig");

const main_git_common_dir = registration.main_git_common_dir;
const canonical_source_spec_path = canonical_source.canonical_source_spec_path;
const syncDirectory = filesystem.syncDirectory;
const planCanonicalSourceSpec = canonical_source.planCanonicalSourceSpec;

pub const RowKind = manifest_model.RowKind;
pub const Status = manifest_model.Status;
pub const RetentionClass = manifest_model.RetentionClass;
pub const Row = manifest_model.Row;
pub const Manifest = manifest_model.Manifest;
pub const parseManifest = manifest_model.parseManifest;
pub const encodeManifest = manifest_model.encodeManifest;

pub const RegistrationSnapshot = registration.RegistrationSnapshot;
pub const parseRegistration = registration.parseRegistration;
pub const RegistrationGuard = registration.RegistrationGuard;

pub const FileIdentity = identity_model.FileIdentity;
pub const SnapshotIdentity = identity_model.SnapshotIdentity;

pub const CapacityObservation = capacity.CapacityObservation;
pub const CapacityRequirement = capacity.CapacityRequirement;
pub const Store = store_model.Store;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    const command = args.next() orelse return error.MissingCommand;
    if (std.mem.eql(u8, command, "resolve-authority")) {
        if (args.next() != null) return error.UnknownOption;
        const environment_value = init.minimal.environ.getAlloc(
            allocator,
            "ZLLVM_ARTIFACT_STORE",
        ) catch |err| switch (err) {
            error.EnvironmentVariableMissing => null,
            else => return err,
        };
        defer if (environment_value) |value| allocator.free(value);
        const resolved = try resolveAuthority(allocator, environment_value, main_git_common_dir);
        defer allocator.free(resolved);
        try writeStdoutLine(io, resolved);
        return;
    }
    if (!std.mem.eql(u8, command, "materialize-spec")) return error.UnsupportedCommand;
    const mode = args.next() orelse return error.MissingMaterializeMode;
    const spec_path = args.next() orelse return error.MissingSourceSpecification;
    if (args.next() != null) return error.UnknownOption;
    if (!std.mem.eql(u8, spec_path, canonical_source_spec_path)) {
        return error.UnexpectedSourceSpecification;
    }
    if (std.mem.eql(u8, mode, "plan")) {
        const proposed = try planCanonicalSourceSpec(allocator, io, spec_path);
        defer allocator.free(proposed);
        try writeStdout(io, proposed);
        return;
    }
    if (!std.mem.eql(u8, mode, "publish")) return error.UnknownMaterializeMode;
    const environment_value = try init.minimal.environ.getAlloc(allocator, "ZLLVM_ARTIFACT_STORE");
    defer allocator.free(environment_value);
    const root = try resolveAuthority(allocator, environment_value, main_git_common_dir);
    defer allocator.free(root);
    const manifest = try canonical_source.publishCanonicalSourceSpec(
        allocator,
        io,
        spec_path,
        root,
        createAbsoluteDirectorySynced,
    );
    defer allocator.free(manifest);
    try writeStdout(io, manifest);
}

fn writeStdout(io: std.Io, text: []const u8) !void {
    var buffer: [1024]u8 = undefined;
    var writer = std.Io.File.stdout().writer(io, &buffer);
    try writer.interface.writeAll(text);
    try writer.interface.flush();
}

fn writeStdoutLine(io: std.Io, text: []const u8) !void {
    var buffer: [1024]u8 = undefined;
    var writer = std.Io.File.stdout().writer(io, &buffer);
    try writer.interface.print("{s}\n", .{text});
    try writer.interface.flush();
}

fn prepareStoreRoot(
    allocator: std.mem.Allocator,
    io: std.Io,
    guard: *const RegistrationGuard,
    root_path: []const u8,
) !void {
    return canonical_source.prepareStoreRoot(
        allocator,
        io,
        guard,
        root_path,
        createAbsoluteDirectorySynced,
    );
}

pub fn resolveAuthority(
    allocator: std.mem.Allocator,
    environment_value: ?[]const u8,
    git_common_dir: []const u8,
) ![]u8 {
    if (environment_value) |value| {
        if (!std.fs.path.isAbsolute(value)) return error.PathNotAbsolute;
        const normalized = try std.fs.path.resolve(allocator, &.{value});
        errdefer allocator.free(normalized);
        if (!std.mem.eql(u8, normalized, value)) return error.PathNotNormalized;
        return normalized;
    }
    if (!std.fs.path.isAbsolute(git_common_dir) or
        !std.mem.eql(u8, std.fs.path.basename(git_common_dir), ".git"))
    {
        return error.InvalidGitCommonDirectory;
    }
    const main_root = std.fs.path.dirname(git_common_dir) orelse return error.InvalidGitCommonDirectory;
    const parent = std.fs.path.dirname(main_root) orelse return error.InvalidGitCommonDirectory;
    const name = std.fs.path.basename(main_root);
    const store_name = try std.fmt.allocPrint(allocator, "{s}-artifacts", .{name});
    defer allocator.free(store_name);
    return std.fs.path.join(allocator, &.{ parent, store_name });
}

fn createAbsoluteDirectorySynced(
    io: std.Io,
    absolute_path: []const u8,
) !void {
    const parent_path = std.fs.path.dirname(absolute_path) orelse return error.InvalidRootPath;
    const basename = std.fs.path.basename(absolute_path);
    var parent = try std.Io.Dir.openDirAbsolute(io, parent_path, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer parent.close(io);
    try parent.createDir(io, basename, .default_dir);
    var created = try parent.openDir(io, basename, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer created.close(io);
    try syncDirectory(created);
    try syncDirectory(parent);
}

fn removeAbsoluteDirectorySynced(io: std.Io, absolute_path: []const u8) !void {
    const parent_path = std.fs.path.dirname(absolute_path) orelse return error.InvalidRootPath;
    const basename = std.fs.path.basename(absolute_path);
    var parent = try std.Io.Dir.openDirAbsolute(io, parent_path, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer parent.close(io);
    try parent.deleteTree(io, basename);
    try syncDirectory(parent);
}

test "dormant exact-real acceptance gate precedes real paths" {
    try exact_real_test_support.acceptanceGatePrecedesRealPaths();
}
test "dormant exact-real copy evidence verifies actual held-root bytes" {
    try exact_real_test_support.copyEvidenceVerifiesActualHeldRootBytes();
}
test "dormant exact-real copy evidence is unchanged in finite observer" {
    try exact_real_test_support.copyEvidenceIsUnchangedInFiniteObserver();
}
test "dormant exact-real acceptance receipt encoding is canonical" {
    try exact_real_test_support.acceptanceReceiptEncodingIsCanonical();
}
test "dormant exact-real observer detects finite path and logical controls" {
    try exact_real_test_support.observerDetectsFinitePathAndLogicalControls();
}
test "dormant exact-real acceptance receipt publication is durable and no-replace" {
    try exact_real_test_support.acceptanceReceiptPublicationIsDurableAndNoReplace();
}
test "INBOX-206CQ exact-real acceptance one-shot" {
    try exact_real_test_support.acceptanceOneShot();
}
test "dormant readiness snapshot ownership unwinds later allocation failure" {
    try readiness_test_support.readinessSnapshotOwnershipUnwindsLaterAllocationFailure();
}
test "dormant authority candidate validates only closed synthetic state" {
    try readiness_test_support.authorityCandidateValidatesOnlyClosedSyntheticState();
}
test "authority resolution is closed and default remains read only" {
    try store_test_support.authorityResolutionIsClosed(resolveAuthority);
}
test "published snapshot generator binds every member to its exact object key" {
    try store_test_support.publishedSnapshotGeneratorBindsEveryMember();
}
test "snapshot listing validation is closed to sorted regular members" {
    try store_test_support.snapshotListingValidationIsClosed();
}
test "canonical calls source specification is closed and produces canonical proposed rows" {
    try store_test_support.canonicalSourceSpecificationIsClosed();
}
test "synthetic store publishes verifies snapshots and resolves without overwrite" {
    try store_test_support.syntheticStorePublishesAndResolves(resolveAuthority, prepareStoreRoot, removeAbsoluteDirectorySynced);
}
