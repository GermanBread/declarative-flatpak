{ writeShellScriptBin }:

writeShellScriptBin "run-nixos" ''
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
    nixos-rebuild build-vm --flake .#nixos && \
      ./result/bin/run-*-vm
    rm result
    popd &>/dev/null
  }
  
  run-interactive-vm() {
    vm
    timeout
    run-interactive-vm
  }

  run-interactive-vm
''