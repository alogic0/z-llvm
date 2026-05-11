# Correctness Fuzzing And Differential Testing

The current differential layer is generated-but-bounded. It creates small
accepted IR cases rather than storing large fuzzing corpora in the repository.

## Runner

```text
scripts/run_generated_scalar_diff.sh
```

The runner:

```text
generates scalar identity cases in a temporary directory
compares z_llvm output with normalized opt-22 output
generates unsupported scalable-vector and invalid atomic-ordering cases and expects failure
optionally runs lli-22 on a pure scalar main function when lli-22 is installed
```

## Current Generated Positive Cases

```text
add x, 0
sub x, 0
mul x, 1
and x, -1
or x, 0
xor x, 0
```

## Current Generated Negative Cases

```text
scalable vector return type
invalid atomic ordering
```

## Policy

Generated failures should be minimized before becoming tracked fixtures. The
runner should keep temporary generated artifacts outside the docs and test
trees unless a failure is promoted into a named regression fixture.
