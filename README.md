# Global FHS environment for NixOS

Possible thanks to OCI containers!

> **Warning**
> I tested this module on my dev host.
> It may not work on yours.
> If it doesn't, open an issue!

I recommend you use this in a setup where `/` gets wiped every reboot.

## Installation using flakes

`/etc/nixos/flake.nix`
```nix
{
  inputs = {
    # ...
    fhs.url = "github:GermanBread/nixos-fhs/stable";
    # ...
  };

  outputs = { ..., fhs, ... }: {
    nixosConfigurations.<host> = nixpkgs.lib.nixosSystem {
      # ...
      modules = [
        # ...
        fhs.nixosModules.default
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

### services.fhs-compat.**distro**

```
default:
  "arch"

example:
  one of "debian", "arch", "void"

description:
  Which distro to use for bootstrapping the FHS environment.
```

### services.fhs-compat.**tmpfsSize**

```
default:
  "2G"

description:
  How big the tmpfs mounted on $mountPoint should be.
  Sizes must have a valid suffix.
```

### services.fhs-compat.**mountPoint**

```
default:
  "/.fhs"

description:
  Where the FHS environment will be installed to.
```

### services.fhs-compat.**mountBinDirs**

```
default:
  false

example:
  true

description:
  Whether or not to put a bind mount over /bin and /usr.
  Both will redirect to their counterparts in $mountPoint.

  This option does not affect /sbin.
```

### services.fhs-compat.**packages**

```
default:
  []

example:
  [ "neofetch" "sdl2" ]

description:
  Which packages to install. Package names vary from distro to distro.
```

### services.fhs-compat.**preInitCommand**

```
default:
  null

description:
  Which command to run on a fresh container.

  WARNING:
  Multiline strings have to be escaped properly, like so:
  foo && \
    bar
```

### services.fhs-compat.**postInitCommand**

```
default:
  null

example:
  "pacman -R neofetch sdl2";

description:
  Which command to run after packages have been installed.

  WARNING:
  Multiline strings have to be escaped properly, like so:
  foo && \
    bar