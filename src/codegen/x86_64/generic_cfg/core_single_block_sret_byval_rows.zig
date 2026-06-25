const impl = @import("core_single_block_rows_impl.zig");

pub const lowerGenericCfgSelectedSretStores = impl.lowerGenericCfgSelectedSretStores;
pub const lowerGenericCfgScalarSretParamStores = impl.lowerGenericCfgScalarSretParamStores;
pub const lowerGenericCfgSretCopy = impl.lowerGenericCfgSretCopy;
pub const aggregateCopyGepOffset = impl.aggregateCopyGepOffset;
pub const aggregateLeafTypeAtOffset = impl.aggregateLeafTypeAtOffset;
pub const sretAggregateType = impl.sretAggregateType;
pub const byvalAggregateType = impl.byvalAggregateType;
pub const aggregateAbiAttrType = impl.aggregateAbiAttrType;
pub const findMatchingParen = impl.findMatchingParen;
pub const aggregateFieldOffsetU8 = impl.aggregateFieldOffsetU8;
pub const aggregateFieldOffset = impl.aggregateFieldOffset;
pub const aggregateByteOffsetU8 = impl.aggregateByteOffsetU8;
pub const aggregateByteOffset = impl.aggregateByteOffset;
