{
  description = "Declarative flatpaks.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }@inputs: utils.lib.eachDefaultSystem (system: let 
    pkgs = import nixpkgs {
      inherit system;
    };
    inherit (pkgs) callPackage;
  in {
    devShells.default = callPackage ./shell.nix { inherit inputs; };
  }) // {
    nixosModules = rec {
      declarative-flatpak.imports = [ ./src/modules/nixos.nix ];
      default = declarative-flatpak;
    };
    homeManagerModules = rec {
      declarative-flatpak.imports = [ ./src/modules/home-manager.nix ];
      default = declarative-flatpak;
    };
  };
}