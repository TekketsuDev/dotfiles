# Desktop-only packages — Arch laptop with Hyprland
# hyprland/waybar/wofi stay managed by pacman (Arch-specific)
{ pkgs, ... }: {
  home.packages = with pkgs; [
    kitty
    brave
    discord
    spotify
    obsidian
    obs-studio
    zathura
    zathura-plugins
    mpv
    imv
    wl-clipboard
    grim
    slurp
    swww
    noto-fonts-emoji
    font-awesome
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ]; })
  ];
}
