# ~/.zshrc (Main Loader) — FAST & CLEAN

# 0) Salir rápido si no es interactivo
[[ $- != *i* ]] && return

# 1) Entorno temprano (sin spamear PATH)
source "$HOME/dotfiles/config/.zsh/modules/env.zsh"


# ================================
# Load Env
# ================================

export ZSH="$CONFIG_HOME/.oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"
ZSH_THEME="xiong-chiamiov-plus"

# Orden de plugins: lo más pesado al final
plugins=(
  git
  archlinux
  zoxide
  nvm               # lo haremos lazy más abajo
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# ================================
# Load & History
# ================================
HISTFILE=~/.config/.zsh/zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
autoload -Uz compinit
compinit -C

# Evita compfix lento de OMZ en algunos setups
export ZSH_DISABLE_COMPFIX=true

source $ZSH/oh-my-zsh.sh

# 3) Plugins externos ligeros
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# 4) zoxide (rápido)
eval "$(zoxide init zsh)"

# 5) NVM LAZY (autoload al primer uso)
#   No cargues nvm siempre; define wrappers que lo cargan solo cuando hace falta.
#
# source /usr/share/nvm/init-nvm.sh

_nvm_lazy_load() {
  unfunction node npm npx corepack yarn yarnpkg 2>/dev/null || true
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # usa tu init real; en tu caso tienes /usr/share/nvm/init-nvm.sh
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

# solo en TTY real + una vez por sesión
if [[ -t 1 && -z ${FASTFETCH_SHOWN+x} ]]; then
  FASTFETCH_SHOWN=1
  fastfetch -c "$HOME/.config/fastfetch/config-compact.jsonc"
fi

# ──────[ Modular Sources ]──────
source $DOTFILES_CONFIG/.zsh/modules/aliases.zsh
#source $DOTFILES_CONFIG/.zsh/modules/functions.zsh
source $DOTFILES_CONFIG/.zsh/modules/navigation.zsh
#source $DOTFILES_CONFIG/.zsh/modules/collectors.zsh
#source $DOTFILES_CONFIG/.zsh/modules/diagrams.zsh

