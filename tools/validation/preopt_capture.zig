//! The preopt hook has two distinct stdout contracts: LLVM text, then an object.
const std = @import("std");
const u = @import("common.zig");
const Runner = @import("runner.zig").Runner;

pub const Stage = enum { optimize, emit };

pub fn passes(mode: []const u8) ![]const u8 {
    if (std.mem.eql(u8, mode, "ReleaseSafe")) return "zig-release-safe-accepted";
    if (std.mem.eql(u8, mode, "ReleaseFast")) return "zig-release-fast-accepted";
    if (std.mem.eql(u8, mode, "ReleaseSmall")) return "zig-release-small-accepted";
    return error.UnsupportedPreoptMode;
}

pub fn stage(argv: []const []const u8, mode: []const u8) !Stage {
    const pipeline = try passes(mode);
    if (argv.len == 3 and std.mem.startsWith(u8, argv[0], "--passes=") and
        std.mem.eql(u8, argv[0][9..], pipeline) and std.mem.eql(u8, argv[1], "--input-limit=67108864")) return .optimize;
    if (argv.len == 4 and std.mem.eql(u8, argv[0], "--emit=obj") and
        std.mem.eql(u8, argv[1], "--target=x86_64-unknown-linux-gnu") and
        std.mem.eql(u8, argv[2], "--input-limit=67108864")) return .emit;
    return error.UnexpectedPreoptHookInvocation;
}

pub fn inputLimit(bytes: u64) !u64 {
    return std.math.add(u64, bytes, 1);
}

pub fn identity(c: *u.Context, path: []const u8) !u.Value {
    return u.toValue(c.a, .{ .path = path, .bytes = (try std.Io.Dir.cwd().statFile(c.io, path, .{})).size, .sha256 = try c.digest(path) });
}

/// LLVM's ExecuteAndWait redirects stdout to an actual frontend output file.
/// That path binds a later emission invocation to this optimization, rather
/// than relying on PID ordering or guessing a module from a filename.
pub fn deliveryPath(c: *u.Context) ![]const u8 {
    const path = try std.Io.Dir.cwd().realPathFileAlloc(c.io, "/proc/self/fd/1", c.a);
    if ((try std.Io.Dir.cwd().statFile(c.io, path, .{})).kind != .file) return error.PreoptDeliveryRequiresFile;
    return path;
}

pub fn deliver(c: *u.Context, path: []const u8) !void {
    const file = try std.Io.Dir.cwd().openFile(c.io, path, .{});
    defer file.close(c.io);
    var buffer: [65536]u8 = undefined;
    var reader = file.readerStreaming(c.io, &buffer);
    var out_buffer: [65536]u8 = undefined;
    var writer = std.Io.File.stdout().writerStreaming(c.io, &out_buffer);
    _ = try reader.interface.streamRemaining(&writer.interface);
    try writer.interface.flush();
}

pub fn optimize(c: *u.Context, root: []const u8, argv: []const []const u8) !u8 {
    const mode = c.env.get("ZLLVM_ZIG_MODE") orelse return error.MissingPreoptMode;
    if (try stage(argv, mode) != .optimize) return error.UnexpectedPreoptHookInvocation;
    const directory = try c.newOutput(try c.fmt("{s}/{d}", .{ root, std.os.linux.getpid() }));
    const original = argv[argv.len - 1];
    const input = try c.join(&.{ directory, "input.ll" });
    const output = try c.join(&.{ directory, "optimized.ll" });
    const compiler = c.env.get("ZLLVM_WHOLE_BACKEND") orelse return error.MissingBackend;
    const delivery = try deliveryPath(c);
    var report = try u.toValue(c.a, .{
        .stage = "optimize",
        .pipeline = "preopt",
        .mode = mode,
        .passes = try passes(mode),
        .backend = try identity(c, compiler),
        .original_input = original,
        .original_input_resolved = try std.Io.Dir.cwd().realPathFileAlloc(c.io, original, c.a),
        .original_argv = argv,
        .delivery_path = delivery,
        .input_captured = false,
        .optimization_complete = false,
        .output_delivered = false,
        .object_complete = false,
        .failure_stage = "capture",
    });
    const invocation = try c.join(&.{ directory, "invocation.json" });
    try c.writeJson(invocation, report);
    try @import("shared_input.zig").capture(c, original, input);
    const input_identity = try identity(c, input);
    if (!std.mem.eql(u8, try c.digest(original), try u.str(input_identity, "sha256"))) return error.InputChangedDuringCapture;
    try u.put(c.a, &report, "input", input_identity);
    try u.put(c.a, &report, "input_captured", u.b(true));
    try c.writeJson(invocation, report);
    const command = &.{ compiler, argv[0], try c.fmt("--input-limit={d}", .{try inputLimit(@intCast((try u.get(input_identity, "bytes")).integer))}), input };
    try c.writeJson(try c.join(&.{ directory, "effective-argv.json" }), command);
    var runner = Runner.init(c, directory);
    const result = try runner.run(command, try c.join(&.{ directory, "optimizer" }), &c.env, .{
        .timeout_ms = try std.fmt.parseInt(u32, c.env.get("ZLLVM_WHOLE_TIMEOUT_MS") orelse "3600000", 10),
        .stdout_file = output,
        .group = .child_only,
    });
    try u.put(c.a, &report, "returncode", u.n(result.code));
    try u.put(c.a, &report, "process_completed", u.b(result.completed));
    try u.put(c.a, &report, "commands", runner.commands);
    try u.put(c.a, &report, "output", try identity(c, output));
    if (!result.completed or result.code != 0) {
        try u.put(c.a, &report, "failure_stage", u.s("optimization"));
        try c.writeJson(try c.join(&.{ directory, "report.json" }), report);
        return 1;
    }
    if ((try std.Io.Dir.cwd().statFile(c.io, output, .{})).size == 0) return error.EmptyOptimizerOutput;
    if (!std.mem.eql(u8, try c.digest(compiler), try u.str(try u.get(report, "backend"), "sha256"))) return error.BackendChanged;
    try u.put(c.a, &report, "optimization_complete", u.b(true));
    try deliver(c, output);
    if (!std.mem.eql(u8, try c.digest(delivery), try c.digest(output))) return error.OptimizerDeliveryChanged;
    try u.put(c.a, &report, "output_delivered", u.b(true));
    try u.put(c.a, &report, "failure_stage", u.s("none"));
    try c.writeJson(try c.join(&.{ directory, "report.json" }), report);
    return 0;
}

pub fn matches(optimization: u.Value, input: u.Value, original: []const u8) !bool {
    return u.json.is(optimization.object.get("stage") orelse .null, "optimize") and
        u.json.eql(optimization.object.get("optimization_complete") orelse .null, u.b(true)) and
        u.json.eql(optimization.object.get("output_delivered") orelse .null, u.b(true)) and
        u.json.eql(optimization.object.get("object_complete") orelse .null, u.b(false)) and
        u.json.is(optimization.object.get("delivery_path") orelse .null, original) and
        u.json.eql(try u.get(try u.get(optimization, "output"), "sha256"), try u.get(input, "sha256")) and
        u.json.eql(try u.get(try u.get(optimization, "output"), "bytes"), try u.get(input, "bytes"));
}

pub fn find(c: *u.Context, root: []const u8, input: u.Value, original: []const u8) !u.Value {
    var dir = try std.Io.Dir.cwd().openDir(c.io, root, .{ .iterate = true });
    defer dir.close(c.io);
    var it = dir.iterate();
    var selected: ?u.Value = null;
    while (try it.next(c.io)) |entry| {
        if (entry.kind != .directory) continue;
        const directory = try c.join(&.{ root, entry.name });
        const path = try c.join(&.{ directory, "report.json" });
        if (!u.exists(c.io, path)) continue;
        var report = try c.load(path);
        if (!try matches(report, input, original)) continue;
        if (selected != null) return error.AmbiguousOptimizerInput;
        try u.put(c.a, &report, "directory", u.s(directory));
        selected = report;
    }
    return selected orelse error.MissingOptimizerInput;
}

pub fn audit(c: *u.Context, root: []const u8, parent: u.Value, object: u.Value) !void {
    if (!u.json.is(parent.object.get("local_pipeline") orelse .null, "preopt")) return;
    if (!u.json.is(try u.get(object, "stage"), "emit") or !u.json.eql(try u.get(object, "object_delivered"), u.b(true))) return error.IncompletePreoptChain;
    const directory = try u.str(object, "optimizer_directory");
    if (!u.isWithin(try c.join(&.{ root, "captures" }), directory)) return error.OptimizerOutsideRun;
    const report = try c.load(try c.join(&.{ directory, "report.json" }));
    var matched: usize = 0;
    for ((try u.get(parent, "optimizations")).array.items) |recorded| {
        if (!u.json.is(try u.get(recorded, "directory"), directory)) continue;
        if (recorded.object.count() != report.object.count() + 1) return error.OptimizerCaptureChanged;
        var fields = report.object.iterator();
        while (fields.next()) |field| if (!u.json.eql(field.value_ptr.*, recorded.object.get(field.key_ptr.*) orelse .null)) return error.OptimizerCaptureChanged;
        matched += 1;
    }
    const object_invocation = try c.load(try c.join(&.{ try u.str(object, "directory"), "invocation.json" }));
    if (!u.json.eql(try u.get(object, "original_input_resolved"), try u.get(object_invocation, "original_input_resolved"))) return error.PreoptInputOriginChanged;
    if (matched != 1 or !try matches(report, try u.get(object, "input"), try u.str(object, "original_input_resolved"))) return error.IncompletePreoptChain;
    for ([_][]const u8{ "input", "output" }) |field| {
        const recorded = try u.get(report, field);
        const path = try c.join(&.{ directory, if (std.mem.eql(u8, field, "input")) "input.ll" else "optimized.ll" });
        if (!u.json.is(try u.get(recorded, "path"), path) or !u.json.eql(recorded, try identity(c, path))) return error.OptimizerArtifactChanged;
    }
    const invocation = try c.load(try c.join(&.{ directory, "invocation.json" }));
    for ([_][]const u8{ "stage", "pipeline", "mode", "passes", "backend", "original_input", "original_input_resolved", "original_argv", "delivery_path", "input" }) |field| {
        if (!u.json.eql(try u.get(invocation, field), try u.get(report, field))) return error.OptimizerCaptureChanged;
    }
    const original_values = try u.json.array(try u.get(report, "original_argv"));
    const original_argv = try c.a.alloc([]const u8, original_values.len);
    for (original_values, original_argv) |value, *arg| arg.* = try u.json.text(value);
    if (try stage(original_argv, try u.str(parent, "mode")) != .optimize) return error.OptimizerCommandMismatch;
    const backend = try u.get(parent, "backend");
    if (!u.json.eql(backend, try u.toValue(c.a, .{ .path = try u.str(try u.get(report, "backend"), "path"), .sha256 = try u.str(try u.get(report, "backend"), "sha256") }))) return error.BackendIdentityChanged;
    const commands = try c.load(try c.join(&.{ directory, "commands.json" }));
    if (commands.array.items.len != 1) return error.ExpectedOneOptimizerCommand;
    const command = commands.array.items[0];
    if (!u.json.is(try u.get(command, "outcome"), "completed") or (try u.get(command, "actual_returncode")).integer != 0 or (try u.get(command, "returncode")).integer != 0) return error.OptimizerDidNotComplete;
    const effective = try c.load(try c.join(&.{ directory, "effective-argv.json" }));
    const expected = try u.strings(c.a, &.{
        try u.str(backend, "path"),
        try c.fmt("--passes={s}", .{try passes(try u.str(parent, "mode"))}),
        try c.fmt("--input-limit={d}", .{try inputLimit(@intCast((try u.get(try u.get(report, "input"), "bytes")).integer))}),
        try u.str(try u.get(report, "input"), "path"),
    });
    if (!u.json.eql(effective, expected) or !u.json.eql(try u.get(command, "argv"), expected)) return error.OptimizerCommandMismatch;
}

test "preopt stages reject wrong modes mixed contracts and changed pipelines" {
    try std.testing.expectEqual(Stage.optimize, try stage(&.{ "--passes=zig-release-safe-accepted", "--input-limit=67108864", "/input.ll" }, "ReleaseSafe"));
    try std.testing.expectEqual(Stage.emit, try stage(&.{ "--emit=obj", "--target=x86_64-unknown-linux-gnu", "--input-limit=67108864", "/input.ll" }, "ReleaseSafe"));
    try std.testing.expectError(error.UnsupportedPreoptMode, stage(&.{}, "Debug"));
    try std.testing.expectError(error.UnexpectedPreoptHookInvocation, stage(&.{ "--passes=zig-release-fast-accepted", "--input-limit=67108864", "/input.ll" }, "ReleaseSafe"));
    try std.testing.expectError(error.UnexpectedPreoptHookInvocation, stage(&.{ "--emit=obj", "--passes=zig-release-safe-accepted", "/input.ll" }, "ReleaseSafe"));
    try std.testing.expectEqual(@as(u64, 67_108_866), try inputLimit(67_108_865));
    try std.testing.expectError(error.Overflow, inputLimit(std.math.maxInt(u64)));
}

test "preopt identity chains reject incomplete text outputs wrong paths and mismatched bytes" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const input = try u.toValue(a, .{ .bytes = 123, .sha256 = "same" });
    var optimization = try u.toValue(a, .{ .stage = "optimize", .optimization_complete = true, .output_delivered = true, .object_complete = false, .delivery_path = "/frontend/optimized.ll", .output = input });
    try std.testing.expect(try matches(optimization, input, "/frontend/optimized.ll"));
    try std.testing.expect(!try matches(optimization, input, "/another/module.ll"));
    try std.testing.expect(!try matches(optimization, try u.toValue(a, .{ .bytes = 124, .sha256 = "same" }), "/frontend/optimized.ll"));
    try u.put(a, &optimization, "optimization_complete", u.b(false));
    try std.testing.expect(!try matches(optimization, input, "/frontend/optimized.ll"));
    try u.put(a, &optimization, "optimization_complete", u.b(true));
    try u.put(a, &optimization, "object_complete", u.b(true));
    try std.testing.expect(!try matches(optimization, input, "/frontend/optimized.ll"));
}
