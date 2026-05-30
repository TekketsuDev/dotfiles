{
  description = "tekketsu dotfiles — multi-profile home-manager";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url                      = "github:nix-community/home-manager";
      inputs.nixpkgs.follows   = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};

      # bootstrap.sh writes USER/HOME into .machine.conf; flake reads them via --impure
      user = builtins.getEnv "DOTFILES_USER";
      home = builtins.getEnv "DOTFILES_HOME";

      mkHome = profile: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./nix/profiles/${profile}.nix
          {
            home.username     = if user != "" then user else "tekketsu";
            home.homeDirectory = if home != "" then home else "/home/tekketsu";
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;
          }
        ];
      };
    in {
      homeConfigurations = {
        "arch-desktop" = mkHome "arch-desktop";
        "wsl"          = mkHome "wsl";
        "ct-minimal"   = mkHome "ct-minimal";
        "ubuntu"       = mkHome "ubuntu";
      };
    };
}
