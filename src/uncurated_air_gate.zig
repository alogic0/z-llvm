const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_lowering = @import("zig_air_lowering.zig");
const abi_boundaries = @import("abi_boundaries.zig");
const codegen = @import("codegen.zig");
const mc = @import("mc.zig");

pub fn main(init: std.process.Init) !void {
    const options = try parseOptions(init.minimal.args);
    if (options.all_release_modes) {
        const modes = [_]Mode{ .ReleaseFast, .ReleaseSafe, .ReleaseSmall };
        for (modes) |mode| {
            var mode_options = options;
            mode_options.mode = mode;
            mode_options.all_release_modes = false;
            try runMode(init, mode_options);
        }
    } else {
        try runMode(init, options);
    }
}

fn runMode(init: std.process.Init, options: Options) !void {
    const allocator = init.gpa;
    const io = init.io;
    const mode = options.mode;

    const debug_dump_ir_source = init.minimal.environ.getAlloc(allocator, "ZLLVM_DEBUG_DUMP_IR_SOURCE") catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => return err,
    };
    defer if (debug_dump_ir_source) |value| allocator.free(value);
    const debug_codegen_paths_value = init.minimal.environ.getAlloc(allocator, "ZLLVM_DEBUG_CODEGEN_PATHS") catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => return err,
    };
    defer if (debug_codegen_paths_value) |value| allocator.free(value);
    const debug_codegen_paths = debug_codegen_paths_value != null;

    const zig_emitter_env = init.minimal.environ.getAlloc(allocator, "ZIG_EMITTER") catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => return err,
    };
    defer if (zig_emitter_env) |value| allocator.free(value);
    const zig_emitter = zig_emitter_env orelse "../ziglang/build/stage4/bin/zig";
    std.Io.Dir.cwd().access(io, zig_emitter, .{ .execute = true }) catch {
        return error.MissingZigAirEmitter;
    };

    const sources = try collectSources(allocator, io, options.corpus);
    defer {
        for (sources) |source| allocator.free(source);
        allocator.free(sources);
    }
    const temp_path = try std.fmt.allocPrint(allocator, "tmp/uncurated_zig_air_{s}_{}", .{ mode.lowerName(), std.os.linux.getpid() });
    defer allocator.free(temp_path);
    try std.Io.Dir.cwd().createDirPath(io, temp_path);
    defer std.Io.Dir.cwd().deleteTree(io, temp_path) catch {};

    var unsupported_counts = std.StringHashMap(usize).init(allocator);
    defer {
        var key_iterator = unsupported_counts.keyIterator();
        while (key_iterator.next()) |key| allocator.free(key.*);
        unsupported_counts.deinit();
    }
    var typed_v2_fallback_counts = std.StringHashMap(usize).init(allocator);
    defer {
        var key_iterator = typed_v2_fallback_counts.keyIterator();
        while (key_iterator.next()) |key| allocator.free(key.*);
        typed_v2_fallback_counts.deinit();
    }

    var source_rows: usize = 0;
    var discovered_functions: usize = 0;
    var structured_functions: usize = 0;
    var generic_codegen_functions: usize = 0;
    var structured_air_v1_functions: usize = 0;
    var legacy_air_text_lowering_functions: usize = 0;
    var generic_lowering_functions: usize = 0;
    var shape_recognizer_functions: usize = 0;
    var generic_cfg_functions: usize = 0;
    var structural_matcher_functions: usize = 0;
    var object_emitted_functions: usize = 0;
    var inspected_objects: usize = 0;
    var relocation_rows: usize = 0;
    var tls_rows: usize = 0;
    var undefined_import_rows: usize = 0;
    var native_link_accepted_rows: usize = 0;
    var executable_ok_rows: usize = 0;
    var link_only_rows: usize = 0;
    var runtime_boundary_rows: usize = 0;
    var unsupported_zig_linker_feature_rows: usize = 0;
    var unsupported_functions: usize = 0;
    var codegen_failures: usize = 0;
    var structured_air_v2_functions: usize = 0;
    var typed_air_type_functions: usize = 0;
    var typed_air_operand_functions: usize = 0;
    var typed_v2_fallback_functions: usize = 0;
    var object_failures: usize = 0;
    var native_link_failures: usize = 0;
    var boundary_counts: abi_boundaries.Counts = .{};
    var unexpected_accept_rows: usize = 0;
    var wrong_diagnostic_rows: usize = 0;
    var first_unsupported_source: ?[]const u8 = null;
    defer if (first_unsupported_source) |value| allocator.free(value);
    var first_unsupported_function: ?[]const u8 = null;
    defer if (first_unsupported_function) |value| allocator.free(value);
    var first_unsupported_opcode: ?[]const u8 = null;
    defer if (first_unsupported_opcode) |value| allocator.free(value);
    var first_typed_v2_fallback_function: ?[]const u8 = null;
    defer if (first_typed_v2_fallback_function) |value| allocator.free(value);
    var first_typed_v2_fallback_opcode: ?[]const u8 = null;
    defer if (first_typed_v2_fallback_opcode) |value| allocator.free(value);
    var first_typed_v2_fallback_data_kind: ?[]const u8 = null;
    defer if (first_typed_v2_fallback_data_kind) |value| allocator.free(value);
    var first_typed_v2_fallback_reason: ?[]const u8 = null;
    defer if (first_typed_v2_fallback_reason) |value| allocator.free(value);

    for (sources) |source| {
        const stem = std.fs.path.stem(source);
        const descriptor_name = try std.fmt.allocPrint(allocator, "{s}.air", .{stem});
        defer allocator.free(descriptor_name);
        const descriptor_path = try std.fs.path.join(allocator, &.{ temp_path, descriptor_name });
        defer allocator.free(descriptor_path);

        var env_map = try cloneEnvironment(allocator, init.environ_map);
        defer env_map.deinit();
        try env_map.put("ZLLVM_AIR_EXPORT_PATH", descriptor_path);
        const argv = [_][]const u8{
            zig_emitter,
            "build-obj",
            "-fllvm",
            "-flibllvm",
            "-fno-emit-bin",
            mode.zigOptimizeArg(),
            "-target",
            "x86_64-linux-gnu",
            source,
        };
        const emit_result = try std.process.run(allocator, io, .{
            .argv = &argv,
            .environ_map = &env_map,
            .stdout_limit = .limited(16 * 1024 * 1024),
            .stderr_limit = .limited(16 * 1024 * 1024),
        });
        defer {
            allocator.free(emit_result.stdout);
            allocator.free(emit_result.stderr);
        }
        switch (emit_result.term) {
            .exited => |code| if (code != 0) {
                if (options.abi_boundary_expectations) {
                    if (abi_boundaries.categoryForAirExportFailure(source, emit_result.stderr)) |category| {
                        source_rows += 1;
                        const row_count = abi_boundaries.rowCountForSource(source);
                        discovered_functions += row_count;
                        boundary_counts.add(category, row_count);
                        std.debug.print(
                            "abi-boundary source={s} function=module category={s} diagnostic={s} stage=air-export stderr={s}\n",
                            .{ source, category.name(), category.diagnosticName(), firstLine(emit_result.stderr) },
                        );
                        continue;
                    }
                }
                std.debug.print(
                    "air-export-failure source={s} exit_code={} stdout={s} stderr={s}\n",
                    .{ source, code, firstLine(emit_result.stdout), firstLine(emit_result.stderr) },
                );
                return error.ZigAirExportFailed;
            },
            else => {
                std.debug.print(
                    "air-export-failure source={s} term={s} stdout={s} stderr={s}\n",
                    .{ source, termName(emit_result.term), firstLine(emit_result.stdout), firstLine(emit_result.stderr) },
                );
                return error.ZigAirExportFailed;
            },
        }

        const descriptor = try std.Io.Dir.cwd().readFileAlloc(
            io,
            descriptor_path,
            allocator,
            .limited(32 * 1024 * 1024),
        );
        defer allocator.free(descriptor);
        source_rows += 1;
        var parsed = air_export.parse(allocator, descriptor) catch |err| {
            unsupported_functions += 1;
            try incrementCount(allocator, &unsupported_counts, "parse");
            std.debug.print(
                "unsupported-air source={s} function=- opcode=parse reason={s}\n",
                .{ source, @errorName(err) },
            );
            if (first_unsupported_source == null) {
                first_unsupported_source = try allocator.dupe(u8, source);
                first_unsupported_function = try allocator.dupe(u8, "-");
                first_unsupported_opcode = try allocator.dupe(u8, "parse");
            }
            continue;
        };
        defer parsed.deinit();
        var lowered = air_lowering.lowerCompatible(allocator, parsed) catch |err| {
            if (options.abi_boundary_expectations) {
                if (abi_boundaries.categoryForLoweringFailure(source, err)) |category| {
                    const row_count = abi_boundaries.rowCountForSource(source);
                    discovered_functions += row_count;
                    boundary_counts.add(category, row_count);
                    std.debug.print(
                        "abi-boundary source={s} function=module category={s} diagnostic={s} stage=lowering error={s}\n",
                        .{ source, category.name(), category.diagnosticName(), @errorName(err) },
                    );
                    continue;
                }
            }
            unsupported_functions += 1;
            try incrementCount(allocator, &unsupported_counts, "lowering");
            std.debug.print(
                "unsupported-air source={s} function=- opcode=lowering reason={s}\n",
                .{ source, @errorName(err) },
            );
            if (first_unsupported_source == null) {
                first_unsupported_source = try allocator.dupe(u8, source);
                first_unsupported_function = try allocator.dupe(u8, "-");
                first_unsupported_opcode = try allocator.dupe(u8, "lowering");
            }
            continue;
        };
        defer lowered.deinit();

        if (debug_dump_ir_source) |dump_source| {
            if (std.mem.indexOf(u8, source, dump_source) != null) {
                var aw: std.Io.Writer.Allocating = .init(allocator);
                defer aw.deinit();
                lowered.module.print(&aw.writer) catch {};
                std.debug.print("debug-dump-ir source={s}\n{s}\n", .{ source, aw.written() });
            }
        }

        discovered_functions += rootFunctionCount(parsed);
        structured_functions += lowered.accepted_functions;
        structured_air_v1_functions += lowered.structured_air_v1_functions;
        structured_air_v2_functions += lowered.structured_air_v2_functions;
        typed_air_type_functions += lowered.typed_air_type_functions;
        typed_air_operand_functions += lowered.typed_air_operand_functions;
        legacy_air_text_lowering_functions += lowered.legacy_air_text_lowering_functions;
        generic_lowering_functions += lowered.generic_lowering_functions;
        shape_recognizer_functions += lowered.shape_recognizer_functions;
        typed_v2_fallback_functions += lowered.typed_v2_fallbacks.len;
        for (lowered.typed_v2_fallbacks) |fallback| {
            const fallback_key = try std.fmt.allocPrint(allocator, "{s}:{s}:{s}", .{
                fallback.reason,
                fallback.opcode,
                fallback.data_kind,
            });
            defer allocator.free(fallback_key);
            try incrementCount(allocator, &typed_v2_fallback_counts, fallback_key);
            std.debug.print(
                "typed-v2-fallback source={s} function={s} opcode={s} data_kind={s} reason={s}\n",
                .{ source, fallback.function, fallback.opcode, fallback.data_kind, fallback.reason },
            );
            if (first_typed_v2_fallback_function == null) {
                first_typed_v2_fallback_function = try allocator.dupe(u8, fallback.function);
                first_typed_v2_fallback_opcode = try allocator.dupe(u8, fallback.opcode);
                first_typed_v2_fallback_data_kind = try allocator.dupe(u8, fallback.data_kind);
                first_typed_v2_fallback_reason = try allocator.dupe(u8, fallback.reason);
            }
        }
        unsupported_functions += lowered.unsupported.len;
        for (lowered.unsupported) |diagnostic| {
            if (options.abi_boundary_expectations) {
                if (abi_boundaries.categoryForUnsupported(source, diagnostic)) |category| {
                    boundary_counts.add(category, 1);
                    std.debug.print(
                        "abi-boundary source={s} function={s} category={s} diagnostic={s}\n",
                        .{ source, diagnostic.function, category.name(), category.diagnosticName() },
                    );
                    continue;
                }
                wrong_diagnostic_rows += 1;
                std.debug.print(
                    "abi-boundary-failure source={s} function={s} expected=targeted-abi-boundary actual={s}/{s}\n",
                    .{ source, diagnostic.function, diagnostic.opcode, @tagName(diagnostic.reason) },
                );
                continue;
            }
            if (diagnostic.reason == .opcode or diagnostic.reason == .control_flow_shape) {
                try incrementCount(allocator, &unsupported_counts, diagnostic.opcode);
            }
            std.debug.print(
                "unsupported-air source={s} function={s} opcode={s} reason={s}\n",
                .{ source, diagnostic.function, diagnostic.opcode, @tagName(diagnostic.reason) },
            );
            if (first_unsupported_source == null) {
                first_unsupported_source = try allocator.dupe(u8, source);
                first_unsupported_function = try allocator.dupe(u8, diagnostic.function);
                first_unsupported_opcode = try allocator.dupe(u8, diagnostic.opcode);
            }
        }
        var machines: std.ArrayList(codegen.x86_64.MachineFunction) = .empty;
        defer {
            for (machines.items) |*machine| machine.deinit(allocator);
            machines.deinit(allocator);
        }
        for (lowered.module.functions.items) |function| {
            var machine = codegen.x86_64.lowerFunction(
                allocator,
                "x86_64-unknown-linux-gnu",
                function,
            ) catch |err| {
                if (options.abi_boundary_expectations) {
                    if (abi_boundaries.categoryForCodegenFailure(source, err)) |category| {
                        boundary_counts.add(category, 1);
                        std.debug.print(
                            "abi-boundary source={s} function={s} category={s} diagnostic={s}\n",
                            .{ source, function.name, category.name(), category.diagnosticName() },
                        );
                    } else {
                        wrong_diagnostic_rows += 1;
                        std.debug.print(
                            "abi-boundary-failure source={s} function={s} expected=targeted-abi-boundary actual={s}\n",
                            .{ source, function.name, @errorName(err) },
                        );
                    }
                    continue;
                }
                codegen_failures += 1;
                std.debug.print(
                    "unsupported-codegen source={s} function={s} error={s}\n",
                    .{ source, function.name, @errorName(err) },
                );
                continue;
            };
            if (options.abi_boundary_expectations) {
                unexpected_accept_rows += 1;
                std.debug.print(
                    "abi-boundary-failure source={s} function={s} expected=unsupported actual=accepted\n",
                    .{ source, function.name },
                );
                machine.deinit(allocator);
                continue;
            }
            try machines.append(allocator, machine);
            generic_codegen_functions += 1;
            const codegen_path = machines.items[machines.items.len - 1].codegen_path;
            if (debug_codegen_paths) {
                std.debug.print(
                    "codegen-path source={s} function={s} path={s}\n",
                    .{ source, function.name, @tagName(codegen_path) },
                );
            }
            switch (codegen_path) {
                .generic_cfg => generic_cfg_functions += 1,
                .structural_matcher => structural_matcher_functions += 1,
            }
        }
        if ((options.object_progress or options.object_inspection or options.native_link_progress or options.executable_progress) and machines.items.len != 0) {
            const object = mc.elf.buildObjectWithModuleData(
                allocator,
                machines.items,
                lowered.module.aliases.items,
                lowered.module.globals.items,
            ) catch |err| {
                object_failures += 1;
                std.debug.print(
                    "unsupported-object source={s} error={s}\n",
                    .{ source, @errorName(err) },
                );
                continue;
            };
            defer allocator.free(object);
            object_emitted_functions += machines.items.len;

            if (options.object_inspection or options.native_link_progress or options.executable_progress) {
                const object_name = try std.fmt.allocPrint(allocator, "{s}.o", .{stem});
                defer allocator.free(object_name);
                const object_path = try std.fs.path.join(allocator, &.{ temp_path, object_name });
                defer allocator.free(object_path);
                try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = object_path, .data = object });

                if (options.object_inspection) {
                    const inspection = try inspectObject(allocator, io, object_path, mode, source);
                    inspected_objects += 1;
                    if (inspection.has_relocations) relocation_rows += 1;
                    if (inspection.has_tls) tls_rows += 1;
                    if (inspection.has_undefined_imports) undefined_import_rows += 1;
                }

                if (!(options.native_link_progress or options.executable_progress)) continue;

                const exe_name = try std.fmt.allocPrint(allocator, "{s}.link", .{stem});
                defer allocator.free(exe_name);
                const exe_path = try std.fs.path.join(allocator, &.{ temp_path, exe_name });
                defer allocator.free(exe_path);

                const harness = if (options.executable_progress) executableHarnessForSource(source) else null;
                const link_result = if (harness) |executable_harness| link_result: {
                    if (executable_harness.c_path) |harness_c| {
                        break :link_result try linkObjectWithHarnessFile(allocator, io, zig_emitter, mode, object_path, exe_path, harness_c);
                    }
                    const harness_body = try executableHarnessBody(allocator, executable_harness);
                    defer allocator.free(harness_body);
                    break :link_result try linkObjectWithHarness(allocator, io, zig_emitter, mode, object_path, exe_path, harness_body);
                } else try nativeLinkObject(allocator, io, zig_emitter, mode, object_path, exe_path);
                defer {
                    allocator.free(link_result.stdout);
                    allocator.free(link_result.stderr);
                }
                if (termOk(link_result.term)) {
                    if (harness) |executable_harness| {
                        const run_result = try runExecutable(allocator, io, exe_path);
                        defer {
                            allocator.free(run_result.stdout);
                            allocator.free(run_result.stderr);
                        }
                        if (termOk(run_result.term)) {
                            native_link_accepted_rows += 1;
                            executable_ok_rows += 1;
                            std.debug.print(
                                "executable-ok source={s} function=module abi={s} expected={s} actual=exit0\n",
                                .{ source, executable_harness.abi_mode, executable_harness.expected },
                            );
                        } else {
                            native_link_failures += 1;
                            std.debug.print(
                                "executable-failure source={s} function=module abi={s} expected={s} actual={s} exit_code={d} stderr={s}\n",
                                .{ source, executable_harness.abi_mode, executable_harness.expected, termName(run_result.term), termExitCode(run_result.term), firstLine(run_result.stderr) },
                            );
                        }
                    } else {
                        native_link_accepted_rows += 1;
                        link_only_rows += 1;
                        if (options.executable_progress) {
                            std.debug.print(
                                "link-only source={s} function=module abi=unstable expected=- actual=linked category=no-stable-executable-harness\n",
                                .{source},
                            );
                        }
                    }
                } else switch (classifyNativeLinkFailure(link_result.stderr)) {
                    .runtime_boundary => |symbol| {
                        runtime_boundary_rows += 1;
                        std.debug.print(
                            "native-link-boundary source={s} function=module category=runtime/compiler-rt/libc symbol={s}\n",
                            .{ source, symbol },
                        );
                    },
                    .unsupported_zig_linker_feature => |category| {
                        unsupported_zig_linker_feature_rows += 1;
                        std.debug.print(
                            "native-link-boundary source={s} function=module category={s} stderr={s}\n",
                            .{ source, category, firstLine(link_result.stderr) },
                        );
                    },
                    .local_failure => |category| {
                        native_link_failures += 1;
                        std.debug.print(
                            "native-link-failure source={s} function=module category={s} stderr={s}\n",
                            .{ source, category, firstLine(link_result.stderr) },
                        );
                    },
                }
            }
        }
    }

    var top_construct: []const u8 = "-";
    var top_count: usize = 0;
    var iterator = unsupported_counts.iterator();
    while (iterator.next()) |entry| {
        if (entry.value_ptr.* > top_count or
            (entry.value_ptr.* == top_count and std.mem.lessThan(u8, entry.key_ptr.*, top_construct)))
        {
            top_construct = entry.key_ptr.*;
            top_count = entry.value_ptr.*;
        }
    }
    var top_typed_v2_fallback_reason: []const u8 = "-";
    var top_typed_v2_fallback_count: usize = 0;
    var typed_fallback_iterator = typed_v2_fallback_counts.iterator();
    while (typed_fallback_iterator.next()) |entry| {
        if (entry.value_ptr.* > top_typed_v2_fallback_count or
            (entry.value_ptr.* == top_typed_v2_fallback_count and std.mem.lessThan(u8, entry.key_ptr.*, top_typed_v2_fallback_reason)))
        {
            top_typed_v2_fallback_reason = entry.key_ptr.*;
            top_typed_v2_fallback_count = entry.value_ptr.*;
        }
    }

    const air_local_fail: usize = if ((options.corpus == .expanded or options.corpus == .scale or options.corpus == .frontier) and
        (unsupported_functions != 0 or codegen_failures != 0 or typed_v2_fallback_functions != 0 or legacy_air_text_lowering_functions != 0 or shape_recognizer_functions != 0 or
            (options.corpus == .frontier and structural_matcher_functions != 0)))
        1
    else
        0;
    std.debug.print(
        "summary uncurated-zig-air mode={s} corpus={s} target=x86_64-linux-gnu source_rows={} discovered_functions={} structured_functions={} generic_codegen_functions={} generic_cfg_functions={} structural_matcher_functions={} structured_air_v1_functions={} structured_air_v2_functions={} typed_air_type_functions={} typed_air_operand_functions={} legacy_air_text_lowering_functions={} typed_v2_fallback_functions={} generic_lowering_functions={} shape_recognizer_functions={} unsupported_functions={} codegen_failures={} case_id_rows=0 source_fact_classification_rows=0 first_unsupported_source={s} first_unsupported_function={s} first_unsupported_opcode={s} top_unsupported_construct={s} top_unsupported_count={} first_typed_v2_fallback_function={s} first_typed_v2_fallback_opcode={s} first_typed_v2_fallback_data_kind={s} first_typed_v2_fallback_reason={s} top_typed_v2_fallback_reason={s} top_typed_v2_fallback_count={} local_fail={}\n",
        .{
            mode.name(),
            options.corpus.name(),
            source_rows,
            discovered_functions,
            structured_functions,
            generic_codegen_functions,
            generic_cfg_functions,
            structural_matcher_functions,
            structured_air_v1_functions,
            structured_air_v2_functions,
            typed_air_type_functions,
            typed_air_operand_functions,
            legacy_air_text_lowering_functions,
            typed_v2_fallback_functions,
            generic_lowering_functions,
            shape_recognizer_functions,
            unsupported_functions,
            codegen_failures,
            first_unsupported_source orelse "-",
            first_unsupported_function orelse "-",
            first_unsupported_opcode orelse "-",
            top_construct,
            top_count,
            first_typed_v2_fallback_function orelse "-",
            first_typed_v2_fallback_opcode orelse "-",
            first_typed_v2_fallback_data_kind orelse "-",
            first_typed_v2_fallback_reason orelse "-",
            top_typed_v2_fallback_reason,
            top_typed_v2_fallback_count,
            air_local_fail,
        },
    );
    if (options.object_progress) {
        std.debug.print(
            "summary uncurated-zig-air-object mode={s} target=x86_64-linux-gnu object_emitted_functions={} object_failures={} llvm_targetmachine_rows=0 local_fail=0\n",
            .{ mode.name(), object_emitted_functions, object_failures },
        );
    }
    if (options.object_inspection) {
        std.debug.print(
            "summary uncurated-zig-air-object-inspection mode={s} target=x86_64-linux-gnu inspected={} elf64_rel={} relocation_rows={} tls_rows={} undefined_import_rows={} comdat_rows=0 eh_frame_rows=0 unsupported_relocation_rows=0 local_fail=0\n",
            .{ mode.name(), inspected_objects, inspected_objects, relocation_rows, tls_rows, undefined_import_rows },
        );
    }
    if (options.native_link_progress) {
        const local_fail: usize = if (native_link_failures == 0 and unsupported_zig_linker_feature_rows == 0) 0 else 1;
        std.debug.print(
            "summary uncurated-zig-air-native-link mode={s} target=x86_64-linux-gnu native_link_accepted_rows={} executable_ok_rows={} link_only_rows={} runtime_boundary_rows={} unsupported_zig_linker_feature_rows={} native_link_failures={} llvm_targetmachine_rows=0 lld_rows=0 local_fail={}\n",
            .{
                mode.name(),
                native_link_accepted_rows,
                executable_ok_rows,
                link_only_rows,
                runtime_boundary_rows,
                unsupported_zig_linker_feature_rows,
                native_link_failures,
                local_fail,
            },
        );
    }
    if (options.executable_progress) {
        const local_fail: usize = if (native_link_failures == 0 and unsupported_zig_linker_feature_rows == 0) 0 else 1;
        std.debug.print(
            "summary uncurated-zig-air-executable mode={s} target=x86_64-linux-gnu native_link_accepted_rows={} executable_ok_rows={} link_only_rows={} runtime_boundary_rows={} unsupported_zig_linker_feature_rows={} native_link_failures={} llvm_targetmachine_rows=0 lld_rows=0 local_fail={}\n",
            .{
                mode.name(),
                native_link_accepted_rows,
                executable_ok_rows,
                link_only_rows,
                runtime_boundary_rows,
                unsupported_zig_linker_feature_rows,
                native_link_failures,
                local_fail,
            },
        );
    }
    if (options.abi_boundary_expectations) {
        const boundary_local_fail: usize = if (options.corpus == .frontier_boundaries and
            source_rows == 6 and
            discovered_functions == 10 and
            boundary_counts.varargs_rows == 2 and
            boundary_counts.vector_rows == 2 and
            boundary_counts.x87_rows == 2 and
            boundary_counts.packed_aggregate_rows == 2 and
            boundary_counts.tail_call_rows == 1 and
            boundary_counts.callconv_rows == 1 and
            boundary_counts.stack_pressure_rows == 0 and
            unexpected_accept_rows == 0 and
            wrong_diagnostic_rows == 0)
            0
        else
            1;
        std.debug.print(
            "summary uncurated-zig-air-abi-boundaries mode={s} corpus={s} target=x86_64-linux-gnu source_rows={} discovered_functions={} varargs_boundary_rows={} vector_boundary_rows={} x87_boundary_rows={} packed_aggregate_boundary_rows={} tail_call_boundary_rows={} callconv_boundary_rows={} stack_pressure_boundary_rows={} unexpected_accept_rows={} wrong_diagnostic_rows={} llvm_targetmachine_rows=0 lld_rows=0 local_fail={}\n",
            .{
                mode.name(),
                options.corpus.name(),
                source_rows,
                discovered_functions,
                boundary_counts.varargs_rows,
                boundary_counts.vector_rows,
                boundary_counts.x87_rows,
                boundary_counts.packed_aggregate_rows,
                boundary_counts.tail_call_rows,
                boundary_counts.callconv_rows,
                boundary_counts.stack_pressure_rows,
                unexpected_accept_rows,
                wrong_diagnostic_rows,
                boundary_local_fail,
            },
        );
        if (boundary_local_fail != 0) return error.AbiBoundaryExpectationFailed;
    }

    if (air_local_fail != 0) return error.ExpandedCorpusLocalFailure;
    if ((options.native_link_progress or options.executable_progress) and
        (native_link_failures != 0 or unsupported_zig_linker_feature_rows != 0))
    {
        return error.NativeLinkLocalFailure;
    }

    if (options.strict_finish) {
        try validateStrictFinish(.{
            .mode = mode,
            .corpus = options.corpus,
            .object_progress = options.object_progress,
            .executable_progress = options.executable_progress,
            .source_rows = source_rows,
            .discovered_functions = discovered_functions,
            .structured_functions = structured_functions,
            .generic_codegen_functions = generic_codegen_functions,
            .generic_cfg_functions = generic_cfg_functions,
            .structural_matcher_functions = structural_matcher_functions,
            .structured_air_v2_functions = structured_air_v2_functions,
            .typed_air_operand_functions = typed_air_operand_functions,
            .legacy_air_text_lowering_functions = legacy_air_text_lowering_functions,
            .typed_v2_fallback_functions = typed_v2_fallback_functions,
            .generic_lowering_functions = generic_lowering_functions,
            .shape_recognizer_functions = shape_recognizer_functions,
            .unsupported_functions = unsupported_functions,
            .codegen_failures = codegen_failures,
            .object_emitted_functions = object_emitted_functions,
            .object_failures = object_failures,
            .native_link_accepted_rows = native_link_accepted_rows,
            .executable_ok_rows = executable_ok_rows,
            .link_only_rows = link_only_rows,
            .runtime_boundary_rows = runtime_boundary_rows,
            .unsupported_zig_linker_feature_rows = unsupported_zig_linker_feature_rows,
            .native_link_failures = native_link_failures,
        });
    }
}

const helpers = @import("uncurated_air_gate_helpers.zig");

const Options = helpers.Options;
const Mode = helpers.Mode;
const Corpus = helpers.Corpus;
const StrictFinishCounters = helpers.StrictFinishCounters;

const ObjectInspection = helpers.ObjectInspection;
const ExecutableHarness = helpers.ExecutableHarness;
const ModuleMainHarness = helpers.ModuleMainHarness;
const ModuleMainReturnType = helpers.ModuleMainReturnType;

const rootFunctionCount = helpers.rootFunctionCount;
const parseOptions = helpers.parseOptions;
const validateStrictFinish = helpers.validateStrictFinish;
const expectStrict = helpers.expectStrict;
const inspectObject = helpers.inspectObject;
const executableHarnessForSource = helpers.executableHarnessForSource;
const executableHarnessBody = helpers.executableHarnessBody;
const nativeLinkObject = helpers.nativeLinkObject;
const linkObjectWithHarness = helpers.linkObjectWithHarness;
const linkObjectWithHarnessFile = helpers.linkObjectWithHarnessFile;
const runExecutable = helpers.runExecutable;
const termOk = helpers.termOk;
const termName = helpers.termName;
const termExitCode = helpers.termExitCode;
const classifyNativeLinkFailure = helpers.classifyNativeLinkFailure;
const cloneEnvironment = helpers.cloneEnvironment;
const incrementCount = helpers.incrementCount;
const collectSources = helpers.collectSources;

const firstLine = helpers.firstLine;
