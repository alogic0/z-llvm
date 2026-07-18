const value_use_model = @import("../model.zig");

pub const PhysicalNode = value_use_model.PhysicalNode;
pub const Mapping = struct {
    source: ?PhysicalNode,
    destination: PhysicalNode,
    source_request_index: ?u8,
};

pub const CopyVisitState = enum { unseen, visiting, complete };
