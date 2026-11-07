pub const main = @import("validation/whole_compiler.zig").main;

test {
    _ = @import("validation/whole_compiler_report.zig");
}
