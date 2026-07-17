comptime {
    _ = @import("value_use/core_contract_tests.zig");
    _ = @import("value_use/actions/control_compare_branch_switch_tests.zig");
    _ = @import("value_use/actions/address_memory_store_tests.zig");
    _ = @import("value_use/materialization_supported_tests.zig");
    _ = @import("value_use/core_planning_tests.zig");
    _ = @import("value_use/materialization_prepared_tests.zig");
    _ = @import("value_use/planning_early_tests.zig");
    _ = @import("value_use/materialization_capability_tests.zig");
    _ = @import("value_use/core_owned_label_tests.zig");
    _ = @import("value_use/actions/address_memory_gep_tests.zig");
    _ = @import("value_use/actions/calls_tests.zig");
    _ = @import("value_use/composition_tests.zig");
    _ = @import("value_use/actions/address_memory_load_tests.zig");
    _ = @import("value_use/actions/control_compare_scratch_tests.zig");
    _ = @import("value_use/actions/control_compare_eq_zero_tests.zig");
    _ = @import("value_use/actions/control_compare_setcc_tests.zig");
    _ = @import("value_use/actions/control_compare_sign_bit_tests.zig");
    _ = @import("value_use/actions/control_compare_i128_tests.zig");
    _ = @import("value_use/core_architecture_proof_tests.zig");
}
