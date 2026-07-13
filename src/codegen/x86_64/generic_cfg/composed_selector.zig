const impl = @import("composed_selector_impl.zig");

pub const MachineFunction = impl.MachineFunction;
pub const Diagnostic = impl.Diagnostic;
pub const SelectionResult = impl.SelectionResult;
pub const tryLowerComposedCfg = impl.tryLowerComposedCfg;
pub const tryLowerComposedCfgWithContext = impl.tryLowerComposedCfgWithContext;
pub const tryLowerComposedBlock = impl.tryLowerComposedBlock;
pub const tryLowerComposedBlockWithContext = impl.tryLowerComposedBlockWithContext;

test {
    _ = @import("composed_selector_tests.zig");
}
