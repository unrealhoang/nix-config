# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.default

    # Or modules exported from other flakes (such as nix-colors):
    inputs.nix-colors.homeManagerModules.default
    inputs.impermanence.nixosModules.home-manager.impermanence
    # inputs.hyprland.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
    ./features/alacritty
    ./features/git
    ./features/hyprland
    ./features/neovim
    ./features/slack
    ./features/tmux
    ./features/zsh
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

  home.persistence."/mnt/data/Shared" = {
    directories = [
      ".mozilla"
      "dotfiles"
    ];
    allowOther = false;
  };
  home.persistence."/mnt/data" = {
    directories = [
      "Resources"
      "Workspace"
      "Downloads"
    ];
    allowOther = true;
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
    fcitx5.addons = with pkgs; [
      fcitx5-unikey
    ];
  };
  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    NIXOS_OZONE_WL = "1";
  };
  fonts.fontconfig.enable = true;

  # Add stuff for your user as you see fit:
  colorscheme = inputs.nix-colors.colorSchemes.dracula;

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland;
  };
  home.packages = with pkgs; [
    steam telegram-desktop
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    proggyfonts
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "JetBrainsMono" ]; })
    gnumake
  ];

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
