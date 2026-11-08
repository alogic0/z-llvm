# Census classification and narrow integer ABI facts

Status: accepted at `baf7a767`; all 17 cumulative gates pass.
Plan: [census classification and shared integer ABI repair](../plans/2026-11-07-census-integer-abi.md).
Raw evidence: `local-state/validations/census-integer-abi-20261107/`.
Baseline: accepted implementation `5ad6c51c`, working base `22fc1347`.
Implementation commits: `4e7de9c5` (diagnostics and handoff), `baf7a767` (ABI repair).
Machine-readable [acceptance record](census_integer_abi_acceptance_20261107.json).

## Classification at the final rejection

`src/selection_census.zig` parses and verifies the complete original module,
preserves declarations, globals, named types and layout, then invokes the
production selector for every definition. Optional observers copy the failing
call or parameter before the private legalized function is released. Records
include the instruction position, function and call types/attributes, calling
conventions, argument values, defining operation and resolved location tags.
They describe the rejected call's arguments; they do not identify an individual
failing argument within that list. Unobserved rejection kinds remain null.

Attempt resets discard earlier retries. A retained observation is published only
when its diagnostic tag and detail match the final selector result. Successful
selection publishes no rejected-attempt context. The state authority supplies
location tags without exposing operands to consumer lowering. Its structural
allowances remain unchanged; only the reviewed `bindParams` body fingerprint
changes for the observation callback, with the same seven binding operations.

The instrumented baseline reproduces all 3,524 successful compiler identities,
all 5,404 failure tuples, all 274 runtime successes and all 181 runtime failure
tuples exactly. `classification-sources.sha256`, `classification-binary.sha256`,
`classification-instrumentation.patch`, `classifier-baseline-source.zig` and
`rejection-observer-baseline.zig` retain its source/binary binding against
`22fc1347`. The later authority refactor does not increase the bypass inventory.

The baseline's largest groups are classified after optional legalization:

| First rejection | Functions | Observed forms |
| --- | ---: | --- |
| Call argument width | 1,086 | 1,067 occur inside functions with annotated narrow returns, which disabled the entire ABI legalizer; outgoing i6 constants dominate |
| LLVM intrinsic | 785 | 602 `llvm.uadd.sat.i64`, 52 `llvm.ctpop.i32`, 44 `llvm.fshl.i64`; remaining names and widths retained |
| Call return width | 771 | 412 i16, 355 i5, three i3 and one i2 |
| Memcpy source | 751 | 750 constant pointer expressions without a resolved location; one alloca with `stack_scalar` location |
| Parameter extension | 314 | 18 i1, 23 i2, 79 i3, 17 i5, 11 i7 and 166 i8 |

These table groups use the complete diagnostic/tag/detail tuple, including
`UnsupportedCodegenControlFlow`. Other outer diagnostics can carry the same
selector detail and remain separate in the retained classification. Every
function in these five groups has a matching final observation. These are first
rejections, not estimates of how many functions one repair will complete.

## Shared repair and executable contract

The narrow ABI legalizer now accepts validated advisory `noundef` and integer
range facts on function returns, parameters and call returns. It uses the shared
attribute validator; it does not accept arbitrary attributes. A fact on a narrow
function return no longer disables unrelated parameter and call legalization.
Supported narrow call arguments use the same contract.

The original IR retains its types and facts. The private selector view widens
1–31-bit values to 32-bit register/stack carriers and omits validated advisory
facts from those wider carriers. A fact about an i8 payload cannot constrain the
unspecified upper bits of a raw i32 return. Receive masks precede truncation and
publishing the logical value; outgoing values preserve the original low bits.
Sign/zero-extension attributes, unsupported calling conventions, musttail,
variadic forms and other unsupported ABI contracts retain explicit boundaries.
Temporary names use the existing collision index instead of rescanning the
whole function for every new carrier.

The permanent `narrow_abi_facts` population has five functions. Across Fast,
Safe and Small, each of two local routes compares 1,280 observations against an
LLVM reference. It covers dirty incoming/returned padding, wrapped range facts,
mixed widths, nine incoming and eight outgoing arguments, live values across
volatile-register clobbers, PHIs, boolean branches, exact memory writes and an
unused call result whose side effect must survive. Both final Debug and
ReleaseFast compiler builds pass: 7,680 local and 3,840 reference observations
per build. The baseline rejects the valid fixture.

Unit tests cover all logical widths 1–31, source immutability, legalization
idempotence, dirty padding and unsupported/malformed attribute rejection.
Observer tests check private-context lifetime, stale-attempt reset, rollback and
identical selected machine bytes with observation enabled or disabled.

## Complete-input replay

The final production replay completes all 8,928 compiler definitions: 4,341
select and 4,587 reject. All 3,524 baseline successes remain, with 817 additional
successful identities. Of these, 521 previously stopped on call-return width,
137 on call-argument width and 123 on parameter extension under the table's
outer diagnostic; the other 36 successes and every failure transition are
retained explicitly. Runtime selection remains 274 of 455, preserving every
baseline success.

The new largest first-failure groups are 1,772 memcpy sources, 976 intrinsics,
368 global GEP properties and 184 register-pressure rejections. In particular,
870 previous call-argument failures now reach memcpy source handling. The
post-repair observation identifies 1,771 constant `getelementptr` sources and
one stack allocation in that memcpy group. Of the intrinsic group, 757 first
reject `llvm.uadd.sat.i64`. Constant-pointer source handling through shared
address/dependency contracts is the recommended next slice, followed by the
concrete intrinsic forms. Every new repair still needs complete replay: removing
a first rejection can expose another boundary.

The saturating-add group is also concrete: all 757 rejected `llvm.uadd.sat.i64`
calls carry advisory facts, with return facts on 755 and argument facts on 185
(overlapping groups). `integer_intrinsics.operation` already recognizes the
operation but rejects any return or argument attributes. Its expansion changes
the helper's return to an overflow aggregate, so future support must validate
the facts and avoid attaching scalar range facts to that aggregate. This is a
shared intrinsic-contract repair lead, not evidence that all 757 functions will
select afterward. Raw details are in `saturating-add-classification.json`.

The remaining 22 call-argument-width rejections contain one nonstandard wide
integer each: four i33, twelve i37, four i49 and two i63. They fall outside this
slice's 1–31-bit carrier contract; these are recorded separately from the
completed narrow-width repair.

The final ReleaseFast production compiler matches the development classifier's
selected identities and every failure tuple for both inputs. The comparator
maps the CLI's absent-tag/detail marker `-` to the classifier's JSON null;
all named diagnostics are compared unchanged. Source and backend identities
verify before and after each replay. Neither replay publishes a complete object.
Compiler startup and self-rebuild remain unaccepted.

The compiler replay takes 791.94 seconds with 6,365,528 KB maximum RSS. The full
compiler and runtime streams contain 3,568,532 and 70,370 events, respectively.
Audits verify every sequence number, elapsed-time ordering, unique function
identity, balanced activity/legalizer/retry records and final counters. These
timings include profiling and concurrent validation; they are not throughput
comparisons. Dependency coverage remains conservative.

Debug and ReleaseSafe each pass 1,949 unit tests and 21 structural checks.
The two profiling-process tests, five whole-compiler reporting tests and the
readiness suite pass. The cumulative run passes all 17 gates in 3,566.71 seconds.
All 50 native populations pass: 1,810,884 local observations against 905,442
references. Every prior population retains its observation counts and fixture
sources; the only additions are the new ABI fixture, driver and registry entry.

Core counts remain 100 lowered/emitted/linked and 12 executed per mode, with
bypass ratchet 130 unchanged. All 36 records preserve selected-object bytes,
observations and linked executable sizes. Independent reference wrappers grow
by eight bytes in 24 records; reference and linked hashes differ between builds.
These fields are compared separately, without claiming complete
executable byte identity.

The five fixed Zig programs pass all 15 program/mode pairs with unchanged source,
manifest and emitter identities. The unchanged Zig input corpus passes 87 pairs
and 603 observation controls, preserving the independent expected observations
and prior selection counters. The C input corpus passes 138 pairs and 552
controls with unchanged source/manifest identities and observations. Execution
breadth controls preserve all 21 function/mode pairs, 22,788 observations and
54 deliberate fault detections. The behavioral suite retains 6,528 observations.

Only `full-acceptance.log` supplies cumulative acceptance. The initial
`full-setup` attempt stopped before any gate because the new validation directory
did not exist. Creating that directory resolved setup without source changes.

## Retention

Postchecks verify all 1,741 frozen compiler/tool/test/build inputs, both compiler
identities, original compiler/runtime inputs, prior accepted artifacts and all
thirteen scratch files. No archives were created. Disk admission remains
32,949,672,960 bytes and execution reserve remains 24,359,738,368 bytes. The
cumulative gate's minimum observed free space is 38,694,051,840 bytes, and its
final sample is 41,339,289,600 bytes.
