# Cycle 22: ABI Expansion For Byval, Sret, Varargs, And Aggregate Returns

## Goal

Expand ABI-shaped IR support only for source-backed rows that require byval,
sret, varargs, or aggregate returns.

## Source Anchors

- Existing aggregate ABI rows and future ABI captures
- LLVM IR: `byval`, `sret`, `inreg`, varargs, aggregate return lowering
- Local code: parser, verifier, target ABI helpers
- Docs: target ABI and unsupported IR

## Plan

- [x] Capture Zig source groups that force each ABI shape before implementation.
- [x] Preserve parameter and return attributes textually first.
- [x] Add verifier rules for accepted ABI attributes.
- [x] Update DataLayout/ABI helpers only where optimizer legality needs sizes or
      alignment.
- [x] Keep full calling convention lowering and multi-target ABI parity out of
      scope.
- [x] Add corpus and opt fixtures for accepted ABI-shaped IR.

## Exit Criteria

- [x] At least one new ABI-shaped source-backed blocker is closed.
- [x] Unsupported ABI forms fail closed.
- [x] Docs state which ABI facts are semantic versus textual preservation.

## Completed Slice

- Preserved `byval(...)` and `sret(...)` textually on pointer parameters in
  declarations and definitions, with verifier rejection for non-pointer use.
- Added explicit declaration and call-site varargs rejection coverage.
- Added a parse-preserve fixture for accepted pointer `byval`/`sret`
  annotations.
- Kept aggregate return lowering, hidden sret storage, byval copies, register
  assignment, stack argument layout, and multi-target ABI parity out of scope.
