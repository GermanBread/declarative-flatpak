{
  description = "Declarative flatpaks.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }: utils.lib.eachDefaultSystem (system: let 
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    devShells.default = let 
      script = pkgs.writeShellScriptBin "run-vm" ''
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
        
        vm() {
          pushd vm &>/dev/null
          nix flake update -v --inputs-from ../ 2>&1 | awk '
          {
            printf "\rUpdating flake"
          }
          END {
            printf "\rDone\033[0K\n"
          }
          '
          nixos-shell --flake .# -I nixpkgs=${nixpkgs}
          popd &>/dev/null
        }
        
        run-interactive-vm() {
          vm
          timeout
          run-interactive-vm
        }

        run-interactive-vm
      '';
    in pkgs.mkShell {
      packages = with pkgs; [
        nixos-shell
        ncurses
        ostree
        script
        gawk
        jq
      ];
      shellHook = ''
        # ln -sfT $(pwd) /tmp/flatpak-module-dev
        
        echo -e "\033[31mRun run-vm to run your code\033[0m"
      '';
      NIX_PATH="nixpkgs=${nixpkgs}";
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