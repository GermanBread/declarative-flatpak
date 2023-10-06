# services.flatpak.**enableModule**
## Default
```nix
config.services.flatpak.enable
```
## Description
Enable/disable this module.
If your NixOS config has `services.flatpak.enable` set to `true`, this module will be activated automatically.

# services.flatpak.**deduplicate**
## Default
```nix
true
```
## Description
Try to save space by deduplicating generations.

May take a very long time.

# services.flatpak.**state-dir**
## Default
```nix
null
```
## Description
Path where to place the flatpak generations

By default will be:
- `/var/lib/flatpak-module` (for NixOS)
- `~/.local/state/flatpak-module` (for home-manager)

If left at default value, the corresponding directory will be picked.
# services.flatpak.**target-dir**
## Default
```nix
null
```
## Description
Path where to link the flatpak file to.

By default will be:
- `/var/lib/flatpak` (for NixOS)
- `~/.local/share/flatpak` (for home-manager)

If left at default value, the corresponding directory will be picked.

# services.flatpak.**recycle-generation**
## Default
```nix
false
```
## Description
Instead of creating a new generation from scratch, try to re-use the old generation but just run `flatpak update` on it.
This might significantly reduce bandwidth usage.

**WARNING:** EXPERIMENTAL /// MIGHT BE RISKY TO USE

# services.flatpak.**packages**
## Default
```nix
[]
```
## Example
```nix
[ "flathub:app/org.kde.index//stable" "flathub-beta:app/org.kde.kdenlive/x86_64/stable" ]

# out-of-tree flatpaks can be installed like this (note: they can't be a URL because flatpak doesn't like that)
[ ":${./foobar.flatpak}" "flathub:/root/testflatpak.flatpakref" ]
```
## Description
Which packages to install.

Use this format: `<remote name>:<type>/<flatpak ref>/<arch>/<branch>:<commit>`

Replace `<remote-name>` with the remote name you want to install from.
Replace `<type>` with either "runtime" or "app".
Replace `<arch>` with the CPU architecture, may be omitted (but the slash needs to be kept)
Replace `<branch-name`> with the name of the application branch.
Replace `<commit>` with a given commit, or leave it out entirely

# services.flatpak.**preInitCommand**
## Description
Which commands to run before installation.

If left at the default value, nothing will be done.

# services.flatpak.**postInitCommand**
Which commands to run after installation.

If left at the default value, nothing will be done.

# services.flatpak.**remotes**
## Default
```nix
{}
```
## Example
```nix
{
  "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
  "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
}
```
## Description
Declare flatpak remotes.

May only contain uppercase and lowercase ASCII characters and hyphens.

# services.flatpak.**overrides**

## Default
```nix
{}
```

## Example
```nix
services.flatpak.overrides = {
  "global" = {
    filesystems = [
      "home"
      "!~/Games/Heroic"
    ];
    environment = {
      "MOZ_ENABLE_WAYLAND" = 1;
    };
    sockets = [
      "!x11"
      "fallback-x11"
    ];
  };
}
```

## Description
Overrides to apply.

Paths prefixed with '!' will deny read permissions for that path, also applies to sockets.
Paths may not be escaped.

## Note on overrides:

If you want to apply specialised overrides, do so by running commands via postInitCommand