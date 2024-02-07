{ config, ... }:
{
  imports = [
    ../user-configurations
  ];
  config = {
    programs.git = {
      enable = true;
      userName = "Unreal Hoang";
      userEmail = "unrealhoang@gmail.com";
      aliases = {
        ci = "checkin";
        st = "status";
        br = "branch";
        co = "checkout";
        df = "diff";
        cm = "commit";
        cp = "cherry-pick";
      };
      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmRDJOAiOymGN+VSuyCpKHbVbBQF5/2Q6E2XdjIiIdm";
        signByDefault = true;
      };
      extraConfig = {
        gpg = {
          format = "ssh";
          ssh.program = config.userConf.gitGpgSSHSignProgram;
        };
        core = {
          autocrlf = "input";
          editor = "nvim";
        };
        push.default = "current";
        pull.ff = "only";
        diff = {
          algorithm = "minimal";
          compactionHeuristic = true;
          renames = true;
        };
        merge.conflictstyle = "diff3";
      };
    };
  };
}
