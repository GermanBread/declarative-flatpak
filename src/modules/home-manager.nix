{ config, lib, pkgs, nixosConfig ? null, ... }:

let
  cfg = if nixosConfig == null then config.services.flatpak else (config.services.flatpak // { enable = nixosConfig.services.flatpak.enable; });
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

        $DRY_RUN_CMD systemctl is-system-running -q && \
          systemctl --user start manage-user-flatpaks.service || true
      '';
    };

    xdg.enable = true;
  };
}