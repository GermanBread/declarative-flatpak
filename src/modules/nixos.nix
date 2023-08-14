{ config, lib, pkgs, ... }:

let
  cfg = config.services.flatpak;
in

{
  options.services.flatpak = import ../options.nix { inherit lib; };

  config = {
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

    assertions = [
      {
        assertion = cfg.enable;
        message = "This flatpak module is useless if flatpaks are disabled in your config.";
      }
    ];

    warnings = [
      "The flatpak module just recieved a big update! What this means for you:\n- Please take some time and read the documentation at https://github.com/GermanBread/declarative-flatpak\n- Remove commands from postInitCommands which might conflict with the new override option"
    ];
  };
}