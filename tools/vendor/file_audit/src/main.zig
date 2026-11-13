const std = @import("std");
const audit = @import("file_audit");
const help =
    \\Usage:
    \\  zig-file-audit scan ROOT [--hash] [--exclude RELATIVE] [--max-entries N] [--max-depth N]
    \\  zig-file-audit duplicates ROOT [--exclude RELATIVE] [--max-entries N] [--max-depth N]
    \\  zig-file-audit verify SNAPSHOT.json
    \\  zig-file-audit --version
    \\Prints one JSON document on success. Read-only; never deletes or links files.
    \\Write reports outside the scanned root so report creation does not change it.
    \\Symlinks/special files are recorded without reading or traversing them.
    \\No paths are excluded implicitly. Exclusions match exact relative subtrees.
    \\
;

fn execute(init: std.process.Init) !void {
    const a = init.gpa;
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const io = init.io;
    var buffer: [16384]u8 = undefined;
    var output = std.Io.File.stdout().writer(io, &buffer);
    if (args.len == 2 and std.mem.eql(u8, args[1], "--version")) {
        try output.interface.print("zig-file-audit {s}\n", .{audit.version});
    } else if (args.len == 2 and std.mem.eql(u8, args[1], "--help")) {
        try output.interface.writeAll(help);
    } else if (args.len == 3 and std.mem.eql(u8, args[1], "verify")) {
        const file = try std.Io.Dir.cwd().openFile(io, args[2], .{ .allow_directory = false, .follow_symlinks = false });
        defer file.close(io);
        var input_buffer: [4096]u8 = undefined;
        var reader = file.readerStreaming(io, &input_buffer);
        const bytes = try reader.interface.allocRemaining(a, .limited(256 * 1024 * 1024));
        defer a.free(bytes);
        const parsed = try std.json.parseFromSlice(audit.Snapshot, a, bytes, .{ .allocate = .alloc_always });
        defer parsed.deinit();
        try audit.verify(a, io, parsed.value);
        try std.json.Stringify.value(.{ .status = "passed", .root = parsed.value.root, .entries = parsed.value.entries.len }, .{}, &output.interface);
        try output.interface.writeByte('\n');
    } else {
        if (args.len < 3) return error.InvalidArguments;
        const duplicate = std.mem.eql(u8, args[1], "duplicates");
        if (!duplicate and !std.mem.eql(u8, args[1], "scan")) return error.InvalidArguments;
        var options: audit.Options = .{ .hash_files = duplicate };
        var excludes: std.ArrayList([]const u8) = .empty;
        defer excludes.deinit(a);
        var i: usize = 3;
        while (i < args.len) : (i += 1) {
            if (std.mem.eql(u8, args[i], "--hash")) {
                options.hash_files = true;
            } else {
                if (i + 1 >= args.len) return error.InvalidArguments;
                const name = args[i];
                i += 1;
                if (std.mem.eql(u8, name, "--exclude")) try excludes.append(a, args[i]) else if (std.mem.eql(u8, name, "--max-entries")) {
                    options.max_entries = try std.fmt.parseInt(usize, args[i], 10);
                } else if (std.mem.eql(u8, name, "--max-depth")) {
                    options.max_depth = try std.fmt.parseInt(usize, args[i], 10);
                } else return error.InvalidArguments;
            }
        }
        options.exclude_paths = excludes.items;
        var snapshot = try audit.scan(a, io, args[2], options);
        defer snapshot.deinit();
        if (duplicate) {
            var found = try audit.findDuplicates(a, snapshot.value);
            defer found.deinit();
            try std.json.Stringify.value(found.value, .{}, &output.interface);
        } else try std.json.Stringify.value(snapshot.value, .{}, &output.interface);
        try output.interface.writeByte('\n');
    }
    try output.interface.flush();
}

pub fn main(init: std.process.Init) void {
    execute(init) catch |err| {
        var buffer: [4096]u8 = undefined;
        var output = std.Io.File.stderr().writer(init.io, &buffer);
        output.interface.print("zig-file-audit: {s}\n", .{@errorName(err)}) catch {};
        if (err == error.InvalidArguments) output.interface.writeAll(help) catch {};
        output.interface.flush() catch {};
        std.process.exit(1);
    };
}
