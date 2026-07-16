const impl = @import("composed_selector_impl.zig");
const value_use_transaction = @import("composed_selector_value_use_transaction.zig");

pub const MachineFunction = impl.MachineFunction;
pub const Diagnostic = impl.Diagnostic;
pub const SelectionResult = impl.SelectionResult;
pub const tryLowerComposedCfg = impl.tryLowerComposedCfg;
pub const tryLowerComposedCfgWithContext = impl.tryLowerComposedCfgWithContext;
pub const tryLowerComposedCfgWithContextAndAddressDependencies = impl.tryLowerComposedCfgWithContextAndAddressDependencies;
pub const tryLowerComposedBlock = impl.tryLowerComposedBlock;
pub const tryLowerComposedBlockWithContext = impl.tryLowerComposedBlockWithContext;
pub const tryLowerComposedBlockWithContextAndAddressDependencies = impl.tryLowerComposedBlockWithContextAndAddressDependencies;
pub const ValueUseTransaction = value_use_transaction.ValueUseTransaction;

test {
    _ = @import("composed_selector_tests.zig");
}
