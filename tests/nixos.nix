{ nixosTest }:

nixosTest {
  name = "NixOS test";

  nodes = {
    bare = { config, pkgs, ... }: {

    };
  };

  testScript = ''
    bare.fail("false");
    bare.succeed("true");
  '';
}