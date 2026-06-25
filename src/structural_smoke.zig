const std = @import("std");

test "descriptor facades compile" {
    const descriptor = @import("semantic_descriptor_v2.zig");
    const api = @import("semantic_descriptor_v2_api.zig");
    const verify_api = @import("semantic_descriptor_v2_verify.zig");
    const canonicalize = @import("semantic_descriptor_v2_canonicalize.zig");

    _ = descriptor.verify;
    _ = api.programFromSourceFacts;
    _ = verify_api.verify;
    _ = canonicalize.releaseCanonicalizationReport;
}

test "ir writer stage facades compile" {
    const writers = @import("main_flow_ir_writer_case_writers.zig");

    _ = writers.stage1.writeTinyScalarIrWriterBody;
    _ = writers.stage2.writeMinimalIrWriterBody;
    _ = writers.writeMinimalIrWriterBody;
}

test "generic cfg responsibility facades compile" {
    const single_block = @import("codegen/x86_64/generic_cfg/core_single_block_rows.zig");
    const aggregate = @import("codegen/x86_64/generic_cfg/cabi_aggregate_lowering.zig");

    _ = single_block.scalar.lowerGenericCfgSingleBlockScalar;
    _ = single_block.calls.lowerGenericCfgSingleBlockCallCheckMain;
    _ = single_block.sret_byval.lowerGenericCfgSretCopy;
    _ = single_block.packed_bits.lowerGenericCfgSingleBlockPackedBits;
    _ = single_block.pointer.lowerGenericCfgPointerSelectLoadReturn;

    _ = aggregate.classification.classifySysVAggregate;
    _ = aggregate.fields.aggregateGepByteOffset;
    _ = aggregate.returns.lowerAggregateAbiReturn;
    _ = aggregate.sret_byval_copy.supportedAggregateCopyLeaf;
}

test "std import keeps test binary non-empty" {
    try std.testing.expect(true);
}
