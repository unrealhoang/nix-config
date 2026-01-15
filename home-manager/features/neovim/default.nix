{ pkgs, inputs, config, ... }:
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
in
{
  imports = [
    ../user-configurations
    inputs.nixCats.homeModule
  ];

  home.packages = [ pkgs.lua-language-server pkgs.nil ];
  programs.ripgrep.enable = true;
  programs.bat.enable = true;

  # Disable programs.neovim since we're using nixCats
  programs.neovim.enable = false;

  nixCats = {
    enable = true;

    # Use the nixCats plugin utils
    addOverlays = [
      (inputs.nixCats.utils.standardPluginOverlay inputs)
    ];

    packageNames = [ "nvim" ];

    luaPath = "${./.}";

    packages = {
      nvim = {
        settings = {
          wrapRc = true;
          configDirName = "nvim";
          aliases = [ "vim" "vi" ];
          neovim-unwrapped = null;
        };

        categories = {
          general = true;
          treesitter = true;
          completion = true;
          lsp = true;
          telescope = true;
          git = true;
          ui = true;
          debug = true;
          rust = true;
          ai = true;
          catppuccin_flavour = palette;
        };

        extra = {
          nixdExtras = {
            nixpkgs = inputs.nixpkgs;
          };
        };

        # Runtime dependencies
        lspsAndRuntimeDeps = {
          general = with pkgs; [
            ripgrep
            fd
          ];
          lsp = with pkgs; [
            lua-language-server
            nil
            gopls
          ];
          rust = with pkgs; [
            rust-analyzer
          ];
        };

        # Plugins that load on startup
        startupPlugins = {
          general = with pkgs.vimPlugins; [
            lze
            lzextras
            vim-sleuth
            vim-better-whitespace
          ];
          ui = with pkgs.vimPlugins; [
            catppuccin-nvim
            nvim-web-devicons
            bufferline-nvim
            fidget-nvim
            which-key-nvim
            mini-nvim
          ];
          treesitter = with pkgs.vimPlugins; [
            nvim-treesitter
            nvim-treesitter-textobjects
            nvim-treesitter-endwise
            nvim-treesitter-parsers.lua
            nvim-treesitter-parsers.rust
            nvim-treesitter-parsers.go
            nvim-treesitter-parsers.sql
            nvim-treesitter-parsers.nix
            nvim-treesitter-parsers.html
            nvim-treesitter-parsers.css
            nvim-treesitter-parsers.markdown
            nvim-treesitter-parsers.markdown_inline
          ];
        };

        # Plugins that load lazily
        optionalPlugins = {
          general = with pkgs.vimPlugins; [
            fzf-vim
            vim-peekaboo
            BufOnly-vim
            nerdtree
            undotree
            oil-nvim
            snacks-nvim
            treesj
            vim-nix
          ];
          completion = with pkgs.vimPlugins; [
            nvim-cmp
            cmp-nvim-lsp
            cmp-buffer
            cmp-path
            cmp-cmdline
            cmp_luasnip
            luasnip
            lspkind-nvim
          ];
          lsp = with pkgs.vimPlugins; [
            nvim-lspconfig
            neodev-nvim
            trouble-nvim
            lsp-colors-nvim
            popfix
            nvim-lsputils
          ];
          telescope = with pkgs.vimPlugins; [
            telescope-nvim
            plenary-nvim
            popup-nvim
          ];
          git = with pkgs.vimPlugins; [
            vim-fugitive
          ];
          debug = with pkgs.vimPlugins; [
            nvim-dap
            nvim-dap-ui
            nvim-nio
          ];
          rust = with pkgs.vimPlugins; [
            rustaceanvim
            crates-nvim
          ];
          ai = [
            pkgs.vimPlugins.codecompanion-nvim
            nvim-aider
          ];
        };
      };
    };
  };
}
