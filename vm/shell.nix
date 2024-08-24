{
  nixos-shell.mounts = {
    mountHome = false;
    mountNixProfile = false;
  };

  virtualisation = {
    cores = 8;
    memorySize = 8096 * 2;
    diskSize = 16 * 1024;
  };
}