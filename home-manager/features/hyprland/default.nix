{ inputs, pkgs, lib, ... }:

let
  workspaces = (map toString (lib.range 0 9));
  # Map keys to hyprland directions
  directions = rec {
    left = "l";
    right = "r";
    up = "u";
    down = "d";
    h = left;
    l = right;
    k = up;
    j = down;
  };
  grimblast = inputs.hyprland-contrib.packages.${pkgs.system}.grimblast;
  pkgs-hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;
  pkgs-hyprlock = inputs.hyprlock.packages.${pkgs.system}.hyprlock;
  # pkgs-waybar = inputs.waybar.packages.${pkgs.system}.waybar;

  hyprlock = "${pkgs-hyprlock}/bin/hyprlock";
  hyprctl = "${pkgs-hyprland}/bin/hyprctl";
  notifysend = "${pkgs.libnotify}/bin/notify-send";
  loginctl = "${pkgs.systemd}/bin/loginctl";
  pidof = "${pkgs.procps}/bin/pidof";
in {
  home.packages = with pkgs; [
    wofi
    swaybg
    wlsunset
    wl-clipboard
    pavucontrol
    xdg-desktop-portal-gtk
    xdg-utils
    waybar
    dunst
    python3
    playerctl
    pamixer
    networkmanagerapplet
    hyprpicker
    grimblast
    dualsensectl
    notify-desktop
  ];

  home.file.".config/wofi.css".source = ./wofi.css;
  home.file.".config/waybar/config".source = ./waybar/config;
  home.file.".config/waybar/style.css".source = ./waybar/style.css;
  home.file.".config/waybar/dualsense-notifier.sh".source =
    (pkgs.concatScript "dualsense-notifier.sh" [
      (pkgs.writeText "icon-path" ''
        icon_path="${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark/24x24@2x/apps/preferences-desktop-gaming.svg"
      '')
      ./waybar/dualsense-notifier.sh
    ]);
  home.file.".config/dunst".source = ./dunst;
  home.file.".config/hypr/game_mode.sh" = {
    source = ./game_mode.sh;
    executable = true;
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      background = [{
        monitor = "";
        path = "~/Pictures/Wallpapers/fuji.png";
        blur_passes = 1;
        contrast = 0.8916;
        brightness = 0.8172;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      }];
      input-field = [{
        monitor = "";
        size = "250, 60";
        outline_thickness = 2;
        dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
        dots_spacing = 0.2; # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = true;
        outer_color = "rgba(0, 0, 0, 0)";
        inner_color = "rgba(0, 0, 0, 0.5)";
        font_color = "rgb(200, 200, 200)";
        fade_on_empty = false;
        placeholder_text =
          ''<i><span foreground="##cdd6f4">Input Password...</span></i>'';
        hide_input = false;
        position = "0, -120";
        halign = "center";
        valign = "center";
      }];
      label = [
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$(date +"%-I:%M%p")"'';
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 120;
          font_family = "JetBrains Mono Nerd Font Mono ExtraBold";
          position = "0, -300";
          halign = "center";
          valign = "top";
        }
        {
          monitor = "";
          text = "Hi there, $USER";
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 25;
          font_family = "JetBrains Mono Nerd Font Mono";
          position = "0, -40";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${pidof} ${hyprlock} || ${hyprlock}";
        before_sleep_cmd = "${loginctl} lock-session";
        after_sleep_cmd = "${hyprctl} dispatch dpms on";
      };
      listener = [{
        timeout = 300;
        on-timeout = "${hyprlock}";
        on-resume = ''${notifysend} "Welcome back!"'';
      }];
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs-hyprland;

    settings = {
      debug = { disable_logs = false; };
      env = [
        "XCURSOR_THEME,Bibata-Modern-Amber"
        "XCURSOR_SIZE,24"
        "GDK_SCALE,2"
        "XDG_CURRENT_DESKTOP,Hyprland"
      ];
      exec-once = [
        "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
        "${pkgs.dunst}/bin/dunst"
        # "hyprctl setcursor Bibata-Modern-Amber 24"
        "waybar"
        "nm-applet --indicator"
      ];
      monitor = [
        "DP-1,3840x2160@60,0x0,2,bitdepth,8"
        "DP-2,3840x2160@60,1920x0,2,bitdepth,8"
      ];
      workspace = [ "4,monitor:DP-1" "5,monitor:DP-1,decorate:false" ];
      windowrulev2 = [
        "float,class:org.kde.polkit-kde-authentication-agent-1"
        "move 100 100,class:(1Password),title:(1Password)"
        "workspace 5,class:(dota2),title:(Dota 2)"
        "workspace 4,class:(steam)"
        "workspace 5,class:(thunderbird)"
      ];
      bindm = [ "SUPER,mouse:272,movewindow" "SUPER,mouse:273,resizewindow" ];
      bind = [
        "SUPER,f9,exec,~/.config/hypr/game_mode.sh"
        "SUPER,d,exec,wofi --show run --xoffset=1670 --yoffset=12 --width=230px --height=984 --style=$HOME/.config/wofi.css --term=footclient --prompt=Run"
        "SUPERSHIFT,q,killactive"
        "SUPERSHIFT,e,exit"

        "SUPER,s,togglesplit"
        "SUPER,f,fullscreen,1"
        "SUPERSHIFT,f,fullscreen,0"
        "SUPERSHIFT,space,togglefloating"

        "SUPER,minus,splitratio,-0.25"
        "SUPERSHIFT,minus,splitratio,-0.3333333"

        "SUPER,equal,splitratio,0.25"
        "SUPERSHIFT,equal,splitratio,0.3333333"

        "SUPER,g,togglegroup"
        "SUPER,tab,changegroupactive,f"
        "SUPERSHIFT,tab,changegroupactive,b"

        # apps
        "SUPER,return,exec,alacritty"
        "SUPERSHIFT,return,exec,firefox"

        # screenshot
        "SUPERSHIFT,v,exec,grimblast save output ~/Pictures/Screenshots/ss-$(date +%Y-%m-%d_%T).png"
        "SUPERSHIFT,b,exec,grimblast save area ~/Pictures/Screenshots/ss-$(date +%Y-%m-%d_%T).png"
      ] ++ (map (n: "SUPER,${n},workspace,name:${n}") workspaces)
        ++ (map (n: "SUPERSHIFT,${n},movetoworkspace,name:${n}") workspaces)
        ++ (lib.mapAttrsToList
          (key: direction: "SUPER,${key},movefocus,${direction}") directions) ++
        # Swap windows
        (lib.mapAttrsToList
          (key: direction: "SUPERSHIFT,${key},movewindoworgroup,${direction}")
          directions) ++
        # Move workspace to other monitor
        (lib.mapAttrsToList (key: direction:
          "SUPERALT,${key},movecurrentworkspacetomonitor,${direction}")
          directions);

      general = {
        gaps_in = 3;
        gaps_out = 6;
        border_size = 2;
        "col.active_border" = "$lavender";
        "col.inactive_border" = "$overlay0";
      };
      # cursor = {
      #   inactive_timeout = 4;
      # };
      group = {
        "col.border_active" = "$lavender";
        "col.border_inactive" = "$overlay0";
        groupbar = { text_color = "$rosewater"; };
      };
      xwayland = { force_zero_scaling = true; };
      binds = { workspace_back_and_forth = true; };
      dwindle.split_width_multiplier = 1.35;
      misc = {
        vfr = "on";
        focus_on_activate = true;
      };

      device = {
        name = "logitech-ergo-m575s";
        scroll_method = "on_button_down";
        scroll_button = 274;
        scroll_button_lock = true;
      };
      decoration = {
        active_opacity = 1;
        inactive_opacity = 0.84;
        fullscreen_opacity = 1.0;
        rounding = 5;
        blur = {
          enabled = true;
          size = 5;
          passes = 3;
          new_optimizations = true;
          ignore_opacity = true;
        };
        shadow = {
          enabled = true;
          color = "0x44000000";
          color_inactive = "0x66000000";
          offset = "3 3";
          range = 6;
        };
      };
      animations = {
        enabled = true;
        bezier = [
          "easein,0.11, 0, 0.5, 0"
          "easeout,0.5, 1, 0.89, 1"
          "easeinback,0.36, 0, 0.66, -0.56"
          "easeoutback,0.34, 1.56, 0.64, 1"
        ];

        animation = [
          "windowsIn,1,3,easeoutback,slide"
          "windowsOut,1,3,easeinback,slide"
          "windowsMove,1,3,easeoutback"
          "workspaces,1,2,easeoutback,slide"
          "fadeIn,1,3,easeout"
          "fadeOut,1,3,easein"
          "fadeSwitch,1,3,easeout"
          "fadeShadow,1,3,easeout"
          "fadeDim,1,3,easeout"
          "border,1,3,easeout"
        ];
      };
    };
    extraConfig = "";
  };
}
