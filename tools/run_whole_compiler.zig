pub const main = @import("validation/whole_compiler.zig").main;

test {
    _ = @import("validation/whole_compiler_generations.zig");
    _ = @import("validation/whole_compiler_report.zig");
    _ = @import("validation/whole_compiler_reuse.zig");
    _ = @import("validation/whole_compiler_resources.zig");
}
