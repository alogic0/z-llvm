const core = @import("zig_air_model_base.zig");
const typed_recognizers = @import("zig_air_model_typed_recognizers.zig");

pub const SliceSumSummary = core.SliceSumSummary;
pub const PointerSliceAddressSummary = core.PointerSliceAddressSummary;
pub const TypedSliceLoopSummary = core.TypedSliceLoopSummary;

pub const pointerSliceAddressSummary = core.pointerSliceAddressSummary;
pub const sliceSumSummary = core.sliceSumSummary;
pub const selectedSliceSumShape = core.selectedSliceSumShape;
pub const typedSliceSumSummary = typed_recognizers.typedSliceSumSummary;
pub const typedConditionalSliceSumSummary = typed_recognizers.typedConditionalSliceSumSummary;
pub const typedAccumulatorLoopSummary = typed_recognizers.typedAccumulatorLoopSummary;
pub const typedConditionalSlotUpdateSummary = typed_recognizers.typedConditionalSlotUpdateSummary;
