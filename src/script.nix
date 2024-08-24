{ cfg, config, lib, pkgs
, is-system-install, extra-flatpak-flags ? [] }:

let
  inherit (pkgs) coreutils util-linux inetutils gnugrep flatpak gawk rsync ostree systemd findutils gnused diffutils callPackage writeShellScript writeText;
  inherit (lib) makeBinPath;

  
  fargs = if is-system-install then [ "--system" ] else [ "--user" ] ++ extra-flatpak-flags;
  regexes = (callPackage ./lib/types.nix {}).regexes;
  filecfg = writeText "flatpak-gen-config" (builtins.toJSON {
    inherit (cfg) overrides packages remotes state-dir target-dir preRemotesCommand preInstallCommand preSwitchCommand;
  });
in

writeShellScript "setup-flatpaks" ''
  ${if cfg.enable-debug then ''
  set -v
  '' else ""}
  
  export PATH=${makeBinPath [ coreutils util-linux inetutils gnugrep flatpak gawk rsync ostree systemd findutils gnused diffutils ]}
  
  # Failsafe
  _count=0
  until ping -c1 github.com &>/dev/null; do
    if [ $_count -ge 60 ]; then
      echo "Failed to acquire an internet connection in 60 seconds."
      exit 1
    fi
    _count=$(($_count + 1))
    sleep 1
  done
  unset _count
  echo "Internet connected"

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
      -not -exec test -e {}/keep \; -exec rm -rf ${if cfg.enable-debug then "-v" else ""} {} \; \
      -o -not -exec grep "$CURR_BOOTID" {}/keep &>/dev/null \; -exec rm -rf ${if cfg.enable-debug then "-v" else ""} {} \;
    rmdir $MODULE_DATA_ROOT/boot/* 2>/dev/null || true
  fi
  
  echo "Running with boot ID $CURR_BOOTID"
  echo "An installation will be created at \"$TARGET_DIR\""
  mkdir -pm 755 $TARGET_DIR
  mkdir -pm 755 $INSTALL_TRASH_DIR
  mkdir -pm 755 $TARGET_DIR/data

  export FLATPAK_USER_DIR=$TARGET_DIR/data
  export FLATPAK_SYSTEM_DIR=$TARGET_DIR/data

  ln -sfT $TARGET_DIR $MODULE_DATA_ROOT/build

  # "steal" the repo from last install
  if [ -e $ACTIVE_DIR/data/repo ]; then
    cp -al $ACTIVE_DIR/data/repo $TARGET_DIR/data/repo
    ostree remote list --repo=$TARGET_DIR/data/repo | while read r; do
      ostree remote delete --repo=$TARGET_DIR/data/repo --if-exists $r
    done
    # needed for prune
    rm -rf $TARGET_DIR/data/repo/refs/heads/deploy
    rm -rf $TARGET_DIR/data/repo/refs/remotes/*
  else
    ostree init --repo=$TARGET_DIR/data/repo --mode=bare-user-only
  fi


  ${cfg.preRemotesCommand}

  ${builtins.toString (builtins.attrValues (builtins.mapAttrs (name: value: ''
  echo "Adding remote ${name} with URL ${value}"
  flatpak ${builtins.toString fargs} remote-add --if-not-exists ${name} ${value}
  '') cfg.remotes))}

  ${cfg.preInstallCommand}

  for i in ${builtins.toString (builtins.filter (x: builtins.match ".+${regexes.ffile}$" x == null) cfg.packages)}; do
    _remote=$(grep -Eo '^${regexes.fremote}' <<< $i)
    _id=$(grep -Eo '${regexes.ftype}/${regexes.fref}/${regexes.farch}/${regexes.fbranch}(:${regexes.fcommit})?' <<< $i)
    _commit=$(grep -Eo ':${regexes.fcommit}$' <<< $_id) || true
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
    _remote=$(grep -Eo '^${regexes.fremote}:' <<< $i | head -c-2)
    _id=$(grep -Eo ':.+\.flatpakref$' <<< $i | tail -c+2)

    flatpak ${builtins.toString fargs} install --noninteractive --no-auto-pin $_remote $_id
  done

  ${cfg.preSwitchCommand}

  ostree prune --repo=$TARGET_DIR/data/repo --refs-only || true
  ostree prune --repo=$TARGET_DIR/data/repo || true
  
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
  cat ${callPackage ./pkgs/overrides.nix { inherit cfg ref; }} >$TARGET_DIR/data/overrides/${ref}
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

  echo $TARGET_DIR  >$MODULE_DATA_ROOT/active
  ln -sfT ${filecfg} $TARGET_DIR/config

  ${cfg.UNCHECKEDpostEverythingCommand}
''