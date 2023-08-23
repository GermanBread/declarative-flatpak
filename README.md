# Declarative flatpaks

### [**NixOS** module](docs/nixos.md)
### [**Home Manager** module](docs/home-manager.md)
---
### [Module definition](docs/definition.md)

**Warning** Your setup must be able to hold the size of your flatpak installation at least twice. This module will keep the flatpak installations from the previous sucessful boot in order to not make your flatpak apps crash.

If you have >8GB of free space in `/var` (or your home directory if you use the home-manager module) everything *should* work flawlessly.