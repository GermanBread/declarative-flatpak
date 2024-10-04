{ lib, pkgs, ... }: {
  # Credit: https://github.com/PJungkamp #23 #25
  ini = pkgs.formats.ini {
    listToValue = lib.concatMapStringsSep ";" (lib.generators.mkValueStringDefault {});
  };
}