//! Preserve an honest diagnosis of a closed, possibly incomplete event stream.
//! This reads every byte and validates the available ordered prefix. It never
//! substitutes for a complete event audit or authorizes retirement by itself.
const std = @import("std");
const u = @import("validation/common.zig");
const storage = @import("storage_cleanup/engine.zig");
const core = @import("storage_cleanup/event_audit_core.zig");
const fa = storage.fa;
const p = storage.p;
const Failure = struct { code: []const u8, record: u64, byte_offset: u64 };

fn diagnose(e: *storage.Engine, path: []const u8) !void {
    if (!p.relative(path) or !p.candidate(path) or !std.mem.eql(u8, std.fs.path.basename(path), "profile.events.jsonl")) return error.InvalidTracePath;
    const before = try e.metadata(path);
    if (before.kind != .file) return error.NotRegularFile;
    var parent = try fa.metadata.openRoot(e.c.io, try e.absolute(std.fs.path.dirname(path).?));
    defer parent.close(e.c.io);
    const name = std.fs.path.basename(path);
    const file = try parent.openFile(e.c.io, name, .{ .follow_symlinks = false, .allow_directory = false });
    defer file.close(e.c.io);
    if (!before.eql(try fa.metadata.descriptor(file.handle))) return error.OpenedFileChanged;
    var state = core.State.init(e.c.a);
    defer state.deinit();
    var arena = std.heap.ArenaAllocator.init(e.c.gpa);
    defer arena.deinit();
    var reader = file.readerStreaming(e.c.io, try e.c.a.alloc(u8, 1024 * 1024));
    const last = try e.c.a.alloc(u8, 1024 * 1024);
    var last_len: usize = 0;
    var hash = std.crypto.hash.sha2.Sha256.init(.{});
    var bytes: u64 = 0;
    var records: u64 = 0;
    var validated: u64 = 0;
    var failure: ?Failure = null;
    var newline_complete = true;
    while (true) {
        const line = reader.interface.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                const tail = reader.interface.buffer[reader.interface.seek..reader.interface.end];
                if (tail.len != 0) {
                    hash.update(tail);
                    newline_complete = false;
                    if (failure == null) failure = .{ .code = "UnterminatedRecord", .record = records, .byte_offset = bytes };
                    bytes += tail.len;
                }
                break;
            },
            else => return err,
        };
        hash.update(line);
        const offset = bytes;
        bytes += line.len;
        records += 1;
        @memcpy(last[0..line.len], line);
        last_len = line.len;
        if (failure != null) continue;
        _ = arena.reset(.retain_capacity);
        const event = std.json.parseFromSliceLeaky(core.Event, arena.allocator(), line, .{ .ignore_unknown_fields = true }) catch |err| {
            failure = .{ .code = @errorName(err), .record = records - 1, .byte_offset = offset };
            continue;
        };
        state.feed(event, offset, bytes) catch |err| {
            failure = .{ .code = @errorName(err), .record = records - 1, .byte_offset = offset };
            continue;
        };
        validated += 1;
    }
    if (bytes != before.size or !before.eql(try fa.metadata.descriptor(file.handle)) or
        !before.eql(try fa.metadata.child(e.c.gpa, parent, name))) return error.TraceChanged;
    const sha = try e.c.a.dupe(u8, &std.fmt.bytesToHex(hash.finalResult(), .lower));
    const core_path = try e.c.fmt("{s}/event_audit_core.zig", .{e.output});
    const driver_path = try e.c.fmt("{s}/diagnose_native_events.zig", .{e.output});
    try u.files.writeAtomic(e.c.io, .{ .path = try e.absolute(core_path), .replace = false }, &.{@embedFile("storage_cleanup/event_audit_core.zig")});
    try u.files.writeAtomic(e.c.io, .{ .path = try e.absolute(driver_path), .replace = false }, &.{@embedFile("diagnose_native_events.zig")});
    try e.write(try e.c.fmt("{s}/diagnosis.json", .{e.output}), .{
        .schema = "zllvm-event-prefix-diagnosis-v1",
        .path = path,
        .sha256 = sha,
        .metadata = before,
        .whole_stream_read = true,
        .logical_bytes_read = bytes,
        .stream_metadata_unchanged = true,
        .records = records,
        .validated_prefix_records = validated,
        .prefix_semantically_valid = failure == null,
        .newline_complete = newline_complete,
        .error_record = failure,
        .complete = state.complete,
        .succeeded = state.succeeded,
        .function_begins = state.begins,
        .function_ends = state.ends,
        .selected = state.selected,
        .failed = state.failed,
        .failed_functions = state.failures.items,
        .active_function = state.active,
        .retry_active = state.retry,
        .last_record = std.mem.trimEnd(u8, last[0..last_len], "\r\n"),
        .core = p.Evidence{ .path = core_path, .sha256 = try e.digest(core_path) },
        .driver = p.Evidence{ .path = driver_path, .sha256 = try e.digest(driver_path) },
        .diagnostic_binary_sha256 = try e.c.digest("/proc/self/exe"),
        .retirement_ready = false,
        .scope = "Ordered-prefix diagnosis only. Missing completion and interrupted producer outcomes remain incomplete. Separate producer binding, disposition, retention and mutation checks are required.",
    });
}

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const args = try init.minimal.args.toSlice(c.a);
    if (args.len != 3 or !std.mem.eql(u8, args[1], "--trace")) return error.ExpectedTracePath;
    const state_path = try c.join(&.{"local-state/storage-cleanup"});
    var state = try fa.metadata.openRoot(c.io, state_path);
    defer state.close(c.io);
    const lease = try state.createFile(c.io, "cleanup.lock", .{ .truncate = false });
    defer lease.close(c.io);
    if (!try lease.tryLock(c.io, .shared)) return error.CleanupInProgress;
    defer lease.unlock(c.io);
    const output = try c.fmt("local-state/retirements/native-event-diagnosis/{d}-{d}", .{ std.Io.Clock.real.now(c.io).nanoseconds, std.os.linux.getpid() });
    _ = try c.newOutput(output);
    var engine = storage.Engine.init(&c, .{}, output, "zigrep");
    try diagnose(&engine, args[2]);
    try c.print("Event diagnosis: {s}/diagnosis.json\n", .{output});
}

test "event prefix diagnosis distinguishes incomplete complete corrupt and unterminated streams" {
    const t = std.testing;
    const begin = "{\"schema\":\"compilation-events-v1\",\"sequence\":0,\"elapsed_ns\":0,\"event\":\"profile_begin\",\"function\":null,\"phase\":\"other\",\"details\":{}}\n";
    const end = "{\"schema\":\"compilation-events-v1\",\"sequence\":1,\"elapsed_ns\":1,\"event\":\"profile_end\",\"function\":null,\"phase\":\"other\",\"details\":{\"succeeded\":true,\"counters\":{\"selected_functions\":0,\"failed_functions\":0}}}\n";
    for (0..4) |case| {
        var tmp = t.tmpDir(.{ .iterate = true });
        defer tmp.cleanup();
        var arena = std.heap.ArenaAllocator.init(t.allocator);
        defer arena.deinit();
        const a = arena.allocator();
        var c: u.Context = .{ .a = a, .gpa = t.allocator, .io = t.io, .root = try tmp.dir.realPathFileAlloc(t.io, ".", a), .env = try t.environ.createMap(a), .quiet = true };
        const run = "local-state/validations/diagnostic/batch/run";
        const output = "local-state/retirements/diagnosis";
        try tmp.dir.createDirPath(t.io, run);
        try tmp.dir.createDirPath(t.io, output);
        var e = storage.Engine.init(&c, .{}, output, "zigrep");
        const raw = switch (case) {
            0 => begin,
            1 => begin ++ end,
            2 => begin ++ begin,
            else => begin ++ "{",
        };
        const path = run ++ "/profile.events.jsonl";
        try tmp.dir.writeFile(t.io, .{ .sub_path = path, .data = raw });
        try diagnose(&e, path);
        var report = try e.load(t.allocator, output ++ "/diagnosis.json");
        defer report.deinit();
        try t.expectEqual(case < 2, try storage.boolean(report.value, "prefix_semantically_valid"));
        try t.expectEqual(case == 1, try storage.boolean(report.value, "complete"));
        try t.expect(!try storage.boolean(report.value, "retirement_ready"));
        try t.expectEqualStrings(try u.digestBytes(a, raw), try storage.str(report.value, "sha256"));
        try t.expectEqual(@as(i64, @intCast(raw.len)), try storage.integer(report.value, "logical_bytes_read"));
    }
}
