{ inputs, outputs, ... }: {
  # You can import other home-manager modules here
  imports = [
    ./features/zsh
    inputs.catppuccin.homeModules.catppuccin
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

  # catppuccin/nix is moving to: `enable` = global on/off toggle, `autoEnable` =
  # auto-enroll every supported port. Adopt the new semantics explicitly to
  # silence the migration warning while preserving current behavior (no ports
  # themed): global toggle on, but nothing auto-enrolled.
  catppuccin = {
    enable = true;
    autoEnable = false;
  };

  # Stable SSH agent socket symlink so tmux sessions always find the agent
  programs.zsh.initContent = ''
    if [ -S "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent.sock" ]; then
      ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
      export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
    fi
  '';

  programs.tmux.enable = true;
  programs.tmux.extraConfig = ''
    set-environment -g SSH_AUTH_SOCK "$HOME/.ssh/agent.sock"
  '';

  home.stateVersion = "24.05";
}
