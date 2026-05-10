# Pass Manager

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/PassManager.h
llvm-project-22/llvm/lib/IR/PassManager.cpp
llvm-project-22/llvm/include/llvm/IR/PassInstrumentation.h
llvm-project-22/llvm/lib/IR/PassTimingInfo.cpp
llvm-project-22/llvm/include/llvm/IR/OptBisect.h
llvm-project-22/llvm/lib/IR/OptBisect.cpp
```

Upstream entry points to check:

```text
PassManager
PreservedAnalyses
PassInstrumentationCallbacks
TimePassesHandler
OptBisect
OptBisect::shouldRunPass
```

LLVM's pass manager coordinates pass execution, analysis preservation and
invalidation, pass instrumentation, timing, and opt-bisect controls. This
project currently has one module-level pass manager and conservatively rebuilds
analyses inside passes.

Implemented subset:

```text
module pass list with stable pass names
trace output before and after each pass
optional per-pass timing comments
optional pass execution limit
module verification after each executed pass
```

CLI:

```bash
zig build run -- --passes=instcombine,dce --trace test/opt/inputs/instcombine.ll
zig build run -- --passes=scalar-foundation --time test/opt/inputs/instcombine.ll
zig build run -- --passes=scalar-foundation --pass-limit=2 test/opt/inputs/instcombine.ll
```

Instrumentation output:

```text
; before <pass-name>
; after <pass-name>: changed|unchanged
; time <pass-name>: <nanoseconds> ns
; pass limit reached after N pass(es)
```

Analysis invalidation contract:

```text
All analyses are considered invalid after a pass runs.
Passes that need analyses rebuild them locally from the current module/function state.
No pass currently advertises preserved analyses.
This is deliberately conservative until an analysis manager lands.
```

Upstream mapping:

```text
Pass timing maps to LLVM's TimePassesHandler concept, but only as simple stable comments for local debugging.
The pass limit maps to LLVM's opt-bisect idea: stop executing optimization passes after a configured count.
The invalidation contract is stricter than LLVM's PreservedAnalyses model because every pass is treated as invalidating all analyses.
```

Known gaps:

```text
no analysis manager
no preserved-analysis reporting
no nested pass managers
no before/after pass instrumentation callbacks
no pass skip callbacks beyond the simple pass limit
no machine-readable timing output
```
