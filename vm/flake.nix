{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    nixos-shell.url = "github:Mic92/nixos-shell";

    flatpak.url = "./..";
  };

  outputs = { self, nixpkgs, home-manager, flatpak, nixos-shell }: let
    system = "x86_64-linux";
    import-config = {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.vm = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem rec {
      pkgs = import nixpkgs import-config;
      inherit system;
      modules = [
        home-manager.nixosModules.home-manager
        nixos-shell.nixosModules.nixos-shell
        flatpak.nixosModules.default

        ./vm.nix
      ];
      specialArgs = {
        inherit flatpak;
      };
    };
  };
}
