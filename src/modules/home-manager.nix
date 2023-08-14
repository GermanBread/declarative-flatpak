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
    
    warnings = [
      "The flatpak module just recieved a big update! What this means for you:\n- Please take some time and read the documentation at https://github.com/GermanBread/declarative-flatpak\n- Remove commands from postInitCommands which might conflict with the new override option"
    ];
  };
}