{ pkgs, config, ... }:
let
  palette = config.catppuccin.flavor;
  nvim-aider = pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-aider";
    version = "2025-04-09";
    src = pkgs.fetchFromGitHub {
      owner = "GeorgesAlkhouri";
      repo = "nvim-aider";
      rev = "a9a707b24f2987b3c73a3589f02c838a572298a4";
      sha256 = "ipwYJon55rFu6gkOdaI3nw05mp4bJaJvGek/hEQTnXI=";
    };
    meta.homepage = "https://github.com/GeorgesAlkhouri/nvim-aider";
  };
in {
  imports = [ ../user-configurations ];
  home.packages = [ pkgs.lua-language-server pkgs.nil ];
  programs.ripgrep.enable = true;
  programs.bat = { enable = true; };
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
      rustaceanvim
      crates-nvim
      treesj

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

      mini-nvim
      which-key-nvim

      snacks-nvim
      nvim-aider
    ];
    defaultEditor = true;
  };
  home.file.".config/nvim/init.lua".text = ''
    vim.g.catppuccin_flavour = "${palette}"
  '' + (builtins.readFile ./init.lua);
  home.file.".config/nvim/lua".source = ./lua;
}
