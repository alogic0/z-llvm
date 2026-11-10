const std = @import("std");
const u = @import("common.zig");

pub const Runner = struct {
    context: *u.Context,
    output: []const u8,
    commands: u.Value,
    command_json: std.ArrayList(u8) = .empty,

    pub fn init(context: *u.Context, output: []const u8) Runner {
        return .{ .context = context, .output = output, .commands = u.array(context.a) };
    }

    pub const Options = struct {
        timeout_ms: u32 = 120_000,
        stdout_file: ?[]const u8 = null,
        stdin_file: ?[]const u8 = null,
        cwd: ?[]const u8 = null,
        group: u.process.Group = .owned,
    };
    pub const Result = struct { code: i64, wall_ns: u64, completed: bool };

    /// Encode each immutable command once. Keep the same complete, indented
    /// commands.json publication after every command, including interruptions.
    /// Only serialization is incremental; atomic publication stays unchanged.
    pub fn publishCommand(r: *Runner, command: u.Value) !void {
        const c = r.context;
        try u.add(&r.commands, command);
        const bytes = try std.json.Stringify.valueAlloc(c.gpa, command, .{ .whitespace = .indent_2 });
        defer c.gpa.free(bytes);
        try r.command_json.appendSlice(c.a, if (r.command_json.items.len == 0) "[\n" else ",\n");
        var lines = std.mem.splitScalar(u8, bytes, '\n');
        var first = true;
        while (lines.next()) |line| {
            if (!first) try r.command_json.append(c.a, '\n');
            first = false;
            try r.command_json.appendSlice(c.a, "  ");
            try r.command_json.appendSlice(c.a, line);
        }
        try u.files.writeAtomic(c.io, .{ .path = try c.join(&.{ r.output, "commands.json" }), .replace = true }, &.{ r.command_json.items, "\n]\n" });
    }

    pub fn run(r: *Runner, argv: []const []const u8, stem: []const u8, env: *const std.process.Environ.Map, options: Options) !Result {
        const c = r.context;
        const input: ?std.Io.File = if (options.stdin_file) |path| try std.Io.Dir.cwd().openFile(c.io, path, .{}) else null;
        defer if (input) |file| file.close(c.io);
        const out_path = options.stdout_file orelse try c.fmt("{s}.stdout", .{stem});
        const err_path = try c.fmt("{s}.stderr", .{stem});
        const out = try c.createLog(out_path, false);
        defer out.close(c.io);
        const err = try c.createLog(err_path, false);
        defer err.close(c.io);
        const report = try u.file_command.run(c.gpa, c.io, .{
            .spawn = .{
                .argv = argv,
                .cwd = .{ .path = options.cwd orelse c.root },
                .environ_map = env,
                .search_path = true,
                .stdout = .{ .file = out },
                .stdin = if (input) |file| .{ .file = file } else .ignore,
                .stderr = .{ .file = err },
                .cancellation = u.cancellation(),
                .group = options.group,
            },
            .timeout_ms = options.timeout_ms,
            .cancel_grace_ms = 1000,
        });
        var outcome: []const u8 = "completed";
        var failure: ?[]const u8 = null;
        const code: i64 = switch (report.outcome) {
            .completed => u.returnCode(report.term.?),
            .timed_out => blk: {
                outcome = "timed_out";
                failure = "Timeout";
                break :blk 124;
            },
            .canceled => blk: {
                outcome = "canceled";
                failure = "Canceled";
                break :blk u.cancellationCode();
            },
            .failed => |failed| blk: {
                outcome = if (failed.phase == .launch) "launch_failed" else "supervision_failed";
                failure = @errorName(failed.cause);
                if (failed.phase == .launch) try err.writeStreamingAll(c.io, failure.?);
                break :blk if (failed.phase == .launch) 127 else 125;
            },
            .output_limit => unreachable, // File commands never capture output.
        };
        var record = u.object(c.a);
        try u.put(c.a, &record, "argv", try u.strings(c.a, argv));
        try u.put(c.a, &record, "cwd", u.s(options.cwd orelse c.root));
        try u.put(c.a, &record, "returncode", u.n(code));
        try u.put(c.a, &record, "wall_ns", u.n(report.wall_ns));
        try u.put(c.a, &record, "timeout_ms", u.n(options.timeout_ms));
        try u.put(c.a, &record, "stdout", u.s(out_path));
        try u.put(c.a, &record, "stderr", u.s(err_path));
        if (options.stdin_file) |path| {
            try u.put(c.a, &record, "stdin", u.s(path));
            try u.put(c.a, &record, "stdin_sha256", u.s(try c.digest(path)));
        }
        try u.put(c.a, &record, "outcome", u.s(outcome));
        if (failure) |name| try u.put(c.a, &record, "failure", u.s(name));
        if (report.cleanup_failure) |cleanup| try u.put(c.a, &record, "cleanup_failure", u.s(@errorName(cleanup)));
        if (report.term) |term| try u.put(c.a, &record, "actual_returncode", u.n(u.returnCode(term)));
        try r.publishCommand(record);
        return .{ .code = code, .wall_ns = report.wall_ns, .completed = report.outcome == .completed and report.term.? == .exited };
    }

    pub fn require(r: *Runner, argv: []const []const u8, stem: []const u8, env: *const std.process.Environ.Map) !void {
        const result = try r.run(argv, stem, env, .{});
        if (result.code != 0) return r.context.fail("command failed ({d}): {s}; see {s}.stderr", .{ result.code, argv[0], stem });
    }

    pub fn observe(r: *Runner, exe: []const u8, args: []const []const u8, expected_status: i64, expected_stdout: []const u8, stem: []const u8, env: *const std.process.Environ.Map) !void {
        const c = r.context;
        const argv = try c.a.alloc([]const u8, args.len + 1);
        argv[0] = exe;
        @memcpy(argv[1..], args);
        const result = try r.run(argv, stem, env, .{ .timeout_ms = 5000 });
        if (result.code != expected_status or !std.mem.eql(u8, try c.read(try c.fmt("{s}.stdout", .{stem})), expected_stdout) or (try c.read(try c.fmt("{s}.stderr", .{stem}))).len != 0)
            return c.fail("program observation differs: {s}", .{std.fs.path.basename(stem)});
    }
};
