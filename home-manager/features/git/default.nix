{ config, ... }: {
  imports = [ ../user-configurations ];
  config = {
    programs.git = {
      enable = true;
      signing = {
        format = "ssh";
        signer = config.userConf.gitGpgSSHSignProgram;
        signByDefault = true;
      };
      settings = {
        user = {
          name = "Unreal Hoang";
          email = "unrealhoang@gmail.com";
          signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmRDJOAiOymGN+VSuyCpKHbVbBQF5/2Q6E2XdjIiIdm";
        };
        alias = {
          ci = "checkin";
          st = "status";
          br = "branch";
          co = "checkout";
          df = "diff";
          cm = "commit";
          cp = "cherry-pick";
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
      includes = let incConf = config.userConf.gitFolderConfigs;
      in builtins.map (ifPath: {
        condition = "gitdir:${ifPath}";
        path = incConf.${ifPath};
      }) (builtins.attrNames incConf);
    };
  };
}
