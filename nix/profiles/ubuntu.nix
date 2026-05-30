# Ubuntu server / general Linux — terminal + dev
{ ... }: {
  imports = [
    ../modules/common.nix
    ../modules/terminal.nix
    ../modules/dev.nix
  ];
}
