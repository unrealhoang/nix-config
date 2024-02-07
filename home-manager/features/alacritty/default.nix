{ lib, pkgs, config, ... }:
let
  font-family = "JetBrainsMono Nerd Font Mono";
  # frappe | latte | macchiato | mocha
  color-palette = "frappe";
  color-config-loc =
    ".config/alacritty/catppuccin/catppuccin-${color-palette}.toml";
in {
  imports = [ ../user-configurations ];
  config = {
    home.file."${color-config-loc}".source = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "alacritty";
      rev = "f2da554ee63690712274971dd9ce0217895f5ee0";
      sha256 = "sha256-ypYaxlsDjI++6YNcE+TxBSnlUXKKuAMmLQ4H74T/eLw=";
    } + "/catppuccin-${color-palette}.toml";

    programs.alacritty = {
      enable = true;
      settings = {
        import = [ config.home.file."${color-config-loc}".target ];
        env = { TERM = "xterm-256color"; };
        window = {
          opacity = 0.95;
          padding = {
            x = 2;
            y = 2;
          };
          startup_mode = "Maximized";
        };
        live_config_reload = true;
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
