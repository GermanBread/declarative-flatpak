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
    devShells.default = let 
      script = pkgs.writeShellScriptBin "test-vm" ''
        timeout() {
          seq 1 5 | while read r; do
            echo x
            sleep 1
          done | awk '
          NR < 5 {
            printf "\r(press CTRL-C to cancel) Starting vm in %d\033[0K", 6 - NR
          }
          NR > 4 {
            printf "\rStarting vm in %d\033[0K", 6 - NR
          }
          END {
            printf "\rStarting vm\033[0K\n"
          }
          '
        }
        
        run-vm() {
          pushd test &>/dev/null
          nix flake update -v --inputs-from ../ 2>&1 | awk '
          {
            printf "\rUpdating flake"
          }
          END {
            printf "\rDone\033[0K\n"
          }
          '
          nixos-shell --flake .#
          popd &>/dev/null
        }
        
        test-vm() {
          run-vm
          timeout
          test-vm
        }

        test-vm
      '';
    in pkgs.mkShell {
      NIX_PATH="nixpkgs=${nixpkgs}";
      packages = with pkgs; [
        nixos-shell
        ncurses
        script
        gawk
        jq
      ];
      shellHook = ''
        echo -e "\033[31mRun test-vm to test your code\033[0m"
      '';
    };
  }) // {
    nixosModules = rec {
      declarative-flatpak = import ./src/modules/nixos.nix;
      default = declarative-flatpak;
    };
    homeManagerModules = rec {
      declarative-flatpak = import ./src/modules/home-manager.nix;
      default = declarative-flatpak;
    };
  };
}
