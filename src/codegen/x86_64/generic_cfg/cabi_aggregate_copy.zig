const ir = @import("../../../ir.zig");
const type_layout = @import("../../../zig_air_type_layout.zig");

pub fn isSupportedAggregateCopyLeafAggregate(aggregate_ty: ir.Type) bool {
    return type_layout.isSupportedScalarLeafAggregate(aggregate_ty);
}

pub fn supportedAggregateCopyLeaf(ty: ir.Type) bool {
    return type_layout.isSupportedScalarLeaf(ty);
}
