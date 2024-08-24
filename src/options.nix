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

      May take a very, very long time.
    '';
  };
  state-dir = mkOption {
    type = types.nullOr types.path;
    default = null;
    description = mdDoc ''
      Path where to place the flatpak generations

      By default will be:
      - /var/lib/flatpak-module (for NixOS)
      - ~/.local/state/flatpak-module (for home-manager)

      If left at default value, the corresponding directory will be picked.
    '';
  };
  target-dir = mkOption {
    type = types.nullOr types.path;
    default = null;
    description = mdDoc ''
      Path where to link the flatpak file to.
      
      By default will be:
      - /var/lib/flatpak (for NixOS)
      - ~/.local/share/flatpak (for home-manager)

      If left at default value, the corresponding directory will be picked.
    '';
  };
  # blockStartup = mkOption {
  #   type = types.bool;
  #   default = false;
  #   description = mdDoc ''
  #   '';
  # };
  preRemotesCommand = mkOption {
    type = types.nullOr types.str;
    default = "";
    description = mdDoc ''
      Which commands to run before remoted are configured.

      All essential variables have been initialized by now.
    '';
  };
  preInstallCommand = mkOption {
    type = types.nullOr types.str;
    default = "";
    description = mdDoc ''
      Which commands to run before refs are installed.
    '';
  };
  preDedupeCommand = mkOption {
    type = types.nullOr types.str;
    default = "";
    description = mdDoc ''
      Which commands to run before deduplication.

      Will run even if deduplication is disabled.
    '';
  };
  preSwitchCommand = mkOption {
    type = types.nullOr types.str;
    default = "";
    description = mdDoc ''
      Which commands to run before the generation is activated.
    '';
  };
  UNCHECKEDpostEverythingCommand = mkOption {
    type = types.nullOr types.str;
    default = "";
    description = mdDoc ''
      Which commands to run after the script completed execution.

      The error status of this command will NOT be checked. Errors that occur will NOT prevent the generation from being activated!
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
          type = types.nullOr (types.listOf types.str);
          default = null;
        };
        sockets = mkOption {
          type = types.nullOr (types.listOf types.str);
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
  enable-debug = mkEnableOption "Show more info.";
}