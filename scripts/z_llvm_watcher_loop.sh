#!/usr/bin/env bash

set -u

WATCHER_PANE="${1:-worker:2.0}"
WORKER_PANE="${2:-worker:0.0}"
REVIEWER_PANE="${3:-worker:1.0}"
POLL_SECONDS="${WATCHER_POLL_SECONDS:-15}"
STOP_CONFIRM_SECONDS="${WORKER_STOP_CONFIRM_SECONDS:-45}"
REMINDER_SECONDS="${WATCHER_REMINDER_SECONDS:-900}"
HEARTBEAT_SECONDS="${WATCHER_HEARTBEAT_SECONDS:-300}"
PID_FILE="/tmp/z_llvm_watcher_loop.pid"
LOG_FILE="/tmp/z_llvm_watcher_loop.log"
BUFFER_NAME="z_llvm_watcher_directive"

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE"
}

for interval_name in POLL_SECONDS STOP_CONFIRM_SECONDS REMINDER_SECONDS HEARTBEAT_SECONDS; do
    interval_value="${!interval_name}"
    if [[ ! "$interval_value" =~ ^[1-9][0-9]*$ ]]; then
        printf '%s must be a positive integer, got %q\n' "$interval_name" "$interval_value" >&2
        exit 2
    fi
done

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

ROLE:
Monitor the Worker and take action only after the monitoring script reports
that the Worker has stopped. Determine the current project state from the
Worker's final report, docs/worker_inbox.md, docs/next_steps.md, current source,
commits, and retained logs. Do not rely on state embedded in this directive.

Never interrupt a busy Worker or send Ctrl+C. Never use reset --hard. Preserve
stash entries and existing patches.

WHEN NOTIFIED THAT THE WORKER STOPPED:
1. Preserve the Worker’s final report verbatim.
2. Inspect the commit, worktree, source diff, evidence, and retained logs. Do not run the project code yourself; review source and existing logs only.
3. Verify every active-inbox condition, including scope, ratchet, identities, gates, prohibited actions, clean worktree, and untouched stash.
4. Discuss acceptance and the next bounded task with the Reviewer on worker:1.0. Every Reviewer message must begin exactly:
It's from Watcher:
5. Reach explicit agreement before assigning anything to the Worker. Incorporate all Reviewer refinements.
6. Surface relevant Worker and Reviewer dialogue verbatim to the user.
7. After agreement, add the new directive to docs/worker_inbox.md, update docs/next_steps.md to the sole current authorized action, commit only tracked operating-document changes, and dispatch the agreed task to worker:0.0 using tmux bracketed paste.
8. Confirm the Worker acknowledged the directive and its stop conditions.

Proceed autonomously on Watcher/Reviewer agreement. A failed acceptance blocks
wider advancement, but it does not block a bounded diagnosis or remediation
that the Reviewer explicitly authorizes. Dispatch that agreed corrective slice.
EOF
)

WORKER_STOPPED_MESSAGE=$(cat <<'EOF'
The monitoring script detected that the Worker has stopped. Inspect worker:0.0 now and determine what it completed. Verify the source diff and retained logs without running project code. Then discuss acceptance and the next bounded task with the Reviewer on worker:1.0; begin every Reviewer message exactly with "It's from Watcher:". Obtain explicit agreement before updating the operating documents or assigning another task to the Worker. If acceptance failed but the Reviewer authorizes a bounded diagnosis or remediation, dispatch that corrective slice; failed acceptance alone is not a reason to leave the Worker idle.
EOF
)

WORKER_STILL_STOPPED_MESSAGE=$(cat <<'EOF'
Reminder: the Worker remains stopped after the previous notification. Check whether the Worker/Reviewer review produced an agreed next action. If the Reviewer authorized a bounded diagnosis or remediation after withheld acceptance, update the operating documents and dispatch it now. Leave the Worker stopped only for Reviewer disagreement, no mutually agreed safe bounded task, a destructive/irreversible/materially scope-expanding action requiring the user, or a genuine structural blocker; report that blocker explicitly.
EOF
)

pane_exists() {
    local pane="$1"
    tmux display-message -p -t "$pane" '#{pane_id}' >/dev/null 2>&1
}

agent_is_running() {
    local pane="$1"
    local command
    command="$(tmux display-message -p -t "$pane" '#{pane_current_command}' 2>/dev/null || true)"
    case "$command" in
        ""|bash|dash|fish|sh|zsh)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

pane_reports_busy() {
    local pane="$1"
    tmux capture-pane -t "$pane" -p -S -30 2>/dev/null |
        tail -20 |
        grep -Eq 'Working \(|esc to interrupt|Running command|Waiting for|Script running with cell ID'
}

worker_has_active_job() {
    local root_pid
    local frontier
    local next_frontier
    local pid
    local ppid
    local stat
    local command
    local parent

    root_pid="$(tmux display-message -p -t "$WORKER_PANE" '#{pane_pid}' 2>/dev/null || true)"
    [[ "$root_pid" =~ ^[0-9]+$ ]] || return 1

    frontier="$root_pid"
    while [[ -n "$frontier" ]]; do
        next_frontier=""
        while read -r pid ppid stat command; do
            [[ -n "$pid" ]] || continue
            for parent in $frontier; do
                if [[ "$ppid" == "$parent" ]]; then
                    next_frontier+=" $pid"
                    case "$command" in
                        node|codex|codex-code-mode)
                            ;;
                        *)
                            [[ "$stat" == Z* ]] || return 0
                            ;;
                    esac
                    break
                fi
            done
        done < <(ps -e -o pid=,ppid=,stat=,comm=)
        frontier="$next_frontier"
    done

    return 1
}

worker_is_busy() {
    pane_reports_busy "$WORKER_PANE" || worker_has_active_job
}

paste_message() {
    local message="$1"
    printf '%s' "$message" | tmux load-buffer -b "$BUFFER_NAME" -
    tmux paste-buffer -t "$WATCHER_PANE" -b "$BUFFER_NAME" -p -d
    tmux send-keys -t "$WATCHER_PANE" Enter
}

log "started watcher=$WATCHER_PANE worker=$WORKER_PANE reviewer=$REVIEWER_PANE stop_confirm=${STOP_CONFIRM_SECONDS}s reminder=${REMINDER_SECONDS}s heartbeat=${HEARTBEAT_SECONDS}s"

while ! pane_exists "$WATCHER_PANE" ||
    ! agent_is_running "$WATCHER_PANE" ||
    pane_reports_busy "$WATCHER_PANE"; do
    sleep "$POLL_SECONDS"
done

paste_message "$INITIAL_DIRECTIVE"
log "sent general initial directive to $WATCHER_PANE"

worker_state="unknown"
idle_since=0
next_reminder_at=0
last_heartbeat_at="$(date +%s)"

while true; do
    sleep "$POLL_SECONDS"
    now="$(date +%s)"

    if (( now - last_heartbeat_at >= HEARTBEAT_SECONDS )); then
        log "heartbeat worker_state=$worker_state"
        last_heartbeat_at="$now"
    fi

    if ! pane_exists "$WORKER_PANE" || ! agent_is_running "$WORKER_PANE"; then
        if [[ "$worker_state" != "unavailable" ]]; then
            log "Worker agent unavailable; waiting"
            worker_state="unavailable"
            idle_since=0
            next_reminder_at=0
        fi
        continue
    fi

    if worker_is_busy; then
        if [[ "$worker_state" != "busy" ]]; then
            log "Worker is active"
        fi
        worker_state="busy"
        idle_since=0
        next_reminder_at=0
        continue
    fi

    if [[ "$worker_state" == "busy" || "$worker_state" == "unknown" || "$worker_state" == "unavailable" ]]; then
        worker_state="idle_candidate"
        idle_since="$now"
        log "Worker appears idle; confirming for ${STOP_CONFIRM_SECONDS}s"
        continue
    fi

    if [[ "$worker_state" == "idle_candidate" ]]; then
        if (( now - idle_since < STOP_CONFIRM_SECONDS )); then
            continue
        fi
        worker_state="stopped_pending"
        log "Worker stop confirmed; notification pending"
    fi

    if [[ "$worker_state" == "stopped_notified" ]]; then
        if (( now < next_reminder_at )); then
            continue
        fi

        if ! pane_exists "$WATCHER_PANE" || ! agent_is_running "$WATCHER_PANE"; then
            log "Watcher unavailable; reminder deferred"
            next_reminder_at=$((now + POLL_SECONDS))
            continue
        fi

        if pane_reports_busy "$WATCHER_PANE"; then
            log "Watcher busy; reminder deferred"
            next_reminder_at=$((now + POLL_SECONDS))
            continue
        fi

        paste_message "$WORKER_STILL_STOPPED_MESSAGE"
        next_reminder_at=$((now + REMINDER_SECONDS))
        log "reminded $WATCHER_PANE that the Worker remains stopped"
        continue
    fi

    if [[ "$worker_state" != "stopped_pending" ]]; then
        continue
    fi

    if ! pane_exists "$WATCHER_PANE" || ! agent_is_running "$WATCHER_PANE"; then
        log "Watcher unavailable; stop notification deferred"
        continue
    fi

    if pane_reports_busy "$WATCHER_PANE"; then
        log "Watcher busy; stop notification deferred"
        continue
    fi

    paste_message "$WORKER_STOPPED_MESSAGE"
    worker_state="stopped_notified"
    next_reminder_at=$((now + REMINDER_SECONDS))
    log "notified $WATCHER_PANE that the Worker stopped"
done
