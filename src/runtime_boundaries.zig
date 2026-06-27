const std = @import("std");

pub const runtime_symbol_prefixes = [_][]const u8{
    "debug.",
    "panic",
    "__",
    "compiler_rt.",
    "memcpy",
    "memset",
    "memcmp",
    "malloc",
    "free",
    "abort",
    "exit",
    "posix.",
    "os.",
    "Io.",
    "Thread.",
    "start.",
};

pub const runtime_symbol_suffixes = [_][]const u8{
    ".outOfBounds",
    ".integerPartOutOfBounds",
    ".unwrapNull",
};

pub fn isRuntimeBoundarySymbol(symbol: []const u8) bool {
    for (runtime_symbol_prefixes) |prefix| {
        if (std.mem.startsWith(u8, symbol, prefix)) return true;
    }
    for (runtime_symbol_suffixes) |suffix| {
        if (std.mem.endsWith(u8, symbol, suffix)) return true;
    }
    return false;
}

test "runtime boundary symbol policy is table driven" {
    try std.testing.expect(isRuntimeBoundarySymbol("debug.defaultPanic"));
    try std.testing.expect(isRuntimeBoundarySymbol("compiler_rt.__muloti4"));
    try std.testing.expect(isRuntimeBoundarySymbol("memcpy"));
    try std.testing.expect(isRuntimeBoundarySymbol("panic.outOfBounds"));
    try std.testing.expect(isRuntimeBoundarySymbol("safety.integerPartOutOfBounds"));
    try std.testing.expect(!isRuntimeBoundarySymbol("frontier_helper"));
}
