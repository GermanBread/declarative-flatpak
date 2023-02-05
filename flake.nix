{
  description = "Global FHS environment for your daily computing needs.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";
  in {
    nixosModules = rec {
      fhs-compat = throw "This flake output has been renamed to \"nixos-fhs\".\nPlease use the \"default\" output.";

      nixos-fhs = import ./module;
      default = nixos-fhs;
    };

    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nixos-shell
      ];
    };
  };
}
