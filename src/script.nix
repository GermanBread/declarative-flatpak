{ config, lib, pkgs
, is-system-install
, extra-flatpak-flags ? [] }:

let
  fargs = if is-system-install then [ "--system" ] else [ "--user" ] ++ extra-flatpak-flags;
  cfg = config.services.flatpak;
in

pkgs.writeShellScript "setup-flatpaks" ''
  export PATH=${lib.makeBinPath (with pkgs; [ coreutils inetutils gnugrep flatpak gawk rsync ])}:$PATH
  
  until ping -c1 github.com &>/dev/null; do echo x; sleep 1; done | awk '
  {
    printf "Waiting for net (%d tries)\n", (NR)
  }
  END {
    printf "Network connected.\n"
  }
  '

  set -eu

  ${if is-system-install then ''
  export TMPDIR=/var/cache/flatpak-module
  '' else ''
  export TMPDIR=${config.xdg.cacheHome}/flatpak-module
  ''}
  rm -rf $TMPDIR || true
  mkdir -pm 700 $TMPDIR
  export FLATPAK_USER_DIR=$TMPDIR
  export FLATPAK_SYSTEM_DIR=$TMPDIR

  ${cfg.preInitCommand}

  if [ $(flatpak remotes ${builtins.toString fargs} | tr -d '\n' | wc -l ) -eq 0 ]; then
    ${if cfg.remotes != null && builtins.length (builtins.attrValues cfg.remotes) > 0 then ''
    echo "No remotes have been found. Adding them now."

    ${builtins.toString (builtins.attrValues (builtins.mapAttrs (name: value: ''
    echo "Adding remote ${name} with URL ${value}"
    flatpak remote-add --if-not-exists ${builtins.toString fargs} ${name} ${value}
    '') cfg.remotes))}
    '' else ''
    echo "No remotes installed nor declared in config. Refusing to do anything."
    exit 0
    ''}
  fi

  ${if cfg.packages != null then ''
  flatpak ${builtins.toString fargs} list --app --columns=ref,origin | while read preref remote; do
    ref=$(flatpak ${builtins.toString fargs} remote-info $remote $preref -r)

    case $remote:$ref in
    ${builtins.toString (builtins.map (pkg: let
      split = builtins.split ":" pkg;
      ref = builtins.elemAt split 2;
      remote = builtins.elemAt split 0;
    in ''
      ${remote}:$(flatpak ${builtins.toString fargs} remote-info ${remote} ${ref} -r))
        true
      ;;
    '') cfg.packages)}
      *)
        echo "Removing $remote:$ref"
        flatpak ${builtins.toString fargs} uninstall --noninteractive $ref
      ;;
    esac
  done

  # Now take care of runtimes
  flatpak ${builtins.toString fargs} pin | while read ref; do
    echo "[WORKAROUND] Removing pinned runtime $ref"
    flatpak ${builtins.toString fargs} uninstall --noninteractive $ref || true
    flatpak ${builtins.toString fargs} pin --remove $ref || true
  done

  flatpak ${builtins.toString fargs} uninstall --unused --noninteractive
  '' else "true"}
  
  ${if cfg.remotes != null then ''
  flatpak ${builtins.toString fargs} remotes --columns=name | while read r; do
    echo "Forcefully removing remote $r"
    flatpak ${builtins.toString fargs} remote-delete --force $r
  done
  ${builtins.toString (builtins.attrValues (builtins.mapAttrs (name: value: ''
  echo "Adding remote ${name} with URL ${value}"
  flatpak ${builtins.toString fargs} remote-add ${name} ${value}
  '') cfg.remotes))}
  '' else "true"}

  ${if cfg.packages != null then ''
  for i in ${builtins.toString cfg.packages}; do
    _remote=$(echo $i | grep -Eo '^[a-zA-Z-]+:' | tr -d ':')
    _id=$(echo $i | grep -Eo '[a-zA-Z0-9._/-]+$')

    echo "Installing/Updating $_id from $_remote"
    flatpak ${builtins.toString fargs} install --noninteractive --or-update $_remote $_id
  done
  '' else "true"}
  
  ${cfg.postInitCommand}

  echo "Applying changes"
  ${if is-system-install then ''
  rsync -a --delete $TMPDIR/ /var/lib/flatpak/
  chmod 755 /var/lib/flatpak/
  '' else ''
  rsync -a --delete $TMPDIR/ ${config.xdg.dataHome}/flatpak/
  chmod 755 ${config.xdg.dataHome}/flatpak/
  ''}

  rm -rf $TMPDIR || true
''