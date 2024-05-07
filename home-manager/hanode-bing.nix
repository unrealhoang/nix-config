{ inputs, outputs, ... }: {
  # You can import other home-manager modules here
  imports = [
    ./features/neovim
    ./features/tmux
    ./features/zsh
    inputs.catppuccin.homeManagerModules.catppuccin
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
    username = "bing";
    homeDirectory = "/home/bing";
  };
  programs.home-manager.enable = true;

  home.stateVersion = "24.05";
}
