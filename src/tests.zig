const std = @import("std");

comptime {
    _ = @import("tests/composed_memset.zig");
    _ = @import("tests/air_lowering.zig");
    _ = @import("tests/codegen_x86_64.zig");
    _ = @import("tests/codegen_x86_64_generic_cfg_selector.zig");
    _ = @import("tests/ir.zig");
    _ = @import("tests/ir_operands.zig");
    _ = @import("tests/ir_instruction_ownership.zig");
    _ = @import("tests/optimizer_correctness.zig");
    _ = @import("tests/integer_semantics.zig");
    _ = @import("tests/module_references.zig");
    _ = @import("tests/globaldce_references.zig");
    _ = @import("tests/adce_operands.zig");
    _ = @import("tests/verifier_allocation.zig");
}
