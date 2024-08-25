{ mkShell, nixos-shell, ncurses, ostree, gawk, jq, callPackage, inputs }:

mkShell {
  packages = [
    nixos-shell
    ncurses
    ostree
    gawk
    jq

    (callPackage ./scripts/run-shell.nix { inherit inputs; })
    (callPackage ./scripts/run-tests.nix { })
  ];
  shellHook = ''
    echo -e "\033[31mrun-shell\033[0m to run your code in nixos-shell"
    echo -e "\033[31mrun-tests\033[0m to run nixos tests"
  '';
  NIX_PATH="nixpkgs=${inputs.nixpkgs}";
}