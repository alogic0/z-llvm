# Development Cycle

Each implementation cycle uses `docs/next_steps.md` as the active checklist.

For every future step that reproduces LLVM behavior, completion requires an upstream mapping before the step is committed.

## Required Upstream Mapping

Each pass, analysis, IR feature, or codegen feature must document:

```text
LLVM source files
LLVM classes/functions used as reference entry points
reproduced behavior
known missing behavior
test fixtures or opt commands used for comparison
```

The mapping belongs in the relevant document:

```text
docs/passes/<pass>.md
docs/analysis/<analysis>.md
docs/ir.md
docs/codegen.md
```

If the upstream mapping is incomplete, the implementation can land only if the doc explicitly says what still needs to be checked.

## Step Completion Rule

A checkbox in `docs/next_steps.md` can be marked complete only after:

1.  the implementation is done;
2.  tests or fixtures are added;
3.  the relevant upstream LLVM mapping is documented;
4.  the known unsupported behavior is documented;
5.  the step is committed separately using the commit policy.
