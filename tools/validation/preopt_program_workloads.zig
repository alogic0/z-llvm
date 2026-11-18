//! Fixed-program correctness oracles and the common program build.
const std = @import("std");
const u = @import("common.zig");
const Runner = @import("runner.zig").Runner;
const baseline = @import("baseline.zig");
const owners = @import("native_canaries.zig").owners;
const elf = @import("object_contract.zig");

pub const ids = [_][]const u8{ "arguments_branches", "loops_memory", "nested_calls", "register_pressure", "memset" };
pub const routes = [_][]const u8{ "local-fast", "llvm-O3", "local-small", "llvm-Oz" };
pub const manifest_path = "test/behavioral/performance_manifest.json";
pub const oracle_path = "docs/evidence/composed_byte_loops_performance.json";
const clang = "/usr/lib/llvm-22/bin/clang";
const opt = "/usr/lib/llvm-22/bin/opt";
const readelf = "/usr/bin/readelf";
const objdump = "/usr/lib/llvm-22/bin/llvm-objdump";
const target = "x86_64-unknown-linux-gnu";
const Kind = enum { arguments_branches, loops_memory, nested_calls, register_pressure };

fn scalar(kind: Kind, x: i32, y: i32) i32 {
    return switch (kind) {
        .arguments_branches => if (x < 0) @divTrunc(x, 8) ^ y else @divTrunc(x, 8) + y,
        .loops_memory => blk: {
            var value = x;
            for (0..@intCast(y)) |i| value = (value ^ @as(i32, @intCast(i))) +% 7;
            break :blk value;
        },
        .nested_calls => (@divTrunc(x, 16) ^ y) +% @divTrunc(y, 16),
        .register_pressure => blk: {
            var value = y;
            for (1..13) |i| value ^= x +% @as(i32, @intCast(i));
            break :blk value;
        },
    };
}

const Oracle = struct { semantic: []const u8, runtime: []const u8 };
fn scalarOracle(c: *u.Context, kind: Kind) !Oracle {
    var observations: std.Io.Writer.Allocating = .init(c.a);
    var sum: u64 = 0;
    const edges = [_]i32{ std.math.minInt(i32), -1025, -257, -17, -9, -1, 0, 1, 7, 8, 17, 255, std.math.maxInt(i32) };
    var seed: u32 = 0x5eed1234;
    for (0..272) |index| {
        const edge = index < edges.len * 16;
        if (!edge) seed = seed *% 1664525 +% 1013904223;
        const x: i32 = if (edge) edges[index / 16] else @bitCast(seed);
        const y: i32 = @intCast(if (edge) index % 16 else (seed >> 16) & 15);
        const value = scalar(kind, x, y);
        try observations.writer.print("{d}\n", .{value});
        sum +%= @as(u32, @bitCast(value));
    }
    const digest = try c.fmt("calls=35651584 digest={x}\n", .{sum *% 131072});
    return .{ .semantic = try u.digestBytes(c.a, observations.written()), .runtime = try u.digestBytes(c.a, digest) };
}

pub fn corpus(c: *u.Context) !u.Value {
    if (!std.mem.eql(u8, try c.digest(manifest_path), "f0137fba1d79f2c6ac276e0c32d9ad933f43b8d72bc67cc815a86148de76329a") or
        !std.mem.eql(u8, try c.digest(oracle_path), "a419b629c6c75935c9eefacd3e5650d7fbc494fb86f32f7ebae2e1c7475166db")) return error.FrozenCorpusChanged;
    const manifest = try c.load(manifest_path);
    const hashes = try u.get(manifest, "inputs_sha256");
    for (hashes.object.keys(), hashes.object.values()) |path, expected| {
        if (!u.json.is(expected, try c.digest(path))) return c.fail("corpus input changed: {s}", .{path});
    }
    const reference = try c.load(oracle_path);
    if (!(try u.get(reference, "complete")).bool) return error.IncompleteOracle;
    const workloads = try u.json.array(try u.get(manifest, "workloads"));
    if (workloads.len != ids.len) return error.IncompleteMatrix;
    var rows = u.array(c.a);
    for (workloads, ids) |workload, id| {
        if (!u.json.is(try u.get(workload, "id"), id)) return error.WorkloadOrderChanged;
        var found: ?Oracle = null;
        for (try u.json.array(try u.get(reference, "rows"))) |row| {
            if (!u.json.is(try u.get(row, "route"), "llvm-O3") or !u.json.is(try u.get(row, "workload"), id)) continue;
            if (found != null or !u.json.is(try u.get(row, "status"), "supported")) return error.AmbiguousOracle;
            found = .{ .semantic = try u.str(row, "semantic_stdout_sha256"), .runtime = try u.str(row, "runtime_stdout_sha256") };
        }
        const golden = found orelse return error.MissingOracle;
        if (std.meta.stringToEnum(Kind, id)) |kind| {
            const model = try scalarOracle(c, kind);
            if (!std.mem.eql(u8, model.semantic, golden.semantic) or !std.mem.eql(u8, model.runtime, golden.runtime)) return error.ScalarOracleDisagreement;
        }
        var row = workload;
        try u.put(c.a, &row, "oracle", try u.toValue(c.a, golden));
        try u.add(&rows, row);
    }
    return rows;
}

pub fn verifyProcess(r: *Runner, exe: []const u8, stem: []const u8, expected: []const u8) !Runner.Result {
    const c = r.context;
    const observation = try r.run(&.{exe}, stem, &c.env, .{ .timeout_ms = 30_000 });
    if (!observation.completed or observation.code != 0 or
        (try c.read(try c.fmt("{s}.stderr", .{stem}))).len != 0 or
        !std.mem.eql(u8, expected, try c.digest(try c.fmt("{s}.stdout", .{stem}))))
        return c.fail("outcome or stdout oracle mismatch: {s}", .{stem});
    return observation;
}

fn source(c: *u.Context, workload: u.Value, dest: []const u8) !void {
    const paths = try u.stringSlice(c.a, try u.get(workload, "sources"));
    switch (paths.len) {
        1 => try c.copy(paths[0], dest),
        2 => {
            const additions = try c.read(paths[1]);
            const start = std.mem.indexOf(u8, additions, "define ") orelse return error.NoDefinitions;
            try c.write(dest, try c.fmt("{s}\n{s}", .{ try c.read(paths[0]), additions[start..] }));
        },
        else => return error.InvalidWorkloadSources,
    }
}

pub const Builder = struct {
    runner: *Runner,
    temporary: []const u8,
    compiler: []const u8,
    zig: []const u8,
    drivers: std.StringHashMap([]const u8),

    fn driver(b: *Builder, path: []const u8) ![]const u8 {
        if (b.drivers.get(path)) |obj| return obj;
        const r = b.runner;
        const c = r.context;
        const name = std.fs.path.stem(path);
        const obj = try c.join(&.{ b.temporary, try c.fmt("{s}.o", .{name}) });
        try r.require(&.{ b.zig, "build-obj", path, "-O", "ReleaseFast", "-target", "x86_64-linux-gnu", "-mcpu=baseline", "-fllvm", "-fno-lto", "-fno-PIE", "-fstrip", "-fno-compiler-rt", try c.fmt("-femit-bin={s}", .{obj}) }, try c.join(&.{ r.output, name }), &c.env);
        try b.drivers.put(path, obj);
        return obj;
    }

    pub fn workload(b: *Builder, row: u.Value, rows: *u.Value) !void {
        const r = b.runner;
        const c = r.context;
        const id = try u.str(row, "id");
        const evidence = try c.join(&.{ r.output, id });
        try c.mkdir(evidence);
        const input = try c.join(&.{ evidence, "input.ll" });
        try source(c, row, input);
        try r.require(&.{ opt, "-passes=verify", "-disable-output", input }, try c.join(&.{ evidence, "verify-original" }), &c.env);
        const semantic_driver = try b.driver(try u.str(row, "semantic_driver"));
        const runtime_driver = try b.driver(try u.str(row, "runtime_driver"));
        for (routes, 0..) |route, i| {
            const dir = try c.join(&.{ evidence, route });
            const products = try c.join(&.{ b.temporary, id, route });
            try c.mkdir(dir);
            try c.mkdir(products);
            const obj = try c.join(&.{ products, "program.o" });
            const local = i == 0 or i == 2;
            var optimized_sha: ?[]const u8 = null;
            if (local) {
                const optimized = try c.join(&.{ dir, "optimized.ll" });
                const pass = if (i == 0) "--passes=zig-release-fast-accepted" else "--passes=zig-release-small-accepted";
                try r.requireOutput(&.{ b.compiler, pass, try limit(c, input), input }, try c.join(&.{ dir, "optimize" }), &c.env, optimized);
                optimized_sha = try c.digest(optimized);
                try r.require(&.{ opt, "-passes=verify", "-disable-output", optimized }, try c.join(&.{ dir, "verify-optimized" }), &c.env);
                const owner_file = try c.join(&.{ dir, "owners.tsv" });
                try r.requireOutput(&.{ b.compiler, "--emit=obj", "--generic-cfg-selector", "--codegen-reachable", "--report-all-codegen-failures", "--target=" ++ target, try limit(c, optimized), try c.fmt("--selection-owner-output={s}", .{owner_file}), optimized }, try c.join(&.{ dir, "emit" }), &c.env, obj);
                if (!std.mem.eql(u8, optimized_sha.?, try c.digest(optimized))) return error.OptimizerEmitterBinding;
                try owners(c, try c.read(owner_file), try baseline.definedNames(c.a, try c.read(optimized)));
            } else {
                try r.require(&.{ clang, "-x", "ir", "--target=" ++ target, "-march=x86-64", "-mtune=generic", "-fno-pic", "-fno-pie", "-fno-lto", "-g0", "-Wno-override-module", if (i == 1) "-O3" else "-Oz", "-c", input, "-o", obj }, try c.join(&.{ dir, "clang" }), &c.env);
            }
            try r.require(&.{ objdump, "-dr", "--no-show-raw-insn", obj }, try c.join(&.{ dir, "disassembly" }), &c.env);
            try r.require(&.{ readelf, "-WSs", obj }, try c.join(&.{ dir, "object-sections-symbols" }), &c.env);
            const oracle = try u.get(row, "oracle");
            for ([_][]const u8{ "semantic", "runtime" }, [_][]const u8{ semantic_driver, runtime_driver }) |kind, harness| {
                const exe = try c.join(&.{ products, kind });
                try r.require(&.{ b.zig, "build-exe", harness, obj, "-O", "ReleaseFast", "-target", "x86_64-linux-gnu", "-mcpu=baseline", "-fno-lto", "-fno-PIE", "-static", "-flld", "-fstrip", "-fcompiler-rt", "--build-id=none", "--verbose-link", try c.fmt("-femit-bin={s}", .{exe}) }, try c.join(&.{ dir, try c.fmt("link-{s}", .{kind}) }), &c.env);
                _ = try verifyProcess(r, exe, try c.join(&.{ dir, try c.fmt("check-{s}", .{kind}) }), try u.str(oracle, kind));
                if (std.mem.eql(u8, kind, "semantic") and std.mem.eql(u8, id, "memset")) {
                    for ([_][]const u8{ "checked", "ssp" }) |trap| {
                        const result = try r.run(&.{ exe, trap }, try c.join(&.{ dir, try c.fmt("trap-{s}", .{trap}) }), &c.env, .{});
                        if (result.code != -@as(i64, @backingInt(std.posix.SIG.ILL))) return error.MissingBoundsTrap;
                    }
                }
            }
            const runtime = try c.join(&.{ products, "runtime" });
            const elf_stem = try c.join(&.{ dir, "executable-elf" });
            try r.require(&.{ readelf, "-WhlS", runtime }, elf_stem, &c.env);
            const headers = try c.read(try c.fmt("{s}.stdout", .{elf_stem}));
            if (std.mem.indexOf(u8, headers, "EXEC (Executable file)") == null or std.mem.indexOf(u8, headers, "INTERP") != null or
                std.mem.indexOf(u8, headers, ".debug_info") != null or std.mem.indexOf(u8, headers, ".symtab") != null) return error.UnexpectedLinkedImage;
            try u.add(rows, try u.toValue(c.a, .{
                .workload = id,
                .route = route,
                .input_sha256 = try c.digest(input),
                .optimizer_output_emitter_input_sha256 = optimized_sha,
                .semantic_driver_sha256 = try c.digest(semantic_driver),
                .runtime_driver_sha256 = try c.digest(runtime_driver),
                .oracle = oracle,
                .object_sha256 = try c.digest(obj),
                .object = try elf.sizeBreakdown(c.a, try c.read(obj)),
                .runtime_path = runtime,
                .runtime_sha256 = try c.digest(runtime),
                .executable = try elf.sizeBreakdown(c.a, try c.read(runtime)),
            }));
            try c.writeJson(try c.join(&.{ r.output, "report.json" }), .{ .complete = false, .rows = rows.* });
        }
    }
};

fn limit(c: *u.Context, path: []const u8) ![]const u8 {
    return c.fmt("--input-limit={d}", .{(try std.Io.Dir.cwd().statFile(c.io, path, .{})).size + 1});
}

test "scalar workload models cover signed edges, wrap and empty loop" {
    try std.testing.expectEqual(@as(i32, -2), scalar(.arguments_branches, -9, 1));
    try std.testing.expectEqual(std.math.minInt(i32), scalar(.loops_memory, std.math.minInt(i32), 0));
    try std.testing.expectEqual(@as(i32, 2), scalar(.nested_calls, -15, 2));
    try std.testing.expectEqual(@as(i32, 12), scalar(.register_pressure, 0, 0));
}
