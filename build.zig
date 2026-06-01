const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "z_llvm",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the z_llvm tool");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(unit_tests).step);

    addScriptStep(b, "readiness", "Run the full readiness gate", "scripts/run_readiness_checks.sh");
    addScriptStep(b, "handoff", "Run optimizer/codegen handoff validation", "scripts/run_handoff_validation.sh");
    addScriptStep(b, "distribution-all", "Run selected distribution gates and boundary gates", "scripts/run_distribution_all_gates.sh");
    addScriptStep(b, "distribution-no-llvm", "Run the selected no-LLVM-codegen distribution subset", "scripts/run_distribution_no_llvm_codegen_subset.sh");
    addScriptStep(b, "distribution-boundary", "Run conservative distribution boundary gates", "scripts/run_distribution_boundary_gates.sh");
    addScriptStep(b, "distribution-musl-object", "Run selected x86_64 musl object subset gates", "scripts/run_distribution_x86_64_musl_object_subset.sh");
    addScriptStep(b, "distribution-musl-executable", "Run selected x86_64 musl executable subset gates", "scripts/run_distribution_x86_64_musl_executable_subset.sh");
    addScriptStepWithArgs(b, "probe-distribution-objects", "Run object-probe automation; pass arguments after --", "scripts/probe_distribution_objects.sh");
    addScriptStepWithArgs(b, "capture-zig-ir", "Capture Zig-emitted LLVM IR; pass arguments after --", "scripts/capture_zig_ir.sh");
}

fn addScriptStep(b: *std.Build, name: []const u8, description: []const u8, script: []const u8) void {
    const run_cmd = b.addSystemCommand(&.{ "bash", script });
    const step = b.step(name, description);
    step.dependOn(&run_cmd.step);
}

fn addScriptStepWithArgs(b: *std.Build, name: []const u8, description: []const u8, script: []const u8) void {
    const run_cmd = b.addSystemCommand(&.{ "bash", script });
    if (b.args) |args| run_cmd.addArgs(args);
    const step = b.step(name, description);
    step.dependOn(&run_cmd.step);
}
