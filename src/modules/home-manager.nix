{ config, lib, pkgs, ... }:

let
  script = (import ../hm-script.nix { inherit config pkgs lib; }).script;
in

{
  options.services.flatpak = import ../options.nix { mkOption = lib.mkOption; types = lib.types; };

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
        ExecStart = "${script}";
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