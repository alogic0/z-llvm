const std = @import("std");

pub const Triple = struct {
    arch: []const u8,
    vendor: []const u8,
    os: []const u8,
    abi: ?[]const u8 = null,

    pub fn parse(text: []const u8) !Triple {
        var parts = std.mem.splitScalar(u8, text, '-');
        const arch = parts.next() orelse return error.InvalidTargetTriple;
        const vendor = parts.next() orelse return error.InvalidTargetTriple;
        const os = parts.next() orelse return error.InvalidTargetTriple;
        const abi = parts.next();
        if (arch.len == 0 or vendor.len == 0 or os.len == 0) return error.InvalidTargetTriple;
        if (parts.next() != null) return error.InvalidTargetTriple;
        return .{
            .arch = arch,
            .vendor = vendor,
            .os = os,
            .abi = abi,
        };
    }

    pub fn isX86_64(triple: Triple) bool {
        return std.mem.eql(u8, triple.arch, "x86_64");
    }

    pub fn isLinux(triple: Triple) bool {
        return std.mem.eql(u8, triple.os, "linux");
    }
};
