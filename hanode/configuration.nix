{ lib, inputs, pkgs, config, ... }:

{
  options = {
    my-settings.mediaDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/media";
      description = "Path to media store, accessible by the media services";
    };
  };
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.impermanence.nixosModules.impermanence
  ];

  config = {
    nix = {
      package = pkgs.nixFlakes;
      settings = {
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";
        # Deduplicate and optimize nix store
        auto-optimise-store = true;
        trusted-users = [ "unreal" "bing" ];
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
    services.pipewire = { enable = false; };

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
        ExecStartPre =
          "${pkgs.curl}/bin/curl -Lo /var/blocklist.hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        ExecStart =
          "${pkgs.gnused}/bin/sed -i '/^0.0.0.0/!d' /var/blocklist.hosts";
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
        base = locations: {
          inherit locations;

          forceSSL = true;
          enableACME = true;
          acmeRoot = null;
        };
        proxy = { port, ws ? true, host ? "localhost" }:
          base {
            "/" = {
              proxyPass = "http://${host}:" + builtins.toString (port) + "/";
              proxyWebsockets = ws;
            };
          };
      in {
        "${grafConf.domain}" = proxy {
          host = grafConf.http_addr;
          port = grafConf.http_port;
        };
        "ha.binginu.homes" = proxy { port = 8123; };
        "jellyfin.binginu.homes" = proxy { port = 8096; };
        "seer.binginu.homes" =
          proxy { port = config.services.jellyseerr.port; };
        "aria.binginu.homes" = base { "/" = { }; } // {
          root = "${pkgs.ariang}/share/ariang";
        };
        "ariarpc.binginu.homes" =
          proxy { port = config.services.aria2.rpcListenPort; };
        "radarr.binginu.homes" = proxy { port = 7878; };
        "sonarr.binginu.homes" = proxy { port = 8989; };
      };
    };

    services.prometheus = let promConf = config.services.prometheus;
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
            targets = [ "localhost:${toString promConf.exporters.node.port}" ];
          }];
        }
        {
          job_name = "coredns";
          static_configs = [{ targets = [ "localhost:9153" ]; }];
        }
      ];
    };
    services.grafana = {
      enable = true;
      settings = {
        server = {
          domain = "grafana.binginu.homes";
          http_port = 2345;
          http_addr = "127.0.0.1";
        };
      };
    };
    users.groups.media = { members = [ "bing" "aria2" "jellyfin" ]; };
    environment.persistence."/mnt/data/persist" = {
      directories = [{
        directory = config.my-settings.mediaDir;
        user = "bing";
        group = "media";
        mode = "0770";
      }];
    };
    my-settings.mediaDir = "/mnt/data/Downloads/Videos";
    services.aria2 = {
      enable = true;
      openPorts = true;
      downloadDir = config.my-settings.mediaDir;
      rpcSecretFile = "/etc/aria2/secret";
      extraArguments = "--rpc-allow-origin-all";
    };
    systemd.tmpfiles.rules =
      [ "d '${config.my-settings.mediaDir}' 0770 aria2 media - -" ];

    systemd.services.aria2.serviceConfig.Group = lib.mkForce "media";

    services.coredns = {
      enable = true;
      config = ''
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
    networking.firewall.allowedTCPPorts = [ 8123 21 53 80 443 ];
    networking.firewall.allowedUDPPorts = [ 53 1900 7359 ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    virtualisation.oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        volumes = [ "home-assistant:/config" ];
        environment.TZ = "Asia/Tokyo";
        image =
          "ghcr.io/home-assistant/home-assistant:stable"; # Warning: if the tag does not change, the image will not be updated
        extraOptions = [
          "--network=host"
          "--device=/dev/ttyACM0:/dev/ttyACM0" # Example, change this to match your own hardware
        ];
      };
    };

    # 1. enable vaapi on OS-level
    nixpkgs.config.packageOverrides = pkgs: {
      jellyfin-ffmpeg = pkgs.jellyfin-ffmpeg.override {
        ffmpeg_6-full = pkgs.ffmpeg_6-full.override {
          withMfx = false;
          withVpl = true;
        };
      };
    };

    hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
        onevpl-intel-gpu
        libvdpau-va-gl
      ];
    };

    # 2. do not forget to enable jellyfin
    environment.variables = {
      NEOReadDebugKeys = "1";
      OverrideGpuAddressSpace = "48";
    };
    systemd.services."jellyfin".environment = {
      NEOReadDebugKeys = "1";
      OverrideGpuAddressSpace = "48";
    };
    services.jellyfin = { enable = true; };
    services.jellyseerr.enable = true;
    services.radarr = {
      enable = true;
      group = "media";
    };
    services.sonarr = {
      enable = true;
      group = "media";
    };
    services.cloudflare-dyndns = {
      enable = true;
      apiTokenFile = "/var/lib/secrets/cf_token.secret";
      domains = [ "home.binginu.homes" ];
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.05"; # Did you read the comment?
  };
}
