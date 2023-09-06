local rename_file = require 'conf/utils'.rename_file

local function keymap(mode, keybind, target, desc, opts)
  local default_opts = { remap = false, silent = true }
  local opts2 = vim.tbl_deep_extend("force", default_opts, opts or {})
  local opts_with_desc = vim.tbl_deep_extend("keep", opts2, { desc = (desc or "") })

  if not pcall(vim.keymap.set, mode, keybind, target, opts_with_desc) then
    error(string.format(
      "Failed to set mapping for: [%s]%s -> %s (%s)",
      mode,
      keybind,
      vim.inspect(target),
      vim.inspect(opts_with_desc))
    )
  end
end

local function install_mappings(mappings)
  for mode, mode_mappings in pairs(mappings) do
    for keybind, mapping_info in pairs(mode_mappings) do
      local target = mapping_info[1]
      local desc = mapping_info[2]
      local opts = mapping_info[3]

      keymap(mode, keybind, target, desc, opts)
    end
  end
end

local function install_autocmd_mappings(autocmd_mappings)
  for autocmd, mappings in pairs(autocmd_mappings) do

    local autocmd_s = vim.split(autocmd, "/", { plain = true })
    local event = autocmd_s[1]
    local pattern = autocmd_s[2] or error(string.format("autocmd is not valid: %s", autocmd))
    vim.api.nvim_create_autocmd(event, { pattern = pattern, callback = function()
      install_mappings(mappings)
    end })
  end
end

local function setup_mappings()
  vim.o.timeoutlen = 300
  local folders = {
    ['<leader>l']  = { name = "Lsp" },
    ['<leader>lr'] = { name = "Rust Tools" },
    ['<leader>d']  = { name = "Diagnostics" },
    ['<leader>p']  = { name = "Project Navigation" },
    ['<leader>b']  = { name = "Dap DeBbuger" },
    ['<leader>g']  = { name = "Git" },
    ['<leader>t']  = { name = "Treesitter" },
  }
  local wk = require 'which-key'
  wk.setup{}
  wk.register(folders)
  local mappings = {
    n = {
      -- common navigation
      ['gsd'] = { '<cmd>rightbelow vertical lua vim.lsp.buf.definition()<CR>', 'go to definition in split' },
      ['gd'] = { vim.lsp.buf.definition, 'go to definition' },
      ['K'] = { vim.lsp.buf.hover, 'show hover information' },
      ['gD'] = { vim.lsp.buf.implementation, 'go to implementation' },
      ['1gD'] = { vim.lsp.buf.type_definition, 'go to type definition' },
      ['gr'] = { vim.lsp.buf.references, 'go to references' },
      ['<leader>.'] = { vim.lsp.buf.code_action, 'code actions' },
      ['gW'] = { vim.lsp.buf.workspace_symbol, 'workspace symbols' },
      ['<leader>ff'] = { vim.lsp.buf.format, 'code formatting' },

      -- lsp specific
      ['<leader>ld'] = { vim.diagnostic.open_float, 'show diagnostic in float' },
      ['<leader>ls'] = { require 'telescope.builtin'.lsp_document_symbols, 'document symbols' },
      ['<leader>lS'] = { require 'telescope.builtin'.lsp_workspace_symbols, 'workspace symbols' },
      ['<leader>lf'] = { vim.lsp.buf.format, 'code formatting' },
      ['<leader>ln'] = { vim.lsp.buf.rename, 'rename' },

      -- Rust tools
      ['<leader>lre'] = { require 'rust-tools.expand_macro'.expand_macro, 'Expand Rust Macro' },
      ['<leader>lrr'] = { require 'rust-tools.runnables'.runnables, 'Rust runnables' },
      ['<leader>lrp'] = { require 'rust-tools.parent_module'.parent_module, 'Rust go to parent module' },
      ['<leader>lrc'] = { require 'rust-tools.open_cargo_toml'.open_cargo_toml, 'Rust open Cargo.toml' },
      ['<leader>lrj'] = { require 'rust-tools.join_lines'.join_lines, 'Rust join lines' },
      ['<leader>lrh'] = { require 'rust-tools.hover_actions'.hover_actions, 'Hover actions' },

      -- diagnostics related
      ['<leader>dl'] = { vim.diagnostic.setloclist, 'loclist of diagnostics' },
      ['<leader>dt'] = { function() require 'telescope.builtin'.diagnostics({ bufnr = 0 }) end,
        'current file diagnostics' },
      ['<leader>dT'] = { function() require 'telescope.builtin'.diagnostics() end, 'project diagnostics' },
      ['<leader>dn'] = { vim.diagnostic.goto_next, 'go to next diagnostics' },
      ['<leader>dp'] = { vim.diagnostic.goto_prev, 'go to prev diagnostics' },

      -- project navigation
      ['<leader>pf'] = { '<cmd>Files<cr>', 'find files' },
      ['<leader>pg'] = { '<cmd>GFiles<cr>', 'find git fiels' },
      ['<leader>pb'] = { '<cmd>Buffers<cr>', 'find buffers' },
      ['<leader>pa'] = { '<cmd>exec ":Rg ".input("Rg> ")<cr>', 'Search from input' },
      ['<leader>ps'] = { '<cmd>exec ":Rg ".expand("<cword>")<cr>', 'Search current word' },
      ['<leader>gc'] = { '<cmd>Commits<cr>', 'find git commits' },
      ['<leader>gg'] = { '<cmd>BCommits<cr>', 'find git commits for current buffer' },
      ['<leader>fo'] = { ':e %:h/', 'open file relative to current buffer' },

      -- buffer navigation
      ['<leader>]'] = { ':bn<cr>', 'next buffer' },
      ['<leader>['] = { ':bp<cr>', 'prev buffer' },
      ['<leader><tab>'] = { ':b#<cr>', 'last buffer' },

      -- dap debugger
      ['<leader>bs'] = { require'dap'.toggle_breakpoint, 'set breakpoint' },
      ['<leader>bc'] = { require'dap'.continue, 'continue' },
      ['<leader>bi'] = { require'dap'.step_into, 'step Into' },
      ['<leader>bo'] = { require'dap'.step_over, 'step Over' },
      ['<leader>bt'] = { require'dap'.terminate, 'Terminate request' },
      ['<leader>bd'] = { require'dap'.disconnect, 'Disconnect from dap server' },
      ['<leader>bu'] = { require'dapui'.toggle, 'toggle dap UI' },

      -- misc
      ['<leader>n'] = { rename_file, 'rename current file' },
      ['<leader><space>'] = { '<cmd>StripWhitespace<cr>', 'remove trailing whitespace' },
      ['<c-l>'] = { '<cmd>nohl<cr><c-l>', 'refersh no highlight search' },
      ['<cr>'] = { 'za', 'fold toggle current' },

      -- treesitter related
      -- ['<leader>t.'] = { require'ts-node-action'.node_action, 'node action' },
    },
    v = {
      ['<leader>.'] = { '<esc><cmd>lua vim.lsp.buf.range_code_action()<CR>', 'code range actions' },
    },
    i = {
      ['<c-x><c-f>'] = { '<plug>(fzf-complete-path)', 'complete file path' },
    },
  }
  install_mappings(mappings)

  local reset_cr = {
    n = {
      ['<cr>'] = { '<cr>', 'normal enter', { buffer = true } },
    }
  }
  local autocmd_mappings = {
    ["BufReadPost/quickfix"] = reset_cr,
    ["CmdwinEnter/*"] = reset_cr,
  }
  install_autocmd_mappings(autocmd_mappings)
end

return {
  setup = setup_mappings,
}
