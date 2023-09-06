local function setup_cmp()
  local cmp = require 'cmp'
  local luasnip = require 'luasnip'
  cmp.setup({
    completion = {
      autocomplete = false, -- disable auto-completion
    },
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-d>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-x><C-l>'] = cmp.mapping(cmp.mapping.complete({}), { 'i', 'c' }),
      ['<C-e>'] = cmp.mapping({
        i = cmp.mapping.abort(),
        c = cmp.mapping.close(),
      }),
      ['<Tab>'] = cmp.mapping(function(fallback)
        if luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { 'i', 's' }),
      ['<S-Tab>'] = cmp.mapping(function(fallback)
        if luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { 'i', 's' }),
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
      { name = "crates" },
      {
        name = 'buffer',
        option = {
          get_bufnrs = function()
            return vim.api.nvim_list_bufs()
          end
        },
      },
    })
  })
end

local function setup_treesitter()
  require 'nvim-treesitter.configs'.setup {
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
  local parser_configs = require('nvim-treesitter.parsers').get_parser_configs()

  parser_configs.norg = {
    install_info = {
      url = "https://github.com/nvim-neorg/tree-sitter-norg",
      files = { "src/parser.c", "src/scanner.cc" },
      branch = "main"
    },
  }
  parser_configs.norg_meta = {
    install_info = {
      url = "https://github.com/nvim-neorg/tree-sitter-norg-meta",
      files = { "src/parser.c" },
      branch = "main"
    },
  }

  parser_configs.norg_table = {
    install_info = {
      url = "https://github.com/nvim-neorg/tree-sitter-norg-table",
      files = { "src/parser.c" },
      branch = "main"
    },
  }
end

local function setup_global_helpers()
  local function string2buf(...)
    local arg = { ... }
    local buf = 0
    local str = arg[1]
    if #arg == 2 then
      buf = arg[1]
      str = arg[2]
    end

    local lines = {}
    for s in str:gmatch("[^\r\n]+") do
      table.insert(lines, s)
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end

  local function inspect2buf(...)
    local arg = { ... }
    local buf = 0
    local val = arg[1]
    if #arg == 2 then
      buf = arg[1]
      val = arg[2]
    end

    local str = vim.inspect(val)
    string2buf(buf, str)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'lua')
    vim.api.nvim_buf_set_var(buf, 'inspect_scratch', true)
  end

  local function find_or_create_scratch()
    local bufs = vim.api.nvim_list_bufs()
    local found = -1
    for _, buf in pairs(bufs) do
      local s, v = pcall(vim.api.nvim_buf_get_var, buf, 'inspect_scratch')
      if s and v then
        found = buf
        break
      end
    end

    if found == -1 then
      return vim.api.nvim_create_buf(false, true)
    else
      return found
    end
  end

  local function inspect2scratch(val)
    local buf = find_or_create_scratch()
    inspect2buf(buf, val)

    vim.cmd('vsplit')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
  end

  -- global helper
  local gh = {
    string2buf = string2buf,
    inspect2scratch = inspect2scratch,
    inspect2buf = inspect2buf,
  }
  _G.gh = gh
end

local function bootstrap()
  require 'conf/options'.setup()
  setup_cmp()
  require 'dapui'.setup {}
  require 'conf/lsp'.setup()
  setup_treesitter()
  setup_global_helpers()
  require 'conf/autocommands'.setup()
  require 'conf/user_commands'.setup()
  require 'conf/mappings'.setup()

  require 'telescope'.setup {
    defaults = {
      winblend = 3,
      layout_strategy = "flex",
    },
    file_previewer = require 'telescope.previewers'.vim_buffer_cat.new,
    grep_previewer = require 'telescope.previewers'.vim_buffer_vimgrep.new,
    qflist_previewer = require 'telescope.previewers'.vim_buffer_qflist.new,
  }

  require 'lspkind'.init()
  require 'trouble'.setup {}
  require 'bufferline'.setup {}

  require 'catppuccin'.setup {}
  require 'fidget'.setup {}
  require 'crates'.setup {}

  require 'oil'.setup {}
end

bootstrap()
