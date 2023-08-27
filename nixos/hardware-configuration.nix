{ config, lib, ... }:

{
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/9bb0d0ba-2700-413f-823a-9286331b55d2";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/62E4-44DA";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/cdeb6614-9f88-4be1-99e2-f9c45fbe2c80"; }
    ];

  # Set your system kind (needed for flakes)
  nixpkgs.hostPlatform = "x86_64-linux";

  networking.useDHCP = lib.mkDefault true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
