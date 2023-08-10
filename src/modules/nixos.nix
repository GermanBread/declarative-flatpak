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
        extra-flatpak-flags = [ "--system" ];
      }}";
    };

    assertions = [
      {
        assertion = cfg.enable;
        message = "This flatpak module is useless if flatpaks are disabled in your config.";
      }
    ];

    warnings = [
      "The \"stable\" branch of the flatpak module is about to inherit a lot of the under-the-hood changes from \"dev\".\n    If you want to keep this version, pin it in your flake inputs.\n    The last working commit of this branch is fb31283f55f06b489f2baf920201e8eb73c9a0d3 (commit before this warning was added).\n\nDo not request support.\nDo not override inputs."
    ];
  };
}
