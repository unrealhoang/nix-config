# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, outputs, lib, pkgs, ... }: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.default

    # Or modules exported from other flakes (such as nix-colors):
    inputs.nix-colors.homeManagerModules.default
    inputs.impermanence.nixosModules.home-manager.impermanence
    inputs.catppuccin.homeModules.catppuccin
    # inputs.hyprland.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    ./features/alacritty
    ./features/git
    ./features/hyprland
    ./features/neovim
    ./features/slack
    ./features/tmux
    ./features/zsh
    ./features/user-configurations
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

  nix.gc.automatic = true;
  # TODO: Set your username
  home = {
    username = "unreal";
    homeDirectory = "/home/unreal";

    persistence = {
      "/mnt/data/Shared" = {
        directories = [ ".mozilla" "dotfiles" ];
        allowOther = false;
      };
      "/mnt/data" = {
        directories = [ "Resources" "Workspace" "Downloads" ];
        allowOther = true;
      };
    };

    sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = lib.mkForce "fcitx";
      XMODIFIERS = "@im=fcitx";
    };
  };
  userConf = {
    gitFolderConfigs = {
      "/mnt/data/Workspace/H2/" = "/mnt/data/Workspace/H2/.gitconfig";
    };
  };
  catppuccin = {
    flavor = "mocha";
    tmux.enable = true;
    starship.enable = true;
    alacritty.enable = true;
    btop.enable = true;
    hyprland.enable = true;
  };

  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  xdg.enable = true;
  programs.btop = {
    enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Juno";
      package = pkgs.juno-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Amber";
      package = pkgs.bibata-cursors;
    };
  };
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-gtk fcitx5-unikey fcitx5-bamboo ];
  };
  fonts.fontconfig.enable = true;

  # Add stuff for your user as you see fit:
  colorscheme = inputs.nix-colors.colorSchemes.ayu-dark;

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland;
  };
  home.packages = with pkgs; [
    # fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    proggyfonts
    jetbrains-mono
    # (nerdfonts.override {
    #   fonts = [ "FiraCode" "DroidSansMono" "JetBrainsMono" "Iosevka" ];
    # })
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono

    archcraft-font

    vscode
    gnumake
    telegram-desktop
    discord
    xfce.thunar
    xfce.ristretto
    xfce.tumbler
    remmina
    chromium
    chiaki
    antimicrox
    pnpm
    protontricks
    jq
    awscli2
    thunderbird
    xvkbd
  ];

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.obs-studio.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  nixpkgs.config.chromium.commandLineArgs =
    "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --enable-wayland-ime --ozone-platform=wayland";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # ==================================== REMOTE HYPRLAND
  # Your custom autostart script
  home.file.".local/bin/start-hyprland-remote" = {
    executable = true;
    text = ''
      #!/bin/sh
      # Start Hyprland with a specific config for remote sessions
      exec Hyprland --config ~/.config/hypr/hyprlandRemote.conf
    '';
  };

  # This will be added to your .profile
  programs.zsh.shellInit = ''
    echo HELLO
    echo $AUTOSTART_HYPR
    if [ -n "$AUTOSTART_HYPR" ] && [ "$(tty)" = "/dev/tty6" ]; then
      ~/.local/bin/start-hyprland-remote
    fi
  '';

  home.file.".config/hypr/hyprlandRemote.conf" = {
    text = ''
      # This file is managed by NixOS (home.nix)
      #
      # Hyprland configuration for remote desktop sessions via Sunshine.

      # Disable all physical monitors to ensure we only output to the virtual one.
      monitor=,disable

      # Create a virtual (headless) monitor for Sunshine to capture. [17]
      # This is the primary display for the remote session.
      exec-once = hyprctl output create headless

      # The bug workaround you discovered: create and immediately destroy another
      # headless output. This seems to kickstart Hyprland's exec/client handling
      # when no physical monitors are present.
      exec-once = sleep 2 && hyprctl output create headless && hyprctl output remove HEADLESS-2

      # Start Sunshine with a delay to ensure the Hyprland environment is fully initialized.
      exec-once = sleep 5 && sunshine
    '';
  };
  # ==================================== REMOTE HYPRLAND

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
