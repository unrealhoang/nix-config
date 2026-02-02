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
  vim.o.timeoutlen = 300
  local folders = {
    { "<leader>a", group = "Aider/AI" },
    { "<leader>b", group = "Dap DeBbuger" },
    { "<leader>d", group = "Diagnostics" },
    { "<leader>g", group = "Git" },
    { "<leader>l", group = "Lsp" },
    { "<leader>lr", group = "Rust Tools" },
    { "<leader>p", group = "Project Navigation" },
    { "<leader>t", group = "Treesitter" },
    { "<leader>f", group = "Files/Formatting" },
  }
  local wk = require 'which-key'
  wk.setup{}
  wk.add(folders)
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
      ['<leader>ls'] = { Snacks.picker.lsp_symbols, 'document symbols' },
      ['<leader>lS'] = { Snacks.picker.lsp_workspace_symbols, 'workspace symbols' },
      ['<leader>lf'] = { vim.lsp.buf.format, 'code formatting' },
      ['<leader>ln'] = { vim.lsp.buf.rename, 'rename' },
      ['<leader>li'] = { inlay_toggle, 'toggle inlay hints' },

      -- Rust tools
      ['<leader>lre'] = { function() vim.cmd.RustLsp('expandMacro') end, 'Expand Rust Macro' },
      ['<leader>lrr'] = { function() vim.cmd.RustLsp('runnables') end, 'Rust runnables' },
      ['<leader>lrp'] = { function() vim.cmd.RustLsp('parentModule') end, 'Rust go to parent module' },
      ['<leader>lrc'] = { function() vim.cmd.RustLsp('openCargo') end, 'Rust open Cargo.toml' },
      ['<leader>lrj'] = { function() vim.cmd.RustLsp('joinLines') end, 'Rust join lines' },
      ['<leader>lrh'] = { function() vim.cmd.RustLsp('hover', 'actions') end, 'Hover actions' },

      -- diagnostics related
      ['<leader>dl'] = { vim.diagnostic.setloclist, 'loclist of diagnostics' },
      ['<leader>dt'] = { Snacks.picker.diagnostics_buffer, 'current file diagnostics' },
      ['<leader>dT'] = { Snacks.picker.diagnostics, 'project diagnostics' },
      ['<leader>dd'] = { function()
        local new_config = not vim.diagnostic.config().virtual_lines
        vim.diagnostic.config({ virtual_lines = new_config })
      end, 'toggle hide virtual text diagnostic' },
      [']]'] = { require'trouble'.next, 'go to next diagnostics' },
      ['[['] = { require'trouble'.prev, 'go to prev diagnostics' },

      -- project navigation
      ['<leader>pf'] = { Snacks.picker.files, 'find files' },
      ['<leader>pg'] = { Snacks.picker.git_files, 'find git fiels' },
      ['<leader>pb'] = { Snacks.picker.buffers, 'find buffers' },
      ['<leader>pa'] = { Snacks.picker.grep, 'Search from input' },
      ['<leader>ps'] = { Snacks.picker.grep_word, 'Search current word' },
      ['<leader>gc'] = { Snacks.picker.git_log, 'find git commits' },
      ['<leader>gg'] = { Snacks.picker.git_log_file, 'find git commits for current buffer' },
      ['<leader>fo'] = { function() Snacks.explorer() end, 'open file relative to current buffer' },

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
      ['<leader>n'] = { Snacks.rename.rename_file, 'rename current file' },
      ['<leader><space>'] = { '<cmd>StripWhitespace<cr>', 'remove trailing whitespace' },
      ['<c-l>'] = { '<cmd>nohl<cr><c-l>', 'refersh no highlight search' },
      ['<cr>'] = { 'za', 'fold toggle current' },

      -- treesitter related
      ['<leader>t<space>'] = { require'treesj'.toggle, 'treesitter - toggle split join' },
    },
    v = {
      ['<leader>.'] = { '<esc><cmd>lua vim.lsp.buf.range_code_action()<CR>', 'code range actions' },
      ['<leader>ps'] = { Snacks.picker.grep_word, 'Search current word' },
    },
    i = {
      ['<c-x><c-f>'] = {
        function() require'blink.cmp'.show({ providers = {'path'} }) end,
        'complete file path',
      },
      ['<c-x><c-l>'] = {
        function()
          local bl = require'blink.cmp'
          if not bl.show() then
            if not bl.show_documentation() then
              bl.hide_documentation()
            end
          end
        end,
        'complete',
      },
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
