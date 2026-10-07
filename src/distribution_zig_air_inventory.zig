const std = @import("std");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_export = @import("zig_air_export.zig");

const target_triple = "x86_64-linux-gnu";
const StringCountMap = std.array_hash_map.String(usize);
const OpcodeCountMap = std.array_hash_map.String(OpcodeStat);
const UnknownOpcodePairMap = std.array_hash_map.String(UnknownOpcodePairStat);

const Options = struct {
    slice: InventorySlice = .all,
    mode: ?Mode = null,
    preserve_temp: bool = false,
    real_candidates_tsv: ?[]const u8 = null,
};

const InventorySlice = enum {
    runtime_libs,
    compiler_core,
    compiler_core_module,
    all,

    fn cliName(self: InventorySlice) []const u8 {
        return switch (self) {
            .runtime_libs => "runtime-libs",
            .compiler_core => "compiler-core",
            .compiler_core_module => "compiler-core-module",
            .all => "all",
        };
    }

    fn parse(value: []const u8) !InventorySlice {
        if (std.mem.eql(u8, value, "runtime-libs")) return .runtime_libs;
        if (std.mem.eql(u8, value, "compiler-core")) return .compiler_core;
        if (std.mem.eql(u8, value, "compiler-core-module")) return .compiler_core_module;
        if (std.mem.eql(u8, value, "all")) return .all;
        return error.UnsupportedDistributionInventorySlice;
    }
};

const Mode = enum {
    ReleaseFast,
    ReleaseSafe,
    ReleaseSmall,

    fn zigOptimizeArg(self: Mode) []const u8 {
        return switch (self) {
            .ReleaseFast => "-OReleaseFast",
            .ReleaseSafe => "-OReleaseSafe",
            .ReleaseSmall => "-OReleaseSmall",
        };
    }

    fn zigBuildOptimizeArg(self: Mode) []const u8 {
        return switch (self) {
            .ReleaseFast => "-Doptimize=ReleaseFast",
            .ReleaseSafe => "-Doptimize=ReleaseSafe",
            .ReleaseSmall => "-Doptimize=ReleaseSmall",
        };
    }

    fn name(self: Mode) []const u8 {
        return @tagName(self);
    }

    fn parse(value: []const u8) !Mode {
        if (std.mem.eql(u8, value, "ReleaseFast")) return .ReleaseFast;
        if (std.mem.eql(u8, value, "ReleaseSafe")) return .ReleaseSafe;
        if (std.mem.eql(u8, value, "ReleaseSmall")) return .ReleaseSmall;
        return error.UnsupportedDistributionInventoryMode;
    }

    fn lowerName(self: Mode) []const u8 {
        return switch (self) {
            .ReleaseFast => "releasefast",
            .ReleaseSafe => "releasesafe",
            .ReleaseSmall => "releasesmall",
        };
    }
};

const DistributionSource = struct {
    path: []const u8,
    class: []const u8,
};

const runtime_lib_sources = [_]DistributionSource{
    .{ .path = "../ziglang/lib/compiler_rt.zig", .class = "compiler-rt" },
    .{ .path = "../ziglang/lib/ubsan_rt.zig", .class = "runtime-safety" },
    .{ .path = "../ziglang/lib/c.zig", .class = "libc-boundary" },
};

const compiler_core_sources = [_]DistributionSource{
    .{ .path = "../ziglang/src/main.zig", .class = "compiler-entry" },
    .{ .path = "../ziglang/src/Compilation.zig", .class = "compiler-core" },
    .{ .path = "../ziglang/src/Zcu.zig", .class = "compiler-module-root" },
    .{ .path = "../ziglang/src/Sema.zig", .class = "compiler-sema" },
    .{ .path = "../ziglang/src/Air.zig", .class = "compiler-air" },
    .{ .path = "../ziglang/src/codegen.zig", .class = "compiler-codegen" },
    .{ .path = "../ziglang/src/codegen/llvm.zig", .class = "compiler-llvm-codegen" },
    .{ .path = "../ziglang/src/link.zig", .class = "compiler-link" },
    .{ .path = "../ziglang/src/link/Elf.zig", .class = "compiler-link-elf" },
};

const UnsupportedCategory = enum(u8) {
    varargs,
    vector,
    aggregate_abi,
    x87,
    packed_aggregate,
    inline_asm,
    unknown_opcode,

    fn name(self: UnsupportedCategory) []const u8 {
        return switch (self) {
            .aggregate_abi => "aggregate-abi",
            .packed_aggregate => "packed-aggregate",
            .inline_asm => "inline-asm",
            .unknown_opcode => "unknown-opcode",
            else => @tagName(self),
        };
    }
};

const unsupported_category_count = @typeInfo(UnsupportedCategory).@"enum".field_names.len;
const unknown_opcode_category_count = @typeInfo(air_capabilities.UnknownOpcodeCategory).@"enum".field_names.len;
const top_unknown_opcode_pair_limit = 50;
const top_unknown_opcode_category_pair_limit = 10;
const real_candidate_selector_version = "real-candidate-selector-v1";

const AggregateSurfaceCategory = enum(u8) {
    opcode_shape,
    metadata_type_surface,
    abi_type_surface,

    fn name(self: AggregateSurfaceCategory) []const u8 {
        return switch (self) {
            .opcode_shape => "opcode-shape",
            .metadata_type_surface => "metadata-type-surface",
            .abi_type_surface => "abi-type-surface",
        };
    }
};

const aggregate_surface_category_count = @typeInfo(AggregateSurfaceCategory).@"enum".field_names.len;

const BoundaryCategory = enum(u8) {
    parse_import,
    module_root,
    comptime_dependency,
    non_standalone,

    fn name(self: BoundaryCategory) []const u8 {
        return switch (self) {
            .parse_import => "parse-import",
            .module_root => "module-root",
            .comptime_dependency => "comptime-dependency",
            .non_standalone => "non-standalone",
        };
    }
};

const boundary_category_count = @typeInfo(BoundaryCategory).@"enum".field_names.len;

const CategoryStat = struct {
    count: usize = 0,
    first_source: ?[]const u8 = null,
    first_function: ?[]const u8 = null,

    fn deinit(self: *CategoryStat, allocator: std.mem.Allocator) void {
        if (self.first_source) |value| allocator.free(value);
        if (self.first_function) |value| allocator.free(value);
        self.* = .{};
    }
};

const UnknownOpcodePairStat = struct {
    count: usize = 0,
    first_source: ?[]const u8 = null,
    first_function: ?[]const u8 = null,

    fn deinit(self: *UnknownOpcodePairStat, allocator: std.mem.Allocator) void {
        if (self.first_source) |value| allocator.free(value);
        if (self.first_function) |value| allocator.free(value);
    }
};

const OpcodeStat = struct {
    count: usize = 0,
    first_source: ?[]const u8 = null,
    first_function: ?[]const u8 = null,

    fn deinit(self: *OpcodeStat, allocator: std.mem.Allocator) void {
        if (self.first_source) |value| allocator.free(value);
        if (self.first_function) |value| allocator.free(value);
    }
};

const TextFeatureContext = enum {
    metadata,
    abi,
};

const Counters = struct {
    sources: usize = 0,
    inventory_ok_sources: usize = 0,
    boundary_sources: usize = 0,
    standalone_source_probe: usize = 0,
    real_module_context: usize = 0,
    generated_imports_available: usize = 0,
    stubbed_imports: usize = 0,
    instruction_payload_scan: usize = 0,
    modules: usize = 0,
    functions: usize = 0,
    functions_with_body: usize = 0,
    declarations_without_body: usize = 0,
    instructions_total: usize = 0,
    exported_functions: usize = 0,
    comptime_functions: usize = 0,
    globals: usize = 0,
    constant_globals: usize = 0,
    tls_globals: usize = 0,
    extern_imports: usize = 0,
    runtime_symbols: usize = 0,
    calls: usize = 0,
    callconv_default: usize = 0,
    callconv_c: usize = 0,
    callconv_other: usize = 0,
    varargs_uses: usize = 0,
    vector_uses: usize = 0,
    x87_uses: usize = 0,
    packed_unaligned_aggregate_uses: usize = 0,
    atomics: usize = 0,
    inline_asm: usize = 0,
    loads: usize = 0,
    stores: usize = 0,
    allocas: usize = 0,
    switches: usize = 0,
    loops: usize = 0,
    branches: usize = 0,
    aggregate_types: usize = 0,
    aggregate_opcode_shapes: usize = 0,
    aggregate_metadata_type_surfaces: usize = 0,
    aggregate_abi_type_surfaces: usize = 0,
    aggregate_layout_facts: usize = 0,
    pointer_uses: usize = 0,
    slice_uses: usize = 0,
    optional_uses: usize = 0,
    error_union_uses: usize = 0,
    unsupported_functions: usize = 0,
    unsupported_opcodes: usize = 0,
    unsupported_categories: [unsupported_category_count]CategoryStat = @splat(.{}),
    unknown_opcode_categories: [unknown_opcode_category_count]CategoryStat = @splat(.{}),
    aggregate_surface_categories: [aggregate_surface_category_count]CategoryStat = @splat(.{}),
    boundary_categories: [boundary_category_count]CategoryStat = @splat(.{}),
    opcode_counts: OpcodeCountMap = .empty,
    data_kind_counts: StringCountMap = .empty,
    unknown_opcode_pair_counts: UnknownOpcodePairMap = .empty,
    callconv_counts: StringCountMap = .empty,

    fn deinit(self: *Counters, allocator: std.mem.Allocator) void {
        for (&self.unsupported_categories) |*category| category.deinit(allocator);
        for (&self.unknown_opcode_categories) |*category| category.deinit(allocator);
        for (&self.aggregate_surface_categories) |*category| category.deinit(allocator);
        for (&self.boundary_categories) |*category| category.deinit(allocator);
        freeOpcodeCountMap(allocator, &self.opcode_counts);
        freeStringCountMap(allocator, &self.data_kind_counts);
        freeUnknownOpcodePairMap(allocator, &self.unknown_opcode_pair_counts);
        freeStringCountMap(allocator, &self.callconv_counts);
    }
};

const CounterSnapshot = struct {
    calls: usize,
    runtime_symbols: usize,
    unsupported_categories: [unsupported_category_count]usize,
};

const CandidateRow = struct {
    source: []const u8,
    function: []const u8,
    instruction_count: usize,
    signature_class: []const u8,
    call_class: []const u8,
    global_refs: usize,
    runtime_refs: usize,
    determinism: []const u8,
    harnessable_reason: []const u8,
    sort_bucket: usize,

    fn deinit(self: CandidateRow, allocator: std.mem.Allocator) void {
        allocator.free(self.source);
        allocator.free(self.function);
        allocator.free(self.harnessable_reason);
    }
};

const CandidateRows = struct {
    rows: std.ArrayList(CandidateRow) = .empty,

    fn deinit(self: *CandidateRows, allocator: std.mem.Allocator) void {
        for (self.rows.items) |row| row.deinit(allocator);
        self.rows.deinit(allocator);
    }
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const options = try parseOptions(init.minimal.args);

    const zig_emitter_env = init.minimal.environ.getAlloc(allocator, "ZIG_EMITTER") catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => return err,
    };
    defer if (zig_emitter_env) |value| allocator.free(value);
    const zig_emitter = zig_emitter_env orelse "../ziglang/build/stage4/bin/zig";
    std.Io.Dir.cwd().access(io, zig_emitter, .{ .execute = true }) catch {
        return error.MissingZigAirEmitter;
    };

    const modes = [_]Mode{ .ReleaseFast, .ReleaseSafe, .ReleaseSmall };
    for (modes) |mode| {
        if (!modeSelected(options, mode)) continue;
        if (options.slice == .runtime_libs or options.slice == .all) {
            try runSlice(init, zig_emitter, mode, .runtime_libs);
        }
        if (options.slice == .compiler_core or options.slice == .all) {
            try runSlice(init, zig_emitter, mode, .compiler_core);
        }
        if (options.slice == .compiler_core_module or options.slice == .all) {
            try runCompilerCoreModuleSlice(init, zig_emitter, mode, options.preserve_temp, options.real_candidates_tsv);
        }
    }
}

fn parseOptions(args: std.process.Args) !Options {
    var options: Options = .{};
    var iterator = std.process.Args.Iterator.init(args);
    _ = iterator.skip();
    while (iterator.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "--slice=")) {
            options.slice = try InventorySlice.parse(arg["--slice=".len..]);
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            const value = arg["--mode=".len..];
            if (std.mem.eql(u8, value, "all")) {
                options.mode = null;
            } else {
                options.mode = try Mode.parse(value);
            }
        } else if (std.mem.eql(u8, arg, "--preserve-temp")) {
            options.preserve_temp = true;
        } else if (std.mem.startsWith(u8, arg, "--real-candidates-tsv=")) {
            options.real_candidates_tsv = arg["--real-candidates-tsv=".len..];
        } else {
            return error.UnsupportedDistributionInventoryArgument;
        }
    }
    return options;
}

fn modeSelected(options: Options, mode: Mode) bool {
    return if (options.mode) |selected| selected == mode else true;
}

fn runSlice(init: std.process.Init, zig_emitter: []const u8, mode: Mode, slice: InventorySlice) !void {
    const allocator = init.gpa;
    const io = init.io;

    const temp_path = try std.fmt.allocPrint(
        allocator,
        "tmp/distribution_zig_air_inventory_{s}_{s}_{}",
        .{ slice.cliName(), mode.lowerName(), std.os.linux.getpid() },
    );
    defer allocator.free(temp_path);
    try std.Io.Dir.cwd().createDirPath(io, temp_path);
    defer std.Io.Dir.cwd().deleteTree(io, temp_path) catch {};

    var counters: Counters = .{};
    defer counters.deinit(allocator);
    counters.instruction_payload_scan = 1;
    if (slice == .compiler_core) counters.standalone_source_probe = 1;

    const sources = sourcesForSlice(slice);
    for (sources) |source| {
        counters.sources += 1;
        std.Io.Dir.cwd().access(io, source.path, .{ .read = true }) catch |err| {
            if (sliceAllowsBoundaries(slice)) {
                try noteBoundary(allocator, &counters, .parse_import, source.path, "missing-source");
                std.debug.print("inventory-boundary slice={s} mode={s} source={s} category=parse-import reason=missing-source error={s}\n", .{ slice.cliName(), mode.name(), source.path, @errorName(err) });
                continue;
            }
            std.debug.print("inventory-source-missing slice={s} path={s} error={s}\n", .{ slice.cliName(), source.path, @errorName(err) });
            return error.MissingDistributionInventorySource;
        };

        const stem = std.fs.path.stem(source.path);
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
            target_triple,
            source.path,
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
                if (sliceAllowsBoundaries(slice)) {
                    const boundary = classifyBoundary(emit_result.stderr);
                    try noteBoundary(allocator, &counters, boundary.category, source.path, boundary.reason);
                    std.debug.print(
                        "inventory-boundary slice={s} mode={s} source={s} category={s} reason={s} stderr={s}\n",
                        .{ slice.cliName(), mode.name(), source.path, boundary.category.name(), boundary.reason, firstLine(emit_result.stderr) },
                    );
                    continue;
                }
                std.debug.print(
                    "inventory-air-export-failure slice={s} mode={s} source={s} exit_code={} stdout={s} stderr={s}\n",
                    .{ slice.cliName(), mode.name(), source.path, code, firstLine(emit_result.stdout), firstLine(emit_result.stderr) },
                );
                return error.ZigAirInventoryExportFailed;
            },
            else => {
                if (sliceAllowsBoundaries(slice)) {
                    try noteBoundary(allocator, &counters, .non_standalone, source.path, "non-exited-air-export");
                    std.debug.print(
                        "inventory-boundary slice={s} mode={s} source={s} category=non-standalone reason=non-exited-air-export term={s}\n",
                        .{ slice.cliName(), mode.name(), source.path, termName(emit_result.term) },
                    );
                    continue;
                }
                std.debug.print(
                    "inventory-air-export-failure slice={s} mode={s} source={s} term={s} stdout={s} stderr={s}\n",
                    .{ slice.cliName(), mode.name(), source.path, termName(emit_result.term), firstLine(emit_result.stdout), firstLine(emit_result.stderr) },
                );
                return error.ZigAirInventoryExportFailed;
            },
        }

        const descriptor = try std.Io.Dir.cwd().readFileAlloc(
            io,
            descriptor_path,
            allocator,
            .limited(512 * 1024 * 1024),
        );
        defer allocator.free(descriptor);

        var parsed = air_export.parse(allocator, descriptor) catch |err| {
            if (sliceAllowsBoundaries(slice)) {
                try noteBoundary(allocator, &counters, .parse_import, source.path, @errorName(err));
                std.debug.print(
                    "inventory-boundary slice={s} mode={s} source={s} category=parse-import reason=parse-{s}\n",
                    .{ slice.cliName(), mode.name(), source.path, @errorName(err) },
                );
                continue;
            }
            std.debug.print(
                "inventory-parse-failure slice={s} mode={s} source={s} error={s}\n",
                .{ slice.cliName(), mode.name(), source.path, @errorName(err) },
            );
            return error.ZigAirInventoryParseFailed;
        };
        defer parsed.deinit();

        try accountModule(allocator, &counters, source, parsed);
    }

    try printSummary(allocator, slice, mode, counters);
}

fn sourcesForSlice(slice: InventorySlice) []const DistributionSource {
    return switch (slice) {
        .runtime_libs => &runtime_lib_sources,
        .compiler_core => &compiler_core_sources,
        .compiler_core_module => &.{},
        .all => &.{},
    };
}

fn sliceAllowsBoundaries(slice: InventorySlice) bool {
    return switch (slice) {
        .runtime_libs => false,
        .compiler_core => true,
        .compiler_core_module => false,
        .all => unreachable,
    };
}

fn runCompilerCoreModuleSlice(
    init: std.process.Init,
    zig_emitter: []const u8,
    mode: Mode,
    preserve_success_temp: bool,
    real_candidates_tsv: ?[]const u8,
) !void {
    const allocator = init.gpa;
    const io = init.io;
    const slice = InventorySlice.compiler_core_module;

    const temp_path = try std.fmt.allocPrint(
        allocator,
        "tmp/distribution_zig_air_inventory_{s}_{s}_{}",
        .{ slice.cliName(), mode.lowerName(), std.os.linux.getpid() },
    );
    defer allocator.free(temp_path);
    try std.Io.Dir.cwd().createDirPath(io, temp_path);
    var preserve_temp = false;
    defer if (!preserve_temp) std.Io.Dir.cwd().deleteTree(io, temp_path) catch {};

    const descriptor_path = try std.fs.path.join(allocator, &.{ temp_path, "compiler.air" });
    defer allocator.free(descriptor_path);
    const zig_cache_path = try std.fs.path.join(allocator, &.{ temp_path, "zig-cache" });
    defer allocator.free(zig_cache_path);
    const stdout_path = try std.fs.path.join(allocator, &.{ temp_path, "zig-build.stdout" });
    defer allocator.free(stdout_path);
    const stderr_path = try std.fs.path.join(allocator, &.{ temp_path, "zig-build.stderr" });
    defer allocator.free(stderr_path);

    printCompilerCoreModuleProgress(slice, mode, descriptor_path, "prepare");

    var env_map = try cloneEnvironment(allocator, init.environ_map);
    defer env_map.deinit();
    try env_map.put("ZLLVM_AIR_EXPORT_PATH", descriptor_path);

    const argv = [_][]const u8{
        zig_emitter,
        "build",
        "--build-file",
        "../ziglang/build.zig",
        "--cache-dir",
        zig_cache_path,
        "-Dno-bin",
        "-Dno-lib",
        "-Dno-langref",
        "-Ddebug-extensions=true",
        "-Dtarget=x86_64-linux-gnu",
        mode.zigBuildOptimizeArg(),
    };
    printCompilerCoreModuleProgress(slice, mode, descriptor_path, "zig-build-start");
    const build_result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .environ_map = &env_map,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer {
        allocator.free(build_result.stdout);
        allocator.free(build_result.stderr);
    }
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = stdout_path, .data = build_result.stdout });
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = stderr_path, .data = build_result.stderr });
    switch (build_result.term) {
        .exited => |code| if (code != 0) {
            preserve_temp = true;
            std.debug.print(
                "inventory-module-context-failure slice={s} mode={s} exit_code={} temp_path={s} export_path={s} stdout_path={s} stderr_path={s} stdout={s} stderr={s}\n",
                .{
                    slice.cliName(),
                    mode.name(),
                    code,
                    temp_path,
                    descriptor_path,
                    stdout_path,
                    stderr_path,
                    firstLine(build_result.stdout),
                    firstLine(build_result.stderr),
                },
            );
            return error.ZigCompilerModuleInventoryFailed;
        },
        else => {
            preserve_temp = true;
            std.debug.print(
                "inventory-module-context-failure slice={s} mode={s} term={s} temp_path={s} export_path={s} stdout_path={s} stderr_path={s} stdout={s} stderr={s}\n",
                .{
                    slice.cliName(),
                    mode.name(),
                    termName(build_result.term),
                    temp_path,
                    descriptor_path,
                    stdout_path,
                    stderr_path,
                    firstLine(build_result.stdout),
                    firstLine(build_result.stderr),
                },
            );
            return error.ZigCompilerModuleInventoryFailed;
        },
    }
    printCompilerCoreModuleProgress(slice, mode, descriptor_path, "zig-build-complete");

    var counters: Counters = .{
        .sources = 1,
        .inventory_ok_sources = 1,
        .real_module_context = 1,
        .generated_imports_available = 1,
        .stubbed_imports = 0,
        .instruction_payload_scan = 1,
    };
    defer counters.deinit(allocator);
    var candidate_rows: CandidateRows = .{};
    defer candidate_rows.deinit(allocator);
    printCompilerCoreModuleProgress(slice, mode, descriptor_path, "descriptor-scan-start");
    try scanLargeDescriptor(
        allocator,
        io,
        descriptor_path,
        &counters,
        "../ziglang/src/main.zig",
        if (real_candidates_tsv != null) &candidate_rows else null,
    );
    std.debug.print(
        "inventory-progress slice={s} mode={s} phase=descriptor-scan-complete export_path={s} functions={} instructions_total={}\n",
        .{ slice.cliName(), mode.name(), descriptor_path, counters.functions, counters.instructions_total },
    );
    printCompilerCoreModuleProgress(slice, mode, descriptor_path, "validate-start");
    if (counters.functions <= 1) {
        std.debug.print(
            "inventory-module-context-failure slice={s} mode={s} reason=insufficient-function-count functions={}\n",
            .{ slice.cliName(), mode.name(), counters.functions },
        );
        return error.ZigCompilerModuleInventoryTooSmall;
    }
    if (counters.functions_with_body == 0 or counters.instructions_total == 0) {
        std.debug.print(
            "inventory-module-context-failure slice={s} mode={s} reason=missing-body-scan functions={} functions_with_body={} instructions_total={}\n",
            .{ slice.cliName(), mode.name(), counters.functions, counters.functions_with_body, counters.instructions_total },
        );
        return error.ZigCompilerModuleInventoryMissingBodyScan;
    }
    printCompilerCoreModuleProgress(slice, mode, descriptor_path, "summary-start");
    try printSummary(allocator, slice, mode, counters);
    if (real_candidates_tsv) |path| {
        try writeRealCandidatesTsv(allocator, io, path, slice, mode, &candidate_rows);
    }
    if (preserve_success_temp) {
        preserve_temp = true;
        std.debug.print(
            "inventory-progress slice={s} mode={s} phase=preserve-temp temp_path={s} export_path={s} stdout_path={s} stderr_path={s}\n",
            .{ slice.cliName(), mode.name(), temp_path, descriptor_path, stdout_path, stderr_path },
        );
    }
    printCompilerCoreModuleProgress(slice, mode, descriptor_path, "complete");
}

fn printCompilerCoreModuleProgress(
    slice: InventorySlice,
    mode: Mode,
    export_path: []const u8,
    phase: []const u8,
) void {
    std.debug.print(
        "inventory-progress slice={s} mode={s} phase={s} export_path={s}\n",
        .{ slice.cliName(), mode.name(), phase, export_path },
    );
}

fn accountModule(
    allocator: std.mem.Allocator,
    counters: *Counters,
    source: DistributionSource,
    module: air_export.Module,
) !void {
    counters.inventory_ok_sources += 1;
    counters.modules += 1;
    counters.globals += module.globals.len;
    if (module.aggregate_layout_facts) |provider| counters.aggregate_layout_facts += provider.facts.len;

    var function_names = std.StringHashMap(void).init(allocator);
    defer function_names.deinit();
    for (module.functions) |function| try function_names.put(function.name, {});

    for (module.globals) |global| {
        if (global.is_constant) counters.constant_globals += 1;
        if (!std.mem.eql(u8, global.thread_local, "default")) counters.tls_globals += 1;
        accountTextFeatures(allocator, counters, source.path, "global", global.type_text, null) catch |err| return err;
        if (global.initializer_text) |initializer| {
            accountTextFeatures(allocator, counters, source.path, "global", initializer, null) catch |err| return err;
        }
        if (isRuntimeSymbol(global.name)) counters.runtime_symbols += 1;
    }

    for (module.functions) |function| {
        counters.functions += 1;
        if (function.instruction_count == 0) {
            counters.declarations_without_body += 1;
        } else {
            counters.functions_with_body += 1;
        }
        if (isProbablyExportedFunction(function.name)) counters.exported_functions += 1;
        if (isProbablyComptimeFunction(function.name)) counters.comptime_functions += 1;
        if (isRuntimeSymbol(function.name)) counters.runtime_symbols += 1;

        var unsupported_in_function = false;
        accountFunctionType(allocator, counters, source.path, function.name, function.type_text, &unsupported_in_function) catch |err| return err;

        if (function.structured_air_v2) |typed| {
            for (typed.instructions) |instruction| {
                accountTypedInstruction(
                    allocator,
                    counters,
                    source.path,
                    function.name,
                    instruction,
                    &function_names,
                    &unsupported_in_function,
                ) catch |err| return err;
            }
        } else {
            for (function.instructions) |instruction| {
                accountLegacyInstruction(
                    allocator,
                    counters,
                    source.path,
                    function.name,
                    instruction,
                    &unsupported_in_function,
                ) catch |err| return err;
            }
        }

        if (unsupported_in_function) counters.unsupported_functions += 1;
    }
}

fn scanLargeDescriptor(
    allocator: std.mem.Allocator,
    io: std.Io,
    descriptor_path: []const u8,
    counters: *Counters,
    source_path: []const u8,
    candidates: ?*CandidateRows,
) !void {
    const file = try std.Io.Dir.cwd().openFile(io, descriptor_path, .{});
    defer file.close(io);
    var file_buffer: [128 * 1024]u8 = undefined;
    var reader_state = file.reader(io, &file_buffer);
    const reader = &reader_state.interface;

    try expectLine(reader, "zllvm-air-export-v1");
    _ = try readValueLine(reader, "contract_version");
    _ = try readValueLine(reader, "payload");
    _ = try readValueLine(reader, "producer");
    _ = try readValueLine(reader, "root_source");
    _ = try readValueLine(reader, "wrapper");
    _ = try readValueLine(reader, "mode");
    _ = try readValueLine(reader, "target");
    const function_count = try parseUnsignedLine(usize, try readValueLine(reader, "function_count"));
    const global_count = try parseUnsignedLine(usize, try readValueLine(reader, "global_count"));
    counters.modules += 1;
    counters.globals += global_count;

    for (0..global_count) |_| {
        try expectLine(reader, "global_begin");
        const global_name = try readFramedSmall(allocator, reader, "name_bytes");
        defer allocator.free(global_name);
        const type_text = try readFramedSmall(allocator, reader, "type_bytes");
        defer allocator.free(type_text);
        const thread_local = try readValueLine(reader, "thread_local");
        const constant = try readValueLine(reader, "constant");
        if (!std.mem.eql(u8, thread_local, "default")) counters.tls_globals += 1;
        if (std.mem.eql(u8, constant, "true")) counters.constant_globals += 1;
        try accountTextFeatures(allocator, counters, source_path, "global", type_text, null);
        if (isRuntimeSymbol(global_name)) counters.runtime_symbols += 1;
        const next = try takeLine(reader);
        if (std.mem.startsWith(u8, next, "initializer_bytes=")) {
            const len = try parseUnsignedLine(usize, next["initializer_bytes=".len..]);
            try scanFramedText(allocator, reader, len, counters, source_path, "global", null);
            try expectLine(reader, "global_end");
        } else if (!std.mem.eql(u8, next, "global_end")) {
            return error.InvalidInventoryDescriptor;
        }
    }

    var pending_function_begin: ?[]const u8 = null;
    if (function_count > 0) {
        while (true) {
            const line = try takeLine(reader);
            if (std.mem.startsWith(u8, line, "aggregate_layout_facts_bytes=")) {
                const len = try parseUnsignedLine(usize, line["aggregate_layout_facts_bytes=".len..]);
                counters.aggregate_layout_facts += try countAggregateLayoutFactsFrame(reader, len);
                continue;
            }
            if (std.mem.startsWith(u8, line, "error_union_call_facts_bytes=")) {
                const len = try parseUnsignedLine(usize, line["error_union_call_facts_bytes=".len..]);
                try skipFramedBytes(reader, len);
                continue;
            }
            pending_function_begin = line;
            break;
        }
    }

    for (0..function_count) |_| {
        if (pending_function_begin) |line| {
            if (!std.mem.eql(u8, line, "function_begin")) return error.InvalidInventoryDescriptor;
            pending_function_begin = null;
        } else {
            try expectLine(reader, "function_begin");
        }
        const function_name = try readFramedSmall(allocator, reader, "name_bytes");
        defer allocator.free(function_name);
        const type_text = try readFramedSmall(allocator, reader, "type_bytes");
        defer allocator.free(type_text);
        const instruction_count = try parseUnsignedLine(usize, try readValueLine(reader, "instruction_count"));
        _ = try readValueLine(reader, "main_body_count");
        _ = try readValueLine(reader, "liveness");

        counters.functions += 1;
        if (instruction_count == 0) {
            counters.declarations_without_body += 1;
        } else {
            counters.functions_with_body += 1;
        }
        if (isProbablyExportedFunction(function_name)) counters.exported_functions += 1;
        if (isProbablyComptimeFunction(function_name)) counters.comptime_functions += 1;
        if (isRuntimeSymbol(function_name)) counters.runtime_symbols += 1;

        var unsupported_in_function = false;
        const before_candidate = snapshotCounters(counters);
        const signature_class = classifySignature(function_name, type_text, instruction_count);
        try accountFunctionType(allocator, counters, source_path, function_name, type_text, &unsupported_in_function);
        var candidate_global_refs: usize = 0;

        var line = try takeLine(reader);
        if (!std.mem.startsWith(u8, line, "air_bytes=")) return error.InvalidInventoryDescriptor;
        const air_len = try parseUnsignedLine(usize, line["air_bytes=".len..]);
        try skipFramedBytes(reader, air_len);

        line = try takeLine(reader);
        if (std.mem.startsWith(u8, line, "structured_air_bytes=")) {
            const len = try parseUnsignedLine(usize, line["structured_air_bytes=".len..]);
            try skipFramedBytes(reader, len);
            line = try takeLine(reader);
        }
        if (!std.mem.startsWith(u8, line, "structured_air_v2_bytes=")) {
            if (instruction_count > 0) return error.ZigCompilerModuleInventoryMissingTypedBody;
        } else {
            const typed_text = try readFramedSmallFromValueLine(allocator, reader, line, "structured_air_v2_bytes");
            defer allocator.free(typed_text);
            if (instruction_count > 0 and typed_text.len == 0) return error.ZigCompilerModuleInventoryMissingTypedBody;
            candidate_global_refs = countGlobalRefs(typed_text);
            const scanned_instruction_count = try scanStructuredAirV2Text(allocator, counters, source_path, function_name, typed_text, &unsupported_in_function);
            if (instruction_count > 0 and scanned_instruction_count != instruction_count) {
                return error.ZigCompilerModuleInventoryIncompleteTypedBody;
            }
            line = try takeLine(reader);
        }
        if (!std.mem.eql(u8, line, "function_end")) return error.InvalidInventoryDescriptor;
        if (unsupported_in_function) counters.unsupported_functions += 1;
        if (candidates) |candidate_rows| {
            try appendCandidateRow(
                allocator,
                candidate_rows,
                source_path,
                function_name,
                instruction_count,
                signature_class,
                candidate_global_refs,
                before_candidate,
                snapshotCounters(counters),
            );
        }
    }
}

fn snapshotCounters(counters: *const Counters) CounterSnapshot {
    var unsupported_categories: [unsupported_category_count]usize = undefined;
    inline for (std.meta.fields(UnsupportedCategory)) |field| {
        unsupported_categories[field.value] = counters.unsupported_categories[field.value].count;
    }
    return .{
        .calls = counters.calls,
        .runtime_symbols = counters.runtime_symbols,
        .unsupported_categories = unsupported_categories,
    };
}

fn classifySignature(function: []const u8, type_text: []const u8, instruction_count: usize) []const u8 {
    if (instruction_count == 0 or isProbablyComptimeFunction(function)) return "not-callable";
    const capability = air_capabilities.typeSurfaceCapability(type_text);
    if (capability.varargs or
        capability.vector or
        capability.x87 or
        capability.packed_or_unaligned_aggregate or
        capability.aggregate_abi)
    {
        return "not-callable";
    }
    if (containsAny(type_text, &.{ "callconv(.c)", "callconv(.C)" })) return "C-ABI-stable";
    if (contains(type_text, "callconv")) return "not-callable";
    return "internal-callable";
}

fn appendCandidateRow(
    allocator: std.mem.Allocator,
    rows: *CandidateRows,
    source: []const u8,
    function: []const u8,
    instruction_count: usize,
    signature_class: []const u8,
    global_refs: usize,
    before: CounterSnapshot,
    after: CounterSnapshot,
) !void {
    const call_count = after.calls - before.calls;
    const runtime_refs = after.runtime_symbols - before.runtime_symbols;
    const unsupported_category = firstUnsupportedCategory(before, after);
    const call_class: []const u8 = if (call_count == 0) "leaf" else "external";
    const reason = try candidateReason(allocator, unsupported_category, signature_class, call_count, global_refs, runtime_refs);
    errdefer allocator.free(reason);
    const source_copy = try allocator.dupe(u8, source);
    errdefer allocator.free(source_copy);
    const function_copy = try allocator.dupe(u8, function);
    errdefer allocator.free(function_copy);
    try rows.rows.append(allocator, .{
        .source = source_copy,
        .function = function_copy,
        .instruction_count = instruction_count,
        .signature_class = signature_class,
        .call_class = call_class,
        .global_refs = global_refs,
        .runtime_refs = runtime_refs,
        .determinism = "assumed_nondeterministic",
        .harnessable_reason = reason,
        .sort_bucket = candidateSortBucket(unsupported_category, signature_class, call_count, global_refs, runtime_refs),
    });
}

fn firstUnsupportedCategory(before: CounterSnapshot, after: CounterSnapshot) ?UnsupportedCategory {
    inline for (std.meta.fields(UnsupportedCategory)) |field| {
        if (after.unsupported_categories[field.value] > before.unsupported_categories[field.value]) {
            return @enumFromInt(field.value);
        }
    }
    return null;
}

fn candidateReason(
    allocator: std.mem.Allocator,
    unsupported_category: ?UnsupportedCategory,
    signature_class: []const u8,
    call_count: usize,
    global_refs: usize,
    runtime_refs: usize,
) ![]const u8 {
    if (unsupported_category) |category| {
        return std.fmt.allocPrint(allocator, "proven_unharnessable:unsupported-{s}", .{category.name()});
    }
    if (std.mem.eql(u8, signature_class, "not-callable")) {
        return allocator.dupe(u8, "proven_unharnessable:signature");
    }
    if (runtime_refs > 0) return allocator.dupe(u8, "not_yet_analyzed:runtime_refs");
    if (global_refs > 0) return allocator.dupe(u8, "not_yet_analyzed:global_refs");
    if (call_count > 0) return allocator.dupe(u8, "not_yet_analyzed:callee_closure");
    return allocator.dupe(u8, "harnessable:leaf_no_refs_supported");
}

fn candidateSortBucket(
    unsupported_category: ?UnsupportedCategory,
    signature_class: []const u8,
    call_count: usize,
    global_refs: usize,
    runtime_refs: usize,
) usize {
    if (unsupported_category != null) return 500;
    if (std.mem.eql(u8, signature_class, "not-callable")) return 400;
    if (runtime_refs > 0) return 300;
    if (global_refs > 0) return 200;
    if (call_count > 0) return 100;
    return 0;
}

fn countGlobalRefs(text: []const u8) usize {
    var count: usize = 0;
    var index: usize = 0;
    while (std.mem.indexOfScalarPos(u8, text, index, '@')) |at| {
        const next_index = at + 1;
        if (next_index < text.len and (std.ascii.isAlphabetic(text[next_index]) or text[next_index] == '_')) {
            count += 1;
        }
        index = next_index;
    }
    return count;
}

fn scanFramedText(
    allocator: std.mem.Allocator,
    reader: *std.Io.Reader,
    len: usize,
    counters: *Counters,
    source: []const u8,
    function: []const u8,
    unsupported_in_function: ?*bool,
) !void {
    var remaining = len;
    while (remaining > 0) {
        const chunk_len = @min(remaining, 64 * 1024);
        const chunk = try reader.take(chunk_len);
        accountChunkFeatures(allocator, counters, source, function, chunk, unsupported_in_function) catch |err| return err;
        remaining -= chunk.len;
    }
    try reader.discardAll(1);
}

fn skipFramedBytes(reader: *std.Io.Reader, len: usize) !void {
    try reader.discardAll64(len);
    try reader.discardAll(1);
}

fn countAggregateLayoutFactsFrame(reader: *std.Io.Reader, len: usize) !usize {
    var remaining = len;
    var count: usize = 0;
    var at_line_start = true;
    var matching_fact_prefix: usize = 0;
    const fact_prefix = "fact ";
    while (remaining > 0) {
        const chunk_len = @min(remaining, 64 * 1024);
        const chunk = try reader.take(chunk_len);
        for (chunk) |byte| {
            if (at_line_start) {
                if (byte == fact_prefix[matching_fact_prefix]) {
                    matching_fact_prefix += 1;
                    if (matching_fact_prefix == fact_prefix.len) {
                        count += 1;
                        at_line_start = false;
                        matching_fact_prefix = 0;
                    }
                    continue;
                }
                at_line_start = false;
                matching_fact_prefix = 0;
            }
            if (byte == '\n') {
                at_line_start = true;
                matching_fact_prefix = 0;
            }
        }
        remaining -= chunk.len;
    }
    try reader.discardAll(1);
    return count;
}

fn accountChunkFeatures(
    allocator: std.mem.Allocator,
    counters: *Counters,
    source: []const u8,
    function: []const u8,
    text: []const u8,
    unsupported_in_function: ?*bool,
) !void {
    counters.calls += countAny(text, &.{ "\n  call", "\ncall", " opcode=call", " opcode=call_always_tail" });
    counters.switches += countAny(text, &.{ "switch_br", "\nswitch" });
    counters.loops += countAny(text, &.{ "\n  loop", "\nloop", " opcode=loop", " opcode=repeat" });
    counters.branches += countAny(text, &.{ "cond_br", "\n  br", "\nbr", " opcode=br", " opcode=cond_br", "block" });
    counters.atomics += countAny(text, &.{ "atomic", "cmpxchg", "fence" });
    counters.inline_asm += countAny(text, &.{ "assembly", " inline_asm", " asm" });
    try accountTextFeatures(allocator, counters, source, function, text, unsupported_in_function);
}

fn scanStructuredAirV2Text(
    allocator: std.mem.Allocator,
    counters: *Counters,
    source: []const u8,
    function: []const u8,
    text: []const u8,
    unsupported_in_function: *bool,
) !usize {
    var lines = std.mem.splitScalar(u8, text, '\n');
    const header = lines.next() orelse return error.InvalidStructuredAirV2;
    if (!std.mem.eql(u8, header, "structured_air-v2")) return error.InvalidStructuredAirV2;
    var saw_end = false;
    var instruction_count: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.eql(u8, line, "structured_air_v2_end")) {
            saw_end = true;
            break;
        }
        try accountStructuredAirV2Line(allocator, counters, source, function, line, unsupported_in_function);
        instruction_count += 1;
    }
    if (!saw_end) return error.InvalidStructuredAirV2;
    return instruction_count;
}

fn accountStructuredAirV2Line(
    allocator: std.mem.Allocator,
    counters: *Counters,
    source: []const u8,
    function: []const u8,
    line: []const u8,
    unsupported_in_function: *bool,
) !void {
    var fields: PipeCursor = .{ .line = line };
    const kind = try fields.readField();
    if (!std.mem.eql(u8, kind, "typed_inst")) return error.InvalidStructuredAirV2;
    _ = try parseUnsignedLine(u32, try fields.readField());
    const opcode = try fields.readField();
    const result_type = try fields.readFramedField(true);
    const data_kind = try fields.readField();
    const operand_count = try parseUnsignedLine(usize, try fields.readField());
    const text_context = textFeatureContextForOpcode(opcode);

    try accountOpcode(allocator, counters, source, function, opcode, data_kind, unsupported_in_function);
    try accountTextFeaturesInContext(allocator, counters, source, function, result_type, text_context, unsupported_in_function);
    try accountTextFeatures(allocator, counters, source, function, data_kind, unsupported_in_function);

    for (0..operand_count) |operand_index| {
        const operand_kind = try fields.readField();
        const value = try fields.readFramedField(true);
        const type_text = try fields.readFramedField(operand_index + 1 < operand_count);
        try accountTextFeatures(allocator, counters, source, function, operand_kind, unsupported_in_function);
        try accountTextFeatures(allocator, counters, source, function, value, unsupported_in_function);
        try accountTextFeaturesInContext(allocator, counters, source, function, type_text, text_context, unsupported_in_function);
        if (isCallOpcode(opcode) and isRuntimeSymbol(value)) counters.runtime_symbols += 1;
    }

    if (!fields.done()) {
        const detail_count_text = try fields.readField();
        const detail_count = try parseUnsignedLine(usize, detail_count_text);
        for (0..detail_count) |detail_index| {
            const detail_key = try fields.readField();
            const detail_value = try fields.readFramedField(detail_index + 1 < detail_count);
            try accountTextFeatures(allocator, counters, source, function, detail_key, unsupported_in_function);
            try accountTextFeaturesInContext(allocator, counters, source, function, detail_value, text_context, unsupported_in_function);
            if (isCallOpcode(opcode)) {
                if (maybeDetailCalleeText(detail_key, detail_value)) |callee| {
                    if (isRuntimeSymbol(callee)) counters.runtime_symbols += 1;
                }
            }
        }
    }
    if (!fields.done()) return error.InvalidStructuredAirV2;
}

const PipeCursor = struct {
    line: []const u8,
    index: usize = 0,

    fn done(self: PipeCursor) bool {
        return self.index >= self.line.len;
    }

    fn readField(self: *PipeCursor) ![]const u8 {
        if (self.index > self.line.len) return error.InvalidStructuredAirV2;
        const start = self.index;
        const relative_end = std.mem.indexOfScalar(u8, self.line[start..], '|') orelse {
            self.index = self.line.len;
            return self.line[start..];
        };
        const end = start + relative_end;
        self.index = end + 1;
        return self.line[start..end];
    }

    fn readFramedField(self: *PipeCursor, expect_more: bool) ![]const u8 {
        const len = try parseUnsignedLine(usize, try self.readField());
        if (self.index + len > self.line.len) return error.InvalidStructuredAirV2;
        const start = self.index;
        const end = start + len;
        self.index = end;
        if (expect_more) {
            if (self.index >= self.line.len or self.line[self.index] != '|') return error.InvalidStructuredAirV2;
            self.index += 1;
        } else if (self.index < self.line.len) {
            if (self.line[self.index] != '|') return error.InvalidStructuredAirV2;
            self.index += 1;
        }
        return self.line[start..end];
    }
};

fn readFramedSmall(allocator: std.mem.Allocator, reader: *std.Io.Reader, prefix: []const u8) ![]u8 {
    const line = try readValueLine(reader, prefix);
    return readFramedSmallFromValue(allocator, reader, line);
}

fn readFramedSmallFromValueLine(
    allocator: std.mem.Allocator,
    reader: *std.Io.Reader,
    line: []const u8,
    prefix: []const u8,
) ![]u8 {
    if (!std.mem.startsWith(u8, line, prefix) or line.len <= prefix.len or line[prefix.len] != '=') {
        return error.InvalidInventoryDescriptor;
    }
    return readFramedSmallFromValue(allocator, reader, line[prefix.len + 1 ..]);
}

fn readFramedSmallFromValue(allocator: std.mem.Allocator, reader: *std.Io.Reader, line: []const u8) ![]u8 {
    const len = try parseUnsignedLine(usize, line);
    var copy = try allocator.alloc(u8, len);
    errdefer allocator.free(copy);
    var offset: usize = 0;
    while (offset < len) {
        const chunk_len = @min(len - offset, 32 * 1024);
        const bytes = try reader.take(chunk_len);
        @memcpy(copy[offset..][0..bytes.len], bytes);
        offset += bytes.len;
    }
    try reader.discardAll(1);
    return copy;
}

fn readValueLine(reader: *std.Io.Reader, key: []const u8) ![]const u8 {
    const line = try takeLine(reader);
    if (!std.mem.startsWith(u8, line, key) or line.len <= key.len or line[key.len] != '=') {
        return error.InvalidInventoryDescriptor;
    }
    return line[key.len + 1 ..];
}

fn expectLine(reader: *std.Io.Reader, expected: []const u8) !void {
    const line = try takeLine(reader);
    if (!std.mem.eql(u8, line, expected)) return error.InvalidInventoryDescriptor;
}

fn takeLine(reader: *std.Io.Reader) ![]const u8 {
    const line = try reader.takeDelimiterInclusive('\n');
    return std.mem.trim(u8, line, "\r\n");
}

fn parseUnsignedLine(comptime T: type, value: []const u8) !T {
    return std.fmt.parseUnsigned(T, value, 10);
}

fn accountFunctionType(
    allocator: std.mem.Allocator,
    counters: *Counters,
    source: []const u8,
    function: []const u8,
    type_text: []const u8,
    unsupported_in_function: *bool,
) !void {
    if (containsAny(type_text, &.{ "callconv(.c)", "callconv(.C)", "callconv(.c)" })) {
        counters.callconv_c += 1;
        try countString(allocator, &counters.callconv_counts, "c");
    } else if (contains(type_text, "callconv")) {
        counters.callconv_other += 1;
        try countString(allocator, &counters.callconv_counts, "other");
    } else {
        counters.callconv_default += 1;
        try countString(allocator, &counters.callconv_counts, "default");
    }
    try accountTextFeaturesInContext(allocator, counters, source, function, type_text, .abi, unsupported_in_function);
}

fn accountTypedInstruction(
    allocator: std.mem.Allocator,
    counters: *Counters,
    source: []const u8,
    function: []const u8,
    instruction: air_export.TypedInstruction,
    function_names: *std.StringHashMap(void),
    unsupported_in_function: *bool,
) !void {
    try accountOpcode(allocator, counters, source, function, instruction.opcode, instruction.data_kind, unsupported_in_function);
    const text_context = textFeatureContextForOpcode(instruction.opcode);
    try accountTextFeaturesInContext(allocator, counters, source, function, instruction.result_type, text_context, unsupported_in_function);
    try accountTextFeatures(allocator, counters, source, function, instruction.data_kind, unsupported_in_function);
    for (instruction.operands) |operand| {
        try accountTextFeatures(allocator, counters, source, function, operand.kind, unsupported_in_function);
        try accountTextFeaturesInContext(allocator, counters, source, function, operand.type_text, text_context, unsupported_in_function);
        try accountTextFeatures(allocator, counters, source, function, operand.value, unsupported_in_function);
        if (isCallOpcode(instruction.opcode)) {
            if (maybeOperandCallee(operand)) |callee| {
                if (!function_names.contains(callee)) counters.extern_imports += 1;
                if (isRuntimeSymbol(callee)) counters.runtime_symbols += 1;
            }
        }
    }
    for (instruction.details) |detail| {
        try accountTextFeatures(allocator, counters, source, function, detail.key, unsupported_in_function);
        try accountTextFeaturesInContext(allocator, counters, source, function, detail.value, text_context, unsupported_in_function);
        if (isCallOpcode(instruction.opcode)) {
            if (maybeDetailCallee(detail)) |callee| {
                if (!function_names.contains(callee)) counters.extern_imports += 1;
                if (isRuntimeSymbol(callee)) counters.runtime_symbols += 1;
            }
        }
    }
}

fn accountLegacyInstruction(
    allocator: std.mem.Allocator,
    counters: *Counters,
    source: []const u8,
    function: []const u8,
    instruction: air_export.Instruction,
    unsupported_in_function: *bool,
) !void {
    try accountOpcode(allocator, counters, source, function, instruction.opcode, instruction.payload, unsupported_in_function);
    try accountTextFeaturesInContext(allocator, counters, source, function, instruction.payload, textFeatureContextForOpcode(instruction.opcode), unsupported_in_function);
}

fn accountOpcode(
    allocator: std.mem.Allocator,
    counters: *Counters,
    source: []const u8,
    function: []const u8,
    opcode: []const u8,
    data_kind: []const u8,
    unsupported_in_function: *bool,
) !void {
    counters.instructions_total += 1;
    try countOpcode(allocator, &counters.opcode_counts, opcode, source, function);
    try countString(allocator, &counters.data_kind_counts, data_kind);

    const category = air_export.categoryForOpcode(opcode);
    switch (category) {
        .call => counters.calls += 1,
        .control_flow => {
            if (containsAny(opcode, &.{ "switch", "switch_br" })) counters.switches += 1;
            if (containsAny(opcode, &.{ "loop", "repeat" })) counters.loops += 1;
            if (containsAny(opcode, &.{ "br", "cond_br", "block" })) counters.branches += 1;
        },
        .aggregate => {
            counters.aggregate_types += 1;
            counters.aggregate_opcode_shapes += 1;
            try noteAggregateSurface(allocator, counters, .opcode_shape, source, function);
        },
        .memory => {
            if (std.mem.eql(u8, opcode, "load") or std.mem.eql(u8, opcode, "atomic_load")) counters.loads += 1;
            if (std.mem.startsWith(u8, opcode, "store") or std.mem.eql(u8, opcode, "atomic_store")) counters.stores += 1;
            if (std.mem.eql(u8, opcode, "alloc") or std.mem.eql(u8, opcode, "inferred_alloc")) counters.allocas += 1;
            if (contains(opcode, "atomic") or contains(opcode, "cmpxchg") or contains(opcode, "fence")) counters.atomics += 1;
        },
        else => {},
    }
    if (std.mem.eql(u8, opcode, "load") or std.mem.eql(u8, opcode, "atomic_load")) counters.loads += @intFromBool(category != .memory);
    if (std.mem.startsWith(u8, opcode, "store") or std.mem.eql(u8, opcode, "atomic_store")) counters.stores += @intFromBool(category != .memory);
    if (std.mem.eql(u8, opcode, "alloc") or std.mem.eql(u8, opcode, "inferred_alloc")) counters.allocas += @intFromBool(category != .memory);
    if (containsAny(opcode, &.{ "asm", "assembly" })) {
        counters.inline_asm += 1;
        try noteUnsupported(allocator, counters, .inline_asm, source, function);
        unsupported_in_function.* = true;
    }
    if (containsAny(opcode, &.{ "atomic", "cmpxchg", "fence" })) counters.atomics += 1;
    if (!air_capabilities.isInventoryKnownOpcode(opcode)) {
        counters.unsupported_opcodes += 1;
        try noteUnsupported(allocator, counters, .unknown_opcode, source, function);
        const data_kind_capability = air_capabilities.opcodeDataKindCapability(opcode, data_kind);
        try noteUnknownOpcodeCategory(allocator, counters, data_kind_capability.category, source, function);
        try noteUnknownOpcodePair(allocator, counters, data_kind_capability.category, opcode, data_kind, source, function);
        unsupported_in_function.* = true;
    }
    try accountTextFeaturesInContext(allocator, counters, source, function, data_kind, textFeatureContextForOpcode(opcode), unsupported_in_function);
}

fn accountTextFeatures(
    allocator: std.mem.Allocator,
    counters: *Counters,
    source: []const u8,
    function: []const u8,
    text: []const u8,
    unsupported_in_function: ?*bool,
) !void {
    try accountTextFeaturesInContext(allocator, counters, source, function, text, .metadata, unsupported_in_function);
}

fn accountTextFeaturesInContext(
    allocator: std.mem.Allocator,
    counters: *Counters,
    source: []const u8,
    function: []const u8,
    text: []const u8,
    context: TextFeatureContext,
    unsupported_in_function: ?*bool,
) !void {
    if (text.len == 0) return;
    const capability = air_capabilities.typeSurfaceCapability(text);
    if (capability.varargs) {
        counters.varargs_uses += 1;
        try noteUnsupportedMaybe(allocator, counters, .varargs, source, function, unsupported_in_function);
    }
    if (capability.vector) {
        counters.vector_uses += 1;
        try noteUnsupportedMaybe(allocator, counters, .vector, source, function, unsupported_in_function);
    }
    if (capability.x87) {
        counters.x87_uses += 1;
        try noteUnsupportedMaybe(allocator, counters, .x87, source, function, unsupported_in_function);
    }
    if (capability.packed_or_unaligned_aggregate) {
        counters.packed_unaligned_aggregate_uses += 1;
        try noteUnsupportedMaybe(allocator, counters, .packed_aggregate, source, function, unsupported_in_function);
    }
    if (capability.aggregate_abi) {
        counters.aggregate_types += 1;
        switch (context) {
            .metadata => {
                counters.aggregate_metadata_type_surfaces += 1;
                try noteAggregateSurface(allocator, counters, .metadata_type_surface, source, function);
            },
            .abi => {
                counters.aggregate_abi_type_surfaces += 1;
                try noteAggregateSurface(allocator, counters, .abi_type_surface, source, function);
            },
        }
        try noteUnsupportedMaybe(allocator, counters, .aggregate_abi, source, function, unsupported_in_function);
    }
    if (capability.pointer) counters.pointer_uses += 1;
    if (capability.slice) counters.slice_uses += 1;
    if (capability.optional) counters.optional_uses += 1;
    if (capability.error_union) counters.error_union_uses += 1;
    if (isRuntimeSymbol(text)) counters.runtime_symbols += 1;
}

fn noteAggregateSurface(
    allocator: std.mem.Allocator,
    counters: *Counters,
    category: AggregateSurfaceCategory,
    source: []const u8,
    function: []const u8,
) !void {
    const index = @intFromEnum(category);
    counters.aggregate_surface_categories[index].count += 1;
    if (counters.aggregate_surface_categories[index].first_source == null) {
        counters.aggregate_surface_categories[index].first_source = try allocator.dupe(u8, source);
        counters.aggregate_surface_categories[index].first_function = try allocator.dupe(u8, function);
    }
}

fn noteUnknownOpcodeCategory(
    allocator: std.mem.Allocator,
    counters: *Counters,
    category: air_capabilities.UnknownOpcodeCategory,
    source: []const u8,
    function: []const u8,
) !void {
    const index = @intFromEnum(category);
    counters.unknown_opcode_categories[index].count += 1;
    if (counters.unknown_opcode_categories[index].first_source == null) {
        counters.unknown_opcode_categories[index].first_source = try allocator.dupe(u8, source);
        counters.unknown_opcode_categories[index].first_function = try allocator.dupe(u8, function);
    }
}

fn noteUnknownOpcodePair(
    allocator: std.mem.Allocator,
    counters: *Counters,
    category: air_capabilities.UnknownOpcodeCategory,
    opcode: []const u8,
    data_kind: []const u8,
    source: []const u8,
    function: []const u8,
) !void {
    const key = try std.fmt.allocPrint(allocator, "{s}:{s}:{s}", .{ category.name(), opcode, data_kind });
    errdefer allocator.free(key);
    if (counters.unknown_opcode_pair_counts.getIndex(key)) |index| {
        allocator.free(key);
        counters.unknown_opcode_pair_counts.values()[index].count += 1;
        return;
    }
    const first_source = try allocator.dupe(u8, source);
    errdefer allocator.free(first_source);
    const first_function = try allocator.dupe(u8, function);
    errdefer allocator.free(first_function);
    try counters.unknown_opcode_pair_counts.put(allocator, key, .{
        .count = 1,
        .first_source = first_source,
        .first_function = first_function,
    });
}

fn noteUnsupportedMaybe(
    allocator: std.mem.Allocator,
    counters: *Counters,
    category: UnsupportedCategory,
    source: []const u8,
    function: []const u8,
    unsupported_in_function: ?*bool,
) !void {
    try noteUnsupported(allocator, counters, category, source, function);
    if (unsupported_in_function) |flag| flag.* = true;
}

fn noteUnsupported(
    allocator: std.mem.Allocator,
    counters: *Counters,
    category: UnsupportedCategory,
    source: []const u8,
    function: []const u8,
) !void {
    const index = @intFromEnum(category);
    counters.unsupported_categories[index].count += 1;
    if (counters.unsupported_categories[index].first_source == null) {
        counters.unsupported_categories[index].first_source = try allocator.dupe(u8, source);
        counters.unsupported_categories[index].first_function = try allocator.dupe(u8, function);
    }
}

fn noteBoundary(
    allocator: std.mem.Allocator,
    counters: *Counters,
    category: BoundaryCategory,
    source: []const u8,
    reason: []const u8,
) !void {
    counters.boundary_sources += 1;
    const index = @intFromEnum(category);
    counters.boundary_categories[index].count += 1;
    if (counters.boundary_categories[index].first_source == null) {
        counters.boundary_categories[index].first_source = try allocator.dupe(u8, source);
        counters.boundary_categories[index].first_function = try allocator.dupe(u8, reason);
    }
}

const Boundary = struct {
    category: BoundaryCategory,
    reason: []const u8,
};

fn classifyBoundary(stderr: []const u8) Boundary {
    if (containsAny(stderr, &.{
        "no module named",
        "unable to load",
        "FileNotFound",
        "not found",
        "import",
    })) {
        return .{ .category = .parse_import, .reason = classifyImportReason(stderr) };
    }
    if (containsAny(stderr, &.{
        "build_options",
        "module",
        "main module",
        "root",
        "package",
    })) {
        return .{ .category = .module_root, .reason = "requires-build-module-graph" };
    }
    if (containsAny(stderr, &.{
        "comptime",
        "unable to resolve comptime",
        "evaluation exceeded",
    })) {
        return .{ .category = .comptime_dependency, .reason = "requires-comptime-context" };
    }
    return .{ .category = .non_standalone, .reason = "non-standalone-zig-source" };
}

fn classifyImportReason(stderr: []const u8) []const u8 {
    if (contains(stderr, "build_options")) return "missing-build-options-module";
    if (contains(stderr, "config")) return "missing-config-module";
    if (contains(stderr, "target")) return "missing-target-module";
    return "missing-import-or-module";
}

fn printSummary(allocator: std.mem.Allocator, slice: InventorySlice, mode: Mode, counters: Counters) !void {
    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();
    const writer = &output.writer;

    try writer.print(
        "summary distribution-zig-air-inventory slice={s} mode={s} target={s} sources={} inventory_ok_sources={} boundary_sources={} standalone_source_probe={} real_module_context={} generated_imports_available={} stubbed_imports={} instruction_payload_scan={} modules={} functions={} functions_with_body={} declarations_without_body={} instructions_total={} exported_functions={} generic_functions={} comptime_functions={} globals={} constant_globals={} tls_globals={} extern_imports={} runtime_symbols={} calls={} callconv_default={} callconv_c={} callconv_other={}",
        .{
            slice.cliName(),
            mode.name(),
            target_triple,
            counters.sources,
            counters.inventory_ok_sources,
            counters.boundary_sources,
            counters.standalone_source_probe,
            counters.real_module_context,
            counters.generated_imports_available,
            counters.stubbed_imports,
            counters.instruction_payload_scan,
            counters.modules,
            counters.functions,
            counters.functions_with_body,
            counters.declarations_without_body,
            counters.instructions_total,
            counters.exported_functions,
            counters.comptime_functions,
            counters.comptime_functions,
            counters.globals,
            counters.constant_globals,
            counters.tls_globals,
            counters.extern_imports,
            counters.runtime_symbols,
            counters.calls,
            counters.callconv_default,
            counters.callconv_c,
            counters.callconv_other,
        },
    );
    try writer.print(
        " varargs_uses={} vector_uses={} x87_uses={} packed_unaligned_aggregate_uses={} atomics={} inline_asm={} loads={} stores={} allocas={} switches={} loops={} branches={} aggregate_types={} aggregate_opcode_shapes={} aggregate_metadata_type_surfaces={} aggregate_abi_type_surfaces={} aggregate_layout_facts={} pointer_uses={} slice_uses={} optional_uses={} error_union_uses={} unsupported_functions={} unsupported_opcodes={} local_fail=0\n",
        .{
            counters.varargs_uses,
            counters.vector_uses,
            counters.x87_uses,
            counters.packed_unaligned_aggregate_uses,
            counters.atomics,
            counters.inline_asm,
            counters.loads,
            counters.stores,
            counters.allocas,
            counters.switches,
            counters.loops,
            counters.branches,
            counters.aggregate_types,
            counters.aggregate_opcode_shapes,
            counters.aggregate_metadata_type_surfaces,
            counters.aggregate_abi_type_surfaces,
            counters.aggregate_layout_facts,
            counters.pointer_uses,
            counters.slice_uses,
            counters.optional_uses,
            counters.error_union_uses,
            counters.unsupported_functions,
            counters.unsupported_opcodes,
        },
    );
    inline for (std.meta.fields(AggregateSurfaceCategory)) |field| {
        const category: AggregateSurfaceCategory = @enumFromInt(field.value);
        const stat = counters.aggregate_surface_categories[field.value];
        try writer.print(
            "aggregate_surface slice={s} mode={s} category={s} count={} first_source={s} first_function={s}\n",
            .{
                slice.cliName(),
                mode.name(),
                category.name(),
                stat.count,
                stat.first_source orelse "-",
                stat.first_function orelse "-",
            },
        );
    }
    inline for (std.meta.fields(UnsupportedCategory)) |field| {
        const category: UnsupportedCategory = @enumFromInt(field.value);
        const stat = counters.unsupported_categories[field.value];
        try writer.print(
            "unsupported slice={s} mode={s} category={s} count={} first_source={s} first_function={s}\n",
            .{
                slice.cliName(),
                mode.name(),
                category.name(),
                stat.count,
                stat.first_source orelse "-",
                stat.first_function orelse "-",
            },
        );
    }
    try printTopUnsupported(writer, slice, mode, counters);
    inline for (std.meta.fields(air_capabilities.UnknownOpcodeCategory)) |field| {
        const category: air_capabilities.UnknownOpcodeCategory = @enumFromInt(field.value);
        const stat = counters.unknown_opcode_categories[field.value];
        try writer.print(
            "unknown_opcode slice={s} mode={s} category={s} count={} first_source={s} first_function={s}\n",
            .{
                slice.cliName(),
                mode.name(),
                category.name(),
                stat.count,
                stat.first_source orelse "-",
                stat.first_function orelse "-",
            },
        );
    }
    try printTopUnknownOpcodes(writer, slice, mode, counters);
    try printTopUnknownOpcodePairs(allocator, writer, slice, mode, counters, top_unknown_opcode_pair_limit);
    try printTopUnknownOpcodeCategoryPairs(allocator, writer, slice, mode, counters, top_unknown_opcode_category_pair_limit);
    inline for (std.meta.fields(BoundaryCategory)) |field| {
        const category: BoundaryCategory = @enumFromInt(field.value);
        const stat = counters.boundary_categories[field.value];
        try writer.print(
            "boundary slice={s} mode={s} category={s} count={} first_source={s} first_reason={s}\n",
            .{
                slice.cliName(),
                mode.name(),
                category.name(),
                stat.count,
                stat.first_source orelse "-",
                stat.first_function orelse "-",
            },
        );
    }
    for (counters.opcode_counts.keys(), counters.opcode_counts.values()) |opcode, stat| {
        try writer.print(
            "opcode slice={s} mode={s} name={s} count={} first_source={s} first_function={s}\n",
            .{
                slice.cliName(),
                mode.name(),
                opcode,
                stat.count,
                stat.first_source orelse "-",
                stat.first_function orelse "-",
            },
        );
    }
    try printTopOpcodeMap(allocator, writer, slice, mode, "top_opcode", &counters.opcode_counts, 20);
    for (counters.data_kind_counts.keys(), counters.data_kind_counts.values()) |data_kind, count| {
        try writer.print(
            "data_kind slice={s} mode={s} name={s} count={}\n",
            .{ slice.cliName(), mode.name(), data_kind, count },
        );
    }
    try printTopStringMap(allocator, writer, slice, mode, "top_data_kind", &counters.data_kind_counts, 20);
    for (counters.callconv_counts.keys(), counters.callconv_counts.values()) |callconv_name, count| {
        try writer.print(
            "callconv slice={s} mode={s} name={s} count={}\n",
            .{ slice.cliName(), mode.name(), callconv_name, count },
        );
    }
    try writeAllStdout(output.written());
}

fn writeRealCandidatesTsv(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    slice: InventorySlice,
    mode: Mode,
    rows: *CandidateRows,
) !void {
    std.sort.heap(CandidateRow, rows.rows.items, {}, candidateRowLessThan);

    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();
    const writer = &output.writer;

    try writer.writeAll("rank\tsource\tfunction\tinstruction_count\tsignature_class\tcall_class\tglobal_refs\truntime_refs\tdeterminism\tharnessable_reason\n");
    var harnessable_rows: usize = 0;
    var not_yet_analyzed_rows: usize = 0;
    var proven_unharnessable_rows: usize = 0;
    for (rows.rows.items, 1..) |row, rank| {
        if (std.mem.startsWith(u8, row.harnessable_reason, "harnessable:")) harnessable_rows += 1;
        if (std.mem.startsWith(u8, row.harnessable_reason, "not_yet_analyzed:")) not_yet_analyzed_rows += 1;
        if (std.mem.startsWith(u8, row.harnessable_reason, "proven_unharnessable:")) proven_unharnessable_rows += 1;
        try writer.print(
            "{}\t{s}\t{s}\t{}\t{s}\t{s}\t{}\t{}\t{s}\t{s}\n",
            .{
                rank,
                row.source,
                row.function,
                row.instruction_count,
                row.signature_class,
                row.call_class,
                row.global_refs,
                row.runtime_refs,
                row.determinism,
                row.harnessable_reason,
            },
        );
    }

    var cwd = std.Io.Dir.cwd();
    if (std.fs.path.dirname(path)) |dirname| try cwd.createDirPath(io, dirname);
    try cwd.writeFile(io, .{ .sub_path = path, .data = output.written() });
    std.debug.print(
        "summary distribution-real-candidates selector_version={s} slice={s} mode={s} target={s} path={s} rows={} harnessable_rows={} not_yet_analyzed_rows={} proven_unharnessable_rows={} local_fail=0\n",
        .{
            real_candidate_selector_version,
            slice.cliName(),
            mode.name(),
            target_triple,
            path,
            rows.rows.items.len,
            harnessable_rows,
            not_yet_analyzed_rows,
            proven_unharnessable_rows,
        },
    );
}

fn candidateRowLessThan(_: void, lhs: CandidateRow, rhs: CandidateRow) bool {
    if (lhs.sort_bucket != rhs.sort_bucket) return lhs.sort_bucket < rhs.sort_bucket;
    if (lhs.instruction_count != rhs.instruction_count) return lhs.instruction_count < rhs.instruction_count;
    return std.mem.lessThan(u8, lhs.function, rhs.function);
}

fn cloneEnvironment(
    allocator: std.mem.Allocator,
    source: *const std.process.Environ.Map,
) !std.process.Environ.Map {
    var result = std.process.Environ.Map.init(allocator);
    errdefer result.deinit();
    for (source.keys(), source.values()) |key, value| try result.put(key, value);
    return result;
}

const NamedCount = struct {
    name: []const u8,
    count: usize,
};

fn namedCountLessThan(_: void, lhs: NamedCount, rhs: NamedCount) bool {
    if (lhs.count != rhs.count) return lhs.count > rhs.count;
    return std.mem.lessThan(u8, lhs.name, rhs.name);
}

fn printTopStringMap(
    allocator: std.mem.Allocator,
    writer: *std.Io.Writer,
    slice: InventorySlice,
    mode: Mode,
    line_name: []const u8,
    map: *const StringCountMap,
    limit: usize,
) !void {
    var entries = try allocator.alloc(NamedCount, map.count());
    defer allocator.free(entries);
    for (map.keys(), map.values(), 0..) |name, count, index| {
        entries[index] = .{ .name = name, .count = count };
    }
    std.sort.heap(NamedCount, entries, {}, namedCountLessThan);
    const top_count = @min(limit, entries.len);
    for (entries[0..top_count], 1..) |entry, rank| {
        try writer.print(
            "{s} slice={s} mode={s} rank={} name={s} count={}\n",
            .{ line_name, slice.cliName(), mode.name(), rank, entry.name, entry.count },
        );
    }
}

fn printTopOpcodeMap(
    allocator: std.mem.Allocator,
    writer: *std.Io.Writer,
    slice: InventorySlice,
    mode: Mode,
    line_name: []const u8,
    map: *const OpcodeCountMap,
    limit: usize,
) !void {
    var entries = try allocator.alloc(UnknownOpcodePairTopEntry, map.count());
    defer allocator.free(entries);
    for (map.keys(), map.values(), 0..) |name, stat, index| {
        entries[index] = .{
            .name = name,
            .count = stat.count,
            .first_source = stat.first_source orelse "-",
            .first_function = stat.first_function orelse "-",
        };
    }
    std.sort.heap(UnknownOpcodePairTopEntry, entries, {}, unknownOpcodePairTopLessThan);
    const top_count = @min(limit, entries.len);
    for (entries[0..top_count], 1..) |entry, rank| {
        try writer.print(
            "{s} slice={s} mode={s} rank={} name={s} count={} first_source={s} first_function={s}\n",
            .{ line_name, slice.cliName(), mode.name(), rank, entry.name, entry.count, entry.first_source, entry.first_function },
        );
    }
}

const UnsupportedTopEntry = struct {
    category: UnsupportedCategory,
    count: usize,
    first_source: []const u8,
    first_function: []const u8,
};

const UnknownOpcodeTopEntry = struct {
    category: air_capabilities.UnknownOpcodeCategory,
    count: usize,
    first_source: []const u8,
    first_function: []const u8,
};

const UnknownOpcodePairTopEntry = struct {
    name: []const u8,
    count: usize,
    first_source: []const u8,
    first_function: []const u8,
};

fn unsupportedTopLessThan(_: void, lhs: UnsupportedTopEntry, rhs: UnsupportedTopEntry) bool {
    if (lhs.count != rhs.count) return lhs.count > rhs.count;
    return std.mem.lessThan(u8, lhs.category.name(), rhs.category.name());
}

fn unknownOpcodeTopLessThan(_: void, lhs: UnknownOpcodeTopEntry, rhs: UnknownOpcodeTopEntry) bool {
    if (lhs.count != rhs.count) return lhs.count > rhs.count;
    return std.mem.lessThan(u8, lhs.category.name(), rhs.category.name());
}

fn unknownOpcodePairTopLessThan(_: void, lhs: UnknownOpcodePairTopEntry, rhs: UnknownOpcodePairTopEntry) bool {
    if (lhs.count != rhs.count) return lhs.count > rhs.count;
    return std.mem.lessThan(u8, lhs.name, rhs.name);
}

fn printTopUnsupported(
    writer: *std.Io.Writer,
    slice: InventorySlice,
    mode: Mode,
    counters: Counters,
) !void {
    var entries: [unsupported_category_count]UnsupportedTopEntry = undefined;
    inline for (std.meta.fields(UnsupportedCategory)) |field| {
        const category: UnsupportedCategory = @enumFromInt(field.value);
        const stat = counters.unsupported_categories[field.value];
        entries[field.value] = .{
            .category = category,
            .count = stat.count,
            .first_source = stat.first_source orelse "-",
            .first_function = stat.first_function orelse "-",
        };
    }
    std.sort.heap(UnsupportedTopEntry, entries[0..], {}, unsupportedTopLessThan);
    for (entries, 1..) |entry, rank| {
        try writer.print(
            "top_unsupported slice={s} mode={s} rank={} category={s} count={} first_source={s} first_function={s}\n",
            .{ slice.cliName(), mode.name(), rank, entry.category.name(), entry.count, entry.first_source, entry.first_function },
        );
    }
}

fn printTopUnknownOpcodePairs(
    allocator: std.mem.Allocator,
    writer: *std.Io.Writer,
    slice: InventorySlice,
    mode: Mode,
    counters: Counters,
    limit: usize,
) !void {
    var entries = try allocator.alloc(UnknownOpcodePairTopEntry, counters.unknown_opcode_pair_counts.count());
    defer allocator.free(entries);
    for (counters.unknown_opcode_pair_counts.keys(), counters.unknown_opcode_pair_counts.values(), 0..) |name, stat, index| {
        entries[index] = .{
            .name = name,
            .count = stat.count,
            .first_source = stat.first_source orelse "-",
            .first_function = stat.first_function orelse "-",
        };
    }
    std.sort.heap(UnknownOpcodePairTopEntry, entries, {}, unknownOpcodePairTopLessThan);
    const top_count = @min(limit, entries.len);
    for (entries[0..top_count], 1..) |entry, rank| {
        try writer.print(
            "top_unknown_opcode_pair slice={s} mode={s} rank={} name={s} count={} first_source={s} first_function={s}\n",
            .{ slice.cliName(), mode.name(), rank, entry.name, entry.count, entry.first_source, entry.first_function },
        );
    }
}

fn printTopUnknownOpcodeCategoryPairs(
    allocator: std.mem.Allocator,
    writer: *std.Io.Writer,
    slice: InventorySlice,
    mode: Mode,
    counters: Counters,
    limit: usize,
) !void {
    inline for (std.meta.fields(air_capabilities.UnknownOpcodeCategory)) |field| {
        const category: air_capabilities.UnknownOpcodeCategory = @enumFromInt(field.value);
        const category_name = category.name();
        var entries = try allocator.alloc(UnknownOpcodePairTopEntry, counters.unknown_opcode_pair_counts.count());
        defer allocator.free(entries);
        var entry_count: usize = 0;
        for (counters.unknown_opcode_pair_counts.keys(), counters.unknown_opcode_pair_counts.values()) |name, stat| {
            if (!unknownOpcodePairBelongsToCategory(name, category_name)) continue;
            entries[entry_count] = .{
                .name = name,
                .count = stat.count,
                .first_source = stat.first_source orelse "-",
                .first_function = stat.first_function orelse "-",
            };
            entry_count += 1;
        }
        std.sort.heap(UnknownOpcodePairTopEntry, entries[0..entry_count], {}, unknownOpcodePairTopLessThan);
        const top_count = @min(limit, entry_count);
        for (entries[0..top_count], 1..) |entry, rank| {
            try writer.print(
                "top_unknown_opcode_category_pair slice={s} mode={s} category={s} rank={} name={s} count={} first_source={s} first_function={s}\n",
                .{ slice.cliName(), mode.name(), category_name, rank, entry.name, entry.count, entry.first_source, entry.first_function },
            );
        }
    }
}

fn unknownOpcodePairBelongsToCategory(name: []const u8, category_name: []const u8) bool {
    return name.len > category_name.len and
        name[category_name.len] == ':' and
        std.mem.eql(u8, name[0..category_name.len], category_name);
}

fn printTopUnknownOpcodes(
    writer: *std.Io.Writer,
    slice: InventorySlice,
    mode: Mode,
    counters: Counters,
) !void {
    var entries: [unknown_opcode_category_count]UnknownOpcodeTopEntry = undefined;
    inline for (std.meta.fields(air_capabilities.UnknownOpcodeCategory)) |field| {
        const category: air_capabilities.UnknownOpcodeCategory = @enumFromInt(field.value);
        const stat = counters.unknown_opcode_categories[field.value];
        entries[field.value] = .{
            .category = category,
            .count = stat.count,
            .first_source = stat.first_source orelse "-",
            .first_function = stat.first_function orelse "-",
        };
    }
    std.sort.heap(UnknownOpcodeTopEntry, entries[0..], {}, unknownOpcodeTopLessThan);
    for (entries, 1..) |entry, rank| {
        try writer.print(
            "top_unknown_opcode slice={s} mode={s} rank={} category={s} count={} first_source={s} first_function={s}\n",
            .{ slice.cliName(), mode.name(), rank, entry.category.name(), entry.count, entry.first_source, entry.first_function },
        );
    }
}

fn writeAllStdout(bytes: []const u8) !void {
    var remaining = bytes;
    while (remaining.len > 0) {
        const rc = std.os.linux.write(std.posix.STDOUT_FILENO, remaining.ptr, remaining.len);
        switch (std.os.linux.errno(rc)) {
            .SUCCESS => {},
            .INTR, .AGAIN => continue,
            else => return error.StdoutWriteFailed,
        }
        const written = rc;
        if (written == 0) return error.StdoutWriteFailed;
        remaining = remaining[written..];
    }
}

fn isProbablyExportedFunction(name: []const u8) bool {
    const leaf = if (std.mem.lastIndexOfScalar(u8, name, '.')) |index| name[index + 1 ..] else name;
    return std.mem.startsWith(u8, leaf, "__") or
        std.mem.startsWith(u8, leaf, "_") or
        std.mem.startsWith(u8, leaf, "zig_") or
        std.mem.startsWith(u8, leaf, "mem") or
        std.mem.startsWith(u8, leaf, "panic") or
        !contains(name, ".");
}

fn isProbablyComptimeFunction(name: []const u8) bool {
    return containsAny(name, &.{ "__anon", ".anon", "comptime", "__comptime" });
}

fn isRuntimeSymbol(text: []const u8) bool {
    return containsAny(text, &.{
        "compiler_rt",
        "__ubsan",
        "__zig",
        "panic",
        "defaultPanic",
        "memcpy",
        "memset",
        "memmove",
        "libc",
    });
}

fn isCallOpcode(opcode: []const u8) bool {
    return air_capabilities.isCallOpcode(opcode);
}

fn textFeatureContextForOpcode(opcode: []const u8) TextFeatureContext {
    if (air_capabilities.isCallOpcode(opcode) or
        air_capabilities.isReturnOpcode(opcode) or
        air_capabilities.isArgOpcode(opcode))
    {
        return .abi;
    }
    return .metadata;
}

fn maybeOperandCallee(operand: air_export.TypedOperand) ?[]const u8 {
    if (containsAny(operand.kind, &.{ "callee", "function", "fn" })) return operand.value;
    return null;
}

fn maybeDetailCallee(detail: air_export.TypedDetail) ?[]const u8 {
    if (containsAny(detail.key, &.{ "callee", "function", "fn", "call_target" })) return detail.value;
    return null;
}

fn maybeDetailCalleeText(key: []const u8, value: []const u8) ?[]const u8 {
    if (containsAny(key, &.{ "callee", "function", "fn", "call_target" })) return value;
    return null;
}

fn contains(haystack: []const u8, needle: []const u8) bool {
    return std.mem.indexOf(u8, haystack, needle) != null;
}

fn containsAny(haystack: []const u8, needles: []const []const u8) bool {
    for (needles) |needle| {
        if (contains(haystack, needle)) return true;
    }
    return false;
}

fn countAny(haystack: []const u8, needles: []const []const u8) usize {
    var count: usize = 0;
    for (needles) |needle| count += std.mem.count(u8, haystack, needle);
    return count;
}

fn countString(allocator: std.mem.Allocator, map: *StringCountMap, key: []const u8) !void {
    if (map.getIndex(key)) |index| {
        map.values()[index] += 1;
        return;
    }
    const owned_key = try allocator.dupe(u8, key);
    errdefer allocator.free(owned_key);
    try map.put(allocator, owned_key, 1);
}

fn countOpcode(
    allocator: std.mem.Allocator,
    map: *OpcodeCountMap,
    opcode: []const u8,
    source: []const u8,
    function: []const u8,
) !void {
    if (map.getIndex(opcode)) |index| {
        map.values()[index].count += 1;
        return;
    }
    const owned_key = try allocator.dupe(u8, opcode);
    errdefer allocator.free(owned_key);
    const first_source = try allocator.dupe(u8, source);
    errdefer allocator.free(first_source);
    const first_function = try allocator.dupe(u8, function);
    errdefer allocator.free(first_function);
    try map.put(allocator, owned_key, .{
        .count = 1,
        .first_source = first_source,
        .first_function = first_function,
    });
}

fn freeStringCountMap(allocator: std.mem.Allocator, map: *StringCountMap) void {
    for (map.keys()) |key| allocator.free(key);
    map.deinit(allocator);
    map.* = .empty;
}

fn freeOpcodeCountMap(allocator: std.mem.Allocator, map: *OpcodeCountMap) void {
    for (map.keys(), map.values()) |key, *value| {
        allocator.free(key);
        value.deinit(allocator);
    }
    map.deinit(allocator);
    map.* = .empty;
}

fn freeUnknownOpcodePairMap(allocator: std.mem.Allocator, map: *UnknownOpcodePairMap) void {
    for (map.keys(), map.values()) |key, *value| {
        allocator.free(key);
        value.deinit(allocator);
    }
    map.deinit(allocator);
    map.* = .empty;
}

fn firstLine(output: []const u8) []const u8 {
    if (std.mem.indexOfScalar(u8, output, '\n')) |index| return output[0..index];
    return output;
}

fn termName(term: std.process.Child.Term) []const u8 {
    return switch (term) {
        .exited => "exited",
        .signal => "signal",
        .stopped => "stopped",
        .unknown => "unknown",
    };
}
