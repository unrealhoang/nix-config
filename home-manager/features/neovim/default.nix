{ pkgs, config, inputs, ... }:
let
  palette = config.catppuccin.flavor;
  nixCatsUtils = import inputs.nixCats;
  luaPath = ./.;

  categoryDefinitions = { pkgs, ... }: {
    lspsAndRuntimeDeps = {
      general = with pkgs; [
        typescript-language-server
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
        vim-peekaboo
        vim-better-whitespace
        nvim-treesitter-endwise
        vim-fugitive
        vim-nix
        vim-sleuth
        undotree
        (nvim-treesitter.withPlugins (p: [
          p.tree-sitter-nix
          p.tree-sitter-go
          p.tree-sitter-rust
          p.tree-sitter-nu
          p.tree-sitter-lua
          p.tree-sitter-json
          p.tree-sitter-yaml
          p.tree-sitter-toml
          p.tree-sitter-html
          p.tree-sitter-javascript
          p.tree-sitter-typescript
          p.tree-sitter-tsx
        ]))
        nvim-treesitter-textobjects

        nvim-lspconfig
        lspkind-nvim
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
        which-key-nvim
        snacks-nvim
      ];
    };

    optionalPlugins = {
      general = [];
    };
  };

  packageDefinitions = {
    nvim = { pkgs, ... }: {
      settings = {
        wrapRc = false;
      };
      categories = {
        general = true;
      };
      extra = {
        catppuccin_flavour = palette;
        nixdExtras = {
          nixpkgs = ''import ${pkgs.path} {}'';
          nixos_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").nixosConfigurations.configname.options'';
          home_manager_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").homeConfigurations.configname.options'';
        };
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
