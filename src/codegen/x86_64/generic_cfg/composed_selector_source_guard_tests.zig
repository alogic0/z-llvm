const std = @import("std");

const source_dir = "src/codegen/x86_64/generic_cfg";
const source_prefix = "composed_selector_";
const source_suffix = ".zig";

const SourceKind = enum {
    authority,
    lifecycle,
    consumer,
};

const ClassifiedSource = struct {
    name: []const u8,
    kind: SourceKind,
};

// Every production composed-selector source must appear here. Test sources are
// white-box fixtures and are deliberately classified by their `_tests.zig`
// suffix instead.
const classified_sources = [_]ClassifiedSource{
    .{ .name = "composed_selector_aggregate.zig", .kind = .consumer },
    .{ .name = "composed_selector_calls.zig", .kind = .consumer },
    .{ .name = "composed_selector_cfg.zig", .kind = .consumer },
    .{ .name = "composed_selector_conversion.zig", .kind = .consumer },
    .{ .name = "composed_selector_eflags.zig", .kind = .consumer },
    .{ .name = "composed_selector_fp.zig", .kind = .consumer },
    .{ .name = "composed_selector_frame.zig", .kind = .consumer },
    .{ .name = "composed_selector_icmp.zig", .kind = .consumer },
    .{ .name = "composed_selector_impl.zig", .kind = .consumer },
    .{ .name = "composed_selector_memory.zig", .kind = .consumer },
    .{ .name = "composed_selector_scalar.zig", .kind = .consumer },
    .{ .name = "composed_selector_state.zig", .kind = .authority },
    .{ .name = "composed_selector_state_data.zig", .kind = .lifecycle },
    .{ .name = "composed_selector_vector.zig", .kind = .consumer },
};

const DirectOperation = enum {
    bind_eax,
    bind_rax,
    bind_accumulator,
    clobber_accumulator,

    fn pattern(operation: DirectOperation) []const u8 {
        return switch (operation) {
            .bind_eax => "bindEax(",
            .bind_rax => "bindRax(",
            .bind_accumulator => "bindAccumulator(",
            .clobber_accumulator => "clobberAccumulator(",
        };
    }
};

const DirectInventoryEntry = struct {
    source: []const u8,
    operation: DirectOperation,
    maximum: usize,
};

// Frozen at INBOX-72. Later O1 commits may reduce these per-file/per-operation
// maxima, but cannot add or relocate a direct accumulator bind/clobber site.
const direct_accumulator_inventory = [_]DirectInventoryEntry{
    .{ .source = "composed_selector_calls.zig", .operation = .bind_eax, .maximum = 9 },
    .{ .source = "composed_selector_calls.zig", .operation = .bind_rax, .maximum = 9 },
    .{ .source = "composed_selector_calls.zig", .operation = .clobber_accumulator, .maximum = 12 },
    .{ .source = "composed_selector_cfg.zig", .operation = .bind_accumulator, .maximum = 1 },
    .{ .source = "composed_selector_cfg.zig", .operation = .clobber_accumulator, .maximum = 8 },
    .{ .source = "composed_selector_conversion.zig", .operation = .bind_eax, .maximum = 1 },
    .{ .source = "composed_selector_conversion.zig", .operation = .clobber_accumulator, .maximum = 2 },
    .{ .source = "composed_selector_fp.zig", .operation = .bind_eax, .maximum = 4 },
    .{ .source = "composed_selector_fp.zig", .operation = .bind_rax, .maximum = 1 },
    .{ .source = "composed_selector_fp.zig", .operation = .clobber_accumulator, .maximum = 8 },
    .{ .source = "composed_selector_icmp.zig", .operation = .bind_eax, .maximum = 4 },
    .{ .source = "composed_selector_icmp.zig", .operation = .clobber_accumulator, .maximum = 22 },
    .{ .source = "composed_selector_memory.zig", .operation = .bind_eax, .maximum = 6 },
    .{ .source = "composed_selector_memory.zig", .operation = .bind_rax, .maximum = 3 },
    .{ .source = "composed_selector_memory.zig", .operation = .clobber_accumulator, .maximum = 8 },
    .{ .source = "composed_selector_scalar.zig", .operation = .bind_eax, .maximum = 16 },
    .{ .source = "composed_selector_scalar.zig", .operation = .bind_rax, .maximum = 17 },
    .{ .source = "composed_selector_scalar.zig", .operation = .bind_accumulator, .maximum = 3 },
    .{ .source = "composed_selector_scalar.zig", .operation = .clobber_accumulator, .maximum = 5 },
    .{ .source = "composed_selector_vector.zig", .operation = .bind_rax, .maximum = 1 },
    .{ .source = "composed_selector_vector.zig", .operation = .bind_accumulator, .maximum = 3 },
    .{ .source = "composed_selector_vector.zig", .operation = .clobber_accumulator, .maximum = 4 },
};

fn validateCurrentTree(allocator: std.mem.Allocator) !void {
    const io = std.testing.io;
    var dir = try std.Io.Dir.cwd().openDir(io, source_dir, .{ .iterate = true });
    defer dir.close(io);

    var seen = [_]bool{false} ** classified_sources.len;
    var iterator = dir.iterate();
    while (try iterator.next(io)) |entry| {
        if (entry.kind != .file or
            !std.mem.startsWith(u8, entry.name, source_prefix) or
            !std.mem.endsWith(u8, entry.name, source_suffix) or
            isTestSource(entry.name)) continue;

        const classification_index = classificationIndex(entry.name) orelse return error.UnclassifiedComposedSelectorSource;
        seen[classification_index] = true;
        const path = try std.fs.path.join(allocator, &.{ source_dir, entry.name });
        defer allocator.free(path);
        const source = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(2 * 1024 * 1024));
        defer allocator.free(source);
        try validateProductionSource(entry.name, source);
    }

    for (seen) |was_seen| {
        if (!was_seen) return error.MissingClassifiedComposedSelectorSource;
    }
}

fn validateProductionSource(name: []const u8, source: []const u8) !void {
    const index = classificationIndex(name) orelse return error.UnclassifiedComposedSelectorSource;
    switch (classified_sources[index].kind) {
        .authority => {},
        .lifecycle => try validateStateDataLifecycle(source),
        .consumer => {
            if (std.mem.indexOf(u8, source, ".values") != null) return error.RawSelectorValuesAccess;
            try validateDirectAccumulatorInventory(name, source);
        },
    }
}

fn validateStateDataLifecycle(source: []const u8) !void {
    const init_site = ".values = std.StringHashMap(ValueBinding).init(allocator),";
    const deinit_site = "selector.values.deinit();";
    var init_count: usize = 0;
    var deinit_count: usize = 0;
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, ".values") == null) continue;
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (std.mem.eql(u8, trimmed, init_site)) {
            init_count += 1;
        } else if (std.mem.eql(u8, trimmed, deinit_site)) {
            deinit_count += 1;
        } else {
            return error.UnapprovedStateDataValuesAccess;
        }
    }
    if (init_count != 1 or deinit_count != 1) return error.StateDataLifecycleInventoryMismatch;
}

fn validateDirectAccumulatorInventory(name: []const u8, source: []const u8) !void {
    inline for (std.meta.tags(DirectOperation)) |operation| {
        const actual = std.mem.count(u8, source, operation.pattern());
        const maximum = directInventoryMaximum(name, operation);
        if (actual > maximum) return error.DirectAccumulatorInventoryGrowth;
    }
}

fn directInventoryMaximum(name: []const u8, operation: DirectOperation) usize {
    for (direct_accumulator_inventory) |entry| {
        if (entry.operation == operation and std.mem.eql(u8, entry.source, name)) return entry.maximum;
    }
    return 0;
}

fn classificationIndex(name: []const u8) ?usize {
    for (classified_sources, 0..) |classification, index| {
        if (std.mem.eql(u8, classification.name, name)) return index;
    }
    return null;
}

fn isTestSource(name: []const u8) bool {
    return std.mem.endsWith(u8, name, "_tests.zig");
}

test "composed selector source guard rejects all raw map methods outside the authority" {
    const fixtures = [_][]const u8{
        "fn bad(selector: anytype) void { _ = selector.values.get(\"x\"); }",
        "fn bad(selector: anytype) void { var it = selector.values.iterator(); _ = &it; }",
        "fn bad(selector: anytype) void { selector.values.put(\"x\", undefined) catch unreachable; }",
        "fn bad(selector: anytype) void { _ = selector.values.remove(\"x\"); }",
    };
    for (fixtures) |fixture| {
        try std.testing.expectError(
            error.RawSelectorValuesAccess,
            validateProductionSource("composed_selector_scalar.zig", fixture),
        );
    }
}

test "composed selector source guard rejects an unclassified production file" {
    try std.testing.expectError(
        error.UnclassifiedComposedSelectorSource,
        validateProductionSource("composed_selector_new_route.zig", "const std = @import(\"std\");"),
    );
}

test "composed selector source guard narrowly permits only state-data lifecycle access" {
    const lifecycle =
        \\    .values = std.StringHashMap(ValueBinding).init(allocator),
        \\    selector.values.deinit();
    ;
    try validateProductionSource("composed_selector_state_data.zig", lifecycle);
    try std.testing.expectError(
        error.UnapprovedStateDataValuesAccess,
        validateProductionSource(
            "composed_selector_state_data.zig",
            lifecycle ++ "    _ = selector.values.get(\"x\");\n",
        ),
    );
}

test "composed selector source guard freezes direct accumulator inventory" {
    try std.testing.expectError(
        error.DirectAccumulatorInventoryGrowth,
        validateProductionSource(
            "composed_selector_aggregate.zig",
            "fn bad() void { selector_state.bindEax(undefined, \"x\") catch unreachable; }",
        ),
    );
}

test "composed selector source guard accepts the fully classified current tree" {
    try validateCurrentTree(std.testing.allocator);
}
