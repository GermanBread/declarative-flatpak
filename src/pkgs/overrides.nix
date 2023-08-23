{ lib
, pkgs
, writeText
, cfg
, ref }:

writeText "flatpak-override-for-${ref}" ''
  [Context]
  ${if cfg.overrides.${ref}.filesystems != null then ''
  filesystems=${builtins.concatStringsSep ";" cfg.overrides.${ref}.filesystems}
  '' else ""}
  ${if cfg.overrides.${ref}.sockets != null then ''
  sockets=${builtins.concatStringsSep ";" cfg.overrides.${ref}.sockets}
  '' else ""}

  [Environment]
  ${if cfg.overrides.${ref}.environment != null then ''
  ${builtins.concatStringsSep ";" (builtins.map (envname: let
    envvalue = cfg.overrides.${ref}.environment.${envname};
  in ''
  ${envname}=${builtins.toString envvalue}
  '') (builtins.attrNames (cfg.overrides.${ref}.environment or [])))}
  '' else ""}
''