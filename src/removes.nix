{ lib, ... }: let
  inherit (lib) mkRemovedOptionModule;
in 

{
  imports = [
    (mkRemovedOptionModule [ "services" "flatpak" "preDedupeCommand" ] ''
      This option has been removed.
    '')
    (mkRemovedOptionModule [ "services" "flatpak" "deduplicate" ] ''
      The option has been removed.
    '')
  ];
}