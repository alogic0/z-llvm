#!/usr/bin/env bash
# inbox_watch.sh - watch docs/worker_inbox.md and nudge the worker in tmux.
#
# When the inbox file changes, types a fixed instruction line into the tmux
# session running the worker, telling it to reread the inbox and start a
# work cycle. The worker must be started inside tmux:
#
#   tmux new -s worker        # then launch the worker inside
#
# Start the daemon (from the repo root):
#
#   nohup tools/inbox_watch.sh >> tmp/inbox_watch.log 2>&1 &
#
# Stop it:
#
#   pkill -f tools/inbox_watch.sh
#
# Requires tmux. Uses inotifywait (package inotify-tools) when available,
# otherwise falls back to mtime/checksum polling.

set -u

REPO="${HOME}/prog/z_llvm"
INBOX="$REPO/docs/worker_inbox.md"
SESSION="worker"      # tmux session that must exist
TARGET="worker:0.0"   # exact window.pane where the worker runs (send-keys goes here)
MESSAGE="Reread docs/worker_inbox.md and start the next work cycle per docs/working-cycle.md. Acknowledge unacknowledged Active inbox entries by id."
DEBOUNCE_SECONDS=15  # collapse save bursts into one nudge
POLL_SECONDS=20      # polling interval when inotifywait is absent

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

checksum() { md5sum "$INBOX" 2>/dev/null | cut -d' ' -f1; }

nudge() {
  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    log "skip: tmux session '$SESSION' not found (inbox changed, nobody to nudge)"
    return 1
  fi
  # -l sends the text literally; Enter is sent as a key press separately.
  # Target the exact window.pane, not the session: a bare session target
  # would type into whatever window is currently active.
  tmux send-keys -t "$TARGET" -l "$MESSAGE"
  sleep 2
  tmux send-keys -t "$TARGET" Enter
  log "nudged tmux pane '$TARGET'"
}

LAST_SUM=$(checksum)
LAST_NUDGE=0

handle_change() {
  local now sum remaining
  now=$(date +%s)
  sum=$(checksum)
  if [ "$sum" = "$LAST_SUM" ]; then
    return  # touched but content unchanged
  fi
  remaining=$((DEBOUNCE_SECONDS - (now - LAST_NUDGE)))
  if [ "$remaining" -gt 0 ]; then
    # Defer, never swallow: wait out the window, then nudge once for
    # whatever the file contains by then (collapses save bursts).
    log "debounce: change within ${DEBOUNCE_SECONDS}s window, deferring ${remaining}s"
    sleep "$remaining"
  fi
  LAST_SUM=$(checksum)  # re-read: include anything written during the wait
  LAST_NUDGE=$(date +%s)
  nudge
}

command -v tmux >/dev/null || { log "fatal: tmux not installed"; exit 1; }
[ -e "$INBOX" ] || log "note: $INBOX does not exist yet; will fire when it appears"

if command -v inotifywait >/dev/null; then
  # Watch the directory, not the file: atomic saves (tmp file + rename)
  # replace the inode and would silently kill a file-level watch.
  DIR=$(dirname "$INBOX")
  BASE=$(basename "$INBOX")
  log "watching $INBOX via inotifywait -m, target tmux session '$SESSION'"
  # Monitor mode: one long-lived watcher streaming events, so the second
  # event of an atomic save (close_write on the temp file, then moved_to on
  # the target) cannot land in a gap between single-shot invocations.
  # stdbuf -oL: inotifywait block-buffers when piped (stdout not a TTY),
  # which delays events by kilobytes; force line buffering so each event
  # flushes immediately.
  stdbuf -oL inotifywait -m -q -e close_write -e moved_to --format '%f' "$DIR" |
  while read -r EV; do
    [ "$EV" = "$BASE" ] || continue
    handle_change
  done
  log "fatal: inotifywait stream ended"
  exit 1
else
  log "inotifywait not found; polling every ${POLL_SECONDS}s"
  while sleep "$POLL_SECONDS"; do
    handle_change
  done
fi
