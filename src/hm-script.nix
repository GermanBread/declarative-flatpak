{ config, lib, pkgs }:

let
  cfg = config.services.flatpak;
in

{
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
}