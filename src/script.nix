{ config, lib, pkgs
, is-system-install
, extra-flatpak-flags ? [] }:

let
  fargs = if is-system-install then [ "--system" ] else [ "--user" ] ++ extra-flatpak-flags;
  cfg = config.services.flatpak;
in

pkgs.writeShellScript "setup-flatpaks" ''
  export PATH=${lib.makeBinPath (with pkgs; [ coreutils inetutils gnugrep flatpak gawk rsync ostree mktemp ])}:$PATH
  
  until ping -c1 github.com &>/dev/null; do echo x; sleep 1; done | awk '
  {
    printf "Waiting for net (%d tries)\n", (NR)
  }
  END {
    printf "Network connected.\n"
  }
  '

  add_remotes() {
    ${builtins.toString (builtins.attrValues (builtins.mapAttrs (name: value: ''
    echo "Adding remote ${name} with URL ${value}"
    flatpak ${builtins.toString fargs} remote-add --if-not-exists ${name} ${value}
    '') cfg.remotes))}
  }

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

  ${if builtins.length (builtins.attrValues cfg.remotes) == 0 then ''
  echo "No remotes declared in config. Refusing to do anything."
  exit 0
  '' else ""}

  add_remotes

  for i in ${builtins.toString (builtins.filter (x: builtins.match ".+\.flatpak(ref)?$" x == null) cfg.packages)}; do
    _remote=$(echo $i | grep -Eo '^[a-zA-Z-]+:' | head -c-2)
    _id=$(echo $i | grep -Eo '[a-zA-Z0-9._/-]+$')

    flatpak ${builtins.toString fargs} install --noninteractive --no-auto-pin $_remote $_id
  done

  echo "Installing out-of-tree refs"
  for i in ${builtins.toString (builtins.filter (x: builtins.match ":.+\.flatpak$" x != null) cfg.packages)}; do
    _id=$(echo $i | grep -Eo ':.+\.flatpak$' | tail -c+2)

    flatpak ${builtins.toString fargs} install --noninteractive --no-auto-pin $_id
  done
  for i in ${builtins.toString (builtins.filter (x: builtins.match ":.+\.flatpakref$" x != null) cfg.packages)}; do
    _remote=$(echo $i | grep -Eo '^[a-zA-Z-]+:' | head -c-2)
    _id=$(echo $i | grep -Eo ':.+\.flatpakref$' | tail -c+2)

    flatpak ${builtins.toString fargs} install --noninteractive --no-auto-pin $_remote $_id
  done

  ${if is-system-install then ''
  [ -d /var/lib/flatpak ] && mv /var/lib/flatpak $(mktemp -d .flatpak-old.XXXXXX)
  chmod 755 $TMPDIR
  mv $TMPDIR /var/lib/flatpak
  '' else ''
  [ -d ${config.xdg.dataHome}/flatpak ] && mv ${config.xdg.dataHome}/flatpak $(mktemp -d .flatpak-old-$USER.XXXXXX)
  mv $TMPDIR ${config.xdg.dataHome}/flatpak
  ''}
  
  ${cfg.postInitCommand}
''