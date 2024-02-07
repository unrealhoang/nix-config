{ config, ... }: {
  imports = [ ../user-configurations ];
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
      extraConfig = {
        user.signingKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmRDJOAiOymGN+VSuyCpKHbVbBQF5/2Q6E2XdjIiIdm";
        gpg = {
          format = "ssh";
          ssh.program = config.userConf.gitGpgSSHSignProgram;
        };
        core = {
          autocrlf = "input";
          editor = "nvim";
        };
        commit.gpgsign = true;
        push.default = "current";
        pull.ff = "only";
        diff = {
          algorithm = "minimal";
          compactionHeuristic = true;
          renames = true;
        };
        merge.conflictstyle = "diff3";

        includeIf = let
          incConf = config.userConf.gitFolderConfigs;
          confs = builtins.map (ifPath: {
            name = "gitdir:${ifPath}";
            value = { path = incConf.${ifPath}; };
          }) (builtins.attrNames incConf);
        in builtins.listToAttrs confs;
      };
    };
  };
}
