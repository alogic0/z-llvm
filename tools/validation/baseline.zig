//! Non-gating frozen workload measurements. zig-process owns every child/reap.
const std = @import("std");
const u = @import("common.zig");
const Runner = @import("runner.zig").Runner;
const elf = @import("object_contract.zig");
const canaries = @import("native_canaries.zig");
const provenance = @import("provenance.zig");
const routes = [_][]const u8{ "direct", "release-o3", "llvm-O3" };
const warmups = 2;
const samples = 9;
const Stage = struct { name: []const u8, argv: []const []const u8, output: ?[]const u8 = null };
const Prepared = struct { directory: []const u8, object: []const u8, input: []const u8, stages: []const Stage, row: usize };
pub const Stats = struct { median: f64, min: f64, max: f64, mad: f64 };

fn median(sorted: []const f64) f64 {
    const mid = sorted.len / 2;
    return if (sorted.len % 2 != 0) sorted[mid] else (sorted[mid - 1] + sorted[mid]) / 2;
}
pub fn stats(a: std.mem.Allocator, values: []const f64) !Stats {
    if (values.len == 0) return error.EmptySamples;
    const sorted = try a.dupe(f64, values);
    defer a.free(sorted);
    std.mem.sort(f64, sorted, {}, std.sort.asc(f64));
    const mid = median(sorted);
    const deviations = try a.alloc(f64, values.len);
    defer a.free(deviations);
    for (sorted, deviations) |v, *d| d.* = @abs(v - mid);
    std.mem.sort(f64, deviations, {}, std.sort.asc(f64));
    return .{ .median = mid, .min = sorted[0], .max = sorted[sorted.len - 1], .mad = median(deviations) };
}
fn run(r: *Runner, argv: []const []const u8, stem: []const u8, output: ?[]const u8, check: bool) !Runner.Result {
    const result = try r.run(argv, stem, &r.context.env, .{ .stdout_file = output });
    if (check and result.code != 0) return r.context.fail("command failed ({d}): {s}; see {s}.stderr", .{ result.code, argv[0], stem });
    return result;
}
fn checkHashes(c: *u.Context, hashes: u.Value) !void {
    if (hashes != .object) return error.InvalidInputHashes;
    for (hashes.object.keys(), hashes.object.values()) |path, hash| if (!u.json.is(hash, try c.digest(try c.join(&.{path})))) return c.fail("frozen input changed: {s}", .{path});
}
pub fn definedNames(a: std.mem.Allocator, text: []const u8) ![]const []const u8 {
    var names = std.StringHashMap(void).init(a);
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line| {
        if (line.len < 7 or !std.mem.startsWith(u8, line, "define") or !std.ascii.isWhitespace(line[6])) continue;
        const at = std.mem.indexOfScalar(u8, line, '@') orelse return error.InvalidDefinition;
        const tail = line[at + 1 ..];
        if (tail.len == 0) return error.InvalidDefinition;
        const quoted = tail[0] == '"';
        const end = std.mem.indexOfScalarPos(u8, tail, @intFromBool(quoted), if (quoted) '"' else '(') orelse return error.InvalidDefinition;
        try names.put(tail[@intFromBool(quoted)..end], {});
    }
    if (names.count() == 0) return error.NoDefinitions;
    const result = try a.alloc([]const u8, names.count());
    var iterator = names.keyIterator();
    var i: usize = 0;
    while (iterator.next()) |name| : (i += 1) result[i] = name.*;
    return result;
}
fn unsupported(c: *u.Context, frozen: u.Value, case: []const u8, route: []const u8, stage: []const u8, result: Runner.Result, stem: []const u8, row: *u.Value) !bool {
    if (result.code == 0) return false;
    const diagnostic = try c.read(try c.fmt("{s}.stderr", .{stem}));
    const key = try c.fmt("{s}/{s}", .{ case, route });
    const expected = (try u.get(frozen, "unsupported")).object.get(key) orelse return c.fail("unexpected {s} failure: {s}", .{ stage, key });
    if (!u.json.eql(expected, try u.toValue(c.a, .{ .stage = stage, .returncode = result.code, .stderr = diagnostic }))) return error.UnsupportedDiagnosticChanged;
    try u.put(c.a, row, "status", u.s("unsupported"));
    try u.put(c.a, row, "stage", u.s(stage));
    try u.put(c.a, row, "diagnostic", u.s(diagnostic));
    return true;
}
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    if (u.contains(argv[1..], "--help")) {
        try c.print("usage: zig run tools/fixed_program_baseline.zig -- --compiler EXE --zig EXE --output NEW_DIR --cpu ALLOWED_LOGICAL_CPU\n", .{});
        return;
    }
    const args = try u.Args.parse(c.a, argv[1..], &.{ "compiler", "zig", "output", "cpu" }, &.{});
    measure(&c, args, argv) catch |err| {
        try c.print("baseline failed: {s}\n", .{c.diagnostic orelse @errorName(err)});
        std.process.exit(1);
    };
}
fn measure(c: *u.Context, args: u.Args, invocation: []const []const u8) !void {
    const linux = std.os.linux;
    const cpu = try std.fmt.parseUnsigned(usize, try args.require("cpu"), 10);
    var affinity: linux.cpu_set_t = undefined;
    if (linux.errno(linux.sched_getaffinity(0, @sizeOf(linux.cpu_set_t), &affinity)) != .SUCCESS) return error.CpuAffinityUnavailable;
    const word = cpu / @bitSizeOf(usize);
    const bit = @as(usize, 1) << @as(std.math.Log2Int(usize), @intCast(cpu % @bitSizeOf(usize)));
    if (word >= affinity.len or affinity[word] & bit == 0) return error.CpuOutsideProcessAffinity;
    @memset(&affinity, 0);
    affinity[word] = bit;
    try linux.sched_setaffinity(0, &affinity);
    const output = try c.newOutput(try args.require("output"));
    var runner = Runner.init(c, output);
    var tools = std.StringHashMap([]const u8).init(c.a);
    try tools.put("z_llvm", try std.Io.Dir.cwd().realPathFileAlloc(c.io, try c.join(&.{try args.require("compiler")}), c.a));
    try tools.put("zig", try std.Io.Dir.cwd().realPathFileAlloc(c.io, try c.join(&.{try args.require("zig")}), c.a));
    for ([_][]const u8{ "clang-22", "opt-22", "readelf" }) |name| try tools.put(name, try std.Io.Dir.cwd().realPathFileAlloc(c.io, u.trim(try c.capture(&.{ "which", name })), c.a));
    var versions = std.StringHashMap([]const u8).init(c.a);
    for ([_][]const u8{ "zig", "clang-22", "opt-22", "readelf" }) |name| {
        const stem = try c.join(&.{ output, try c.fmt("{s}-version", .{name}) });
        _ = try run(&runner, &.{ tools.get(name).?, if (std.mem.eql(u8, name, "zig")) "version" else "--version" }, stem, null, true);
        try versions.put(name, u.trim(try c.read(try c.fmt("{s}.stdout", .{stem}))));
    }
    if (!std.mem.eql(u8, versions.get("zig").?, "0.17.0")) return error.Zig017Required;
    const manifest_path = try c.join(&.{"test/behavioral/performance_manifest.json"});
    const frozen = try c.load(manifest_path);
    try checkHashes(c, try u.get(frozen, "inputs_sha256"));
    const source_state = try provenance.files(c, &.{ "src", "build.zig", ".zigversion" });
    const procedure = try provenance.tools(c);
    const manifest_hash = try c.digest(manifest_path);
    var tool_records = u.object(c.a);
    var iterator = tools.iterator();
    while (iterator.next()) |tool| try u.put(c.a, &tool_records, tool.key_ptr.*, try u.toValue(c.a, .{ .path = tool.value_ptr.*, .sha256 = try c.digest(tool.value_ptr.*), .version = versions.get(tool.key_ptr.*) }));
    var frequency = u.object(c.a);
    for ([_][]const u8{ "scaling_governor", "scaling_driver", "scaling_min_freq", "scaling_max_freq" }) |name| {
        const path = try c.fmt("/sys/devices/system/cpu/cpu{d}/cpufreq/{s}", .{ cpu, name });
        if (u.exists(c.io, path)) try u.put(c.a, &frequency, name, u.s(u.trim(try c.read(path))));
    }
    const metadata = try u.toValue(c.a, .{
        .schema = 1,
        .started_utc = u.trim(try c.capture(&.{ "date", "-u", "+%Y-%m-%dT%H:%M:%SZ" })),
        .invocation = invocation,
        .cwd = c.root,
        .git_head = u.trim(try c.capture(&.{ "git", "rev-parse", "HEAD" })),
        .git_status = try c.capture(&.{ "git", "status", "--short" }),
        .source_sha256 = source_state,
        .frozen_manifest = frozen,
        .runner_sha256 = try c.digest(try c.join(&.{"tools/validation/baseline.zig"})),
        .tool_provenance = procedure,
        .manifest_sha256 = manifest_hash,
        .tools = tool_records,
        .compiler_build = "zig 0.17.0 build -Doptimize=ReleaseFast --prefix OUTPUT/compiler (outside measurement)",
        .platform = u.trim(try c.capture(&.{ "uname", "-a" })),
        .cpu_affinity = [_]usize{cpu},
        .cpuinfo = try c.read("/proc/cpuinfo"),
        .frequency_policy = frequency,
        .warmups = warmups,
        .samples = samples,
        .target = "x86_64-unknown-linux-gnu",
        .harness = "ReleaseFast x86_64-linux-gnu baseline CPU, no LTO",
        .cache = "warm OS page cache; no cache flush; fresh compiler processes; no compiler result cache",
        .timing = "Zig awake nanosecond clock; zig-process readiness waits and owned reap under one launch/execution deadline; IR-to-object excludes build/link/verify/hash; runtime includes process startup and driver",
        .measurement_engine = "zig-process-0.6.1-readiness-v2",
        .cross_engine_speedup_claim = false,
    });
    try c.writeJson(try c.join(&.{ output, "metadata.json" }), metadata);
    var rows = u.array(c.a);
    // Even a failed first workload has a readable incomplete result.
    const results_path = try c.join(&.{ output, "results.json" });
    try c.writeJson(results_path, .{ .schema = 1, .complete = false, .rows = rows });
    errdefer c.writeJson(results_path, .{ .schema = 1, .complete = false, .rows = rows, .error_message = c.diagnostic orelse "measurement failed; inspect commands.json" }) catch {};
    for (try u.json.array(try u.get(frozen, "workloads"))) |workload| {
        const case = try u.str(workload, "id");
        const case_dir = try c.join(&.{ output, case });
        try c.mkdir(case_dir);
        const original = try c.join(&.{ case_dir, "input.ll" });
        const sources = try u.stringSlice(c.a, try u.get(workload, "sources"));
        if (sources.len < 1 or sources.len > 2) return error.InvalidWorkloadSources;
        var source: []const u8 = try c.read(try c.join(&.{sources[0]}));
        if (sources.len == 2) {
            const second = try c.read(try c.join(&.{sources[1]}));
            source = try c.fmt("{s}\n{s}", .{ source, second[std.mem.indexOf(u8, second, "define ") orelse return error.NoDefinitions ..] });
        }
        try c.write(original, source);
        _ = try run(&runner, &.{ tools.get("opt-22").?, "-passes=verify", "-disable-output", original }, try c.join(&.{ case_dir, "verify-original" }), null, true);
        var prepared: [3]?Prepared = .{ null, null, null };
        for ([_]usize{ 2, 0, 1 }) |route_index| {
            const route = routes[route_index];
            const directory = try c.join(&.{ case_dir, route });
            try c.mkdir(directory);
            const obj = try c.join(&.{ directory, "program.o" });
            try u.add(&rows, try u.toValue(c.a, .{ .workload = case, .route = route, .input_sha256 = try c.digest(original), .status = "supported", .compile_samples = u.array(c.a), .runtime_ns = u.array(c.a) }));
            const row_index = rows.array.items.len - 1;
            const row = &rows.array.items[row_index];
            var input = original;
            var stages: std.ArrayList(Stage) = .empty;
            if (route_index == 1) {
                input = try c.join(&.{ directory, "optimized.ll" });
                const command = try c.a.dupe([]const u8, &.{ tools.get("z_llvm").?, "--passes=release-o3", original });
                try stages.append(c.a, .{ .name = "optimizer", .argv = command, .output = input });
                const stem = try c.join(&.{ directory, "prepare-optimizer" });
                if (try unsupported(c, frozen, case, route, "optimizer", try run(&runner, command, stem, input, false), stem, row)) continue;
                _ = try run(&runner, &.{ tools.get("opt-22").?, "-passes=verify", "-disable-output", input }, try c.join(&.{ directory, "verify-optimized" }), null, true);
            }
            const base = [_][]const u8{ tools.get("z_llvm").?, "--target=x86_64-unknown-linux-gnu", "--generic-cfg-selector" };
            const command = if (route_index == 2) try c.a.dupe([]const u8, &.{ tools.get("clang-22").?, "--target=x86_64-unknown-linux-gnu", "-march=x86-64", "-Wno-override-module", "-O3", "-c", original, "-o", obj }) else try std.mem.concat(c.a, []const u8, &.{ &base, &.{ "--emit=obj", input } });
            const object_output: ?[]const u8 = if (route_index == 2) null else obj;
            try stages.append(c.a, .{ .name = "codegen", .argv = command, .output = object_output });
            const stem = try c.join(&.{ directory, "prepare-codegen" });
            if (try unsupported(c, frozen, case, route, "codegen", try run(&runner, command, stem, object_output, false), stem, row)) continue;
            if ((try u.get(frozen, "unsupported")).object.contains(try c.fmt("{s}/{s}", .{ case, route }))) return error.SupportChangedReviseProtocol;
            if (route_index != 2) {
                const owner_path = try c.join(&.{ directory, "owners.tsv" });
                _ = try run(&runner, try std.mem.concat(c.a, []const u8, &.{ &base, &.{ "--emit=selection-owner-manifest", input } }), try c.join(&.{ directory, "ownership" }), owner_path, true);
                const owner_text = try c.read(owner_path);
                try canaries.owners(c, owner_text, try definedNames(c.a, try c.read(input)));
                var ownership = u.object(c.a);
                var lines = std.mem.tokenizeScalar(u8, owner_text, '\n');
                _ = lines.next();
                while (lines.next()) |line| {
                    const tab = std.mem.indexOfScalar(u8, line, '\t').?;
                    try u.put(c.a, &ownership, line[0..tab], u.s(line[tab + 1 ..]));
                }
                try u.put(c.a, row, "ownership", ownership);
            }
            try u.put(c.a, row, "object_sha256", u.s(try c.digest(obj)));
            try u.put(c.a, row, "object_bytes", u.n((try std.Io.Dir.cwd().statFile(c.io, obj, .{})).size));
            try u.put(c.a, row, "executable_section_bytes", u.n(try elf.executableBytes(c.a, try c.read(obj))));
            _ = try run(&runner, &.{ tools.get("readelf").?, "-SW", obj }, try c.join(&.{ directory, "sections" }), null, true);
            _ = try run(&runner, &.{ tools.get("readelf").?, "-Ws", obj }, try c.join(&.{ directory, "symbols" }), null, true);
            var undefined_symbols = u.array(c.a);
            var symbol_lines = std.mem.tokenizeScalar(u8, try c.read(try c.join(&.{ directory, "symbols.stdout" })), '\n');
            while (symbol_lines.next()) |line| {
                if (std.mem.indexOf(u8, line, " UND ") == null) continue;
                var words = std.mem.tokenizeAny(u8, line, " \t");
                var count: usize = 0;
                var last: []const u8 = "";
                while (words.next()) |word_text| {
                    count += 1;
                    last = word_text;
                }
                if (count == 8) try u.add(&undefined_symbols, u.s(last));
            }
            try u.put(c.a, row, "undefined_symbols", undefined_symbols);
            for ([_][]const u8{ "semantic", "runtime" }, [_][]const u8{ "semantic_driver", "runtime_driver" }) |kind, driver_key| {
                const exe = try c.join(&.{ directory, kind });
                _ = try run(&runner, &.{ tools.get("zig").?, "build-exe", try u.str(workload, driver_key), obj, "-O", "ReleaseFast", "-target", "x86_64-linux-gnu", "-mcpu=baseline", try c.fmt("-femit-bin={s}", .{exe}) }, try c.join(&.{ directory, try c.fmt("link-{s}", .{kind}) }), null, true);
                const check = try c.join(&.{ directory, try c.fmt("check-{s}", .{kind}) });
                _ = try run(&runner, &.{exe}, check, null, true);
                const actual = try c.read(try c.fmt("{s}.stdout", .{check}));
                if ((try c.read(try c.fmt("{s}.stderr", .{check}))).len != 0) return error.UnexpectedDriverStderr;
                if (route_index != 2 and !std.mem.eql(u8, actual, try c.read(try c.join(&.{ case_dir, "llvm-O3", try c.fmt("check-{s}.stdout", .{kind}) })))) return error.DriverSemanticMismatch;
                if (std.mem.eql(u8, kind, "semantic")) {
                    if (std.mem.eql(u8, case, "memset")) {
                        if (!std.mem.startsWith(u8, actual, "memset observations=1442 ")) return error.MissingMemsetObservations;
                        for ([_][]const u8{ "checked", "ssp" }) |trap| if ((try run(&runner, &.{ exe, trap }, try c.join(&.{ directory, try c.fmt("trap-{s}", .{trap}) }), null, false)).code != -@as(i64, @backingInt(std.posix.SIG.ILL))) return error.MissingBoundsTrap;
                    } else {
                        var line_count = std.mem.count(u8, actual, "\n");
                        if (actual.len > 0 and actual[actual.len - 1] != '\n') line_count += 1;
                        if (line_count != 272) return error.MissingScalarObservations;
                    }
                }
                try u.put(c.a, row, try c.fmt("{s}_stdout_sha256", .{kind}), u.s(try u.digestBytes(c.a, actual)));
            }
            const runtime_exe = try c.join(&.{ directory, "runtime" });
            try u.put(c.a, row, "runtime_executable_sha256", u.s(try c.digest(runtime_exe)));
            try u.put(c.a, row, "linked_harness_bytes", u.n((try std.Io.Dir.cwd().statFile(c.io, runtime_exe, .{})).size));
            try u.put(c.a, row, "stage_input_sha256", u.s(try c.digest(input)));
            prepared[route_index] = .{ .directory = directory, .object = obj, .input = input, .stages = try stages.toOwnedSlice(c.a), .row = row_index };
        }
        var sample: i32 = -warmups;
        while (sample < samples) : (sample += 1) {
            const rotation: usize = @intCast(@mod(sample, 3));
            for (0..3) |order| {
                const item = prepared[(rotation + order) % 3] orelse continue;
                const row = &rows.array.items[item.row];
                var durations = u.object(c.a);
                var total: i128 = 0;
                for (item.stages) |stage| {
                    const result = try run(&runner, stage.argv, try c.join(&.{ item.directory, try c.fmt("compile-{d}-{s}", .{ sample, stage.name }) }), stage.output, true);
                    try u.put(c.a, &durations, try c.fmt("{s}_ns", .{stage.name}), u.n(result.wall_ns));
                    total += result.wall_ns;
                }
                if (!u.json.is(try u.get(row.*, "object_sha256"), try c.digest(item.object)) or !u.json.is(try u.get(row.*, "stage_input_sha256"), try c.digest(item.input))) return error.NondeterministicCompilation;
                try u.put(c.a, &durations, "total_ns", u.n(total));
                if (sample >= 0) try u.add(row.object.getPtr("compile_samples").?, durations);
            }
            for (0..3) |order| {
                const item = prepared[(rotation + order) % 3] orelse continue;
                const row = &rows.array.items[item.row];
                const stem = try c.join(&.{ item.directory, try c.fmt("runtime-{d}", .{sample}) });
                const result = try run(&runner, &.{try c.join(&.{ item.directory, "runtime" })}, stem, null, true);
                if (!u.json.is(try u.get(row.*, "runtime_stdout_sha256"), try c.digest(try c.fmt("{s}.stdout", .{stem}))) or (try c.read(try c.fmt("{s}.stderr", .{stem}))).len != 0) return error.RuntimeSampleSemanticMismatch;
                if (sample >= 0) try u.add(row.object.getPtr("runtime_ns").?, u.n(result.wall_ns));
            }
        }
        for (prepared, routes) |maybe_item, route| {
            const item = maybe_item orelse continue;
            const row = &rows.array.items[item.row];
            const compile_samples = try u.json.array(try u.get(row.*, "compile_samples"));
            var compile_stats = u.object(c.a);
            for (compile_samples[0].object.keys()) |key| {
                const values = try c.a.alloc(f64, compile_samples.len);
                for (compile_samples, values) |observation, *v| v.* = @floatFromInt(try u.json.integer(try u.get(observation, key)));
                try u.put(c.a, &compile_stats, key, try u.toValue(c.a, try stats(c.a, values)));
            }
            try u.put(c.a, row, "compile_stats_ns", compile_stats);
            const runtime_values = try u.json.array(try u.get(row.*, "runtime_ns"));
            const values = try c.a.alloc(f64, runtime_values.len);
            for (runtime_values, values) |v, *dest| dest.* = @floatFromInt(try u.json.integer(v));
            const runtime_stats = try stats(c.a, values);
            try u.put(c.a, row, "runtime_stats_ns", try u.toValue(c.a, runtime_stats));
            try c.print("{s} {s}: runtime={d:.3}ms object={d} code={d}\n", .{ case, route, runtime_stats.median / 1e6, (try u.get(row.*, "object_bytes")).integer, (try u.get(row.*, "executable_section_bytes")).integer });
        }
        try c.writeJson(results_path, .{ .schema = 1, .complete = false, .rows = rows });
    }
    if (!u.json.eql(source_state, try provenance.files(c, &.{ "src", "build.zig", ".zigversion" }))) return error.SourceChangedDuringMeasurement;
    try checkHashes(c, try u.get(frozen, "inputs_sha256"));
    try provenance.verifyTools(c, procedure);
    if (!std.mem.eql(u8, manifest_hash, try c.digest(manifest_path))) return error.MeasurementProcedureChanged;
    iterator = tools.iterator();
    while (iterator.next()) |tool| if (!u.json.is(try u.get(try u.get(tool_records, tool.key_ptr.*), "sha256"), try c.digest(tool.value_ptr.*))) return error.CompilerToolChanged;
    try c.writeJson(results_path, .{ .schema = 1, .complete = true, .rows = rows });
}
