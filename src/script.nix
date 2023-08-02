{ config, lib, pkgs
, is-system-install
, extra-flatpak-flags ? [] }:

let
  fargs = if is-system-install then [ "--system" ] else [ "--user" ] ++ extra-flatpak-flags;
  cfg = config.services.flatpak;
in

pkgs.writeShellScript "setup-flatpaks" ''
  export PATH=${lib.makeBinPath (with pkgs; [ coreutils inetutils gnugrep flatpak gawk rsync ostree ])}:$PATH
  
  until ping -c1 github.com &>/dev/null; do echo x; sleep 1; done | awk '
  {
    printf "Waiting for net (%d tries)\n", (NR)
  }
  END {
    printf "Network connected.\n"
  }
  '

  nuke_remotes() {
    ${if cfg.remotes != null then ''
    flatpak ${builtins.toString fargs} remotes --columns=name | while read r; do
      echo "Forcefully removing remote $r"
      flatpak ${builtins.toString fargs} remote-delete --force $r
    done
    '' else "true"}
  }
  add_remotes() {
    ${if cfg.remotes != null then ''
    ${builtins.toString (builtins.attrValues (builtins.mapAttrs (name: value: ''
    echo "Adding remote ${name} with URL ${value}"
    flatpak ${builtins.toString fargs} remote-add --if-not-exists ${name} ${value}
    '') cfg.remotes))}
    '' else "true"}
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

  if [ $(flatpak remotes ${builtins.toString fargs} | tr -d '\n' | wc -l ) -eq 0 ]; then
    ${if cfg.remotes != null && builtins.length (builtins.attrValues cfg.remotes) > 0 then ''
    echo "No remotes have been found. Adding them now."
    '' else ''
    echo "No remotes installed nor declared in config. Refusing to do anything."
    exit 0
    ''}
  fi

  add_remotes

  ${if cfg.packages != null then ''
  for i in ${builtins.toString (builtins.filter (x: builtins.match ".+\.flatpak(ref)?$" x == null) cfg.packages)}; do
    _remote=$(echo $i | grep -Eo '^[a-zA-Z-]+:' | head -c-1)
    _id=$(echo $i | grep -Eo '[a-zA-Z0-9._/-]+$')

    flatpak ${builtins.toString fargs} install --noninteractive --no-auto-pin $_remote $_id
  done
  '' else "true"}
  
  ${cfg.postInitCommand}

  echo "Applying changes - configuring remotes"
  unset FLATPAK_USER_DIR FLATPAK_SYSTEM_DIR
  add_remotes
  export FLATPAK_USER_DIR=$TMPDIR
  export FLATPAK_SYSTEM_DIR=$TMPDIR

  # Unpin everything
  unset FLATPAK_USER_DIR FLATPAK_SYSTEM_DIR
  flatpak ${builtins.toString fargs} pin | while read r; do
    flatpak ${builtins.toString fargs} pin --remove $r
  done
  export FLATPAK_USER_DIR=$TMPDIR
  export FLATPAK_SYSTEM_DIR=$TMPDIR

  # Remove refs
  echo "Applying changes - uninstalling refs"
  unset FLATPAK_USER_DIR FLATPAK_SYSTEM_DIR
  flatpak ${builtins.toString fargs} list --app --columns=ref | while read r; do
    export FLATPAK_USER_DIR=$TMPDIR
    export FLATPAK_SYSTEM_DIR=$TMPDIR

    unset _pass
    export _pass=false
    flatpak ${builtins.toString fargs} list --app --columns=ref | while read f; do
      [ $r = $f ] && export _pass=true || true
    done
    
    unset FLATPAK_USER_DIR FLATPAK_SYSTEM_DIR
    
    $_pass || flatpak ${builtins.toString fargs} uninstall -y --noninteractive app/$r || true
  done

  unset FLATPAK_USER_DIR FLATPAK_SYSTEM_DIR
  flatpak ${builtins.toString fargs} list --runtime --columns=ref | while read r; do
    export FLATPAK_USER_DIR=$TMPDIR
    export FLATPAK_SYSTEM_DIR=$TMPDIR

    unset _pass
    export _pass=false
    flatpak ${builtins.toString fargs} list --runtime --columns=ref | while read f; do
      [ $r = $f ] && export _pass=true || true
    done
    
    unset FLATPAK_USER_DIR FLATPAK_SYSTEM_DIR
    
    $_pass || flatpak ${builtins.toString fargs} uninstall -y --noninteractive runtime/$r || true
  done

  flatpak uninstall --unused -y --noninteractive

  nuke_remotes
  add_remotes

  # Install refs
  echo "Applying changes - installing refs"
  export FLATPAK_USER_DIR=$TMPDIR
  export FLATPAK_SYSTEM_DIR=$TMPDIR
  flatpak ${builtins.toString fargs} list --runtime --columns=origin,ref | while read o r; do
    unset FLATPAK_USER_DIR FLATPAK_SYSTEM_DIR

    flatpak ${builtins.toString fargs} install -y --noninteractive --no-deps --no-related --no-pull --no-auto-pin $o runtime/$r

    export FLATPAK_USER_DIR=$TMPDIR
    export FLATPAK_SYSTEM_DIR=$TMPDIR
  done

  export FLATPAK_USER_DIR=$TMPDIR
  export FLATPAK_SYSTEM_DIR=$TMPDIR
  flatpak ${builtins.toString fargs} list --app --columns=origin,ref | while read o r; do
    unset FLATPAK_USER_DIR FLATPAK_SYSTEM_DIR

    flatpak ${builtins.toString fargs} install -y --noninteractive --no-deps --no-related --no-pull --no-auto-pin $o app/$r

    export FLATPAK_USER_DIR=$TMPDIR
    export FLATPAK_SYSTEM_DIR=$TMPDIR
  done

  echo "Installing out-of-tree refs"
  unset FLATPAK_USER_DIR FLATPAK_SYSTEM_DIR
  ${if cfg.packages != null then ''
  for i in ${builtins.toString (builtins.filter (x: builtins.match ":.+\.flatpak$" x != null) cfg.packages)}; do
    _id=$(echo $i | grep -Eo ':.+\.flatpak$' | tail -c+2)

    flatpak ${builtins.toString fargs} install --noninteractive --no-auto-pin $_id
  done
  for i in ${builtins.toString (builtins.filter (x: builtins.match ":.+\.flatpakref$" x != null) cfg.packages)}; do
    _remote=$(echo $i | grep -Eo '^[a-zA-Z-]+:' | head -c-1)
    _id=$(echo $i | grep -Eo ':.+\.flatpakref$' | tail -c+2)

    flatpak ${builtins.toString fargs} install --noninteractive --no-auto-pin $_remote $_id
  done
  '' else "true"}

  rm -rf $TMPDIR || true
''