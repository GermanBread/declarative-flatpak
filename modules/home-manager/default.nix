{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.flatpak;

  script = pkgs.writeShellScript "setup-flatpaks" ''
    export PATH=${lib.makeBinPath (with pkgs; [ inetutils flatpak ])}:$PATH
    
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
    flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
    for i in ${builtins.toString cfg.packages}; do
      flatpak install --user --noninteractive --or-update $i
    done
    ${if cfg.postInitCommand != null then cfg.postInitCommand else "true"}
  '';
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
    systemd.user.services."manage-user-flatpaks" = {
      Unit = {
        After = [
          "network.target"
        ];
      };
      Install = {
        WantedBy = [
          "default.target"
        ];
      };
      Service = {
        ExecStart = "${script}";
      };
    };

    home.activation = {
      start-service = lib.hm.dag.entryAfter ["writeBoundary"] ''
        export PATH=${lib.makeBinPath (with pkgs; [ systemd ])}:$PATH

        $DRY_RUN_CMD systemctl --user start manage-user-flatpaks.service || true
      '';
    };

    xdg.enable = true;
  };
}