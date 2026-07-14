const std = @import("std");
const common = @import("tool_common.zig");

const Tool = struct {
    id: []const u8,
    path: []const u8,
    args: []const []const u8 = &.{},
    cache_contract: CacheContract = .unreported,
};

const CacheContract = enum {
    unreported,
    air_export_v1,
};

const CacheStatus = enum {
    none,
    hit,
    miss,
    mixed,
};

const Measurement = struct {
    tool_index: usize,
    duration_ms: i96,
    cache_status: CacheStatus,
};

const CompletedTool = struct {
    result: std.process.RunResult,
    duration_ms: i96,
};

const tools = [_]Tool{
    .{ .id = "selected-object-suite", .path = "tools/run_distribution_no_llvm_codegen_subset.zig" },
    .{ .id = "selected-object-inspection", .path = "tools/run_native_link_object_inspection.zig" },
    .{ .id = "selected-native-link", .path = "tools/run_distribution_native_link_m5.zig" },
    .{ .id = "selected-native-probe", .path = "tools/probe_native_linker_compatibility.zig" },
    .{ .id = "zig-source-native-link", .path = "tools/run_distribution_zig_source_native_link.zig" },
    .{ .id = "integrated-object-postopt", .path = "tools/run_distribution_zig_integrated_object.zig" },
    .{ .id = "integrated-object-preopt", .path = "tools/run_distribution_zig_integrated_object.zig", .args = &.{"--pipeline=preopt"} },
    .{ .id = "integrated-object-ir-writer", .path = "tools/run_distribution_zig_integrated_object.zig", .args = &.{"--ir-writer"} },
    .{ .id = "integrated-object-release", .path = "tools/run_distribution_zig_integrated_object.zig", .args = &.{"--release-source-owned"} },
    .{ .id = "real-rows-release-fast", .path = "src/distribution_real_rows_gate.zig", .args = &.{ "--mode=ReleaseFast", "--strict", "--limit=100" }, .cache_contract = .air_export_v1 },
    .{ .id = "real-rows-release-safe", .path = "src/distribution_real_rows_gate.zig", .args = &.{ "--mode=ReleaseSafe", "--strict", "--limit=100" }, .cache_contract = .air_export_v1 },
    .{ .id = "real-rows-release-small", .path = "src/distribution_real_rows_gate.zig", .args = &.{ "--mode=ReleaseSmall", "--strict", "--limit=100" }, .cache_contract = .air_export_v1 },
    .{ .id = "integrated-executable", .path = "tools/run_distribution_zig_integrated_exe.zig" },
    .{ .id = "release-object-inspection", .path = "tools/run_native_link_object_inspection.zig", .args = &.{"--release-source-owned"} },
    .{ .id = "release-native-link", .path = "tools/run_distribution_native_link_m5.zig", .args = &.{"--release-source-owned"} },
    .{ .id = "release-native-probe", .path = "tools/probe_native_linker_compatibility.zig", .args = &.{"--release-source-owned"} },
    .{ .id = "boundary-gates", .path = "tools/run_distribution_boundary_gates.zig" },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const fresh_real_rows = try parseArgs(allocator, init);

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";
    const target_assignment = try std.fmt.allocPrint(allocator, "TARGET={s}", .{target});
    defer allocator.free(target_assignment);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("distribution all gates target={s}\n", .{target});
    try stdout_writer.interface.flush();

    var measurements: [tools.len]Measurement = undefined;
    var total_duration_ms: i96 = 0;
    var cache_hits: usize = 0;
    var cache_misses: usize = 0;
    var cache_mixed: usize = 0;
    var cache_none: usize = 0;

    var tool_index: usize = 0;
    while (tool_index < tools.len) {
        if (tool_index == 9) {
            var first = try io.concurrent(runTool, .{ allocator, io, target_assignment, tool_index, fresh_real_rows });
            var second = try io.concurrent(runTool, .{ allocator, io, target_assignment, tool_index + 1, fresh_real_rows });
            var third = try io.concurrent(runTool, .{ allocator, io, target_assignment, tool_index + 2, fresh_real_rows });
            var completed = [_]CompletedTool{
                try first.await(io),
                try second.await(io),
                try third.await(io),
            };
            for (&completed, tool_index..) |*item, completed_index| {
                try recordTool(
                    &stdout_writer.interface,
                    completed_index,
                    item.*,
                    &measurements,
                    &total_duration_ms,
                    &cache_hits,
                    &cache_misses,
                    &cache_mixed,
                    &cache_none,
                    target,
                    fresh_real_rows,
                );
                common.freeRunResult(allocator, item.result);
            }
            tool_index += completed.len;
            continue;
        }
        const completed = try runTool(allocator, io, target_assignment, tool_index, fresh_real_rows);
        try recordTool(
            &stdout_writer.interface,
            tool_index,
            completed,
            &measurements,
            &total_duration_ms,
            &cache_hits,
            &cache_misses,
            &cache_mixed,
            &cache_none,
            target,
            fresh_real_rows,
        );
        common.freeRunResult(allocator, completed.result);
        tool_index += 1;
    }

    var ranked_indices: [tools.len]usize = undefined;
    for (&ranked_indices, 0..) |*index, value| index.* = value;
    sortSlowestFirst(&ranked_indices, &measurements);
    const slowest_count = @min(@as(usize, 5), tools.len);
    for (ranked_indices[0..slowest_count], 1..) |measurement_index, rank| {
        const measurement = measurements[measurement_index];
        const tool = tools[measurement.tool_index];
        try stdout_writer.interface.print("summary distribution-all-slowest rank={} tool={s}", .{ rank, tool.path });
        for (tool.args) |arg| try stdout_writer.interface.print(" {s}", .{arg});
        try stdout_writer.interface.print(" duration_ms={} cache_status={s}\n", .{ measurement.duration_ms, @tagName(measurement.cache_status) });
    }
    const reported_cache_contracts = countCacheContracts(.air_export_v1);
    const unreported_cache_contracts = countCacheContracts(.unreported);
    try stdout_writer.interface.print(
        "summary distribution-all-gate-inventory schema_version=1 subgates={} runner=zig-run runner_input_scope=command target={s} reported_cache_contracts={} unreported_cache_contracts={} local_fail=0\n",
        .{ tools.len, target, reported_cache_contracts, unreported_cache_contracts },
    );
    try stdout_writer.interface.print(
        "summary distribution-all-timing subgates={} total_duration_ms={} cache_hit_subgates={} cache_miss_subgates={} cache_mixed_subgates={} cache_none_subgates={} cache_observation_unreported_subgates={} slowest_reported={} fresh_real_rows={} local_fail=0\n",
        .{ tools.len, total_duration_ms, cache_hits, cache_misses, cache_mixed, cache_none, unreported_cache_contracts, slowest_count, fresh_real_rows },
    );

    try stdout_writer.interface.writeAll("ok distribution all gates\n");
    try stdout_writer.interface.flush();
}

fn recordTool(
    writer: *std.Io.Writer,
    tool_index: usize,
    completed: CompletedTool,
    measurements: *[tools.len]Measurement,
    total_duration_ms: *i96,
    cache_hits: *usize,
    cache_misses: *usize,
    cache_mixed: *usize,
    cache_none: *usize,
    target: []const u8,
    fresh_real_rows: bool,
) !void {
    const tool = tools[tool_index];
    const cache_mode: []const u8 = if (fresh_real_rows and tool.cache_contract == .air_export_v1) "fresh" else "default";
    try writer.print(
        "gate-input id={s} tool={s}",
        .{ tool.id, tool.path },
    );
    for (tool.args) |arg| try writer.print(" {s}", .{arg});
    try writer.print(
        " target={s} runner=zig-run input_scope=runner-command cache_contract={s} cache_mode={s}\n",
        .{ target, @tagName(tool.cache_contract), cache_mode },
    );
    try writer.print("gate-start id={s} tool={s}", .{ tool.id, tool.path });
    for (tool.args) |arg| try writer.print(" {s}", .{arg});
    try writer.writeAll("\n");
    const cache_status = cacheStatus(completed.result.stdout);
    switch (tool.cache_contract) {
        .air_export_v1 => if (cache_status == .none) return error.MissingDeclaredCacheTelemetry,
        .unreported => if (cache_status != .none) return error.UnclassifiedCacheTelemetry,
    }
    measurements[tool_index] = .{
        .tool_index = tool_index,
        .duration_ms = completed.duration_ms,
        .cache_status = cache_status,
    };
    total_duration_ms.* += completed.duration_ms;
    switch (cache_status) {
        .hit => cache_hits.* += 1,
        .miss => cache_misses.* += 1,
        .mixed => cache_mixed.* += 1,
        .none => cache_none.* += 1,
    }
    try writer.writeAll(completed.result.stdout);
    try writer.print("gate-end id={s} tool={s}", .{ tool.id, tool.path });
    for (tool.args) |arg| try writer.print(" {s}", .{arg});
    try writer.print(" exit_status=0 duration_ms={} cache_status={s}\n", .{ completed.duration_ms, @tagName(cache_status) });
    try writer.flush();
}

fn countCacheContracts(contract: CacheContract) usize {
    var count: usize = 0;
    for (tools) |tool| {
        if (tool.cache_contract == contract) count += 1;
    }
    return count;
}

fn runTool(allocator: std.mem.Allocator, io: std.Io, target_assignment: []const u8, tool_index: usize, fresh_real_rows: bool) !CompletedTool {
    const tool = tools[tool_index];
    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.appendSlice(allocator, &.{ "env", target_assignment, "zig", "run", tool.path });
    if (tool.args.len != 0) {
        try argv.append(allocator, "--");
        try argv.appendSlice(allocator, tool.args);
    }
    if (fresh_real_rows and std.mem.eql(u8, tool.path, "src/distribution_real_rows_gate.zig")) {
        if (tool.args.len == 0) try argv.append(allocator, "--");
        try argv.append(allocator, "--fresh-export");
    }
    const start = std.Io.Timestamp.now(io, .awake);
    return .{
        .result = try common.runCapture(allocator, io, argv.items, tool.path),
        .duration_ms = elapsedMs(io, start),
    };
}

fn parseArgs(allocator: std.mem.Allocator, init: std.process.Init) !bool {
    var fresh_real_rows = false;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--fresh-real-rows")) {
            fresh_real_rows = true;
        } else {
            return error.UnexpectedArgument;
        }
    }
    return fresh_real_rows;
}

fn elapsedMs(io: std.Io, start: std.Io.Timestamp) i96 {
    return @divTrunc(start.durationTo(std.Io.Timestamp.now(io, .awake)).nanoseconds, std.time.ns_per_ms);
}

fn cacheStatus(output: []const u8) CacheStatus {
    var saw_hit = false;
    var saw_miss = false;
    var lines = std.mem.splitScalar(u8, output, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, "cache") == null) continue;
        if (std.mem.indexOf(u8, line, "status=hit") != null) saw_hit = true;
        if (std.mem.indexOf(u8, line, "status=miss") != null or
            std.mem.indexOf(u8, line, "status=fresh") != null)
        {
            saw_miss = true;
        }
    }
    if (saw_hit and saw_miss) return .mixed;
    if (saw_hit) return .hit;
    if (saw_miss) return .miss;
    return .none;
}

fn sortSlowestFirst(indices: []usize, measurements: []const Measurement) void {
    var index: usize = 1;
    while (index < indices.len) : (index += 1) {
        const candidate = indices[index];
        var insert_at = index;
        while (insert_at > 0 and measurements[indices[insert_at - 1]].duration_ms < measurements[candidate].duration_ms) {
            indices[insert_at] = indices[insert_at - 1];
            insert_at -= 1;
        }
        indices[insert_at] = candidate;
    }
}

test "cache status classifies hit miss mixed and absent output" {
    try std.testing.expectEqual(CacheStatus.hit, cacheStatus("air-export-cache status=hit\n"));
    try std.testing.expectEqual(CacheStatus.miss, cacheStatus("air-export-cache status=miss-export\n"));
    try std.testing.expectEqual(CacheStatus.miss, cacheStatus("air-export-cache status=fresh-export\n"));
    try std.testing.expectEqual(CacheStatus.mixed, cacheStatus("cache status=hit\ncache status=miss-export\n"));
    try std.testing.expectEqual(CacheStatus.none, cacheStatus("summary local_fail=0\n"));
}

test "slowest measurements sort by descending duration" {
    const measurements = [_]Measurement{
        .{ .tool_index = 0, .duration_ms = 10, .cache_status = .none },
        .{ .tool_index = 1, .duration_ms = 30, .cache_status = .hit },
        .{ .tool_index = 2, .duration_ms = 20, .cache_status = .miss },
    };
    var indices = [_]usize{ 0, 1, 2 };
    sortSlowestFirst(&indices, &measurements);
    try std.testing.expectEqualSlices(usize, &.{ 1, 2, 0 }, &indices);
}

test "cache contracts distinguish explicit telemetry from unreported gates" {
    try std.testing.expectEqual(@as(usize, 3), countCacheContracts(.air_export_v1));
    try std.testing.expectEqual(@as(usize, 14), countCacheContracts(.unreported));
}
