{ pkgs, config, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix = {
    package = pkgs.nixFlakes;
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
    };
  };

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 2;
  };

  networking.hostName = "hanixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  # networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = false;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  programs.zsh.enable = true;
  users.users.bing = {
    isNormalUser = true;
    description = "bing";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin = {
    enable = true;
    user = "bing";
  };

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  services.xserver.displayManager.gdm.autoSuspend = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = [ ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "unrealhoang+acme@gmail.com";
      dnsProvider = "cloudflare";
      environmentFile = "/var/lib/secrets/certs.secret";
    };
  };

  #### COREDNS ####

  systemd.services.updateBlocklist = {
    description = "Update blocklist";
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.curl}/bin/curl -Lo /var/blocklist.hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
      ExecStart = "${pkgs.gnused}/bin/sed -i '/^0\.0\.0\.0/!d' /var/blocklist.hosts";
    };
    wantedBy = [ "multi-user.target" ];
  };

    # run this service once a day
  systemd.timers.updateBlocklist = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Unit = "updateBlocklist.service";
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = let
      grafConf = config.services.grafana.settings.server;
    in {
      "${grafConf.domain}" = {
        locations."/" = {
          proxyPass = let
            addr = grafConf.http_addr;
            port = builtins.toString grafConf.http_port;
          in "http://${addr}:${port}";
          proxyWebsockets = true;
        };
      };
      "jellyfin.binginu.homes" = {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        locations."/" = {
          proxyPass = "http://localhost:8096";
          proxyWebsockets = true;
        };
      };
      "ha.hanode.me" = {
        locations."/" = {
          proxyPass = "http://localhost:8123";
          proxyWebsockets = true;
        };
      };
      "aria.binginu.homes" = {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        root = "${pkgs.ariang}/share/ariang";
        locations."/" = { };
      };
      "ariarpc.binginu.homes" = {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        locations."/" = {
          proxyPass = let
            port = config.services.aria2.rpcListenPort;
          in "http://localhost:${builtins.toString port}";
          proxyWebsockets = true;
        };
      };
    };
  };

  services.prometheus = let
    promConf = config.services.prometheus;
  in {
    enable = true;
    port = 9001;

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = ["localhost:${toString promConf.exporters.node.port}"];
        }];
      }
      {
        job_name = "coredns";
        static_configs = [{
          targets = ["localhost:9153"];
        }];
      }
    ];
  };
  services.grafana = {
    enable = true;
    settings = {
      server = {
        domain = "grafana.hanode.me";
        http_port = 2345;
        http_addr = "127.0.0.1";
      };
    };
  };
  services.aria2 = {
    enable = true;
    openPorts = true;
    downloadDir = "/mnt/data/Downloads/Videos";
    rpcSecretFile = "/etc/aria2/secret";
    extraArguments = "--rpc-allow-origin-all";
  };
  services.coredns = {
    enable = true;
    config =
    ''
      . {
        prometheus localhost:9153
        reload 10s
        hosts /var/blocklist.hosts {
          fallthrough
        }
        # Cloudflare Forwarding
        forward . 1.1.1.1 1.0.0.1
        cache
      }
    '';
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
      8123
      21
      53
      80
      443
  ];
  networking.firewall.allowedUDPPorts = [
    53
    1900
    7359
  ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      volumes = [ "home-assistant:/config" ];
      environment.TZ = "Asia/Tokyo";
      image = "ghcr.io/home-assistant/home-assistant:stable"; # Warning: if the tag does not change, the image will not be updated
      extraOptions = [
        "--network=host"
        "--device=/dev/ttyACM0:/dev/ttyACM0"  # Example, change this to match your own hardware
      ];
    };
  };

  # 1. enable vaapi on OS-level
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
    ];
  };

  # 2. do not forget to enable jellyfin
  services.jellyfin.enable = true;


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
