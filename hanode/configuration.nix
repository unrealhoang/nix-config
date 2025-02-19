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
      package = pkgs.nixVersions.stable;
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
    services.pulseaudio.enable = false;
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
    services.openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        UseDns = true;
      };
    };

    # Open ports in the firewall.
    networking = {
      nat = {
        enable = true;
        externalInterface = "eth0";
        internalInterfaces = [ "wg0" ];
      };
      firewall = {
        allowedTCPPorts = [ 22 21 53 80 443 ];
        allowedUDPPorts = [ 53 51820 ];
      };
      wireguard = {
        enable = true;
        interfaces = {
          wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
            ips = [ "10.100.0.1/24" ];

            # The port that WireGuard listens to. Must be accessible by the client.
            listenPort = 51820;

            # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
            # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
            postSetup = ''
              ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
            '';

            # This undoes the above command
            postShutdown = ''
              ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
            '';

            # Path to the private key file.
            #
            # Note: The private key can also be included inline via the privateKey option,
            # but this makes the private key world-readable; thus, using privateKeyFile is
            # recommended.
            privateKey = "cBmXmNDWAkmrIbAXC+38t/pxRvzdTYpeCLw+wLdJG04=";
            peers = [
              # List of allowed peers.
              { # Feel free to give a meaning full name
                # Public key of the peer (not a file path).
                publicKey = "MZPri8Fwy2ljIxSpqIEkTxGfZNL4svZpP4pJGDvURlk=";
                # List of IPs assigned to this peer within the tunnel subnet. Used to configure routing.
                allowedIPs = [ "10.100.0.2/32" ];
              }
            ];
          };
        };
      };
    };

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

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
        vpl-gpu-rt
        libvdpau-va-gl
      ];
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
