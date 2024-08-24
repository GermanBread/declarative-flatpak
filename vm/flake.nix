{
  inputs = {
    # these need to match your system's versions
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager"; # /release-24.05
    nixos-shell.url = "github:Mic92/nixos-shell";

    nixos-shell.inputs."nixpkgs".follows = "nixpkgs";
    home-manager.inputs."nixpkgs".follows = "nixpkgs";

    flatpak.url = "./.."; # "github:GermanBread/declarative-flatpak/stable"; # for testing purposes
  };

  outputs = { self, nixpkgs, home-manager, flatpak, nixos-shell }: let
    system = "x86_64-linux";
  in {
    nixosConfigurations.shell = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        { nixpkgs.config.allowUnfree = true; }

        home-manager.nixosModules.home-manager
        nixos-shell.nixosModules.nixos-shell
        flatpak.nixosModules.default

        ./vm.nix
        ./hm.nix
      ];
      specialArgs = {
        inherit flatpak;
      };
    };
  };
}
