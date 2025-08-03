{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other home-manager modules here
  imports = [
    ./features/alacritty
    ./features/git
    ./features/neovim
    ./features/tmux
    ./features/zsh
    ./features/nushell
    ./features/user-configurations
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };
  home = {
    username = "unreal";
    homeDirectory = "/Users/unreal";
  };
  programs.home-manager.enable = true;
  userConf = {
    terminalFontSize = 12.0;
    gitGpgSSHSignProgram =
      "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    gitFolderConfigs = {
      "/Users/unreal/Workspace/H2/" = "/Users/unreal/Workspace/H2/.gitconfig";
    };
    shellProgram = "${pkgs.zsh}/bin/zsh";
  };
  tmuxOpts.shell = config.userConf.shellProgram;

  catppuccin = {
    flavor = "mocha";
    tmux.enable = true;
    starship.enable = true;
    alacritty.enable = true;
  };

  home.packages = with pkgs;
    [
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka

      docker-client
      nushell
      lima
      uv
      awscli2
      mitmproxy
      duckdb
      cloudflared
    ];

  fonts.fontconfig.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.stateVersion = "23.05";
}
