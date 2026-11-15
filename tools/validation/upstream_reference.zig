//! Bind a preopt comparison to its selected normal-LLVM reference.
const std = @import("std");
const u = @import("common.zig");

fn argument(argv: []u.Value, name: []const u8, expected: []const u8) !void {
    var found: usize = 0;
    for (argv, 0..) |arg, i| if (u.json.is(arg, name)) {
        if (i + 1 == argv.len or !u.json.is(argv[i + 1], expected)) return error.ReferenceCommandMismatch;
        found += 1;
    };
    if (found != 1) return error.ReferenceCommandMismatch;
}

pub fn validate(reference: u.Value, current: u.Value, source: []const u8, a: std.mem.Allocator) !void {
    for ([_][]const u8{ "compiler", "suite", "libc", "source_pin", "mode", "resources", "full_suite" }) |field| {
        if (!u.json.eql(try u.get(reference, field), try u.get(current, field))) return error.ReferenceBindingMismatch;
    }
    if (current.object.get("native_libc_inputs")) |providers| {
        if (!u.json.eql(providers, reference.object.get("native_libc_inputs") orelse return error.ReferenceMissingProviders)) return error.ReferenceProviderMismatch;
    }
    if (!u.json.is(try u.get(reference, "status"), "passed") or !u.json.is(try u.get(reference, "route"), "llvm")) return error.InvalidReference;
    const rows = try u.json.array(try u.get(reference, "outcomes"));
    if (rows.len == 0 or (try u.get(reference, "tests")).integer != rows.len) return error.InvalidReference;
    var names = std.StringHashMap(void).init(a);
    defer names.deinit();
    for (rows) |row| {
        const name = try u.str(row, "name");
        if ((try names.getOrPut(name)).found_existing or
            !u.contains(&.{ "OK", "SKIP" }, try u.str(row, "outcome"))) return error.InvalidReference;
    }
    const commands = try u.json.array(try u.get(reference, "commands"));
    if (commands.len < 2) return error.InvalidReference;
    for (commands) |command| {
        if (!u.json.is(try u.get(command, "outcome"), "completed") or
            (try u.get(command, "actual_returncode")).integer != 0 or (try u.get(command, "returncode")).integer != 0) return error.InvalidReference;
    }
    const argv = try u.json.array(try u.get(commands[0], "argv"));
    try argument(argv, "-target", "x86_64-linux-gnu");
    try argument(argv, "--zig-lib-dir", try std.fs.path.join(a, &.{ source, "lib" }));
    try argument(argv, "--libc", try u.str(try u.get(current, "libc"), "path"));
    for ([_][]const u8{ "-fllvm", "-lc", "--test-no-exec" }) |flag| {
        var count: usize = 0;
        for (argv) |arg| if (u.json.is(arg, flag)) {
            count += 1;
        };
        if (count != 1) return error.ReferenceCommandMismatch;
    }
    var cpu: usize = 0;
    var mode: usize = 0;
    var compiler: usize = 0;
    for (argv, 0..) |arg, i| {
        if (u.json.is(arg, "-mcpu=baseline")) cpu += 1;
        if (u.json.is(arg, try std.fmt.allocPrint(a, "-O{s}", .{try u.str(current, "mode")}))) mode += 1;
        if (u.json.is(arg, try u.str(try u.get(current, "compiler"), "path"))) {
            if (i + 2 >= argv.len or !u.json.is(argv[i + 1], "test") or !u.json.is(argv[i + 2], try u.str(try u.get(current, "suite"), "path"))) return error.ReferenceCommandMismatch;
            compiler += 1;
        }
    }
    if (cpu != 1 or mode != 1 or compiler != 1) return error.ReferenceCommandMismatch;
}

test "preopt references bind frontend inputs resources and actual normal commands" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const current = try u.toValue(a, .{
        .compiler = .{ .path = "/zig", .sha256 = "frontend" },
        .suite = .{ .path = "/src/test/behavior.zig", .sha256 = "suite" },
        .libc = .{ .path = "/libc.txt", .sha256 = "libc" },
        .source_pin = "pin",
        .mode = "ReleaseSafe",
        .resources = "normal",
        .full_suite = true,
    });
    var reference = try u.toValue(a, .{
        .compiler = .{ .path = "/zig", .sha256 = "frontend" },
        .suite = .{ .path = "/src/test/behavior.zig", .sha256 = "suite" },
        .libc = .{ .path = "/libc.txt", .sha256 = "libc" },
        .source_pin = "pin",
        .mode = "ReleaseSafe",
        .resources = "normal",
        .full_suite = true,
        .status = "passed",
        .route = "llvm",
        .tests = 2,
        .outcomes = .{ .{ .name = "first", .outcome = "OK" }, .{ .name = "second", .outcome = "SKIP" } },
        .commands = .{
            .{ .argv = .{ "/zig", "test", "/src/test/behavior.zig", "-OReleaseSafe", "-target", "x86_64-linux-gnu", "-mcpu=baseline", "-fllvm", "-lc", "--test-no-exec", "--zig-lib-dir", "/src/lib", "--libc", "/libc.txt" }, .outcome = "completed", .actual_returncode = 0, .returncode = 0 },
            .{ .argv = .{"/behavior"}, .outcome = "completed", .actual_returncode = 0, .returncode = 0 },
        },
    });
    try validate(reference, current, "/src", a);
    try u.put(a, &reference, "route", u.s("local"));
    try std.testing.expectError(error.InvalidReference, validate(reference, current, "/src", a));
    try u.put(a, &reference, "route", u.s("llvm"));
    try u.put(a, &reference, "resources", u.s("accepted"));
    try std.testing.expectError(error.ReferenceBindingMismatch, validate(reference, current, "/src", a));
    try u.put(a, &reference, "resources", u.s("normal"));
    try u.put(a, &reference, "compiler", try u.toValue(a, .{ .path = "/zig", .sha256 = "another" }));
    try std.testing.expectError(error.ReferenceBindingMismatch, validate(reference, current, "/src", a));
    try u.put(a, &reference, "compiler", try u.get(current, "compiler"));
    var provider_current = try u.toValue(a, current);
    try u.put(a, &provider_current, "native_libc_inputs", try u.toValue(a, .{.{ .path = "/libc.so.6", .sha256 = "current" }}));
    try std.testing.expectError(error.ReferenceMissingProviders, validate(reference, provider_current, "/src", a));
    try u.put(a, &reference, "native_libc_inputs", try u.toValue(a, .{.{ .path = "/libc.so.6", .sha256 = "old" }}));
    try std.testing.expectError(error.ReferenceProviderMismatch, validate(reference, provider_current, "/src", a));
    try u.put(a, &reference, "native_libc_inputs", try u.get(provider_current, "native_libc_inputs"));
    try validate(reference, provider_current, "/src", a);
}
