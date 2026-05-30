# ~/.zshrc
# ==================================

[[ $- != *i* ]] && return

# ───────────────────────────────
# 1) Time
# ───────────────────────────────
zmodload zsh/datetime
ZSH_START_TIME=$EPOCHREALTIME

# ───────────────────────────────
# 2) Entorno temprano 
# ───────────────────────────────
source "$HOME/dotfiles/config/.zsh/modules/env.zsh"

# ───────────────────────────────
# 3) Oh My Zsh 
# ───────────────────────────────
export ZSH="$CONFIG_HOME/.oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"


plugins=(
  git
  archlinux
  zoxide
)

# Evita compfix lento de OMZ
export ZSH_DISABLE_COMPFIX=true

# ───────────────────────────────
# 4) Historial + completions
# ───────────────────────────────
HISTFILE=~/.config/.zsh/zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory


if [[ ! -d /usr/share/zsh/vendor-completions ]]; then
  fpath=(${fpath:#/usr/share/zsh/vendor-completions})
fi

autoload -Uz compinit
compinit -C

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh

# ───────────────────────────────
# 5) Cargar OMZ
# ───────────────────────────────
PURE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/pure"

if [[ ! -d "$PURE_DIR" ]]; then
  command mkdir -p "${PURE_DIR:h}"
  command git clone --depth=1 https://github.com/sindresorhus/pure.git "$PURE_DIR" >/dev/null 2>&1
fi

fpath=("$PURE_DIR" $fpath)
autoload -U promptinit; promptinit
prompt pure

source "$ZSH/oh-my-zsh.sh"

# ───────────────────────────────
# 6) Plugins ligeros externos
# ───────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

eval "$(zoxide init zsh)"

# ───────────────────────────────
# 7) Autosuggestions & Highlighting
# ───────────────────────────────
autoload -Uz add-zsh-hook

_load_zsh_extras() {
  [[ -n ${ZSH_EXTRAS_LOADED+x} ]] && return
  ZSH_EXTRAS_LOADED=1

  ZSH_AUTOSUGGEST_USE_ASYNC=1
  ZSH_AUTOSUGGEST_MANUAL_REBIND=1

  source "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
bindkey '^[[200~' bracketed-paste
bindkey '^[[201~' bracketed-paste
}

add-zsh-hook precmd _load_zsh_extras

# ───────────────────────────────
# 8) NVM — Lazy real
# ───────────────────────────────
_nvm_lazy_load() {
  unfunction node npm npx corepack yarn yarnpkg 2>/dev/null || true
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

  if [ -f /usr/share/nvm/init-nvm.sh ]; then
    source /usr/share/nvm/init-nvm.sh
  elif [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
  fi
}

for _cmd in node npm npx corepack yarn yarnpkg; do
  eval "
  function $_cmd() {
    _nvm_lazy_load
    command $_cmd \"\$@\"
  }"
done



# ───────────────────────────────
# 9) Modular sources
# ───────────────────────────────
source "$DOTFILES_CONFIG/.zsh/modules/aliases.zsh"
# source "$DOTFILES_CONFIG/.zsh/modules/functions.zsh"
source "$DOTFILES_CONFIG/.zsh/modules/navigation.zsh"
# source "$DOTFILES_CONFIG/.zsh/modules/collectors.zsh"
# source "$DOTFILES_CONFIG/.zsh/modules/diagrams.zsh"

# ───────────────────────────────
# 10) Time Measure
# ───────────────────────────────
typeset -gF _ZSH_END_TIME=${EPOCHREALTIME}
typeset -gi ZSH_LOAD_MS=$(( (_ZSH_END_TIME - ZSH_START_TIME) * 1000 ))
# Guardar tiempo para fastfetch
printf "%s\n" "$ZSH_LOAD_MS" > "$XDG_RUNTIME_DIR/zsh-load-ms"
printf "%s\n" "$ZSH_LOAD_MS" > "$HOME/.cache/zsh-load-ms"
unset _ZSH_END_TIME

# ───────────────────────────────
# 11) Fastfetch
# ───────────────────────────────
if [[ -t 1 \
   && -z ${FASTFETCH_SHOWN+x} \
   && -z ${NVIM+x} \
   && -z ${VIM+x} \
   && -z ${TERM_PROGRAM+x} \
   ]]; then
  FASTFETCH_SHOWN=1
  fastfetch -c "$HOME/.config/fastfetch/config-compact.jsonc"
fi
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
