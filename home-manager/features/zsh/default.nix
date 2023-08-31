{ lib, pkgs, ... }: {
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "fasd"
      ];
    };
    syntaxHighlighting.enable = true;
    history = {
      size = 1000000;
    };
  };
}
