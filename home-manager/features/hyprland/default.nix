{ inputs, pkgs, lib, config, ... }:

let
  workspaces =
    (map toString (lib.range 0 9));
  # Map keys to hyprland directions
  directions = rec {
    left = "l"; right = "r"; up = "u"; down = "d";
    h = left; l = right; k = up; j = down;
  };
in
{
  home.packages = with pkgs; [
    wofi swaybg wlsunset wl-clipboard
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  ];
  home.file.".config/wofi.css".source = ./wofi.css;

  wayland.windowManager.hyprland = {
    enable = true;

    enableNvidiaPatches = false;
    settings = {
      monitor = [
        "DP-1,3840x2160@60,0x0,2"
        "DP-2,3840x2160@60,1920x0,2"
      ];
      bindm = [
        "SUPER,mouse:272,movewindow"
        "SUPER,mouse:273,resizewindow"
      ];
      bind = [
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
        "SUPER,apostrophe,changegroupactive,f"
        "SUPERSHIFT,apostrophe,changegroupactive,b"

	# apps
	"SUPER,return,exec,alacritty"
	"SUPERSHIFT,return,exec,firefox"
      ] ++
      (map (n:
        "SUPER,${n},workspace,name:${n}"
      ) workspaces) ++
      (map (n:
        "SUPERSHIFT,${n},movetoworkspace,name:${n}"
      ) workspaces) ++
      (lib.mapAttrsToList (key: direction:
        "SUPER,${key},movefocus,${direction}"
      ) directions) ++
      # Swap windows
      (lib.mapAttrsToList (key: direction:
        "SUPERSHIFT,${key},swapwindow,${direction}"
      ) directions) ++
      # Move workspace to other monitor
      (lib.mapAttrsToList (key: direction:
        "SUPERALT,${key},movecurrentworkspacetomonitor,${direction}"
      ) directions);

      general = {
        gaps_in = 15;
        gaps_out = 20;
        border_size = 2.7;
        cursor_inactive_timeout = 4;
        "col.active_border" = "0xff${config.colorscheme.colors.base0C}";
        "col.inactive_border" = "0xff${config.colorscheme.colors.base02}";
        "col.group_border_active" = "0xff${config.colorscheme.colors.base0B}";
        "col.group_border" = "0xff${config.colorscheme.colors.base04}";
      };
      dwindle.split_width_multiplier = 1.35;
      misc.vfr = "on";

      decoration = {
        active_opacity = 0.94;
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
        drop_shadow = true;
        shadow_range = 12;
        shadow_offset = "3 3";
        "col.shadow" = "0x44000000";
        "col.shadow_inactive" = "0x66000000";
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
    extraConfig = ''
    '';
  };
  programs.eww = {
    enable = true;
    package = pkgs.eww-wayland;
    configDir = ./eww;
  };
}
