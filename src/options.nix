{ cfg }:

{ lib, pkgs, ... }:

let
  flatpak-types = callPackage ./lib/types/flatpak.nix {};
  
  inherit (pkgs) callPackage;
  inherit (lib) mkOption mdDoc mkEnableOption;
  inherit (lib.types) listOf bool nullOr attrsOf path str submodule anything;
  
  inherit (flatpak-types) fpkg fremote;
in {
  imports = [
    ./renames.nix
    ./removes.nix
  ];
  
  options.services.flatpak = {
    packages = mkOption {
      type = listOf fpkg;
      default = [];
      example = [ "flathub:org.kde.index//stable" "flathub-beta:org.kde.kdenlive//stable" ];
      description = mdDoc ''
        Which packages to install.

        As soon as you use more than one remote you should start prefixing them to avoid conflicts.
        The package must be prefixed with the remote's name and a colon.
      '';
    };
    enableModule = mkOption {
      type = bool;
      default = cfg.enable;
      description = mdDoc ''
        Enable/disable this module.
      '';
    };
    flatpak-dir = mkOption {
      type = nullOr path;
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
    #   type = bool;
    #   default = false;
    #   description = mdDoc ''
    #   '';
    # };
    preRemotesCommand = mkOption {
      type = nullOr str;
      default = "";
      description = mdDoc ''
        Which commands to run before remoted are configured.

        All essential variables have been initialized by now.
      '';
    };
    preInstallCommand = mkOption {
      type = nullOr str;
      default = "";
      description = mdDoc ''
        Which commands to run before refs are installed.
      '';
    };
    preSwitchCommand = mkOption {
      type = nullOr str;
      default = "";
      description = mdDoc ''
        Which commands to run before the generation is activated.
      '';
    };
    UNCHECKEDpostEverythingCommand = mkOption {
      type = nullOr str;
      default = "";
      description = mdDoc ''
        Which commands to run after the script completed execution.

        The error status of this command will NOT be checked. Errors that occur will NOT prevent the generation from being activated!
      '';
    };
    remotes = mkOption {
      type = fremote;
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
      type = attrsOf (submodule {
        options = {
          filesystems = mkOption {
            type = nullOr (listOf str);
            default = null;
          };
          sockets = mkOption {
            type = nullOr (listOf str);
            default = null;
          };
          environment = mkOption {
            type = nullOr (attrsOf anything);
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
    check-for-internet = mkOption {
      default = true;
      type = bool;
    };
    debug = mkEnableOption "Show more info.";
  };
}