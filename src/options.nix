{ lib, cfg }:

with lib;

let
  custom-types = (import ./lib/types.nix { inherit lib; }).types;
in {
  packages = mkOption {
    type = types.listOf custom-types.fpkg;
    default = [];
    example = [ "flathub:org.kde.index//stable" "flathub-beta:org.kde.kdenlive//stable" ];
    description = mdDoc ''
      Which packages to install.

      As soon as you use more than one remote, you should start prefixing them to avoid conflicts.
      The package must be prefixed with the remote's name and a colon.
    '';
  };
  enableModule = mkOption {
    type = types.bool;
    default = cfg.enable;
    description = mdDoc ''
      Enable/disable this module.
    '';
  };
  deduplicate = mkOption {
    type = types.bool;
    default = true;
    description = mdDoc ''
      Try to save space by deduplicating generations.

      May take a very long time.
    '';
  };
  # blockStartup = mkOption {
  #   type = types.bool;
  #   default = false;
  #   description = mdDoc ''
  #   '';
  # };
  preInitCommand = mkOption {
    type = types.nullOr types.str;
    default = "";
    description = mdDoc ''
      Which command(s) to run before installation.

      If left at the default value, nothing will be done.
    '';
  };
  postInitCommand = mkOption {
    type = types.nullOr types.str;
    default = "";
    description = mdDoc ''
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
    description = mdDoc ''
      Declare flatpak remotes.
    '';
  };
  overrides = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        filesystems = mkOption {
          type = types.nullOr (types.listOf types.string);
          default = null;
        };
        sockets = mkOption {
          type = types.nullOr (types.listOf types.string);
          default = null;
        };
        environment = mkOption {
          type = types.nullOr (types.attrsOf types.anything);
          default = null;
        };
      };
    });
    default = {};
    example = ''
      services.flatpak.overrides = {
        "global" = {
          filesystems = [
            "home"
            "!~/Games/Heroic"
          ];
          environment = {
            "MOZ_ENABLE_WAYLAND" = 1;
          };
          sockets = [
            "!x11"
            "fallback-x11"
          ];
        };
      }
    '';
    description = mdDoc ''
      Overrides to apply.

      Paths prefixed with '!' will deny read permissions for that path, also applies to sockets.
      Paths may not be escaped.
    '';
  };
}