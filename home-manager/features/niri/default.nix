{
  inputs,
  pkgs,
  lib,
  ...
}:

let
  # Apps spawned from niri keybinds — refer to them via absolute store paths
  # so PATH ordering inside the niri session can't break the launchers.
  alacrittyBin = "${pkgs.alacritty}/bin/alacritty";
  firefoxBin = "${pkgs.firefox}/bin/firefox";
  fuzzelBin = "${pkgs.fuzzel}/bin/fuzzel";
  grimBin = "${pkgs.grim}/bin/grim";
  slurpBin = "${pkgs.slurp}/bin/slurp";
  wlCopyBin = "${pkgs.wl-clipboard}/bin/wl-copy";
in
{
  imports = [
    # The niri-flake NixOS module wires the HM `programs.niri` options in
    # automatically via nixos/common.nix; importing homeModules.niri here
    # would double-declare them. Only noctalia needs an explicit HM import.
    inputs.noctalia-shell.homeModules.default
  ];

  home.packages = with pkgs; [
    fuzzel # app launcher
    wl-clipboard
    grim
    slurp # screenshots
    xdg-desktop-portal-gtk
    xdg-utils
    pavucontrol
    networkmanagerapplet
    brightnessctl
    playerctl
    pamixer
    libnotify
    # noctalia-shell is pulled in by its home module
  ];

  programs.noctalia = {
    enable = true;
    # Minimal seed config (v5 uses TOML at ~/.config/noctalia/config.toml).
    # Most of the shell's state is managed at runtime via its settings menu;
    # values declared here are just the starting point.
    # Schema: https://docs.noctalia.dev/v5
    settings = {
      shell.font = "JetBrainsMono Nerd Font";
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };
      # Noctalia draws the wallpaper itself (replacing the old swaybg spawn).
      # `crop` is the equivalent of swaybg's `-m fill`. The default path is
      # applied to every output; the picker folder points at the same library.
      # Schema: https://docs.noctalia.dev/v5/desktop/wallpaper/
      wallpaper = {
        enabled = true;
        fill_mode = "crop";
        directory = "/home/unreal/Pictures/Wallpapers";
        default.path = "/home/unreal/Pictures/Wallpapers/fuji.png";
      };
    };
  };

  programs.niri = {
    settings = {
      # XWayland support: niri's built-in xwayland-satellite integration is
      # enabled by default but only looks for `xwayland-satellite` on niri's
      # PATH, which the SDDM-launched session doesn't carry. Pin it to the
      # niri-flake package (the unstable variant, matching niri-unstable) so X11
      # apps — e.g. Steam and many games — get a working DISPLAY.
      xwayland-satellite = {
        enable = true;
        path =
          lib.getExe
            inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.xwayland-satellite-unstable;
      };

      # Spawn noctalia-shell on session start (per
      # https://docs.noctalia.dev/v5/getting-started/compositor-settings/niri/).
      # Wallpaper is drawn by noctalia's own wallpaper service (see
      # programs.noctalia.settings.wallpaper below) — running swaybg here as
      # well meant two surfaces fought over the background layer and noctalia's
      # (briefly empty) one won, leaving niri's purple default visible.
      spawn-at-startup = [
        { command = [ "noctalia" ]; }
        # Start 1Password minimised to the tray so its SSH agent socket
        # (~/.1password/agent.sock) is available in this local autologin
        # session — home.nix points SSH_AUTH_SOCK at it when there's no
        # forwarded agent, letting git authenticate to GitHub without SSH.
        # Use the system-wrapped binary from programs._1password-gui (polkit
        # integration), referenced by absolute path per the PATH rules in
        # CLAUDE.md.
        {
          command = [
            "/run/current-system/sw/bin/1password"
            "--silent"
          ];
        }
      ];

      input = {
        keyboard.xkb.options = "caps:ctrl_modifier";
        touchpad = {
          tap = true;
          natural-scroll = true;
        };
        focus-follows-mouse.enable = false;
      };

      # Mirrors the dual-4K layout used by the hyprland feature.
      outputs."DP-1" = {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 60.0;
        };
        position = {
          x = 0;
          y = 0;
        };
        scale = 2.0;
      };
      outputs."DP-2" = {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 60.0;
        };
        # Physically mounted in portrait; rotate the output so content is upright.
        transform.rotation = 90;
        position = {
          x = 1920;
          y = 0;
        };
        scale = 2.0;
      };
      layout = {
        gaps = 6;
        border = {
          enable = true;
          width = 2;
          active.color = "#cba6f7"; # catppuccin lavender
          inactive.color = "#6c7086"; # overlay0
        };
        focus-ring.enable = false;
        preset-column-widths = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
        ];
        default-column-width.proportion = 0.5;
      };

      binds =
        with lib;
        let
          # Workspace switches mirror SUPER+N from hyprland.
          mkWorkspaceBinds = n: {
            "Mod+${toString n}".action.focus-workspace = n;
            "Mod+Shift+${toString n}".action.move-column-to-workspace = n;
          };
          workspaceBinds = lib.foldl' lib.recursiveUpdate { } (map mkWorkspaceBinds (lib.range 1 9));
        in
        workspaceBinds
        // {
          # Apps
          "Mod+Return".action.spawn = alacrittyBin;
          "Mod+Shift+Return".action.spawn = firefoxBin;
          "Mod+D".action.spawn = fuzzelBin;

          # Window control
          "Mod+Shift+Q".action.close-window = { };
          "Mod+Shift+E".action.quit = { };
          "Mod+F".action.maximize-column = { };
          "Mod+Shift+F".action.fullscreen-window = { };
          "Mod+Shift+Space".action.toggle-window-floating = { };

          # Focus (vim-style)
          "Mod+H".action.focus-column-left = { };
          "Mod+L".action.focus-column-right = { };
          "Mod+J".action.focus-window-down = { };
          "Mod+K".action.focus-window-up = { };

          # Mod+wheel scrolls focus across all columns. cooldown-ms keeps a
          # hi-res / free-spinning wheel from skipping several columns per notch.
          "Mod+WheelScrollDown" = {
            action.focus-column-right = { };
            cooldown-ms = 100;
          };
          "Mod+WheelScrollUp" = {
            action.focus-column-left = { };
            cooldown-ms = 100;
          };

          # Move columns / windows
          "Mod+Shift+H".action.move-column-left = { };
          "Mod+Shift+L".action.move-column-right = { };
          "Mod+Shift+J".action.move-window-down = { };
          "Mod+Shift+K".action.move-window-up = { };

          # Resize
          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";

          # Move workspaces between monitors
          "Mod+Alt+H".action.move-workspace-to-monitor-left = { };
          "Mod+Alt+L".action.move-workspace-to-monitor-right = { };

          # Focus next monitor
          "Mod+Comma".action.focus-monitor-next = { };

          # Audio / brightness
          "XF86AudioRaiseVolume".action.spawn = [
            "${pkgs.pamixer}/bin/pamixer"
            "-i"
            "5"
          ];
          "XF86AudioLowerVolume".action.spawn = [
            "${pkgs.pamixer}/bin/pamixer"
            "-d"
            "5"
          ];
          "XF86AudioMute".action.spawn = [
            "${pkgs.pamixer}/bin/pamixer"
            "-t"
          ];
          "XF86MonBrightnessUp".action.spawn = [
            "${pkgs.brightnessctl}/bin/brightnessctl"
            "set"
            "5%+"
          ];
          "XF86MonBrightnessDown".action.spawn = [
            "${pkgs.brightnessctl}/bin/brightnessctl"
            "set"
            "5%-"
          ];

          # Screenshots: clipboard (area) and file (output)
          "Mod+Shift+B".action.spawn = [
            "sh"
            "-c"
            "${grimBin} -g \"$(${slurpBin})\" - | ${wlCopyBin}"
          ];
          "Mod+Shift+V".action.spawn = [
            "sh"
            "-c"
            "${grimBin} ~/Pictures/Screenshots/ss-$(date +%Y-%m-%d_%H%M%S).png"
          ];
        };

      environment = {
        XCURSOR_THEME = "Bibata-Modern-Amber";
        XCURSOR_SIZE = "24";
        XDG_CURRENT_DESKTOP = "niri";
      };
    };
  };
}
