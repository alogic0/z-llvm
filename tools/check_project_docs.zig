const std = @import("std");
const Status = struct {
    schema: u32,
    accepted_revision: []const u8,
    accepted_tree: []const u8,
    source_pin: []const u8,
    candidate_sha256: []const u8,
    selector_version: []const u8 = "real-candidate-selector-v2",
    modes: []const []const u8,
    candidate_rows: u32,
    lowered: u32,
    objects: u32,
    native_linked: u32,
    executed_functions: u32,
    paired_harnesses_ok: u32,
    local_fail: u32,
    compiler_rt_bypass_ratchet: u32,
    declaration_revision: []const u8,
    evidence: []const []const u8,
};
const begin = "<!-- accepted-status:start -->";
const end = "<!-- accepted-status:end -->";
const docs = [_][]const u8{
    "docs/roadmap/correctness_checkpoint.md",
    "docs/architecture.md",
    "docs/roadmap/architecture_refactor_plan.md",
    "docs/roadmap/optimizer_boundary_repairs.md",
    "docs/evidence/composed_memset_family.md",
    "README.md",
    "CONTRIBUTING.md",
    "THIRD_PARTY_NOTICES.md",
    "docs/README.md",
    "docs/ir/README.md",
    "docs/roadmap/historical/README.md",
    "docs/current_state.md",
    "docs/next_steps.md",
    "docs/performance.md",
    "docs/roadmap/historical/handoffs-through-2026-11-19.md",
    "docs/roadmap/project_improvement_plan.md",
    "docs/plans/2026-11-09-validation-performance-improvement.md",
    "docs/validation_tiers.md",
    "docs/retention_headroom_policy.md",
    "docs/zllvm_artifact_retention_contract.md",
    "docs/evidence/project_improvement/implementation.md",
    "docs/environment.md",
    "docs/install_toolchain.md",
    "docs/compiler_profiling.md",
    "docs/build_steps.md",
    "docs/working-cycle.md",
    "docs/roadmap/convergence_progress.md",
    "test/behavioral/README.md",
};

pub fn main(init: std.process.Init) !void {
    const a = init.gpa;
    const io = init.io;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, a);
    defer args.deinit();
    _ = args.next();
    const option = args.next();
    const write = if (option) |arg| std.mem.eql(u8, arg, "--write") else false;
    if ((option != null and !write) or args.next() != null) return error.UnknownOption;
    const bytes = try read(a, io, "docs/accepted_status.json");
    defer a.free(bytes);
    const parsed = try std.json.parseFromSlice(Status, a, bytes, .{});
    defer parsed.deinit();
    const s = parsed.value;
    if (s.schema != 1 or s.modes.len == 0 or s.lowered > s.candidate_rows or s.objects > s.lowered or s.native_linked > s.objects or s.executed_functions > s.native_linked or s.paired_harnesses_ok > s.executed_functions) return error.InvalidStatus;
    for (s.evidence) |path| try std.Io.Dir.cwd().access(io, path, .{});
    const modes = try std.mem.join(a, ", ", s.modes);
    defer a.free(modes);
    const generated = try std.fmt.allocPrint(a, "{s}\n\nAccepted revision: `{s}`; tree: `{s}`.\n\n" ++
        "Population: compiler-core candidate prefix ({} rows), selector `{s}`.\n" ++
        "Modes: {s}. Source pin: `{s}`.\n" ++
        "Candidate SHA-256: `{s}`.\n\n" ++
        "| Metric | Accepted value per mode | Scope |\n| --- | ---: | --- |\n" ++
        "| Functions lowered | {} | Compiler-core prefix |\n" ++
        "| Objects emitted | {} | Compiler-core prefix |\n" ++
        "| Native links | {} | Compiler-core prefix |\n" ++
        "| Functions executed | {} | Fixed execution cohort |\n" ++
        "| Paired harnesses accepted | {} | Legacy real_programs_ok cohort metric |\n" ++
        "| Local failures | {} | Compiler-core gate |\n\n" ++
        "Compiler-rt bypass ratchet: {} (separate 285-function population).\n\n{s}", .{ begin, s.accepted_revision, s.accepted_tree, s.candidate_rows, s.selector_version, modes, s.source_pin, s.candidate_sha256, s.lowered, s.objects, s.native_linked, s.executed_functions, s.paired_harnesses_ok, s.local_fail, s.compiler_rt_bypass_ratchet, end });
    defer a.free(generated);
    for ([_][]const u8{ "docs/current_state.md", "docs/roadmap/convergence_progress.md" }) |path| {
        const old = try read(a, io, path);
        defer a.free(old);
        const start = std.mem.indexOf(u8, old, begin) orelse return error.MissingStatusMarker;
        const finish = (std.mem.indexOfPos(u8, old, start, end) orelse return error.MissingStatusMarker) + end.len;
        if (write) {
            const updated = try std.mem.concat(a, u8, &.{ old[0..start], generated, old[finish..] });
            defer a.free(updated);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = updated });
        } else if (!std.mem.eql(u8, old[start..finish], generated)) {
            std.debug.print("status disagrees with docs/accepted_status.json: {s}; run zig build check-docs -- --write\n", .{path});
            return error.StatusDrift;
        }
    }
    var links: usize = 0;
    var headings: usize = 0;
    for (docs) |path| {
        const content = try read(a, io, path);
        defer a.free(content);
        var lines = MarkdownLines{ .remaining = content };
        while (lines.next()) |line| {
            var offset: usize = 0;
            while (std.mem.indexOfPos(u8, line, offset, "](")) |start| {
                const close = std.mem.indexOfScalarPos(u8, line, start + 2, ')') orelse return error.MalformedLink;
                offset = close + 1;
                const target = std.mem.trim(u8, line[start + 2 .. close], "<>");
                if (target.len == 0 or std.mem.indexOf(u8, target, "://") != null or std.mem.startsWith(u8, target, "mailto:")) continue;
                var parts = std.mem.splitScalar(u8, target, '#');
                const file = parts.first();
                const joined = if (file.len == 0) try a.dupe(u8, path) else try std.fs.path.resolve(a, &.{ std.fs.path.dirname(path) orelse ".", file });
                defer a.free(joined);
                std.Io.Dir.cwd().access(io, joined, .{}) catch |err| {
                    std.debug.print("broken internal link: {s} -> {s}\n", .{ path, target });
                    return err;
                };
                links += 1;
                const fragment = parts.rest();
                if (fragment.len == 0 or !std.mem.endsWith(u8, joined, ".md")) continue;
                const destination = if (file.len == 0) content else try read(a, io, joined);
                defer if (file.len != 0) a.free(destination);
                if (!try hasHeading(a, destination, fragment)) {
                    std.debug.print("broken heading link: {s} -> {s}\n", .{ path, target });
                    return error.MissingHeading;
                }
                headings += 1;
            }
        }
    }
    std.debug.print("documentation check ok: {} current documents, {} internal links, {} heading links, 2 status blocks\n", .{ docs.len, links, headings });
}

const MarkdownLines = struct {
    remaining: []const u8,
    fence: []const u8 = "",

    fn next(self: *MarkdownLines) ?[]const u8 {
        while (self.remaining.len != 0) {
            const end_of_line = std.mem.indexOfScalar(u8, self.remaining, '\n') orelse self.remaining.len;
            const line = std.mem.trimEnd(u8, self.remaining[0..end_of_line], "\r");
            self.remaining = self.remaining[@min(end_of_line + 1, self.remaining.len)..];
            const trimmed = std.mem.trimStart(u8, line, " ");
            if (line.len - trimmed.len <= 3 and trimmed.len != 0 and (trimmed[0] == '`' or trimmed[0] == '~')) {
                const marker = trimmed[0..1];
                const length = std.mem.findNone(u8, trimmed, marker) orelse trimmed.len;
                const tail = trimmed[length..];
                if (self.fence.len != 0) {
                    if (std.mem.startsWith(u8, trimmed, self.fence) and std.mem.trim(u8, tail, " \t").len == 0) self.fence = "";
                    continue;
                }
                if (length >= 3 and (marker[0] == '~' or std.mem.indexOfScalar(u8, tail, '`') == null)) {
                    self.fence = trimmed[0..length];
                    continue;
                }
            }
            if (self.fence.len == 0) return line;
        }
        return null;
    }
};

// These guides use ATX headings with English titles, inline code and punctuation.
fn hasHeading(allocator: std.mem.Allocator, content: []const u8, fragment: []const u8) !bool {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const wanted = std.Uri.percentDecodeInPlace(try a.dupe(u8, fragment));
    var seen = std.StringHashMap(void).init(a);
    var lines = MarkdownLines{ .remaining = content };
    while (lines.next()) |line| {
        const trimmed = std.mem.trimStart(u8, line, " ");
        if (line.len - trimmed.len > 3) continue;
        const level = std.mem.findNone(u8, trimmed, "#") orelse continue;
        if (level == 0 or level > 6 or !std.ascii.isWhitespace(trimmed[level])) continue;
        const title = std.mem.trim(u8, trimmed[level..], " \t");
        const without_hashes = std.mem.trimEnd(u8, title, "#");
        const text = if (without_hashes.len != 0 and std.ascii.isWhitespace(without_hashes[without_hashes.len - 1]))
            std.mem.trimEnd(u8, without_hashes, " \t")
        else
            title;
        var slug: std.ArrayList(u8) = .empty;
        for (text) |byte| {
            if (std.ascii.isAlphanumeric(byte) or byte == '-' or byte == '_') {
                try slug.append(a, std.ascii.toLower(byte));
            } else if (byte == ' ') {
                try slug.append(a, '-');
            }
        }
        var id: []const u8 = slug.items;
        var suffix: usize = 0;
        while (seen.contains(id)) {
            suffix += 1;
            id = try std.fmt.allocPrint(a, "{s}-{}", .{ slug.items, suffix });
        }
        if (std.mem.eql(u8, id, wanted)) return true;
        try seen.put(id, {});
    }
    return false;
}

test "Markdown anchors handle formatted titles, collisions, and fenced examples" {
    const text =
        \\## Using `z_llvm`?
        \\## Using `z_llvm`?-1
        \\## Using `z_llvm`? ##
        \\   ~~~~md
        \\## Removed heading
        \\~~~
        \\## Still inside
        \\~~~~
    ;
    try std.testing.expect(try hasHeading(std.testing.allocator, text, "using-z%5Fllvm"));
    try std.testing.expect(try hasHeading(std.testing.allocator, text, "using-z_llvm-2"));
    try std.testing.expect(!try hasHeading(std.testing.allocator, text, "removed-heading"));
    try std.testing.expect(!try hasHeading(std.testing.allocator, text, "still-inside"));
}

fn read(a: std.mem.Allocator, io: std.Io, path: []const u8) ![]u8 {
    return std.Io.Dir.cwd().readFileAlloc(io, path, a, .limited(8 * 1024 * 1024));
}
