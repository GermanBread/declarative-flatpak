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
    # <user> is a placeholder for your username
    homeConfigurations.<user> = home-manager.lib.homeManagerConfiguration {
      # Import the flatpaks module here
      modules = [
        # ... other modules ...
        flatpaks.homeManagerModules.default
        # ... other modules ...
        # ... other files ...
        ./home.nix
        # ... other files ...
      ];
    };
  };
}
```
> [!NOTE]
> This example is not a fully functional config. It is rather a guide to show you where you should import the module in your `flake.nix`.

> [!CAUTION]
> Do not import the module inside `home.nix`
> ```nix
> { pkgs, flakes, ... }: {
>    imports = [
>      # dont include here
>    ];
> }
> ```
> Relevant issue: nix-community/nixvim#83