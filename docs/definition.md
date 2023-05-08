# services.flatpak.**packages**
## Default
```nix
null
```
## Example
```nix
[ "flathub:org.kde.index" "flathub-beta:org.kde.kdenlive" ]
```
## Description
Which packages to install.

Use this format: `<remote name>:<flatpak ref>`

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
  "flathub" = "https://flathub.org/repo/flathub.flatpakrepo";
  "flathub-beta" = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
};
```
## Description
Declare flatpak remotes.

If left at the default value, nothing will be done.