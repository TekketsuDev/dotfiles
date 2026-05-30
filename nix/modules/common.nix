# All machines — minimal shell + core tools
{ pkgs, ... }: {
  home.packages = with pkgs; [
    git
    neovim
    tmux
    stow
    zsh
    curl
    wget
    tree
    openssh
    gnupg
  ];
}
