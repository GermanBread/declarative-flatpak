{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.flatpak;
in

{
  options.services.flatpak = {
    packages = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "org.kde.index" "org.kde.kdenlive" ];
      description = ''
        Which packages to install.
      '';
    };
    preInitCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Which command(s) to run before installation.
      '';
    };
    postInitCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Which command(s) to run after installation.
      '';
    };
  };

  config = {
    systemd.services."manage-system-flatpaks" = {
      description = "Manage system-wide flatpaks";
      after = [
        "network-online.target"
      ];
      wantedBy = [
        "multi-user.target"
      ];
      path = with pkgs; [
        inetutils
        flatpak
      ];
      script = ''
        echo -n "Waiting for net."
        until ping -c1 github.com; do sleep 1; done
        echo "Ok."
        
        set -eu

        elem() {
          for i in $2; do
            [ $i = $1 ] && return 0
          done
          return 1
        }

        ${if cfg.preInitCommand != null then cfg.preInitCommand else "true"}
        flatpak list --app --columns=app --system | while read r; do
          if ! elem $r "${builtins.toString cfg.packages}"; then
            flatpak uninstall --system --noninteractive $r
          fi
        done
        flatpak uninstall --system --unused --noninteractive
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        for i in ${builtins.toString cfg.packages}; do
          flatpak install --system --noninteractive --or-update $i
        done
        ${if cfg.postInitCommand != null then cfg.postInitCommand else "true"}
      '';
    };

    xdg.portal.enable = true;
    services.flatpak.enable = true;
  };
}