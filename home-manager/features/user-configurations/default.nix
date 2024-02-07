# Store all declaration of user configurations for feature modules
{ lib, ... }:
with lib;
{
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
  };
}
