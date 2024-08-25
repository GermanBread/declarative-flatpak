```nix
{
  # Put the flatpak module in your inputs
  inputs = {
    # ... other imports ...
    flatpaks.url = "github:GermanBread/declarative-flatpak/stable-v3";
    # Please DO NOT override the "nixpkgs" input!
    # Overriding "nixpkgs" is unsupported unless stated otherwise.
    # ... other imports ...
  };

  # Put the flatpaks input anywhere in the output function arguments
  outputs = { ..., flatpaks, ... }: {
    # <host> is a placeholder for your hostname
    nixosConfigurations.<host> = nixpkgs.lib.nixosSystem {
      # Import the flatpaks module here
      modules = [
        # ... other modules ...
        flatpaks.nixosModules.default
        # ... other modules ...
        # ... other files ...
        ./configuration.nix
        # ... other files ...
      ];
    };
  };
}
```
> [!NOTE]
> This example is not a fully functional config. It is rather a guide to show you where you should import the module in your `flake.nix`.