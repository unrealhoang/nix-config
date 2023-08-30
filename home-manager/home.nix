# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.default

    # Or modules exported from other flakes (such as nix-colors):
    inputs.nix-colors.homeManagerModules.default
    inputs.hyprland.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
    ./features/tmux/default.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
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
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  # TODO: Set your username
  home = {
    username = "unreal";
    homeDirectory = "/home/unreal";
  };

  programs.alacritty.enable = true;
  # Add stuff for your user as you see fit:
  wayland.windowManager.hyprland = {
    enable = true;
    enableNvidiaPatches = false;
    extraConfig = ''
    $mod = SUPER

    bind = $mod,t,exec,alacritty
    bind = $mod,return,exec,alacritty
    bind = $mod,d,exec,firefox
    # workspaces
    # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
    ${builtins.concatStringsSep "\n" (builtins.genList (
        x: let
          ws = builtins.toString (x + 1);
        in ''
          bind = $mod, ${ws}, workspace, ${ws}
          bind = $mod SHIFT, ${ws}, movetoworkspace, ${ws}
        ''
      )
      9)}
    '';
  };

  programs.neovim.enable = true;
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland;
  };
  home.packages = with pkgs; [ steam ];

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
