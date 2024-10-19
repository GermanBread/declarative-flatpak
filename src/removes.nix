{ lib, ... }: let
  inherit (lib) mkRemovedOptionModule;
in 

{
  imports = [
    (mkRemovedOptionModule [ "services" "flatpak" "preDedupeCommand" ] "Since deduplication has been removed, this hook had to go.")
    (mkRemovedOptionModule [ "services" "flatpak" "deduplicate" ] "This option has been made redundant due to internal script changes.")
    (mkRemovedOptionModule [ "services" "flatpak" "state-dir" ] "This module does not rely on a state dir anymore.")
  ];
}