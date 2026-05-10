const std = @import("std");

pub const SupportedTarget = enum {
    x86_64_linux_gnu,
    x86_64_linux_musl,
    aarch64_linux_gnu,
    wasm32_wasi,
};

pub const Triple = struct {
    arch: []const u8,
    vendor: []const u8,
    os: []const u8,
    abi: ?[]const u8 = null,

    pub fn parse(text: []const u8) !Triple {
        var parts = std.mem.splitScalar(u8, text, '-');
        const arch = parts.next() orelse return error.InvalidTargetTriple;
        const second = parts.next() orelse return error.InvalidTargetTriple;
        const third = parts.next();
        const fourth = parts.next();
        if (parts.next() != null) return error.InvalidTargetTriple;

        const vendor: []const u8 = if (third == null) "unknown" else second;
        const os: []const u8 = third orelse second;
        const abi = fourth;
        if (arch.len == 0 or vendor.len == 0 or os.len == 0) return error.InvalidTargetTriple;
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

    pub fn isAArch64(triple: Triple) bool {
        return std.mem.eql(u8, triple.arch, "aarch64");
    }

    pub fn isWasm32(triple: Triple) bool {
        return std.mem.eql(u8, triple.arch, "wasm32");
    }

    pub fn isLinux(triple: Triple) bool {
        return std.mem.eql(u8, triple.os, "linux");
    }

    pub fn isWasi(triple: Triple) bool {
        return std.mem.eql(u8, triple.os, "wasi");
    }

    pub fn supportedTarget(triple: Triple) ?SupportedTarget {
        const abi = triple.abi orelse "";
        if (triple.isX86_64() and triple.isLinux() and std.mem.eql(u8, abi, "gnu")) return .x86_64_linux_gnu;
        if (triple.isX86_64() and triple.isLinux() and std.mem.eql(u8, abi, "musl")) return .x86_64_linux_musl;
        if (triple.isAArch64() and triple.isLinux() and std.mem.eql(u8, abi, "gnu")) return .aarch64_linux_gnu;
        if (triple.isWasm32() and triple.isWasi()) return .wasm32_wasi;
        return null;
    }

    pub fn isSupported(triple: Triple) bool {
        return triple.supportedTarget() != null;
    }
};
