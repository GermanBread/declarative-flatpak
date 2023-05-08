{ config, lib, pkgs
, extra-flatpak-flags ? [] }:

let
  cfg = config.services.flatpak;
in

pkgs.writeShellScript "setup-flatpaks" ''
  export PATH=${lib.makeBinPath (with pkgs; [ coreutils inetutils gnugrep flatpak gawk ])}:$PATH
  
  until ping -c1 github.com &>/dev/null; do echo x; sleep 1; done | awk '
  {
    printf "Waiting for net (%d tries)\n", (NR)
  }
  END {
    printf "OK\n"
  }
  '

  set -eu

  ${cfg.preInitCommand}

  ${if cfg.packages != null then ''
  _default_remote=$(flatpak remotes ${builtins.toString extra-flatpak-flags} --columns=name | head -n1)
  flatpak list --app --columns=ref,origin ${builtins.toString extra-flatpak-flags} | while read r; do
    _unfiltered_id=$(awk '{print$1}' <<< $r)
    _remote=$(awk '{print$2}' <<< $r)
    [ -z $_remote ] && _remote=$_default_remote
    _id=$(flatpak remote-info ${builtins.toString extra-flatpak-flags} $_remote $_unfiltered_id -r)

    case $_remote:$_id in
    ${builtins.toString (builtins.map (pkg: let
      split = builtins.split ":" pkg;
      unfiltered-id = if (builtins.length split) > 1 then builtins.elemAt split 2 else builtins.head split;
      remote = if (builtins.length split) > 1 then builtins.elemAt split 0 else "$_default_remote";
    in ''
      ${remote}:$(flatpak remote-info ${builtins.toString extra-flatpak-flags} ${remote} ${unfiltered-id} -r))
        echo "NOT removing $_remote:$_id"
      ;;
    '') cfg.packages)}
      *)
        echo "Removing $_remote:$_id"
        flatpak uninstall ${builtins.toString extra-flatpak-flags} --noninteractive $_id
      ;;
    esac
  done
  flatpak uninstall ${builtins.toString extra-flatpak-flags} --unused --noninteractive
  '' else "true"}
  
  ${if cfg.remotes != null then ''
  flatpak remotes ${builtins.toString extra-flatpak-flags} --columns=name | while read r; do
    echo "Forcefully removing remote $r"
    flatpak remote-delete ${builtins.toString extra-flatpak-flags} --force $r
  done
  ${builtins.toString (builtins.attrValues (builtins.mapAttrs (name: value: ''
  echo "Adding remote ${name} with URL ${value}"
  flatpak remote-add ${builtins.toString extra-flatpak-flags} ${name} ${value}
  '') cfg.remotes))}
  '' else "true"}

  ${if cfg.packages != null then ''
  _default_remote=$(flatpak remotes ${builtins.toString extra-flatpak-flags} --columns=name | head -n1)
  for i in ${builtins.toString cfg.packages}; do
    _remote=$(echo $i | grep -Eo '^[a-zA-Z-]+:' | tr -d ':')
    _id=$(echo $i | grep -Eo '[a-zA-Z0-9._/-]+$')
    [ -z $_remote ] && _remote=$_default_remote

    echo "Installing/Updating $_id from $_remote"
    flatpak install ${builtins.toString extra-flatpak-flags} --noninteractive --or-update $_remote $_id
  done
  '' else "true"}
  
  ${cfg.postInitCommand}
''