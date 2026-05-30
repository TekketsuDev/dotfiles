# WSL2 — terminal + dev, no desktop packages
{ ... }: {
  imports = [
    ../modules/common.nix
    ../modules/terminal.nix
    ../modules/dev.nix
  ];
}
