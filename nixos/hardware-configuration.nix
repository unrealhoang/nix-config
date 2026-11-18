{ config, lib, pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelParams =
    [ "amdgpu.dc=1" "video=DP-1:3840x2160@60" "video=DP-2:3840x2160@60" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9bb0d0ba-2700-413f-823a-9286331b55d2";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/62E4-44DA";
    fsType = "vfat";
  };

  # Nix store on the Samsung 860 EVO (sdb2, formerly the Arch install) rather
  # than the DRAM-less Transcend that holds /. By label so the UUID doesn't
  # need to be known before `mkfs.ext4 -L nix`.
  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nix";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/0d518695-1f02-4ac8-81bc-43a33e6f9505";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/mnt/data2" = {
    device = "/dev/disk/by-uuid/58117334-6c91-4525-95e3-3c87007e385e";
    fsType = "ext4";
    neededForBoot = true;
  };

  # By label: the swap partition at the end of sdb was recreated during the
  # /nix move, so its UUID changed.
  swapDevices = [{ device = "/dev/disk/by-label/swap"; }];

  # Set your system kind (needed for flakes)
  nixpkgs.hostPlatform = "x86_64-linux";

  networking.useDHCP = lib.mkDefault true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.graphics = { extraPackages = with pkgs; [ rocmPackages.clr.icd ]; };
  hardware.enableRedistributableFirmware = true;
}
