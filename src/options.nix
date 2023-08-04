{ lib }:

with lib;

let
  custom-types = (import ./lib/types.nix { inherit lib; }).types;
in {
  packages = mkOption {
    type = types.listOf custom-types.fpkg;
    default = null;
    example = [ "flathub:org.kde.index//stable" "flathub-beta:org.kde.kdenlive//stable" ];
    description = ''
      Which packages to install.

      As soon as you use more than one remote, you should start prefixing them to avoid conflicts.
      The package must be prefixed with the remote's name and a colon.
    '';
  };
  preInitCommand = mkOption {
    type = types.nullOr types.str;
    default = "";
    description = ''
      Which command(s) to run before installation.

      If left at the default value, nothing will be done.
    '';
  };
  postInitCommand = mkOption {
    type = types.nullOr types.str;
    default = "";
    description = ''
      Which command(s) to run after installation.

      If left at the default value, nothing will be done.
    '';
  };
  remotes = mkOption {
    type = custom-types.fremote;
    default = {};
    example = ''
      services.flatpak.remotes = {
        "flathub" = "https://flathub.org/repo/flathub.flatpakrepo";
        "flathub-beta" = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      };
    '';
    description = ''
      Declare flatpak remotes.
    '';
  };
  # overrides = mkOption {
  #   type = types.anything;
  #   default = {};
  #   example = ''
  #     services.flatpak.overrides = {
  #       global = { # global is a reserved name
  #         filesystems = [
  #           "home"
  #           "!~/Games/Heroic"
  #         ];
  #       };
  #       "com.usebottles.bottles" = {
  #         filesystem = [
  #           "/var/lib/flatpak"
  #           "!home"
  #         ];
  #         environment = {
  #           "GTK_USE_PORTAL" = 1;
  #         }
  #       }
  #     }
  #   '';
  #   description = ''
  #     Overrides to apply.

  #     Only filesystem overrides supported right now.

  #     Paths prefixed with '!' will deny read permissions for that path.
  #     Paths are escaped.

  #     (home-manager only) If the value of a key is set to "use-system", the system's override will be used.

  #     This module removes all other overrides not declared explicitly.
  #     If left at the default (null), nothing will be done.
  #   '';
  # };
}