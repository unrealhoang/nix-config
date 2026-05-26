# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, outputs, lib, pkgs, ... }: {
  # You can import other home-manager modules here
  imports = [

    # Or modules exported from other flakes (such as nix-colors):
    inputs.nix-colors.homeManagerModules.default
    inputs.catppuccin.homeModules.catppuccin

    # You can also split up your configuration and import pieces of it here:
    ./features/alacritty
    ./features/git
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
      inputs.claude-code-nix.overlays.default

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

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
  # TODO: Set your username
  home = {
    username = "unreal";
    homeDirectory = "/home/unreal";

    persistence = {
      "/mnt/data/Shared" = {
        directories = [ ".mozilla" "dotfiles" ];
      };
      "/mnt/data" = {
        directories = [ "Resources" "Workspace" "Downloads" ];
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
    fcitx5.addons = with pkgs; [ qt6Packages.fcitx5-unikey ];
  };
  fonts.fontconfig.enable = true;

  # Add stuff for your user as you see fit:
  colorscheme = inputs.nix-colors.colorSchemes.ayu-dark;

  programs.firefox = {
    enable = true;
  };
  home.packages = with pkgs; [
    # fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
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
    thunar
    ristretto
    tumbler
    remmina
    chromium
    antimicrox
    pnpm
    protontricks
    jq
    awscli2
    thunderbird
    xvkbd
    claude-code
    ethtool
    mosh
  ];

  # Stable SSH agent socket symlink for tmux agent forwarding
  programs.zsh.initContent = ''
    if [ -S "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent.sock" ]; then
      ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
      export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
    fi
  '';
  programs.tmux.extraConfig = ''
    set-environment -g SSH_AUTH_SOCK "$HOME/.ssh/agent.sock"
  '';

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
  home.stateVersion = "26.05";
}
