{
  inputs = {
    # these need to match your system's versions
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager"; # /release-24.05
    nixos-shell.url = "github:Mic92/nixos-shell";

    nixos-shell.inputs."nixpkgs".follows = "nixpkgs";
    home-manager.inputs."nixpkgs".follows = "nixpkgs";

    flatpak.url = "./..";
  };

  outputs = { self, nixpkgs, home-manager, flatpak, nixos-shell }: let
    system = "x86_64-linux";
    import-config = {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.shell = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem {
      pkgs = import nixpkgs import-config;
      inherit system;
      modules = [
        home-manager.nixosModules.home-manager
        nixos-shell.nixosModules.nixos-shell
        flatpak.nixosModules.default

        ./shell.nix
        ./vm.nix
      ];
      specialArgs = {
        inherit flatpak;
      };
    };
    nixosConfigurations.nixos = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem {
      pkgs = import nixpkgs import-config;
      inherit system;
      modules = [
        home-manager.nixosModules.home-manager
        flatpak.nixosModules.default

        "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"

        ./nixos.nix
        ./vm.nix
      ];
      specialArgs = {
        inherit flatpak;
      };
    };
  };
}
