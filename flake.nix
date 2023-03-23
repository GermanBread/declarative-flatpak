{
  description = "Global FHS environment for your daily computing needs.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    utils.url = "github:numtide/flake-utils";
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
        run-vm() {
          pushd test
          nix flake update --inputs-from ../
          nixos-shell --flake .#
          popd
        }
        
        test-vm() {
          run-vm
          
          countdown=4
          echo -n '(press CTRL-C to cancel) Restarting vm in 5'
          while [ $countdown -gt 0 ]; do
            sleep 1
            echo -n ...$countdown
            countdown=$(($countdown - 1))
          done
          sleep 1
          echo ...0
          test-vm
        }

        init-hook() {
          countdown=4
          echo -n '(press CTRL-C to cancel) Starting vm in 5'
          while [ $countdown -gt 0 ]; do
            sleep 1
            echo -n ...$countdown
            countdown=$(($countdown - 1))
          done
          sleep 1
          echo ...0
          
          test-vm
        }

        init-hook
      '';
    };
  }) // {
    nixosModules = rec {
      declarative-flatpak = import ./modules/nixos;
      default = declarative-flatpak;
    };
    homeManagerModules = rec {
      declarative-flatpak = import ./modules/home-manager;
      default = declarative-flatpak;
    };
  };
}