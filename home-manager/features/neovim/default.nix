{ pkgs, config, ... }: let
    palette = config.userConf.catppuccinPalette;
in {
  imports = [ ../user-configurations ];
  home.packages = [ pkgs.lua-language-server pkgs.nil ];
  programs.ripgrep.enable = true;
  programs.bat = {
    enable = true;
    themes = {
      "Catppuccin-${palette}" = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat"; # Bat uses sublime syntax for its themes
          rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
          sha256 = "6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
        };
        file = "Catppuccin-${palette}.tmTheme";
      };
    };
    config = { theme = "Catppuccin-${palette}"; };
  };
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      catppuccin-nvim
      nvim-web-devicons
      bufferline-nvim
      fidget-nvim
      fzf-vim
      vim-peekaboo
      vim-better-whitespace
      BufOnly-vim
      nerdtree
      nvim-treesitter-endwise
      vim-fugitive
      vim-surround
      vim-nix
      vim-sleuth
      undotree
      nvim-treesitter
      nvim-treesitter-textobjects
      nvim-treesitter-parsers.lua
      nvim-treesitter-parsers.rust
      nvim-treesitter-parsers.go
      nvim-treesitter-parsers.sql
      nvim-treesitter-parsers.nix
      nvim-treesitter-parsers.html
      nvim-treesitter-parsers.css

      nvim-lspconfig
      popfix
      nvim-lsputils
      popup-nvim
      plenary-nvim
      telescope-nvim
      lspkind-nvim
      lsp-colors-nvim
      rust-tools-nvim
      crates-nvim

      nvim-dap
      nvim-dap-ui

      trouble-nvim
      neodev-nvim

      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      nvim-cmp

      cmp_luasnip
      luasnip

      oil-nvim

      which-key-nvim
    ];
    defaultEditor = true;
  };
  home.file.".config/nvim/init.lua".text = ''
  vim.g.catppuccin_flavour = "${palette}"
  '' + (builtins.readFile ./init.lua);
  home.file.".config/nvim/lua".source = ./lua;
}
