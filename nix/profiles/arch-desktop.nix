# Arch Linux laptop — full desktop + all dev environments
{ ... }: {
  imports = [
    ../modules/common.nix
    ../modules/terminal.nix
    ../modules/desktop.nix
    ../modules/dev.nix
  ];
}
