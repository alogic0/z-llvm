//! Read-only ordered-event verification for an explicitly supplied trace.
//! This shares the strict native audit state machine. It does not establish
//! producer/build/input provenance or authorize deleting the input.
const std = @import("std");
const u = @import("validation/common.zig");
const fa = @import("vendor/file_audit/src/root.zig");
const core = @import("storage_cleanup/event_audit_core.zig");
const Failure = struct { code: []const u8, record: u64, byte_offset: u64 };

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const args = try init.minimal.args.toSlice(c.a);
    if (args.len != 5 or !std.mem.eql(u8, args[1], "--input") or !std.mem.eql(u8, args[3], "--output"))
        return error.ExpectedInputAndFreshOutput;
    const path = try c.join(&.{args[2]});
    const output = try c.join(&.{args[4]});
    if (u.exists(c.io, output)) return error.OutputAlreadyExists;
    var parent = try fa.metadata.openRoot(c.io, std.fs.path.dirname(path).?);
    defer parent.close(c.io);
    const name = std.fs.path.basename(path);
    const before = try fa.metadata.child(c.gpa, parent, name);
    if (before.kind != .file) return error.NotRegularFile;
    const z = try c.a.dupeSentinel(u8, name, 0);
    const fd = std.os.linux.openat(parent.handle, z, .{ .ACCMODE = .RDONLY, .CLOEXEC = true, .NOFOLLOW = true, .NONBLOCK = true, .NOCTTY = true }, 0);
    if (std.os.linux.errno(fd) != .SUCCESS) return error.OpenFailed;
    const file: std.Io.File = .{ .handle = @intCast(fd), .flags = .{ .nonblocking = true } };
    defer file.close(c.io);
    if (!before.eql(try fa.metadata.descriptor(file.handle))) return error.OpenedFileChanged;

    var state = core.State.init(c.a);
    defer state.deinit();
    var arena = std.heap.ArenaAllocator.init(c.gpa);
    defer arena.deinit();
    var reader = file.readerStreaming(c.io, try c.a.alloc(u8, 1024 * 1024));
    const last = try c.a.alloc(u8, 1024 * 1024);
    var last_len: usize = 0;
    var hash = std.crypto.hash.sha2.Sha256.init(.{});
    var bytes: u64 = 0;
    var records: u64 = 0;
    var validated: u64 = 0;
    var failure: ?Failure = null;
    var newline_complete = true;
    const started = std.Io.Timestamp.now(c.io, .awake);
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
    const prefix_valid = failure == null;
    if (failure == null) state.finish() catch |err| {
        failure = .{ .code = @errorName(err), .record = records, .byte_offset = bytes };
    };
    if (bytes != before.size or !before.eql(try fa.metadata.descriptor(file.handle)) or
        !before.eql(try fa.metadata.child(c.gpa, parent, name))) return error.TraceChanged;
    const status = if (failure == null) "verified_stream" else if (prefix_valid and !state.complete) "incomplete_stream" else "invalid_stream";
    try u.json.writeAtomic(c.gpa, c.io, .{ .path = output, .replace = false }, try u.toValue(c.a, .{
        .schema = "zllvm-trace-stream-verification-v1",
        .status = status,
        .path = path,
        .metadata = before,
        .sha256 = try c.a.dupe(u8, &std.fmt.bytesToHex(hash.finalResult(), .lower)),
        .whole_stream_read = true,
        .logical_bytes_read = bytes,
        .stream_metadata_unchanged = true,
        .whole_stream_semantically_valid = failure == null,
        .prefix_semantically_valid = prefix_valid,
        .newline_complete = newline_complete,
        .error_record = failure,
        .records = records,
        .validated_prefix_records = validated,
        .complete = state.complete,
        .succeeded = state.succeeded,
        .function_begins = state.begins,
        .function_ends = state.ends,
        .selected = state.selected,
        .failed = state.failed,
        .counters = state.counters,
        .failed_functions = state.failures.items,
        .active_function = state.active,
        .retry_active = state.retry,
        .last_record = std.mem.trimEnd(u8, last[0..last_len], "\r\n"),
        .core_sha256 = try u.digestBytes(c.a, @embedFile("storage_cleanup/event_audit_core.zig")),
        .driver_sha256 = try u.digestBytes(c.a, @embedFile("audit_trace_stream.zig")),
        .auditor_binary_sha256 = try c.digest("/proc/self/exe"),
        .audit_elapsed_ns = started.durationTo(.now(c.io, .awake)).nanoseconds,
        .retirement_ready = false,
    }));
    try c.print("{s}: {s}\n", .{ status, output });
}
