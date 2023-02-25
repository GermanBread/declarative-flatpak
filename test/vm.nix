{ pkgs, ... }: {
  services.getty.autologinUser = "root";

  systemd.services.NetworkManager-wait-online.enable = false;

  services.flatpak = {
    packages = [
      "org.mozilla.firefox"
    ];
  };

  virtualisation = {
    cores = 8;
    memorySize = 8096 * 2;
    diskSize = 10 * 1024;
  };

  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-kde
  ];

  networking.networkmanager.enable = true;

  system.stateVersion = "22.05";
}