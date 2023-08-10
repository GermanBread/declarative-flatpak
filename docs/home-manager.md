```nix
{
  inputs = {
    # ...
    flatpaks.url = "github:GermanBread/declarative-flatpak/stable";
    # Do not override inputs (see nixos.md)
    # ...
  };

  outputs = { ..., flatpaks, ... }: {
    homeConfigurations.<user> = nixpkgs.lib.nixosSystem {
      # ...
      modules = [
        # ...
        flatpaks.homeManagerModules.default
        # ...
        ./home.nix
        # ...
      ];
      # ...
    };
  };
}
```
