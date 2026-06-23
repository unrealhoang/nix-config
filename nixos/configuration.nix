# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    inputs.catppuccin.nixosModules.catppuccin
    inputs.niri.nixosModules.niri
    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Sunshine game-stream host (Moonlight server), plain desktop capture
    ./sunshine.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.customs
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      inputs.llm-agents.overlays.default

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
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

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
  networking.interfaces.enp5s0.wakeOnLan.enable = true;
  networking.hostName = "unrealPc";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      47984
      47989
      47990
      48010
      22
      5900
      3389
      8080
      3001
      5173
    ];
    allowedUDPPorts = [ 3389 ];
    allowedUDPPortRanges = [
      {
        from = 47998;
        to = 48000;
      }
      {
        from = 8000;
        to = 8010;
      }
    ];
  };

  catppuccin = {
    # Lock in per-port opt-in behavior before upstream flips the default to
    # auto-enroll. enable = true is the new global toggle; autoEnable = false
    # preserves the current behavior of only enabling explicitly-named ports.
    enable = true;
    autoEnable = false;
    flavor = "mocha";
    grub.enable = true;
  };
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      timeoutStyle = "hidden";
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      memtest86.enable = true;
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
      extraGroups = [
        "wheel"
        "docker"
        "networkmanager"
        # Headless-Sunshine: lets the user's sway-sunshine / sunshine services
        # read /dev/input/event* and create /dev/uinput devices without a
        # logind seat (see ./sunshine.nix).
        "input"
      ];
      shell = pkgs.zsh;
    };
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
    zsh
    steam
    steam-run
    clinfo
    wayvnc
    llm-agents.codex
    # Second, isolated Steam instance rooted at /mnt/data2/SteamOld (see
    # pkgs/steam-old). Also launched by the headless Sunshine stream (./sunshine.nix).
    steam-old
    # Launcher entry for the steam-old wrapper above (fuzzel/noctalia, etc.).
    # No steam:// mime handler so it doesn't hijack links from the main Steam.
    (makeDesktopItem {
      name = "steam-old";
      desktopName = "Steam (Old Library)";
      comment = "Separate Steam instance rooted at /mnt/data2/SteamOld";
      exec = "steam-old";
      icon = "steam";
      terminal = false;
      categories = [ "Game" ];
      keywords = [
        "Steam"
        "Valve"
        "Games"
      ];
    })
  ];

  programs.mosh.enable = true;

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
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
      (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" # lua
        ''
          bluez_monitor.rules = {
            matches = {
              { { "device.name", "matches", "bluez_card.*" }, },
            },
            apply_properties = {
               ["bluez5.auto-connect"]  = "[ a2dp_sink ]",
            },
          }
        ''
      )
    ];
  };
  services.blueman.enable = true;
  hardware.bluetooth.enable = true;

  programs.fuse.userAllowOther = true;
  programs.zsh.enable = true;

  # programs.hyprland = {
  #   enable = true;
  #   package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  #   portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  # };

  programs.niri = {
    enable = true;
    # Stable niri, prebuilt on niri.cachix.org. Sunshine streams the real niri
    # output via wlr-screencopy (no virtual-output build needed).
    package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-stable;
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "unreal" ];
  };

  programs.seahorse.enable = true;
  security.pam.services = {
    # hyprlock = { };
    login.enableGnomeKeyring = true;
  };
  services.ratbagd.enable = true;
  services.tailscale.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  # Autologin `unreal` straight into niri so the box comes up with a live
  # compositor on cold boot — required for headless Sunshine streaming and so
  # the niri session can be restarted remotely (`systemctl restart
  # display-manager`) without a physical login. Tradeoff: physical access to
  # the machine yields an unlocked desktop, and gnome-keyring/1Password may
  # need a manual unlock since the PAM login-password handoff is skipped.
  services.displayManager = {
    defaultSession = "niri";
    autoLogin = {
      enable = true;
      user = "unreal";
    };
  };

  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        # All keyboards EXCEPT Sunshine's virtual keyboard (vendor 0xbeef /
        # product 0xdead). Otherwise keyd grabs it exclusively and re-emits on
        # its own "keyd virtual keyboard", which the headless sway (./sunshine.nix)
        # doesn't listen to — so streamed keyboard input never reaches apps.
        # Leaving it ungrabbed lets sway read the Sunshine keyboard directly.
        ids = [
          "*"
          "-beef:dead"
        ];
        settings = {
          main = {
            capslock = "layer(control)";
          };
        };
      };
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";
}
