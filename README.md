# Declarative flatpaks

## Setup

Here is how you can import the [**NixOS** module](docs/nixos.md) and [**Home Manager** module](docs/home-manager.md) respectively.

## Usage

When imported, new options will be made available under `services.flatpak`. Please refer to the [**Module definition**](docs/definition.md) for configuration options.

> [!IMPORTANT]
> The stable branch is versioned. You will get notified when it gets obsoleted read [here](docs/branches.md) for more info.

> [!NOTE]
> Your setup must be able to hold the size of your flatpak installation at least twice.

> [!NOTE]
> Contrary to popular belief, this module was never intended to implement "generational rollbacks". The *unique* directory layout was created to enable atomic updates for flatpak.