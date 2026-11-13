//! Missing diagnostics are acceptable only when an approved completed ledger
//! proves that this exact name contained no diagnostic bytes when retired.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const empty_sha = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";

pub fn keep(e: *core.Engine, path: []const u8, kept: *std.ArrayList(p.Evidence)) !void {
    const relative = try e.relative(path);
    if (e.metadata(relative)) |_| return e.keep(kept, relative, null) else |err| if (err != error.FileNotFound) return err;
    for (e.config.retired_empty_log_records) |record| {
        try e.check(record);
        var parsed = try e.load(e.c.gpa, record.path);
        defer parsed.deinit();
        const v = parsed.value;
        const before = try core.get(v, "preservation_verified_before");
        const after = try core.get(v, "preservation_verified_after");
        if (try core.integer(v, "schema") != 1 or !core.eq(v, "status", "complete") or
            before != .bool or !before.bool or after != .bool or !after.bool) return error.IncompleteLogRetirement;
        const actions = try core.get(v, "actions");
        if (actions != .array) return error.InvalidLogRetirement;
        var matches: usize = 0;
        for (actions.array.items) |action| {
            if (!core.eq(action, "path", relative)) continue;
            matches += 1;
            const applied = try core.get(action, "applied");
            const info = try core.get(action, "info");
            if (applied != .bool or !applied.bool or !core.eq(action, "sha256", empty_sha) or
                try core.integer(info, "size") != 0 or try core.integer(info, "allocated") != 0) return error.NonemptyOrUnretiredLog;
        }
        if (matches == 0) continue;
        if (matches != 1) return error.AmbiguousLogRetirement;
        const audit = try e.c.fmt("{s}/approved-audit.json", .{std.fs.path.dirname(record.path).?});
        try e.keep(kept, record.path, record.sha256);
        try e.keep(kept, audit, try core.str(v, "audit_sha256"));
        return;
    }
    return error.MissingDiagnosticRetirement;
}
