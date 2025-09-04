#!/usr/bin/env bash
set -euo pipefail

SESSION="dev"
PROJECTS_FOLDER="${1:-/home/tekketsu/projects}"
if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach-session -t "$SESSION"
fi

# --- Último archivo de Neovim (filtrando ruido de lazy/glfw) ---
last_file="$(nvim --headless +'lua print(vim.v.oldfiles[1] or "")' +qa 2>&1 | awk '/^\// { gsub(/%$/, "", $0); print; exit }' || true)"
if [[ -n "${last_file}" && -e "${last_file}" ]]; then
  PROJECT_DIR="$(dirname -- "${last_file}")"
elif [[ -n "$PWD" && -d "$PWD" ]]; then
    PROJECT_DIR="$PWD"
else
    PROJECT_DIR="$HOME"
fi

echo "$PROJECT_DIR starts at $(date)" >> ~/dotfiles/scripts/dev/log.txt

tmux new-session -d -s "$SESSION" -n "code" -c "$PROJECTS_FOLDER" \
    "nvim -c 'lua vim.g.savesession = true'"
#tmux new-session -d -s "$SESSION" -n "code" -c "$PROJECT_DIR" "nvim -S session.vim -c 'lua vim.g.savesession = true'"
tmux new-window -t "$SESSION":2 -n "shell" -c "${PROJECT_DIR:-$HOME}" "zsh"
tmux new-window -t "$SESSION":3 -n "configs" -c "$HOME" "zsh -c 'nvim ~/dotfiles; exec zsh'"
tmux new-session -d -s "$SESSION":4 -n "last-file" -c "${PROJECT_DIR:-$HOME}" \
    "zsh -c '[[ -f session.vim ]] && nvim -S session.vim || nvim; exec zsh'"
#tmux new-window -t "$SESSION":4 -n "ssh" -c "$HOME" "ssh -G $(grep -E '^Host ' ~/.ssh/config | awk '{print \$2}' | fzf)"

# Attach to session
tmux select-window -t "$SESSION:code"
exec tmux attach-session -t "$SESSION"
