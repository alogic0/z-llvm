# Cycle 22: Module Linkage, COMDAT, and Global Optimization

## Goal

Improve module-level semantics needed before global cleanup and IPO can be
called Zig-aligned.

## Plan

- [x] Inventory linkage, visibility, DLL storage class, COMDAT, aliases,
      ifunc-like forms, unnamed_addr, section, alignment, and global metadata
      in Zig rows.
- [x] Parse and preserve the supported module-level attributes.
- [x] Add verifier checks for references, linkage rules, initializer types, and
      COMDAT membership where modeled.
- [x] Expand GlobalDCE and global cleanup only for internally provable unused
      symbols.
- [x] Keep whole-program assumptions, ThinLTO import, WPD, and CFI deferred.
- [x] Add fixtures for live globals, dead internal globals, aliases, COMDAT,
      weak linkage, and unsupported target-specific forms.
- [x] Update module, global cleanup, and LTO docs.

## Exit Criteria

- [x] Global cleanup handles at least one source-backed internal dead global.
- [x] Linkage and COMDAT preservation is tested.
- [x] IPO limits are explicit and conservative.

## Completed Slice

- Added weak linkage parsing/printing for functions and globals; GlobalDCE
  treats weak definitions as externally visible roots.
- Added COMDAT reference verification for modeled global/function attributes.
- Added `globaldce_weak_root` as an `opt-22` equivalent fixture and kept
  COMDAT behavior conservative.
