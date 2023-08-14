{ config, lib, pkgs
, is-system-install
, extra-flatpak-flags ? [] }:

let
  fargs = if is-system-install then [ "--system" ] else [ "--user" ] ++ extra-flatpak-flags;
  cfg = config.services.flatpak;
  regex = (import ./lib/types.nix { inherit lib; }).regex;
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

  set -eu

  ${if is-system-install then ''
  export TMPDIR=/var/cache/flatpak-module
  '' else ''
  export TMPDIR=${config.xdg.cacheHome}/flatpak-module
  ''}
  rm -rf $TMPDIR
  mkdir -pm 700 $TMPDIR
  export FLATPAK_USER_DIR=$TMPDIR
  export FLATPAK_SYSTEM_DIR=$TMPDIR

  ${cfg.preInitCommand}

  ${if builtins.length (builtins.attrValues cfg.remotes) == 0 then ''
  echo "No remotes declared in config. Refusing to do anything."
  exit 0
  '' else builtins.toString (builtins.attrValues (builtins.mapAttrs (name: value: ''
  echo "Adding remote ${name} with URL ${value}"
  flatpak ${builtins.toString fargs} remote-add --if-not-exists ${name} ${value}
  '') cfg.remotes))}

  for i in ${builtins.toString (builtins.filter (x: builtins.match ".+${regex.ffile}$" x == null) cfg.packages)}; do
    _remote=$(grep -Eo '^${regex.fremote}' <<< $i)
    _id=$(grep -Eo '${regex.ftype}\/${regex.fref}\/${regex.farch}\/${regex.fbranch}(:${regex.fcommit})?' <<< $i)
    _commit=$(grep -Eo ':${regex.fcommit}$' <<< $_id) || true
    if [ -n "$_commit" ]; then
      _commit=$(tail -c-$(($(wc -c <<< $_commit) - 1)) <<< $_commit)
      _id=$(head -c-$(($(wc -c <<< $_commit) + 1)) <<< $_id)
    fi

    # echo F $i
    # echo R $_remote
    # echo C $_commit
    # echo I $_id

    flatpak ${builtins.toString fargs} install --noninteractive --no-auto-pin $_remote $_id

    if [ -n "$_commit" ]; then
      flatpak update --commit="$_commit" $_id || echo "failed to update to commit \"$_commit\". Check if the commit is long enough"
    fi
  done

  echo "Installing out-of-tree refs"
  for i in ${builtins.toString (builtins.filter (x: builtins.match ":.+\.flatpak$" x != null) cfg.packages)}; do
    _id=$(grep -Eo ':.+\.flatpak$' <<< $i | tail -c+2)

    flatpak ${builtins.toString fargs} install --noninteractive --no-auto-pin $_id
  done
  for i in ${builtins.toString (builtins.filter (x: builtins.match ":.+\.flatpakref$" x != null) cfg.packages)}; do
    _remote=$(grep -Eo '^${regex.fremote}:' <<< $i | head -c-2)
    _id=$(grep -Eo ':.+\.flatpakref$' <<< $i | tail -c+2)

    flatpak ${builtins.toString fargs} install --noninteractive --no-auto-pin $_remote $_id
  done

  # install overrides
  mkdir -p $TMPDIR/overrides
  ${builtins.concatStringsSep "\n" (builtins.map (overridename: let
    overridevalue = cfg.overrides.${overridename};
  in ''
  echo "Installing override for ${overridename}"
  cat << EOF >$TMPDIR/overrides/${overridename}
  
  [Context]
  ${if overridevalue.filesystems != null then ''
  filesystems=${builtins.concatStringsSep ";" overridevalue.filesystems}
  '' else ""}
  ${if overridevalue.sockets != null then ''
  sockets=${builtins.concatStringsSep ";" overridevalue.sockets}
  '' else ""}

  [Environment]
  ${if overridevalue.environment != null then ''
  ${builtins.concatStringsSep ";" (builtins.map (envname: let
    envvalue = overridevalue.environment.${envname};
  in ''
  ${envname}=${builtins.toString envvalue}
  '') (builtins.attrNames (overridevalue.environment or [])))}
  '' else ""}

  EOF
  '') (builtins.attrNames cfg.overrides))}

  ${if is-system-install then ''
  if [ -d /var/lib/flatpak ]; then
    for i in db; do
      rm -rf $TMPDIR/$i
      [ -d /var/lib/flatpak/$i ] && cp -a /var/lib/flatpak/$i $TMPDIR/$i
    done
    mv /var/lib/flatpak $(mktemp -d flatpak-module-system-old.XXXXXX -p /tmp)
  fi
  chmod 755 $TMPDIR
  mv $TMPDIR /var/lib/flatpak
  '' else ''
  if [ -d ${config.xdg.dataHome}/flatpak ]; then
    for i in db; do
      rm -rf $TMPDIR/$i
      [ -d ${config.xdg.dataHome}/flatpak/$i ] && cp -a ${config.xdg.dataHome}/flatpak/$i $TMPDIR/$i
    done
    mv ${config.xdg.dataHome}/flatpak $(mktemp -d flatpak-module-user-old-$USER.XXXXXX -p /tmp)
  fi
  mv $TMPDIR ${config.xdg.dataHome}/flatpak
  ''}
  
  ${cfg.postInitCommand}
''