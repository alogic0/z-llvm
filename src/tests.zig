const std = @import("std");

comptime {
    _ = @import("tests/air_lowering.zig");
    _ = @import("tests/codegen_x86_64.zig");
    _ = @import("tests/ir.zig");
}
