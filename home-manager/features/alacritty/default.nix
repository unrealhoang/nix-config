{ lib, pkgs, ... }: {
  programs.alacritty.enable = true;
  programs.kitty.enable = true;
  home.file.".config/alacritty/alacritty.yml".source = ./alacritty.yml;
}
