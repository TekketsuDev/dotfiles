#!/usr/bin/env bash
# session-picker.sh — fzf menu to attach/create/kill tmux sessions
# Bound to prefix+S in tmux.conf

CURRENT=$(tmux display-message -p '#S' 2>/dev/null)

# Actions prepended to session list
NEW_SESSION="[+] new session"
KILL_SESSION="[-] kill a session"

SESSION=$(
  (
    echo "$NEW_SESSION"
    echo "$KILL_SESSION"
    tmux list-sessions -F "#{session_name}  #{session_windows}w  (#{?session_attached,attached,detached})  #{?#{==:#{session_name},$CURRENT},← current,}" 2>/dev/null
  ) | fzf \
    --prompt=" session › " \
    --header="  prefix+S: session picker | Enter: attach | Esc: cancel" \
    --border=rounded \
    --height=50% \
    --reverse \
    --ansi
)

[[ -z "$SESSION" ]] && exit 0

case "$SESSION" in
  "$NEW_SESSION")
    NAME=$(tmux display-popup -E "read -p 'Session name: ' n && echo \$n" 2>/dev/null || true)
    [[ -z "$NAME" ]] && exit 0
    tmux new-session -d -s "$NAME" -c "$HOME"
    tmux switch-client -t "$NAME"
    ;;
  "$KILL_SESSION")
    TARGET=$(tmux list-sessions -F "#{session_name}" 2>/dev/null \
      | fzf --prompt=" kill session › " --border=rounded --height=40% --reverse)
    [[ -z "$TARGET" ]] && exit 0
    tmux kill-session -t "$TARGET"
    ;;
  *)
    # Extract session name (first word)
    TARGET=$(echo "$SESSION" | awk '{print $1}')
    tmux switch-client -t "$TARGET" 2>/dev/null || tmux attach-session -t "$TARGET"
    ;;
esac
