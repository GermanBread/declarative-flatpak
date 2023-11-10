{ config, lib, pkgs, ... }@args:

let
  cfg = if args ? nixosConfig then (config.services.flatpak // { enable = args.nixosConfig.services.flatpak.enable; }) else config.services.flatpak;
in 

{
  options.services.flatpak = import ../options.nix { inherit lib cfg; };

  config = lib.mkIf cfg.enableModule {
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
          is-system-install = false;
        }}";
      };
    };

    home.activation = {
      start-service = lib.hm.dag.entryAfter ["writeBoundary"] ''
        export PATH=${lib.makeBinPath (with pkgs; [ systemd ])}:$PATH

        $DRY_RUN_CMD systemctl --user daemon-reload
        $DRY_RUN_CMD systemctl is-system-running -q && \
          systemctl --user enable --now manage-user-flatpaks.service || true
      '';
    };

    xdg.enable = true;
  };
}