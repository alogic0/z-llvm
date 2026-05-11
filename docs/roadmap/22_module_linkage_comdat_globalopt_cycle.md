# Cycle 22: Module Linkage, COMDAT, and Global Optimization

## Goal

Improve module-level semantics needed before global cleanup and IPO can be
called Zig-aligned.

## Plan

- [ ] Inventory linkage, visibility, DLL storage class, COMDAT, aliases,
      ifunc-like forms, unnamed_addr, section, alignment, and global metadata
      in Zig rows.
- [ ] Parse and preserve the supported module-level attributes.
- [ ] Add verifier checks for references, linkage rules, initializer types, and
      COMDAT membership where modeled.
- [ ] Expand GlobalDCE and global cleanup only for internally provable unused
      symbols.
- [ ] Keep whole-program assumptions, ThinLTO import, WPD, and CFI deferred.
- [ ] Add fixtures for live globals, dead internal globals, aliases, COMDAT,
      weak linkage, and unsupported target-specific forms.
- [ ] Update module, global cleanup, and LTO docs.

## Exit Criteria

- [ ] Global cleanup handles at least one source-backed internal dead global.
- [ ] Linkage and COMDAT preservation is tested.
- [ ] IPO limits are explicit and conservative.
