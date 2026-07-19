#!/usr/bin/env bash

set -u

TARGET="${1:-worker:2.0}"
INTERVAL_SECONDS="${WATCHER_INTERVAL_SECONDS:-900}"
POLL_SECONDS="${WATCHER_POLL_SECONDS:-15}"
PID_FILE="/tmp/z_llvm_watcher_loop.pid"
LOG_FILE="/tmp/z_llvm_watcher_loop.log"
BUFFER_NAME="z_llvm_watcher_directive"

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE"
}

if [[ -f "$PID_FILE" ]]; then
    old_pid="$(<"$PID_FILE")"
    if [[ "$old_pid" =~ ^[0-9]+$ ]] && kill -0 "$old_pid" 2>/dev/null; then
        printf 'Watcher loop is already running as PID %s\n' "$old_pid" >&2
        exit 1
    fi
fi

printf '%s\n' "$$" >"$PID_FILE"
cleanup() {
    rm -f "$PID_FILE"
    log "stopped"
}
trap cleanup EXIT
trap 'exit 0' INT TERM

INITIAL_DIRECTIVE=$(cat <<'EOF'
You are the Watcher for the z_llvm Worker/Reviewer workflow.

PANES:
- Worker: worker:0.0
- Reviewer: worker:1.0
- Watcher: worker:2.0

CURRENT STATE:
- INBOX-173 is accepted at efcac24b.
- INBOX-174 is authorized in the tracked operating directive at ed26c326.
- The Worker acknowledged INBOX-174 and is implementing the combined dormant ordinary-direct-call and intByteSize actions.
- Production routing must remain byte-identical and the ratchet remains 131.
- INBOX-174 forbids production wiring, isolation, performance, strengthened Tier 2, and Tier 3.
- Expected evidence is docs/evidence/inbox174_o2_calls_dormant.summary.
- Never use reset --hard. Preserve stash@{0} and existing patches.

MONITORING:
Regularly inspect worker:0.0 with:
tmux capture-pane -t worker:0.0 -p -S -180 | tail -140

Do not interrupt a busy Worker. An apparently idle pane may be waiting on a background build, so inspect its screen and relevant processes first. Never send Ctrl+C.

WHEN THE WORKER STOPS:
1. Preserve the Worker’s final report verbatim.
2. Inspect the commit, worktree, source diff, evidence, and retained logs. Do not run the project code yourself; review source and existing logs only.
3. Verify every active-inbox condition, including scope, ratchet, identities, gates, prohibited actions, clean worktree, and untouched stash.
4. Discuss acceptance and the next bounded task with the Reviewer on worker:1.0. Every Reviewer message must begin exactly:
It's from Watcher:
5. Reach explicit agreement before assigning anything to the Worker. Incorporate all Reviewer refinements.
6. Surface relevant Worker and Reviewer dialogue verbatim to the user.
7. After agreement, add the new directive to docs/worker_inbox.md, update docs/next_steps.md to the sole current authorized action, commit only tracked operating-document changes, and dispatch the agreed task to worker:0.0 using tmux bracketed paste.
8. Confirm the Worker acknowledged the directive and its stop conditions.

EXPECTED SEQUENCE:
After INBOX-174, propose—but do not assume authorization for—a separate isolation matrix: ordinary calls alone, intByteSize alone, and their aggregate. Production wiring, ratchet 130, and performance require later separate review.

Proceed autonomously on Watcher/Reviewer agreement. Ask the user only for destructive, irreversible, or materially scope-expanding actions. On divergence or failed acceptance conditions, stop advancement and report instead of fixing forward.
EOF
)

REMINDER=$(cat <<'EOF'
Watcher reminder: inspect worker:0.0 now. If the Worker is still active, do not interrupt it and continue monitoring. If it has stopped, verify its source/log evidence, discuss acceptance and the next bounded task with worker:1.0 (begin every message with "It's from Watcher:"), obtain explicit agreement, update the inbox/operating docs, and only then dispatch the agreed task to the Worker.
EOF
)

pane_exists() {
    tmux display-message -p -t "$TARGET" '#{pane_id}' >/dev/null 2>&1
}

watcher_is_running() {
    local command
    command="$(tmux display-message -p -t "$TARGET" '#{pane_current_command}' 2>/dev/null || true)"
    case "$command" in
        ""|bash|dash|fish|sh|zsh)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

watcher_is_busy() {
    tmux capture-pane -t "$TARGET" -p -S -20 2>/dev/null |
        tail -20 |
        grep -Eq 'Working \(|esc to interrupt|Running command|Waiting for'
}

paste_message() {
    local message="$1"
    printf '%s' "$message" | tmux load-buffer -b "$BUFFER_NAME" -
    tmux paste-buffer -t "$TARGET" -b "$BUFFER_NAME" -p -d
    tmux send-keys -t "$TARGET" Enter
}

log "started target=$TARGET interval=${INTERVAL_SECONDS}s"

while ! pane_exists || ! watcher_is_running || watcher_is_busy; do
    sleep "$POLL_SECONDS"
done

paste_message "$INITIAL_DIRECTIVE"
log "sent initial directive to $TARGET"

next_reminder=$(( $(date +%s) + INTERVAL_SECONDS ))

while true; do
    sleep "$POLL_SECONDS"

    now="$(date +%s)"
    if (( now < next_reminder )); then
        continue
    fi

    if ! pane_exists; then
        log "target pane unavailable; reminder deferred"
        continue
    fi

    if ! watcher_is_running; then
        log "Watcher agent not running; reminder deferred"
        continue
    fi

    if watcher_is_busy; then
        log "Watcher busy; reminder deferred"
        continue
    fi

    paste_message "$REMINDER"
    log "sent reminder to $TARGET"
    next_reminder=$(( now + INTERVAL_SECONDS ))
done
