# INBOX-52 Release Object Artifact Reuse Acceptance

schema_version: 1
directive: `INBOX-52 bounded artifact-reuse optimization interlude`
target: `x86_64-linux-gnu`
status: pass

Committed implementation identity for both Tier-3 runs:

- commit `6d5d3ad61cc6eb500190e3b5292555f4308d41e2`;
- tree `2466430c065e242eb85179618ea63dc9770ace39`.

## Bounded Capability

`distribution-all` now gives four release-source gates an explicit
`release_source_object_bundle_v1` artifact contract. The integrated release
gate remains the sole producer: it emits all 100 objects, runs its existing
native-link and executable proofs, atomically publishes each object, and
publishes the complete manifest only after all rows pass. Object inspection,
native-link, and linker-probe gates validate the manifest target, row input
identity, size, and SHA-256 before reusing each object.

The manifest records target, case id, optimization mode, source wrapper,
covered fixture, object size, and object hash. Its deterministic SHA-256 is
`a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa`
in both the fresh and cached runs. The three consumers report the same
identity. Native-link still executes all 100 rows; no execution result is
cached. Each focused gate retains its old self-producing path when no bundle
environment is supplied.

Permanent helper coverage proves successful publication/reuse and rejects an
object modified after publication. A real focused cycle produces
`releasefast_source_tiny_scalar` once, reuses it in all three consumers, and
executes it in the native-link consumer. Independent object inspection without
a supplied bundle also passes.

Validation before Tier 3:

```text
zig test tools/release_source_object_bundle.zig
zig test tools/run_distribution_all_gates.zig
zig test tools/run_distribution_zig_integrated_object.zig
zig test tools/run_native_link_object_inspection.zig
zig test tools/run_distribution_native_link_m5.zig
zig test tools/probe_native_linker_compatibility.zig
zig test tools/compare_distribution_all_logs.zig
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
```

Results: full unit 1005/1005; Tier 2 24/24 steps and 1013/1013 tests;
bundle helper 1/1 including tamper rejection; runner 4/4; comparator 4/4;
all other affected tool compilation checks pass.

## Paired Tier 3

The policy-required same-state pair used these commands:

```text
zig build distribution-all -- --fresh-real-rows > tmp/distribution_all_inbox52_fresh.log 2>&1
zig build distribution-all > tmp/distribution_all_inbox52_cached.log 2>&1
zig run tools/compare_distribution_all_logs.zig -- tmp/distribution_all_inbox52_fresh.log tmp/distribution_all_inbox52_cached.log
```

Both runs pass all 17 subgates. Both keep integrated objects at 146/146 in
postopt, preopt, and IR-writer pipelines; strict real rows at 100/100/100;
integrated executables at 6/6; and release-source inspection/link/probe at
100/100 each. The schema-2 comparator proves semantic equivalence across all
1,262 canonical records:

```text
summary distribution-all-equivalence schema_version=2 gates=17 canonical_records=1262 semantic_match=true local_fail=0
```

Fresh run:

- actual wall time: 1,990.254 seconds (33m10.254s), measured from log
  creation to final write;
- summed child duration: 3,731.632 seconds;
- strict real-row cache status: three misses;
- release consumer durations: inspection 463ms, native-link 1,053ms,
  linker-probe 976ms.

Cached run:

- actual wall time: 1,337.819 seconds (22m17.819s), measured from log
  creation to final write;
- summed child duration: 2,021.645 seconds;
- strict real-row cache status: three hits;
- release consumer durations: inspection 403ms, native-link 1,029ms,
  linker-probe 968ms.

The accepted cached baseline is 1,678.60 seconds. The new cached wall time
saves 340.781 seconds (5m40.781s), a 20.30% reduction. This is a
meaningful result and clears the ten-percent threshold, but does not authorize
preopt sharding or wider DAG/concurrency work. The next named optimization
candidate remains a separately reviewed, deterministic, bounded 146-case
preopt sharding slice.

The old INBOX-51 release consumer durations were 95,408ms, 95,516ms, and
95,527ms because each consumer re-emitted all 100 objects. The new pair keeps
the authoritative producer duration near its prior level while removing those
three redundant emissions.

Artifacts:

- fresh preface `tmp/inbox52_artifact_reuse_fresh_tier3_preface.txt`, sha256
  `b12255b74f6417ef0c78e2a1f4936f560b82fd6321bbcab0fda75332bac8cf4c`;
- cached preface `tmp/inbox52_artifact_reuse_cached_tier3_preface.txt`, sha256
  `95c7881d854b124e28fa5039c2d32b338254851e958c7ed403f12ea6ffc03926`;
- fresh log `tmp/distribution_all_inbox52_fresh.log`, sha256
  `bf3776aecb0771320cf9e1f84a08732782b0b56e665dc46b04b53add7462b76a`;
- cached log `tmp/distribution_all_inbox52_cached.log`, sha256
  `3851cf2f6b2370cc85507d905f14622e2c4fd5a29a51d54541eadabeb01cfac9`;
- focused producer `tmp/inbox52_focused_producer.log`, sha256
  `6da7862cda0edd11ab949064b27a0b95a8ec14bb541ae48323e6fb5e1799c73b`;
- focused inspection/native-link/probe logs have sha256
  `dba4697d85b30e2d7ad477d12f6897fafd6797bcc0834ea548412ae9aa7a43df`,
  `bb32a7339f139e6b0096ef1ec58e24d965ce13564824832a87903d23f6cf032b`,
  and `19d87dd09ef52106bf6e995024e33c467c020de4814701c780356a1545ec7e19`;
- independent focused inspection log sha256
  `a79dd5d8373eb1cef35af5b054a6b87b4421edca091aa3a1270a981ce13c8923`.

INBOX-52 is complete and accepted. Stop after this slice. The switch-PHI/EI
program remains pending architectural direction, and any preopt sharding or
wider distribution-all optimization requires a separate reviewed directive.
