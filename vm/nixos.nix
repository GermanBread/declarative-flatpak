{
  virtualisation = {
    cores = 8;
    memorySize = 8096 * 2;
    diskSize = 16 * 1024;
    
    qemu.options = [
      "-device virtio-vga"
    ];
  };
}