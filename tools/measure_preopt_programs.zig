//! Prepare and time the frozen Fast/Small generated-program comparisons.
const std = @import("std");
const u = @import("validation/common.zig");
const Runner = @import("validation/runner.zig").Runner;
const workloads = @import("validation/preopt_program_workloads.zig");
const stats = @import("validation/baseline.zig").stats;

const warmups = 2;
const samples = 12;
const cpu = 2;
const orders = [4][4]usize{ .{ 0, 1, 3, 2 }, .{ 1, 2, 0, 3 }, .{ 2, 3, 1, 0 }, .{ 3, 0, 2, 1 } };

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    if (argv.len < 2 or u.contains(argv[1..], "--help"))
        return c.print("usage: tools/run-validation ... measure_preopt_programs oracles | prepare --compiler EXE --zig EXE | sample --prepared REPORT\n", .{});
    run(&c, argv) catch |err| {
        try c.print("generated-program measurement failed: {s}\n", .{c.diagnostic orelse @errorName(err)});
        std.process.exit(1);
    };
}

fn run(c: *u.Context, argv: []const []const u8) !void {
    const evidence = c.env.get("ZLLVM_RUN_ROOT") orelse return error.ManagedRunRequired;
    const temporary = c.env.get("ZLLVM_TEMP_ROOT") orelse return error.ManagedRunRequired;
    const args = try u.Args.parse(c.a, argv[2..], &.{ "compiler", "zig", "prepared" }, &.{});
    var runner = Runner.init(c, evidence);
    const corpus = try workloads.corpus(c);
    if (std.mem.eql(u8, argv[1], "oracles")) return c.writeJson(try c.join(&.{ evidence, "oracles.json" }), corpus);
    if (std.mem.eql(u8, argv[1], "sample")) return sample(&runner, try args.require("prepared"), corpus);
    if (!std.mem.eql(u8, argv[1], "prepare")) return error.UnknownMeasurementStage;
    var builder = workloads.Builder{
        .runner = &runner,
        .temporary = temporary,
        .compiler = try c.join(&.{try args.require("compiler")}),
        .zig = try args.require("zig"),
        .drivers = std.StringHashMap([]const u8).init(c.a),
    };
    var rows = u.array(c.a);
    for (try u.json.array(corpus)) |workload| try builder.workload(workload, &rows);
    try c.writeJson(try c.join(&.{ evidence, "report.json" }), .{ .complete = true, .rows = rows, .common_driver_objects = builder.drivers.count() });
}

fn pinCpu() !void {
    const linux = std.os.linux;
    var mask: linux.cpu_set_t = undefined;
    if (linux.errno(linux.sched_getaffinity(0, @sizeOf(linux.cpu_set_t), &mask)) != .SUCCESS) return error.AffinityUnavailable;
    if ((mask[0] & (1 << cpu)) == 0) return error.CpuOutsideAffinity;
    @memset(&mask, 0);
    mask[0] = 1 << cpu;
    try linux.sched_setaffinity(0, &mask);
}

fn verifyImages(c: *u.Context, rows: []const u.Value, corpus: u.Value) !void {
    if (rows.len != workloads.ids.len * workloads.routes.len) return error.IncompleteMatrix;
    for (rows, 0..) |row, i| {
        const workload = corpus.array.items[i / workloads.routes.len];
        if (!u.json.eql(try u.get(row, "workload"), try u.get(workload, "id")) or
            !u.json.is(try u.get(row, "route"), workloads.routes[i % workloads.routes.len]) or
            !u.json.eql(try u.get(row, "oracle"), try u.get(workload, "oracle")) or
            !u.json.is(try u.get(row, "runtime_sha256"), try c.digest(try u.str(row, "runtime_path")))) return error.PreparedImageChanged;
        const first = rows[i - i % workloads.routes.len];
        for ([_][]const u8{ "input_sha256", "semantic_driver_sha256", "runtime_driver_sha256" }) |key| {
            if (!u.json.eql(try u.get(first, key), try u.get(row, key))) return error.UnmatchedComparisonInput;
        }
    }
}

fn sample(r: *Runner, prepared: []const u8, corpus: u.Value) !void {
    const c = r.context;
    const path = try c.join(&.{ r.output, "report.json" });
    const sha = try c.digest(prepared);
    const build = try c.load(prepared);
    if (try u.json.integer(try u.get(build, "common_driver_objects")) != 4 or !(try u.get(build, "complete")).bool) return error.IncompletePreparation;
    const rows = try u.json.array(try u.get(build, "rows"));
    try verifyImages(c, rows, corpus);
    try pinCpu();
    const affinity = try c.capture(&.{ "/usr/bin/taskset", "-pc", "0" });
    try c.write(try c.join(&.{ r.output, "observed-affinity.txt" }), affinity);
    var observations = u.array(c.a);
    var durations: [workloads.ids.len][workloads.routes.len][samples]f64 = undefined;
    for (0..warmups + samples) |block| {
        const warming = block < warmups;
        const round = if (warming) block else block - warmups;
        for (0..workloads.ids.len) |position| {
            const w = (block + position) % workloads.ids.len;
            for (orders[(round + w) % orders.len], 0..) |route, order| {
                const row = rows[w * workloads.routes.len + route];
                const stem = try c.join(&.{ r.output, try c.fmt("{s}-{d:0>2}-{s}-{s}", .{ if (warming) "warmup" else "sample", round + 1, workloads.ids[w], workloads.routes[route] }) });
                const result = try workloads.verifyProcess(r, try u.str(row, "runtime_path"), stem, try u.str(try u.get(row, "oracle"), "runtime"));
                try u.add(&observations, try u.toValue(c.a, .{ .warmup = warming, .round = round + 1, .workload_position = position + 1, .route_position = order + 1, .workload = workloads.ids[w], .route = workloads.routes[route], .wall_ns = result.wall_ns, .actual_exit = result.code }));
                if (!warming) durations[w][route][round] = @floatFromInt(result.wall_ns);
            }
        }
        try c.writeJson(path, .{ .complete = false, .observations = observations });
    }
    try verifyImages(c, rows, corpus);
    if (!std.mem.eql(u8, sha, try c.digest(prepared))) return error.PreparationChanged;
    var results = u.array(c.a);
    var pairs = u.array(c.a);
    for (workloads.ids, 0..) |id, w| {
        for (workloads.routes, 0..) |route, index| {
            const row = rows[w * workloads.routes.len + index];
            try u.add(&results, try u.toValue(c.a, .{
                .workload = id,
                .route = route,
                .runtime_ns = try stats(c.a, &durations[w][index]),
                .object = try u.get(row, "object"),
                .executable = try u.get(row, "executable"),
                .runtime_sha256 = try u.str(row, "runtime_sha256"),
            }));
        }
        for ([_]usize{ 0, 2 }) |local| {
            var ratios: [samples]f64 = undefined;
            for (&ratios, durations[w][local], durations[w][local + 1]) |*ratio, l, reference| ratio.* = l / reference;
            try u.add(&pairs, try u.toValue(c.a, .{ .workload = id, .local = workloads.routes[local], .llvm = workloads.routes[local + 1], .paired_wall_ratio = try stats(c.a, &ratios) }));
        }
    }
    try c.writeJson(path, .{ .schema = 1, .complete = true, .prepared_sha256 = sha, .cpu = cpu, .warmup_blocks = warmups, .measured_blocks = samples, .observations = observations, .rows = results, .comparisons = pairs });
}

test "balanced orders visit every position and ordered pair equally" {
    var positions: [4][4]usize = @splat(@splat(0));
    var follows: [4][4]usize = @splat(@splat(0));
    for (orders) |order| {
        for (order, 0..) |route, i| {
            positions[route][i] += 1;
            if (i > 0) follows[order[i - 1]][route] += 1;
        }
    }
    for (0..4) |a| for (0..4) |b| {
        try std.testing.expectEqual(@as(usize, 1), positions[a][b]);
        try std.testing.expectEqual(@as(usize, @intFromBool(a != b)), follows[a][b]);
    };
}

test {
    _ = workloads;
}
