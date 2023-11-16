```nix
{
  inputs = {
    flatpaks.url = "github:GermanBread/declarative-flatpak/stable";
    # Please DO NOT override the "nixpkgs" input!
    # Overriding "nixpkgs" is unsupported unless stated otherwise.
  };

  outputs = { self, flatpaks, nixpkgs}: {
    nixosConfigurations = {
      flatpaks = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          flatpaks.nixosModules.default
          ./configuration.nix
        ];
      };
    };
  };
}
```

Build it using:
```
nixos-rebuild build --flake .#flatpaks
```
