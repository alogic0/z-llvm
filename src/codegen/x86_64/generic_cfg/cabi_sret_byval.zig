const impl = @import("cabi_impl.zig");
pub const lowerCAbiF128Sret = impl.lowerCAbiF128Sret;
pub const appendCAbiF128SretMachine = impl.appendCAbiF128SretMachine;
pub const lowerCAbiF128AggregateReturn = impl.lowerCAbiF128AggregateReturn;
pub const appendCAbiF128AggregateReturnMachine = impl.appendCAbiF128AggregateReturnMachine;
pub const lowerCAbiF128ScalarReturn = impl.lowerCAbiF128ScalarReturn;
pub const appendCAbiF128ScalarReturnMachine = impl.appendCAbiF128ScalarReturnMachine;
pub const appendCompareStackByval64Imm64 = impl.appendCompareStackByval64Imm64;
