{ flatpak, ... }: {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  
  home-manager.users."user" = { config, ... }: {
    imports = [
      flatpak.homeManagerModules.default
    ];

    services.flatpak = {
      packages = [
        "flathub-beta:app/org.chromium.Chromium//beta"
        "flathub:app/com.usebottles.bottles//stable"
      ];
      remotes = {
        "flathub" = "https://flathub.org/repo/flathub.flatpakrepo";
        "flathub-beta" = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      };
      enable-debug = true;
      state-dir = "${config.home.homeDirectory}/flatpak/state";
      target-dir = "${config.home.homeDirectory}/flatpak/deploy";
    };

    home.file.".zshrc".text = "";

    home.stateVersion = "22.11";
  };
}