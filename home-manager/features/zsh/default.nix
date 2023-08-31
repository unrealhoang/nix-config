{ lib, pkgs, ... }: {
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        git sudo fasd zsh-completions zsh-syntax-highlighting
      ];
    };
    syntaxHighlighting.enable = true;
    history = {
      size = 1000000;
    };
  }
}
