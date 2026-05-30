#!/usr/bin/env bash
# devenv.sh — launch a tmux dev environment for a specific stack
# Usage: devenv <env> [project-dir]
#   Environments: c | cpp | raylib | react | esp32
#
# Each session layout:
#   Window 1 "code"   : nvim (left 65%) | claude code (right 35%)
#   Window 2 "build"  : shell + stack-specific pane (compiler/dev-server/monitor)
#   Window 3 "shell"  : free shell
set -euo pipefail

ENV="${1:-}"
PROJECT_DIR="${2:-$PWD}"

_g='\033[0;32m'; _y='\033[0;33m'; _r='\033[0;31m'; _n='\033[0m'
log()  { printf "${_g}[devenv]${_n} %s\n" "$*"; }
err()  { printf "${_r}[err]${_n} %s\n" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: devenv <env> [project-dir]

Environments:
  c          C project (gcc, gdb, bear, clangd)
  cpp        C++ project (clang, cmake, clangd)
  raylib     Raylib/C game dev (cmake, raylib, hot-compile)
  react      React/Node project (pnpm dev server)
  esp32      ESP32 firmware (platformio, serial monitor)

Each session opens:
  [code]   nvim + claude code side pane
  [build]  stack-specific build/run pane
  [shell]  free terminal

EOF
}

[[ -z "$ENV" ]] && { usage; exit 1; }
[[ -d "$PROJECT_DIR" ]] || err "Project dir not found: $PROJECT_DIR"

SESSION="dev-$ENV"
NVIM_CMD="nvim"

# Reattach if session already exists
if tmux has-session -t "$SESSION" 2>/dev/null; then
  log "Attaching to existing session: $SESSION"
  exec tmux attach-session -t "$SESSION"
fi

log "Starting $ENV env in: $PROJECT_DIR"

# ─── Window 1: code — nvim (left) + claude code (right) ──────────────────────
tmux new-session -d -s "$SESSION" -n "code" -c "$PROJECT_DIR"

# Split vertically: nvim on left 65%, claude on right 35%
tmux send-keys -t "$SESSION:code" "$NVIM_CMD ." Enter
tmux split-window -t "$SESSION:code" -h -p 35 -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION:code.right" "claude" Enter
tmux select-pane -t "$SESSION:code.left"

# ─── Window 2: build — stack-specific ────────────────────────────────────────
tmux new-window -t "$SESSION" -n "build" -c "$PROJECT_DIR"

case "$ENV" in
  c)
    # Left: build shell | Right: gdb ready
    tmux send-keys -t "$SESSION:build" \
      "echo '=== C build shell ===' && echo 'make / bear make / gcc -g *.c -o out'" Enter
    tmux split-window -t "$SESSION:build" -h -p 40 -c "$PROJECT_DIR"
    tmux send-keys -t "$SESSION:build.right" "echo 'gdb ./out'" Enter
    ;;

  cpp)
    # Left: cmake build | Right: run
    tmux send-keys -t "$SESSION:build" \
      "mkdir -p build && cd build && cmake .. -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && cmake --build ." Enter
    tmux split-window -t "$SESSION:build" -h -p 40 -c "$PROJECT_DIR"
    tmux send-keys -t "$SESSION:build.right" "echo 'Run: ./build/<binary>'" Enter
    ;;

  raylib)
    # Auto-build watcher using inotifywait if available
    tmux send-keys -t "$SESSION:build" \
      "mkdir -p build && cd build && cmake .. && cmake --build . && echo '--- Build OK ---'" Enter
    tmux split-window -t "$SESSION:build" -h -p 40 -c "$PROJECT_DIR"
    if command -v inotifywait &>/dev/null; then
      tmux send-keys -t "$SESSION:build.right" \
        "inotifywait -m -e close_write --include '.*\\.c$' -r . | while read; do cd build && cmake --build . && echo '--- Rebuilt ---'; done" Enter
    else
      tmux send-keys -t "$SESSION:build.right" "echo 'Run: ./build/<binary>'" Enter
    fi
    ;;

  react)
    # Left: pnpm dev server | Right: free
    if command -v pnpm &>/dev/null; then
      tmux send-keys -t "$SESSION:build" "pnpm install && pnpm dev" Enter
    elif command -v bun &>/dev/null; then
      tmux send-keys -t "$SESSION:build" "bun install && bun dev" Enter
    else
      tmux send-keys -t "$SESSION:build" "npm install && npm run dev" Enter
    fi
    tmux split-window -t "$SESSION:build" -h -p 35 -c "$PROJECT_DIR"
    tmux send-keys -t "$SESSION:build.right" "echo 'Browser: http://localhost:5173 (Vite) or :3000 (Next)'" Enter
    ;;

  esp32)
    # Left: platformio build/upload | Right: serial monitor
    tmux send-keys -t "$SESSION:build" \
      "echo '=== ESP32 Build ===' && echo 'pio run           # build' && echo 'pio run -t upload # flash' && echo 'pio device monitor # serial'" Enter
    tmux split-window -t "$SESSION:build" -h -p 45 -c "$PROJECT_DIR"
    tmux send-keys -t "$SESSION:build.right" \
      "echo '=== Serial Monitor ===' && echo 'pio device monitor --baud 115200'" Enter
    ;;

  *)
    err "Unknown environment: $ENV. Use: c | cpp | raylib | react | esp32"
    ;;
esac

# ─── Window 3: free shell ──────────────────────────────────────────────────
tmux new-window -t "$SESSION" -n "shell" -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION:shell" "echo '=== $ENV shell — $PROJECT_DIR ===' && zsh" Enter

# ─── attach ───────────────────────────────────────────────────────────────────
tmux select-window -t "$SESSION:code"
exec tmux attach-session -t "$SESSION"
