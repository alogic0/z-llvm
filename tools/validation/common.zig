//! Shared mechanics for validation tools. Evidence and admission policy stay in consumers.
const std = @import("std");
pub const process = @import("../vendor/process/src/root.zig");
pub const json = @import("../vendor/test_support/src/json.zig");
pub const files = @import("../vendor/test_support/src/files.zig");
pub const file_command = @import("../vendor/test_support/src/file_command.zig").WithProcess(process);
pub const Value = std.json.Value;
pub const modes = [_][]const u8{ "ReleaseFast", "ReleaseSafe", "ReleaseSmall" };
var canceled: process.Cancellation = .{};
var requested_signal: std.atomic.Value(u8) = .init(0);

fn handleSignal(signal: std.posix.SIG) callconv(.c) void {
    requested_signal.store(@intCast(@backingInt(signal)), .release);
    canceled.request();
}
/// CLI policy only: the provider never installs process-wide signal handlers.
pub fn installSignals() void {
    const action: std.posix.Sigaction = .{ .handler = .{ .handler = handleSignal }, .mask = std.posix.sigemptyset(), .flags = 0 };
    std.posix.sigaction(.INT, &action, null);
    std.posix.sigaction(.TERM, &action, null);
}
pub fn cancellation() *const process.Cancellation {
    return &canceled;
}
pub fn cancellationCode() i64 {
    return 128 + @as(i64, requested_signal.load(.acquire));
}

pub const Context = struct {
    a: std.mem.Allocator,
    gpa: std.mem.Allocator,
    io: std.Io,
    root: []const u8,
    env: std.process.Environ.Map,
    diagnostic: ?[]const u8 = null,
    quiet: bool = false,
    workspace_paths: ?@import("storage_paths.zig").Paths = null,

    /// Explicitly classify a generated product as temporary. Logs, inputs and
    /// reports continue to use join(). Legacy/standalone callers retain paths.
    pub fn temporaryPath(c: *Context, parts: []const []const u8) ![]const u8 {
        const original = try c.join(parts);
        const mapping = c.workspace_paths orelse return original;
        if (!isWithin(mapping.evidence, original) or std.mem.eql(u8, mapping.evidence, original)) return error.TemporaryPathOutsideWorkspace;
        const path = try c.fmt("{s}/{s}", .{ mapping.temporary, original[mapping.evidence.len + 1 ..] });
        var parent = try @import("../zllvm_artifact_store/store.zig").openDirectory(c.io, std.fs.path.dirname(path).?, true);
        parent.close(c.io);
        return path;
    }

    /// Diagnostics derived from an artifact name belong in the evidence tree.
    pub fn evidencePath(c: *Context, path: []const u8) ![]const u8 {
        const mapping = c.workspace_paths orelse return path;
        if (!isWithin(mapping.temporary, path) or std.mem.eql(u8, mapping.temporary, path)) return path;
        return c.fmt("{s}/{s}", .{ mapping.evidence, path[mapping.temporary.len + 1 ..] });
    }

    pub fn init(start: std.process.Init) !Context {
        const a = start.arena.allocator();
        const env = try start.minimal.environ.createMap(a);
        var root: []const u8 = try std.Io.Dir.cwd().realPathFileAlloc(start.io, env.get("ZLLVM_PROJECT_ROOT") orelse ".", a);
        while (true) {
            const pin = try std.fs.path.join(a, &.{ root, ".zigversion" });
            const main = try std.fs.path.join(a, &.{ root, "src/main.zig" });
            if (exists(start.io, pin) and exists(start.io, main)) break;
            root = std.fs.path.dirname(root) orelse return error.ProjectRootNotFound;
        }
        return .{ .a = a, .gpa = start.gpa, .io = start.io, .root = root, .env = env };
    }

    pub fn fail(c: *Context, comptime format: []const u8, args: anytype) error{ ValidationFailed, OutOfMemory } {
        c.diagnostic = try std.fmt.allocPrint(c.a, format, args);
        return error.ValidationFailed;
    }

    pub fn join(c: Context, parts: []const []const u8) ![]const u8 {
        const joined = try std.fs.path.join(c.a, parts);
        return std.fs.path.resolve(c.a, &.{ c.root, joined });
    }

    pub fn fmt(c: Context, comptime format: []const u8, args: anytype) ![]const u8 {
        return std.fmt.allocPrint(c.a, format, args);
    }

    pub fn read(c: Context, path: []const u8) ![]u8 {
        return files.read(c.a, c.io, .{ .path = path, .limit = 512 * 1024 * 1024 });
    }

    pub fn load(c: Context, path: []const u8) !Value {
        return (try json.parse(c.a, try c.read(path))).value;
    }

    pub fn write(c: Context, path: []const u8, bytes: []const u8) !void {
        try std.Io.Dir.cwd().writeFile(c.io, .{ .sub_path = path, .data = bytes });
    }

    /// Linux log descriptors append even when a child uses positional stdout/stderr
    /// writers. Independent writers must not overwrite earlier diagnostics.
    pub fn createLog(c: Context, path: []const u8, exclusive: bool) !std.Io.File {
        return files.createLog(c.io, .{ .path = path, .exclusive = exclusive });
    }

    pub fn mkdir(c: Context, path: []const u8) !void {
        try std.Io.Dir.cwd().createDirPath(c.io, path);
    }

    pub fn copy(c: Context, source: []const u8, destination: []const u8) !void {
        const input = try std.Io.Dir.cwd().openFile(c.io, source, .{});
        defer input.close(c.io);
        const output = try std.Io.Dir.cwd().createFile(c.io, destination, .{});
        defer output.close(c.io);
        var buffer: [65536]u8 = undefined;
        var reader = input.readerStreaming(c.io, &buffer);
        var out_buffer: [65536]u8 = undefined;
        var writer = output.writerStreaming(c.io, &out_buffer);
        _ = try reader.interface.streamRemaining(&writer.interface);
        try writer.interface.flush();
    }

    pub fn digest(c: Context, path: []const u8) ![]const u8 {
        return c.a.dupe(u8, &std.fmt.bytesToHex(try files.sha256(c.io, path), .lower));
    }

    pub fn writeJson(c: Context, path: []const u8, value: anytype) !void {
        try json.writeAtomic(c.gpa, c.io, .{ .path = path, .replace = true }, value);
    }

    pub fn print(c: Context, comptime format: []const u8, args: anytype) !void {
        if (c.quiet) return;
        try std.Io.File.stdout().writeStreamingAll(c.io, try c.fmt(format, args));
    }

    pub fn cleanEnvironment(c: Context) !std.process.Environ.Map {
        var env = std.process.Environ.Map.init(c.a);
        for (c.env.keys(), c.env.values()) |key, value| {
            if (!std.mem.startsWith(u8, key, "ZLLVM_") and !std.mem.startsWith(u8, key, "ZIG_USE_ZLLVM")) try env.put(key, value);
        }
        return env;
    }

    pub fn capture(c: *Context, argv: []const []const u8) ![]const u8 {
        const report = try process.runReport(c.gpa, c.io, .{
            .spawn = .{ .argv = argv, .cwd = .{ .path = c.root }, .environ_map = &c.env, .search_path = true, .cancellation = cancellation() },
            .timeout_ms = 120_000,
            .stdout_limit = 512 * 1024 * 1024,
            .stderr_limit = 8 * 1024 * 1024,
        });
        defer report.deinit(c.gpa);
        if (!report.success()) return c.fail("command failed: {s}: {s}: {s}", .{ argv[0], @tagName(report.outcome), report.stderr });
        return c.a.dupe(u8, report.stdout);
    }

    /// Resolve the existing parent before creating anything, rejecting symlink escapes.
    pub fn resolveParent(c: *Context, name: []const u8) ![]const u8 {
        const absolute = try c.join(&.{name});
        var parent = absolute;
        var suffix: []const u8 = "";
        while (!exists(c.io, parent)) {
            suffix = try std.fs.path.join(c.a, &.{ std.fs.path.basename(parent), suffix });
            parent = std.fs.path.dirname(parent) orelse return error.InvalidOutputPath;
        }
        const resolved_parent = try std.Io.Dir.cwd().realPathFileAlloc(c.io, parent, c.a);
        return std.fs.path.resolve(c.a, &.{ resolved_parent, suffix });
    }

    pub fn ownedPath(c: *Context, name: []const u8) ![]const u8 {
        const resolved = try c.resolveParent(name);
        if (!isWithin(c.root, resolved) or std.mem.eql(u8, c.root, resolved)) return c.fail("evidence must stay in a new path inside the project", .{});
        return resolved;
    }

    pub fn newOutput(c: *Context, name: []const u8) ![]const u8 {
        const path = try c.ownedPath(name);
        if (exists(c.io, path)) return error.PathAlreadyExists;
        try c.mkdir(std.fs.path.dirname(path).?);
        try std.Io.Dir.cwd().createDir(c.io, path, .fromMode(0o700));
        return path;
    }
};

pub fn exists(io: std.Io, path: []const u8) bool {
    _ = std.Io.Dir.cwd().statFile(io, path, .{}) catch return false;
    return true;
}
pub fn isWithin(root: []const u8, path: []const u8) bool {
    return std.mem.eql(u8, root, path) or (std.mem.startsWith(u8, path, root) and path.len > root.len and path[root.len] == '/');
}
pub fn digestBytes(a: std.mem.Allocator, bytes: []const u8) ![]const u8 {
    var hash: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &hash, .{});
    return a.dupe(u8, &std.fmt.bytesToHex(hash, .lower));
}
pub fn trim(bytes: []const u8) []const u8 {
    return std.mem.trim(u8, bytes, " \t\r\n");
}
pub fn s(bytes: []const u8) Value {
    return .{ .string = bytes };
}
pub fn n(number: anytype) Value {
    return .{ .integer = @intCast(number) };
}
pub fn b(value: bool) Value {
    return .{ .bool = value };
}
pub fn object(a: std.mem.Allocator) Value {
    _ = a;
    return .{ .object = .empty };
}
pub fn array(a: std.mem.Allocator) Value {
    return .{ .array = std.array_list.Managed(Value).init(a) };
}
pub fn put(a: std.mem.Allocator, value: *Value, key: []const u8, item: Value) !void {
    try value.object.put(a, key, item);
}
pub fn add(value: *Value, item: Value) !void {
    try value.array.append(item);
}
pub fn get(value: Value, key: []const u8) !Value {
    return json.field(value, key);
}
pub fn str(value: Value, key: []const u8) ![]const u8 {
    return json.textField(value, key);
}
pub fn strings(a: std.mem.Allocator, values: []const []const u8) !Value {
    var result = array(a);
    for (values) |value| try add(&result, s(value));
    return result;
}
pub fn stringSlice(a: std.mem.Allocator, value: Value) ![]const []const u8 {
    const items = try json.array(value);
    const out = try a.alloc([]const u8, items.len);
    for (items, out) |item, *dest| {
        dest.* = try json.text(item);
    }
    return out;
}
pub fn increment(a: std.mem.Allocator, value: *Value, key: []const u8, amount: i64) !void {
    const old = value.object.get(key) orelse n(0);
    try put(a, value, key, n(try json.integer(old) + amount));
}
pub fn pipeline(mode: []const u8) ![]const u8 {
    for (modes, [_][]const u8{ "zig-release-fast-accepted", "zig-release-safe-accepted", "zig-release-small-accepted" }) |m, p| if (std.mem.eql(u8, m, mode)) return p;
    return error.InvalidMode;
}
pub fn returnCode(term: std.process.Child.Term) i64 {
    return switch (term) {
        .exited => |code| code,
        .signal => |signal| -@as(i64, @backingInt(signal)),
        .stopped => |signal| -@as(i64, @backingInt(signal)),
        .unknown => |code| @intCast(code),
    };
}

pub const Args = struct {
    values: std.StringHashMap([]const u8),
    pub fn parse(a: std.mem.Allocator, argv: []const []const u8, options: []const []const u8, flags: []const []const u8) !Args {
        var values = std.StringHashMap([]const u8).init(a);
        var i: usize = 0;
        while (i < argv.len) : (i += 1) {
            const arg = argv[i];
            if (!std.mem.startsWith(u8, arg, "--")) return error.UnknownArgument;
            const split = std.mem.indexOfScalar(u8, arg, '=');
            const name = arg[2 .. split orelse arg.len];
            if (contains(flags, name)) {
                if (split != null) return error.FlagTakesNoValue;
                try values.put(name, "true");
            } else if (contains(options, name)) {
                const value = if (split) |at| arg[at + 1 ..] else blk: {
                    i += 1;
                    if (i == argv.len or std.mem.startsWith(u8, argv[i], "--")) return error.MissingArgumentValue;
                    break :blk argv[i];
                };
                try values.put(name, value);
            } else return error.UnknownArgument;
        }
        return .{ .values = values };
    }
    pub fn get(args: Args, key: []const u8) ?[]const u8 {
        return args.values.get(key);
    }
    pub fn require(args: Args, key: []const u8) ![]const u8 {
        return args.get(key) orelse error.MissingRequiredArgument;
    }
    pub fn flag(args: Args, key: []const u8) bool {
        return args.values.contains(key);
    }
};
pub fn contains(values: []const []const u8, value: []const u8) bool {
    for (values) |item| if (std.mem.eql(u8, item, value)) return true;
    return false;
}

pub const canonical = json.canonicalAlloc;
pub fn big(a: std.mem.Allocator, number: u64) !Value {
    return if (number <= std.math.maxInt(i64)) n(number) else .{ .number_string = try std.fmt.allocPrint(a, "{d}", .{number}) };
}
pub fn toValue(a: std.mem.Allocator, item: anytype) !Value {
    return (try json.parse(a, try std.json.Stringify.valueAlloc(a, item, .{}))).value;
}
