# Worker Agent How-To

How the autonomous worker is run, monitored, and messaged. The worker is
a Codex CLI session; the supervising docs/verification agent is a Claude
Code session. All coordination state lives in files, so either side can be
restarted at any time without losing context.

## Running the worker

The worker must run inside tmux so it can be observed and messaged:

```sh
tmux new -s worker          # window 0, pane 0 is the canonical target
cd ~/prog/z_llvm
codex -s danger-full-access
```

Canonical pane address: `worker:0.0`. Keep the worker in window 0 pane 0;
all messaging commands below target that address, and a bare session
target would type into whatever window happens to be active.

Standard start/restart prompt (works for a fresh session and after any
stop; never needs task details because the docs carry all state):

```text
Resume worker cycles per docs/working-cycle.md. Read docs/worker_inbox.md
first and acknowledge any unacknowledged Active inbox entries by id. Work
cycles automatically until blocked or complete.
```

Model note: the session has run on `gpt-5.5 high`. If the pane shows
model errors (HTTP 400 "model not supported"), switch back with `/model`
inside the Codex TUI — no nudge can land while requests error.

## Coordination files

- `docs/worker_inbox.md` — directives from the supervisor to the worker.
  Single-writer (supervisor); the worker reads it at every cycle start
  and never edits it. Gitignored on purpose. Entries are INBOX-N, dated,
  acknowledged by id in a commit message or stop state, then archived by
  the supervisor.
- `docs/next_steps.md` — the worker's stop states and blockers.
- `docs/roadmap/convergence_progress.md` — goal tracker, ratchets,
  progress log.
- `docs/working-cycle.md` — the worker's operating rules, including the
  inbox-read step and the bounded inbox wait after a stop.
- `docs/validation_tiers.md` — authoritative validation policy.

## Monitoring the worker

### Event monitors (run by the supervisor as background watchers)

New-commit watcher — emits one line per new commit within ~30 s:

```sh
last=$(git -C ~/prog/z_llvm rev-parse HEAD)
while true; do
  cur=$(git -C ~/prog/z_llvm rev-parse HEAD 2>/dev/null)
  if [ -n "$cur" ] && [ "$cur" != "$last" ]; then
    git -C ~/prog/z_llvm log --format='new-commit %h %s' "$last..$cur" | head -5
    last=$cur
  fi
  sleep 30
done
```

Stop-state watcher — fires when the worker writes a stop report, even
without a commit:

```sh
last=$(md5sum ~/prog/z_llvm/docs/next_steps.md | cut -d' ' -f1)
while true; do
  cur=$(md5sum ~/prog/z_llvm/docs/next_steps.md 2>/dev/null | cut -d' ' -f1)
  if [ -n "$cur" ] && [ "$cur" != "$last" ]; then
    echo "stop-state-updated: docs/next_steps.md changed in working tree"
    last=$cur
  fi
  sleep 30
done
```

(In the Claude Code session these run via the Monitor tool with
`persistent: true`, delivering events as task notifications.)

### Point-in-time checks

State snapshot — commits since last check, dirty files, newest logs:

```sh
git -C ~/prog/z_llvm log --format='%ci %h %s' <last-seen-hash>..HEAD
git -C ~/prog/z_llvm status --short | grep -vE 'worker_inbox|^\?\?'
ls -t ~/prog/z_llvm/tmp/*.log | head -3
```

Pane capture — the only way to distinguish "working", "idle-complete",
and "session broken" when the repo is silent with a clean tree:

```sh
tmux capture-pane -t worker:0.0 -p | grep -v '^$' | tail -10
```

Read it as: a `• Working (Nm Ns • esc to interrupt)` line means mid-turn;
a `─ Worked for ... ─` closing bar with no Working line means the turn
ended and the worker is idle awaiting input; JSON error lines mean the
session itself is broken (usually the model setting).

Log-name convention: the worker names validation logs
`tmp/<gate>_after_<change>.log`, so `ls -t tmp/*.log | head` reveals what
it is working on without interrupting it.

## Sending messages to the worker

All delivery is tmux keystroke injection. Always send the text literally
(`-l`), pause, then send Enter as a separate key — the pause lets the
Codex TUI register the input before submission:

```sh
tmux send-keys -t worker:0.0 -l "<message text>"
sleep 2
tmux send-keys -t worker:0.0 Enter
```

Three delivery situations:

1. Worker idle (turn ended): the message starts a new turn immediately.
2. Worker mid-turn: the message queues and is absorbed as steering —
   Codex reads it during the turn and adjusts. Good for course
   corrections that can wait a few minutes.
3. Urgent interrupt mid-turn: send Escape first to cancel the in-flight
   turn, then send the message. The worker keeps (does not revert) its
   in-progress edits, per the working-cycle interruption rules:

```sh
tmux send-keys -t worker:0.0 Escape
sleep 3
tmux send-keys -t worker:0.0 -l "<urgent message>"
sleep 2
tmux send-keys -t worker:0.0 Enter
```

Protocol for substantive direction: write the directive as an INBOX-N
entry in `docs/worker_inbox.md` first (durable, auditable, read at every
cycle start), then send a short nudge pointing at it:

```text
Reread docs/worker_inbox.md and start the next work cycle per
docs/working-cycle.md. Acknowledge unacknowledged Active inbox entries
by id.
```

The nudge text can be specific ("INBOX-11 adopts a new validation
policy...") — specificity helps when the message lands mid-turn.

## Verifying delivery

After a nudge, confirm it took:

```sh
sleep 8
tmux capture-pane -t worker:0.0 -p | grep -v '^$' | tail -4
```

Expect either a fresh `• Working (…s)` line (new turn started) or, if it
was mid-turn, later evidence in the turn narration or the commit body
("Acknowledges INBOX-N").

## History / retired pieces

`scripts/inbox_watch.sh` (a daemon that watched the inbox and auto-nudged
via tmux) is retired: the supervisor now performs detection and nudging
directly, which proved more reliable — the daemon accumulated two
watch-mechanics bugs (inotify single-shot event gap; pipe block
buffering) in one day. The script remains in the repo as reference; do
not run it alongside supervisor-driven nudging or the worker will get
duplicate messages.
