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

test "cfg analysis reports successors predecessors and reachability" {
    const input =
        \\define i32 @cfg(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %exit
        \\right:
        \\  br label %exit
        \\dead:
        \\  ret i32 0
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();

    try std.testing.expectEqualSlices(usize, &.{ 1, 2 }, graph.successors(0));
    try std.testing.expectEqualSlices(usize, &.{0}, graph.predecessors(1));
    try std.testing.expectEqualSlices(usize, &.{ 1, 2 }, graph.predecessors(4));

    const reachable = try graph.reachableFromEntry(std.testing.allocator);
    defer std.testing.allocator.free(reachable);

    try std.testing.expectEqualSlices(bool, &.{ true, true, true, false, true }, reachable);
}

test "dominator analysis answers dominance queries" {
    const input =
        \\define i32 @dom(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %exit
        \\right:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var dom = try dominator.Dominators.build(std.testing.allocator, function);
    defer dom.deinit();

    try std.testing.expect(dom.dominates(0, 0));
    try std.testing.expect(dom.dominates(0, 1));
    try std.testing.expect(dom.dominates(0, 2));
    try std.testing.expect(dom.dominates(0, 3));
    try std.testing.expect(dom.dominates(1, 1));
    try std.testing.expect(!dom.dominates(1, 3));
    try std.testing.expect(!dom.dominates(2, 3));
}

test "dominator analysis reports immediate dominators and frontiers" {
    const input =
        \\define i32 @frontier(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var dom = try dominator.Dominators.build(std.testing.allocator, function);
    defer dom.deinit();

    try std.testing.expectEqual(@as(?usize, null), dom.immediateDominator(0));
    try std.testing.expectEqual(@as(?usize, 0), dom.immediateDominator(1));
    try std.testing.expectEqual(@as(?usize, 0), dom.immediateDominator(2));
    try std.testing.expectEqual(@as(?usize, 0), dom.immediateDominator(3));

    var frontiers = try dominator.DominanceFrontiers.build(std.testing.allocator, function, dom);
    defer frontiers.deinit();

    try std.testing.expectEqualSlices(usize, &.{}, frontiers.frontier(0));
    try std.testing.expectEqualSlices(usize, &.{3}, frontiers.frontier(1));
    try std.testing.expectEqualSlices(usize, &.{3}, frontiers.frontier(2));
    try std.testing.expectEqualSlices(usize, &.{}, frontiers.frontier(3));
}

test "postdominator analysis answers postdominance queries" {
    const input =
        \\define i32 @postdom(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %exit
        \\right:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var postdom = try postdominator.PostDominators.build(std.testing.allocator, function);
    defer postdom.deinit();

    try std.testing.expect(postdom.postdominates(3, 0));
    try std.testing.expect(postdom.postdominates(3, 1));
    try std.testing.expect(postdom.postdominates(3, 2));
    try std.testing.expect(postdom.postdominates(3, 3));
    try std.testing.expect(postdom.postdominates(1, 1));
    try std.testing.expect(!postdom.postdominates(1, 0));
    try std.testing.expect(!postdom.postdominates(1, 2));

    try std.testing.expectEqual(@as(?usize, 3), postdom.immediatePostDominator(0));
    try std.testing.expectEqual(@as(?usize, 3), postdom.immediatePostDominator(1));
    try std.testing.expectEqual(@as(?usize, 3), postdom.immediatePostDominator(2));
    try std.testing.expectEqual(@as(?usize, null), postdom.immediatePostDominator(3));
}

test "control dependence reports branch-controlled blocks" {
    const input =
        \\define i32 @control_dep(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %then, label %exit
        \\then:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();

    var postdom = try postdominator.PostDominators.build(std.testing.allocator, function);
    defer postdom.deinit();

    const dependence: postdominator.ControlDependence = .{
        .graph = graph,
        .postdom = postdom,
    };

    try std.testing.expect(dependence.isControlDependentOn(1, 0));
    try std.testing.expect(!dependence.isControlDependentOn(2, 0));
    try std.testing.expect(!dependence.isControlDependentOn(0, 0));
}

test "postdominator analysis covers nested diamonds loops multiple exits and unreachable blocks" {
    const nested_diamond =
        \\define i32 @nested(i1 %a, i1 %b, i32 %v) {
        \\entry:
        \\  br i1 %a, label %left, label %right
        \\left:
        \\  br i1 %b, label %left_inner, label %left_join
        \\left_inner:
        \\  br label %left_join
        \\left_join:
        \\  br label %exit
        \\right:
        \\  br label %exit
        \\exit:
        \\  ret i32 %v
        \\}
        \\
    ;
    var nested_module = try ir.Module.parse(std.testing.allocator, nested_diamond);
    defer nested_module.deinit();
    const nested_function = nested_module.functions.items[0];
    var nested_postdom = try postdominator.PostDominators.build(std.testing.allocator, nested_function);
    defer nested_postdom.deinit();
    try std.testing.expectEqual(@as(?usize, 5), nested_postdom.immediatePostDominator(0));
    try std.testing.expectEqual(@as(?usize, 3), nested_postdom.immediatePostDominator(1));
    try std.testing.expectEqual(@as(?usize, 3), nested_postdom.immediatePostDominator(2));
    try std.testing.expectEqual(@as(?usize, 5), nested_postdom.immediatePostDominator(3));

    var nested_graph = try cfg.Graph.build(std.testing.allocator, nested_function);
    defer nested_graph.deinit();
    const nested_dependence: postdominator.ControlDependence = .{
        .graph = nested_graph,
        .postdom = nested_postdom,
    };
    try std.testing.expect(nested_dependence.isControlDependentOn(1, 0));
    try std.testing.expect(nested_dependence.isControlDependentOn(4, 0));
    try std.testing.expect(nested_dependence.isControlDependentOn(2, 1));
    try std.testing.expect(!nested_dependence.isControlDependentOn(3, 1));

    const loop_cfg =
        \\define i32 @loop_postdom(i1 %cond, i32 %v) {
        \\entry:
        \\  br label %header
        \\header:
        \\  br i1 %cond, label %body, label %exit
        \\body:
        \\  br label %header
        \\exit:
        \\  ret i32 %v
        \\}
        \\
    ;
    var loop_module = try ir.Module.parse(std.testing.allocator, loop_cfg);
    defer loop_module.deinit();
    const loop_function = loop_module.functions.items[0];
    var loop_postdom = try postdominator.PostDominators.build(std.testing.allocator, loop_function);
    defer loop_postdom.deinit();
    try std.testing.expectEqual(@as(?usize, 1), loop_postdom.immediatePostDominator(0));
    try std.testing.expectEqual(@as(?usize, 3), loop_postdom.immediatePostDominator(1));
    try std.testing.expectEqual(@as(?usize, 1), loop_postdom.immediatePostDominator(2));
    try std.testing.expectEqual(@as(?usize, null), loop_postdom.immediatePostDominator(3));

    const multi_exit =
        \\define i32 @multi_exit(i1 %cond, i32 %v) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  ret i32 %v
        \\right:
        \\  ret i32 0
        \\}
        \\
    ;
    var multi_module = try ir.Module.parse(std.testing.allocator, multi_exit);
    defer multi_module.deinit();
    const multi_function = multi_module.functions.items[0];
    var multi_postdom = try postdominator.PostDominators.build(std.testing.allocator, multi_function);
    defer multi_postdom.deinit();
    try std.testing.expectEqual(@as(?usize, null), multi_postdom.immediatePostDominator(0));
    try std.testing.expectEqual(@as(?usize, null), multi_postdom.immediatePostDominator(1));
    try std.testing.expectEqual(@as(?usize, null), multi_postdom.immediatePostDominator(2));

    const unreachable_cfg =
        \\define i32 @unreachable_postdom(i1 %cond, i32 %v) {
        \\entry:
        \\  br label %exit
        \\dead:
        \\  br label %exit
        \\exit:
        \\  ret i32 %v
        \\}
        \\
    ;
    var unreachable_module = try ir.Module.parse(std.testing.allocator, unreachable_cfg);
    defer unreachable_module.deinit();
    const unreachable_function = unreachable_module.functions.items[0];
    var unreachable_postdom = try postdominator.PostDominators.build(std.testing.allocator, unreachable_function);
    defer unreachable_postdom.deinit();
    try std.testing.expectEqual(@as(?usize, 2), unreachable_postdom.immediatePostDominator(0));
    try std.testing.expectEqual(@as(?usize, null), unreachable_postdom.immediatePostDominator(1));
    try std.testing.expectEqual(@as(?usize, null), unreachable_postdom.immediatePostDominator(2));
}

test "loop info finds a natural loop from a dominator backedge" {
    const input =
        \\define i32 @loop(i1 %cond, i32 %a) {
        \\entry:
        \\  br label %header
        \\header:
        \\  br i1 %cond, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var loops = try loop_info.LoopInfo.build(std.testing.allocator, function);
    defer loops.deinit();
    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();

    try std.testing.expectEqual(@as(usize, 1), loops.loops.items.len);
    const natural_loop = loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expectEqual(@as(usize, 1), natural_loop.header);
    try std.testing.expectEqual(@as(usize, 3), natural_loop.latch);
    try std.testing.expectEqual(@as(usize, 1), natural_loop.headerBlock());
    try std.testing.expectEqual(@as(usize, 3), natural_loop.latchBlock());
    try std.testing.expectEqual(@as(usize, 1), natural_loop.depthLevel());
    try std.testing.expectEqualSlices(usize, &.{ 1, 2, 3 }, natural_loop.blocks.items);
    try std.testing.expect(natural_loop.contains(2));
    try std.testing.expect(natural_loop.containsBlock(2));
    try std.testing.expect(!natural_loop.contains(4));
    try std.testing.expectEqual(@as(?usize, 0), natural_loop.preheader(function, graph));

    var latches = try natural_loop.latchBlocks(std.testing.allocator);
    defer latches.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{3}, latches.items);

    const backedge = natural_loop.backedge();
    try std.testing.expectEqual(@as(usize, 3), backedge.latch);
    try std.testing.expectEqual(@as(usize, 1), backedge.header);

    try std.testing.expectEqual(@as(usize, 1), loops.loopDepth(2));
    try std.testing.expectEqual(@as(usize, 0), loops.loopDepth(4));

    var header_latches = try loops.latchesForHeader(std.testing.allocator, 1);
    defer header_latches.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{3}, header_latches.items);

    var backedges = try loops.backedges(std.testing.allocator);
    defer backedges.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), backedges.items.len);
    try std.testing.expectEqual(@as(usize, 3), backedges.items[0].latch);
    try std.testing.expectEqual(@as(usize, 1), backedges.items[0].header);

    var def_blocks = std.StringHashMap(usize).init(std.testing.allocator);
    defer def_blocks.deinit();
    try def_blocks.put("a", std.math.maxInt(usize));
    try def_blocks.put("x", 2);
    try std.testing.expect(natural_loop.isLoopInvariantValue(.{ .named = "a" }, def_blocks));
    try std.testing.expect(natural_loop.isLoopInvariantValue(.{ .int = 1 }, def_blocks));
    try std.testing.expect(!natural_loop.isLoopInvariantValue(.{ .named = "x" }, def_blocks));

    var exiting = try natural_loop.exitingBlocks(std.testing.allocator, graph);
    defer exiting.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{1}, exiting.items);

    var exits = try natural_loop.exitBlocks(std.testing.allocator, graph);
    defer exits.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{4}, exits.items);
}

test "licm leaves loops without an existing preheader unchanged" {
    const input =
        \\define i32 @licm_no_preheader(i32 %a) {
        \\entry:
        \\  br i1 1, label %header, label %exit
        \\header:
        \\  %x = icmp sgt i32 %a, 0
        \\  br i1 %x, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(licm.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "loop info checks LCSSA form for outside loop uses" {
    const accepted =
        \\define i32 @lcssa_ok(i1 %cond) {
        \\entry:
        \\  br label %header
        \\header:
        \\  %i = phi i32 [ 0, %entry ], [ %next, %latch ]
        \\  br i1 %cond, label %latch, label %exit
        \\latch:
        \\  %next = add i32 %i, 1
        \\  br label %header
        \\exit:
        \\  %i.lcssa = phi i32 [ %i, %header ]
        \\  ret i32 %i.lcssa
        \\}
        \\
    ;

    var accepted_module = try ir.Module.parse(std.testing.allocator, accepted);
    defer accepted_module.deinit();
    const accepted_function = accepted_module.functions.items[0];

    var accepted_loops = try loop_info.LoopInfo.build(std.testing.allocator, accepted_function);
    defer accepted_loops.deinit();
    var accepted_graph = try cfg.Graph.build(std.testing.allocator, accepted_function);
    defer accepted_graph.deinit();

    const accepted_loop = accepted_loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expect(try accepted_loop.hasLcssaForm(std.testing.allocator, accepted_function, accepted_graph));

    const rejected =
        \\define i32 @lcssa_bad(i1 %cond) {
        \\entry:
        \\  br label %header
        \\header:
        \\  %i = phi i32 [ 0, %entry ], [ %next, %latch ]
        \\  br i1 %cond, label %latch, label %exit
        \\latch:
        \\  %next = add i32 %i, 1
        \\  br label %header
        \\exit:
        \\  ret i32 %i
        \\}
        \\
    ;

    var rejected_module = try ir.Module.parse(std.testing.allocator, rejected);
    defer rejected_module.deinit();
    const rejected_function = rejected_module.functions.items[0];

    var rejected_loops = try loop_info.LoopInfo.build(std.testing.allocator, rejected_function);
    defer rejected_loops.deinit();
    var rejected_graph = try cfg.Graph.build(std.testing.allocator, rejected_function);
    defer rejected_graph.deinit();

    const rejected_loop = rejected_loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expect(!try rejected_loop.hasLcssaForm(std.testing.allocator, rejected_function, rejected_graph));

    var rewrite_module = try ir.Module.parse(std.testing.allocator, rejected);
    defer rewrite_module.deinit();
    var rewrite_graph = try cfg.Graph.build(std.testing.allocator, rewrite_module.functions.items[0]);
    defer rewrite_graph.deinit();
    var rewrite_loops = try loop_info.LoopInfo.build(std.testing.allocator, rewrite_module.functions.items[0]);
    defer rewrite_loops.deinit();
    const rewrite_loop = rewrite_loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expect(try loop_info.formSimpleLcssa(&rewrite_module, 0, rewrite_loop.*, rewrite_graph));
    try rewrite_module.verify();

    var verify_graph = try cfg.Graph.build(std.testing.allocator, rewrite_module.functions.items[0]);
    defer verify_graph.deinit();
    var verify_loops = try loop_info.LoopInfo.build(std.testing.allocator, rewrite_module.functions.items[0]);
    defer verify_loops.deinit();
    const verify_loop = verify_loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expect(try verify_loop.hasLcssaForm(std.testing.allocator, rewrite_module.functions.items[0], verify_graph));

    const non_dedicated =
        \\define i32 @lcssa_non_dedicated(i1 %cond, i1 %side) {
        \\entry:
        \\  br i1 %side, label %outside, label %header
        \\outside:
        \\  br label %exit
        \\header:
        \\  %i = phi i32 [ 0, %entry ], [ %next, %latch ]
        \\  br i1 %cond, label %latch, label %exit
        \\latch:
        \\  %next = add i32 %i, 1
        \\  br label %header
        \\exit:
        \\  ret i32 %i
        \\}
        \\
    ;

    var non_dedicated_module = try ir.Module.parse(std.testing.allocator, non_dedicated);
    defer non_dedicated_module.deinit();
    var non_dedicated_graph = try cfg.Graph.build(std.testing.allocator, non_dedicated_module.functions.items[0]);
    defer non_dedicated_graph.deinit();
    var non_dedicated_loops = try loop_info.LoopInfo.build(std.testing.allocator, non_dedicated_module.functions.items[0]);
    defer non_dedicated_loops.deinit();
    const non_dedicated_loop = non_dedicated_loops.loopForHeader(2) orelse return error.MissingLoop;
    try std.testing.expect(!try non_dedicated_loop.hasDedicatedExits(std.testing.allocator, non_dedicated_graph));
    try std.testing.expect(!try loop_info.formSimpleLcssa(&non_dedicated_module, 0, non_dedicated_loop.*, non_dedicated_graph));
}

test "loop info classifies reduced Zig corpus loop shape" {
    const input =
        \\define i32 @corpus_loop(i32 %n) {
        \\1:
        \\  %.not = icmp eq i32 %n, 0
        \\  br i1 %.not, label %._crit_edge, label %.lr.ph.preheader
        \\.lr.ph.preheader:
        \\  br label %.lr.ph
        \\.lr.ph:
        \\  %.01 = phi i32 [ 0, %.lr.ph.preheader ], [ %next, %.lr.ph ]
        \\  %next = add nuw i32 %.01, 1
        \\  %done = icmp eq i32 %next, %n
        \\  br i1 %done, label %._crit_edge, label %.lr.ph, !llvm.loop !0
        \\._crit_edge:
        \\  %.0.lcssa = phi i32 [ 0, %1 ], [ %next, %.lr.ph ]
        \\  ret i32 %.0.lcssa
        \\}
        \\
        \\!0 = distinct !{!0}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const function = module.functions.items[0];

    var loops = try loop_info.LoopInfo.build(std.testing.allocator, function);
    defer loops.deinit();
    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();

    const natural_loop = loops.loopForHeader(2) orelse return error.MissingLoop;
    try std.testing.expectEqual(@as(usize, 2), natural_loop.header);
    try std.testing.expectEqual(@as(usize, 2), natural_loop.latch);

    var exiting = try natural_loop.exitingBlocks(std.testing.allocator, graph);
    defer exiting.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{2}, exiting.items);

    var exits = try natural_loop.exitBlocks(std.testing.allocator, graph);
    defer exits.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{3}, exits.items);
    try std.testing.expect(try natural_loop.hasLcssaForm(std.testing.allocator, function, graph));

    var inductions = try natural_loop.simpleInductionVariables(std.testing.allocator, function);
    defer inductions.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), inductions.items.len);
    try std.testing.expectEqualStrings(".01", inductions.items[0].phi_result);
    try std.testing.expectEqual(ir.Value{ .int = 0 }, inductions.items[0].initial_value);
    try std.testing.expectEqual(ir.Value{ .int = 1 }, inductions.items[0].step_value);
    try std.testing.expectEqualStrings("next", inductions.items[0].next_value);
    try std.testing.expect(natural_loop.isSideEffectFreeDeletionCandidate(function));
    try std.testing.expectEqual(loop_info.LoopRotateStatus.unsupported_self_latch_header, natural_loop.rotationStatus(function, graph));
    try std.testing.expectEqual(loop_info.LoopDeletionStatus.eligible_not_implemented, try natural_loop.deletionStatus(std.testing.allocator, function, graph));
}

test "loop info rejects side-effecting loop deletion candidates" {
    const input =
        \\define void @loop_store(i1 %cond, ptr %p, i32 %v) {
        \\entry:
        \\  br label %header
        \\header:
        \\  br i1 %cond, label %body, label %exit
        \\body:
        \\  store i32 %v, ptr %p
        \\  br label %header
        \\exit:
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var loops = try loop_info.LoopInfo.build(std.testing.allocator, function);
    defer loops.deinit();
    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();
    const natural_loop = loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expect(!natural_loop.isSideEffectFreeDeletionCandidate(function));
    try std.testing.expectEqual(loop_info.LoopDeletionStatus.rejected_side_effects, try natural_loop.deletionStatus(std.testing.allocator, function, graph));
}

test "loop info reports nested loop depth and innermost block ownership" {
    const input =
        \\define i32 @nested_loops(i1 %outer_cond, i1 %inner_cond, i32 %a) {
        \\entry:
        \\  br label %outer_header
        \\outer_header:
        \\  br i1 %outer_cond, label %inner_preheader, label %exit
        \\inner_preheader:
        \\  br label %inner_header
        \\inner_header:
        \\  br i1 %inner_cond, label %inner_latch, label %outer_latch
        \\inner_latch:
        \\  br label %inner_header
        \\outer_latch:
        \\  br label %outer_header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var loops = try loop_info.LoopInfo.build(std.testing.allocator, function);
    defer loops.deinit();

    try std.testing.expectEqual(@as(usize, 2), loops.loops.items.len);
    const outer = loops.loopForHeader(1) orelse return error.MissingLoop;
    const inner = loops.loopForHeader(3) orelse return error.MissingLoop;

    try std.testing.expectEqual(@as(usize, 1), outer.depthLevel());
    try std.testing.expectEqual(@as(usize, 2), inner.depthLevel());
    try std.testing.expectEqual(@as(?usize, outer.header), if (inner.parent_index) |parent_index| loops.loops.items[parent_index].header else null);
    try std.testing.expectEqual(@as(usize, 1), loops.loopDepth(5));
    try std.testing.expectEqual(@as(usize, 2), loops.loopDepth(4));

    const inner_owner = loops.loopForBlock(4) orelse return error.MissingLoop;
    try std.testing.expectEqual(@as(usize, 3), inner_owner.header);
}

test "licm leaves side-effecting stores in the loop" {
    const input =
        \\define i32 @licm_store_reject(i32 %a) {
        \\entry:
        \\  %p = alloca i32
        \\  br label %header
        \\header:
        \\  %i = phi i32 [ 0, %entry ], [ %next, %latch ]
        \\  store i32 %i, ptr %p
        \\  br i1 1, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  %next = add i32 %i, 1
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(licm.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "licm leaves memory loads in the loop" {
    const input =
        \\define i32 @licm_load_reject(i32 %a) {
        \\entry:
        \\  %p = alloca i32
        \\  store i32 %a, ptr %p
        \\  br label %header
        \\header:
        \\  %v = load i32, ptr %p
        \\  store i32 %v, ptr %p
        \\  br i1 1, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(licm.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "licm hoists invariant aligned header loads when memory is not clobbered" {
    const input =
        \\define i32 @licm_aligned_load_reject(i32 %a, ptr %p) {
        \\entry:
        \\  br label %header
        \\header:
        \\  %v = load i32, ptr %p, align 4
        \\  %c = icmp sgt i32 %v, 0
        \\  br i1 %c, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;
    const expected =
        \\define i32 @licm_aligned_load_reject(i32 %a, ptr %p) {
        \\entry:
        \\  %v = load i32, ptr %p, align 4
        \\  %c = icmp sgt i32 %v, 0
        \\  br label %header
        \\header:
        \\  br i1 %c, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(licm.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "licm leaves trapping divisions in the loop" {
    const input =
        \\define i32 @licm_trap_reject(i32 %a, i32 %b) {
        \\entry:
        \\  br label %header
        \\header:
        \\  %q = sdiv i32 %a, %b
        \\  br i1 1, label %body, label %exit
        \\body:
        \\  br label %latch
        \\latch:
        \\  br label %header
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(licm.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "dce preserves atomic memory barriers" {
    const input =
        \\define i32 @memory_atomic_barrier_reject(i32 %a, ptr %p) {
        \\entry:
        \\  store atomic i32 %a, ptr %p release, align 4
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "licm skips multi-latch loops until canonical loop support exists" {
    const input =
        \\define i32 @licm_multi_latch(i32 %a) {
        \\entry:
        \\  br label %header
        \\header:
        \\  %x = icmp sgt i32 %a, 0
        \\  br i1 %x, label %left, label %right
        \\left:
        \\  br label %latch_left
        \\latch_left:
        \\  br label %header
        \\right:
        \\  br label %latch_right
        \\latch_right:
        \\  br label %header
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(licm.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "early-cse removes repeated pure expressions in a block" {
    const input =
        \\define i32 @cse(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %y = add i32 %a, 1
        \\  %z = mul i32 %y, 2
        \\  ret i32 %z
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(early_cse.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @cse(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %z = mul i32 %x, 2
        \\  ret i32 %z
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "early-cse removes dominating pure and safe load expressions" {
    const input =
        \\define i32 @cse_dom_load(i1 %cond, ptr %p, i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %l0 = load i32, ptr %p
        \\  br i1 %cond, label %then, label %exit
        \\then:
        \\  %y = add i32 %a, 1
        \\  %l1 = load i32, ptr %p
        \\  %z = add i32 %y, %l1
        \\  ret i32 %z
        \\exit:
        \\  ret i32 %l0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(early_cse.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @cse_dom_load(i1 %cond, ptr %p, i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %l0 = load i32, ptr %p
        \\  br i1 %cond, label %then, label %exit
        \\then:
        \\  %z = add i32 %x, %l0
        \\  ret i32 %z
        \\exit:
        \\  ret i32 %l0
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "early-cse removes matching readnone calls" {
    const input =
        \\declare i32 @pure(i32) readnone
        \\
        \\define i32 @cse_readnone_call(i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  %y = call i32 @pure(i32 %a)
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(early_cse.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\declare i32 @pure(i32) readnone
        \\
        \\define i32 @cse_readnone_call(i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  ret i32 %x
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "early-cse preserves operand-bundled readnone calls conservatively" {
    const input =
        \\declare i32 @pure() #0
        \\
        \\define i32 @cse_bundled_readnone_call() {
        \\entry:
        \\  %x = call i32 @pure() [ "cold"() ]
        \\  %y = call i32 @pure() [ "deopt"() ]
        \\  %z = add i32 %x, %y
        \\  ret i32 %z
        \\}
        \\
        \\attributes #0 = { memory(none) nounwind }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(early_cse.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "gvn removes equivalent phi nodes and safe loads" {
    const input =
        \\define i32 @gvn_phi_load(i1 %cond, ptr %p, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %join
        \\right:
        \\  br label %join
        \\join:
        \\  %p0 = phi i32 [ %a, %left ], [ %b, %right ]
        \\  %p1 = phi i32 [ %a, %left ], [ %b, %right ]
        \\  %l0 = load i32, ptr %p
        \\  %l1 = load i32, ptr %p
        \\  %x = add i32 %p1, %l1
        \\  ret i32 %x
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(gvn.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @gvn_phi_load(i1 %cond, ptr %p, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %join
        \\right:
        \\  br label %join
        \\join:
        \\  %p0 = phi i32 [ %a, %left ], [ %b, %right ]
        \\  %l0 = load i32, ptr %p
        \\  %x = add i32 %p0, %l0
        \\  ret i32 %x
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "gvn removes matching readnone calls" {
    const input =
        \\declare i32 @pure(i32) readnone
        \\
        \\define i32 @gvn_readnone_call(i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  %y = call i32 @pure(i32 %a)
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(gvn.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\declare i32 @pure(i32) readnone
        \\
        \\define i32 @gvn_readnone_call(i32 %a) {
        \\entry:
        \\  %x = call i32 @pure(i32 %a)
        \\  ret i32 %x
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "sccp folds direct calls to constant-return functions" {
    const input =
        \\define internal i32 @constant() {
        \\entry:
        \\  ret i32 7
        \\}
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %x = call i32 @constant()
        \\  ret i32 %x
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(sccp.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define internal i32 @constant() {
        \\entry:
        \\  ret i32 7
        \\}
        \\
        \\define i32 @caller() {
        \\entry:
        \\  ret i32 7
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "slp vectorizer recognizes same-op scalar bundles and reports unsupported transform" {
    const input =
        \\define i32 @slp_seed(i32 %a, i32 %b, i32 %c, i32 %d) {
        \\entry:
        \\  %x0 = add i32 %a, %b
        \\  %x1 = add i32 %c, %d
        \\  %sum = add i32 %x0, %x1
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    const candidate = slp_vectorizer.findCandidate(module.functions.items[0]) orelse return error.ExpectedSlpCandidate;
    try std.testing.expectEqualStrings("slp_seed", candidate.function_name);
    try std.testing.expectEqualStrings("entry", candidate.block_name);
    try std.testing.expectEqualStrings("x0", candidate.first_result);
    try std.testing.expectEqualStrings("x1", candidate.second_result);
    try std.testing.expectEqual(ir.BinaryOp.add, candidate.opcode);
    try std.testing.expectEqual(@as(usize, 2), candidate.lanes);

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(slp_vectorizer.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    const result = try pm.run(&module, &context, &output.writer, false);
    try std.testing.expectEqual(pass_manager.PassResult.unchanged, result);
    try std.testing.expectEqual(@as(usize, 1), context.diagnostic_count);
    const diagnostic = context.last_diagnostic orelse return error.ExpectedSlpDiagnostic;
    try std.testing.expectEqualStrings("slp-vectorizer", diagnostic.pass_name);
    try std.testing.expectEqualStrings("slp_seed", diagnostic.function_name);
    try std.testing.expectEqualStrings("x0", diagnostic.value_name.?);
    try std.testing.expectEqualStrings(slp_vectorizer.diagnostic_message, diagnostic.message);
}
