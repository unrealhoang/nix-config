-- nixCats + lze lazy loading configuration
-- Check if running in nixCats environment
local nixCats = require('nixCats')

-- Set mapleader early
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Setup catppuccin flavor from nixCats category
local catppuccin_flavour = nixCats('catppuccin_flavour') or "mocha"
vim.g.catppuccin_flavour = catppuccin_flavour

-- Load core options first (before plugins)
require('conf/options').setup()

-- Setup lze lazy loading
require('lze').register_handlers(require('lzextras').lsp)

-- Helper to check if category is enabled
local function cat(category)
  return nixCats(category) ~= nil and nixCats(category) ~= false
end

-- Plugin specifications for lze
local plugins = {}

-- ============================================================================
-- UI Plugins (startup)
-- ============================================================================

if cat('ui') then
  table.insert(plugins, {
    'catppuccin-nvim',
    for_cat = 'ui',
    load = function(name)
      vim.cmd.packadd(name)
      require('catppuccin').setup {}
      vim.cmd.colorscheme('catppuccin')
    end,
  })

  table.insert(plugins, {
    'bufferline.nvim',
    for_cat = 'ui',
    event = 'DeferredUIEnter',
    after = function()
      require('bufferline').setup {}
    end,
  })

  table.insert(plugins, {
    'fidget.nvim',
    for_cat = 'ui',
    event = 'DeferredUIEnter',
    after = function()
      require('fidget').setup {}
    end,
  })

  table.insert(plugins, {
    'which-key.nvim',
    for_cat = 'ui',
    event = 'DeferredUIEnter',
    after = function()
      vim.o.timeoutlen = 300
      local wk = require('which-key')
      wk.setup {}
      wk.add({
        { "<leader>b", group = "Dap DeBbuger" },
        { "<leader>d", group = "Diagnostics" },
        { "<leader>g", group = "Git" },
        { "<leader>l", group = "Lsp" },
        { "<leader>lr", group = "Rust Tools" },
        { "<leader>p", group = "Project Navigation" },
        { "<leader>t", group = "Treesitter" },
        { "<leader>f", group = "Files/Formatting" },
      })
    end,
  })

  table.insert(plugins, {
    'mini.nvim',
    for_cat = 'ui',
    event = 'DeferredUIEnter',
    after = function()
      -- Add any mini.nvim modules setup here
    end,
  })
end

-- ============================================================================
-- Treesitter
-- ============================================================================

if cat('treesitter') then
  table.insert(plugins, {
    'nvim-treesitter',
    for_cat = 'treesitter',
    event = 'DeferredUIEnter',
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd('nvim-treesitter-textobjects')
      vim.cmd.packadd('nvim-treesitter-endwise')
    end,
    after = function()
      require('nvim-treesitter').setup {
        highlight = {
          disable = { "sql" },
          enable = true,
        },
        indent = {
          enable = true,
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
    end,
  })

  table.insert(plugins, {
    'treesj',
    for_cat = 'treesitter',
    keys = {
      { '<leader>t<space>', function() require('treesj').toggle() end, desc = 'treesitter - toggle split join' },
    },
    after = function()
      require('treesj').setup {}
    end,
  })
end

-- ============================================================================
-- Completion
-- ============================================================================

if cat('completion') then
  table.insert(plugins, {
    'nvim-cmp',
    for_cat = 'completion',
    event = { 'InsertEnter', 'CmdlineEnter' },
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd('cmp-nvim-lsp')
      vim.cmd.packadd('cmp-buffer')
      vim.cmd.packadd('cmp-path')
      vim.cmd.packadd('cmp-cmdline')
      vim.cmd.packadd('cmp_luasnip')
      vim.cmd.packadd('luasnip')
      vim.cmd.packadd('lspkind.nvim')
    end,
    after = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      require('lspkind').init()

      cmp.setup({
        completion = {
          autocomplete = false,
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
          { name = 'crates' },
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
    end,
  })
end

-- ============================================================================
-- LSP
-- ============================================================================

if cat('lsp') then
  table.insert(plugins, {
    'nvim-lspconfig',
    for_cat = 'lsp',
    -- Handler for individual LSP server specs
    lsp = function(plugin)
      vim.lsp.config(plugin.name, plugin.lsp or {})
      vim.lsp.enable(plugin.name)
    end,
    -- Global LSP setup runs before any server is configured
    after = function(_)
      -- Load dependencies
      vim.cmd.packadd('neodev.nvim')
      vim.cmd.packadd('trouble.nvim')
      vim.cmd.packadd('lsp-colors.nvim')
      vim.cmd.packadd('popfix')
      vim.cmd.packadd('nvim-lsputils')

      -- Setup neodev first
      require('neodev').setup {
        override = function(root_dir, library)
          if root_dir:find("/nix-config", 1, true) then
            library.enabled = true
            library.plugins = true
          end
        end,
      }

      -- Setup trouble
      require('trouble').setup {}

      -- Get capabilities from cmp if available
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      if cat('completion') then
        local ok, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
        if ok then
          capabilities = cmp_lsp.default_capabilities()
        end
      end
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = { 'documentation', 'detail', 'additionalTextEdits' },
      }

      -- Global LSP config applied to all servers
      vim.lsp.config('*', {
        capabilities = capabilities,
      })

      -- Setup lsputils handlers
      vim.lsp.handlers['textDocument/codeAction'] = require('lsputil.codeAction').code_action_handler
      vim.lsp.handlers['textDocument/references'] = require('lsputil.locations').references_handler
      vim.lsp.handlers['textDocument/definition'] = require('lsputil.locations').definition_handler
      vim.lsp.handlers['textDocument/declaration'] = require('lsputil.locations').declaration_handler
      vim.lsp.handlers['textDocument/typeDefinition'] = require('lsputil.locations').typeDefinition_handler
      vim.lsp.handlers['textDocument/implementation'] = require('lsputil.locations').implementation_handler
      vim.lsp.handlers['textDocument/documentSymbol'] = require('lsputil.symbols').document_handler
      vim.lsp.handlers['workspace/symbol'] = require('lsputil.symbols').workspace_handler

      vim.diagnostic.config({
        virtual_lines = true
      })
    end,
  })

  -- Individual LSP server configurations
  table.insert(plugins, {
    'lua_ls',
    lsp = {
      filetypes = { 'lua' },
      on_init = function(client)
        local path = client.workspace_folders[1].name
        if not vim.uv.fs_stat(path..'/.luarc.json') and not vim.uv.fs_stat(path..'/.luarc.jsonc') then
          client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
            Lua = {
              runtime = { version = 'LuaJIT' },
              diagnostics = { globals = { 'vim' } },
              workspace = {
                checkThirdParty = false,
                library = { vim.env.VIMRUNTIME }
              }
            }
          })
          client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
        end
        return true
      end,
    },
  })

  table.insert(plugins, {
    'nil_ls',
    lsp = {
      filetypes = { 'nix' },
    },
  })

  local gopls_cmd = vim.fn.executable('gopls') == 1 and 'gopls'
    or (vim.fn.getenv('GOPATH') ~= vim.NIL and vim.fn.expand('$GOPATH/bin/gopls'))
    or vim.fn.expand('$HOME/go/bin/gopls')
  table.insert(plugins, {
    'gopls',
    lsp = {
      filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
      cmd = { gopls_cmd },
      settings = {
        gopls = {
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
        },
      },
    },
  })
end

-- ============================================================================
-- Telescope
-- ============================================================================

if cat('telescope') then
  table.insert(plugins, {
    'telescope.nvim',
    for_cat = 'telescope',
    cmd = 'Telescope',
    keys = {
      { '<leader>ls', function() require('telescope.builtin').lsp_document_symbols() end, desc = 'document symbols' },
      { '<leader>lS', function() require('telescope.builtin').lsp_workspace_symbols() end, desc = 'workspace symbols' },
      { '<leader>dt', function() require('telescope.builtin').diagnostics({ bufnr = 0 }) end, desc = 'current file diagnostics' },
      { '<leader>dT', function() require('telescope.builtin').diagnostics() end, desc = 'project diagnostics' },
    },
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd('plenary.nvim')
      vim.cmd.packadd('popup.nvim')
    end,
    after = function()
      require('telescope').setup {
        defaults = {
          winblend = 3,
          layout_strategy = "flex",
        },
        file_previewer = require('telescope.previewers').vim_buffer_cat.new,
        grep_previewer = require('telescope.previewers').vim_buffer_vimgrep.new,
        qflist_previewer = require('telescope.previewers').vim_buffer_qflist.new,
      }
    end,
  })
end

-- ============================================================================
-- Git
-- ============================================================================

if cat('git') then
  table.insert(plugins, {
    'vim-fugitive',
    for_cat = 'git',
    cmd = { 'Git', 'G', 'Gstatus', 'Gblame', 'Gpush', 'Gpull', 'Gcommit', 'Gdiff', 'GFiles', 'Commits', 'BCommits' },
    keys = {
      { '<leader>gc', '<cmd>Commits<cr>', desc = 'find git commits' },
      { '<leader>gg', '<cmd>BCommits<cr>', desc = 'find git commits for current buffer' },
    },
    after = function()
      -- Setup autocommand for fugitive buffers
      local group = vim.api.nvim_create_augroup("FugitiveDeleteBuf", { clear = true })
      vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = "fugitive://*",
        callback = function() vim.opt.bufhidden = "delete" end,
        group = group,
      })
    end,
  })
end

-- ============================================================================
-- Debug (DAP)
-- ============================================================================

if cat('debug') then
  table.insert(plugins, {
    'nvim-dap',
    for_cat = 'debug',
    keys = {
      { '<leader>bs', function() require('dap').toggle_breakpoint() end, desc = 'set breakpoint' },
      { '<leader>bc', function() require('dap').continue() end, desc = 'continue' },
      { '<leader>bi', function() require('dap').step_into() end, desc = 'step Into' },
      { '<leader>bo', function() require('dap').step_over() end, desc = 'step Over' },
      { '<leader>bt', function() require('dap').terminate() end, desc = 'Terminate request' },
      { '<leader>bd', function() require('dap').disconnect() end, desc = 'Disconnect from dap server' },
    },
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd('nvim-dap-ui')
      vim.cmd.packadd('nvim-nio')
    end,
    after = function()
      require('dapui').setup {}
    end,
  })

  table.insert(plugins, {
    'nvim-dap-ui',
    for_cat = 'debug',
    keys = {
      { '<leader>bu', function() require('dapui').toggle() end, desc = 'toggle dap UI' },
    },
    dep_of = 'nvim-dap',
  })
end

-- ============================================================================
-- Rust
-- ============================================================================

if cat('rust') then
  table.insert(plugins, {
    'rustaceanvim',
    for_cat = 'rust',
    ft = 'rust',
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd('crates.nvim')
    end,
    before = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      if cat('completion') then
        local ok, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
        if ok then
          capabilities = cmp_lsp.default_capabilities()
        end
      end

      vim.g.rustaceanvim = {
        server = {
          capabilities = capabilities,
          root_dir = require('lspconfig.util').root_pattern("Cargo.lock", "rust-project.json"),
          settings = {
            ['rust-analyzer'] = {
              cargo = {
                loadOutDirsFromCheck = true,
                allFeatures = true,
              },
            },
          },
        },
      }
    end,
    after = function()
      require('crates').setup {
        completion = {
          cmp = { enabled = true },
        },
      }
    end,
  })
end

-- ============================================================================
-- General Plugins
-- ============================================================================

if cat('general') then
  table.insert(plugins, {
    'fzf.vim',
    for_cat = 'general',
    cmd = { 'Files', 'GFiles', 'Buffers', 'Rg' },
    keys = {
      { '<leader>pf', '<cmd>Files<cr>', desc = 'find files' },
      { '<leader>pg', '<cmd>GFiles<cr>', desc = 'find git files' },
      { '<leader>pb', '<cmd>Buffers<cr>', desc = 'find buffers' },
      { '<leader>pa', '<cmd>exec ":Rg ".input("Rg> ")<cr>', desc = 'Search from input' },
      { '<leader>ps', '<cmd>exec ":Rg ".expand("<cword>")<cr>', desc = 'Search current word' },
    },
  })

  table.insert(plugins, {
    'undotree',
    for_cat = 'general',
    cmd = 'UndotreeToggle',
  })

  table.insert(plugins, {
    'oil.nvim',
    for_cat = 'general',
    cmd = 'Oil',
    keys = {
      { '-', '<cmd>Oil<cr>', desc = 'Open Oil file browser' },
    },
    after = function()
      require('oil').setup {}
    end,
  })

  table.insert(plugins, {
    'nerdtree',
    for_cat = 'general',
    cmd = { 'NERDTree', 'NERDTreeToggle', 'NERDTreeFind' },
  })
end

-- ============================================================================
-- Load plugins with lze
-- ============================================================================

require('lze').load(plugins)

-- ============================================================================
-- Setup keymaps and commands
-- ============================================================================

require('conf/mappings').setup()
require('conf/user_commands').setup()

-- ============================================================================
-- Global helpers
-- ============================================================================

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
    vim.api.nvim_set_option_value('filetype', 'lua', {scope = 'local'})
    vim.api.nvim_buf_set_var(buf, 'inspect_scratch', true)
  end

  local function find_or_create_scratch()
    local bufs = vim.api.nvim_list_bufs()
    local found = -1
    for _, b in pairs(bufs) do
      local s, v = pcall(vim.api.nvim_buf_get_var, b, 'inspect_scratch')
      if s and v then
        found = b
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

  _G.gh = {
    string2buf = string2buf,
    inspect2scratch = inspect2scratch,
    inspect2buf = inspect2buf,
  }
end

setup_global_helpers()
