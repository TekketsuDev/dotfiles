#!/usr/bin/env bash
# workspace.sh — default dev workspace layout
# Layout:
#   ┌──────────┬──────────────────────────────┐  80% height
#   │  15%     │   neovim (85% width)         │
#   │  shell   │                              │
#   ├──────────┴──────────────────────────────┤  20% height
#   │           lazygit (100% width)          │
#   └─────────────────────────────────────────┘
set -euo pipefail

SESSION="workspace"
PROJECT_DIR="${1:-$PWD}"

[[ -d "$PROJECT_DIR" ]] || { echo "Not a directory: $PROJECT_DIR"; exit 1; }

# Reattach if already running
if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach-session -t "$SESSION"
fi

# Create session with a single window
tmux new-session -d -s "$SESSION" -n "dev" -c "$PROJECT_DIR"

# Split bottom 20% — lazygit
tmux split-window -t "$SESSION:dev" -v -p 20 -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION:dev.bottom" "lazygit" Enter

# Select top pane, split left 15% / right 85% — neovim on right
tmux select-pane -t "$SESSION:dev.top"
tmux split-window -t "$SESSION:dev" -h -p 85 -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION:dev.right" "nvim ." Enter

# Focus neovim
tmux select-pane -t "$SESSION:dev.right"

exec tmux attach-session -t "$SESSION"
