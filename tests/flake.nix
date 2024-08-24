{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    utils.url = "github:numtide/flake-utils";
    
    flatpak.url = "./..";
  };

  outputs = { self, nixpkgs, utils, flatpak }: utils.lib.eachDefaultSystem (system: let 
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    checks = {
      nixos = pkgs.callPackage ./nixos.nix { modules.flatpak = flatpak.nixosModules.declarative-flatpak; };
      # home-manager = pkgs.callPackage ./home-manager.nix { modules = { flatpak = flatpak.homeManagerModules.declarative-flatpak; home-manager = home-manager.nixosModules.home-manager; }; };
    };
  });
}