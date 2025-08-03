# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, outputs, lib, config, pkgs, ... }@args: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example
    inputs.catppuccin.nixosModules.catppuccin
    inputs.impermanence.nixosModules.impermanence
    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.customs
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";

    package = pkgs.nixVersions.latest;
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}")
      config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
      trusted-users = [ "unreal" ];
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 14d";
    };
  };

  time.timeZone = "Asia/Tokyo";
  networking.hostName = "unrealPc";
  networking.networkmanager.enable = true;

  catppuccin.flavor = "mocha";
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      catppuccin.enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      memtest86.enable = true;
      extraFiles = { "memtest.bin" = "${pkgs.memtest86plus}/memtest.bin"; };
    };
  };

  virtualisation.docker.enable = true;
  environment.persistence."/mnt/data2/persist" = {
    directories = [
      "/var/lib/nixos"
      "/var/lib/docker"
      "/var/lib/bluetooth"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
    ];
  };

  # TODO: Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    unreal = {
      initialPassword = "123";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      # TODO: Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
      extraGroups = [ "wheel" "docker" "networkmanager" ];
      shell = pkgs.zsh;
    };
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
    zsh
    helvum
    steam
    steam-run
    clinfo
    inputs.hyprlock.packages.${pkgs.system}.hyprlock
  ];
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  services.openssh = {
    enable = true;
    # Forbid root login through SSH.
    settings = {
      PermitRootLogin = "no";
      AllowAgentForwarding = true;
    };
  };
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplip ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # rtkit is optional but recommended
  security.polkit.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.configPackages = [
      (pkgs.writeTextDir
        "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" # lua
        ''
          bluez_monitor.rules = {
            matches = {
              { { "device.name", "matches", "bluez_card.*" }, },
            },
            apply_properties = {
               ["bluez5.auto-connect"]  = "[ a2dp_sink ]",
            },
          }
        '')
    ];
  };
  services.blueman.enable = true;
  hardware.bluetooth.enable = true;

  programs.fuse.userAllowOther = true;
  programs.zsh.enable = true;

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "unreal" ];
  };

  programs.seahorse.enable = true;
  security.pam.services = {
    hyprlock = { };
    login.enableGnomeKeyring = true;
  };
  services.ratbagd.enable = true;
  services.tailscale.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
