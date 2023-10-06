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
      };
    };
    pkgs = { config, pkgs, ... }: {
      imports = [
        modules.flatpak
      ];

      networking.dhcpcd.enable = true;
      
      services.flatpak = {
        enable = true;
        packages = [
          "flathub:runtime/org.freedesktop.Platform.VulkanLayer.MangoHud//21.08:9ee91f5c7944516169bb7a327d81ac7b08b149b3cd238b7a11a61bc1abe28ba9"
          "flathub:app/org.kde.index//stable"
        ];
        remotes = {
          "flathub" = "https://flathub.org/repo/flathub.flatpakrepo";
        };
      };

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-kde
        ];
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
      };
    };
    recycle_gen = { config, pkgs, ... }: {
      imports = [
        modules.flatpak
      ];

      networking.dhcpcd.enable = true;

      services.flatpak = {
        enable = true;
        recycle-generation = true;
      };

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-kde
        ];
      };
    };
  };

  testScript = ''
    disabled.wait_for_unit("network-online.target")
    disabled.succeed("which flatpak")
    disabled.fail("systemctl status --no-pager manage-system-flatpaks.service")
  
    bare.wait_for_unit("network-online.target")
    bare.succeed("which flatpak")
    bare.succeed("systemctl status --no-pager manage-system-flatpaks.service")

    custom_dirs.wait_for_file("/state")
    custom_dirs.wait_for_file("/target")
  
    recycle_gen.start(allow_reboot=True)
    recycle_gen.wait_until_succeeds("journalctl -u manage-system-flatpaks.service -g \"ID $(journalctl --list-boots --no-pager | grep -E '^ +0' | awk '{print$2}')\"")
    recycle_gen.reboot()
    recycle_gen.wait_until_succeeds("journalctl -u manage-system-flatpaks.service -g \"ID $(journalctl --list-boots --no-pager | grep -E '^ +0' | awk '{print$2}')\"")
    recycle_gen.succeed("journalctl -u manage-system-flatpaks.service -g Re-using the current environment")
    recycle_gen.shutdown()
  '';
}