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
    .{ .source = "composed_selector_calls.zig", .operation = .bind_eax, .maximum = 0 },
    .{ .source = "composed_selector_calls.zig", .operation = .bind_rax, .maximum = 0 },
    .{ .source = "composed_selector_calls.zig", .operation = .clobber_accumulator, .maximum = 5 },
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

const GenericBindingInventoryEntry = struct {
    source: []const u8,
    maximum: usize,
};

// Freeze every generic production binding site, including computed locations.
// The scalar lowerCast site below is the one accepted alias-only accumulator
// cast: it emits no instruction and therefore is not a physical definition.
const generic_binding_inventory = [_]GenericBindingInventoryEntry{
    .{ .source = "composed_selector_aggregate.zig", .maximum = 3 },
    .{ .source = "composed_selector_cfg.zig", .maximum = 2 },
    .{ .source = "composed_selector_fp.zig", .maximum = 3 },
    .{ .source = "composed_selector_frame.zig", .maximum = 4 },
    .{ .source = "composed_selector_impl.zig", .maximum = 10 },
    .{ .source = "composed_selector_memory.zig", .maximum = 8 },
    .{ .source = "composed_selector_scalar.zig", .maximum = 2 },
};

const alias_only_cast_binding_site = "try selector_state.bindValueLoc(selector, result_name, result_loc);";

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
            try validateGenericBindingInventory(name, source);
            try validateAccumulatorDisplacementPolicies(source);
            try validateEflagsEmissionAuthority(name, source);
            if (std.mem.eql(u8, name, "composed_selector_scalar.zig") and
                std.mem.count(u8, source, alias_only_cast_binding_site) != 1)
            {
                return error.AliasOnlyCastBindingInventoryMismatch;
            }
        },
    }
}

fn validateEflagsEmissionAuthority(name: []const u8, source: []const u8) !void {
    const guarded = std.mem.eql(u8, name, "composed_selector_calls.zig") or
        std.mem.eql(u8, name, "composed_selector_cfg.zig") or
        std.mem.eql(u8, name, "composed_selector_icmp.zig") or
        std.mem.eql(u8, name, "composed_selector_scalar.zig");
    if (!guarded) return;

    const markers = [_][]const u8{
        ".cmp_",        ".test_", ".setb_eax", ".seta_eax", ".sete_eax", ".setg_eax", ".setl_eax", ".setne_eax",
        ".binary_arg_", ".imul_", ".mul_rax",  ".xor_edx",  ".div_arg",  ".add_",     ".sub_",     ".shl_",
        ".shr_",        ".sar_",  ".and_",     ".or_",      ".adc_",     ".sbb_",     ".je ",      ".jne ",
        ".jo ",         ".jc ",   ".jp ",      ".js ",      ".jae ",     ".jle ",
    };
    inline for (markers) |marker| {
        var search_from: usize = 0;
        while (std.mem.indexOfPos(u8, source, search_from, marker)) |index| {
            const statement_start = if (std.mem.lastIndexOfScalar(u8, source[0..index], ';')) |semicolon| semicolon + 1 else 0;
            const statement_end = if (std.mem.indexOfScalarPos(u8, source, index, ';')) |semicolon| semicolon + 1 else source.len;
            const statement = source[statement_start..statement_end];
            if (std.mem.indexOf(u8, statement, "instructions.append") != null or
                std.mem.indexOf(u8, statement, "instructions.appendSlice") != null)
            {
                return error.RawEflagsInstructionAppend;
            }
            search_from = index + marker.len;
        }
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

fn validateGenericBindingInventory(name: []const u8, source: []const u8) !void {
    const actual = std.mem.count(u8, source, "bindValueLoc(");
    var maximum: usize = 0;
    for (generic_binding_inventory) |entry| {
        if (std.mem.eql(u8, entry.source, name)) {
            maximum = entry.maximum;
            break;
        }
    }
    if (actual > maximum) return error.GenericBindingInventoryGrowth;
}

fn validateAccumulatorDisplacementPolicies(source: []const u8) !void {
    const call_prefix = "transaction.prepare(";
    var search_from: usize = 0;
    while (std.mem.indexOfPos(u8, source, search_from, call_prefix)) |call_start| {
        const open_paren = call_start + call_prefix.len - 1;
        var depth: usize = 0;
        var call_end: ?usize = null;
        for (source[open_paren..], open_paren..) |byte, index| {
            switch (byte) {
                '(' => depth += 1,
                ')' => {
                    depth -= 1;
                    if (depth == 0) {
                        call_end = index + 1;
                        break;
                    }
                },
                else => {},
            }
        }
        const end = call_end orelse return error.MalformedAccumulatorPrepareCall;
        const call = source[call_start..end];
        if (std.mem.indexOf(u8, call, ".spill_live") == null and
            std.mem.indexOf(u8, call, ".caller_clobbers") == null and
            std.mem.indexOf(u8, call, ".spill_source") == null and
            std.mem.indexOf(u8, call, ".scratch_preferred") == null and
            std.mem.indexOf(u8, call, "accumulatorInputDisplacement(") == null and
            std.mem.indexOf(u8, call, "accumulatorLocDisplacement(") == null and
            std.mem.indexOf(u8, call, "accumulatorCastDisplacement(") == null)
        {
            return error.MissingAccumulatorDisplacementPolicy;
        }
        search_from = end;
    }
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

test "composed selector source guard freezes generic and alias-only accumulator binding sites" {
    try std.testing.expectError(
        error.GenericBindingInventoryGrowth,
        validateProductionSource(
            "composed_selector_aggregate.zig",
            "bindValueLoc( bindValueLoc( bindValueLoc( bindValueLoc(",
        ),
    );
    try std.testing.expectError(
        error.AliasOnlyCastBindingInventoryMismatch,
        validateProductionSource("composed_selector_scalar.zig", "fn lowerCast() void {}"),
    );
}

test "composed selector source guard requires an explicit accumulator displacement policy" {
    try std.testing.expectError(
        error.MissingAccumulatorDisplacementPolicy,
        validateProductionSource(
            "composed_selector_conversion.zig",
            "fn lower() void { _ = transaction.prepare(.preserve); }",
        ),
    );
    try validateAccumulatorDisplacementPolicies(
        "_ = transaction.prepare(.preserve, .spill_live);" ++
            "_ = transaction.prepare(.clobber, .caller_clobbers);" ++
            "_ = transaction.prepare(.preserve, .scratch_preferred);" ++
            "_ = transaction.prepare(.clobber, accumulatorLocDisplacement(value, source));" ++
            "_ = transaction.prepare(.clobber, accumulatorCastDisplacement(value, source));",
    );
}

test "composed selector source guard requires the EFLAGS emission authority" {
    const raw_sites = [_][]const u8{
        "try selector.machine.instructions.append(selector.allocator, .{ .cmp_eax_imm32 = 0 });",
        "try selector.machine.instructions.append(selector.allocator, .setne_eax);",
        "try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = undefined });",
        "try selector.machine.instructions.append(selector.allocator, .{ .jne = target });",
    };
    for (raw_sites) |site| {
        try std.testing.expectError(
            error.RawEflagsInstructionAppend,
            validateEflagsEmissionAuthority("composed_selector_scalar.zig", site),
        );
    }
    try validateEflagsEmissionAuthority(
        "composed_selector_scalar.zig",
        "try selector_state.emitEflagsInstruction(selector, .{ .cmp_eax_imm32 = 0 }, .definition);",
    );
}

test "composed selector source guard accepts the fully classified current tree" {
    try validateCurrentTree(std.testing.allocator);
}
