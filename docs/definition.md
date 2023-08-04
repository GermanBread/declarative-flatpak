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

Use this format: `<remote name>:<type>/<flatpak ref>/<arch>/<branch>`

`<type>` needs to be one of "app" or "runtime"
`<arch>` may be omitted, but the slash needs to be kept.
`<remote name>` is subject to the remote naming constraints.

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

# Note on overrides:

If you want to apply overrides, do so by running commands via postInitCommand

Eventually I will figure out a way to do overrides declaratively, but this will do