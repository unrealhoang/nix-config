{ config, ... }:
let font-family = "JetBrainsMono Nerd Font Mono";
in {
  imports = [ ../user-configurations ];
  config = {
    programs.alacritty = {
      enable = true;
      settings = {
        terminal = {
          shell = {
            program = config.userConf.shellProgram;
            args = [ "--login" ];
          };
        };
        env = { TERM = "xterm-256color"; };
        window = {
          opacity = 0.95;
          padding = {
            x = 2;
            y = 2;
          };
          startup_mode = "Maximized";
        };
        general = {
          live_config_reload = true;
        };
        font = {
          normal = {
            family = font-family;
            style = "Regular";
          };
          bold = {
            family = font-family;
            style = "Bold";
          };
          italic = {
            family = font-family;
            style = "Italic";
          };
          size = config.userConf.terminalFontSize;
        };
        colors = { draw_bold_text_with_bright_colors = true; };
      };
    };
    programs.kitty.enable = true;
  };
}
