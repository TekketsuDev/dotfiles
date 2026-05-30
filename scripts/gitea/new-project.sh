#!/usr/bin/env bash
# new-project.sh — create a Gitea repo and add it as remote
# Called automatically by the Claude Code PostToolUse hook on `git init`
# Can also be run manually: new-project.sh [dir] [--private]
set -euo pipefail

# ─── load config ─────────────────────────────────────────────────────────────
DOTFILES_DIR="${DOTFILES:-$HOME/dotfiles}"
MACHINE_CONF="$DOTFILES_DIR/.machine.conf"
[[ -f "$MACHINE_CONF" ]] && . "$MACHINE_CONF"

GITEA_URL="${GITEA_REMOTE_URL:-}"
GITEA_TOKEN="${GITEA_TOKEN:-}"
GITEA_USER="${GITEA_USER:-tekketsu}"
GITEA_HOST="${GITEA_HOST:-192.168.10.10}"
GITEA_HTTP_PORT="${GITEA_HTTP_PORT:-3000}"
GITEA_API="http://${GITEA_HOST}:${GITEA_HTTP_PORT}/api/v1"

# ─── parse args ──────────────────────────────────────────────────────────────
TARGET_DIR="${1:-$PWD}"
PRIVATE=false
[[ "${2:-}" == "--private" ]] && PRIVATE=true

# Resolve absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$PWD")"
REPO_NAME="$(basename "$TARGET_DIR")"

# ─── checks ──────────────────────────────────────────────────────────────────
if [[ -z "$GITEA_TOKEN" ]]; then
  echo '{"systemMessage":"⚠ Gitea: GITEA_TOKEN not set in .machine.conf — skipping auto-create"}'
  exit 0
fi

# Skip if remote already configured
if git -C "$TARGET_DIR" remote | grep -q "gitea\|origin" 2>/dev/null; then
  EXISTING=$(git -C "$TARGET_DIR" remote get-url origin 2>/dev/null || git -C "$TARGET_DIR" remote get-url gitea 2>/dev/null || echo "")
  if echo "$EXISTING" | grep -q "$GITEA_HOST"; then
    echo '{"suppressOutput":true}'
    exit 0
  fi
fi

# ─── create repo on Gitea ────────────────────────────────────────────────────
HTTP_STATUS=$(curl -s -o /tmp/gitea-create-resp.json -w "%{http_code}" \
  -X POST "${GITEA_API}/user/repos" \
  -H "Content-Type: application/json" \
  -H "Authorization: token ${GITEA_TOKEN}" \
  -d "{
    \"name\": \"${REPO_NAME}\",
    \"description\": \"Created by Claude Code\",
    \"private\": ${PRIVATE},
    \"auto_init\": false,
    \"default_branch\": \"main\"
  }" 2>/dev/null)

if [[ "$HTTP_STATUS" == "201" ]]; then
  SSH_URL="git@${GITEA_HOST}:${GITEA_USER}/${REPO_NAME}.git"
  # Add remote
  if git -C "$TARGET_DIR" remote | grep -q "^origin$" 2>/dev/null; then
    git -C "$TARGET_DIR" remote add gitea "$SSH_URL" 2>/dev/null || true
    REMOTE_NAME="gitea"
  else
    git -C "$TARGET_DIR" remote add origin "$SSH_URL" 2>/dev/null || true
    REMOTE_NAME="origin"
  fi
  echo "{\"systemMessage\":\"✓ Gitea repo created: ${REPO_NAME} → ${REMOTE_NAME} (${SSH_URL})\"}"

elif [[ "$HTTP_STATUS" == "409" ]]; then
  # Repo already exists — just add remote
  SSH_URL="git@${GITEA_HOST}:${GITEA_USER}/${REPO_NAME}.git"
  git -C "$TARGET_DIR" remote add gitea "$SSH_URL" 2>/dev/null || true
  echo "{\"systemMessage\":\"✓ Gitea repo ${REPO_NAME} already exists — remote added\"}"

else
  MSG=$(python3 -c "import json,sys; d=json.load(open('/tmp/gitea-create-resp.json')); print(d.get('message','unknown error'))" 2>/dev/null || echo "HTTP $HTTP_STATUS")
  echo "{\"systemMessage\":\"⚠ Gitea repo creation failed: ${MSG}\"}"
fi
