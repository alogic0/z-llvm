const codegen_x86_64_common = @import("codegen_x86_64_common.zig");

const std = codegen_x86_64_common.std;
const air_bridge = codegen_x86_64_common.air_bridge;
const alias = codegen_x86_64_common.alias;
const call_graph = codegen_x86_64_common.call_graph;
const cfg = codegen_x86_64_common.cfg;
const codegen = codegen_x86_64_common.codegen;
const dominator = codegen_x86_64_common.dominator;
const function_attrs = codegen_x86_64_common.function_attrs;
const fp_semantics = codegen_x86_64_common.fp_semantics;
const loop_info = codegen_x86_64_common.loop_info;
const memory_effect = codegen_x86_64_common.memory_effect;
const memory_location = codegen_x86_64_common.memory_location;
const memory_ssa = codegen_x86_64_common.memory_ssa;
const ir = codegen_x86_64_common.ir;
const normalize = codegen_x86_64_common.normalize;
const mc = codegen_x86_64_common.mc;
const pass_manager = codegen_x86_64_common.pass_manager;
const pipelines = codegen_x86_64_common.pipelines;
const postdominator = codegen_x86_64_common.postdominator;
const semantic_descriptor_v2 = codegen_x86_64_common.semantic_descriptor_v2;
const target = codegen_x86_64_common.target;
const target_library_info = codegen_x86_64_common.target_library_info;
const target_transform_info = codegen_x86_64_common.target_transform_info;
const instcombine = codegen_x86_64_common.instcombine;
const zig_air_export = codegen_x86_64_common.zig_air_export;
const zig_air_lowering = codegen_x86_64_common.zig_air_lowering;
const dce = codegen_x86_64_common.dce;
const dse = codegen_x86_64_common.dse;
const early_cse = codegen_x86_64_common.early_cse;
const gvn = codegen_x86_64_common.gvn;
const licm = codegen_x86_64_common.licm;
const mem2reg = codegen_x86_64_common.mem2reg;
const sccp = codegen_x86_64_common.sccp;
const simplifycfg = codegen_x86_64_common.simplifycfg;
const slp_vectorizer = codegen_x86_64_common.slp_vectorizer;
const sroa = codegen_x86_64_common.sroa;
const expectMachineInstruction = codegen_x86_64_common.expectMachineInstruction;
test "x86_64 elf writer emits relocatable object metadata" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add_args(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    const object = try mc.elf.buildObject(std.testing.allocator, &.{machine});
    defer std.testing.allocator.free(object);

    try std.testing.expect(object.len >= 64);
    try std.testing.expectEqualSlices(u8, "\x7fELF", object[0..4]);
    try std.testing.expectEqual(@as(u8, 2), object[4]);
    try std.testing.expect(std.mem.indexOf(u8, object, ".text") != null);
    try std.testing.expect(std.mem.indexOf(u8, object, ".symtab") != null);
    try std.testing.expect(std.mem.indexOf(u8, object, "add_args") != null);
}

test "x86_64 elf writer emits direct call relocation metadata" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee()
        \\
        \\define i32 @call_no_args() {
        \\entry:
        \\  %r = call i32 @callee()
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    const object = try mc.elf.buildObject(std.testing.allocator, &.{machine});
    defer std.testing.allocator.free(object);

    try std.testing.expect(std.mem.indexOf(u8, object, ".rela.text") != null);
    try std.testing.expect(std.mem.indexOf(u8, object, "callee") != null);
}

test "x86_64 elf writer emits selected local function aliases" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@public_add = alias i32 (i32, i32), ptr @internal_add
        \\
        \\define private i32 @internal_add(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    const object = try mc.elf.buildObjectWithAliases(std.testing.allocator, &.{machine}, module.aliases.items);
    defer std.testing.allocator.free(object);

    try std.testing.expect(std.mem.indexOf(u8, object, "internal_add") != null);
    try std.testing.expect(std.mem.indexOf(u8, object, "public_add") != null);
}

test "x86_64 elf symbols resolve quoted calls aliases and data references to one definition" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\@"ex\70ort" = alias i32 (), ptr @"helper(\22type\22)"
        \\@table = global [1 x ptr] [ptr @export]
        \\define internal i32 @"helper(\22type\22)"() {
        \\entry:
        \\ ret i32 42
        \\}
        \\define i32 @caller() {
        \\entry:
        \\ %r = call i32 @"helper(\22type\22)"()
        \\ ret i32 %r
        \\}
    );
    defer module.deinit();
    try module.verify();
    var functions: std.ArrayList(codegen.x86_64.MachineFunction) = .empty;
    defer {
        for (functions.items) |*function| function.deinit(std.testing.allocator);
        functions.deinit(std.testing.allocator);
    }
    for (module.functions.items) |function| {
        var lowered = try codegen.x86_64.lowerFunctionWithOptions(std.testing.allocator, "x86_64-unknown-linux-gnu", function, .{ .generic_cfg_selector = true });
        errdefer lowered.deinit(std.testing.allocator);
        try functions.append(std.testing.allocator, lowered);
    }
    const object = try mc.elf.buildObjectWithModuleContext(std.testing.allocator, functions.items, module.aliases.items, .{
        .globals = module.globals.items,
        .named_types = module.named_types.items,
        .target_datalayout = null,
        .functions = module.functions.items,
        .emit_all_globals = true,
        .require_resolved_aliases = true,
    });
    defer std.testing.allocator.free(object);
    const shoff: usize = @intCast(std.mem.readInt(u64, object[40..48], .little));
    const shnum = std.mem.readInt(u16, object[60..62], .little);
    var names: usize = 0;
    for (0..shnum) |section| {
        const header = object[shoff + section * 64 ..][0..64];
        if (std.mem.readInt(u32, header[4..8], .little) != 2) continue;
        const start: usize = @intCast(std.mem.readInt(u64, header[24..32], .little));
        const size: usize = @intCast(std.mem.readInt(u64, header[32..40], .little));
        const strings = object[shoff + std.mem.readInt(u32, header[40..44], .little) * 64 ..][0..64];
        const strtab: usize = @intCast(std.mem.readInt(u64, strings[24..32], .little));
        var offset = start + 24; // Skip the mandatory null symbol.
        while (offset < start + size) : (offset += 24) {
            const symbol = object[offset..][0..24];
            try std.testing.expect(std.mem.readInt(u16, symbol[6..8], .little) != 0);
            const name = std.mem.sliceTo(object[strtab + std.mem.readInt(u32, symbol[0..4], .little) ..], 0);
            if (std.mem.eql(u8, name, "helper(\"type\")") or std.mem.eql(u8, name, "export")) names += 1;
        }
    }
    try std.testing.expectEqual(@as(usize, 2), names);
}
