//! An observational footprint, separate from the verified deletion inventory.
const std = @import("std");
const core = @import("engine.zig");
const u = @import("../validation/common.zig");

pub fn write(e: *core.Engine, phase: []const u8) !void {
    const observed = try u.process.runReport(e.c.gpa, e.c.io, .{ .spawn = .{ .argv = &.{ "du", "-x", "-B1", "--max-depth=1", "--", "local-state" }, .cwd = .{ .path = e.c.root }, .environ_map = &e.c.env, .search_path = true }, .timeout_ms = 120_000, .stdout_limit = 4 * 1024 * 1024, .stderr_limit = 1024 * 1024 });
    defer observed.deinit(e.c.gpa);
    if (!observed.success()) {
        // Builders can change unrelated directories during this observation.
        // An incomplete footprint is not a reason to relax or fail mutation.
        return e.write(try e.c.fmt("{s}/footprint-{s}.json", .{ e.output, phase }), .{ .schema = "zllvm-storage-footprint-v1", .status = "unavailable", .diagnostic = observed.stderr, .outcome = observed.outcome });
    }
    const text = observed.stdout;
    const Row = struct { path: []const u8, allocated_bytes: u64, disposition: []const u8 };
    var rows: std.ArrayList(Row) = .empty;
    var total: u64 = 0;
    var lines = std.mem.tokenizeScalar(u8, text, '\n');
    while (lines.next()) |line| {
        const tab = std.mem.indexOfScalar(u8, line, '\t') orelse return error.InvalidFootprint;
        const bytes = try std.fmt.parseInt(u64, line[0..tab], 10);
        const path = line[tab + 1 ..];
        if (std.mem.eql(u8, path, "local-state")) {
            total = bytes;
            continue;
        }
        var disposition: []const u8 = "unassessed";
        for (e.config.protected_paths) |protected| if (core.p.within(protected, path)) {
            disposition = "protected by policy";
            break;
        };
        if (std.mem.eql(u8, path, "local-state/validations")) disposition = "mixed: see individual candidate decisions; other files unassessed";
        if (std.mem.eql(u8, path, "local-state/retirements")) disposition = "retained audit and reconstruction evidence";
        try rows.append(e.c.a, .{ .path = path, .allocated_bytes = bytes, .disposition = disposition });
    }
    var eligible: u64 = 0;
    var held: u64 = 0;
    for (e.actions.items) |a| {
        if (!a.measured) continue;
        if (a.status == .ready) eligible += a.allocated_bytes;
        if (a.status == .skipped) held += a.allocated_bytes;
    }
    try e.write(try e.c.fmt("{s}/footprint-{s}.json", .{ e.output, phase }), .{
        .schema = "zllvm-storage-footprint-v1",
        .status = "observed",
        .local_state_allocated_bytes = total,
        .eligible_candidate_file_bytes = eligible,
        .held_candidate_file_bytes = held,
        .outside_measured_candidates_bytes_estimate = total -| (eligible + held),
        .roots = rows.items,
        .scope = "Observational same-filesystem du, including directories and concurrent work. Bytes outside measured candidates include retained evidence, protected roots and unsupported formats; they are NOT a claim of necessity or deletion eligibility. See report.json for exact guarded actions. A minimal pass reaches the minimum allowed by verified rules, not a proof of a globally minimal tree.",
    });
}
