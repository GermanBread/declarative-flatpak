# Declarative flatpaks

> **Warning**
> I tested this module on my dev host.
> It may not work on yours.
> If it doesn't, open an issue!

## Installation using flakes

`/etc/nixos/flake.nix`
```nix
{
  inputs = {
    # ...
    flatpaks.url = "github:GermanBread/declarative-flatpaks/stable";
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

## Module definition

### services.flatpak.**packages**

```
default:
  []

example:
  [ "org.kde.index" "org.kde.kdenlive" ]

description:
  Which packages to install. Package names vary from distro to distro.
```

### services.flatpak.**preInitCommand**

```
default:
  null

description:
  Which command to run before installtion.

  WARNING:
  Multiline strings have to be escaped properly, like so:
  foo && \
    bar
```

### services.flatpak.**postInitCommand**

```
default:
  null

description:
  Which command to run after installation.

  WARNING:
  Multiline strings have to be escaped properly, like so:
  foo && \
    bar