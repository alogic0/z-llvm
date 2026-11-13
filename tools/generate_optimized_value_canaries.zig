//! Bounded pointer constants, mixed boolean calls and padded floating storage.
const std = @import("std");
const u = @import("validation/common.zig");
const Output = @import("generate_optimized_fact_canaries.zig").Output;
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root", "population" }, &.{});
    const population = args.get("population");
    const typed_frame = if (population) |name| std.mem.eql(u8, name, "typed_floating_frames") else false;
    const floating_hints = if (population) |name| std.mem.eql(u8, name, "floating_vector_hints") else false;
    if (population != null and !typed_frame and !floating_hints) return error.UnsupportedPopulation;
    const root = try c.newOutput(try args.require("output-root"));
    var entries = u.array(c.a);
    if (floating_hints) {
        try u.add(&entries, try floatingHints(&c, root));
    } else if (!typed_frame) {
        try u.add(&entries, try symbolicPointers(&c, root));
        try u.add(&entries, try floatingBooleans(&c, root));
    }
    if (!floating_hints) try u.add(&entries, try paddedFloating(&c, root, typed_frame));
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = entries }));
    if (args.get("verify-root")) |before| {
        const old = try u.json.array(try u.get(try c.load(try c.join(&.{ before, "native_canaries.json" })), "canaries"));
        for (try u.json.array(entries)) |entry| {
            var found = false;
            for (old) |candidate| if (u.json.is(try u.get(candidate, "population"), try u.str(entry, "population"))) {
                if (found or !u.json.eql(entry, candidate)) return error.RegistryContractMismatch;
                found = true;
            };
            if (!found) return error.PopulationMissing;
            for ([_][]const u8{ ".ll", "_driver.c" }) |suffix| {
                const file = try c.fmt("{s}{s}", .{ try u.str(entry, "fixture"), suffix });
                if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureMismatch;
            }
        }
    }
    try c.print("{s}{s}\n", .{ if (floating_hints) "floating vector hints:72 cases/144 definitions/36864 observations per route" else if (typed_frame) "typed floating frames:16 cases/8192 observations per route" else "optimized values:three populations/six fixtures", if (args.get("verify-root") != null) "; byte-exact verification passed" else "" });
}

fn floatingHints(c: *u.Context, root: []const u8) !u.Value {
    const contract = "independent-integer-payload-goldens=four-double-x87-and-quad=fastcc-optional-tail-and-notail=literal-and-dynamic-vectors=one-and-two-vector-arguments=caller-and-callee-call-clobbers=source-and-output-guards=preserved";
    var out = try Output.init(c, "floating-vector-hints", "floating_vector_hints_model.c", contract);
    const literals = [_][]const u8{
        "<double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>",
        "<x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>",
        "<fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>",
    };
    for ([_][]const u8{ "double", "x86_fp80", "fp128" }, [_]usize{ 64, 80, 128 }, literals) |ty, bits, literal| for (1..3) |arity| for (0..2) |constant| for (0..2) |facts| for ([_][]const u8{ "", "tail ", "notail " }) |hint| {
        const body = try c.fmt("floating_hint_body_{d}", .{out.count});
        const probe = try c.fmt("floating_hint_probe_{d}", .{out.count});
        const attrs = if (facts != 0) "noundef " else "";
        const bytes = bits / 8 * 4;
        const payload = bytes * arity;
        try u.add(&out.functions, u.s(body));
        try out.probe(c, probe, bits, arity * 2 + constant);
        try out.ir.writer.print("define internal fastcc i64 @{s}(ptr %out,<4 x {s}> {s}%a{s},i64 %salt) noinline {{\nentry:\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store <4 x {s}> %a,ptr %out,align 1\n", .{ body, ty, attrs, if (arity == 2) try c.fmt(",<4 x {s}> {s}%b", .{ ty, attrs }) else "", ty });
        if (arity == 2) try out.ir.writer.print(" %next = getelementptr i8,ptr %out,i64 {d}\n store <4 x {s}> %b,ptr %next,align 1\n", .{ bytes, ty });
        try out.ir.writer.print(" %token_out = getelementptr i8,ptr %out,i64 {d}\n store i64 %token,ptr %token_out,align 1\n ret i64 %token\n}}\ndefine i64 @{s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n", .{ payload, probe });
        if (constant == 0) {
            try out.ir.writer.print(" %a = load <4 x {s}>,ptr %source,align 1\n", .{ty});
            if (arity == 2) try out.ir.writer.print(" %next = getelementptr i8,ptr %source,i64 {d}\n %b = load <4 x {s}>,ptr %next,align 1\n", .{ bytes, ty });
        } else if (facts != 0) {
            // The existing parser admits vector attributes with SSA operands.
            // Keep direct literal calls in the unannotated cases and cover
            // attributed constants through a defined, equivalent SSA value.
            var lanes = std.mem.splitScalar(u8, literal[1 .. literal.len - 1], ',');
            for (0..4) |lane| {
                const name = if (lane == 3) "a" else try c.fmt("literal_{d}", .{lane});
                const previous = if (lane == 0) "poison" else try c.fmt("%literal_{d}", .{lane - 1});
                try out.ir.writer.print(" %{s} = insertelement <4 x {s}> {s},{s},i64 {d}\n", .{ name, ty, previous, lanes.next() orelse return error.MissingFloatingLiteralLane, lane });
            }
            if (lanes.next() != null) return error.ExtraFloatingLiteralLane;
        }
        const left = if (constant != 0 and facts == 0) literal else "%a";
        const right = if (constant != 0) (if (facts == 0) literal else "%a") else "%b";
        try out.ir.writer.print(" %r = {s}call fastcc i64 @{s}(ptr %out,<4 x {s}> {s}{s}{s},i64 %salt)\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n %after = getelementptr i8,ptr %out,i64 {d}\n store <4 x {s}> {s},ptr %after,align 1\n", .{ hint, body, ty, attrs, left, if (arity == 2) try c.fmt(",<4 x {s}> {s}{s}", .{ ty, attrs, right }) else "", payload + 8, ty, left });
        if (arity == 2) try out.ir.writer.print(" %after2 = getelementptr i8,ptr %after,i64 {d}\n store <4 x {s}> {s},ptr %after2,align 1\n", .{ bytes, ty, right });
        try out.ir.writer.print(" %last = getelementptr i8,ptr %out,i64 {d}\n store i64 %token,ptr %last,align 1\n %answer = xor i64 %r,%salt\n ret i64 %answer\n}}\n", .{payload * 2 + 8});
    };
    if (out.count != 72) return error.FloatingHintInventoryChanged;
    return out.finish(c, root, "floating_vector_hints", "floating-vector-hints", contract);
}

fn symbolicPointers(c: *u.Context, root: []const u8) !u.Value {
    const contract = "independent-c-symbol-addresses=typed-roundtrips=bounded-modular-offsets=pointer-stores=call-arguments=comparisons=phi-edges=selects=call-clobbers=guard-pages=preserved";
    var out = try Output.init(c, "symbolic-roundtrips", "symbolic_roundtrips_model.c", contract);
    try out.ir.writer.writeAll("@symbolic_roundtrip_storage = global [256 x i8] zeroinitializer,align 16\ndeclare i64 @complete_pointer_echo(ptr)\n");
    const Pair = struct { base: i32, delta: i32 };
    const pairs = [_]Pair{ .{ .base = 1, .delta = 1 }, .{ .base = 4, .delta = 4 }, .{ .base = 8, .delta = 8 }, .{ .base = 16, .delta = 16 }, .{ .base = 32, .delta = 32 }, .{ .base = 64, .delta = 64 }, .{ .base = 64, .delta = 1 }, .{ .base = 64, .delta = 7 }, .{ .base = 64, .delta = -1 }, .{ .base = 64, .delta = -17 }, .{ .base = 128, .delta = 32 }, .{ .base = 128, .delta = 64 } };
    for (pairs) |pair| for (0..2) |subtract| for (0..@as(usize, if (pair.delta < 0) 2 else 1)) |unsigned| for (0..2) |phi| {
        const offset = if (subtract != 0) pair.base - pair.delta else pair.base + pair.delta;
        if (offset < 0 or offset >= 255) return error.SymbolicOracleBounds;
        const delta = if (unsigned != 0) try c.fmt("{d}", .{@as(u64, @bitCast(@as(i64, pair.delta)))}) else try c.fmt("{d}", .{pair.delta});
        const expression = try c.fmt("inttoptr (i64 {s} (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 {d}) to i64),i64 {s}) to ptr)", .{ if (subtract != 0) "sub" else "add", pair.base, delta });
        const expected = try c.fmt("getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 {d})", .{offset});
        const next = try c.fmt("getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 {d})", .{offset + 1});
        const probe = try c.fmt("symbolic_roundtrip_probe_{d}", .{out.count});
        try out.probe(c, probe, @intCast(offset), phi);
        try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n", .{probe});
        if (phi != 0) try out.ir.writer.print(" %bit = and i64 %salt,1\n %condition = icmp ne i64 %bit,0\n br i1 %condition,label %left,label %right\nleft:\n br label %merge\nright:\n br label %merge\nmerge:\n %selected = phi ptr [{s},%left],[{s},%right]\n %expected = select i1 %condition,ptr {s},ptr {s}\n", .{ expression, next, expected, next });
        const value = if (phi != 0) "%selected" else expression;
        try out.ir.writer.print(" store ptr {0s},ptr %out,align 1\n %actual = load ptr,ptr %out,align 1\n %address = ptrtoint ptr %actual to i64\n %same = icmp eq ptr {0s},{1s}\n %wide = zext i1 %same to i64\n %echo = call i64 @complete_pointer_echo(ptr {0s})\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n %p1 = getelementptr i8,ptr %out,i64 8\n store i64 %wide,ptr %p1,align 1\n %p2 = getelementptr i8,ptr %out,i64 16\n store i64 %echo,ptr %p2,align 1\n %p3 = getelementptr i8,ptr %out,i64 24\n store i64 %token,ptr %p3,align 1\n %answer = xor i64 %address,%token\n ret i64 %answer\n}}\n", .{ value, if (phi != 0) "%expected" else expected });
    };
    if (out.count != 56) return error.SymbolicCaseInventoryChanged;
    return out.finish(c, root, "symbolic_roundtrips", "symbolic-roundtrips", contract);
}

fn floatingBooleans(c: *u.Context, root: []const u8) !u.Value {
    const contract = "independent-integer-floating-goldens=ordered-nan-comparisons=mixed-boolean-return-abi=half-through-quad=cc-and-fastcc=optional-call-hints=call-clobbers=guard-pages=preserved";
    var out = try Output.init(c, "floating-boolean-calls", "floating_boolean_calls_model.c", contract);
    for ([_][]const u8{ "half", "float", "double", "x86_fp80", "fp128" }, [_]usize{ 16, 32, 64, 80, 128 }) |ty, bits| for ([_][]const u8{ "", "fastcc " }) |cc| for (1..3) |arity| for ([_][]const u8{ "", "tail ", "notail " }) |hint| {
        const body = try c.fmt("floating_boolean_body_{d}", .{out.count});
        const probe = try c.fmt("floating_boolean_probe_{d}", .{out.count});
        try u.add(&out.functions, u.s(body));
        try out.probe(c, probe, bits, arity);
        try out.ir.writer.print("define internal {s}i1 @{s}({s} %a{s}) noinline {{\nentry:\n %ordered = fcmp ord {s} %a,{s}\n ret i1 %ordered\n}}\n", .{ cc, body, ty, if (arity == 2) try c.fmt(",{s} %b", .{ty}) else "", ty, if (arity == 2) "%b" else "%a" });
        try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n %a = load {s},ptr %source,align 1\n", .{ probe, ty });
        if (arity == 2) try out.ir.writer.print(" %next = getelementptr i8,ptr %source,i64 {d}\n %b = load {s},ptr %next,align 1\n", .{ if (bits >= 80) 16 else bits / 8, ty });
        try out.ir.writer.print(" %r = {s}call {s}i1 @{s}({s} %a{s})\n %value = zext i1 %r to i64\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store i64 %value,ptr %out,align 1\n %p = getelementptr i8,ptr %out,i64 8\n store i64 %token,ptr %p,align 1\n %answer = xor i64 %value,%token\n ret i64 %answer\n}}\n", .{ hint, cc, body, ty, if (arity == 2) try c.fmt(",{s} %b", .{ty}) else "" });
    };
    if (out.count != 60) return error.FloatingBooleanInventoryChanged;
    return out.finish(c, root, "floating_boolean_calls", "floating-boolean-calls", contract);
}

fn paddedFloating(c: *u.Context, root: []const u8, typed: bool) !u.Value {
    const contract = if (typed) "independent-byte-goldens=native-float-and-half-vectors=owned-i32-frames=literal-and-dynamic-payloads=signaling-and-quiet-nans=escaped-storage=neighbor-guards=call-clobbers=preserved" else "independent-byte-goldens=native-float-and-half-vectors=owned-byte-frames=literal-and-dynamic-payloads=signaling-and-quiet-nans=escaped-storage=neighbor-guards=call-clobbers=preserved";
    const prefix = if (typed) "typed-floating-frames" else "padded-floating-memory";
    var out = try Output.init(c, prefix, "padded_floating_memory_model.c", contract);
    try out.ir.writer.writeAll("declare void @complete_touch(ptr)\n");
    const types = [_][]const u8{ "<4 x float>", "<8 x half>" };
    const values = [_][]const u8{ "<float 1.000000e+00,float -0.000000e+00,float 0x7FF8000020000000,float 0x7FF4000000000000>", "<half 0xH3C00,half 0xH8000,half 0xH7C00,half 0xHFC00,half 0xH7E01,half 0xH7D55,half 0xH0001,half 0xH03FF>" };
    for (types, values, [_]usize{ 32, 16 }) |ty, literal, bits| for (0..2) |constant| for ([_]usize{ 16, 32, 48, 64 }) |offset| {
        const probe = try c.fmt("{s}_probe_{d}", .{ if (typed) "typed_floating" else "padded_floating", out.count });
        try out.probe(c, probe, bits, constant);
        try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n %frame = alloca {s},align 16\n %slot = getelementptr i8,ptr %frame,i64 {d}\n %before = getelementptr i8,ptr %slot,i64 -1\n %after = getelementptr i8,ptr %slot,i64 16\n store i8 81,ptr %before,align 1\n store i8 163,ptr %after,align 1\n", .{ probe, if (typed) "[24 x i32]" else "[96 x i8]", offset });
        if (constant == 0) try out.ir.writer.print(" %input = load {s},ptr %source,align 1\n", .{ty});
        try out.ir.writer.print(" store {s} {s},ptr %slot,align 16\n call void @complete_touch(ptr %slot)\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n %value = load {s},ptr %slot,align 16\n store {s} %value,ptr %out,align 1\n %token_out = getelementptr i8,ptr %out,i64 16\n store i64 %token,ptr %token_out,align 1\n %first = load i8,ptr %before,align 1\n %last = load i8,ptr %after,align 1\n %first_out = getelementptr i8,ptr %out,i64 24\n %last_out = getelementptr i8,ptr %out,i64 25\n store i8 %first,ptr %first_out,align 1\n store i8 %last,ptr %last_out,align 1\n ret i64 %token\n}}\n", .{ ty, if (constant != 0) literal else "%input", ty, ty });
    };
    if (out.count != 16) return error.PaddedFloatingInventoryChanged;
    return out.finish(c, root, if (typed) "typed_floating_frames" else "padded_floating_memory", prefix, contract);
}
