{ pkgs, ... }:
{
  virtualisation = {
    graphics = false;
    cores = 4;
    memorySize = 1024 * 4;
    diskSize = 1024 * 64;
    qemu = {
      consoles = [
        "tty0"
        "hvc0"
      ];
      options = [
        "-serial null"
        "-device virtio-serial"
        "-chardev stdio,mux=on,id=char0,signal=off"
        "-mon chardev=char0,mode=readline"
        "-device virtconsole,chardev=char0,nr=0"
      ];
    };
  };

  documentation.enable = false;

  services.flatpak = {
    enable = true;
    packages = [
      # comment these out at random
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.MangoHud//21.08:9ee91f5c7944516169bb7a327d81ac7b08b149b3cd238b7a11a61bc1abe28ba9"
      #"flathub-beta:runtime/com.valvesoftware.Steam.Utility.vkBasalt//beta" # this runtime is cursed for some reason
      "flathub:app/org.kde.index//stable"
      "flathub-beta:app/org.mozilla.firefox//stable"
      "flathub:app/moe.launcher.honkers-launcher/x86_64/stable"
      "flathub:runtime/org.gtk.Gtk3theme.Breeze//3.22"
      "flathub:${./files/io.gitlab.daikhan.stable.flatpakref}"
      ":${./files/xwaylandvideobridge.flatpak}"
    ];
    remotes = {
      "flathub" = "https://flathub.org/repo/flathub.flatpakrepo";
      "flathub-beta" = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
    };
    overrides = {
      "org.mozilla.firefox" = {
        Context.filesystems = [
          "xdg-home/foobar"
          "!host"
        ];
        Environment = {
          "PATHLIKE_TEST" = [
            "/etc"
            "a"
            123
          ];
          "MOZ_ENABLE_WAYLAND" = 1;
        };
        Context.sockets = [
          "!x11"
          "fallback-x11"
        ];
      };
      # should not error
      # see https://github.com/in-a-dil-emma/declarative-flatpak/pull/60
      "org.vinegarhq.Sober".Context.devices = [ "input" ];
      "org.test.App" = {
        # Intentionally leave out everything for bugfix
      };
    };
    onCalendar = "*-*-* *:00,15,30,45:00";
    flatpakDir = "/flatpak";
    veryVerbose = true;
  };

  # Dev env stuff
  environment.loginShellInit = ''
    trap 'sudo poweroff' EXIT
  '';

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = with pkgs; [
      xdg-desktop-portal
    ];
  };

  environment.systemPackages = with pkgs; [
    tmux
    ncdu
    xdg-utils
  ];

  networking = {
    hostName = "test-vm";
    networkmanager.enable = true;
  };

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
