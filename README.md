# Declarative flatpaks

### [**NixOS** module](docs/nixos.md)
### [**Home Manager** module](docs/home-manager.md)
---
### [Module definition](docs/definition.md)

---

#### How to use it?
- If you want to use the home-manager NixOS module, you have add it to your NixOS flake inputs and then pass it down to your home.nix and import the module there.

- If you want to use the NixOS module, add it in your NixOS flake inputs (if it isn't there already), pass it down to configuration.nix and then import the NixOS module there.

Also, to use the module, you have to use the prefix services.flatpak instead of config.services.flatpak.

---

**Warning** Your setup must be able to hold the size of your flatpak installation at least two times. This module will keep the flatpak installations from the previous successful boot in order to not make your flatpak apps crash. Each "generation" will be deduplicated.

If you have >8GB of free space in `/var` (or your home directory if you use the home-manager module) everything *should* work flawlessly (unless you use massive flatpaks, then account for these too).
