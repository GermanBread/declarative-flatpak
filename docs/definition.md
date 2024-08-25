| OPTION                         | DEFAULT   | TYPE               |
|--------------------------------|-----------|--------------------|
| enableModule                   | see below | `bool`             |
| flatpak-dir                    | see below | `path` or `null`   |
| packages                       | `[]`      | see below          |
| remotes                        | `{}`      | see below          |
| overrides                      | `{}`      | see below          |
| preRemotesCommand              | `null`    | `string` or `null` |
| preInstallCommand              | `null`    | `string` or `null` |
| preSwitchCommand               | `null`    | `string` or `null` |
| UNCHECKEDpostEverythingCommand | `null`    | `string` or `null` |

---

# The "see below" part

## services.flatpak.**enableModule**
### Default
```nix
config.services.flatpak.enable
```
(If home-manager used as NixOS module: Value is read from NixOS host config)
### Description
Enable/disable this module.
If your NixOS config has `services.flatpak.enable` set to `true`, this module will be activated automatically.

> [!IMPORTANT]
> The home-manager module will try to read the value of `services.flatpak.enable` from the **NixOS host**, it will never provide it's own `services.flatpak.enable` option, you will have to set `services.flatpak.enableModule` in your user config if you use home-manager as standalone.

## services.flatpak.**flatpak-dir**
### Default
```nix
null
```
### Description
Path where your flatpak installation is located.

By default will be:
- `/var/lib/flatpak` (for NixOS)
- `~/.local/share/flatpak` (for home-manager)

If left at default value, the corresponding directory will be picked.

## services.flatpak.**packages**
### Default
```nix
[]
```
### Example
```nix
[ "flathub:app/org.kde.index//stable" "flathub-beta:app/org.kde.kdenlive/x86_64/stable" ]

# out-of-tree flatpaks can be installed like this (note: they can't be a URL because flatpak doesn't like that)
[ ":${./foobar.flatpak}" "flathub:/root/testflatpak.flatpakref" ]
```
### Description
Which packages to install.

Use this format: `<remote name>:<type>/<flatpak ref>/<arch>/<branch>:<commit>`

Replace `<remote-name>` with the remote name you want to install from.
Replace `<type>` with either "runtime" or "app".
Replace `<arch>` with the CPU architecture, may be omitted (but the slash needs to be kept)
Replace `<branch-name`> with the name of the application branch.
Replace `<commit>` with a given commit, or leave it out entirely

## services.flatpak.**remotes**
### Default
```nix
{}
```
### Example
```nix
{
  "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
  "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
}
```
### Description
Declare flatpak remotes.

May only contain uppercase and lowercase ASCII characters and hyphens.

## services.flatpak.**overrides**

### Default
```nix
{}
```

### Example
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

### Description
Overrides to apply.

Paths prefixed with '!' will deny read permissions for that path, also applies to sockets.
Paths have to be escaped manually.

> [!NOTE]
> If you want to apply specialised overrides, do so by running commands via preSwitchCommand

## services.flatpak.**preRemotesCommand**
### Description
Which commands to run before remoted are configured.

All essential variables have been initialized by now.

## services.flatpak.**preInstallCommand**
### Description
Which commands to run before refs are installed.

## services.flatpak.**preSwitchCommand**
### Description
Which commands to run before the generation is activated.

## services.flatpak.**UNCHECKEDpostEverythingCommand**
### Description
Which commands to run after the script completed execution.

> [!CAUTION]
> The error status of this command will NOT be checked. Errors that occur will NOT prevent the generation from being activated!