pub const triple = @import("target/triple.zig");
pub const datalayout = @import("target/datalayout.zig");
pub const abi = @import("target/abi.zig");
pub const features = @import("target/features.zig");

pub const Triple = triple.Triple;
pub const SupportedTarget = triple.SupportedTarget;
pub const DataLayout = datalayout.DataLayout;
pub const AbiValueClass = abi.ValueClass;
pub const AbiSlot = abi.Slot;
pub const AbiClassification = abi.Classification;
pub const AbiFunctionSignature = abi.FunctionSignature;
pub const FeatureAttrs = features.FeatureAttrs;
