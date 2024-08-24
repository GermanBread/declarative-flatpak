{ cfg, config, lib, pkgs
, is-system-install, extra-flatpak-flags ? [] }:

let
  inherit (pkgs) coreutils util-linux inetutils gnugrep flatpak gawk rsync ostree systemd findutils gnused diffutils callPackage writeShellScript writeText;
  inherit (lib) makeBinPath;

  
  fargs = if is-system-install then [ "--system" ] else [ "--user" ] ++ extra-flatpak-flags;
  regexes = (callPackage ./lib/types.nix {}).regexes;
  filecfg = writeText "flatpak-gen-config" (builtins.toJSON {
    inherit (cfg) overrides packages remotes flatpak-dir preRemotesCommand preInstallCommand preSwitchCommand;
  });
in

writeShellScript "setup-flatpaks" ''
  ${if cfg.debug then ''
  set -v
  '' else ""}
  
  PATH=${makeBinPath [ coreutils util-linux inetutils gnugrep flatpak gawk rsync ostree systemd findutils gnused diffutils ]}
  
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

  # --- BEGIN VARIABLES ---
  
  LANG=C
  MODULE_PREFIX=".module"
  CURR_BOOTID=$(journalctl --list-boots --no-pager | grep -E '^ +0' | awk '{print$2}') || \
    CURR_BOOTID=1

  ${if is-system-install then ''
  FLATPAK_DIR="/var/lib/flatpak"
  '' else ''
  FLATPAK_DIR="${config.xdg.dataHome}/flatpak"
  ''}

  # Now do some overrides
  ${if cfg.flatpak-dir != null then ''
  FLATPAK_DIR=${cfg.flatpak-dir}
  '' else ""}

  DATA_DIR="$FLATPAK_DIR/$MODULE_PREFIX"
  
  TARGET_DIR="$DATA_DIR/new"
  
  export FLATPAK_USER_DIR="$TARGET_DIR"
  export FLATPAK_SYSTEM_DIR="$TARGET_DIR"
  
  TRASH_DIR="$DATA_DIR/trash/$CURR_BOOTID/$(uuidgen)"

  # --- END VARIABLES ---

  rm -rf "$TARGET_DIR"
  [ -d "$DATA_DIR/trash" ] && \
    find "$DATA_DIR/trash" -mindepth 1 -maxdepth 1 -not -name "$CURR_BOOTID" | while read r; do
      rm -rf "$r"
    done
  
  mkdir -pm 755 "$DATA_DIR"
  mkdir -pm 755 "$TARGET_DIR"
  mkdir -pm 755 "$FLATPAK_DIR"
  mkdir -pm 755 "$TRASH_DIR"

  # "steal" the repo from last install
  if [ -d "$FLATPAK_DIR/repo" ] && [ ! -L "$FLATPAK_DIR/repo" ]; then
    cp -al "$FLATPAK_DIR/repo" "$TARGET_DIR/repo"
    ostree remote list --repo="$TARGET_DIR/repo" | while read r; do
      ostree remote delete --repo="$TARGET_DIR/repo" --if-exists $r
    done
    # needed for prune
    rm -rf "$TARGET_DIR/repo/refs/heads/deploy"
    rm -rf "$TARGET_DIR/repo/refs/remotes"/*
  else
    ostree init --repo="$TARGET_DIR/repo" --mode=bare-user-only
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
      if ! flatpak update --commit="$_commit" $_id; then
        echo "failed to update to commit \"$_commit\". Check if the commit is correct - $_id"
      fi
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

  ostree prune --repo="$TARGET_DIR/repo" --refs-only
  ostree prune --repo="$TARGET_DIR/repo"
  
  echo "Installing files"
  
  # Move the current installation into the bin
  find "$FLATPAK_DIR" -mindepth 1 -maxdepth 1 -not \( -name "$MODULE_PREFIX" -o -name 'db' \) | while read r; do
    mv "$r" "$TRASH_DIR/''${r##*/}"
  done
  
  # Install overrides
  rm -rf "$TARGET_DIR/overrides"
  mkdir -p "$TARGET_DIR/overrides"
  ${builtins.concatStringsSep "\n" (builtins.map (ref: ''
  cat ${callPackage ./pkgs/overrides.nix { inherit cfg ref; }} >"$TARGET_DIR/overrides/${ref}"
  '') (builtins.attrNames cfg.overrides))}
  
  # First, make sure we didn't accidentally copy over the exports
  rm -rf "$TARGET_DIR/processed-exports"
  
  # Dereference because exports are symlinks by default
  [ -d "$TARGET_DIR/exports" ] && rsync -aL $TARGET_DIR/exports/ $TARGET_DIR/processed-exports
  
  # Then begin "processing" the exports to make them point to the correct locations
  [ -d "$TARGET_DIR/processed-exports/bin" ] && \
    find "$TARGET_DIR/processed-exports/bin" \
      -type f -exec sed -i "s,exec flatpak run,FLATPAK_USER_DIR=$TARGET_DIR FLATPAK_SYSTEM_DIR=$TARGET_DIR exec flatpak run,gm" '{}' \;
  [ -d "$TARGET_DIR/processed-exports/share/applications" ] && \
    find "$TARGET_DIR/processed-exports/share/applications" \
      -type f -exec sed -i "s,Exec=flatpak run,Exec=env FLATPAK_USER_DIR=$TARGET_DIR FLATPAK_SYSTEM_DIR=$TARGET_DIR flatpak run,gm" '{}' \;
  
  rm -rf "$TARGET_DIR/exports"
  mv "$TARGET_DIR/processed-exports/" "$TARGET_DIR/exports"

  # Now we install/apply our changes
  find "$TARGET_DIR" -mindepth 1 -maxdepth 1 | while read r; do
    [ -e "$FLATPAK_DIR/''${r##*/}" ] && rm -rf "$FLATPAK_DIR/''${r##*/}"
    mv "$r" "$FLATPAK_DIR/''${r##*/}"
  done

  rm -rf "$TARGET_DIR"

  ln -sfT ${filecfg} "$DATA_DIR/config"

  unset FLATPAK_USER_DIR FLATPAK_SYSTEM_DIR

  ${cfg.UNCHECKEDpostEverythingCommand}
''