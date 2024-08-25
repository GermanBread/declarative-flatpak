{ writeShellScriptBin, inputs }:

writeShellScriptBin "run-shell" ''
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
    nix flake lock --update-input flatpak 2>&1
    nixos-shell --flake .#shell -I nixpkgs=${inputs.nixpkgs}
    popd &>/dev/null
  }
  
  run-interactive-vm() {
    vm
    timeout
    run-interactive-vm
  }

  run-interactive-vm
''