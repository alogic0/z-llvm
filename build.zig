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

    const structural_smoke_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/structural_smoke.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const structural_smoke_step = b.step("structural-smoke", "Compile structural facade smoke tests");
    structural_smoke_step.dependOn(&b.addRunArtifact(structural_smoke_tests).step);

    const release_pipeline_policy_report = b.addExecutable(.{
        .name = "release_pipeline_policy_report",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/report_release_pipeline_policy.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const release_pipeline_policy_step = b.step("release-pipeline-policy", "Report release pipeline pass implementation and placeholder policy");
    release_pipeline_policy_step.dependOn(&b.addRunArtifact(release_pipeline_policy_report).step);

    addToolStepWithArgs(b, "compare-opt", "Run optimizer fixture comparison; pass optional fixture args after --", "tools/compare_opt.zig");
    addToolStepWithFixedArgs(b, "compare-codegen-asm", "Compare generated x86_64 assembly fixtures", "tools/compare_codegen.zig", &.{"--mode=asm"});
    addToolStepWithFixedArgs(b, "compare-codegen-objdump", "Compare generated x86_64 object disassembly fixtures", "tools/compare_codegen.zig", &.{"--mode=objdump"});
    addToolStepWithFixedArgs(b, "compare-codegen-readelf", "Compare generated x86_64 object symbol and relocation fixtures", "tools/compare_codegen.zig", &.{"--mode=readelf"});
    addToolStepWithArgs(b, "lint-zig-ir-manifest", "Lint the Zig IR fixture manifest; pass optional args after --", "tools/lint_zig_ir_manifest.zig");
    addToolStepWithArgs(b, "zig-corpus", "Run accepted Zig IR corpus rows; pass optional manifest after --", "tools/run_zig_corpus.zig");
    addToolStep(b, "generated-scalar-diff", "Run generated scalar differential checks", "tools/run_generated_scalar_diff.zig");
    addToolStep(b, "check-zig-stage4-emitter", "Check the authoritative Zig stage4 emitter", "tools/check_zig_stage4_emitter.zig");
    addToolStep(b, "readiness", "Run the full readiness gate", "tools/run_readiness_checks.zig");
    addToolStep(b, "handoff", "Run optimizer/codegen handoff validation", "tools/run_handoff_validation.zig");
    addToolStepWithArgs(b, "distribution-object", "Run selected ReleaseFast object gate", "tools/run_distribution_object_m1.zig");
    addToolStep(b, "distribution-executable", "Run selected ReleaseFast executable gate", "tools/run_distribution_executable_m1.zig");
    addToolStep(b, "distribution-releasesafe-object", "Run selected ReleaseSafe object and executable ABI gate", "tools/run_distribution_releasesafe_object_m2.zig");
    addToolStep(b, "distribution-releasesmall-object", "Run selected ReleaseSmall object gate", "tools/run_distribution_releasesmall_object_m3.zig");
    addToolStep(b, "distribution-releasesmall-executable", "Run selected ReleaseSmall executable gate", "tools/run_distribution_releasesmall_executable_m3.zig");
    addToolStep(b, "distribution-releasesmall-boundary", "Run selected ReleaseSmall boundary exclusions", "tools/run_distribution_releasesmall_boundary_m3.zig");
    addToolStep(b, "distribution-debug-object", "Run selected Debug object gate", "tools/run_distribution_debug_object_m4.zig");
    addToolStep(b, "distribution-debug-executable", "Run selected Debug executable gate", "tools/run_distribution_debug_executable_m4.zig");
    addToolStep(b, "distribution-debug-unwind", "Run selected Debug unwind/DWARF boundary gate", "tools/run_distribution_debug_unwind_boundary.zig");
    addToolStep(b, "distribution-linker-boundary", "Run linker/CRT ownership boundary gate", "tools/run_distribution_linker_boundary.zig");
    addToolStep(b, "distribution-aarch64-boundary", "Run AArch64 object target boundary gate", "tools/run_distribution_aarch64_object_boundary.zig");
    addToolStep(b, "distribution-all", "Run selected distribution gates, native-link proof/probe, and boundary gates", "tools/run_distribution_all_gates.zig");
    addToolStep(b, "distribution-no-llvm", "Run the selected no-LLVM-codegen distribution subset", "tools/run_distribution_no_llvm_codegen_subset.zig");
    addToolStep(b, "distribution-boundary", "Run conservative distribution boundary gates", "tools/run_distribution_boundary_gates.zig");
    addToolStepWithArgs(b, "distribution-native-link", "Run selected native Zig linker handoff gates", "tools/run_distribution_native_link_m5.zig");
    addToolStepWithArgs(b, "distribution-native-link-object-inspection", "Inspect z_llvm ELF objects before Zig native linker handoff", "tools/run_native_link_object_inspection.zig");
    addToolStep(b, "distribution-zig-source-native-link", "Run selected Zig source to z_llvm object to native-link executable gate", "tools/run_distribution_zig_source_native_link.zig");
    addToolStep(b, "distribution-zig-integrated-object", "Run patched Zig integrated z_llvm object-emission gate", "tools/run_distribution_zig_integrated_object.zig");
    addToolStepWithFixedAndUserArgs(b, "distribution-zig-integrated-preopt", "Run patched Zig integrated preopt z_llvm optimizer/object-emission gate", "tools/run_distribution_zig_integrated_object.zig", &.{"--pipeline=preopt"});
    addToolStepWithFixedAndUserArgs(b, "distribution-zig-ir-writer-tiny-scalar", "Run the first selected Zig-owned textual IR writer gate", "tools/run_distribution_zig_integrated_object.zig", &.{ "--ir-writer", "--case=releasefast_tiny_scalar" });
    addToolStepWithFixedAndUserArgs(b, "distribution-zig-ir-writer", "Run selected Zig-owned textual IR writer integration gate", "tools/run_distribution_zig_integrated_object.zig", &.{"--ir-writer"});
    addToolStep(b, "distribution-x86_64-selected-zllvm", "Run compact selected x86_64 z_llvm replacement gate", "tools/run_distribution_x86_64_selected_zllvm.zig");
    addToolStepWithFixedAndUserArgs(b, "distribution-x86_64-source-backed-structured", "Run broad x86_64 release source-backed structured-direct gate", "tools/run_distribution_zig_integrated_object.zig", &.{"--source-backed-broad"});
    addToolStepWithFixedAndUserArgs(b, "distribution-zig-source-structured-direct", "Run x86_64 release source-wrapper structured-direct gate without case-id ownership", "tools/run_distribution_zig_integrated_object.zig", &.{"--source-wrapper-dispatch"});
    addToolStepWithFixedAndUserArgs(b, "distribution-x86_64-release-source-owned", "Run x86_64 release source-owned semantic structured-direct gate", "tools/run_distribution_zig_integrated_object.zig", &.{"--release-source-owned"});
    const uncurated_air_gate = b.addExecutable(.{
        .name = "uncurated_air_gate",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/uncurated_air_gate.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const run_uncurated_air_gate = b.addRunArtifact(uncurated_air_gate);
    const uncurated_air_step = b.step("distribution-zig-air-uncurated-releasefast", "Discover and generically lower uncurated x86_64 ReleaseFast Zig AIR");
    uncurated_air_step.dependOn(&run_uncurated_air_gate.step);
    const run_uncurated_air_releasefast_broad_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_broad_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_broad_gate.addArg("--corpus=broad");
    const uncurated_air_releasefast_broad_step = b.step("distribution-zig-air-uncurated-releasefast-broad", "Discover and generically lower broad uncurated x86_64 ReleaseFast Zig AIR");
    uncurated_air_releasefast_broad_step.dependOn(&run_uncurated_air_releasefast_broad_gate.step);
    const run_uncurated_air_releasefast_expanded_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_expanded_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_expanded_gate.addArg("--corpus=expanded");
    const uncurated_air_releasefast_expanded_step = b.step("distribution-zig-air-uncurated-releasefast-expanded", "Discover and lower the expanded x86_64 ReleaseFast Zig AIR frontier corpus");
    uncurated_air_releasefast_expanded_step.dependOn(&run_uncurated_air_releasefast_expanded_gate.step);
    const run_uncurated_air_releasefast_scale_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_scale_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_scale_gate.addArg("--corpus=scale");
    run_uncurated_air_releasefast_scale_gate.addArg("--object-progress");
    const uncurated_air_releasefast_scale_step = b.step("distribution-zig-air-uncurated-releasefast-scale", "Discover, lower, and emit objects for the scale x86_64 ReleaseFast Zig AIR frontier corpus");
    uncurated_air_releasefast_scale_step.dependOn(&run_uncurated_air_releasefast_scale_gate.step);
    const run_uncurated_air_releasefast_scale_object_inspection_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_scale_object_inspection_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_scale_object_inspection_gate.addArg("--corpus=scale");
    run_uncurated_air_releasefast_scale_object_inspection_gate.addArg("--object-inspection");
    const uncurated_air_releasefast_scale_object_inspection_step = b.step("distribution-zig-air-uncurated-releasefast-scale-object-inspection", "Inspect scale uncurated x86_64 ReleaseFast real-AIR ELF objects with readelf/objdump");
    uncurated_air_releasefast_scale_object_inspection_step.dependOn(&run_uncurated_air_releasefast_scale_object_inspection_gate.step);
    const run_uncurated_air_releasefast_scale_native_link_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_scale_native_link_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_scale_native_link_gate.addArg("--corpus=scale");
    run_uncurated_air_releasefast_scale_native_link_gate.addArg("--native-link-progress");
    const uncurated_air_releasefast_scale_native_link_step = b.step("distribution-zig-air-uncurated-releasefast-scale-native-link", "Link scale uncurated x86_64 ReleaseFast real-AIR objects with Zig native linker progress accounting");
    uncurated_air_releasefast_scale_native_link_step.dependOn(&run_uncurated_air_releasefast_scale_native_link_gate.step);
    const run_uncurated_air_releasefast_scale_executable_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_scale_executable_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_scale_executable_gate.addArg("--corpus=scale");
    run_uncurated_air_releasefast_scale_executable_gate.addArg("--executable-progress");
    const uncurated_air_releasefast_scale_executable_step = b.step("distribution-zig-air-uncurated-releasefast-scale-executable", "Run stable C-ABI executable probes for scale uncurated x86_64 ReleaseFast real-AIR objects");
    uncurated_air_releasefast_scale_executable_step.dependOn(&run_uncurated_air_releasefast_scale_executable_gate.step);
    const run_uncurated_air_releasefast_frontier_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_frontier_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_frontier_gate.addArg("--corpus=frontier");
    run_uncurated_air_releasefast_frontier_gate.addArg("--object-progress");
    const uncurated_air_releasefast_frontier_step = b.step("distribution-zig-air-uncurated-releasefast-frontier", "Discover, lower, and emit objects for the frontier x86_64 ReleaseFast Zig AIR corpus");
    uncurated_air_releasefast_frontier_step.dependOn(&run_uncurated_air_releasefast_frontier_gate.step);
    const run_uncurated_air_releasefast_frontier_object_inspection_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_frontier_object_inspection_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_frontier_object_inspection_gate.addArg("--corpus=frontier");
    run_uncurated_air_releasefast_frontier_object_inspection_gate.addArg("--object-inspection");
    const uncurated_air_releasefast_frontier_object_inspection_step = b.step("distribution-zig-air-uncurated-releasefast-frontier-object-inspection", "Inspect frontier uncurated x86_64 ReleaseFast real-AIR ELF objects with readelf/objdump");
    uncurated_air_releasefast_frontier_object_inspection_step.dependOn(&run_uncurated_air_releasefast_frontier_object_inspection_gate.step);
    const run_uncurated_air_releasefast_frontier_native_link_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_frontier_native_link_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_frontier_native_link_gate.addArg("--corpus=frontier");
    run_uncurated_air_releasefast_frontier_native_link_gate.addArg("--native-link-progress");
    const uncurated_air_releasefast_frontier_native_link_step = b.step("distribution-zig-air-uncurated-releasefast-frontier-native-link", "Link frontier uncurated x86_64 ReleaseFast real-AIR objects with Zig native linker progress accounting");
    uncurated_air_releasefast_frontier_native_link_step.dependOn(&run_uncurated_air_releasefast_frontier_native_link_gate.step);
    const run_uncurated_air_releasefast_frontier_executable_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_frontier_executable_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_frontier_executable_gate.addArg("--corpus=frontier");
    run_uncurated_air_releasefast_frontier_executable_gate.addArg("--executable-progress");
    const uncurated_air_releasefast_frontier_executable_step = b.step("distribution-zig-air-uncurated-releasefast-frontier-executable", "Run stable C-ABI executable probes for frontier uncurated x86_64 ReleaseFast real-AIR objects");
    uncurated_air_releasefast_frontier_executable_step.dependOn(&run_uncurated_air_releasefast_frontier_executable_gate.step);
    const run_uncurated_air_releasefast_expanded_object_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_expanded_object_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_expanded_object_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasefast_expanded_object_gate.addArg("--object-progress");
    const uncurated_air_releasefast_expanded_object_step = b.step("distribution-zig-air-uncurated-releasefast-expanded-object", "Emit z_llvm ELF objects for expanded uncurated x86_64 ReleaseFast Zig AIR progress accounting");
    uncurated_air_releasefast_expanded_object_step.dependOn(&run_uncurated_air_releasefast_expanded_object_gate.step);
    const run_uncurated_air_releasefast_expanded_object_inspection_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_expanded_object_inspection_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_expanded_object_inspection_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasefast_expanded_object_inspection_gate.addArg("--object-inspection");
    const uncurated_air_releasefast_expanded_object_inspection_step = b.step("distribution-zig-air-uncurated-releasefast-expanded-object-inspection", "Inspect expanded uncurated x86_64 ReleaseFast real-AIR ELF objects with readelf/objdump");
    uncurated_air_releasefast_expanded_object_inspection_step.dependOn(&run_uncurated_air_releasefast_expanded_object_inspection_gate.step);
    const run_uncurated_air_releasefast_expanded_native_link_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_expanded_native_link_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_expanded_native_link_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasefast_expanded_native_link_gate.addArg("--native-link-progress");
    const uncurated_air_releasefast_expanded_native_link_step = b.step("distribution-zig-air-uncurated-releasefast-expanded-native-link", "Link expanded uncurated x86_64 ReleaseFast real-AIR objects with Zig native linker progress accounting");
    uncurated_air_releasefast_expanded_native_link_step.dependOn(&run_uncurated_air_releasefast_expanded_native_link_gate.step);
    const run_uncurated_air_releasefast_expanded_executable_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_expanded_executable_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_expanded_executable_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasefast_expanded_executable_gate.addArg("--executable-progress");
    const uncurated_air_releasefast_expanded_executable_step = b.step("distribution-zig-air-uncurated-releasefast-expanded-executable", "Run stable C-ABI executable probes for expanded uncurated x86_64 ReleaseFast real-AIR objects");
    uncurated_air_releasefast_expanded_executable_step.dependOn(&run_uncurated_air_releasefast_expanded_executable_gate.step);
    const run_uncurated_air_releasefast_broad_object_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_broad_object_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_broad_object_gate.addArg("--corpus=broad");
    run_uncurated_air_releasefast_broad_object_gate.addArg("--object-progress");
    const uncurated_air_releasefast_broad_object_step = b.step("distribution-zig-air-uncurated-releasefast-broad-object", "Emit z_llvm ELF objects for broad uncurated x86_64 ReleaseFast Zig AIR progress accounting");
    uncurated_air_releasefast_broad_object_step.dependOn(&run_uncurated_air_releasefast_broad_object_gate.step);
    const run_uncurated_air_releasefast_broad_object_inspection_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_broad_object_inspection_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_broad_object_inspection_gate.addArg("--corpus=broad");
    run_uncurated_air_releasefast_broad_object_inspection_gate.addArg("--object-inspection");
    const uncurated_air_releasefast_broad_object_inspection_step = b.step("distribution-zig-air-uncurated-releasefast-broad-object-inspection", "Inspect broad uncurated x86_64 ReleaseFast real-AIR ELF objects with readelf/objdump");
    uncurated_air_releasefast_broad_object_inspection_step.dependOn(&run_uncurated_air_releasefast_broad_object_inspection_gate.step);
    const run_uncurated_air_releasefast_broad_native_link_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_broad_native_link_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_broad_native_link_gate.addArg("--corpus=broad");
    run_uncurated_air_releasefast_broad_native_link_gate.addArg("--native-link-progress");
    const uncurated_air_releasefast_broad_native_link_step = b.step("distribution-zig-air-uncurated-releasefast-broad-native-link", "Link broad uncurated x86_64 ReleaseFast real-AIR objects with Zig native linker progress accounting");
    uncurated_air_releasefast_broad_native_link_step.dependOn(&run_uncurated_air_releasefast_broad_native_link_gate.step);
    const run_uncurated_air_releasefast_broad_executable_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_broad_executable_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_broad_executable_gate.addArg("--corpus=broad");
    run_uncurated_air_releasefast_broad_executable_gate.addArg("--executable-progress");
    const uncurated_air_releasefast_broad_executable_step = b.step("distribution-zig-air-uncurated-releasefast-broad-executable", "Run stable C-ABI executable probes for broad uncurated x86_64 ReleaseFast real-AIR objects");
    uncurated_air_releasefast_broad_executable_step.dependOn(&run_uncurated_air_releasefast_broad_executable_gate.step);
    const run_uncurated_air_releasesafe_broad_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_broad_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_broad_gate.addArg("--corpus=broad");
    const uncurated_air_releasesafe_broad_step = b.step("distribution-zig-air-uncurated-releasesafe-broad", "Discover and generically lower broad uncurated x86_64 ReleaseSafe Zig AIR progress");
    uncurated_air_releasesafe_broad_step.dependOn(&run_uncurated_air_releasesafe_broad_gate.step);
    const run_uncurated_air_releasesafe_expanded_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_expanded_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_expanded_gate.addArg("--corpus=expanded");
    const uncurated_air_releasesafe_expanded_step = b.step("distribution-zig-air-uncurated-releasesafe-expanded", "Discover and lower the expanded x86_64 ReleaseSafe Zig AIR frontier corpus");
    uncurated_air_releasesafe_expanded_step.dependOn(&run_uncurated_air_releasesafe_expanded_gate.step);
    const run_uncurated_air_releasesafe_scale_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_scale_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_scale_gate.addArg("--corpus=scale");
    run_uncurated_air_releasesafe_scale_gate.addArg("--object-progress");
    const uncurated_air_releasesafe_scale_step = b.step("distribution-zig-air-uncurated-releasesafe-scale", "Discover, lower, and emit objects for the scale x86_64 ReleaseSafe Zig AIR frontier corpus");
    uncurated_air_releasesafe_scale_step.dependOn(&run_uncurated_air_releasesafe_scale_gate.step);
    const run_uncurated_air_releasesafe_scale_object_inspection_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_scale_object_inspection_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_scale_object_inspection_gate.addArg("--corpus=scale");
    run_uncurated_air_releasesafe_scale_object_inspection_gate.addArg("--object-inspection");
    const uncurated_air_releasesafe_scale_object_inspection_step = b.step("distribution-zig-air-uncurated-releasesafe-scale-object-inspection", "Inspect scale uncurated x86_64 ReleaseSafe real-AIR ELF objects with readelf/objdump");
    uncurated_air_releasesafe_scale_object_inspection_step.dependOn(&run_uncurated_air_releasesafe_scale_object_inspection_gate.step);
    const run_uncurated_air_releasesafe_scale_native_link_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_scale_native_link_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_scale_native_link_gate.addArg("--corpus=scale");
    run_uncurated_air_releasesafe_scale_native_link_gate.addArg("--native-link-progress");
    const uncurated_air_releasesafe_scale_native_link_step = b.step("distribution-zig-air-uncurated-releasesafe-scale-native-link", "Link scale uncurated x86_64 ReleaseSafe real-AIR objects with Zig native linker progress accounting");
    uncurated_air_releasesafe_scale_native_link_step.dependOn(&run_uncurated_air_releasesafe_scale_native_link_gate.step);
    const run_uncurated_air_releasesafe_scale_executable_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_scale_executable_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_scale_executable_gate.addArg("--corpus=scale");
    run_uncurated_air_releasesafe_scale_executable_gate.addArg("--executable-progress");
    const uncurated_air_releasesafe_scale_executable_step = b.step("distribution-zig-air-uncurated-releasesafe-scale-executable", "Run stable C-ABI executable probes for scale uncurated x86_64 ReleaseSafe real-AIR objects");
    uncurated_air_releasesafe_scale_executable_step.dependOn(&run_uncurated_air_releasesafe_scale_executable_gate.step);
    const run_uncurated_air_releasesafe_frontier_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_frontier_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_frontier_gate.addArg("--corpus=frontier");
    run_uncurated_air_releasesafe_frontier_gate.addArg("--object-progress");
    const uncurated_air_releasesafe_frontier_step = b.step("distribution-zig-air-uncurated-releasesafe-frontier", "Discover, lower, and emit objects for the frontier x86_64 ReleaseSafe Zig AIR corpus");
    uncurated_air_releasesafe_frontier_step.dependOn(&run_uncurated_air_releasesafe_frontier_gate.step);
    const run_uncurated_air_releasesafe_frontier_object_inspection_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_frontier_object_inspection_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_frontier_object_inspection_gate.addArg("--corpus=frontier");
    run_uncurated_air_releasesafe_frontier_object_inspection_gate.addArg("--object-inspection");
    const uncurated_air_releasesafe_frontier_object_inspection_step = b.step("distribution-zig-air-uncurated-releasesafe-frontier-object-inspection", "Inspect frontier uncurated x86_64 ReleaseSafe real-AIR ELF objects with readelf/objdump");
    uncurated_air_releasesafe_frontier_object_inspection_step.dependOn(&run_uncurated_air_releasesafe_frontier_object_inspection_gate.step);
    const run_uncurated_air_releasesafe_frontier_native_link_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_frontier_native_link_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_frontier_native_link_gate.addArg("--corpus=frontier");
    run_uncurated_air_releasesafe_frontier_native_link_gate.addArg("--native-link-progress");
    const uncurated_air_releasesafe_frontier_native_link_step = b.step("distribution-zig-air-uncurated-releasesafe-frontier-native-link", "Link frontier uncurated x86_64 ReleaseSafe real-AIR objects with Zig native linker progress accounting");
    uncurated_air_releasesafe_frontier_native_link_step.dependOn(&run_uncurated_air_releasesafe_frontier_native_link_gate.step);
    const run_uncurated_air_releasesafe_frontier_executable_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_frontier_executable_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_frontier_executable_gate.addArg("--corpus=frontier");
    run_uncurated_air_releasesafe_frontier_executable_gate.addArg("--executable-progress");
    const uncurated_air_releasesafe_frontier_executable_step = b.step("distribution-zig-air-uncurated-releasesafe-frontier-executable", "Run stable C-ABI executable probes for frontier uncurated x86_64 ReleaseSafe real-AIR objects");
    uncurated_air_releasesafe_frontier_executable_step.dependOn(&run_uncurated_air_releasesafe_frontier_executable_gate.step);
    const run_uncurated_air_releasesafe_expanded_object_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_expanded_object_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_expanded_object_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasesafe_expanded_object_gate.addArg("--object-progress");
    const uncurated_air_releasesafe_expanded_object_step = b.step("distribution-zig-air-uncurated-releasesafe-expanded-object", "Emit z_llvm ELF objects for expanded uncurated x86_64 ReleaseSafe Zig AIR progress accounting");
    uncurated_air_releasesafe_expanded_object_step.dependOn(&run_uncurated_air_releasesafe_expanded_object_gate.step);
    const run_uncurated_air_releasesafe_expanded_object_inspection_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_expanded_object_inspection_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_expanded_object_inspection_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasesafe_expanded_object_inspection_gate.addArg("--object-inspection");
    const uncurated_air_releasesafe_expanded_object_inspection_step = b.step("distribution-zig-air-uncurated-releasesafe-expanded-object-inspection", "Inspect expanded uncurated x86_64 ReleaseSafe real-AIR ELF objects with readelf/objdump");
    uncurated_air_releasesafe_expanded_object_inspection_step.dependOn(&run_uncurated_air_releasesafe_expanded_object_inspection_gate.step);
    const run_uncurated_air_releasesafe_expanded_native_link_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_expanded_native_link_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_expanded_native_link_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasesafe_expanded_native_link_gate.addArg("--native-link-progress");
    const uncurated_air_releasesafe_expanded_native_link_step = b.step("distribution-zig-air-uncurated-releasesafe-expanded-native-link", "Link expanded uncurated x86_64 ReleaseSafe real-AIR objects with Zig native linker progress accounting");
    uncurated_air_releasesafe_expanded_native_link_step.dependOn(&run_uncurated_air_releasesafe_expanded_native_link_gate.step);
    const run_uncurated_air_releasesafe_expanded_executable_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_expanded_executable_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_expanded_executable_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasesafe_expanded_executable_gate.addArg("--executable-progress");
    const uncurated_air_releasesafe_expanded_executable_step = b.step("distribution-zig-air-uncurated-releasesafe-expanded-executable", "Run stable C-ABI executable probes for expanded uncurated x86_64 ReleaseSafe real-AIR objects");
    uncurated_air_releasesafe_expanded_executable_step.dependOn(&run_uncurated_air_releasesafe_expanded_executable_gate.step);
    const run_uncurated_air_releasesafe_broad_object_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_broad_object_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_broad_object_gate.addArg("--corpus=broad");
    run_uncurated_air_releasesafe_broad_object_gate.addArg("--object-progress");
    const uncurated_air_releasesafe_broad_object_step = b.step("distribution-zig-air-uncurated-releasesafe-broad-object", "Emit z_llvm ELF objects for broad uncurated x86_64 ReleaseSafe Zig AIR progress accounting");
    uncurated_air_releasesafe_broad_object_step.dependOn(&run_uncurated_air_releasesafe_broad_object_gate.step);
    const run_uncurated_air_releasesafe_broad_object_inspection_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_broad_object_inspection_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_broad_object_inspection_gate.addArg("--corpus=broad");
    run_uncurated_air_releasesafe_broad_object_inspection_gate.addArg("--object-inspection");
    const uncurated_air_releasesafe_broad_object_inspection_step = b.step("distribution-zig-air-uncurated-releasesafe-broad-object-inspection", "Inspect broad uncurated x86_64 ReleaseSafe real-AIR ELF objects with readelf/objdump");
    uncurated_air_releasesafe_broad_object_inspection_step.dependOn(&run_uncurated_air_releasesafe_broad_object_inspection_gate.step);
    const run_uncurated_air_releasesafe_broad_executable_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_broad_executable_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_broad_executable_gate.addArg("--corpus=broad");
    run_uncurated_air_releasesafe_broad_executable_gate.addArg("--executable-progress");
    const uncurated_air_releasesafe_broad_executable_step = b.step("distribution-zig-air-uncurated-releasesafe-broad-executable", "Run stable C-ABI executable probes for broad uncurated x86_64 ReleaseSafe real-AIR objects");
    uncurated_air_releasesafe_broad_executable_step.dependOn(&run_uncurated_air_releasesafe_broad_executable_gate.step);
    const run_uncurated_air_releasesmall_broad_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_broad_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_broad_gate.addArg("--corpus=broad");
    const uncurated_air_releasesmall_broad_step = b.step("distribution-zig-air-uncurated-releasesmall-broad", "Discover and generically lower broad uncurated x86_64 ReleaseSmall Zig AIR progress");
    uncurated_air_releasesmall_broad_step.dependOn(&run_uncurated_air_releasesmall_broad_gate.step);
    const run_uncurated_air_releasesmall_expanded_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_expanded_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_expanded_gate.addArg("--corpus=expanded");
    const uncurated_air_releasesmall_expanded_step = b.step("distribution-zig-air-uncurated-releasesmall-expanded", "Discover and lower the expanded x86_64 ReleaseSmall Zig AIR frontier corpus");
    uncurated_air_releasesmall_expanded_step.dependOn(&run_uncurated_air_releasesmall_expanded_gate.step);
    const run_uncurated_air_releasesmall_scale_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_scale_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_scale_gate.addArg("--corpus=scale");
    run_uncurated_air_releasesmall_scale_gate.addArg("--object-progress");
    const uncurated_air_releasesmall_scale_step = b.step("distribution-zig-air-uncurated-releasesmall-scale", "Discover, lower, and emit objects for the scale x86_64 ReleaseSmall Zig AIR frontier corpus");
    uncurated_air_releasesmall_scale_step.dependOn(&run_uncurated_air_releasesmall_scale_gate.step);
    const run_uncurated_air_releasesmall_scale_object_inspection_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_scale_object_inspection_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_scale_object_inspection_gate.addArg("--corpus=scale");
    run_uncurated_air_releasesmall_scale_object_inspection_gate.addArg("--object-inspection");
    const uncurated_air_releasesmall_scale_object_inspection_step = b.step("distribution-zig-air-uncurated-releasesmall-scale-object-inspection", "Inspect scale uncurated x86_64 ReleaseSmall real-AIR ELF objects with readelf/objdump");
    uncurated_air_releasesmall_scale_object_inspection_step.dependOn(&run_uncurated_air_releasesmall_scale_object_inspection_gate.step);
    const run_uncurated_air_releasesmall_scale_native_link_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_scale_native_link_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_scale_native_link_gate.addArg("--corpus=scale");
    run_uncurated_air_releasesmall_scale_native_link_gate.addArg("--native-link-progress");
    const uncurated_air_releasesmall_scale_native_link_step = b.step("distribution-zig-air-uncurated-releasesmall-scale-native-link", "Link scale uncurated x86_64 ReleaseSmall real-AIR objects with Zig native linker progress accounting");
    uncurated_air_releasesmall_scale_native_link_step.dependOn(&run_uncurated_air_releasesmall_scale_native_link_gate.step);
    const run_uncurated_air_releasesmall_scale_executable_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_scale_executable_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_scale_executable_gate.addArg("--corpus=scale");
    run_uncurated_air_releasesmall_scale_executable_gate.addArg("--executable-progress");
    const uncurated_air_releasesmall_scale_executable_step = b.step("distribution-zig-air-uncurated-releasesmall-scale-executable", "Run stable C-ABI executable probes for scale uncurated x86_64 ReleaseSmall real-AIR objects");
    uncurated_air_releasesmall_scale_executable_step.dependOn(&run_uncurated_air_releasesmall_scale_executable_gate.step);
    const run_uncurated_air_releasesmall_frontier_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_frontier_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_frontier_gate.addArg("--corpus=frontier");
    run_uncurated_air_releasesmall_frontier_gate.addArg("--object-progress");
    const uncurated_air_releasesmall_frontier_step = b.step("distribution-zig-air-uncurated-releasesmall-frontier", "Discover, lower, and emit objects for the frontier x86_64 ReleaseSmall Zig AIR corpus");
    uncurated_air_releasesmall_frontier_step.dependOn(&run_uncurated_air_releasesmall_frontier_gate.step);
    const run_uncurated_air_releasesmall_frontier_object_inspection_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_frontier_object_inspection_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_frontier_object_inspection_gate.addArg("--corpus=frontier");
    run_uncurated_air_releasesmall_frontier_object_inspection_gate.addArg("--object-inspection");
    const uncurated_air_releasesmall_frontier_object_inspection_step = b.step("distribution-zig-air-uncurated-releasesmall-frontier-object-inspection", "Inspect frontier uncurated x86_64 ReleaseSmall real-AIR ELF objects with readelf/objdump");
    uncurated_air_releasesmall_frontier_object_inspection_step.dependOn(&run_uncurated_air_releasesmall_frontier_object_inspection_gate.step);
    const run_uncurated_air_releasesmall_frontier_native_link_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_frontier_native_link_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_frontier_native_link_gate.addArg("--corpus=frontier");
    run_uncurated_air_releasesmall_frontier_native_link_gate.addArg("--native-link-progress");
    const uncurated_air_releasesmall_frontier_native_link_step = b.step("distribution-zig-air-uncurated-releasesmall-frontier-native-link", "Link frontier uncurated x86_64 ReleaseSmall real-AIR objects with Zig native linker progress accounting");
    uncurated_air_releasesmall_frontier_native_link_step.dependOn(&run_uncurated_air_releasesmall_frontier_native_link_gate.step);
    const run_uncurated_air_releasesmall_frontier_executable_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_frontier_executable_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_frontier_executable_gate.addArg("--corpus=frontier");
    run_uncurated_air_releasesmall_frontier_executable_gate.addArg("--executable-progress");
    const uncurated_air_releasesmall_frontier_executable_step = b.step("distribution-zig-air-uncurated-releasesmall-frontier-executable", "Run stable C-ABI executable probes for frontier uncurated x86_64 ReleaseSmall real-AIR objects");
    uncurated_air_releasesmall_frontier_executable_step.dependOn(&run_uncurated_air_releasesmall_frontier_executable_gate.step);
    const run_uncurated_air_releasesmall_expanded_object_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_expanded_object_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_expanded_object_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasesmall_expanded_object_gate.addArg("--object-progress");
    const uncurated_air_releasesmall_expanded_object_step = b.step("distribution-zig-air-uncurated-releasesmall-expanded-object", "Emit z_llvm ELF objects for expanded uncurated x86_64 ReleaseSmall Zig AIR progress accounting");
    uncurated_air_releasesmall_expanded_object_step.dependOn(&run_uncurated_air_releasesmall_expanded_object_gate.step);
    const run_uncurated_air_releasesmall_expanded_object_inspection_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_expanded_object_inspection_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_expanded_object_inspection_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasesmall_expanded_object_inspection_gate.addArg("--object-inspection");
    const uncurated_air_releasesmall_expanded_object_inspection_step = b.step("distribution-zig-air-uncurated-releasesmall-expanded-object-inspection", "Inspect expanded uncurated x86_64 ReleaseSmall real-AIR ELF objects with readelf/objdump");
    uncurated_air_releasesmall_expanded_object_inspection_step.dependOn(&run_uncurated_air_releasesmall_expanded_object_inspection_gate.step);
    const run_uncurated_air_releasesmall_expanded_native_link_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_expanded_native_link_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_expanded_native_link_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasesmall_expanded_native_link_gate.addArg("--native-link-progress");
    const uncurated_air_releasesmall_expanded_native_link_step = b.step("distribution-zig-air-uncurated-releasesmall-expanded-native-link", "Link expanded uncurated x86_64 ReleaseSmall real-AIR objects with Zig native linker progress accounting");
    uncurated_air_releasesmall_expanded_native_link_step.dependOn(&run_uncurated_air_releasesmall_expanded_native_link_gate.step);
    const run_uncurated_air_releasesmall_expanded_executable_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_expanded_executable_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_expanded_executable_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasesmall_expanded_executable_gate.addArg("--executable-progress");
    const uncurated_air_releasesmall_expanded_executable_step = b.step("distribution-zig-air-uncurated-releasesmall-expanded-executable", "Run stable C-ABI executable probes for expanded uncurated x86_64 ReleaseSmall real-AIR objects");
    uncurated_air_releasesmall_expanded_executable_step.dependOn(&run_uncurated_air_releasesmall_expanded_executable_gate.step);
    const run_uncurated_air_releasesmall_broad_object_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_broad_object_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_broad_object_gate.addArg("--corpus=broad");
    run_uncurated_air_releasesmall_broad_object_gate.addArg("--object-progress");
    const uncurated_air_releasesmall_broad_object_step = b.step("distribution-zig-air-uncurated-releasesmall-broad-object", "Emit z_llvm ELF objects for broad uncurated x86_64 ReleaseSmall Zig AIR progress accounting");
    uncurated_air_releasesmall_broad_object_step.dependOn(&run_uncurated_air_releasesmall_broad_object_gate.step);
    const run_uncurated_air_releasesmall_broad_object_inspection_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_broad_object_inspection_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_broad_object_inspection_gate.addArg("--corpus=broad");
    run_uncurated_air_releasesmall_broad_object_inspection_gate.addArg("--object-inspection");
    const uncurated_air_releasesmall_broad_object_inspection_step = b.step("distribution-zig-air-uncurated-releasesmall-broad-object-inspection", "Inspect broad uncurated x86_64 ReleaseSmall real-AIR ELF objects with readelf/objdump");
    uncurated_air_releasesmall_broad_object_inspection_step.dependOn(&run_uncurated_air_releasesmall_broad_object_inspection_gate.step);
    const run_uncurated_air_releasesmall_broad_native_link_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_broad_native_link_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_broad_native_link_gate.addArg("--corpus=broad");
    run_uncurated_air_releasesmall_broad_native_link_gate.addArg("--native-link-progress");
    const uncurated_air_releasesmall_broad_native_link_step = b.step("distribution-zig-air-uncurated-releasesmall-broad-native-link", "Link broad uncurated x86_64 ReleaseSmall real-AIR objects with Zig native linker progress accounting");
    uncurated_air_releasesmall_broad_native_link_step.dependOn(&run_uncurated_air_releasesmall_broad_native_link_gate.step);
    const run_uncurated_air_releasesmall_broad_executable_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_broad_executable_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_broad_executable_gate.addArg("--corpus=broad");
    run_uncurated_air_releasesmall_broad_executable_gate.addArg("--executable-progress");
    const uncurated_air_releasesmall_broad_executable_step = b.step("distribution-zig-air-uncurated-releasesmall-broad-executable", "Run stable C-ABI executable probes for broad uncurated x86_64 ReleaseSmall real-AIR objects");
    uncurated_air_releasesmall_broad_executable_step.dependOn(&run_uncurated_air_releasesmall_broad_executable_gate.step);
    const run_uncurated_air_releasefast_broad_finish_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_broad_finish_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_broad_finish_gate.addArg("--corpus=broad");
    run_uncurated_air_releasefast_broad_finish_gate.addArg("--object-progress");
    run_uncurated_air_releasefast_broad_finish_gate.addArg("--strict-finish");
    const run_uncurated_air_releasesafe_broad_finish_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_broad_finish_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_broad_finish_gate.addArg("--corpus=broad");
    run_uncurated_air_releasesafe_broad_finish_gate.addArg("--object-progress");
    run_uncurated_air_releasesafe_broad_finish_gate.addArg("--strict-finish");
    const run_uncurated_air_releasesmall_broad_finish_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_broad_finish_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_broad_finish_gate.addArg("--corpus=broad");
    run_uncurated_air_releasesmall_broad_finish_gate.addArg("--object-progress");
    run_uncurated_air_releasesmall_broad_finish_gate.addArg("--strict-finish");
    const uncurated_air_release_broad_finish_step = b.step("distribution-zig-air-uncurated-release-broad-finish", "Strict finish-line gate for broad x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall typed AIR v2 ownership and object emission");
    uncurated_air_release_broad_finish_step.dependOn(&run_uncurated_air_releasefast_broad_finish_gate.step);
    uncurated_air_release_broad_finish_step.dependOn(&run_uncurated_air_releasesafe_broad_finish_gate.step);
    uncurated_air_release_broad_finish_step.dependOn(&run_uncurated_air_releasesmall_broad_finish_gate.step);
    const run_uncurated_air_releasefast_expanded_finish_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_expanded_finish_gate.addArg("--mode=ReleaseFast");
    run_uncurated_air_releasefast_expanded_finish_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasefast_expanded_finish_gate.addArg("--object-progress");
    run_uncurated_air_releasefast_expanded_finish_gate.addArg("--strict-finish");
    const run_uncurated_air_releasesafe_expanded_finish_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_expanded_finish_gate.addArg("--mode=ReleaseSafe");
    run_uncurated_air_releasesafe_expanded_finish_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasesafe_expanded_finish_gate.addArg("--object-progress");
    run_uncurated_air_releasesafe_expanded_finish_gate.addArg("--strict-finish");
    const run_uncurated_air_releasesmall_expanded_finish_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_expanded_finish_gate.addArg("--mode=ReleaseSmall");
    run_uncurated_air_releasesmall_expanded_finish_gate.addArg("--corpus=expanded");
    run_uncurated_air_releasesmall_expanded_finish_gate.addArg("--object-progress");
    run_uncurated_air_releasesmall_expanded_finish_gate.addArg("--strict-finish");
    const uncurated_air_release_expanded_finish_step = b.step("distribution-zig-air-uncurated-release-expanded-finish", "Strict finish-line gate for expanded x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall typed AIR v2 ownership and object emission");
    uncurated_air_release_expanded_finish_step.dependOn(&run_uncurated_air_releasefast_expanded_finish_gate.step);
    uncurated_air_release_expanded_finish_step.dependOn(&run_uncurated_air_releasesafe_expanded_finish_gate.step);
    uncurated_air_release_expanded_finish_step.dependOn(&run_uncurated_air_releasesmall_expanded_finish_gate.step);
    const uncurated_air_release_scale_step = b.step("distribution-zig-air-uncurated-release-scale", "Run scale x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall typed AIR frontier object-progress gates");
    uncurated_air_release_scale_step.dependOn(&run_uncurated_air_releasefast_scale_gate.step);
    uncurated_air_release_scale_step.dependOn(&run_uncurated_air_releasesafe_scale_gate.step);
    uncurated_air_release_scale_step.dependOn(&run_uncurated_air_releasesmall_scale_gate.step);
    const uncurated_air_release_frontier_step = b.step("distribution-zig-air-uncurated-release-frontier", "Run frontier x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall typed AIR object-progress gates");
    uncurated_air_release_frontier_step.dependOn(&run_uncurated_air_releasefast_frontier_gate.step);
    uncurated_air_release_frontier_step.dependOn(&run_uncurated_air_releasesafe_frontier_gate.step);
    uncurated_air_release_frontier_step.dependOn(&run_uncurated_air_releasesmall_frontier_gate.step);
    const run_uncurated_air_releasesafe_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesafe_gate.addArg("--mode=ReleaseSafe");
    const uncurated_air_releasesafe_step = b.step("distribution-zig-air-uncurated-releasesafe", "Discover and generically lower uncurated x86_64 ReleaseSafe Zig AIR");
    uncurated_air_releasesafe_step.dependOn(&run_uncurated_air_releasesafe_gate.step);
    const run_uncurated_air_releasesmall_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasesmall_gate.addArg("--mode=ReleaseSmall");
    const uncurated_air_releasesmall_step = b.step("distribution-zig-air-uncurated-releasesmall", "Discover and generically lower uncurated x86_64 ReleaseSmall Zig AIR");
    uncurated_air_releasesmall_step.dependOn(&run_uncurated_air_releasesmall_gate.step);
    const run_uncurated_air_releasefast_gate = b.addRunArtifact(uncurated_air_gate);
    run_uncurated_air_releasefast_gate.addArg("--mode=ReleaseFast");
    const uncurated_air_release_step = b.step("distribution-zig-air-uncurated-release", "Run uncurated x86_64 release Zig AIR gates for ReleaseFast, ReleaseSafe, and ReleaseSmall");
    uncurated_air_release_step.dependOn(&run_uncurated_air_releasefast_gate.step);
    uncurated_air_release_step.dependOn(&run_uncurated_air_releasesafe_gate.step);
    uncurated_air_release_step.dependOn(&run_uncurated_air_releasesmall_gate.step);
    addToolStep(b, "distribution-native-link-boundary2", "Run broad x86_64 native-link boundary accounting gate", "tools/run_distribution_native_link_boundary2.zig");
    addToolStepWithArgs(b, "probe-native-linker", "Probe selected local objects against Zig native linker acceptance", "tools/probe_native_linker_compatibility.zig");
    addToolStepWithArgs(b, "probe-native-linker-broad", "Probe broad optimized IR directories for native Zig linker link-only acceptance", "tools/probe_native_linker_broad.zig");
    addToolStepWithFixedArgs(b, "distribution-native-link-releasefast", "Run selected ReleaseFast native Zig linker handoff gates", "tools/run_distribution_native_link_m5.zig", &.{"--mode=ReleaseFast"});
    addToolStepWithFixedArgs(b, "distribution-native-link-releasesafe", "Run selected ReleaseSafe native Zig linker handoff gates", "tools/run_distribution_native_link_m5.zig", &.{"--mode=ReleaseSafe"});
    addToolStepWithFixedArgs(b, "distribution-native-link-releasesmall", "Run selected ReleaseSmall native Zig linker handoff gates", "tools/run_distribution_native_link_m5.zig", &.{"--mode=ReleaseSmall"});
    addToolStepWithFixedArgs(b, "distribution-native-link-debug", "Run selected Debug native Zig linker handoff gates", "tools/run_distribution_native_link_m5.zig", &.{"--mode=Debug"});
    addToolStepWithFixedArgs(b, "probe-native-linker-releasefast", "Probe selected ReleaseFast objects against Zig native linker acceptance", "tools/probe_native_linker_compatibility.zig", &.{"--mode=ReleaseFast"});
    addToolStepWithFixedArgs(b, "probe-native-linker-releasesafe", "Probe selected ReleaseSafe objects against Zig native linker acceptance", "tools/probe_native_linker_compatibility.zig", &.{"--mode=ReleaseSafe"});
    addToolStepWithFixedArgs(b, "probe-native-linker-releasesmall", "Probe selected ReleaseSmall objects against Zig native linker acceptance", "tools/probe_native_linker_compatibility.zig", &.{"--mode=ReleaseSmall"});
    addToolStepWithFixedArgs(b, "probe-native-linker-debug", "Probe selected Debug objects against Zig native linker acceptance", "tools/probe_native_linker_compatibility.zig", &.{"--mode=Debug"});
    addToolStepWithFixedArgs(b, "distribution-musl-object", "Run selected x86_64 musl object subset gates", "tools/run_distribution_x86_64_musl_subset.zig", &.{"--mode=object"});
    addToolStepWithFixedArgs(b, "distribution-musl-executable", "Run selected x86_64 musl executable subset gates", "tools/run_distribution_x86_64_musl_subset.zig", &.{"--mode=executable"});
    addToolStepWithArgs(b, "probe-distribution-objects", "Run object-probe automation; pass arguments after --", "tools/probe_distribution_objects.zig");
    addToolStepWithArgs(b, "capture-zig-ir", "Capture Zig-emitted LLVM IR; pass arguments after --", "tools/capture_zig_ir.zig");
}

fn addToolStep(b: *std.Build, name: []const u8, description: []const u8, tool: []const u8) void {
    const run_cmd = b.addSystemCommand(&.{ "zig", "run", tool });
    const step = b.step(name, description);
    step.dependOn(&run_cmd.step);
}

fn addToolStepWithFixedArgs(
    b: *std.Build,
    name: []const u8,
    description: []const u8,
    tool: []const u8,
    args: []const []const u8,
) void {
    const run_cmd = b.addSystemCommand(&.{ "zig", "run", tool, "--" });
    run_cmd.addArgs(args);
    const step = b.step(name, description);
    step.dependOn(&run_cmd.step);
}

fn addToolStepWithArgs(b: *std.Build, name: []const u8, description: []const u8, tool: []const u8) void {
    const run_cmd = b.addSystemCommand(&.{ "zig", "run", tool, "--" });
    if (b.args) |args| run_cmd.addArgs(args);
    const step = b.step(name, description);
    step.dependOn(&run_cmd.step);
}

fn addToolStepWithFixedAndUserArgs(
    b: *std.Build,
    name: []const u8,
    description: []const u8,
    tool: []const u8,
    fixed_args: []const []const u8,
) void {
    const run_cmd = b.addSystemCommand(&.{ "zig", "run", tool, "--" });
    run_cmd.addArgs(fixed_args);
    if (b.args) |args| run_cmd.addArgs(args);
    const step = b.step(name, description);
    step.dependOn(&run_cmd.step);
}
