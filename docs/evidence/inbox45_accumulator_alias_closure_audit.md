# Accumulator Alias Closure Audit

schema_version: 1
directive: `fix-forward after 0717acf7 during INBOX-45`
target: `x86_64-linux`
result: `no accepted closure invalidated`

## Question

Commit `0717acf7` repaired destructive immediate scalar operations that
preserved only one of multiple live EAX bindings created through a truncation
that is a no-op in the 32-bit machine representation. This audit asks whether
any previously accepted row could have exercised that defective path. Under
the standing audit-invalidation rule, any actual hit would require row-exact
native semantic re-proof before INBOX-45 could resume.

## Method

The audit used the accepted captured compiler_rt IR, md5
`b0eda7a6427c3084fdf096a68696f19c`, and the selector's structured IR parser
and allocation-plan interval authority. A temporary scanner formed transitive
alias classes for integer truncations whose source and result are at most 32
bits, then reported destructive immediate `shl`, `ashr`, `and`, `or`, `add`,
`sub`, and `xor` operations when another member of the operand's alias class
remained live after the operation. This intentionally over-approximates the
defect: it identifies rows that could have the IR/liveness shape before asking
whether the repaired preservation path changes their generated code.

The scan produced 37 records in 15 unique functions. Intersecting those
functions with the accepted 443 / 248 / 195 report classified them as:

- eight rows already failing at the accepted baseline, including the pending
  `__floatunsihf` and `__floatsihf` INBOX-45 rows;
- two internal bodies, `rem_pio2_large` and an anonymous `ldexp` helper, for
  which the accepted report and evidence make no per-function closure claim;
- five previously accepted row claims requiring an exact hit check.

For each of the five accepted rows, a structured parser extracted exactly the
function body and changed only its linkage/visibility for standalone emission.
The extracted IR was emitted once by the accepted pre-repair z_llvm binary and
once by a repair-only `0717acf7` binary. Every pair is nonempty and
byte-identical:

| Accepted row | Object size | Pre/post-repair sha256 |
| --- | ---: | --- |
| `compiler_rt.floatsisf.__floatsisf` | 1216 | `d837a530474ab7b5b897ae4d2581cf109d9c50c82bb9041c72dccb72bf7cd31f` |
| `compiler_rt.floatunsisf.__floatunsisf` | 1120 | `c992240f23552fa1b52f097447aba5c7676f01d1c0631320f83f7ae75d56a665` |
| `compiler_rt.shift.__ashlsi3` | 1048 | `b53bc313dac1805db4437a0a296a6b1f45e92462c61228b8dc17099d9c0d6847` |
| `compiler_rt.shift.__ashrsi3` | 1080 | `e87f2e1c10d4774bf7881e87242917c0d9b56a3d6bd006642066f541320c5434` |
| `compiler_rt.shift.__lshrsi3` | 1048 | `c2d7a50e065169d13413c0bc7b5e51da6acfbff763d5a5af8b8a799044e122d9` |

The accepted and repair-only full reports are also byte-identical and retain
443 selected / 248 emitting / 195 failing. Existing row-exact semantic
evidence for the two conversion rows is
`docs/evidence/std_debug_hello_cttz_i32_acceptance.md`; shift evidence is
`docs/evidence/std_debug_hello_ashlsi3_phi_acceptance.md` and
`docs/evidence/std_debug_hello_ashrdi3_acceptance.md`.

## Conclusion

No previously accepted closure actually hit the defective
multiple-live-EAX-bindings path. The five conservative accepted-row matches
emit identical machine objects when the repair is present, so the repaired
preservation loop did not activate in those bodies. No accepted closure is
invalidated and no row-exact re-proof is required. The two INBOX-45 half
conversion rows were failing before the repair and remain new provisional
closure candidates; they must receive their planned exact native proof.

This is a documentation/evidence correction. No validation gate was required
or run.

## Audit Artifacts

- `tmp/inbox45_alias_audit.zig`, sha256
  `55e5a461a12030e089fb47d8c1123f4b0ba68f8663eaa08cc06637478298e80c`;
- `tmp/inbox45_accumulator_alias_audit_candidates_transitive.log`, sha256
  `3fbc9426d2b99f099ca46b24efa0279e616e20d2d3a3e5fefe45acc11a39652d`;
- `tmp/inbox45_accumulator_alias_audit_intersection_transitive.tsv`, sha256
  `bc68281ea2e6f215b7285687a55853449a422d0d3219e1fd7c221630843b60bd`;
- `tmp/inbox45_accumulator_alias_audit_object_comparison.tsv`, sha256
  `8aa373a88d44fce208068809d8e44692cf07783b19bf7c9382d95a5481beb50b`;
- `tmp/inbox43_f32x4_report.log` and
  `tmp/inbox45_p0_audit_repaired_report.log`, each sha256
  `5f8ae3358d64ac18bca667d5dc79178c0462e3f52129f3488c0b657774d0d274`.
