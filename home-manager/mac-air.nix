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
    shellProgram = "${pkgs.nushell}/bin/nu";
  };
  tmuxOpts.shell = config.userConf.shellProgram;
  catppuccin.flavor = "mocha";

  home.packages = with pkgs;
    [
      (nerdfonts.override {
        fonts = [ "FiraCode" "DroidSansMono" "JetBrainsMono" "Iosevka" ];
      })
      docker-client
      nushell
    ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.stateVersion = "23.05";
}
