#!/usr/bin/env bash
# setup-project-remote.sh — auto-add Gitea remote to any GitHub project
# Called by Claude Code SessionStart hook on every session open
# Safe to run multiple times (idempotent)
set -euo pipefail

# ─── load config ─────────────────────────────────────────────────────────────
DOTFILES_DIR="${DOTFILES:-$HOME/dotfiles}"
[[ -f "$DOTFILES_DIR/.machine.conf" ]] && . "$DOTFILES_DIR/.machine.conf"

GITEA_TOKEN="${GITEA_TOKEN:-}"
GITEA_HOST="${GITEA_HOST:-192.168.10.10}"
GITEA_HTTP_PORT="${GITEA_HTTP_PORT:-3000}"
GITEA_USER="${GITEA_USER:-tekketsu}"
GITEA_API="http://${GITEA_HOST}:${GITEA_HTTP_PORT}/api/v1"

# ─── not a git repo → silent exit ────────────────────────────────────────────
git rev-parse --git-dir &>/dev/null || exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
REPO_NAME=$(basename "$REPO_ROOT")

# ─── already has gitea remote → silent exit ──────────────────────────────────
if git remote | grep -q "^gitea$"; then
  exit 0
fi

# ─── get origin URL ──────────────────────────────────────────────────────────
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
[[ -z "$ORIGIN_URL" ]] && exit 0

# Only act on GitHub remotes
echo "$ORIGIN_URL" | grep -qi "github.com" || exit 0

# ─── check if repo exists in Gitea ───────────────────────────────────────────
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  "${GITEA_API}/repos/${GITEA_USER}/${REPO_NAME}" \
  -H "Authorization: token ${GITEA_TOKEN}" 2>/dev/null)

GITEA_SSH="git@${GITEA_HOST}:${GITEA_USER}/${REPO_NAME}.git"

if [[ "$HTTP_STATUS" == "200" ]]; then
  # Repo exists in Gitea — check if it's a mirror (read-only)
  MIRROR=$(curl -s "${GITEA_API}/repos/${GITEA_USER}/${REPO_NAME}" \
    -H "Authorization: token ${GITEA_TOKEN}" 2>/dev/null | \
    python3 -c "import json,sys; print(json.load(sys.stdin).get('mirror', False))" 2>/dev/null)

  git remote add gitea "$GITEA_SSH" 2>/dev/null

  if [[ "$MIRROR" == "True" ]]; then
    echo "{\"systemMessage\":\"🔗 Gitea remote added for ${REPO_NAME} (mirror — run 'dev gitea-unmirror' to enable push)\"}"
  else
    echo "{\"systemMessage\":\"🔗 Gitea remote added for ${REPO_NAME} → ${GITEA_SSH}\"}"
  fi

elif [[ "$HTTP_STATUS" == "404" ]]; then
  # Doesn't exist yet — create it
  PRIVATE=$(curl -s "https://api.github.com/repos/TekketsuDev/${REPO_NAME}" \
    -H "Authorization: token $(gh auth token 2>/dev/null)" 2>/dev/null | \
    python3 -c "import json,sys; print(json.load(sys.stdin).get('private', False))" 2>/dev/null || echo "false")

  HTTP_CREATE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "${GITEA_API}/user/repos" \
    -H "Content-Type: application/json" \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -d "{\"name\":\"${REPO_NAME}\",\"private\":${PRIVATE},\"auto_init\":false}" 2>/dev/null)

  if [[ "$HTTP_CREATE" == "201" ]]; then
    git remote add gitea "$GITEA_SSH" 2>/dev/null
    echo "{\"systemMessage\":\"✓ Gitea repo created + remote added for ${REPO_NAME}\"}"
  fi
fi
