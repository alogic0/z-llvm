//! Allocation accounting with explicit unresolved storage, without payload copies.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const fa = core.fa;
pub const Disposition = enum { unresolved, eligible, required_by_current_contract };
const Contract = struct { disposition: Disposition, reason: []const u8 };
const Bucket = struct { root: []const u8, kind: []const u8, disposition: Disposition, reason: []const u8, paths: u64 = 0, unique_inodes: u64 = 0, allocated_bytes: u64 = 0 };
const Inode = struct { bucket: usize, bytes: u64 };
const Largest = struct { path: []const u8, identity: fa.metadata.Identity, allocated_bytes: u64, disposition: Disposition = .unresolved, reason: []const u8 = "" };

pub fn runRoot(path: []const u8) []const u8 {
    const count: usize = if (std.mem.startsWith(u8, path, "local-state/validations/")) 5 else 3;
    var components = std.mem.splitScalar(u8, path, '/');
    for (0..count) |_| _ = components.next() orelse return std.fs.path.dirname(path) orelse path;
    const end = components.index orelse return path;
    return path[0 .. end - 1];
}
fn kind(path: []const u8, metadata: fa.Metadata) []const u8 {
    if (metadata.kind != .file) return @tagName(metadata.kind);
    const name = std.fs.path.basename(path);
    if (std.mem.eql(u8, name, "profile.events.jsonl")) return "raw_trace";
    var components = std.mem.splitScalar(u8, path, '/');
    while (components.next()) |part| if (p.cacheName(part)) return "compiler_cache";
    const ext = std.fs.path.extension(name);
    for ([_][]const u8{ ".o", ".obj", ".a" }) |x| if (std.mem.eql(u8, ext, x)) return "object_or_archive";
    for ([_][]const u8{ ".zig", ".c", ".h", ".cpp", ".S", ".sh" }) |x| if (std.mem.eql(u8, ext, x)) return "source_or_script";
    for ([_][]const u8{ ".ll", ".air", ".bc" }) |x| if (std.mem.eql(u8, ext, x)) return "compiler_input";
    for ([_][]const u8{ ".log", ".stdout", ".stderr" }) |x| if (std.mem.eql(u8, ext, x)) return "log";
    if (metadata.mode & 0o111 != 0 or std.mem.eql(u8, ext, ".exe")) return "executable";
    for ([_][]const u8{ ".json", ".jsonl", ".ndjson", ".sha256", ".tsv", ".md" }) |x| if (std.mem.eql(u8, ext, x)) return "record_or_analysis";
    return "other";
}
fn addContract(e: *core.Engine, map: *std.StringHashMap(Contract), path: []const u8, contract: Contract) !void {
    const relative = e.relative(path) catch return;
    if (!p.within("local-state", relative)) return;
    if (map.get(relative)) |old| if (@backingInt(old.disposition) >= @backingInt(contract.disposition)) return;
    try map.put(relative, contract);
}
fn lookup(map: std.StringHashMap(Contract), path: []const u8) Contract {
    var result = Contract{ .disposition = .unresolved, .reason = "No verified current consumer or retirement record; review this file family" };
    var found = false;
    var parent: ?[]const u8 = path;
    while (parent) |value| {
        if (map.get(value)) |contract| if (!found or @backingInt(contract.disposition) > @backingInt(result.disposition)) {
            result = contract;
            found = true;
        };
        parent = std.fs.path.dirname(value);
    }
    return result;
}

pub fn write(e: *core.Engine) !void {
    var contracts = std.StringHashMap(Contract).init(e.c.a);
    for (e.config.protected_paths) |path| try addContract(e, &contracts, path, .{ .disposition = .unresolved, .reason = "Protected root; policy protection alone does not establish why each file is needed" });
    for (e.held.items) |path| {
        var generic = false;
        for (e.config.protected_paths) |protected| if (std.mem.eql(u8, path, protected)) {
            generic = true;
            break;
        };
        if (!generic) try addContract(e, &contracts, path, .{ .disposition = .required_by_current_contract, .reason = try e.c.fmt("Explicit current/queued hold: {s}", .{path}) });
    }
    for (e.config.current_manifests) |manifest| {
        const bytes = try e.read(e.c.gpa, manifest, 32 * 1024 * 1024);
        defer e.c.gpa.free(bytes);
        var lines = std.mem.tokenizeScalar(u8, bytes, '\n');
        while (lines.next()) |line| {
            if (line.len == 0 or line[0] == '#') continue;
            if (line.len < 67 or !p.hash(line[0..64]) or line[64] != ' ' or (line[65] != ' ' and line[65] != '*')) return error.UnsupportedCurrentInventoryManifest;
            try addContract(e, &contracts, line[66..], .{ .disposition = .required_by_current_contract, .reason = manifest });
        }
    }
    for (e.actions.items) |action| {
        if (action.status == .ready) try addContract(e, &contracts, action.path, .{ .disposition = .eligible, .reason = action.producer });
        if (action.status == .skipped) try addContract(e, &contracts, action.path, .{ .disposition = .unresolved, .reason = action.reason orelse "Candidate requires investigation" });
        for (action.retained) |row| try addContract(e, &contracts, row.path, .{ .disposition = .required_by_current_contract, .reason = "Verified reproduction evidence for a collector candidate" });
    }
    var buckets: std.ArrayList(Bucket) = .empty;
    var keys = std.StringHashMap(usize).init(e.c.a);
    var inodes = std.AutoHashMap(fa.metadata.Identity, Inode).init(e.c.gpa);
    defer inodes.deinit();
    var largest: std.ArrayList(Largest) = .empty;
    var largest_minimum: u64 = 0;
    var root = try std.Io.Dir.cwd().openDir(e.c.io, try e.absolute("local-state"), .{ .iterate = true, .follow_symlinks = false });
    defer root.close(e.c.io);
    const root_metadata = try fa.metadata.descriptor(root.handle);
    var walker = try root.walkSelectively(e.c.gpa);
    defer walker.deinit();
    var paths: u64 = 0;
    var vanished: u64 = 0;
    var foreign_device: u64 = 0;
    while (try walker.next(e.c.io)) |entry| {
        const metadata = fa.metadata.child(e.c.gpa, entry.dir, entry.basename) catch |err| switch (err) {
            error.FileNotFound => {
                vanished += 1;
                continue;
            },
            else => return err,
        };
        if (metadata.device != root_metadata.device) {
            foreign_device += 1;
            continue;
        }
        if (metadata.kind == .directory and entry.kind == .directory) try walker.enter(e.c.io, entry);
        const path = try std.fs.path.join(e.c.gpa, &.{ "local-state", entry.path });
        defer e.c.gpa.free(path);
        const contract = lookup(contracts, path);
        const family = kind(path, metadata);
        const group = runRoot(path);
        const key = try std.fmt.allocPrint(e.c.gpa, "{s}\n{s}\n{s}\n{s}", .{ group, family, @tagName(contract.disposition), contract.reason });
        defer e.c.gpa.free(key);
        const index = keys.get(key) orelse blk: {
            const i = buckets.items.len;
            try buckets.append(e.c.a, .{ .root = try e.c.a.dupe(u8, group), .kind = family, .disposition = contract.disposition, .reason = contract.reason });
            try keys.put(try e.c.a.dupe(u8, key), i);
            break :blk i;
        };
        buckets.items[index].paths += 1;
        paths += 1;
        const identity = fa.metadata.identity(metadata);
        const observed = try inodes.getOrPut(identity);
        if (observed.found_existing) {
            const old = observed.value_ptr.*;
            if (@backingInt(buckets.items[index].disposition) > @backingInt(buckets.items[old.bucket].disposition)) {
                buckets.items[old.bucket].allocated_bytes -= old.bytes;
                buckets.items[old.bucket].unique_inodes -= 1;
                buckets.items[index].allocated_bytes += old.bytes;
                buckets.items[index].unique_inodes += 1;
                observed.value_ptr.bucket = index;
            }
            continue;
        }
        observed.value_ptr.* = .{ .bucket = index, .bytes = metadata.allocated_bytes };
        buckets.items[index].allocated_bytes += metadata.allocated_bytes;
        buckets.items[index].unique_inodes += 1;
        if (metadata.kind == .file and metadata.allocated_bytes > largest_minimum) {
            if (largest.items.len == 64) _ = largest.pop();
            try largest.append(e.c.a, .{ .path = try e.c.a.dupe(u8, path), .identity = identity, .allocated_bytes = metadata.allocated_bytes });
            std.mem.sort(Largest, largest.items, {}, struct {
                fn less(_: void, a: Largest, b: Largest) bool {
                    return a.allocated_bytes > b.allocated_bytes;
                }
            }.less);
            if (largest.items.len == 64) largest_minimum = largest.items[63].allocated_bytes;
        }
    }
    for (largest.items) |*item| {
        const bucket = buckets.items[inodes.get(item.identity).?.bucket];
        item.disposition = bucket.disposition;
        item.reason = bucket.reason;
    }
    var totals = [_]u64{ 0, 0, 0 };
    for (buckets.items) |bucket| totals[@backingInt(bucket.disposition)] += bucket.allocated_bytes;
    std.mem.sort(Bucket, buckets.items, {}, struct {
        fn less(_: void, a: Bucket, b: Bucket) bool {
            return a.allocated_bytes > b.allocated_bytes;
        }
    }.less);
    try e.write(try e.c.fmt("{s}/inventory.json", .{e.output}), .{
        .schema = "zllvm-storage-purpose-v1",
        .status = "observed",
        .paths = paths,
        .unique_inodes = inodes.count(),
        .vanished_entries = vanished,
        .foreign_device_entries = foreign_device,
        .allocated_bytes = totals[0] + totals[1] + totals[2],
        .required_by_current_contract_bytes = totals[2],
        .eligible_bytes = totals[1],
        .unresolved_bytes = totals[0],
        .current_integrity_verified = e.current_integrity_verified,
        .buckets = buckets.items,
        .largest_files = largest.items,
        .scope = "Every observed inode is counted once. Contract priority across aliases is required > eligible > unresolved. Includes directory blocks except the local-state root. Concurrent writers can change allocation; this is an observation, not a deletion list. Generic policy protection and historical references alone do not establish necessity. Types are filename/mode classifications, not proof of purpose. Unresolved buckets require a consumer or qualified retirement evidence.",
    });
    try e.c.print("Inventory: {d} paths; required by current contract {d}; eligible {d}; unresolved {d} allocated bytes.\n{s}/inventory.json\n", .{ paths, totals[2], totals[1], totals[0], e.output });
}

test "storage cleanup: inventory groups runs and gives required aliases priority" {
    const t = std.testing;
    try t.expectEqualStrings("local-state/validations/suite/batch/run", runRoot("local-state/validations/suite/batch/run/backend/input.ll"));
    var contracts = std.StringHashMap(Contract).init(t.allocator);
    defer contracts.deinit();
    try contracts.put("a", .{ .disposition = .required_by_current_contract, .reason = "queued" });
    try contracts.put("a/b", .{ .disposition = .eligible, .reason = "older release" });
    try t.expectEqual(.required_by_current_contract, lookup(contracts, "a/b/c").disposition);
}
