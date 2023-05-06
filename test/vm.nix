{ config, pkgs, flatpak, ... }: {
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

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
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
    trap 'sudo poweroff' EXIT
  '';

  networking.networkmanager.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "flazz";
    };
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  
  users.users."user" = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "password";
    shell = pkgs.zsh;
  };
  services.getty.autologinUser = "user";
  home-manager.users."user" = {
    imports = [
      flatpak.homeManagerModules.default
    ];

    services.flatpak.packages = [
      "de.shorsh.discord-screenaudio"
    ];

    home.file.".zshrc".text = "";

    home.stateVersion = "22.11";
  };

  system.stateVersion = "22.05";
}