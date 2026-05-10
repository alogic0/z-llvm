const std = @import("std");
const target = @import("../target.zig");

pub const LibFunc = enum {
    memcpy,
    memmove,
    memset,
    sqrt,

    pub fn parse(name: []const u8) ?LibFunc {
        if (std.mem.eql(u8, name, "memcpy")) return .memcpy;
        if (std.mem.eql(u8, name, "memmove")) return .memmove;
        if (std.mem.eql(u8, name, "memset")) return .memset;
        if (std.mem.eql(u8, name, "sqrt")) return .sqrt;
        return null;
    }
};

pub const Info = struct {
    triple: target.Triple,

    pub fn init(triple: target.Triple) Info {
        return .{ .triple = triple };
    }

    pub fn has(info: Info, lib_func: LibFunc) bool {
        return switch (lib_func) {
            .memcpy, .memmove, .memset => info.triple.isLinux() or info.triple.isWasi(),
            .sqrt => info.triple.isLinux(),
        };
    }

    pub fn hasName(info: Info, name: []const u8) bool {
        const lib_func = LibFunc.parse(name) orelse return false;
        return info.has(lib_func);
    }
};
