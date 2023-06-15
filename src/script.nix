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
    echo "No remotes installed nor declared in config. Refusing to do anything."
    exit 0
    ''}
  fi

  ${if cfg.packages != null then ''
  flatpak ${builtins.toString extra-flatpak-flags} list --app --columns=ref,origin | while read preref remote; do
    ref=$(flatpak ${builtins.toString extra-flatpak-flags} remote-info $remote $preref -r)

    case $remote:$ref in
    ${builtins.toString (builtins.map (pkg: let
      split = builtins.split ":" pkg;
      ref = builtins.elemAt split 2;
      remote = builtins.elemAt split 0;
    in ''
      ${remote}:$(flatpak ${builtins.toString extra-flatpak-flags} remote-info ${remote} ${ref} -r))
        true
      ;;
    '') cfg.packages)}
      *)
        echo "Removing $remote:$ref"
        flatpak ${builtins.toString extra-flatpak-flags} uninstall --noninteractive $ref
      ;;
    esac
  done

  # Now take care of runtimes
  flatpak ${builtins.toString extra-flatpak-flags} pin | while read ref; do
    echo "[WORKAROUND] Removing pinned runtime $ref"
    flatpak ${builtins.toString extra-flatpak-flags} uninstall --noninteractive $ref || true
    flatpak ${builtins.toString extra-flatpak-flags} pin --remove $ref || true
  done

  flatpak ${builtins.toString extra-flatpak-flags} uninstall --unused --noninteractive
  '' else "true"}
  
  ${if cfg.remotes != null then ''
  flatpak ${builtins.toString extra-flatpak-flags} remotes --columns=name | while read r; do
    echo "Forcefully removing remote $r"
    flatpak ${builtins.toString extra-flatpak-flags} remote-delete --force $r
  done
  ${builtins.toString (builtins.attrValues (builtins.mapAttrs (name: value: ''
  echo "Adding remote ${name} with URL ${value}"
  flatpak ${builtins.toString extra-flatpak-flags} remote-add ${name} ${value}
  '') cfg.remotes))}
  '' else "true"}

  ${if cfg.packages != null then ''
  for i in ${builtins.toString cfg.packages}; do
    _remote=$(echo $i | grep -Eo '^[a-zA-Z-]+:' | tr -d ':')
    _id=$(echo $i | grep -Eo '[a-zA-Z0-9._/-]+$')

    echo "Installing/Updating $_id from $_remote"
    flatpak ${builtins.toString extra-flatpak-flags} install --noninteractive --or-update $_remote $_id
  done
  '' else "true"}
  
  ${cfg.postInitCommand}
''
