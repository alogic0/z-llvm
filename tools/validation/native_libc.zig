//! Exact native startup/runtime inputs selected by a libc installation file.
const std = @import("std");
const u = @import("common.zig");

pub fn identities(c: *u.Context, path: []const u8) !u.Value {
    const installation = try std.zig.LibCInstallation.parse(c.a, c.io, path, &@import("builtin").target);
    const crt = installation.crt_dir orelse return error.MissingLibcCrtDirectory;
    const cc = installation.cc_dir orelse return error.MissingLibcCcDirectory;
    if (!std.fs.path.isAbsolute(crt) or !std.fs.path.isAbsolute(cc)) return error.LibcPathsMustBeAbsolute;
    var result = u.array(c.a);
    for ([_][]const u8{ "crt1.o", "Scrt1.o", "crti.o", "crtn.o", "libc.so", "libc.so.6", "ld-linux-x86-64.so.2", "crtbegin.o", "crtend.o", "crtbeginS.o", "crtendS.o" }, 0..) |name, i| {
        const file = try c.join(&.{ if (i < 7) crt else cc, name });
        try u.add(&result, try u.toValue(c.a, .{ .path = file, .bytes = (try std.Io.Dir.cwd().statFile(c.io, file, .{})).size, .sha256 = try c.digest(file) }));
    }
    return result;
}
