const std = @import("std");
const common = @import("tool_common.zig");

const usage =
    \\usage: zig run tools/probe_distribution_objects.zig -- --input-dir=DIR [options]
    \\
    \\Options:
    \\  --target=TRIPLE          Object target [x86_64-unknown-linux-gnu]
    \\  --input-limit=N         z_llvm input limit [67108864]
    \\  --zllvm-exe=PATH        z_llvm executable [zig-out/bin/z_llvm]
    \\  --exclude=FILE:REASON   Skip one optimized IR filename with a boundary reason
    \\  --summary=PATH          Also write the stable probe summary to PATH
    \\  --keep-objects=DIR      Keep emitted objects and error logs under DIR
    \\  --help                  Show this help
    \\
;

const Options = struct {
    input_dir: ?[]const u8 = null,
    target: []const u8 = "x86_64-unknown-linux-gnu",
    input_limit: usize = 67_108_864,
    zllvm_exe: []const u8 = "zig-out/bin/z_llvm",
    summary_path: ?[]const u8 = null,
    keep_objects: ?[]const u8 = null,
    excludes: std.ArrayList(Exclude) = .empty,

    fn deinit(opts: *Options, allocator: std.mem.Allocator) void {
        opts.excludes.deinit(allocator);
    }
};

const Exclude = struct {
    name: []const u8,
    reason: []const u8,
};

const CategoryCount = struct {
    name: []const u8,
    count: usize,
};

const Counts = struct {
    total: usize = 0,
    ok: usize = 0,
    fail: usize = 0,
    excluded: usize = 0,
    first_failure: []const u8 = "-",
    first_failure_category: []const u8 = "-",
    fail_categories: std.ArrayList(CategoryCount) = .empty,
    excluded_categories: std.ArrayList(CategoryCount) = .empty,

    fn deinit(counts: *Counts, allocator: std.mem.Allocator) void {
        counts.fail_categories.deinit(allocator);
        counts.excluded_categories.deinit(allocator);
    }
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const build_argv = [_][]const u8{ "zig", "build" };
    const build_result = try common.runCapture(allocator, io, &build_argv, "zig build");
    common.freeRunResult(allocator, build_result);

    var opts = try parseArgs(allocator, io, init);
    defer opts.deinit(allocator);

    const input_dir = opts.input_dir orelse {
        try fatal(io, "missing required --input-dir\n{s}", .{usage});
    };

    var input_root = std.Io.Dir.cwd().openDir(io, input_dir, .{ .iterate = true }) catch |err| {
        try fatal(io, "input directory not found: {s}: {s}\n", .{ input_dir, @errorName(err) });
    };
    defer input_root.close(io);

    var files: std.ArrayList([]const u8) = .empty;
    defer {
        for (files.items) |file| allocator.free(file);
        files.deinit(allocator);
    }
    try collectLlFiles(allocator, io, input_root, &files);
    std.mem.sort([]const u8, files.items, {}, stringLessThan);

    var cwd = std.Io.Dir.cwd();
    if (opts.keep_objects) |keep_objects| try cwd.createDirPath(io, keep_objects);

    const work_dir = opts.keep_objects orelse try makeTempDir(allocator, io);
    defer if (opts.keep_objects == null) {
        cwd.deleteTree(io, work_dir) catch {};
        allocator.free(work_dir);
    };

    var output: std.ArrayList(u8) = .empty;
    defer output.deinit(allocator);

    var counts: Counts = .{};
    defer counts.deinit(allocator);

    try output.print(allocator, "object-probe target={s} input_dir={s} input_limit={}\n", .{ opts.target, input_dir, opts.input_limit });

    for (files.items) |file| {
        counts.total += 1;

        if (excludeReason(opts.excludes.items, file)) |reason| {
            counts.excluded += 1;
            try incrementCategory(allocator, &counts.excluded_categories, reason);
            try output.print(allocator, "excluded {s} reason={s}\n", .{ file, reason });
            continue;
        }

        const input_path = try std.fs.path.join(allocator, &.{ input_dir, file });
        defer allocator.free(input_path);

        const stem = try safeStem(allocator, file);
        defer allocator.free(stem);
        const object_name = try std.fmt.allocPrint(allocator, "{s}.o", .{stem});
        defer allocator.free(object_name);
        const log_name = try std.fmt.allocPrint(allocator, "{s}.err", .{stem});
        defer allocator.free(log_name);
        const object_path = try std.fs.path.join(allocator, &.{ work_dir, object_name });
        defer allocator.free(object_path);
        const log_path = try std.fs.path.join(allocator, &.{ work_dir, log_name });
        defer allocator.free(log_path);

        const result = try runObjectProbe(allocator, io, opts, input_path);
        defer freeRunResult(allocator, result);

        if (termOk(result.term)) {
            counts.ok += 1;
            try cwd.writeFile(io, .{ .sub_path = object_path, .data = result.stdout });
            try output.print(allocator, "ok {s}\n", .{file});
            continue;
        }

        counts.fail += 1;
        const log = if (result.stderr.len != 0) result.stderr else result.stdout;
        try cwd.writeFile(io, .{ .sub_path = log_path, .data = log });
        const category = categoryForError(log);
        try incrementCategory(allocator, &counts.fail_categories, category);
        if (std.mem.eql(u8, counts.first_failure, "-")) {
            counts.first_failure = file;
            counts.first_failure_category = category;
        }
        try output.print(allocator, "fail {s} category={s} {s}\n", .{ file, category, firstLine(log) });
    }

    try output.print(allocator, "summary total={} ok={} fail={} excluded={} first_failure={s} first_failure_category={s}\n", .{
        counts.total,
        counts.ok,
        counts.fail,
        counts.excluded,
        counts.first_failure,
        counts.first_failure_category,
    });

    std.mem.sort(CategoryCount, counts.fail_categories.items, {}, categoryLessThan);
    for (counts.fail_categories.items) |category| {
        try output.print(allocator, "fail_category {s}={}\n", .{ category.name, category.count });
    }

    std.mem.sort(CategoryCount, counts.excluded_categories.items, {}, categoryLessThan);
    for (counts.excluded_categories.items) |category| {
        try output.print(allocator, "excluded_category {s}={}\n", .{ category.name, category.count });
    }

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.writeAll(output.items);
    try stdout_writer.interface.flush();

    if (opts.summary_path) |summary_path| {
        if (std.fs.path.dirname(summary_path)) |dirname| try cwd.createDirPath(io, dirname);
        try cwd.writeFile(io, .{ .sub_path = summary_path, .data = output.items });
    }
}

fn parseArgs(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Options {
    var opts: Options = .{};
    if (try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET")) |target| opts.target = target;
    if (try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "INPUT_LIMIT")) |input_limit| {
        opts.input_limit = try parseNonZeroUsize(input_limit);
    }

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [4096]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll(usage);
            try stdout_writer.interface.flush();
            std.process.exit(0);
        } else if (std.mem.startsWith(u8, arg, "--input-dir=")) {
            opts.input_dir = arg["--input-dir=".len..];
        } else if (std.mem.startsWith(u8, arg, "--target=")) {
            opts.target = arg["--target=".len..];
        } else if (std.mem.startsWith(u8, arg, "--input-limit=")) {
            opts.input_limit = try parseNonZeroUsize(arg["--input-limit=".len..]);
        } else if (std.mem.startsWith(u8, arg, "--zllvm-exe=")) {
            opts.zllvm_exe = arg["--zllvm-exe=".len..];
        } else if (std.mem.startsWith(u8, arg, "--summary=")) {
            opts.summary_path = arg["--summary=".len..];
        } else if (std.mem.startsWith(u8, arg, "--keep-objects=")) {
            opts.keep_objects = arg["--keep-objects=".len..];
        } else if (std.mem.startsWith(u8, arg, "--exclude=")) {
            try opts.excludes.append(allocator, parseExclude(arg["--exclude=".len..]));
        } else {
            try fatal(io, "unknown argument: {s}\n{s}", .{ arg, usage });
        }
    }

    return opts;
}

fn parseExclude(text: []const u8) Exclude {
    const split = std.mem.indexOfScalar(u8, text, ':') orelse return .{
        .name = text,
        .reason = "boundary-exclusion",
    };
    return .{
        .name = text[0..split],
        .reason = text[split + 1 ..],
    };
}

fn parseNonZeroUsize(text: []const u8) !usize {
    const value = try std.fmt.parseInt(usize, text, 10);
    if (value == 0) return error.InvalidInputLimit;
    return value;
}

fn collectLlFiles(
    allocator: std.mem.Allocator,
    io: std.Io,
    input_root: std.Io.Dir,
    files: *std.ArrayList([]const u8),
) !void {
    var iter = input_root.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".ll")) continue;
        try files.append(allocator, try allocator.dupe(u8, entry.name));
    }
}

fn makeTempDir(allocator: std.mem.Allocator, io: std.Io) ![]const u8 {
    var cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, "tmp");
    const stamp = std.os.linux.getpid();
    const path = try std.fmt.allocPrint(allocator, "tmp/probe_distribution_objects_{}", .{stamp});
    errdefer allocator.free(path);
    try cwd.createDirPath(io, path);
    return path;
}

fn runObjectProbe(
    allocator: std.mem.Allocator,
    io: std.Io,
    opts: Options,
    input_path: []const u8,
) !std.process.RunResult {
    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{opts.target});
    defer allocator.free(target_arg);
    const input_limit_arg = try std.fmt.allocPrint(allocator, "--input-limit={}", .{opts.input_limit});
    defer allocator.free(input_limit_arg);

    const argv = [_][]const u8{
        opts.zllvm_exe,
        "--emit=obj",
        target_arg,
        input_limit_arg,
        input_path,
    };
    return std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    });
}

fn freeRunResult(allocator: std.mem.Allocator, result: std.process.RunResult) void {
    allocator.free(result.stdout);
    allocator.free(result.stderr);
}

fn termOk(term: std.process.Child.Term) bool {
    return switch (term) {
        .exited => |code| code == 0,
        else => false,
    };
}

fn excludeReason(excludes: []const Exclude, file: []const u8) ?[]const u8 {
    for (excludes) |exclude| {
        if (std.mem.eql(u8, exclude.name, file)) return exclude.reason;
    }
    return null;
}

fn categoryForError(log: []const u8) []const u8 {
    const line = firstLine(log);
    if (std.mem.indexOf(u8, line, "UnsupportedCodegenControlFlow") != null) return "unsupported-control-flow";
    if (std.mem.indexOf(u8, line, "UnsupportedCodegenInstruction") != null) return "unsupported-instruction";
    if (std.mem.indexOf(u8, line, "UnsupportedCodegenValue") != null) return "unsupported-value";
    if (std.mem.indexOf(u8, line, "UnsupportedCodegenType") != null) return "unsupported-type";
    if (std.mem.indexOf(u8, line, "UnsupportedCodegenAbi") != null) return "unsupported-abi";
    if (std.mem.indexOf(u8, line, "UnsupportedCodegenTarget") != null) return "unsupported-target";
    if (std.mem.indexOf(u8, line, "InputTooLarge") != null) return "input-too-large";
    if (std.mem.startsWith(u8, line, "error:")) return "other-error";
    return "unknown-error";
}

fn firstLine(text: []const u8) []const u8 {
    const end = std.mem.indexOfScalar(u8, text, '\n') orelse text.len;
    return std.mem.trimEnd(u8, text[0..end], "\r");
}

fn incrementCategory(allocator: std.mem.Allocator, categories: *std.ArrayList(CategoryCount), name: []const u8) !void {
    for (categories.items) |*category| {
        if (std.mem.eql(u8, category.name, name)) {
            category.count += 1;
            return;
        }
    }
    try categories.append(allocator, .{ .name = name, .count = 1 });
}

fn safeStem(allocator: std.mem.Allocator, file: []const u8) ![]const u8 {
    const stem = try allocator.dupe(u8, file);
    for (stem) |*byte| {
        if (!std.ascii.isAlphanumeric(byte.*) and byte.* != '_' and byte.* != '.' and byte.* != '-') {
            byte.* = '_';
        }
    }
    return stem;
}

fn stringLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}

fn categoryLessThan(_: void, lhs: CategoryCount, rhs: CategoryCount) bool {
    return std.mem.lessThan(u8, lhs.name, rhs.name);
}

fn fatal(io: std.Io, comptime fmt: []const u8, args: anytype) !noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    try stderr_writer.interface.print(fmt, args);
    try stderr_writer.interface.flush();
    std.process.exit(2);
}
