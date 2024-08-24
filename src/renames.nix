{ lib, ... }: let
  inherit (lib) mkRenamedOptionModule;
in 

{
  imports = [
    (mkRenamedOptionModule [ "services" "flatpak" "enable-debug" ] [ "services" "flatpak" "debug" ])
    (mkRenamedOptionModule [ "services" "flatpak" "target-dir" ] [ "services" "flatpak" "flatpak-dir" ])
  ];
}