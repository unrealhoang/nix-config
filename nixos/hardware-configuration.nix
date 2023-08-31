{ config, lib, pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelParams = [
    "video=DP-1:3840x2160@60"
    "video=DP-2:3840x2160@60"
  ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/9bb0d0ba-2700-413f-823a-9286331b55d2";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/62E4-44DA";
      fsType = "vfat";
    };

  fileSystems."/mnt/arch" =
    { device = "/dev/disk/by-uuid/334e9200-6c9b-4f45-a3c8-4bc223e2c234";
      fsType = "ext4";
    };

  fileSystems."/mnt/data" =
    { device = "/dev/disk/by-uuid/0d518695-1f02-4ac8-81bc-43a33e6f9505";
      fsType = "ext4";
      neededForBoot = true;
    };

  fileSystems."/mnt/data2" =
    { device = "/dev/disk/by-uuid/58117334-6c91-4525-95e3-3c87007e385e";
      fsType = "ext4";
      neededForBoot = true;
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/cdeb6614-9f88-4be1-99e2-f9c45fbe2c80"; }
    ];

  # Set your system kind (needed for flakes)
  nixpkgs.hostPlatform = "x86_64-linux";

  networking.useDHCP = lib.mkDefault true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.opengl.driSupport = true;
  hardware.enableRedistributableFirmware = true;
}
