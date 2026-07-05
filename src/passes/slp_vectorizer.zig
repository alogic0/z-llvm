const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const diagnostic_message = "SLP bundle recognized, but BoUpSLP tree construction, scheduling, TTI profitability, and vector IR rewriting are not implemented";

pub const pass: pass_manager.ModulePass = .{
    .name = "slp-vectorizer",
    .category = .vector,
    .target_status = "recognition-only LLVM-shaped unsupported boundary",
    .upstream_owner = "llvm/lib/Transforms/Vectorize/SLPVectorizer.cpp",
    .run = run,
};

pub const Candidate = struct {
    function_name: []const u8,
    block_name: []const u8,
    first_result: []const u8,
    second_result: []const u8,
    opcode: ir.BinaryOp,
    ty: ir.Type,
    lanes: usize,
};

fn run(module: *ir.Module, context: *pass_manager.Context) !pass_manager.PassResult {
    for (module.functions.items) |function| {
        if (findCandidate(function)) |candidate| {
            context.emitDiagnostic(pass.name, candidate.function_name, candidate.first_result, diagnostic_message);
            return .unchanged;
        }
    }
    return .unchanged;
}

pub fn findCandidate(function: ir.Function) ?Candidate {
    for (function.blocks.items) |block| {
        var first: ?struct {
            result: []const u8,
            binary: ir.BinaryInst,
            lanes: usize,
        } = null;

        for (block.instructions.items) |instruction| {
            if (instruction.removed or instruction.result == null) {
                first = null;
                continue;
            }

            const binary = switch (instruction.kind) {
                .binary => |binary| binary,
                else => {
                    first = null;
                    continue;
                },
            };
            if (!isAcceptedScalarElement(binary.ty)) {
                first = null;
                continue;
            }

            if (first) |*candidate| {
                if (sameBundleShape(candidate.binary, binary)) {
                    candidate.lanes += 1;
                    return .{
                        .function_name = function.name,
                        .block_name = block.name,
                        .first_result = candidate.result,
                        .second_result = instruction.result.?,
                        .opcode = candidate.binary.op,
                        .ty = candidate.binary.ty,
                        .lanes = candidate.lanes,
                    };
                }
            }

            first = .{ .result = instruction.result.?, .binary = binary, .lanes = 1 };
        }
    }
    return null;
}

fn isAcceptedScalarElement(ty: ir.Type) bool {
    return switch (ty) {
        .int, .float, .double => true,
        .void, .half, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => false,
    };
}

fn sameBundleShape(a: ir.BinaryInst, b: ir.BinaryInst) bool {
    return a.op == b.op and
        a.ty.eql(b.ty) and
        binaryFlagsEqual(a.flags, b.flags) and
        fastMathFlagsEqual(a.fp_flags, b.fp_flags);
}

fn binaryFlagsEqual(a: ir.BinaryFlags, b: ir.BinaryFlags) bool {
    return a.nsw == b.nsw and
        a.nuw == b.nuw and
        a.exact == b.exact and
        a.disjoint == b.disjoint;
}

fn fastMathFlagsEqual(a: ir.FastMathFlags, b: ir.FastMathFlags) bool {
    return a.fast == b.fast and
        a.nnan == b.nnan and
        a.ninf == b.ninf and
        a.nsz == b.nsz and
        a.arcp == b.arcp and
        a.contract == b.contract and
        a.afn == b.afn and
        a.reassoc == b.reassoc;
}
