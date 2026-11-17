# Constant-table layout, fallback and linkage repairs

Status: accepted after validation, identity checks and storage closure under
`local-state/validations/table-contract-fixes-20261116/batch-01`.
The user's three review findings authorize this bounded repair independently of
the completed generalization plan and older unrelated worker-inbox directions.

The clean `d60cfa46` baseline reproduces all three findings: the locally admitted
`i8:32` layout returns the wrong element, an ordinary parameter index rejects
with exit 2, and two independently emitted default objects fail to link because
their private/internal table definitions have global binding. The baseline
compiler is `673948d7f881c40410dfe133b30ccf2c9001b1302ee4434c8a769da630f9b518`.

Source-stride admission now checks the module's allocation layout, and decoding
checks element and complete serialized extents. Explicit incompatible integer,
floating and pair-aggregate alignment overrides decline table specialization.
Pointer materialization reserves a table GEP only when its source stride and
the same index proof used by lowering apply. Unproved parameter indexes,
literals, typed element GEPs, other strides and array-element GEPs retain the
ordinary addressing route. The duplicate mask walker has been removed in favor
of the shared bounded index proof.

Recognized tables, including unused ones, now use ordinary global placement.
The ELF reachability walk also follows `lea_global_arg64`. The separate table
serializer that forced global binding is removed; ordinary placement owns
private/internal linkage, visibility, section and alignment. ELF tests inspect
binding, object type, local-symbol partition, visibility and 64-byte alignment
with both default and whole-module emission.

The maintained native registry adds `table_contracts` and `table_private_link`.
The latter compiles two independent default objects with identical private and
internal names, then executes both through one driver. Its provider explicitly
sets `provider_codegen_reachable: false`; the earlier reachable-provider default
would have bypassed the reported default-emission bug. Both modes remain
supported by the existing native runner. The registry now has 235 populations.

LLVM 22 rejects the reported `i8:32` layout with `i8 must be 8-bit aligned`.
The initial setup attempt incorrectly expected an LLVM stride fold and stopped
before running the backend. Its failed receipt and diagnostic remain unchanged.
The successor records LLVM's rejection explicitly and tests the local admitted
layout against an independent eight-byte-stride C oracle. That case earns no
LLVM execution credit. The valid fallback and two-object cases have independent
LLVM controls; the standalone link proof compiles both reference objects through
LLVM rather than sharing a local provider.

All 75 table-filtered tests pass in Debug and ReleaseFast. The full compiler
commands pass 2,421 units and 74 structural checks. Their enclosing aggregate
fails only because the registry and native runner changed during the build;
`units-complete` preserves that receipt and independently verifies the exact
unchanged compiler/build input inventory and both completed success summaries.
The two unrelated hash differences are explicit; no failed aggregate is relabeled.

Four focused native populations pass in all three modes and both local routes:
the new fallback case records 4,608 local / 2,304 LLVM observations, the link case
3,072 / 1,536, and the existing length and preopt-memory cases remain green.
All 198 numbered faults are detected. Separate layout/default-link checks add
3,840 local observations, 1,536 fully independent LLVM link observations and 42
faults. All 36 local symbol checks pass. Four unrelated objects and their owner
manifests remain byte-identical. Captured-row smoke and all 60 ABI cases pass.

The complete 67,658,559-byte fixed Debug module also preserves its object and
owner bytes exactly. Both compilers produce accepted object digest
`92825c8e7821e8c2becc774942f149aacfd14a99167247199b1ee44c4d4d81c1`.
All eleven existing native-runner contract tests pass in Debug and ReleaseFast.

Before integration, collector `1794878706326727175-3163041` removes eleven
completed workspaces and reclaims 1,162,248,192 allocated bytes. Collector
`1794879491626834600-3177882` removes the two diagnosed scratch workspaces and
consumed baseline compiler, reclaiming another 429,625,344 bytes. Both verify all
seven current manifests; policy and independent holds remain unchanged. The
initial busy publication and subsequent absolute-path argument rejection made
no mutation and remain explicit in `pre-integration-storage`.

All seventeen serial Tier-3 gates pass on unchanged candidate compiler
`4c84ce3d1870c8e415aea5ecd2b927c1408a1e719dd0551154c2b378246896da`.
The complete C/native report matches all three program modes and all 235 native
populations, including the two new cases with their focused observation counts.
It binds registry digest
`53fb40fb0e0de7932d22ed044dd266bc5b98316b840ace746ae6fb97a5d4878a`.
Source, compiler, SDK, explicit d505fc64 emitter and seven current manifests
verify after the gate. Three authenticated AIR cache hits reuse no backend
objects or executions. All three immutable-bundle consumers verify identity
`0e7cab5dcfe3264d659aad11290e0d79fea144d0b79d54adb9b4ebfd844ebfd1`.
The intended local-binding changes are not claimed byte-identical to historical
default table objects or their bundles.

Serial wall time is 3,633,123 ms, with minimum observed free space
80,542,932,992 bytes and the unchanged 20 GB admission floor. These are validation
accounting, without a compiler-performance claim. This repair adds no
compiler-core cohort, compiler-rt row or ReleaseSafe outcome claim.

The integration checker and detached driver both return zero. Post-gate
collector `1794884055255899904-3344749` removes twelve completed workspaces,
reclaiming 2,110,922,752 allocated bytes. Final collector
`1794884834052862462-3360129` removes the consumed candidate compiler and last
integration workspace, reclaiming another 1,003,544,576 bytes. All seven current
manifests pass, policy and independent holds remain byte-identical, and this
cycle has no remaining temporary files or compiler consumers. Source fixtures,
identities, comparisons, original failures, diagnoses and receipts remain
maintained. Ordinary binaries and objects are retired without new pins.
