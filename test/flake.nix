{
  inputs = {
    nixos-shell.url = "github:Mic92/nixos-shell";

    flatpak.url = "./..";
  };

  outputs = { self, nixpkgs, flatpak, nixos-shell }: let
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
        nixos-shell.nixosModules.nixos-shell

        flatpak.nixosModules.default
        ./vm.nix
      ];
    };
  };
}
