const std = @import("std");
const audit = @import("root.zig");
const ignored = [_][]const u8{ ".git", ".zig-cache", "zig-cache", "zig-pkg", "zig-out", "node_modules", "vendor" };
const max_files = 100_000;
const max_file_bytes = 16 * 1024 * 1024;
const max_total_bytes = 256 * 1024 * 1024;
const RuleFile = struct { schema_version: u32 = 1, rules: []const audit.boundaries.Rule };

pub fn main(init: std.process.Init) void {
    run(init) catch |err| {
        var buffer: [1024]u8 = undefined;
        var stderr = std.Io.File.stderr().writer(init.io, &buffer);
        stderr.interface.print("zig-source-audit: {s}\n", .{@errorName(err)}) catch {};
        stderr.interface.flush() catch {};
        std.process.exit(2);
    };
}

fn selected(path: []const u8, choices: []const []const u8) bool {
    for (choices) |choice| {
        if (std.mem.eql(u8, choice, ".") or std.mem.eql(u8, path, choice) or
            (std.mem.startsWith(u8, path, choice) and path.len > choice.len and path[choice.len] == '/')) return true;
    }
    return false;
}

fn needed(path: []const u8, includes: []const []const u8) bool {
    if (selected(path, includes)) return true;
    for (includes) |include| {
        if (std.mem.startsWith(u8, include, path) and include.len > path.len and include[path.len] == '/') return true;
    }
    return false;
}

fn relativeOption(value: []const u8) ![]const u8 {
    if (!std.mem.eql(u8, value, ".") and !audit.validPath(value)) return error.InvalidRelativePath;
    return value;
}

fn run(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const io = init.io;
    const args = try init.minimal.args.toSlice(a);
    var root_path: []const u8 = ".";
    var rules_path: ?[]const u8 = null;
    var includes: std.ArrayList([]const u8) = .empty;
    var excludes: std.ArrayList([]const u8) = .empty;
    var json = false;
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--json")) {
            json = true;
        } else if (std.mem.eql(u8, arg, "--help")) {
            var buffer: [2048]u8 = undefined;
            var output = std.Io.File.stdout().writer(io, &buffer);
            try output.interface.writeAll(
                "Usage: zig-source-audit [--root DIRECTORY] [--include RELATIVE_PATH] [--exclude RELATIVE_PATH] [--rules FILE.json] [--json]\n" ++
                    "Repeat includes/excludes to select source paths. Defaults to all Zig files, skipping vendor, dependency/build caches and symlinks.\n" ++
                    "Metrics advise; syntax errors and configured boundary violations exit 1. Usage/IO/admission failures exit 2.\n",
            );
            try output.interface.flush();
            return;
        } else if (std.mem.eql(u8, arg, "--root") or std.mem.eql(u8, arg, "--include") or
            std.mem.eql(u8, arg, "--exclude") or std.mem.eql(u8, arg, "--rules"))
        {
            i += 1;
            if (i == args.len) return error.MissingOptionValue;
            const value = args[i];
            if (std.mem.eql(u8, arg, "--root")) {
                root_path = value;
            } else if (std.mem.eql(u8, arg, "--rules")) {
                if (rules_path != null) return error.DuplicateRulesFile;
                rules_path = value;
            } else if (std.mem.eql(u8, arg, "--include")) {
                try includes.append(a, try relativeOption(value));
            } else try excludes.append(a, try relativeOption(value));
        } else return error.UnknownOption;
    }
    if (includes.items.len == 0) try includes.append(a, ".");
    const rule_file: RuleFile = if (rules_path) |path| blk: {
        const bytes = try std.Io.Dir.cwd().readFileAlloc(io, path, a, .limited(1024 * 1024));
        const parsed = try std.json.parseFromSliceLeaky(RuleFile, a, bytes, .{});
        if (parsed.schema_version != 1) return error.UnsupportedRulesVersion;
        for (parsed.rules) |rule| {
            if (rule.name.len == 0 or rule.from.len == 0 or rule.deny.len == 0) return error.InvalidRule;
        }
        break :blk parsed;
    } else .{ .rules = &.{} };
    var root = try std.Io.Dir.cwd().openDir(io, root_path, .{ .iterate = true });
    defer root.close(io);
    var walker = try root.walkSelectively(a);
    defer {
        while (walker.stack.items.len != 0) walker.leave(io);
        walker.deinit();
    }
    var sources: std.ArrayList(audit.Input) = .empty;
    var total: usize = 0;
    while (try walker.next(io)) |entry| {
        if (selected(entry.path, excludes.items)) continue;
        if (entry.kind == .directory) {
            var skip = !needed(entry.path, includes.items);
            for (ignored) |name| skip = skip or std.mem.eql(u8, entry.basename, name);
            if (!skip) try walker.enter(io, entry);
            continue;
        }
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.path, ".zig") or !selected(entry.path, includes.items)) continue;
        if (sources.items.len == max_files) return error.TooManySourceFiles;
        const text = try root.readFileAlloc(io, entry.path, a, .limited(max_file_bytes));
        if (text.len > max_total_bytes - total) return error.SourceBytesLimitExceeded;
        total += text.len;
        try sources.append(a, .{ .path = try a.dupe(u8, entry.path), .text = text });
    }
    std.mem.sort(audit.Input, sources.items, {}, struct {
        fn less(_: void, lhs: audit.Input, rhs: audit.Input) bool {
            return std.mem.lessThan(u8, lhs.path, rhs.path);
        }
    }.less);
    // The owned library report has an independent lifetime from IO/argv buffers.
    var report = try audit.analyze(init.gpa, sources.items);
    defer report.deinit();
    const violations = try report.check(rule_file.rules);
    var buffer: [4096]u8 = undefined;
    var output = std.Io.File.stdout().writer(io, &buffer);
    if (json) {
        const encoded = try std.json.Stringify.valueAlloc(a, .{
            .schema_version = @as(u32, 1),
            .compiler = @import("builtin").zig_version_string,
            .files = report.files,
            .dependencies = report.graph.entries,
            .cycles = report.graph.cycles,
            .syntax_errors = report.syntax_errors,
            .violations = violations,
        }, .{ .whitespace = .indent_2 });
        try output.interface.print("{s}\n", .{encoded});
    } else {
        var functions: usize = 0;
        var unresolved: usize = 0;
        var modules: usize = 0;
        for (report.files) |file| {
            if (file.structure) |m| {
                functions += m.functions.len;
            } else try output.interface.print("Invalid syntax: {s}\n", .{file.path});
        }
        for (report.graph.entries) |entry| {
            unresolved += entry.unresolved.len;
            modules += entry.modules.len;
        }
        try output.interface.print("Zig source audit: {d} files, {d} function/test bodies, {d} cyclic groups, {d} unresolved imports, {d} named-module edges.\n", .{ report.files.len, functions, report.graph.cycles.len, unresolved, modules });
        for (violations) |violation| {
            try output.interface.print("Boundary {s}: {s}\n", .{ violation.rule, try std.mem.join(a, " -> ", violation.chain) });
        }
        try output.interface.print("Metrics are advisory. Syntax errors: {d}; boundary violations: {d}.\n", .{ report.syntax_errors, violations.len });
    }
    try output.interface.flush();
    if (report.syntax_errors != 0 or violations.len != 0) {
        report.deinit();
        std.process.exit(1);
    }
}
