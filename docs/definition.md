# services.flatpak.**packages**
## default
```
[]
```
## example
```
[ "org.kde.index" "org.kde.kdenlive" ]
```
## description
```
Which packages to install. Package names vary from distro to distro.
```
# services.flatpak.**preInitCommand**
## description
```
Which command to run before installtion.
```
## WARNING
### Multiline strings have to be escaped properly, like so:
```
foo && \
  bar
```
# services.flatpak.**postInitCommand**
```
Which command to run after installation.
```
## WARNING:
### Multiline strings have to be escaped properly, like so:
```
foo && \
  bar
```