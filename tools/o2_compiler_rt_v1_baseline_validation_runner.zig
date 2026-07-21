const std = @import("std");
const runner = @import("o2_compiler_rt_v1_baseline_validation/orchestration.zig");

pub fn main(init: std.process.Init) !void {
    return runner.main(init);
}

test {
    _ = runner;
}
