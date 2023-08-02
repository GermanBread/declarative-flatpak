{ lib }:

with lib;

let
  regex = rec {
    fremote = "[A-Za-z0-9-]+";
    fpkg = "${fremote}:(runtime|app)\/[a-zA-Z0-9._-]+\/[0-9x_a-zA-Z-]*?\/[a-zA-Z0-9.-]+|(${fremote})?:.+\.flatpak(ref)?";
  };
in {
  types = {
    fpkg = mkOptionType {
      name = "fpgk";
      description = "flathub pkg";
      check = x: if builtins.match "^${regex.fpkg}$" x != null then true else throw ''
        Hi there. Your package "${x}" needs to follow the naming scheme:
          remote-name:type/package-name/arch/branch-name
        
        Replace "remote-name" with the remote name you want to install from.
        Replace "type" with either "runtime" or "app".
        Replace "arch" with the CPU architecture, may be omitted (but the slash needs to be kept)
        Replace "branch-name" with the name of the application branch.
      '';
    };
    fremote = mkOptionType {
      name = "fremote";
      description = "flathhub remote";
      check = x: if builtins.all (elm: builtins.match "^${regex.fremote}$" elm != null) (builtins.attrNames x) then true else throw ''
        Hello again. Your remote "${x}" contains unallowed symbols.
        It may only contain characters from a to z (upper and lowercase), numbers and hyphens (-).
      '';
    };
  };
}