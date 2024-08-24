{ mkShell, nixos-shell, ncurses, ostree, gawk, jq, callPackage, inputs }:

mkShell {
  packages = [
    nixos-shell
    ncurses
    ostree
    gawk
    jq

    (callPackage ./scripts/shell-vm.nix { inherit inputs; })
  ];
  shellHook = ''
    echo -e "\033[31mrun-shell\033[0m to run your code in nixos-shell"
  '';
  NIX_PATH="nixpkgs=${inputs.nixpkgs}";
}