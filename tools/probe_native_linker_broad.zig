const std = @import("std");
const common = @import("tool_common.zig");

const usage =
    \\usage: zig build probe-native-linker-broad -- --mode=ReleaseFast|ReleaseSafe|ReleaseSmall|Debug [options]
    \\
    \\Options:
    \\  --input-dir=DIR          Override the mode default optimized IR/input directory
    \\  --target=TRIPLE          z_llvm object target [x86_64-unknown-linux-gnu]
    \\  --cc-target=TRIPLE       Zig linker target [x86_64-linux-gnu]
    \\  --input-limit=N          z_llvm input limit [67108864]
    \\  --zllvm-exe=PATH         z_llvm executable [zig-out/bin/z_llvm]
    \\  --exclude=FILE:REASON    Skip one optimized IR filename with a boundary reason
    \\  --summary=PATH           Also write the stable probe summary to PATH
    \\  --keep-objects=DIR       Keep emitted objects, stubs, and logs under DIR
    \\  --help                   Show this help
    \\
;

const Options = struct {
    mode: ?[]const u8 = null,
    input_dir: ?[]const u8 = null,
    target: []const u8 = "x86_64-unknown-linux-gnu",
    cc_target: []const u8 = "x86_64-linux-gnu",
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
    accepted: usize = 0,
    accounted: usize = 0,
    local_fail: usize = 0,
    excluded: usize = 0,
    first_failure: []const u8 = "-",
    first_failure_category: []const u8 = "-",
    accounted_categories: std.ArrayList(CategoryCount) = .empty,
    local_categories: std.ArrayList(CategoryCount) = .empty,
    excluded_categories: std.ArrayList(CategoryCount) = .empty,

    fn deinit(counts: *Counts, allocator: std.mem.Allocator) void {
        counts.accounted_categories.deinit(allocator);
        counts.local_categories.deinit(allocator);
        counts.excluded_categories.deinit(allocator);
    }
};

const Symbol = struct {
    name: []const u8,
    type_name: []const u8,
    ndx: []const u8,
};

const LinkPlan = struct {
    has_start: bool = false,
    has_main: bool = false,
    stubs: std.ArrayList(Stub) = .empty,
    boundary_symbol: ?[]const u8 = null,
    boundary_category: ?Category = null,

    fn deinit(plan: *LinkPlan, allocator: std.mem.Allocator) void {
        for (plan.stubs.items) |stub| allocator.free(stub.symbol);
        plan.stubs.deinit(allocator);
        if (plan.boundary_symbol) |symbol| allocator.free(symbol);
    }
};

const Category = enum {
    zig_panic_runtime,
    zig_startup_runtime,
    zig_test_runtime,
    zig_debug_runtime,
    zig_tls_runtime,
    libc_compiler_rt,
    unknown_local_candidate,
    data_symbol,
    symbol,
    relocation,
    section,
    comdat,
    alignment,
    abi,
    object_error,
    object_unknown,
    unsupported_control_flow,
    unsupported_instruction,
    unsupported_value,
    unsupported_type,
    unsupported_abi,
    unsupported_target,
    input_too_large,
    unknown_linker_compatibility,

    fn name(category: Category) []const u8 {
        return switch (category) {
            .zig_panic_runtime => "zig-panic-runtime",
            .zig_startup_runtime => "zig-startup-runtime",
            .zig_test_runtime => "zig-test-runtime",
            .zig_debug_runtime => "zig-debug-runtime",
            .zig_tls_runtime => "zig-tls-runtime",
            .libc_compiler_rt => "libc/compiler-rt",
            .unknown_local_candidate => "unknown-local-candidate",
            .data_symbol => "data-symbol",
            .symbol => "symbol",
            .relocation => "relocation",
            .section => "section",
            .comdat => "comdat",
            .alignment => "alignment",
            .abi => "abi",
            .object_error => "object-error",
            .object_unknown => "object-unknown",
            .unsupported_control_flow => "unsupported-control-flow",
            .unsupported_instruction => "unsupported-instruction",
            .unsupported_value => "unsupported-value",
            .unsupported_type => "unsupported-type",
            .unsupported_abi => "unsupported-abi",
            .unsupported_target => "unsupported-target",
            .input_too_large => "input-too-large",
            .unknown_linker_compatibility => "unknown-linker-compatibility",
        };
    }

    fn isLocalFailure(category: Category) bool {
        return switch (category) {
            .unknown_local_candidate,
            .symbol,
            .relocation,
            .section,
            .comdat,
            .alignment,
            .abi,
            .object_error,
            .object_unknown,
            .unsupported_control_flow,
            .unsupported_instruction,
            .unsupported_value,
            .unsupported_type,
            .unsupported_abi,
            .unsupported_target,
            .input_too_large,
            .unknown_linker_compatibility,
            => true,
            .zig_panic_runtime,
            .zig_startup_runtime,
            .zig_test_runtime,
            .zig_debug_runtime,
            .zig_tls_runtime,
            .libc_compiler_rt,
            .data_symbol,
            => false,
        };
    }
};

const Stub = struct {
    symbol: []const u8,
    category: Category,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const build_argv = [_][]const u8{ "zig", "build" };
    const build_result = try common.runCapture(allocator, io, &build_argv, "zig build");
    common.freeRunResult(allocator, build_result);

    var opts = try parseArgs(allocator, io, init);
    defer opts.deinit(allocator);

    const mode = opts.mode orelse try fatal(io, "missing required --mode\n{s}", .{usage});
    const input_dir = opts.input_dir orelse defaultInputDir(mode);
    if (std.mem.eql(u8, mode, "ReleaseSmall") and opts.excludes.items.len == 0) {
        try opts.excludes.append(allocator, .{
            .name = "standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll",
            .reason = "float-format-helper-boundary",
        });
        try opts.excludes.append(allocator, .{
            .name = "standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll",
            .reason = "table-decoder-boundary",
        });
    }

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

    const temp: common.TempDir = if (opts.keep_objects) |keep_objects|
        .{ .path = keep_objects }
    else
        try common.TempDir.init(allocator, io, "native_linker_broad");
    defer if (opts.keep_objects == null) temp.deinit(allocator, io);

    var output: std.ArrayList(u8) = .empty;
    defer output.deinit(allocator);

    var counts: Counts = .{};
    defer counts.deinit(allocator);

    try output.print(allocator, "native-link-broad mode={s} target={s} cc_target={s} input_dir={s} linker=zig build-exe -fno-lld\n", .{
        mode,
        opts.target,
        opts.cc_target,
        input_dir,
    });

    for (files.items) |file| {
        counts.total += 1;

        if (excludeReason(opts.excludes.items, file)) |reason| {
            counts.excluded += 1;
            try incrementCategory(allocator, &counts.excluded_categories, reason);
            try output.print(allocator, "excluded {s} reason={s}\n", .{ file, reason });
            continue;
        }

        const result = try probeFile(allocator, io, temp, opts, input_dir, file);
        defer {
            if (result.symbol) |symbol| allocator.free(symbol);
            if (result.log) |log| allocator.free(log);
        }

        switch (result.kind) {
            .accepted => {
                counts.accepted += 1;
                try output.print(allocator, "accepted {s} validation=link-only\n", .{file});
            },
            .accounted => |category| {
                counts.accounted += 1;
                try incrementCategory(allocator, &counts.accounted_categories, category.name());
                try output.print(allocator, "accounted {s} category={s}", .{ file, category.name() });
                if (result.symbol) |symbol| try output.print(allocator, " symbol={s}", .{symbol});
                if (result.log) |log| try output.print(allocator, " {s}", .{firstLine(log)});
                try output.append(allocator, '\n');
            },
            .local_fail => |category| {
                counts.local_fail += 1;
                try incrementCategory(allocator, &counts.local_categories, category.name());
                if (std.mem.eql(u8, counts.first_failure, "-")) {
                    counts.first_failure = file;
                    counts.first_failure_category = category.name();
                }
                try output.print(allocator, "local_fail {s} category={s}", .{ file, category.name() });
                if (result.symbol) |symbol| try output.print(allocator, " symbol={s}", .{symbol});
                if (result.log) |log| try output.print(allocator, " {s}", .{firstLine(log)});
                try output.append(allocator, '\n');
            },
        }
    }

    const accounted_total = counts.accepted + counts.accounted + counts.excluded;
    try output.print(allocator, "summary mode={s} total={} accepted={} accounted={} local_fail={} excluded={} accounted_total={} first_failure={s} first_failure_category={s}\n", .{
        mode,
        counts.total,
        counts.accepted,
        counts.accounted,
        counts.local_fail,
        counts.excluded,
        accounted_total,
        counts.first_failure,
        counts.first_failure_category,
    });

    std.mem.sort(CategoryCount, counts.accounted_categories.items, {}, categoryLessThan);
    for (counts.accounted_categories.items) |category| {
        try output.print(allocator, "accounted_category {s}={}\n", .{ category.name, category.count });
    }

    std.mem.sort(CategoryCount, counts.local_categories.items, {}, categoryLessThan);
    for (counts.local_categories.items) |category| {
        try output.print(allocator, "local_fail_category {s}={}\n", .{ category.name, category.count });
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

const ProbeFileResult = struct {
    kind: union(enum) {
        accepted,
        accounted: Category,
        local_fail: Category,
    },
    symbol: ?[]u8 = null,
    log: ?[]u8 = null,
};

fn probeFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    opts: Options,
    input_dir: []const u8,
    file: []const u8,
) !ProbeFileResult {
    const input_path = try std.fs.path.join(allocator, &.{ input_dir, file });
    defer allocator.free(input_path);

    const stem = try safeStem(allocator, file);
    defer allocator.free(stem);
    const object = try common.allocTempFile(allocator, temp, stem, ".o");
    defer allocator.free(object);
    const symbols_path = try common.allocTempFile(allocator, temp, stem, ".symbols.txt");
    defer allocator.free(symbols_path);
    const harness_c = try common.allocTempFile(allocator, temp, stem, "_link_main.c");
    defer allocator.free(harness_c);
    const harness_o = try common.allocTempFile(allocator, temp, stem, "_link_main.o");
    defer allocator.free(harness_o);
    const stubs_s = try common.allocTempFile(allocator, temp, stem, "_stubs.s");
    defer allocator.free(stubs_s);
    const stubs_o = try common.allocTempFile(allocator, temp, stem, "_stubs.o");
    defer allocator.free(stubs_o);
    const exe = try common.allocTempFile(allocator, temp, stem, "_link_only");
    defer allocator.free(exe);

    const emit_result = try emitObject(allocator, io, opts, input_path);
    defer common.freeRunResult(allocator, emit_result);
    if (!common.termOk(emit_result.term)) {
        const log = try allocator.dupe(u8, if (emit_result.stderr.len != 0) emit_result.stderr else emit_result.stdout);
        return .{ .kind = .{ .local_fail = objectCategoryForError(log) }, .log = log };
    }
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = object, .data = emit_result.stdout });

    const readelf_argv = [_][]const u8{ "readelf", "-Ws", object };
    try common.runToFile(allocator, io, &readelf_argv, "readelf -Ws", symbols_path);

    var plan = try buildLinkPlan(allocator, io, symbols_path);
    defer plan.deinit(allocator);
    if (plan.boundary_category) |category| {
        return .{
            .kind = if (category.isLocalFailure()) .{ .local_fail = category } else .{ .accounted = category },
            .symbol = if (plan.boundary_symbol) |symbol| try allocator.dupe(u8, symbol) else null,
        };
    }

    var link_args: std.ArrayList([]const u8) = .empty;
    defer link_args.deinit(allocator);
    const emit_bin_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{exe});
    defer allocator.free(emit_bin_arg);
    try link_args.appendSlice(allocator, &.{ "zig", "build-exe", "-target", opts.cc_target, "-fno-lld" });

    if (plan.has_start) {
        try link_args.append(allocator, "-fentry=_start");
    } else if (!plan.has_main) {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = harness_c, .data = "int main(void) { return 0; }\n" });
        const cc_argv = [_][]const u8{ "zig", "cc", "-target", opts.cc_target, "-c", harness_c, "-o", harness_o };
        const cc_result = try common.runCapture(allocator, io, &cc_argv, "zig cc -c broad native-link harness");
        common.freeRunResult(allocator, cc_result);
        try link_args.append(allocator, harness_o);
    }

    try link_args.append(allocator, object);
    if (plan.stubs.items.len != 0) {
        try writeStubAsm(allocator, io, stubs_s, plan.stubs.items);
        const asm_argv = [_][]const u8{ "zig", "cc", "-target", opts.cc_target, "-c", stubs_s, "-o", stubs_o };
        const asm_result = try common.runCapture(allocator, io, &asm_argv, "zig cc -c broad native-link stubs");
        common.freeRunResult(allocator, asm_result);
        try link_args.append(allocator, stubs_o);
    }

    if (!plan.has_start) try link_args.appendSlice(allocator, &.{ "-lm", "-lc" });
    try link_args.append(allocator, emit_bin_arg);

    const link_result = try std.process.run(allocator, io, .{
        .argv = link_args.items,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer allocator.free(link_result.stdout);
    if (common.termOk(link_result.term)) {
        allocator.free(link_result.stderr);
        if (firstStubCategory(plan.stubs.items)) |category| {
            return .{ .kind = .{ .accounted = category } };
        }
        return .{ .kind = .accepted };
    }

    const category = linkCategoryForError(link_result.stderr);
    return .{ .kind = if (category.isLocalFailure()) .{ .local_fail = category } else .{ .accounted = category }, .log = link_result.stderr };
}

fn emitObject(allocator: std.mem.Allocator, io: std.Io, opts: Options, input_path: []const u8) !std.process.RunResult {
    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{opts.target});
    defer allocator.free(target_arg);
    const input_limit_arg = try std.fmt.allocPrint(allocator, "--input-limit={}", .{opts.input_limit});
    defer allocator.free(input_limit_arg);
    const argv = [_][]const u8{ opts.zllvm_exe, "--emit=obj", target_arg, input_limit_arg, input_path };
    return std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
}

fn buildLinkPlan(allocator: std.mem.Allocator, io: std.Io, symbols_path: []const u8) !LinkPlan {
    var plan: LinkPlan = .{};
    errdefer plan.deinit(allocator);

    const contents = try std.Io.Dir.cwd().readFileAlloc(io, symbols_path, allocator, .limited(32 * 1024 * 1024));
    defer allocator.free(contents);

    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        const symbol = parseSymbol(line) orelse continue;
        if (!std.mem.eql(u8, symbol.ndx, "UND")) {
            if (std.mem.eql(u8, symbol.name, "_start")) plan.has_start = true;
            if (std.mem.eql(u8, symbol.name, "main")) plan.has_main = true;
            continue;
        }
        if (symbol.name.len == 0) continue;

        if (std.mem.eql(u8, symbol.type_name, "TLS")) {
            plan.boundary_symbol = try allocator.dupe(u8, symbol.name);
            plan.boundary_category = .zig_tls_runtime;
            return plan;
        }
        if (std.mem.eql(u8, symbol.type_name, "OBJECT")) {
            plan.boundary_symbol = try allocator.dupe(u8, symbol.name);
            plan.boundary_category = .data_symbol;
            return plan;
        }

        if (classifyStubbedFunctionImport(symbol.name)) |category| {
            try plan.stubs.append(allocator, .{
                .symbol = try allocator.dupe(u8, symbol.name),
                .category = category,
            });
            continue;
        }

        if (classifyRuntimeBoundary(symbol.name)) |category| {
            plan.boundary_symbol = try allocator.dupe(u8, symbol.name);
            plan.boundary_category = category;
            return plan;
        }

        plan.boundary_symbol = try allocator.dupe(u8, symbol.name);
        plan.boundary_category = .unknown_local_candidate;
        return plan;
    }

    return plan;
}

fn parseSymbol(line: []const u8) ?Symbol {
    const colon = std.mem.indexOfScalar(u8, line, ':') orelse return null;
    _ = std.fmt.parseInt(usize, std.mem.trim(u8, line[0..colon], " \t"), 10) catch return null;
    var fields: [6][]const u8 = undefined;
    var rest = std.mem.trim(u8, line[colon + 1 ..], " \t");
    var index: usize = 0;
    while (index < fields.len) : (index += 1) {
        const field_end = std.mem.indexOfAny(u8, rest, " \t") orelse return null;
        fields[index] = rest[0..field_end];
        rest = std.mem.trim(u8, rest[field_end..], " \t");
    }
    return .{
        .name = rest,
        .type_name = fields[2],
        .ndx = fields[5],
    };
}

fn writeStubAsm(allocator: std.mem.Allocator, io: std.Io, path: []const u8, stubs: []const Stub) !void {
    var text: std.ArrayList(u8) = .empty;
    defer text.deinit(allocator);
    for (stubs) |symbol| {
        const block = try std.fmt.allocPrint(allocator,
            \\.text
            \\.globl "{s}"
            \\.type "{s}", @function
            \\"{s}":
            \\  ud2
            \\
        , .{ symbol.symbol, symbol.symbol, symbol.symbol });
        defer allocator.free(block);
        try text.appendSlice(allocator, block);
    }
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = text.items });
}

fn parseArgs(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Options {
    var opts: Options = .{};
    if (try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET")) |target| opts.target = target;
    if (try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "CC_TARGET")) |cc_target| opts.cc_target = cc_target;
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
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            opts.mode = arg["--mode=".len..];
            if (!isKnownMode(opts.mode.?)) try fatal(io, "unknown --mode: {s}\n{s}", .{ opts.mode.?, usage });
        } else if (std.mem.startsWith(u8, arg, "--input-dir=")) {
            opts.input_dir = arg["--input-dir=".len..];
        } else if (std.mem.startsWith(u8, arg, "--target=")) {
            opts.target = arg["--target=".len..];
        } else if (std.mem.startsWith(u8, arg, "--cc-target=")) {
            opts.cc_target = arg["--cc-target=".len..];
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

fn defaultInputDir(mode: []const u8) []const u8 {
    if (std.mem.eql(u8, mode, "ReleaseFast")) return "tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir";
    if (std.mem.eql(u8, mode, "ReleaseSafe")) return "tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir";
    if (std.mem.eql(u8, mode, "ReleaseSmall")) return "tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir";
    if (std.mem.eql(u8, mode, "Debug")) return "test/distribution/debug_x86_64/inputs";
    unreachable;
}

fn isKnownMode(mode: []const u8) bool {
    return std.mem.eql(u8, mode, "ReleaseFast") or
        std.mem.eql(u8, mode, "ReleaseSafe") or
        std.mem.eql(u8, mode, "ReleaseSmall") or
        std.mem.eql(u8, mode, "Debug");
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

fn excludeReason(excludes: []const Exclude, file: []const u8) ?[]const u8 {
    for (excludes) |exclude| {
        if (std.mem.eql(u8, exclude.name, file)) return exclude.reason;
    }
    return null;
}

fn objectCategoryForError(log: []const u8) Category {
    const line = firstLine(log);
    if (std.mem.indexOf(u8, line, "UnsupportedCodegenControlFlow") != null) return .unsupported_control_flow;
    if (std.mem.indexOf(u8, line, "UnsupportedCodegenInstruction") != null) return .unsupported_instruction;
    if (std.mem.indexOf(u8, line, "UnsupportedCodegenValue") != null) return .unsupported_value;
    if (std.mem.indexOf(u8, line, "UnsupportedCodegenType") != null) return .unsupported_type;
    if (std.mem.indexOf(u8, line, "UnsupportedCodegenAbi") != null) return .unsupported_abi;
    if (std.mem.indexOf(u8, line, "UnsupportedCodegenTarget") != null) return .unsupported_target;
    if (std.mem.indexOf(u8, line, "InputTooLarge") != null) return .input_too_large;
    if (std.mem.startsWith(u8, line, "error:")) return .object_error;
    return .object_unknown;
}

fn linkCategoryForError(stderr: []const u8) Category {
    if (std.mem.indexOf(u8, stderr, "duplicate symbol") != null) return .symbol;
    if (std.mem.indexOf(u8, stderr, "undefined symbol") != null or
        std.mem.indexOf(u8, stderr, "undefined reference") != null)
    {
        return .unknown_local_candidate;
    }
    if (std.mem.indexOf(u8, stderr, "relocation") != null) return .relocation;
    if (std.mem.indexOf(u8, stderr, "section") != null) return .section;
    if (std.mem.indexOf(u8, stderr, "TLS") != null or std.mem.indexOf(u8, stderr, "thread-local") != null) return .zig_tls_runtime;
    if (std.mem.indexOf(u8, stderr, "COMDAT") != null or std.mem.indexOf(u8, stderr, "comdat") != null) return .comdat;
    if (std.mem.indexOf(u8, stderr, "align") != null) return .alignment;
    if (std.mem.indexOf(u8, stderr, "ABI") != null or std.mem.indexOf(u8, stderr, "calling convention") != null) return .abi;
    return .unknown_linker_compatibility;
}

fn classifyStubbedFunctionImport(name: []const u8) ?Category {
    if (isLibcOrCompilerRtSymbol(name)) return .libc_compiler_rt;
    if (isZigTestRuntimeSymbol(name)) return .zig_test_runtime;
    if (classifyRuntimeBoundary(name)) |category| {
        if (category != .zig_tls_runtime) return category;
    }
    return null;
}

fn classifyRuntimeBoundary(name: []const u8) ?Category {
    if (std.mem.startsWith(u8, name, "start.")) return .zig_startup_runtime;
    if (std.mem.indexOf(u8, name, "Panic") != null or std.mem.indexOf(u8, name, "panic") != null) return .zig_panic_runtime;
    if (std.mem.startsWith(u8, name, "debug.")) return .zig_debug_runtime;
    if (std.mem.startsWith(u8, name, "os.")) return .zig_startup_runtime;
    if (std.mem.startsWith(u8, name, "builtin.")) return .zig_debug_runtime;
    return null;
}

fn isZigTestRuntimeSymbol(name: []const u8) bool {
    return std.mem.startsWith(u8, name, "fuzzer_") or
        std.mem.startsWith(u8, name, "test.") or
        std.mem.indexOf(u8, name, ".test.") != null;
}

fn isLibcOrCompilerRtSymbol(name: []const u8) bool {
    return std.mem.eql(u8, name, "__eqtf2") or
        std.mem.eql(u8, name, "fmodf") or
        std.mem.eql(u8, name, "fmod") or
        std.mem.eql(u8, name, "memcpy") or
        std.mem.eql(u8, name, "memmove") or
        std.mem.eql(u8, name, "memset") or
        std.mem.eql(u8, name, "memcmp");
}

fn firstStubCategory(stubs: []const Stub) ?Category {
    if (stubs.len == 0) return null;
    return stubs[0].category;
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
