{ lib, cfg, pkgs }:

with lib;

let
  custom-types = (import ./lib/types.nix { inherit lib; }).types;
  ini = pkgs.formats.ini {
    listToValue = lib.concatMapStringsSep ";" (lib.generators.mkValueStringDefault {});
  };
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
  # recycle-generation = mkOption {
  #   type = types.bool;
  #   default = false;
  #   description = mdDoc ''
  #     Instead of creating a new generation from scratch, try to re-use the old generation but just run `flatpak update` on it.
  #     This might significantly reduce bandwidth usage.

  #     **WARNING:** EXPERIMENTAL /// MIGHT BE RISKY TO USE /// PINNING IS BROKEN
  #   '';
  # };
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
    type = types.attrsOf (types.submodule ({config, ...}: {
      options = {
        filesystems = mkOption {
          type = with types; listOf (oneOf [str path]);
          default = [];
        };
        sockets = mkOption {
          type = with types; listOf str;
          default = [];
        };
        environment = mkOption {
          type = with types; attrsOf (oneOf [str path int]);
          default = {};
        };
        metadata = mkOption {
          type = with types; attrsOf (attrsOf anything);
          internal = true;
        };
        source = mkOption {
          type = types.path;
          internal = true;
        };
      };

      config.metadata = {
        Context = {inherit (config) filesystems sockets;};
        Environment = config.environment;
      };

      config.source = ini.generate "flatpak-override-${config._module.args.name}" config.metadata;
    }));
    default = {};
    example = ''
      services.flatpak.overrides = {
        "global" = {
          filesystems = [
            "home"
            "!~/Games/Heroic"
          ];
          environment = {
            "MOZ_ENABLE_WAYLAND" = "1";
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
