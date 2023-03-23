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

  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-kde
    ];
  };

  nixos-shell.mounts = {
    mountHome = false;
    mountNixProfile = false;
  };

  environment.loginShellInit = ''
    trap 'poweroff' EXIT
  '';

  users.users."root".shell = pkgs.zsh;

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "flazz";
    };
  };

  networking.networkmanager.enable = true;

  system.stateVersion = "22.05";
}