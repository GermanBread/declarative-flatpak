{ lib }:

with lib;

let
  regex = rec {
    fremote = "[A-Za-z0-9-]+";
    fpkg = "${fremote}:[a-zA-Z0-9._-]+\/[0-9x_a-zA-Z-]*?\/[a-zA-Z0-9.-]+";
  };
in {
  types = {
    fpkg = mkOptionType {
      name = "fpgk";
      description = "flathub pkg";
      check = x: if builtins.match "^${regex.fpkg}$" x != null then true else throw ''
        Hi there. Your package "${x}" needs to follow the new naming scheme:
          remote-name:package-name/arch/branch-name
        or
          remote-name:package-name//branch-name
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