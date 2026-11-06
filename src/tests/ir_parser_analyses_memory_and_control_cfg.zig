const ir_common = @import("ir_common.zig");

const std = ir_common.std;
const air_bridge = ir_common.air_bridge;
const alias = ir_common.alias;
const call_graph = ir_common.call_graph;
const cfg = ir_common.cfg;
const codegen = ir_common.codegen;
const dominator = ir_common.dominator;
const function_attrs = ir_common.function_attrs;
const fp_semantics = ir_common.fp_semantics;
const loop_info = ir_common.loop_info;
const memory_effect = ir_common.memory_effect;
const memory_location = ir_common.memory_location;
const memory_ssa = ir_common.memory_ssa;
const ir = ir_common.ir;
const normalize = ir_common.normalize;
const mc = ir_common.mc;
const pass_manager = ir_common.pass_manager;
const pipelines = ir_common.pipelines;
const postdominator = ir_common.postdominator;
const semantic_descriptor_v2 = ir_common.semantic_descriptor_v2;
const target = ir_common.target;
const target_library_info = ir_common.target_library_info;
const target_transform_info = ir_common.target_transform_info;
const instcombine = ir_common.instcombine;
const zig_air_export = ir_common.zig_air_export;
const zig_air_lowering = ir_common.zig_air_lowering;
const dce = ir_common.dce;
const dse = ir_common.dse;
const early_cse = ir_common.early_cse;
const gvn = ir_common.gvn;
const licm = ir_common.licm;
const mem2reg = ir_common.mem2reg;
const sccp = ir_common.sccp;
const simplifycfg = ir_common.simplifycfg;
const slp_vectorizer = ir_common.slp_vectorizer;
const sroa = ir_common.sroa;
test "alias analysis classifies source-backed parameter gep offsets" {
    const input =
        \\define i32 @aggregate_param(ptr %p) {
        \\entry:
        \\  %field = getelementptr i8, ptr %p, i64 4
        \\  %a = load i32, ptr %p, align 4
        \\  %b = load i32, ptr %field, align 4
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    try std.testing.expectEqual(
        alias.AliasResult.may_alias,
        alias.alias(function, .{ .named = "p" }, .{ .named = "field" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.no_mod_ref,
        alias.modRefForAccess(function, function.blocks.items[0].instructions.items[2], .{ .named = "p" }, .{ .int = 32 }),
    );

    const field_location = memory_location.forPointer(function, .{ .named = "field" }) orelse return error.TestExpectedMemoryLocation;
    try std.testing.expectEqualStrings("p", field_location.root);
    try std.testing.expectEqual(@as(i128, 4), field_location.offset.?);
}

test "alias analysis classifies partial overlapping access ranges" {
    const input =
        \\define i32 @partial_alias(ptr %p) {
        \\entry:
        \\  %overlap = getelementptr i8, ptr %p, i64 2
        \\  %a = load i32, ptr %p, align 4
        \\  %b = load i32, ptr %overlap, align 1
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    try std.testing.expectEqual(
        alias.AliasResult.partial_alias,
        alias.accessAlias(function, .{ .named = "p" }, .{ .int = 32 }, .{ .named = "overlap" }, .{ .int = 32 }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.ref,
        alias.modRefForAccess(function, function.blocks.items[0].instructions.items[2], .{ .named = "p" }, .{ .int = 32 }),
    );
}

test "alias analysis classifies globals and aliases with module context" {
    const input =
        \\@global_a = internal global i32 0
        \\@global_b = internal global i32 0
        \\@alias_a = alias ptr, ptr @global_a
        \\
        \\define i32 @global_alias() {
        \\entry:
        \\  %v = load i32, ptr @global_a
        \\  store i32 %v, ptr @global_b
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    try std.testing.expectEqual(
        alias.AliasResult.must_alias,
        alias.aliasInModule(module, function, .{ .named = "global_a" }, .{ .named = "alias_a" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.no_alias,
        alias.aliasInModule(module, function, .{ .named = "global_a" }, .{ .named = "global_b" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.no_mod_ref,
        alias.modRefInModule(module, function, function.blocks.items[0].instructions.items[1], .{ .named = "global_a" }),
    );
}

test "memory effect and mod-ref classify memory instructions conservatively" {
    const input =
        \\define i32 @memory_effects(i32 %a, ptr %arg) {
        \\entry:
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  %left1 = getelementptr i32, ptr %left, i32 1
        \\  %pure = add i32 %a, 1
        \\  %load = load i32, ptr %left
        \\  %volatile_load = load volatile i32, ptr %arg
        \\  store i32 %pure, ptr %right
        \\  store atomic i32 %pure, ptr %arg release, align 4
        \\  ret i32 %load
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];
    const block = function.blocks.items[0];

    try std.testing.expectEqual(memory_effect.Effect.none, memory_effect.classify(block.instructions.items[3]));
    try std.testing.expectEqual(memory_effect.Effect.readonly_load, memory_effect.classify(block.instructions.items[4]));
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(block.instructions.items[5]));
    try std.testing.expectEqual(memory_effect.Effect.memory_write, memory_effect.classify(block.instructions.items[6]));
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(block.instructions.items[7]));
    try std.testing.expectEqual(memory_effect.BarrierKind.@"volatile", memory_effect.barrierKind(block.instructions.items[5]));
    try std.testing.expectEqual(memory_effect.BarrierKind.atomic, memory_effect.barrierKind(block.instructions.items[7]));
    try std.testing.expect(memory_effect.mayReadMemory(block.instructions.items[4]));
    try std.testing.expect(memory_effect.mayReadOrWriteMemory(block.instructions.items[7]));
    try std.testing.expect(!memory_effect.isSafeToDelete(block.instructions.items[7]));

    try std.testing.expectEqual(
        alias.ModRefInfo.no_mod_ref,
        alias.modRef(function, block.instructions.items[4], .{ .named = "right" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.no_mod_ref,
        alias.modRef(function, block.instructions.items[4], .{ .named = "left1" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.ref,
        alias.modRef(function, block.instructions.items[4], .{ .named = "left" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.no_mod_ref,
        alias.modRef(function, block.instructions.items[4], .{ .named = "arg" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.mod,
        alias.modRef(function, block.instructions.items[6], .{ .named = "right" }),
    );
    try std.testing.expectEqual(
        alias.ModRefInfo.unknown,
        alias.modRef(function, block.instructions.items[7], .{ .named = "arg" }),
    );
}

test "memory effect marks calls and trapping division conservatively" {
    const input =
        \\declare void @touch()
        \\
        \\define i32 @trap(i32 %a, i32 %b) {
        \\entry:
        \\  %q = sdiv i32 %a, %b
        \\  %safe = udiv i32 %a, 2
        \\  call void @touch()
        \\  ret i32 %q
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const block = module.functions.items[0].blocks.items[0];

    try std.testing.expect(memory_effect.mayTrap(block.instructions.items[0]));
    try std.testing.expect(!memory_effect.isSafeToSpeculativelyExecute(block.instructions.items[0]));
    try std.testing.expect(!memory_effect.mayTrap(block.instructions.items[1]));
    try std.testing.expect(memory_effect.mayThrow(block.instructions.items[2]));
    try std.testing.expect(!memory_effect.isSafeToDelete(block.instructions.items[2]));
}

test "memory ssa clobber helper covers accepted memory-dependence cases" {
    const input =
        \\declare void @unknown()
        \\declare void @readnone_call() readnone
        \\declare void @readonly_call() readonly
        \\
        \\define i32 @memory_ssa_clobber(ptr %p, ptr %q, i32 %v) {
        \\entry:
        \\  %l0 = load i32, ptr %p
        \\  %l1 = load i32, ptr %p
        \\  store i32 %v, ptr %p
        \\  %l2 = load i32, ptr %p
        \\  store i32 %v, ptr %q
        \\  %l3 = load i32, ptr %p
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  %left_load = load i32, ptr %left
        \\  store i32 %v, ptr %right
        \\  %left_load2 = load i32, ptr %left
        \\  call void @unknown()
        \\  %l4 = load i32, ptr %p
        \\  call void @readnone_call()
        \\  %l5 = load i32, ptr %p
        \\  call void @readonly_call()
        \\  %l6 = load i32, ptr %p
        \\  %volatile_load = load volatile i32, ptr %p
        \\  %l7 = load i32, ptr %p
        \\  %atomic_load = load atomic i32, ptr %p acquire, align 4
        \\  %l8 = load i32, ptr %p
        \\  ret i32 %l8
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var memory = try memory_ssa.MemorySSA.build(std.testing.allocator, module, function);
    defer memory.deinit();
    try std.testing.expect(memory.accesses.items.len >= 9);

    try std.testing.expect(!memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 0 }, .{ .block_index = 0, .instruction_index = 1 }, .{ .named = "p" }));
    try std.testing.expect(!memory.hasClobberBetween(.{ .block_index = 0, .instruction_index = 0 }, .{ .block_index = 0, .instruction_index = 1 }, .{ .named = "p" }));
    try std.testing.expect(memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 1 }, .{ .block_index = 0, .instruction_index = 3 }, .{ .named = "p" }));
    try std.testing.expect(memory.hasClobberBetween(.{ .block_index = 0, .instruction_index = 1 }, .{ .block_index = 0, .instruction_index = 3 }, .{ .named = "p" }));
    try std.testing.expect(memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 3 }, .{ .block_index = 0, .instruction_index = 5 }, .{ .named = "p" }));
    try std.testing.expect(!memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 8 }, .{ .block_index = 0, .instruction_index = 10 }, .{ .named = "left" }));
    try std.testing.expect(memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 10 }, .{ .block_index = 0, .instruction_index = 12 }, .{ .named = "p" }));
    try std.testing.expect(!memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 12 }, .{ .block_index = 0, .instruction_index = 14 }, .{ .named = "p" }));
    try std.testing.expect(!memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 14 }, .{ .block_index = 0, .instruction_index = 16 }, .{ .named = "p" }));
    try std.testing.expect(memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 16 }, .{ .block_index = 0, .instruction_index = 18 }, .{ .named = "p" }));
    try std.testing.expect(memory_ssa.hasClobberBetween(module, function, .{ .block_index = 0, .instruction_index = 18 }, .{ .block_index = 0, .instruction_index = 20 }, .{ .named = "p" }));
}

test "memory ssa records narrow phi facts at joins" {
    const input =
        \\define i32 @memory_join(i1 %cond, ptr %p, i32 %v) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  store i32 %v, ptr %p
        \\  br label %join
        \\right:
        \\  br label %join
        \\join:
        \\  %loaded = load i32, ptr %p
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var memory = try memory_ssa.MemorySSA.build(std.testing.allocator, module, function);
    defer memory.deinit();

    var saw_phi = false;
    for (memory.accesses.items) |access| {
        if (access.kind == .phi and access.block_index == 3) saw_phi = true;
    }
    try std.testing.expect(saw_phi);
    try std.testing.expect(memory.hasClobberBetween(.{ .block_index = 1, .instruction_index = 0 }, .{ .block_index = 3, .instruction_index = 0 }, .{ .named = "p" }));
}

test "memory ssa walker reports clobbering access or live-on-entry" {
    const input =
        \\define i32 @memory_walker(i32 %v) {
        \\entry:
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  %first = load i32, ptr %left
        \\  store i32 %v, ptr %right
        \\  %second = load i32, ptr %left
        \\  store i32 %v, ptr %left
        \\  %third = load i32, ptr %left
        \\  ret i32 %third
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var memory = try memory_ssa.MemorySSA.build(std.testing.allocator, module, function);
    defer memory.deinit();
    const walker = memory.getWalker();

    try std.testing.expectEqual(@as(usize, 5), memory.accesses.items.len);
    try std.testing.expectEqual(
        memory_ssa.ClobberResult.live_on_entry,
        walker.getClobberBetween(
            .{ .block_index = 0, .instruction_index = 2 },
            .{ .block_index = 0, .instruction_index = 4 },
            .{ .named = "left" },
            .{ .int = 32 },
        ),
    );

    const clobber = walker.getClobberBetween(
        .{ .block_index = 0, .instruction_index = 4 },
        .{ .block_index = 0, .instruction_index = 6 },
        .{ .named = "left" },
        .{ .int = 32 },
    );
    switch (clobber) {
        .live_on_entry => return error.ExpectedMemoryClobber,
        .access => |access| {
            try std.testing.expectEqual(memory_ssa.AccessKind.def, access.kind);
            try std.testing.expectEqual(@as(usize, 0), access.block_index);
            try std.testing.expectEqual(@as(?usize, 5), access.instruction_index);
        },
    }

    const third_access = memory.findAccessIndex(.{ .block_index = 0, .instruction_index = 6 }) orelse return error.ExpectedMemoryAccess;
    const clobber_for_use = walker.getClobberingMemoryAccessForAccess(third_access, .{ .named = "left" }, .{ .int = 32 });
    switch (clobber_for_use) {
        .live_on_entry => return error.ExpectedMemoryClobber,
        .access => |access| {
            try std.testing.expectEqual(memory_ssa.AccessKind.def, access.kind);
            try std.testing.expectEqual(@as(?usize, 5), access.instruction_index);
        },
    }
}

test "memory ssa walker reports memory phi as clobber" {
    const input =
        \\define i32 @memory_walker_phi(i1 %cond, ptr %p, i32 %v) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  store i32 %v, ptr %p
        \\  br label %join
        \\right:
        \\  br label %join
        \\join:
        \\  %loaded = load i32, ptr %p
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var memory = try memory_ssa.MemorySSA.build(std.testing.allocator, module, function);
    defer memory.deinit();
    const walker = memory.getWalker();

    const clobber = walker.getClobberingMemoryAccess(.{ .block_index = 3, .instruction_index = 0 }, .{ .named = "p" }, .{ .int = 32 });
    switch (clobber) {
        .live_on_entry => return error.ExpectedMemoryClobber,
        .access => |access| {
            try std.testing.expectEqual(memory_ssa.AccessKind.phi, access.kind);
            try std.testing.expectEqual(@as(usize, 3), access.block_index);
            try std.testing.expectEqual(@as(?usize, null), access.instruction_index);
        },
    }
}

test "memory ssa skips phis for pure predecessor diamonds" {
    const input =
        \\define i32 @memory_pure_diamond(i1 %cond, ptr %p) {
        \\entry:
        \\  %first = load i32, ptr %p
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %join
        \\right:
        \\  br label %join
        \\join:
        \\  %second = load i32, ptr %p
        \\  ret i32 %second
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var memory = try memory_ssa.MemorySSA.build(std.testing.allocator, module, function);
    defer memory.deinit();

    for (memory.accesses.items) |access| {
        try std.testing.expect(access.kind != .phi);
    }
    try std.testing.expect(!memory.hasClobberBetween(
        .{ .block_index = 0, .instruction_index = 0 },
        .{ .block_index = 3, .instruction_index = 0 },
        .{ .named = "p" },
    ));
}

test "memory ssa updater deletes accesses and dumps expectations" {
    const input =
        \\define i32 @memory_updater(ptr %p, i32 %a, i32 %b) {
        \\entry:
        \\  store i32 %a, ptr %p
        \\  store i32 %b, ptr %p
        \\  %loaded = load i32, ptr %p
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    var function = &module.functions.items[0];

    var memory = try memory_ssa.MemorySSA.build(std.testing.allocator, module, function.*);
    defer memory.deinit();
    try std.testing.expectEqual(@as(usize, 3), memory.accesses.items.len);
    try memory.verifyConsistent();

    function.blocks.items[0].instructions.items[0].removed = true;
    try std.testing.expect(memory.deleteAccess(0, 0));
    try memory.verifyConsistent();

    var dump: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer dump.deinit();
    try memory.dump(&dump.writer);
    try std.testing.expectEqualStrings(
        \\def block=0 inst=1 ptr=%p
        \\use block=0 inst=2 ptr=%p
        \\
    , dump.writer.buffered());
}

test "mem2reg promotes single-block stack slot" {
    const input =
        \\define i32 @promote(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @promote(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "mem2reg replaces uninitialized stack loads with undef" {
    const input =
        \\define i32 @promote_undef() {
        \\entry:
        \\  %slot = alloca i32
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @promote_undef() {
        \\entry:
        \\  ret i32 undef
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "mem2reg preserves repeated conditional and switch PHI edges" {
    for ([_][]const u8{
        "br i1 %cond, label %merge, label %merge",
        "switch i32 %pick, label %merge [\n i32 0, label %merge\n i32 1, label %merge\n ]",
    }, [_]usize{ 2, 3 }) |terminator, edges| {
        const input = try std.fmt.allocPrint(std.testing.allocator,
            \\define i32 @promote_edges(i1 %cond, i32 %pick, i32 %a, i32 %b) {{
            \\entry:
            \\  %slot = alloca i32
            \\  br i1 %cond, label %left, label %right
            \\left:
            \\  store i32 %a, ptr %slot
            \\  {s}
            \\right:
            \\  store i32 %b, ptr %slot
            \\  br label %merge
            \\merge:
            \\  %v = load i32, ptr %slot
            \\  ret i32 %v
            \\}}
            \\
        , .{terminator});
        defer std.testing.allocator.free(input);
        var module = try ir.Module.parse(std.testing.allocator, input);
        defer module.deinit();
        var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
        _ = try mem2reg.pass.run(&module, &context);
        try module.verify();
        const phi = module.functions.items[0].blocks.items[3].instructions.items[0].kind.phi;
        try std.testing.expectEqual(edges + 1, phi.incoming.items.len);
        var from_left: usize = 0;
        for (phi.incoming.items) |incoming| {
            if (std.mem.eql(u8, incoming.block, "left")) {
                from_left += 1;
                try std.testing.expect(incoming.value.eql(.{ .named = "a" }));
            } else {
                try std.testing.expectEqualStrings("right", incoming.block);
                try std.testing.expect(incoming.value.eql(.{ .named = "b" }));
            }
        }
        try std.testing.expectEqual(edges, from_left);
    }
}

test "mem2reg names from numeric slots remain valid and avoid quoted collisions" {
    const text =
        \\define ptr @promote(i1 %condition, ptr %value, i64 %"__zllvm_phi_0") {
        \\entry:
        \\  %8 = alloca ptr
        \\  br i1 %condition, label %left, label %right
        \\left:
        \\  store ptr null, ptr %8
        \\  br label %merge
        \\right:
        \\  store ptr %value, ptr %8
        \\  br label %merge
        \\merge:
        \\  %result = load ptr, ptr %8
        \\  ret ptr %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    _ = try mem2reg.pass.run(&module, &context);
    try module.verify();
    const function = module.functions.items[0];
    const phi = function.blocks.items[3].instructions.items[0];
    try std.testing.expectEqualStrings("__zllvm_phi_1", phi.result.?);
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const pointers = @import("../codegen/x86_64/generic_cfg/pointer_values.zig");
    const normalized = (try pointers.legalize(arena.allocator(), function, null)).?;
    try std.testing.expect(try pointers.legalize(arena.allocator(), normalized, null) == null);
}

test "mem2reg promotes if-else stack slot with phi" {
    const input =
        \\define i32 @promote_if(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  %slot = alloca i32
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  store i32 %a, ptr %slot
        \\  br label %merge
        \\right:
        \\  store i32 %b, ptr %slot
        \\  br label %merge
        \\merge:
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @promote_if(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %slot.0 = phi i32 [ %a, %left ], [ %b, %right ]
        \\  ret i32 %slot.0
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "mem2reg promotes loop-carried stack slot" {
    const input =
        \\define i32 @promote_loop(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  br label %loop
        \\loop:
        \\  %v = load i32, ptr %slot
        \\  %more = icmp ne i32 %v, 0
        \\  br i1 %more, label %body, label %exit
        \\body:
        \\  %next = sub i32 %v, 1
        \\  store i32 %next, ptr %slot
        \\  br label %loop
        \\exit:
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @promote_loop(i32 %a) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %slot.0 = phi i32 [ %a, %entry ], [ %next, %body ]
        \\  %more = icmp ne i32 %slot.0, 0
        \\  br i1 %more, label %body, label %exit
        \\body:
        \\  %next = sub i32 %slot.0, 1
        \\  br label %loop
        \\exit:
        \\  ret i32 %slot.0
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "mem2reg promotes multiple independent stack slots" {
    const input =
        \\define i32 @promote_two(i1 %cond, i32 %a, i32 %b, i32 %c, i32 %d) {
        \\entry:
        \\  %x = alloca i32
        \\  %y = alloca i32
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  store i32 %a, ptr %x
        \\  store i32 %b, ptr %y
        \\  br label %merge
        \\right:
        \\  store i32 %c, ptr %x
        \\  store i32 %d, ptr %y
        \\  br label %merge
        \\merge:
        \\  %vx = load i32, ptr %x
        \\  %vy = load i32, ptr %y
        \\  %sum = add i32 %vx, %vy
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @promote_two(i1 %cond, i32 %a, i32 %b, i32 %c, i32 %d) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %y.0 = phi i32 [ %b, %left ], [ %d, %right ]
        \\  %x.0 = phi i32 [ %a, %left ], [ %c, %right ]
        \\  %sum = add i32 %x.0, %y.0
        \\  ret i32 %sum
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "mem2reg rejects escaped stack slot" {
    const input =
        \\define ptr @escape() {
        \\entry:
        \\  %slot = alloca i32
        \\  ret ptr %slot
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "mem2reg rejects stores of the stack slot pointer" {
    const input =
        \\define i32 @store_slot(ptr %sink) {
        \\entry:
        \\  %slot = alloca i32
        \\  store ptr %slot, ptr %sink
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "mem2reg ignores non-entry allocas" {
    const input =
        \\define i32 @non_entry_alloca(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\else:
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "mem2reg rejects volatile alloca users" {
    const input =
        \\define i32 @volatile_alloca(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store volatile i32 %a, ptr %slot, align 4
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "mem2reg rejects atomic alloca users as local barriers" {
    const input =
        \\define i32 @atomic_alloca(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store atomic i32 %a, ptr %slot release, align 4
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "simplifycfg folds constant branch and removes unreachable blocks" {
    const input =
        \\define i32 @branch(i32 %a) {
        \\entry:
        \\  br i1 1, label %then, label %else
        \\then:
        \\  ret i32 %a
        \\else:
        \\  %dead = add i32 %a, 1
        \\  ret i32 %dead
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @branch(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "simplifycfg prunes unreachable phi incoming and removes trivial phi" {
    const input =
        \\define i32 @phi_cleanup(i32 %a, i32 %b) {
        \\entry:
        \\  br i1 1, label %then, label %else
        \\then:
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %then ], [ %b, %else ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @phi_cleanup(i32 %a, i32 %b) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "simplifycfg merges matching return blocks" {
    const input =
        \\define i32 @common_ret(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  ret i32 %a
        \\else:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @common_ret(i1 %cond, i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "simplifycfg collapses same-target branch PHI edges when values match" {
    const input =
        \\define i32 @same_target_same_phi(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %merge, label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %entry ], [ %a, %entry ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @same_target_same_phi(i1 %cond, i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "simplifycfg does not thread phi predecessor through multiple edges" {
    const input =
        \\define i32 @switch_duplicate_edge(i2 %cond, i32 %a) {
        \\entry:
        \\  switch i2 %cond, label %empty [
        \\    i2 0, label %empty
        \\  ]
        \\empty:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %empty ]
        \\  ret i32 %v
        \\}
        \\
    ;
    const expected =
        \\define i32 @switch_duplicate_edge(i2 %cond, i32 %a) {
        \\entry:
        \\  switch i2 %cond, label %empty [
        \\    i2 0, label %empty
        \\  ]
        \\empty:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "simplifycfg keeps phi-distinct duplicate predecessor edges" {
    const input =
        \\define i32 @switch_distinct_phi_edges(i2 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  switch i2 %cond, label %empty_a [
        \\    i2 0, label %empty_b
        \\  ]
        \\empty_a:
        \\  br label %merge
        \\empty_b:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %empty_a ], [ %b, %empty_b ]
        \\  ret i32 %v
        \\}
        \\
    ;
    const expected =
        \\define i32 @switch_distinct_phi_edges(i2 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  switch i2 %cond, label %merge [
        \\    i2 0, label %empty_b
        \\  ]
        \\empty_b:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %entry ], [ %b, %empty_b ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}
