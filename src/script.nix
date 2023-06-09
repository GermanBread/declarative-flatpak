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
    printf "Network connected.\n"
  }
  '

  set -eu

  ${cfg.preInitCommand}

  if [ $(flatpak remotes ${builtins.toString extra-flatpak-flags} | tr -d '\n' | wc -l ) -eq 0 ]; then
    ${if cfg.remotes != null && builtins.length (builtins.attrValues cfg.remotes) > 0 then ''
    echo "No remotes have been found. Adding them now."

    ${builtins.toString (builtins.attrValues (builtins.mapAttrs (name: value: ''
    echo "Adding remote ${name} with URL ${value}"
    flatpak remote-add --if-not-exists ${builtins.toString extra-flatpak-flags} ${name} ${value}
    '') cfg.remotes))}
    '' else ''
    echo "No remotes installed nor declared in config. No idea what to do."
    exit 1
    ''}
  fi

  ${if cfg.packages != null then ''
  _affected_pkgs=$(flatpak list --columns=ref,origin ${builtins.toString extra-flatpak-flags} | while read r; do
    _unfiltered_id=$(awk '{print$1}' <<< $r)
    _remote=$(awk '{print$2}' <<< $r)
    _id=$(flatpak remote-info ${builtins.toString extra-flatpak-flags} $_remote $_unfiltered_id -r)

    case $_remote:$_id in
    ${builtins.toString (builtins.map (pkg: let
      split = builtins.split ":" pkg;
      unfiltered-id = builtins.elemAt split 2;
      remote = builtins.elemAt split 0;
    in ''
      ${remote}:$(flatpak remote-info ${builtins.toString extra-flatpak-flags} ${remote} ${unfiltered-id} -r))
        echo "${remote} $(flatpak remote-info ${builtins.toString extra-flatpak-flags} ${remote} ${unfiltered-id} -r)"
      ;;
    '') cfg.packages)}
      *)
        true
      ;;
    esac
  done)
  echo $_affected_pkgs

  while read remote ref; do
    case $remote:$ref in
    ${builtins.toString (builtins.map (pkg: let
      split = builtins.split ":" pkg;
      unfiltered-id = builtins.elemAt split 2;
      remote = builtins.elemAt split 0;
    in ''
      ${remote}:$(flatpak remote-info ${builtins.toString extra-flatpak-flags} ${remote} ${unfiltered-id} -r))
        true
      ;;
    '') cfg.packages)}
      *)
        echo "Removing $remote:$ref"
        flatpak uninstall ${builtins.toString extra-flatpak-flags} --noninteractive $ref
      ;;
    esac
  done <<<$_affected_pkgs

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
  for i in ${builtins.toString cfg.packages}; do
    _remote=$(echo $i | grep -Eo '^[a-zA-Z-]+:' | tr -d ':')
    _id=$(echo $i | grep -Eo '[a-zA-Z0-9._/-]+$')

    echo "Installing/Updating $_id from $_remote"
    flatpak install ${builtins.toString extra-flatpak-flags} --noninteractive --or-update $_remote $_id
  done
  '' else "true"}
  
  ${cfg.postInitCommand}
''