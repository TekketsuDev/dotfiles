#!/usr/bin/env bash
set -euo pipefail

# dev.sh — gestor de dotfiles (stow+git) portable
# Subcomandos:
#   dev preview         # ver qué symlinks crearía (no modifica nada)
#   dev apply           # aplica (prioriza repo, hace backups de conflictos)
#   dev adopt           # adopta (mueve desde HOME al repo) + aplica
#   dev sync            # git add/commit/push (y pull si está limpio)
#   dev edit-ignore     # abre config/.stow-local-ignore en $EDITOR
#   dev install         # instala el launcher 'dev' en ~/.local/bin
#
# Variables útiles:
#   PACKAGES="config home"   # por defecto autodetecta existentes
#   BRANCH=main              # rama git
#   MESSAGE="..."            # mensaje commit
#   EDITOR=...               # usado por edit-ignore

export LC_ALL=C

# --- localizar repo (aunque se invoque por PATH) ---
SCRIPT_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")" 2>/dev/null || SCRIPT_PATH="${BASH_SOURCE[0]}"
REPO_ROOT="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
[[ -d "$REPO_ROOT/.git" ]] || { echo "[dev] ERROR: no se encontró .git en $REPO_ROOT"; exit 1; }

# --- config ---
BRANCH="${BRANCH:-main}"
MESSAGE="${MESSAGE:-chore(dotfiles): auto-sync $(hostname) $(date -Iseconds)}"
declare -A MAP_DEFAULT=( ["home"]="$HOME" ["config"]="$HOME/.config" ["local"]="$HOME/.local" )

# --- utils ---
log(){ printf "[dev] %s\n" "$*"; }
err(){ printf "[dev][ERROR] %s\n" "$*\n" >&2; }
need(){ command -v "$1" >/dev/null 2>&1 || { err "Falta comando: $1"; exit 1; }; }
git_dirty(){ git -C "$REPO_ROOT" status --porcelain | grep -q .; }

need stow; need git

# --- paquetes activos ---
declare -A PKG2TARGET=()
detect_packages() {
  local list=()
  if [[ -n "${PACKAGES:-}" ]]; then
    # usar exactamente los indicados si existen
    for p in $PACKAGES; do [[ -d "$REPO_ROOT/$p" ]] && list+=("$p"); done
  else
    # autodetect por defecto (si existe el dir)
    for p in "${!MAP_DEFAULT[@]}"; do [[ -d "$REPO_ROOT/$p" ]] && list+=("$p"); done
  fi
  if [[ ${#list[@]} -eq 0 ]]; then
    err "No hay paquetes (crea p.ej. '$REPO_ROOT/config')."
    exit 1
  fi
  # construir mapa
  for p in "${list[@]}"; do PKG2TARGET["$p"]="${MAP_DEFAULT[$p]:-$HOME}"; done
}

# --- prune symlinks rotos que apuntaban al repo ---
prune_targets(){
  declare -A seen=()
  for p in "${!PKG2TARGET[@]}"; do seen["${PKG2TARGET[$p]}"]=1; done
  for tgt in "${!seen[@]}"; do
    [[ -d "$tgt" ]] || continue
    log "prune: $tgt"
    mapfile -t LINKS < <(find "$tgt" -xtype l -maxdepth 6 2>/dev/null || true)
    for link in "${LINKS[@]:-}"; do
      dest="$(readlink -f -- "$link" 2>/dev/null || true)"
      [[ -z "${dest:-}" ]] && continue
      if [[ ! -e "$dest" && "$dest" == "$REPO_ROOT"* ]]; then
        log " - rm ${link#$HOME/}"
        rm -f -- "$link"
      fi
    done
  done
}

# --- pre-clean (prioriza repo): backup y elimina bloqueadores ---
backup_and_remove(){
  local path="$1"
  [[ -e "$path" || -L "$path" ]] || return 0
  local ts rel dir
  ts="$(date +%Y%m%d-%H%M%S)"
  rel="${path#$HOME/}"
  dir="$HOME/.stow_backup/$ts/$(dirname "$rel")"
  mkdir -p "$dir"
  log "   backup: ~/${rel}"
  mv -f -- "$path" "$dir/" 2>/dev/null || { cp -a -- "$path" "$dir/"; rm -rf -- "$path"; }
}

preclean_pkg(){
  local pkg="$1" tgt="$2"
  mkdir -p "$tgt"
  log "pre-clean: pkg=$pkg target=$tgt"
  local out
  out="$(stow -nv --no-folding -t "$tgt" -d "$REPO_ROOT" "$pkg" 2>&1 || true)"
  mapfile -t victims < <(
    printf "%s\n" "$out" | awk '
      /existing target / { for (i=1;i<=NF;i++) if ($i=="target") print $(i+1) }
      /CONFLICT/        { for (i=1;i<=NF;i++) if ($i=="CONFLICT:") print $(i+1) }
    ' | sort -u
  )
  if [[ "${#victims[@]}" -gt 0 ]]; then
    for rel in "${victims[@]}"; do [[ -n "$rel" ]] && backup_and_remove "$tgt/$rel"; done
  fi
  echo "$out"
}

# --- acciones stow ---
do_preview(){
  detect_packages
  log "packages:"
  for p in "${!PKG2TARGET[@]}"; do printf "  - %s -> %s\n" "$p" "${PKG2TARGET[$p]}"; done
  prune_targets
  for p in "${!PKG2TARGET[@]}"; do
    log "preview: $p -> ${PKG2TARGET[$p]}"
    stow -nv --no-folding -t "${PKG2TARGET[$p]}" -d "$REPO_ROOT" "$p" || true
  done
}

do_adopt(){
  detect_packages
  log "packages:"
  for p in "${!PKG2TARGET[@]}"; do printf "  - %s -> %s\n" "$p" "${PKG2TARGET[$p]}"; done
  prune_targets
  for p in "${!PKG2TARGET[@]}"; do
    log "adopt: $p -> ${PKG2TARGET[$p]}"
    stow --adopt --no-folding -t "${PKG2TARGET[$p]}" -d "$REPO_ROOT" "$p" || true
    # después restow convergente
    stow -D -t "${PKG2TARGET[$p]}" -d "$REPO_ROOT" "$p" || true
    stow --no-folding -t "${PKG2TARGET[$p]}" -d "$REPO_ROOT" "$p"
  done
}

do_sync(){
  # pull si limpio
  log "sync: origin/$BRANCH"
  git -C "$REPO_ROOT" fetch --all --prune || true
  if ! git_dirty; then
    git -C "$REPO_ROOT" pull --rebase origin "$BRANCH" || true
  else
    log "repo sucio -> skip pull"
  fi
  # add/commit/push
  git -C "$REPO_ROOT" add -A
  if git_dirty; then
    git -C "$REPO_ROOT" commit -m "$MESSAGE"
    git -C "$REPO_ROOT" push -u origin "$BRANCH"
  else
    log "no changes."
  fi
}
do_apply(){
  # Modo “en vivo”: NO usa -D. Hace preclean selectivo y luego --restow + recargas.
  detect_packages
  log "packages (live-safe):"
  for p in "${!PKG2TARGET[@]}"; do printf "  - %s -> %s\n" "$p" "${PKG2TARGET[$p]}"; done
  prune_targets

  # 1) Preclean (backup y quita solo bloqueadores reales)
  for p in "${!PKG2TARGET[@]}"; do
    preclean_pkg "$p" "${PKG2TARGET[$p]}" >/dev/null || true
  done

  # 2) Restow sin -D (evita el “corte”)
  for p in "${!PKG2TARGET[@]}"; do
    log "stow: --restow (live) $p"
    stow --restow --no-folding -t "${PKG2TARGET[$p]}" -d "$REPO_ROOT" "$p"
  done

  # 3) Recargas suaves si existen
  if command -v hyprctl >/dev/null 2>&1; then
    log "reload: hyprctl reload"
    hyprctl reload || true
  fi
  if pgrep -x waybar >/dev/null 2>&1; then
    log "reload: waybar SIGUSR2"
    pkill -SIGUSR2 waybar || true
  fi
  if pgrep -x mako >/dev/null 2>&1; then
    log "reload: mako reload"
    pkill -HUP mako || true
  fi
  # Si estás en zsh interactivo, re-sourcéo
  if [[ -n "${ZSH_VERSION:-}" ]] && [[ -r "$HOME/.config/.zsh/.zshrc" ]]; then
    log "reload: source ~/.config/.zsh/.zshrc"
    source "$HOME/.config/.zsh/.zshrc" || true
  fi
}

do_edit_ignore(){
  mkdir -p "$REPO_ROOT/config"
  : > /dev/null  # no-op
  ${EDITOR:-vi} "$REPO_ROOT/config/.stow-local-ignore"
}

do_install(){
  local dst="$HOME/.local/bin"
  mkdir -p "$dst"
  ln -sf "$REPO_ROOT/dev.sh" "$dst/dev"
  log "instalado: $dst/dev"
  # asegurar PATH para zsh/bash
  if [[ -n "${ZSH_VERSION:-}" || -n "${BASH_VERSION:-}" ]]; then
    local shellrc
    if [[ -n "${ZSH_VERSION:-}" ]]; then shellrc="$HOME/.zshrc"; else shellrc="$HOME/.bashrc"; fi
    grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$shellrc" 2>/dev/null || \
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shellrc"
    log "Añadido ~/.local/bin al PATH en $shellrc (si no estaba). Abre una nueva shell."
  else
    log "Añade ~/.local/bin al PATH de tu shell si aún no lo está."
  fi
}

usage(){
  cat <<EOF
Uso: dev <preview|apply|adopt|sync|edit-ignore|install>

  preview       Muestra qué symlinks crearía (no modifica nada)
  apply         Aplica stow priorizando el repo (hace backup de conflictos)
  adopt         Adopta desde HOME al repo y aplica
  sync          git add/commit/push (pull si repo limpio)
  edit-ignore   Abre config/.stow-local-ignore en \$EDITOR
  install       Crea el launcher 'dev' en ~/.local/bin y asegura PATH

Variables:
  PACKAGES="config home"   # limita paquetes a procesar
  BRANCH=main              # rama git
  MESSAGE="..."            # mensaje de commit

Ejemplos:
  dev preview
  dev apply
  PACKAGES="config" dev adopt
  MESSAGE="feat: update dotfiles" dev sync
EOF
}

cmd="${1:-}"
case "$cmd" in
  preview) shift; do_preview "$@";;
  apply) shift; do_apply "$@";;
  adopt) shift; do_adopt "$@";;
  sync) shift; do_sync "$@";;
  edit-ignore) shift; do_edit_ignore "$@";;
  install) shift; do_install "$@";;
  apply-live) shift; do_apply_live "$@";;

  ""|-h|--help|help) usage;;
  *) err "Comando desconocido: $cmd"; usage; exit 1;;
esac

