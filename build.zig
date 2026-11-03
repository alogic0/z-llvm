const std = @import("std");
const builtin = @import("builtin");

comptime {
    if (!std.mem.eql(u8, builtin.zig_version_string, std.mem.trim(u8, @embedFile(".zigversion"), "\r\n")))
        @compileError("z_llvm requires Zig 0.17.0; invoke that compiler explicitly (see README.md)");
}

pub fn build(b: *std.Build) void {
    // Nested tool invocations inherit the same project compiler. The patched
    // emitter remains independently selected through ZIG_EMITTER/ZIG_SOURCE_DIR.
    b.graph.environ_map.put("PATH", b.fmt("{s}:{s}", .{
        std.fs.path.dirname(b.graph.zig_exe) orelse ".",
        b.graph.environ_map.get("PATH") orelse "/usr/bin:/bin",
    })) catch @panic("out of memory");
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const regex_probe = b.addExecutable(.{ .name = "tool-regex-probe", .root_module = b.createModule(.{
        .root_source_file = b.path("tools/tool_regex_probe.zig"),
        .target = b.graph.host,
        .optimize = optimize,
    }) });
    const regex_options = b.addOptions();
    regex_options.addOptionPath("probe", regex_probe.getEmittedBin());
    const regex_tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("tools/tool_regex_test.zig"),
        .target = b.graph.host,
        .optimize = optimize,
    }) });
    regex_tests.root_module.addOptions("test_options", regex_options);
    const run_regex_tests = b.addRunArtifact(regex_tests);
    run_regex_tests.has_side_effects = true;
    const verify_regex = b.addSystemCommand(&.{ "sha256sum", "--check", "tools/vendor/regex.SHA256SUMS" });
    verify_regex.setCwd(b.path("."));
    run_regex_tests.step.dependOn(&verify_regex.step);
    b.step("verify-regex-source", "Verify the pinned public regex source snapshot").dependOn(&verify_regex.step);
    b.step("test-tool-regex", "Check production regex assertions through owned child processes").dependOn(&run_regex_tests.step);

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
    run_cmd.addPassthruArgs();

    const run_step = b.step("run", "Run the z_llvm tool");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .filters = b.option([]const []const u8, "test-filter", "Run matching unit tests") orelse &.{},
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const test_step = b.step("test", "Run unit tests");
    const unit_run = b.addRunArtifact(unit_tests);
    test_step.dependOn(&unit_run.step);
    const test_unit_step = b.step("test-unit", "Run isolated compiler unit tests without external integration tools");
    test_unit_step.dependOn(&unit_run.step);

    const abi_diff_run = b.addSystemCommand(&.{ "bash", "tools/run_abi_differential.sh" });
    abi_diff_run.step.dependOn(b.getInstallStep());
    const abi_diff_step = b.step("abi-differential", "Run mandatory audited compiler-rt ABI differential gate");
    abi_diff_step.dependOn(&abi_diff_run.step);
    test_step.dependOn(&abi_diff_run.step);

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
    addToolStep(b, "optimizer-correctness", "Execute optimizer regressions against LLVM 22", "tools/run_optimizer_correctness.zig");
    addToolStepWithFixedArgs(b, "compare-codegen-asm", "Compare generated x86_64 assembly fixtures", "tools/compare_codegen.zig", &.{"--mode=asm"});
    addToolStepWithFixedArgs(b, "compare-codegen-objdump", "Compare generated x86_64 object disassembly fixtures", "tools/compare_codegen.zig", &.{"--mode=objdump"});
    addToolStepWithFixedArgs(b, "compare-codegen-readelf", "Compare generated x86_64 object symbol and relocation fixtures", "tools/compare_codegen.zig", &.{"--mode=readelf"});
    addToolStepWithArgs(b, "lint-zig-ir-manifest", "Lint the Zig IR fixture manifest; pass optional args after --", "tools/lint_zig_ir_manifest.zig");
    addToolStepWithArgs(b, "zig-corpus", "Run accepted Zig IR corpus rows; pass optional manifest after --", "tools/run_zig_corpus.zig");
    addToolStep(b, "generated-scalar-diff", "Run generated scalar differential checks", "tools/run_generated_scalar_diff.zig");
    addToolStep(b, "memset-diff", "Execute retained memset family and compositions against LLVM", "tools/run_memset_diff.zig");
    addToolStep(b, "byte-loops-diff", "Execute checked strncpy and scalar byte loops against LLVM", "tools/run_byte_loops_diff.zig");
    addToolStep(b, "memcpy-diff", "Execute retained checked memcpy and compositions against LLVM", "tools/run_memcpy_diff.zig");
    addToolStepWithArgs(b, "behavioral-diff", "Execute composed programs against an independent LLVM reference", "tools/run_behavioral_diff.zig");
    const real_program_run = b.addSystemCommand(&.{ "python3", "tools/run_real_program.py" });
    real_program_run.step.dependOn(b.getInstallStep());
    real_program_run.addPassthruArgs();
    b.step("real-program", "Compare an unchanged pinned upstream Zig program with local optimizer and codegen").dependOn(&real_program_run.step);
    const upstream_c_run = b.addSystemCommand(&.{ "python3", "tools/run_upstream_c_program.py" });
    upstream_c_run.step.dependOn(b.getInstallStep());
    upstream_c_run.addPassthruArgs();
    b.step("upstream-c-program", "Compare the unchanged upstream C fixture and integer-varargs native canary").dependOn(&upstream_c_run.step);
    addToolStepWithArgs(b, "check-docs", "Validate current documentation links and accepted status", "tools/check_project_docs.zig");
    addToolStep(b, "check-zig-stage4-emitter", "Check the authoritative Zig stage4 emitter", "tools/check_zig_stage4_emitter.zig");
    addToolStep(b, "focused-codegen-canaries", "Run procedural fma and __multi3 codegen canaries (non-gating)", "tools/run_focused_codegen_canaries.zig");
    addToolStepWithArgs(b, "real-candidates-v2", "Build the mode-stable real-row candidate denominator", "tools/build_real_candidates_v2.zig");
    const candidates_v3_run = b.addSystemCommand(&.{ "python3", "tools/build_real_candidates_v3.py" });
    candidates_v3_run.addPassthruArgs();
    b.step("real-candidates-v3", "Derive the audited current-pin candidate population").dependOn(&candidates_v3_run.step);
    const real_policy_tests = b.addSystemCommand(&.{ "python3", "-m", "unittest", "discover", "-s", "tools", "-p", "test_real_*.py" });
    b.step("real-program-policy-tests", "Check candidate admission and object provenance negative controls").dependOn(&real_policy_tests.step);
    const derive_real_candidate_definition_run = b.addSystemCommand(&.{
        b.graph.zig_exe,
        "run",
        "tools/derive_real_candidate_definition.zig",
        "--",
    });
    derive_real_candidate_definition_run.addPassthruArgs();
    const derive_real_candidate_definition_step = b.step(
        "derive-real-candidate-definition",
        "Derive the pinned rank-2 definition mapping sidecar",
    );
    derive_real_candidate_definition_step.dependOn(&derive_real_candidate_definition_run.step);
    const real_candidate_definition_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/derive_real_candidate_definition.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const real_candidate_definition_test_step = b.step(
        "test-real-candidate-definition-mapper",
        "Run the pure-Zig rank-2 definition mapper tests",
    );
    real_candidate_definition_test_step.dependOn(&b.addRunArtifact(real_candidate_definition_tests).step);
    const inbox206_cn_acceptance_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/zllvm_inbox206/cn_acceptance.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const inbox206_cn_acceptance_test_step = b.step(
        "test-inbox206-cn-acceptance-runner",
        "Run the private combined CN acceptance-runner synthetic tests",
    );
    inbox206_cn_acceptance_test_step.dependOn(&b.addRunArtifact(inbox206_cn_acceptance_tests).step);
    const inbox206_cn_acceptance = b.addExecutable(.{
        .name = "zllvm-inbox206-cn-acceptance",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/zllvm_inbox206/cn_acceptance.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const inbox206_cn_acceptance_step = b.step(
        "inbox206-cn-acceptance",
        "Run the non-default combined CN acceptance runner",
    );
    const inbox206_cn_acceptance_run = b.addRunArtifact(inbox206_cn_acceptance);
    inbox206_cn_acceptance_run.addPassthruArgs();
    inbox206_cn_acceptance_step.dependOn(&inbox206_cn_acceptance_run.step);
    const inbox206_cn_acceptance_check_step = b.step(
        "check-inbox206-cn-acceptance-runner",
        "Compile the combined CN acceptance runner without executing it",
    );
    inbox206_cn_acceptance_check_step.dependOn(&inbox206_cn_acceptance.step);
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
    addToolStepWithArgs(b, "distribution-all", "Run selected distribution gates, native-link proof/probe, and boundary gates", "tools/run_distribution_all_gates.zig");
    addToolStepWithArgs(b, "distribution-real-rows", "Run ranked real compiler-core rows through staged replacement gate", "tools/run_distribution_real_rows.zig");
    const execution_oracle_v1 = b.addExecutable(.{
        .name = "execution-oracle-v1",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/execution_oracle_v1.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const execution_oracle_v1_run = b.addRunArtifact(execution_oracle_v1);
    execution_oracle_v1_run.addPassthruArgs();
    const execution_oracle_v1_step = b.step(
        "execution-oracle-v1",
        "Run the non-default current-pin one-row execution oracle",
    );
    execution_oracle_v1_step.dependOn(&execution_oracle_v1_run.step);
    const execution_oracle_v1_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/execution_oracle_v1.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const execution_oracle_v1_test_step = b.step(
        "test-execution-oracle-v1",
        "Run focused synthetic execution-oracle-v1 tests",
    );
    execution_oracle_v1_test_step.dependOn(&b.addRunArtifact(execution_oracle_v1_tests).step);
    const artifact_store_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/zllvm_artifact_store.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const artifact_store_test_step = b.step(
        "artifact-store-test",
        "Run isolated artifact-store integrity tests",
    );
    artifact_store_test_step.dependOn(&b.addRunArtifact(artifact_store_tests).step);
    addToolStepWithArgs(b, "artifact-store", "Publish, verify, retrieve, or collect artifacts", "tools/zllvm_artifact_store.zig");
    const inbox206_descriptor_identity_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/zllvm_inbox206_materialize.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const inbox206_descriptor_identity_test_step = b.step(
        "test-inbox206-descriptor-identity",
        "Run the private INBOX-206 descriptor identity tests",
    );
    const inbox206_descriptor_identity_test_run = b.addRunArtifact(inbox206_descriptor_identity_tests);
    inbox206_descriptor_identity_test_step.dependOn(&inbox206_descriptor_identity_test_run.step);
    const inbox206_path_b_child = b.addExecutable(.{
        .name = "zllvm-inbox206-path-b-synthetic-child",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/zllvm_inbox206_materialize.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const inbox206_path_b_run = b.addRunArtifact(inbox206_path_b_child);
    inbox206_path_b_run.addArg("--path-b-self-test");
    const inbox206_path_b_step = b.step(
        "test-inbox206-path-b-real-process",
        "Run private INBOX-206 tests and the Path-B standard-process synthetic receipt slice",
    );
    inbox206_path_b_step.dependOn(&inbox206_descriptor_identity_test_run.step);
    inbox206_path_b_step.dependOn(&inbox206_path_b_run.step);
    addToolStepWithArgs(b, "stage2-pressure-diagnostic", "Write generic-CFG stage-two pressure diagnostics for one IR function", "src/stage2_pressure_diagnostic.zig");
    addToolStep(b, "distribution-no-llvm", "Run the selected no-LLVM-codegen distribution subset", "tools/run_distribution_no_llvm_codegen_subset.zig");
    addToolStep(b, "distribution-boundary", "Run conservative distribution boundary gates", "tools/run_distribution_boundary_gates.zig");
    addToolStepWithArgs(b, "distribution-native-link", "Run selected native Zig linker handoff gates", "tools/run_distribution_native_link_m5.zig");
    addToolStepWithArgs(b, "distribution-native-link-object-inspection", "Inspect z_llvm ELF objects before Zig native linker handoff", "tools/run_native_link_object_inspection.zig");
    addToolStep(b, "distribution-zig-source-native-link", "Run selected Zig source to z_llvm object to native-link executable gate", "tools/run_distribution_zig_source_native_link.zig");
    addToolStep(b, "distribution-zig-integrated-object", "Run patched Zig integrated z_llvm object-emission gate", "tools/run_distribution_zig_integrated_object.zig");
    addToolStepWithArgs(b, "distribution-zig-integrated-exe", "Run patched Zig integrated z_llvm executable syscall gate", "tools/run_distribution_zig_integrated_exe.zig");
    addToolStepWithFixedAndUserArgs(b, "distribution-zig-integrated-preopt", "Run patched Zig integrated preopt z_llvm optimizer/object-emission gate", "tools/run_distribution_zig_integrated_object.zig", &.{"--pipeline=preopt"});
    addToolStepWithFixedAndUserArgs(b, "distribution-zig-ir-writer-tiny-scalar", "Run the first selected Zig-owned textual IR writer gate", "tools/run_distribution_zig_integrated_object.zig", &.{ "--ir-writer", "--case=releasefast_tiny_scalar" });
    addToolStepWithFixedAndUserArgs(b, "distribution-zig-ir-writer", "Run selected Zig-owned textual IR writer integration gate", "tools/run_distribution_zig_integrated_object.zig", &.{"--ir-writer"});
    addToolStep(b, "distribution-x86_64-selected-zllvm", "Run compact selected x86_64 z_llvm replacement gate", "tools/run_distribution_x86_64_selected_zllvm.zig");
    addToolStepWithFixedAndUserArgs(b, "distribution-x86_64-source-backed-structured", "Run broad x86_64 release source-backed structured-direct gate", "tools/run_distribution_zig_integrated_object.zig", &.{"--source-backed-broad"});
    addToolStepWithFixedAndUserArgs(b, "distribution-zig-source-structured-direct", "Run x86_64 release source-wrapper structured-direct gate without case-id ownership", "tools/run_distribution_zig_integrated_object.zig", &.{"--source-wrapper-dispatch"});
    addToolStepWithFixedAndUserArgs(b, "distribution-x86_64-release-source-owned", "Run x86_64 release source-owned semantic structured-direct gate", "tools/run_distribution_zig_integrated_object.zig", &.{"--release-source-owned"});
    const distribution_zig_air_inventory = b.addExecutable(.{
        .name = "distribution_zig_air_inventory",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/distribution_zig_air_inventory.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const distribution_zig_air_inventory_step = b.step(
        "distribution-zig-air-inventory",
        "Inventory x86_64 release Zig distribution AIR visibility without requiring lowering or codegen",
    );
    const distribution_zig_air_inventory_run = b.addRunArtifact(distribution_zig_air_inventory);
    distribution_zig_air_inventory_run.addPassthruArgs();
    distribution_zig_air_inventory_step.dependOn(&distribution_zig_air_inventory_run.step);
    const uncurated_air_gate = b.addExecutable(.{
        .name = "uncurated_air_gate",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/uncurated_air_gate.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });

    const uncurated_air_specs = [_]UncuratedAirGateSpec{
        .{ .name = "distribution-zig-air-uncurated-releasefast", .description = "Discover and generically lower uncurated x86_64 ReleaseFast Zig AIR" },
        .{ .name = "distribution-zig-air-uncurated-releasesafe", .description = "Discover and generically lower uncurated x86_64 ReleaseSafe Zig AIR", .mode = .ReleaseSafe },
        .{ .name = "distribution-zig-air-uncurated-releasesmall", .description = "Discover and generically lower uncurated x86_64 ReleaseSmall Zig AIR", .mode = .ReleaseSmall },

        .{ .name = "distribution-zig-air-uncurated-releasefast-broad", .description = "Discover and generically lower broad uncurated x86_64 ReleaseFast Zig AIR", .mode = .ReleaseFast, .corpus = .broad },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-broad", .description = "Discover and generically lower broad uncurated x86_64 ReleaseSafe Zig AIR progress", .mode = .ReleaseSafe, .corpus = .broad },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-broad", .description = "Discover and generically lower broad uncurated x86_64 ReleaseSmall Zig AIR progress", .mode = .ReleaseSmall, .corpus = .broad },
        .{ .name = "distribution-zig-air-uncurated-releasefast-broad-object", .description = "Emit z_llvm ELF objects for broad uncurated x86_64 ReleaseFast Zig AIR progress accounting", .mode = .ReleaseFast, .corpus = .broad, .variant = .object_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-broad-object", .description = "Emit z_llvm ELF objects for broad uncurated x86_64 ReleaseSafe Zig AIR progress accounting", .mode = .ReleaseSafe, .corpus = .broad, .variant = .object_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-broad-object", .description = "Emit z_llvm ELF objects for broad uncurated x86_64 ReleaseSmall Zig AIR progress accounting", .mode = .ReleaseSmall, .corpus = .broad, .variant = .object_progress },
        .{ .name = "distribution-zig-air-uncurated-releasefast-broad-object-inspection", .description = "Inspect broad uncurated x86_64 ReleaseFast real-AIR ELF objects with readelf/objdump", .mode = .ReleaseFast, .corpus = .broad, .variant = .object_inspection },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-broad-object-inspection", .description = "Inspect broad uncurated x86_64 ReleaseSafe real-AIR ELF objects with readelf/objdump", .mode = .ReleaseSafe, .corpus = .broad, .variant = .object_inspection },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-broad-object-inspection", .description = "Inspect broad uncurated x86_64 ReleaseSmall real-AIR ELF objects with readelf/objdump", .mode = .ReleaseSmall, .corpus = .broad, .variant = .object_inspection },
        .{ .name = "distribution-zig-air-uncurated-releasefast-broad-native-link", .description = "Link broad uncurated x86_64 ReleaseFast real-AIR objects with Zig native linker progress accounting", .mode = .ReleaseFast, .corpus = .broad, .variant = .native_link_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-broad-native-link", .description = "Link broad uncurated x86_64 ReleaseSmall real-AIR objects with Zig native linker progress accounting", .mode = .ReleaseSmall, .corpus = .broad, .variant = .native_link_progress },
        .{ .name = "distribution-zig-air-uncurated-releasefast-broad-executable", .description = "Run stable C-ABI executable probes for broad uncurated x86_64 ReleaseFast real-AIR objects", .mode = .ReleaseFast, .corpus = .broad, .variant = .executable_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-broad-executable", .description = "Run stable C-ABI executable probes for broad uncurated x86_64 ReleaseSafe real-AIR objects", .mode = .ReleaseSafe, .corpus = .broad, .variant = .executable_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-broad-executable", .description = "Run stable C-ABI executable probes for broad uncurated x86_64 ReleaseSmall real-AIR objects", .mode = .ReleaseSmall, .corpus = .broad, .variant = .executable_progress },

        .{ .name = "distribution-zig-air-uncurated-releasefast-expanded", .description = "Discover and lower the expanded x86_64 ReleaseFast Zig AIR frontier corpus", .mode = .ReleaseFast, .corpus = .expanded },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-expanded", .description = "Discover and lower the expanded x86_64 ReleaseSafe Zig AIR frontier corpus", .mode = .ReleaseSafe, .corpus = .expanded },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-expanded", .description = "Discover and lower the expanded x86_64 ReleaseSmall Zig AIR frontier corpus", .mode = .ReleaseSmall, .corpus = .expanded },
        .{ .name = "distribution-zig-air-uncurated-releasefast-expanded-object", .description = "Emit z_llvm ELF objects for expanded uncurated x86_64 ReleaseFast Zig AIR progress accounting", .mode = .ReleaseFast, .corpus = .expanded, .variant = .object_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-expanded-object", .description = "Emit z_llvm ELF objects for expanded uncurated x86_64 ReleaseSafe Zig AIR progress accounting", .mode = .ReleaseSafe, .corpus = .expanded, .variant = .object_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-expanded-object", .description = "Emit z_llvm ELF objects for expanded uncurated x86_64 ReleaseSmall Zig AIR progress accounting", .mode = .ReleaseSmall, .corpus = .expanded, .variant = .object_progress },
        .{ .name = "distribution-zig-air-uncurated-releasefast-expanded-object-inspection", .description = "Inspect expanded uncurated x86_64 ReleaseFast real-AIR ELF objects with readelf/objdump", .mode = .ReleaseFast, .corpus = .expanded, .variant = .object_inspection },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-expanded-object-inspection", .description = "Inspect expanded uncurated x86_64 ReleaseSafe real-AIR ELF objects with readelf/objdump", .mode = .ReleaseSafe, .corpus = .expanded, .variant = .object_inspection },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-expanded-object-inspection", .description = "Inspect expanded uncurated x86_64 ReleaseSmall real-AIR ELF objects with readelf/objdump", .mode = .ReleaseSmall, .corpus = .expanded, .variant = .object_inspection },
        .{ .name = "distribution-zig-air-uncurated-releasefast-expanded-native-link", .description = "Link expanded uncurated x86_64 ReleaseFast real-AIR objects with Zig native linker progress accounting", .mode = .ReleaseFast, .corpus = .expanded, .variant = .native_link_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-expanded-native-link", .description = "Link expanded uncurated x86_64 ReleaseSafe real-AIR objects with Zig native linker progress accounting", .mode = .ReleaseSafe, .corpus = .expanded, .variant = .native_link_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-expanded-native-link", .description = "Link expanded uncurated x86_64 ReleaseSmall real-AIR objects with Zig native linker progress accounting", .mode = .ReleaseSmall, .corpus = .expanded, .variant = .native_link_progress },
        .{ .name = "distribution-zig-air-uncurated-releasefast-expanded-executable", .description = "Run stable C-ABI executable probes for expanded uncurated x86_64 ReleaseFast real-AIR objects", .mode = .ReleaseFast, .corpus = .expanded, .variant = .executable_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-expanded-executable", .description = "Run stable C-ABI executable probes for expanded uncurated x86_64 ReleaseSafe real-AIR objects", .mode = .ReleaseSafe, .corpus = .expanded, .variant = .executable_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-expanded-executable", .description = "Run stable C-ABI executable probes for expanded uncurated x86_64 ReleaseSmall real-AIR objects", .mode = .ReleaseSmall, .corpus = .expanded, .variant = .executable_progress },

        .{ .name = "distribution-zig-air-uncurated-releasefast-scale", .description = "Discover, lower, and emit objects for the scale x86_64 ReleaseFast Zig AIR frontier corpus", .mode = .ReleaseFast, .corpus = .scale, .variant = .object_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-scale", .description = "Discover, lower, and emit objects for the scale x86_64 ReleaseSafe Zig AIR frontier corpus", .mode = .ReleaseSafe, .corpus = .scale, .variant = .object_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-scale", .description = "Discover, lower, and emit objects for the scale x86_64 ReleaseSmall Zig AIR frontier corpus", .mode = .ReleaseSmall, .corpus = .scale, .variant = .object_progress },
        .{ .name = "distribution-zig-air-uncurated-releasefast-scale-object-inspection", .description = "Inspect scale uncurated x86_64 ReleaseFast real-AIR ELF objects with readelf/objdump", .mode = .ReleaseFast, .corpus = .scale, .variant = .object_inspection },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-scale-object-inspection", .description = "Inspect scale uncurated x86_64 ReleaseSafe real-AIR ELF objects with readelf/objdump", .mode = .ReleaseSafe, .corpus = .scale, .variant = .object_inspection },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-scale-object-inspection", .description = "Inspect scale uncurated x86_64 ReleaseSmall real-AIR ELF objects with readelf/objdump", .mode = .ReleaseSmall, .corpus = .scale, .variant = .object_inspection },
        .{ .name = "distribution-zig-air-uncurated-releasefast-scale-native-link", .description = "Link scale uncurated x86_64 ReleaseFast real-AIR objects with Zig native linker progress accounting", .mode = .ReleaseFast, .corpus = .scale, .variant = .native_link_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-scale-native-link", .description = "Link scale uncurated x86_64 ReleaseSafe real-AIR objects with Zig native linker progress accounting", .mode = .ReleaseSafe, .corpus = .scale, .variant = .native_link_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-scale-native-link", .description = "Link scale uncurated x86_64 ReleaseSmall real-AIR objects with Zig native linker progress accounting", .mode = .ReleaseSmall, .corpus = .scale, .variant = .native_link_progress },
        .{ .name = "distribution-zig-air-uncurated-releasefast-scale-executable", .description = "Run stable C-ABI executable probes for scale uncurated x86_64 ReleaseFast real-AIR objects", .mode = .ReleaseFast, .corpus = .scale, .variant = .executable_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-scale-executable", .description = "Run stable C-ABI executable probes for scale uncurated x86_64 ReleaseSafe real-AIR objects", .mode = .ReleaseSafe, .corpus = .scale, .variant = .executable_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-scale-executable", .description = "Run stable C-ABI executable probes for scale uncurated x86_64 ReleaseSmall real-AIR objects", .mode = .ReleaseSmall, .corpus = .scale, .variant = .executable_progress },

        .{ .name = "distribution-zig-air-uncurated-releasefast-frontier", .description = "Discover, lower, and emit objects for the frontier x86_64 ReleaseFast Zig AIR corpus", .mode = .ReleaseFast, .corpus = .frontier, .variant = .object_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-frontier", .description = "Discover, lower, and emit objects for the frontier x86_64 ReleaseSafe Zig AIR corpus", .mode = .ReleaseSafe, .corpus = .frontier, .variant = .object_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-frontier", .description = "Discover, lower, and emit objects for the frontier x86_64 ReleaseSmall Zig AIR corpus", .mode = .ReleaseSmall, .corpus = .frontier, .variant = .object_progress },
        .{ .name = "distribution-zig-air-uncurated-releasefast-frontier-object-inspection", .description = "Inspect frontier uncurated x86_64 ReleaseFast real-AIR ELF objects with readelf/objdump", .mode = .ReleaseFast, .corpus = .frontier, .variant = .object_inspection },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-frontier-object-inspection", .description = "Inspect frontier uncurated x86_64 ReleaseSafe real-AIR ELF objects with readelf/objdump", .mode = .ReleaseSafe, .corpus = .frontier, .variant = .object_inspection },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-frontier-object-inspection", .description = "Inspect frontier uncurated x86_64 ReleaseSmall real-AIR ELF objects with readelf/objdump", .mode = .ReleaseSmall, .corpus = .frontier, .variant = .object_inspection },
        .{ .name = "distribution-zig-air-uncurated-releasefast-frontier-native-link", .description = "Link frontier uncurated x86_64 ReleaseFast real-AIR objects with Zig native linker progress accounting", .mode = .ReleaseFast, .corpus = .frontier, .variant = .native_link_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-frontier-native-link", .description = "Link frontier uncurated x86_64 ReleaseSafe real-AIR objects with Zig native linker progress accounting", .mode = .ReleaseSafe, .corpus = .frontier, .variant = .native_link_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-frontier-native-link", .description = "Link frontier uncurated x86_64 ReleaseSmall real-AIR objects with Zig native linker progress accounting", .mode = .ReleaseSmall, .corpus = .frontier, .variant = .native_link_progress },
        .{ .name = "distribution-zig-air-uncurated-releasefast-frontier-executable", .description = "Run stable C-ABI executable probes for frontier uncurated x86_64 ReleaseFast real-AIR objects", .mode = .ReleaseFast, .corpus = .frontier, .variant = .executable_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesafe-frontier-executable", .description = "Run stable C-ABI executable probes for frontier uncurated x86_64 ReleaseSafe real-AIR objects", .mode = .ReleaseSafe, .corpus = .frontier, .variant = .executable_progress },
        .{ .name = "distribution-zig-air-uncurated-releasesmall-frontier-executable", .description = "Run stable C-ABI executable probes for frontier uncurated x86_64 ReleaseSmall real-AIR objects", .mode = .ReleaseSmall, .corpus = .frontier, .variant = .executable_progress },
    };
    for (uncurated_air_specs) |spec| _ = addUncuratedAirGate(b, uncurated_air_gate, spec);

    _ = addUncuratedAirTripleGate(b, uncurated_air_gate, .{
        .name = "distribution-zig-air-uncurated-release",
        .description = "Run uncurated x86_64 release Zig AIR gates for ReleaseFast, ReleaseSafe, and ReleaseSmall",
    });
    _ = addUncuratedAirTripleGate(b, uncurated_air_gate, .{
        .name = "distribution-zig-air-uncurated-release-broad-finish",
        .description = "Strict finish-line gate for broad x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall typed AIR v2 ownership and object emission",
        .corpus = .broad,
        .variant = .strict_finish,
    });
    _ = addUncuratedAirTripleGate(b, uncurated_air_gate, .{
        .name = "distribution-air-release-broad",
        .description = "Strict broad x86_64 release real-AIR optimizer/object/native-link/executable milestone gate",
        .corpus = .broad,
        .variant = .executable_strict_finish,
    });
    _ = addUncuratedAirTripleGate(b, uncurated_air_gate, .{
        .name = "distribution-air-release-expanded",
        .description = "Strict expanded x86_64 release real-AIR optimizer/object/native-link/executable milestone gate",
        .corpus = .expanded,
        .variant = .executable_strict_finish,
    });
    _ = addUncuratedAirTripleGate(b, uncurated_air_gate, .{
        .name = "distribution-air-release-scale",
        .description = "Scale x86_64 release real-AIR optimizer/object/native-link/executable progress gate",
        .corpus = .scale,
        .variant = .object_executable_progress,
    });
    _ = addUncuratedAirTripleGate(b, uncurated_air_gate, .{
        .name = "distribution-air-release-scale-finish",
        .description = "Strict scale x86_64 release real-AIR optimizer/object/native-link/executable milestone gate",
        .corpus = .scale,
        .variant = .executable_strict_finish,
    });
    _ = addUncuratedAirTripleGate(b, uncurated_air_gate, .{
        .name = "distribution-air-release-frontier",
        .description = "Strict frontier x86_64 release real-AIR optimizer/object/native-link/executable milestone gate",
        .corpus = .frontier,
        .variant = .executable_strict_finish,
    });
    _ = addUncuratedAirTripleGate(b, uncurated_air_gate, .{
        .name = "distribution-air-release-frontier-boundaries",
        .description = "Expected fail-closed x86_64 release frontier ABI boundary gate for varargs and vectors",
        .corpus = .frontier_boundaries,
        .variant = .abi_boundary_expectations,
    });
    _ = addUncuratedAirTripleGate(b, uncurated_air_gate, .{
        .name = "distribution-zig-air-uncurated-release-expanded-finish",
        .description = "Strict finish-line gate for expanded x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall typed AIR v2 ownership and object emission",
        .corpus = .expanded,
        .variant = .strict_finish,
    });
    _ = addUncuratedAirTripleGate(b, uncurated_air_gate, .{
        .name = "distribution-zig-air-uncurated-release-scale",
        .description = "Run scale x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall typed AIR frontier object-progress gates",
        .corpus = .scale,
        .variant = .object_progress,
    });
    _ = addUncuratedAirTripleGate(b, uncurated_air_gate, .{
        .name = "distribution-zig-air-uncurated-release-frontier",
        .description = "Run frontier x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall typed AIR object-progress gates",
        .corpus = .frontier,
        .variant = .object_progress,
    });

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
    const run_cmd = b.addSystemCommand(&.{ b.graph.zig_exe, "run", tool });
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
    const run_cmd = b.addSystemCommand(&.{ b.graph.zig_exe, "run", tool, "--" });
    run_cmd.addArgs(args);
    const step = b.step(name, description);
    step.dependOn(&run_cmd.step);
}

fn addToolStepWithArgs(b: *std.Build, name: []const u8, description: []const u8, tool: []const u8) void {
    const run_cmd = b.addSystemCommand(&.{ b.graph.zig_exe, "run", tool, "--" });
    run_cmd.addPassthruArgs();
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
    const run_cmd = b.addSystemCommand(&.{ b.graph.zig_exe, "run", tool, "--" });
    run_cmd.addArgs(fixed_args);
    run_cmd.addPassthruArgs();
    const step = b.step(name, description);
    step.dependOn(&run_cmd.step);
}

const UncuratedAirVariant = enum {
    discovery,
    object_progress,
    object_inspection,
    native_link_progress,
    executable_progress,
    object_executable_progress,
    strict_finish,
    executable_strict_finish,
    abi_boundary_expectations,

    fn addArgs(self: UncuratedAirVariant, run_cmd: *std.Build.Step.Run) void {
        switch (self) {
            .discovery => {},
            .object_progress => run_cmd.addArg("--object-progress"),
            .object_inspection => run_cmd.addArg("--object-inspection"),
            .native_link_progress => run_cmd.addArg("--native-link-progress"),
            .executable_progress => run_cmd.addArg("--executable-progress"),
            .object_executable_progress => {
                run_cmd.addArg("--object-progress");
                run_cmd.addArg("--executable-progress");
            },
            .strict_finish => {
                run_cmd.addArg("--object-progress");
                run_cmd.addArg("--strict-finish");
            },
            .executable_strict_finish => {
                run_cmd.addArg("--object-progress");
                run_cmd.addArg("--executable-progress");
                run_cmd.addArg("--strict-finish");
            },
            .abi_boundary_expectations => run_cmd.addArg("--abi-boundary-expectations"),
        }
    }
};

const UncuratedAirMode = enum {
    ReleaseFast,
    ReleaseSafe,
    ReleaseSmall,

    fn addArg(self: UncuratedAirMode, run_cmd: *std.Build.Step.Run) void {
        run_cmd.addArg(switch (self) {
            .ReleaseFast => "--mode=ReleaseFast",
            .ReleaseSafe => "--mode=ReleaseSafe",
            .ReleaseSmall => "--mode=ReleaseSmall",
        });
    }
};

const UncuratedAirCorpus = enum {
    broad,
    expanded,
    scale,
    frontier,
    frontier_boundaries,

    fn addArg(self: UncuratedAirCorpus, run_cmd: *std.Build.Step.Run) void {
        run_cmd.addArg(switch (self) {
            .broad => "--corpus=broad",
            .expanded => "--corpus=expanded",
            .scale => "--corpus=scale",
            .frontier => "--corpus=frontier",
            .frontier_boundaries => "--corpus=frontier-boundaries",
        });
    }
};

const UncuratedAirGateSpec = struct {
    name: []const u8,
    description: []const u8,
    mode: ?UncuratedAirMode = null,
    corpus: ?UncuratedAirCorpus = null,
    variant: UncuratedAirVariant = .discovery,
};

fn addUncuratedAirGate(
    b: *std.Build,
    uncurated_air_gate: *std.Build.Step.Compile,
    spec: UncuratedAirGateSpec,
) *std.Build.Step {
    const run_cmd = b.addRunArtifact(uncurated_air_gate);
    addUncuratedAirArgs(run_cmd, spec);
    const step = b.step(spec.name, spec.description);
    step.dependOn(&run_cmd.step);
    return step;
}

fn addUncuratedAirTripleGate(
    b: *std.Build,
    uncurated_air_gate: *std.Build.Step.Compile,
    spec: UncuratedAirGateSpec,
) *std.Build.Step {
    const run_cmd = b.addRunArtifact(uncurated_air_gate);
    run_cmd.stdio = .inherit;
    run_cmd.addArg("--all-release-modes");
    addUncuratedAirArgs(run_cmd, .{
        .name = spec.name,
        .description = spec.description,
        .corpus = spec.corpus,
        .variant = spec.variant,
    });
    const step = b.step(spec.name, spec.description);
    step.dependOn(&run_cmd.step);
    return step;
}

fn addUncuratedAirArgs(run_cmd: *std.Build.Step.Run, spec: UncuratedAirGateSpec) void {
    if (spec.mode) |mode| mode.addArg(run_cmd);
    if (spec.corpus) |corpus| corpus.addArg(run_cmd);
    spec.variant.addArgs(run_cmd);
}
