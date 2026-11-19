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

test "legacy nocapture shares the verified pointer capture set" {
    try ir.verifyParameterAttrs(.ptr, "noalias nocapture writeonly");
    try std.testing.expectError(error.UnsupportedCallAttribute, ir.verifyParameterAttrs(.{ .int = 64 }, "nocapture"));
    for ([_][]const u8{ "nocapture nocapture", "captures(none) nocapture", "nocapture captures(address)" }) |attrs|
        try std.testing.expectError(error.UnsupportedCallAttribute, ir.verifyParameterAttrs(.ptr, attrs));
}

test "nullable memory attributes retain every function and call boundary" {
    for ([_][]const u8{ "dereferenceable_or_null(0)", "dereferenceable_or_null(16)", "noundef align 8 dereferenceable_or_null(140)", "dereferenceable(8) dereferenceable_or_null(16)" }) |attrs| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\declare {0s} ptr @helper(ptr {0s})
            \\define {0s} ptr @forward(ptr {0s} %input) {{
            \\entry:
            \\ %answer = call {0s} ptr @helper(ptr {0s} %input)
            \\ ret ptr %answer
            \\}}
        , .{attrs});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const function = module.functions.items[0];
        try std.testing.expectEqualStrings(attrs, function.ret_attrs.?);
        try std.testing.expectEqualStrings(attrs, function.params.items[0].attrs.?);
        const call = function.blocks.items[0].instructions.items[0].kind.call;
        try std.testing.expectEqualStrings(attrs, call.ret_attrs.?);
        try std.testing.expectEqualStrings(attrs, call.args.items[0].attrs.?);
    }
}

test "attributed call arguments preserve the outer constant expression" {
    const gep = "getelementptr inbounds (i8, ptr inttoptr (i64 1 to ptr), i64 0)";
    const diff = "sub (i64 ptrtoint (ptr @object to i64), i64 1)";
    var module = try ir.Module.parse(std.testing.allocator,
        "@object = global i8 0\n" ++
            "declare void @use(ptr, i64)\n" ++
            "define void @caller() {\nentry:\n" ++
            " call void @use(ptr align 1 readonly nonnull " ++ gep ++ ", i64 noundef " ++ diff ++ ")\n" ++
            " ret void\n}\n");
    defer module.deinit();
    try module.verify();
    const args = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call.args.items;
    try std.testing.expect(args[0].ty == .ptr);
    try std.testing.expectEqualStrings("align 1 readonly nonnull", args[0].attrs.?);
    try std.testing.expectEqualStrings(gep, args[0].value.constant_expr);
    try std.testing.expectEqual(@as(u16, 64), args[1].ty.int);
    try std.testing.expectEqualStrings("noundef", args[1].attrs.?);
    try std.testing.expectEqualStrings(diff, args[1].value.constant_expr);

    const parseArg = @import("../ir/parser_calls.zig").parseCallArg;
    const quoted = try parseArg("ptr byval(%\"record inttoptr (payload)\") %\"parameter getelementptr (value)\"");
    try std.testing.expectEqualStrings("byval(%\"record inttoptr (payload)\")", quoted.attrs.?);
    try std.testing.expectEqualStrings("\"parameter getelementptr (value)\"", quoted.value.named);
    try std.testing.expectError(error.InvalidCall, parseArg("ptr nonnull " ++ gep ++ " inttoptr (i64 2 to ptr)"));
    const misaligned = try parseArg("ptr align 3 " ++ gep);
    try std.testing.expectError(error.InvalidAlignment, ir.verifyParameterAttrs(misaligned.ty, misaligned.attrs));
}

test "memory promise payloads and extension attributes reject malformed duplicate and incompatible forms" {
    for ([_][]const u8{ "dereferenceable_or_null()", "dereferenceable_or_null(-1)", "dereferenceable_or_null(+16)", "dereferenceable_or_null(1_6)", "dereferenceable_or_null(0x10)", "dereferenceable_or_null(16)junk", "dereferenceable_or_null(18446744073709551616)", "dereferenceable_or_null(16) dereferenceable_or_null(16)" }) |attrs| {
        try std.testing.expectError(error.UnsupportedCallAttribute, ir.verifyParameterAttrs(.ptr, attrs));
    }
    try std.testing.expectError(error.UnsupportedCallAttribute, ir.verifyParameterAttrs(.{ .int = 64 }, "dereferenceable_or_null(16)"));
    for ([_][]const u8{ "zeroext zeroext", "signext signext", "zeroext signext", "signext zeroext" }) |attrs| {
        try std.testing.expectError(error.UnsupportedCallAttribute, ir.verifyParameterAttrs(.{ .int = 8 }, attrs));
    }
    for ([_][]const u8{ "zeroext", "signext" }) |attrs| {
        try ir.verifyParameterAttrs(.{ .int = 8 }, attrs);
        try std.testing.expectError(error.UnsupportedCallAttribute, ir.verifyParameterAttrs(.ptr, attrs));
    }
}
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

test "allocptr preserves allocator attributes through parsing and release optimization" {
    const input =
        \\declare void @free(ptr allocptr noundef align 1 captures(none)) local_unnamed_addr #54
        \\define void @release(ptr allocptr %p) {
        \\entry:
        \\  call void @free(ptr allocptr noundef align 1 captures(none) %p)
        \\  ret void
        \\}
        \\attributes #54 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" }
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    var round_trip = try ir.Module.parse(std.testing.allocator, output.writer.buffered());
    defer round_trip.deinit();
    try round_trip.verify();
    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, "release-o3");
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    _ = try pm.run(&module, &context, &output.writer, false);
    try module.verify();
    try std.testing.expectEqualStrings("allocptr noundef align 1 captures(none)", module.declarations.items[0].params.items[0].attrs.?);
    try std.testing.expect(std.mem.indexOf(u8, module.attribute_groups.items[0], "allockind(\"free\")") != null);
    try std.testing.expect(std.mem.indexOf(u8, module.attribute_groups.items[0], "\"alloc-family\"=\"malloc\"") != null);
    var calls: usize = 0;
    for (module.functions.items[0].blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .call) {
            calls += 1;
            try std.testing.expectEqualStrings("free", inst.kind.call.callee);
            try std.testing.expectEqualStrings("allocptr noundef align 1 captures(none)", inst.kind.call.args.items[0].attrs.?);
        }
    };
    try std.testing.expectEqual(@as(usize, 1), calls);
}

test "allocptr rejects nonpointer duplicate and malformed parameter and call attributes" {
    for ([_][]const u8{
        "declare void @bad(i64 allocptr)",
        "declare void @bad(<2 x ptr> allocptr)",
        "declare void @bad(ptr allocptr allocptr)",
        "declare void @bad(ptr allocptr(1))",
        "define void @bad(i32 allocptr %p) {\nentry:\n ret void\n}",
        "declare void @free(ptr)\ndefine void @bad(ptr %p) {\nentry:\n call void @free(ptr allocptr allocptr %p)\n ret void\n}",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try std.testing.expectError(error.UnsupportedCallAttribute, module.verify());
    }
}
test "parser preserves module target records and void return" {
    const input =
        \\source_filename = "tiny.zig"
        \\target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @side_effect_free() {
        \\entry:
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const layout = try target.DataLayout.parse(module.target_datalayout.?);
    try std.testing.expectEqual(@as(u16, 64), try layout.pointerSizeBits());

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves function linkage and header attributes" {
    const input =
        \\source_filename = "attrs.zig"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define internal i32 @kept(i32 %a) local_unnamed_addr #0 {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    try std.testing.expectEqual(ir.FunctionLinkage.internal, function.linkage);
    try std.testing.expectEqualStrings("local_unnamed_addr #0", function.attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser accepts anonymous aggregate return function header" {
    const input =
        \\define private fastcc { ptr, i64 } @main.errorName(i16 %0) unnamed_addr #0 align 1 {
        \\  ret { ptr, i64 } undef
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    try std.testing.expectEqual(ir.FunctionLinkage.private, function.linkage);
    try std.testing.expectEqualStrings("fastcc", function.calling_conv.?);
    try std.testing.expect(function.ret_ty.eql(.{ .aggregate = "{ ptr, i64 }" }));
    try std.testing.expectEqualStrings("unnamed_addr #0 align 1", function.attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\define private fastcc { ptr, i64 } @main.errorName(i16 %0) unnamed_addr #0 align 1 {
        \\1:
        \\  ret { ptr, i64 } undef
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "parser preserves function visibility and parameter attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define external hidden i32 @visible(i32 noundef %a, ptr nonnull readonly captures(none) initializes((0, 4)) %p, ptr nonnull readnone align 1 captures(address) %q, ptr nonnull readnone align 1 captures(address, ret: address, provenance) %r) #1 {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    try std.testing.expectEqual(ir.FunctionLinkage.external, function.linkage);
    try std.testing.expectEqual(ir.FunctionVisibility.hidden, function.visibility);
    try std.testing.expectEqualStrings("noundef", function.params.items[0].attrs.?);
    try std.testing.expectEqualStrings("nonnull readonly captures(none) initializes((0, 4))", function.params.items[1].attrs.?);
    try std.testing.expectEqualStrings("nonnull readnone align 1 captures(address)", function.params.items[2].attrs.?);
    try std.testing.expectEqualStrings("nonnull readnone align 1 captures(address, ret: address, provenance)", function.params.items[3].attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves pointer ABI parameter attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\%Named.Sret = type { i16, i8 }
        \\
        \\declare void @takes_byval(ptr byval({ i32, i32 }), ptr sret({ i32, i32 }))
        \\
        \\define void @abi_attrs(ptr byval({ i32, i32 }) %src, ptr sret({ i32, i32 }) %dst) {
        \\entry:
        \\  ret void
        \\}
        \\
        \\define void @named_sret(ptr noalias sret({ i16, %Named.Sret }) captures(none) %out) {
        \\entry:
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings("byval({ i32, i32 })", module.declarations.items[0].params.items[0].attrs.?);
    try std.testing.expectEqualStrings("sret({ i32, i32 })", module.declarations.items[0].params.items[1].attrs.?);
    try std.testing.expectEqualStrings("byval({ i32, i32 })", module.functions.items[0].params.items[0].attrs.?);
    try std.testing.expectEqualStrings("sret({ i32, i32 })", module.functions.items[0].params.items[1].attrs.?);
    try std.testing.expectEqualStrings("noalias sret({ i16, %Named.Sret }) captures(none)", module.functions.items[1].params.items[0].attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves call argument attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @takes_ptrs(ptr, ptr)
        \\
        \\define void @caller(ptr %p, ptr %q) {
        \\entry:
        \\  call void @takes_ptrs(ptr nonnull %p, ptr nonnull readonly align 1 dereferenceable(1) %q)
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("nonnull", call.args.items[0].attrs.?);
    try std.testing.expectEqualStrings("nonnull readonly align 1 dereferenceable(1)", call.args.items[1].attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves call return attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i16 @llvm.ctpop.i16(i16)
        \\
        \\define i16 @caller(i16 %x) {
        \\entry:
        \\  %count = call range(i16 0, 17) i16 @llvm.ctpop.i16(i16 %x)
        \\  ret i16 %count
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("range(i16 0, 17)", call.ret_attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves inline asm call argument attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @target() {
        \\entry:
        \\  ret void
        \\}
        \\
        \\define void @caller() {
        \\entry:
        \\  tail call void asm sideeffect "", "X,X,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @caller, ptr nonnull @target) #0
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[1].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("nonnull", call.args.items[0].attrs.?);
    try std.testing.expectEqualStrings("nonnull", call.args.items[1].attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves call operand bundles" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.assume(i1)
        \\
        \\define void @caller() {
        \\entry:
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  call void @llvm.assume(i1 1) #0 [ "cold"() ], !noalias !0
        \\  ret void
        \\}
        \\
        \\attributes #0 = { nounwind }
        \\
        \\!0 = !{!1}
        \\!1 = distinct !{!1}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const plain_call = module.functions.items[0].blocks.items[0].instructions.items[0];
    try std.testing.expectEqualStrings("[ \"cold\"() ]", plain_call.kind.call.operand_bundle.?);
    try std.testing.expect(plain_call.kind.call.attrs == null);

    const attr_call = module.functions.items[0].blocks.items[0].instructions.items[1];
    try std.testing.expectEqualStrings("#0", attr_call.kind.call.attrs.?);
    try std.testing.expectEqualStrings("[ \"cold\"() ]", attr_call.kind.call.operand_bundle.?);
    try std.testing.expectEqualStrings("!noalias !0", attr_call.metadata.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser rejects malformed call operand bundles" {
    const unquoted =
        \\declare void @llvm.assume(i1)
        \\
        \\define void @caller() {
        \\entry:
        \\  call void @llvm.assume(i1 true) [ cold() ]
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedOperandBundle, ir.Module.parse(std.testing.allocator, unquoted));

    const inputs =
        \\declare void @llvm.assume(i1)
        \\
        \\define void @caller(i32 %x) {
        \\entry:
        \\  call void @llvm.assume(i1 true) [ "cold"(i32 %x) ]
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedOperandBundle, ir.Module.parse(std.testing.allocator, inputs));
}

test "verifier checks capture attributes at call argument sites" {
    for ([_]struct { ty: []const u8, attrs: []const u8, valid: bool }{
        .{ .ty = "ptr", .attrs = "nocapture", .valid = true },
        .{ .ty = "ptr", .attrs = "swiftself", .valid = false },
        .{ .ty = "ptr", .attrs = "nocapture captures(none)", .valid = false },
        .{ .ty = "i32", .attrs = "nocapture", .valid = false },
    }) |case| {
        const input = try std.fmt.allocPrint(std.testing.allocator,
            \\declare void @callee({0s})
            \\define void @caller({0s} %p) {{
            \\entry:
            \\  call void @callee({0s} {1s} %p)
            \\  ret void
            \\}}
        , .{ case.ty, case.attrs });
        defer std.testing.allocator.free(input);
        var module = try ir.Module.parse(std.testing.allocator, input);
        defer module.deinit();
        if (case.valid) {
            try module.verify();
        } else {
            try std.testing.expectError(error.UnsupportedCallAttribute, module.verify());
        }
    }
}

test "verifier rejects invalid call argument attribute payloads" {
    const invalid_align =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @takes_ptr(ptr)
        \\
        \\define void @caller(ptr %p) {
        \\entry:
        \\  call void @takes_ptr(ptr align 3 %p)
        \\  ret void
        \\}
        \\
    ;

    var align_module = try ir.Module.parse(std.testing.allocator, invalid_align);
    defer align_module.deinit();
    try std.testing.expectError(error.InvalidAlignment, align_module.verify());

    const invalid_dereferenceable =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @takes_ptr(ptr)
        \\
        \\define void @caller(ptr %p) {
        \\entry:
        \\  call void @takes_ptr(ptr dereferenceable() %p)
        \\  ret void
        \\}
        \\
    ;

    var deref_module = try ir.Module.parse(std.testing.allocator, invalid_dereferenceable);
    defer deref_module.deinit();
    try std.testing.expectError(error.UnsupportedCallAttribute, deref_module.verify());
}

test "verifier rejects duplicate call argument attributes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @takes_ptr(ptr)
        \\
        \\define void @caller(ptr %p) {
        \\entry:
        \\  call void @takes_ptr(ptr nonnull nonnull %p)
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectError(error.UnsupportedCallAttribute, module.verify());
}

test "parser preserves switch terminators" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @select_switch(i32 %tag) {
        \\entry:
        \\  switch i32 %tag, label %default [
        \\    i32 0, label %zero
        \\    i32 7, label %seven
        \\  ]
        \\zero:
        \\  ret i32 10
        \\seven:
        \\  ret i32 17
        \\default:
        \\  ret i32 99
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const switch_term = module.functions.items[0].blocks.items[0].terminator.?.@"switch";
    try std.testing.expectEqualStrings("default", switch_term.default_target);
    try std.testing.expectEqual(@as(usize, 2), switch_term.cases.items.len);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves switch labels containing bracket characters" {
    const input =
        \\define i32 @switch_bracket_label(i32 %tag) {
        \\entry:
        \\  switch i32 %tag, label %default [
        \\    i32 0, label %"array_hash_map.Custom([]const u8).exit"
        \\  ], !prof !0
        \\"array_hash_map.Custom([]const u8).exit":
        \\  ret i32 7
        \\default:
        \\  ret i32 99
        \\}
        \\
        \\!0 = !{!"branch_weights", i32 1, i32 2}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const switch_term = module.functions.items[0].blocks.items[0].terminator.?.@"switch";
    try std.testing.expectEqual(@as(usize, 1), switch_term.cases.items.len);
    try std.testing.expectEqualStrings("\"array_hash_map.Custom([]const u8).exit\"", switch_term.cases.items[0].target);
    try std.testing.expectEqualStrings("!prof !0", switch_term.metadata.?);
}

test "parser preserves indirectbr terminators" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @dispatch(ptr %addr) {
        \\entry:
        \\  indirectbr ptr %addr, [label %left, label %right]
        \\left:
        \\  ret void
        \\right:
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const indirectbr = module.functions.items[0].blocks.items[0].terminator.?.indirectbr;
    try std.testing.expect(indirectbr.addr_ty.eql(.ptr));
    try std.testing.expectEqualStrings("addr", indirectbr.addr.named);
    try std.testing.expectEqual(@as(usize, 2), indirectbr.targets.items.len);
    try std.testing.expectEqualStrings("left", indirectbr.targets.items[0]);
    try std.testing.expectEqualStrings("right", indirectbr.targets.items[1]);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves vector splat call arguments" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare <4 x i32> @add_splat(<4 x i32>, <4 x i32>)
        \\
        \\define <4 x i32> @caller(<4 x i32> %x) {
        \\entry:
        \\  %sum = call <4 x i32> @add_splat(<4 x i32> %x, <4 x i32> splat (i32 16))
        \\  ret <4 x i32> %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("splat (i32 16)", call.args.items[1].value.vector);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves poison call arguments" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @takes_poison(i64)
        \\
        \\define i64 @caller() {
        \\entry:
        \\  %value = call i64 @takes_poison(i64 poison)
        \\  ret i64 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqual(call.args.items[0].value, .poison);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser infers numeric implicit entry block names" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i1 @implicit_entry_phi(i1 %cond) {
        \\  %1 = zext i1 %cond to i8
        \\  br i1 %cond, label %join, label %other
        \\other:
        \\  br label %join
        \\join:
        \\  %value = phi i1 [ true, %0 ], [ false, %other ]
        \\  ret i1 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings("0", module.functions.items[0].blocks.items[0].name);
}

test "parser infers zero implicit entry block before nonnumeric result" {
    const input =
        \\define i1 @implicit_zero_entry(i1 %cond) {
        \\  %.slot = alloca i8
        \\  br i1 %cond, label %then, label %join
        \\then:
        \\  br label %join
        \\join:
        \\  %value = phi i1 [ true, %then ], [ false, %0 ]
        \\  ret i1 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings("0", module.functions.items[0].blocks.items[0].name);
}

test "parser and verifier accept pointer integer casts" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define ptr @as_ptr(i64 %addr) {
        \\entry:
        \\  %p = inttoptr i64 %addr to ptr
        \\  ret ptr %p
        \\}
        \\
        \\define i64 @as_int(ptr %p) {
        \\entry:
        \\  %addr = ptrtoint ptr %p to i64
        \\  ret i64 %addr
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves pointer cast constant expressions in phis" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define ptr @constant_expr_phi(i1 %cond) {
        \\entry:
        \\  br i1 %cond, label %then, label %merge
        \\then:
        \\  br label %merge
        \\merge:
        \\  %p = phi ptr [ inttoptr (i64 1 to ptr), %entry ], [ null, %then ]
        \\  ret ptr %p
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser verifies and prints phi incoming poison" {
    const input =
        \\define i64 @phi_poison(i1 %cond, i64 %x) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %v = phi i64 [ poison, %left ], [ %x, %right ]
        \\  ret i64 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const phi = module.functions.items[0].blocks.items[3].instructions.items[0].kind.phi;
    try std.testing.expectEqual(ir.Value.poison, phi.incoming.items[0].value);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves icmp samesign flag" {
    const input =
        \\define i1 @cmp(i64 %a, i64 %b) {
        \\entry:
        \\  %r = icmp samesign ult i64 %a, %b
        \\  ret i1 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cmp = module.functions.items[0].blocks.items[0].instructions.items[0].kind.icmp;
    try std.testing.expect(cmp.samesign);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves integer constant expressions in icmp and binary operands" {
    const input =
        \\@start = external global i8
        \\@end = external global i8
        \\
        \\define i1 @constant_expr_cmp() {
        \\entry:
        \\  %cmp = icmp eq i64 sub (i64 ptrtoint (ptr @end to i64), i64 ptrtoint (ptr @start to i64)), 0
        \\  %shift = lshr exact i64 sub (i64 ptrtoint (ptr @end to i64), i64 ptrtoint (ptr @start to i64)), 3
        \\  ret i1 %cmp
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cmp = module.functions.items[0].blocks.items[0].instructions.items[0].kind.icmp;
    try std.testing.expect(cmp.lhs == .constant_expr);

    const shift = module.functions.items[0].blocks.items[0].instructions.items[1].kind.binary;
    try std.testing.expect(shift.lhs == .constant_expr);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser verifies and prints or disjoint flags" {
    const input =
        \\define i64 @or_disjoint(i8 %a, i64 %x) {
        \\entry:
        \\  %r = or disjoint i8 %a, 48
        \\  %wide = zext i8 %r to i64
        \\  %s = or disjoint i64 %x, 18014398509481984
        \\  %out = or i64 %s, %wide
        \\  ret i64 %out
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const byte_or = module.functions.items[0].blocks.items[0].instructions.items[0].kind.binary;
    try std.testing.expectEqual(ir.BinaryOp.@"or", byte_or.op);
    try std.testing.expect(byte_or.flags.disjoint);
    try std.testing.expectEqual(ir.Type{ .int = 8 }, byte_or.ty);

    const wide_or = module.functions.items[0].blocks.items[0].instructions.items[2].kind.binary;
    try std.testing.expectEqual(ir.BinaryOp.@"or", wide_or.op);
    try std.testing.expect(wide_or.flags.disjoint);
    try std.testing.expectEqual(ir.Type{ .int = 64 }, wide_or.ty);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier rejects invalid ABI parameter attributes" {
    const byval_non_pointer =
        \\declare void @bad(i32 byval({ i32 }))
        \\
    ;

    var byval_module = try ir.Module.parse(std.testing.allocator, byval_non_pointer);
    defer byval_module.deinit();
    try std.testing.expectError(error.UnsupportedAbiType, byval_module.verify());

    const sret_non_pointer =
        \\define void @bad(i32 sret({ i32 }) %result) {
        \\entry:
        \\  ret void
        \\}
        \\
    ;

    var sret_module = try ir.Module.parse(std.testing.allocator, sret_non_pointer);
    defer sret_module.deinit();
    try std.testing.expectError(error.UnsupportedAbiType, sret_module.verify());
}

test "parser preserves source-backed varargs declarations and calls" {
    const input =
        \\declare i32 @printf(ptr noundef nonnull readonly align 1 captures(none), ...)
        \\
        \\define i32 @caller(ptr %p) {
        \\entry:
        \\  %result = call i32 (ptr, ...) @printf(ptr nonnull readonly align 1 dereferenceable(1) %p, double 2.000000e+00)
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expect(module.declarations.items[0].is_varargs);
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("(ptr, ...)", call.callee_function_ty.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());

    const vararg_call =
        \\declare void @sink(ptr)
        \\
        \\define void @caller(ptr %p) {
        \\entry:
        \\  call void @sink(ptr %p, ...)
        \\  ret void
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedVarArgs, ir.Module.parse(std.testing.allocator, vararg_call));
}

test "verifier accepts source-backed naked function register-argument calls" {
    const input =
        \\define i64 @naked_target() #0 {
        \\entry:
        \\  unreachable
        \\}
        \\
        \\define i64 @caller(ptr %entry, i64 %stack) {
        \\entry:
        \\  %result = call i64 @naked_target(ptr %entry, i64 %stack, i32 8195840)
        \\  ret i64 %result
        \\}
        \\
        \\attributes #0 = { naked nounwind }
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(input, output.writer.buffered());

    const non_naked =
        \\define i64 @target() {
        \\entry:
        \\  unreachable
        \\}
        \\
        \\define i64 @caller(ptr %entry) {
        \\entry:
        \\  %result = call i64 @target(ptr %entry)
        \\  ret i64 %result
        \\}
        \\
    ;
    var bad_module = try ir.Module.parse(std.testing.allocator, non_naked);
    defer bad_module.deinit();
    try std.testing.expectError(error.CallSignatureMismatch, bad_module.verify());
}

test "verifier accepts dead_on_unwind on pointer parameters and rejects invalid usage" {
    const valid =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @takes_dead_on_unwind(ptr dead_on_unwind)
        \\
        \\define void @caller(ptr dead_on_unwind noalias %p) {
        \\entry:
        \\  call void @takes_dead_on_unwind(ptr dead_on_unwind %p)
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, valid);
    defer module.deinit();
    try module.verify();

    try std.testing.expectEqualStrings("dead_on_unwind", module.declarations.items[0].params.items[0].attrs.?);
    try std.testing.expectEqualStrings("dead_on_unwind noalias", module.functions.items[0].params.items[0].attrs.?);

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("dead_on_unwind", call.args.items[0].attrs.?);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    try std.testing.expectEqualStrings(valid, output.writer.buffered());

    const bad_non_ptr =
        \\define void @bad(i32 dead_on_unwind %x) {
        \\entry:
        \\  ret void
        \\}
        \\
    ;
    var bad_non_ptr_module = try ir.Module.parse(std.testing.allocator, bad_non_ptr);
    defer bad_non_ptr_module.deinit();
    try std.testing.expectError(error.UnsupportedCallAttribute, bad_non_ptr_module.verify());

    const bad_duplicate =
        \\define void @bad(ptr dead_on_unwind dead_on_unwind %p) {
        \\entry:
        \\  ret void
        \\}
        \\
    ;
    var bad_dup_module = try ir.Module.parse(std.testing.allocator, bad_duplicate);
    defer bad_dup_module.deinit();
    try std.testing.expectError(error.UnsupportedCallAttribute, bad_dup_module.verify());
}

test "naked function attributes are complete tokens across group references" {
    const attrs = @import("../ir/function_attributes.zig");
    const groups = [_][]const u8{
        "attributes #0 = { nounwind \"note\"=\"not naked\" }",
        "attributes #1 = { naked noreturn nounwind }",
    };
    try std.testing.expect(attrs.contains("#0 #1", &groups, "naked"));
    try std.testing.expect(attrs.contains("#0 naked", &groups, "naked"));
    try std.testing.expect(!attrs.contains("#0", &groups, "naked"));
    try std.testing.expect(!attrs.contains("\"naked\"=\"yes\"", &groups, "naked"));
}
