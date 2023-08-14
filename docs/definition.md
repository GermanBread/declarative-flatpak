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