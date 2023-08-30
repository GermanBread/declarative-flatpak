{ config, lib, pkgs, ... }:

let
  cfg = config.services.flatpak;
in

{
  options.services.flatpak = import ../options.nix { inherit lib cfg; };

  config = lib.mkIf cfg.enableModule {
    systemd.services."manage-system-flatpaks" = {
      description = "Manage system-wide flatpaks";
      after = [
        "network-online.target"
      ];
      wantedBy = [
        "multi-user.target"
      ];
      script = "${import ../script.nix {
        inherit config lib pkgs;
        is-system-install = true;
      }}";
    };
  };
}