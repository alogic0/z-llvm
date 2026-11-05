# Shared tool dependencies

`regex/` is a read-only subset of the independent `zig-regex` 0.1.0 source
distribution at tag `v0.1.0`, commit
`b9cff7ce90e17449ce388dca67dfaf177a88e23f`. It contains the exact public `src/`
tree, compiler pin, API/contribution/release documentation and MIT, Unicode and
provenance notices. The extra documentation keeps the copied README links valid.

Full archive SHA-256:
`c3058c74fc9a8cb36a1cff60c4e6b334f0f1d61c1143d1a7685491ffb6ba72a3`.
Full Zig package hash:
`regex-0.1.0-ez7ct3GiDgDs4FXspHuL00_WQJjgTuxRJZJdKAZfwR94`.
`regex.SHA256SUMS` records every selected source/notice file after extraction.

Tools deliberately remain standalone `zig run tools/FILE.zig` programs, including
their nested runners. A module supplied only by the outer build would disappear
from those child invocations. Keeping the unchanged public source within their
module root preserves that interface without rewriting the runner graph. This
snapshot replaces `tools/zigrep_regex`; fixes belong in the independent provider
and are adopted by an explicit version/digest update.

After an update, run `zig build verify-regex-source test-tool-regex`, and repeat
with `-Doptimize=ReleaseSafe`. The process fixtures exercise the actual
`tool_common.expectRegex/expectNoRegex` functions, preserving linewise matching,
CRLF handling, POSIX-class normalization, Unicode and failure diagnostics/status.
They also cover the provider's corrected inline case-mode behavior. These checks
do not establish compiler output or ABI-differential acceptance.

## Source audit

`source_audit/` contains the verbatim public `src/` tree and notices from the
independent `zig-source-audit` 0.1.1 package at
`9de0c09b4e8c8bfe70b733e6ef176c602918943d`.

Full archive SHA-256:
`5c7ee8ca69a228bfd19c72883e4021c582bc4c9540a90b4dd44dccd3c2de5d08`.
Full Zig package hash:
`source_audit-0.1.1-FaX7WF_oAADBJ5D5MSdARP5HboAWqUWaH3j0k8vv3gBx`.
`source_audit.SHA256SUMS` records the selected file digests. This uses the same
standalone-runner boundary as regex; `zig build source-audit` verifies the source
then runs the shared CLI. No product paths are added to the provider. Supply
consumer-owned `--rules` JSON explicitly when enforcing architecture constraints.
The 0.1.1 patch corrects installation documentation; the analysis source is
byte-identical to the initial 0.1.0 adoption.

## Process and validation support

`process/` is a verbatim source selection from the independent `zig-process`
0.6.0 repository at `800c6ea9739cdf98405471df0120f1c9ad6ae1e0`, copied directly
from `~/prog/zig-process`. It includes all six public source files, the native
test fixture, compiler pin, license and provider design/status documentation.
`test_support/` contains the unchanged `files.zig` and `json.zig` modules and
license from `zig-test-support` 0.1.0 at
`e23cb642765677807c2e80f613fb873f9780554a`. Both revisions match
`~/zig-inventory-2026-11-03/inventory.json`; no archives were created.

The per-file ledgers are `process.SHA256SUMS` and `test_support.SHA256SUMS`.
Run `zig build verify-validation-sources real-program-policy-tests`, including
`-Doptimize=ReleaseSafe`. Provider capture-failure tests use its unmodified
fixture through build options. Consumer tests cover process status, binary
logs, cancellation, timeouts, descendant cleanup, ELF provenance, candidate
admission, fact freezing and measurement statistics.

These tools use the same standalone source boundary as regex. They do not
depend on an absolute path to another checkout. Signal handlers, output
directories, validation decisions and evidence formats belong to
`tools/validation/`; the provider retains exclusive child and process-group
ownership. The benchmark observes the provider's borrowed pidfd with blocking
`poll`, then lets the provider reap and clean up. This avoids millisecond
polling quantization without introducing a second reaper.
