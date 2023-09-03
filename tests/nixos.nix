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
  };

  testScript = ''
    disabled.wait_for_unit("network-online.target")
    disabled.succeed("which flatpak")
    disabled.fail("systemctl status --no-pager manage-system-flatpaks.service");
    
    bare.wait_for_unit("network-online.target")
    bare.succeed("which flatpak")
    bare.succeed("systemctl status --no-pager manage-system-flatpaks.service");
  '';
}