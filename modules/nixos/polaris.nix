{ config, lib, pkgs, utils, ... }:
let
  inherit (lib) mkEnableOption mkPackageOption mkOption mkIf mkDefault types optionals getExe;
  inherit (utils) escapeSystemdExecArgs;
  cfg = config.services.polaris;

  # polaris inherits sunshine's port layout: a single base port with fixed offsets
  # see https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/advanced_usage.html#port
  generatePorts = port: offsets: map (offset: port + offset) offsets;
  defaultPort = 47989;

  settingsFormat = pkgs.formats.keyValue { };
  appsFormat = pkgs.formats.json { };

  configFile = settingsFormat.generate "polaris.conf" cfg.settings;
  appsFile = appsFormat.generate "apps.json" cfg.applications;

  # When wrapped via security.wrappers (cap_sys_admin+p), the kernel sets
  # AT_SECURE=1 and the loader ignores LD_LIBRARY_PATH. Bake libevdi into
  # the binary's RUNPATH (which is honored under AT_SECURE) so dlopen finds it.
  evdiPkg = config.boot.kernelPackages.evdi;
  polarisBin =
    if cfg.evdi.enable then
      pkgs.runCommand "${cfg.package.pname}-evdi-${cfg.package.version}" {
        nativeBuildInputs = [ pkgs.patchelf ];
      } ''
        install -Dm755 ${cfg.package}/bin/polaris $out/bin/polaris
        patchelf --add-rpath ${evdiPkg}/lib $out/bin/polaris
      ''
    else cfg.package;
in
{
  # nixpkgs ships an unrelated `services.polaris` (Polaris Music Server) under
  # the same namespace; take it over so consumers get the GameStream host.
  disabledModules = [ "services/misc/polaris.nix" ];

  options.services.polaris = with types; {
    enable = mkEnableOption "Polaris, a self-hosted GameStream host for Moonlight/Nova (Sunshine fork)";
    package = mkPackageOption pkgs "polaris" { };
    openFirewall = mkOption {
      type = bool;
      default = false;
      description = "Whether to automatically open Polaris ports in the firewall.";
    };
    capSysAdmin = mkOption {
      type = bool;
      default = false;
      description = "Whether to give the Polaris binary CAP_SYS_ADMIN, required for DRM/KMS screen capture.";
    };
    autoStart = mkOption {
      type = bool;
      default = true;
      description = "Whether the Polaris user service should be started automatically.";
    };
    evdi.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable the EVDI virtual-display backend: loads the evdi kernel module
        and exposes libevdi to the Polaris service. Required for headless
        streaming on hosts without a wlroots compositor or kscreen-doctor.
      '';
    };
    settings = mkOption {
      default = { };
      description = ''
        Settings rendered into polaris.conf. If non-default, web UI configuration is disabled.
      '';
      example = lib.literalExpression ''
        {
          headless_mode = "enabled";
          linux_use_cage_compositor = "enabled";
          encoder = "nvenc";
        }
      '';
      type = submodule (_: {
        freeformType = settingsFormat.type;
        options.port = mkOption {
          type = port;
          default = defaultPort;
          description = "Base port; other ports are offset from this.";
        };
      });
    };
    applications = mkOption {
      default = { };
      description = "Applications exposed to Moonlight (apps.json).";
      type = submodule {
        options = {
          env = mkOption {
            default = { };
            description = "Environment variables for the applications.";
            type = attrsOf str;
          };
          apps = mkOption {
            default = [ ];
            description = "Applications to be exposed to Moonlight.";
            type = listOf attrs;
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.polaris.settings.file_apps = mkIf (cfg.applications.apps != [ ]) "${appsFile}";

    environment.systemPackages = [ cfg.package ];

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = generatePorts cfg.settings.port [ (-5) 0 1 21 ];
      allowedUDPPorts = generatePorts cfg.settings.port [ 9 10 11 13 21 ];
    };

    boot.kernelModules = [ "uinput" "uhid" ] ++ lib.optional cfg.evdi.enable "evdi";
    boot.extraModulePackages = lib.optional cfg.evdi.enable config.boot.kernelPackages.evdi;

    services.udev.packages = [ cfg.package ];

    services.avahi = {
      enable = mkDefault true;
      publish = {
        enable = mkDefault true;
        userServices = mkDefault true;
      };
    };

    security.wrappers.polaris = mkIf cfg.capSysAdmin {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_admin+p";
      source = "${polarisBin}/bin/polaris";
    };

    systemd.user.services.polaris = {
      description = "Self-hosted GameStream host for Moonlight (Polaris)";

      # default.target is reached on user systemd start (login);
      # graphical-session.target is only soft-ordered, since some DEs
      # (XFCE under NixOS lightdm/autoLogin) never activate it.
      wantedBy = mkIf cfg.autoStart [ "default.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];

      # Runtime executables polaris discovers via PATH (mirrors upstream's
      # CPACK_RPM_PACKAGE_REQUIRES in cmake/packaging/linux.cmake).
      path = with pkgs; [
        labwc       # private cage compositor for headless stream
        grim        # wayland screenshot
        wlr-randr   # configure headless outputs on the cage compositor
        xwayland    # XWayland for X11 game launches
        xorg.xdpyinfo
      ];

      startLimitIntervalSec = 500;
      startLimitBurst = 5;

      serviceConfig = {
        # pass configFile only when the user customised settings beyond the default port,
        # otherwise leave web-UI configuration unlocked
        ExecStart = escapeSystemdExecArgs ([
          (if cfg.capSysAdmin then "${config.security.wrapperDir}/polaris" else "${polarisBin}/bin/polaris")
        ] ++ optionals (cfg.applications.apps != [ ]
              || builtins.length (builtins.attrNames cfg.settings) > 1
              || cfg.settings.port != defaultPort) [ "${configFile}" ]);
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
