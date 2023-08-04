{ config, pkgs, flatpak, ... }: {
  systemd.services.NetworkManager-wait-online.enable = false;

  services.flatpak = {
    packages = [
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.MangoHud//21.08"
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.vkBasalt//21.08"
      "flathub:app/org.kde.index//stable"
      
      "flathub-beta:app/org.mozilla.firefox//stable"
      
      "launcher-moe:app/moe.launcher.honkers-launcher/x86_64/master"

      "flathub:${./io.gitlab.daikhan.stable.flatpakref}"
      ":${./xwaylandvideobridge.flatpak}"
    ];
    remotes = {
      "flathub" = "https://flathub.org/repo/flathub.flatpakrepo";
      "flathub-beta" = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      "launcher-moe" = "https://gol.launcher.moe/gol.launcher.moe.flatpakrepo";
    };
  };

  virtualisation = {
    cores = 8;
    memorySize = 8096 * 2;
    diskSize = 10 * 1024;
  };

  # Dev env stuff
  environment.loginShellInit = ''
    trap 'sudo poweroff' EXIT
  '';
  #virtualisation.sharedDirectories = {
  #  "source" = {
  #    target = "/src";
  #    source = "/tmp/flatpak-module-dev";
  #  };
  #};
  #systemd.paths."hot-reload" = {
  #  pathConfig = {
  #    "PathModified" = "/src";
  #    "Unit" = [ "hot-restart.service" ];
  #  };
  #};
  #systemd.services."hot-restart" = {
  #  script = ''
  #    systemctl poweroff
  #  '';
  #};

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

  environment.systemPackages = with pkgs; [
    tmux
  ];

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

    services.flatpak = {
      packages = [
        "flathub:app/de.shorsh.discord-screenaudio//stable"
        # "flathub-beta:app/org.chromium.Chromium//beta"
        # "flathub:app/com.usebottles.bottles//stable"
      ];
      remotes = {
        "flathub" = "https://flathub.org/repo/flathub.flatpakrepo";
        "flathub-beta" = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      };
    };

    home.file.".zshrc".text = "";

    home.stateVersion = "22.11";
  };

  system.stateVersion = "22.05";
}
