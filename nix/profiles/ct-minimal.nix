# Proxmox LXC container — minimal, just core shell tools
{ ... }: {
  imports = [
    ../modules/common.nix
    ../modules/terminal.nix
  ];
}
