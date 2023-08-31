{ lib, pkgs, ... }: {
  programs.starship = {
    enable = true;
    settings = {
      git_status = {
        ahead = ''⇡''${count}'';
        diverged = ''⇕⇡''${ahead_count}⇣''${behind_count}'';
        behind = ''⇣''${count}'';
      };
    };
  };
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
