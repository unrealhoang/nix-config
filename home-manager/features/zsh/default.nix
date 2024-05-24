{ pkgs, ... }: {
  programs.starship = {
    catppuccin.enable = true;
    enable = true;
    settings = {
      git_status = {
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
      };
    };
  };
  programs.fzf.enable = true;
  programs.zsh = {
    enable = true;
    envExtra = ''
      . ${pkgs.nix}/etc/profile.d/nix-daemon.sh
    '';
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "fasd" "fzf" "direnv" ];
    };
    syntaxHighlighting.enable = true;
    history = { size = 1000000; };
  };
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };
}
