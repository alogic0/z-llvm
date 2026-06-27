const std = @import("std");
const air_export = @import("zig_air_export.zig");

pub fn isRootSourceFunction(root_stem: []const u8, function_name: []const u8) bool {
    return std.mem.eql(u8, function_name, root_stem) or
        (std.mem.startsWith(u8, function_name, root_stem) and
            function_name.len > root_stem.len and function_name[root_stem.len] == '.');
}

pub fn rootFunctionCount(functions: []const air_export.Function, root_stem: []const u8) usize {
    var count: usize = 0;
    for (functions) |function| {
        if (isRootSourceFunction(root_stem, function.name)) count += 1;
    }
    return count;
}

pub fn moduleRootFunctionCount(module: air_export.Module) usize {
    return rootFunctionCount(module.functions, std.fs.path.stem(module.root_source));
}

test "AIR root helper matches root and qualified root functions" {
    try std.testing.expect(isRootSourceFunction("main", "main"));
    try std.testing.expect(isRootSourceFunction("main", "main.helper"));
    try std.testing.expect(!isRootSourceFunction("main", "mainland"));
    try std.testing.expect(!isRootSourceFunction("main", "helper"));
}
