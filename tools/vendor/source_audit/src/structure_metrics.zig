//! Syntactic evidence for editing review, not a calibrated difficulty score.
//! Callers own returned data through their allocator (normally a report arena).
const std = @import("std");
const Ast = std.zig.Ast;
const A = std.mem.Allocator;

pub const Import = struct {
    kind: enum { local, module, dynamic },
    name: []const u8,
    line: usize,
    test_only: bool,
};
pub const Function = struct {
    name: []const u8,
    line: usize,
    bytes: usize,
    test_only: bool,
    decisions: usize = 0,
    switch_arms: usize = 0,
    max_nesting: usize = 0,
};
pub const Result = struct {
    functions: []const Function,
    imports: []const Import,
    outside_function_bytes: usize,
};
const Span = struct { first: u32, last: u32 };
const Scope = struct { span: Span, name: []const u8, test_only: bool };

fn span(tree: Ast, node: Ast.Node.Index) Span {
    return .{ .first = tree.firstToken(node), .last = tree.lastToken(node) };
}
fn line(tree: Ast, token: u32) usize {
    return 1 + std.mem.count(u8, tree.source[0..tree.tokenStart(token)], "\n");
}
fn scopeLess(_: void, x: Scope, y: Scope) bool {
    return if (x.span.first == y.span.first) x.span.last > y.span.last else x.span.first < y.span.first;
}
pub fn isTestFile(path: []const u8) bool {
    return std.mem.endsWith(u8, path, "_test.zig") or std.mem.endsWith(u8, path, "/testing.zig");
}

/// Parses in-process using the pinned compiler's public AST API. Includes test
/// bodies separately; nested functions do not add decisions to their parent.
pub fn inspect(a: A, source: [:0]const u8) !Result {
    var tree = try Ast.parse(a, source, .{ .mode = .zig });
    defer tree.deinit(a);
    if (tree.errors.len != 0) return error.InvalidZigSource;
    var scopes: std.ArrayList(Scope) = .empty;
    defer scopes.deinit(a);
    for (1..tree.nodes.len) |i| {
        const node: Ast.Node.Index = @fromBackingInt(@as(u32, @intCast(i)));
        switch (tree.nodeTag(node)) {
            .fn_decl => {
                var buffer: [1]Ast.Node.Index = undefined;
                const proto = tree.fullFnProto(&buffer, node).?;
                try scopes.append(a, .{ .span = span(tree, node), .name = tree.tokenSlice(proto.name_token.?), .test_only = false });
            },
            .test_decl => {
                const name = tree.nodeData(node).opt_token_and_node[0].unwrap();
                try scopes.append(a, .{ .span = span(tree, node), .name = if (name) |t| tree.tokenSlice(t) else "test", .test_only = true });
            },
            else => {},
        }
    }
    std.mem.sort(Scope, scopes.items, {}, scopeLess);
    const owners = try a.alloc(?usize, tree.tokens.len);
    defer a.free(owners);
    @memset(owners, null);
    const depths = try a.alloc(usize, tree.tokens.len);
    defer a.free(depths);
    @memset(depths, 0);
    const functions = try a.alloc(Function, scopes.items.len);
    var outside = source.len;
    var covered_end: usize = 0;
    for (scopes.items, 0..) |*s, index| {
        if (owners[s.span.first]) |parent| s.test_only = s.test_only or functions[parent].test_only;
        const start = tree.tokenStart(s.span.first);
        const end = tree.tokenStart(s.span.last) + tree.tokenSlice(s.span.last).len;
        if (end > covered_end) outside -= end - @max(start, covered_end);
        covered_end = @max(covered_end, end);
        functions[index] = .{ .name = try a.dupe(u8, s.name), .line = line(tree, s.span.first), .bytes = end - start, .test_only = s.test_only };
        @memset(owners[s.span.first .. s.span.last + 1], index);
    }
    var imports: std.ArrayList(Import) = .empty;
    const nesting = Nesting{ .tree = tree, .owners = owners, .depths = depths };
    for (1..tree.nodes.len) |i| {
        const node: Ast.Node.Index = @fromBackingInt(@as(u32, @intCast(i)));
        const token = tree.nodeMainToken(node);
        const owner = owners[token];
        var buffer: [2]Ast.Node.Index = undefined;
        if (tree.builtinCallParams(&buffer, node)) |params| {
            if (std.mem.eql(u8, tree.tokenSlice(token), "@import")) {
                const literal = params.len == 1 and tree.nodeTag(params[0]) == .string_literal;
                const name = if (literal)
                    std.zig.string_literal.parseAlloc(a, tree.tokenSlice(tree.nodeMainToken(params[0]))) catch |err| switch (err) {
                        error.InvalidLiteral => return error.InvalidZigSource,
                        else => return err,
                    }
                else
                    try a.dupe(u8, "<expression>");
                try imports.append(a, .{ .kind = if (!literal) .dynamic else if (std.mem.endsWith(u8, name, ".zig")) .local else .module, .name = name, .line = line(tree, token), .test_only = if (owner) |o| functions[o].test_only else false });
            }
        }
        const index = owner orelse continue;
        const f = &functions[index];
        if (tree.fullIf(node)) |v| {
            f.decisions += 1;
            nesting.deepen(v.ast.then_expr, index);
            if (v.ast.else_expr.unwrap()) |other| {
                // An else-if chain stays at the same body nesting level.
                if (tree.fullIf(other) == null) nesting.deepen(other, index);
            }
        } else if (tree.fullWhile(node)) |v| {
            f.decisions += 1;
            nesting.deepen(v.ast.then_expr, index);
            if (v.ast.else_expr.unwrap()) |other| nesting.deepen(other, index);
        } else if (tree.fullFor(node)) |v| {
            f.decisions += 1;
            nesting.deepen(v.ast.then_expr, index);
            if (v.ast.else_expr.unwrap()) |other| nesting.deepen(other, index);
        } else if (tree.fullSwitchCase(node)) |v| {
            f.switch_arms += 1;
            nesting.deepen(v.ast.target_expr, index);
        } else switch (tree.nodeTag(node)) {
            .bool_and, .bool_or => f.decisions += 1,
            .@"catch", .@"orelse" => {
                f.decisions += 1;
                nesting.deepen(tree.nodeData(node).node_and_node[1], index);
            },
            else => {},
        }
    }
    for (owners, depths) |owner, depth| {
        if (owner) |index| functions[index].max_nesting = @max(functions[index].max_nesting, depth);
    }
    return .{ .functions = functions, .imports = try imports.toOwnedSlice(a), .outside_function_bytes = outside };
}

const Nesting = struct {
    tree: Ast,
    owners: []const ?usize,
    depths: []usize,

    fn deepen(n: Nesting, node: Ast.Node.Index, owner: usize) void {
        const s = span(n.tree, node);
        for (s.first..s.last + 1) |token| {
            if (n.owners[token] == owner) n.depths[token] += 1;
        }
    }
};

test "AST distinguishes comments, escaped and expression imports, tests and nested functions" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const r = try inspect(arena.allocator(),
        \\// @import("fake.zig") if while
        \\const text = "@import(\"fake.zig\") if while";
        \\const dep = @import ("\x72eal.zig");
        \\const unknown = @import(prefix ++ ".zig");
        \\fn outer() void {
        \\    if (a) { while (b) {} }
        \\    const S = struct { fn inner() void { if (a and b) {} } };
        \\}
        \\test "separate" { const dep = @import("test.zig"); if (a) {} }
    );
    try std.testing.expectEqual(@as(usize, 3), r.functions.len);
    try std.testing.expectEqual(@as(usize, 2), r.functions[0].decisions);
    try std.testing.expectEqual(@as(usize, 2), r.functions[0].max_nesting);
    try std.testing.expectEqual(@as(usize, 2), r.functions[1].decisions);
    try std.testing.expectEqual(@as(usize, 1), r.functions[1].max_nesting);
    try std.testing.expect(r.functions[2].test_only);
    try std.testing.expectEqual(@as(usize, 3), r.imports.len);
    try std.testing.expectEqualStrings("real.zig", r.imports[0].name);
    try std.testing.expectEqual(.dynamic, r.imports[1].kind);
    try std.testing.expect(r.imports[2].test_only);
}

test "flat dispatch, else-if, fallbacks and loop bodies are separate signals" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const r = try inspect(arena.allocator(),
        \\fn dispatch(x: u8) void { switch (x) { 0, 1 => a(), 2 => b(), else => c() } }
        \\fn chain() void { if (a) {} else if (b or c) {} else {} }
        \\fn nested() void { for (items) |item| { if (item) { while (ready) {} } } }
        \\fn fallback() void { const x = (f() catch null) orelse return; }
    );
    try std.testing.expectEqual(@as(usize, 0), r.functions[0].decisions);
    try std.testing.expectEqual(@as(usize, 3), r.functions[0].switch_arms);
    try std.testing.expectEqual(@as(usize, 1), r.functions[0].max_nesting);
    try std.testing.expectEqual(@as(usize, 3), r.functions[1].decisions);
    try std.testing.expectEqual(@as(usize, 1), r.functions[1].max_nesting);
    try std.testing.expectEqual(@as(usize, 3), r.functions[2].max_nesting);
    try std.testing.expectEqual(@as(usize, 2), r.functions[3].decisions);
    try std.testing.expectError(error.InvalidZigSource, inspect(arena.allocator(), "const = ;"));
    try std.testing.expectError(error.InvalidZigSource, inspect(arena.allocator(), "const dep = @import(\"\\x\");"));
}

test "formatting and explanatory comments change bytes, not flow measurements" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const compact = try inspect(arena.allocator(), "fn f() void { if (a) { while (b) {} } }");
    const explained = try inspect(arena.allocator(), "fn f() void {\n // if for catch: this documents an invariant\n if (a) {\n while (b) {}\n }\n}\n");
    try std.testing.expect(explained.functions[0].bytes > compact.functions[0].bytes);
    try std.testing.expectEqual(compact.functions[0].decisions, explained.functions[0].decisions);
    try std.testing.expectEqual(compact.functions[0].max_nesting, explained.functions[0].max_nesting);
}

test "nested test helpers own their flow and declaration spans are not double-counted" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const source =
        \\// explanatory context
        \\const data = "if while";
        \\test "outer" {
        \\    if (ready) {
        \\        const Helper = struct { fn inner() void { while (ready) {} } };
        \\    }
        \\}
    ;
    const r = try inspect(arena.allocator(), source);
    try std.testing.expectEqual(@as(usize, 2), r.functions.len);
    for (r.functions) |f| {
        try std.testing.expect(f.test_only);
        try std.testing.expectEqual(@as(usize, 1), f.decisions);
        try std.testing.expectEqual(@as(usize, 1), f.max_nesting);
    }
    try std.testing.expectEqual(source.len, r.outside_function_bytes + r.functions[0].bytes);
}
