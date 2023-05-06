{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    home-manager.url = "github:nix-community/home-manager/release-22.11";
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
      pkgs = import nixpkgs {
        inherit system;
      };
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
