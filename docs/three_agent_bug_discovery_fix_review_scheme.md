# Three-Agent Bug Discovery, Fix, and Review Scheme

## Goal

Create a repeatable loop where one agent finds source-backed bugs, one agent
fixes one selected bug, and one agent independently reviews the fix for
correctness before the work is archived or committed.

The loop must avoid mixing discovery, implementation, and approval in one
mental context. Each agent has a clear handoff artifact and a different
definition of done.

## Roles

### Agent 1: Discovery

Purpose: find the next real blocker.

Responsibilities:

- Run the current corpus/discovery sweep or focused fixture expansion.
- Group failures by root cause, not by every individual file.
- Reduce at least one representative fixture per root-cause bucket.
- Classify each bucket as:
  - parser gap;
  - verifier gap;
  - optimizer correctness gap;
  - optimizer quality gap;
  - unsupported boundary;
  - harness/tooling issue;
  - input-too-large or compile-skip.
- Compare the representative case to LLVM/`opt-22` when applicable.
- Produce a short bug packet for exactly one selected bug.

Discovery does not edit production code.

Output artifact:

```text
tmp/scratch/bug_packets/NN_short_name.md
```

Required bug-packet fields:

- title;
- source-backed evidence;
- reproduction command;
- smallest fixture path;
- observed local behavior;
- expected LLVM or local policy behavior;
- likely owning files;
- non-goals;
- suggested acceptance checks.

Definition of done:

- One bug is selected.
- It has a minimized fixture or exact corpus row.
- The failure is reproducible.
- The expected behavior is clear enough for a fixer to implement without
  rediscovering the problem.

## Agent 2: Fixer

Purpose: implement one bug packet.

Responsibilities:

- Read only the selected bug packet and nearby code.
- Create or update the smallest required fixture.
- Implement the smallest local code change.
- Keep scope inside the bug packet unless a blocker is discovered.
- Update relevant docs or cycle checklist.
- Run focused tests first, then normal gates if shared behavior changed.

Fixer does not approve its own fix as correct.

Output artifact:

```text
tmp/scratch/fix_reports/NN_short_name.md
```

Required fix-report fields:

- bug packet path;
- files changed;
- behavior changed;
- tests added or updated;
- commands run;
- known residual risk;
- any requested reviewer focus.

Definition of done:

- The selected repro is fixed.
- Focused fixture coverage exists.
- Relevant gates pass or failures are documented.
- The change is ready for independent review.

## Agent 3: Reviewer

Purpose: verify that the fix is correct, scoped, and honestly documented.

Responsibilities:

- Start from the bug packet and fix report.
- Review the diff with a code-review stance.
- Check whether the fixture actually catches the original bug.
- Check whether the fix preserves LLVM/source-backed behavior.
- Look for overbroad parser acceptance, verifier holes, optimizer unsoundness,
  missing flag/metadata preservation, and documentation overclaims.
- Rerun the focused repro and enough gates to trust the change.
- Produce findings first, ordered by severity.

Reviewer does not implement follow-up fixes unless explicitly assigned a new
fixer role.

Output artifact:

```text
tmp/scratch/review_reports/NN_short_name.md
```

Required review-report fields:

- verdict: accepted, accepted-with-risk, or rejected;
- findings;
- commands run;
- residual risk;
- whether the cycle can be archived.

Definition of done:

- If accepted, the bug packet, fix report, and review report are all linked
  from the active cycle or `docs/next_steps.md`.
- If rejected, the finding becomes the next bug packet or the existing packet
  is returned to the fixer.

## Handoff Flow

```text
Discovery Agent
  -> bug packet
  -> Fixer Agent
  -> code, fixtures, fix report
  -> Reviewer Agent
  -> accepted/rejected review report
  -> commit only after positive review
  -> archive cycle or reopen bug packet
```

## File Layout

Scratch working area:

```text
tmp/scratch/bug_packets/
tmp/scratch/fix_reports/
tmp/scratch/review_reports/
```

Durable docs only after review acceptance:

```text
docs/roadmap/NN_cycle_name.md
docs/roadmap/historical/completed_discovery_cycles/NN_cycle_name.md
docs/fixtures/...
test/...
```

Scratch files may contain incomplete thinking. Roadmap files should contain
only selected, reviewable, source-backed work.

## Loop Rules

- One selected bug per fixer cycle.
- Discovery may find many buckets, but it hands off only one selected bug.
- The fixer must not silently broaden the grammar or optimizer behavior.
- The reviewer must check the bug packet, not only the final diff.
- LLVM comparison is required for LLVM-equivalent behavior.
- Local-conservative differences must be explicitly labeled.
- Compile-skip and input-size issues are not parser bugs unless reduced to IR
  behavior.
- A passed gate is not enough if the fixture encodes the wrong behavior.
- The fixer does not commit before review. Commit only after the reviewer
  returns `accepted` or `accepted-with-risk`; if review is rejected, return the
  finding to the fixer or create the next bug packet.

## Suggested Commands

Discovery:

```text
zig run tools/zig_corpus_discovery.zig -- --help
```

Focused fixer checks:

```text
zig build test
zig build compare-opt --
```

Reviewer gates:

```text
zig build test
zig build compare-opt --
zig build readiness
```

## First Use

Use this scheme for the next corpus refresh:

- Agent 1 discovers and groups new blockers.
- Agent 1 writes `tmp/scratch/bug_packets/01_next_source_backed_blocker.md`.
- Agent 2 fixes only that blocker.
- Agent 3 reviews whether the fix closes the blocker without overclaiming.
