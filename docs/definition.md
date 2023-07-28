# services.flatpak.**packages**
## Default
```nix
null
```
## Example
```nix
[ "flathub:org.kde.index//stable" "flathub-beta:org.kde.kdenlive/x86_64/stable" ]
```
## Description
Which packages to install.

Use this format: `<remote name>:<flatpak ref>/<arch>/<branch>`

`<arch>` may be omitted, but the slash needs to be kept.
`<remote name>` is subject to the remote naming constraints.

If left at the default value, nothing will be done.

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
null
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

If left at the default value, nothing will be done.