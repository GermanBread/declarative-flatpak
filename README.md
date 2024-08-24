# Declarative flatpaks

## Setup

Here is how you can import the [**NixOS** module](docs/nixos.md) and [**Home Manager** module](docs/home-manager.md) respectively.

## Usage

When imported, new options will be made available under `services.flatpak`. Please refer to the [**Module definition**](docs/definition.md) for configuration options.

Read [here](docs/branches.md) on how branches are named.

**Warning** Your setup must be able to hold the size of your flatpak installation at least two times. This module will keep the flatpak installations from the previous successful boot in order to not make your flatpak apps crash. Each "generation" will be deduplicated.

If you have >8GB of free space in `/var` (or your home directory if you use the home-manager module) everything *should* work flawlessly (unless you use massive flatpaks, then account for these too).