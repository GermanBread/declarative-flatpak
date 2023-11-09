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

**Warning**

Do not import the module inside `home.nix`

```nix
{ pkgs, flakes, ... }: {
   imports = [
     # dont include here
   ];
}
```

Relevant issue: nix-community/nixvim#83