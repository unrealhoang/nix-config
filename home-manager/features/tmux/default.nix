{ pkgs, lib, config, ... }:
{
  programs.tmux = {
    enable = true;
  };
  home.file.".tmux.conf".source = ./.tmux.conf;
};
