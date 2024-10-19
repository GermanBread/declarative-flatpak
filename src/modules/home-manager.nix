{ config, lib, pkgs, ... }@args:

let
  inherit (pkgs) callPackage systemd;
  inherit (lib) mkIf makeBinPath;
  
  cfg =
    if args ? nixosConfig
    then (config.services.flatpak // { enable = args.nixosConfig.services.flatpak.enable; })
    else (config.services.flatpak // { enable = false; })
    ;
in 

{
  imports = [
    (import ../options.nix { inherit cfg; })
  ];

  config.systemd.user.services."manage-user-flatpaks" = mkIf cfg.enableModule {
    Unit = {
      Wants = mkIf cfg.runOnActivation [
        "network.target"
      ];
    };
    Install = {
      WantedBy = mkIf cfg.runOnActivation [
        "default.target"
      ];
    };
    Service = {
      ExecStart = "${callPackage ../script.nix {
        inherit cfg config;
        is-system-install = false;
      }}";
    };
  };
  config.systemd.user.timers."manage-user-flatpaks" = mkIf (cfg.enableModule && cfg.onCalendar != null) {
    Unit = {
      Wants = [
        "network.target"
      ];
    };
    Install = {
      WantedBy = [
        "default.target"
      ];
    };
    Timer = {
      OnCalendar = cfg.onCalendar;
      Persistent = true;
    };
  };

  config.home.activation = mkIf cfg.enableModule {
    start-service = lib.hm.dag.entryAfter ["writeBoundary"] ''
      export PATH=${makeBinPath ([ systemd ])}:$PATH

      $DRY_RUN_CMD systemctl is-system-running -q && \
        systemctl --user daemon-reload || true
      $DRY_RUN_CMD systemctl is-system-running -q && \
        systemctl --user enable manage-user-flatpaks || true
      ${if cfg.onCalendar != null then ''
      $DRY_RUN_CMD systemctl is-system-running -q && \
        systemctl --user start manage-user-flatpaks || true
      '' else ""}
    '';
  };

  config.xdg.enable = true;
}