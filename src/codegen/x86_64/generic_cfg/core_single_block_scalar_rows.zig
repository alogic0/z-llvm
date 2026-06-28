const impl = @import("core_single_block_rows_impl.zig");

pub const lowerGenericCfgSingleBlockScalar = impl.lowerGenericCfgSingleBlockScalar;
pub const lowerGenericCfgSingleBlockFp = impl.lowerGenericCfgSingleBlockFp;
pub const lowerGenericCfgSingleBlockAggregateAbi = impl.lowerGenericCfgSingleBlockAggregateAbi;
pub const lowerGenericCfgSingleBlockI64 = impl.lowerGenericCfgSingleBlockI64;
pub const lowerGenericCfgSingleBlockPointerLoadStore = impl.lowerGenericCfgSingleBlockPointerLoadStore;
pub const lowerGenericCfgSingleBlockSliceLen = impl.lowerGenericCfgSingleBlockSliceLen;
