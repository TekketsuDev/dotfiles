# Terminal power-user tools — all non-desktop machines
{ pkgs, ... }: {
  home.packages = with pkgs; [
    fzf
    eza
    btop
    htop
    zoxide
    ripgrep
    fd
    tldr
    yazi
    fastfetch
    nmap
    traceroute
    inetutils
    jq
    yq-go
    unzip
    zip
    rsync
    tmux
    lsof
    strace
    inotify-tools
  ];
}
