{ nixosTest, modules }:

nixosTest {
  name = "NixOS test";

  nodes = {
    bare = { config, pkgs, ... }: {
      imports = [
        modules.flatpak
      ];

      services.flatpak.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-kde
        ];
        config.common.default = "*";
      };
    };
    disabled = { config, pkgs, ... }: {
      imports = [
        modules.flatpak
      ];

      services.flatpak = {
        enable = true;
        enableModule = false;
      };

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-kde
        ];
        config.common.default = "*";
      };
    };
    custom_dirs = { config, pkgs, ... }: {
      imports = [
        modules.flatpak
      ];
      
      services.flatpak = {
        enable = true;
        flatpak-dir = "/target";
      };

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-kde
        ];
        config.common.default = "*";
      };
    };
    installation = { config, lib, pkgs, ... }: {
      imports = [
        modules.flatpak
      ];

      services.flatpak = {
        enable = true;
        flatpak-dir = "/target";
        remotes = {
          "test" = ../vm/gol.launcher.moe.flatpakrepo;
        };
        packages = [
          ":${../vm/xwaylandvideobridge.flatpak}"
        ];
        debug = true;
      };

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-kde
        ];
        config.common.default = "*";
      };
    };
    persist = { config, pkgs, ... }: {
      imports = [
        modules.flatpak
      ];

      services.flatpak = {
        enable = true;
        flatpak-dir = "/target";
        UNCHECKEDpostEverythingCommand = ''
          touch /target/repo/thisfileshouldpersist
          touch /target/thisfileshouldnotpersist
        '';
        packages = [
          ":${../vm/xwaylandvideobridge.flatpak}"
        ];
        debug = true;
      };

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-kde
        ];
        config.common.default = "*";
      };
    };
  };

  testScript = ''
    disabled.wait_for_unit("network-online.target")
    disabled.succeed("which flatpak")
    disabled.fail("systemctl status --no-pager manage-system-flatpaks.service")
    disabled.shutdown()
  
    bare.wait_for_unit("network-online.target")
    bare.succeed("which flatpak")
    bare.succeed("systemctl list-unit-files -l | grep 'manage-system-flatpaks'")
    bare.shutdown()

    custom_dirs.wait_for_unit("manage-system-flatpaks.service")
    custom_dirs.wait_until_succeeds("stat /target", timeout=60)
    custom_dirs.shutdown()

    installation.wait_for_unit("network-online.target")
    installation.wait_for_unit("manage-system-flatpaks.service")
    installation.wait_until_succeeds("stat /target/.module", timeout=120)
    installation.wait_until_succeeds("stat /target/repo", timeout=120)
    installation.wait_until_succeeds("stat /target/exports", timeout=120)
    installation.succeed("stat /target/exports/bin/org.kde.xwaylandvideobridge")
    installation.succeed("flatpak run --command=true org.kde.xwaylandvideobridge")
    installation.fail("flatpak run --command=false org.kde.xwaylandvideobridge")
  
    persist.start(allow_reboot=True)
    persist.wait_for_unit("manage-system-flatpaks.service")
    persist.wait_for_file("/target/repo", timeout=120)
    # Added by POST hook, both should succeed
    persist.succeed("stat /target/repo/thisfileshouldpersist")
    persist.succeed("stat /target/thisfileshouldnotpersist")
    persist.reboot()
    persist.wait_until_succeeds("stat /target/.module/new", timeout=60)
    persist.wait_until_fails("stat /target/.module/new", timeout=60)
    persist.succeed("stat /target/repo/thisfileshouldpersist")
    persist.fail("stat /target/thisfileshouldnotpersist")
    persist.shutdown()
  '';
}