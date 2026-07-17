from pathlib import Path
import hashlib
import os
import re

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction.zig"
OUT = SRC.parent / "value_use"
SOURCE = Path(os.environ.get("INBOX128_R0_SOURCE", SRC))
text = SOURCE.read_text()
expected_r0_sha256 = "825abb19d5a24bfa2fc1ccc1c611a4ffc6c620c1d771ad3a026fa5bc866f52e1"
actual_r0_sha256 = hashlib.sha256(text.encode()).hexdigest()
if actual_r0_sha256 != expected_r0_sha256:
    raise SystemExit(
        f"INBOX-128 frozen R0 source mismatch: {actual_r0_sha256} != {expected_r0_sha256}"
    )
lines = text.splitlines(keepends=True)


def brace_delta(line: str) -> int:
    # The source has no multiline strings spanning declaration braces in the
    # moved regions. Strip line comments and quoted strings for stable counts.
    line = line.split("//", 1)[0]
    line = re.sub(r'"(?:\\.|[^"\\])*"', '""', line)
    return line.count("{") - line.count("}")


def declaration_ranges(indent: int, start: int, end: int):
    result = []
    i = start - 1
    while i < end:
        line = lines[i]
        if re.match(r"^" + (" " * indent) + r"(?:pub )?fn [A-Za-z_]", line):
            begin = i
            depth = 0
            seen = False
            while i < end:
                d = brace_delta(lines[i])
                if "{" in lines[i]:
                    seen = True
                depth += d
                i += 1
                if seen and depth == 0:
                    break
            result.append((begin, i))
        else:
            i += 1
    return result


member_ranges = declaration_ranges(4, 1033, 2424)
top_ranges = declaration_ranges(0, 2425, len(lines))


def fn_name(block: str) -> str:
    match = re.search(r"(?:pub )?fn ([A-Za-z_][A-Za-z0-9_]*)", block)
    assert match
    return match.group(1)


core_members = {
    "begin", "deinit", "register", "attachScratchCompareAction",
    "applySwitchBoundary", "preparedView", "executePreparedAction", "commit",
    "rollback", "requestCount", "phase", "actionDiagnostic", "failedRequestIs",
    "setMemcpyTestFailure", "setLoadTestFailure", "setScratchCompareTestFailure",
    "setCurrentHomeEqZeroTestFailure", "setSetccEaxCompareTestFailure",
    "setCurrentHomeSignBitTestFailure", "setI128EqMinTestFailure",
    "setI128SignBitTestFailure", "requireActive", "rollbackInternal",
    "handleFor", "validateHandle", "recordRequestFailure",
    "noteRequestBoundaryError", "validateActionRegistration",
    "validateRegisteredOperandHandle", "noteRegisteredOperandBoundaryError",
    "validateActionDependenciesCanonical", "validateConsumedActionAfter",
    "validateConsumedOperandAfter", "validateConsumedOperandAfterUnchecked",
    "validateOperandCanonical",
}
planning_members = {
    "seal", "validateRequestAt", "validateRequest",
    "validateSemanticOrderTopology", "actionSecondaryOperand",
    "actionTertiaryOperand", "resetSemanticOrderPlan",
    "planEarlyMaterializations", "appendOrderedOperand", "sortSemanticRoots",
    "semanticRootLessThan", "firstStructuralDestination", "validateEarlyHome",
    "validateEarlyHomeUnchecked",
}
materialization_members = {
    "prepare", "materializeAll", "registeredOperandCurrent",
    "registeredOperandView", "materializeEarlyPlans", "materializeEarlyPlan",
    "materializeRequest", "materializeRequestUnchecked",
    "materializeRequestFromLoc", "resolveNamedCurrent", "buildPreparedRecord",
    "buildPreparedRecordUnchecked",
}
composition_members = {
    "beginAccumulatorSession", "prepareAccumulator",
    "prepareAccumulatorCallBeforeArguments",
    "finishAccumulatorCallPreparationAfterArguments", "materializeAccumulator",
    "spillAccumulatorValue", "defineAccumulatorResult",
    "finalizeAccumulatorResult", "commitAccumulatorSession",
    "validateAccumulatorSession",
}
control_members = {
    "isCurrentHomeSignBitIcmp", "isI128EqMinIcmp", "isI128SignBitIcmp",
}


def member_owner(name: str) -> str:
    for owner, names in (
        ("core", core_members),
        ("planning", planning_members),
        ("materialization", materialization_members),
        ("composition", composition_members),
        ("control_compare", control_members),
    ):
        if name in names:
            return owner
    raise RuntimeError(f"unowned member {name}")


member_blocks = {}
for begin, end in member_ranges:
    block = "".join(lines[begin:end])
    name = fn_name(block)
    member_blocks[name] = (begin + 1, end, block, member_owner(name))

private_member_names = {
    name for name, (_, _, block, _) in member_blocks.items()
    if re.match(r"^    fn ", block)
}


def split_params(signature: str):
    open_pos = signature.index("(")
    depth = 0
    close_pos = None
    for i in range(open_pos, len(signature)):
        ch = signature[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                close_pos = i
                break
    assert close_pos is not None
    body = signature[open_pos + 1:close_pos]
    params = []
    start = 0
    depth = 0
    for i, ch in enumerate(body):
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "," and depth == 0:
            part = body[start:i].strip()
            if part:
                params.append(part)
            start = i + 1
    part = body[start:].strip()
    if part:
        params.append(part)
    names = [p.split(":", 1)[0].strip() for p in params]
    return open_pos, close_pos, names


def signature_of(block: str):
    brace = block.index("{")
    return block[:brace].rstrip()


def make_wrapper(block: str, owner: str):
    sig = signature_of(block)
    sig = re.sub(r"^    ", "", sig, flags=re.M)
    sig = sig.replace("ValueUseTransaction", "Self")
    for model_name, _ in type_names:
        sig = re.sub(rf"\b{model_name}\b", f"Self.{model_name}", sig)
    _, _, names = split_params(sig)
    name = fn_name(sig)
    target = f"Impl.{name}" if owner == "core" else f"Impl.{owner}.{name}"
    if name in {"registeredOperandCurrent", "registeredOperandView"}:
        target = f"Impl.{name}"
    args = list(names)
    if name == "begin":
        args.insert(0, "Self")
    elif "transaction:" in sig:
        args.insert(0, "Impl")
    call = f"{target}({', '.join(args)})"
    return "\n".join("        " + line if line else "" for line in sig.splitlines()) + " {\n" + \
        f"            return {call};\n        }}\n"


def make_impl(block: str, name: str):
    block = re.sub(r"^    (pub )?fn ", "pub fn ", block, count=1)
    block = block.replace("transaction: *const ValueUseTransaction", "transaction: anytype")
    block = block.replace("transaction: *ValueUseTransaction", "transaction: anytype")
    if "transaction: anytype" in signature_of(block):
        block = block.replace(
            "transaction: anytype",
            "comptime Authority: type, transaction: anytype",
            1,
        )
    block = block.replace("ValueUseTransaction.", "Types.")
    if name == "begin":
        block = block.replace(
            "pub fn begin(selector: *ComposedBlockSelector) !ValueUseTransaction",
            "pub fn begin(comptime Transaction: type, selector: *ComposedBlockSelector) !Transaction",
            1,
        )
    return block


type_names = []
for idx in list(range(34, 39)) + list(range(72, 902)) + list(range(1020, 1031)):
    line = lines[idx]
    match = re.match(r"^    (pub )?const ([A-Za-z_][A-Za-z0-9_]*)", line)
    if match:
        type_names.append((match.group(2), bool(match.group(1))))

classifier_ranges = [(443, 465), (529, 547), (547, 564)]
wrapper_excluded = {
    "validateSemanticOrderTopology", "actionSecondaryOperand",
    "actionTertiaryOperand", "resetSemanticOrderPlan",
    "planEarlyMaterializations", "appendOrderedOperand", "sortSemanticRoots",
    "semanticRootLessThan", "firstStructuralDestination",
}


common_imports = """const std = @import("std");
const builtin = @import("builtin");
const ir = @import("../../../../ir.zig");
const x86_64_machine = @import("../../machine.zig");
const x86_64_types = @import("../../types.zig");
const selector_types = @import("../selector_types.zig");
const state_data = @import("../composed_selector_state_data.zig");
const selector_state = @import("../composed_selector_state.zig");
const stage2_planning = @import("../stage2_planning.zig");
const address_dependencies = @import("../composed_selector_address_dependencies.zig");
const eflags = @import("../composed_selector_eflags.zig");
const constant_table = @import("../../constant_table.zig");
const aggregate_object = @import("../aggregate_object.zig");
const composed_helpers = @import("../composed_helpers.zig");
const Diagnostic = @import("../inspection.zig").Diagnostic;

const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const RegPair = selector_types.RegPair;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualReg = selector_types.VirtualReg;
const VirtualRegClass = selector_types.VirtualRegClass;
const ComposedBlockSelector = state_data.ComposedBlockSelector;
const AddressDependencyDomain = address_dependencies.AddressDependencyDomain;
const AccumulatorDefinition = selector_state.AccumulatorDefinition;
const AccumulatorDefinitionSession = selector_state.AccumulatorDefinitionSession;
const AccumulatorDisplacementPolicy = selector_state.AccumulatorDisplacementPolicy;
const AccumulatorPreparationEffect = selector_state.AccumulatorPreparationEffect;
"""


def indent_block(block: str, spaces: int):
    prefix = " " * spaces
    return "".join(prefix + line if line.strip() else line for line in block.splitlines(keepends=True))


# Model: exact semantic declarations plus a generic state/method shell.
def source_without_ranges(start, end, excluded):
    return "".join(
        lines[index - 1]
        for index in range(start, end)
        if not any(first <= index < last for first, last in excluded)
    )


types_source = "".join(lines[34:39]) + source_without_ranges(
    73, 903, classifier_ranges
) + "".join(lines[1020:1031])
types_source = re.sub(r"^    ", "", types_source, flags=re.M)
types_source = re.sub(r"^const ", "pub const ", types_source, flags=re.M)
types_source = types_source.replace(
    "    fn slice(identity: *const ActionIdentity)",
    "    pub fn slice(identity: *const ActionIdentity)",
).replace(
    "    fn validate(identity: *const ActionIdentity)",
    "    pub fn validate(identity: *const ActionIdentity)",
).replace(
    "    fn validate(action: *const SwitchCompareChainAction)",
    "    pub fn validate(action: *const SwitchCompareChainAction)",
).replace(
    "    fn from(input: ir.Value) !Source",
    "    pub fn from(input: ir.Value) !Source",
).replace(
    "    fn eql(source: *const Source, other: *const Source)",
    "    pub fn eql(source: *const Source, other: *const Source)",
)
# These methods remain hidden from the facade because their owning model types
# are imported only by the private leaf graph. Zig's file privacy nevertheless
# requires technical visibility across those leaves.
types_source = re.sub(
    r"^    fn (eql|slice|validate|from|init|asDestination)\(",
    r"    pub fn \1(",
    types_source,
    flags=re.M,
)
physical_node_methods = """

    pub fn fromArgReg(reg: ArgReg) PhysicalNode {
        return switch (reg) {
            .rdi => .rdi,
            .rsi => .rsi,
            .rdx => .rdx,
            .rcx => .rcx,
            .r8 => .r8,
            .r9 => .r9,
        };
    }

    pub fn argReg(node: PhysicalNode) ?ArgReg {
        return switch (node) {
            .rdi => .rdi,
            .rsi => .rsi,
            .rdx => .rdx,
            .rcx => .rcx,
            .r8 => .r8,
            .r9 => .r9,
            .accumulator => null,
        };
    }

    pub fn scalarSource(loc: ValueLoc) ?PhysicalNode {
        return switch (loc) {
            .arg32, .arg64, .scratch32, .scratch64 => |reg| fromArgReg(reg),
            .arg128, .scratch128 => |pair| fromArgReg(pair.lo),
            .eax, .rax => .accumulator,
            .readonly_table_ptr => |ptr| switch (ptr.storage) {
                .reg => |reg| fromArgReg(reg),
                .spill => null,
            },
            else => null,
        };
    }

    pub fn pairSources(loc: ValueLoc) [2]?PhysicalNode {
        return switch (loc) {
            .arg128, .scratch128 => |pair| .{ fromArgReg(pair.lo), fromArgReg(pair.hi) },
            .spill128 => .{ null, null },
            else => .{ null, null },
        };
    }
"""
types_source = re.sub(
    r"(pub const PhysicalNode = enum\(u8\) \{.*?)(\n\};)",
    lambda match: match.group(1) + physical_node_methods + match.group(2),
    types_source,
    count=1,
    flags=re.S,
)
optional_block = next(
    "".join(lines[a:b]) for a, b in top_ranges
    if fn_name("".join(lines[a:b])) == "optionalPreparedActionEql"
)
optional_block = optional_block.replace(
    "fn optionalPreparedActionEql", "fn optionalPreparedActionEql", 1
).replace(
    "?ValueUseTransaction.PreparedAction", "?PreparedAction"
)
fields = "".join(lines[40:71])
fields = fields.replace("snapshot: Snapshot", "snapshot: Impl.Snapshot")
for field_name, _ in type_names:
    fields = re.sub(rf"\b{field_name}\b", f"Self.{field_name}", fields)
aliases = []
for name, is_pub in type_names:
    aliases.append(f"        {'pub ' if is_pub else ''}const {name} = Model.{name};\n")
wrappers = []
for begin, end in member_ranges:
    block = "".join(lines[begin:end])
    name = fn_name(block)
    if name in wrapper_excluded:
        continue
    wrappers.append(make_wrapper(block, member_owner(name)))
wrappers.extend([
    """        pub fn isCurrentHomeSignBitIcmp(icmp: ir.IcmpInst) bool {
            return Impl.control_compare.isCurrentHomeSignBitIcmp(icmp);
        }
""",
    """        pub fn isI128EqMinIcmp(icmp: ir.IcmpInst) bool {
            return Impl.control_compare.isI128EqMinIcmp(icmp);
        }
""",
    """        pub fn isI128SignBitIcmp(icmp: ir.IcmpInst) bool {
            return Impl.control_compare.isI128SignBitIcmp(icmp);
        }
""",
])
model_text = common_imports + "\n" + optional_block + "\n" + types_source + "\nconst Model = @This();\n\n"
model_text += "pub fn Transaction(comptime Impl: type) type {\n    return struct {\n        const Self = @This();\n"
model_text += "".join(aliases)
model_text += "\n" + fields
model_text += "\n" + "\n".join(wrappers)
model_text += "    };\n}\n"


def module_prelude(extra="", action=False):
    imports = common_imports
    model_path = "model.zig"
    if action:
        imports = imports.replace("../../../../ir.zig", "../../../../../ir.zig")
        imports = imports.replace("../../machine.zig", "../../../machine.zig")
        imports = imports.replace("../../types.zig", "../../../types.zig")
        imports = imports.replace("../selector_types.zig", "../../selector_types.zig")
        imports = imports.replace("../composed_selector_", "../../composed_selector_")
        imports = imports.replace("../stage2_planning.zig", "../../stage2_planning.zig")
        imports = imports.replace("../../constant_table.zig", "../../../constant_table.zig")
        imports = imports.replace("../aggregate_object.zig", "../../aggregate_object.zig")
        imports = imports.replace("../composed_helpers.zig", "../../composed_helpers.zig")
        imports = imports.replace("../inspection.zig", "../../inspection.zig")
        model_path = "../model.zig"
    aliases = "".join(f"const {name} = Types.{name};\n" for name, _ in type_names)
    return imports + f'const model = @import("{model_path}");\n' + \
        "const Types = model;\n" + aliases + extra + "\n"


top_blocks = {}
for begin, end in top_ranges:
    block = "".join(lines[begin:end])
    top_blocks[fn_name(block)] = (begin + 1, end, block)


control_names = {
    "classifyScratchCompare", "executeScratchCompare",
    "preserveScratchCompareLiveAccumulator", "refreshScratchCompareOperandViews",
    "stageScratchCompareOperand", "stageScratchCompareOperandUnchecked",
    "failScratchCompareForTest", "executeCurrentHomeEqZero",
    "classifySetccEaxCompare", "executeSetccEaxCompare",
    "validateSetccEaxCompareHome", "failSetccEaxCompareForTest",
    "classifyCurrentHomeSignBit", "executeCurrentHomeSignBit",
    "validateCurrentHomeSignBitHome",
    "preserveCurrentHomeSignBitLiveAccumulator",
    "failCurrentHomeSignBitForTest", "executeI128EqMin", "executeI128SignBit",
    "refreshAndValidateI128PairSource", "validateI128PairHome",
    "failI128EqMinForTest", "failI128SignBitForTest",
    "classifyCurrentHomeEqZero", "failCurrentHomeEqZeroForTest",
    "executeBranchCondition", "executeSwitchCompareChain", "switchConditionMask",
    "restoreSwitchDisplacedPhiDestinations",
}
address_names = {
    "executeScalarLoad", "prepareScalarLoadAccumulator",
    "refreshLoadPreparedOperand", "executeOrdinaryScalarLoad",
    "appendPreparedLoadStackI32", "appendPreparedLoadStackU64IntoRax",
    "preparedScalarHomeLoc", "executeReadOnlyScalarLoad",
    "stageReadOnlyScalarLoadPointer", "materializePreparedLoadPointer",
    "executeReadOnlyPairLoad", "executeStackI128AliasLoad",
    "executeReadOnlyTableI16Load", "failLoadForTest",
    "executeStoreScalar", "executeStoreImmediate", "executeStoreI64",
    "executeStoreStackPointer", "executeStoreEaxToPointer",
    "executeStoreStackI32", "appendStoreEaxStack",
    "materializeActionScalar32", "materializeActionScalar64",
    "materializeActionPointer", "materializeActionScalarHome",
    "clobberActionDestination", "stackScalarFromPreparedView",
    "executeByteAddress", "executeScaledAddress", "executeReadOnlyTableAddress",
    "scaleShift", "scaledOffset",
}
calls_names = {
    "executeInlineMemcpy", "refreshMemcpyPreparedOperand",
    "materializeMemcpyHandle", "materializeMemcpyRequest",
    "materializeMemcpyRequestUnchecked", "failMemcpyForTest",
}
materialization_names = {
    "preparedViewFromLoc", "preparedMemcpyScalarView",
    "preparedScratchCompareView", "preparedConditionView",
    "preparedStackF32PairAddressView", "preparedScalarView",
    "preparedPointerView", "preparedStackObjectView",
    "preparedAddressDescriptor", "requireDependencyRole",
    "preparedAddressComponent", "preparedScalarHome", "preparedPairView",
    "validatePreparedShape", "preparedViewLoc", "preparedRecordEql",
    "preparedViewEql", "preparedStackObjectEql",
    "preparedAddressDescriptorEql", "preparedAddressComponentEql",
    "preparedTablePointerEql", "clobberPhysicalNode", "materializeScalar32",
    "materializeScalar64", "materializeByteAddressPointer",
    "materializePointer", "materializeStackAddress", "materializePair",
    "materializePairLimb", "materializeNull",
}
planning_names = {
    "validateFormAndDestination", "validateDeferredSwitchRequest",
    "earlySequencingCandidate",
    "requestDestinationNodes", "requestMappings", "actionOwnsOrderedWrites",
    "validateStorePointerOperand", "validateStoreI64ValueOperand",
    "validateStoreStackObjectOperand", "validateMemcpyPointerOperand",
    "validateMemcpyLengthOperand", "appendStorePointerDestinationNodes",
    "appendStorePointerMappings", "validateI64StorePointer",
    "validateStackPointerStoreViews", "validateCopyActionForm",
    "rejectCopyCycles", "visitCopyNode", "rejectSemanticOrderCycles",
    "visitSemanticOrderNode", "firstMappingDestination",
    "sourceStructuralOrder",
}
model_shared_names = {
    "validateBindingCompatibility", "validateScratchCompareBinding",
    "validateOrdinaryLoadHome", "validateReadOnlyPointerLoadHome",
    "validateReadOnlyTableLoadHome", "hasLow32View", "validateExpectedType",
    "validateSourceView", "earlyCopyIsFlagsPreserving", "scalarSourceNode",
    "pairSourceNodes", "nodeForArgReg", "argRegForNode",
}
composition_names = {"ownActionIdentity", "ownRegisteredOperandName"}
core_top_names = {"executePreparedActionInternal"}


def transaction_names_for(owner, top_names):
    result = {
        name for name, (_, _, block, actual_owner) in member_blocks.items()
        if actual_owner == owner and "transaction: *ValueUseTransaction" in signature_of(block)
    }
    result.update(
        name for name in top_names
        if "transaction: *ValueUseTransaction" in signature_of(top_blocks[name][2])
    )
    return result

const_blocks = {
    "control_compare": [(2639, 2670), (3143, 3155), (3389, 3394), (3784, 3790)],
    "planning": [(5083, 5118), (6502, 6504)],
}


technical_public = {
    "model": set(),
    "planning": {
        "seal", "validateRequestAt", "validateRequest",
        "validateSemanticOrderTopology", "planEarlyMaterializations",
        "validateEarlyHome", "validateFormAndDestination",
        "validateBindingCompatibility",
        "requestDestinationNodes", "requestMappings", "actionOwnsOrderedWrites",
        "scalarSourceNode", "pairSourceNodes", "nodeForArgReg",
        "argRegForNode",
    },
    "materialization": {
        "prepare", "materializeAll", "materializeEarlyPlans",
        "materializeRequest",
        "resolveNamedCurrent", "buildPreparedRecord",
        "preparedViewFromLoc", "preparedMemcpyScalarView",
        "preparedScratchCompareView", "preparedConditionView",
        "preparedStackF32PairAddressView", "preparedScalarView",
        "preparedPointerView", "preparedStackObjectView", "preparedPairView",
        "validatePreparedShape", "preparedViewLoc", "preparedRecordEql",
        "clobberPhysicalNode", "materializeScalar32", "materializeScalar64",
        "materializeByteAddressPointer", "materializePointer",
        "materializeStackAddress", "materializePair", "materializePairLimb",
        "materializeNull",
    },
    "composition": {
        "beginAccumulatorSession", "prepareAccumulator",
        "prepareAccumulatorCallBeforeArguments",
        "finishAccumulatorCallPreparationAfterArguments",
        "materializeAccumulator", "spillAccumulatorValue",
        "defineAccumulatorResult", "finalizeAccumulatorResult",
        "commitAccumulatorSession", "ownActionIdentity",
        "ownRegisteredOperandName",
    },
    "address_memory": {
        "executeByteAddress", "executeScaledAddress",
        "executeReadOnlyTableAddress", "executeStoreScalar",
        "executeStoreImmediate", "executeStoreI64",
        "executeStoreStackPointer", "executeScalarLoad",
        "executeReadOnlyPairLoad", "executeStackI128AliasLoad",
        "executeReadOnlyTableI16Load",
    },
    "control_compare": {
        "executeScratchCompare", "executeCurrentHomeEqZero",
        "executeSetccEaxCompare", "executeCurrentHomeSignBit",
        "executeI128EqMin", "executeI128SignBit",
        "executeBranchCondition", "executeSwitchCompareChain",
        "classifyScratchCompare", "isCurrentHomeSignBitIcmp",
        "isI128EqMinIcmp", "isI128SignBitIcmp",
    },
    "calls": {"executeInlineMemcpy"},
}


def transformed_top(block: str, owner: str):
    name = fn_name(block)
    if name in technical_public.get(owner, set()):
        block = re.sub(r"^fn ", "pub fn ", block, count=1)
    block = block.replace("transaction: *const ValueUseTransaction", "transaction: anytype")
    block = block.replace("transaction: *ValueUseTransaction", "transaction: anytype")
    if "transaction: anytype" in signature_of(block):
        block = block.replace(
            "transaction: anytype",
            "comptime Authority: type, transaction: anytype",
            1,
        )
    block = block.replace("ValueUseTransaction.", "Types.")
    return block


def blocks_for(owner, names):
    selected = sorted((top_blocks[name] for name in names), key=lambda item: item[0])
    return "".join(transformed_top(block, owner) for _, _, block in selected)


def member_impls(owner):
    selected = sorted(
        ((line, name, block) for name, (line, _, block, actual) in member_blocks.items() if actual == owner),
        key=lambda item: item[0],
    )
    result = ""
    for _, name, block in selected:
        implementation = make_impl(block, name)
        if name not in technical_public.get(owner, set()):
            implementation = re.sub(r"^pub fn ", "fn ", implementation, count=1)
        result += implementation
    return result


def direct_local_member_calls(source, names):
    for name in names:
        source = re.sub(
            rf"transaction\.{name}\(",
            f"{name}(transaction, ",
            source,
        )
        source = source.replace(f"{name}(transaction, )", f"{name}(transaction)")
    return source


def private_authority_calls(source):
    for name in private_member_names:
        owner = member_owner(name)
        target = f"Authority.{name}" if owner == "core" else f"Authority.{owner}.{name}"
        source = re.sub(
            rf"transaction\.{name}\(",
            f"{target}(Authority, transaction, ",
            source,
        )
        source = source.replace(
            f"{target}(Authority, transaction, )",
            f"{target}(Authority, transaction)",
        )
    return source


def authority_function_names(blocks):
    result = set()
    for name, (_, _, block) in blocks.items():
        if "transaction: *ValueUseTransaction" in signature_of(block):
            result.add(name)
    return result


def add_local_authority_calls(source, names):
    for name in names:
        source = re.sub(
            rf"(?<!fn )(?<![.\w]){name}\(",
            f"{name}(Authority, ",
            source,
        )
        source = source.replace(f"{name}(Authority, )", f"{name}(Authority)")
    return source


def add_qualified_authority_calls(source, qualifier, names):
    for name in names:
        source = source.replace(
            f"{qualifier}.{name}(",
            f"{qualifier}.{name}(Authority, ",
        )
        source = source.replace(
            f"{qualifier}.{name}(Authority, )",
            f"{qualifier}.{name}(Authority)",
        )
    return source


def suppress_unused_authority(source):
    source_lines = source.splitlines(keepends=True)
    ranges = []
    i = 0
    while i < len(source_lines):
        if re.match(r"^(?:pub )?fn [A-Za-z_]", source_lines[i]):
            start = i
            depth = 0
            seen = False
            while i < len(source_lines):
                if "{" in source_lines[i]:
                    seen = True
                depth += brace_delta(source_lines[i])
                i += 1
                if seen and depth == 0:
                    break
            ranges.append((start, i))
        else:
            i += 1
    for start, end in ranges:
        block = "".join(source_lines[start:end])
        if "comptime Authority: type" not in signature_of(block):
            continue
        body = block[block.index("{") + 1:]
        if "Authority" not in body:
            block = block.replace("comptime Authority: type", "comptime _: type", 1)
            source_lines[start:end] = block.splitlines(keepends=True)
    return "".join(source_lines)


def raw_consts(owner):
    return "".join("".join(lines[a - 1:b - 1]) for a, b in const_blocks.get(owner, [])).replace(
        "ValueUseTransaction.", "Types."
    )


# Cross-owner call qualification.
def qualify_control(s):
    for name in (
        "preparedViewLoc", "clobberPhysicalNode", "materializeScalar32",
        "materializeScalar64",
    ):
        s = re.sub(rf"(?<![.\w]){name}\(", f"materialization.{name}(", s)
    s = re.sub(r"(?<![.\w])ownActionIdentity\(", "composition.ownActionIdentity(", s)
    s = re.sub(r"(?<![.\w])nodeForArgReg\(", "Authority.planning.nodeForArgReg(", s)
    return s


def qualify_address(s):
    for name in (
        "preparedViewLoc", "materializeScalar32", "materializeScalar64",
        "materializeByteAddressPointer", "materializePointer",
        "clobberPhysicalNode",
    ):
        s = re.sub(rf"(?<![.\w]){name}\(", f"materialization.{name}(", s)
    s = re.sub(r"(?<![.\w])ownActionIdentity\(", "composition.ownActionIdentity(", s)
    s = re.sub(r"(?<![.\w])ownRegisteredOperandName\(", "composition.ownRegisteredOperandName(", s)
    for name in ("nodeForArgReg", "scalarSourceNode"):
        s = re.sub(rf"(?<![.\w]){name}\(", f"Authority.planning.{name}(", s)
    return s


def qualify_planning(s):
    s = re.sub(r"(?<![.\w])classifyScratchCompare\(", "control_compare.classifyScratchCompare(", s)
    return s


def qualify_core(s):
    replacements = {
        "preparedRecordEql": "materialization.preparedRecordEql",
        "actionOwnsOrderedWrites": "planning.actionOwnsOrderedWrites",
        "validatePreparedShape": "materialization.validatePreparedShape",
        "executeByteAddress": "address_memory.executeByteAddress",
        "executeScaledAddress": "address_memory.executeScaledAddress",
        "executeReadOnlyTableAddress": "address_memory.executeReadOnlyTableAddress",
        "executeStoreScalar": "address_memory.executeStoreScalar",
        "executeStoreImmediate": "address_memory.executeStoreImmediate",
        "executeStoreI64": "address_memory.executeStoreI64",
        "executeStoreStackPointer": "address_memory.executeStoreStackPointer",
        "executeScalarLoad": "address_memory.executeScalarLoad",
        "executeReadOnlyPairLoad": "address_memory.executeReadOnlyPairLoad",
        "executeStackI128AliasLoad": "address_memory.executeStackI128AliasLoad",
        "executeReadOnlyTableI16Load": "address_memory.executeReadOnlyTableI16Load",
        "executeScratchCompare": "control_compare.executeScratchCompare",
        "executeCurrentHomeEqZero": "control_compare.executeCurrentHomeEqZero",
        "executeSetccEaxCompare": "control_compare.executeSetccEaxCompare",
        "executeCurrentHomeSignBit": "control_compare.executeCurrentHomeSignBit",
        "executeI128EqMin": "control_compare.executeI128EqMin",
        "executeI128SignBit": "control_compare.executeI128SignBit",
        "executeBranchCondition": "control_compare.executeBranchCondition",
        "executeSwitchCompareChain": "control_compare.executeSwitchCompareChain",
        "executeInlineMemcpy": "calls.executeInlineMemcpy",
        "optionalPreparedActionEql": "model.optionalPreparedActionEql",
        "classifyScratchCompare": "control_compare.classifyScratchCompare",
        "restoreSwitchDisplacedPhiDestinations": "control_compare.restoreSwitchDisplacedPhiDestinations",
        "scaleShift": "address_memory.scaleShift",
        "preparedViewLoc": "materialization.preparedViewLoc",
        "materializeScalar32": "materialization.materializeScalar32",
        "validateStorePointerOperand": "planning.validateStorePointerOperand",
        "validateStoreI64ValueOperand": "planning.validateStoreI64ValueOperand",
        "validateStoreStackObjectOperand": "planning.validateStoreStackObjectOperand",
        "validateMemcpyPointerOperand": "planning.validateMemcpyPointerOperand",
        "validateMemcpyLengthOperand": "planning.validateMemcpyLengthOperand",
        "materializeScalar64": "materialization.materializeScalar64",
        "materializePointer": "materialization.materializePointer",
    }
    for old, new in replacements.items():
        s = re.sub(rf"(?<![.\w]){old}\(", f"{new}(", s)
    return s


snapshot_source = "".join(lines[902:1020])
snapshot_source = re.sub(r"^    ", "", snapshot_source, flags=re.M)
snapshot_source = snapshot_source.replace("const Snapshot = struct", "const CoreSnapshot = struct")
snapshot_source = snapshot_source.replace("!Snapshot", "!CoreSnapshot")
snapshot_source = snapshot_source.replace("*const Snapshot", "*const CoreSnapshot")
snapshot_source = snapshot_source.replace("*Snapshot", "*CoreSnapshot")

core_prelude = module_prelude(
    'const planning_module = @import("planning.zig");\n'
    'const materialization_module = @import("materialization.zig");\n'
    'const composition_module = @import("composition.zig");\n'
    'const address_memory = @import("actions/address_memory.zig");\n'
    'const control_compare_module = @import("actions/control_compare.zig");\n'
    'const calls = @import("actions/calls.zig");\n'
)
core_helper_member_names = {
    "actionSecondaryOperand", "actionTertiaryOperand", "resetSemanticOrderPlan",
    "registeredOperandCurrent", "registeredOperandView",
}
core_helper_top_names = {
    "validateStorePointerOperand", "validateStoreI64ValueOperand",
    "validateStoreStackObjectOperand", "validateMemcpyPointerOperand",
    "validateMemcpyLengthOperand", "scaleShift",
    "restoreSwitchDisplacedPhiDestinations",
}
core_helper_bodies = ""
for helper_name in core_helper_member_names:
    helper = make_impl(member_blocks[helper_name][2], helper_name)
    helper = re.sub(r"^pub fn ", "fn ", helper, count=1)
    if helper_name in {"registeredOperandCurrent", "registeredOperandView"}:
        helper = helper.replace(
            f"fn {helper_name}(", f"fn core_{helper_name}(", 1
        )
    core_helper_bodies += helper
core_helper_bodies += blocks_for("core", core_helper_top_names)
core_optional = optional_block.replace(
    "fn optionalPreparedActionEql", "fn coreOptionalPreparedActionEql", 1
)
core_bodies = (
    member_impls("core") + blocks_for("core", core_top_names) +
    core_helper_bodies + core_optional
)
core_bodies = qualify_core(core_bodies)
core_bodies = add_local_authority_calls(
    core_bodies,
    transaction_names_for("core", core_top_names),
)
for qualifier, names in (
    ("address_memory", transaction_names_for("unused", address_names)),
    ("control_compare", transaction_names_for("control_compare", control_names)),
    ("calls", transaction_names_for("unused", calls_names)),
):
    core_bodies = add_qualified_authority_calls(core_bodies, qualifier, names)
core_bodies = private_authority_calls(core_bodies)
core_bodies = core_bodies.replace("planning.", "planning_module.")
core_bodies = core_bodies.replace("materialization.", "materialization_module.")
core_bodies = core_bodies.replace("composition.", "composition_module.")
core_bodies = core_bodies.replace("control_compare.", "control_compare_module.")
core_bodies = core_bodies.replace("Authority.planning_module.", "Authority.planning.")
core_bodies = core_bodies.replace("Authority.materialization_module.", "Authority.materialization.")
core_bodies = core_bodies.replace("Authority.composition_module.", "Authority.composition.")
core_bodies = core_bodies.replace("Authority.control_compare_module.", "Authority.control_compare.")
core_bodies = core_bodies.replace(
    "Authority.planning.resetSemanticOrderPlan", "resetSemanticOrderPlan"
).replace(
    "Authority.planning.actionSecondaryOperand", "actionSecondaryOperand"
).replace(
    "Authority.planning.actionTertiaryOperand", "actionTertiaryOperand"
).replace(
    "planning_module.validateStorePointerOperand", "validateStorePointerOperand"
).replace(
    "planning_module.validateStoreI64ValueOperand", "validateStoreI64ValueOperand"
).replace(
    "planning_module.validateStoreStackObjectOperand", "validateStoreStackObjectOperand"
).replace(
    "planning_module.validateMemcpyPointerOperand", "validateMemcpyPointerOperand"
).replace(
    "planning_module.validateMemcpyLengthOperand", "validateMemcpyLengthOperand"
).replace(
    "address_memory.scaleShift", "scaleShift"
).replace(
    "control_compare_module.restoreSwitchDisplacedPhiDestinations",
    "restoreSwitchDisplacedPhiDestinations",
).replace(
    "model.optionalPreparedActionEql", "coreOptionalPreparedActionEql"
)
core_bodies = core_bodies.replace("Snapshot.init(", "CoreSnapshot.init(")
implementation = """const Implementation = struct {
    pub const Snapshot = CoreSnapshot;
    pub const planning = planning_module;
    pub const materialization = materialization_module;
    pub const composition = composition_module;
    pub const control_compare = control_compare_module;
"""
implementation += "    pub const registeredOperandCurrent = core_registeredOperandCurrent;\n"
implementation += "    pub const registeredOperandView = core_registeredOperandView;\n"
implementation += "    pub const validateRequest = planning_module.validateRequest;\n"
implementation += "    pub const validateRequestAt = planning_module.validateRequestAt;\n"
implementation += "    pub const validateEarlyHome = planning_module.validateEarlyHome;\n"
for name, (line, _, block, owner) in sorted(member_blocks.items(), key=lambda item: item[1][0]):
    if owner != "core":
        continue
    implementation += f"    pub const {name} = core_{name};\n"
implementation += "};\n\n"
for name in core_members:
    core_bodies = re.sub(rf"(?:pub )?fn {name}\(", f"fn core_{name}(", core_bodies, count=1)
core_text = core_prelude + snapshot_source + "\n" + core_bodies + "\n" + implementation
core_text += "pub const ValueUseTransaction = model.Transaction(Implementation);\n"

planning_text = module_prelude('const control_compare = @import("actions/control_compare.zig");\n')
planning_text += (
    raw_consts("planning") + member_impls("planning") +
    blocks_for("planning", planning_names) +
    blocks_for("planning", model_shared_names)
)
planning_text = qualify_planning(planning_text)
planning_forwarders = {
    "scalarSourceNode": """pub fn scalarSourceNode(loc: ValueLoc) ?Types.PhysicalNode {
    return Types.PhysicalNode.scalarSource(loc);
}
""",
    "pairSourceNodes": """pub fn pairSourceNodes(loc: ValueLoc) [2]?Types.PhysicalNode {
    return Types.PhysicalNode.pairSources(loc);
}
""",
    "nodeForArgReg": """pub fn nodeForArgReg(reg: ArgReg) Types.PhysicalNode {
    return Types.PhysicalNode.fromArgReg(reg);
}
""",
    "argRegForNode": """pub fn argRegForNode(node: Types.PhysicalNode) ?ArgReg {
    return node.argReg();
}
""",
}
for helper_name, forwarder in planning_forwarders.items():
    original = transformed_top(top_blocks[helper_name][2], "planning")
    planning_text = planning_text.replace(original, forwarder)
planning_text = add_local_authority_calls(
    planning_text,
    transaction_names_for("planning", planning_names),
)
planning_text = private_authority_calls(planning_text)
planning_text = planning_text.replace("Authority.planning.", "")

materialization_text = module_prelude()
materialization_text += member_impls("materialization") + blocks_for("materialization", materialization_names)
materialization_private_helpers = {
    "validateExpectedType", "validateSourceView", "earlyCopyIsFlagsPreserving",
    "validateBindingCompatibility", "validateScratchCompareBinding",
    "validateOrdinaryLoadHome", "validateReadOnlyPointerLoadHome",
    "validateReadOnlyTableLoadHome", "hasLow32View",
}
materialization_text += blocks_for("materialization", materialization_private_helpers)
materialization_text = re.sub(
    r"(?<![.\w])nodeForArgReg\(",
    "Types.PhysicalNode.fromArgReg(",
    materialization_text,
).replace(
    "argRegForNode(node)", "node.argReg()"
)
materialization_text = materialization_text.replace(
    "model.validateBindingCompatibility(", "validateBindingCompatibility("
).replace(
    "model.validateExpectedType(", "validateExpectedType("
).replace(
    "model.validateSourceView(", "validateSourceView("
).replace(
    "model.earlyCopyIsFlagsPreserving(", "earlyCopyIsFlagsPreserving("
).replace(
    "model.nodeForArgReg(", "Authority.planning.nodeForArgReg("
).replace(
    "model.argRegForNode(", "Authority.planning.argRegForNode("
)
materialization_text = add_local_authority_calls(
    materialization_text,
    transaction_names_for("materialization", materialization_names),
)
materialization_text = private_authority_calls(materialization_text)
materialization_text = materialization_text.replace("Authority.materialization.", "")

composition_text = module_prelude()
composition_text += member_impls("composition") + blocks_for("composition", composition_names)
composition_text = add_local_authority_calls(
    composition_text,
    transaction_names_for("composition", composition_names),
)
composition_text = private_authority_calls(composition_text)
composition_text = composition_text.replace("Authority.composition.", "")

control_text = module_prelude(
    'const materialization = @import("../materialization.zig");\n'
    'const composition = @import("../composition.zig");\n'
, action=True)
control_text += raw_consts("control_compare")
classifier_blocks = ""
for start, end in classifier_ranges:
    block = "".join(lines[start - 1:end - 1])
    classifier_blocks += re.sub(r"^    ", "", block, flags=re.M)
control_text += classifier_blocks + blocks_for("control_compare", control_names)
control_text = qualify_control(control_text)
control_text = add_local_authority_calls(
    control_text,
    transaction_names_for("control_compare", control_names),
)
control_text = add_qualified_authority_calls(
    control_text,
    "composition",
    transaction_names_for("composition", composition_names),
)
control_text = private_authority_calls(control_text)
control_text = control_text.replace(
    "Authority.materialization.registeredOperandView",
    "Authority.registeredOperandView",
).replace(
    "Authority.planning.nodeForArgReg", "Types.PhysicalNode.fromArgReg",
)

address_text = module_prelude(
    'const materialization = @import("../materialization.zig");\n'
    'const composition = @import("../composition.zig");\n'
, action=True)
address_text += blocks_for("address_memory", address_names)
address_text = qualify_address(address_text)
address_text = add_local_authority_calls(
    address_text,
    transaction_names_for("unused", address_names),
)
address_text = add_qualified_authority_calls(
    address_text,
    "composition",
    transaction_names_for("composition", composition_names),
)
address_text = private_authority_calls(address_text)
address_text = address_text.replace(
    "Authority.materialization.registeredOperandView",
    "Authority.registeredOperandView",
).replace(
    "Authority.planning.nodeForArgReg", "Types.PhysicalNode.fromArgReg",
).replace(
    "Authority.planning.scalarSourceNode", "Types.PhysicalNode.scalarSource",
)

calls_text = module_prelude(
    'const materialization = @import("../materialization.zig");\n',
    action=True,
)
calls_text += blocks_for("calls", calls_names)
calls_text = re.sub(
    r"(?<![.\w])materializeScalar64\(",
    "materialization.materializeScalar64(",
    calls_text,
)
calls_text = add_local_authority_calls(
    calls_text,
    transaction_names_for("unused", calls_names),
)
calls_text = private_authority_calls(calls_text)

planning_text = planning_text.replace(
    "Authority.materialization.registeredOperandCurrent",
    "Authority.registeredOperandCurrent",
)
for operation in ("validateRequest", "validateRequestAt", "validateEarlyHome"):
    materialization_text = materialization_text.replace(
        f"Authority.planning.{operation}", f"Authority.{operation}"
    )
for action_text_name in ("address_text", "calls_text"):
    current_text = locals()[action_text_name]
    for operation in ("validateRequest", "validateRequestAt"):
        current_text = current_text.replace(
            f"Authority.planning.{operation}", f"Authority.{operation}"
        )
    if action_text_name == "address_text":
        address_text = current_text
    else:
        calls_text = current_text

core_text = suppress_unused_authority(core_text)
planning_text = suppress_unused_authority(planning_text)
materialization_text = suppress_unused_authority(materialization_text)
composition_text = suppress_unused_authority(composition_text)
address_text = suppress_unused_authority(address_text)
control_text = suppress_unused_authority(control_text)
calls_text = suppress_unused_authority(calls_text)

OUT.mkdir(parents=True, exist_ok=True)
(OUT / "actions").mkdir(parents=True, exist_ok=True)
(OUT / "model.zig").write_text(model_text)
(OUT / "core.zig").write_text(core_text)
(OUT / "planning.zig").write_text(planning_text)
(OUT / "materialization.zig").write_text(materialization_text)
(OUT / "composition.zig").write_text(composition_text)
(OUT / "actions/address_memory.zig").write_text(address_text)
(OUT / "actions/control_compare.zig").write_text(control_text)
(OUT / "actions/calls.zig").write_text(calls_text)
SRC.write_text(
    'const core = @import("value_use/core.zig");\n\n'
    'pub const ValueUseTransaction = core.ValueUseTransaction;\n'
)

owner_paths = {
    "core": "src/codegen/x86_64/generic_cfg/value_use/core.zig",
    "planning": "src/codegen/x86_64/generic_cfg/value_use/planning.zig",
    "materialization": "src/codegen/x86_64/generic_cfg/value_use/materialization.zig",
    "composition": "src/codegen/x86_64/generic_cfg/value_use/composition.zig",
    "address_memory": "src/codegen/x86_64/generic_cfg/value_use/actions/address_memory.zig",
    "control_compare": "src/codegen/x86_64/generic_cfg/value_use/actions/control_compare.zig",
    "calls": "src/codegen/x86_64/generic_cfg/value_use/actions/calls.zig",
    "model": "src/codegen/x86_64/generic_cfg/value_use/model.zig",
}
manifest_rows = [
    "r0_line\tkind\tsymbol\tr1_owner\ttransformation\tr0_block_sha256"
]
for name, (line, _, block, owner) in sorted(member_blocks.items(), key=lambda item: item[1][0]):
    manifest_rows.append(
        f"{line + 1}\tmethod\t{name}\t{owner_paths[owner]}\t"
        f"generic-direct-wrapper+receiver-rewrite\t{hashlib.sha256(block.encode()).hexdigest()}"
    )
for name, (start, _, block) in sorted(top_blocks.items(), key=lambda item: item[1][0]):
    owner = next((
        candidate for candidate, names in (
            ("core", core_top_names),
            ("planning", planning_names),
            ("materialization", materialization_names),
            ("composition", composition_names),
            ("address_memory", address_names),
            ("control_compare", control_names),
            ("calls", calls_names),
            ("planning", model_shared_names),
        ) if name in names
    ), "model")
    manifest_rows.append(
        f"{start + 1}\tfunction\t{name}\t{owner_paths[owner]}\t"
        f"mechanical-move+internal-context-receiver\t{hashlib.sha256(block.encode()).hexdigest()}"
    )
for name, _ in type_names:
    line = next(
        index + 1 for index, source_line in enumerate(lines)
        if re.match(rf"^    (?:pub )?const {re.escape(name)}\b", source_line)
    )
    manifest_rows.append(
        f"{line}\tmodel\t{name}\t{owner_paths['model']}\t"
        "mechanical-move+facade-alias\t-"
    )
Path("docs/evidence/inbox128_o2_r1_symbol_provenance.tsv").write_text(
    "\n".join(manifest_rows) + "\n"
)
