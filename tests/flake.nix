{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    utils.url = "github:numtide/flake-utils";
    
    flatpak.url = "./..";
  };

  outputs = { self, nixpkgs, utils, home-manager, flatpak }: utils.lib.eachDefaultSystem (system: let 
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