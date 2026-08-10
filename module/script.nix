{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (pkgs)
    curl
    coreutils
    util-linux
    gnugrep
    flatpak
    gawk
    rsync
    ostree
    systemd
    findutils
    gnused
    diffutils
    writeShellScript
    writeText
    ;
  inherit (builtins)
    concatStringsSep
    map
    filter
    toJSON
    match
    attrValues
    mapAttrs
    attrNames
    ;
  inherit (cfg.internal) targetDir mainScript;
  inherit (lib) makeBinPath optionalString;
  inherit (cfg.internal) overrideFiles;

  inherit (import ../lib/regexes.nix)
    fcommit
    fref
    ffile
    fremote
    ftype
    farch
    fbranch
    ;

  cfg = config.services.flatpak;
  is-hm = config ? home && lib ? hm;
  filecfg = writeText "flatpak-gen-config" (toJSON {
    inherit (cfg)
      overrides
      packages
      remotes
      preRemotesCommand
      preInstallCommand
      preSwitchCommand
      UNCHECKEDfinalizeCommand
      ;
  });
  system-user-switch = if is-hm then "--user" else "--system";
  script = mapAttrs (name: value: ''
    echo "Executing step: ${name}"
    ${value}
  '') {
    config-diff = optionalString (!cfg.forceRunOnActivation) ''
      if [ -e "$DATA_DIR/config" ] && cmp -s ${filecfg} "$DATA_DIR/config"; then
        echo "Configs do not differ, therefore I won't do anything. You may change this default behaviour"
        exit 0
      fi
    '';
    setup = ''
      ${optionalString cfg.veryVerbose "set -vx"}
      set -eu
      shopt -s extglob nullglob

      PATH="${
        makeBinPath [
          curl
          coreutils
          util-linux
          gnugrep
          flatpak
          gawk
          rsync
          ostree
          systemd
          findutils
          gnused
          diffutils
        ]
      }"

      LANG=C
      MODULE_DIR_INFIX=".module"
      CURR_BOOTID=$(journalctl --list-boots --no-pager | grep -E '^ +0' | awk '{print$2}') || \
        CURR_BOOTID=1

      CURRENT_FLATPAK_DIR="${targetDir}"
      ${optionalString (cfg.flatpakDir != null) ''
        CURRENT_FLATPAK_DIR="${cfg.flatpakDir}"
      ''}

      DATA_DIR="$CURRENT_FLATPAK_DIR"/"$MODULE_DIR_INFIX"

      NEW_FLATPAK_INSTALL="$DATA_DIR"/new

      TRASH_DIR="$DATA_DIR"/trash/"$CURR_BOOTID"/"$(uuidgen)"

      export FLATPAK_USER_DIR="$NEW_FLATPAK_INSTALL"
      export FLATPAK_SYSTEM_DIR="$NEW_FLATPAK_INSTALL"

      function fail {
        # a partially copied ostree repo cannot be trusted
        # in the off-chance that a flatpak command fails this will get created and the second service run will start from scratch
        touch "$NEW_FLATPAK_INSTALL"/repo/dirty
      }
      trap 'fail' ERR
    '';
    dirs = ''
      for i in "$DATA_DIR"/trash/!("$CURR_BOOTID"); do
        find "$i" -d -delete
      done

      # its absence is our indicator that the module is in the process of building a new generation
      rm -f "$DATA_DIR"/config

      for i in "$DATA_DIR"/{repo-save,install-data,processed-exports}; do
        if test -d "$i"; then
          find "$i" -d -delete
        fi
      done

      # we can try recycling the in-progress repo
      if [ -d "$NEW_FLATPAK_INSTALL"/repo ] && [ ! -e "$NEW_FLATPAK_INSTALL"/repo/dirty ]; then
        echo "Found in-progress state, we can recycle it"
        mv "$NEW_FLATPAK_INSTALL"/repo "$DATA_DIR"/repo-save
      fi

      if test -d "$NEW_FLATPAK_INSTALL"; then
        find "$NEW_FLATPAK_INSTALL" -d -delete
      fi

      mkdir -pm 755 "$DATA_DIR" "$NEW_FLATPAK_INSTALL" "$TRASH_DIR" "$DATA_DIR"/install-data "$NEW_FLATPAK_INSTALL"/overrides "$NEW_FLATPAK_INSTALL"/db
    '';
    recycle-repo = ''
      if [ -d "$DATA_DIR"/repo-save ]; then
        touch "$DATA_DIR"/repo-save/dirty
        mv "$DATA_DIR"/repo-save "$NEW_FLATPAK_INSTALL"/repo
        ostree fsck --repo="$NEW_FLATPAK_INSTALL"/repo
      elif [ -d "$CURRENT_FLATPAK_DIR"/repo ] && [ ! -e "$CURRENT_FLATPAK_DIR"/repo/dirty ]; then
        echo "Recycling existing repo"
        touch "$CURRENT_FLATPAK_DIR"/repo/dirty
        cp -a --reflink=auto "$CURRENT_FLATPAK_DIR"/repo "$NEW_FLATPAK_INSTALL"/repo
        ostree fsck --repo="$NEW_FLATPAK_INSTALL"/repo
        rm "$CURRENT_FLATPAK_DIR"/repo/dirty
      else
        echo "Creating repo from scratch"
        ostree init --repo="$NEW_FLATPAK_INSTALL"/repo --mode=bare-user-only
      fi
      touch "$NEW_FLATPAK_INSTALL"/repo/dirty
      ostree remote list --repo="$NEW_FLATPAK_INSTALL"/repo | while read r; do
        ostree remote delete --repo="$NEW_FLATPAK_INSTALL"/repo --if-exists "$r"
      done
      for i in "$NEW_FLATPAK_INSTALL"/repo/{refs,extensions}; do
        if test -d "$i"; then
          find "$i" -d -delete
        fi
      done
      mkdir -p \
        "$NEW_FLATPAK_INSTALL"/repo/refs/{heads,mirrors,remotes} \
        "$NEW_FLATPAK_INSTALL"/repo/extensions
      rm "$NEW_FLATPAK_INSTALL"/repo/dirty
    '';
    add-remotes = toString (
      attrValues (
        mapAttrs (name: value: ''
          echo "Adding remote ${name} with URL ${value}"
          flatpak ${system-user-switch} remote-add --if-not-exists "${name}" "${value}" || exit 1
        '') cfg.remotes
      )
    );
    prep-install = ''
      counter=0

      for i in ${toString (filter (x: match ".+${ffile}$" x == null) cfg.packages)}; do
        _remote="$(grep -Eo '^${fremote}' <<< $i)"
        _id="$(grep -Eo '${ftype}/${fref}/${farch}/${fbranch}(:${fcommit})?' <<< $i)"
        _commit="$(grep -Eo ':${fcommit}$' <<< $_id)" || true
        if [ -n "$_commit" ]; then
          _commit=$(tail -c-$(($(wc -c <<< $_commit) - 1)) <<< $_commit)
          _id=$(head -c-$(($(wc -c <<< $_commit) + 1)) <<< $_id)
        fi

        mkdir -p "$DATA_DIR"/install-data/"$_remote"/$counter
        echo -n "$_id" >"$DATA_DIR"/install-data/"$_remote"/$counter/id
        [ -n "$_commit" ] && echo -n "$_commit" >"$DATA_DIR"/install-data/"$_remote"/$counter/commit

        : $(( counter++ ))
      done

      unset counter
    '';
    install-remote = ''
      pushd "$DATA_DIR"/install-data
      for rem in *; do
        pushd "$DATA_DIR"/install-data/"$rem"

        for ref in *; do
          _id="$(<"$ref"/id)"
          # the cli doesn't support specifying multiple refs alongside the repo (?)
          flatpak ${system-user-switch} install --noninteractive --or-update --no-auto-pin "$rem" "$_id" || exit 1
        done

        for ref in *; do
          [ ! -e "$ref"/commit ] && continue

          _id="$(<"$ref"/id)"
          _commit="$(<"$ref"/commit)"

          if ! flatpak update --noninteractive --commit="$_commit" "$_id"; then
            echo "Failed to update ref $_id to commit $_commit. Verify if the commit is correct"
            exit 1
          fi
        done

        popd
      done
      popd
    '';
    install-local = ''
      echo "Installing out-of-tree refs"
      for i in ${toString (filter (x: match ":.+\.flatpak$" x != null) cfg.packages)}; do
        _id="$(grep -Eo ':.+\.flatpak$' <<< $i | tail -c+2)"

        flatpak ${system-user-switch} install --noninteractive --or-update --no-auto-pin "$_id" || exit 1
      done
      for i in ${toString (filter (x: match ":.+\.flatpakref$" x != null) cfg.packages)}; do
        _remote="$(grep -Eo '^${fremote}:' <<< $i | head -c-2)"
        _id="$(grep -Eo ':.+\.flatpakref$' <<< $i | tail -c+2)"

        flatpak ${system-user-switch} install --noninteractive --or-update --no-auto-pin "$_remote" "$_id" || exit 1
      done
    '';
    prune-ostree = ''
      ostree prune --repo="$NEW_FLATPAK_INSTALL"/repo --refs-only
      ostree prune --repo="$NEW_FLATPAK_INSTALL"/repo
    '';
    overrides = ''
      echo "Installing overrides"
      ${concatStringsSep "\n" (
        map (ref: ''
          cat ${overrideFiles.${ref}} >"$NEW_FLATPAK_INSTALL"/overrides/"${ref}"
        '') (attrNames cfg.overrides)
      )}
    '';
    exports = optionalString (cfg.flatpakDir != null) ''
      if [ -d "$NEW_FLATPAK_INSTALL"/exports ]; then
        # Dereference because exports are symlinks by default
        rsync -aL --delete --remove-source-files "$NEW_FLATPAK_INSTALL"/exports/ "$DATA_DIR"/processed-exports/
        find "$NEW_FLATPAK_INSTALL"/exports -d -delete

        # Then begin "processing" the exports to make them point to the correct locations
        if [ -d "$DATA_DIR"/processed-exports/bin ]; then
          find "$DATA_DIR"/processed-exports/bin \
            -type f -exec sed -i 's,exec flatpak run,FLATPAK_USER_DIR='"'$CURRENT_FLATPAK_DIR'"' FLATPAK_SYSTEM_DIR='"'$CURRENT_FLATPAK_DIR'"' exec flatpak run,gm' '{}' \;
        fi
        if [ -d "$DATA_DIR"/processed-exports/share/applications ]; then
          find "$DATA_DIR"/processed-exports/share/applications \
            -type f -exec sed -i 's,Exec=flatpak run,Exec=env FLATPAK_USER_DIR='"'$CURRENT_FLATPAK_DIR'"' FLATPAK_SYSTEM_DIR='"'$CURRENT_FLATPAK_DIR'"' flatpak run,gm' '{}' \;
        fi

        mv "$DATA_DIR"/processed-exports "$NEW_FLATPAK_INSTALL"/exports
      fi
    '';
    switch = ''
      echo "Moving old data for future deletion"
      {
        dirs=("$CURRENT_FLATPAK_DIR"/!("$MODULE_DIR_INFIX"|db))
        if (( ''${#dirs[@]} > 0 )); then
          mv "''${dirs[@]}" "$TRASH_DIR"
        fi
      }

      echo "Installing flatpak data"
      pushd "$NEW_FLATPAK_INSTALL"
      touch repo/dirty
      for i in *; do
        mv "$i" "$CURRENT_FLATPAK_DIR"/"$i"
      done
      popd
      rm "$CURRENT_FLATPAK_DIR"/repo/dirty
    '';
    post-cleanup = ''
      echo "Finishing up"
      ln -snfT ${filecfg} "$DATA_DIR"/config
      find "$NEW_FLATPAK_INSTALL" -d -delete
      trap - ERR
    '';
  };
in
{
  config.services.flatpak.internal.mainScript = {
    activation = writeShellScript "setup-flatpaks" (
      concatStringsSep "\n" [
        script.setup
        script.config-diff
        mainScript.auto
      ]
    );
    auto = writeShellScript "setup-flatpaks" (
      concatStringsSep "\n" [
        script.setup
        script.dirs
        script.recycle-repo
        cfg.preRemotesCommand
        script.add-remotes
        cfg.preInstallCommand
        script.prep-install
        script.install-remote
        script.install-local
        cfg.preSwitchCommand
        script.prune-ostree
        script.overrides
        script.exports
        script.switch
        script.post-cleanup
        cfg.UNCHECKEDfinalizeCommand
      ]
    );
  };
}
