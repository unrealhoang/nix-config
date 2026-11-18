# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{
  inputs,
  outputs,
  lib,
  pkgs,
  ...
}:
let
  # claude-code comes from llm-agents.nix (same input that provides codex in
  # nixos/configuration.nix), not from nixpkgs or a dedicated overlay.
  claude-code = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
  mkClaudeProfile =
    name:
    pkgs.writeShellScriptBin "claude-${name}" ''
      export CLAUDE_CONFIG_DIR="$HOME/.claude-${name}"
      exec ${claude-code}/bin/claude "$@"
    '';
in
{
  # You can import other home-manager modules here
  imports = [

    # Or modules exported from other flakes (such as nix-colors):
    inputs.nix-colors.homeManagerModules.default
    inputs.catppuccin.homeModules.catppuccin

    # You can also split up your configuration and import pieces of it here:
    ./features/alacritty
    ./features/git
    ./features/herdr
    ./features/neovim
    ./features/niri
    ./features/signal
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

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
  # TODO: Set your username
  home = {
    username = "unreal";
    homeDirectory = "/home/unreal";
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      BROWSER = "firefox";
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = lib.mkForce "fcitx";
      XMODIFIERS = "@im=fcitx";
    };

    persistence = {
      "/mnt/data/Shared" = {
        directories = [
          ".mozilla"
          "dotfiles"
          ".claude-personal"
          ".claude-work"
        ];
      };
      "/mnt/data" = {
        directories = [
          "Resources"
          "Workspace"
          "Downloads"
        ];
      };
    };
  };
  userConf = {
    gitFolderConfigs = {
      "/mnt/data/Workspace/H2/" = "/mnt/data/Workspace/H2/.gitconfig";
    };
  };
  catppuccin = {
    # See nixos/configuration.nix for rationale (per-port opt-in lockdown).
    enable = true;
    autoEnable = false;
    flavor = "mocha";
    tmux.enable = true;
    starship.enable = true;
    alacritty.enable = true;
    btop.enable = true;
  };

  services.gnome-keyring = {
    enable = true;
    components = [
      "pkcs11"
      "secrets"
      "ssh"
    ];
  };

  xdg = {
    enable = true;
    # Thunar handles "Open Containing Folder" from Firefox and any other app
    # that opens a directory via xdg-open (inode/directory MIME type).
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "thunar.desktop";
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
      };
    };
    # Apps (and xdg-mime itself) write mimeapps.list at runtime, so an
    # unmanaged copy is usually already present. Let HM own it declaratively
    # instead of refusing to clobber it.
    configFile."mimeapps.list".force = true;
  };
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
    unzip
    remmina
    chromium
    antimicrox
    pnpm
    protontricks
    jq
    awscli2
    thunderbird
    xvkbd
    (mkClaudeProfile "personal")
    (mkClaudeProfile "work")
    inputs.tgfs.packages.${pkgs.stdenv.hostPlatform.system}.tgfs
    ethtool
    mosh
  ];

  # Stable SSH agent socket at ~/.ssh/agent.sock. tmux pins SSH_AUTH_SOCK to
  # this path (see extraConfig below), so we keep the symlink pointed at
  # whichever agent is appropriate for the current session:
  #   - In an SSH session with a forwarded agent, use the forwarded socket
  #     (the client's 1Password), preserving the existing tmux-forwarding setup.
  #   - Otherwise (a local, non-SSH login — e.g. the autologin niri session),
  #     fall back to this host's own 1Password SSH agent so git can still
  #     authenticate to GitHub. gnome-keyring's ssh component also sets
  #     SSH_AUTH_SOCK on local login, but its agent doesn't hold the GitHub
  #     key, so we override it here.
  programs.zsh.initContent = ''
    if [ -n "$SSH_CONNECTION" ] && [ -S "$SSH_AUTH_SOCK" ]; then
      if [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent.sock" ]; then
        ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
        export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
      fi
    elif [ -S "$HOME/.1password/agent.sock" ]; then
      ln -sf "$HOME/.1password/agent.sock" "$HOME/.ssh/agent.sock"
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
  nixpkgs.config.chromium.commandLineArgs = "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --enable-wayland-ime --ozone-platform=wayland";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
}
