//! Preserve prior native command outcomes, compiler artifacts and registry entries.
const std = @import("std");
const u = @import("common.zig");
const Entry = struct { command: u.Value, matched: bool = false };
const Index = std.StringHashMap(Entry);

fn canonical(c: *u.Context, command: u.Value, root: []const u8) !u.Value {
    const argv = try u.stringSlice(c.a, try u.get(command, "argv"));
    if (argv.len == 0) return error.EmptyCommand;
    var result = u.array(c.a);
    for (argv, 0..) |arg, i| try u.add(&result, u.s(if (i == 0 and std.mem.endsWith(u8, arg, "/z_llvm")) "COMPILER" else try std.mem.replaceOwned(u8, c.a, arg, root, "OUTPUT")));
    return result;
}
fn index(c: *u.Context, commands: []u.Value, root: []const u8) !Index {
    var seen = std.StringHashMap(usize).init(c.a);
    var result = Index.init(c.a);
    for (commands) |command| {
        const argv = try u.canonical(c.a, try canonical(c, command, root));
        const occurrence = try seen.getOrPut(argv);
        if (!occurrence.found_existing) occurrence.value_ptr.* = 0;
        const key = try c.fmt("{s}#{d}", .{ argv, occurrence.value_ptr.* });
        occurrence.value_ptr.* += 1;
        try result.put(key, .{ .command = command });
    }
    return result;
}
fn addedCommand(command: u.Value, additions: []const u.Value) !bool {
    for (try u.json.array(try u.get(command, "argv"))) |value| {
        var components = std.mem.splitScalar(u8, try u.json.text(value), '/');
        while (components.next()) |component| {
            for (additions) |addition| {
                const fixture = try u.str(addition, "fixture");
                const prefix = try u.str(addition, "prefix");
                if (std.mem.startsWith(u8, component, fixture) and u.contains(&.{ ".ll", "_driver.c" }, component[fixture.len..])) return true;
                if (std.mem.startsWith(u8, component, prefix) and component.len > prefix.len and component[prefix.len] == '-') return true;
            }
        }
    }
    return false;
}
fn expectedFixtures(c: *u.Context, additions: []const u.Value) !std.StringHashMap(void) {
    var result = std.StringHashMap(void).init(c.a);
    for (additions) |addition| for ([_][]const u8{ ".ll", "_driver.c" }) |suffix| {
        const entry = try result.getOrPut(try c.fmt("{s}{s}", .{ try u.str(addition, "fixture"), suffix }));
        if (entry.found_existing) return error.DuplicateNativeAddition;
    };
    for (additions) |addition| if (addition.object.get("reference_fixture")) |reference| {
        const entry = try result.getOrPut(try c.fmt("{s}.ll", .{try u.json.text(reference)}));
        if (entry.found_existing) return error.DuplicateNativeAddition;
        if (addition.object.get("reference_source")) |source| {
            const origin = try result.getOrPut(try u.json.text(source));
            if (origin.found_existing) return error.DuplicateNativeAddition;
        }
    };
    for (additions) |addition| if (addition.object.get("provider_fixture")) |provider| {
        const entry = try result.getOrPut(try c.fmt("{s}.ll", .{try u.json.text(provider)}));
        if (entry.found_existing) return error.DuplicateNativeAddition;
    };
    return result;
}
pub fn compare(c: *u.Context, before_root: []const u8, after_root: []const u8, additions: []const u.Value, report: *u.Value) !void {
    const before = try c.load(try c.join(&.{ before_root, "report.json" }));
    const after = try c.load(try c.join(&.{ after_root, "report.json" }));
    if (!u.json.is(try u.get(before, "status"), "passed") or !u.json.is(try u.get(after, "status"), "passed")) return error.NativeRunFailed;
    if (!u.json.eql(try u.get(before, "source_sha256"), try u.get(after, "source_sha256"))) return error.NativeSourceChanged;
    const old_fixtures = try u.get(before, "fixture_sha256");
    const new_fixtures = try u.get(after, "fixture_sha256");
    if (old_fixtures != .object or new_fixtures != .object) return error.ExpectedFixtureObject;
    var fixture_it = old_fixtures.object.iterator();
    while (fixture_it.next()) |entry| if (!u.json.eql(entry.value_ptr.*, new_fixtures.object.get(entry.key_ptr.*) orelse return error.PriorFixtureMissing)) return error.PriorFixtureChanged;
    var expected = try expectedFixtures(c, additions);
    fixture_it = new_fixtures.object.iterator();
    while (fixture_it.next()) |entry| {
        if (!old_fixtures.object.contains(entry.key_ptr.*) and !expected.remove(entry.key_ptr.*)) return error.UnexpectedNativeFixture;
    }
    if (expected.count() != 0) return error.AddedNativeFixtureMissing;
    var before_counts = u.object(c.a);
    var after_counts = u.object(c.a);
    var fields = before.object.iterator();
    while (fields.next()) |entry| {
        if (entry.value_ptr.* == .integer) {
            const candidate = after.object.get(entry.key_ptr.*) orelse return error.NativeCountMissing;
            try u.put(c.a, &before_counts, entry.key_ptr.*, entry.value_ptr.*);
            try u.put(c.a, &after_counts, entry.key_ptr.*, candidate);
            if (!u.json.eql(entry.value_ptr.*, candidate)) return c.fail("prior native count differs: {s}", .{entry.key_ptr.*});
        }
    }
    const old_commands = try u.json.array(try c.load(try c.join(&.{ before_root, "commands.json" })));
    const new_commands = try u.json.array(try c.load(try c.join(&.{ after_root, "commands.json" })));
    var old = try index(c, old_commands, before_root);
    var new = try index(c, new_commands, after_root);
    var identical = u.object(c.a);
    var differences = u.array(c.a);
    var entries = old.iterator();
    while (entries.next()) |entry| {
        const candidate = new.getPtr(entry.key_ptr.*) orelse return c.fail("prior command missing: {s}", .{entry.key_ptr.*});
        candidate.matched = true;
        const b = entry.value_ptr.command;
        const a = candidate.command;
        for ([_][]const u8{ "returncode", "outcome", "actual_returncode", "timeout_ms" }) |field| {
            if (!u.json.eql(b.object.get(field) orelse .null, a.object.get(field) orelse .null)) return c.fail("prior command outcome differs: {s}: {s}", .{ entry.key_ptr.*, field });
        }
        const argv = try u.stringSlice(c.a, try u.get(b, "argv"));
        if (std.mem.endsWith(u8, argv[0], "/z_llvm") and try u.json.integer(try u.get(b, "returncode")) == 0) {
            const kind = for (argv) |arg| {
                if (std.mem.startsWith(u8, arg, "--emit=")) break arg;
            } else "optimizer";
            const before_hash = try c.digest(try u.str(b, "stdout"));
            const after_hash = try c.digest(try u.str(a, "stdout"));
            if (std.mem.eql(u8, before_hash, after_hash)) try u.increment(c.a, &identical, kind, 1) else try u.add(&differences, try u.toValue(c.a, .{
                .command = entry.key_ptr.*,
                .baseline_sha256 = before_hash,
                .candidate_sha256 = after_hash,
                .baseline_stdout = try u.str(b, "stdout"),
                .candidate_stdout = try u.str(a, "stdout"),
            }));
        }
    }
    var extras: usize = 0;
    entries = new.iterator();
    while (entries.next()) |entry| if (!entry.value_ptr.matched) {
        if (!try addedCommand(entry.value_ptr.command, additions)) return c.fail("unexpected command: {s}", .{entry.key_ptr.*});
        extras += 1;
    };
    try u.put(c.a, report, "prior_commands", u.n(old_commands.len));
    try u.put(c.a, report, "retained_command_outcomes", u.n(old_commands.len));
    try u.put(c.a, report, "new_population_commands", u.n(extras));
    try u.put(c.a, report, "byte_identical_prior_artifacts", identical);
    try u.put(c.a, report, "artifact_differences", differences);
    try u.put(c.a, report, "before_integer_counts", before_counts);
    try u.put(c.a, report, "after_integer_counts", after_counts);
    if (differences.array.items.len != 0) return error.NativeArtifactsRequireReview;
}

pub fn registry(c: *u.Context, before: u.Value, after: u.Value, additions: []const u.Value) !u.Value {
    if (!u.json.eql(try u.get(before, "schema"), try u.get(after, "schema"))) return error.NativeRegistrySchemaChanged;
    const old = try u.json.array(try u.get(before, "canaries"));
    const new = try u.json.array(try u.get(after, "canaries"));
    if (new.len != old.len + additions.len) return error.NativeRegistryCountDiffers;
    for (old, new[0..old.len]) |b, a| if (!u.json.eql(b, a)) return error.PriorRegistryEntryChanged;
    var expected = std.StringHashMap(u.Value).init(c.a);
    for (additions) |addition| {
        const entry = try expected.getOrPut(try u.str(addition, "population"));
        if (entry.found_existing) return error.DuplicateNativeAddition;
        entry.value_ptr.* = addition;
    }
    for (new[old.len..]) |addition| {
        const wanted = expected.fetchRemove(try u.str(addition, "population")) orelse return error.UnexpectedRegistryAddition;
        if (!u.json.eql(wanted.value, addition)) return error.RegistryAdditionChanged;
    }
    return u.toValue(c.a, .{ .prior_populations = old.len, .current_populations = new.len, .prior_entries_unchanged = true });
}
