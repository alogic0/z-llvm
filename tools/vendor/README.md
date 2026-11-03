# Shared tool dependencies

`regex/` is a read-only subset of the independent `zig-regex` 0.1.0 source
distribution at tag `v0.1.0`, commit
`b9cff7ce90e17449ce388dca67dfaf177a88e23f`. It contains the exact public `src/`
tree, README/design contract and MIT, Unicode and provenance notices.

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
