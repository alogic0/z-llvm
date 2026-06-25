const std = @import("std");
const pipelines = @import("pipelines.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    try pipelines.verifyPlaceholderBudgets();

    for (pipelines.release_policy_pipeline_names) |pipeline_name| {
        const pipeline = pipelines.find(pipeline_name) orelse return error.UnknownPipeline;
        const counts = pipelines.summarizePipeline(pipeline);
        const expected_placeholders = pipelines.expectedPlaceholderBudget(pipeline_name);
        try stdout_writer.interface.print(
            "pipeline={s} implemented_passes={} placeholder_passes={} conservative_passes={} boundary_noop_passes={} out_of_scope_passes={} unknown_passes={}",
            .{
                pipeline.name,
                counts.implemented,
                counts.placeholder,
                counts.conservative,
                counts.boundary_noop,
                counts.out_of_scope,
                counts.unknown,
            },
        );
        if (expected_placeholders) |expected| {
            try stdout_writer.interface.print(" expected_placeholder_passes={}", .{expected});
        }
        if (pipelines.expectedReleasePolicyBudget(pipeline_name)) |expected| {
            try stdout_writer.interface.print(
                " expected_boundary_noop_passes={} expected_out_of_scope_passes={}",
                .{ expected.expected_boundary_noop, expected.expected_out_of_scope },
            );
        }
        try stdout_writer.interface.writeAll("\n");
    }

    try stdout_writer.interface.flush();
}
