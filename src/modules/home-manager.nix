{ config, lib, pkgs, ... }:

{
  options.services.flatpak = import ../options.nix { inherit lib; };

  config = {
    systemd.user.services."manage-user-flatpaks" = {
      Unit = {
        After = [
          "network.target"
        ];
      };
      Install = {
        WantedBy = [
          "default.target"
        ];
      };
      Service = {
        ExecStart = "${import ../script.nix {
          inherit config lib pkgs;
          extra-flatpak-flags = [ "--user" ];
        }}";
      };
    };

    home.activation = {
      start-service = lib.hm.dag.entryAfter ["writeBoundary"] ''
        export PATH=${lib.makeBinPath (with pkgs; [ systemd ])}:$PATH

        $DRY_RUN_CMD systemctl is-system-running -q && \
          systemctl --user start manage-user-flatpaks.service || true
      '';
    };

    xdg.enable = true;

    warnings = [
      "The \"stable\" branch of the flatpak module is about to inherit a lot of the under-the-hood changes from \"dev\".\n    If you want to keep this version, pin it in your flake inputs.\n    The last working commit of this branch is fb31283f55f06b489f2baf920201e8eb73c9a0d3 (commit before this warning was added).\n\nDo not request support.\nDo not override inputs."
    ];
  };
}