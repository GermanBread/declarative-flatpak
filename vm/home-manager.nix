{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users."user" =
      { lib, ... }:
      {
        imports = [
          ../home-manager
        ];

        services.flatpak = {
          veryVerbose = true;
          packages = [
            "flathub-beta:app/org.mozilla.firefox//beta"
            "flathub:app/com.usebottles.bottles//stable:e53e9e154949a9e542f94a5dbd2422446e4e7c15aa62e11e4a0aeaba09be446f"
          ];
          remotes = {
            "flathub" = "https://flathub.org/repo/flathub.flatpakrepo";
            "flathub-beta" = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
          };
          #flatpakDir = "${config.home.homeDirectory}/flatpak";
        };

        home = {
          file.".zshrc".text = "";
          stateVersion = lib.trivial.release;
          sessionVariables = {
            #FLATPAK_USER_DIR = config.services.flatpak.flatpakDir;
          };
        };
      };
  };
}
