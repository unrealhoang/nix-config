{ lib, pkgs, ... }: {
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
      undotree
      nvim-treesitter
      nvim-treesitter-textobjects
      nvim-treesitter-parsers.rust
      nvim-treesitter-parsers.go
      nvim-treesitter-parsers.sql

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

      cmp-luasnip
      luasnip

      which-key-nvim
    ];
    defaultEditor = true;
  }
  home.file.".config/nvim/init.lua".source = ./init.lua
  home.file.".config/nvim/lua".source = ./lua
}
