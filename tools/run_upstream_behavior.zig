//! Run one unchanged upstream behavior configuration with optional local capture.
const std = @import("std");
const behavior = @import("validation/upstream_behavior.zig");

pub fn main(init: std.process.Init) !void {
    const env = try init.minimal.environ.createMap(init.arena.allocator());
    if (env.get("ZLLVM_WHOLE_CAPTURE_ROOT") != null) return @import("validation/whole_compiler.zig").main(init);
    return behavior.main(init);
}

test {
    _ = behavior;
}
