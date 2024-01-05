{ config, lib, pkgs
, is-system-install
, extra-flatpak-flags ? [] }:

let
  fargs = if is-system-install then [ "--system" ] else [ "--user" ] ++ extra-flatpak-flags;
  cfg = config.services.flatpak;
  regex = (import ./lib/types.nix { inherit lib; }).regex;
  filecfg = pkgs.writeText "flatpak-gen-config" (builtins.toJSON {
    inherit (cfg) overrides packages preInitCommand postInitCommand remotes state-dir target-dir;
  });
in

pkgs.writeShellScript "setup-flatpaks" ''
  ${if cfg.enable-debug then ''
  set -v
  '' else ""}
  
  export PATH=${lib.makeBinPath (with pkgs; [ coreutils util-linux inetutils gnugrep flatpak gawk rsync ostree systemd findutils gnused diffutils ])}
  
  until ping -c1 github.com &>/dev/null; do echo x; sleep 1; done | awk '
  {
    printf "Waiting for net (%d tries)\n", (NR)
  }
  END {
    printf "Network connected.\n"
  }
  '

  set -eu

  export LANG=C

  ${if is-system-install then ''
  export MODULE_DATA_ROOT=/var/lib/flatpak-module
  export FLATPAK_DIR=/var/lib/flatpak
  '' else ''
  export MODULE_DATA_ROOT=${config.xdg.stateHome}/flatpak-module
  export FLATPAK_DIR=${config.xdg.dataHome}/flatpak
  ''}
  
  # Now do some overrides
  ${if cfg.state-dir != null then ''
  export MODULE_DATA_ROOT=${cfg.state-dir}
  '' else ""}
  ${if cfg.target-dir != null then ''
  export FLATPAK_DIR=${cfg.target-dir}
  '' else ""}

  CURR_BOOTID=$(journalctl --list-boots --no-pager | grep -E '^ +0' | awk '{print$2}') || \
    CURR_BOOTID=1

  ACTIVE_DIR=$(cat $MODULE_DATA_ROOT/active 2>/dev/null) || \
    ACTIVE_DIR=$MODULE_DATA_ROOT/boot/2/1
  TARGET_DIR=$MODULE_DATA_ROOT/boot/$CURR_BOOTID/$(uuidgen)
  INSTALL_TRASH_DIR=$MODULE_DATA_ROOT/boot/0/$(uuidgen)

  if [ -d $MODULE_DATA_ROOT/boot ]; then
    [ -e $ACTIVE_DIR ] && \
      echo "$CURR_BOOTID" >$ACTIVE_DIR/keep
    
    echo Cleaning old directories
    find $MODULE_DATA_ROOT/boot -type d -mindepth 2 -maxdepth 2 \
      -not -exec test -e {}/keep \; -exec rm -rf {} \; \
      -o -not -exec grep "$CURR_BOOTID" {}/keep &>/dev/null \; -exec rm -rf {} \;
    rmdir $MODULE_DATA_ROOT/boot/* 2>/dev/null || true
  fi
  
  echo "Running with boot ID $CURR_BOOTID"
  echo "An installation will be created at \"$TARGET_DIR\""
  mkdir -pm 755 $TARGET_DIR
  mkdir -pm 755 $INSTALL_TRASH_DIR

  ${cfg.preInitCommand}

  export FLATPAK_USER_DIR=$TARGET_DIR/data
  export FLATPAK_SYSTEM_DIR=$TARGET_DIR/data

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

    # echo R $_remote
    # echo C $_commit
    # echo I $_id

    flatpak ${builtins.toString fargs} install --noninteractive --no-auto-pin $_remote $_id

    if [ -n "$_commit" ]; then
      flatpak update --commit="$_commit" $_id || echo "failed to update to commit \"$_commit\". Check if the commit is correct - $_id"
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
  
  ${if cfg.deduplicate then ''
  # Deduplicate
  if [ -d $ACTIVE_DIR/data ]; then
    echo "Deduplicating"
    pushd $ACTIVE_DIR/data &>/dev/null
    find . -type f | while read r; do
      if cmp -s $ACTIVE_DIR/data/$r $TARGET_DIR/data/$r; then
        ln -f $ACTIVE_DIR/data/$r $TARGET_DIR/data/$r
        echo "$r deduplicated"
      fi
    done
    popd &>/dev/null
  fi
  '' else "# Deduplication would have happened here"}

  echo "Installing files"
  
  # Move the current "installation" into the bin
  [ -d $FLATPAK_DIR ] && mv $FLATPAK_DIR/* $INSTALL_TRASH_DIR || true
  rm -rf $FLATPAK_DIR || echo "WARNING: Could not delete $FLATPAK_DIR"
  mkdir -pm 755 $FLATPAK_DIR
  
  # Then try to recover state data
  rm -rf $FLATPAK_DIR/db
  [ -d $INSTALL_TRASH_DIR/db ] && mv $INSTALL_TRASH_DIR/db $FLATPAK_DIR/db
  
  # Install overrides
  rm -rf $TARGET_DIR/data/overrides
  mkdir -p $TARGET_DIR/data/overrides
  ${builtins.concatStringsSep "\n" (builtins.map (ref: ''
  cp ${cfg.source} "$TARGET_DIR/data/overrides/${ref}"
  '') (builtins.attrNames cfg.overrides))}
  
  # First, make sure we didn't accidentally copy over the exports
  rm -rf $TARGET_DIR/data/processed-exports
  
  # Dereference because exports are symlinks by default
  [ -d $TARGET_DIR/data/exports ] && rsync -aL $TARGET_DIR/data/exports/ $TARGET_DIR/data/processed-exports
  
  # Then begin "processing" the exports to make them point to the correct locations
  [ -d $TARGET_DIR/data/processed-exports/bin ] && \
    find $TARGET_DIR/data/processed-exports/bin \
      -type f -exec sed -i "s,exec flatpak run,FLATPAK_USER_DIR=$TARGET_DIR/data FLATPAK_SYSTEM_DIR=$TARGET_DIR/data exec flatpak run,gm" '{}' \;
  [ -d $TARGET_DIR/data/processed-exports/share/applications ] && \
    find $TARGET_DIR/data/processed-exports/share/applications \
      -type f -exec sed -i "s,Exec=flatpak run,Exec=env FLATPAK_USER_DIR=$TARGET_DIR/data FLATPAK_SYSTEM_DIR=$TARGET_DIR/data flatpak run,gm" '{}' \;
  
  # Now clone the modified exports over
  [ -d $TARGET_DIR/data/processed-exports ] && rsync -aL $TARGET_DIR/data/processed-exports/ $FLATPAK_DIR/exports

  # Create some symlinks to allow the user to mutate their environment
  for i in repo runtime app overrides; do
    [ -e $TARGET_DIR/data/$i ] && ln -s $TARGET_DIR/data/$i $FLATPAK_DIR/$i
  done

  unset FLATPAK_USER_DIR FLATPAK_SYSTEM_DIR

  ${cfg.postInitCommand}

  echo $TARGET_DIR  >$MODULE_DATA_ROOT/active
  ln -sfT ${filecfg} $TARGET_DIR/config
''
