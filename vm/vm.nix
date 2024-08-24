{ pkgs, flatpak, ... }: {
  systemd.services.NetworkManager-wait-online.enable = false;

  services.flatpak = {
    packages = [ # comment these out at random
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.MangoHud//21.08:9ee91f5c7944516169bb7a327d81ac7b08b149b3cd238b7a11a61bc1abe28ba9"
      "flathub-beta:runtime/com.valvesoftware.Steam.Utility.vkBasalt//beta" # this runtime is cursed for some reason
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
    overrides = {
      "org.mozilla.firefox" = {
        filesystems = [
          "xdg-home/foobar"
          "!host"
        ];
        environment = {
          "MOZ_ENABLE_WAYLAND" = 1;
        };
        sockets = [
          "!x11"
          "fallback-x11"
        ];
      };
    };
    state-dir = "/yes";
    # target-dir = "/deployment";
    deduplicate = false;
    enable-debug = true;
  };

  # Dev env stuff
  environment.loginShellInit = ''
    trap 'sudo poweroff' EXIT
  '';

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = with pkgs; [
      xdg-desktop-portal-kde
    ];
  };

  environment.systemPackages = with pkgs; [
    tmux ncdu eza
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
  
  services.getty.autologinUser = "user";
  users.users."user" = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "password";
    shell = pkgs.zsh;
  };
  home-manager.users."user" = { lib, pkgs, nixosConfig, ... }: {
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
      enable-debug = true;
      deduplicate = false;
      preRemotesCommand = "echo silly1";
      preInstallCommand = "echo silly2";
      preDedupeCommand = "echo silly3";
      preSwitchCommand = "echo silly4";
    };

    home.file.".zshrc".text = "";

    home.stateVersion = "22.11";
  };

  boot.tmp.useTmpfs = true;

  system.stateVersion = "22.05";
}
