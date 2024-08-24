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
    installation = { config, pkgs, ... }: {
      imports = [
        modules.flatpak
      ];

      services.flatpak = {
        enable = true;
        target-dir = "/target";
        packages = [
          ":${../vm/xwaylandvideobridge.flatpak}"
        ];
      };

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-kde
        ];
        config.common.default = "*";
      };

      virtualisation = {
        cores = 8;
        memorySize = 8096 * 2;
        diskSize = 16 * 1024;
      };
    };
    custom_dirs = { config, pkgs, ... }: {
      imports = [
        modules.flatpak
      ];

      networking.dhcpcd.enable = true;
      
      services.flatpak = {
        enable = true;
        state-dir = "/state";
        target-dir = "/target";
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
        target-dir = "/target";
        UNCHECKEDpostEverythingCommand = ''
          touch /target/repo/thisfileshouldpersist
          touch /target/thisfileshouldnotpersist
        '';
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
    bare.succeed("systemctl status --no-pager manage-system-flatpaks.service")
    bare.shutdown()

    custom_dirs.wait_for_unit("manage-system-flatpaks.service")
    custom_dirs.wait_for_file("/state", timeout=60)
    custom_dirs.wait_for_file("/target", timeout=60)
    custom_dirs.succeed("stat /state")
    custom_dirs.succeed("stat /target")
    custom_dirs.shutdown()
  
    persist.start(allow_reboot=True)
    persist.wait_for_unit("manage-system-flatpaks.service")
    persist.wait_for_file("/target", timeout=60)
    persist.succeed("stat /target/repo/thisfileshouldpersist")
    persist.succeed("stat /target/thisfileshouldnotpersist")
    persist.reboot()
    persist.wait_for_unit("manage-system-flatpaks.service")
    persist.wait_for_file("/target", timeout=60)
    persist.succeed("stat /target/repo/thisfileshouldpersist")
    persist.fail("stat /target/thisfileshouldnotpersist")
    persist.shutdown()
  '';
}