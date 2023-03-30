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
    remotes = mkOption {
      type = types.listOf types.str;
      default = [ "flathub https://flathub.org/repo/flathub.flatpakrepo" ];
      example = [ "repo-name https://example.org/repo.flatpakrepo" ];
      description = ''
        Flatpak remotes to add. Flathub is enabled by default.
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
    systemd.user.services."manage-user-flatpaks" = {
      after = [
        "basic.target"
      ];
      wantedBy = [
        "default.target"
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
        flatpak list --app --columns=app --user | while read r; do
          if ! elem $r "${builtins.toString cfg.packages}"; then
            flatpak uninstall --user --noninteractive $r
          fi
        done
        flatpak uninstall --user --unused --noninteractive
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        for i in ${builtins.toString cfg.packages}; do
          flatpak install --user --noninteractive --or-update $i
        done

        flatpak remotes --columns=name,url --user | while read r; do
          if ! elem $r "${builtins.toString cfg.remotes}"; then
            flatpak remote-delete --user $r
          fi
        done

        for i in ${builtins.toString cfg.remotes}; do
          flatpak remote-add --user --if-not-exists $i
        done
        ${if cfg.postInitCommand != null then cfg.postInitCommand else "true"}
      '';
    };

    xdg.enable = true;
  };
}