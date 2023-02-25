{
  description = "Global FHS environment for your daily computing needs.";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, utils }: utils.lib.eachDefaultSystem (system: let 
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nixos-shell
        jq
      ];
      shellHook = ''
        test-vm() {
          pushd test
          nix flake update --inputs-from ../
          nixos-shell --flake .#
          popd
        }
      '';
    };
  }) // {
    nixosModules = rec {
      declarative-flatpak = import ./modules/nixos;
      default = declarative-flatpak;
    };
  };
}