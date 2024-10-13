{ pkgs, ... }: {
  nixos-shell.mounts = {
    mountHome = false;
    mountNixProfile = false;
  };

  virtualisation = {
    cores = 8;
    memorySize = 8096 * 2;
    diskSize = 64 * 1024;
  };

  services.flatpak = {
    packages = [ # comment these out at random
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.MangoHud//21.08:9ee91f5c7944516169bb7a327d81ac7b08b149b3cd238b7a11a61bc1abe28ba9"
      "flathub-beta:runtime/com.valvesoftware.Steam.Utility.vkBasalt//beta" # this runtime is cursed for some reason
      "flathub:app/org.kde.index//stable"
      
      "flathub-beta:app/org.mozilla.firefox//stable"
      
      "launcher-moe:app/moe.launcher.honkers-launcher/x86_64/master"

      "flathub:runtime/org.gtk.Gtk3theme.Breeze//3.22"

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
      "org.test.App" = {
        # Intentionally leave out everything for bugfix
      };
    };
    # flatpak-dir = "/flatpak";
    # debug = true;
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
    tmux ncdu xdg-utils
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

  services.getty.autologinUser = "user";
  users.users."user" = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "password";
    shell = pkgs.zsh;
  };

  boot.tmp.useTmpfs = true;

  system.stateVersion = "22.05";
}
