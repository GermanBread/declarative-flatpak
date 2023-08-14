# Declarative flatpaks

### [**NixOS** module](docs/nixos.md)
### [**Home Manager** module](docs/home-manager.md)
---
### [Module definition](docs/definition.md)

**Warning** Your setup must be able to hold the size of your flatpak installation at least twice (while the module is working). Your `/tmp` needs to be able to hold the size of your flatpak installation at least least once per module use (until you reboot).

If you have >8GB of free space in `/var` (or your home directory if you use the home-manager module) and >4GB of space in `/tmp` everything *should* work flawlessly.

TL;DR: If you have 16GB of RAM installed and at least 8GB free space in `/var` you should be fine.