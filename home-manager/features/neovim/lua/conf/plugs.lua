local function setup_plugs()
  local Plug = vim.fn['plug#']
  vim.fn['plug#begin']('~/.config/nvim/plugged')

  -- theme
  Plug('arcticicestudio/nord-vim', { branch = 'develop' })
  Plug 'chriskempson/base16-vim'
  Plug 'hzchirs/vim-material'
  Plug 'sainnhe/edge'
  Plug 'sainnhe/gruvbox-material'
  Plug 'sainnhe/everforest'
  Plug 'shinchu/lightline-gruvbox.vim'
  Plug 'eddyekofo94/gruvbox-flat.nvim'
  Plug 'catppuccin/nvim'

  -- lang
  Plug 'diepm/vim-rest-console'
  Plug 'elixir-lang/vim-elixir'
  Plug 'rust-lang/rust.vim'
  Plug 'cespare/vim-toml'

  -- icon
  Plug 'kyazdani42/nvim-web-devicons'

  -- status line
  -- Plug 'itchyny/lightline.vim'
  -- Plug 'maximbaz/lightline-ale'
  -- Plug 'mgee/lightline-bufferline'
  -- Plug 'famiu/feline.nvim'
  Plug 'akinsho/nvim-bufferline.lua'
  Plug 'windwp/windline.nvim'
  Plug 'j-hui/fidget.nvim'

  Plug 'junegunn/vim-peekaboo'
  Plug 'kchmck/vim-coffee-script'
  Plug 'ntpeters/vim-better-whitespace'
  Plug 'schickling/vim-bufonly'
  Plug 'scrooloose/nerdtree'
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-surround'
  Plug 'mbbill/undotree'

  Plug 'nvim-treesitter/nvim-treesitter'
  Plug 'nvim-treesitter/nvim-treesitter-textobjects'
  Plug 'nvim-treesitter/playground'
  Plug 'ckolkey/ts-node-action'

  -- REST client
  Plug 'NTBBloodbath/rest.nvim'

  -- lsp-related
  Plug 'neovim/nvim-lspconfig'
  Plug 'RishabhRD/popfix'
  Plug 'RishabhRD/nvim-lsputils'
  Plug 'nvim-lua/popup.nvim'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'onsails/lspkind-nvim'
  Plug 'folke/lsp-colors.nvim'
  Plug 'mrcjkb/rustaceanvim'
  Plug 'saecki/crates.nvim'

  -- dap-related
  Plug 'mfussenegger/nvim-dap'
  Plug 'rcarriga/nvim-dap-ui'

  -- diagnostics
  Plug 'folke/trouble.nvim'
  Plug 'folke/neodev.nvim'

  -- snippet
  Plug 'L3MON4D3/LuaSnip' -- Snippets plugin

  -- git
  Plug 'TimUntersberger/neogit'

  -- org
  Plug 'nvim-neorg/neorg'

  -- keymap menu
  Plug 'linty-org/key-menu.nvim'
  vim.fn['plug#end']()
end

return {
  setup = setup_plugs,
}
