{ writeShellScriptBin }:

writeShellScriptBin "run-tests" ''
  nix flake check ./tests --print-build-logs
''