const std = @import("std");

comptime {
    _ = @import("air_export_cache.zig");
    _ = @import("codegen/x86_64/symbol_address.zig");
    _ = @import("mc/global_data.zig");
    _ = @import("codegen/x86_64/generic_cfg/word_pair_memory_tests.zig");
    _ = @import("codegen/x86_64/generic_cfg/runtime_pointer_stack_tests.zig");
    _ = @import("codegen/x86_64/generic_cfg/integer_pointer_tests.zig");
    _ = @import("codegen/x86_64/generic_cfg/signed_nonnegative_tests.zig");
    _ = @import("codegen/x86_64/generic_cfg/type_layout_padding_tests.zig");
    _ = @import("codegen/x86_64/generic_cfg/global_memory_tests.zig");
    _ = @import("tests/correctness_checkpoint_native.zig");
    _ = @import("tests/composed_byte_loops.zig");
    _ = @import("tests/composed_memcpy.zig");
    _ = @import("tests/composed_memset.zig");
    _ = @import("tests/air_lowering.zig");
    _ = @import("tests/codegen_x86_64.zig");
    _ = @import("tests/codegen_x86_64_generic_cfg_selector.zig");
    _ = @import("tests/ir.zig");
    _ = @import("tests/ir_operands.zig");
    _ = @import("tests/ir_numeric_names.zig");
    _ = @import("tests/ir_parser_ownership.zig");
    _ = @import("tests/ir_parser_parameters.zig");
    _ = @import("tests/ir_instruction_ownership.zig");
    _ = @import("tests/optimizer_correctness.zig");
    _ = @import("tests/optimizer_review_boundaries.zig");
    _ = @import("tests/optimizer_checkpoint.zig");
    _ = @import("tests/integer_semantics.zig");
    _ = @import("tests/module_references.zig");
    _ = @import("tests/block_addresses.zig");
    _ = @import("tests/simplifycfg_names.zig");
    _ = @import("tests/globaldce_references.zig");
    _ = @import("tests/global_dependencies.zig");
    _ = @import("tests/adce_operands.zig");
    _ = @import("tests/verifier_allocation.zig");
}
