{ mkShell, nixos-shell, ncurses, ostree, gawk, jq, callPackage, inputs }:

mkShell {
  packages = [
    nixos-shell
    ncurses
    ostree
    gawk
    jq

    (callPackage ./scripts/nixos-native-vm.nix {})
    (callPackage ./scripts/nixos-shell-vm.nix { inherit inputs; })
  ];
  shellHook = ''
    echo -e "\033[31mrun-shell\033[0m to run your code in nixos-shell"
    echo -e "\033[31mrun-nxos\033[0m to run your code in a test nixos system"
  '';
  NIX_PATH="nixpkgs=${inputs.nixpkgs}";
}