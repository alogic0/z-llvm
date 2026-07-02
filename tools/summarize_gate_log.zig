const std = @import("std");
const common = @import("tool_common.zig");

const usage =
    \\usage: zig run tools/summarize_gate_log.zig -- --log=PATH --out=docs/evidence/TOPIC.summary --command='COMMAND' [options]
    \\
    \\Reads a saved gate log and writes a tracked evidence summary.
    \\
    \\Required:
    \\  --log=PATH                 Saved gate log to summarize.
    \\  --out=PATH                 Output summary under docs/evidence/ with .summary suffix.
    \\  --command=COMMAND          Exact command that produced the log.
    \\
    \\Options:
    \\  --exit-status=N            Process exit status. If omitted, read process_exit_status=N from the log.
    \\  --z-llvm-commit=HASH       Override the current z_llvm commit hash.
    \\  --ziglang-pin=HASH         Override the current ../ziglang commit hash.
    \\  --ziglang-pin-file=PATH    Tracked Zig pin file (default: docs/evidence/ziglang_pin.txt).
    \\  --zig-source-dir=PATH      Sibling Zig checkout for pin lookup (default: ../ziglang).
    \\  --candidate-file-hash=HASH Real-row denominator metadata (default: n/a).
    \\  --selector-version=TEXT    Real-row selector metadata (default: n/a).
    \\  --mode=TEXT                Real-row mode metadata (default: n/a).
    \\  --limit=TEXT               Real-row limit metadata (default: n/a).
    \\  --ratchet-migration-note=TEXT
    \\                             Ratchet migration note (default: n/a).
    \\
;

const Options = struct {
    log_path: []const u8,
    out_path: []const u8,
    command: []const u8,
    exit_status: ?[]const u8,
    z_llvm_commit: ?[]const u8,
    ziglang_pin: ?[]const u8,
    ziglang_pin_file: []const u8,
    zig_source_dir: []const u8,
    candidate_file_hash: []const u8,
    selector_version: []const u8,
    mode: []const u8,
    limit: []const u8,
    ratchet_migration_note: []const u8,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const options = try parseArgs(allocator, io, init);

    if (!std.mem.startsWith(u8, options.out_path, "docs/evidence/") or
        !std.mem.endsWith(u8, options.out_path, ".summary"))
    {
        try common.validationError(io, "--out must be a docs/evidence/*.summary path: {s}\n", .{options.out_path});
    }

    const log = try std.Io.Dir.cwd().readFileAlloc(io, options.log_path, allocator, .limited(128 * 1024 * 1024));
    defer allocator.free(log);

    const z_llvm_commit = options.z_llvm_commit orelse try gitRev(allocator, io, &.{ "git", "rev-parse", "HEAD" }, "git rev-parse z_llvm HEAD");
    defer if (options.z_llvm_commit == null) allocator.free(z_llvm_commit);

    const ziglang_pin = options.ziglang_pin orelse try readZiglangPin(allocator, io, options);
    defer if (options.ziglang_pin == null) allocator.free(ziglang_pin);

    const parsed_exit_status = parseProcessExitStatus(log);
    const process_exit_status = options.exit_status orelse parsed_exit_status orelse "unknown";
    const first_failure_line = firstFailureLine(log, process_exit_status);

    var summary_lines: std.ArrayList([]const u8) = .empty;
    defer summary_lines.deinit(allocator);
    var line_iter = std.mem.splitScalar(u8, log, '\n');
    while (line_iter.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, "\r");
        if (std.mem.startsWith(u8, line, "summary ")) {
            try summary_lines.append(allocator, line);
        }
    }

    var output: std.ArrayList(u8) = .empty;
    defer output.deinit(allocator);
    try appendFmt(allocator, &output,
        \\# Gate Evidence Summary
        \\
        \\schema_version: 1
        \\log_path: `{s}`
        \\command: `{s}`
        \\z_llvm_commit: `{s}`
        \\ziglang_pin: `{s}`
        \\process_exit_status: `{s}`
        \\first_failure_line: `{s}`
        \\
        \\## Ratchet Metadata
        \\
        \\candidate_file_hash: `{s}`
        \\selector_version: `{s}`
        \\mode: `{s}`
        \\limit: `{s}`
        \\ratchet_migration_note: `{s}`
        \\
        \\## Summary Lines
        \\
        \\```text
        \\
    , .{
        options.log_path,
        options.command,
        z_llvm_commit,
        ziglang_pin,
        process_exit_status,
        first_failure_line orelse "none",
        options.candidate_file_hash,
        options.selector_version,
        options.mode,
        options.limit,
        options.ratchet_migration_note,
    });
    for (summary_lines.items) |line| {
        try appendFmt(allocator, &output, "{s}\n", .{line});
    }
    try output.appendSlice(allocator,
        \\```
        \\
    );

    var cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, "docs/evidence");
    try cwd.writeFile(io, .{ .sub_path = options.out_path, .data = output.items });

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("wrote-gate-summary out={s} summary_lines={} first_failure={s}\n", .{
        options.out_path,
        summary_lines.items.len,
        first_failure_line orelse "none",
    });
    try stdout_writer.interface.flush();
}

fn parseArgs(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Options {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var log_path: ?[]const u8 = null;
    var out_path: ?[]const u8 = null;
    var command: ?[]const u8 = null;
    var exit_status: ?[]const u8 = null;
    var z_llvm_commit: ?[]const u8 = null;
    var ziglang_pin: ?[]const u8 = null;
    var ziglang_pin_file: []const u8 = "docs/evidence/ziglang_pin.txt";
    var zig_source_dir: []const u8 = "../ziglang";
    var candidate_file_hash: []const u8 = "n/a";
    var selector_version: []const u8 = "n/a";
    var mode: []const u8 = "n/a";
    var limit: []const u8 = "n/a";
    var ratchet_migration_note: []const u8 = "n/a";

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [1024]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll(usage);
            try stdout_writer.interface.flush();
            std.process.exit(0);
        } else if (std.mem.startsWith(u8, arg, "--log=")) {
            log_path = arg["--log=".len..];
        } else if (std.mem.startsWith(u8, arg, "--out=")) {
            out_path = arg["--out=".len..];
        } else if (std.mem.startsWith(u8, arg, "--command=")) {
            command = arg["--command=".len..];
        } else if (std.mem.startsWith(u8, arg, "--exit-status=")) {
            exit_status = arg["--exit-status=".len..];
        } else if (std.mem.startsWith(u8, arg, "--z-llvm-commit=")) {
            z_llvm_commit = arg["--z-llvm-commit=".len..];
        } else if (std.mem.startsWith(u8, arg, "--ziglang-pin=")) {
            ziglang_pin = arg["--ziglang-pin=".len..];
        } else if (std.mem.startsWith(u8, arg, "--ziglang-pin-file=")) {
            ziglang_pin_file = arg["--ziglang-pin-file=".len..];
        } else if (std.mem.startsWith(u8, arg, "--zig-source-dir=")) {
            zig_source_dir = arg["--zig-source-dir=".len..];
        } else if (std.mem.startsWith(u8, arg, "--candidate-file-hash=")) {
            candidate_file_hash = arg["--candidate-file-hash=".len..];
        } else if (std.mem.startsWith(u8, arg, "--selector-version=")) {
            selector_version = arg["--selector-version=".len..];
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            mode = arg["--mode=".len..];
        } else if (std.mem.startsWith(u8, arg, "--limit=")) {
            limit = arg["--limit=".len..];
        } else if (std.mem.startsWith(u8, arg, "--ratchet-migration-note=")) {
            ratchet_migration_note = arg["--ratchet-migration-note=".len..];
        } else {
            try common.validationError(io, "unexpected argument: {s}\n{s}", .{ arg, usage });
        }
    }

    return .{
        .log_path = log_path orelse try common.validationError(io, "missing --log\n{s}", .{usage}),
        .out_path = out_path orelse try common.validationError(io, "missing --out\n{s}", .{usage}),
        .command = command orelse try common.validationError(io, "missing --command\n{s}", .{usage}),
        .exit_status = exit_status,
        .z_llvm_commit = z_llvm_commit,
        .ziglang_pin = ziglang_pin,
        .ziglang_pin_file = ziglang_pin_file,
        .zig_source_dir = zig_source_dir,
        .candidate_file_hash = candidate_file_hash,
        .selector_version = selector_version,
        .mode = mode,
        .limit = limit,
        .ratchet_migration_note = ratchet_migration_note,
    };
}

fn appendFmt(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    comptime format: []const u8,
    args: anytype,
) !void {
    const text = try std.fmt.allocPrint(allocator, format, args);
    defer allocator.free(text);
    try output.appendSlice(allocator, text);
}

fn gitRev(
    allocator: std.mem.Allocator,
    io: std.Io,
    argv: []const []const u8,
    label: []const u8,
) ![]const u8 {
    const result = try common.runCapture(allocator, io, argv, label);
    defer common.freeRunResult(allocator, result);
    return try allocator.dupe(u8, std.mem.trim(u8, result.stdout, " \t\r\n"));
}

fn readZiglangPin(allocator: std.mem.Allocator, io: std.Io, options: Options) ![]const u8 {
    const pin_contents = std.Io.Dir.cwd().readFileAlloc(io, options.ziglang_pin_file, allocator, .limited(4096)) catch |err| switch (err) {
        error.FileNotFound => return gitRev(
            allocator,
            io,
            &.{ "git", "-C", options.zig_source_dir, "rev-parse", "HEAD" },
            "git rev-parse Zig source HEAD",
        ),
        else => return err,
    };
    defer allocator.free(pin_contents);
    return try allocator.dupe(u8, std.mem.trim(u8, pin_contents, " \t\r\n"));
}

fn parseProcessExitStatus(log: []const u8) ?[]const u8 {
    var result: ?[]const u8 = null;
    var line_iter = std.mem.splitScalar(u8, log, '\n');
    while (line_iter.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, "\r");
        if (std.mem.startsWith(u8, line, "process_exit_status=")) {
            result = line["process_exit_status=".len..];
        }
    }
    return result;
}

fn firstFailureLine(log: []const u8, process_exit_status: []const u8) ?[]const u8 {
    var first_explicit: ?[]const u8 = null;
    var first_summary: ?[]const u8 = null;

    var line_iter = std.mem.splitScalar(u8, log, '\n');
    while (line_iter.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, "\r");
        if (line.len == 0) continue;
        if (first_summary == null and std.mem.startsWith(u8, line, "summary ") and summaryLineFailed(line)) {
            first_summary = line;
        }
        if (first_explicit == null and explicitFailureLine(line)) {
            first_explicit = line;
        }
    }

    if (first_explicit) |line| return line;
    if (first_summary) |line| return line;
    if (!std.mem.eql(u8, process_exit_status, "0") and !std.mem.eql(u8, process_exit_status, "unknown")) {
        return "process exited with nonzero status but no failure line was found";
    }
    return null;
}

fn summaryLineFailed(line: []const u8) bool {
    return nonZeroField(line, "local_fail") or
        nonZeroField(line, "codegen_failures") or
        nonZeroField(line, "object_failures") or
        nonZeroField(line, "native_link_failures") or
        nonZeroField(line, "local_object_codegen_failures") or
        nonZeroField(line, "unexpected_accept_rows") or
        nonZeroField(line, "wrong_diagnostic_rows");
}

fn nonZeroField(line: []const u8, field: []const u8) bool {
    var key_buffer: [96]u8 = undefined;
    const key = std.fmt.bufPrint(&key_buffer, "{s}=", .{field}) catch return false;
    const start = std.mem.indexOf(u8, line, key) orelse return false;
    const value_start = start + key.len;
    var value_end = value_start;
    while (value_end < line.len and line[value_end] != ' ') : (value_end += 1) {}
    const value = line[value_start..value_end];
    const parsed = std.fmt.parseUnsigned(u64, value, 10) catch return false;
    return parsed != 0;
}

fn explicitFailureLine(line: []const u8) bool {
    if (std.mem.startsWith(u8, line, "summary ")) return false;
    if (std.mem.startsWith(u8, line, "process_exit_status=")) return false;
    if (std.mem.startsWith(u8, line, "abi-boundary ")) return false;
    return std.mem.indexOf(u8, line, "strict-finish-failure") != null or
        std.mem.indexOf(u8, line, "error:") != null or
        std.mem.indexOf(u8, line, "Error:") != null or
        std.mem.indexOf(u8, line, "does not match") != null or
        std.mem.indexOf(u8, line, "failed") != null or
        std.mem.indexOf(u8, line, "failure") != null or
        std.mem.indexOf(u8, line, "panic:") != null;
}
