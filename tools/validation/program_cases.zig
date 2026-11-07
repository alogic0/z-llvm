//! File-driven observations for unchanged programs. Each execution gets a fresh
//! directory; both compiler routes must satisfy the independently authored oracle.
const std = @import("std");
const u = @import("common.zig");
const Runner = @import("runner.zig").Runner;

pub fn relativePath(path: []const u8) !void {
    if (path.len == 0 or std.fs.path.isAbsolute(path) or std.mem.indexOfScalar(u8, path, '\\') != null or std.mem.indexOfScalar(u8, path, 0) != null) return error.InvalidCasePath;
    var parts = std.mem.splitScalar(u8, path, '/');
    while (parts.next()) |part| {
        if (part.len == 0 or std.mem.eql(u8, part, ".") or std.mem.eql(u8, part, "..")) return error.InvalidCasePath;
    }
}

pub fn validate(c: *u.Context, manifest: u.Value) !void {
    const cases = try u.json.array(try u.get(manifest, "cases"));
    if (cases.len == 0) return error.EmptyProgramCorpus;
    const output = try u.str(manifest, "output_directory");
    try relativePath(output);
    var ids = std.StringHashMap(void).init(c.a);
    for (cases) |case| {
        const id = try u.str(case, "id");
        if (id.len == 0 or (try ids.getOrPut(id)).found_existing) return error.InvalidCaseId;
        for (id) |ch| if (!std.ascii.isAlphanumeric(ch) and ch != '-') return error.InvalidCaseId;
        _ = try u.stringSlice(c.a, try u.get(case, "args"));
        const inputs = try u.get(case, "input_files");
        if (inputs != .object) return error.ExpectedInputFiles;
        for (inputs.object.keys(), inputs.object.values()) |path, value| {
            try relativePath(path);
            if (u.isWithin(output, path) or u.isWithin(path, output)) return error.OverlappingCasePaths;
            _ = try u.json.text(value);
        }
        const expected = try u.get(case, "expected");
        try u.json.exact(expected, &.{ "completed", "exit_status", "stdout", "stderr", "files" });
        const completed = try u.get(expected, "completed");
        if (completed != .bool or !completed.bool) return error.InvalidExpectedCompletion;
        const code = try u.json.integer(try u.get(expected, "exit_status"));
        if (code < 0 or code > 255) return error.InvalidExpectedExitStatus;
        _ = try u.str(expected, "stdout");
        _ = try u.str(expected, "stderr");
        const files = try u.get(expected, "files");
        if (files != .object) return error.ExpectedOutputFiles;
        for (files.object.keys(), files.object.values()) |path, value| {
            try relativePath(path);
            _ = try u.json.text(value);
        }
    }
}

pub fn fileTree(c: *u.Context, root: []const u8) !u.Value {
    var result = u.object(c.a);
    var dir = try std.Io.Dir.cwd().openDir(c.io, root, .{ .iterate = true });
    defer dir.close(c.io);
    var walker = try dir.walk(c.a);
    defer walker.deinit();
    while (try walker.next(c.io)) |entry| {
        switch (entry.kind) {
            .directory => {},
            .file => try u.put(c.a, &result, try c.a.dupe(u8, entry.path), u.s(try c.read(try c.join(&.{ root, entry.path })))),
            else => return error.UnexpectedOutputFileType,
        }
    }
    return result;
}

pub fn matches(observed: u.Value, expected: u.Value) bool {
    return u.json.eql(observed, expected);
}

/// Deliberately corrupt observations. These are oracle controls, not compiler
/// mutation tests; missing/extra files are checked independently of their bytes.
pub fn negativeControls(c: *u.Context, observed: u.Value, expected: u.Value) !usize {
    var bad = u.Value{ .object = try observed.object.clone(c.a) };
    var count: usize = 0;
    const keys = [_][]const u8{ "completed", "exit_status", "stdout", "stderr" };
    const values = [_]u.Value{
        u.b(false),
        u.n((try u.get(observed, "exit_status")).integer ^ 1),
        u.s(try c.fmt("{s}!", .{try u.str(observed, "stdout")})),
        u.s(try c.fmt("{s}!", .{try u.str(observed, "stderr")})),
    };
    for (keys, values) |key, value| {
        try u.put(c.a, &bad, key, value);
        if (matches(bad, expected)) return error.ObservationControlAccepted;
        count += 1;
        try u.put(c.a, &bad, key, try u.get(observed, key));
    }
    const files = try u.get(observed, "files");
    var changed = u.Value{ .object = try files.object.clone(c.a) };
    const extra = ".oracle-unexpected-file";
    if (changed.object.contains(extra)) return error.ReservedControlPath;
    try u.put(c.a, &changed, extra, u.s("unexpected"));
    try u.put(c.a, &bad, "files", changed);
    if (matches(bad, expected)) return error.ObservationControlAccepted;
    count += 1;
    _ = changed.object.swapRemove(extra);
    if (files.object.count() != 0) {
        const path = files.object.keys()[0];
        try u.put(c.a, &changed, path, u.s(try c.fmt("{s}!", .{try u.str(files, path)})));
        try u.put(c.a, &bad, "files", changed);
        if (matches(bad, expected)) return error.ObservationControlAccepted;
        count += 1;
        _ = changed.object.swapRemove(path);
        try u.put(c.a, &bad, "files", changed);
        if (matches(bad, expected)) return error.ObservationControlAccepted;
        count += 1;
    }
    return count;
}

pub fn observe(c: *u.Context, runner: *Runner, manifest: u.Value, exe: []const u8, directory: []const u8, route: enum { reference, local }, env: *const std.process.Environ.Map, report: *u.Value, row: *u.Value) !void {
    const route_name = @tagName(route);
    const key = try c.fmt("{s}_cases", .{route_name});
    try u.put(c.a, row, key, u.array(c.a));
    for ((try u.get(manifest, "cases")).array.items, 0..) |case, index| {
        const id = try u.str(case, "id");
        const root = try c.newOutput(try c.join(&.{ directory, "cases", id, route_name }));
        const output = try c.join(&.{ root, try u.str(manifest, "output_directory") });
        try c.mkdir(output);
        const inputs = try u.get(case, "input_files");
        for (inputs.object.keys(), inputs.object.values()) |path, bytes| {
            const absolute = try c.join(&.{ root, path });
            try c.mkdir(std.fs.path.dirname(absolute).?);
            try c.write(absolute, bytes.string);
        }
        const argv = try std.mem.concat(c.a, []const u8, &.{ &.{exe}, try u.stringSlice(c.a, try u.get(case, "args")) });
        const stem = try c.join(&.{ directory, "cases", id, try c.fmt("{s}-run", .{route_name}) });
        try u.increment(c.a, report, try c.fmt("{s}_executions", .{route_name}), 1);
        try u.increment(c.a, row, try c.fmt("{s}_executions", .{route_name}), 1);
        const result = try runner.run(argv, stem, env, .{ .cwd = root, .timeout_ms = 10_000 });
        const observed = try u.toValue(c.a, .{
            .completed = result.completed,
            .exit_status = result.code,
            .stdout = try c.read(try c.fmt("{s}.stdout", .{stem})),
            .stderr = try c.read(try c.fmt("{s}.stderr", .{stem})),
            .files = try fileTree(c, output),
        });
        const expected = try u.get(case, "expected");
        const observation_path = try c.fmt("{s}.json", .{stem});
        try c.writeJson(observation_path, observed);
        const matched = matches(observed, expected);
        try u.add(row.object.getPtr(key).?, try u.toValue(c.a, .{ .id = id, .matched = matched, .observation = observed, .path = observation_path, .sha256 = try c.digest(observation_path) }));
        // Inputs must not be silently changed by the program under test.
        for (inputs.object.keys(), inputs.object.values()) |path, bytes| {
            if (!std.mem.eql(u8, try c.read(try c.join(&.{ root, path })), bytes.string)) return error.ProgramInputChanged;
        }
        if (!matched) return c.fail("{s} case {s} differs from its independent oracle; see {s}", .{ route_name, id, observation_path });
        if (route == .local) {
            const reference = (try u.get(row.*, "reference_cases")).array.items[index];
            if (!matches(observed, try u.get(reference, "observation"))) return error.ProgramDifferentialMismatch;
            try u.increment(c.a, report, "negative_controls", @intCast(try negativeControls(c, observed, expected)));
            try u.increment(c.a, report, "matched_inputs", 1);
        }
    }
}
