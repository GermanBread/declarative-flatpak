{ writeShellScriptBin, inputs }:

writeShellScriptBin "run-shell" ''
  pushd vm &>/dev/null
  nix flake lock --update-input flatpak
  nixos-shell --quiet --flake .#shell -I nixpkgs=${inputs.nixpkgs}
  popd &>/dev/null
''