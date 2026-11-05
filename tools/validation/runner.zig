const std = @import("std");
const u = @import("common.zig");

pub const Runner = struct {
    context: *u.Context,
    output: []const u8,
    commands: u.Value,

    pub fn init(context: *u.Context, output: []const u8) Runner {
        return .{ .context = context, .output = output, .commands = u.array(context.a) };
    }

    pub const Options = struct {
        timeout_ms: u32 = 120_000,
        stdout_file: ?[]const u8 = null,
        /// Benchmarks block on the borrowed pidfd; no millisecond polling quantization.
        blocking: bool = false,
        group: u.process.Group = .owned,
    };
    pub const Result = struct { code: i64, wall_ns: i128 };

    pub fn run(r: *Runner, argv: []const []const u8, stem: []const u8, env: *const std.process.Environ.Map, options: Options) !Result {
        const c = r.context;
        const out_path = options.stdout_file orelse try c.fmt("{s}.stdout", .{stem});
        const err_path = try c.fmt("{s}.stderr", .{stem});
        const out = try c.createLog(out_path, false);
        defer out.close(c.io);
        const err = try c.createLog(err_path, false);
        defer err.close(c.io);
        const start = std.Io.Clock.awake.now(c.io);
        var outcome: []const u8 = "completed";
        var failure: ?[]const u8 = null;
        var actual_term: ?std.process.Child.Term = null;
        var cleanup_failure: ?[]const u8 = null;
        const code: i64 = blk: {
            var child = u.process.Child.spawn(c.gpa, c.io, .{
                .argv = argv,
                .cwd = .{ .path = c.root },
                .environ_map = env,
                .search_path = true,
                .stdout = .{ .file = out },
                .stderr = .{ .file = err },
                .cancellation = u.cancellation(),
                .group = options.group,
            }) catch |e| {
                outcome = "launch_failed";
                failure = @errorName(e);
                try err.writeStreamingAll(c.io, failure.?);
                break :blk 127;
            };
            defer child.deinit();
            actual_term = wait(&child, c, options) catch |e| {
                outcome = if (e == error.Timeout) "timed_out" else if (e == error.Canceled) "canceled" else "supervision_failed";
                failure = @errorName(e);
                actual_term = child.stop(if (e == error.Canceled) 1000 else 0) catch |cleanup| failed: {
                    cleanup_failure = @errorName(cleanup);
                    break :failed null;
                };
                break :blk if (e == error.Timeout) 124 else if (e == error.Canceled) u.cancellationCode() else 125;
            };
            break :blk u.returnCode(actual_term.?);
        };
        const elapsed = std.Io.Clock.awake.now(c.io).nanoseconds - start.nanoseconds;
        var record = u.object(c.a);
        try u.put(c.a, &record, "argv", try u.strings(c.a, argv));
        try u.put(c.a, &record, "returncode", u.n(code));
        try u.put(c.a, &record, "wall_ns", u.n(elapsed));
        try u.put(c.a, &record, "stdout", u.s(out_path));
        try u.put(c.a, &record, "stderr", u.s(err_path));
        try u.put(c.a, &record, "outcome", u.s(outcome));
        if (failure) |name| try u.put(c.a, &record, "failure", u.s(name));
        if (cleanup_failure) |name| try u.put(c.a, &record, "cleanup_failure", u.s(name));
        if (actual_term) |term| try u.put(c.a, &record, "actual_returncode", u.n(u.returnCode(term)));
        try u.add(&r.commands, record);
        try c.writeJson(try c.join(&.{ r.output, "commands.json" }), r.commands);
        return .{ .code = code, .wall_ns = elapsed };
    }

    fn wait(child: *u.process.Child, c: *u.Context, options: Options) !std.process.Child.Term {
        if (!options.blocking) return child.waitUntil(std.Io.Clock.awake.now(c.io).addDuration(.fromMilliseconds(options.timeout_ms)), u.cancellation());
        // Observe readiness only. The provider exclusively owns reaping and group cleanup.
        var fds = [_]std.os.linux.pollfd{.{ .fd = child.pollHandle() orelse return error.MissingPollHandle, .events = std.os.linux.POLL.IN, .revents = 0 }};
        while (true) {
            if (u.cancellation().isRequested()) return error.Canceled;
            switch (std.os.linux.errno(std.os.linux.poll(&fds, fds.len, -1))) {
                .SUCCESS => {
                    if (fds[0].revents & (std.os.linux.POLL.ERR | std.os.linux.POLL.NVAL) != 0) return error.ProcessPollFailed;
                    break;
                },
                .INTR => continue,
                else => return error.ProcessPollFailed,
            }
        }
        return child.finish();
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
