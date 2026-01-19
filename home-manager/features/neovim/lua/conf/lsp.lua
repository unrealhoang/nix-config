local function setup_lsp_rust()
  local util = require 'lspconfig/util'
  vim.g.rustaceanvim = {
    server = {
      root_dir = util.root_pattern("Cargo.lock", "rust-project.json"),
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
end

local function setup_lsp_go()
  local cmd
  if vim.fn.executable('gopls') then
    cmd = 'gopls'
  elseif vim.fn.getenv('GOPATH') ~= vim.NIL then
    cmd = vim.fn.expand('$GOPATH/bin/gopls')
  else
    cmd = vim.fn.expand('$HOME/go/bin/gopls')
  end
  vim.lsp.config('gopls', {
    inlay_hints = { enable = true },
    cmd = { cmd },
  })
  vim.lsp.enable('gopls')
end

local function setup_lsp_lua()
  require 'lazydev'.setup { }
  vim.lsp.enable('lua_ls')
end

local function setup_lsp_nix()
  vim.lsp.config('nil_ls', { })
  vim.lsp.enable('nil_ls')
end

local function setup_lsp()
  setup_lsp_rust()
  setup_lsp_go()
  setup_lsp_lua()
  setup_lsp_nix()
end

return {
  setup = setup_lsp,
}
