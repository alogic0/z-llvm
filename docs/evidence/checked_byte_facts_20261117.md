# Checked byte facts without object identity

Status: accepted after rewrite construction at `49a37848`; the ordered follow-up
and its storage cycle are complete. Evidence root is
`local-state/validations/compiler-generalization/follow-up-20261116/stage-04`.

The shared byte range contains an optional signed offset and optional length.
It checks range ends, containment and offset addition without assigning object
identity. Unknown facts remain distinct from zero. Overflow returns unknown or
refuses bounds. Memory-location GEP multiplication/addition and field-index casts
are checked; its root, alias, type and pointer-wrapping policies remain local.

The f32 aggregate view keeps its eight-byte object and existing pointer/PHI
admission. Equal offsets across different incoming objects can prove per-path
bounds while unique-root and alias facts remain unknown. Sharing the range does
not grant another lowering or backend capability.

Two new regressions cover unknown/zero/end boundaries, overflow and same/different
PHI roots. The existing full-selector f32 execution and rejection tests are now
registered permanently in the main test root. The initial filtered attempt ran
setup tests only; its owner stopped the new full-unit build with actual exit 143,
preserving the source, logs and diagnosis. Corrected qualification requires both
intended test names followed by `OK` in each mode, then fresh full units.
Both intended selector tests now execute and pass in Debug/Fast, alongside all
72 selected byte-fact tests per mode. All 2,438 Fast units and 74 structural checks
pass. Direct registration fixes focused discovery; the full suite already has an
indirect route through the selector facade. The source adoption bridge also
passes: all runtime/tool/fixture bytes match, with exactly three standalone
wrappers and three direct test-only imports distinguished.

The final source bridge compares every runtime/tool/fixture file against the
qualified combined snapshot, accounting only for three standalone test wrappers
and three direct test-only imports. Independent complete file maps bind that
snapshot; its empty Git-derived inventory is not source proof. Any adoption of
its compiler/native results requires this bridge, matching SDK/library/flags and
unchanged executable bytes. Those checks pass for compiler `7e9e98d4...`, adopting
the snapshot's five native populations, all 234 controls and exact fixed Debug
object/owner proof. These remain identified as adopted results. Fresh all-mode
ABI comparisons match all 60 cases, and all 27 M1 executables pass on unchanged
source. Final fresh serial integration now passes all seventeen gates and all
237 native populations, run `264e157d06a0e4707a06073df977b546`, on unchanged source.
The geometry population matches 1,920 local/960 reference observations, and the
extended table population matches 8,448 local/4,224 reference observations.
Authenticated frontend AIR is reused; backend, link and execution results are
fresh.

Pre-integration storage closure passes: receipt
`1794913366582263335-4132803` reclaims 1,144,786,944 allocated bytes from the
diagnosed first attempt, closed boundaries, predecessor compiler and duplicate
source. Original outcomes, complete source maps and comparison evidence remain
maintained. The adopted compiler remained through the final run and is now
released. Guarded teardown also retires the ordinary main Debug compiler
`06d34385...` after its consumers finish. Final collector receipt
`local-state/retirements/automatic-storage-cleanup/1794918075363632718-114700/report.json`
reclaims 236,646,400 allocated bytes from those two workspaces. The final
`stage-04/storage-closure/report.json` confirms all owned pipelines are closed
and no owned temporary roots remain. Original failure receipts, source maps and
validation evidence remain maintained. All seven current integrity manifests
verify; seventeen independent holds and storage policy are unchanged.

The earlier scheduling deferral remains unchanged. This slice makes no new
performance or 2,097-outcome ReleaseSafe claim.
