{ pkgs, ... }: {
  programs.starship = {
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
    initContent = ''
      enable-fzf-tab
    '';
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "fasd" "fzf" "direnv" ];
    };
    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];
    syntaxHighlighting.enable = true;
    history = { size = 1000000; };
  };
}
