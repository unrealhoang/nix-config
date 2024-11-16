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
    inputs.catppuccin.homeManagerModules.catppuccin
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
  catppuccin.flavor = "mocha";

  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  xdg.enable = true;
  programs.btop = {
    catppuccin.enable = true;
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
    enabled = "fcitx5";
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
    (nerdfonts.override {
      fonts = [ "FiraCode" "DroidSansMono" "JetBrainsMono" "Iosevka" ];
    })
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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
