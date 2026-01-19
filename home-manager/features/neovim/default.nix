{ pkgs, config, inputs, ... }:
let
  palette = config.catppuccin.flavor;
  nixCatsUtils = import inputs.nixCats;
  luaPath = ./.;

  categoryDefinitions = { pkgs, settings, categories, extra, name, mkPlugin, ... }: {
    lspsAndRuntimeDeps = {
      general = with pkgs; [
        lua-language-server
        nil
        fd
      ];
    };

    startupPlugins = {
      general = with pkgs.vimPlugins; [
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
        nvim-treesitter.withAllGrammars
        nvim-treesitter-textobjects

        nvim-lspconfig
        popfix
        nvim-lsputils
        popup-nvim
        plenary-nvim
        lspkind-nvim
        lsp-colors-nvim
        rustaceanvim
        crates-nvim
        treesj

        nvim-dap
        nvim-dap-ui
        nvim-nio

        trouble-nvim
        lazydev-nvim

        blink-cmp
        luasnip

        oil-nvim

        mini-nvim
        which-key-nvim

        snacks-nvim
      ];
    };

    optionalPlugins = {
      general = [];
    };
  };

  packageDefinitions = {
    nvim = { pkgs, name, mkPlugin, ... }: {
      settings = {
        wrapRc = false;
      };
      categories = {
        general = true;
      };
      extra = {
        catppuccin_flavour = palette;
      };
    };
  };

  defaultPackageName = "nvim";

  neovimPackage = nixCatsUtils.baseBuilder luaPath { inherit pkgs; } categoryDefinitions packageDefinitions defaultPackageName;
in {
  imports = [ ../user-configurations ];

  home.packages = [
    neovimPackage
  ];

  # Symlink config for live reload (wrapRc = false)
  # Use mkOutOfStoreSymlink to point directly to repo files, not nix store copies
  xdg.configFile."nvim/init.lua".source = config.lib.file.mkOutOfStoreSymlink "/Users/unreal/nix-config/home-manager/features/neovim/init.lua";
  xdg.configFile."nvim/lua".source = config.lib.file.mkOutOfStoreSymlink "/Users/unreal/nix-config/home-manager/features/neovim/lua";

  programs.ripgrep.enable = true;
  programs.bat.enable = true;
}
