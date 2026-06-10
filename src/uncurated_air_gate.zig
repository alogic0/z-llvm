const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_lowering = @import("zig_air_lowering.zig");
const codegen = @import("codegen.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const options = try parseOptions(init.minimal.args);
    const mode = options.mode;

    const zig_emitter_env = init.minimal.environ.getAlloc(allocator, "ZIG_EMITTER") catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => return err,
    };
    defer if (zig_emitter_env) |value| allocator.free(value);
    const zig_emitter = zig_emitter_env orelse "../ziglang/build/stage4/bin/zig";
    std.Io.Dir.cwd().access(io, zig_emitter, .{ .execute = true }) catch {
        return error.MissingZigAirEmitter;
    };

    const sources = try collectSources(allocator, io, options.corpus);
    defer {
        for (sources) |source| allocator.free(source);
        allocator.free(sources);
    }
    const temp_path = try std.fmt.allocPrint(allocator, "tmp/uncurated_zig_air_{s}_{}", .{ mode.lowerName(), std.os.linux.getpid() });
    defer allocator.free(temp_path);
    try std.Io.Dir.cwd().createDirPath(io, temp_path);
    defer std.Io.Dir.cwd().deleteTree(io, temp_path) catch {};

    var unsupported_counts = std.StringHashMap(usize).init(allocator);
    defer {
        var key_iterator = unsupported_counts.keyIterator();
        while (key_iterator.next()) |key| allocator.free(key.*);
        unsupported_counts.deinit();
    }

    var source_rows: usize = 0;
    var discovered_functions: usize = 0;
    var structured_functions: usize = 0;
    var generic_codegen_functions: usize = 0;
    var unsupported_functions: usize = 0;
    var codegen_failures: usize = 0;
    var first_unsupported_source: ?[]const u8 = null;
    defer if (first_unsupported_source) |value| allocator.free(value);
    var first_unsupported_function: ?[]const u8 = null;
    defer if (first_unsupported_function) |value| allocator.free(value);
    var first_unsupported_opcode: ?[]const u8 = null;
    defer if (first_unsupported_opcode) |value| allocator.free(value);

    for (sources) |source| {
        const stem = std.fs.path.stem(source);
        const descriptor_name = try std.fmt.allocPrint(allocator, "{s}.air", .{stem});
        defer allocator.free(descriptor_name);
        const descriptor_path = try std.fs.path.join(allocator, &.{ temp_path, descriptor_name });
        defer allocator.free(descriptor_path);

        var env_map = try cloneEnvironment(allocator, init.environ_map);
        defer env_map.deinit();
        try env_map.put("ZLLVM_AIR_EXPORT_PATH", descriptor_path);
        const argv = [_][]const u8{
            zig_emitter,
            "build-obj",
            "-fllvm",
            "-flibllvm",
            "-fno-emit-bin",
            mode.zigOptimizeArg(),
            "-target",
            "x86_64-linux-gnu",
            source,
        };
        const emit_result = try std.process.run(allocator, io, .{
            .argv = &argv,
            .environ_map = &env_map,
            .stdout_limit = .limited(16 * 1024 * 1024),
            .stderr_limit = .limited(16 * 1024 * 1024),
        });
        defer {
            allocator.free(emit_result.stdout);
            allocator.free(emit_result.stderr);
        }
        switch (emit_result.term) {
            .exited => |code| if (code != 0) return error.ZigAirExportFailed,
            else => return error.ZigAirExportFailed,
        }

        const descriptor = try std.Io.Dir.cwd().readFileAlloc(
            io,
            descriptor_path,
            allocator,
            .limited(32 * 1024 * 1024),
        );
        defer allocator.free(descriptor);
        source_rows += 1;
        var parsed = air_export.parse(allocator, descriptor) catch |err| {
            unsupported_functions += 1;
            try incrementCount(allocator, &unsupported_counts, "parse");
            std.debug.print(
                "unsupported-air source={s} function=- opcode=parse reason={s}\n",
                .{ source, @errorName(err) },
            );
            if (first_unsupported_source == null) {
                first_unsupported_source = try allocator.dupe(u8, source);
                first_unsupported_function = try allocator.dupe(u8, "-");
                first_unsupported_opcode = try allocator.dupe(u8, "parse");
            }
            continue;
        };
        defer parsed.deinit();
        var lowered = air_lowering.lowerCompatible(allocator, parsed) catch |err| {
            unsupported_functions += 1;
            try incrementCount(allocator, &unsupported_counts, "lowering");
            std.debug.print(
                "unsupported-air source={s} function=- opcode=lowering reason={s}\n",
                .{ source, @errorName(err) },
            );
            if (first_unsupported_source == null) {
                first_unsupported_source = try allocator.dupe(u8, source);
                first_unsupported_function = try allocator.dupe(u8, "-");
                first_unsupported_opcode = try allocator.dupe(u8, "lowering");
            }
            continue;
        };
        defer lowered.deinit();

        discovered_functions += rootFunctionCount(parsed);
        structured_functions += lowered.accepted_functions;
        unsupported_functions += lowered.unsupported.len;
        for (lowered.unsupported) |diagnostic| {
            if (diagnostic.reason == .opcode or diagnostic.reason == .control_flow_shape) {
                try incrementCount(allocator, &unsupported_counts, diagnostic.opcode);
            }
            std.debug.print(
                "unsupported-air source={s} function={s} opcode={s} reason={s}\n",
                .{ source, diagnostic.function, diagnostic.opcode, @tagName(diagnostic.reason) },
            );
            if (first_unsupported_source == null) {
                first_unsupported_source = try allocator.dupe(u8, source);
                first_unsupported_function = try allocator.dupe(u8, diagnostic.function);
                first_unsupported_opcode = try allocator.dupe(u8, diagnostic.opcode);
            }
        }
        for (lowered.module.functions.items) |function| {
            var machine = codegen.x86_64.lowerFunction(
                allocator,
                "x86_64-unknown-linux-gnu",
                function,
            ) catch |err| {
                codegen_failures += 1;
                std.debug.print(
                    "unsupported-codegen source={s} function={s} error={s}\n",
                    .{ source, function.name, @errorName(err) },
                );
                continue;
            };
            machine.deinit(allocator);
            generic_codegen_functions += 1;
        }
    }

    var top_construct: []const u8 = "-";
    var top_count: usize = 0;
    var iterator = unsupported_counts.iterator();
    while (iterator.next()) |entry| {
        if (entry.value_ptr.* > top_count or
            (entry.value_ptr.* == top_count and std.mem.lessThan(u8, entry.key_ptr.*, top_construct)))
        {
            top_construct = entry.key_ptr.*;
            top_count = entry.value_ptr.*;
        }
    }

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print(
        "summary uncurated-zig-air mode={s} target=x86_64-linux-gnu source_rows={} discovered_functions={} structured_functions={} generic_codegen_functions={} unsupported_functions={} codegen_failures={} case_id_rows=0 source_fact_classification_rows=0 first_unsupported_source={s} first_unsupported_function={s} first_unsupported_opcode={s} top_unsupported_construct={s} top_unsupported_count={} local_fail=0\n",
        .{
            mode.name(),
            source_rows,
            discovered_functions,
            structured_functions,
            generic_codegen_functions,
            unsupported_functions,
            codegen_failures,
            first_unsupported_source orelse "-",
            first_unsupported_function orelse "-",
            first_unsupported_opcode orelse "-",
            top_construct,
            top_count,
        },
    );
    try stdout_writer.interface.flush();
}

fn rootFunctionCount(module: air_export.Module) usize {
    const root_stem = std.fs.path.stem(module.root_source);
    var count: usize = 0;
    for (module.functions) |function| {
        if (air_lowering.isRootSourceFunction(root_stem, function.name)) count += 1;
    }
    return count;
}

const Options = struct {
    mode: Mode = .ReleaseFast,
    corpus: Corpus = .inputs,
};

const Mode = enum {
    ReleaseFast,
    ReleaseSafe,

    fn name(self: Mode) []const u8 {
        return switch (self) {
            .ReleaseFast => "ReleaseFast",
            .ReleaseSafe => "ReleaseSafe",
        };
    }

    fn lowerName(self: Mode) []const u8 {
        return switch (self) {
            .ReleaseFast => "releasefast",
            .ReleaseSafe => "releasesafe",
        };
    }

    fn zigOptimizeArg(self: Mode) []const u8 {
        return switch (self) {
            .ReleaseFast => "-OReleaseFast",
            .ReleaseSafe => "-OReleaseSafe",
        };
    }
};

const Corpus = enum {
    inputs,
    broad,
};

fn parseOptions(args: std.process.Args) !Options {
    var options: Options = .{};
    var iterator = std.process.Args.Iterator.init(args);
    _ = iterator.skip();
    while (iterator.next()) |arg| {
        if (std.mem.eql(u8, arg, "--mode=ReleaseFast")) {
            options.mode = .ReleaseFast;
        } else if (std.mem.eql(u8, arg, "--mode=ReleaseSafe")) {
            options.mode = .ReleaseSafe;
        } else if (std.mem.eql(u8, arg, "--corpus=inputs")) {
            options.corpus = .inputs;
        } else if (std.mem.eql(u8, arg, "--corpus=broad")) {
            options.corpus = .broad;
        } else {
            return error.UnsupportedUncuratedAirArgument;
        }
    }
    return options;
}

fn collectSources(allocator: std.mem.Allocator, io: std.Io, corpus: Corpus) ![][]const u8 {
    var sources: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (sources.items) |source| allocator.free(source);
        sources.deinit(allocator);
    }
    try collectSourcesFromRoot(allocator, io, &sources, "test/zig/inputs");
    if (corpus == .broad) {
        try collectSourcesFromRoot(allocator, io, &sources, "test/zig/integrated");
    }
    std.mem.sort([]const u8, sources.items, {}, struct {
        fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
            return std.mem.lessThan(u8, lhs, rhs);
        }
    }.lessThan);
    return sources.toOwnedSlice(allocator);
}

fn collectSourcesFromRoot(
    allocator: std.mem.Allocator,
    io: std.Io,
    sources: *std.ArrayList([]const u8),
    root: []const u8,
) !void {
    var dir = try std.Io.Dir.cwd().openDir(io, root, .{ .iterate = true });
    defer dir.close(io);
    var iterator = dir.iterate();
    while (try iterator.next(io)) |entry| {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.name, ".zig")) continue;
        try sources.append(allocator, try std.fs.path.join(allocator, &.{ root, entry.name }));
    }
}

fn incrementCount(
    allocator: std.mem.Allocator,
    counts: *std.StringHashMap(usize),
    key: []const u8,
) !void {
    const entry = try counts.getOrPut(key);
    if (entry.found_existing) {
        entry.value_ptr.* += 1;
    } else {
        entry.key_ptr.* = try allocator.dupe(u8, key);
        entry.value_ptr.* = 1;
    }
}

fn cloneEnvironment(
    allocator: std.mem.Allocator,
    source: *const std.process.Environ.Map,
) !std.process.Environ.Map {
    var result = std.process.Environ.Map.init(allocator);
    errdefer result.deinit();
    for (source.keys(), source.values()) |key, value| try result.put(key, value);
    return result;
}
