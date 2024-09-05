{ lib, callPackage }:

let
  inherit (lib) mkOptionType;
  regexes = import ../regexes.nix;
in {
  package = mkOptionType {
    name = "package";
    description = "flathub package definition";
    check = x: if builtins.match "^${regexes.fpkg}$" x != null then true else throw ''
      Hi there. Your package "${x}" needs to follow the naming scheme:
        remote-name:type/package-name/arch/branch-name:commit
      
      Replace "remote-name" with the remote name you want to install from.
      Replace "type" with either "runtime" or "app".
      Replace "arch" with the CPU architecture, may be omitted (but the slash needs to be kept)
      Replace "branch-name" with the name of the application branch.
      Replace "commit" with a given commit, or leave it out entirely, must be exactly 64 characters long
    '';
  };
  remote = mkOptionType {
    name = "remote";
    description = "flathub remote";
    check = x: if builtins.all (elm: builtins.match "^${regexes.fremote}$" elm != null) (builtins.attrNames x) then true else throw ''
      Hello again. Your remote "${x}" contains unallowed symbols.
      It may only contain characters from a to z (upper and lowercase), numbers and hyphens (-).
    '';
  };
}