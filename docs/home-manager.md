```nix
{
  inputs = {
    flatpaks.url = "github:GermanBread/declarative-flatpak/stable";
    # Please DO NOT override the "nixpkgs" input!
    # Overriding "nixpkgs" is unsupported unless stated otherwise.
  };

  outputs = { flatpaks }: {
    homeConfigurations.<user> = home-manager.lib.homeManagerConfiguration {
      modules = [
        flatpaks.homeManagerModules.default

        ./home.nix
      ];
    };
  };
}
```

#### Alternatively, you can pass the module down to your `home.nix` (or any other file where needed) and import it there.