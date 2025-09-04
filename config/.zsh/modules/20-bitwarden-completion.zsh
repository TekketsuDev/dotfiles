# Autocompletado para Bitwarden CLI
fpath+=("${ZSH_CUSTOM:-$HOME/.config/zsh}/completions")
autoload -Uz compinit
# Solo compinit si aún no está cargado
(( $+functions[compdef] )) || compinit

