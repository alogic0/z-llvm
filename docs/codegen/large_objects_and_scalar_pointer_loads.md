# Large fixed objects and scalar pointer loads

The byte-addressed storage view accepts fixed objects through four MiB. The
existing total frame limit remains eight MiB, including spills and call storage.
Page probing, signed displacement checks, exact extent tracking, checked size
arithmetic, layout validation and alignment rules remain in force. Runtime-sized
allocas and address-space objects remain closed.

A final optional scalar-load fallback captures ordinary f32 and f64 memory bits
with an integer load of exactly the same width, then bitcasts those captured bits
to the original type. This handles table-derived and merged pointers after the
existing owners decline the function. It preserves access alignment, drops
floating metadata from the private integer instruction, and excludes atomic,
volatile and nondefault address-space accesses. It changes no source IR.

Native checks exercise unaligned table and merged pointers, signaling and quiet
NaN payloads, signed zeros, mutation after the original load, caller clobbers,
guarded outputs and page-crossing fixed stack objects. Boundary unit checks cover
the four-MiB object limit and rejection above it.
