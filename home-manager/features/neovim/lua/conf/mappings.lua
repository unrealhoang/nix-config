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

local function inlay_toggle()
  local filter = { bufnr = 0 }
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
end

local function setup_mappings()
  -- Note: which-key setup and folder groups are now in init.lua
  local mappings = {
    n = {
      -- common navigation (LSP)
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
      ['<leader>lf'] = { vim.lsp.buf.format, 'code formatting' },
      ['<leader>ln'] = { vim.lsp.buf.rename, 'rename' },
      ['<leader>li'] = { inlay_toggle, 'toggle inlay hints' },

      -- Rust tools
      ['<leader>lre'] = { function() vim.cmd.RustAnalyzer('expandMacro') end, 'Expand Rust Macro' },
      ['<leader>lrr'] = { function() vim.cmd.RustAnalyzer('runnables') end, 'Rust runnables' },
      ['<leader>lrp'] = { function() vim.cmd.RustAnalyzer('parentModule') end, 'Rust go to parent module' },
      ['<leader>lrc'] = { function() vim.cmd.RustAnalyzer('openCargo') end, 'Rust open Cargo.toml' },
      ['<leader>lrj'] = { function() vim.cmd.RustAnalyzer('joinLines') end, 'Rust join lines' },
      ['<leader>lrh'] = { function() vim.cmd.RustAnalyzer('hover', 'actions') end, 'Hover actions' },

      -- diagnostics related
      ['<leader>dl'] = { vim.diagnostic.setloclist, 'loclist of diagnostics' },
      ['<leader>dn'] = { vim.diagnostic.goto_next, 'go to next diagnostics' },
      ['<leader>dp'] = { vim.diagnostic.goto_prev, 'go to prev diagnostics' },

      -- buffer navigation
      ['<leader>]'] = { ':bn<cr>', 'next buffer' },
      ['<leader>['] = { ':bp<cr>', 'prev buffer' },
      ['<leader><tab>'] = { ':b#<cr>', 'last buffer' },

      -- misc
      ['<leader>n'] = { rename_file, 'rename current file' },
      ['<leader><space>'] = { '<cmd>StripWhitespace<cr>', 'remove trailing whitespace' },
      ['<c-l>'] = { '<cmd>nohl<cr><c-l>', 'refersh no highlight search' },
      ['<cr>'] = { 'za', 'fold toggle current' },
      ['<leader>fo'] = { ':e %:h/', 'open file relative to current buffer' },
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
