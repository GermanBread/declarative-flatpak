```nix
{
  inputs = {
    # ...
    flatpaks.url = "github:GermanBread/declarative-flatpak/stable";
    # Please DO NOT override the "nixpkgs" input!
    # Overriding "nixpkgs" is unsupported unless stated otherwise.
    # ...
  };

  outputs = { ..., flatpaks, ... }: {
    nixosConfigurations.<host> = nixpkgs.lib.nixosSystem {
      # ...
      modules = [
        # ...
        flatpaks.nixosModules.default
        # ...
        ./configuration.nix
        # ...
      ];
      # ...
    };
  };
}
```
