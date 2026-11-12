//! Generate the bounded recursive medium-frame resource regression in Zig.
const std = @import("std");
pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const args = try init.minimal.args.toSlice(a);
    if (args.len != 2) return error.ExpectedFreshOutput;
    const waves = 48;
    const file = try std.Io.Dir.cwd().createFile(init.io, args[1], .{ .exclusive = true });
    defer file.close(init.io);
    var buffer: [65536]u8 = undefined;
    var writer = file.writerStreaming(init.io, &buffer);
    const out = &writer.interface;
    try out.writeAll("declare i64 @medium_observe(i64,i64,i64,i64,i64,i64,i64,i64,i64,i64)\ndefine i64 @medium_spill(ptr %out, i64 %seed, i64 %depth) {\nentry:\n %a0 = xor i64 %seed, 23\n");
    for (0..waves) |wave| {
        for (0..16) |lane| try out.print(" %v{d} = add i64 %seed, {d}\n", .{ wave * 16 + lane, 17 + wave * 29 + lane * 131 });
        try out.print(" %c{d} = call i64 @medium_observe(", .{wave});
        for (0..8) |lane| try out.print("i64 %v{d}, ", .{wave * 16 + lane});
        try out.print("i64 {d}, i64 %seed)\n", .{wave});
        for (0..16) |lane| {
            const id = wave * 16 + lane;
            try out.print(" %t{d} = xor i64 %v{d}, %c{d}\n", .{ id, id, wave });
            if (lane == 0) try out.print(" %s{d} = add i64 %a{d}, %t{d}\n", .{ id, wave, id }) else try out.print(" %s{d} = add i64 %s{d}, %t{d}\n", .{ id, id - 1, id });
        }
        try out.print(" %a{d} = add i64 %s{d}, 0\n", .{ wave + 1, wave * 16 + 15 });
    }
    try out.print(" %again = icmp ne i64 %depth, 0\n br i1 %again, label %recurse, label %done\nrecurse:\n %next_seed = add i64 %seed, 17\n %next_depth = sub i64 %depth, 1\n %child = call i64 @medium_spill(ptr %out,i64 %next_seed,i64 %next_depth)\n %sum = add i64 %a{d}, %child\n br label %done\ndone:\n %result = phi i64 [%a{d}, %entry], [%sum, %recurse]\n store i64 %result,ptr %out,align 8\n ret i64 %result\n}}\n", .{ waves, waves });
    try out.flush();
}
