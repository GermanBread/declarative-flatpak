{ config, lib, pkgs, ... }:

let
  inherit (pkgs) callPackage;
  inherit (lib) mkIf;
  
  cfg = config.services.flatpak;
in

{
  imports = [
    (import ../options.nix { inherit cfg; })
  ];
  
  config.systemd.services."manage-system-flatpaks" = mkIf cfg.enableModule {
    description = "Manage system-wide flatpaks";
    serviceConfig.Type = "exec";
    wants = [
      "network-online.target"
    ];
    wantedBy = [
      "multi-user.target"
    ];
    script = "${callPackage ../script.nix {
      inherit cfg config;
      is-system-install = true;
    }}";
  };
}