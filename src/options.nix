{ mkOption, types }:

{
  packages = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "org.kde.index" "org.kde.kdenlive" ];
    description = ''
      Which packages to install.
    '';
  };
  preInitCommand = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = ''
      Which command(s) to run before installation.
    '';
  };
  postInitCommand = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = ''
      Which command(s) to run after installation.
    '';
  };
}