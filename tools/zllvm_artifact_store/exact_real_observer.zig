const std = @import("std");
const builtin = @import("builtin");
const authority_control = @import("authority_control.zig");
const digest = @import("digest.zig");
const filesystem = @import("filesystem.zig");
const identity_model = @import("identity.zig");
const manifest_model = @import("manifest.zig");
const registration = @import("registration.zig");

const dormant_generation_key = authority_control.API.generation_key;
const dormant_receipt_key = authority_control.API.receipt_key;
const dormant_git_executable = authority_control.API.git_executable;
const ControlGitObservation = authority_control.API.ControlObservation;
const DormantAuthorityConfig = authority_control.API.AuthorityConfig;
const readDormantControlFile = authority_control.API.readControlFile;
const sha256Hex = digest.sha256Hex;
const openPathNoFollow = filesystem.openPathNoFollow;
const identityOfOpenFileAnyMode = identity_model.identityOfOpenFileAnyMode;
const parseManifest = manifest_model.parseManifest;
const RegistrationSnapshot = registration.RegistrationSnapshot;

const DormantReadinessNetEffects = struct {
    created_paths: usize = 0,
    removed_paths: usize = 0,
    modified_paths: usize = 0,
    publication_path_changes: usize = 0,
    logical_state_modified: bool = false,

    pub fn isUnchanged(effects: DormantReadinessNetEffects) bool {
        return effects.created_paths == 0 and
            effects.removed_paths == 0 and
            effects.modified_paths == 0 and
            effects.publication_path_changes == 0 and
            !effects.logical_state_modified;
    }
};

fn appendDormantReadinessField(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    value: []const u8,
) !void {
    try output.print(allocator, "{}:", .{value.len});
    try output.appendSlice(allocator, value);
    try output.append(allocator, '\n');
}

fn appendDormantReadinessInteger(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    value: anytype,
) !void {
    try output.print(allocator, "{}\n", .{value});
}

fn appendDormantControlObservationState(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    observation: *const ControlGitObservation,
) !void {
    try appendDormantReadinessField(allocator, output, &observation.commit);
    try appendDormantReadinessField(allocator, output, &observation.tree);
    try appendDormantReadinessField(allocator, output, observation.branch);
    try appendDormantReadinessField(allocator, output, observation.status);
    try appendDormantReadinessField(allocator, output, observation.remotes);
    try appendDormantReadinessInteger(allocator, output, observation.entries.len);
    for (observation.entries) |entry| {
        try appendDormantReadinessField(allocator, output, &entry.mode);
        try appendDormantReadinessField(allocator, output, &entry.kind);
        try appendDormantReadinessField(allocator, output, &entry.object_id);
        try appendDormantReadinessField(allocator, output, entry.path);
    }
}

fn appendDormantRegistrationState(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    snapshot: *const RegistrationSnapshot,
) !void {
    try appendDormantReadinessField(allocator, output, snapshot.raw);
    try appendDormantReadinessInteger(allocator, output, snapshot.paths.len);
    for (snapshot.paths) |path| {
        try appendDormantReadinessField(allocator, output, path);
    }
    try appendDormantReadinessField(allocator, output, &snapshot.full_hash);
    try appendDormantReadinessField(allocator, output, &snapshot.path_hash);
    try appendDormantReadinessField(allocator, output, &snapshot.topology_hash);
    try appendDormantReadinessField(allocator, output, &snapshot.non_main_hash);
    try appendDormantReadinessInteger(allocator, output, snapshot.repository_tmp_count);
    try appendDormantReadinessInteger(allocator, output, snapshot.system_tmp_count);
    try appendDormantReadinessInteger(allocator, output, snapshot.other_count);
}

fn appendDormantLogicalState(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    config: *const DormantAuthorityConfig,
) !void {
    try appendDormantReadinessField(allocator, output, config.control_root);
    try appendDormantReadinessField(allocator, output, config.authority_root);
    try appendDormantReadinessField(allocator, output, config.payload_root);
    try appendDormantReadinessField(allocator, output, config.source_root);
    try appendDormantReadinessField(allocator, output, &config.source_manifest_sha256);
    try appendDormantReadinessField(
        allocator,
        output,
        &config.expected_source_inventory_sha256,
    );
    try appendDormantReadinessField(
        allocator,
        output,
        &config.expected_source_file_ledger_sha256,
    );
    try appendDormantReadinessField(
        allocator,
        output,
        &config.expected_source_destination_ledger_sha256,
    );
    try appendDormantReadinessField(allocator, output, config.expected_copy_evidence_path);
    try appendDormantReadinessField(allocator, output, &config.expected_copy_evidence_sha256);
    try appendDormantReadinessField(allocator, output, &config.expected_registration_full_hash);
    try appendDormantReadinessField(allocator, output, &config.expected_registration_path_hash);
    try appendDormantReadinessField(
        allocator,
        output,
        &config.expected_registration_topology_hash,
    );
    try appendDormantReadinessField(
        allocator,
        output,
        &config.expected_registration_non_main_hash,
    );

    const policy = &config.root_policy;
    try appendDormantReadinessField(allocator, output, @tagName(policy.kind));
    try appendDormantReadinessField(allocator, output, policy.main_root);
    try appendDormantReadinessField(allocator, output, policy.control_root);
    try appendDormantReadinessField(allocator, output, policy.authority_root);
    try appendDormantReadinessField(allocator, output, policy.payload_root);
    try appendDormantReadinessField(allocator, output, policy.source_root);
    try appendDormantReadinessField(allocator, output, policy.supplemental_control_root);
    try appendDormantReadinessInteger(allocator, output, policy.non_main_roots.len);
    for (policy.non_main_roots) |path| {
        try appendDormantReadinessField(allocator, output, path);
    }
    try appendDormantReadinessInteger(allocator, output, policy.control_files.len);
    for (policy.control_files) |expectation| {
        try appendDormantReadinessField(
            allocator,
            output,
            @tagName(expectation.component),
        );
        try appendDormantReadinessField(allocator, output, expectation.path);
        try appendDormantReadinessField(allocator, output, &expectation.sha256);
        try appendDormantReadinessInteger(allocator, output, expectation.bytes);
        try appendDormantReadinessInteger(allocator, output, expectation.mode);
    }
    try appendDormantControlObservationState(allocator, output, &policy.observed_control);
    try appendDormantControlObservationState(allocator, output, &policy.expected_control);
    try appendDormantRegistrationState(allocator, output, &config.guard.frozen);
}

const DormantExactAcceptanceSnapshotIdentity = struct {
    bytes: u64,
    sha256: [64]u8,
};

const DormantExactObserverPathSpec = struct {
    label: []u8,
    path: []u8,
    unexpected_publication: bool,

    fn deinit(spec: *DormantExactObserverPathSpec, allocator: std.mem.Allocator) void {
        allocator.free(spec.path);
        allocator.free(spec.label);
        spec.* = undefined;
    }
};

const DormantExactObserverRow = struct {
    label: []u8,
    path: []u8,
    state: []u8,
    exists: bool,
    logical: bool,
    unexpected_publication: bool,

    pub fn deinit(row: *DormantExactObserverRow, allocator: std.mem.Allocator) void {
        allocator.free(row.state);
        allocator.free(row.path);
        allocator.free(row.label);
        row.* = undefined;
    }
};

const DormantExactRealObservation = struct {
    allocator: std.mem.Allocator,
    rows: []DormantExactObserverRow,
    identity: DormantExactAcceptanceSnapshotIdentity,

    pub fn deinit(observation: *DormantExactRealObservation) void {
        for (observation.rows) |*row| row.deinit(observation.allocator);
        observation.allocator.free(observation.rows);
        observation.* = undefined;
    }
};

fn appendDormantExactObserverSpec(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    label: []const u8,
    path: []const u8,
    unexpected_publication: bool,
) !void {
    for (specs.items) |existing| {
        if (std.mem.eql(u8, existing.label, label) or
            std.mem.eql(u8, existing.path, path))
        {
            if (!std.mem.eql(u8, existing.label, label) or
                !std.mem.eql(u8, existing.path, path) or
                existing.unexpected_publication != unexpected_publication)
            {
                return error.DormantExactObserverAmbiguousPath;
            }
            return;
        }
    }
    const owned_label = try allocator.dupe(u8, label);
    errdefer allocator.free(owned_label);
    const owned_path = try allocator.dupe(u8, path);
    errdefer allocator.free(owned_path);
    try specs.append(allocator, .{
        .label = owned_label,
        .path = owned_path,
        .unexpected_publication = unexpected_publication,
    });
}

fn appendDormantExactObserverAllocatedSpec(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    label: []const u8,
    path: []const u8,
    unexpected_publication: bool,
) !void {
    try appendDormantExactObserverSpec(
        allocator,
        specs,
        label,
        path,
        unexpected_publication,
    );
}

fn appendDormantExactObserverAncestors(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    root: []const u8,
    domain: []const u8,
    relative_path: []const u8,
) !void {
    const parent = std.fs.path.dirname(relative_path) orelse return;
    if (std.mem.eql(u8, parent, ".")) return;
    var prefix: std.ArrayList(u8) = .empty;
    defer prefix.deinit(allocator);
    var segments = std.mem.splitScalar(u8, parent, '/');
    while (segments.next()) |segment| {
        if (prefix.items.len != 0) try prefix.append(allocator, '/');
        try prefix.appendSlice(allocator, segment);
        const label = try std.fmt.allocPrint(
            allocator,
            "{s}-directory:{s}",
            .{ domain, prefix.items },
        );
        defer allocator.free(label);
        const path = try std.fs.path.join(allocator, &.{ root, prefix.items });
        defer allocator.free(path);
        try appendDormantExactObserverAllocatedSpec(
            allocator,
            specs,
            label,
            path,
            false,
        );
    }
}

fn appendDormantExactObserverFileSpec(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    root: []const u8,
    domain: []const u8,
    relative_path: []const u8,
) !void {
    try appendDormantExactObserverAncestors(
        allocator,
        specs,
        root,
        domain,
        relative_path,
    );
    const label = try std.fmt.allocPrint(
        allocator,
        "{s}-file:{s}",
        .{ domain, relative_path },
    );
    defer allocator.free(label);
    const path = try std.fs.path.join(allocator, &.{ root, relative_path });
    defer allocator.free(path);
    try appendDormantExactObserverAllocatedSpec(allocator, specs, label, path, false);
}

fn dormantExactObserverRowLessThan(
    _: void,
    a: DormantExactObserverRow,
    b: DormantExactObserverRow,
) bool {
    const label_order = std.mem.order(u8, a.label, b.label);
    if (label_order != .eq) return label_order == .lt;
    return std.mem.order(u8, a.path, b.path) == .lt;
}

fn captureDormantExactObserverRowFromDir(
    allocator: std.mem.Allocator,
    io: std.Io,
    directory: std.Io.Dir,
    basename: []const u8,
    label: []const u8,
    canonical_path: []const u8,
    unexpected_publication: bool,
) !DormantExactObserverRow {
    const owned_label = try allocator.dupe(u8, label);
    errdefer allocator.free(owned_label);
    const owned_path = try allocator.dupe(u8, canonical_path);
    errdefer allocator.free(owned_path);
    var state: std.ArrayList(u8) = .empty;
    errdefer state.deinit(allocator);
    const stat = directory.statFile(io, basename, .{ .follow_symlinks = false }) catch |err|
        switch (err) {
            error.FileNotFound => {
                try appendDormantReadinessField(allocator, &state, "absent");
                return .{
                    .label = owned_label,
                    .path = owned_path,
                    .state = try state.toOwnedSlice(allocator),
                    .exists = false,
                    .logical = false,
                    .unexpected_publication = unexpected_publication,
                };
            },
            else => return err,
        };
    try appendDormantReadinessField(allocator, &state, "present");
    try appendDormantReadinessField(allocator, &state, @tagName(stat.kind));
    try appendDormantReadinessInteger(
        allocator,
        &state,
        @as(u16, @intCast(stat.permissions.toMode() & 0o7777)),
    );
    try appendDormantReadinessInteger(allocator, &state, stat.inode);
    try appendDormantReadinessInteger(allocator, &state, stat.nlink);
    try appendDormantReadinessInteger(allocator, &state, stat.size);
    if (stat.kind == .file) {
        var file = try directory.openFile(io, basename, .{
            .allow_directory = false,
            .follow_symlinks = false,
        });
        defer file.close(io);
        var identity = try identityOfOpenFileAnyMode(allocator, io, file);
        defer identity.deinit(allocator);
        if (identity.bytes != stat.size or
            identity.mode != @as(u16, @intCast(stat.permissions.toMode() & 0o7777)))
        {
            return error.DormantExactObserverPathDrift;
        }
        try appendDormantReadinessField(allocator, &state, &identity.sha256);
    } else {
        try appendDormantReadinessField(allocator, &state, "not-applicable");
    }
    return .{
        .label = owned_label,
        .path = owned_path,
        .state = try state.toOwnedSlice(allocator),
        .exists = true,
        .logical = false,
        .unexpected_publication = unexpected_publication,
    };
}

fn captureDormantExactObserverAbsoluteRow(
    allocator: std.mem.Allocator,
    io: std.Io,
    spec: DormantExactObserverPathSpec,
) !DormantExactObserverRow {
    const parent_path = std.fs.path.dirname(spec.path) orelse
        return error.DormantExactObserverUnsafePath;
    const basename = std.fs.path.basename(spec.path);
    var parent = std.Io.Dir.openDirAbsolute(io, parent_path, .{
        .access_sub_paths = true,
        .follow_symlinks = false,
    }) catch |err| switch (err) {
        error.FileNotFound => {
            const owned_label = try allocator.dupe(u8, spec.label);
            errdefer allocator.free(owned_label);
            const owned_path = try allocator.dupe(u8, spec.path);
            errdefer allocator.free(owned_path);
            var state: std.ArrayList(u8) = .empty;
            errdefer state.deinit(allocator);
            try appendDormantReadinessField(allocator, &state, "absent");
            return .{
                .label = owned_label,
                .path = owned_path,
                .state = try state.toOwnedSlice(allocator),
                .exists = false,
                .logical = false,
                .unexpected_publication = spec.unexpected_publication,
            };
        },
        else => return err,
    };
    defer parent.close(io);
    return captureDormantExactObserverRowFromDir(
        allocator,
        io,
        parent,
        basename,
        spec.label,
        spec.path,
        spec.unexpected_publication,
    );
}

fn appendDormantExactObserverLogicalRow(
    allocator: std.mem.Allocator,
    rows: *std.ArrayList(DormantExactObserverRow),
    label: []const u8,
    path: []const u8,
    state: []const u8,
) !void {
    const owned_label = try allocator.dupe(u8, label);
    errdefer allocator.free(owned_label);
    const owned_path = try allocator.dupe(u8, path);
    errdefer allocator.free(owned_path);
    const owned_state = try allocator.dupe(u8, state);
    errdefer allocator.free(owned_state);
    try rows.append(allocator, .{
        .label = owned_label,
        .path = owned_path,
        .state = owned_state,
        .exists = true,
        .logical = true,
        .unexpected_publication = false,
    });
}

fn dormantExactObserverIdentity(
    allocator: std.mem.Allocator,
    rows: []const DormantExactObserverRow,
) !DormantExactAcceptanceSnapshotIdentity {
    var encoded: std.ArrayList(u8) = .empty;
    defer encoded.deinit(allocator);
    try appendDormantReadinessField(allocator, &encoded, "dormant-exact-real-observer-v1");
    try appendDormantReadinessInteger(allocator, &encoded, rows.len);
    for (rows) |row| {
        try appendDormantReadinessField(allocator, &encoded, row.label);
        try appendDormantReadinessField(allocator, &encoded, row.path);
        try appendDormantReadinessField(
            allocator,
            &encoded,
            if (row.exists) "present" else "absent",
        );
        try appendDormantReadinessField(
            allocator,
            &encoded,
            if (row.logical) "logical" else "path",
        );
        try appendDormantReadinessField(
            allocator,
            &encoded,
            if (row.unexpected_publication) "unexpected-publication" else "admitted",
        );
        try appendDormantReadinessField(allocator, &encoded, row.state);
    }
    return .{
        .bytes = std.math.cast(u64, encoded.items.len) orelse
            return error.DormantAcceptanceSnapshotTooLarge,
        .sha256 = sha256Hex(encoded.items),
    };
}

fn finishDormantExactObservation(
    allocator: std.mem.Allocator,
    rows: *std.ArrayList(DormantExactObserverRow),
) !DormantExactRealObservation {
    std.mem.sort(DormantExactObserverRow, rows.items, {}, dormantExactObserverRowLessThan);
    for (rows.items, 0..) |row, index| {
        if (index != 0) {
            const previous = rows.items[index - 1];
            if (std.mem.eql(u8, previous.label, row.label) or
                std.mem.eql(u8, previous.path, row.path))
            {
                return error.DormantExactObserverDuplicateRow;
            }
        }
    }
    const identity = try dormantExactObserverIdentity(allocator, rows.items);
    return .{
        .allocator = allocator,
        .rows = try rows.toOwnedSlice(allocator),
        .identity = identity,
    };
}

fn compareDormantExactRealObservations(
    before: *const DormantExactRealObservation,
    after: *const DormantExactRealObservation,
) DormantReadinessNetEffects {
    var effects: DormantReadinessNetEffects = .{};
    var before_index: usize = 0;
    var after_index: usize = 0;
    while (before_index < before.rows.len or after_index < after.rows.len) {
        const old: ?DormantExactObserverRow = if (before_index < before.rows.len)
            before.rows[before_index]
        else
            null;
        const new: ?DormantExactObserverRow = if (after_index < after.rows.len)
            after.rows[after_index]
        else
            null;
        const order = if (old == null)
            std.math.Order.gt
        else if (new == null)
            std.math.Order.lt
        else blk: {
            const label_order = std.mem.order(u8, old.?.label, new.?.label);
            break :blk if (label_order != .eq)
                label_order
            else
                std.mem.order(u8, old.?.path, new.?.path);
        };
        if (order == .lt) {
            const row = old.?;
            if (row.logical) {
                effects.logical_state_modified = true;
            } else if (row.exists) {
                effects.removed_paths += 1;
            }
            if (row.unexpected_publication and row.exists) {
                effects.publication_path_changes += 1;
            }
            before_index += 1;
        } else if (order == .gt) {
            const row = new.?;
            if (row.logical) {
                effects.logical_state_modified = true;
            } else if (row.exists) {
                effects.created_paths += 1;
            }
            if (row.unexpected_publication and row.exists) {
                effects.publication_path_changes += 1;
            }
            after_index += 1;
        } else {
            const old_row = old.?;
            const new_row = new.?;
            if (old_row.logical or new_row.logical) {
                if (!old_row.logical or !new_row.logical or
                    !std.mem.eql(u8, old_row.state, new_row.state))
                {
                    effects.logical_state_modified = true;
                }
            } else if (!old_row.exists and new_row.exists) {
                effects.created_paths += 1;
            } else if (old_row.exists and !new_row.exists) {
                effects.removed_paths += 1;
            } else if (old_row.exists and new_row.exists and
                !std.mem.eql(u8, old_row.state, new_row.state))
            {
                effects.modified_paths += 1;
            }
            if ((old_row.unexpected_publication and old_row.exists) or
                (new_row.unexpected_publication and new_row.exists))
            {
                effects.publication_path_changes += 1;
            }
            before_index += 1;
            after_index += 1;
        }
    }
    return effects;
}

fn deinitDormantExactObserverSpecs(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
) void {
    for (specs.items) |*spec| spec.deinit(allocator);
    specs.deinit(allocator);
}

fn appendDormantExactObserverDirectorySpec(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    root: []const u8,
    domain: []const u8,
    relative_path: []const u8,
) !void {
    const label = try std.fmt.allocPrint(
        allocator,
        "{s}-directory:{s}",
        .{ domain, relative_path },
    );
    defer allocator.free(label);
    const path = try std.fs.path.join(allocator, &.{ root, relative_path });
    defer allocator.free(path);
    try appendDormantExactObserverAllocatedSpec(allocator, specs, label, path, false);
}

fn appendDormantExactObserverControlSpecs(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    config: *const DormantAuthorityConfig,
) !void {
    for (config.root_policy.control_files) |expectation| {
        try appendDormantExactObserverFileSpec(
            allocator,
            specs,
            config.control_root,
            "control",
            expectation.path,
        );
    }
}

fn appendDormantExactObserverPayloadSpecs(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    config: *const DormantAuthorityConfig,
) !void {
    const generation_bytes = try readDormantControlFile(
        config,
        .generation,
        dormant_generation_key,
    );
    defer allocator.free(generation_bytes);
    var manifest = try parseManifest(allocator, generation_bytes);
    defer manifest.deinit(allocator);
    for ([_][]const u8{
        "incoming",
        "objects",
        "objects/sha256",
        "snapshots",
        "snapshots/sha256",
    }) |relative_path| {
        try appendDormantExactObserverDirectorySpec(
            allocator,
            specs,
            config.payload_root,
            "payload",
            relative_path,
        );
    }
    for (manifest.rows) |row| {
        if (row.kind != .object and row.kind != .snapshot) continue;
        const parent_path = std.fs.path.dirname(row.key) orelse
            return error.DormantExactObserverUnsafePath;
        try appendDormantExactObserverDirectorySpec(
            allocator,
            specs,
            config.payload_root,
            "payload",
            parent_path,
        );
        try appendDormantExactObserverFileSpec(
            allocator,
            specs,
            config.payload_root,
            "payload",
            row.key,
        );
    }
}

fn appendDormantExactObserverUnexpectedPublicationSpecs(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    config: *const DormantAuthorityConfig,
) !void {
    const relative_directory = "authority/zllvm/v1/receipts/publication";
    var control = std.Io.Dir.openDirAbsolute(config.io, config.control_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    }) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer control.close(config.io);
    var publication = openPathNoFollow(
        config.io,
        control,
        relative_directory,
        false,
    ) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer publication.close(config.io);
    var iterator = publication.iterate();
    var entry_count: usize = 0;
    while (try iterator.next(config.io)) |entry| {
        entry_count += 1;
        if (entry_count > 64) return error.DormantExactObserverPublicationBoundExceeded;
        if (std.mem.eql(u8, entry.name, std.fs.path.basename(dormant_receipt_key))) continue;
        const relative_path = try std.fs.path.join(
            allocator,
            &.{ relative_directory, entry.name },
        );
        defer allocator.free(relative_path);
        const path = try std.fs.path.join(allocator, &.{ config.control_root, relative_path });
        defer allocator.free(path);
        const label = try std.fmt.allocPrint(
            allocator,
            "unexpected-publication:{s}",
            .{entry.name},
        );
        defer allocator.free(label);
        try appendDormantExactObserverAllocatedSpec(allocator, specs, label, path, true);
    }
}

fn captureDormantExactRealObservation(
    config: *const DormantAuthorityConfig,
) !DormantExactRealObservation {
    if (!builtin.is_test) return error.TestOnlyOperation;
    var specs: std.ArrayList(DormantExactObserverPathSpec) = .empty;
    defer deinitDormantExactObserverSpecs(config.allocator, &specs);
    try appendDormantExactObserverSpec(
        config.allocator,
        &specs,
        "root:main",
        config.root_policy.main_root,
        false,
    );
    try appendDormantExactObserverSpec(
        config.allocator,
        &specs,
        "root:control",
        config.control_root,
        false,
    );
    try appendDormantExactObserverSpec(
        config.allocator,
        &specs,
        "root:payload",
        config.payload_root,
        false,
    );
    try appendDormantExactObserverSpec(
        config.allocator,
        &specs,
        "root:source",
        config.source_root,
        false,
    );
    try appendDormantExactObserverSpec(
        config.allocator,
        &specs,
        "tool:git",
        dormant_git_executable,
        false,
    );
    try appendDormantExactObserverFileSpec(
        config.allocator,
        &specs,
        config.root_policy.main_root,
        "copy-evidence",
        config.expected_copy_evidence_path,
    );
    try appendDormantExactObserverControlSpecs(config.allocator, &specs, config);
    try appendDormantExactObserverPayloadSpecs(config.allocator, &specs, config);
    try appendDormantExactObserverUnexpectedPublicationSpecs(
        config.allocator,
        &specs,
        config,
    );

    var rows: std.ArrayList(DormantExactObserverRow) = .empty;
    errdefer {
        for (rows.items) |*row| row.deinit(config.allocator);
        rows.deinit(config.allocator);
    }
    for (specs.items) |spec| {
        try rows.append(
            config.allocator,
            try captureDormantExactObserverAbsoluteRow(
                config.allocator,
                config.io,
                spec,
            ),
        );
    }
    var logical_state: std.ArrayList(u8) = .empty;
    defer logical_state.deinit(config.allocator);
    try appendDormantReadinessField(
        config.allocator,
        &logical_state,
        "dormant-exact-real-logical-state-v1",
    );
    try appendDormantLogicalState(config.allocator, &logical_state, config);
    try appendDormantExactObserverLogicalRow(
        config.allocator,
        &rows,
        "logical:authority-and-registration",
        "logical://authority-and-registration",
        logical_state.items,
    );
    return finishDormantExactObservation(config.allocator, &rows);
}

pub const API = struct {
    pub const NetEffects = DormantReadinessNetEffects;
    pub const SnapshotIdentity = DormantExactAcceptanceSnapshotIdentity;
    pub const ObserverRow = DormantExactObserverRow;
    pub const Observation = DormantExactRealObservation;
    pub const appendReadinessField = appendDormantReadinessField;
    pub const appendReadinessInteger = appendDormantReadinessInteger;
    pub const appendLogicalState = appendDormantLogicalState;
    pub const captureRowFromDir = captureDormantExactObserverRowFromDir;
    pub const appendLogicalRow = appendDormantExactObserverLogicalRow;
    pub const finishObservation = finishDormantExactObservation;
    pub const compareObservations = compareDormantExactRealObservations;
    pub const captureObservation = captureDormantExactRealObservation;
};
