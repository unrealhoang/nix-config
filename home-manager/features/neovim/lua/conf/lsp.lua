local function on_lsp_attach(_, bufnr)
  vim.b.omnifunc = "v:lua.vim.lsp.omnifunc"
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
end

local function setup_lsp_rust(capabilities)
  local util = require 'lspconfig/util'
  local extension_path = vim.fn.expand("$HOME/.vscode-oss/extensions/vadimcn.vscode-lldb-1.7.0/", nil, nil)
  local codelldb_path = extension_path .. 'adapter/codelldb'
  local liblldb_path = extension_path .. 'lldb/lib/liblldb.so'
  require 'rust-tools'.setup {
    tools = {
      hover_with_actions = false,
    },
    hover_actions = {
      auto_focus = true,
    },
    server = {
      on_attach = on_lsp_attach,
      standalone = false,
      root_dir = util.root_pattern("Cargo.lock", "rust-project.json"),
      init_options = {
        publishDecorations = true;
      },
      capabilities = capabilities,
      settings = {
        ['rust-analyzer'] = {
          cargo = {
            loadOutDirsFromCheck = true,
            allFeatures = true,
          },
          procMacro = {
            -- enable = true,
            ignored = {
              ['async-trait'] = { 'async_trait' },
            },
          },
        },
      },
    },
    dap = {
      adapter = require 'rust-tools.dap'.get_codelldb_adapter(codelldb_path, liblldb_path, nil)
    }
  }
end

local function setup_lsp_go(capabilities)
  local cmd
  if vm.fn.executable('gopls') then
    cmd = 'gopls'
  elseif vim.fn.getenv('GOPATH') ~= vim.NIL then
    cmd = vim.fn.expand('$GOPATH/bin/gopls')
  else
    cmd = vim.fn.expand('$HOME/go/bin/gopls')
  end
  require 'lspconfig'.gopls.setup {
    cmd = { cmd },
    on_attach = on_lsp_attach,
    capabilities = capabilities,
  }
end

local function setup_lsp_lua(capabilities)
  local sumneko_binary = "lua-language-server"
  local sumneko_main = "/usr/lib/lua-language-server/main.lua"
  local lua_runtime_path = vim.split(package.path, ';', {})
  table.insert(lua_runtime_path, "lua/?.lua")
  table.insert(lua_runtime_path, "lua/?/init.lua")

  require 'neodev'.setup {}
  require 'lspconfig'.lua_ls.setup({
    cmd = { sumneko_binary, "-E", sumneko_main },
    capabilities = capabilities,
    on_attach = on_lsp_attach,
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT',
          path = lua_runtime_path,
        },
        diagnostics = {
          globals = { 'vim' },
        },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
        },
        telemetry = {
          enable = false,
        }
      }
    }
  })
end

local function setup_lsp()
  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      'documentation',
      'detail',
      'additionalTextEdits',
    },
  }
  setup_lsp_rust(capabilities)
  setup_lsp_go(capabilities)
  setup_lsp_lua(capabilities)

  vim.lsp.handlers['textDocument/codeAction'] = require 'lsputil.codeAction'.code_action_handler
  vim.lsp.handlers['textDocument/references'] = require 'lsputil.locations'.references_handler
  vim.lsp.handlers['textDocument/definition'] = require 'lsputil.locations'.definition_handler
  vim.lsp.handlers['textDocument/declaration'] = require 'lsputil.locations'.declaration_handler
  vim.lsp.handlers['textDocument/typeDefinition'] = require 'lsputil.locations'.typeDefinition_handler
  vim.lsp.handlers['textDocument/implementation'] = require 'lsputil.locations'.implementation_handler
  vim.lsp.handlers['textDocument/documentSymbol'] = require 'lsputil.symbols'.document_handler
  vim.lsp.handlers['workspace/symbol'] = require 'lsputil.symbols'.workspace_handler
end

return {
  setup = setup_lsp,
}
