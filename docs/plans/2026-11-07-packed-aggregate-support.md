# Shared packed aggregate support

Status: complete at `1bf7b020`; all 17 integration gates pass. See the
[implementation and evidence](../evidence/packed_aggregate_support.md).

The retained complete compiler IR rejects 111 packed aggregate globals before
verification. Admit their structure syntax through the common IR parser, share
the structure field view with layout and constant emission, and preserve packed
field offsets, allocation strides, nested ordinary-structure padding, and
unaligned pointer relocations. Keep unsupported element layouts and aggregate
calling conventions explicit boundaries.

1. Add a shared packed/unpacked structure view; use it for types, constants,
   DataLayout, field queries and global-data encoding. Preserve vector parsing.
2. Add parser/serialization, layout and malformed-input checks, plus permanent
   native execution against LLVM for defined bytes, nested arrays, GEP strides,
   mutation, data/function pointer fixups and explicit global alignment.
3. Replay the retained global census and complete compiler input without
   modifying either. Record the next actual failure stage. Runtime vector casts
   remain a separate slice; do not infer compiler readiness from syntax closure.
4. Run unit, parser/readiness, native and full integration validation before
   accepting this shared layout/relocation capability. Existing compiler-core
   counters remain unchanged. Keep exact source/binary/input identities and logs.

Evidence root: `local-state/validations/packed-aggregate-20261107/`. Reuse the
current pinned frontend and core AIR caches. Admission is 32,949,672,960 bytes;
execution reserve is 24,359,738,368 bytes. Preserve original scratch probes,
previous evidence and compiler binaries. Create no archives.

Outcome: all 36,959 global/alias records now parse independently, removing the
111 packed-global syntax rejections. The permanent native population passes
all modes/routes in Debug and ReleaseFast compiler builds. Exact whole-compiler
replay advances to `InvalidLabel`; the independent definition census records
seven parser rejections among 8,928 definitions. Resolving those parser
boundaries, then the separate runtime vector-cast verifier boundary, is the
next work. This slice does not claim a complete compiler object or executable.
