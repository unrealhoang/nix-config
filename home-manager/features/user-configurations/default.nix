# Store all declaration of user configurations for feature modules
{ lib, pkgs, ... }:
with lib; {
  options.userConf = {
    terminalFontSize = mkOption {
      type = types.float;
      description = "Terminal emulation font size";
      default = 10.0;
    };
    gitGpgSSHSignProgram = mkOption {
      type = types.str;
      description = "program to gpg sign";
      default = "op-ssh-sign";
    };
    gitFolderConfigs = mkOption {
      type = types.attrsOf types.str;
      description = "custom per folder configuration for git ";
    };
    shellProgram = mkOption {
      type = types.str;
      description = "path to shell program";
      default = "${pkgs.zsh}/bin/zsh";
    };
  };
}
