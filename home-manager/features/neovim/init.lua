-- Set catppuccin flavor from nixCats extra
local ok, nixCats_extra = pcall(function() return require('nixCats').extra end)
if ok and nixCats_extra and nixCats_extra.catppuccin_flavour then
  vim.g.catppuccin_flavour = nixCats_extra.catppuccin_flavour
end

local function setup_cmp()
  require 'luasnip'
  require 'blink.cmp'.setup({
    snippets = { preset = 'luasnip' },
    keymap = {
      preset = 'default',
      ['<C-space>'] = {},
    },
    sources = {
      default = { 'lsp', 'path', 'snippets' },
    },
    completion = {
      keyword = { range = 'full' },
      accept = { auto_brackets = { enabled = false }, },
      menu = { auto_show = false, },
      ghost_text = { enabled = true },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
      }
    },
    signature = { enabled = true },
  })
end

local function setup_treesitter()
  require 'nvim-treesitter'.setup {
    playground = {
      enable = true,
      disable = {},
      updatetime = 25,
      persist_queries = false
    },
    highlight = {
      disable = { "sql" },
      enable = true, -- false will disable the whole extension
    },
    indent = {
      enable = true,
    },
    refactor = {
      highlight_definitions = { enable = true },
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn",
        node_incremental = "gnn",
        scope_incremental = "grc",
        node_decremental = "gnp",
      },
    },
    textobjects = {
      select = {
        enable = true,
        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ["<leader>ts"] = "@parameter.inner",
        },
        swap_previous = {
          ["<leader>tS"] = "@parameter.inner",
        },
      }
    },
  }
end

local function bootstrap()
  require 'conf/options'.setup()
  require 'crates'.setup {}
  setup_cmp()
  require 'conf/lsp'.setup()

  vim.diagnostic.config({
    -- Use the default configuration
    virtual_lines = true
  })
  setup_treesitter()
  require 'conf/autocommands'.setup()
  require 'conf/user_commands'.setup()

  require 'lspkind'.init()
  require 'trouble'.setup {}
  require 'bufferline'.setup {}

  require 'catppuccin'.setup {}
  require 'fidget'.setup {}
  require 'treesj'.setup {}

  require 'oil'.setup {}

  require 'snacks'.setup({
    picker = {
      grep = {
        finder = 'rg',
      },
      layout = {
        preset = 'ivy',
      }
    },
  })
  require 'conf/mappings'.setup()
end

bootstrap()
