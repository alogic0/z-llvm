const std = @import("std");

const usage =
    \\usage: zig run tools/zig_corpus_discovery.zig -- [options]
    \\
    \\Discovers source-backed LLVM IR blockers from Zig test files.
    \\The script writes only under the discovery output directory.
    \\
    \\Options:
    \\  --zig-source-dir=PATH   Zig source checkout used for stage4 emission [../ziglang]
    \\  --zig-exe=PATH          Zig executable for IR emission [<zig-source-dir>/build/stage4/bin/zig]
    \\  --local-zig-exe=PATH    Zig executable for building/running z_llvm local checks [zig]
    \\  --local-zllvm-exe=PATH  Prebuilt z_llvm executable for local checks [build through --local-zig-exe]
    \\  --local-build-optimize=MODE
    \\                          Optimize mode for `zig build run` local checks [ReleaseFast]
    \\  --test-root=PATH        Directory to scan for .zig files [<zig-source-dir>/test]
    \\  --source-report=PATH    Use source rows from an existing report.tsv instead of scanning test-root
    \\  --source-status=STATUS  With --source-report, keep only rows with this status
    \\  --out-dir=PATH          Discovery output directory [tmp/zig_ir/discovery]
    \\  --mode=MODE             Optimize mode [ReleaseFast]
    \\  --target=TRIPLE         Zig target [x86_64-linux-gnu]
    \\  --passes=PASSES         Local pipeline/pass list [verify]
    \\                          verify-only sweeps use z_llvm --pass-limit=0
    \\                          because the CLI verifier already gates parsing
    \\  --local-input-limit=N   z_llvm input limit in bytes [1048576]
    \\  --local-output-limit=N  z_llvm optimized output capture limit in bytes [67108864]
    \\  --max=N                 Stop after N candidate .zig files [0 means unlimited]
    \\  --progress-every=N      Write partial report and print progress every N files [25; 0 disables]
    \\  --capture-optimized-output
    \\                          Save normalized local optimized output for accepted rows
    \\  --local-trace           Pass --trace to z_llvm during local checks
    \\  --local-quiet           Pass --quiet to z_llvm during local checks [default]
    \\  --no-local-quiet        Keep local z_llvm check output
    \\  --no-strip              Do not pass -fstrip to Zig emission
    \\  --help                  Show this help
    \\
    \\Outputs:
    \\  <out-dir>/report.tsv
    \\  <out-dir>/summary.txt
    \\  <out-dir>/ir/*.ll
    \\  <out-dir>/optimized-ir/*.ll when --capture-optimized-output is set
    \\  <out-dir>/logs/*.stderr.txt for failures
    \\
;

const Options = struct {
    zig_source_dir: []const u8 = "../ziglang",
    zig_exe_override: ?[]const u8 = null,
    local_zig_exe: []const u8 = "zig",
    local_zllvm_exe: ?[]const u8 = null,
    local_build_optimize: []const u8 = "ReleaseFast",
    test_root_override: ?[]const u8 = null,
    source_report: ?[]const u8 = null,
    source_status: ?[]const u8 = null,
    out_dir: []const u8 = "tmp/zig_ir/discovery",
    mode: []const u8 = "ReleaseFast",
    target: []const u8 = "x86_64-linux-gnu",
    passes: []const u8 = "verify",
    local_input_limit: usize = 1024 * 1024,
    local_output_limit: usize = 64 * 1024 * 1024,
    max: usize = 0,
    progress_every: usize = 25,
    capture_optimized_output: bool = false,
    local_trace: bool = false,
    local_quiet: bool = true,
    strip: bool = true,
};

const Counts = struct {
    candidates: usize = 0,
    compile_skip: usize = 0,
    emit_ok: usize = 0,
    local_ok: usize = 0,
    input_too_large: usize = 0,
    parse_fail: usize = 0,
    verify_fail: usize = 0,
    optimizer_fail: usize = 0,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const opts = try parseArgs(allocator, io, init);
    const zig_exe = opts.zig_exe_override orelse try std.fs.path.join(allocator, &.{ opts.zig_source_dir, "build/stage4/bin/zig" });
    defer if (opts.zig_exe_override == null) allocator.free(zig_exe);

    const test_root = opts.test_root_override orelse try std.fs.path.join(allocator, &.{ opts.zig_source_dir, "test" });
    defer if (opts.test_root_override == null) allocator.free(test_root);

    try validateMode(opts.mode);

    var cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, opts.out_dir);
    const ir_dir = try std.fs.path.join(allocator, &.{ opts.out_dir, "ir" });
    defer allocator.free(ir_dir);
    const logs_dir = try std.fs.path.join(allocator, &.{ opts.out_dir, "logs" });
    defer allocator.free(logs_dir);
    const optimized_dir = try std.fs.path.join(allocator, &.{ opts.out_dir, "optimized-ir" });
    defer allocator.free(optimized_dir);
    try cwd.createDirPath(io, ir_dir);
    try cwd.createDirPath(io, logs_dir);
    if (opts.capture_optimized_output) try cwd.createDirPath(io, optimized_dir);

    var candidates: std.ArrayList([]const u8) = .empty;
    defer {
        for (candidates.items) |candidate| allocator.free(candidate);
        candidates.deinit(allocator);
    }
    if (opts.source_report) |source_report| {
        try collectCandidatesFromReport(allocator, io, source_report, opts.source_status, &candidates);
    } else {
        try collectCandidates(allocator, io, test_root, &candidates);
    }
    std.mem.sort([]const u8, candidates.items, {}, stringLessThan);

    var report: std.ArrayList(u8) = .empty;
    defer report.deinit(allocator);
    try report.appendSlice(allocator, "status\tsource\tir_path\toptimized_ir_path\tlog_path\tnote\n");

    const report_path = try std.fs.path.join(allocator, &.{ opts.out_dir, "report.tsv" });
    defer allocator.free(report_path);
    const summary_path = try std.fs.path.join(allocator, &.{ opts.out_dir, "summary.txt" });
    defer allocator.free(summary_path);

    var counts: Counts = .{ .candidates = candidates.items.len };
    var processed: usize = 0;
    try writeProgress(allocator, io, cwd, report_path, summary_path, report.items, counts, processed, opts, zig_exe, test_root, false);
    for (candidates.items) |relative_source| {
        if (opts.max != 0 and processed >= opts.max) break;
        processed += 1;

        const source_path = try std.fs.path.join(allocator, &.{ test_root, relative_source });
        defer allocator.free(source_path);

        const safe_name = try safeName(allocator, relative_source);
        defer allocator.free(safe_name);

        const ir_basename = try std.fmt.allocPrint(allocator, "{s}.{s}.{s}.ll", .{ safe_name, opts.mode, targetTag(opts.target) });
        defer allocator.free(ir_basename);
        const ir_path = try std.fs.path.join(allocator, &.{ ir_dir, ir_basename });
        defer allocator.free(ir_path);

        const compile = runEmit(allocator, io, zig_exe, opts, source_path, ir_path) catch |err| {
            const log_path = try writeToolErrorLog(allocator, io, logs_dir, safe_name, "emit", err);
            defer allocator.free(log_path);
            counts.compile_skip += 1;
            try appendRow(&report, allocator, "compile-skip", relative_source, ir_path, "", log_path, @errorName(err));
            try maybeWriteProgress(allocator, io, cwd, report_path, summary_path, report.items, counts, processed, opts, zig_exe, test_root);
            continue;
        };
        defer freeRunResult(allocator, compile);

        if (!termOk(compile.term)) {
            const log_path = try writeLog(allocator, io, logs_dir, safe_name, "emit", compile.stderr);
            defer allocator.free(log_path);
            counts.compile_skip += 1;
            try appendRow(&report, allocator, "compile-skip", relative_source, ir_path, "", log_path, oneLineNote(compile.stderr));
            try maybeWriteProgress(allocator, io, cwd, report_path, summary_path, report.items, counts, processed, opts, zig_exe, test_root);
            continue;
        }

        counts.emit_ok += 1;

        const local = runLocalCheck(allocator, io, opts, ir_path) catch |err| {
            const log_path = try writeToolErrorLog(allocator, io, logs_dir, safe_name, "local", err);
            defer allocator.free(log_path);
            counts.optimizer_fail += 1;
            try appendRow(&report, allocator, "optimizer-fail", relative_source, ir_path, "", log_path, @errorName(err));
            try maybeWriteProgress(allocator, io, cwd, report_path, summary_path, report.items, counts, processed, opts, zig_exe, test_root);
            continue;
        };
        defer freeRunResult(allocator, local);

        if (!termOk(local.term)) {
            const status = classifyLocalFailure(opts.passes, local.stderr);
            const log_path = try writeLog(allocator, io, logs_dir, safe_name, status, local.stderr);
            defer allocator.free(log_path);
            incrementFailure(&counts, status);
            try appendRow(&report, allocator, status, relative_source, ir_path, "", log_path, oneLineNote(local.stderr));
            try maybeWriteProgress(allocator, io, cwd, report_path, summary_path, report.items, counts, processed, opts, zig_exe, test_root);
            continue;
        }

        var optimized_path: []const u8 = "";
        var optimized_path_owned = false;
        defer if (optimized_path_owned) allocator.free(optimized_path);

        if (opts.capture_optimized_output) {
            const optimized_basename = try std.fmt.allocPrint(allocator, "{s}.{s}.{s}.optimized.ll", .{ safe_name, opts.mode, targetTag(opts.target) });
            defer allocator.free(optimized_basename);
            optimized_path = try std.fs.path.join(allocator, &.{ optimized_dir, optimized_basename });
            optimized_path_owned = true;

            const optimized = runLocalOptimizedOutput(allocator, io, opts, ir_path) catch |err| {
                const log_path = try writeToolErrorLog(allocator, io, logs_dir, safe_name, "optimized-output", err);
                defer allocator.free(log_path);
                counts.optimizer_fail += 1;
                try appendRow(&report, allocator, "optimizer-fail", relative_source, ir_path, optimized_path, log_path, @errorName(err));
                try maybeWriteProgress(allocator, io, cwd, report_path, summary_path, report.items, counts, processed, opts, zig_exe, test_root);
                continue;
            };
            defer freeRunResult(allocator, optimized);

            if (!termOk(optimized.term)) {
                const status = classifyLocalFailure(opts.passes, optimized.stderr);
                const log_path = try writeLog(allocator, io, logs_dir, safe_name, "optimized-output", optimized.stderr);
                defer allocator.free(log_path);
                incrementFailure(&counts, status);
                try appendRow(&report, allocator, status, relative_source, ir_path, optimized_path, log_path, oneLineNote(optimized.stderr));
                try maybeWriteProgress(allocator, io, cwd, report_path, summary_path, report.items, counts, processed, opts, zig_exe, test_root);
                continue;
            }

            try cwd.writeFile(io, .{ .sub_path = optimized_path, .data = optimized.stdout });
        }

        counts.local_ok += 1;
        const ok_status = if (std.mem.eql(u8, opts.passes, "verify")) "verify-ok" else "optimizer-ok";
        try appendRow(&report, allocator, ok_status, relative_source, ir_path, optimized_path, "", "");
        try maybeWriteProgress(allocator, io, cwd, report_path, summary_path, report.items, counts, processed, opts, zig_exe, test_root);
    }

    try writeProgress(allocator, io, cwd, report_path, summary_path, report.items, counts, processed, opts, zig_exe, test_root, true);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print(
        "wrote {s}\nwrote {s}\nsummary processed={} compile-skip={} emit-ok={} local-ok={} parse-fail={} verify-fail={} optimizer-fail={}\n",
        .{
            report_path,
            summary_path,
            processed,
            counts.compile_skip,
            counts.emit_ok,
            counts.local_ok,
            counts.parse_fail,
            counts.verify_fail,
            counts.optimizer_fail,
        },
    );
    try stdout_writer.interface.flush();
}

fn parseArgs(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Options {
    var opts: Options = .{};
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
        } else if (std.mem.startsWith(u8, arg, "--zig-source-dir=")) {
            opts.zig_source_dir = arg["--zig-source-dir=".len..];
        } else if (std.mem.startsWith(u8, arg, "--zig-exe=")) {
            opts.zig_exe_override = arg["--zig-exe=".len..];
        } else if (std.mem.startsWith(u8, arg, "--local-zig-exe=")) {
            opts.local_zig_exe = arg["--local-zig-exe=".len..];
        } else if (std.mem.startsWith(u8, arg, "--local-zllvm-exe=")) {
            opts.local_zllvm_exe = arg["--local-zllvm-exe=".len..];
        } else if (std.mem.startsWith(u8, arg, "--local-build-optimize=")) {
            opts.local_build_optimize = arg["--local-build-optimize=".len..];
        } else if (std.mem.startsWith(u8, arg, "--test-root=")) {
            opts.test_root_override = arg["--test-root=".len..];
        } else if (std.mem.startsWith(u8, arg, "--source-report=")) {
            opts.source_report = arg["--source-report=".len..];
        } else if (std.mem.startsWith(u8, arg, "--source-status=")) {
            opts.source_status = arg["--source-status=".len..];
        } else if (std.mem.startsWith(u8, arg, "--out-dir=")) {
            opts.out_dir = arg["--out-dir=".len..];
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            opts.mode = arg["--mode=".len..];
        } else if (std.mem.startsWith(u8, arg, "--target=")) {
            opts.target = arg["--target=".len..];
        } else if (std.mem.startsWith(u8, arg, "--passes=")) {
            opts.passes = arg["--passes=".len..];
        } else if (std.mem.startsWith(u8, arg, "--local-input-limit=")) {
            opts.local_input_limit = try parseNonZeroUsize(arg["--local-input-limit=".len..]);
        } else if (std.mem.startsWith(u8, arg, "--local-output-limit=")) {
            opts.local_output_limit = try parseNonZeroUsize(arg["--local-output-limit=".len..]);
        } else if (std.mem.startsWith(u8, arg, "--max=")) {
            opts.max = try std.fmt.parseInt(usize, arg["--max=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--progress-every=")) {
            opts.progress_every = try std.fmt.parseInt(usize, arg["--progress-every=".len..], 10);
        } else if (std.mem.eql(u8, arg, "--capture-optimized-output")) {
            opts.capture_optimized_output = true;
        } else if (std.mem.eql(u8, arg, "--local-trace")) {
            opts.local_trace = true;
        } else if (std.mem.eql(u8, arg, "--local-quiet")) {
            opts.local_quiet = true;
        } else if (std.mem.eql(u8, arg, "--no-local-quiet")) {
            opts.local_quiet = false;
        } else if (std.mem.eql(u8, arg, "--no-strip")) {
            opts.strip = false;
        } else {
            var stderr_buffer: [4096]u8 = undefined;
            var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
            try stderr_writer.interface.print("unexpected argument: {s}\n{s}", .{ arg, usage });
            try stderr_writer.interface.flush();
            std.process.exit(2);
        }
    }

    return opts;
}

fn validateMode(mode: []const u8) !void {
    if (std.mem.eql(u8, mode, "Debug")) return;
    if (std.mem.eql(u8, mode, "ReleaseSafe")) return;
    if (std.mem.eql(u8, mode, "ReleaseFast")) return;
    if (std.mem.eql(u8, mode, "ReleaseSmall")) return;
    return error.UnsupportedOptimizeMode;
}

fn parseNonZeroUsize(text: []const u8) !usize {
    const value = try std.fmt.parseInt(usize, text, 10);
    if (value == 0) return error.InvalidInputLimit;
    return value;
}

fn collectCandidates(
    allocator: std.mem.Allocator,
    io: std.Io,
    test_root: []const u8,
    candidates: *std.ArrayList([]const u8),
) !void {
    var root_dir = try std.Io.Dir.cwd().openDir(io, test_root, .{ .iterate = true });
    defer root_dir.close(io);

    var walker = try root_dir.walk(allocator);
    defer walker.deinit();
    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.path, ".zig")) continue;
        try candidates.append(allocator, try allocator.dupe(u8, entry.path));
    }
}

fn collectCandidatesFromReport(
    allocator: std.mem.Allocator,
    io: std.Io,
    report_path: []const u8,
    source_status: ?[]const u8,
    candidates: *std.ArrayList([]const u8),
) !void {
    const report = try std.Io.Dir.cwd().readFileAlloc(io, report_path, allocator, .limited(16 * 1024 * 1024));
    defer allocator.free(report);

    var lines = std.mem.splitScalar(u8, report, '\n');
    _ = lines.next();
    while (lines.next()) |line| {
        if (std.mem.trim(u8, line, " \t\r").len == 0) continue;
        var fields = std.mem.splitScalar(u8, line, '\t');
        const status = fields.next() orelse continue;
        const source = fields.next() orelse continue;
        if (source_status) |wanted| {
            if (!std.mem.eql(u8, status, wanted)) continue;
        }
        try candidates.append(allocator, try allocator.dupe(u8, source));
    }
}

fn runEmit(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_exe: []const u8,
    opts: Options,
    source_path: []const u8,
    ir_path: []const u8,
) !std.process.RunResult {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-llvm-ir={s}", .{ir_path});
    defer allocator.free(emit_arg);

    if (opts.strip) {
        const argv = [_][]const u8{
            zig_exe,
            "build-obj",
            "-fllvm",
            "-flibllvm",
            "-fstrip",
            "-fno-emit-bin",
            emit_arg,
            "-O",
            opts.mode,
            "-target",
            opts.target,
            source_path,
        };
        return std.process.run(allocator, io, .{
            .argv = &argv,
            .stdout_limit = .limited(16 * 1024 * 1024),
            .stderr_limit = .limited(16 * 1024 * 1024),
        });
    } else {
        const argv = [_][]const u8{
            zig_exe,
            "build-obj",
            "-fllvm",
            "-flibllvm",
            "-fno-emit-bin",
            emit_arg,
            "-O",
            opts.mode,
            "-target",
            opts.target,
            source_path,
        };
        return std.process.run(allocator, io, .{
            .argv = &argv,
            .stdout_limit = .limited(16 * 1024 * 1024),
            .stderr_limit = .limited(16 * 1024 * 1024),
        });
    }
}

fn runLocalCheck(
    allocator: std.mem.Allocator,
    io: std.Io,
    opts: Options,
    ir_path: []const u8,
) !std.process.RunResult {
    const passes_arg = try std.fmt.allocPrint(allocator, "--passes={s}", .{opts.passes});
    defer allocator.free(passes_arg);
    const input_limit_arg = try std.fmt.allocPrint(allocator, "--input-limit={}", .{opts.local_input_limit});
    defer allocator.free(input_limit_arg);

    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    var optimize_arg: ?[]const u8 = null;
    defer if (optimize_arg) |arg| allocator.free(arg);

    if (opts.local_zllvm_exe) |local_exe| {
        try argv.append(allocator, local_exe);
    } else {
        optimize_arg = try std.fmt.allocPrint(allocator, "-Doptimize={s}", .{opts.local_build_optimize});
        try argv.appendSlice(allocator, &.{ opts.local_zig_exe, "build", optimize_arg.?, "run", "--" });
    }

    try argv.append(allocator, passes_arg);
    try argv.append(allocator, input_limit_arg);
    if (std.mem.eql(u8, opts.passes, "verify")) try argv.append(allocator, "--pass-limit=0");
    if (opts.local_trace) try argv.append(allocator, "--trace");
    if (opts.local_quiet) try argv.append(allocator, "--quiet");
    try argv.append(allocator, ir_path);

    return std.process.run(allocator, io, .{
        .argv = argv.items,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    });
}

fn runLocalOptimizedOutput(
    allocator: std.mem.Allocator,
    io: std.Io,
    opts: Options,
    ir_path: []const u8,
) !std.process.RunResult {
    const passes_arg = try std.fmt.allocPrint(allocator, "--passes={s}", .{opts.passes});
    defer allocator.free(passes_arg);
    const input_limit_arg = try std.fmt.allocPrint(allocator, "--input-limit={}", .{opts.local_input_limit});
    defer allocator.free(input_limit_arg);

    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    var optimize_arg: ?[]const u8 = null;
    defer if (optimize_arg) |arg| allocator.free(arg);

    if (opts.local_zllvm_exe) |local_exe| {
        try argv.append(allocator, local_exe);
    } else {
        optimize_arg = try std.fmt.allocPrint(allocator, "-Doptimize={s}", .{opts.local_build_optimize});
        try argv.appendSlice(allocator, &.{ opts.local_zig_exe, "build", optimize_arg.?, "run", "--" });
    }

    try argv.append(allocator, passes_arg);
    try argv.append(allocator, input_limit_arg);
    if (std.mem.eql(u8, opts.passes, "verify")) try argv.append(allocator, "--pass-limit=0");
    try argv.append(allocator, ir_path);

    return std.process.run(allocator, io, .{
        .argv = argv.items,
        .stdout_limit = .limited(opts.local_output_limit),
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

fn classifyLocalFailure(passes: []const u8, stderr: []const u8) []const u8 {
    if (containsAny(stderr, &.{"StreamTooLong"})) return "input-too-large";

    if (containsAny(stderr, &.{
        "UnsupportedInstruction",
        "UnsupportedGlobal",
        "UnsupportedFunction",
        "UnsupportedType",
        "UnsupportedMetadata",
        "InvalidInstruction",
        "InvalidFunction",
        "InvalidGlobal",
        "LineOutsideFunction",
        "Expected",
        "expected",
    })) return "parse-fail";

    if (containsAny(stderr, &.{
        "TypeMismatch",
        "UnknownValue",
        "UnknownBlock",
        "ValueDoesNotDominateUse",
        "DuplicateDefinition",
        "PhiIncoming",
        "FunctionWithoutBlocks",
        "EntryBlockHasPredecessors",
        "InstructionNeedsResult",
        "StoreHasResult",
    })) return "verify-fail";

    if (std.mem.eql(u8, passes, "verify")) return "verify-fail";
    return "optimizer-fail";
}

fn incrementFailure(counts: *Counts, status: []const u8) void {
    if (std.mem.eql(u8, status, "input-too-large")) {
        counts.input_too_large += 1;
    } else if (std.mem.eql(u8, status, "parse-fail")) {
        counts.parse_fail += 1;
    } else if (std.mem.eql(u8, status, "verify-fail")) {
        counts.verify_fail += 1;
    } else {
        counts.optimizer_fail += 1;
    }
}

fn containsAny(haystack: []const u8, needles: []const []const u8) bool {
    for (needles) |needle| {
        if (std.mem.indexOf(u8, haystack, needle) != null) return true;
    }
    return false;
}

fn writeLog(
    allocator: std.mem.Allocator,
    io: std.Io,
    logs_dir: []const u8,
    safe_name_value: []const u8,
    tag: []const u8,
    contents: []const u8,
) ![]const u8 {
    const basename = try std.fmt.allocPrint(allocator, "{s}.{s}.stderr.txt", .{ safe_name_value, tag });
    defer allocator.free(basename);
    const path = try std.fs.path.join(allocator, &.{ logs_dir, basename });
    errdefer allocator.free(path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = contents });
    return path;
}

fn writeToolErrorLog(
    allocator: std.mem.Allocator,
    io: std.Io,
    logs_dir: []const u8,
    safe_name_value: []const u8,
    tag: []const u8,
    err: anyerror,
) ![]const u8 {
    const message = try std.fmt.allocPrint(allocator, "{s}\n", .{@errorName(err)});
    defer allocator.free(message);
    return writeLog(allocator, io, logs_dir, safe_name_value, tag, message);
}

fn appendRow(
    report: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    status: []const u8,
    source: []const u8,
    ir_path: []const u8,
    optimized_ir_path: []const u8,
    log_path: []const u8,
    note: []const u8,
) !void {
    try report.print(allocator, "{s}\t{s}\t{s}\t{s}\t{s}\t{s}\n", .{
        status,
        source,
        ir_path,
        optimized_ir_path,
        log_path,
        note,
    });
}

fn maybeWriteProgress(
    allocator: std.mem.Allocator,
    io: std.Io,
    cwd: std.Io.Dir,
    report_path: []const u8,
    summary_path: []const u8,
    report: []const u8,
    counts: Counts,
    processed: usize,
    opts: Options,
    zig_exe: []const u8,
    test_root: []const u8,
) !void {
    if (opts.progress_every == 0) return;
    if (processed % opts.progress_every != 0) return;
    try writeProgress(allocator, io, cwd, report_path, summary_path, report, counts, processed, opts, zig_exe, test_root, false);
}

fn writeProgress(
    allocator: std.mem.Allocator,
    io: std.Io,
    cwd: std.Io.Dir,
    report_path: []const u8,
    summary_path: []const u8,
    report: []const u8,
    counts: Counts,
    processed: usize,
    opts: Options,
    zig_exe: []const u8,
    test_root: []const u8,
    final: bool,
) !void {
    try cwd.writeFile(io, .{ .sub_path = report_path, .data = report });

    var summary: std.ArrayList(u8) = .empty;
    defer summary.deinit(allocator);
    try summary.print(allocator,
        \\complete={}
        \\zig_exe={s}
        \\local_zig_exe={s}
        \\local_zllvm_exe={s}
        \\local_build_optimize={s}
        \\local_trace={}
        \\local_quiet={}
        \\test_root={s}
        \\mode={s}
        \\target={s}
        \\passes={s}
        \\source_report={s}
        \\source_status={s}
        \\local_input_limit={}
        \\local_output_limit={}
        \\capture_optimized_output={}
        \\candidates={}
        \\processed={}
        \\compile_skip={}
        \\emit_ok={}
        \\local_ok={}
        \\input_too_large={}
        \\parse_fail={}
        \\verify_fail={}
        \\optimizer_fail={}
        \\
    , .{
        final,
        zig_exe,
        opts.local_zig_exe,
        opts.local_zllvm_exe orelse "",
        opts.local_build_optimize,
        opts.local_trace,
        opts.local_quiet,
        test_root,
        opts.mode,
        opts.target,
        opts.passes,
        opts.source_report orelse "",
        opts.source_status orelse "",
        opts.local_input_limit,
        opts.local_output_limit,
        opts.capture_optimized_output,
        counts.candidates,
        processed,
        counts.compile_skip,
        counts.emit_ok,
        counts.local_ok,
        counts.input_too_large,
        counts.parse_fail,
        counts.verify_fail,
        counts.optimizer_fail,
    });
    try cwd.writeFile(io, .{ .sub_path = summary_path, .data = summary.items });

    if (!final and processed == 0) return;

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const label = if (final) "final" else "progress";
    try stdout_writer.interface.print(
        "{s} processed={}/{} compile-skip={} emit-ok={} local-ok={} input-too-large={} parse-fail={} verify-fail={} optimizer-fail={}\n",
        .{
            label,
            processed,
            counts.candidates,
            counts.compile_skip,
            counts.emit_ok,
            counts.local_ok,
            counts.input_too_large,
            counts.parse_fail,
            counts.verify_fail,
            counts.optimizer_fail,
        },
    );
    try stdout_writer.interface.flush();
}

fn oneLineNote(stderr: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, stderr, " \t\r\n");
    if (trimmed.len == 0) return "";
    if (std.mem.indexOfScalar(u8, trimmed, '\n')) |index| return trimmed[0..index];
    return trimmed;
}

fn safeName(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    for (path) |byte| {
        const safe = switch (byte) {
            'a'...'z', 'A'...'Z', '0'...'9', '.', '-', '_' => byte,
            else => '_',
        };
        try out.append(allocator, safe);
    }
    return out.toOwnedSlice(allocator);
}

fn targetTag(target: []const u8) []const u8 {
    if (std.mem.indexOfScalar(u8, target, '-')) |index| return target[0..index];
    return target;
}

fn stringLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs) == .lt;
}
